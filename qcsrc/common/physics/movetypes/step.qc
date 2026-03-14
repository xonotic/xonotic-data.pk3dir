#include "step.qh"

#ifdef SVQC
/// Minimal version of Physics_UpdateStats() for spawning NPCs
void _Movetype_Physics_Step_UpdateStats(entity this)
{
	STAT(GAMEPLAYFIX_STEPDOWN, this) = autocvar_sv_gameplayfix_stepdown;
	STAT(MOVEVARS_STEPHEIGHT, this) = autocvar_sv_stepheight;
	// HACK: gravity isn't set here, instead a condition in the PHYS_GRAVITY macro is relied on,
	// this prevents 0 from meaning 0 gravity, which could be solved by removing the condition from the macro
	// and setting/updating the gravity STAT (field) on non-player entities which need it.
	//STAT(MOVEVARS_GRAVITY, this) = autocvar_sv_gravity;
}
#endif

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	_Movetype_Physics_Walk(this, dt);
}
