void SUB_DontUseTargets() { }

void() SUB_UseTargets;

void DelayThink()
{SELFPARAM();
	activator = this.enemy;
	SUB_UseTargets ();
	remove(this);
}

void FixSize(entity e)
{
	e.mins_x = rint(e.mins_x);
	e.mins_y = rint(e.mins_y);
	e.mins_z = rint(e.mins_z);

	e.maxs_x = rint(e.maxs_x);
	e.maxs_y = rint(e.maxs_y);
	e.maxs_z = rint(e.maxs_z);
}

#ifdef SVQC

void trigger_init(entity this)
{
	string m = this.model;
	WITHSELF(this, WarpZoneLib_ExactTrigger_Init());
 	if(m != "")
 	{
 		precache_model(m);
 		_setmodel(this, m); // no precision needed
	}
	setorigin(this, this.origin);
	if(this.scale)
		setsize(this, this.mins * this.scale, this.maxs * this.scale);
	else
		setsize(this, this.mins, this.maxs);

	BITSET_ASSIGN(this.effects, EF_NODEPTHTEST);
}

void trigger_link(entity this, bool(entity this, entity to, int sendflags) sendfunc)
{
	this.SendEntity = SendEntity_self;
	this.SendEntity3 = sendfunc;
	this.SendFlags = 0xFFFFFF;
}

void trigger_common_write(entity this, bool withtarget)
{
	int f = 0;
	if(this.warpzone_isboxy)
		BITSET_ASSIGN(f, 1);
	if(this.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	if(withtarget)
	{
		WriteString(MSG_ENTITY, this.target);
		WriteString(MSG_ENTITY, this.target2);
		WriteString(MSG_ENTITY, this.target3);
		WriteString(MSG_ENTITY, this.target4);
		WriteString(MSG_ENTITY, this.targetname);
		WriteString(MSG_ENTITY, this.killtarget);
	}

	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}

	WriteShort(MSG_ENTITY, this.modelindex);
	WriteCoord(MSG_ENTITY, this.mins.x);
	WriteCoord(MSG_ENTITY, this.mins.y);
	WriteCoord(MSG_ENTITY, this.mins.z);
	WriteCoord(MSG_ENTITY, this.maxs.x);
	WriteCoord(MSG_ENTITY, this.maxs.y);
	WriteCoord(MSG_ENTITY, this.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, this.scale * 16, 255));

	WriteCoord(MSG_ENTITY, this.movedir_x);
	WriteCoord(MSG_ENTITY, this.movedir_y);
	WriteCoord(MSG_ENTITY, this.movedir_z);

	WriteCoord(MSG_ENTITY, this.angles_x);
	WriteCoord(MSG_ENTITY, this.angles_y);
	WriteCoord(MSG_ENTITY, this.angles_z);
}

#elif defined(CSQC)

void trigger_common_read(bool withtarget)
{SELFPARAM();
	int f = ReadByte();
	this.warpzone_isboxy = (f & 1);

	if(withtarget)
	{
		if(this.target) { strunzone(this.target); }
		this.target = strzone(ReadString());
		if(this.target2) { strunzone(this.target2); }
		this.target2 = strzone(ReadString());
		if(this.target3) { strunzone(this.target3); }
		this.target3 = strzone(ReadString());
		if(this.target4) { strunzone(this.target4); }
		this.target4 = strzone(ReadString());
		if(this.targetname) { strunzone(this.targetname); }
		this.targetname = strzone(ReadString());
		if(this.killtarget) { strunzone(this.killtarget); }
		this.killtarget = strzone(ReadString());
	}

	if(f & 4)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
	}
	else
		this.origin = '0 0 0';
	setorigin(this, this.origin);

	this.modelindex = ReadShort();
	this.mins_x = ReadCoord();
	this.mins_y = ReadCoord();
	this.mins_z = ReadCoord();
	this.maxs_x = ReadCoord();
	this.maxs_y = ReadCoord();
	this.maxs_z = ReadCoord();
	this.scale = ReadByte() / 16;
	setsize(this, this.mins, this.maxs);

	this.movedir_x = ReadCoord();
	this.movedir_y = ReadCoord();
	this.movedir_z = ReadCoord();

	this.angles_x = ReadCoord();
	this.angles_y = ReadCoord();
	this.angles_z = ReadCoord();
}

void trigger_remove_generic(entity this)
{
	if(this.target) { strunzone(this.target); }
	this.target = string_null;

	if(this.target2) { strunzone(this.target2); }
	this.target2 = string_null;

	if(this.target3) { strunzone(this.target3); }
	this.target3 = string_null;

	if(this.target4) { strunzone(this.target4); }
	this.target4 = string_null;

	if(this.targetname) { strunzone(this.targetname); }
	this.target = string_null;

	if(this.killtarget) { strunzone(this.killtarget); }
	this.killtarget = string_null;
}
#endif

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void SUB_UseTargets()
{SELFPARAM();
	entity t, otemp, act;
	string s;
	float i;

//
// check for a delay
//
	if (this.delay)
	{
	// create a temp object to fire at a later time
		t = new(DelayedUse);
		t.nextthink = time + this.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = this.message;
		t.killtarget = this.killtarget;
		t.target = this.target;
		t.target2 = this.target2;
		t.target3 = this.target3;
		t.target4 = this.target4;
		return;
	}


//
// print the message
//
#ifdef SVQC
	if(this)
	if(IS_PLAYER(activator) && this.message != "")
	if(IS_REAL_CLIENT(activator))
	{
		centerprint(activator, this.message);
		if (this.noise == "")
			play2(activator, SND(TALK));
	}

//
// kill the killtagets
//
	s = this.killtarget;
	if (s != "")
	{
		for(t = world; (t = find(t, targetname, s)); )
			remove(t);
	}
#endif

//
// fire targets
//
	act = activator;
	otemp = other;

	if(this.target_random)
		RandomSelection_Init();

	for(i = 0; i < 4; ++i)
	{
		switch(i)
		{
			default:
			case 0: s = this.target; break;
			case 1: s = this.target2; break;
			case 2: s = this.target3; break;
			case 3: s = this.target4; break;
		}
		if (s != "")
		{
			// Flag to set func_clientwall state
			// 1 == deactivate, 2 == activate, 0 == do nothing
			float aw_flag = this.antiwall_flag;
			for(t = world; (t = find(t, targetname, s)); )
			if(t.use)
			{
				if(this.target_random)
				{
					RandomSelection_Add(t, 0, string_null, 1, 0);
				}
				else
				{
					if (t.classname == "func_clientwall" || t.classname == "func_clientillusionary")
						t.antiwall_flag = aw_flag;
					setself(t);
					other = this;
					activator = act;
					self.use();
				}
			}
		}
	}

	if(this.target_random && RandomSelection_chosen_ent)
	{
		setself(RandomSelection_chosen_ent);
		other = this;
		activator = act;
		self.use();
	}

	activator = act;
	setself(this);
	other = otemp;
}

#ifdef CSQC
void trigger_touch_generic(entity this, void() touchfunc)
{
	entity e;
	for(e = findradius((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1); e; e = e.chain)
	if(e.classname == "csqcprojectile")
	{
		vector emin = e.absmin, emax = e.absmax;
		if(this.solid == SOLID_BSP)
		{
			emin -= '1 1 1';
			emax += '1 1 1';
		}
		if(boxesoverlap(emin, emax, this.absmin, this.absmax)) // quick
		if(WarpZoneLib_BoxTouchesBrush(emin, emax, this, e)) // accurate
		{
			other = e;
			WITHSELF(this, touchfunc());
		}
	}
}
void trigger_draw_generic(entity this)
{
	float dt = time - this.move_time;
	this.move_time = time;
	if(dt <= 0) { return; }

	if(this.trigger_touch) { trigger_touch_generic(this, this.trigger_touch); }
}
#endif
