#include "triggers.qh"

bool isPushable(entity e)
{
	if(e.pushable)
		return true;
#ifdef SVQC
	if(IS_VEHICLE(e))
		return false;
	if(e.iscreature)
		return true;
	if (ITEM_IS_LOOT(e))
	{
		return true;
	}
	switch(e.classname)
	{
		case "body":
			return true;
		case "bullet": // antilagged bullets can't hit this either
			return false;
	}
	if (e.projectiledeathtype)
		return true;
#endif
#ifdef CSQC
	if(e.flags & FL_PROJECTILE)
		return true;
	if(e.isplayermodel)
		return true;
#endif
	return false;
}

void SUB_DontUseTargets(entity this, entity actor, entity trigger) { }

void SUB_UseTargets(entity this, entity actor, entity trigger);

void DelayThink(entity this)
{
	SUB_UseTargets (this, this.enemy, NULL);
	delete(this);
}

#ifdef SVQC
void generic_setactive(entity this, int act)
{
	if(act == ACTIVE_TOGGLE)
	{
		if(this.active == ACTIVE_ACTIVE)
		{
			this.active = ACTIVE_NOT;
		}
		else
		{
			this.active = ACTIVE_ACTIVE;
		}
	}
	else
	{
		this.active = act;
	}
}

void generic_netlinked_setactive(entity this, int act)
{
	int old_status = this.active;
	generic_setactive(this, act);

	if (this.active != old_status)
	{
		this.SendFlags |= SF_TRIGGER_UPDATE;
	}
}

void generic_netlinked_reset(entity this)
{
	if(this.targetname && this.targetname != "")
	{
		if(this.spawnflags & START_ENABLED)
		{
			this.active = ACTIVE_ACTIVE;
		}
		else
		{
			this.active = ACTIVE_NOT;
		}
	}
	else
	{
		this.active = ACTIVE_ACTIVE;
	}

	this.SendFlags |= SF_TRIGGER_UPDATE;
}

// Compatibility with old maps
void generic_netlinked_legacy_use(entity this, entity actor, entity trigger)
{
	//LOG_WARNF("Entity %s was (de)activated by a trigger, please update map to use relays", this.targetname);
	this.setactive(this, ACTIVE_TOGGLE);
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
	if(this.movedir != '0 0 0')
		BITSET_ASSIGN(f, 8);
	if(this.angles != '0 0 0')
		BITSET_ASSIGN(f, 16);
	WriteByte(MSG_ENTITY, f);

	if(withtarget)
	{
		// probably some way to clean this up...
		int targbits = 0;
		if(this.target && this.target != "") targbits |= BIT(0);
		if(this.target2 && this.target2 != "") targbits |= BIT(1);
		if(this.target3 && this.target3 != "") targbits |= BIT(2);
		if(this.target4 && this.target4 != "") targbits |= BIT(3);
		if(this.targetname && this.targetname != "") targbits |= BIT(4);
		if(this.killtarget && this.killtarget != "") targbits |= BIT(5);

		WriteByte(MSG_ENTITY, targbits);

		if(targbits & BIT(0))
			WriteString(MSG_ENTITY, this.target);
		if(targbits & BIT(1))
			WriteString(MSG_ENTITY, this.target2);
		if(targbits & BIT(2))
			WriteString(MSG_ENTITY, this.target3);
		if(targbits & BIT(3))
			WriteString(MSG_ENTITY, this.target4);
		if(targbits & BIT(4))
			WriteString(MSG_ENTITY, this.targetname);
		if(targbits & BIT(5))
			WriteString(MSG_ENTITY, this.killtarget);
	}

	if(f & 4)
		WriteVector(MSG_ENTITY, this.origin);

	if(f & 8)
		WriteVector(MSG_ENTITY, this.movedir);

	if(f & 16)
		WriteVector(MSG_ENTITY, this.angles);

	WriteShort(MSG_ENTITY, this.modelindex);
	WriteVector(MSG_ENTITY, this.mins);
	WriteVector(MSG_ENTITY, this.maxs);
	WriteByte(MSG_ENTITY, bound(1, this.scale * 16, 255));
}

#elif defined(CSQC)

void trigger_common_read(entity this, bool withtarget)
{
	int f = ReadByte();
	this.warpzone_isboxy = (f & 1);

	if(withtarget)
	{
		strfree(this.target);
		strfree(this.target2);
		strfree(this.target3);
		strfree(this.target4);
		strfree(this.targetname);
		strfree(this.killtarget);

		int targbits = ReadByte();

		this.target = ((targbits & BIT(0)) ? strzone(ReadString()) : string_null);
		this.target2 = ((targbits & BIT(1)) ? strzone(ReadString()) : string_null);
		this.target3 = ((targbits & BIT(2)) ? strzone(ReadString()) : string_null);
		this.target4 = ((targbits & BIT(3)) ? strzone(ReadString()) : string_null);
		this.targetname = ((targbits & BIT(4)) ? strzone(ReadString()) : string_null);
		this.killtarget = ((targbits & BIT(5)) ? strzone(ReadString()) : string_null);
	}

	if(f & 4)
		this.origin = ReadVector();
	else
		this.origin = '0 0 0';
	setorigin(this, this.origin);

	if(f & 8)
		this.movedir = ReadVector();
	else
		this.movedir = '0 0 0';

	if(f & 16)
		this.angles = ReadVector();
	else
		this.angles = '0 0 0';

	this.modelindex = ReadShort();
	if (this.modelindex)
		setmodelindex(this, this.modelindex);
	this.mins = ReadVector();
	this.maxs = ReadVector();
	this.scale = ReadByte() / 16;
	setsize(this, this.mins, this.maxs);
}

void trigger_remove_generic(entity this)
{
	strfree(this.target);
	strfree(this.target2);
	strfree(this.target3);
	strfree(this.target4);
	strfree(this.targetname);
	strfree(this.killtarget);
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

void SUB_UseTargets_Ex(entity this, entity actor, entity trigger, bool preventReuse, int skiptargets)
{
//
// check for a delay
//
	if (this.delay)
	{
		// create a temp object to fire at a later time
		entity t = new_pure(DelayedUse);
		t.nextthink = time + this.delay;
		setthink(t, DelayThink);
		t.enemy = actor;
		t.message = this.message;
		t.killtarget = this.killtarget;
		if(!(skiptargets & BIT(1))) t.target = this.target;
		if(!(skiptargets & BIT(2))) t.target2 = this.target2;
		if(!(skiptargets & BIT(3))) t.target3 = this.target3;
		if(!(skiptargets & BIT(4))) t.target4 = this.target4;
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
		if(skiptargets & BIT(i + 1))
			continue;
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
			for(entity t = NULL; (t = find(t, targetname, s)); )
			{
				if(t != this && t.use && (t.sub_target_used != time || !preventReuse))
				{
					if(this.target_random)
					{
						RandomSelection_AddEnt(t, 1, 0);
					}
					else
					{
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

void SUB_UseTargets(entity this, entity actor, entity trigger) { SUB_UseTargets_Ex(this, actor, trigger, false, 0); }
void SUB_UseTargets_PreventReuse(entity this, entity actor, entity trigger) { SUB_UseTargets_Ex(this, actor, trigger, true, 0); }
void SUB_UseTargets_SkipTargets(entity this, entity actor, entity trigger, int skiptargets) { SUB_UseTargets_Ex(this, actor, trigger, false, skiptargets); }
