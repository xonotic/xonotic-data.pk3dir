#include "sv_util.qh"

#include <common/mutators/base.qh>
#include <common/mutators/mutator/powerups/sv_powerups.qh>
#include <common/mutators/mutator/status_effects/status_effects.qh>
#include <server/items/items.qh>
#include <server/scores.qh>

//#define MAYHEM_DEBUG


.float total_damage_dealt;

void MayhemCalculatePlayerScore(entity scorer, float upscaler, float frag_weight, float damage_weight, bool disable_selfdamage2score)
{
	// if frag is 0.25, damage is 0.75 and upscaler is 20
	// then killing a full hp opponent is 1 frag which is worth of 20 score
	// or damage worth of 2 starting health+armor is 1.5 frags or 30 score even if no kills were gotten

	// decide scoringmethod and avoid potential divide by 0 errors
	int scoringmethod;
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

		#ifdef MAYHEM_DEBUG
			if (!IS_BOT_CLIENT(scorer))
			{
				printf("%f scorer.total_damage_dealt\n",            scorer.total_damage_dealt);
				printf("%f scorer.hitsound_damage_dealt\n",         scorer.hitsound_damage_dealt);
				printf("%f playerdamagescore\n",                    playerdamagescore / 100);
				printf("%f rounded playerdamagescore\n",            roundedplayerdamagescore / 100);
				printf("%f playerkillscore\n",                      playerkillscore / 100);
				printf("%f PlayerScore_Get(scorer, SP_KILLS)\n",    PlayerScore_Get(scorer, SP_KILLS));
				printf("%f playerscore\n",                          playerscore / 100);
				printf("%f scoretoadd\n",                           scoretoadd / 100);
				printf("%f PlayerScore_Get(scorer, SP_SCORE)\n\n",  PlayerScore_Get(scorer, SP_SCORE));
			}
		#endif
			break;
		}

		case 2:
		{
			// calculate how much score the player should have based on their frags gotten and then add the missing score
			float playerkillscore = PlayerScore_Get(scorer, SP_KILLS) - PlayerScore_Get(scorer, SP_TEAMKILLS) - PlayerScore_Get(scorer, SP_SUICIDES);
			float upscaledplayerscore = playerkillscore * upscaler;
			float scoretoadd = upscaledplayerscore - PlayerScore_Get(scorer, SP_SCORE);
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd));

		#ifdef MAYHEM_DEBUG
			if (!IS_BOT_CLIENT(scorer))
			{
				printf("%f playerkillscore\n",                      playerkillscore);
				printf("%f PlayerScore_Get(scorer, SP_KILLS)\n",    PlayerScore_Get(scorer, SP_KILLS));
				printf("%f upscaled playerscore\n",                 upscaledplayerscore);
				printf("%f scoretoadd\n",                           scoretoadd);
				printf("%f PlayerScore_Get(scorer, SP_SCORE)\n\n",  PlayerScore_Get(scorer, SP_SCORE));
			}
		#endif
			break;
		}

		case 3:
		{
			// calculate how much score the player should have based on their damage dealt and then add the missing score
			float playerdamagescore = (scorer.total_damage_dealt / (start_health + start_armorvalue)) * 100;
			float roundedplayerdamagescore = rint(playerdamagescore * 10) / 10;
			float upscaledplayerscore = roundedplayerdamagescore * upscaler;
			float scoretoadd = upscaledplayerscore - (PlayerScore_Get(scorer, SP_SCORE) * 100);
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd / 100));

		#ifdef MAYHEM_DEBUG
			if (!IS_BOT_CLIENT(scorer))
			{
				printf("%f scorer.total_damage_dealt\n",            scorer.total_damage_dealt);
				printf("%f playerdamagescore\n",                    playerdamagescore);
				printf("%f rounded playerdamagescore\n",            roundedplayerdamagescore);
				printf("%f upscaled playerscore\n",                 upscaledplayerscore);
				printf("%f scoretoadd\n",                           scoretoadd);
				printf("%f PlayerScore_Get(scorer, SP_SCORE)\n\n",  PlayerScore_Get(scorer, SP_SCORE));
			}
		#endif
			break;
		}
	}
}


// Mutator hook functions

void mayhem_util_SetStartItems(bool unlimited_ammo, float health, float armor, float shells, float nails, float rockets, float cells, float fuel)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if (!cvar("g_use_ammunition") || unlimited_ammo)
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = health;
	start_armorvalue   = warmup_start_armorvalue   = armor;
	start_ammo_shells  = warmup_start_ammo_shells  = shells;
	start_ammo_nails   = warmup_start_ammo_nails   = nails;
	start_ammo_rockets = warmup_start_ammo_rockets = rockets;
	start_ammo_cells   = warmup_start_ammo_cells   = cells;
	start_ammo_fuel    = warmup_start_ammo_fuel    = fuel;
}

bool mayhem_util_PlayerRegen(bool regen, bool rot)
{
	if (!regen)
		M_ARGV(2, float) = 0;
	if (!rot)
		M_ARGV(3, float) = 0;
	return (!regen && !rot);
}

bool mayhem_util_ForbidThrowCurrentWeapon()
{
	return true;
}

void mayhem_util_SetWeaponArena(string weaponarena)
{
	if (M_ARGV(0, string) == "0"
	||  M_ARGV(0, string) == "")
		M_ARGV(0, string) = weaponarena;
}

bool mayhem_util_FilterItem(bool powerups, bool pickup_items, bool pickup_items_remove_weapons_and_ammo)
{
	entity item = M_ARGV(0, entity);

	// enable powerups if forced globally or global accepts gametypes to have powerups according to their own settings
	if (item.itemdef.instanceOfPowerup)
	if (autocvar_g_powerups == 1 || (autocvar_g_powerups == -1 && powerups))
		return false;

	// disabled powerups if forced off globally or in this gametype
	if (item.itemdef.instanceOfPowerup)
	if (autocvar_g_powerups == 0 || !powerups)
		return true;

	// remove all items if items are forced off globally
	if (autocvar_g_pickup_items == 0)
		return true;

	// if items are switched on in this gametype allow the removal of weapons and ammo still
	if (item.itemdef.instanceOfAmmo || item.itemdef.instanceOfWeaponPickup)
	if ((pickup_items && pickup_items_remove_weapons_and_ammo) && autocvar_g_pickup_items <= 0)
		return true;

	// remove items if not globally set to follow mode's settings and locally set off
	if (autocvar_g_pickup_items == -1 && pickup_items)
		return true;

	return false;
}

void mayhem_util_Damage_Calculate(bool selfdamage)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if (IS_PLAYER(frag_target) // nullify self-damage if self-damage is disabled and always nullify splat
	&& !IS_DEAD(frag_target) // but enable anyone to gib corpses, even their own corpses with delayed damage
	&& ((!selfdamage && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id))
		frag_damage = 0;

	M_ARGV(4, float) = frag_damage;
}

void mayhem_util_PlayerDamage_SplitHealthArmor(float upscaler, float frag_weight, float damage_weight, bool disable_selfdamage2score)
{
	if (!damage_weight)
		return;

	entity frag_target = M_ARGV(2, entity);

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage >= 1)
		return;

	entity frag_attacker = M_ARGV(1, entity);
	float frag_deathtype = M_ARGV(6, float);
	float damage_take = M_ARGV(4, float);
	float damage_save = M_ARGV(5, float);

	float realdmg = damage_take + damage_save;
	if (realdmg == 0)
		return;

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage)
		realdmg *= 1 - autocvar_g_spawnshield_blockdamage;

	entity scorer = NULL; // entity which needs their score to be updated

	if (IS_PLAYER(frag_attacker))
	{
		// non-friendly fire
		if (!SAME_TEAM(frag_target, frag_attacker))
			frag_attacker.total_damage_dealt += realdmg;

		// friendly fire aka self damage
		if (SAME_TEAM(frag_target, frag_attacker) || (frag_target == frag_attacker && !disable_selfdamage2score))
			frag_attacker.total_damage_dealt -= realdmg;

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
		if (!disable_selfdamage2score)
		if (frag_deathtype == DEATH_KILL.m_id
		||  frag_deathtype == DEATH_DROWN.m_id
		||  frag_deathtype == DEATH_HURTTRIGGER.m_id
		||  frag_deathtype == DEATH_CAMP.m_id
		||  frag_deathtype == DEATH_LAVA.m_id
		||  frag_deathtype == DEATH_SLIME.m_id
		||  frag_deathtype == DEATH_SWAMP.m_id)
			frag_target.total_damage_dealt -= realdmg;

		scorer = frag_target;
	}

#ifdef MAYHEM_DEBUG
	if (!IS_BOT_CLIENT(scorer))
	{
		printf("%f total real dmg from PlayerDamage_SplitHealthArmor\n",  realdmg);
		printf("%f scorer.total_damage_dealt\n",                          scorer.total_damage_dealt);
	}
#endif

	MayhemCalculatePlayerScore(scorer, upscaler, frag_weight, damage_weight, disable_selfdamage2score);
}

bool mayhem_util_GiveFragsForKill(float upscaler, float frag_weight, float damage_weight, bool disable_selfdamage2score)
{
	entity frag_attacker = M_ARGV(0, entity);
	M_ARGV(2, float) = 0; // score to give for the frag directly

	if (IS_PLAYER(frag_attacker))
		MayhemCalculatePlayerScore(frag_attacker, upscaler, frag_weight, damage_weight, disable_selfdamage2score);

	return true;
}

bool mayhem_util_reset_map_players()
{
	// reset damage dealt on reset
	FOREACH_CLIENT(true, it.total_damage_dealt = 0);
	return false;
}
