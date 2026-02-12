#include "walk.qh"

void _Movetype_Physics_Walk(entity this, float dt)  // SV_WalkMove
{
	// if frametime is 0 (due to client sending the same timestamp twice), don't move
	if (dt <= 0)
		return;

	bool applygravity = (IS_WATERJUMPING(this) || this.waterlevel <= WATERLEVEL_WETFEET)
	                 && (this.move_movetype == MOVETYPE_WALK || this.move_movetype == MOVETYPE_STEP);
	vector start_velocity = this.velocity;

	int clip = _Movetype_FlyMove(this, dt, applygravity, PHYS_STEPHEIGHT(this));

	_Movetype_LinkEdict(this, true);

	if (clip & 8)  // teleport
		return;

	if (IS_WATERJUMPING(this))
	{
		// bones_was_here: Q3 has double gravity during a water jump, might be a bug but
		// we need it to get the Q3/CPMA step up and IMO it feels better (less flying around).
		this.velocity.z -= dt * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);
		if (this.velocity.z < 0 || this.ladder_entity)
		{
			// Q3: cancel as soon as we are falling down again
			// bones_was_here: or if we get on a ladder
			#ifdef CSQC
			csqcplayer_current_moveflags &= ~(PMF_TIME_WATERJUMP | PMF_SKIMMING | PMF_TIME_KNOCKBACK);
			if (csqcplayer_moveframe == clientcommandframe)
			#endif
			{
				this.pm_time = 0;
				this.flags &= ~(FL_KNOCKBACK | FL_WATERJUMP);
			}
		}
		return;
	}

	// don't do the down move if stepdown is disabled, moving upward, not in water, or the move started offground or ended onground
	if (!GAMEPLAYFIX_STEPDOWN(this) || this.waterlevel >= WATERLEVEL_SUBMERGED || start_velocity.z >= (1.0 / 32.0) || !WAS_ONGROUND(this) || IS_ONGROUND(this)
	|| (GAMEPLAYFIX_STEPDOWN_MAXSPEED(this) && vdist(start_velocity, >=, GAMEPLAYFIX_STEPDOWN_MAXSPEED(this)) && !IS_ONSLICK(this)))
		return;

	vector originalorigin = this.origin;
	// move down
	if (!_Movetype_PushEntity(this, vec3(0, 0, -PHYS_STEPHEIGHT(this)), true))
	{
		// we got teleported when downstepping... must abort the move
		return;
	}

	// cancel the step down if it didn't land on walkable ground
	if (trace_fraction == 1 || trace_plane_normal.z < MIN_WALK_NORMAL)
		this.origin = originalorigin;
	else if (GAMEPLAYFIX_STEPDOWN(this) == 2)
		PM_GroundDetected(this, start_velocity);

	_Movetype_LinkEdict(this, true);
}
