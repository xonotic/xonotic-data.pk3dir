#include "toss.qh"

void _Movetype_Physics_Toss(entity this, float dt)  // SV_Physics_Toss
{
	if(IS_ONGROUND(this))
	{
		if(this.velocity.z >= (1 / 32) && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			// don't stick to ground if onground and moving upward
			UNSET_ONGROUND(this);
		}
		else if(!this.groundentity || !GAMEPLAYFIX_NOAIRBORNCORPSE(this))
		{
			return;
		}
		else if(this.move_suspendedinair && wasfreed(this.groundentity))
		{
			this.groundentity = NULL;
			if(NOAIRBORNCORPSE_ALLOWSUSPENDED(this))
				return;
		}
		else if(boxesoverlap(this.absmin, this.absmax, this.groundentity.absmin, this.groundentity.absmax))
		{
			// don't slide if still touching the groundentity
			return;
		}
	}

	this.move_suspendedinair = false;

	_Movetype_CheckVelocity(this);

	if(this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS)
	{
		this.move_didgravity = true;
		this.velocity_z -= (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1)
		    * dt
		    * ((this.gravity) ? this.gravity : 1)
		    * PHYS_GRAVITY(this);
	}

	/*if (this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS)
	{
		this.move_didgravity = true;
		this.velocity_z -= (((this.gravity) ? this.gravity : 1) * PHYS_GRAVITY(this) * dt);
	}*/

	this.angles = this.angles + this.avelocity * dt;

	float movetime = dt;
	for (int bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		if(this.velocity == '0 0 0')
			break;

		vector move = this.velocity * movetime;
		if(!_Movetype_PushEntity(this, move, true))
			return; // teleported
		if (wasfreed(this))
			return;

		// NOTE: this is bmodelstartsolid in the engine
		if (trace_allsolid && trace_fraction == 0 && trace_ent.solid == SOLID_BSP)
		{
			// QC lacks pointers so we must save the old trace values
			float oldtrace_fraction = trace_fraction;
			vector oldtrace_plane_normal = trace_plane_normal;
			entity oldtrace_ent = trace_ent;
			_Movetype_UnstickEntity(this);
			trace_fraction = oldtrace_fraction;
			trace_plane_normal = oldtrace_plane_normal;
			trace_ent = oldtrace_ent;
			if(!_Movetype_PushEntity(this, move, true))
				return; // teleported
			if (wasfreed(this))
				return;
			if (trace_allsolid && trace_fraction == 0)
			{
				// immovably stuck, don't waste CPU trying to move again
				this.velocity = '0 0 0';
				SET_ONGROUND(this);
				return;
			}
		}

		if (trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			float bouncefac = (!this.bouncefactor) ? 1.0 : this.bouncefactor;
			this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 1 + bouncefac);
			UNSET_ONGROUND(this);
			if(!GAMEPLAYFIX_SLIDEMOVEPROJECTILES(this))
				movetime = 0;
		}
		else if (this.move_movetype == MOVETYPE_BOUNCE)
		{
			float bouncefac = (!this.bouncefactor) ? 0.5 : this.bouncefactor;
			float bstop = (!this.bouncestop) ? (60 / 800) : this.bouncestop;
			float grav = ((this.gravity) ? this.gravity : 1);

			this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 1 + bouncefac);

			float d = trace_plane_normal * this.velocity;
			if(!GAMEPLAYFIX_GRENADEBOUNCESLOPES(this))
				d = this.velocity.z;
			if (trace_plane_normal.z > 0.7 && d < PHYS_GRAVITY(this) * bstop * grav)
			{
				SET_ONGROUND(this);
				this.groundentity = trace_ent;
				this.velocity = '0 0 0';
				this.avelocity = '0 0 0';
				movetime = 0;
			}
			else
			{
				UNSET_ONGROUND(this);
				if(!GAMEPLAYFIX_SLIDEMOVEPROJECTILES(this))
					movetime = 0;
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
				movetime = 0;
			}
			else
			{
				UNSET_ONGROUND(this);
				if(!GAMEPLAYFIX_SLIDEMOVEPROJECTILES(this))
					movetime = 0;
			}
		}

		// DP revision 8905 (just, WHY...)
		//if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
			//break;

		// DP revision 8918 (WHY...)
		//if (IS_ONGROUND(this))
			//break;
	}

	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE && this.move_didgravity > 0 && !IS_ONGROUND(this))
		this.velocity_z -= 0.5 * dt * ((this.gravity) ? this.gravity : 1) * PHYS_GRAVITY(this);

	_Movetype_CheckWaterTransition(this);
}
