#include "step.qh"

#ifdef SVQC
/// Minimal version of Physics_UpdateStats() for spawning NPCs
void _Movetype_Physics_Step_UpdateStats(entity this)
{
	STAT(MOVEVARS_GRAVITY, this) = autocvar_sv_gravity;
	STAT(GAMEPLAYFIX_STEPDOWN, this) = autocvar_sv_gameplayfix_stepdown;
	STAT(MOVEVARS_STEPHEIGHT, this) = autocvar_sv_stepheight;
}
#endif

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	_Movetype_Physics_Walk(this, dt);
}
