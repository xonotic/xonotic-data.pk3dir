#include "sv_survival.qh"

float autocvar_g_survival_hunter_count = 0.25;
float autocvar_g_survival_round_timelimit = 120;
float autocvar_g_survival_warmup = 10;
bool autocvar_g_survival_punish_teamkill = true;
bool autocvar_g_survival_reward_survival = true;
float autocvar_g_survival_round_enddelay;

entity survivalStatuses;
void SurvivalStatuses_Init();

#define STATUS_SEND_RESET   1
#define STATUS_SEND_HUNTERS 2

bool SurvivalStatuses_SendEntity(entity this, entity dest, float sendflags)
{
	Stream out = MSG_ENTITY;
	WriteHeader(out, ENT_CLIENT_SURVIVALSTATUSES);

	// always send hunters their own status and their allies
	if (dest.survival_status == SURV_STATUS_HUNTER)
		sendflags |= STATUS_SEND_HUNTERS;

	serialize(byte, out, sendflags);
	if (sendflags & STATUS_SEND_HUNTERS)
	{
		for (int i = 1; i <= maxclients; i += 8)
		{
			int f = 0;
			entity e = edict_num(i);

			for (int b = 0; b < 8; ++b, e = nextent(e))
			{
				bool is_hunter = (INGAME(e) && e.survival_status == SURV_STATUS_HUNTER);
				if (is_hunter)
					f |= BIT(b);
			}
			serialize(byte, out, f);
		}
	}
	//print(sprintf("sent flags %f to %s\n", sendflags, dest.netname));
	return true;
}

void SurvivalStatuses_Init()
{
	if(survivalStatuses)
	{
		backtrace("Can't spawn survivalStatuses again!");
		return;
	}
	Net_LinkEntity(survivalStatuses = new_pure(survivalStatuses), false, 0, SurvivalStatuses_SendEntity);
}

void Surv_UpdateScores(bool timed_out)
{
	// give players their hard-earned kills now that the round is over
	FOREACH_CLIENT(true,
	{
		it.totalfrags += it.survival_validkills;
		if(it.survival_validkills)
			GameRules_scoring_add(it, SCORE, it.survival_validkills);
		it.survival_validkills = 0;
		// player survived the round
		if(IS_PLAYER(it) && !IS_DEAD(it))
		{
			if(autocvar_g_survival_reward_survival && timed_out && it.survival_status == SURV_STATUS_PREY)
				GameRules_scoring_add(it, SCORE, 1); // reward survivors who make it to the end of the round time limit
			if(it.survival_status == SURV_STATUS_PREY)
				GameRules_scoring_add(it, SURV_SURVIVALS, 1);
			else if(it.survival_status == SURV_STATUS_HUNTER)
				GameRules_scoring_add(it, SURV_HUNTS, 1);
		}
	});
}

float Surv_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0
		&& autocvar_g_survival_round_enddelay == -1)
	{
		// if the match times out, survivors win too!
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_SURVIVOR_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_SURVIVOR_WIN);
		FOREACH_CLIENT(IS_PLAYER(it), {
			nades_RemovePlayer(it);
		});

		Surv_UpdateScores(true);

		allowed_to_spawn = false;
		game_stopped = true;
		round_handler_Init(5, autocvar_g_survival_warmup, autocvar_g_survival_round_timelimit);
		survivalStatuses.SendFlags = STATUS_SEND_HUNTERS;
		return 1;
	}

	int survivor_count = 0, hunter_count = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(it.survival_status == SURV_STATUS_PREY)
			survivor_count++;
		else if(it.survival_status == SURV_STATUS_HUNTER)
			hunter_count++;
	});
	if(survivor_count > 0 && hunter_count > 0)
	{
		// Dr. Jaska:
		// reset delay time here only for consistency
		// Survival players currently have no known ways to resurrect
		round_handler_ResetEndDelayTime();
		return 0;
	}

	// delay round ending a bit
	if (autocvar_g_survival_round_enddelay
		&& round_handler_GetEndTime() > 0
		&& round_handler_GetEndTime() - time > 0) // don't delay past timelimit
	{
		if (round_handler_GetEndDelayTime() == -1)
		{
			round_handler_SetEndDelayTime(min(time + autocvar_g_survival_round_enddelay, round_handler_GetEndTime()));
			return 0;
		}
		else if (round_handler_GetEndDelayTime() >= time)
		{
			return 0;
		}
	}

	if(hunter_count > 0) // hunters win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_HUNTER_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_HUNTER_WIN);
	}
	else if(survivor_count > 0) // survivors win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_SURVIVOR_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_SURVIVOR_WIN);
	}
	else
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	Surv_UpdateScores(false);

	allowed_to_spawn = false;
	game_stopped = true;
	round_handler_Init(5, autocvar_g_survival_warmup, autocvar_g_survival_round_timelimit);
	survivalStatuses.SendFlags = STATUS_SEND_HUNTERS;

	FOREACH_CLIENT(IS_PLAYER(it), {
		nades_RemovePlayer(it);
	});

	return 1;
}

void Surv_RoundStart()
{
	allowed_to_spawn = boolean(warmup_stage);
	int playercount = 0;
	FOREACH_CLIENT(true,
	{
		if(IS_PLAYER(it) && !IS_DEAD(it))
		{
			++playercount;
			it.survival_status = SURV_STATUS_PREY;
		}
		else
			it.survival_status = 0; // this is mostly a safety check; if a client manages to somehow maintain a survival status, clear it before the round starts!
		it.survival_validkills = 0;
	});
	int hunter_count = bound(1, ((autocvar_g_survival_hunter_count >= 1) ? autocvar_g_survival_hunter_count : floor(playercount * autocvar_g_survival_hunter_count)), playercount - 1); // 20%, but ensure at least 1 and less than total
	int total_hunters = 0;
	FOREACH_CLIENT_RANDOM(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(total_hunters >= hunter_count)
			break;
		total_hunters++;
		it.survival_status = SURV_STATUS_HUNTER;
	});
	survivalStatuses.SendFlags = STATUS_SEND_RESET;

	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(it.survival_status == SURV_STATUS_PREY)
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_SURVIVAL_SURVIVOR);
		else if(it.survival_status == SURV_STATUS_HUNTER)
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_SURVIVAL_HUNTER);
	});
}

bool Surv_CheckPlayers()
{
	static int prev_missing_players;
	allowed_to_spawn = true;
	int playercount = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		++playercount;
	});
	if (playercount >= 2)
	{
		if(prev_missing_players > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_PLAYERS);
		prev_missing_players = -1;
		return true;
	}
	if(playercount == 0)
	{
		if(prev_missing_players > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_PLAYERS);
		prev_missing_players = -1;
		return false;
	}
	// if we get here, only 1 player is missing
	if(prev_missing_players != 1)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_PLAYERS, 1);
		prev_missing_players = 1;
	}
	return false;
}

bool surv_isEliminated(entity e)
{
	if(INGAME_JOINED(e) && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
		return true;
	if(INGAME_JOINING(e))
		return true;
	return false;
}

void surv_Initialize() // run at the start of a match, initiates gametype
{
	GameRules_scoring(0, SFL_SORT_PRIO_PRIMARY, 0, {
		field(SP_SURV_SURVIVALS, "survivals", 0);
		field(SP_SURV_HUNTS, "hunts", SFL_SORT_PRIO_SECONDARY);
	});

	allowed_to_spawn = true;
	round_handler_Spawn(Surv_CheckPlayers, Surv_CheckWinner, Surv_RoundStart);
	round_handler_Init(5, autocvar_g_survival_warmup, autocvar_g_survival_round_timelimit);
	EliminatedPlayers_Init(surv_isEliminated);
	SurvivalStatuses_Init();
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(surv, ClientObituary)
{
	// in survival, announcing a frag would tell everyone who the hunter is
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if(IS_PLAYER(frag_attacker) && frag_attacker != frag_target)
	{
		float frag_deathtype = M_ARGV(3, float);
		entity wep_ent = M_ARGV(4, entity);
		// "team" kill, a point is awarded to the player by default so we must take it away plus an extra one
		// unless the player is going to be punished for suicide, in which case just remove one
		if(frag_attacker.survival_status == frag_target.survival_status)
			GiveFrags(frag_attacker, frag_target, ((autocvar_g_survival_punish_teamkill) ? -1 : -2), frag_deathtype, wep_ent.weaponentity_fld);
	}

	if(frag_attacker.survival_status == SURV_STATUS_HUNTER)
		M_ARGV(5, bool) = true; // anonymous attacker
}

MUTATOR_HOOKFUNCTION(surv, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.survival_status = 0;
	player.survival_validkills = 0;
	INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
}

MUTATOR_HOOKFUNCTION(surv, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	// spectators / observers that weren't playing can join; they are
	// immediately forced to observe in the PutClientInServer hook
	// this way they are put in a team and can play in the next round
	if (!allowed_to_spawn && INGAME(player))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(surv, PutClientInServer)
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

	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
}

MUTATOR_HOOKFUNCTION(surv, reset_map_players)
{
	FOREACH_CLIENT(true, {
		CS(it).killcount = 0;
		it.survival_status = 0;
		if (INGAME(it) || IS_BOT_CLIENT(it))
		{
			TRANSMUTE(Player, it);
			INGAME_STATUS_SET(it, INGAME_STATUS_JOINED);
			PutClientInServer(it);
		}
	});
	bot_relinkplayerlist();
	survivalStatuses.SendFlags = STATUS_SEND_RESET;
	return true;
}

MUTATOR_HOOKFUNCTION(surv, reset_map_global)
{
	allowed_to_spawn = true;
	return true;
}

MUTATOR_HOOKFUNCTION(surv, MatchEnd_BeforeScores)
{
	MatchEnd_RestoreSpectatorStatus();
	return true;
}

entity surv_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
		if (!IS_DEAD(it) && this.survival_status == it.survival_status)
		{
			if (!last_pl)
				last_pl = it;
			else
				return NULL;
		}
	});
	return last_pl;
}

void surv_LastPlayerForTeam_Notify(entity this)
{
	if (!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
	{
		entity pl = surv_LastPlayerForTeam(this);
		if (pl)
			Send_Notification(NOTIF_ONE_ONLY, pl, MSG_CENTER, CENTER_ALONE);
	}
}

MUTATOR_HOOKFUNCTION(surv, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	surv_LastPlayerForTeam_Notify(frag_target);
	if (!allowed_to_spawn)
	{
		frag_target.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time + 2;
	}
	frag_target.respawn_flags |= RESPAWN_FORCE;
	if (!warmup_stage)
	{
		eliminatedPlayers.SendFlags |= 1;
		if (IS_BOT_CLIENT(frag_target))
			bot_clearqueue(frag_target);
	}

	// killed an ally! punishment is death
	if(autocvar_g_survival_punish_teamkill && frag_attacker != frag_target && IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target) && frag_attacker.survival_status == frag_target.survival_status && !ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted()) // don't autokill if the round hasn't started yet
		Damage(frag_attacker, frag_attacker, frag_attacker, 100000, DEATH_MIRRORDAMAGE.m_id, DMG_NOWEP, frag_attacker.origin, '0 0 0');
	return true;
}

MUTATOR_HOOKFUNCTION(surv, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		surv_LastPlayerForTeam_Notify(player);
	return true;
}

MUTATOR_HOOKFUNCTION(surv, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);
	bool is_forced = M_ARGV(1, bool);
	if (is_forced && INGAME(player))
		INGAME_STATUS_CLEAR(player);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		surv_LastPlayerForTeam_Notify(player);
	if (player.killindicator_teamchange == -2) // player wants to spectate
		INGAME_STATUS_CLEAR(player);
	if (INGAME(player))
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	if (!INGAME(player))
	{
		player.survival_validkills = 0;
		player.survival_status = 0;
		return false;  // allow team reset
	}
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(surv, Scores_CountFragsRemaining)
{
	// announce remaining frags?
	return true;
}

MUTATOR_HOOKFUNCTION(surv, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	if(!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
		frag_attacker.survival_validkills += M_ARGV(2, float);
	M_ARGV(2, float) = 0; // score will be given to the winner when the round ends
	return true;
}

MUTATOR_HOOKFUNCTION(surv, AddPlayerScore)
{
	entity scorefield = M_ARGV(0, entity);
	if(scorefield == SP_KILLS || scorefield == SP_DEATHS || scorefield == SP_SUICIDES || scorefield == SP_DMG || scorefield == SP_DMGTAKEN)
		M_ARGV(1, float) = 0; // don't report that the player has killed or been killed, that would out them as a hunter!
}

MUTATOR_HOOKFUNCTION(surv, CalculateRespawnTime)
{
	// no respawn calculations needed, player is forced to spectate anyway
	return true;
}

MUTATOR_HOOKFUNCTION(surv, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || INGAME_JOINED(it))
			++M_ARGV(0, int);
		++M_ARGV(1, int);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(surv, ClientCommand_Spectate)
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

MUTATOR_HOOKFUNCTION(surv, BotShouldAttack)
{
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	if(targ.survival_status == bot.survival_status)
		return true;
}
