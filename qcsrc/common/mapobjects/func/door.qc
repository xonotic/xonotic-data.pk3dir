#include "door.qh"
#include "door_rotating.qh"
/*

Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.

Door.owner is the master door.  If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.

*/


/*
=============================================================================

THINK FUNCTIONS

=============================================================================
*/

void door_go_down(entity this);
void door_go_up(entity this, entity actor, entity trigger);

void door_blocked(entity this, entity blocker)
{
	bool reverse = false;
	if((this.spawnflags & DOOR_CRUSH)
		&& !Q3COMPAT_COMMON
#ifdef SVQC
		&& (blocker.takedamage != DAMAGE_NO)
#elif defined(CSQC)
		&& !IS_DEAD(blocker)
#endif
	)
	{ // KIll Kill Kill!!
#ifdef SVQC
		Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
#endif
	}
	else
	{
#ifdef SVQC
		if (this.dmg && blocker.takedamage != DAMAGE_NO)    // Shall we bite?
			Damage (blocker, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
#endif

		// don't change direction for dead or dying stuff
		if (!IS_DEAD(blocker)
#ifdef SVQC
			&& blocker.takedamage != DAMAGE_NO
#endif
			&& this.wait >= 0
			&& !(Q3COMPAT_COMMON && (this.spawnflags & Q3_DOOR_CRUSHER))
		)
		{
			if (this.state == STATE_DOWN)
			{
				if (this.classname == "door")
					door_go_up(this, NULL, NULL);
				else
					door_rotating_go_up(this, blocker);
			}
			else
			{
				if (this.classname == "door")
					door_go_down(this);
				else
					door_rotating_go_down(this);
			}
			reverse = true;
		}
#ifdef SVQC
		else
		{
			//gib dying stuff just to make sure
			if (this.dmg && blocker.takedamage != DAMAGE_NO && IS_DEAD(blocker))    // Shall we bite?
				Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
		}
#endif
	}
	// if we didn't change direction and are using a non-linear movement controller, we must pause it
	if (!reverse && this.classname == "door" && this.move_controller)
		SUB_CalcMovePause(this);
}

void door_hit_top(entity this)
{
	if (this.noise1 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.state = STATE_TOP;
	if (this.spawnflags & DOOR_TOGGLE)
		return;		// don't come down automatically
	if (this.classname == "door")
	{
		setthink(this, door_go_down);
	} else
	{
		setthink(this, door_rotating_go_down);
	}
	this.nextthink = this.ltime + this.wait;
}

void door_hit_bottom(entity this)
{
	if (this.noise1 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.state = STATE_BOTTOM;
}

void door_go_down(entity this)
{
	if (this.noise2 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	if (this.max_health)
	{
		this.takedamage = DAMAGE_YES;
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
	}

	this.state = STATE_DOWN;
	SUB_CalcMove (this, this.pos1, TSPEED_LINEAR, this.speed, door_hit_bottom);
}

void door_go_up(entity this, entity actor, entity trigger)
{
	if (this.state == STATE_UP)
		return;		// already going up

	if (this.state == STATE_TOP)
	{	// reset top wait time
		this.nextthink = this.ltime + this.wait;
		return;
	}

	if (this.noise2 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	this.state = STATE_UP;
	SUB_CalcMove (this, this.pos2, TSPEED_LINEAR, this.speed, door_hit_top);

	string oldmessage;
	oldmessage = this.message;
	this.message = "";
	SUB_UseTargets(this, actor, trigger);
	this.message = oldmessage;
}


/*
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
*/

bool door_check_keys(entity door, entity player)
{
	if(door.owner)
		door = door.owner;

	// no key needed
	if(!door.itemkeys)
		return true;

	// this door require a key
	// only a player can have a key
	if(!IS_PLAYER(player))
		return false;

	entity store = player;
#ifdef SVQC
	store = PS(player);
#endif
	int valid = (door.itemkeys & store.itemkeys);
	door.itemkeys &= ~valid; // only some of the needed keys were given

	if(!door.itemkeys)
	{
#ifdef SVQC
		play2(player, door.noise);
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_DOOR_UNLOCKED);
#endif
		return true;
	}

	if(!valid)
	{
#ifdef SVQC
		if(player.key_door_messagetime <= time)
		{
			play2(player, door.noise3);
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_DOOR_LOCKED_NEED, item_keys_keylist(door.itemkeys));
			player.key_door_messagetime = time + 2;
		}
#endif
		return false;
	}

	// door needs keys the player doesn't have
#ifdef SVQC
	if(player.key_door_messagetime <= time)
	{
		play2(player, door.noise3);
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_DOOR_LOCKED_ALSONEED, item_keys_keylist(door.itemkeys));
		player.key_door_messagetime = time + 2;
	}
#endif

	return false;
}

void door_use(entity this, entity actor, entity trigger)
{
	//dprint("door_use (model: ");dprint(this.model);dprint(")\n");

	if (!this.owner)
		return;
	if (this.owner.active != ACTIVE_ACTIVE)
		return;
	this = this.owner;

	if (this.spawnflags & DOOR_TOGGLE)
	{
		if (this.state == STATE_UP || this.state == STATE_TOP)
		{
			entity e = this;
			do {
				if (e.classname == "door") {
					door_go_down(e);
				} else {
					door_rotating_go_down(e);
				}
				e = e.enemy;
			} while ((e != this) && (e != NULL));
			return;
		}
	}

// trigger all paired doors
	entity e = this;
	do {
		if (e.classname == "door") {
			door_go_up(e, actor, trigger);
		} else {
			// if the BIDIR spawnflag (==2) is set and the trigger has set trigger_reverse, reverse the opening direction
			if ((e.spawnflags & DOOR_ROTATING_BIDIR) && trigger.trigger_reverse!=0 && e.lip != 666 && e.state == STATE_BOTTOM) {
				e.lip = 666; // e.lip is used to remember reverse opening direction for door_rotating
				e.pos2 = '0 0 0' - e.pos2;
			}
			// if BIDIR_IN_DOWN (==8) is set, prevent the door from reoping during closing if it is triggered from the wrong side
			if (!((e.spawnflags & DOOR_ROTATING_BIDIR) &&  (e.spawnflags & DOOR_ROTATING_BIDIR_IN_DOWN) && e.state == STATE_DOWN
				&& (((e.lip == 666) && (trigger.trigger_reverse == 0)) || ((e.lip != 666) && (trigger.trigger_reverse != 0)))))
			{
				door_rotating_go_up(e, trigger);
			}
		}
		e = e.enemy;
	} while ((e != this) && (e != NULL));
}

void door_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(this.spawnflags & NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	TakeResource(this, RES_HEALTH, damage);

	if (this.itemkeys)
	{
		// don't allow opening doors through damage if keys are required
		return;
	}

	if (GetResource(this, RES_HEALTH) <= 0)
	{
		SetResourceExplicit(this.owner, RES_HEALTH, this.owner.max_health);
		this.owner.takedamage = DAMAGE_NO;	// will be reset upon return
		door_use(this.owner, attacker, NULL);
	}
}

.float door_finished;

/*
================
door_touch

Prints messages
================
*/

void door_touch(entity this, entity toucher)
{
	if (!IS_PLAYER(toucher))
		return;
	if (this.owner.door_finished > time)
		return;
#ifdef SVQC
	if (this.owner.active != ACTIVE_ACTIVE)
		return;
#endif

	this.owner.door_finished = time + 2;

#ifdef SVQC
	if (!(this.owner.dmg) && (this.owner.message != ""))
	{
		if (IS_CLIENT(toucher))
			centerprint(toucher, this.owner.message);
		play2(toucher, this.owner.noise);
	}
#endif
}

void door_generic_plat_blocked(entity this, entity blocker)
{
	if((this.spawnflags & DOOR_CRUSH) && (blocker.takedamage != DAMAGE_NO)) { // Kill Kill Kill!!
#ifdef SVQC
		Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
#endif
	}
	else
	{

#ifdef SVQC
		if((this.dmg) && (blocker.takedamage == DAMAGE_YES))    // Shall we bite?
			Damage (blocker, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
#endif

		 //Dont chamge direction for dead or dying stuff
		if(IS_DEAD(blocker) && (blocker.takedamage == DAMAGE_NO))
		{
			if (this.wait >= 0)
			{
				if (this.state == STATE_DOWN)
					door_rotating_go_up (this, blocker);
				else
					door_rotating_go_down (this);
			}
		}
#ifdef SVQC
		else
		{
			//gib dying stuff just to make sure
			if((this.dmg) && (blocker.takedamage != DAMAGE_NO))    // Shall we bite?
				Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
		}
#endif
	}
}

/*
=========================================
door trigger

Spawned if a door lacks a real activator
=========================================
*/

void door_trigger_touch(entity this, entity toucher)
{
	if (GetResource(toucher, RES_HEALTH) < 1)
#ifdef SVQC
		if (!((toucher.iscreature || (toucher.flags & FL_PROJECTILE)) && !IS_DEAD(toucher)))
#elif defined(CSQC)
		if(!((IS_CLIENT(toucher) || toucher.classname == "ENT_CLIENT_PROJECTILE") && !IS_DEAD(toucher)))
#endif
			return;
#ifdef SVQC
	if (this.owner.active != ACTIVE_ACTIVE)
		return;
#endif

	if (this.owner.state == STATE_UP)
		return;

	// check if door is locked
	if (!door_check_keys(this, toucher))
		return;

	if (this.owner.state == STATE_TOP)
	{
		if (this.owner.nextthink < this.owner.ltime + this.owner.wait)
		{
			entity e = this.owner;
			do {
				e.nextthink = e.ltime + e.wait;
				e = e.enemy;
			} while (e != this.owner);
		}
		return;
	}

	door_use(this.owner, toucher, NULL);
}

void door_spawnfield(entity this, vector fmins, vector fmaxs)
{
	entity	trigger;
	vector	t1 = fmins, t2 = fmaxs;

	trigger = new(doortriggerfield);
	set_movetype(trigger, MOVETYPE_NONE);
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = this;
#ifdef SVQC
	settouch(trigger, door_trigger_touch);
#endif

	setsize (trigger, t1 - '60 60 8', t2 + '60 60 8');
}


/*
=============
LinkDoors


=============
*/

entity LinkDoors_nextent(entity cur, entity near, entity pass)
{
	while ((cur = find(cur, classname, pass.classname))
	&& ((!Q3COMPAT_COMMON && (cur.spawnflags & DOOR_DONT_LINK)) || cur.enemy))
	{
	}
	return cur;
}

bool LinkDoors_isconnected(entity e1, entity e2, entity pass)
{
	if(Q3COMPAT_COMMON)
		return e1.team == e2.team;

	float DELTA = 4;
	if((e1.absmin_x > e2.absmax_x + DELTA)
	|| (e1.absmin_y > e2.absmax_y + DELTA)
	|| (e1.absmin_z > e2.absmax_z + DELTA)
	|| (e2.absmin_x > e1.absmax_x + DELTA)
	|| (e2.absmin_y > e1.absmax_y + DELTA)
	|| (e2.absmin_z > e1.absmax_z + DELTA)
	) { return false; }
	return true;
}

#ifdef SVQC
void door_link();
#endif
void LinkDoors(entity this)
{
	entity	t;
	vector	cmins, cmaxs;

#ifdef SVQC
	door_link();
#endif

	if (this.enemy)
		return;		// already linked by another door

	// Q3 door linking is done for teamed doors only and is not affected by spawnflags or bmodel proximity
	if ((!Q3COMPAT_COMMON && (this.spawnflags & DOOR_DONT_LINK)) || (Q3COMPAT_COMMON && !this.team))
	{
		this.owner = this.enemy = this;

		if (GetResource(this, RES_HEALTH))
			return;
		if(this.targetname && this.targetname != "")
			return;
		if (this.items)
			return;

		door_spawnfield(this, this.absmin, this.absmax);

		return;		// don't want to link this door
	}

	FindConnectedComponent(this, enemy, LinkDoors_nextent, LinkDoors_isconnected, this);

	// set owner, and make a loop of the chain
	LOG_TRACE("LinkDoors: linking doors:");
	for(t = this; ; t = t.enemy)
	{
		LOG_TRACE(" ", etos(t));
		t.owner = this;
		if(t.enemy == NULL)
		{
			t.enemy = this;
			break;
		}
	}
	LOG_TRACE("");

	// collect health, targetname, message, size
	cmins = this.absmin;
	cmaxs = this.absmax;
	for(t = this; ; t = t.enemy)
	{
		if(GetResource(t, RES_HEALTH) && !GetResource(this, RES_HEALTH))
			SetResourceExplicit(this, RES_HEALTH, GetResource(t, RES_HEALTH));
		if((t.targetname != "") && (this.targetname == ""))
			this.targetname = t.targetname;
		if((t.message != "") && (this.message == ""))
			this.message = t.message;
		if (t.absmin_x < cmins_x)
			cmins_x = t.absmin_x;
		if (t.absmin_y < cmins_y)
			cmins_y = t.absmin_y;
		if (t.absmin_z < cmins_z)
			cmins_z = t.absmin_z;
		if (t.absmax_x > cmaxs_x)
			cmaxs_x = t.absmax_x;
		if (t.absmax_y > cmaxs_y)
			cmaxs_y = t.absmax_y;
		if (t.absmax_z > cmaxs_z)
			cmaxs_z = t.absmax_z;
		if(t.enemy == this)
			break;
	}

	// distribute health, targetname, message
	for(t = this; t; t = t.enemy)
	{
		SetResourceExplicit(t, RES_HEALTH, GetResource(this, RES_HEALTH));
		t.targetname = this.targetname;
		t.message = this.message;
		if(t.enemy == this)
			break;
	}

	// shootable, or triggered doors just needed the owner/enemy links,
	// they don't spawn a field

	if (GetResource(this, RES_HEALTH))
		return;
	if(this.targetname && this.targetname != "")
		return;
	if (this.items)
		return;

	door_spawnfield(this, cmins, cmaxs);
}

REGISTER_NET_LINKED(ENT_CLIENT_DOOR)

#ifdef SVQC
/*QUAKED spawnfunc_func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).

GOLD_KEY causes the door to open only if the activator holds a gold key.

SILVER_KEY causes the door to open only if the activator holds a silver key.

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"lip"		lip remaining at end of move (8 default)
"dmg"		damage to inflict when blocked (0 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
FIXME: only one sound set available at the time being

*/

float door_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_DOOR);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteString(MSG_ENTITY, this.classname);
		WriteByte(MSG_ENTITY, this.spawnflags);

		WriteString(MSG_ENTITY, this.model);

		trigger_common_write(this, true);

		WriteVector(MSG_ENTITY, this.pos1);
		WriteVector(MSG_ENTITY, this.pos2);

		WriteVector(MSG_ENTITY, this.size);

		WriteShort(MSG_ENTITY, this.wait);
		WriteShort(MSG_ENTITY, this.speed);
		WriteByte(MSG_ENTITY, this.lip);
		WriteByte(MSG_ENTITY, this.state);
		WriteCoord(MSG_ENTITY, this.ltime);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// client makes use of this, we do not
	}

	if(sf & SF_TRIGGER_UPDATE)
	{
		WriteVector(MSG_ENTITY, this.origin);

		WriteVector(MSG_ENTITY, this.pos1);
		WriteVector(MSG_ENTITY, this.pos2);
	}

	return true;
}

void door_link()
{
	//Net_LinkEntity(this, false, 0, door_send);
}

void door_init_keys(entity this)
{
	// Quake 1 and QL keys compatibility
	if (this.spawnflags & SPAWNFLAGS_GOLD_KEY)
		this.itemkeys |= BIT(0);
	if (this.spawnflags & SPAWNFLAGS_SILVER_KEY)
		this.itemkeys |= BIT(1);
}
#endif

void door_init_startopen(entity this)
{
	setorigin(this, this.pos2);
	this.pos2 = this.pos1;
	this.pos1 = this.origin;

#ifdef SVQC
	this.SendFlags |= SF_TRIGGER_UPDATE;
#endif
}

void door_reset(entity this)
{
	setorigin(this, this.pos1);
	this.velocity = '0 0 0';
	this.state = STATE_BOTTOM;
	this.active = ACTIVE_ACTIVE;
	setthink(this, func_null);
	this.nextthink = 0;

#ifdef SVQC
	this.SendFlags |= SF_TRIGGER_RESET;
	door_init_keys(this);
#endif
}

#ifdef SVQC

// common code for func_door and func_door_rotating spawnfuncs
void door_init_shared(entity this)
{
	this.max_health = GetResource(this, RES_HEALTH);

	// unlock sound
	if(this.noise == "")
	{
		this.noise = "misc/talk.wav";
	}
	// door still locked sound
	if(this.noise3 == "")
	{
		this.noise3 = "misc/talk.wav";
	}
	precache_sound(this.noise);
	precache_sound(this.noise3);

	if((this.dmg || (this.spawnflags & DOOR_CRUSH)) && (this.message == ""))
	{
		this.message = "was squished";
	}
	if((this.dmg || (this.spawnflags & DOOR_CRUSH)) && (this.message2 == ""))
	{
		this.message2 = "was squished by";
	}

	// TODO: other soundpacks
	if (this.sounds > 0 || q3compat)
	{
		// Doors in Q3 always have sounds (they're hard coded)
		this.noise2 = "plats/medplat1.wav";
		this.noise1 = "plats/medplat2.wav";
	}

	if (q3compat)
	{
		// CPMA adds these fields for overriding the Q3 default sounds
		string s = GetField_fullspawndata(this, "sound_start", true);
		string e = GetField_fullspawndata(this, "sound_end", true);

		// Quake Live adds these ones, because of course it had to be different from CPMA
		if (!s) s = GetField_fullspawndata(this, "startsound", true);
		if (!e) e = GetField_fullspawndata(this, "endsound", true);

		if (s)
			this.noise2 = strzone(s);
		else
		{
			// PK3s supporting Q3A sometimes include custom sounds at Q3 default paths
			s = "sound/movers/doors/dr1_strt.wav";
			if (FindFileInMapPack(s))
				this.noise2 = s;
		}

		if (e)
			this.noise1 = strzone(e);
		else
		{
			e = "sound/movers/doors/dr1_end.wav";
			if (FindFileInMapPack(e))
				this.noise1 = e;
		}
	}

	// sound when door stops moving
	if(this.noise1 && this.noise1 != "")
	{
		precache_sound(this.noise1);
	}
	// sound when door is moving
	if(this.noise2 && this.noise2 != "")
	{
		precache_sound(this.noise2);
	}

	if(autocvar_sv_doors_always_open)
	{
		this.wait = -1;
	}
	else if (!this.wait)
	{
		this.wait = q3compat ? 2 : 3;
	}

	if (!this.lip)
	{
		this.lip = 8;
	}

	this.state = STATE_BOTTOM;

	if (GetResource(this, RES_HEALTH) || (q3compat && this.targetname == ""))
	{
		//this.canteamdamage = true; // TODO
		this.takedamage = DAMAGE_YES;
		this.event_damage = door_damage;
	}

	if (this.items)
	{
		this.wait = -1;
	}
}

// spawnflags require key (for now only func_door)
spawnfunc(func_door)
{
	door_init_keys(this);

	SetMovedir(this);

	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;
	this.classname = "door";

	setblocked(this, door_blocked);
	this.use = door_use;
	this.active = ACTIVE_ACTIVE;

	if(this.spawnflags & DOOR_NONSOLID)
		this.solid = SOLID_NOT;

	// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
	// but spawn in the open position
	// the tuba door on xoylent requires the delayed init
	if (this.spawnflags & DOOR_START_OPEN)
		InitializeEntity(this, door_init_startopen, INITPRIO_SETLOCATION);

	door_init_shared(this);

	this.pos1 = this.origin;
	vector absmovedir;
	absmovedir.x = fabs(this.movedir.x);
	absmovedir.y = fabs(this.movedir.y);
	absmovedir.z = fabs(this.movedir.z);
	this.pos2 = this.pos1 + this.movedir * (absmovedir * this.size - this.lip);

	if(autocvar_sv_doors_always_open)
	{
		this.speed = max(750, this.speed);
	}
	else if (!this.speed)
	{
		if (q3compat)
			this.speed = 400;
		else
			this.speed = 100;
	}

	if (q3compat)
	{
		if (!this.dmg)
			this.dmg = 2;

		if (!this.team)
		{
			string t = GetField_fullspawndata(this, "team", false);
			// bones_was_here: same hack as used to support teamed items on Q3 maps
			if (t) this.team = crc16(false, t);
		}
	}

	settouch(this, door_touch);

	// LinkDoors can't be done until all of the doors have been spawned, so
	// the sizes can be detected properly.
	InitializeEntity(this, LinkDoors, INITPRIO_LINKDOORS);

	this.reset = door_reset;
}

#elif defined(CSQC)

NET_HANDLE(ENT_CLIENT_DOOR, bool isnew)
{
	int sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		this.classname = strzone(ReadString());
		this.spawnflags = ReadByte();

		this.mdl = strzone(ReadString());
		_setmodel(this, this.mdl);

		trigger_common_read(this, true);

		this.pos1 = ReadVector();
		this.pos2 = ReadVector();

		this.size = ReadVector();

		this.wait = ReadShort();
		this.speed = ReadShort();
		this.lip = ReadByte();
		this.state = ReadByte();
		this.ltime = ReadCoord();

		this.solid = SOLID_BSP;
		set_movetype(this, MOVETYPE_PUSH);
		this.use = door_use;

		LinkDoors(this);

		if(this.spawnflags & DOOR_START_OPEN)
			door_init_startopen(this);

		this.move_time = time;
		set_movetype(this, MOVETYPE_PUSH);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		door_reset(this);
	}

	if(sf & SF_TRIGGER_UPDATE)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);

		this.pos1 = ReadVector();
		this.pos2 = ReadVector();
	}
	return true;
}

#endif
