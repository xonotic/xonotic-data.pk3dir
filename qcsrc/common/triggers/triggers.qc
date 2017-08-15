#include "triggers.qh"
void SUB_DontUseTargets(entity this, entity actor, entity trigger) { }

void SUB_UseTargets(entity this, entity actor, entity trigger);

void DelayThink(entity this)
{
	SUB_UseTargets (this, this.enemy, NULL);
	delete(this);
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

bool autocvar_g_triggers_debug = true;

void trigger_init(entity this)
{
	string m = this.model;
	EXACTTRIGGER_INIT;
	if(autocvar_g_triggers_debug)
	{
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
	}

	if(autocvar_g_triggers_debug)
		BITSET_ASSIGN(this.effects, EF_NODEPTHTEST);
}

void trigger_link(entity this, bool(entity this, entity to, int sendflags) sendfunc)
{
	setSendEntity(this, sendfunc);
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

void trigger_common_read(entity this, bool withtarget)
{
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

If this.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any this.message to the activator.

Removes all entities with a targetname that match this.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)this.target and call their .use function

==============================
*/

void SUB_UseTargets_Ex(entity this, entity actor, entity trigger, bool preventReuse)
{
//
// check for a delay
//
	if (this.delay)
	{
	// create a temp object to fire at a later time
		entity t = new(DelayedUse);
		t.nextthink = time + this.delay;
		setthink(t, DelayThink);
		t.enemy = actor;
		t.message = this.message;
		t.killtarget = this.killtarget;
		t.target = this.target;
		t.target2 = this.target2;
		t.target3 = this.target3;
		t.target4 = this.target4;
		t.antiwall_flag = this.antiwall_flag;
		return;
	}

	string s;

//
// print the message
//
#ifdef SVQC
	if(this)
	if(IS_PLAYER(actor) && this.message != "")
	if(IS_REAL_CLIENT(actor))
	{
		centerprint(actor, this.message);
		if (this.noise == "")
			play2(actor, SND(TALK));
	}

//
// kill the killtagets
//
	s = this.killtarget;
	if (s != "")
	{
		for(entity t = NULL; (t = find(t, targetname, s)); )
			delete(t);
	}
#endif

//
// fire targets
//

	if(this.target_random)
		RandomSelection_Init();

	for(int i = 0; i < 4; ++i)
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
			int aw_flag = this.antiwall_flag;
			for(entity t = NULL; (t = find(t, targetname, s)); )
			{
				if(t.use && (t.sub_target_used != time || !preventReuse))
				{
					if(this.target_random)
					{
						RandomSelection_AddEnt(t, 1, 0);
					}
					else
					{
						if (t.classname == "func_clientwall" || t.classname == "func_clientillusionary")
							t.antiwall_flag = aw_flag;

						t.use(t, actor, this);
						if(preventReuse)
							t.sub_target_used = time;
					}
				}
			}
		}
	}

	if(this.target_random && RandomSelection_chosen_ent)
	{
		RandomSelection_chosen_ent.use(RandomSelection_chosen_ent, actor, this);
		if(preventReuse)
			RandomSelection_chosen_ent.sub_target_used = time;
	}
}

void SUB_UseTargets(entity this, entity actor, entity trigger) { SUB_UseTargets_Ex(this, actor, trigger, false); }
void SUB_UseTargets_PreventReuse(entity this, entity actor, entity trigger) { SUB_UseTargets_Ex(this, actor, trigger, true); }

void SUB_UseTargets_self(entity this)
{
	SUB_UseTargets(this, NULL, NULL);
}
