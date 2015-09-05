void conveyor_think()
{SELFPARAM();
#ifdef CSQC
	// TODO: check if this is what is causing the glitchiness when switching between them
	float dt = time - self.move_time;
	self.move_time = time;
	if(dt <= 0) { return; }
#endif
	entity e;

	// set myself as current conveyor where possible
	for(e = world; (e = findentity(e, conveyor, self)); )
		e.conveyor = world;

	if(self.state)
	{
		for(e = findradius((self.absmin + self.absmax) * 0.5, vlen(self.absmax - self.absmin) * 0.5 + 1); e; e = e.chain)
			if(!e.conveyor.state)
				if(isPushable(e))
				{
					vector emin = e.absmin;
					vector emax = e.absmax;
					if(self.solid == SOLID_BSP)
					{
						emin -= '1 1 1';
						emax += '1 1 1';
					}
					if(boxesoverlap(emin, emax, self.absmin, self.absmax)) // quick
						if(WarpZoneLib_BoxTouchesBrush(emin, emax, self, e)) // accurate
							e.conveyor = self;
				}

		for(e = world; (e = findentity(e, conveyor, self)); )
		{
			if(IS_CLIENT(e)) // doing it via velocity has quite some advantages
				continue; // done in SV_PlayerPhysics	continue;

			setorigin(e, e.origin + self.movedir * PHYS_INPUT_FRAMETIME);
			move_out_of_solid(e);
#ifdef SVQC
			UpdateCSQCProjectile(e);
#endif
			/*
			// stupid conveyor code
			tracebox(e.origin, e.mins, e.maxs, e.origin + self.movedir * sys_frametime, MOVE_NORMAL, e);
			if(trace_fraction > 0)
				setorigin(e, trace_endpos);
			*/
		}
	}

#ifdef SVQC
	self.nextthink = time;
#endif
}

#ifdef SVQC

void conveyor_use()
{SELFPARAM();
	self.state = !self.state;

	self.SendFlags |= 2;
}

void conveyor_reset()
{SELFPARAM();
	self.state = (self.spawnflags & 1);

	self.SendFlags |= 2;
}

bool conveyor_send(entity to, int sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_CONVEYOR);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, self.warpzone_isboxy);
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		WriteCoord(MSG_ENTITY, self.mins_x);
		WriteCoord(MSG_ENTITY, self.mins_y);
		WriteCoord(MSG_ENTITY, self.mins_z);
		WriteCoord(MSG_ENTITY, self.maxs_x);
		WriteCoord(MSG_ENTITY, self.maxs_y);
		WriteCoord(MSG_ENTITY, self.maxs_z);

		WriteCoord(MSG_ENTITY, self.movedir_x);
		WriteCoord(MSG_ENTITY, self.movedir_y);
		WriteCoord(MSG_ENTITY, self.movedir_z);

		WriteByte(MSG_ENTITY, self.speed);
		WriteByte(MSG_ENTITY, self.state);

		WriteString(MSG_ENTITY, self.targetname);
		WriteString(MSG_ENTITY, self.target);
	}

	if(sf & 2)
		WriteByte(MSG_ENTITY, self.state);

	return true;
}

void conveyor_init()
{SELFPARAM();
	if (!self.speed)
		self.speed = 200;
	self.movedir = self.movedir * self.speed;
	self.think = conveyor_think;
	self.nextthink = time;
	IFTARGETED
	{
		self.use = conveyor_use;
		self.reset = conveyor_reset;
		conveyor_reset();
	}
	else
		self.state = 1;

	FixSize(self);

	Net_LinkEntity(self, 0, false, conveyor_send);

	self.SendFlags |= 1;
}

void spawnfunc_trigger_conveyor()
{
	SetMovedir();
	EXACTTRIGGER_INIT;
	conveyor_init();
}

void spawnfunc_func_conveyor()
{SELFPARAM();
	SetMovedir();
	InitMovingBrushTrigger();
	self.movetype = MOVETYPE_NONE;
	conveyor_init();
}

#elif defined(CSQC)

void conveyor_init()
{SELFPARAM();
	self.draw = conveyor_think;
	self.drawmask = MASK_NORMAL;

	self.movetype = MOVETYPE_NONE;
	self.model = "";
	self.solid = SOLID_TRIGGER;
	self.move_origin = self.origin;
	self.move_time = time;
}

void ent_conveyor()
{SELFPARAM();
	float sf = ReadByte();

	if(sf & 1)
	{
		self.warpzone_isboxy = ReadByte();
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);

		self.mins_x = ReadCoord();
		self.mins_y = ReadCoord();
		self.mins_z = ReadCoord();
		self.maxs_x = ReadCoord();
		self.maxs_y = ReadCoord();
		self.maxs_z = ReadCoord();
		setsize(self, self.mins, self.maxs);

		self.movedir_x = ReadCoord();
		self.movedir_y = ReadCoord();
		self.movedir_z = ReadCoord();

		self.speed = ReadByte();
		self.state = ReadByte();

		self.targetname = strzone(ReadString());
		self.target = strzone(ReadString());

		conveyor_init();
	}

	if(sf & 2)
		self.state = ReadByte();
}
#endif
