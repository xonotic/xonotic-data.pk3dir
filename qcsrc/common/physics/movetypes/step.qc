#include "step.qh"

void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	if(IS_ONGROUND(this))
	{
		if(this.velocity_z >= (1.0 / 32.0) && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			UNSET_ONGROUND(this);
			_Movetype_CheckVelocity(this);
			_Movetype_FlyMove(this, dt, true, false, 0);
			setorigin(this, this.origin); // SV_LinkEdict
			_Movetype_LinkEdict_TouchAreaGrid(this);
		}
	}
	else
	{
		_Movetype_CheckVelocity(this);
		_Movetype_FlyMove(this, dt, true, false, 0);
		setorigin(this, this.origin); // SV_LinkEdict
		_Movetype_LinkEdict_TouchAreaGrid(this);

		// TODO? movetypesteplandevent
	}

	_Movetype_CheckWaterTransition(this);
}
