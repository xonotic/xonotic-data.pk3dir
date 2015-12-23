void _Movetype_PushMove(entity this, float dt)  // SV_PushMove
{
	if (this.move_velocity == '0 0 0' && this.move_avelocity == '0 0 0')
	{
		this.move_ltime += dt;
		return;
	}

	switch (this.solid)
	{
		// LordHavoc: valid pusher types
		case SOLID_BSP:
		case SOLID_BBOX:
		case SOLID_SLIDEBOX:
		case SOLID_CORPSE:  // LordHavoc: this would be weird...
			break;
		// LordHavoc: no collisions
		case SOLID_NOT:
		case SOLID_TRIGGER:
			this.move_origin = this.move_origin + dt * this.move_velocity;
			this.move_angles = this.move_angles + dt * this.move_avelocity;
			this.move_angles_x -= 360.0 * floor(this.move_angles.x * (1.0 / 360.0));
			this.move_angles_y -= 360.0 * floor(this.move_angles.y * (1.0 / 360.0));
			this.move_angles_z -= 360.0 * floor(this.move_angles.z * (1.0 / 360.0));
			this.move_ltime += dt;
			_Movetype_LinkEdict(this, true);
			return;
		default:
			LOG_TRACEF("_Movetype_PushMove: entity %e, unrecognized solid type %d\n", this, this.solid);
			return;
	}

	bool rotated = (this.move_angles * this.move_angles) + (this.move_avelocity * this.move_avelocity) > 0;

	vector move1 = this.move_velocity * dt;
	vector moveangle = this.move_avelocity * dt;

	makevectors_matrix(-moveangle);

//	vector pushorig = this.move_origin;
//	vector pushang = this.move_angles;
//	float pushltime = this.move_ltime;

// move the pusher to its final position

	this.move_origin = this.move_origin + dt * this.move_velocity;
	this.move_angles = this.move_angles + dt * this.move_avelocity;

	this.move_ltime += dt;
	_Movetype_LinkEdict(this, true);

	int savesolid = this.solid;

	if (this.move_movetype != MOVETYPE_FAKEPUSH)
	{
		for (entity check = findradius(0.5 * (this.absmin + this.absmax), 0.5 * vlen(this.absmax - this.absmin)); check; check = check.chain)
		{
			switch (check.move_movetype)
			{
				case MOVETYPE_NONE:
				case MOVETYPE_PUSH:
				case MOVETYPE_FOLLOW:
				case MOVETYPE_NOCLIP:
				case MOVETYPE_FLY_WORLDONLY:
					continue;
				default:
					break;
			}

			if (check.owner == this)
				continue;

			if (this.owner == check)
				continue;

			vector pivot = check.mins + 0.5 * (check.maxs - check.mins);
			vector move;
			if (rotated)
			{
				vector org = (check.move_origin - this.move_origin) + pivot;
				vector org2;
				org2.x = org * v_forward;
				org2.y = org * v_right;
				org2.z = org * v_up;
				move = (org2 - org) + move1;
			}
			else
			{
				move = move1;
			}

			// physics objects need better collisions than this code can do
			if (check.move_movetype == 32)  // MOVETYPE_PHYSICS
			{
				check.move_origin = check.move_origin + move;
				WITH(entity, this, check, _Movetype_LinkEdict(this, true));
				continue;
			}

			// try moving the contacted entity
			this.solid = SOLID_NOT;
			bool flag = false;
			WITH(entity, this, check, {
				flag = _Movetype_PushEntity(this, move, true);
			});
			if (!flag)
			{
				// entity "check" got teleported
				check.move_angles_y += trace_fraction * moveangle.y;
				this.solid = savesolid;
				continue;  // pushed enough
			}
			// FIXME: turn players specially
			check.move_angles_y += trace_fraction * moveangle.y;
			this.solid = savesolid;

			// this trace.fraction < 1 check causes items to fall off of pushers
			// if they pass under or through a wall
			// the groundentity check causes items to fall off of ledges
			if (check.move_movetype != MOVETYPE_WALK && (trace_fraction < 1 || check.move_groundentity != this))
				check.move_flags &= ~FL_ONGROUND;
		}
	}

	this.move_angles_x -= 360.0 * floor(this.move_angles.x * (1.0 / 360.0));
	this.move_angles_y -= 360.0 * floor(this.move_angles.y * (1.0 / 360.0));
	this.move_angles_z -= 360.0 * floor(this.move_angles.z * (1.0 / 360.0));
}

void _Movetype_Physics_Pusher(entity this, float dt)  // SV_Physics_Pusher
{
	float oldltime = this.move_ltime;
	float thinktime = this.move_nextthink;
	float movetime;
	if (thinktime < this.move_ltime + dt)
	{
		movetime = thinktime - this.move_ltime;
		if (movetime < 0)
			movetime = 0;
	}
	else
	{
		movetime = dt;
	}

	if (movetime)
		// advances this.move_ltime if not blocked
		_Movetype_PushMove(this, movetime);

	if (thinktime > oldltime && thinktime <= this.move_ltime)
	{
		this.move_nextthink = 0;
		this.move_time = time;
		other = world;
		WITH(entity, self, this, this.move_think());
	}
}
