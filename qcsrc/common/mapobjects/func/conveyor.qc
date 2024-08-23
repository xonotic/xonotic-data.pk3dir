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

	if(this.active == ACTIVE_ACTIVE)
	{
		FOREACH_ENTITY_RADIUS((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1, it.conveyor.active == ACTIVE_NOT && isPushable(it),
		{
			if (WarpZoneLib_ExactTrigger_Touch(this, it, false))
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

bool conveyor_send(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_CONVEYOR);
	WriteByte(MSG_ENTITY, sendflags);

	if(sendflags & SF_TRIGGER_INIT)
	{
		WriteByte(MSG_ENTITY, this.warpzone_isboxy);
		WriteVector(MSG_ENTITY, this.origin);

		WriteVector(MSG_ENTITY, this.mins);
		WriteVector(MSG_ENTITY, this.maxs);

		WriteVector(MSG_ENTITY, this.movedir);

		WriteByte(MSG_ENTITY, this.speed);
		WriteByte(MSG_ENTITY, this.active);

		WriteString(MSG_ENTITY, this.targetname);
		WriteString(MSG_ENTITY, this.target);
	}

	if(sendflags & SF_TRIGGER_UPDATE)
		WriteByte(MSG_ENTITY, this.active);

	return true;
}

void conveyor_init(entity this)
{
	if (!this.speed) this.speed = 200;
	this.movedir *= this.speed;
	setthink(this, conveyor_think);
	this.nextthink = time;
	this.setactive = generic_netlinked_setactive;
	if(this.targetname && this.targetname != "")
	{
		// backwards compatibility
		this.use = generic_netlinked_legacy_use;
	}
	this.reset = generic_netlinked_reset;
	this.reset(this);

	Net_LinkEntity(this, 0, false, conveyor_send);

	this.SendFlags |= SF_TRIGGER_INIT;
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
	int sendflags = ReadByte();

	if(sendflags & SF_TRIGGER_INIT)
	{
		this.warpzone_isboxy = ReadByte();
		this.origin = ReadVector();
		setorigin(this, this.origin);

		this.mins = ReadVector();
		this.maxs = ReadVector();
		setsize(this, this.mins, this.maxs);

		this.movedir = ReadVector();

		this.speed = ReadByte();
		this.active = ReadByte();

		this.targetname = strzone(ReadString());
		this.target = strzone(ReadString());

		conveyor_init(this, isnew);
	}

	if(sendflags & SF_TRIGGER_UPDATE)
		this.active = ReadByte();

	return true;
}
#endif
