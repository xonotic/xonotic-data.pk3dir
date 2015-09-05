void _Movetype_Physics_Walk(float dt)  // SV_WalkMove
{SELFPARAM();
	vector stepnormal = '0 0 0';

	// if frametime is 0 (due to client sending the same timestamp twice), don't move
	if (dt <= 0)
		return;

	if (GAMEPLAYFIX_UNSTICKPLAYERS)
		_Movetype_UnstickEntity();

	bool applygravity = (!_Movetype_CheckWater(self) && self.move_movetype == MOVETYPE_WALK && !(self.move_flags & FL_WATERJUMP));

	_Movetype_CheckVelocity();

	// do a regular slide move unless it looks like you ran into a step
	bool oldonground = (self.move_flags & FL_ONGROUND);

	vector start_origin = self.move_origin;
	vector start_velocity = self.move_velocity;

	int clip = _Movetype_FlyMove(dt, applygravity, stepnormal, GAMEPLAYFIX_STEPMULTIPLETIMES ? PHYS_STEPHEIGHT : 0);

	if (GAMEPLAYFIX_DOWNTRACEONGROUND && !(clip & 1))
	{
		// only try this if there was no floor in the way in the trace (no,
		// this check seems to be not REALLY necessary, because if clip & 1,
		// our trace will hit that thing too)
		vector upmove = self.move_origin + '0 0 1';
		vector downmove = self.move_origin - '0 0 1';
		int type;
		if (self.move_movetype == MOVETYPE_FLYMISSILE)
			type = MOVE_MISSILE;
		else if (self.move_movetype == MOVETYPE_FLY_WORLDONLY)
			type = MOVE_WORLDONLY;
		else if (self.solid == SOLID_TRIGGER || self.solid == SOLID_NOT)
			type = MOVE_NOMONSTERS;
		else type = MOVE_NORMAL;
		tracebox(upmove, self.mins, self.maxs, downmove, type, self);
		if (trace_fraction < 1 && trace_plane_normal.z > 0.7)
			clip |= 1;  // but we HAVE found a floor
	}

	// if the move did not hit the ground at any point, we're not on ground
	if (!(clip & 1))
		self.move_flags &= ~FL_ONGROUND;

	_Movetype_CheckVelocity();
	_Movetype_LinkEdict(true);

	if (clip & 8)  // teleport
		return;

	if (self.move_flags & FL_WATERJUMP)
		return;

	if (PHYS_NOSTEP)
		return;

	vector originalmove_origin = self.move_origin;
	vector originalmove_velocity = self.move_velocity;
	// originalmove_clip = clip;
	int originalmove_flags = self.move_flags;
	entity originalmove_groundentity = self.move_groundentity;

	// if move didn't block on a step, return
	if (clip & 2)
	{
		// if move was not trying to move into the step, return
		if (fabs(start_velocity.x) < 0.03125 && fabs(start_velocity.y) < 0.03125)
			return;

		if (self.move_movetype != MOVETYPE_FLY)
		{
			// return if gibbed by a trigger
			if (self.move_movetype != MOVETYPE_WALK)
				return;

			// return if attempting to jump while airborn (unless sv_jumpstep)
			if (!PHYS_JUMPSTEP)
				if (!oldonground && self.move_waterlevel == 0)
					return;
		}

		// try moving up and forward to go up a step
		// back to start pos
		self.move_origin = start_origin;
		self.move_velocity = start_velocity;

		// move up
		vector upmove = '0 0 1' * PHYS_STEPHEIGHT;
		vector prev_origin = self.move_origin;
		_Movetype_PushEntity(upmove, true);
		if(wasfreed(self))
			return;
		if(trace_startsolid && self.move_origin != prev_origin)
		{
			// we got teleported when upstepping... must abort the move
			return;
		}

		// move forward
		self.move_velocity_z = 0;
		clip = _Movetype_FlyMove(dt, applygravity, stepnormal, 0);
		self.move_velocity_z += start_velocity.z;
		if (clip & 8)
		{
			// we got teleported when upstepping... must abort the move
			// note that z velocity handling may not be what QC expects here, but we cannot help it
			return;
		}

		_Movetype_CheckVelocity();
		_Movetype_LinkEdict(true);

		// check for stuckness, possibly due to the limited precision of floats
		// in the clipping hulls
		if (clip
		    && fabs(originalmove_origin.y - self.move_origin.y) < 0.03125
		    && fabs(originalmove_origin.x - self.move_origin.x) < 0.03125)
		{
			// Con_Printf("wall\n");
			// stepping up didn't make any progress, revert to original move
			self.move_origin = originalmove_origin;
			self.move_velocity = originalmove_velocity;
			// clip = originalmove_clip;
			self.move_flags = originalmove_flags;
			self.move_groundentity = originalmove_groundentity;
			// now try to unstick if needed
			// clip = SV_TryUnstick (ent, oldvel);
			return;
		}

		// Con_Printf("step - ");

		// extra friction based on view angle
		if ((clip & 2) && PHYS_WALLFRICTION)
			_Movetype_WallFriction(stepnormal);
	}
	// don't do the down move if stepdown is disabled, moving upward, not in water, or the move started offground or ended onground
	else if (!GAMEPLAYFIX_STEPDOWN || self.move_waterlevel >= 3 || start_velocity.z >= (1.0 / 32.0) || !oldonground || (self.move_flags & FL_ONGROUND))
	{
		return;
	}

	// move down
	vector downmove = '0 0 1' * (-PHYS_STEPHEIGHT + start_velocity.z * dt);
	vector prev_origin = self.move_origin;
	_Movetype_PushEntity(downmove, true);
	if(wasfreed(self))
		return;

	if(trace_startsolid && self.move_origin != prev_origin)
	{
		// we got teleported when downstepping... must abort the move
		return;
	}

	if (trace_fraction < 1 && trace_plane_normal.z > 0.7)
	{
		// this has been disabled so that you can't jump when you are stepping
		// up while already jumping (also known as the Quake2 double jump bug)
	}
	else
	{
		// Con_Printf("slope\n");
		// if the push down didn't end up on good ground, use the move without
		// the step up.  This happens near wall / slope combinations, and can
		// cause the player to hop up higher on a slope too steep to climb
		self.move_origin = originalmove_origin;
		self.move_velocity = originalmove_velocity;
		self.move_flags = originalmove_flags;
		self.move_groundentity = originalmove_groundentity;
	}

	_Movetype_CheckVelocity();
	_Movetype_LinkEdict(true);
}
