#include "keys.qh"

#ifdef CSQC
bool item_keys_usekey(entity l, entity p)
{
	int valid = (l.itemkeys & p.itemkeys); // TODO: itemkeys isn't networked or anything!
	l.itemkeys &= ~valid; // only some of the needed keys were given
	return valid != 0;
}
#endif

#ifdef SVQC
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
	int valid = l.itemkeys & p.itemkeys;

	if (!valid) {
		// player has none of the needed keys
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
	if ((keylist & (keylist-1)) == 0)
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
void item_key_touch(entity this, entity toucher)
{
	if (!IS_PLAYER(toucher))
		return;

	// player already picked up this key
	if (PS(toucher).itemkeys & this.itemkeys)
		return;

	PS(toucher).itemkeys |= this.itemkeys;
	play2(toucher, this.noise);

	centerprint(toucher, this.message);

	string oldmsg = this.message;
	this.message = "";
	SUB_UseTargets(this, toucher, toucher); // TODO: should we be using toucher for the trigger here?
	this.message = oldmsg;
}

/**
 * Spawn a key with given model, key code and color.
 */
void spawn_item_key(entity this)
{
	precache_model(this.model);

	if (this.spawnflags & 1) // FLOATING
		this.noalign = 1;

	if (this.noalign)
		set_movetype(this, MOVETYPE_NONE);
	else
		set_movetype(this, MOVETYPE_TOSS);

	precache_sound(this.noise);

	this.mdl = this.model;
	this.effects = EF_LOWPRECISION;
	_setmodel(this, this.model);
	//setsize(this, '-16 -16 -24', '16 16 32');
	setorigin(this, this.origin + '0 0 32');
	setsize(this, '-16 -16 -56', '16 16 0');
	this.modelflags |= MF_ROTATE;
	this.solid = SOLID_TRIGGER;

	if (!this.noalign)
	{
		// first nudge it off the floor a little bit to avoid math errors
		setorigin(this, this.origin + '0 0 1');
		// note droptofloor returns false if stuck/or would fall too far
		droptofloor(this);
	}

	settouch(this, item_key_touch);
}


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
spawnfunc(item_key)
{
	string _netname;
	vector _colormod;

	// reject this entity if more than one key was set!
	if (this.itemkeys>0 && (this.itemkeys & (this.itemkeys-1)) != 0) {
		objerror(this, "item_key.itemkeys must contain only 1 bit set specifying the key it represents!");
		delete(this);
		return;
	}

	// find default netname and colormod
	switch(this.itemkeys) {
	case BIT(0):
		_netname = "GOLD key";
		_colormod = '1 0.9 0';
		break;

	case BIT(1):
		_netname = "SILVER key";
		_colormod = '0.9 0.9 0.9';
		break;

	case BIT(2):
		_netname = "BRONZE key";
		_colormod = '0.6 0.25 0';
		break;

	case BIT(3):
		_netname = "RED keycard";
		_colormod = '0.9 0 0';
		break;

	case BIT(4):
		_netname = "BLUE keycard";
		_colormod = '0 0 0.9';
		break;

	case BIT(5):
		_netname = "GREEN keycard";
		_colormod = '0 0.9 0';
		break;

	default:
		_netname = "FLUFFY PINK keycard";
		_colormod = '1 1 1';

		if (this.netname == "") {
			objerror(this, "item_key doesn't have a default name for this key and a custom one was not specified!");
			delete(this);
			return;
		}
		break;

	}

	// find default model
	string _model = string_null;
	if (this.itemkeys <= ITEM_KEY_BIT(2)) {
		_model = "models/keys/key.md3";
	} else if (this.itemkeys >= ITEM_KEY_BIT(3) && this.itemkeys <= ITEM_KEY_BIT(5)) {
		_model = "models/keys/key.md3"; // FIXME: replace it by a keycard model!
	} else if (this.model == "") {
		objerror(this, "item_key doesn't have a default model for this key and a custom one was not specified!");
		delete(this);
		return;
	}

	// set defailt netname
	if (this.netname == "")
		this.netname = _netname;

	// set default colormod
	if (!this.colormod)
		this.colormod = _colormod;

	// set default model
	if (this.model == "")
		this.model = _model;

	// set default pickup message
	if (this.message == "")
		this.message = strzone(strcat("You've picked up the ", this.netname, "!"));

	if (this.noise == "")
		this.noise = strzone(SND(ITEMPICKUP));

	// save the name for later
	item_keys_names[lowestbit(this.itemkeys)] = this.netname;

	// put the key on the map
	spawn_item_key(this);
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
spawnfunc(item_key1)
{
	this.classname = "item_key";
	this.itemkeys = ITEM_KEY_BIT(1);
	spawnfunc_item_key(this);
}

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
spawnfunc(item_key2)
{
	this.classname = "item_key";
	this.itemkeys = ITEM_KEY_BIT(0);
	spawnfunc_item_key(this);
}

#endif
