#include "sv_tmayhem.qh"

// TODO? rename to teammayhem? requires checking alias and other string lengths
int autocvar_g_tmayhem_teams;
int autocvar_g_tmayhem_teams_override;

bool autocvar_g_tmayhem_regenerate;
string autocvar_g_tmayhem_weaponarena;
bool autocvar_g_tmayhem_powerups;
bool autocvar_g_tmayhem_selfdamage;
int autocvar_g_tmayhem_scoringmethod;



// code from here on is just to support maps that don't have team entities
void tmayhem_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(tmayhem_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.team = teamcolor;
	this.spawnfunc_checked = true;
	//spawnfunc_tmayhem_team(this);
}

void tmayhem_DelayedInit(entity this)
{
	// if no teams are found, spawn defaults
	if(find(NULL, classname, "tmayhem_team") == NULL)
	{
		LOG_TRACE("No \"tmayhem_team\" entities found on this map, creating them anyway.");

		int numteams = autocvar_g_tmayhem_teams_override;
		if(numteams < 2) { numteams = autocvar_g_tmayhem_teams; }

		int teams = BITS(bound(2, numteams, 4));
		if(teams & BIT(0))
			tmayhem_SpawnTeam("Red", NUM_TEAM_1);
		if(teams & BIT(1))
			tmayhem_SpawnTeam("Blue", NUM_TEAM_2);
		if(teams & BIT(2))
			tmayhem_SpawnTeam("Yellow", NUM_TEAM_3);
		if(teams & BIT(3))
			tmayhem_SpawnTeam("Pink", NUM_TEAM_4);
	}
}

void tmayhem_Initialize()
{
	if(autocvar_g_tmayhem_visual_score_limit != 0 && autocvar_g_tmayhem_fraglimit != 0)
		tmayhempointmultiplier = autocvar_g_tmayhem_visual_score_limit / autocvar_g_tmayhem_fraglimit;

	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_tmayhem_team_spawns);
	GameRules_limit_score(autocvar_g_tmayhem_visual_score_limit);
	GameRules_limit_lead(autocvar_g_tmayhem_score_leadlimit);

	InitializeEntity(NULL, tmayhem_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(tmayhem, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "tmayhem_team";
}

MUTATOR_HOOKFUNCTION(tmayhem, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(tmayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	start_health       = warmup_start_health       = cvar("g_tmayhem_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_tmayhem_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_tmayhem_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_tmayhem_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_tmayhem_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_tmayhem_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_tmayhem_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_tmayhem_start_ammo_fuel");
}

//this hook also enables rotting, as players spawn with more hp and armor than what default rot limits are set to this is a bad idea as of now
MUTATOR_HOOKFUNCTION(tmayhem, PlayerRegen)
{
	if(autocvar_g_tmayhem_regenerate)
		return false;
	return true;
}

MUTATOR_HOOKFUNCTION(tmayhem, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(tmayhem, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_tmayhem_weaponarena;
}

MUTATOR_HOOKFUNCTION(tmayhem, FilterItem)
{
	entity item = M_ARGV(0, entity);
	if (autocvar_g_powerups == 1){
		if (item.itemdef.instanceOfPowerup){
			return false;
		} 
	}
	else if (autocvar_g_powerups == -1){
		if (item.itemdef.instanceOfPowerup){
			if (autocvar_g_tmayhem_powerups){
				return false;
			} 
		} 
	}
	if (autocvar_g_pickup_items <= 0)
		return true;
}

MUTATOR_HOOKFUNCTION(tmayhem, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);

	if (IS_PLAYER(frag_target))
	if (!IS_DEAD(frag_target))
	if ((autocvar_g_tmayhem_selfdamage == 0 && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0;

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerDamage_SplitHealthArmor)
{
	switch(autocvar_g_tmayhem_scoringmethod)
	{
		//frags only
		case 2:
		{
			return;
		}
		
		//damage only
		case 3:
		{
			entity frag_attacker = M_ARGV(1, entity);
			entity frag_target = M_ARGV(2, entity);
			float frag_deathtype = M_ARGV(6, float);
			float frag_damage = M_ARGV(7, float);
			float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
			float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

			float excess = max(0, frag_damage - damage_take - damage_save);

			//non-friendly fire
			if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));

			//friendly fire or self damage
			if (frag_target == frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));

			//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
			//deathtypes:
			//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
			//camp = campcheck, lava = lava, slime = slime
			//team change / rebalance suicides are currently not included
			if (!IS_PLAYER(frag_attacker) && (
				frag_deathtype == DEATH_KILL.m_id ||
				frag_deathtype == DEATH_DROWN.m_id ||
				frag_deathtype == DEATH_HURTTRIGGER.m_id ||
				frag_deathtype == DEATH_CAMP.m_id ||
				frag_deathtype == DEATH_LAVA.m_id ||
				frag_deathtype == DEATH_SLIME.m_id))
					GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * 0.75 * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));
			return;
		}
		
		//combined damage and frags
		default:
		case 1:
		{
			entity frag_attacker = M_ARGV(1, entity);
			entity frag_target = M_ARGV(2, entity);
			float frag_deathtype = M_ARGV(6, float);
			float frag_damage = M_ARGV(7, float);
			float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
			float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

			float excess = max(0, frag_damage - damage_take - damage_save);

			//non-friendly fire
			if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * 0.75 * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));
			
			//friendly fire or self damage
			if (frag_target == frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * 0.75 * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));
		
			//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
			//deathtypes:
			//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
			//camp = campcheck, lava = lava, slime = slime
			//team change / rebalance suicides are currently not included
			if (!IS_PLAYER(frag_attacker) && (
				frag_deathtype == DEATH_KILL.m_id ||
				frag_deathtype == DEATH_DROWN.m_id ||
				frag_deathtype == DEATH_HURTTRIGGER.m_id ||
				frag_deathtype == DEATH_CAMP.m_id ||
				frag_deathtype == DEATH_LAVA.m_id ||
				frag_deathtype == DEATH_SLIME.m_id))
					GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * 0.75 * tmayhempointmultiplier * (1/(start_health + start_armorvalue)));
			return;
		}
	}
}

MUTATOR_HOOKFUNCTION(tmayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	switch(autocvar_g_tmayhem_scoringmethod)
	{
		//frags only
		case 2:
		{
														//fix 999 score from 30 kills for example
			M_ARGV(2, float) = 1 * tmayhempointmultiplier * 1.0001;
			return true;
		}
		
		//damage only
		case 3:
		{
			M_ARGV(2, float) = 0;
			return true;
		}
		
		//combined damage and frags
		default:
		case 1:
		{
			M_ARGV(2, float) = 0.25 * tmayhempointmultiplier * 1.0001;
			return true;
		}
	}
}
