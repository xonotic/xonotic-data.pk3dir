#include "plat.qh"
REGISTER_NET_LINKED(ENT_CLIENT_PLAT)

#ifdef SVQC
void plat_link(entity this);

void plat_delayedinit(entity this)
{
	plat_link(this);
	// Q3 uses only a truth check of .targetname to decide whether to spawn a trigger
	if (!Q3COMPAT_COMMON || this.targetname == "")
		plat_spawn_inside_trigger(this); // the "start moving" trigger
}

float plat_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_PLAT);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteByte(MSG_ENTITY, this.platmovetype_start);
		WriteByte(MSG_ENTITY, this.platmovetype_turn);
		WriteByte(MSG_ENTITY, this.platmovetype_end);
		WriteByte(MSG_ENTITY, this.spawnflags);

		WriteString(MSG_ENTITY, this.model);

		trigger_common_write(this, true);

		WriteVector(MSG_ENTITY, this.pos1);
		WriteVector(MSG_ENTITY, this.pos2);

		WriteVector(MSG_ENTITY, this.size);

		WriteAngleVector(MSG_ENTITY, this.mangle);

		WriteShort(MSG_ENTITY, this.speed);
		WriteShort(MSG_ENTITY, this.height);
		WriteByte(MSG_ENTITY, this.lip);
		WriteByte(MSG_ENTITY, this.state);

		WriteShort(MSG_ENTITY, this.dmg);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// used on client
	}

	return true;
}

void plat_link(entity this)
{
	//Net_LinkEntity(this, 0, false, plat_send);
}

spawnfunc(func_plat)
{
	if (q3compat)
	{
		this.spawnflags = 0; // Q3 plats have no spawnflags
		if (!this.dmg) this.dmg = 2;
	}
	else if (this.spawnflags & CRUSH)
	{
		this.dmg = 10000;
	}

	if (this.dmg && (this.message == ""))
	{
		this.message = "was squished";
	}
	if (this.dmg && (this.message2 == ""))
	{
		this.message2 = "was squished by";
	}

	if (this.sounds == 1)
	{
		this.noise = "plats/plat1.wav";
		this.noise1 = "plats/plat2.wav";
	}

	if (this.sounds == 2 || q3compat)
	{
		// Plats in Q3 always have sounds (they're hard coded in Q3 engine)
		this.noise = "plats/medplat1.wav";
		this.noise1 = "plats/medplat2.wav";
	}

	// WARNING: backwards compatibility because people don't use already existing fields :(
	if (this.sound1)
		this.noise = this.sound1;
	if (this.sound2)
		this.noise1 = this.sound2;

	if (q3compat)
	{
		// CPMA adds these fields for overriding the Q3 default sounds
		string s = GetField_fullspawndata(this, "sound_start", true);
		string e = GetField_fullspawndata(this, "sound_end", true);

		if (s)
			this.noise = strzone(s);
		else
		{
			// PK3s supporting Q3A sometimes include custom sounds at Q3 default paths
			s = "sound/movers/plats/pt1_strt.wav";
			if (FindFileInMapPack(s))
				this.noise = s;
		}

		if (e)
			this.noise1 = strzone(e);
		else
		{
			e = "sound/movers/plats/pt1_end.wav";
			if (FindFileInMapPack(e))
				this.noise1 = e;
		}
	}

	if(this.noise && this.noise != "")
	{
		precache_sound(this.noise);
	}
	if(this.noise1 && this.noise1 != "")
	{
		precache_sound(this.noise1);
	}

	this.mangle = this.angles;
	this.angles = '0 0 0';

	this.classname = "plat";
	this.draggable = drag_undraggable;
	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;
	setsize (this, this.mins , this.maxs);

	setblocked(this, plat_crush);

	if (!this.speed) this.speed = q3compat ? 200 : 150;
	if (!this.lip) this.lip = q3compat ? 8 : 16;
	if (!this.height) this.height = this.size.z - this.lip;

	this.pos1 = this.origin;
	this.pos2 = this.origin;
	this.pos2_z = this.origin.z - this.height;

	this.reset = plat_reset;
	this.reset(this);

	InitializeEntity(this, plat_delayedinit, INITPRIO_FINDTARGET);
}
#elif defined(CSQC)
void plat_draw(entity this)
{
	Movetype_Physics_NoMatchServer(this);
	//Movetype_Physics_MatchServer(autocvar_cl_projectiles_sloppy);
}

NET_HANDLE(ENT_CLIENT_PLAT, bool isnew)
{
	float sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		this.platmovetype_start = ReadByte();
		this.platmovetype_turn = ReadByte();
		this.platmovetype_end = ReadByte();
		this.spawnflags = ReadByte();

		this.model = strzone(ReadString());
		_setmodel(this, this.model);

		trigger_common_read(this, true);

		this.pos1 = ReadVector();
		this.pos2 = ReadVector();

		this.size = ReadVector();

		this.mangle = ReadAngleVector();

		this.speed = ReadShort();
		this.height = ReadShort();
		this.lip = ReadByte();
		this.state = ReadByte();

		this.dmg = ReadShort();

		this.classname = "plat";
		this.solid = SOLID_BSP;
		set_movetype(this, MOVETYPE_PUSH);
		this.drawmask = MASK_NORMAL;
		this.draw = plat_draw;
		if (isnew) IL_PUSH(g_drawables, this);
		this.use = plat_use;
		this.entremove = trigger_remove_generic;

		plat_reset(this); // also called here

		set_movetype(this, MOVETYPE_PUSH);
		this.move_time = time;

		if (!Q3COMPAT_COMMON || this.targetname == "")
			plat_spawn_inside_trigger(this);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		plat_reset(this);

		this.move_time = time;
	}
	return true;
}
#endif
