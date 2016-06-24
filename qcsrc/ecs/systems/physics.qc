#include "physics.qh"
#include "input.qh"

.int disableclientprediction;

void sys_phys_simulate(entity this, float dt);

void sys_phys_update(entity this, float dt)
{
	sys_in_update(this, dt);

	sys_phys_fix(this, dt);
	if (sys_phys_override(this)) { return; } sys_phys_monitor(this);

	int buttons_prev = this.buttons_old;
	this.buttons_old = PHYS_INPUT_BUTTON_MASK(this);
	this.movement_old = this.movement;
	this.v_angle_old = this.v_angle;

	sys_phys_ai(this);

	sys_phys_pregame_hold(this);

	if (IS_SVQC) {
		if (PHYS_MOVETYPE(this) == MOVETYPE_NONE) { return; }
		// when we get here, disableclientprediction cannot be 2
		this.disableclientprediction = 0;
	}

	viewloc_PlayerPhysics(this);

	PM_check_frozen(this);

	PM_check_blocked(this);

	float maxspeed_mod = (!this.in_swamp) ? 1 : this.swamp_slowdown;  // cvar("g_balance_swamp_moverate");

// conveyors: first fix velocity
	if (this.conveyor.state) { this.velocity -= this.conveyor.movedir; }
	MUTATOR_CALLHOOK(PlayerPhysics, this);

	if (!IS_PLAYER(this)) {
		sys_phys_spectator_control(this);
		maxspeed_mod = this.spectatorspeed;
	}
	sys_phys_fixspeed(this, maxspeed_mod);

	if (IS_DEAD(this)) {
		// handle water here
		vector midpoint = ((this.absmin + this.absmax) * 0.5);
		if (pointcontents(midpoint) == CONTENT_WATER) {
			this.velocity = this.velocity * 0.5;

			// do we want this?
			// if(pointcontents(midpoint + '0 0 2') == CONTENT_WATER)
			// { this.velocity_z = 70; }
		}
		goto end;
	}

	if (IS_SVQC && !PHYS_FIXANGLE(this)) { this.angles = '0 1 0' * this.v_angle.y; }
	if (IS_PLAYER(this)) {
		if (IS_ONGROUND(this)) {
			PM_check_hitground(this);
			PM_Footsteps(this);
		} else if (IsFlying(this)) {
			this.wasFlying = true;
		}
		CheckPlayerJump(this);
	}

	if (this.flags & FL_WATERJUMP) {
		this.velocity_x = this.movedir.x;
		this.velocity_y = this.movedir.y;
		if (time > PHYS_TELEPORT_TIME(this)
		    || this.waterlevel == WATERLEVEL_NONE
		    || PHYS_WATERJUMP_TIME(this) <= 0
		   ) {
			this.flags &= ~FL_WATERJUMP;
			PHYS_TELEPORT_TIME(this) = 0;
			PHYS_WATERJUMP_TIME(this) = 0;
		}
	} else if (MUTATOR_CALLHOOK(PM_Physics, this, maxspeed_mod)) {
		// handled
	} else if (PHYS_MOVETYPE(this) == MOVETYPE_NOCLIP
	    || PHYS_MOVETYPE(this) == MOVETYPE_FLY
	    || PHYS_MOVETYPE(this) == MOVETYPE_FLY_WORLDONLY
	    || MUTATOR_CALLHOOK(IsFlying, this)) {
		this.com_phys_friction = PHYS_FRICTION(this);
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_acc_rate = PHYS_ACCELERATE(this) * maxspeed_mod;
		sys_phys_simulate(this, dt);
	} else if (this.waterlevel >= WATERLEVEL_SWIMMING) {
		PM_swim(this, maxspeed_mod);
	} else if (time < this.ladder_time) {
		this.com_phys_friction = PHYS_FRICTION(this);
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_acc_rate = PHYS_ACCELERATE(this) * maxspeed_mod;
		this.com_phys_gravity = '0 0 -1' * PHYS_GRAVITY(this) * dt;
		if (PHYS_ENTGRAVITY(this)) { this.com_phys_gravity *= PHYS_ENTGRAVITY(this); }
		this.com_phys_ladder = true;
		sys_phys_simulate(this, dt);
		this.com_phys_ladder = false;
		this.com_phys_gravity = '0 0 0';
	} else if (ITEMS_STAT(this) & IT_USING_JETPACK) {
		PM_jetpack(this, maxspeed_mod);
	} else if (IS_ONGROUND(this)) {
		if (!WAS_ONGROUND(this)) {
			emit(phys_land, this);
			if (this.lastground < time - 0.3) {
				this.velocity *= (1 - PHYS_FRICTION_ONLAND(this));
			}
		}
		this.com_phys_vel_max = PHYS_MAXSPEED(this) * maxspeed_mod;
		this.com_phys_gravity = '0 0 -1' * PHYS_GRAVITY(this) * dt;
		if (PHYS_ENTGRAVITY(this)) { this.com_phys_gravity *= PHYS_ENTGRAVITY(this); }
		this.com_phys_ground = true;
		this.com_phys_vel_2d = true;
		sys_phys_simulate(this, dt);
		this.com_phys_vel_2d = false;
		this.com_phys_ground = false;
		this.com_phys_gravity = '0 0 0';
	} else {
		PM_air(this, buttons_prev, maxspeed_mod);
	}

	LABEL(end)
	if (IS_ONGROUND(this)) { this.lastground = time; }
// conveyors: then break velocity again
	if (this.conveyor.state) { this.velocity += this.conveyor.movedir; }
	this.lastflags = this.flags;

	this.lastclassname = this.classname;
}

void sys_phys_simulate(entity this, float dt)
{
	const float g = -this.com_phys_gravity.z;
	if (!this.com_phys_ground) {
		// noclipping
		// flying
		// on a spawnfunc_func_ladder
		// swimming in spawnfunc_func_water
		UNSET_ONGROUND(this);

		this.velocity_z += g / 2;
		this.velocity = this.velocity * (1 - dt * this.com_phys_friction);
		this.velocity_z += g / 2;
	}

	makevectors(vmul(this.v_angle, (this.com_phys_vel_2d ? '0 1 0' : '1 1 1')));
	// wishvel = v_forward * this.movement.x + v_right * this.movement.y + v_up * this.movement.z;
	vector wishvel = v_forward * this.movement.x
	    + v_right * this.movement.y
	    + '0 0 1' * this.movement.z * (this.com_phys_vel_2d ? 0 : 1);
	if (this.com_phys_ladder) {
		if (this.viewloc) {
			wishvel.z = this.oldmovement.x;
		}
		if (this.ladder_entity.classname == "func_water") {
			float f = vlen(wishvel);
			if (f > this.ladder_entity.speed) {
				wishvel *= (this.ladder_entity.speed / f);
			}

			this.watertype = this.ladder_entity.skin;
			f = this.ladder_entity.origin_z + this.ladder_entity.maxs_z;
			if ((this.origin_z + this.view_ofs_z) < f) {
				this.waterlevel = WATERLEVEL_SUBMERGED;
			} else if ((this.origin_z + (this.mins_z + this.maxs_z) * 0.5) < f) {
				this.waterlevel = WATERLEVEL_SWIMMING;
			} else if ((this.origin_z + this.mins_z + 1) < f) {
				this.waterlevel = WATERLEVEL_WETFEET;
			} else {
				this.waterlevel = WATERLEVEL_NONE;
				this.watertype = CONTENT_EMPTY;
			}
		}
	}
	// acceleration
	const vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), this.com_phys_vel_max);

	if (this.com_phys_ground) {
		if (IS_DUCKED(this)) { wishspeed *= 0.5; }

		// apply edge friction
		const float f2 = vlen2(vec2(this.velocity));
		if (f2 > 0) {
			trace_dphitq3surfaceflags = 0;
			tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
			// TODO: apply edge friction
			// apply ground friction
			const int realfriction = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
			    ? PHYS_FRICTION_SLICK(this)
				: PHYS_FRICTION(this);

			float f = sqrt(f2);
			f = 1 - PHYS_INPUT_TIMELENGTH * realfriction
			    * ((f < PHYS_STOPSPEED(this)) ? (PHYS_STOPSPEED(this) / f) : 1);
			f = max(0, f);
			this.velocity *= f;
			/*
			   Mathematical analysis time!

			   Our goal is to invert this mess.

			   For the two cases we get:
			    v = v0 * (1 - PHYS_INPUT_TIMELENGTH * (PHYS_STOPSPEED(this) / v0) * PHYS_FRICTION(this))
			      = v0 - PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this)
			    v0 = v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this)
			   and
			    v = v0 * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
			    v0 = v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))

			   These cases would be chosen ONLY if:
			    v0 < PHYS_STOPSPEED(this)
			    v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this) < PHYS_STOPSPEED(this)
			    v < PHYS_STOPSPEED(this) * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
			   and, respectively:
			    v0 >= PHYS_STOPSPEED(this)
			    v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this)) >= PHYS_STOPSPEED(this)
			    v >= PHYS_STOPSPEED(this) * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
			 */
		}
		const float addspeed = wishspeed - this.velocity * wishdir;
		if (addspeed > 0) {
			const float accelspeed = min(PHYS_ACCELERATE(this) * PHYS_INPUT_TIMELENGTH * wishspeed, addspeed);
			this.velocity += accelspeed * wishdir;
		}
		if (IS_CSQC && vdist(this.velocity, >, 0)) {
			PM_ClientMovement_Move(this);
		}
		return;
	}

	if (IS_CSQC || time >= PHYS_TELEPORT_TIME(this)) {
		PM_Accelerate(this, wishdir, wishspeed, wishspeed, this.com_phys_acc_rate, 1, 0, 0, 0);
	}
	PM_ClientMovement_Move(this);
}
