#include "../physics.qh"

void _Movetype_Physics_Toss(float dt) // SV_Physics_Toss
{
	if(self.move_flags & FL_ONGROUND)
	{
		if(self.move_velocity_z >= 1/32)
			self.move_flags &= ~FL_ONGROUND;
		else if(!self.move_groundentity)
			return;
		else if(self.move_suspendedinair && wasfreed(self.move_groundentity))
		{
			self.move_groundentity = world;
			return;
		}
	}

	self.move_suspendedinair = false;

	_Movetype_CheckVelocity();

	if(self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS)
	{
		self.move_didgravity = 1;
		if(GRAVITY_UNAFFECTED_BY_TICRATE)
		{
			if(self.gravity)
				self.move_velocity_z -= 0.5 * dt * self.gravity * PHYS_GRAVITY;
			else
				self.move_velocity_z -= 0.5 * dt * PHYS_GRAVITY;
		}
		else
		{
			if(self.gravity)
				self.move_velocity_z -= dt * self.gravity * PHYS_GRAVITY;
			else
				self.move_velocity_z -= dt * PHYS_GRAVITY;
		}
	}

	self.move_angles = self.move_angles + self.move_avelocity * dt;

	float movetime, bump;
	movetime = dt;
	for(bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move;
		move = self.move_velocity * movetime;
		_Movetype_PushEntity(move, true);
		if(wasfreed(self))
			return;

		if(trace_startsolid)
		{
			_Movetype_UnstickEntity();
			_Movetype_PushEntity(move, false);
			if(wasfreed(self))
				return;
		}

		if(trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 2.0);
			self.move_flags &= ~FL_ONGROUND;
		}
		else if(self.move_movetype == MOVETYPE_BOUNCE)
		{
			float d, bouncefac, bouncestop;

			bouncefac = self.move_bounce_factor;     if(!bouncefac)  bouncefac = 0.5;
			bouncestop = self.move_bounce_stopspeed; if(!bouncestop) bouncestop = 60 / 800;
			if(self.gravity)
				bouncestop *= self.gravity * PHYS_GRAVITY;
			else
				bouncestop *= PHYS_GRAVITY;

			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1 + bouncefac);

			d = trace_plane_normal * self.move_velocity;
			if(trace_plane_normal_z > 0.7 && d < bouncestop && d > -bouncestop)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
				self.move_flags &= ~FL_ONGROUND;
		}
		else
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1.0);
			if(trace_plane_normal_z > 0.7)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				if(trace_ent.solid == SOLID_BSP)
					self.move_suspendedinair = true;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
				self.move_flags &= ~FL_ONGROUND;
		}

		// DP revision 8905 (just, WHY...)
		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if(self.move_flags & FL_ONGROUND)
			break;
	}

	if(GRAVITY_UNAFFECTED_BY_TICRATE)
	if(self.move_didgravity > 0)
	if(!(self.move_flags & FL_ONGROUND))
	{
		if(self.gravity)
			self.move_velocity_z -= 0.5 * dt * self.gravity * PHYS_GRAVITY;
		else
			self.move_velocity_z -= 0.5 * dt * PHYS_GRAVITY;
	}

	_Movetype_CheckWaterTransition(self);
}
