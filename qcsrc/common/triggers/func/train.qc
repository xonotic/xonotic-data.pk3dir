.float train_wait_turning;
void() train_next;
void train_wait()
{SELFPARAM();
	WITH(entity, self, self.enemy, SUB_UseTargets());
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

#ifdef SVQC
float train_send(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_TRAIN);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteString(MSG_ENTITY, self.platmovetype);
		WriteByte(MSG_ENTITY, self.platmovetype_turn);
		WriteByte(MSG_ENTITY, self.spawnflags);

		WriteString(MSG_ENTITY, self.model);

		trigger_common_write(true);

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

void train_use()
{
	self.SUB_NEXTTHINK = self.SUB_LTIME + 1;
	self.SUB_THINK = train_next;
	self.use = func_null; // not again
}

void func_train_find()
{SELFPARAM();
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
	if (self.noise != "")
		precache_sound(self.noise);

	if (self.target == "")
		objerror("func_train without a target");
	if (!self.speed)
		self.speed = 100;

	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;

	if(self.spawnflags & 4)
		self.use = train_use;

	if (self.spawnflags & 2)
	{
		self.platmovetype_turn = true;
		self.view_ofs = '0 0 0'; // don't offset a rotating train, origin works differently now
	}
	else
		self.view_ofs = self.mins;

	// wait for targets to spawn
	InitializeEntity(self, func_train_find, INITPRIO_FINDTARGET);

	self.blocked = generic_plat_blocked;
	if(self.dmg && (self.message == ""))
		self.message = " was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";
	if(self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;
	self.dmgtime2 = time;

	if(!set_platmovetype(self, self.platmovetype))
		return;
	self.platmovetype_start_default = self.platmovetype_start;
	self.platmovetype_end_default = self.platmovetype_end;

	// TODO make a reset function for this one
}
#elif defined(CSQC)
void train_draw(entity this)
{
	//Movetype_Physics_NoMatchServer();
	Movetype_Physics_MatchServer(autocvar_cl_projectiles_sloppy);
}

void ent_train()
{SELFPARAM();
	float sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		self.platmovetype = strzone(ReadString());
		self.platmovetype_turn = ReadByte();
		self.spawnflags = ReadByte();

		self.model = strzone(ReadString());
		_setmodel(self, self.model);

		trigger_common_read(true);

		self.curvetarget = strzone(ReadString());

		self.pos1_x = ReadCoord();
		self.pos1_y = ReadCoord();
		self.pos1_z = ReadCoord();
		self.pos2_x = ReadCoord();
		self.pos2_y = ReadCoord();
		self.pos2_z = ReadCoord();

		self.size_x = ReadCoord();
		self.size_y = ReadCoord();
		self.size_z = ReadCoord();

		self.view_ofs_x = ReadCoord();
		self.view_ofs_y = ReadCoord();
		self.view_ofs_z = ReadCoord();

		self.mangle_x = ReadAngle();
		self.mangle_y = ReadAngle();
		self.mangle_z = ReadAngle();

		self.speed = ReadShort();
		self.height = ReadShort();
		self.lip = ReadByte();
		self.state = ReadByte();
		self.wait = ReadByte();

		self.dmg = ReadShort();
		self.dmgtime = ReadByte();

		self.classname = "func_train";
		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
		self.drawmask = MASK_NORMAL;
		self.draw = train_draw;
		self.entremove = trigger_remove_generic;

		if(set_platmovetype(self, self.platmovetype))
		{
			self.platmovetype_start_default = self.platmovetype_start;
			self.platmovetype_end_default = self.platmovetype_end;
		}

		// everything is set up by the time the train is linked, we shouldn't need this
		//func_train_find();

		// but we will need these
		//self.move_nextthink = self.move_ltime + 0.1;
		//self.move_think = train_next;
		train_next();

		self.move_movetype = MOVETYPE_PUSH;
		self.move_origin = self.origin;
		self.move_angles = self.angles;
		self.move_time = time;
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// TODO: make a reset function for trains
	}
}

#endif
