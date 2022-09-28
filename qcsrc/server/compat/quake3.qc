#include "quake3.qh"

#include <common/gamemodes/_mod.qh>
#include <common/gamemodes/gamemode/ctf/sv_ctf.qh>
#include <common/mapobjects/trigger/counter.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/buffs/buffs.qh>
#include <common/mutators/mutator/buffs/sv_buffs.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/notifications/all.qh>
#include <common/resources/sv_resources.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/items/items.qh>
#include <server/items/spawning.qh>
#include <server/world.qh>

/***********************
 * QUAKE 3 ENTITIES - So people can play quake3 maps with the xonotic weapons
 ***********************

 * Map entities NOT handled in this file:
 holdable_invulnerability    Q3TA   buffs/all.inc
 holdable_kamikaze           Q3TA   buffs/all.inc
 holdable_teleporter         Q3A    buffs/all.inc
 item_ammoregen              Q3TA   buffs/all.inc
 item_doubler                Q3TA   buffs/all.inc
 item_guard                  Q3TA   buffs/all.inc
 item_scout                  Q3TA   buffs/all.inc
 item_armor_jacket           CPMA   quake2.qc
 item_flight                 Q3A    buffs/all.inc
 item_health                 Q3A    quake.qc
 item_health_large           Q3A    items/spawning.qc
 item_health_small           Q3A    health.qh
 item_health_mega            Q3A    health.qh
 item_regen                  Q3A    buffs/all.inc
 weapon_machinegun           Q3A    machinegun.qh
 weapon_grenadelauncher      Q3A    mortar.qh
 weapon_rocketlauncher       Q3A    devastator.qh
 * CTF spawnfuncs in sv_ctf.qc

 NOTE: for best experience, you need to swap MGs with SGs in the map or it won't have a MG
*/

// SG -> MG || SG
SPAWNFUNC_Q3_COND(weapon_shotgun, ammo_shells, (q3compat & Q3COMPAT_ARENA), WEP_MACHINEGUN, WEP_SHOTGUN)

// MG -> SG || MG
// Technically we should replace weapon_machinegun with WEP_SHOTGUN if Q3COMPAT_ARENA, but it almost never occurs on Q3 maps
SPAWNFUNC_Q3AMMO_COND(ammo_bullets, (q3compat & Q3COMPAT_ARENA), WEP_SHOTGUN, WEP_MACHINEGUN)

// GL -> Mortar
SPAWNFUNC_Q3AMMO(ammo_grenades, WEP_MORTAR)

// Team Arena Proximity Launcher -> Mortar
// It's more accurate to spawn Mine Layer but players prefer Mortar, and weapon_grenadelauncher is usually disabled by "notta" and weapon_prox_launcher placed at the same origin
SPAWNFUNC_Q3(weapon_prox_launcher, ammo_mines, WEP_MORTAR)

// Team Arena Chaingun -> HLAC
SPAWNFUNC_Q3(weapon_chaingun, ammo_belt, WEP_HLAC)

// Quake Live Heavy Machine Gun -> HLAC
SPAWNFUNC_Q3(weapon_hmg, ammo_hmg, WEP_HLAC)

// Team Arena Nailgun -> Crylink || Quake Nailgun -> Electro
SPAWNFUNC_Q3_COND(weapon_nailgun, ammo_nails, cvar("sv_mapformat_is_quake3"), WEP_CRYLINK, WEP_ELECTRO)

// LG -> Electro
SPAWNFUNC_Q3(weapon_lightning, ammo_lightning, WEP_ELECTRO)

// Plasma -> Hagar
SPAWNFUNC_Q3(weapon_plasmagun, ammo_cells, WEP_HAGAR)

// Rail -> Vortex
SPAWNFUNC_Q3(weapon_railgun, ammo_slugs, WEP_VORTEX)

// BFG -> Crylink || Fireball
SPAWNFUNC_Q3_COND(weapon_bfg, ammo_bfg, cvar_string("g_mod_balance") == "XDF", WEP_CRYLINK, WEP_FIREBALL)
	// FIXME: WEP_FIREBALL has no ammo_type field so ammo_bfg is deleted by SPAWNFUNC_BODY

// grappling hook -> hook
SPAWNFUNC_WEAPON(weapon_grapplinghook, WEP_HOOK)

// RL -> RL
SPAWNFUNC_Q3AMMO(ammo_rockets, WEP_DEVASTATOR)

// Gauntlet -> Tuba
SPAWNFUNC_ITEM(weapon_gauntlet, WEP_TUBA)

// Armor
SPAWNFUNC_ITEM(item_armor_body, ITEM_ArmorMega)
SPAWNFUNC_ITEM(item_armor_combat, ITEM_ArmorBig)
SPAWNFUNC_ITEM(item_armor_shard, ITEM_ArmorSmall)
SPAWNFUNC_ITEM(item_armor_green, ITEM_ArmorMedium) // CCTF

// Powerups
SPAWNFUNC_ITEM(item_quad, ITEM_Strength)
SPAWNFUNC_ITEM(item_enviro, ITEM_Shield)
SPAWNFUNC_ITEM(item_haste, ITEM_Speed)
SPAWNFUNC_ITEM(item_invis, ITEM_Invisibility)

// medkit -> armor (we have no holdables)
SPAWNFUNC_ITEM(holdable_medkit, ITEM_ArmorBig)

.float wait;
.float delay;

// weapon remove ent from df
void target_init_verify(entity this)
{
	entity trigger, targ;
	for(trigger = NULL; (trigger = find(trigger, classname, "trigger_multiple")); )
		for(targ = NULL; (targ = find(targ, targetname, trigger.target)); )
			if (targ.classname == "target_init" || targ.classname == "target_give" || targ.classname == "target_items")
			{
				trigger.wait = 0;
				trigger.delay = 0;
				targ.wait = 0;
				targ.delay = 0;

				//setsize(targ, trigger.mins, trigger.maxs);
				//setorigin(targ, trigger.origin);
				//remove(trigger);
			}
}

void target_init_use(entity this, entity actor, entity trigger)
{
	if (!(this.spawnflags & 1))
	{
		SetResource(actor, RES_ARMOR, start_armorvalue);
		actor.pauserotarmor_finished = time + autocvar_g_balance_pause_armor_rot;
	}

	if (!(this.spawnflags & 2))
	{
		SetResource(actor, RES_HEALTH, start_health);
		actor.pauserothealth_finished = time + autocvar_g_balance_pause_health_rot;
		actor.pauseregen_finished = time + autocvar_g_balance_pause_health_regen;
	}

	if (!(this.spawnflags & 4))
	{
		if(this.spawnflags & 32) // spawn with only melee
		{
			SetResource(actor, RES_SHELLS, 0);
			SetResource(actor, RES_BULLETS, 0);
			SetResource(actor, RES_ROCKETS, 0);
			SetResource(actor, RES_CELLS, 0);
			SetResource(actor, RES_PLASMA, 0);
			SetResource(actor, RES_FUEL, 0);

			STAT(WEAPONS, actor) = WEPSET(SHOTGUN);
		}
		else
		{
			SetResource(actor, RES_SHELLS, start_ammo_shells);
			SetResource(actor, RES_BULLETS, start_ammo_nails);
			SetResource(actor, RES_ROCKETS, start_ammo_rockets);
			SetResource(actor, RES_CELLS, start_ammo_cells);
			SetResource(actor, RES_PLASMA, start_ammo_plasma);
			SetResource(actor, RES_FUEL, start_ammo_fuel);

			STAT(WEAPONS, actor) = start_weapons;
		}
	}

	if (!(this.spawnflags & 8))
	{
		FOREACH(StatusEffect, it.instanceOfPowerups,
		{
			it.m_remove(it, actor, STATUSEFFECT_REMOVE_NORMAL);
		});
		entity heldbuff = buff_FirstFromFlags(actor);
		if(heldbuff) // TODO: make a dropbuffs function to handle this
		{
			int buffid = heldbuff.m_id;
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, ITEM_BUFF_DROP, buffid);
			sound(actor, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
			if(!IS_INDEPENDENT_PLAYER(actor))
				Send_Notification(NOTIF_ALL_EXCEPT, actor, MSG_INFO, INFO_ITEM_BUFF_LOST, actor.netname, buffid);
			buff_RemoveAll(actor, STATUSEFFECT_REMOVE_NORMAL);
		}
	}

	if (!(this.spawnflags & 16))
	{
		// We don't have holdables.
	}

	SUB_UseTargets(this, actor, trigger);
}

spawnfunc(target_init)
{
	this.use = target_init_use;
	InitializeEntity(this, target_init_verify, INITPRIO_FINDTARGET);
}

// weapon give ent from Q3
void target_give_init(entity this)
{
	IL_EACH(g_items, it.targetname == this.target,
	{
		if (it.classname == "item_buff")
		{
			this.netname = cons(this.netname, it.buffdef.netname);
			this.buffs_finished += it.buffs_finished;
		}
		else
		{
			this.ammo_rockets          += it.ammo_rockets;
			this.ammo_cells            += it.ammo_cells;
			this.ammo_shells           += it.ammo_shells;
			this.ammo_nails            += it.ammo_nails;
			this.invincible_finished   += it.invincible_finished;
			this.strength_finished     += it.strength_finished;
			this.speed_finished        += it.speed_finished;
			this.invisibility_finished += it.invisibility_finished;
			this.health                += it.health;
			this.armorvalue            += it.armorvalue;

			this.netname = cons(this.netname, (it.itemdef.m_weapon) ? it.itemdef.m_weapon.netname : it.itemdef.netname);
		}

		//remove(it); // removing ents in init functions causes havoc, workaround:
		setthink(it, SUB_Remove);
		it.nextthink = time;
	});
	this.spawnflags = 2;
	this.spawnfunc_checked = true;
	spawnfunc_target_items(this);
	InitializeEntity(this, target_init_verify, INITPRIO_FINDTARGET);
}

spawnfunc(target_give)
{
	InitializeEntity(this, target_give_init, INITPRIO_FINDTARGET);
}

void score_use(entity this, entity actor, entity trigger)
{
	if(!IS_PLAYER(actor))
		return;
	actor.fragsfilter_cnt += this.count;
}
spawnfunc(target_score)
{
	if(!g_cts) { delete(this); return; }

	if(!this.count)
		this.count = 1;
	this.use = score_use;
}

void fragsfilter_use(entity this, entity actor, entity trigger)
{
	if(!IS_PLAYER(actor))
		return;
	if(actor.fragsfilter_cnt >= this.frags)
		SUB_UseTargets(this, actor, trigger);
}
spawnfunc(target_fragsFilter)
{
	if(!g_cts) { delete(this); return; }

	if(!this.frags)
		this.frags = 1;
	this.use = fragsfilter_use;
}

.bool notteam;
.bool notsingle;
.bool notfree;
.bool notta;
.bool notvq3;
.bool notcpm;
.string gametype;
bool DoesQ3ARemoveThisEntity(entity this)
{
	// Q3 style filters (DO NOT USE, THIS IS COMPAT ONLY)

	// DeFRaG mappers use "notcpm" or "notvq3" to disable an entity in CPM or VQ3 physics
	// Xonotic is usually played with a CPM-based physics so we default to CPM mode
	if(cvar_string("g_mod_physics") == "Q3")
	{
		if(this.notvq3)
			return true;
	}
	else if(this.notcpm)
		return true;

	// Q3 mappers use "notq3a" or "notta" to disable an entity in Q3A or Q3TA
	// Xonotic has ~equivalent features to Team Arena
	if(this.notta)
		return true;

	// FIXME: singleplayer does not use maxclients 1 as that would prevent bots
	if(this.notsingle)
		if(maxclients == 1)
			return true;

	if(this.notteam)
		if(teamplay)
			return true;

	if(this.notfree)
		if(!teamplay)
			return true;

	if(this.gametype)
	{
		string gametypename;
		// From ioq3 g_spawn.c: static char *gametypeNames[] = {"ffa", "tournament", "single", "team", "ctf", "oneflag", "obelisk", "harvester"};
		gametypename = "ffa";
		if(teamplay)
			gametypename = "team";
		if(g_ctf)
			gametypename = "ctf";
		if(g_ctf && ctf_oneflag)
			gametypename = "oneflag";
		if(g_duel)
			gametypename = "tournament";
		if(maxclients == 1)
			gametypename = "single";
		// we do not have the other types (obelisk, harvester)
		if(strstrofs(this.gametype, gametypename, 0) < 0)
			return true;
	}

	return false;
}

int GetAmmoConsumptionQ3(string netname)
// Returns ammo consumed per shot by the primary/default fire mode
// Returns 0 if the netname has no ammo cvar
{
	switch (netname)
	{
		case "arc":	   return autocvar_g_balance_arc_beam_ammo;
		case "devastator": return autocvar_g_balance_devastator_ammo;
		case "machinegun": return autocvar_g_balance_machinegun_sustained_ammo;
		case "minelayer":  return autocvar_g_balance_minelayer_ammo;
		case "seeker":	   return autocvar_g_balance_seeker_tag_ammo;
		default:	   return cvar(strcat("g_balance_", netname, "_primary_ammo"));
	}
}

