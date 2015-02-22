void _Movetype_PushMove(float dt) // SV_PushMove
{
	bool rotated;
	int savesolid;
	float movetime2, pushltime;
	vector move, move1, moveangle, pushorig, pushang;
	vector a;
	vector pivot;
	entity oldself;
	entity check;

	if(self.move_velocity == '0 0 0' && self.move_avelocity == '0 0 0')
	{
		self.move_ltime += dt;
		return;
	}

	switch(self.solid)
	{
	// LordHavoc: valid pusher types
	case SOLID_BSP:
	case SOLID_BBOX:
	case SOLID_SLIDEBOX:
	case SOLID_CORPSE: // LordHavoc: this would be weird...
		break;
	// LordHavoc: no collisions
	case SOLID_NOT:
	case SOLID_TRIGGER:
		self.move_origin = self.move_origin + dt * self.move_velocity;
		self.move_angles = self.move_angles + dt * self.move_avelocity;
		self.move_angles_x -= 360.0 * floor(self.move_angles_x * (1.0 / 360.0));
		self.move_angles_y -= 360.0 * floor(self.move_angles_y * (1.0 / 360.0));
		self.move_angles_z -= 360.0 * floor(self.move_angles_z * (1.0 / 360.0));
		self.move_ltime += dt;
		_Movetype_LinkEdict(true);
		return;
	default:
		dprintf("_Movetype_PushMove: entity %e, unrecognized solid type %d\n", self, self.solid);
		return;
	}

	rotated = (self.move_angles * self.move_angles) + (self.move_avelocity * self.move_avelocity) > 0;

	movetime2 = dt;

	move1 = self.move_velocity * movetime2;
	moveangle = self.move_avelocity * movetime2;

	a = -moveangle;
	makevectors_matrix(a);

	pushorig = self.move_origin;
	pushang = self.move_angles;
	pushltime = self.move_ltime;

// move the pusher to its final position

	self.move_origin = self.move_origin + dt * self.move_velocity;
	self.move_angles = self.move_angles + dt * self.move_avelocity;
	
	self.move_ltime += dt;
	_Movetype_LinkEdict(true);

	savesolid = self.solid;

	if(self.move_movetype != MOVETYPE_FAKEPUSH)
	for(check = findradius(0.5 * (self.absmin + self.absmax), 0.5 * vlen(self.absmax - self.absmin)); check; check = check.chain)
	{
		switch(check.move_movetype)
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

		if(check.owner == self)
			continue;

		if(self.owner == check)
			continue;

		pivot = check.mins + 0.5 * (check.maxs - check.mins);

		if (rotated)
		{
			vector org2;
			vector org = check.move_origin - self.move_origin;
			org = org + pivot;
			org2_x = dotproduct(org, v_forward);
			org2_y = dotproduct(org, v_right);
			org2_z = dotproduct(org, v_up);
			move = org2 - org;
			move = move + move1;
		}
		else
			move = move1;

		// physics objects need better collisions than this code can do
		if(check.move_movetype == 32) // MOVETYPE_PHYSICS
		{
			check.move_origin = check.move_origin + move;
			oldself = self;
			self = check;
			_Movetype_LinkEdict(true);
			self = oldself;
			continue;
		}

		// try moving the contacted entity
		self.solid = SOLID_NOT;
		oldself = self;
		self = check;
		if(!_Movetype_PushEntity(move, true))
		{
			self = oldself;
			// entity "check" got teleported
			check.move_angles_y += trace_fraction * moveangle_y;
			self.solid = savesolid;
			continue; // pushed enough
		}
		self = oldself;
		// FIXME: turn players specially
		check.move_angles_y += trace_fraction * moveangle_y;
		self.solid = savesolid;

		// this trace.fraction < 1 check causes items to fall off of pushers
		// if they pass under or through a wall
		// the groundentity check causes items to fall off of ledges
		if(check.move_movetype != MOVETYPE_WALK && (trace_fraction < 1 || check.move_groundentity != self))
			check.move_flags &= ~FL_ONGROUND;
	}

	self.move_angles_x -= 360.0 * floor(self.move_angles_x * (1.0 / 360.0));
	self.move_angles_y -= 360.0 * floor(self.move_angles_y * (1.0 / 360.0));
	self.move_angles_z -= 360.0 * floor(self.move_angles_z * (1.0 / 360.0));
}

void _Movetype_Physics_Pusher(float dt) // SV_Physics_Pusher
{
	float thinktime, oldltime, movetime;

	oldltime = self.move_ltime;

	thinktime = self.move_nextthink;
	if(thinktime < self.move_ltime + dt)
	{
		movetime = thinktime - self.move_ltime;
		if(movetime < 0)
			movetime = 0;
	}
	else
		movetime = dt;

	if(movetime)
		// advances self.move_ltime if not blocked
		_Movetype_PushMove(movetime);

	if(thinktime > oldltime && thinktime <= self.move_ltime)
	{
		self.move_nextthink = 0;
		self.move_time = time;
		other = world;
		if(self.move_think)
			self.move_think();
	}
}
