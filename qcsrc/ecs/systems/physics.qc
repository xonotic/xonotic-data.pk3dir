#include "physics.qh"
#include "input.qh"

.int disableclientprediction;

void sys_phys_simulate(entity this, float dt);
void sys_phys_simulate_simple(entity this, float dt);

void sys_phys_postupdate(entity this);

void sys_phys_update(entity this, float dt)
{
	if (!IS_CLIENT(this))
	{
		sys_phys_simulate_simple(this, dt);
		return;
	}
	sys_in_update(this, dt);

	sys_phys_fix(this, dt);
	if (sys_phys_override(this, dt))
		return;

	sys_phys_monitor(this, dt);

	PHYS_CS(this).movement_old = PHYS_CS(this).movement;
	PHYS_CS(this).v_angle_old = this.v_angle;
	PHYS_CS(this).buttons_old = PHYS_INPUT_BUTTON_MASK(this);

	sys_phys_ai(this);

	sys_phys_pregame_hold(this);

	if (IS_SVQC)
	{
		if (this.move_movetype == MOVETYPE_NONE)
			return;
		// when we get here, disableclientprediction cannot be 2
		if(this.move_movetype == MOVETYPE_FOLLOW) // not compatible with prediction
			this.disableclientprediction = 1;
		else if(this.move_qcphysics)
			this.disableclientprediction = -1;
		else
			this.disableclientprediction = 0;
	}

	viewloc_PlayerPhysics(this);

	PM_check_frozen(this);

	PM_check_blocked(this);

	float maxspeed_mod = 1;

	// conveyors: first fix velocity
	if (this.conveyor.active)
		this.velocity -= this.conveyor.movedir;
	MUTATOR_CALLHOOK(PlayerPhysics, this, dt);

	if (!IS_PLAYER(this))
	{
		sys_phys_spectator_control(this);
		maxspeed_mod = STAT(SPECTATORSPEED, this);
	}
	sys_phys_fixspeed(this, maxspeed_mod);

	if (IS_DEAD(this))
	{
		// handle water here
		vector midpoint = ((this.absmin + this.absmax) * 0.5);
		int cont = pointcontents(midpoint);
		if (cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		{
			this.velocity = this.velocity * 0.5;

			// do we want this?
			// if(pointcontents(midpoint + '0 0 2') == CONTENT_WATER)
			// { this.velocity_z = 70; }
		}
		sys_phys_postupdate(this);
		return;
	}

	PM_check_slick(this);

	if (IS_SVQC && !PHYS_FIXANGLE(this))
		this.angles = eY * this.v_angle.y;
	if (IS_PLAYER(this))
	{
		if (IS_ONGROUND(this))
		{
			PM_check_hitground(this);
			PM_Footsteps(this);
		}
		else if (IsFlying(this))
			this.wasFlying = true;
		CheckPlayerJump(this);
	}

	if (this.flags & FL_WATERJUMP)
	{
		this.velocity_x = this.movedir.x;
		this.velocity_y = this.movedir.y;
		if (time > this.teleport_time || this.waterlevel == WATERLEVEL_NONE)
		{
			this.flags &= ~FL_WATERJUMP;
			this.teleport_time = 0;
		}
	}
	else if (MUTATOR_CALLHOOK(PM_Physics, this, maxspeed_mod, dt))
		{ /* handled */ }
	else if (this.move_movetype == MOVETYPE_NOCLIP
	      || this.move_movetype == MOVETYPE_FLY
	      || this.move_movetype == MOVETYPE_FLY_WORLDONLY
	      || MUTATOR_CALLHOOK(IsFlying, this))
	{
		this.com_phys_friction = PHYS_FRICTION(this);
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_acc_rate = PHYS_ACCELERATE(this) * maxspeed_mod;
		this.com_phys_friction_air = true;
		sys_phys_simulate(this, dt);
		this.com_phys_friction_air = false;
	}
	else if (this.waterlevel >= WATERLEVEL_SWIMMING)
	{
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_acc_rate = PHYS_ACCELERATE(this) * maxspeed_mod;
		this.com_phys_water = true;
		sys_phys_simulate(this, dt);
		this.com_phys_water = false;
		this.jumppadcount = 0;
	}
	else if (this.ladder_entity)
	{
		this.com_phys_friction = PHYS_FRICTION(this);
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_acc_rate = PHYS_ACCELERATE(this) * maxspeed_mod;
		this.com_phys_gravity = -PHYS_GRAVITY(this) * dt;
		if (PHYS_ENTGRAVITY(this))
			this.com_phys_gravity *= PHYS_ENTGRAVITY(this);
		this.com_phys_ladder = true;
		this.com_phys_friction_air = true;
		sys_phys_simulate(this, dt);
		this.com_phys_friction_air = false;
		this.com_phys_ladder = false;
		this.com_phys_gravity = 0;
	}
	else if (ITEMS_STAT(this) & IT_USING_JETPACK)
		PM_jetpack(this, maxspeed_mod, dt);
	else if (IS_ONGROUND(this) && (!IS_ONSLICK(this) || !PHYS_SLICK_APPLYGRAVITY(this)))
	{
		if (!WAS_ONGROUND(this))
		{
			emit(phys_land, this);
			if (this.lastground < time - 0.3)
				this.velocity *= (1 - PHYS_FRICTION_ONLAND(this));
		}
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_gravity = -PHYS_GRAVITY(this) * dt;
		if (PHYS_ENTGRAVITY(this))
			this.com_phys_gravity *= PHYS_ENTGRAVITY(this);
		this.com_phys_ground = true;
		this.com_phys_vel_2d = true;
		sys_phys_simulate(this, dt);
		this.com_phys_vel_2d = false;
		this.com_phys_ground = false;
		this.com_phys_gravity = 0;
	}
	else
	{
		this.com_phys_acc_rate_air = PHYS_AIRACCELERATE(this) * min(maxspeed_mod, 1);
		this.com_phys_acc_rate_air_stop = PHYS_AIRSTOPACCELERATE(this) * maxspeed_mod;
		this.com_phys_acc_rate_air_strafe = PHYS_AIRSTRAFEACCELERATE(this) * maxspeed_mod;
		this.com_phys_vel_max_air_strafe = PHYS_MAXAIRSTRAFESPEED(this) * maxspeed_mod;
		this.com_phys_vel_max_air = PHYS_MAXAIRSPEED(this) * maxspeed_mod;
		this.com_phys_vel_max = PHYS_MAXAIRSPEED(this) * min(maxspeed_mod, 1);
		this.com_phys_air = true;
		this.com_phys_vel_2d = true;
		sys_phys_simulate(this, dt);
		this.com_phys_vel_2d = false;
		this.com_phys_air = false;
	}

	sys_phys_postupdate(this);
}

void sys_phys_postupdate(entity this)
{
	if (IS_ONGROUND(this))
		this.lastground = time;
	// conveyors: then break velocity again
	if (this.conveyor.active)
		this.velocity += this.conveyor.movedir;
	this.lastflags = this.flags;

	this.lastclassname = this.classname;
}

/** for players */
void sys_phys_simulate(entity this, float dt)
{
	if (!this.com_phys_ground && !this.com_phys_air)
	{
		// noclipping
		// flying
		// on a spawnfunc_func_ladder
		// swimming in spawnfunc_func_water
		// swimming
		UNSET_ONGROUND(this);

		if (this.com_phys_friction_air > 0)
		{
			const float grav = -this.com_phys_gravity;
			this.velocity_z += grav / 2;
			this.velocity = this.velocity * (1 - dt * this.com_phys_friction);
			this.velocity_z += grav / 2;
		}
	}

	if (this.com_phys_water)
	{
		// water jump only in certain situations
		// this mimics quakeworld code
		if (this.com_in_jump
		&&  this.waterlevel == WATERLEVEL_SWIMMING
		&&  this.velocity_z >= -180
		&& !this.viewloc
		&& !PHYS_FROZEN(this))
		{
			vector yawangles = eY * this.v_angle.y;
			vector forward, right, up;
			MAKE_VECTORS(yawangles, forward, right, up);
			vector spot = this.origin + 24 * forward;
			spot_z += 8;
			traceline(spot, spot, MOVE_NOMONSTERS, this);
			if (trace_startsolid)
			{
				spot_z += 24;
				traceline(spot, spot, MOVE_NOMONSTERS, this);
				if (!trace_startsolid)
				{
					this.velocity = forward * 50;
					this.velocity_z = 310;
					UNSET_ONGROUND(this);
					SET_JUMP_HELD(this);
				}
			}
		}
	}

	vector forward, right, up;
	vector v_tmp = (this.com_phys_vel_2d ? vec3(0, this.v_angle.y, 0) : this.v_angle);
	MAKE_VECTORS(v_tmp, forward, right, up);
	// wishvel = forward * PHYS_CS(this).movement.x + right * PHYS_CS(this).movement.y + up * PHYS_CS(this).movement.z;
	vector wishvel = forward * PHYS_CS(this).movement.x
		+ right * PHYS_CS(this).movement.y
		+ eZ * (this.com_phys_vel_2d ? 0 : PHYS_CS(this).movement.z);
	if (this.com_phys_water)
	{
		if (PHYS_FROZEN(this))
		{
			if(this.waterlevel >= WATERLEVEL_SUBMERGED && this.velocity.z >= -70) // don't change the speed too abruptally
				wishvel = '0 0 160'; // resurface
			else if(this.waterlevel >= WATERLEVEL_SWIMMING && this.velocity.z > 0)
				wishvel = eZ * (1.3 * min(this.velocity.z, 160)); // resurface a bit more above the surface
		}
		else
		{
			if (PHYS_INPUT_BUTTON_CROUCH(this))
				wishvel.z = -PHYS_MAXSPEED(this);
			if (this.viewloc)
				wishvel.z = -160;    // drift anyway
			else if (wishvel == '0 0 0')
				wishvel.z = -60; // drift towards bottom
		}
	}
	if (this.com_phys_ladder)
	{
		if (this.viewloc)
			wishvel.z = PHYS_CS(this).movement_old.x;

		if (this.ladder_entity.classname == "func_water")
		{
			float f = vlen(wishvel);
			if (f > this.ladder_entity.speed)
				wishvel *= (this.ladder_entity.speed / f);

			this.watertype = this.ladder_entity.skin;
			f = this.ladder_entity.origin_z + this.ladder_entity.maxs_z;
			if ((this.origin_z + this.view_ofs_z) < f)
				this.waterlevel = WATERLEVEL_SUBMERGED;
			else if ((this.origin_z + (this.mins_z + this.maxs_z) * 0.5) < f)
				this.waterlevel = WATERLEVEL_SWIMMING;
			else if ((this.origin_z + this.mins_z + 1) < f)
				this.waterlevel = WATERLEVEL_WETFEET;
			else
			{
				this.waterlevel = WATERLEVEL_NONE;
				this.watertype = CONTENT_EMPTY;
			}
		}
	}

	// acceleration
	float wishspeed = vlen(wishvel);
	// Mathematically equivalent to normalize(wishvel) but more closely matches Q3
	// which uses the same single-precision optimisation to save one sqrt()
	const vector wishdir = wishspeed ? wishvel * (1 / wishspeed) : '0 0 0';
	wishspeed = min(wishspeed, this.com_phys_vel_max);

	if (this.com_phys_air)
	{
		if (!(this.flags & FL_WATERJUMP))
		{
			// apply air speed limit
			float airaccelqw = PHYS_AIRACCEL_QW(this);
			float wishspeed0 = wishspeed;
			const float maxairspd = this.com_phys_vel_max;
			wishspeed = min(wishspeed, maxairspd);
			if (IS_DUCKED(this))
				wishspeed *= 0.5;

			float airaccel = this.com_phys_acc_rate_air;

			float accelerating = (this.velocity * wishdir > 0);
			float wishspeed2 = wishspeed;

			// CPM: air control
			if (PHYS_AIRSTOPACCELERATE(this))
			{
				const float dot = normalize(vec2(this.velocity)) * wishdir;
				if (dot < 0)
				{
					if (PHYS_AIRSTOPACCELERATE_FULL(this))
						airaccel = this.com_phys_acc_rate_air_stop; // full slow-down
					else
						airaccel += (airaccel - this.com_phys_acc_rate_air_stop) * dot; // sinusoidal slow-down
				}
			}
			// note that for straight forward jumping:
			// step = accel * dt * wishspeed0;
			// accel  = bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
			// -->
			// dv/dt = accel * maxspeed (when slow)
			// dv/dt = accel * maxspeed * (1 - accelqw) (when fast)
			// log dv/dt = logaccel + logmaxspeed (when slow)
			// log dv/dt = logaccel + logmaxspeed + log(1 - accelqw) (when fast)
			float strafity = IsMoveInDirection(PHYS_CS(this).movement, -90) + IsMoveInDirection(PHYS_CS(this).movement, +90);  // if one is nonzero, other is always zero
			if (PHYS_MAXAIRSTRAFESPEED(this))
				wishspeed = min(wishspeed, GeomLerp(this.com_phys_vel_max_air,
				                                    strafity,
				                                    this.com_phys_vel_max_air_strafe));

			if (PHYS_AIRSTRAFEACCELERATE(this))
				airaccel = GeomLerp(airaccel, strafity, this.com_phys_acc_rate_air_strafe);

			if (PHYS_AIRSTRAFEACCEL_QW(this))
				airaccelqw =
					(((strafity > 0.5 ? PHYS_AIRSTRAFEACCEL_QW(this) : PHYS_AIRACCEL_QW(this)) >= 0) ? +1 : -1)
					*
					(1 - GeomLerp(1 - fabs(PHYS_AIRACCEL_QW(this)), strafity, 1 - fabs(PHYS_AIRSTRAFEACCEL_QW(this))));
			// !CPM

			if (PHYS_WARSOWBUNNY_TURNACCEL(this) && accelerating && PHYS_CS(this).movement.y == 0 && PHYS_CS(this).movement.x != 0)
				PM_AirAccelerate(this, dt, wishdir, wishspeed2);
			else
			{
				float sidefric = maxairspd ? (PHYS_AIRACCEL_SIDEWAYS_FRICTION(this) / maxairspd) : 0;
				PM_Accelerate(this, dt, wishdir, wishspeed, wishspeed0, airaccel, airaccelqw,
					PHYS_AIRACCEL_QW_STRETCHFACTOR(this), sidefric, PHYS_AIRSPEEDLIMIT_NONQW(this));
			}

			if (PHYS_AIRCONTROL(this))
				CPM_PM_Aircontrol(this, dt, wishdir, wishspeed2);
		}
	}
	else
	{
		if (this.com_phys_ground && IS_DUCKED(this))
			wishspeed *= 0.5;

		if (this.com_phys_water)
		{
			wishspeed *= 0.7;

			//	if (!(this.flags & FL_WATERJUMP)) // TODO: use
			{
				// water friction
				float f = 1 - dt * PHYS_FRICTION(this);
				this.velocity *= bound(0, f, 1);

				f = wishspeed - this.velocity * wishdir;
				if (f > 0)
				{
					float accelspeed = min(PHYS_ACCELERATE(this) * dt * wishspeed, f);
					this.velocity += accelspeed * wishdir;
				}

				// holding jump button swims upward slowly
				if (this.com_in_jump && !this.viewloc && !PHYS_FROZEN(this))
				{
					// was:
					// lava: 50
					// slime: 80
					// water: 100
					// idea: double those
					if (this.waterlevel >= WATERLEVEL_SUBMERGED)
						this.velocity_z = PHYS_MAXSPEED(this) * 0.7;
					else
						this.velocity_z = 200;
				}
			}
			if (this.viewloc)
			{
				const float addspeed = wishspeed - this.velocity * wishdir;
				if (addspeed > 0)
				{
					const float accelspeed = min(PHYS_ACCELERATE(this) * dt * wishspeed, addspeed);
					this.velocity += accelspeed * wishdir;
				}
			}
			else
			{
				// water acceleration
				PM_Accelerate(this, dt, wishdir, wishspeed, wishspeed, this.com_phys_acc_rate, 1, 0, 0, 0);
			}
			return;
		}
		if (this.com_phys_ground)
		{
			// apply edge friction
			const float f2 = vlen2(vec2(this.velocity));
			const int realfriction = (IS_ONSLICK(this))
				? PHYS_FRICTION_SLICK(this)
				: PHYS_FRICTION(this);
			if (f2 > 0 && realfriction > 0)
			{
				// TODO: apply edge friction
				// apply ground friction

				float f = sqrt(f2);
				const float S = PHYS_STOPSPEED(this);
				//f = 1 - dt * realfriction * ((f < S) ? (S / f) : 1);
				// k9er: documentation here https://gitlab.com/otta8634/xonotic-physics
				const float dt_r = PHYS_FRICTION_REPLICA_DT;
				// minor optimization, but it's only useful if friction > 1/dt_r
				//if (realfriction * dt_r >= 1)
				//	f = 0;
				//else
				{
					const float independent_geometric = (1 - realfriction * dt_r) ** (dt / dt_r);
					// NOTE: first condition ensures subframe accuracy in the geometric -> linear transition, may be not worth the hassle
					if (S < f && f < S / independent_geometric)
					{
						this.velocity = normalize(this.velocity);
						f = S - S * realfriction * (dt - (dt_r * log(S / f)) / log(1 - realfriction * dt_r));
					}
					else if (f >= S)
						f = independent_geometric;
					else
						f = 1 - realfriction * dt * S / f;
					f = max(0, f);
				}
				this.velocity *= f;
			}
			const float addspeed = wishspeed - this.velocity * wishdir;
			if (addspeed > 0)
			{
				const float accel = (IS_ONSLICK(this))
					? PHYS_SLICKACCELERATE(this)
					: PHYS_ACCELERATE(this);
				const float accelspeed = min(accel * dt * wishspeed, addspeed);
				this.velocity += accelspeed * wishdir;
			}
			return;
		}

		if (!(this.flags & FL_WATERJUMP))
			PM_Accelerate(this, dt, wishdir, wishspeed, wishspeed, this.com_phys_acc_rate, 1, 0, 0, 0);
	}
}

.entity groundentity;
/** for other entities */
void sys_phys_simulate_simple(entity this, float dt)
{
	vector mn = this.mins;
	vector mx = this.maxs;

	vector g = '0 0 0';
	if (this.com_phys_gravity_factor && !g)
		g = '0 0 -1' * PHYS_GRAVITY(NULL);

	vector vel = this.com_phys_vel;
	vector pos = this.com_phys_pos;

	// SV_Physics_Toss

	vel += g * dt;

	this.angles += dt * this.avelocity;
	float movetime = dt;
	for (int i = 0; i < MAX_CLIP_PLANES && movetime > 0; ++i)
	{
		vector push = vel * movetime;
		vector p0 = pos;
		vector p1 = p0 + push;
		// SV_PushEntity
		tracebox(p0, mn, mx, p1, MOVE_NORMAL, this);
		if (!trace_startsolid)
		{
			bool hit = trace_fraction < 1;
			pos = trace_endpos;
			entity ent = trace_ent;
			// SV_LinkEdict_TouchAreaGrid
			if (this.solid != SOLID_NOT)
			{
				FOREACH_ENTITY_RADIUS_ORDERED(0.5 * (this.absmin + this.absmax), 0.5 * vlen(this.absmax - this.absmin), true,
				{
					if (it.solid != SOLID_TRIGGER || it == this)
						continue;
					if (gettouch(it) && boxesoverlap(it.absmin, it.absmax, this.absmin, this.absmax))
					{
						// SV_LinkEdict_TouchAreaGrid_Call
						trace_allsolid = false;
						trace_startsolid = false;
						trace_fraction = 1;
						trace_inwater = false;
						trace_inopen = true;
						trace_endpos = it.origin;
						trace_plane_normal = '0 0 1';
						trace_plane_dist = 0;
						trace_ent = this;
						trace_dpstartcontents = 0;
						trace_dphitcontents = 0;
						trace_dphitq3surfaceflags = 0;
						trace_dphittexturename = string_null;
						gettouch(it)(this, it);
						vel = this.velocity;
					}
				});
			}
			if (hit && this.solid >= SOLID_TRIGGER && (!IS_ONGROUND(this) || this.groundentity != ent))
			{
				// SV_Impact (ent, trace);
				tracebox(p0, mn, mx, p1, MOVE_NORMAL, this);
				void(entity, entity) touched = gettouch(this);
				if (touched && this.solid != SOLID_NOT)
					touched(ent, this);

				void(entity, entity) touched2 = gettouch(ent);
				if (this && ent && touched2 && ent.solid != SOLID_NOT)
				{
					trace_endpos = ent.origin;
					trace_plane_normal *= -1;
					trace_plane_dist *= -1;
					trace_ent = this;
					trace_dpstartcontents = 0;
					trace_dphitcontents = 0;
					trace_dphitq3surfaceflags = 0;
					trace_dphittexturename = string_null;
					touched2(this, ent);
				}
			}
		}
		// end SV_PushEntity
		if (wasfreed(this))
			return;
		tracebox(p0, mn, mx, p1, MOVE_NORMAL, this);
		if (trace_fraction == 1)
			break;
		movetime *= 1 - min(1, trace_fraction);
		ClipVelocity(vel, trace_plane_normal, vel, 1);
	}

	this.com_phys_vel = vel;
	this.com_phys_pos = pos;
	setorigin(this, this.com_phys_pos);
}

void sys_phys_update_single(entity this)
{
	sys_phys_simulate_simple(this, frametime);
}
