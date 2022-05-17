#include "sv_clanarena.qh"

float autocvar_g_ca_damage2score = 100;
bool autocvar_g_ca_spectate_enemies;

float autocvar_g_ca_start_health = 200;
float autocvar_g_ca_start_armor = 200;
float autocvar_g_ca_start_ammo_shells = 60;
float autocvar_g_ca_start_ammo_nails = 320;
float autocvar_g_ca_start_ammo_rockets = 160;
float autocvar_g_ca_start_ammo_cells = 180;
float autocvar_g_ca_start_ammo_plasma = 180;
float autocvar_g_ca_start_ammo_fuel = 0;

.float ca_damage_counter;

void CA_count_alive_players()
{
	total_players = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		Team_SetNumberOfAlivePlayers(Team_GetTeamFromIndex(i), 0);
	}
	FOREACH_CLIENT(IS_PLAYER(it) && Entity_HasValidTeam(it),
	{
		++total_players;
		if (IS_DEAD(it))
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
		STAT(REDALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1));
		STAT(BLUEALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2));
		STAT(YELLOWALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(3));
		STAT(PINKALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(4));
	});
}

void nades_Clear(entity player);

float CA_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);
		FOREACH_CLIENT(IS_PLAYER(it), { nades_Clear(it); });

		allowed_to_spawn = false;
		game_stopped = true;
		round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);
		return 1;
	}

	CA_count_alive_players();
	int winner_team = Team_GetWinnerAliveTeam();
	if (!winner_team)
		return 0;

	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		TeamScore_AddToTeam(winner_team, ST_CA_ROUNDS, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	allowed_to_spawn = false;
	game_stopped = true;
	round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

	FOREACH_CLIENT(IS_PLAYER(it), { nades_Clear(it); });

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
	if (Team_GetNumberOfAliveTeams() == NumTeams(ca_teams))
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
		if ((ca_teams & Team_IndexToBit(i)) &&
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

bool ca_isEliminated(entity e)
{
	if(INGAME_JOINED(e) && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
		return true;
	if(INGAME_JOINING(e))
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
	// restart from the beginning
	for (entity e = NULL; (e = find(e, classname, STR_PLAYER)); )
	{
		if (SAME_TEAM(player, e)) return e;
	}
	return start;
}


MUTATOR_HOOKFUNCTION(ca, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
	if (time <= game_starttime) // reset on game restart, not on round start
		player.ca_damage_counter = 0;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
}

MUTATOR_HOOKFUNCTION(ca, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	// spectators / observers that weren't playing can join; they are
	// immediately forced to observe in the PutClientInServer hook
	// this way they are put in a team and can play in the next round
	if (!allowed_to_spawn && INGAME(player))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if (!allowed_to_spawn && IS_PLAYER(player)) // this is true even when player is trying to join
	{
		TRANSMUTE(Observer, player);
		if (CS(player).jointime != time && !INGAME(player)) // not when connecting
		{
			INGAME_STATUS_SET(player, INGAME_STATUS_JOINING);
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}
}

MUTATOR_HOOKFUNCTION(ca, reset_map_players)
{
	FOREACH_CLIENT(true, {
		CS(it).killcount = 0;
		if (INGAME(it) || IS_BOT_CLIENT(it))
		{
			TRANSMUTE(Player, it);
			INGAME_STATUS_SET(it, INGAME_STATUS_JOINED);
			PutClientInServer(it);
		}
	});
	return true;
}

MUTATOR_HOOKFUNCTION(ca, reset_map_global)
{
	allowed_to_spawn = true;
	return true;
}

MUTATOR_HOOKFUNCTION(ca, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = ca_teams;
	return true;
}

entity ca_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
		if (!IS_DEAD(it) && SAME_TEAM(this, it))
		{
			if (!last_pl)
				last_pl = it;
			else
				return NULL;
		}
	});
	return last_pl;
}

void ca_LastPlayerForTeam_Notify(entity this)
{
	if (!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
	{
		entity pl = ca_LastPlayerForTeam(this);
		if (pl)
			Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_ALONE);
	}
}

MUTATOR_HOOKFUNCTION(ca, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	ca_LastPlayerForTeam_Notify(frag_target);
	if (!allowed_to_spawn)
	{
		frag_target.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time + 2;
	}
	frag_target.respawn_flags |= RESPAWN_FORCE;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return true;
}


MUTATOR_HOOKFUNCTION(ca, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		ca_LastPlayerForTeam_Notify(player);
	return true;
}

MUTATOR_HOOKFUNCTION(ca, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	bool is_forced = M_ARGV(1, bool);
	if (is_forced && INGAME(player))
		INGAME_STATUS_CLEAR(player);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		ca_LastPlayerForTeam_Notify(player);
	if (player.killindicator_teamchange == -2) // player wants to spectate
	{
		entcs_update_players(player);
		INGAME_STATUS_CLEAR(player);
	}
	if (INGAME(player))
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	if (!INGAME(player))
		return false;  // allow team reset
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(ca, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ca, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 0; // score will be given to the winner team when the round ends
	return true;
}

MUTATOR_HOOKFUNCTION(ca, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if(!cvar("g_use_ammunition"))
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = autocvar_g_ca_start_health;
	start_armorvalue   = warmup_start_armorvalue   = autocvar_g_ca_start_armor;
	start_ammo_shells  = warmup_start_ammo_shells  = autocvar_g_ca_start_ammo_shells;
	start_ammo_nails   = warmup_start_ammo_nails   = autocvar_g_ca_start_ammo_nails;
	start_ammo_rockets = warmup_start_ammo_rockets = autocvar_g_ca_start_ammo_rockets;
	start_ammo_cells   = warmup_start_ammo_cells   = autocvar_g_ca_start_ammo_cells;
	start_ammo_plasma  = warmup_start_ammo_plasma  = autocvar_g_ca_start_ammo_plasma;
	start_ammo_fuel    = warmup_start_ammo_fuel    = autocvar_g_ca_start_ammo_fuel;
}

MUTATOR_HOOKFUNCTION(ca, Damage_Calculate)
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

MUTATOR_HOOKFUNCTION(ca, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (autocvar_g_powerups <= 0)
	if (item.itemdef.instanceOfPowerup)
		return true;

	if (autocvar_g_pickup_items <= 0)
		return true;
}

MUTATOR_HOOKFUNCTION(ca, PlayerDamage_SplitHealthArmor)
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

	if (autocvar_g_ca_damage2score <= 0 || frag_damage - excess == 0) return;

	entity scorer = NULL;
	float scorer_damage = 0;

	if (IS_PLAYER(frag_attacker))
	{
		if (DIFF_TEAM(frag_target, frag_attacker))
			scorer_damage = frag_damage - excess;
		else // friendly fire
			scorer_damage = -(frag_damage - excess);

		scorer = frag_attacker;
	}
	else
	{
		//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
		//deathtypes:
		//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
		//camp = campcheck, lava = lava, slime = slime
		//team change / rebalance suicides are currently not included
		if (frag_deathtype == DEATH_KILL.m_id ||
			frag_deathtype == DEATH_DROWN.m_id ||
			frag_deathtype == DEATH_HURTTRIGGER.m_id ||
			frag_deathtype == DEATH_CAMP.m_id ||
			frag_deathtype == DEATH_LAVA.m_id ||
			frag_deathtype == DEATH_SLIME.m_id ||
			frag_deathtype == DEATH_SWAMP.m_id)
		{
			scorer_damage = -(frag_damage - excess);
			scorer = frag_target;
		}
	}

	if (scorer)
		GameRules_scoring_add_float2int(scorer, SCORE, scorer_damage, ca_damage_counter, autocvar_g_ca_damage2score);
}

MUTATOR_HOOKFUNCTION(ca, CalculateRespawnTime)
{
	// no respawn calculations needed, player is forced to spectate anyway
	return true;
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
	entity client = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	if (!autocvar_g_ca_spectate_enemies && INGAME(client))
	if (DIFF_TEAM(targ, client))
		return true;
}

MUTATOR_HOOKFUNCTION(ca, SpectateNext)
{
	entity client = M_ARGV(0, entity);

	if (!autocvar_g_ca_spectate_enemies && INGAME(client)
		&& Team_GetNumberOfAlivePlayers(Entity_GetTeam(client)))
	{
		entity targ = M_ARGV(1, entity);
		M_ARGV(1, entity) = CA_SpectateNext(client, targ);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ca, SpectatePrev)
{
	entity client = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);
	entity first = M_ARGV(2, entity);

	if (!autocvar_g_ca_spectate_enemies && INGAME(client)
		&& Team_GetNumberOfAlivePlayers(Entity_GetTeam(client)))
	{
		do { targ = targ.chain; }
		while(targ && DIFF_TEAM(targ, client));

		if (!targ)
		{
			for (targ = first; targ && DIFF_TEAM(targ, client); targ = targ.chain);

			if (targ == client.enemy)
				return MUT_SPECPREV_RETURN;
		}
	}
	else
		return MUT_SPECPREV_CONTINUE;

	M_ARGV(1, entity) = targ;

	return MUT_SPECPREV_FOUND;
}

MUTATOR_HOOKFUNCTION(ca, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || INGAME_JOINED(it))
			++M_ARGV(0, int);
		++M_ARGV(1, int);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(ca, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if (INGAME(player))
	{
		// they're going to spec, we can do other checks
		if (autocvar_sv_spectate && (IS_SPEC(player) || IS_OBSERVER(player)))
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(ca, HideTeamNagger)
{
	return true; // doesn't work well with the whole spectator as player thing
}

MUTATOR_HOOKFUNCTION(ca, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_ca_weaponarena;
}

MUTATOR_HOOKFUNCTION(ca, SV_ParseServerCommand)
{
	string cmd_name = M_ARGV(0, string);
	if (cmd_name == "shuffleteams")
		shuffleteams_on_reset_map = !allowed_to_spawn;
	return false;
}
