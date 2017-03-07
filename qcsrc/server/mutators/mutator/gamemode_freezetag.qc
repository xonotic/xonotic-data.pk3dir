#include "gamemode_freezetag.qh"

float autocvar_g_freezetag_frozen_maxtime;
float autocvar_g_freezetag_revive_clearspeed;
float autocvar_g_freezetag_round_timelimit;
//int autocvar_g_freezetag_teams;
int autocvar_g_freezetag_teams_override;
float autocvar_g_freezetag_warmup;

void freezetag_ScoreRules(int teams)
{
	ScoreRules_basics(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, true); // SFL_SORT_PRIO_PRIMARY
	ScoreInfo_SetLabel_PlayerScore(SP_FREEZETAG_REVIVALS, "revivals", 0);
	ScoreRules_basics_end();
}

void freezetag_count_alive_players()
{
	total_players = redalive = bluealive = yellowalive = pinkalive = 0;
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		switch(it.team)
		{
			case NUM_TEAM_1: ++total_players; if(it.health >= 1 && STAT(FROZEN, it) != 1) ++redalive; break;
			case NUM_TEAM_2: ++total_players; if(it.health >= 1 && STAT(FROZEN, it) != 1) ++bluealive; break;
			case NUM_TEAM_3: ++total_players; if(it.health >= 1 && STAT(FROZEN, it) != 1) ++yellowalive; break;
			case NUM_TEAM_4: ++total_players; if(it.health >= 1 && STAT(FROZEN, it) != 1) ++pinkalive; break;
		}
	));
	FOREACH_CLIENT(IS_REAL_CLIENT(it), LAMBDA(
		it.redalive_stat = redalive;
		it.bluealive_stat = bluealive;
		it.yellowalive_stat = yellowalive;
		it.pinkalive_stat = pinkalive;
	));

	eliminatedPlayers.SendFlags |= 1;
}
#define FREEZETAG_ALIVE_TEAMS() ((redalive > 0) + (bluealive > 0) + (yellowalive > 0) + (pinkalive > 0))
#define FREEZETAG_ALIVE_TEAMS_OK() (FREEZETAG_ALIVE_TEAMS() == NumTeams(freezetag_teams))

float freezetag_CheckTeams()
{
	static float prev_missing_teams_mask;
	if(FREEZETAG_ALIVE_TEAMS_OK())
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return 1;
	}
	if(total_players == 0)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return 0;
	}
	int missing_teams_mask = 0;
	if(freezetag_teams & BIT(0))
		missing_teams_mask += (!redalive) * 1;
	if(freezetag_teams & BIT(1))
		missing_teams_mask += (!bluealive) * 2;
	if(freezetag_teams & BIT(2))
		missing_teams_mask += (!yellowalive) * 4;
	if(freezetag_teams & BIT(3))
		missing_teams_mask += (!pinkalive) * 8;
	if(prev_missing_teams_mask != missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return 0;
}

float freezetag_getWinnerTeam()
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

void nades_Clear(entity);
void nades_GiveBonus(entity player, float score);

float freezetag_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
			it.freezetag_frozen_timeout = 0;
			nades_Clear(it);
		));
		game_stopped = true;
		round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);
		return 1;
	}

	if(FREEZETAG_ALIVE_TEAMS() > 1)
		return 0;

	int winner_team = freezetag_getWinnerTeam();
	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		TeamScore_AddToTeam(winner_team, ST_SCORE, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		it.freezetag_frozen_timeout = 0;
		nades_Clear(it);
	));

	game_stopped = true;
	round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);
	return 1;
}

entity freezetag_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, LAMBDA(
		if(it.health >= 1)
		if(!STAT(FROZEN, it))
		if(SAME_TEAM(it, this))
		if(!last_pl)
			last_pl = it;
		else
			return NULL;
	));
	return last_pl;
}

void freezetag_LastPlayerForTeam_Notify(entity this)
{
	if(round_handler_IsActive())
	if(round_handler_IsRoundStarted())
	{
		entity pl = freezetag_LastPlayerForTeam(this);
		if(pl)
			Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_ALONE);
	}
}

void freezetag_Add_Score(entity targ, entity attacker)
{
	if(attacker == targ)
	{
		// you froze your own dumb targ
		// counted as "suicide" already
		PlayerScore_Add(targ, SP_SCORE, -1);
	}
	else if(IS_PLAYER(attacker))
	{
		// got frozen by an enemy
		// counted as "kill" and "death" already
		PlayerScore_Add(targ, SP_SCORE, -1);
		PlayerScore_Add(attacker, SP_SCORE, +1);
	}
	// else nothing - got frozen by the game type rules themselves
}

void freezetag_Freeze(entity targ, entity attacker)
{
	if(STAT(FROZEN, targ))
		return;

	if(autocvar_g_freezetag_frozen_maxtime > 0)
		targ.freezetag_frozen_timeout = time + autocvar_g_freezetag_frozen_maxtime;

	Freeze(targ, 0, 1, true);

	freezetag_count_alive_players();

	freezetag_Add_Score(targ, attacker);
}

void freezetag_Unfreeze(entity this)
{
	this.freezetag_frozen_time = 0;
	this.freezetag_frozen_timeout = 0;

	Unfreeze(this);
}

float freezetag_isEliminated(entity e)
{
	if(IS_PLAYER(e) && (STAT(FROZEN, e) == 1 || IS_DEAD(e)))
		return true;
	return false;
}


// ================
// Bot player logic
// ================

void(entity this) havocbot_role_ft_freeing;
void(entity this) havocbot_role_ft_offense;

void havocbot_goalrating_freeplayers(entity this, float ratingscale, vector org, float sradius)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it != this && SAME_TEAM(it, this), LAMBDA(
		if (STAT(FROZEN, it) == 1)
		{
			if(vdist(it.origin - org, >, sradius))
				continue;
			navigation_routerating(this, it, ratingscale, 2000);
		}
		else
		{
			// If teamate is not frozen still seek them out as fight better
			// in a group.
			navigation_routerating(this, it, ratingscale/3, 2000);
		}
	));
}

void havocbot_role_ft_offense(entity this)
{
	if(IS_DEAD(this))
		return;

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20;

	// Count how many players on team are unfrozen.
	int unfrozen = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && SAME_TEAM(it, this) && !(STAT(FROZEN, it) != 1), LAMBDA(unfrozen++));

	// If only one left on team or if role has timed out then start trying to free players.
	if (((unfrozen == 0) && (!STAT(FROZEN, this))) || (time > this.havocbot_role_timeout))
	{
		LOG_TRACE("changing role to freeing");
		this.havocbot_role = havocbot_role_ft_freeing;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (time > this.bot_strategytime)
	{
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;

		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 20000, this.origin, 10000);
		havocbot_goalrating_freeplayers(this, 9000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);
	}
}

void havocbot_role_ft_freeing(entity this)
{
	if(IS_DEAD(this))
		return;

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20;

	if (time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to offense");
		this.havocbot_role = havocbot_role_ft_offense;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (time > this.bot_strategytime)
	{
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;

		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 8000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 10000, this.origin, 10000);
		havocbot_goalrating_freeplayers(this, 20000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);
	}
}


// ==============
// Hook Functions
// ==============

void ft_RemovePlayer(entity this)
{
	this.health = 0; // neccessary to update correctly alive stats
	if(!STAT(FROZEN, this))
		freezetag_LastPlayerForTeam_Notify(this);
	freezetag_Unfreeze(this);
	freezetag_count_alive_players();
}

MUTATOR_HOOKFUNCTION(ft, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	ft_RemovePlayer(player);
	return true;
}

MUTATOR_HOOKFUNCTION(ft, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	ft_RemovePlayer(player);
}

MUTATOR_HOOKFUNCTION(ft, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	if(round_handler_IsActive())
	if(round_handler_CountdownRunning())
	{
		if(STAT(FROZEN, frag_target))
			freezetag_Unfreeze(frag_target);
		freezetag_count_alive_players();
		return true; // let the player die so that he can respawn whenever he wants
	}

	// Cases DEATH_TEAMCHANGE and DEATH_AUTOTEAMCHANGE are needed to fix a bug whe
	// you succeed changing team through the menu: you both really die (gibbing) and get frozen
	if(ITEM_DAMAGE_NEEDKILL(frag_deathtype)
		|| frag_deathtype == DEATH_TEAMCHANGE.m_id || frag_deathtype == DEATH_AUTOTEAMCHANGE.m_id)
	{
		// let the player die, he will be automatically frozen when he respawns
		if(STAT(FROZEN, frag_target) != 1)
		{
			freezetag_Add_Score(frag_target, frag_attacker);
			freezetag_count_alive_players();
			freezetag_LastPlayerForTeam_Notify(frag_target);
		}
		else
			freezetag_Unfreeze(frag_target); // remove ice
		frag_target.health = 0; // Unfreeze resets health
		frag_target.freezetag_frozen_timeout = -2; // freeze on respawn
		return true;
	}

	if(STAT(FROZEN, frag_target))
		return true;

	freezetag_Freeze(frag_target, frag_attacker);
	freezetag_LastPlayerForTeam_Notify(frag_target);

	if(frag_attacker == frag_target || frag_attacker == NULL)
	{
		if(IS_PLAYER(frag_target))
			Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_FREEZETAG_SELF);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_SELF, frag_target.netname);
	}
	else
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_FREEZE, frag_target.netname, frag_attacker.netname);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ft, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(player.freezetag_frozen_timeout == -1) // if PlayerSpawn is called by reset_map_players
		return true; // do nothing, round is starting right now

	if(player.freezetag_frozen_timeout == -2) // player was dead
	{
		freezetag_Freeze(player, NULL);
		return true;
	}

	freezetag_count_alive_players();

	if(round_handler_IsActive())
	if(round_handler_IsRoundStarted())
	{
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_SPAWN_LATE);
		freezetag_Freeze(player, NULL);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ft, reset_map_players)
{
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		it.killcount = 0;
		it.freezetag_frozen_timeout = -1;
		PutClientInServer(it);
		it.freezetag_frozen_timeout = 0;
	));
	freezetag_count_alive_players();
	return true;
}

MUTATOR_HOOKFUNCTION(ft, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 0; // no frags counted in Freeze Tag
	return true;
}

MUTATOR_HOOKFUNCTION(ft, PlayerPreThink, CBC_ORDER_FIRST)
{
	if(game_stopped)
		return true;

	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
		return true;

	int n;
	entity o = NULL;
	entity player = M_ARGV(0, entity);
	//if(STAT(FROZEN, player))
	//if(player.freezetag_frozen_timeout > 0 && time < player.freezetag_frozen_timeout)
		//player.iceblock.alpha = ICE_MIN_ALPHA + (ICE_MAX_ALPHA - ICE_MIN_ALPHA) * (player.freezetag_frozen_timeout - time) / (player.freezetag_frozen_timeout - player.freezetag_frozen_time);

	if(player.freezetag_frozen_timeout > 0 && time >= player.freezetag_frozen_timeout)
		n = -1;
	else
	{
		vector revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;
		n = 0;
		FOREACH_CLIENT(IS_PLAYER(it) && it != player, LAMBDA(
			if(STAT(FROZEN, it) == 0)
			if(!IS_DEAD(it))
			if(SAME_TEAM(it, player))
			if(boxesoverlap(player.absmin - revive_extra_size, player.absmax + revive_extra_size, it.absmin, it.absmax))
			{
				if(!o)
					o = it;
				if(STAT(FROZEN, player) == 1)
					it.reviving = true;
				++n;
			}
		));

	}

	if(n && STAT(FROZEN, player) == 1) // OK, there is at least one teammate reviving us
	{
		player.revive_progress = bound(0, player.revive_progress + frametime * max(1/60, autocvar_g_freezetag_revive_speed), 1);
		player.health = max(1, player.revive_progress * ((warmup_stage) ? warmup_start_health : start_health));

		if(player.revive_progress >= 1)
		{
			freezetag_Unfreeze(player);
			freezetag_count_alive_players();

			if(n == -1)
			{
				Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_AUTO_REVIVED, autocvar_g_freezetag_frozen_maxtime);
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_AUTO_REVIVED, player.netname, autocvar_g_freezetag_frozen_maxtime);
				return true;
			}

			// EVERY team mate nearby gets a point (even if multiple!)
			FOREACH_CLIENT(IS_PLAYER(it) && it.reviving, LAMBDA(
				PlayerScore_Add(it, SP_FREEZETAG_REVIVALS, +1);
				PlayerScore_Add(it, SP_SCORE, +1);
				nades_GiveBonus(it,autocvar_g_nades_bonus_score_low);
			));

			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_REVIVED, o.netname);
			Send_Notification(NOTIF_ONE, o, MSG_CENTER, CENTER_FREEZETAG_REVIVE, player.netname);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_REVIVED, player.netname, o.netname);
		}

		FOREACH_CLIENT(IS_PLAYER(it) && it.reviving, LAMBDA(
			it.revive_progress = player.revive_progress;
			it.reviving = false;
		));
	}
	else if(!n && STAT(FROZEN, player) == 1) // only if no teammate is nearby will we reset
	{
		player.revive_progress = bound(0, player.revive_progress - frametime * autocvar_g_freezetag_revive_clearspeed, 1);
		player.health = max(1, player.revive_progress * ((warmup_stage) ? warmup_start_health : start_health));
	}
	else if(!n && !STAT(FROZEN, player))
	{
		player.revive_progress = 0; // thawing nobody
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ft, SetStartItems)
{
	start_items &= ~IT_UNLIMITED_AMMO;
	//start_health       = warmup_start_health       = cvar("g_lms_start_health");
	//start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_lms_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(ft, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	if (!IS_DEAD(bot))
	{
		if (random() < 0.5)
			bot.havocbot_role = havocbot_role_ft_freeing;
		else
			bot.havocbot_role = havocbot_role_ft_offense;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ft, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = freezetag_teams;
}

MUTATOR_HOOKFUNCTION(ft, SetWeaponArena)
{
	// most weapons arena
	if(M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = "most";
}

MUTATOR_HOOKFUNCTION(ft, FragCenterMessage)
{
	entity frag_attacker = M_ARGV(0, entity);
	entity frag_target = M_ARGV(1, entity);
	//float frag_deathtype = M_ARGV(2, float);
	int kill_count_to_attacker = M_ARGV(3, int);
	int kill_count_to_target = M_ARGV(4, int);

	if(STAT(FROZEN, frag_target))
		return; // target was already frozen, so this is just pushing them off the cliff

	Send_Notification(NOTIF_ONE, frag_attacker, MSG_CHOICE, CHOICE_FRAG_FREEZE, frag_target.netname, kill_count_to_attacker, (IS_BOT_CLIENT(frag_target) ? -1 : frag_target.ping));
	Send_Notification(NOTIF_ONE, frag_target, MSG_CHOICE, CHOICE_FRAGGED_FREEZE, frag_attacker.netname, kill_count_to_target, frag_attacker.health, frag_attacker.armorvalue, (IS_BOT_CLIENT(frag_attacker) ? -1 : frag_attacker.ping));

	return true;
}

void freezetag_Initialize()
{
	freezetag_teams = autocvar_g_freezetag_teams_override;
	if(freezetag_teams < 2)
		freezetag_teams = cvar("g_freezetag_teams"); // read the cvar directly as it gets written earlier in the same frame
	freezetag_teams = bound(2, freezetag_teams, 4);

	int teams = 0;
	if(freezetag_teams >= 1) teams |= BIT(0);
	if(freezetag_teams >= 2) teams |= BIT(1);
	if(freezetag_teams >= 3) teams |= BIT(2);
	if(freezetag_teams >= 4) teams |= BIT(3);

	freezetag_teams = teams; // now set it?
	freezetag_ScoreRules(freezetag_teams);

	round_handler_Spawn(freezetag_CheckTeams, freezetag_CheckWinner, func_null);
	round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);

	EliminatedPlayers_Init(freezetag_isEliminated);
}
