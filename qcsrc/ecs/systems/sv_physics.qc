#include "physics.qh"

void sys_phys_fix(entity this, float dt)
{
	WarpZone_PlayerPhysics_FixVAngle(this);
	STAT(MOVEVARS_HIGHSPEED, this) = autocvar_g_movement_highspeed;
	MUTATOR_CALLHOOK(PlayerPhysics_UpdateStats, this); // do it BEFORE the function so we can modify highspeed!
	Physics_UpdateStats(this, PHYS_HIGHSPEED(this));
}

bool sys_phys_override(entity this, float dt)
{
	int buttons = PHYS_INPUT_BUTTON_MASK(this);
	float idlesince = this.parm_idlesince;
	this.parm_idlesince = time; // in the case that physics are overridden
	if (PM_check_specialcommand(this, buttons)) { return true; }
	if (this.PlayerPhysplug && this.PlayerPhysplug(this, dt)) { return true; }
	this.parm_idlesince = idlesince;
	return false;
}

void sys_phys_monitor(entity this, float dt)
{
	int buttons = PHYS_INPUT_BUTTON_MASK(this);
	anticheat_physics(this);
	if (sv_maxidle > 0) {
		if (buttons != this.buttons_old
		    || this.movement != this.movement_old
		    || this.v_angle != this.v_angle_old) { this.parm_idlesince = time; }
	}
	PM_check_nickspam(this);
	PM_check_punch(this, dt);
}

void sys_phys_ai(entity this)
{
	if (!IS_BOT_CLIENT(this)) { return; }
	if (playerdemo_read(this)) { return; }
	bot_think(this);
}

void sys_phys_pregame_hold(entity this)
{
	if (!IS_PLAYER(this)) { return; }
	const bool allowed_to_move = (time >= game_starttime && !game_stopped);
	if (!allowed_to_move) {
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE);
		this.disableclientprediction = 2;
	} else if (this.disableclientprediction == 2) {
		if (this.move_movetype == MOVETYPE_NONE) { set_movetype(this, MOVETYPE_WALK); }
		this.disableclientprediction = 0;
	}
}

void sys_phys_spectator_control(entity this)
{
	float maxspeed_mod = autocvar_sv_spectator_speed_multiplier;
	if (!this.spectatorspeed) { this.spectatorspeed = maxspeed_mod; }
	if ((this.impulse >= 1 && this.impulse <= 19)
	    || (this.impulse >= 200 && this.impulse <= 209)
	    || (this.impulse >= 220 && this.impulse <= 229)
	   ) {
		if (this.lastclassname != STR_PLAYER) {
			if (this.impulse == 10
			    || this.impulse == 15
			    || this.impulse == 18
			    || (this.impulse >= 200 && this.impulse <= 209)
			   ) { this.spectatorspeed = bound(1, this.spectatorspeed + 0.5, 5); } else if (this.impulse == 11) {
				this.spectatorspeed = maxspeed_mod;
			} else if (this.impulse == 12
			    || this.impulse == 16
			    || this.impulse == 19
			    || (this.impulse >= 220 && this.impulse <= 229)
			          ) {
				this.spectatorspeed = bound(1, this.spectatorspeed - 0.5, 5);
			} else if (this.impulse >= 1 && this.impulse <= 9) {
				this.spectatorspeed = 1 + 0.5 * (this.impulse - 1);
			}
		}  // otherwise just clear
		this.impulse = 0;
	}
}

void sys_phys_fixspeed(entity this, float maxspeed_mod)
{
	float spd = max(PHYS_MAXSPEED(this), PHYS_MAXAIRSPEED(this)) * maxspeed_mod;
	if (this.speed != spd) {
		this.speed = spd;
		string temps = ftos(spd);
		stuffcmd(this, strcat("cl_forwardspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_backspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_sidespeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_upspeed ", temps, "\n"));
	}

	if (this.jumpspeedcap_min != autocvar_sv_jumpspeedcap_min) {
		this.jumpspeedcap_min = autocvar_sv_jumpspeedcap_min;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_min \"%s\"\n", autocvar_sv_jumpspeedcap_min));
	}
	if (this.jumpspeedcap_max != autocvar_sv_jumpspeedcap_max) {
		this.jumpspeedcap_max = autocvar_sv_jumpspeedcap_max;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_max \"%s\"\n", autocvar_sv_jumpspeedcap_max));
	}
}

void sys_phys_land(entity this)
{
	if (autocvar_speedmeter) {
		LOG_TRACEF("landing velocity: %v (abs: %f)", this.velocity, vlen(this.velocity));
	}
	if (this.jumppadcount > 1) {
		LOG_TRACEF("%dx jumppad combo", this.jumppadcount);
	}
	this.jumppadcount = 0;
}

STATIC_INIT(sys_phys)
{
	entity listener = new_pure(sys_phys);
	subscribe(listener, phys_land, sys_phys_land);
}
