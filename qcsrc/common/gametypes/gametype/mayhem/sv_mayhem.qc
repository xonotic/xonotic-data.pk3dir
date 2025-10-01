#include "sv_mayhem.qh"
#include <common/scores.qh>

// import autocvars for MayhemCalculatePlayerScore's teamplay cvars
#include "common/gametypes/gametype/tmayhem/sv_tmayhem.qh"

float autocvar_g_mayhem_point_limit;
float autocvar_g_mayhem_point_leadlimit;

bool autocvar_g_mayhem_regenerate;
bool autocvar_g_mayhem_rot;
string autocvar_g_mayhem_weaponarena;
bool autocvar_g_mayhem_powerups;
bool autocvar_g_mayhem_selfdamage;
float autocvar_g_mayhem_scoring_upscaler;
float autocvar_g_mayhem_scoring_damage_weight;
float autocvar_g_mayhem_scoring_kill_weight;
bool autocvar_g_mayhem_scoring_disable_selfdamage2score;
bool autocvar_g_mayhem_pickup_items;
bool autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_mayhem_unlimited_ammo;

float autocvar_g_mayhem_start_health = 200;
float autocvar_g_mayhem_start_armor = 200;
float autocvar_g_mayhem_start_ammo_shells = 60;
float autocvar_g_mayhem_start_ammo_nails = 320;
float autocvar_g_mayhem_start_ammo_rockets = 160;
float autocvar_g_mayhem_start_ammo_cells = 180;
float autocvar_g_mayhem_start_ammo_fuel = 0;

.float total_damage_dealt;

/*
// unused for now
void mayhem_DelayedInit(entity this)
{
	return;
}
*/

void mayhem_Initialize()
{
	GameRules_limit_score(autocvar_g_mayhem_point_limit);
	GameRules_limit_lead(autocvar_g_mayhem_point_leadlimit);

	// unused for now
	//InitializeEntity(NULL, mayhem_DelayedInit, INITPRIO_GAMETYPE);
}

/*
MUTATOR_HOOKFUNCTION(mayhem, Scores_CountFragsRemaining)
{
	// do not announce remaining frags, upscaled score count doesn't match well with this
	// when scorelimit is set to 1000 it would announce 997, 998 and 999 score counts
	// usually a single shot which deals ~40-80 dmg gives 2 or 3 score
	// this usually would cause a "2 fra..." announcement to be played as the match ends
	// without leaving anyone time to even process the announcement
	return false;
}
*/

MUTATOR_HOOKFUNCTION(mayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if (!cvar("g_use_ammunition") || autocvar_g_mayhem_unlimited_ammo)
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = autocvar_g_mayhem_start_health;
	start_armorvalue   = warmup_start_armorvalue   = autocvar_g_mayhem_start_armor;
	start_ammo_shells  = warmup_start_ammo_shells  = autocvar_g_mayhem_start_ammo_shells;
	start_ammo_nails   = warmup_start_ammo_nails   = autocvar_g_mayhem_start_ammo_nails;
	start_ammo_rockets = warmup_start_ammo_rockets = autocvar_g_mayhem_start_ammo_rockets;
	start_ammo_cells   = warmup_start_ammo_cells   = autocvar_g_mayhem_start_ammo_cells;
	start_ammo_fuel    = warmup_start_ammo_fuel    = autocvar_g_mayhem_start_ammo_fuel;
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerRegen)
{
	if(!autocvar_g_mayhem_regenerate)
		M_ARGV(2, float) = 0;
	if(!autocvar_g_mayhem_rot)
		M_ARGV(3, float) = 0;
	return (!autocvar_g_mayhem_regenerate && !autocvar_g_mayhem_rot);
}

MUTATOR_HOOKFUNCTION(mayhem, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mayhem_weaponarena;
}

MUTATOR_HOOKFUNCTION(mayhem, FilterItem)
{
	entity item = M_ARGV(0, entity);

	// enable powerups if forced globally or global accepts gametypes to have powerups according to their own settings
	if (autocvar_g_powerups == 1 || (autocvar_g_powerups == -1 && autocvar_g_mayhem_powerups == 1)){
		if (item.itemdef.instanceOfPowerup){
			return false;
		}
	}
	// disabled powerups if forced off globally or in this gametype
	if (autocvar_g_powerups == 0 || autocvar_g_mayhem_powerups == 0){
		if (item.itemdef.instanceOfPowerup){
			return true;
		}
	}
	// remove all items if items are forced off globally
	if (autocvar_g_pickup_items == 0){
		return true;
	}
	// if items are switched on in this gametype allow the removal of weapons and ammo still
	if ((autocvar_g_mayhem_pickup_items == 1 && autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo == 1) && autocvar_g_pickup_items <= 0){
		if (item.itemdef.instanceOfAmmo || item.itemdef.instanceOfWeaponPickup){
			return true;
		}
	}
	// remove items if not globally set to follow mode's settings and locally set off
	if (autocvar_g_pickup_items == -1 && autocvar_g_mayhem_pickup_items == 0){
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(mayhem, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if (IS_PLAYER(frag_target)) // nullify self-damage if self-damage is disabled and always nullify splat
	if (!IS_DEAD(frag_target)) // but enable anyone to gib corpses, even their own corpses with delayed damage
	if ((autocvar_g_mayhem_selfdamage == 0 && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	M_ARGV(4, float) = frag_damage;
}

void MayhemCalculatePlayerScore(entity scorer)
{
	int scoringmethod = 1;
	float upscaler; // how much score does 1 frag give
	float frag_weight; // how many frags should a kill be worth
	float damage_weight; // how many frags is damage worth of player's spawn health+armor

	// if frag is 0.25 , damage is 0.75 and upscaler is 20
	// then killing a full hp opponent is 1 frag which is worth of 20 score
	// or damage worth of 2 starting health+armor is 1.5 frags or 30 score even if no kills were gotten

	bool disable_selfdamage2score;

	if (teamplay) {
		// use Team Mayhem values
		upscaler = autocvar_g_tmayhem_scoring_upscaler;
		frag_weight = autocvar_g_tmayhem_scoring_kill_weight;
		damage_weight = autocvar_g_tmayhem_scoring_damage_weight;
		disable_selfdamage2score = autocvar_g_tmayhem_scoring_disable_selfdamage2score;
	} else {
		// use FFA Mayhem values
		upscaler = autocvar_g_mayhem_scoring_upscaler;
		frag_weight = autocvar_g_mayhem_scoring_kill_weight;
		damage_weight = autocvar_g_mayhem_scoring_damage_weight;
		disable_selfdamage2score = autocvar_g_mayhem_scoring_disable_selfdamage2score;
	}

	// decide scoringmethod and avoid potential divide by 0 errors

	if (frag_weight && damage_weight) // both frag and damage weights have non-zero values
		scoringmethod = 1;
	else if (frag_weight) // frag weight has a value
		scoringmethod = 2;
	else if (damage_weight) // damage weight has a value
		scoringmethod = 3;
	else
		return; // neither frags nor damage are set to give score

	switch (scoringmethod)
	{
		default:
		case 1:
		{
			// calculate how much score the player should have based on their damage dealt and frags gotten and then add the missing score

			// give a different weight for suicides if scoring method 1 doesn't have selfdamage2score enabled to harshly punish for suicides to avoid exploiting
			float suicide_weight = 1 + (disable_selfdamage2score / frag_weight);

			// total damage divided by player start health&armor to get how many lives worth of damage they've dealt,
			// then calculate new value affected by weight
			float playerdamagescore = ((scorer.total_damage_dealt / (start_health + start_armorvalue)) * 100) * upscaler * damage_weight;
			                                                                                       //  * 100 to avoid float inaccuracy at that decimal level

			// playerdamagescore rounded to one decimal
			float roundedplayerdamagescore = rint(playerdamagescore * 10) / 10;

			// amount of kills
			float killcount = PlayerScore_Get(scorer, SP_KILLS) - PlayerScore_Get(scorer, SP_TEAMKILLS) - (PlayerScore_Get(scorer, SP_SUICIDES) * suicide_weight);

			// kills minus suicides, calculate weight
			float playerkillscore = (killcount * 100) * upscaler * frag_weight;
			                               //  * 100 to avoid float inaccuracy at that decimal level

			float playerscore = roundedplayerdamagescore + playerkillscore;

			// calculated how much score the player has and now calculate total of how much they are supposed to have
			float scoretoadd = playerscore - (PlayerScore_Get(scorer, SP_SCORE) * 100);
			                                                                //  * 100 to avoid float inaccuracy at that decimal level

			// adjust total score to be what the player is supposed to have
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd / 100));
			                                                       //  / 100 to move back to the original decimal level

			#if 0
				// debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", scorer.total_damage_dealt),         " scorer.total_damage_dealt \n");
					print(sprintf("%f", scorer.hitsound_damage_dealt),      " scorer.hitsound_damage_dealt \n");
					print(sprintf("%f", playerdamagescore/100),             " playerdamagescore \n");
					print(sprintf("%f", roundedplayerdamagescore/100),      " rounded playerdamagescore \n");
					print(sprintf("%f", playerkillscore/100),               " playerkillscore \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_KILLS)), " PlayerScore_Get(scorer, SP_KILLS) \n");
					print(sprintf("%f", playerscore/100),                   " playerscore \n");
					print(sprintf("%f", scoretoadd/100),                    " scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			#endif
			return;
		}

		case 2:
		{
			// calculate how much score the player should have based on their frags gotten and then add the missing score
			float playerkillscore = PlayerScore_Get(scorer, SP_KILLS) - PlayerScore_Get(scorer, SP_TEAMKILLS) - PlayerScore_Get(scorer, SP_SUICIDES);
			float upscaledplayerscore = playerkillscore * upscaler;
			float scoretoadd = upscaledplayerscore - PlayerScore_Get(scorer, SP_SCORE);
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd));

			#if 0
				// debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", playerkillscore),                   " playerkillscore \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_KILLS)), " PlayerScore_Get(scorer, SP_KILLS) \n");
					print(sprintf("%f", upscaledplayerscore),               " upscaled playerscore \n");
					print(sprintf("%f", scoretoadd),                        " scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			#endif
			return;
		}

		case 3:
		{
			// calculate how much score the player should have based on their damage dealt and then add the missing score
			float playerdamagescore = ((scorer.total_damage_dealt / (start_health + start_armorvalue)) * 100);
			float roundedplayerdamagescore = rint(playerdamagescore * 10) / 10;
			float upscaledplayerscore = roundedplayerdamagescore * upscaler;
			float scoretoadd = upscaledplayerscore - (PlayerScore_Get(scorer, SP_SCORE) * 100);
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd / 100));

			#if 0
				// debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", scorer.total_damage_dealt),         " scorer.total_damage_dealt \n");
					print(sprintf("%f", playerdamagescore),                 " playerdamagescore \n");
					print(sprintf("%f", roundedplayerdamagescore),          " rounded playerdamagescore \n");
					print(sprintf("%f", upscaledplayerscore),               " upscaled playerscore \n");
					print(sprintf("%f", scoretoadd),                        " scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			#endif
			return;
		}
	}
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerDamage_SplitHealthArmor)
{
	if (!autocvar_g_mayhem_scoring_damage_weight) return;

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
		if (frag_target != frag_attacker)
			frag_attacker.total_damage_dealt += total;

		// friendly fire aka self damage
		if (frag_target == frag_attacker && !autocvar_g_mayhem_scoring_disable_selfdamage2score)
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
		if (!autocvar_g_mayhem_scoring_disable_selfdamage2score && (
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

	#if 0
		// debug printing
		if(!IS_BOT_CLIENT(scorer)){
			print(sprintf("%f", total), " total dmg from PlayerDamage_SplitHealthArmor \n");
			print(sprintf("%f", scorer.total_damage_dealt), "scorer.total_damage_dealt\n");
		}
	#endif

	MayhemCalculatePlayerScore(scorer);
}

MUTATOR_HOOKFUNCTION(mayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	M_ARGV(2, float) = 0; //score to give for the frag directly

	if (IS_PLAYER(frag_attacker)) MayhemCalculatePlayerScore(frag_attacker);

	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, reset_map_players)
{
	// reset damage dealt on reset
	FOREACH_CLIENT(true, {
		it.total_damage_dealt = 0;
	});
	return false;
}

