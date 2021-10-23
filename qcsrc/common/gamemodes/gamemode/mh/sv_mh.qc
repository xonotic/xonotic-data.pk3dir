#include "sv_mh.qh"

spawnfunc(mh_team)
{
	if(!g_mh || !this.cnt) { delete(this); return; }

	this.team = this.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void mh_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(mh_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.team = teamcolor;
	this.spawnfunc_checked = true;
	//spawnfunc_mh_team(this);
}

void mh_DelayedInit(entity this)
{
	// TODO: change this?

	// if no teams are found, spawn defaults
	if(find(NULL, classname, "mh_team") == NULL)
	{
		LOG_TRACE("No \"mh_team\" entities found on this map, creating them anyway.");

		int numteams = 2;

		int teams = BITS(bound(2, numteams, 2));
		if(teams & BIT(0))
			mh_SpawnTeam("Red", NUM_TEAM_1); //is this the place to change the displayed team name?
		if(teams & BIT(1))
			mh_SpawnTeam("Blue", NUM_TEAM_2); //is this the place to change the displayed team name?
	}
}

void mh_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_mh_team_spawns);
	GameRules_limit_score(autocvar_g_mh_point_limit);

	InitializeEntity(NULL, mh_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(mh, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "mh_team";
}

MUTATOR_HOOKFUNCTION(mh, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

// ===================
//  weaponarena hooks
// ===================

MUTATOR_HOOKFUNCTION(mh, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mh_weaponarena;
}

//ammo is needed if weapons are given with above weaponarena unless players are given infinite ammo
MUTATOR_HOOKFUNCTION(mh, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	start_health       = warmup_start_health       = cvar("g_ca_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_ca_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_ca_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_ca_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_ca_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_ca_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_ca_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_ca_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(mh, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mh, FilterItem)
{
	return true;
}

// =============
//  score hooks
// =============

//refactor this when setting up score for tagging
MUTATOR_HOOKFUNCTION(mh, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);

	if (IS_PLAYER(frag_target))
	if (!IS_DEAD(frag_target))
	if (frag_target == frag_attacker || SAME_TEAM(frag_target, frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0;

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
}

//refactor this when setting up score for tagging
MUTATOR_HOOKFUNCTION(mh, PlayerDamage_SplitHealthArmor)
{
	if (time < game_starttime || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		return;

	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(6, float);
	float frag_damage = M_ARGV(7, float);
	float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
	float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

	float excess = max(0, frag_damage - damage_take - damage_save);

	//non-friendly fire
	if (frag_target != frag_attacker && IS_PLAYER(frag_attacker) && DIFF_TEAM(frag_target, frag_attacker))
		GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * 1);

	//friendly fire
	if (SAME_TEAM(frag_target, frag_attacker))
		GameRules_scoring_add_team(frag_attacker, SCORE, (-1 * (frag_damage - excess)) * 1);

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
		frag_deathtype == DEATH_SLIME.m_id ||
		frag_deathtype == DEATH_SWAMP.m_id))
			GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * 1);
}

MUTATOR_HOOKFUNCTION(mh, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 0; // score will be given to the players differently
	return true;
}
