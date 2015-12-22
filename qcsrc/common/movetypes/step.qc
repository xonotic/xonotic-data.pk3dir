void _Movetype_Physics_Step(entity this, float dt) // SV_Physics_Step
{
	if(this.move_flags & FL_ONGROUND)
	{
		if(this.velocity_z >= (1.0 / 32.0) && UPWARD_VELOCITY_CLEARS_ONGROUND(this))
		{
			this.move_flags &= ~FL_ONGROUND;
			_Movetype_CheckVelocity(this);
			_Movetype_FlyMove(this, dt, true, '0 0 0', 0);
			_Movetype_LinkEdict(this, true);
		}
	}
	else
	{
		_Movetype_CheckVelocity(this);
		_Movetype_FlyMove(this, dt, true, '0 0 0', 0);
		_Movetype_LinkEdict(this, true);

		// TODO? movetypesteplandevent
	}

	_Movetype_CheckWaterTransition(this);
}
