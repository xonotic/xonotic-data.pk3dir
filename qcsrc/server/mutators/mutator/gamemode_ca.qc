#include "gamemode_ca.qh"
#ifndef GAMEMODE_CA_H
#define GAMEMODE_CA_H

int autocvar_g_ca_point_limit;
int autocvar_g_ca_point_leadlimit;
float autocvar_g_ca_round_timelimit;
bool autocvar_g_ca_team_spawns;
int autocvar_g_ca_teams;
int autocvar_g_ca_teams_override;
float autocvar_g_ca_warmup;


int ca_teams;
bool allowed_to_spawn;

const int ST_CA_ROUNDS = 1;

bool CA_CheckTeams();
bool CA_CheckWinner();
void CA_RoundStart();
bool ca_isEliminated(entity e);

void SetLimits(int fraglimit_override, int leadlimit_override, float timelimit_override, float qualifying_override);

REGISTER_MUTATOR(ca, false)
{
	MUTATOR_ONADD
	{
		// game loads at time 1
		if (time > 1) error("This is a game type and it cannot be added at runtime.");

		allowed_to_spawn = true;

		ca_teams = autocvar_g_ca_teams_override;
		if (ca_teams < 2) ca_teams = autocvar_g_ca_teams;
		ca_teams = bound(2, ca_teams, 4);
		ret_float = ca_teams;

        ScoreRules_basics(ca_teams, SFL_SORT_PRIO_PRIMARY, 0, true);
        ScoreInfo_SetLabel_TeamScore(ST_CA_ROUNDS, "rounds", SFL_SORT_PRIO_PRIMARY);
        ScoreRules_basics_end();

		round_handler_Spawn(CA_CheckTeams, CA_CheckWinner, CA_RoundStart);
		round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

		EliminatedPlayers_Init(ca_isEliminated);

		ActivateTeamplay();
		SetLimits(autocvar_g_ca_point_limit, autocvar_g_ca_point_leadlimit, -1, -1);

		if (autocvar_g_ca_team_spawns)
			have_team_spawns = -1; // request team spawns
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

// should be removed in the future, as other code should not have to care
.float caplayer; // 0.5 if scheduled to join the next round
#endif

#ifdef IMPLEMENTATION
float autocvar_g_ca_damage2score_multiplier;
bool autocvar_g_ca_spectate_enemies;

void CA_count_alive_players()
{
	total_players = redalive = bluealive = yellowalive = pinkalive = 0;
	FOREACH_CLIENT(IS_PLAYER(it), {
		switch(TMID(it.team))
		{
			case NUM_TEAM_1: ++total_players; if(!IS_DEAD(it)) ++redalive; break;
			case NUM_TEAM_2: ++total_players; if(!IS_DEAD(it)) ++bluealive; break;
			case NUM_TEAM_3: ++total_players; if(!IS_DEAD(it)) ++yellowalive; break;
			case NUM_TEAM_4: ++total_players; if(!IS_DEAD(it)) ++pinkalive; break;
		}
	});
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		it.redalive_stat = redalive;
		it.bluealive_stat = bluealive;
		it.yellowalive_stat = yellowalive;
		it.pinkalive_stat = pinkalive;
	});
}

float CA_GetWinnerTeam()
{
	float winner_team = 0;
	if(redalive >= 1)
		winner_team = NUM_TEAM_1;
	if(bluealive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_2;
	}
	if(yellowalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_3;
	}
	if(pinkalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_4;
	}
	if(winner_team)
		return winner_team;
	return -1; // no player left
}

void nades_Clear(entity player);

#define CA_ALIVE_TEAMS() ((redalive > 0) + (bluealive > 0) + (yellowalive > 0) + (pinkalive > 0))
#define CA_ALIVE_TEAMS_OK() (CA_ALIVE_TEAMS() == ca_teams)
float CA_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		allowed_to_spawn = false;
		round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(nades_Clear(it)));
		return 1;
	}

	CA_count_alive_players();
	if(CA_ALIVE_TEAMS() > 1)
		return 0;

	int winner_team = CA_GetWinnerTeam();
	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		TeamScore_AddToTeam(winner_team, ST_CA_ROUNDS, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_TIED);
	}

	allowed_to_spawn = false;
	round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(nades_Clear(it)));

	return 1;
}

void CA_RoundStart()
{
    allowed_to_spawn = boolean(warmup_stage);
}

bool CA_CheckTeams()
{
	static int prev_missing_teams_mask;
	allowed_to_spawn = true;
	CA_count_alive_players();
	if(CA_ALIVE_TEAMS_OK())
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, world, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return true;
	}
	if(total_players == 0)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, world, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return false;
	}
	int missing_teams_mask = (!redalive) + (!bluealive) * 2;
	if(ca_teams >= 3) missing_teams_mask += (!yellowalive) * 4;
	if(ca_teams >= 4) missing_teams_mask += (!pinkalive) * 8;
	if(prev_missing_teams_mask != missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return false;
}

bool ca_isEliminated(entity e)
{
	if(e.caplayer == 1 && (IS_DEAD(e) || e.frags == FRAGS_LMS_LOSER))
		return true;
	if(e.caplayer == 0.5)
		return true;
	return false;
}

/** Returns next available player to spectate if g_ca_spectate_enemies == 0 */
entity CA_SpectateNext(entity player, entity start)
{
	if (SAME_TEAM(start, player)) return start;
	// continue from current player
	for (entity e = start; (e = find(e, classname, STR_PLAYER)); )
	{
		if (SAME_TEAM(player, e)) return e;
	}
	// restart from begining
	for (entity e = NULL; (e = find(e, classname, STR_PLAYER)); )
	{
		if (SAME_TEAM(player, e)) return e;
	}
	return start;
}


MUTATOR_HOOKFUNCTION(ca, PlayerSpawn)
{
    SELFPARAM();
	this.caplayer = 1;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
}

MUTATOR_HOOKFUNCTION(ca, PutClientInServer)
{
    SELFPARAM();
	if (!allowed_to_spawn && IS_PLAYER(this)) // this is true even when player is trying to join
	{
		this.classname = STR_OBSERVER;
		if (this.jointime != time && !this.caplayer) // not when connecting
		{
			this.caplayer = 0.5;
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}
}

MUTATOR_HOOKFUNCTION(ca, reset_map_players)
{
	FOREACH_CLIENT(true, {
		it.killcount = 0;
		if (!it.caplayer && IS_BOT_CLIENT(it))
		{
			it.__team = -1;
			it.caplayer = 1;
		}
		if (it.caplayer)
		{
			it.classname = STR_PLAYER;
			it.caplayer = 1;
			WITH(entity, self, it, PutClientInServer());
		}
	});
	return true;
}

MUTATOR_HOOKFUNCTION(ca, ClientConnect)
{
    SELFPARAM();
	this.classname = STR_OBSERVER;
	return true;
}

MUTATOR_HOOKFUNCTION(ca, reset_map_global)
{
	allowed_to_spawn = true;
	return true;
}

MUTATOR_HOOKFUNCTION(ca, GetTeamCount, CBC_ORDER_EXCLUSIVE)
{
	ret_float = ca_teams;
	return false;
}

entity ca_LastPlayerForTeam()
{
    SELFPARAM();
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
		if (!IS_DEAD(it))
		if (SAME_TEAM(this, it))
		if (!last_pl)
			last_pl = it;
		else
			return NULL;
	});
	return last_pl;
}

void ca_LastPlayerForTeam_Notify()
{
	if (round_handler_IsActive())
	if (round_handler_IsRoundStarted())
	{
		entity pl = ca_LastPlayerForTeam();
		if (pl)
			Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_ALONE);
	}
}

MUTATOR_HOOKFUNCTION(ca, PlayerDies)
{
	ca_LastPlayerForTeam_Notify();
	if (!allowed_to_spawn)
		frag_target.respawn_flags =  RESPAWN_SILENT;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, ClientDisconnect)
{
    SELFPARAM();
	if (this.caplayer == 1)
		ca_LastPlayerForTeam_Notify();
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, ForbidPlayerScore_Clear)
{
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, MakePlayerObserver)
{
    SELFPARAM();
	if (this.caplayer == 1)
		ca_LastPlayerForTeam_Notify();
	if (this.killindicator_teamchange == -2)
		this.caplayer = 0;
	if (this.caplayer)
		this.frags = FRAGS_LMS_LOSER;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(ca, ForbidThrowCurrentWeapon)
{
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, GiveFragsForKill, CBC_ORDER_FIRST)
{
	frag_score = 0; // score will be given to the winner team when the round ends
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, SetStartItems)
{
	start_items       &= ~IT_UNLIMITED_AMMO;
	start_health       = warmup_start_health       = cvar("g_lms_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_lms_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");

	return 0;
}

MUTATOR_HOOKFUNCTION(ca, PlayerDamage_Calculate)
{
	if (IS_PLAYER(frag_target))
	if (!IS_DEAD(frag_target))
	if (frag_target == frag_attacker || SAME_TEAM(frag_target, frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(ca, FilterItem)
{
    SELFPARAM();
	if (autocvar_g_powerups <= 0)
	if (this.flags & FL_POWERUP)
		return true;

	if (autocvar_g_pickup_items <= 0)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(ca, PlayerDamage_SplitHealthArmor)
{
	float excess = max(0, frag_damage - damage_take - damage_save);

	if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
		PlayerTeamScore_Add(frag_attacker, SP_SCORE, ST_SCORE, (frag_damage - excess) * autocvar_g_ca_damage2score_multiplier);

	return false;
}

MUTATOR_HOOKFUNCTION(ca, PlayerRegen)
{
	// no regeneration in CA
	return true;
}

MUTATOR_HOOKFUNCTION(ca, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(ca, SpectateSet)
{
    SELFPARAM();
	if (!autocvar_g_ca_spectate_enemies && this.caplayer)
	if (DIFF_TEAM(spec_player, this))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, SpectateNext)
{
    SELFPARAM();
	if (!autocvar_g_ca_spectate_enemies && this.caplayer)
	{
		spec_player = CA_SpectateNext(this, spec_player);
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(ca, SpectatePrev)
{
    SELFPARAM();
	if (!autocvar_g_ca_spectate_enemies && this.caplayer)
	{
		do { spec_player = spec_player.chain; }
		while(spec_player && DIFF_TEAM(spec_player, this));

		if (!spec_player)
		{
			for (spec_player = spec_first; spec_player && DIFF_TEAM(spec_player, this); spec_player = spec_player.chain);

			if (spec_player == this.enemy)
				return MUT_SPECPREV_RETURN;
		}
	}

	return MUT_SPECPREV_FOUND;
}

MUTATOR_HOOKFUNCTION(ca, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || it.caplayer == 1)
			++bot_activerealplayers;
		++bot_realplayers;
	});
	return true;
}

MUTATOR_HOOKFUNCTION(ca, ClientCommand_Spectate)
{
    SELFPARAM();
	if (this.caplayer)
	{
		// they're going to spec, we can do other checks
		if (autocvar_sv_spectate && (IS_SPEC(this) || IS_OBSERVER(this)))
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(ca, WantWeapon)
{
	want_allguns = true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, GetPlayerStatus)
{
	return set_player.caplayer == 1;
}

MUTATOR_HOOKFUNCTION(ca, SetWeaponArena)
{
	// most weapons arena
	if (ret_string == "0" || ret_string == "") ret_string = "most";
}

#endif
