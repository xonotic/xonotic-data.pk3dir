#include "item_key.qh"
#include "_all.qh"

#include "../common/triggers/subs.qh"
#include "../common/monsters/all.qh"
#include "../common/notifications.qh"
#include "../common/util.qh"
#include "../warpzonelib/util_server.qh"

/*
TODO:
- add an unlock sound (here to trigger_keylock and to func_door)
- display available keys on the HUD
- make more tests
- think about adding NOT_EASY/NOT_NORMAL/NOT_HARD for Q1 compatibility
- should keys have a trigger?
*/

bool item_keys_usekey(entity l, entity p)
{
	float valid = l.itemkeys & p.itemkeys;

	if (!valid) {
		// other has none of the needed keys
		return false;
	} else if (l.itemkeys == valid) {
		// ALL needed keys were given
		l.itemkeys = 0;
		return true;
	} else {
		// only some of the needed keys were given
		l.itemkeys &= ~valid;
		return true;
	}
}

string item_keys_keylist(float keylist) {
	// no keys
	if (!keylist)
		return "";

	// one key
	if ((keylist & (keylist-1)) != 0)
		return strcat("the ", item_keys_names[lowestbit(keylist)]);

	string n = "";
	int base = 0;
	while (keylist) {
		int l = lowestbit(keylist);
		if (n)
			n = strcat(n, ", the ", item_keys_names[base + l]);
		else
			n = strcat("the ", item_keys_names[base + l]);

		keylist = bitshift(keylist,  -(l + 1));
		base+= l + 1;
	}

	return n;
}


/*
================================
item_key
================================
*/

/**
 * Key touch handler.
 */
void item_key_touch()
{SELFPARAM();
	if (!IS_PLAYER(other))
		return;

	// player already picked up this key
	if (other.itemkeys & self.itemkeys)
		return;

	other.itemkeys |= self.itemkeys;
	play2(other, self.noise);

	centerprint(other, self.message);
};

/**
 * Spawn a key with given model, key code and color.
 */
void spawn_item_key()
{SELFPARAM();
	precache_model(self.model);

	if (self.spawnflags & 1) // FLOATING
		self.noalign = 1;

	if (self.noalign)
		self.movetype = MOVETYPE_NONE;
	else
		self.movetype = MOVETYPE_TOSS;

	precache_sound(self.noise);

	self.mdl = self.model;
	self.effects = EF_LOWPRECISION;
	_setmodel(self, self.model);
	//setsize(self, '-16 -16 -24', '16 16 32');
	setorigin(self, self.origin + '0 0 32');
	setsize(self, '-16 -16 -56', '16 16 0');
	self.modelflags |= MF_ROTATE;
	self.solid = SOLID_TRIGGER;

	if (!self.noalign)
	{
		// first nudge it off the floor a little bit to avoid math errors
		setorigin(self, self.origin + '0 0 1');
		// note droptofloor returns false if stuck/or would fall too far
		droptofloor();
	}

	self.touch = item_key_touch;
};


/*QUAKED item_key (0 .5 .8) (-16 -16 -24) (16 16 32) FLOATING
A key entity.
The itemkeys should contain one of the following key IDs:
1 - GOLD key -
2 - SILVER key
4 - BRONZE key
8 - RED keycard
16 - BLUE keycard
32 - GREEN keycard
Custom keys:
... - last key is 1<<23
Keys with bigger Id than 32 don't have a default netname and model, if you use one of them, you MUST provide those.
-----------KEYS------------
colormod: color of the key (default: '.9 .9 .9').
itemkeys: a key Id.
message: message to print when player picks up this key.
model: custom key model to use.
netname: the display name of the key.
noise: custom sound to play when player picks up the key.
-------- SPAWNFLAGS --------
FLOATING: the item will float in air, instead of aligning to the floor by falling
---------NOTES----------
This is the only correct way to put keys on the map!

itemkeys MUST always have exactly one bit set.
*/
void spawnfunc_item_key()
{SELFPARAM();
	string _netname;
	vector _colormod;

	// reject this entity if more than one key was set!
	if (self.itemkeys>0 && (self.itemkeys & (self.itemkeys-1)) != 0) {
		objerror("item_key.itemkeys must contain only 1 bit set specifying the key it represents!");
		remove(self);
		return;
	}

	// find default netname and colormod
	switch(self.itemkeys) {
	case 1:
		_netname = "GOLD key";
		_colormod = '1 .9 0';
		break;

	case 2:
		_netname = "SILVER key";
		_colormod = '.9 .9 .9';
		break;

	case 4:
		_netname = "BRONZE key";
		_colormod = '.6 .25 0';
		break;

	case 8:
		_netname = "RED keycard";
		_colormod = '.9 0 0';
		break;

	case 16:
		_netname = "BLUE keycard";
		_colormod = '0 0 .9';
		break;

	case 32:
		_netname = "GREEN keycard";
		_colormod = '0 .9 0';
		break;

	default:
		_netname = "FLUFFY PINK keycard";
		_colormod = '1 1 1';

		if (self.netname == "") {
			objerror("item_key doesn't have a default name for this key and a custom one was not specified!");
			remove(self);
			return;
		}
		break;

	}

	// find default model
	string _model = string_null;
	if (self.itemkeys <= ITEM_KEY_BIT(2)) {
		_model = "models/keys/key.md3";
	} else if (self.itemkeys >= ITEM_KEY_BIT(3) && self.itemkeys <= ITEM_KEY_BIT(5)) {
		_model = "models/keys/key.md3"; // FIXME: replace it by a keycard model!
	} else if (self.model == "") {
		objerror("item_key doesn't have a default model for this key and a custom one was not specified!");
		remove(self);
		return;
	}

	// set defailt netname
	if (self.netname == "")
		self.netname = _netname;

	// set default colormod
	if (!self.colormod)
		self.colormod = _colormod;

	// set default model
	if (self.model == "")
		self.model = _model;

	// set default pickup message
	if (self.message == "")
		self.message = strzone(strcat("You've picked up the ", self.netname, "!"));

	if (self.noise == "")
		self.noise = SND(ITEMPICKUP);

	// save the name for later
	item_keys_names[lowestbit(self.itemkeys)] = self.netname;

	// put the key on the map
	spawn_item_key();
}

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32) FLOATING
SILVER key.
-----------KEYS------------
colormod: color of the key (default: '.9 .9 .9').
message: message to print when player picks up this key.
model: custom model to use.
noise: custom sound to play when player picks up the key.
-------- SPAWNFLAGS --------
FLOATING: the item will float in air, instead of aligning to the floor by falling
---------NOTES----------
Don't use this entity on new maps! Use item_key instead.
*/
void spawnfunc_item_key1(void)
{SELFPARAM();
	self.classname = "item_key";
	self.itemkeys = ITEM_KEY_BIT(1);
	spawnfunc_item_key();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32) FLOATING
GOLD key.
-----------KEYS------------
colormod: color of the key (default: '1 .9 0').
message: message to print when player picks up this key.
model: custom model to use.
noise: custom sound to play when player picks up the key.
-------- SPAWNFLAGS --------
FLOATING: the item will float in air, instead of aligning to the floor by falling
---------NOTES----------
Don't use this entity on new maps! Use item_key instead.
*/
void spawnfunc_item_key2(void)
{SELFPARAM();
	self.classname = "item_key";
	self.itemkeys = ITEM_KEY_BIT(0);
	spawnfunc_item_key();
};
