#ifdef SVQC

void target_items_use(entity this, entity actor, entity trigger)
{
	// bones_was_here: why is EXACTTRIGGER_TOUCH here?
	// target_items has no bmodel (according to entities.ent), no touch func, and is SOLID_NOT

	if(ITEM_IS_LOOT(actor))
	{
		EXACTTRIGGER_TOUCH(this, trigger);
		delete(actor);
		return;
	}

	if (!IS_PLAYER(actor) || IS_DEAD(actor))
		return;

	if(trigger.solid == SOLID_TRIGGER)
	{
		EXACTTRIGGER_TOUCH(this, trigger);
	}

	IL_EACH(g_items, it.enemy == actor && ITEM_IS_LOOT(it),
	{
		delete(it);
	});

	if(GiveItems(actor, 0, tokenize_console(this.netname)))
		centerprint(actor, this.message);
}

spawnfunc(target_items)
{
	this.use = target_items_use;
	if(!this.strength_finished)
		this.strength_finished = autocvar_g_balance_powerup_strength_time;
	if(!this.invincible_finished)
		this.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	if(!this.speed_finished)
		this.speed_finished = autocvar_g_balance_powerup_speed_time;
	if(!this.invisibility_finished)
		this.invisibility_finished = autocvar_g_balance_powerup_invisibility_time;
	if(!this.superweapons_finished)
		this.superweapons_finished = autocvar_g_balance_superweapons_time;

	string str;
	int n = tokenize_console(this.netname);
	if(argv(0) == "give")
	{
		str = substring(this.netname, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
	}
	else
	{
		for(int j = 0; j < n; ++j)
		{
			// this is from a time when unlimited superweapons were handled together with ammo in some parts of the code
			if     (argv(j) == "unlimited_ammo")         this.items |= IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(j) == "unlimited_weapon_ammo")  this.items |= IT_UNLIMITED_AMMO;
			else if(argv(j) == "unlimited_superweapons") this.items |= IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(j) == "strength")               this.items |= ITEM_Strength.m_itemid;
			else if(argv(j) == "invincible")             this.items |= ITEM_Shield.m_itemid;
			else if(argv(j) == "speed")                  this.items |= ITEM_Speed.m_itemid;
			else if(argv(j) == "invisibility")           this.items |= ITEM_Invisibility.m_itemid;
			else if(argv(j) == "superweapons")           this.items |= IT_SUPERWEAPON;
			else if(argv(j) == "jetpack")                this.items |= ITEM_Jetpack.m_itemid;
			else if(argv(j) == "fuel_regen")             this.items |= ITEM_FuelRegen.m_itemid;
			else
			{
				FOREACH(StatusEffects, it.instanceOfBuff,
				{
					string s = Buff_CompatName(argv(j));
					if(s == it.netname)
					{
						this.buffdef = it;
						if(!this.buffs_finished)
							this.buffs_finished = it.m_time(it);
						break;
					}
				});
				FOREACH(Weapons, it != WEP_Null, {
					string s = argv(j);
					if(s == it.netname || s == it.m_deprecated_netname)
					{
						STAT(WEAPONS, this) |= (it.m_wepset);
						if(this.spawnflags == 0 || this.spawnflags == 2)
							it.wr_init(it);
						break;
					}
				});
			}
		}

		string itemprefix, valueprefix;
		// bones_was_here: this is inconsistent with entities.ent documentation, what's the intended behaviour?
		// Knowing that should allow some optimising (target_items is much slower than target_give when triggered).
		// spawnflags is supposed to be a bitfield, target_items breaks the standard :/
		if(this.spawnflags == 0)
		{
			itemprefix = "";
			valueprefix = "";
		}
		else if(this.spawnflags == 1)
		{
			itemprefix = "max ";
			valueprefix = "max ";
		}
		else if(this.spawnflags == 2)
		{
			itemprefix = "min ";
			valueprefix = "min ";
		}
		else if(this.spawnflags == 4)
		{
			itemprefix = "minus ";
			valueprefix = "max ";
		}
		else
		{
			error("invalid spawnflags");
			itemprefix = valueprefix = string_null;
		}

		str = "";
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & IT_UNLIMITED_AMMO), "unlimited_weapon_ammo");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & IT_UNLIMITED_SUPERWEAPONS), "unlimited_superweapons");
		str = sprintf("%s %s%d %s", str, valueprefix, this.strength_finished * boolean(this.items & ITEM_Strength.m_itemid), "strength");
		str = sprintf("%s %s%d %s", str, valueprefix, this.invincible_finished * boolean(this.items & ITEM_Shield.m_itemid), "invincible");
		str = sprintf("%s %s%d %s", str, valueprefix, this.invisibility_finished * boolean(this.items & ITEM_Invisibility.m_itemid), "invisibility");
		str = sprintf("%s %s%d %s", str, valueprefix, this.speed_finished * boolean(this.items & ITEM_Speed.m_itemid), "speed");
		str = sprintf("%s %s%d %s", str, valueprefix, this.superweapons_finished * boolean(this.items & IT_SUPERWEAPON), "superweapons");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & ITEM_Jetpack.m_itemid), "jetpack");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & ITEM_FuelRegen.m_itemid), "fuel_regen");
		float res;
		res = GetResource(this, RES_SHELLS);  if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "shells");
		res = GetResource(this, RES_BULLETS); if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "nails");
		res = GetResource(this, RES_ROCKETS); if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "rockets");
		res = GetResource(this, RES_CELLS);   if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "cells");
		res = GetResource(this, RES_FUEL);    if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "fuel");
		res = GetResource(this, RES_HEALTH);  if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "health");
		res = GetResource(this, RES_ARMOR);   if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "armor");
		FOREACH(StatusEffects, it.instanceOfBuff, str = sprintf("%s %s%d %s", str, valueprefix, this.buffs_finished * boolean(this.buffdef == it), it.netname));
		FOREACH(Weapons, it != WEP_Null, str = sprintf("%s %s%d %s", str, itemprefix, !!(STAT(WEAPONS, this) & (it.m_wepset)), it.netname));
	}
	this.netname = strzone(str);

	n = tokenize_console(this.netname);
	for(int j = 0; j < n; ++j)
	{
		string cmd = argv(j);
		FOREACH(Weapons, it != WEP_Null && (cmd == it.netname || cmd == it.m_deprecated_netname), {
			it.wr_init(it);
			break;
		});
	}
}

#endif // SVQC
