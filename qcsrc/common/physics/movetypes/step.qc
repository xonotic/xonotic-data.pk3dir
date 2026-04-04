#include "step.qh"

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	_Movetype_Physics_Walk(this, dt);
}
