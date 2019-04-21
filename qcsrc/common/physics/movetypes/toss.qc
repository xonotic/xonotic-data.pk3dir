#include "toss.qh"

void _Movetype_Physics_Toss(entity this, float dt)  // SV_Physics_Toss
{
	if (IS_ONGROUND(this))
	{
		if (this.velocity.z >= 1 / 32 && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			UNSET_ONGROUND(this);
		}
		else if (!this.groundentity)
		{
			return;
		}
		else if (this.move_suspendedinair && wasfreed(this.groundentity))
		{
			this.groundentity = NULL;
			return;
		}
	}

	this.move_suspendedinair = false;

	_Movetype_CheckVelocity(this);

	/*if (this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS)
	{
		this.move_didgravity = 1;
		this.velocity_z -= (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1)
		    * dt
		    * (this.gravity ? this.gravity : 1)
		    * PHYS_GRAVITY(this);
	}*/

	if (this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS)
	{
		this.move_didgravity = true;
		this.velocity_z -= (((this.gravity) ? this.gravity : 1) * PHYS_GRAVITY(this) * dt);
	}

	this.angles = this.angles + this.avelocity * dt;

	float movetime = dt;
	for (int bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move = this.velocity * movetime;
		_Movetype_PushEntity(this, move, true, false);
		if (wasfreed(this))
			return;

		if (trace_startsolid)
		{
			_Movetype_UnstickEntity(this);
			_Movetype_PushEntity(this, move, false, false);
			if (wasfreed(this))
				return;
		}

		if (trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 2.0);
			UNSET_ONGROUND(this);
		}
		else if (this.move_movetype == MOVETYPE_BOUNCE)
		{
			float bouncefac = this.bouncefactor;     if (!bouncefac)  bouncefac = 0.5;
			float bstop = this.bouncestop; if (!bstop) bstop = 60 / 800;
			bstop *= (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

			this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 1 + bouncefac);

			float d = trace_plane_normal * this.velocity;
			if (trace_plane_normal.z > 0.7 && d < bstop && d > -bstop)
			{
				SET_ONGROUND(this);
				this.groundentity = trace_ent;
				this.velocity = '0 0 0';
				this.avelocity = '0 0 0';
			}
			else
			{
				UNSET_ONGROUND(this);
			}
		}
		else
		{
			this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 1.0);
			if (trace_plane_normal.z > 0.7)
			{
				SET_ONGROUND(this);
				this.groundentity = trace_ent;
				if (trace_ent.solid == SOLID_BSP)
					this.move_suspendedinair = true;
				this.velocity = '0 0 0';
				this.avelocity = '0 0 0';
			}
			else
			{
				UNSET_ONGROUND(this);
			}
		}

		// DP revision 8905 (just, WHY...)
		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if (IS_ONGROUND(this))
			break;
	}

	//if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE && this.move_didgravity > 0 && !IS_ONGROUND(this))
	//	this.velocity_z -= 0.5 * dt * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

	_Movetype_CheckWaterTransition(this);
}
