#include "sv_rules.qh"

#include <common/scores.qh>
#include <server/spawnpoints.qh>
#include <server/teamplay.qh>

void GameRules_teams(bool value)
{
    if (value) {
        serverflags |= SERVERFLAG_TEAMPLAY;
        teamplay = 1;
        cvar_set("teamplay", "2");  // DP needs this for sending proper getstatus replies.
        Team_InitTeams();
        GameRules_spawning_teams(true);
    } else {
    	serverflags &= ~SERVERFLAG_TEAMPLAY;
    	teamplay = 0;
    	cvar_set("teamplay", "0");  // DP needs this for sending proper getstatus replies.
    	GameRules_spawning_teams(false);
    }
}

void GameRules_spawning_teams(bool value)
{
    have_team_spawns = value ? -1 : 0;
}

bool _GameRules_score_enabled = true;
void GameRules_score_enabled(bool value)
{
    _GameRules_score_enabled = value;
}

bool GameRules_limit_score_initialized;
void GameRules_limit_score(int limit)
{
    if (GameRules_limit_score_initialized) return;
    if (autocvar_g_campaign) return;
    if (limit < 0) return;
    cvar_set("fraglimit", ftos(limit));
    GameRules_limit_score_initialized = true;
}

bool GameRules_limit_lead_initialized;
void GameRules_limit_lead(int limit)
{
    if (GameRules_limit_lead_initialized) return;
    if (autocvar_g_campaign) return;
    if (limit < 0) return;
    cvar_set("leadlimit", ftos(limit));
    GameRules_limit_lead_initialized = true;
}

bool GameRules_limit_time_initialized;
void GameRules_limit_time(int limit)
{
    if (GameRules_limit_time_initialized) return;
    if (autocvar_g_campaign) return;
    if (limit < 0) return;
    cvar_set("timelimit", ftos(limit));
    GameRules_limit_time_initialized = true;
}

bool GameRules_limit_time_qualifying_initialized;
void GameRules_limit_time_qualifying(int limit)
{
    if (GameRules_limit_time_qualifying_initialized) return;
    if (autocvar_g_campaign) return;
    if (limit < 0) return;
    cvar_set("g_race_qualifying_timelimit", ftos(limit));
    GameRules_limit_time_qualifying_initialized = true;
}

void GameRules_limit_fallbacks()
{
    GameRules_limit_score(autocvar_fraglimit_override);
    GameRules_limit_lead(autocvar_leadlimit_override);
    GameRules_limit_time(autocvar_timelimit_override);
}

void _GameRules_scoring_begin(int teams, float spprio, float stprio)
{
    ScoreRules_basics(teams, spprio, stprio, _GameRules_score_enabled);
}
void _GameRules_scoring_field(entity i, string label, int scoreflags)
{
    ScoreInfo_SetLabel_PlayerScore(i, label, scoreflags);
}
void _GameRules_scoring_field_team(float i, string label, int scoreflags)
{
    ScoreInfo_SetLabel_TeamScore(i, label, scoreflags);
}
void _GameRules_scoring_end()
{
    ScoreRules_basics_end();
}

.bool m_GameRules_scoring_vip;
void GameRules_scoring_vip(entity player, bool value)
{
    player.m_GameRules_scoring_vip = value;
}
bool GameRules_scoring_is_vip(entity player)
{
    return player.m_GameRules_scoring_vip;
}

// Uses client.float_field to accumulate and consume float score and adds score to the player as int (rounded)
// only when at least one unit of score has been accumulated. It works with negative score too
// Float scores can't be used as score because they aren't supported by the QC score networking system
// and online server browsers (e.g. qstat)
float _GameRules_scoring_add_float2int(entity client, entity sp, float value, .float float_field, float score_factor)
{
	client.(float_field) += value;
	float score_counter = client.(float_field) / score_factor;
	if (score_counter >= -0.5 && score_counter < 0.5)
		return 0;

	// NOTE: this code works for subtracting score too
	int points = floor(score_counter + 0.5);
	client.(float_field) -= points * score_factor;
	if (!points)
		return 0;
	return PlayerScore_Add(client, sp, points);
}

float _GameRules_scoring_add(entity client, entity sp, float value)
{
    return PlayerScore_Add(client, sp, value);
}
float _GameRules_scoring_add_team(entity client, entity sp, int st, float value)
{
    return PlayerTeamScore_Add(client, sp, st, value);
}

// Mayhem score functionality
void Mayhem_FragLimit_Override()
{
	if (!autocvar_g_mayhem) return;

	if (autocvar_fraglimit_override != 0)
		GameRules_limit_score(autocvar_g_mayhem_visual_score_limit);
	else
		GameRules_limit_score(9999);
}

void FFAMayhemCalculatePlayerScore(entity scorer)
{
	if (!autocvar_g_mayhem) return;

	if (autocvar_fraglimit_override > 0) autocvar_g_mayhem_fraglimit = autocvar_fraglimit_override;
	
	switch (autocvar_g_mayhem_scoringmethod)
	{
		default:
		case 1:
		{
			//calculate how much score the player should have based on their damage dealt and frags gotten and then add the missing score

			//give a different weight for suicides if scoring method 1 doesn't have selfdamage2score enabled to harshly punish for suicides to avoid exploiting
			float suicide_weight = 1 + (autocvar_g_mayhem_scoringmethod_1_disable_selfdamage2score * (1/autocvar_g_mayhem_scoringmethod_1_frag_weight));

			//total damage divided by player start health&armor to get how many lives worth of damage they've dealt, then how much that is out of the fraglimit, then calculate new value affected by weight
			float playerdamagescore = (((((scorer.total_damage_dealt/(start_health + start_armorvalue)) * 100)/autocvar_g_mayhem_fraglimit) * autocvar_g_mayhem_scoringmethod_1_damage_weight) );
																									//  * 100 to avoid float inaccuracy at that decimal level

			//playerdamagescore rounded
			float roundedplayerdamagescore = ((rint(playerdamagescore*10))/10);

			//kills minus suicides, total out of fraglimit, calculate weight
			float playerkillscore = ((((PlayerScore_Get(scorer, SP_KILLS) - (PlayerScore_Get(scorer, SP_SUICIDES) * suicide_weight)) * 100) / autocvar_g_mayhem_fraglimit) * autocvar_g_mayhem_scoringmethod_1_frag_weight);
																																//   * 100 to avoid float inaccuracy at that decimal level

			//only used for debug print, add killscore and damagescore together
			float playerscore = (roundedplayerdamagescore + playerkillscore);

			//add killscore and damagescore together to get total score and then adjust it to be total out of the visual score limit
			float playerscorevisual = ((roundedplayerdamagescore + playerkillscore) * autocvar_g_mayhem_visual_score_limit);
																														

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
			float playerkillscore = (((PlayerScore_Get(scorer, SP_KILLS) - PlayerScore_Get(scorer, SP_SUICIDES)) * 100)/ autocvar_g_mayhem_fraglimit);
			float playerscorevisual = (playerkillscore * autocvar_g_mayhem_visual_score_limit) / 100;
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
			float playerdamagescore = (((scorer.total_damage_dealt/(start_health + start_armorvalue)) * 100)/autocvar_g_mayhem_fraglimit);
			float roundedplayerdamagescore = ((rint(playerdamagescore*10))/10);
			float playerscorevisual = (roundedplayerdamagescore * autocvar_g_mayhem_visual_score_limit);
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

void Mayhem_Scoring_Method(entity frag_attacker, entity frag_target, float dmg_taken, float dmg_saved, float frag_deathtype, float frag_damage)
{
	if (!autocvar_g_mayhem) return;

	if (autocvar_g_mayhem_scoringmethod == 2) return;

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) 
		&& autocvar_g_spawnshield_blockdamage >= 1) 
		return;

	float damage_take = bound(0, dmg_taken, GetResource(frag_target, RES_HEALTH));
	float damage_save = bound(0, dmg_saved, GetResource(frag_target, RES_ARMOR));
	float excess = max(0, frag_damage - damage_take - damage_save);
	float total = frag_damage - excess;

	if (total == 0) return;

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && autocvar_g_spawnshield_blockdamage < 1)
		total *= 1 - bound(0, autocvar_g_spawnshield_blockdamage, 1);

	entity scorer = NULL; //entity which needs their score to be updated

	if (IS_PLAYER(frag_attacker))
	{
		//non-friendly fire
		if (frag_target != frag_attacker)
			frag_attacker.total_damage_dealt += total;

		//friendly fire aka self damage
		if (frag_target == frag_attacker && !autocvar_g_mayhem_scoringmethod_1_disable_selfdamage2score)
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
		if (!autocvar_g_mayhem_scoringmethod_1_disable_selfdamage2score && (
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

	FFAMayhemCalculatePlayerScore(scorer);
}
