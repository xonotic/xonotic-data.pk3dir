#include "physics.qh"
#include "input.qh"

.int disableclientprediction;

void sys_phys_update(entity this, float dt)
{
	sys_in_update(this, dt);

	sys_phys_fix(this, dt);
	if (sys_phys_override(this)) return;
	sys_phys_monitor(this);

	int buttons_prev = this.buttons_old;
	this.buttons_old = PHYS_INPUT_BUTTON_MASK(this);
	this.movement_old = this.movement;
	this.v_angle_old = this.v_angle;

	sys_phys_ai(this);

	sys_phys_pregame_hold(this);

	if (IS_SVQC) {
		if (PHYS_MOVETYPE(this) == MOVETYPE_NONE) return;

		// when we get here, disableclientprediction cannot be 2
		this.disableclientprediction = 0;
	}

	viewloc_PlayerPhysics(this);

	PM_check_frozen(this);

	PM_check_blocked(this);

	float maxspeed_mod = (!this.in_swamp) ? 1 : this.swamp_slowdown; // cvar("g_balance_swamp_moverate");

// conveyors: first fix velocity
	if (this.conveyor.state) this.velocity -= this.conveyor.movedir;

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

	if (IS_SVQC && !PHYS_FIXANGLE(this)) this.angles = '0 1 0' * this.v_angle.y;

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
		PM_fly(this, maxspeed_mod);
	} else if (this.waterlevel >= WATERLEVEL_SWIMMING) {
		PM_swim(this, maxspeed_mod);
	} else if (time < this.ladder_time) {
		PM_ladder(this, maxspeed_mod);
	} else if (ITEMS_STAT(this) & IT_USING_JETPACK) {
		PM_jetpack(this, maxspeed_mod);
	} else if (IS_ONGROUND(this)) {
		PM_walk(this, maxspeed_mod);
	} else {
		PM_air(this, buttons_prev, maxspeed_mod);
	}

	LABEL(end)
	if (IS_ONGROUND(this)) this.lastground = time;

// conveyors: then break velocity again
	if (this.conveyor.state) this.velocity += this.conveyor.movedir;

	this.lastflags = this.flags;

	this.lastclassname = this.classname;
}
