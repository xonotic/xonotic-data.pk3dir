#include "physics.qh"

void sys_phys_fix(entity this, float dt)
{
	this.team = myteam + 1; // is this correct?
	this.movement = PHYS_INPUT_MOVEVALUES(this);
	this.items = STAT(ITEMS, this);
	if (!(PHYS_INPUT_BUTTON_JUMP(this))) // !jump
		UNSET_JUMP_HELD(this);           // canjump = true
	PM_ClientMovement_UpdateStatus(this);
}

bool sys_phys_override(entity this, float dt)
{
	// no vehicle prediction
	return hud != HUD_NORMAL;
}

void sys_phys_monitor(entity this, float dt) {}

void sys_phys_ai(entity this) {}

void sys_phys_pregame_hold(entity this) {}

void sys_phys_spectator_control(entity this) {}

void sys_phys_fixspeed(entity this, float maxspeed_mod)
{
	float spd = max(PHYS_MAXSPEED(this), PHYS_MAXAIRSPEED(this)) * maxspeed_mod;
	if (this.speed != spd) {
		this.speed = spd;
		string temps = ftos(spd);
		cvar_set("cl_forwardspeed", temps);
		cvar_set("cl_backspeed", temps);
		cvar_set("cl_sidespeed", temps);
		cvar_set("cl_upspeed", temps);
	}
}
