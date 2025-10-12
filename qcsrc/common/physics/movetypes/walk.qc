#include "walk.qh"

void _Movetype_Physics_Walk(entity this, float dt)  // SV_WalkMove
{
	// if frametime is 0 (due to client sending the same timestamp twice), don't move
	if (dt <= 0)
		return;

	bool applygravity = !_Movetype_CheckWater(this) && (this.move_movetype == MOVETYPE_WALK || this.move_movetype == MOVETYPE_STEP) && !(this.flags & FL_WATERJUMP);
	vector start_velocity = this.velocity;

	int clip = _Movetype_FlyMove(this, dt, applygravity, PHYS_STEPHEIGHT(this));

	_Movetype_LinkEdict(this, true);

	if (clip & 8)  // teleport
		return;

	if (this.flags & FL_WATERJUMP)
		return;

	// don't do the down move if stepdown is disabled, moving upward, not in water, or the move started offground or ended onground
	if (!GAMEPLAYFIX_STEPDOWN(this) || this.waterlevel >= 3 || start_velocity.z >= (1.0 / 32.0) || !WAS_ONGROUND(this) || IS_ONGROUND(this)
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
