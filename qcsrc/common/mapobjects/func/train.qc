#include "train.qh"
.float train_wait_turning;
.entity future_target;
void train_next(entity this);
#ifdef SVQC
void train_use(entity this, entity actor, entity trigger);
#endif
void train_wait(entity this)
{
	SUB_UseTargets(this.enemy, NULL, NULL);
	this.enemy = NULL;

	// if turning is enabled, the train will turn toward the next point while waiting
	if(this.platmovetype_turn && !this.train_wait_turning)
	{
		entity targ, cp;
		vector ang;
		targ = this.future_target;
		if((this.spawnflags & TRAIN_CURVE) && targ.curvetarget)
			cp = find(NULL, targetname, targ.curvetarget);
		else
			cp = NULL;

		if(cp) // bezier curves movement
			ang = cp.origin - (this.origin - this.view_ofs); // use the origin of the control point of the next path_corner
		else // linear movement
			ang = targ.origin - (this.origin - this.view_ofs); // use the origin of the next path_corner
		ang = vectoangles(ang);
		ang_x = -ang_x; // flip up / down orientation

		if(this.wait > 0) // slow turning
			SUB_CalcAngleMove(this, ang, TSPEED_TIME, this.ltime - time + this.wait, train_wait);
		else // instant turning
			SUB_CalcAngleMove(this, ang, TSPEED_TIME, 0.0000001, train_wait);
		this.train_wait_turning = true;
		return;
	}

#ifdef SVQC
	if(this.noise != "")
		stopsoundto(MSG_BROADCAST, this, CH_TRIGGER_SINGLE); // send this as unreliable only, as the train will resume operation shortly anyway
#endif

#ifdef SVQC
	entity tg = this.future_target;
	if(tg.spawnflags & TRAIN_NEEDACTIVATION)
	{
		this.use = train_use;
		setthink(this, func_null);
		this.nextthink = 0;
	}
	else
#endif
	     if(this.wait < 0 || this.train_wait_turning) // no waiting or we already waited while turning
	{
		this.train_wait_turning = false;
		train_next(this);
	}
	else
	{
		setthink(this, train_next);
		this.nextthink = this.ltime + this.wait;
	}
}

entity train_next_find(entity this)
{
	if(this.target_random)
	{
		RandomSelection_Init();
		for(entity t = NULL; (t = find(t, targetname, this.target));)
		{
			RandomSelection_AddEnt(t, 1, 0);
		}
		return RandomSelection_chosen_ent;
	}
	else
	{
		return find(NULL, targetname, this.target);
	}
}

void train_next(entity this)
{
	entity targ = NULL, cp = NULL;
	vector cp_org = '0 0 0';

	targ = this.future_target;

	this.target = targ.target;
	this.target_random = targ.target_random;
	this.future_target = train_next_find(targ);

	if (this.spawnflags & TRAIN_CURVE)
	{
		if(targ.curvetarget)
		{
			cp = find(NULL, targetname, targ.curvetarget); // get its second target (the control point)
			cp_org = cp.origin - this.view_ofs; // no control point found, assume a straight line to the destination
		}
	}
	if (this.target == "")
		objerror(this, "train_next: no next target");
	this.wait = targ.wait;
	if (!this.wait)
		this.wait = 0.1;

	if(targ.platmovetype)
	{
		// this path_corner contains a movetype overrider, apply it
		this.platmovetype_start = targ.platmovetype_start;
		this.platmovetype_end = targ.platmovetype_end;
	}
	else
	{
		// this path_corner doesn't contain a movetype overrider, use the train's defaults
		this.platmovetype_start = this.platmovetype_start_default;
		this.platmovetype_end = this.platmovetype_end_default;
	}

	if (targ.speed)
	{
		if (cp)
			SUB_CalcMove_Bezier(this, cp_org, targ.origin - this.view_ofs, TSPEED_LINEAR, targ.speed, train_wait);
		else
			SUB_CalcMove(this, targ.origin - this.view_ofs, TSPEED_LINEAR, targ.speed, train_wait);
	}
	else
	{
		if (cp)
			SUB_CalcMove_Bezier(this, cp_org, targ.origin - this.view_ofs, TSPEED_LINEAR, this.speed, train_wait);
		else
			SUB_CalcMove(this, targ.origin - this.view_ofs, TSPEED_LINEAR, this.speed, train_wait);
	}

	if(this.noise != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE);
}

REGISTER_NET_LINKED(ENT_CLIENT_TRAIN)

#ifdef SVQC
float train_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRAIN);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteString(MSG_ENTITY, this.platmovetype);
		WriteByte(MSG_ENTITY, this.platmovetype_turn);
		WriteByte(MSG_ENTITY, this.spawnflags);

		WriteString(MSG_ENTITY, this.model);

		trigger_common_write(this, true);

		WriteString(MSG_ENTITY, this.curvetarget);

		WriteVector(MSG_ENTITY, this.pos1);
		WriteVector(MSG_ENTITY, this.pos2);

		WriteVector(MSG_ENTITY, this.size);

		WriteVector(MSG_ENTITY, this.view_ofs);

		WriteAngleVector(MSG_ENTITY, this.mangle);

		WriteShort(MSG_ENTITY, this.speed);
		WriteShort(MSG_ENTITY, this.height);
		WriteByte(MSG_ENTITY, this.lip);
		WriteByte(MSG_ENTITY, this.state);
		WriteByte(MSG_ENTITY, this.wait);

		WriteShort(MSG_ENTITY, this.dmg);
		WriteByte(MSG_ENTITY, this.dmgtime);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// used on client
	}

	return true;
}

void train_link(entity this)
{
	//Net_LinkEntity(this, 0, false, train_send);
}

void train_use(entity this, entity actor, entity trigger)
{
	this.nextthink = this.ltime + 1;
	setthink(this, train_next);
	this.use = func_null; // not again, next target can set it again if needed
	if(trigger.target2 && trigger.target2 != "")
		this.future_target = find(NULL, targetname, trigger.target2);
}

void func_train_find(entity this)
{
	entity targ = train_next_find(this);
	this.target = targ.target;
	this.target_random = targ.target_random;
	// save the future target for later
	this.future_target = train_next_find(targ);
	if (this.target == "")
		objerror(this, "func_train_find: no next target");
	setorigin(this, targ.origin - this.view_ofs);

	if(!(this.spawnflags & TRAIN_NEEDACTIVATION))
	{
		this.nextthink = this.ltime + 1;
		setthink(this, train_next);
	}

	train_link(this);
}

#endif

/*QUAKED spawnfunc_func_train (0 .5 .8) ?
Ridable platform, targets spawnfunc_path_corner path to follow.
speed : speed the train moves (can be overridden by each spawnfunc_path_corner)
target : targetname of first spawnfunc_path_corner (starts here)
*/
#ifdef SVQC
spawnfunc(func_train)
{
	if (this.noise != "")
		precache_sound(this.noise);

	if (this.target == "")
		objerror(this, "func_train without a target");
	if (!this.speed)
		this.speed = 100;

	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;

	if(this.spawnflags & TRAIN_NEEDACTIVATION)
		this.use = train_use;

	if (this.spawnflags & TRAIN_TURN)
	{
		this.platmovetype_turn = true;
		this.view_ofs = '0 0 0'; // don't offset a rotating train, origin works differently now
	}
	else
		this.view_ofs = this.mins;

	// wait for targets to spawn
	InitializeEntity(this, func_train_find, INITPRIO_FINDTARGET);

	setblocked(this, generic_plat_blocked);
	if(this.dmg && (this.message == ""))
		this.message = " was squished";
    if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	if(!set_platmovetype(this, this.platmovetype))
		return;
	this.platmovetype_start_default = this.platmovetype_start;
	this.platmovetype_end_default = this.platmovetype_end;

	// TODO make a reset function for this one
}
#elif defined(CSQC)
void train_draw(entity this)
{
	//Movetype_Physics_NoMatchServer();
	Movetype_Physics_MatchServer(this, autocvar_cl_projectiles_sloppy);
}

NET_HANDLE(ENT_CLIENT_TRAIN, bool isnew)
{
	float sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		this.platmovetype = strzone(ReadString());
		this.platmovetype_turn = ReadByte();
		this.spawnflags = ReadByte();

		this.model = strzone(ReadString());
		_setmodel(this, this.model);

		trigger_common_read(this, true);

		this.curvetarget = strzone(ReadString());

		this.pos1 = ReadVector();
		this.pos2 = ReadVector();

		this.size = ReadVector();

		this.view_ofs = ReadVector();

		this.mangle = ReadAngleVector();

		this.speed = ReadShort();
		this.height = ReadShort();
		this.lip = ReadByte();
		this.state = ReadByte();
		this.wait = ReadByte();

		this.dmg = ReadShort();
		this.dmgtime = ReadByte();

		this.classname = "func_train";
		this.solid = SOLID_BSP;
		set_movetype(this, MOVETYPE_PUSH);
		this.drawmask = MASK_NORMAL;
		this.draw = train_draw;
		if (isnew) IL_PUSH(g_drawables, this);
		this.entremove = trigger_remove_generic;

		if(set_platmovetype(this, this.platmovetype))
		{
			this.platmovetype_start_default = this.platmovetype_start;
			this.platmovetype_end_default = this.platmovetype_end;
		}

		// everything is set up by the time the train is linked, we shouldn't need this
		//func_train_find();

		// but we will need these
		train_next(this);

		set_movetype(this, MOVETYPE_PUSH);
		this.move_time = time;
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// TODO: make a reset function for trains
	}

	return true;
}

#endif
