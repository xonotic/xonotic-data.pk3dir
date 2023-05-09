#include "step.qh"

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	// NPCs don't use sys_phys_update() so this is needed here
	PM_GroundTrace(this, this.velocity, true);

	_Movetype_Physics_Walk(this, dt);
}
