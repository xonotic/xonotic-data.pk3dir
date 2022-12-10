#include "walk.qh"

void _Movetype_Physics_Walk(entity this, float dt)  // SV_WalkMove
{
	// if frametime is 0 (due to client sending the same timestamp twice), don't move
	if (dt <= 0)
		return;

	if (GAMEPLAYFIX_UNSTICKPLAYERS(this))
		_Movetype_CheckStuck(this);

	bool applygravity = (!_Movetype_CheckWater(this) && this.move_movetype == MOVETYPE_WALK && !(this.flags & FL_WATERJUMP));

	_Movetype_CheckVelocity(this);

	// do a regular slide move unless it looks like you ran into a step
	bool oldonground = IS_ONGROUND(this);

	vector start_origin = this.origin;
	vector start_velocity = this.velocity;

	if(PHYS_WALLCLIP(this) && this.pm_time)
	{
		if(dt >= this.pm_time || (this.flags & FL_WATERJUMP))
			this.pm_time = 0;
		else
			this.pm_time -= dt;
	}

	int clip = _Movetype_FlyMove(this, dt, applygravity, false, GAMEPLAYFIX_STEPMULTIPLETIMES(this) ? PHYS_STEPHEIGHT(this) : 0);

	if (GAMEPLAYFIX_DOWNTRACEONGROUND(this) && !(clip & 1))
	{
		// only try this if there was no floor in the way in the trace (no,
		// this check seems to be not REALLY necessary, because if clip & 1,
		// our trace will hit that thing too)
		vector upmove = this.origin + '0 0 1';
		vector downmove = this.origin - '0 0 1';
		int type;
		if (this.move_nomonsters)
			type = max(0, this.move_nomonsters);
		else if (this.move_movetype == MOVETYPE_FLYMISSILE)
			type = MOVE_MISSILE;
		else if (this.move_movetype == MOVETYPE_FLY_WORLDONLY)
			type = MOVE_WORLDONLY;
		else if (this.solid == SOLID_TRIGGER || this.solid == SOLID_NOT)
			type = MOVE_NOMONSTERS;
		else
			type = MOVE_NORMAL;
		tracebox(upmove, this.mins, this.maxs, downmove, type, this);
		if (trace_fraction < 1 && trace_plane_normal.z > 0.7)
		{
			clip |= 1;  // but we HAVE found a floor
			// set groundentity so we get carried when walking onto a mover
			this.groundentity = trace_ent;
		}
	}

	// if the move did not hit the ground at any point, we're not on ground
	if (!(clip & 1))
		UNSET_ONGROUND(this);
	else if(PHYS_WALLCLIP(this) && !this.groundentity && (PHYS_WALLCLIP(this) == 2 || start_velocity.z < -200)) // don't do landing time if we were just going down a slope
		this.pm_time = 0.25;

	_Movetype_CheckVelocity(this);
	_Movetype_LinkEdict(this, true);

	if (clip & 8)  // teleport
		return;

	if (this.flags & FL_WATERJUMP)
		return;

	if (PHYS_NOSTEP(this))
		return;

	vector originalorigin = this.origin;
	vector originalvelocity = this.velocity;
	// originalmove_clip = clip;
	int originalflags = this.flags;
	entity originalmove_groundentity = this.groundentity;

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
				if (!oldonground && this.waterlevel == 0)
					return;
		}

		// try moving up and forward to go up a step
		// back to start pos
		this.origin = start_origin;
		this.velocity = start_velocity;

		// move up
		vector upmove = '0 0 1' * PHYS_STEPHEIGHT(this);
		if(!_Movetype_PushEntity(this, upmove, true))
		{
			// we got teleported when upstepping... must abort the move
			return;
		}

		// move forward
		this.velocity_z = 0;
		clip = _Movetype_FlyMove(this, dt, applygravity, true, 0);
		this.velocity_z += start_velocity.z;
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
		    && fabs(originalorigin.y - this.origin.y) < 0.03125
		    && fabs(originalorigin.x - this.origin.x) < 0.03125)
		{
			// Con_Printf("wall\n");
			// stepping up didn't make any progress, revert to original move
			this.origin = originalorigin;
			this.velocity = originalvelocity;
			// clip = originalmove_clip;
			this.flags = originalflags;
			this.groundentity = originalmove_groundentity;
			// now try to unstick if needed
			// clip = SV_TryUnstick (ent, oldvel);
			return;
		}

		// Con_Printf("step - ");

		// extra friction based on view angle
		if ((clip & 2) && PHYS_WALLFRICTION(this))
			_Movetype_WallFriction(this, move_stepnormal);
	}
	// don't do the down move if stepdown is disabled, moving upward, not in water, or the move started offground or ended onground
	else if (!GAMEPLAYFIX_STEPDOWN(this) || this.waterlevel >= 3 || start_velocity.z >= (1.0 / 32.0) 
				|| !oldonground || IS_ONGROUND(this) || (GAMEPLAYFIX_STEPDOWN_MAXSPEED(this) && vdist(start_velocity, >=, GAMEPLAYFIX_STEPDOWN_MAXSPEED(this)) && !IS_ONSLICK(this)))
	{
		return;
	}

	// move down
	vector downmove = '0 0 0';
	downmove.z = -PHYS_STEPHEIGHT(this) + start_velocity.z * dt;
	if(!_Movetype_PushEntity(this, downmove, true))
	{
		// we got teleported when downstepping... must abort the move
		return;
	}

	if (trace_fraction < 1 && trace_plane_normal.z > 0.7)
	{
		// this has been disabled so that you can't jump when you are stepping
		// up while already jumping (also known as the Quake2 double jump bug)
		// LordHavoc: disabled this check so you can walk on monsters/players
		//if (PRVM_serveredictfloat(ent, solid) == SOLID_BSP)
		if(GAMEPLAYFIX_STEPDOWN(this) == 2)
		{
			SET_ONGROUND(this);
			this.groundentity = trace_ent;
		}
	}
	else
	{
		// Con_Printf("slope\n");
		// if the push down didn't end up on good ground, use the move without
		// the step up.  This happens near wall / slope combinations, and can
		// cause the player to hop up higher on a slope too steep to climb
		this.origin = originalorigin;
		this.velocity = originalvelocity;
		this.flags = originalflags;
		this.groundentity = originalmove_groundentity;
	}

	_Movetype_CheckVelocity(this);
	_Movetype_LinkEdict(this, true);
}
