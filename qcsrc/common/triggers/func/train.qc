#ifdef SVQC
.float train_wait_turning;
void() train_next;
void train_wait()
{
	entity oldself;
	oldself = self;
	self = self.enemy;
	SUB_UseTargets();
	self = oldself;
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
			SUB_CalcAngleMove(ang, TSPEED_TIME, self.ltime - time + self.wait, train_wait);
		else // instant turning
			SUB_CalcAngleMove(ang, TSPEED_TIME, 0.0000001, train_wait);
		self.train_wait_turning = true;
		return;
	}

	if(self.noise != "")
		stopsoundto(MSG_BROADCAST, self, CH_TRIGGER_SINGLE); // send this as unreliable only, as the train will resume operation shortly anyway

	if(self.wait < 0 || self.train_wait_turning) // no waiting or we already waited while turning
	{
		self.train_wait_turning = false;
		train_next();
	}
	else
	{
		self.think = train_next;
		trigger_setnextthink(self, self.ltime + self.wait);
	}
}

void train_next()
{
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
		sound(self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_IDLE);
}

void func_train_find()
{
	entity targ;
	targ = find(world, targetname, self.target);
	self.target = targ.target;
	if (self.target == "")
		objerror("func_train_find: no next target");
	setorigin(self, targ.origin - self.view_ofs);
	trigger_setnextthink(self, self.ltime + 1);
	self.think = train_next;
}

/*QUAKED spawnfunc_func_train (0 .5 .8) ?
Ridable platform, targets spawnfunc_path_corner path to follow.
speed : speed the train moves (can be overridden by each spawnfunc_path_corner)
target : targetname of first spawnfunc_path_corner (starts here)
*/
void spawnfunc_func_train()
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
	
	if (self.spawnflags & 2)
	{
		self.platmovetype_turn = true;
		self.view_ofs = '0 0 0'; // don't offset a rotating train, origin works differently now
	}
	else
		self.view_ofs = self.mins;

	// wait for targets to spawn
	InitializeEntity(self, func_train_find, INITPRIO_SETLOCATION);

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
#endif
