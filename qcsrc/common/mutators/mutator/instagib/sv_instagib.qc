#include "sv_instagib.qh"

//int autocvar_g_instagib_ammo_drop;
bool autocvar_g_instagib_ammo_convert_cells;
bool autocvar_g_instagib_ammo_convert_rockets;
bool autocvar_g_instagib_ammo_convert_shells;
bool autocvar_g_instagib_ammo_convert_bullets;
int autocvar_g_instagib_extralives;
float autocvar_g_instagib_speed_highspeed;

#include <server/client.qh>

#include <common/items/_mod.qh>

REGISTER_MUTATOR(mutator_instagib, cvar("g_instagib") && !g_nexball);

spawnfunc(item_minst_cells)
{
	if (!g_instagib) { delete(this); return; }
	StartItem(this, ITEM_VaporizerCells);
}

void instagib_invisibility(entity this)
{
	this.strength_finished = autocvar_g_balance_powerup_strength_time;
	StartItem(this, ITEM_Invisibility);
}

void instagib_extralife(entity this)
{
	StartItem(this, ITEM_ExtraLife);
}

void instagib_speed(entity this)
{
	this.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	StartItem(this, ITEM_Speed);
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
void instagib_ammocheck(entity this)
{
	if(time < this.instagib_nextthink)
		return;
	if(!IS_PLAYER(this))
		return; // not a player

	if(IS_DEAD(this) || game_stopped)
		instagib_stop_countdown(this);
	else if (this.ammo_cells > 0 || (this.items & IT_UNLIMITED_WEAPON_AMMO) || (this.flags & FL_GODMODE))
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
		if (this.health <= 5)
		{
			Damage(this, this, this, 5, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_INSTAGIB_TERMINATED);
		}
		else if (this.health <= 10)
		{
			Damage(this, this, this, 5, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_1);
		}
		else if (this.health <= 20)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_2);
		}
		else if (this.health <= 30)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_3);
		}
		else if (this.health <= 40)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_4);
		}
		else if (this.health <= 50)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_5);
		}
		else if (this.health <= 60)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_6);
		}
		else if (this.health <= 70)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_7);
		}
		else if (this.health <= 80)
		{
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_8);
		}
		else if (this.health <= 90)
		{
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_INSTAGIB_FINDAMMO);
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_NUM_9);
		}
		else
		{
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_MULTI, MULTI_INSTAGIB_FINDAMMO);
			Damage(this, this, this, 10, DEATH_NOAMMO.m_id, this.origin, '0 0 0');
		}
	}
	this.instagib_nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MatchEnd)
{
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(instagib_stop_countdown(it)));
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
	if(mon.monsterid == MON_MAGE.monsterid)
		mon.skin = 1;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BotShouldAttack)
{
	entity targ = M_ARGV(1, entity);

	if (targ.items & ITEM_Invisibility.m_itemid)
		return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	instagib_stop_countdown(player);
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

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPowerups)
{
	entity player = M_ARGV(0, entity);

	if (!(player.effects & EF_FULLBRIGHT))
		player.effects |= EF_FULLBRIGHT;

	if (player.items & ITEM_Invisibility.m_itemid)
	{
		play_countdown(player, player.strength_finished, SND_POWEROFF);
		if (time > player.strength_finished)
		{
			player.alpha = default_player_alpha;
			player.exteriorweaponentity.alpha = default_weapon_alpha;
			player.items &= ~ITEM_Invisibility.m_itemid;
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_POWERDOWN_INVISIBILITY);
		}
	}
	else
	{
		if (time < player.strength_finished)
		{
			player.alpha = autocvar_g_instagib_invis_alpha;
			player.exteriorweaponentity.alpha = autocvar_g_instagib_invis_alpha;
			player.items |= ITEM_Invisibility.m_itemid;
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_INVISIBILITY, player.netname);
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_POWERUP_INVISIBILITY);
		}
	}

	if (player.items & ITEM_Speed.m_itemid)
	{
		play_countdown(player, player.invincible_finished, SND_POWEROFF);
		if (time > player.invincible_finished)
		{
			player.items &= ~ITEM_Speed.m_itemid;
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_POWERDOWN_SPEED);
		}
	}
	else
	{
		if (time < player.invincible_finished)
		{
			player.items |= ITEM_Speed.m_itemid;
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_SPEED, player.netname);
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_POWERUP_SPEED);
		}
	}
}

.float stat_sv_maxspeed;

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);

	if(player.items & ITEM_Speed.m_itemid)
		player.stat_sv_maxspeed = player.stat_sv_maxspeed * autocvar_g_instagib_speed_highspeed;
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

			if(frag_target.armorvalue)
			{
				frag_target.armorvalue -= 1;
				frag_damage = 0;
				frag_target.damage_dealt += 1;
				frag_attacker.damage_dealt += 1;
				Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, frag_target.armorvalue);
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
					if(frag_damage <= 0 && frag_target.health > 0) { Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_SECONDARY_NODAMAGE); }
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
		if(frag_attacker.armorvalue > 0)
		{
			frag_attacker.armorvalue -= 1;
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, frag_attacker.armorvalue);
			frag_attacker.damage_dealt += frag_mirrordamage;
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

MUTATOR_HOOKFUNCTION(mutator_instagib, SetStartItems)
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
	entity e = spawn();
	setorigin(e, item.origin);
	e.noalign = item.noalign;
	e.cnt = item.cnt;
	e.team = item.team;
	e.spawnfunc_checked = true;
	spawnfunc_item_minst_cells(e);
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

	if(item.weapon == WEP_VAPORIZER.m_id && item.classname == "droppedweapon")
	{
		item.ammo_cells = autocvar_g_instagib_ammo_drop;
		return false;
	}

	if(item.weapon == WEP_DEVASTATOR.m_id || item.weapon == WEP_VORTEX.m_id)
	{
		replace_with_insta_cells(item);
		return true;
	}

	if(item.flags & FL_POWERUP)
		return false;

	if(item.ammo_cells > autocvar_g_instagib_ammo_drop && item.classname != "item_minst_cells")
		item.ammo_cells = autocvar_g_instagib_ammo_drop;

	if(item.ammo_cells && !item.weapon)
		return false;

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, CustomizeWaypoint)
{
	entity wp = M_ARGV(0, entity);
	entity player = M_ARGV(1, entity);

	entity e = WaypointSprite_getviewentity(player);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if((wp.owner.flags & FL_CLIENT) && (wp.owner.items & ITEM_Invisibility.m_itemid) && (e == player))
	if(DIFF_TEAM(wp.owner, e))
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
	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	if(item.ammo_cells)
	{
		// play some cool sounds ;)
		if (IS_CLIENT(toucher))
		{
			if(toucher.health <= 5)
				Send_Notification(NOTIF_ONE, toucher, MSG_ANNCE, ANNCE_INSTAGIB_LASTSECOND);
			else if(toucher.health < 50)
				Send_Notification(NOTIF_ONE, toucher, MSG_ANNCE, ANNCE_INSTAGIB_NARROWLY);
		}

		if(toucher.health < 100)
			toucher.health = 100;

		return MUT_ITEMTOUCH_CONTINUE;
	}

	if(item.itemdef == ITEM_ExtraLife)
	{
		toucher.armorvalue = bound(toucher.armorvalue, 999, toucher.armorvalue + autocvar_g_instagib_extralives);
		Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_EXTRALIVES);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, OnEntityPreSpawn)
{
	if (!autocvar_g_powerups) { return; }
	entity ent = M_ARGV(0, entity);
	// Can't use .itemdef here
	if (!(ent.classname == "item_strength" || ent.classname == "item_invincible" || ent.classname == "item_health_mega"))
		return;

	entity e = spawn();

	float r = random();
	if (r < 0.3)
		setthink(e, instagib_invisibility);
	else if (r < 0.6)
		setthink(e, instagib_extralife);
	else
		setthink(e, instagib_speed);

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
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", instagib");
}

MUTATOR_HOOKFUNCTION(mutator_instagib, SetModname)
{
	M_ARGV(0, string) = "InstaGib";
	return true;
}
