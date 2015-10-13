#ifndef MUTATOR_INSTAGIB_H
#define MUTATOR_INSTAGIB_H

#include "items.qc"

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC

#include "../../../../server/cl_client.qh"
#include "../../../buffs/all.qh"

#include "../../../items/all.qc"

REGISTER_MUTATOR(mutator_instagib, cvar("g_instagib") && !g_nexball);

spawnfunc(item_minst_cells)
{
	if (!g_instagib) { remove(self); return; }
	if (!self.ammo_cells) self.ammo_cells = autocvar_g_instagib_ammo_drop;
	StartItemA(ITEM_VaporizerCells);
}

void instagib_invisibility()
{SELFPARAM();
	self.strength_finished = autocvar_g_balance_powerup_strength_time;
	StartItemA(ITEM_Invisibility);
}

void instagib_extralife()
{SELFPARAM();
	self.max_health = 1;
	StartItemA(ITEM_ExtraLife);
}

void instagib_speed()
{SELFPARAM();
	self.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	StartItemA(ITEM_Speed);
}

.float instagib_nextthink;
.float instagib_needammo;
void instagib_stop_countdown(entity e)
{
	if (!e.instagib_needammo)
		return;
	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER_CPID, CPID_INSTAGIB_FINDAMMO);
	e.instagib_needammo = false;
}
void instagib_ammocheck()
{SELFPARAM();
	if(time < self.instagib_nextthink)
		return;
	if(!IS_PLAYER(self))
		return; // not a player

	if(self.deadflag || gameover)
		instagib_stop_countdown(self);
	else if (self.ammo_cells > 0 || (self.items & IT_UNLIMITED_WEAPON_AMMO) || (self.flags & FL_GODMODE))
		instagib_stop_countdown(self);
	else if(autocvar_g_rm && autocvar_g_rm_laser)
	{
		if(!self.instagib_needammo)
		{
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_INSTAGIB_DOWNGRADE);
			self.instagib_needammo = true;
		}
	}
	else
	{
		self.instagib_needammo = true;
		if (self.health <= 5)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_INSTAGIB_TERMINATED);
		}
		else if (self.health <= 10)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_1);
		}
		else if (self.health <= 20)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_2);
		}
		else if (self.health <= 30)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_3);
		}
		else if (self.health <= 40)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_4);
		}
		else if (self.health <= 50)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_5);
		}
		else if (self.health <= 60)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_6);
		}
		else if (self.health <= 70)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_7);
		}
		else if (self.health <= 80)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_8);
		}
		else if (self.health <= 90)
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_INSTAGIB_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_9);
		}
		else
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_MULTI, MULTI_INSTAGIB_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO.m_id, self.origin, '0 0 0');
		}
	}
	self.instagib_nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MatchEnd)
{
	entity head;
	FOR_EACH_PLAYER(head)
		instagib_stop_countdown(head);

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MonsterDropItem)
{
	other.monster_loot = spawnfunc_item_minst_cells;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MonsterSpawn)
{SELFPARAM();
	// always refill ammo
	if(self.monsterid == MON_MAGE.monsterid)
		self.skin = 1;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BotShouldAttack)
{
	if (checkentity.items & ITEM_Invisibility.m_itemid)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, MakePlayerObserver)
{SELFPARAM();
	instagib_stop_countdown(self);
	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerSpawn)
{SELFPARAM();
	self.effects |= EF_FULLBRIGHT;
	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPreThink)
{
	instagib_ammocheck();
	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerRegen)
{
	// no regeneration in instagib
	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPowerups)
{SELFPARAM();
	if (!(self.effects & EF_FULLBRIGHT))
		self.effects |= EF_FULLBRIGHT;

	if (self.items & ITEM_Invisibility.m_itemid)
	{
		play_countdown(self.strength_finished, SND(POWEROFF));
		if (time > self.strength_finished)
		{
			self.alpha = default_player_alpha;
			self.exteriorweaponentity.alpha = default_weapon_alpha;
			self.items &= ~ITEM_Invisibility.m_itemid;
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_INVISIBILITY);
		}
	}
	else
	{
		if (time < self.strength_finished)
		{
			self.alpha = autocvar_g_instagib_invis_alpha;
			self.exteriorweaponentity.alpha = autocvar_g_instagib_invis_alpha;
			self.items |= ITEM_Invisibility.m_itemid;
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_INVISIBILITY, self.netname);
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_INVISIBILITY);
		}
	}

	if (self.items & ITEM_Speed.m_itemid)
	{
		play_countdown(self.invincible_finished, SND(POWEROFF));
		if (time > self.invincible_finished)
		{
			self.items &= ~ITEM_Speed.m_itemid;
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_SPEED);
		}
	}
	else
	{
		if (time < self.invincible_finished)
		{
			self.items |= ITEM_Speed.m_itemid;
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_SPEED, self.netname);
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_SPEED);
		}
	}
	return false;
}

.float stat_sv_maxspeed;

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerPhysics)
{SELFPARAM();
	if(self.items & ITEM_Speed.m_itemid)
		self.stat_sv_maxspeed = self.stat_sv_maxspeed * autocvar_g_instagib_speed_highspeed;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerDamage_SplitHealthArmor)
{
	damage_save = 0;
	damage_take = frag_damage;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, ForbidThrowCurrentWeapon)
{
	// weapon dropping on death handled by FilterItem

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerDamage_Calculate)
{
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
			if(frag_target.armorvalue)
			{
				frag_target.armorvalue -= 1;
				frag_damage = 0;
				frag_target.damage_dealt += 1;
				frag_attacker.damage_dealt += 1; // TODO: change this to a specific hitsound for armor hit
				Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, frag_target.armorvalue);
			}
		}

		if(IS_PLAYER(frag_attacker) && DEATH_ISWEAPON(frag_deathtype, WEP_BLASTER))
		{
			if(frag_deathtype & HITTYPE_SECONDARY)
			{
				if(!autocvar_g_instagib_blaster_keepdamage)
					frag_damage = frag_mirrordamage = 0;

				if(frag_target != frag_attacker)
				{
					if(frag_damage <= 0 && frag_target.health > 0) { Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_SECONDARY_NODAMAGE); }
					if(!autocvar_g_instagib_blaster_keepforce)
						frag_force = '0 0 0';
				}
			}
		}
	}

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

	if((frag_target.buffs & BUFF_INVISIBLE.m_itemid) || (frag_target.items & ITEM_Invisibility.m_itemid))
		yoda = 1;

	return false;
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
	start_ammo_fuel    = warmup_start_ammo_fuel    = 0;

	start_weapons = warmup_start_weapons = WEPSET(VAPORIZER);
	start_items |= IT_UNLIMITED_SUPERWEAPONS;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, FilterItem)
{SELFPARAM();
	if(self.classname == "item_cells")
		return true; // no normal cells?

	if(self.weapon == WEP_VAPORIZER.m_id && self.classname == "droppedweapon")
	{
		self.ammo_cells = autocvar_g_instagib_ammo_drop;
		return false;
	}

	if(self.weapon == WEP_DEVASTATOR.m_id || self.weapon == WEP_VORTEX.m_id)
	{
		entity e = spawn();
		setorigin(e, self.origin);
		e.noalign = self.noalign;
        e.cnt = self.cnt;
        e.team = self.team;
		WITH(entity, self, e, spawnfunc_item_minst_cells(e));
		return true;
	}

	if(self.flags & FL_POWERUP)
		return false;

	if(self.ammo_cells > autocvar_g_instagib_ammo_drop && self.classname != "item_minst_cells")
		self.ammo_cells = autocvar_g_instagib_ammo_drop;

	if(self.ammo_cells && !self.weapon)
		return false;

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, CustomizeWaypoint)
{SELFPARAM();
	entity e = WaypointSprite_getviewentity(other);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if((self.owner.flags & FL_CLIENT) && (self.owner.items & ITEM_Invisibility.m_itemid) && (e == other))
	if(DIFF_TEAM(self.owner, e))
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, PlayerDies)
{
	if(DEATH_ISWEAPON(frag_deathtype, WEP_VAPORIZER))
		frag_damage = 1000; // always gib if it was a vaporizer death

	return FALSE;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, ItemTouch)
{SELFPARAM();
	if(self.ammo_cells)
	{
		// play some cool sounds ;)
		if (IS_CLIENT(other))
		{
			if(other.health <= 5)
				Send_Notification(NOTIF_ONE, other, MSG_ANNCE, ANNCE_INSTAGIB_LASTSECOND);
			else if(other.health < 50)
				Send_Notification(NOTIF_ONE, other, MSG_ANNCE, ANNCE_INSTAGIB_NARROWLY);
		}

		if(other.health < 100)
			other.health = 100;

		return MUT_ITEMTOUCH_CONTINUE;
	}

	if(self.max_health)
	{
		other.armorvalue = bound(other.armorvalue, 999, other.armorvalue + autocvar_g_instagib_extralives);
		Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_EXTRALIVES);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, OnEntityPreSpawn)
{SELFPARAM();
	if (!autocvar_g_powerups) { return false; }
	// Can't use .itemdef here
	if (!(self.classname == "item_strength" || self.classname == "item_invincible" || self.classname == "item_health_mega"))
		return false;

	entity e = spawn();

	float r = random();
	if (r < 0.3)
		e.think = instagib_invisibility;
	else if (r < 0.6)
		e.think = instagib_extralife;
	else
		e.think = instagib_speed;

	e.nextthink = time + 0.1;
	e.spawnflags = self.spawnflags;
	e.noalign = self.noalign;
	setorigin(e, self.origin);

	return true;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":instagib");
	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", instagib");
	return false;
}

MUTATOR_HOOKFUNCTION(mutator_instagib, SetModname)
{
	modname = "instagib";
	return true;
}

#endif
#endif
