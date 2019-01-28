#include "sv_freezetag.qh"

#include <server/resources.qh>

float autocvar_g_freezetag_frozen_maxtime;
float autocvar_g_freezetag_revive_clearspeed;
float autocvar_g_freezetag_round_timelimit;
//int autocvar_g_freezetag_teams;
int autocvar_g_freezetag_teams_override;
float autocvar_g_freezetag_warmup;

void freezetag_count_alive_players()
{
	total_players = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		Team_SetNumberOfAlivePlayers(Team_GetTeamFromIndex(i), 0);
	}
	FOREACH_CLIENT(IS_PLAYER(it) && Entity_HasValidTeam(it),
	{
		++total_players;
		if (GetResourceAmount(it, RESOURCE_HEALTH) < 1 || STAT(FROZEN, it) == FROZEN_NORMAL)
		{
			continue;
		}
		entity team_ = Entity_GetTeam(it);
		int num_alive = Team_GetNumberOfAlivePlayers(team_);
		++num_alive;
		Team_SetNumberOfAlivePlayers(team_, num_alive);
	});
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		STAT(REDALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(
			1));
		STAT(BLUEALIVE, it) = Team_GetNumberOfAlivePlayers(
			Team_GetTeamFromIndex(2));
		STAT(YELLOWALIVE, it) = Team_GetNumberOfAlivePlayers(
			Team_GetTeamFromIndex(3));
		STAT(PINKALIVE, it) = Team_GetNumberOfAlivePlayers(
			Team_GetTeamFromIndex(4));
	});

	eliminatedPlayers.SendFlags |= 1;
}

bool freezetag_CheckTeams()
{
	static float prev_missing_teams_mask;
	if (Team_GetNumberOfAliveTeams() == NumTeams(freezetag_teams))
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return true;
	}
	if(total_players == 0)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return false;
	}
	int missing_teams_mask = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if ((freezetag_teams & Team_IndexToBit(i)) &&
			(Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(i)) == 0))
		{
			missing_teams_mask |= Team_IndexToBit(i);
		}
	}
	if(prev_missing_teams_mask != missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return false;
}

int freezetag_getWinnerTeam()
{
	int winner_team = 0;
	if (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)) >= 1)
	{
		winner_team = NUM_TEAM_1;
	}
	for (int i = 2; i <= NUM_TEAMS; ++i)
	{
		if (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(i)) >= 1)
		{
			if (winner_team != 0)
			{
				return 0;
			}
			winner_team = Team_IndexToTeam(i);
		}
	}
	if (winner_team)
	{
		return winner_team;
	}
	return -1; // no player left
}

void nades_Clear(entity);
void nades_GiveBonus(entity player, float score);

bool freezetag_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);
		FOREACH_CLIENT(IS_PLAYER(it), {
			it.freezetag_frozen_timeout = 0;
			nades_Clear(it);
		});
		game_stopped = true;
		round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);
		return true;
	}

	if (Team_GetNumberOfAliveTeams() > 1)
	{
		return false;
	}

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

	FOREACH_CLIENT(IS_PLAYER(it), {
		it.freezetag_frozen_timeout = 0;
		nades_Clear(it);
	});

	game_stopped = true;
	round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);
	return true;
}

entity freezetag_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this && SAME_TEAM(it, this), {
		if (STAT(FROZEN, it) != FROZEN_NORMAL && GetResourceAmount(it, RESOURCE_HEALTH) >= 1)
		{
			if (!last_pl)
				last_pl = it;
			else
				return NULL;
		}
	});
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
		GameRules_scoring_add(targ, SCORE, -1);
	}
	else if(IS_PLAYER(attacker))
	{
		// got frozen by an enemy
		// counted as "kill" and "death" already
		GameRules_scoring_add(targ, SCORE, -1);
		GameRules_scoring_add(attacker, SCORE, +1);
	}
	// else nothing - got frozen by the game type rules themselves
}

// to be called when the player is frozen by freezetag (on death, spectator join etc), gives the score
void freezetag_Freeze(entity targ, entity attacker)
{
	if(STAT(FROZEN, targ))
		return;

	if(autocvar_g_freezetag_frozen_maxtime > 0)
		targ.freezetag_frozen_timeout = time + autocvar_g_freezetag_frozen_maxtime;

	Freeze(targ, 0, FROZEN_NORMAL, true);

	freezetag_count_alive_players();

	freezetag_Add_Score(targ, attacker);
}

bool freezetag_isEliminated(entity e)
{
	if(IS_PLAYER(e) && (STAT(FROZEN, e) == FROZEN_NORMAL || IS_DEAD(e)))
		return true;
	return false;
}


// ================
// Bot player logic
// ================

void(entity this) havocbot_role_ft_freeing;
void(entity this) havocbot_role_ft_offense;

void havocbot_goalrating_ft_freeplayers(entity this, float ratingscale, vector org, float sradius)
{
	entity best_pl = NULL;
	float best_dist2 = FLOAT_MAX;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this && SAME_TEAM(it, this), {
		if (STAT(FROZEN, it) == FROZEN_NORMAL)
		{
			if(vdist(it.origin - org, >, sradius))
				continue;
			navigation_routerating(this, it, ratingscale, 2000);
		}
		else if (best_dist2
			&& GetResourceAmount(it, RESOURCE_HEALTH) < GetResourceAmount(this, RESOURCE_HEALTH) + 30
			&& vlen2(it.origin - org) < best_dist2)
		{
			// If teamate is not frozen still seek them out as fight better
			// in a group.
			best_dist2 = vlen2(it.origin - org);
			if (best_dist2 < 700 ** 2)
			{
				best_pl = NULL;
				best_dist2 = 0; // already close to a teammate
			}
			else
				best_pl = it;
		}
	});
	if (best_pl)
		navigation_routerating(this, best_pl, ratingscale / 2, 2000);
}

void havocbot_role_ft_offense(entity this)
{
	if(IS_DEAD(this))
		return;

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20;

	// Count how many players on team are unfrozen.
	int unfrozen = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && SAME_TEAM(it, this) && STAT(FROZEN, it) != FROZEN_NORMAL, {
		unfrozen++;
	});

	// If only one left on team or if role has timed out then start trying to free players.
	if ((!unfrozen && STAT(FROZEN, this) != FROZEN_NORMAL) || time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to freeing");
		this.havocbot_role = havocbot_role_ft_freeing;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 12000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 10000, this.origin, 10000);
		havocbot_goalrating_ft_freeplayers(this, 9000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
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

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 5000, this.origin, 10000);
		havocbot_goalrating_ft_freeplayers(this, 20000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}


// ==============
// Hook Functions
// ==============

void ft_RemovePlayer(entity this)
{
	if (STAT(FROZEN, this) != FROZEN_NORMAL)
		freezetag_LastPlayerForTeam_Notify(this);
	Unfreeze(this, false);

	SetResourceAmountExplicit(this, RESOURCE_HEALTH, 0); // neccessary to correctly count alive players
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
		if (STAT(FROZEN, frag_target) == FROZEN_NORMAL)
			Unfreeze(frag_target, true);
		freezetag_count_alive_players();
		return true; // let the player die so that he can respawn whenever he wants
	}

	// Cases DEATH_TEAMCHANGE and DEATH_AUTOTEAMCHANGE are needed to fix a bug whe
	// you succeed changing team through the menu: you both really die (gibbing) and get frozen
	if(ITEM_DAMAGE_NEEDKILL(frag_deathtype)
		|| frag_deathtype == DEATH_TEAMCHANGE.m_id || frag_deathtype == DEATH_AUTOTEAMCHANGE.m_id)
	{
		// let the player die, he will be automatically frozen when he respawns
		if (STAT(FROZEN, frag_target) != FROZEN_NORMAL)
		{
			freezetag_Add_Score(frag_target, frag_attacker);
			freezetag_count_alive_players();
			freezetag_LastPlayerForTeam_Notify(frag_target);
		}
		else
			Unfreeze(frag_target, false); // remove ice
		frag_target.freezetag_frozen_timeout = -2; // freeze on respawn
		return true;
	}

	if (STAT(FROZEN, frag_target) == FROZEN_NORMAL)
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
	FOREACH_CLIENT(IS_PLAYER(it), {
		CS(it).killcount = 0;
		it.freezetag_frozen_timeout = -1;
		PutClientInServer(it);
		it.freezetag_frozen_timeout = 0;
	});
	freezetag_count_alive_players();
	return true;
}

MUTATOR_HOOKFUNCTION(ft, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 0; // no frags counted in Freeze Tag
	return true;
}

MUTATOR_HOOKFUNCTION(ft, Unfreeze)
{
	entity targ = M_ARGV(0, entity);
	targ.freezetag_frozen_time = 0;
	targ.freezetag_frozen_timeout = 0;
}

#ifdef IS_REVIVING
	#undef IS_REVIVING
#endif

// returns true if player is reviving it
#define IS_REVIVING(player, it, revive_extra_size) \
	(it != player && !STAT(FROZEN, it) && !IS_DEAD(it) && SAME_TEAM(it, player) \
	&& boxesoverlap(player.absmin - revive_extra_size, player.absmax + revive_extra_size, it.absmin, it.absmax))

MUTATOR_HOOKFUNCTION(ft, PlayerPreThink, CBC_ORDER_FIRST)
{
	if(game_stopped)
		return true;

	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
		return true;

	int n;
	entity player = M_ARGV(0, entity);
	//if (STAT(FROZEN, player) == FROZEN_NORMAL)
	//if(player.freezetag_frozen_timeout > 0 && time < player.freezetag_frozen_timeout)
		//player.iceblock.alpha = ICE_MIN_ALPHA + (ICE_MAX_ALPHA - ICE_MIN_ALPHA) * (player.freezetag_frozen_timeout - time) / (player.freezetag_frozen_timeout - player.freezetag_frozen_time);

	entity reviving_players_last = NULL;
	entity reviving_players_first = NULL;

	if(player.freezetag_frozen_timeout > 0 && time >= player.freezetag_frozen_timeout)
		n = -1;
	else
	{
		n = 0;
		vector revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;
		FOREACH_CLIENT(IS_PLAYER(it) && IS_REVIVING(player, it, revive_extra_size), {
			if (reviving_players_last)
				reviving_players_last.chain = it;
			reviving_players_last = it;
			if (!reviving_players_first)
				reviving_players_first = it;
			++n;
		});
		if (reviving_players_last)
			reviving_players_last.chain = NULL;
	}

	if (!n) // no teammate nearby
	{
		if (STAT(FROZEN, player) == FROZEN_NORMAL)
		{
			STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) - frametime * autocvar_g_freezetag_revive_clearspeed, 1);
			SetResourceAmountExplicit(player, RESOURCE_HEALTH, max(1, STAT(REVIVE_PROGRESS, player) * ((warmup_stage) ? warmup_start_health : start_health)));
		}
		else if (!STAT(FROZEN, player))
			STAT(REVIVE_PROGRESS, player) = 0; // thawing nobody
	}
	else if (STAT(FROZEN, player) == FROZEN_NORMAL) // OK, there is at least one teammate reviving us
	{
		STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) + frametime * max(1/60, autocvar_g_freezetag_revive_speed), 1);
		SetResourceAmountExplicit(player, RESOURCE_HEALTH, max(1, STAT(REVIVE_PROGRESS, player) * ((warmup_stage) ? warmup_start_health : start_health)));

		if(STAT(REVIVE_PROGRESS, player) >= 1)
		{
			Unfreeze(player, false);
			freezetag_count_alive_players();

			if(n == -1)
			{
				Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_AUTO_REVIVED, autocvar_g_freezetag_frozen_maxtime);
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_AUTO_REVIVED, player.netname, autocvar_g_freezetag_frozen_maxtime);
				return true;
			}

			// EVERY team mate nearby gets a point (even if multiple!)
			for(entity it = reviving_players_first; it; it = it.chain)
			{
				GameRules_scoring_add(it, FREEZETAG_REVIVALS, +1);
				GameRules_scoring_add(it, SCORE, +1);
				nades_GiveBonus(it, autocvar_g_nades_bonus_score_low);
			}

			entity first = reviving_players_first;
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_REVIVED, first.netname);
			Send_Notification(NOTIF_ONE, first, MSG_CENTER, CENTER_FREEZETAG_REVIVE, player.netname);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_REVIVED, player.netname, first.netname);
		}

		for(entity it = reviving_players_first; it; it = it.chain)
			STAT(REVIVE_PROGRESS, it) = STAT(REVIVE_PROGRESS, player);
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

	// if bots spawn all at once assign them a more appropriated role after a while
	if (time < CS(bot).jointime + 1)
		bot.havocbot_role_timeout = time + 10 + random() * 10;

	return true;
}

MUTATOR_HOOKFUNCTION(ft, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = freezetag_teams;
	return true;
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

	if(STAT(FROZEN, frag_target) == FROZEN_NORMAL)
		return; // target was already frozen, so this is just pushing them off the cliff

	Send_Notification(NOTIF_ONE, frag_attacker, MSG_CHOICE, CHOICE_FRAG_FREEZE, frag_target.netname, kill_count_to_attacker, (IS_BOT_CLIENT(frag_target) ? -1 : CS(frag_target).ping));
	Send_Notification(NOTIF_ONE, frag_target, MSG_CHOICE, CHOICE_FRAGGED_FREEZE, frag_attacker.netname, kill_count_to_target,
		GetResourceAmount(frag_attacker, RESOURCE_HEALTH), GetResourceAmount(frag_attacker, RESOURCE_ARMOR), (IS_BOT_CLIENT(frag_attacker) ? -1 : CS(frag_attacker).ping));

	return true;
}

void freezetag_Initialize()
{
	freezetag_teams = autocvar_g_freezetag_teams_override;
	if(freezetag_teams < 2)
		freezetag_teams = cvar("g_freezetag_teams"); // read the cvar directly as it gets written earlier in the same frame

	freezetag_teams = BITS(bound(2, freezetag_teams, 4));
	GameRules_scoring(freezetag_teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, {
		field(SP_FREEZETAG_REVIVALS, "revivals", 0);
	});

	round_handler_Spawn(freezetag_CheckTeams, freezetag_CheckWinner, func_null);
	round_handler_Init(5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);

	EliminatedPlayers_Init(freezetag_isEliminated);
}
