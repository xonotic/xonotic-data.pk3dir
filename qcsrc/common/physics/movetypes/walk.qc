void _Movetype_Physics_Walk(entity this, float dt)  // SV_WalkMove
{
	vector stepnormal = '0 0 0';

	// if frametime is 0 (due to client sending the same timestamp twice), don't move
	if (dt <= 0)
		return;

	if (GAMEPLAYFIX_UNSTICKPLAYERS(this))
		_Movetype_UnstickEntity(this);

	bool applygravity = (!_Movetype_CheckWater(this) && this.move_movetype == MOVETYPE_WALK && !(this.move_flags & FL_WATERJUMP));

	_Movetype_CheckVelocity(this);

	// do a regular slide move unless it looks like you ran into a step
	bool oldonground = (this.move_flags & FL_ONGROUND);

	vector start_origin = this.move_origin;
	vector start_velocity = this.move_velocity;

	int clip = _Movetype_FlyMove(this, dt, applygravity, stepnormal, GAMEPLAYFIX_STEPMULTIPLETIMES(this) ? PHYS_STEPHEIGHT(this) : 0);

	if (GAMEPLAYFIX_DOWNTRACEONGROUND(this) && !(clip & 1))
	{
		// only try this if there was no floor in the way in the trace (no,
		// this check seems to be not REALLY necessary, because if clip & 1,
		// our trace will hit that thing too)
		vector upmove = this.move_origin + '0 0 1';
		vector downmove = this.move_origin - '0 0 1';
		int type;
		if (this.move_movetype == MOVETYPE_FLYMISSILE)
			type = MOVE_MISSILE;
		else if (this.move_movetype == MOVETYPE_FLY_WORLDONLY)
			type = MOVE_WORLDONLY;
		else if (this.solid == SOLID_TRIGGER || this.solid == SOLID_NOT)
			type = MOVE_NOMONSTERS;
		else type = MOVE_NORMAL;
		tracebox(upmove, this.mins, this.maxs, downmove, type, this);
		if (trace_fraction < 1 && trace_plane_normal.z > 0.7)
			clip |= 1;  // but we HAVE found a floor
	}

	// if the move did not hit the ground at any point, we're not on ground
	if (!(clip & 1))
		this.move_flags &= ~FL_ONGROUND;

	_Movetype_CheckVelocity(this);
	_Movetype_LinkEdict(this, true);

	if (clip & 8)  // teleport
		return;

	if (this.move_flags & FL_WATERJUMP)
		return;

	if (PHYS_NOSTEP(this))
		return;

	vector originalmove_origin = this.move_origin;
	vector originalmove_velocity = this.move_velocity;
	// originalmove_clip = clip;
	int originalmove_flags = this.move_flags;
	entity originalmove_groundentity = this.move_groundentity;

	// if move didn't block on a step, return
	if (clip & 2)
	{
		// if move was not trying to move into the step, return
		if (fabs(start_velocity.x) < 0.03125 && fabs(start_velocity.y) < 0.03125)
			return;

		if (this.move_movetype != MOVETYPE_FLY)
		{
			// return if gibbed by a trigger
			if (this.move_movetype != MOVETYPE_WALK)
				return;

			// return if attempting to jump while airborn (unless sv_jumpstep)
			if (!PHYS_JUMPSTEP(this))
				if (!oldonground && this.move_waterlevel == 0)
					return;
		}

		// try moving up and forward to go up a step
		// back to start pos
		this.move_origin = start_origin;
		this.move_velocity = start_velocity;

		// move up
		vector upmove = '0 0 1' * PHYS_STEPHEIGHT(this);
		_Movetype_PushEntity(this, upmove, true);
		if(wasfreed(this))
			return;
		if(trace_startsolid)
		{
			// we got teleported when upstepping... must abort the move
			return;
		}

		// move forward
		this.move_velocity_z = 0;
		clip = _Movetype_FlyMove(this, dt, applygravity, stepnormal, 0);
		this.move_velocity_z += start_velocity.z;
		if (clip & 8)
		{
			// we got teleported when upstepping... must abort the move
			// note that z velocity handling may not be what QC expects here, but we cannot help it
			return;
		}

		_Movetype_CheckVelocity(this);
		_Movetype_LinkEdict(this, true);

		// check for stuckness, possibly due to the limited precision of floats
		// in the clipping hulls
		if (clip
		    && fabs(originalmove_origin.y - this.move_origin.y) < 0.03125
		    && fabs(originalmove_origin.x - this.move_origin.x) < 0.03125)
		{
			// Con_Printf("wall\n");
			// stepping up didn't make any progress, revert to original move
			this.move_origin = originalmove_origin;
			this.move_velocity = originalmove_velocity;
			// clip = originalmove_clip;
			this.move_flags = originalmove_flags;
			this.move_groundentity = originalmove_groundentity;
			// now try to unstick if needed
			// clip = SV_TryUnstick (ent, oldvel);
			return;
		}

		// Con_Printf("step - ");

		// extra friction based on view angle
		if ((clip & 2) && PHYS_WALLFRICTION(this))
			_Movetype_WallFriction(this, stepnormal);
	}
	// don't do the down move if stepdown is disabled, moving upward, not in water, or the move started offground or ended onground
	else if (!GAMEPLAYFIX_STEPDOWN(this) || this.move_waterlevel >= 3 || start_velocity.z >= (1.0 / 32.0) || !oldonground || (this.move_flags & FL_ONGROUND))
	{
		return;
	}

	// move down
	vector downmove = '0 0 1' * (-PHYS_STEPHEIGHT(this) + start_velocity.z * dt);
	_Movetype_PushEntity(this, downmove, true);
	if(wasfreed(this))
		return;

	if(trace_startsolid)
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
		this.move_origin = originalmove_origin;
		this.move_velocity = originalmove_velocity;
		this.move_flags = originalmove_flags;
		this.move_groundentity = originalmove_groundentity;
	}

	_Movetype_CheckVelocity(this);
	_Movetype_LinkEdict(this, true);
}
