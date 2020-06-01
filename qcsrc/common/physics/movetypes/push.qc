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
			this.angles_x -= 360.0 * floor(this.angles_x) * (1.0 / 360.0);
			this.angles_y -= 360.0 * floor(this.angles_y) * (1.0 / 360.0);
			this.angles_z -= 360.0 * floor(this.angles_z) * (1.0 / 360.0);
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
		this.angles_x -= 360.0 * floor(this.angles_x) * (1.0 / 360.0);
		this.angles_y -= 360.0 * floor(this.angles_y) * (1.0 / 360.0);
		this.angles_z -= 360.0 * floor(this.angles_z) * (1.0 / 360.0);
		return;
	}

	IL_CLEAR(g_pushmove_moved); // make sure it's not somehow uncleared

	FOREACH_ENTITY_RADIUS(0.5 * (this.absmin + this.absmax), 0.5 * vlen(this.absmax - this.absmin), true,
	{
		switch(it.move_movetype)
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

		if(it.owner == this || this.owner == it)
			continue;

		// if the entity is standing on the pusher, it will definitely be moved
		// if the entity is not standing on the pusher, but is in the pusher's
		// final position, move it
		if (!IS_ONGROUND(it) || it.groundentity != this)
		{
			tracebox(it.origin, it.mins, it.maxs, it.origin, MOVE_NORMAL, it);
			if(!trace_startsolid)
				continue;
		}
		vector pivot = it.mins + 0.5 * it.maxs;
		vector move;

		if(rotated)
		{
			vector org = it.origin - this.origin;
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

		it.moved_from = it.origin;
		it.moved_fromangles = it.angles;
		IL_PUSH(g_pushmove_moved, it);

		// physics objects need better collisions than this code can do
		if(it.move_movetype == MOVETYPE_PHYSICS)
		{
			it.origin = it.origin + move;
			_Movetype_LinkEdict(it, true);
			continue;
		}

		// try moving the contacted entity
		int savesolid = it.solid;
		it.solid = SOLID_NOT;
		if(!_Movetype_PushEntity(it, move, true, false))
		{
			// entity "check" got teleported
			it.angles_y += trace_fraction * moveangle.y;
			it.solid = savesolid;
			continue; // pushed enough
		}
		// FIXME: turn players specially
		it.angles_y += trace_fraction * moveangle.y;
		it.solid = savesolid;

		// this trace.fraction < 1 check causes items to fall off of pushers
		// if they pass under or through a wall
		// the groundentity check causes items to fall off of ledges
		if(it.move_movetype != MOVETYPE_WALK && (trace_fraction < 1 || it.groundentity != this))
			UNSET_ONGROUND(it);

		// if it is still inside the pusher, block
		tracebox(it.origin, it.mins, it.maxs, it.origin, MOVE_NORMAL, it);
		if(trace_startsolid)
		{
			if(_Movetype_NudgeOutOfSolid_PivotIsKnownGood(it, pivot))
			{
				// hack to invoke all necessary movement triggers
				vector move2 = '0 0 0';
				if(!_Movetype_PushEntity(it, move2, true, false))
				{
					// entity "check" got teleported
					continue;
				}
				// we could fix it
				continue;
			}

			// still inside pusher, so it's really blocked

			// fail the move
			if(it.mins_x == it.maxs_x)
				continue;
			if(it.solid == SOLID_NOT || it.solid == SOLID_TRIGGER)
			{
				// corpse
				it.mins_x = it.mins_y = 0;
				it.maxs = it.mins;
				continue;
			}

			this.origin = pushorig;
			this.angles = pushang;
			this.ltime = pushltime;
			_Movetype_LinkEdict(this, false);

			// move back any entities we already moved
			IL_EACH(g_pushmove_moved, true,
			{
				it.origin = it.moved_from;
				it.angles = it.moved_fromangles;
				_Movetype_LinkEdict(it, false);
			});

			// if the pusher has a "blocked" function, call it, otherwise just stay in place until the obstacle is gone
			if(getblocked(this))
				getblocked(this)(this, it);
			break;
		}
	});
	this.angles_x -= 360.0 * floor(this.angles_x) * (1.0 / 360.0);
	this.angles_y -= 360.0 * floor(this.angles_y) * (1.0 / 360.0);
	this.angles_z -= 360.0 * floor(this.angles_z) * (1.0 / 360.0);
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
		_Movetype_PushMove(this, dt);
	}

	if(this.nextthink > oldltime && this.nextthink <= this.ltime)
	{
		this.nextthink = 0;
		getthink(this)(this);
	}
}
