REGISTER_NET_LINKED(ENT_CLIENT_PLAT)

#ifdef SVQC
void plat_link();

void plat_delayedinit()
{
	plat_link();
	plat_spawn_inside_trigger(); // the "start moving" trigger
}

float plat_send(entity to, float sf)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_PLAT);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteByte(MSG_ENTITY, self.platmovetype_start);
		WriteByte(MSG_ENTITY, self.platmovetype_turn);
		WriteByte(MSG_ENTITY, self.platmovetype_end);
		WriteByte(MSG_ENTITY, self.spawnflags);

		WriteString(MSG_ENTITY, self.model);

		trigger_common_write(self, true);

		WriteCoord(MSG_ENTITY, self.pos1_x);
		WriteCoord(MSG_ENTITY, self.pos1_y);
		WriteCoord(MSG_ENTITY, self.pos1_z);
		WriteCoord(MSG_ENTITY, self.pos2_x);
		WriteCoord(MSG_ENTITY, self.pos2_y);
		WriteCoord(MSG_ENTITY, self.pos2_z);

		WriteCoord(MSG_ENTITY, self.size_x);
		WriteCoord(MSG_ENTITY, self.size_y);
		WriteCoord(MSG_ENTITY, self.size_z);

		WriteAngle(MSG_ENTITY, self.mangle_x);
		WriteAngle(MSG_ENTITY, self.mangle_y);
		WriteAngle(MSG_ENTITY, self.mangle_z);

		WriteShort(MSG_ENTITY, self.speed);
		WriteShort(MSG_ENTITY, self.height);
		WriteByte(MSG_ENTITY, self.lip);
		WriteByte(MSG_ENTITY, self.state);

		WriteShort(MSG_ENTITY, self.dmg);
	}

	if(sf & SF_TRIGGER_RESET)
	{
		// used on client
	}

	return true;
}

void plat_link()
{
	//Net_LinkEntity(self, 0, false, plat_send);
}

spawnfunc(func_plat)
{
	if (this.sounds == 0) this.sounds = 2;

    if (this.spawnflags & 4) this.dmg = 10000;

    if (this.dmg && (this.message == "")) this.message = "was squished";
    if (this.dmg && (this.message2 == "")) this.message2 = "was squished by";

	if (this.sounds == 1)
	{
		precache_sound ("plats/plat1.wav");
		precache_sound ("plats/plat2.wav");
		this.noise = "plats/plat1.wav";
		this.noise1 = "plats/plat2.wav";
	}

	if (this.sounds == 2)
	{
		precache_sound ("plats/medplat1.wav");
		precache_sound ("plats/medplat2.wav");
		this.noise = "plats/medplat1.wav";
		this.noise1 = "plats/medplat2.wav";
	}

	if (this.sound1)
	{
		precache_sound (this.sound1);
		this.noise = this.sound1;
	}
	if (this.sound2)
	{
		precache_sound (this.sound2);
		this.noise1 = this.sound2;
	}

	this.mangle = this.angles;
	this.angles = '0 0 0';

	this.classname = "plat";
	if (!InitMovingBrushTrigger())
		return;
	this.effects |= EF_LOWPRECISION;
	setsize (this, this.mins , this.maxs);

	this.blocked = plat_crush;

	if (!this.speed) this.speed = 150;
	if (!this.lip) this.lip = 16;
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

		trigger_common_read(true);

		this.pos1_x = ReadCoord();
		this.pos1_y = ReadCoord();
		this.pos1_z = ReadCoord();
		this.pos2_x = ReadCoord();
		this.pos2_y = ReadCoord();
		this.pos2_z = ReadCoord();

		this.size_x = ReadCoord();
		this.size_y = ReadCoord();
		this.size_z = ReadCoord();

		this.mangle_x = ReadAngle();
		this.mangle_y = ReadAngle();
		this.mangle_z = ReadAngle();

		this.speed = ReadShort();
		this.height = ReadShort();
		this.lip = ReadByte();
		this.state = ReadByte();

		this.dmg = ReadShort();

		this.classname = "plat";
		this.solid = SOLID_BSP;
		this.movetype = MOVETYPE_PUSH;
		this.drawmask = MASK_NORMAL;
		this.draw = plat_draw;
		this.use = plat_use;
		this.entremove = trigger_remove_generic;

		plat_reset(this); // also called here

		this.move_movetype = MOVETYPE_PUSH;
		this.move_origin = this.origin;
		this.move_angles = this.angles;
		this.move_time = time;

		plat_spawn_inside_trigger();
	}

	if(sf & SF_TRIGGER_RESET)
	{
		plat_reset(this);

		this.move_origin = this.origin;
		this.move_angles = this.angles;
		this.move_time = time;
	}
	return true;
}
#endif
