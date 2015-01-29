#ifdef SVQC
void plat_delayedinit()
{
	plat_spawn_inside_trigger ();	// the "start moving" trigger
}

float plat_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_PLAT);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteShort(MSG_ENTITY, num_for_edict(self));
		WriteString(MSG_ENTITY, self.target);
		WriteString(MSG_ENTITY, self.target2);
		WriteString(MSG_ENTITY, self.target3);
		WriteString(MSG_ENTITY, self.target4);
		WriteString(MSG_ENTITY, self.targetname);

		WriteByte(MSG_ENTITY, self.platmovetype_start);
		WriteByte(MSG_ENTITY, self.platmovetype_turn);
		WriteByte(MSG_ENTITY, self.platmovetype_end);

		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		WriteString(MSG_ENTITY, self.model);

		WriteCoord(MSG_ENTITY, self.mins_x);
		WriteCoord(MSG_ENTITY, self.mins_y);
		WriteCoord(MSG_ENTITY, self.mins_z);
		WriteCoord(MSG_ENTITY, self.maxs_x);
		WriteCoord(MSG_ENTITY, self.maxs_y);
		WriteCoord(MSG_ENTITY, self.maxs_z);

		WriteCoord(MSG_ENTITY, self.pos1_x);
		WriteCoord(MSG_ENTITY, self.pos1_y);
		WriteCoord(MSG_ENTITY, self.pos1_z);
		WriteCoord(MSG_ENTITY, self.pos2_x);
		WriteCoord(MSG_ENTITY, self.pos2_y);
		WriteCoord(MSG_ENTITY, self.pos2_z);

		WriteCoord(MSG_ENTITY, self.size_x);
		WriteCoord(MSG_ENTITY, self.size_y);
		WriteCoord(MSG_ENTITY, self.size_z);

		WriteAngle(MSG_ENTITY, self.angles_x);
		WriteAngle(MSG_ENTITY, self.angles_y);
		WriteAngle(MSG_ENTITY, self.angles_z);

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

	return TRUE;
}

void plat_link()
{
	Net_LinkEntity(self, 0, FALSE, plat_send);
}

void spawnfunc_func_plat()
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

	plat_link();

	InitializeEntity(self, plat_delayedinit, INITPRIO_FINDTARGET);
}
#elif defined(CSQC)
void plat_draw()
{

}

void ent_plat()
{
	float sf = ReadByte();

	if(sf & SF_TRIGGER_INIT)
	{
		self.sv_entnum = ReadShort();
		self.target = strzone(ReadString());
		self.target2 = strzone(ReadString());
		self.target3 = strzone(ReadString());
		self.target4 = strzone(ReadString());
		self.targetname = strzone(ReadString());

		self.platmovetype_start = ReadByte();
		self.platmovetype_turn = ReadByte();
		self.platmovetype_end = ReadByte();

		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);

		self.model = strzone(ReadString());
		setmodel(self, self.model);

		self.mins_x = ReadCoord();
		self.mins_y = ReadCoord();
		self.mins_z = ReadCoord();
		self.maxs_x = ReadCoord();
		self.maxs_y = ReadCoord();
		self.maxs_z = ReadCoord();
		setsize(self, self.mins, self.maxs);

		self.pos1_x = ReadCoord();
		self.pos1_y = ReadCoord();
		self.pos1_z = ReadCoord();
		self.pos2_x = ReadCoord();
		self.pos2_y = ReadCoord();
		self.pos2_z = ReadCoord();

		self.size_x = ReadCoord();
		self.size_y = ReadCoord();
		self.size_z = ReadCoord();

		self.angles_x = ReadAngle();
		self.angles_y = ReadAngle();
		self.angles_z = ReadAngle();

		self.mangle_x = ReadAngle();
		self.mangle_y = ReadAngle();
		self.mangle_z = ReadAngle();

		self.speed = ReadShort();
		self.height = ReadShort();
		self.lip = ReadByte();
		self.state = ReadByte();

		self.dmg = ReadShort();

		self.solid = SOLID_BSP;
		self.movetype = MOVETYPE_PUSH;
		self.drawmask = MASK_NORMAL;
		self.draw = plat_draw;
		self.use = plat_use;

		plat_reset(); // also called here
	}

	if(sf & SF_TRIGGER_RESET)
	{
		plat_reset();
	}
}
#endif
