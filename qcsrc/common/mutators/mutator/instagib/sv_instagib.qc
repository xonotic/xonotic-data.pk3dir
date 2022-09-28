#include "sv_instagib.qh"

#include <server/client.qh>
#include <common/items/_mod.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include "../random_items/sv_random_items.qh"

bool autocvar_g_instagib_damagedbycontents = true;
bool autocvar_g_instagib_blaster_keepdamage = false;
bool autocvar_g_instagib_blaster_keepforce = false;
bool autocvar_g_instagib_mirrordamage;
bool autocvar_g_instagib_friendlypush = true;
//int autocvar_g_instagib_ammo_drop;
bool autocvar_g_instagib_ammo_convert_cells;
bool autocvar_g_instagib_ammo_convert_rockets;
bool autocvar_g_instagib_ammo_convert_shells;
bool autocvar_g_instagib_ammo_convert_bullets;

void instagib_invisibility(entity this)
{
	this.invisibility_finished = autocvar_g_instagib_invisibility_time;
	StartItem(this, ITEM_Invisibility);
}

void instagib_extralife(entity this)
{
	StartItem(this, ITEM_ExtraLife);
}

void instagib_speed(entity this)
{
	this.speed_finished = autocvar_g_instagib_speed_time;
	StartItem(this, ITEM_Speed);
}

/// \brief Returns a random classname of the instagib item.
/// \param[in] prefix Prefix of the cvars that hold probabilities.
/// \return Random classname of the instagib item.
string RandomItems_GetRandomInstagibItemClassName(string prefix)
{
	RandomSelection_Init();
	IL_EACH(g_instagib_items, Item_IsDefinitionAllowed(it),
	{
		string cvar_name = sprintf("g_%s_%s_probability", prefix,
			it.m_canonical_spawnfunc);
		if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
		{
			LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			continue;
		}
		RandomSelection_AddString(it.m_canonical_spawnfunc, cvar(cvar_name), 1);
	});
	return RandomSelection_chosen_string;
}

.float instagib_nextthink;
.float instagib_needammo;
void instagib_stop_countdown(entity e)
{
	if (!e.instagib_needammo)
		return;
	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER, CPID_INSTAGIB_FINDAMMO);
	e.instagib_needammo = false;
}

void instagib_countdown(entity this)
{
	float hp = GetResource(this, RES_HEALTH);

	float dmg = (hp <= 10) ? 5 : 10;
	Damage(this, this, this, dmg, DEATH_NOAMMO.m_id, DMG_NOWEP, this.origin, '0 0 0');

	entity annce = (hp <= 5) ? ANNCE_INSTAGIB_TERMINATED : Announcer_PickNumber(CNT_NORMAL, ceil(hp / 10));
	Send_Notification(NOTIF_ONE, this, MSG_ANNCE, annce);

	if (hp > 80)
	{
		if (hp <= 90)
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_INSTAGIB_FINDAMMO);
		else
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_MULTI, MULTI_INSTAGIB_FINDAMMO);
	}
}

void instagib_ammocheck(entity this)
{
	if(time < this.instagib_nextthink)
		return;
	if(!IS_PLAYER(this))
		return; // not a player

	if(IS_DEAD(this) || game_stopped)
		instagib_stop_countdown(this);
	else if (GetResource(this, RES_CELLS) > 0 || (this.items & IT_UNLIMITED_AMMO) || (this.flags & FL_GODMODE))
		instagib_stop_countdown(this);
	else if(autocvar_g_rm && autocvar_g_rm_laser)
	{
		if(!this.instagib_needammo)
		{
			Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_INSTAGIB_DOWNGRADE);
			this.instagib_needammo = true;
		}
	}
	else
	{
		this.instagib_needammo = true;
		instagib_countdown(this);
	}
	this.instagib_nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MatchEnd)
{
	FOREACH_CLIENT(IS_PLAYER(it), { instagib_stop_countdown(it); });
}

MUTATOR_HOOKFUNCTION(mutator_instagib, RandomItems_GetRandomItemClassName)
{
	M_ARGV(1, string) = RandomItems_GetRandomInstagibItemClassName(
		M_ARGV(0, string));
	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MonsterDropItem)
{
	entity item = M_ARGV(1, entity);

	item.monster_loot = ITEM_VaporizerCells;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MonsterSpawn)
{
	entity mon = M_ARGV(0, entity);

	// always refill ammo
	if(mon.monsterdef == MON_MAGE)
		mon.skin = 1;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	instagib_stop_countdown(player);
}

MUTATOR_HOOKFUNCTION(mutator_instagib, ForbidRandomStartWeapons)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.effects |= EF_FULLBRIGHT;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	instagib_ammocheck(player);
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerRegen)
{
	// no regeneration in instagib
	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerDamage_SplitHealthArmor)
{
	M_ARGV(4, float) = M_ARGV(7, float); // take = damage
	M_ARGV(5, float) = 0; // save
}

MUTATOR_HOOKFUNCTION(mutator_instagib, ForbidThrowCurrentWeapon)
{
	// weapon dropping on death handled by FilterItem
	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);
	vector frag_force = M_ARGV(6, vector);

	if(autocvar_g_friendlyfire == 0 && SAME_TEAM(frag_target, frag_attacker) && IS_PLAYER(frag_target) && IS_PLAYER(frag_attacker))
		frag_damage = 0;

	if(IS_PLAYER(frag_target))
	{
		if(frag_deathtype == DEATH_FALL.m_id)
			frag_damage = 0; // never count fall damage

		if(!autocvar_g_instagib_damagedbycontents)
		switch(DEATH_ENT(frag_deathtype))
		{
			case DEATH_DROWN:
			case DEATH_SLIME:
			case DEATH_LAVA:
				frag_damage = 0;
				break;
		}

		if(IS_PLAYER(frag_attacker))
		if(DEATH_ISWEAPON(frag_deathtype, WEP_VAPORIZER))
		{
			if(!autocvar_g_instagib_friendlypush && SAME_TEAM(frag_target, frag_attacker))
				frag_force = '0 0 0';

			float armor = GetResource(frag_target, RES_ARMOR);
			if(armor)
			{
				armor -= 1;
				SetResource(frag_target, RES_ARMOR, armor);
				frag_damage = 0;
				frag_target.hitsound_damage_dealt += 1;
				frag_attacker.hitsound_damage_dealt += 1;
				Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, armor);
			}
		}

		if(IS_PLAYER(frag_attacker) && DEATH_ISWEAPON(frag_deathtype, WEP_BLASTER))
		{
			if(frag_deathtype & HITTYPE_SECONDARY)
			{
				if(!autocvar_g_instagib_blaster_keepdamage || frag_attacker == frag_target)
				{
					frag_damage = 0;
					if(!autocvar_g_instagib_mirrordamage)
						frag_mirrordamage = 0; // never do mirror damage on enemies
				}

				if(frag_target != frag_attacker)
				{
					if(!autocvar_g_instagib_blaster_keepforce)
						frag_force = '0 0 0';
				}
			}
		}
	}

	if(!autocvar_g_instagib_mirrordamage) // only apply the taking lives hack if we don't want to support real damage mirroring
	if(IS_PLAYER(frag_attacker))
	if(frag_mirrordamage > 0)
	{
		// just lose extra LIVES, don't kill the player for mirror damage
		float armor = GetResource(frag_attacker, RES_ARMOR);
		if(armor > 0)
		{
			armor -= 1;
			SetResource(frag_attacker, RES_ARMOR, armor);
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, armor);
			frag_attacker.hitsound_damage_dealt += frag_mirrordamage;
		}
		frag_mirrordamage = 0;
	}

	if(frag_target.alpha && frag_target.alpha < 1)
	if(IS_PLAYER(frag_target))
		yoda = 1;

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
	M_ARGV(6, vector) = frag_force;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, SetStartItems, CBC_ORDER_LAST)
{
	start_health       = warmup_start_health       = 100;
	start_armorvalue   = warmup_start_armorvalue   = 0;

	start_ammo_shells  = warmup_start_ammo_shells  = 0;
	start_ammo_nails   = warmup_start_ammo_nails   = 0;
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_instagib_ammo_start");
	start_ammo_plasma  = warmup_start_ammo_plasma  = 0;
	start_ammo_rockets = warmup_start_ammo_rockets = 0;
	//start_ammo_fuel    = warmup_start_ammo_fuel    = 0;

	start_weapons = warmup_start_weapons = WEPSET(VAPORIZER);
	start_items |= IT_UNLIMITED_SUPERWEAPONS;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, SetWeaponArena)
{
	// turn weapon arena off
	M_ARGV(0, string) = "off";
}

void replace_with_insta_cells(entity item)
{
	entity e = new(item_vaporizer_cells);
	setorigin(e, item.origin);
	e.noalign = Item_ShouldKeepPosition(item);
	e.cnt = item.cnt;
	e.team = item.team;
	e.spawnfunc_checked = true;
	spawnfunc_item_vaporizer_cells(e);
}

MUTATOR_HOOKFUNCTION(mutator_instagib, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if(item.classname == "item_cells")
	{
		if(autocvar_g_instagib_ammo_convert_cells)
		{
			replace_with_insta_cells(item);
		}
		return true;
	}
	else if(item.classname == "item_rockets")
	{
		if(autocvar_g_instagib_ammo_convert_rockets)
		{
			replace_with_insta_cells(item);
		}
		return true;
	}
	else if(item.classname == "item_shells")
	{
		if(autocvar_g_instagib_ammo_convert_shells)
		{
			replace_with_insta_cells(item);
		}
		return true;
	}
	else if(item.classname == "item_bullets")
	{
		if(autocvar_g_instagib_ammo_convert_bullets)
		{
			replace_with_insta_cells(item);
		}
		return true;
	}

	if(item.weapon == WEP_VAPORIZER.m_id && Item_IsLoot(item))
	{
		SetResource(item, RES_CELLS, autocvar_g_instagib_ammo_drop);
		return false;
	}

	if(item.weapon == WEP_DEVASTATOR.m_id || item.weapon == WEP_VORTEX.m_id)
	{
		replace_with_insta_cells(item);
		return true;
	}

	if(item.itemdef.instanceOfPowerup)
		return false;

	float cells = GetResource(item, RES_CELLS);
	if(cells > autocvar_g_instagib_ammo_drop && item.classname != "item_vaporizer_cells")
		SetResource(item, RES_CELLS, autocvar_g_instagib_ammo_drop);

	if(cells && !item.weapon)
		return false;

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerDies)
{
	float frag_deathtype = M_ARGV(3, float);

	if(DEATH_ISWEAPON(frag_deathtype, WEP_VAPORIZER))
		M_ARGV(4, float) = 1000; // always gib if it was a vaporizer death
}

MUTATOR_HOOKFUNCTION(mutator_instagib, ItemTouch)
{
	if(MUTATOR_RETURNVALUE) return false;

	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	if(GetResource(item, RES_CELLS))
	{
		// play some cool sounds ;)
		float hp = GetResource(toucher, RES_HEALTH);
		if (IS_CLIENT(toucher))
		{
			if(hp <= 5)
				Send_Notification(NOTIF_ONE, toucher, MSG_ANNCE, ANNCE_INSTAGIB_LASTSECOND);
			else if(hp < 50)
				Send_Notification(NOTIF_ONE, toucher, MSG_ANNCE, ANNCE_INSTAGIB_NARROWLY);
		}

		if(hp < 100)
			SetResource(toucher, RES_HEALTH, 100);

		return MUT_ITEMTOUCH_CONTINUE;
	}

	if(item.itemdef == ITEM_ExtraLife)
	{
		GiveResource(toucher, RES_ARMOR, autocvar_g_instagib_extralives);
		Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_EXTRALIVES, autocvar_g_instagib_extralives);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, OnEntityPreSpawn)
{
	if (MUTATOR_RETURNVALUE) return false;
	if (!autocvar_g_powerups) { return; }
	entity ent = M_ARGV(0, entity);
	// Can't use .itemdef here
	if (!(ent.classname == "item_strength" || ent.classname == "item_shield" || ent.classname == "item_invincible" || ent.classname == "item_health_mega"))
		return;

	entity e = spawn();

	float r = random();
	if (r < 0.3)
	{
		e.classname = "item_invisibility";
		setthink(e, instagib_invisibility);
	}
	else if (r < 0.6)
	{
		e.classname = "item_extralife";
		setthink(e, instagib_extralife);
	}
	else
	{
		e.classname = "item_speed";
		setthink(e, instagib_speed);
	}

	e.nextthink = time + 0.1;
	e.spawnflags = ent.spawnflags;
	e.noalign = ent.noalign;
	setorigin(e, ent.origin);

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":instagib");
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", InstaGib");
}

MUTATOR_HOOKFUNCTION(mutator_instagib, SetModname)
{
	M_ARGV(0, string) = "InstaGib";
	return true;
}
