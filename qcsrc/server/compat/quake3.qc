#include "quake3.qh"

#include <common/weapons/_all.qh>

spawnfunc(weapon_crylink);
spawnfunc(weapon_electro);
spawnfunc(weapon_hagar);
spawnfunc(weapon_machinegun);
spawnfunc(weapon_vortex);
spawnfunc(weapon_minelayer);

spawnfunc(target_items);

spawnfunc(item_bullets);
spawnfunc(item_cells);
spawnfunc(item_rockets);
spawnfunc(item_shells);

spawnfunc(item_strength);

spawnfunc(item_armor_big);
spawnfunc(item_armor_mega);
spawnfunc(item_armor_small);

spawnfunc(item_health_medium);
spawnfunc(item_health_mega);

//***********************
//QUAKE 3 ENTITIES - So people can play quake3 maps with the xonotic weapons
//***********************

// NOTE: for best experience, you need to swap MGs with SGs in the map or it won't have a MG

// SG -> SG
spawnfunc(ammo_shells)         { spawnfunc_item_shells(this);         }

// MG -> MG
spawnfunc(ammo_bullets)        { spawnfunc_item_bullets(this);        }

// GL -> Mortar
spawnfunc(ammo_grenades)       { spawnfunc_item_rockets(this);        }

// Mines -> Rockets
spawnfunc(weapon_prox_launcher) { spawnfunc_weapon_minelayer(this);   }
spawnfunc(ammo_mines)           { spawnfunc_item_rockets(this);       }

// LG -> Lightning
spawnfunc(weapon_lightning)    { spawnfunc_weapon_electro(this);      }
spawnfunc(ammo_lightning)      { spawnfunc_item_cells(this);          }

// Plasma -> Hagar
spawnfunc(weapon_plasmagun)    { spawnfunc_weapon_hagar(this);        }
spawnfunc(ammo_cells)          { spawnfunc_item_rockets(this);        }

// Rail -> Vortex
spawnfunc(weapon_railgun)      { spawnfunc_weapon_vortex(this);       }
spawnfunc(ammo_slugs)          { spawnfunc_item_cells(this);          }

// BFG -> Crylink
spawnfunc(weapon_bfg)          { spawnfunc_weapon_crylink(this);      }
spawnfunc(ammo_bfg)            { spawnfunc_item_cells(this);          }

// RL -> RL
spawnfunc(ammo_rockets)        { spawnfunc_item_rockets(this);        }

// Armor
spawnfunc(item_armor_body)     { spawnfunc_item_armor_mega(this);     }
spawnfunc(item_armor_combat)   { spawnfunc_item_armor_big(this);      }
spawnfunc(item_armor_shard)    { spawnfunc_item_armor_small(this);    }
spawnfunc(item_enviro)         { spawnfunc_item_invincible(this);     }

// medkit -> armor (we have no holdables)
spawnfunc(holdable_medkit)	   { spawnfunc_item_armor_mega(this);     }

// doubler -> strength
spawnfunc(item_doubler)        { spawnfunc_item_strength(this); }

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

spawnfunc(target_init)
{
	this.spawnflags = 0; // remove all weapons except the ones listed below
	this.netname = "shotgun"; // keep these weapons through the remove trigger
	spawnfunc_target_items(this);
	InitializeEntity(this, target_init_verify, INITPRIO_FINDTARGET);
}

// weapon give ent from defrag
void target_give_init(entity this)
{
	IL_EACH(g_items, it.targetname == this.target,
	{
		if (it.classname == "weapon_rocketlauncher" || it.classname == "weapon_devastator") {
			this.ammo_rockets += it.count * WEP_CVAR(devastator, ammo);
			this.netname = "devastator";
		}
		else if (it.classname == "weapon_lightning") {
			this.ammo_cells += it.count * WEP_CVAR_PRI(electro, ammo); // WEAPONTODO
			if(this.netname == "")
				this.netname = "electro";
			else
				this.netname = strcat(this.netname, " electro");
		}
		else if (it.classname == "weapon_plasmagun") {
			this.ammo_rockets += it.count * WEP_CVAR_PRI(hagar, ammo); // WEAPONTODO
			if(this.netname == "")
				this.netname = "hagar";
			else
				this.netname = strcat(this.netname, " hagar");
		}
		else if (it.classname == "weapon_bfg") {
			this.ammo_cells += it.count * WEP_CVAR_PRI(crylink, ammo);
			if(this.netname == "")
				this.netname = "crylink";
			else
				this.netname = strcat(this.netname, " crylink");
		}
		else if (it.classname == "weapon_grenadelauncher" || it.classname == "weapon_mortar") {
			this.ammo_rockets += it.count * WEP_CVAR_PRI(mortar, ammo); // WEAPONTODO
			if(this.netname == "")
				this.netname = "mortar";
			else
				this.netname = strcat(this.netname, " mortar");
		}
		else if (it.classname == "item_armor_body")
			this.armorvalue = 100;
		else if (it.classname == "item_health_mega")
			this.health = 200;
		//remove(it); // removing ents in init functions causes havoc, workaround:
        setthink(it, SUB_Remove);
        it.nextthink = time;
	});
	this.spawnflags = 2;
	spawnfunc_target_items(this);
	InitializeEntity(this, target_init_verify, INITPRIO_FINDTARGET);
}

spawnfunc(target_give)
{
	InitializeEntity(this, target_give_init, INITPRIO_FINDTARGET);
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
		if(maxclients == 1)
			gametypename = "single";
		// we do not have the other types (oneflag, obelisk, harvester, teamtournament)
		if(strstrofs(this.gametype, gametypename, 0) < 0)
			return true;
	}

	return false;
}
