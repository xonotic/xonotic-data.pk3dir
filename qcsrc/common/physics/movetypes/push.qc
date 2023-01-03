#include "push.qh"

void _Movetype_PushMove(entity this, float dt) // SV_PushMove
{
	if(this.velocity == '0 0 0' && this.avelocity == '0 0 0')
	{
		this.ltime += dt;
		return;
	}

	switch(this.solid)
	{
		// LadyHavoc: valid pusher types
		case SOLID_BSP:
		case SOLID_BBOX:
		case SOLID_SLIDEBOX:
		case SOLID_CORPSE: // LadyHavoc: this would be weird...
			break;
		// LadyHavoc: no collisions
		case SOLID_NOT:
		case SOLID_TRIGGER:
		{
			this.origin = this.origin + dt * this.velocity;
			this.angles = this.angles + dt * this.avelocity;
			this.angles_x -= 360.0 * floor(this.angles_x * (1.0 / 360.0));
			this.angles_y -= 360.0 * floor(this.angles_y * (1.0 / 360.0));
			this.angles_z -= 360.0 * floor(this.angles_z * (1.0 / 360.0));
			this.ltime += dt;
			_Movetype_LinkEdict(this, false);
			return;
		}
		default:
		{
			LOG_INFOF("_Movetype_Physics_Push: entity #%d, unrecognized solid type %d", etof(this), this.solid);
			return;
		}
	}
	if(!this.modelindex)
	{
		LOG_INFOF("_Movetype_Physics_Push: entity #%d has an invalid modelindex %d", etof(this), this.modelindex);
		return;
	}

	bool rotated = ((vlen2(this.angles) + vlen2(this.avelocity)) > 0);

	vector move1 = this.velocity * dt;
	vector moveangle = this.avelocity * dt;

	vector a = -moveangle;
	vector forward, left, up;
	MAKE_VECTORS(a, forward, left, up);
	left *= -1; // actually make it left!

	vector pushorig = this.origin;
	vector pushang = this.angles;
	float pushltime = this.ltime;

	// move the pusher to its final position

	this.origin = this.origin + dt * this.velocity;
	this.angles = this.angles + dt * this.avelocity;
	this.ltime += dt;
	_Movetype_LinkEdict(this, false); // pulls absmin/absmax from the engine

	if(this.move_movetype == MOVETYPE_FAKEPUSH) // Tenebrae's MOVETYPE_PUSH variant that doesn't push...
	{
		this.angles_x -= 360.0 * floor(this.angles_x * (1.0 / 360.0));
		this.angles_y -= 360.0 * floor(this.angles_y * (1.0 / 360.0));
		this.angles_z -= 360.0 * floor(this.angles_z * (1.0 / 360.0));
		return;
	}

	IL_CLEAR(g_pushmove_moved); // make sure it's not somehow uncleared

	for(entity check = findradius((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1); check; check = check.chain)
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

		if(check.owner == this || this.owner == check)
			continue;

		// if the entity is standing on the pusher, it will definitely be moved
		// if the entity is not standing on the pusher, but is in the pusher's
		// final position, move it
		if (!IS_ONGROUND(check) || check.groundentity != this)
		{
			tracebox(check.origin, check.mins, check.maxs, check.origin, MOVE_NOMONSTERS, check);
			if(!trace_startsolid)
				continue;
		}
		vector pivot = check.mins + 0.5 * (check.maxs - check.mins);
		vector move;

		if(rotated)
		{
			vector org = check.origin - this.origin;
			org = org + pivot;

			vector org2;
			org2.x = (org * forward);
			org2.y = (org * left);
			org2.z = (org * up);
			move = org2 - org;
			move = move + move1;
		}
		else
			move = move1;

		check.moved_from = check.origin;
		check.moved_fromangles = check.angles;
		IL_PUSH(g_pushmove_moved, check);

		// physics objects need better collisions than this code can do
		if(check.move_movetype == MOVETYPE_PHYSICS)
		{
			check.origin = check.origin + move;
			_Movetype_LinkEdict(check, true);
			continue;
		}

		// try moving the contacted entity
		int savesolid = this.solid;
		this.solid = SOLID_NOT;
		if(!_Movetype_PushEntity(check, move, true))
		{
			// entity "check" got teleported
			check.angles_y += trace_fraction * moveangle.y;
			this.solid = savesolid;
			continue; // pushed enough
		}
		// FIXME: turn players specially
		check.angles_y += trace_fraction * moveangle.y;
		this.solid = savesolid;

		// this trace.fraction < 1 check causes items to fall off of pushers
		// if they pass under or through a wall
		// the groundentity check causes items to fall off of ledges
		if(check.move_movetype != MOVETYPE_WALK && (trace_fraction < 1 || check.groundentity != this))
			UNSET_ONGROUND(check);

		// if it is still inside the pusher, block
		tracebox(check.origin, check.mins, check.maxs, check.origin, MOVE_NOMONSTERS, check);
		if(trace_startsolid)
		{
			if(_Movetype_NudgeOutOfSolid_PivotIsKnownGood(check, pivot))
			{
				// hack to invoke all necessary movement triggers
				_Movetype_PushEntity(check, '0 0 0', true);
				// we could fix it or entity "check" was telported
				continue;
			}

			// still inside pusher, so it's really blocked

			// fail the move
			if(check.mins_x == check.maxs_x)
				continue;
			if(check.solid == SOLID_NOT || check.solid == SOLID_TRIGGER)
			{
				// corpse
				check.mins_x = check.mins_y = 0;
				check.maxs = check.mins;
				continue;
			}

			this.origin = pushorig;
			this.angles = pushang;
			this.ltime = pushltime;
			_Movetype_LinkEdict(this, false);

			// move back any entities we already moved
			IL_EACH(g_pushmove_moved, true,
			{
				check.origin = check.moved_from;
				check.angles = check.moved_fromangles;
				_Movetype_LinkEdict(check, false);
			});

			// if the pusher has a "blocked" function, call it, otherwise just stay in place until the obstacle is gone
			if(getblocked(this))
				getblocked(this)(this, check);
			break;
		}
	}
	this.angles_x -= 360.0 * floor(this.angles_x * (1.0 / 360.0));
	this.angles_y -= 360.0 * floor(this.angles_y * (1.0 / 360.0));
	this.angles_z -= 360.0 * floor(this.angles_z * (1.0 / 360.0));
	IL_CLEAR(g_pushmove_moved); // clean up
}

void _Movetype_Physics_Push(entity this, float dt) // SV_Physics_Pusher
{
	float oldltime = this.ltime;
	float movetime = dt;
	if(this.nextthink < this.ltime + dt)
	{
		movetime = this.nextthink - this.ltime;
		if(movetime < 0)
			movetime = 0;
	}

	if(movetime)
	{
		// advances this.ltime if not blocked
		_Movetype_PushMove(this, movetime);
	}

	if(this.nextthink > oldltime && this.nextthink <= this.ltime)
	{
		this.nextthink = 0;
		getthink(this)(this);
	}
}
