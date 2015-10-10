#ifdef SVQC
void plat_link();

void plat_delayedinit()
{
	plat_link();
	plat_spawn_inside_trigger(); // the "start moving" trigger
}

float plat_send(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_PLAT);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteByte(MSG_ENTITY, self.platmovetype_start);
		WriteByte(MSG_ENTITY, self.platmovetype_turn);
		WriteByte(MSG_ENTITY, self.platmovetype_end);
		WriteByte(MSG_ENTITY, self.spawnflags);

		WriteString(MSG_ENTITY, self.model);

		trigger_common_write(true);

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
	if (self.sounds == 0)
		self.sounds = 2;

    if(self.spawnflags & 4)
        self.dmg = 10000;

    if(self.dmg && (self.message == ""))
		self.message = "was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";

	if (self.sounds == 1)
	{
		precache_sound ("plats/plat1.wav");
		precache_sound ("plats/plat2.wav");
		self.noise = "plats/plat1.wav";
		self.noise1 = "plats/plat2.wav";
	}

	if (self.sounds == 2)
	{
		precache_sound ("plats/medplat1.wav");
		precache_sound ("plats/medplat2.wav");
		self.noise = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}

	if (self.sound1)
	{
		precache_sound (self.sound1);
		self.noise = self.sound1;
	}
	if (self.sound2)
	{
		precache_sound (self.sound2);
		self.noise1 = self.sound2;
	}

	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "plat";
	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;
	setsize (self, self.mins , self.maxs);

	self.blocked = plat_crush;

	if (!self.speed)
		self.speed = 150;
	if (!self.lip)
		self.lip = 16;
	if (!self.height)
		self.height = self.size_z - self.lip;

	self.pos1 = self.origin;
	self.pos2 = self.origin;
	self.pos2_z = self.origin_z - self.height;

	self.reset = plat_reset;
	plat_reset();

	InitializeEntity(self, plat_delayedinit, INITPRIO_FINDTARGET);
}
#elif defined(CSQC)
void plat_draw(entity this)
{
	Movetype_Physics_NoMatchServer();
	//Movetype_Physics_MatchServer(autocvar_cl_projectiles_sloppy);
}

void ent_plat()
{SELFPARAM();
	float sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		self.platmovetype_start = ReadByte();
		self.platmovetype_turn = ReadByte();
		self.platmovetype_end = ReadByte();
		self.spawnflags = ReadByte();

		self.model = strzone(ReadString());
		_setmodel(self, self.model);

		trigger_common_read(true);

		self.pos1_x = ReadCoord();
		self.pos1_y = ReadCoord();
		self.pos1_z = ReadCoord();
		self.pos2_x = ReadCoord();
		self.pos2_y = ReadCoord();
		self.pos2_z = ReadCoord();

		self.size_x = ReadCoord();
		self.size_y = ReadCoord();
		self.size_z = ReadCoord();

		self.mangle_x = ReadAngle();
		self.mangle_y = ReadAngle();
		self.mangle_z = ReadAngle();

		self.speed = ReadShort();
		self.height = ReadShort();
		self.lip = ReadByte();
		self.state = ReadByte();

		self.dmg = ReadShort();

		self.classname = "plat";
		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
		self.drawmask = MASK_NORMAL;
		self.draw = plat_draw;
		self.use = plat_use;
		self.entremove = trigger_remove_generic;

		plat_reset(); // also called here

		self.move_movetype = MOVETYPE_PUSH;
		self.move_origin = self.origin;
		self.move_angles = self.angles;
		self.move_time = time;

		plat_spawn_inside_trigger();
	}

	if(sf & SF_TRIGGER_RESET)
	{
		plat_reset();

		self.move_origin = self.origin;
		self.move_angles = self.angles;
		self.move_time = time;
	}
}
#endif
