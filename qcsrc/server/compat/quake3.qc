#include "quake3.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include <server/items.qh>
#include <server/resources.qh>
#include <common/t_items.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mapobjects/trigger/counter.qh>
#include <common/weapons/_all.qh>

//***********************
//QUAKE 3 ENTITIES - So people can play quake3 maps with the xonotic weapons
//***********************

// NOTE: for best experience, you need to swap MGs with SGs in the map or it won't have a MG

// SG -> SG
SPAWNFUNC_ITEM(ammo_shells, ITEM_Shells)

// MG -> MG
SPAWNFUNC_ITEM(ammo_bullets, ITEM_Bullets)

// GL -> Mortar
SPAWNFUNC_ITEM(ammo_grenades, ITEM_Rockets)

// Mines -> Rockets
SPAWNFUNC_WEAPON(weapon_prox_launcher, WEP_MINE_LAYER)
SPAWNFUNC_ITEM(ammo_mines, ITEM_Rockets)

// LG -> Lightning
SPAWNFUNC_WEAPON(weapon_lightning, WEP_ELECTRO)
SPAWNFUNC_ITEM(ammo_lightning, ITEM_Cells)

// Plasma -> Hagar
SPAWNFUNC_WEAPON(weapon_plasmagun, WEP_HAGAR)
SPAWNFUNC_ITEM(ammo_cells, ITEM_Rockets)

// Rail -> Vortex
SPAWNFUNC_WEAPON(weapon_railgun, WEP_VORTEX)
SPAWNFUNC_ITEM(ammo_slugs, ITEM_Cells)

// BFG -> Crylink
SPAWNFUNC_WEAPON(weapon_bfg, WEP_CRYLINK)
SPAWNFUNC_ITEM(ammo_bfg, ITEM_Cells)

// grappling hook -> hook
SPAWNFUNC_WEAPON(weapon_grapplinghook, WEP_HOOK)

// RL -> RL
SPAWNFUNC_ITEM(ammo_rockets, ITEM_Rockets)

// Armor
SPAWNFUNC_ITEM(item_armor_body, ITEM_ArmorMega)
SPAWNFUNC_ITEM(item_armor_combat, ITEM_ArmorBig)
SPAWNFUNC_ITEM(item_armor_shard, ITEM_ArmorSmall)
SPAWNFUNC_ITEM(item_enviro, ITEM_Shield)

// medkit -> armor (we have no holdables)
SPAWNFUNC_ITEM(holdable_medkit, ITEM_ArmorMega)

// doubler -> strength
SPAWNFUNC_ITEM(item_doubler, ITEM_Strength)

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
		SetResource(actor, RES_SHELLS, start_ammo_shells);
		SetResource(actor, RES_BULLETS, start_ammo_nails);
		SetResource(actor, RES_ROCKETS, start_ammo_rockets);
		SetResource(actor, RES_CELLS, start_ammo_cells);
		SetResource(actor, RES_PLASMA, start_ammo_plasma);
		SetResource(actor, RES_FUEL, start_ammo_fuel);

		STAT(WEAPONS, actor) = start_weapons;
		if (this.spawnflags & 32)
		{
			// TODO
		}
	}

	if (!(this.spawnflags & 8))
	{
		actor.strength_finished = 0;
		actor.invincible_finished = 0;
		STAT(BUFFS, actor) = 0;
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

// weapon give ent from defrag
void target_give_init(entity this)
{
	IL_EACH(g_items, it.targetname == this.target,
	{
		if (it.classname == "weapon_devastator") {
			SetResourceExplicit(this, RES_ROCKETS, GetResource(this, RES_ROCKETS) + it.count * WEP_CVAR_PRI(devastator, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "devastator");
		}
		else if (it.classname == "weapon_vortex") {
			SetResourceExplicit(this, RES_CELLS, GetResource(this, RES_CELLS) + it.count * WEP_CVAR_PRI(vortex, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "vortex");
		}
		else if (it.classname == "weapon_electro") {
			SetResourceExplicit(this, RES_CELLS, GetResource(this, RES_CELLS) + it.count * WEP_CVAR_PRI(electro, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "electro");
		}
		else if (it.classname == "weapon_hagar") {
			SetResourceExplicit(this, RES_ROCKETS, GetResource(this, RES_ROCKETS) + it.count * WEP_CVAR_PRI(hagar, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "hagar");
		}
		else if (it.classname == "weapon_crylink") {
			SetResourceExplicit(this, RES_CELLS, GetResource(this, RES_CELLS) + it.count * WEP_CVAR_PRI(crylink, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "crylink");
		}
		else if (it.classname == "weapon_mortar") {
			SetResourceExplicit(this, RES_ROCKETS, GetResource(this, RES_ROCKETS) + it.count * WEP_CVAR_PRI(mortar, ammo)); // WEAPONTODO
			this.netname = cons(this.netname, "mortar");
		}
		else if (it.classname == "item_armor_mega")
			SetResourceExplicit(this, RES_ARMOR, 100);
		else if (it.classname == "item_health_mega")
			SetResourceExplicit(this, RES_HEALTH, 200);
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

//spawnfunc(item_flight)       /* handled by buffs mutator */
//spawnfunc(item_haste)        /* handled by buffs mutator */
//spawnfunc(item_health)       /* handled in t_quake.qc */
//spawnfunc(item_health_large) /* handled in t_items.qc */
//spawnfunc(item_health_small) /* handled in t_items.qc */
//spawnfunc(item_health_mega)  /* handled in t_items.qc */
//spawnfunc(item_invis)        /* handled by buffs mutator */
//spawnfunc(item_regen)        /* handled by buffs mutator */

// CTF spawnfuncs handled in mutators/gamemode_ctf.qc now

.float notteam;
.float notsingle;
.float notfree;
.float notq3a;
.float notta;
.string gametype;
bool DoesQ3ARemoveThisEntity(entity this)
{
	// Q3 style filters (DO NOT USE, THIS IS COMPAT ONLY)

	if(this.notq3a)
		if(!teamplay || g_tdm || g_ctf)
			return true;

	if(this.notta)
		if (!(!teamplay || g_tdm || g_ctf))
			return true;

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
		// static char *gametypeNames[] = {"ffa", "tournament", "single", "team", "ctf", "oneflag", "obelisk", "harvester", "teamtournament"}
		gametypename = "ffa";
		if(teamplay)
			gametypename = "team";
		if(g_ctf)
			gametypename = "ctf";
		if(g_duel)
			gametypename = "tournament";
		if(maxclients == 1)
			gametypename = "single";
		// we do not have the other types (oneflag, obelisk, harvester, teamtournament)
		if(strstrofs(this.gametype, gametypename, 0) < 0)
			return true;
	}

	return false;
}
