#include "conveyor.qh"
REGISTER_NET_LINKED(ENT_CLIENT_CONVEYOR)

void conveyor_think(entity this)
{
#ifdef CSQC
	// TODO: check if this is what is causing the glitchiness when switching between them
	float dt = time - this.move_time;
	this.move_time = time;
	if(dt <= 0) { return; }
#endif

	// set myself as current conveyor where possible
	IL_EACH(g_conveyed, it.conveyor == this,
	{
		it.conveyor = NULL;
		IL_REMOVE(g_conveyed, it);
	});

	if(this.state)
	{
		FOREACH_ENTITY_RADIUS((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1, !it.conveyor.state && isPushable(it),
		{
			vector emin = it.absmin;
			vector emax = it.absmax;
			if(this.solid == SOLID_BSP)
			{
				emin -= '1 1 1';
				emax += '1 1 1';
			}
			if(boxesoverlap(emin, emax, this.absmin, this.absmax)) // quick
				if(WarpZoneLib_BoxTouchesBrush(emin, emax, this, it)) // accurate
				{
					if(!it.conveyor)
						IL_PUSH(g_conveyed, it);
					it.conveyor = this;
				}
		});

		IL_EACH(g_conveyed, it.conveyor == this,
		{
			if(IS_CLIENT(it)) // doing it via velocity has quite some advantages
				continue; // done in SV_PlayerPhysics	continue;

			setorigin(it, it.origin + this.movedir * PHYS_INPUT_FRAMETIME);
			move_out_of_solid(it);
#ifdef SVQC
			UpdateCSQCProjectile(it);
#endif
			/*
			// stupid conveyor code
			tracebox(it.origin, it.mins, it.maxs, it.origin + this.movedir * sys_frametime, MOVE_NORMAL, it);
			if(trace_fraction > 0)
				setorigin(it, trace_endpos);
			*/
		});
	}

#ifdef SVQC
	this.nextthink = time;
#endif
}

#ifdef SVQC

void conveyor_use(entity this, entity actor, entity trigger)
{
	this.state = !this.state;

	this.SendFlags |= 2;
}

void conveyor_reset(entity this)
{
	this.state = (this.spawnflags & 1);

	this.SendFlags |= 2;
}

bool conveyor_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_CONVEYOR);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, this.warpzone_isboxy);
		WriteCoord(MSG_ENTITY, this.origin_x);
		WriteCoord(MSG_ENTITY, this.origin_y);
		WriteCoord(MSG_ENTITY, this.origin_z);

		WriteCoord(MSG_ENTITY, this.mins_x);
		WriteCoord(MSG_ENTITY, this.mins_y);
		WriteCoord(MSG_ENTITY, this.mins_z);
		WriteCoord(MSG_ENTITY, this.maxs_x);
		WriteCoord(MSG_ENTITY, this.maxs_y);
		WriteCoord(MSG_ENTITY, this.maxs_z);

		WriteCoord(MSG_ENTITY, this.movedir_x);
		WriteCoord(MSG_ENTITY, this.movedir_y);
		WriteCoord(MSG_ENTITY, this.movedir_z);

		WriteByte(MSG_ENTITY, this.speed);
		WriteByte(MSG_ENTITY, this.state);

		WriteString(MSG_ENTITY, this.targetname);
		WriteString(MSG_ENTITY, this.target);
	}

	if(sf & 2)
		WriteByte(MSG_ENTITY, this.state);

	return true;
}

void conveyor_init(entity this)
{
	if (!this.speed) this.speed = 200;
	this.movedir *= this.speed;
	setthink(this, conveyor_think);
	this.nextthink = time;
	IFTARGETED
	{
		this.use = conveyor_use;
		this.reset = conveyor_reset;
		this.reset(this);
	}
	else
		this.state = 1;

	FixSize(this);

	Net_LinkEntity(this, 0, false, conveyor_send);

	this.SendFlags |= 1;
}

spawnfunc(trigger_conveyor)
{
	SetMovedir(this);
	EXACTTRIGGER_INIT;
	conveyor_init(this);
}

spawnfunc(func_conveyor)
{
	SetMovedir(this);
	InitMovingBrushTrigger(this);
	set_movetype(this, MOVETYPE_NONE);
	conveyor_init(this);
}

#elif defined(CSQC)

void conveyor_draw(entity this) { conveyor_think(this); }

void conveyor_init(entity this, bool isnew)
{
	if(isnew)
		IL_PUSH(g_drawables, this);
	this.draw = conveyor_draw;
	this.drawmask = MASK_NORMAL;

	set_movetype(this, MOVETYPE_NONE);
	this.model = "";
	this.solid = SOLID_TRIGGER;
	this.move_time = time;
}

NET_HANDLE(ENT_CLIENT_CONVEYOR, bool isnew)
{
	int sf = ReadByte();

	if(sf & 1)
	{
		this.warpzone_isboxy = ReadByte();
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
		setorigin(this, this.origin);

		this.mins_x = ReadCoord();
		this.mins_y = ReadCoord();
		this.mins_z = ReadCoord();
		this.maxs_x = ReadCoord();
		this.maxs_y = ReadCoord();
		this.maxs_z = ReadCoord();
		setsize(this, this.mins, this.maxs);

		this.movedir_x = ReadCoord();
		this.movedir_y = ReadCoord();
		this.movedir_z = ReadCoord();

		this.speed = ReadByte();
		this.state = ReadByte();

		this.targetname = strzone(ReadString());
		this.target = strzone(ReadString());

		conveyor_init(this, isnew);
	}

	if(sf & 2)
		this.state = ReadByte();

	return true;
}
#endif
