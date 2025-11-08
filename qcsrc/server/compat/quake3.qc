#include "quake3.qh"

#include <common/gametypes/_mod.qh>
#include <common/gametypes/gametype/ctf/sv_ctf.qh>
#include <common/mapobjects/trigger/counter.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/buffs/_mod.qh>
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
 item_key_gold               QL     keys.qc
 item_key_silver             QL     keys.qc
 item_key_master             QL     keys.qc
 weapon_machinegun           Q3A    machinegun.qh
 weapon_grenadelauncher      Q3A    mortar.qh
 weapon_rocketlauncher       Q3A    devastator.qh
 * CTF spawnfuncs in sv_ctf.qc

 NOTE: for best experience, you need to swap MGs with SGs in the map or it won't have a MG
 Guns that are very different may need .count scaling beyond that of GetAmmoConsumption().
*/

// Shotgun <-> Machine Gun
// We don't want the swap on defrag maps (some of which have a valid .arena file as well as the .defi).
// In Q3 defaults SG has 10 shells and MG has 100 bullets, Xonotic's GetAmmoConsumption() will return 1 for both
// so .count will be out by 10x, however Xonotic has a stronger MG than Q3 so using 8x for SG->MG.
SPAWNFUNC_Q3(weapon_shotgun, ammo_shells,
             q3compat == Q3COMPAT_ARENA ? WEP_MACHINEGUN : WEP_SHOTGUN,
             q3compat == Q3COMPAT_ARENA ? 8 : 1)
SPAWNFUNC_Q3(weapon_machinegun, ammo_bullets,
             q3compat == Q3COMPAT_ARENA ? WEP_SHOTGUN : WEP_MACHINEGUN,
             q3compat == Q3COMPAT_ARENA ? 0.1 : 1)

// Grenade Launcher -> Mortar
SPAWNFUNC_Q3(weapon_grenadelauncher, ammo_grenades, WEP_MORTAR)

// Team Arena Proximity Launcher -> Mine Layer
SPAWNFUNC_Q3(weapon_prox_launcher, ammo_mines, WEP_MINE_LAYER)

// Team Arena Chain Gun -> HLAC
SPAWNFUNC_Q3(weapon_chaingun, ammo_belt, WEP_HLAC)

// Quake Live Heavy MachineGun -> HLAC
SPAWNFUNC_Q3(weapon_hmg, ammo_hmg, WEP_HLAC)

// Team Arena Nail Gun -> Crylink || Quake Nail Gun -> Electro
SPAWNFUNC_Q3(weapon_nailgun, ammo_nails, autocvar_sv_mapformat_is_quake3 ? WEP_CRYLINK : WEP_ELECTRO)

// Lightning Gun -> Electro
// Damage potential of 100 LG bolts (varies between Q3 derivatives) is roughly half that of 100 electro cells,
// Xonotic's GetAmmoConsumption() will return 4 so we need a 1/8 .count scale here.
SPAWNFUNC_Q3(weapon_lightning, ammo_lightning, WEP_ELECTRO, 0.125)

// Plasma Gun -> Hagar
SPAWNFUNC_Q3(weapon_plasmagun, ammo_cells, WEP_HAGAR)

// Rail Gun -> Vortex
SPAWNFUNC_Q3(weapon_railgun, ammo_slugs, WEP_VORTEX)

// BFG -> Crylink || Fireball
SPAWNFUNC_Q3(weapon_bfg, ammo_bfg, cvar_string("g_mod_balance") == "XDF" ? WEP_CRYLINK : WEP_FIREBALL)
	// NB: WEP_FIREBALL has no ammo_type field so ammo_bfg is deleted by SPAWNFUNC_BODY

// Grappling Hook
SPAWNFUNC_WEAPON(weapon_grapplinghook, WEP_HOOK)
	// NB: in Q3 this doesn't use ammo

// Rocket Launcher -> Devastator
SPAWNFUNC_Q3(weapon_rocketlauncher, ammo_rockets, WEP_DEVASTATOR)

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
			SetResource(actor, RES_FUEL, 0);

			STAT(WEAPONS, actor) = WEPSET(SHOTGUN);
		}
		else
		{
			SetResource(actor, RES_SHELLS, start_ammo_shells);
			SetResource(actor, RES_BULLETS, start_ammo_nails);
			SetResource(actor, RES_ROCKETS, start_ammo_rockets);
			SetResource(actor, RES_CELLS, start_ammo_cells);
			SetResource(actor, RES_FUEL, start_ammo_fuel);

			STAT(WEAPONS, actor) = start_weapons;
		}
	}

	if (!(this.spawnflags & 8))
	{
		FOREACH(StatusEffects, it.instanceOfPowerupStatusEffect,
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

#define FRAGSFILTER_REMOVER BIT(0)
#define FRAGSFILTER_RUNONCE BIT(1) // introduced but now unused by q3df
#define FRAGSFILTER_SILENT  BIT(2)
#define FRAGSFILTER_RESET   BIT(3)

void fragsfilter_use(entity this, entity actor, entity trigger)
{
	if(!IS_PLAYER(actor))
		return;
	if(actor.fragsfilter_cnt >= this.frags)
	{
		if(this.spawnflags & FRAGSFILTER_RESET)
			actor.fragsfilter_cnt = 0;
		else if(this.spawnflags & FRAGSFILTER_REMOVER)
			actor.fragsfilter_cnt -= this.frags;
		SUB_UseTargets(this, actor, trigger);
	}
	else if(!(this.spawnflags & FRAGSFILTER_SILENT))
	{
		int req_frags = this.frags - actor.fragsfilter_cnt;
		centerprint(actor, sprintf("%d more frag%s needed", req_frags, req_frags > 1 ? "s" : ""));
		play2(actor, SND(TALK));
	}
}
spawnfunc(target_fragsFilter)
{
	if(!g_cts) { delete(this); return; }

	if(!this.frags)
		this.frags = 1;
	this.use = fragsfilter_use;
}

#define PRINT_REDTEAM BIT(0) // Q3 only, not used in Q3DF
#define PRINT_BLUETEAM BIT(1) // Q3 only, not used in Q3DF
#define PRINT_PRIVATE BIT(2) // Q3 only, not used in Q3DF
#define PRINT_BROADCAST BIT(3) // Q3DF only, default behavior in Q3

void target_print_message(entity this, entity actor)
{
	centerprint(actor, this.message);
	play2(actor, SND(TALK));
}

void target_print_use(entity this, entity actor, entity trigger)
{
	if(!IS_PLAYER(actor))
		return;

	if(this.message == "")
		return;

	bool priv, red, blue;
	if(!(q3compat & Q3COMPAT_DEFI)) // Q3 spawnflags
	{
		priv = boolean(this.spawnflags & PRINT_PRIVATE);
		red = boolean(this.spawnflags & PRINT_REDTEAM);
		blue = boolean(this.spawnflags & PRINT_BLUETEAM);
	}
	else // Q3DF spawnflags
	{
		priv = !boolean(this.spawnflags & PRINT_BROADCAST);
		red = blue = false;
	}

	if(priv)
	{
		target_print_message(this, actor);
	}
	else
	{
		FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && ((!red && !blue) || (red && it.team == NUM_TEAM_1) || (blue && it.team == NUM_TEAM_2)), target_print_message(this, it));
	}
}

/*
 * ENTITY PARAMETERS:
 *
 *   message: text string to print on screen.
 *   targetname: the activating trigger points to this.
 */
spawnfunc(target_print)
{
	this.use = target_print_use;
}

// target_smallprint, Q3DF only
spawnfunc(target_smallprint)
{
	spawnfunc_target_print(this);
}

.string gametype;
.string not_gametype;
bool DoesQ3ARemoveThisEntity(entity this)
{
	// Q3 style filters (DO NOT USE, THIS IS COMPAT ONLY)

	if (!this.classname)
		return true;

	// DeFRaG mappers use "notcpm" or "notvq3" to disable an entity in CPM or VQ3 physics
	// Xonotic is usually played with a CPM-based physics so we default to CPM mode
	if(cvar_string("g_mod_physics") == "Q3")
	{
		if(stof(GetField_fullspawndata(this, "notvq3", false)))
			return true;
	}
	else if(stof(GetField_fullspawndata(this, "notcpm", false)))
		return true;

	// Q3 mappers use "notq3a" or "notta" to disable an entity in Q3A or Q3TA
	// Xonotic has ~equivalent features to Team Arena
	if(stof(GetField_fullspawndata(this, "notta", false)))
		return true;

	// FIXME: singleplayer does not use maxclients 1 as that would prevent bots,
	// this is the case in Q3 also, it uses another method to block clients.
	// Only accessible in VQ3, via the `spmap` command.
	if(stof(GetField_fullspawndata(this, "notsingle", false)))
		if(maxclients == 1 && IS_GAMETYPE(DEATHMATCH))
			return true;

	if(stof(GetField_fullspawndata(this, "notteam", false)))
		if(teamplay)
			return true;

	if(stof(GetField_fullspawndata(this, "notfree", false)))
		if(!teamplay)
			return true;

	if(this.gametype || this.not_gametype)
	{
		// Q3 checks these with strstr(): case-sensitive, no gametype can be a substring of another,
		// any separator is allowed (conventions are: spaces, commas, or commas with spaces).
		// QL's entities.def says they're space delineated.

		// Q3 gametype entity fields: ffa tournament single team ctf oneflag obelisk  harvester    (game/g_spawn.c)
		// Q3 arena file 'type' key:  ffa tourney                ctf oneflag overload harvester    (ui/ui_gameinfo.c)

		// QL gametype entity fields: ffa duel tdm ca ft rr ctf ad dom har 1f      race ob
		// QL arena file 'type' key:  ffa duel tdm ca ft rr ctf ad dom har oneflag race

		string gametypename_q3, gametypename_ql;

		// One of these will apply if our gametype has no Q3/QL equivalent
		if(teamplay)
		{
			gametypename_q3 = "team";
			gametypename_ql = "tdm";
		}
		else
			gametypename_q3 = gametypename_ql = "ffa";

		if(g_ctf)
		{
			if (ctf_oneflag)
			{
				gametypename_q3 = "oneflag";
				gametypename_ql = "1f";
			}
			else
				gametypename_q3 = gametypename_ql = "ctf";
		}
		else if(g_duel)
		{
			gametypename_q3 = "tournament";
			gametypename_ql = "duel";
		}
		else if(IS_GAMETYPE(DEATHMATCH) && maxclients == 1)
			gametypename_q3 = "single";
		else if(g_ca)
			gametypename_ql = "ql";
		else if(IS_GAMETYPE(FREEZETAG))
			gametypename_ql = "ft";
		else if(IS_GAMETYPE(DOMINATION))
			gametypename_ql = "dom";
		else if(g_race || g_cts)
			gametypename_ql = "race";

		if(this.gametype)
		if(strstrofs(this.gametype, gametypename_q3, 0) < 0
		&& strstrofs(this.gametype, gametypename_ql, 0) < 0)
			return true;

		// Only supported by QL
		if(strstrofs(this.not_gametype, gametypename_ql, 0) >= 0)
			return true;
	}

	return false;
}
