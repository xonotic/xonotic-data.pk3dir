#include "physics.qh"

float autocvar_sv_spectator_speed_multiplier;
float autocvar_sv_spectator_speed_multiplier_min = 1;
float autocvar_sv_spectator_speed_multiplier_max = 5;

void sys_phys_fix(entity this, float dt)
{
	WarpZone_PlayerPhysics_FixVAngle(this);
	Physics_UpdateStats(this);
	PM_ClientMovement_UpdateStatus(this);
}

bool sys_phys_override(entity this, float dt)
{
	int buttons = PHYS_INPUT_BUTTON_MASK(this);
	float idlesince = CS(this).parm_idlesince;
	CS(this).parm_idlesince = time; // in the case that physics are overridden
	if (PM_check_specialcommand(this, buttons))
		return true;
	if (this.PlayerPhysplug && this.PlayerPhysplug(this, dt))
		return true;
	CS(this).parm_idlesince = idlesince;
	return false;
}

void sys_phys_monitor(entity this, float dt)
{
	int buttons = PHYS_INPUT_BUTTON_MASK(this);
	anticheat_physics(this);

	// always do this so active players don't get kicked if sv_maxidle* get enabled mid-match
	if (!PHYS_INPUT_BUTTON_CHAT(this))
	if (buttons != CS(this).buttons_old
	|| CS(this).movement != CS(this).movement_old
	|| this.v_angle != CS(this).v_angle_old)
		CS(this).parm_idlesince = time;

	PM_check_punch(this, dt);
}

void sys_phys_ai(entity this)
{
	if (!IS_BOT_CLIENT(this))
		return;
	bot_think(this);
}

void sys_phys_pregame_hold(entity this)
{
	if (!IS_PLAYER(this))
		return;
	const bool allowed_to_move = (time >= game_starttime && !game_stopped);
	if (!allowed_to_move)
	{
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE);
		this.disableclientprediction = 2;
	}
	else if (this.disableclientprediction == 2)
	{
		if (this.move_movetype == MOVETYPE_NONE)
			set_movetype(this, MOVETYPE_WALK);
		this.disableclientprediction = 0;
	}
}

void sys_phys_spectator_control(entity this)
{
	float maxspeed_mod = autocvar_sv_spectator_speed_multiplier;
	if (!STAT(SPECTATORSPEED, this))
		STAT(SPECTATORSPEED, this) = maxspeed_mod;
	if ((CS(this).impulse >= 1   && CS(this).impulse <= 19)
	||  (CS(this).impulse >= 200 && CS(this).impulse <= 209)
	||  (CS(this).impulse >= 220 && CS(this).impulse <= 229))
	{
		if (this.lastclassname != STR_PLAYER)
		{
			if (CS(this).impulse == 10
			||  CS(this).impulse == 15
			||  CS(this).impulse == 18
			|| (CS(this).impulse >= 200 && CS(this).impulse <= 209))
			{
				STAT(SPECTATORSPEED, this) = bound(autocvar_sv_spectator_speed_multiplier_min,
				                                   STAT(SPECTATORSPEED, this) + 0.5,
				                                   autocvar_sv_spectator_speed_multiplier_max);
			}
			else if (CS(this).impulse == 11)
				STAT(SPECTATORSPEED, this) = maxspeed_mod;
			else if (CS(this).impulse == 12
			     ||  CS(this).impulse == 16
			     ||  CS(this).impulse == 19
			     || (CS(this).impulse >= 220 && CS(this).impulse <= 229))
			{
				STAT(SPECTATORSPEED, this) = bound(autocvar_sv_spectator_speed_multiplier_min,
				                                   STAT(SPECTATORSPEED, this) - 0.5,
				                                   autocvar_sv_spectator_speed_multiplier_max);
			}
			else if (CS(this).impulse >= 1 && CS(this).impulse <= 9)
				STAT(SPECTATORSPEED, this) = 1 + 0.5 * (CS(this).impulse - 1);
		}  // otherwise just clear
		CS(this).impulse = 0;
	}
}

void sys_phys_fixspeed(entity this, float maxspeed_mod)
{
	float spd = max(PHYS_MAXSPEED(this), PHYS_MAXAIRSPEED(this)) * maxspeed_mod;
	if (this.speed != spd)
	{
		this.speed = spd; // TODO: send this as a stat and set the below cvars on the client?
		string temps = ftos(spd);
		stuffcmd(this, strcat("cl_forwardspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_backspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_sidespeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_upspeed ", temps, "\n"));
	}

	if (this.jumpspeedcap_min != autocvar_sv_jumpspeedcap_min)
	{
		this.jumpspeedcap_min = autocvar_sv_jumpspeedcap_min;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_min \"%s\"\n", autocvar_sv_jumpspeedcap_min));
	}
	if (this.jumpspeedcap_max != autocvar_sv_jumpspeedcap_max)
	{
		this.jumpspeedcap_max = autocvar_sv_jumpspeedcap_max;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_max \"%s\"\n", autocvar_sv_jumpspeedcap_max));
	}
}

void sys_phys_land(entity this)
{
	if (autocvar_speedmeter)
		LOG_TRACEF("landing velocity: %v (abs: %f)", this.velocity, vlen(this.velocity));

	if (this.jumppadcount > 1)
		LOG_TRACEF("%dx jumppad combo", this.jumppadcount);

	this.jumppadcount = 0;
}

STATIC_INIT(sys_phys)
{
	entity listener = new_pure(sys_phys);
	subscribe(listener, phys_land, sys_phys_land);
}
