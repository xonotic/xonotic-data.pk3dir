void _Movetype_Physics_Step(float dt) // SV_Physics_Step
{SELFPARAM();
	if(self.move_flags & FL_ONGROUND)
	{
		if(self.velocity_z >= (1.0 / 32.0) && UPWARD_VELOCITY_CLEARS_ONGROUND)
		{
			self.move_flags &= ~FL_ONGROUND;
			_Movetype_CheckVelocity();
			_Movetype_FlyMove(dt, true, '0 0 0', 0);
			_Movetype_LinkEdict(true);
		}
	}
	else
	{
		_Movetype_CheckVelocity();
		_Movetype_FlyMove(dt, true, '0 0 0', 0);
		_Movetype_LinkEdict(true);

		// TODO? movetypesteplandevent
	}

	_Movetype_CheckWaterTransition(self);
}
