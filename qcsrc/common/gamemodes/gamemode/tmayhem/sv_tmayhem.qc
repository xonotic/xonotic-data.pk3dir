#include "sv_tmayhem.qh"

float autocvar_g_tmayhem_fraglimit;
float autocvar_g_tmayhem_visual_score_limit;
float autocvar_g_tmayhem_score_leadlimit;
bool autocvar_g_tmayhem_team_spawns;

// TODO? rename to teammayhem? requires checking alias and other string lengths
int autocvar_g_tmayhem_teams;
int autocvar_g_tmayhem_teams_override;

bool autocvar_g_tmayhem_regenerate;
bool autocvar_g_tmayhem_rot;
string autocvar_g_tmayhem_weaponarena;
bool autocvar_g_tmayhem_powerups;
bool autocvar_g_tmayhem_selfdamage;
int autocvar_g_tmayhem_scoringmethod;
float autocvar_g_tmayhem_scoringmethod_1_damage_weight;
float autocvar_g_tmayhem_scoringmethod_1_frag_weight;
bool autocvar_g_tmayhem_scoringmethod_1_disable_selfdamage2score;
bool autocvar_g_tmayhem_pickup_items;
bool autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_tmayhem_unlimited_ammo;

float autocvar_g_tmayhem_start_health = 200;
float autocvar_g_tmayhem_start_armor = 200;
float autocvar_g_tmayhem_start_ammo_shells = 60;
float autocvar_g_tmayhem_start_ammo_nails = 320;
float autocvar_g_tmayhem_start_ammo_rockets = 160;
float autocvar_g_tmayhem_start_ammo_cells = 180;
float autocvar_g_tmayhem_start_ammo_plasma = 180;
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
	GameRules_limit_lead(autocvar_g_tmayhem_score_leadlimit);

	if (autocvar_fraglimit_override != 0)
		GameRules_limit_score(autocvar_g_tmayhem_visual_score_limit);
	else
		GameRules_limit_score(9999);

	InitializeEntity(NULL, tmayhem_DelayedInit, INITPRIO_GAMETYPE);
}
// code up to here is just to support maps that don't have team entities

MUTATOR_HOOKFUNCTION(tmayhem, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "tmayhem_team";
}

MUTATOR_HOOKFUNCTION(tmayhem, Scores_CountFragsRemaining)
{
	// do not announce remaining frags, upscaled score count doesn't match well with this
	// when scorelimit is set to 1000 it would announce 997, 998 and 999 score counts
	// usually a single shot which deals ~40-80 dmg gives 2 or 3 score
	// this usually would cause a "2 fra..." announcement to be played as the match ends 
	// without leaving anyone time to even process the announcement
	return false;
}

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
	start_ammo_plasma  = warmup_start_ammo_plasma  = autocvar_g_tmayhem_start_ammo_plasma;
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
	
	//enable powerups if forced globally or global accepts gamemodes to have powerups according to their own settings
	if (autocvar_g_powerups == 1 || (autocvar_g_powerups == -1 && autocvar_g_tmayhem_powerups == 1)){
		if (item.itemdef.instanceOfPowerup){
			return false;
		} 
	}
	//disabled powerups if forced off globally or in this gamemode
	if (autocvar_g_powerups == 0 || autocvar_g_tmayhem_powerups == 0){
		if (item.itemdef.instanceOfPowerup){
			return true; 
		} 
	}
	//remove all items if items are forced off globally
	if (autocvar_g_pickup_items == 0){
		return true;
	}
	//if items are switched on in this gamemode allow the removal of weapons and ammo still
	if ((autocvar_g_tmayhem_pickup_items == 1 && autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo == 1) && autocvar_g_pickup_items <= 0){
		if (item.itemdef.instanceOfAmmo || item.itemdef.instanceOfWeaponPickup){
			return true;
		}
	}
	//remove items if not globally set to follow mode's settings and locally set off
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

	if (IS_PLAYER(frag_target)) //don't ever zero damage to non-players
	if (!IS_DEAD(frag_target)) //enable anyone to gib corpses
	if ((autocvar_g_tmayhem_selfdamage == 0 && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id) //nullify self-damage if self-damage is disabled and always nullify splat
		frag_damage = 0;

	frag_mirrordamage = 0; //no mirror damaging

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
}

void TeamMayhemCalculatePlayerScore(entity scorer)
{
	if (autocvar_fraglimit_override > 0) autocvar_g_tmayhem_fraglimit = autocvar_fraglimit_override;
	
	switch (autocvar_g_tmayhem_scoringmethod)
	{
		default:
		case 1:
		{
			//calculate how much score the player should have based on their damage dealt and frags gotten and then add the missing score

			//give a different weight for suicides if scoring method 1 doesn't have selfdamage2score enabled to harshly punish for suicides to avoid exploiting
			float suicide_weight = 1 + (autocvar_g_tmayhem_scoringmethod_1_disable_selfdamage2score * (1/autocvar_g_tmayhem_scoringmethod_1_frag_weight));

			//total damage divided by player start health&armor to get how many lives worth of damage they've dealt, then how much that is out of the fraglimit, then calculate new value affected by weight
			float playerdamagescore = (((((scorer.total_damage_dealt/(start_health + start_armorvalue)) * 100)/autocvar_g_tmayhem_fraglimit) * autocvar_g_tmayhem_scoringmethod_1_damage_weight) );
																									//  * 100 to avoid float inaccuracy at that decimal level

			//playerdamagescore rounded
			float roundedplayerdamagescore = ((rint(playerdamagescore*10))/10);

			//kills minus suicides, total out of fraglimit, calculate weight
			float playerkillscore = ((((PlayerScore_Get(scorer, SP_KILLS) - (PlayerScore_Get(scorer, SP_SUICIDES) * suicide_weight)) * 100) / autocvar_g_tmayhem_fraglimit) * autocvar_g_tmayhem_scoringmethod_1_frag_weight);
																																//   * 100 to avoid float inaccuracy at that decimal level

			//only used for debug print, add killscore and damagescore together
			float playerscore = (roundedplayerdamagescore + playerkillscore);

			//add killscore and damagescore together to get total score and then adjust it to be total out of the visual score limit
			float playerscorevisual = ((roundedplayerdamagescore + playerkillscore) * autocvar_g_tmayhem_visual_score_limit);
																														

			//calculated how much score the player has and now calculate total of how much they are supposed to have
			float scoretoadd = (playerscorevisual - (PlayerScore_Get(scorer, SP_SCORE) * 100));
																				   //  * 100 to avoid float inaccuracy at that decimal level

			//adjust total score to be what the player is supposed to have
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd / 100));
																	// / 100 to move back to the decimal level

			if(0){
				//debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", scorer.total_damage_dealt), 		" scorer.total_damage_dealt \n");
					print(sprintf("%f", playerdamagescore), 				" playerdamagescore \n");
					print(sprintf("%f", roundedplayerdamagescore), 			" rounded playerdamagescore \n");
					print(sprintf("%f", playerkillscore), 					" playerkillscore \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_KILLS)), " PlayerScore_Get(scorer, SP_KILLS) \n");
					print(sprintf("%f", playerscore), 						" playerscore \n");
					print(sprintf("%f", playerscorevisual), 				" visual playerscore \n");
					print(sprintf("%f", scoretoadd), 						" scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			}
		return;
		}

		case 2:
		{
			//calculate how much score the player should have based on their frags gotten and then add the missing score
			float playerkillscore = (((PlayerScore_Get(scorer, SP_KILLS) - PlayerScore_Get(scorer, SP_SUICIDES)) * 100)/ autocvar_g_tmayhem_fraglimit);
			float playerscorevisual = (playerkillscore * autocvar_g_tmayhem_visual_score_limit) / 100;
			float scoretoadd = (playerscorevisual - PlayerScore_Get(scorer, SP_SCORE));
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd));

			if(0){
				//debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", playerkillscore), 					" playerkillscore \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_KILLS)), " PlayerScore_Get(scorer, SP_KILLS) \n");
					print(sprintf("%f", playerscorevisual), 				" visual playerscore \n");
					print(sprintf("%f", scoretoadd), 						" scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			}
		return;
		}

		case 3:
		{
			//calculate how much score the player should have based on their damage dealt and then add the missing score
			float playerdamagescore = (((scorer.total_damage_dealt/(start_health + start_armorvalue)) * 100)/autocvar_g_tmayhem_fraglimit);
			float roundedplayerdamagescore = ((rint(playerdamagescore*10))/10);
			float playerscorevisual = (roundedplayerdamagescore * autocvar_g_tmayhem_visual_score_limit);
			float scoretoadd = (playerscorevisual - (PlayerScore_Get(scorer, SP_SCORE) * 100));
			GameRules_scoring_add_team(scorer, SCORE, floor(scoretoadd / 100));

			if(0){
				//debug printing
				if(!IS_BOT_CLIENT(scorer)){
					print(sprintf("%f", scorer.total_damage_dealt), 		" scorer.total_damage_dealt \n");
					print(sprintf("%f", playerdamagescore), 				" playerdamagescore \n");
					print(sprintf("%f", roundedplayerdamagescore), 			" rounded playerdamagescore \n");
					print(sprintf("%f", playerscorevisual), 				" visual playerscore \n");
					print(sprintf("%f", scoretoadd), 						" scoretoadd \n");
					print(sprintf("%f", PlayerScore_Get(scorer, SP_SCORE)), " PlayerScore_Get(scorer, SP_SCORE) \n \n");
				}
			}
		return;
		}
	}
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerDamage_SplitHealthArmor)
{
	if (autocvar_g_tmayhem_scoringmethod==2) return;
	
	entity frag_target = M_ARGV(2, entity);

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage >= 1)return;
	
	entity frag_attacker = M_ARGV(1, entity);
	float frag_deathtype = M_ARGV(6, float);
	float frag_damage = M_ARGV(7, float);
	float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
	float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));
	float excess = max(0, frag_damage - damage_take - damage_save);
	float total = frag_damage - excess;

	if (total == 0) return;

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage < 1)
		total *= 1 - bound(0, autocvar_g_spawnshield_blockdamage, 1);

	entity scorer = NULL; //entity which needs their score to be updated

	if (IS_PLAYER(frag_attacker))
	{
		//non-friendly fire
		if (!SAME_TEAM(frag_target, frag_attacker))
			frag_attacker.total_damage_dealt += total;

		//friendly fire aka self damage
		if (SAME_TEAM(frag_target, frag_attacker) || (frag_target == frag_attacker && !autocvar_g_tmayhem_scoringmethod_1_disable_selfdamage2score))
			frag_attacker.total_damage_dealt -= total;

		scorer = frag_attacker;
	}
	else
	{
		//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
		//deathtypes:
		//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
		//camp = campcheck, lava = lava, slime = slime
		//team change / rebalance suicides are currently not included
		if (!autocvar_g_tmayhem_scoringmethod_1_disable_selfdamage2score && (
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

	TeamMayhemCalculatePlayerScore(scorer);
}

MUTATOR_HOOKFUNCTION(tmayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	M_ARGV(2, float) = 0; //score to give for the frag directly
	
	if (IS_PLAYER(frag_attacker)) TeamMayhemCalculatePlayerScore(frag_attacker);
	
	return true;
}
