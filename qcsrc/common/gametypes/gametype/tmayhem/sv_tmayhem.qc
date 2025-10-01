#include "sv_tmayhem.qh"
#include <common/gametypes/gametype/mayhem/sv_mayhem.qh>

float autocvar_g_tmayhem_point_limit;
float autocvar_g_tmayhem_point_leadlimit;

int autocvar_g_tmayhem_teams;
int autocvar_g_tmayhem_teams_override;
bool autocvar_g_tmayhem_team_spawns;

bool autocvar_g_tmayhem_regenerate;
bool autocvar_g_tmayhem_rot;
string autocvar_g_tmayhem_weaponarena;
bool autocvar_g_tmayhem_powerups;
bool autocvar_g_tmayhem_selfdamage;
bool autocvar_g_tmayhem_pickup_items;
bool autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_tmayhem_unlimited_ammo;

float autocvar_g_tmayhem_start_health = 200;
float autocvar_g_tmayhem_start_armor = 200;
float autocvar_g_tmayhem_start_ammo_shells = 60;
float autocvar_g_tmayhem_start_ammo_nails = 320;
float autocvar_g_tmayhem_start_ammo_rockets = 160;
float autocvar_g_tmayhem_start_ammo_cells = 180;
float autocvar_g_tmayhem_start_ammo_fuel = 0;

.float total_damage_dealt;

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
	if (find(NULL, classname, "tmayhem_team") == NULL)
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
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_tmayhem_team_spawns);

	GameRules_limit_score(autocvar_g_tmayhem_point_limit);
	GameRules_limit_lead(autocvar_g_tmayhem_point_leadlimit);

	InitializeEntity(NULL, tmayhem_DelayedInit, INITPRIO_GAMETYPE);
}
// code up to here is just to support maps that don't have team entities

MUTATOR_HOOKFUNCTION(tmayhem, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "tmayhem_team";
}

/*
MUTATOR_HOOKFUNCTION(tmayhem, Scores_CountFragsRemaining)
{
	// do not announce remaining frags, upscaled score count doesn't match well with this
	// when scorelimit is set to 1000 it would announce 997, 998 and 999 score counts
	// usually a single shot which deals ~40-80 dmg gives 2 or 3 score
	// this usually would cause a "2 fra..." announcement to be played as the match ends
	// without leaving anyone time to even process the announcement
	return false;
}
*/

MUTATOR_HOOKFUNCTION(tmayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if (!cvar("g_use_ammunition") || autocvar_g_tmayhem_unlimited_ammo)
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = autocvar_g_tmayhem_start_health;
	start_armorvalue   = warmup_start_armorvalue   = autocvar_g_tmayhem_start_armor;
	start_ammo_shells  = warmup_start_ammo_shells  = autocvar_g_tmayhem_start_ammo_shells;
	start_ammo_nails   = warmup_start_ammo_nails   = autocvar_g_tmayhem_start_ammo_nails;
	start_ammo_rockets = warmup_start_ammo_rockets = autocvar_g_tmayhem_start_ammo_rockets;
	start_ammo_cells   = warmup_start_ammo_cells   = autocvar_g_tmayhem_start_ammo_cells;
	start_ammo_fuel    = warmup_start_ammo_fuel    = autocvar_g_tmayhem_start_ammo_fuel;
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerRegen)
{
	if(!autocvar_g_tmayhem_regenerate)
		M_ARGV(2, float) = 0;
	if(!autocvar_g_tmayhem_rot)
		M_ARGV(3, float) = 0;
	return (!autocvar_g_tmayhem_regenerate && !autocvar_g_tmayhem_rot);
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

	// enable powerups if forced globally or global accepts gametypes to have powerups according to their own settings
	if (autocvar_g_powerups == 1 || (autocvar_g_powerups == -1 && autocvar_g_tmayhem_powerups == 1)){
		if (item.itemdef.instanceOfPowerup){
			return false;
		}
	}
	// disabled powerups if forced off globally or in this gametype
	if (autocvar_g_powerups == 0 || autocvar_g_tmayhem_powerups == 0){
		if (item.itemdef.instanceOfPowerup){
			return true;
		}
	}
	// remove all items if items are forced off globally
	if (autocvar_g_pickup_items == 0){
		return true;
	}
	// if items are switched on in this gametype allow the removal of weapons and ammo still
	if ((autocvar_g_tmayhem_pickup_items == 1 && autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo == 1) && autocvar_g_pickup_items <= 0){
		if (item.itemdef.instanceOfAmmo || item.itemdef.instanceOfWeaponPickup){
			return true;
		}
	}
	// remove items if not globally set to follow mode's settings and locally set off
	if (autocvar_g_pickup_items == -1 && autocvar_g_tmayhem_pickup_items == 0){
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(tmayhem, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);

	if (IS_PLAYER(frag_target)) // nullify self-damage if self-damage is disabled and always nullify splat
	if (!IS_DEAD(frag_target)) // but enable anyone to gib corpses, even their own corpses with delayed damage
	if ((autocvar_g_tmayhem_selfdamage == 0 && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0; // no mirror damaging

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerDamage_SplitHealthArmor)
{
	if (!autocvar_g_tmayhem_scoring_damage_weight) return;

	entity frag_target = M_ARGV(2, entity);

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage >= 1) return;

	entity frag_attacker = M_ARGV(1, entity);
	float frag_deathtype = M_ARGV(6, float);
	float frag_damage = M_ARGV(7, float);
	float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
	float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));
	float excess = max(0, frag_damage - damage_take - damage_save);
	float total = frag_damage - excess;

	if (total == 0) return;

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage)
		total *= 1 - autocvar_g_spawnshield_blockdamage;

	entity scorer = NULL; // entity which needs their score to be updated

	if (IS_PLAYER(frag_attacker))
	{
		// non-friendly fire
		if (!SAME_TEAM(frag_target, frag_attacker))
			frag_attacker.total_damage_dealt += total;

		// friendly fire aka self damage
		if (SAME_TEAM(frag_target, frag_attacker) || (frag_target == frag_attacker && !autocvar_g_tmayhem_scoring_disable_selfdamage2score))
			frag_attacker.total_damage_dealt -= total;

		scorer = frag_attacker;
	}
	else
	{
		// handle (environmental hazard) suiciding, check first if the player
		// has a registered attacker who most likely pushed them there to
		// avoid punishing pushed players as pushers are already rewarded
		// deathtypes:
		// kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
		// camp = campcheck, lava = lava, slime = slime
		// team change / rebalance suicides are currently not included
		if (!autocvar_g_tmayhem_scoring_disable_selfdamage2score && (
				frag_deathtype == DEATH_KILL.m_id ||
				frag_deathtype == DEATH_DROWN.m_id ||
				frag_deathtype == DEATH_HURTTRIGGER.m_id ||
				frag_deathtype == DEATH_CAMP.m_id ||
				frag_deathtype == DEATH_LAVA.m_id ||
				frag_deathtype == DEATH_SLIME.m_id ||
				frag_deathtype == DEATH_SWAMP.m_id))
			frag_target.total_damage_dealt -= total;

		scorer = frag_target;
	}

	MayhemCalculatePlayerScore(scorer);
}

MUTATOR_HOOKFUNCTION(tmayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	M_ARGV(2, float) = 0; // score to give for the frag directly

	if (IS_PLAYER(frag_attacker)) MayhemCalculatePlayerScore(frag_attacker);

	return true;
}

MUTATOR_HOOKFUNCTION(tmayhem, reset_map_players)
{
	// reset damage dealt on reset
	FOREACH_CLIENT(true, {
		it.total_damage_dealt = 0;
	});
	return false;
}

