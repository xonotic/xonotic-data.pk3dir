#include "../physics.qh"

void _Movetype_Physics_Toss(float dt)  // SV_Physics_Toss
{SELFPARAM();
	if (self.move_flags & FL_ONGROUND)
	{
		if (self.move_velocity.z >= 1 / 32)
		{
			self.move_flags &= ~FL_ONGROUND;
		}
		else if (!self.move_groundentity)
		{
			return;
		}
		else if (self.move_suspendedinair && wasfreed(self.move_groundentity))
		{
			self.move_groundentity = world;
			return;
		}
	}

	self.move_suspendedinair = false;

	_Movetype_CheckVelocity();

	if (self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS)
	{
		self.move_didgravity = 1;
		self.move_velocity_z -= (GRAVITY_UNAFFECTED_BY_TICRATE ? 0.5 : 1)
		    * dt
		    * (self.gravity ? self.gravity : 1)
		    * PHYS_GRAVITY;
	}

	self.move_angles = self.move_angles + self.move_avelocity * dt;

	float movetime = dt;
	for (int bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move = self.move_velocity * movetime;
		_Movetype_PushEntity(move, true);
		if (wasfreed(self))
			return;

		if (trace_startsolid)
		{
			_Movetype_UnstickEntity();
			_Movetype_PushEntity(move, false);
			if (wasfreed(self))
				return;
		}

		if (trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if (self.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 2.0);
			self.move_flags &= ~FL_ONGROUND;
		}
		else if (self.move_movetype == MOVETYPE_BOUNCE)
		{
			float bouncefac = self.move_bounce_factor;     if (!bouncefac)  bouncefac = 0.5;
			float bouncestop = self.move_bounce_stopspeed; if (!bouncestop) bouncestop = 60 / 800;
			bouncestop *= (self.gravity ? self.gravity : 1) * PHYS_GRAVITY;

			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1 + bouncefac);

			float d = trace_plane_normal * self.move_velocity;
			if (trace_plane_normal.z > 0.7 && d < bouncestop && d > -bouncestop)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
			{
				self.move_flags &= ~FL_ONGROUND;
			}
		}
		else
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1.0);
			if (trace_plane_normal.z > 0.7)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				if (trace_ent.solid == SOLID_BSP)
					self.move_suspendedinair = true;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
			{
				self.move_flags &= ~FL_ONGROUND;
			}
		}

		// DP revision 8905 (just, WHY...)
		if (self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if (self.move_flags & FL_ONGROUND)
			break;
	}

	if (GRAVITY_UNAFFECTED_BY_TICRATE && self.move_didgravity > 0 && !(self.move_flags & FL_ONGROUND))
		self.move_velocity_z -= 0.5 * dt * (self.gravity ? self.gravity : 1) * PHYS_GRAVITY;

	_Movetype_CheckWaterTransition(self);
}
