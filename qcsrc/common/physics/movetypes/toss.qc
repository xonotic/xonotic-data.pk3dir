#include "../physics.qh"

void _Movetype_Physics_Toss(entity this, float dt)  // SV_Physics_Toss
{
	if (this.move_flags & FL_ONGROUND)
	{
		if (this.move_velocity.z >= 1 / 32 && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			this.move_flags &= ~FL_ONGROUND;
		}
		else if (!this.move_groundentity)
		{
			return;
		}
		else if (this.move_suspendedinair && wasfreed(this.move_groundentity))
		{
			this.move_groundentity = world;
			return;
		}
	}

	this.move_suspendedinair = false;

	_Movetype_CheckVelocity(this);

	if (this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS)
	{
		this.move_didgravity = 1;
		this.move_velocity_z -= (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1)
		    * dt
		    * (this.gravity ? this.gravity : 1)
		    * PHYS_GRAVITY(this);
	}

	this.move_angles = this.move_angles + this.move_avelocity * dt;

	float movetime = dt;
	for (int bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move = this.move_velocity * movetime;
		_Movetype_PushEntity(this, move, true);
		if (wasfreed(this))
			return;

		if (trace_startsolid)
		{
			_Movetype_UnstickEntity(this);
			_Movetype_PushEntity(this, move, false);
			if (wasfreed(this))
				return;
		}

		if (trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			this.move_velocity = _Movetype_ClipVelocity(this.move_velocity, trace_plane_normal, 2.0);
			this.move_flags &= ~FL_ONGROUND;
		}
		else if (this.move_movetype == MOVETYPE_BOUNCE)
		{
			float bouncefac = this.move_bounce_factor;     if (!bouncefac)  bouncefac = 0.5;
			float bouncestop = this.move_bounce_stopspeed; if (!bouncestop) bouncestop = 60 / 800;
			bouncestop *= (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

			this.move_velocity = _Movetype_ClipVelocity(this.move_velocity, trace_plane_normal, 1 + bouncefac);

			float d = trace_plane_normal * this.move_velocity;
			if (trace_plane_normal.z > 0.7 && d < bouncestop && d > -bouncestop)
			{
				this.move_flags |= FL_ONGROUND;
				this.move_groundentity = trace_ent;
				this.move_velocity = '0 0 0';
				this.move_avelocity = '0 0 0';
			}
			else
			{
				this.move_flags &= ~FL_ONGROUND;
			}
		}
		else
		{
			this.move_velocity = _Movetype_ClipVelocity(this.move_velocity, trace_plane_normal, 1.0);
			if (trace_plane_normal.z > 0.7)
			{
				this.move_flags |= FL_ONGROUND;
				this.move_groundentity = trace_ent;
				if (trace_ent.solid == SOLID_BSP)
					this.move_suspendedinair = true;
				this.move_velocity = '0 0 0';
				this.move_avelocity = '0 0 0';
			}
			else
			{
				this.move_flags &= ~FL_ONGROUND;
			}
		}

		// DP revision 8905 (just, WHY...)
		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if (this.move_flags & FL_ONGROUND)
			break;
	}

	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE && this.move_didgravity > 0 && !(this.move_flags & FL_ONGROUND))
		this.move_velocity_z -= 0.5 * dt * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

	_Movetype_CheckWaterTransition(this);
}
