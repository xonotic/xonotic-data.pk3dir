.float train_wait_turning;
void() train_next;
#ifdef SVQC
void train_use(entity this, entity actor, entity trigger);
#endif
void train_wait()
{SELFPARAM();
	SUB_UseTargets(this.enemy, NULL, NULL);
	self.enemy = world;

	// if turning is enabled, the train will turn toward the next point while waiting
	if(self.platmovetype_turn && !self.train_wait_turning)
	{
		entity targ, cp;
		vector ang;
		targ = find(world, targetname, self.target);
		if((self.spawnflags & 1) && targ.curvetarget)
			cp = find(world, targetname, targ.curvetarget);
		else
			cp = world;

		if(cp) // bezier curves movement
			ang = cp.origin - (self.origin - self.view_ofs); // use the origin of the control point of the next path_corner
		else // linear movement
			ang = targ.origin - (self.origin - self.view_ofs); // use the origin of the next path_corner
		ang = vectoangles(ang);
		ang_x = -ang_x; // flip up / down orientation

		if(self.wait > 0) // slow turning
			SUB_CalcAngleMove(ang, TSPEED_TIME, self.SUB_LTIME - time + self.wait, train_wait);
		else // instant turning
			SUB_CalcAngleMove(ang, TSPEED_TIME, 0.0000001, train_wait);
		self.train_wait_turning = true;
		return;
	}

#ifdef SVQC
	if(self.noise != "")
		stopsoundto(MSG_BROADCAST, self, CH_TRIGGER_SINGLE); // send this as unreliable only, as the train will resume operation shortly anyway
#endif

#ifdef SVQC
	entity tg = find(world, targetname, self.target);
	if(tg.spawnflags & 4)
	{
		self.use = train_use;
		self.SUB_THINK = func_null;
		self.SUB_NEXTTHINK = 0;
	}
	else
#endif
	     if(self.wait < 0 || self.train_wait_turning) // no waiting or we already waited while turning
	{
		self.train_wait_turning = false;
		train_next();
	}
	else
	{
		self.SUB_THINK = train_next;
		self.SUB_NEXTTHINK = self.SUB_LTIME + self.wait;
	}
}

void train_next()
{SELFPARAM();
	entity targ, cp = world;
	vector cp_org = '0 0 0';

	targ = find(world, targetname, self.target);
	self.target = targ.target;
	if (self.spawnflags & 1)
	{
		if(targ.curvetarget)
		{
			cp = find(world, targetname, targ.curvetarget); // get its second target (the control point)
			cp_org = cp.origin - self.view_ofs; // no control point found, assume a straight line to the destination
		}
	}
	if (self.target == "")
		objerror("train_next: no next target");
	self.wait = targ.wait;
	if (!self.wait)
		self.wait = 0.1;

	if(targ.platmovetype)
	{
		// this path_corner contains a movetype overrider, apply it
		self.platmovetype_start = targ.platmovetype_start;
		self.platmovetype_end = targ.platmovetype_end;
	}
	else
	{
		// this path_corner doesn't contain a movetype overrider, use the train's defaults
		self.platmovetype_start = self.platmovetype_start_default;
		self.platmovetype_end = self.platmovetype_end_default;
	}

	if (targ.speed)
	{
		if (cp)
			SUB_CalcMove_Bezier(cp_org, targ.origin - self.view_ofs, TSPEED_LINEAR, targ.speed, train_wait);
		else
			SUB_CalcMove(targ.origin - self.view_ofs, TSPEED_LINEAR, targ.speed, train_wait);
	}
	else
	{
		if (cp)
			SUB_CalcMove_Bezier(cp_org, targ.origin - self.view_ofs, TSPEED_LINEAR, self.speed, train_wait);
		else
			SUB_CalcMove(targ.origin - self.view_ofs, TSPEED_LINEAR, self.speed, train_wait);
	}

	if(self.noise != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_IDLE);
}

REGISTER_NET_LINKED(ENT_CLIENT_TRAIN)

#ifdef SVQC
float train_send(entity to, float sf)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRAIN);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteString(MSG_ENTITY, self.platmovetype);
		WriteByte(MSG_ENTITY, self.platmovetype_turn);
		WriteByte(MSG_ENTITY, self.spawnflags);

		WriteString(MSG_ENTITY, self.model);

		trigger_common_write(self, true);

		WriteString(MSG_ENTITY, self.curvetarget);

		WriteCoord(MSG_ENTITY, self.pos1_x);
		WriteCoord(MSG_ENTITY, self.pos1_y);
		WriteCoord(MSG_ENTITY, self.pos1_z);
		WriteCoord(MSG_ENTITY, self.pos2_x);
		WriteCoord(MSG_ENTITY, self.pos2_y);
		WriteCoord(MSG_ENTITY, self.pos2_z);

		WriteCoord(MSG_ENTITY, self.size_x);
		WriteCoord(MSG_ENTITY, self.size_y);
		WriteCoord(MSG_ENTITY, self.size_z);

		WriteCoord(MSG_ENTITY, self.view_ofs_x);
		WriteCoord(MSG_ENTITY, self.view_ofs_y);
		WriteCoord(MSG_ENTITY, self.view_ofs_z);

		WriteAngle(MSG_ENTITY, self.mangle_x);
		WriteAngle(MSG_ENTITY, self.mangle_y);
		WriteAngle(MSG_ENTITY, self.mangle_z);

		WriteShort(MSG_ENTITY, self.speed);
		WriteShort(MSG_ENTITY, self.height);
		WriteByte(MSG_ENTITY, self.lip);
		WriteByte(MSG_ENTITY, self.state);
		WriteByte(MSG_ENTITY, self.wait);

		WriteShort(MSG_ENTITY, self.dmg);
		WriteByte(MSG_ENTITY, self.dmgtime);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// used on client
	}

	return true;
}

void train_link()
{
	//Net_LinkEntity(self, 0, false, train_send);
}

void train_use(entity this, entity actor, entity trigger)
{
	this.SUB_NEXTTHINK = this.SUB_LTIME + 1;
	this.SUB_THINK = train_next;
	this.use = func_null; // not again
}

void func_train_find(entity this)
{
	entity targ;
	targ = find(world, targetname, self.target);
	self.target = targ.target;
	if (self.target == "")
		objerror("func_train_find: no next target");
	SUB_SETORIGIN(self, targ.origin - self.view_ofs);

	if(!(self.spawnflags & 4))
	{
		self.SUB_NEXTTHINK = self.SUB_LTIME + 1;
		self.SUB_THINK = train_next;
	}

	train_link();
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
		objerror("func_train without a target");
	if (!this.speed)
		this.speed = 100;

	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;

	if(this.spawnflags & 4)
		this.use = train_use;

	if (this.spawnflags & 2)
	{
		this.platmovetype_turn = true;
		this.view_ofs = '0 0 0'; // don't offset a rotating train, origin works differently now
	}
	else
		this.view_ofs = this.mins;

	// wait for targets to spawn
	InitializeEntity(this, func_train_find, INITPRIO_FINDTARGET);

	this.blocked = generic_plat_blocked;
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

		this.pos1_x = ReadCoord();
		this.pos1_y = ReadCoord();
		this.pos1_z = ReadCoord();
		this.pos2_x = ReadCoord();
		this.pos2_y = ReadCoord();
		this.pos2_z = ReadCoord();

		this.size_x = ReadCoord();
		this.size_y = ReadCoord();
		this.size_z = ReadCoord();

		this.view_ofs_x = ReadCoord();
		this.view_ofs_y = ReadCoord();
		this.view_ofs_z = ReadCoord();

		this.mangle_x = ReadAngle();
		this.mangle_y = ReadAngle();
		this.mangle_z = ReadAngle();

		this.speed = ReadShort();
		this.height = ReadShort();
		this.lip = ReadByte();
		this.state = ReadByte();
		this.wait = ReadByte();

		this.dmg = ReadShort();
		this.dmgtime = ReadByte();

		this.classname = "func_train";
		this.solid = SOLID_BSP;
		this.movetype = MOVETYPE_PUSH;
		this.drawmask = MASK_NORMAL;
		this.draw = train_draw;
		this.entremove = trigger_remove_generic;

		if(set_platmovetype(this, this.platmovetype))
		{
			this.platmovetype_start_default = this.platmovetype_start;
			this.platmovetype_end_default = this.platmovetype_end;
		}

		// everything is set up by the time the train is linked, we shouldn't need this
		//func_train_find();

		// but we will need these
		//this.move_nextthink = this.move_ltime + 0.1;
		//this.move_think = train_next;
		WITHSELF(this, train_next());

		this.move_movetype = MOVETYPE_PUSH;
		this.move_origin = this.origin;
		this.move_angles = this.angles;
		this.move_time = time;
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// TODO: make a reset function for trains
	}

	return true;
}

#endif
