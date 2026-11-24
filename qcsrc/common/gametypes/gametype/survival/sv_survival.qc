#include "sv_survival.qh"

#include <common/gametypes/elimination.qh>
#include <server/chat.qh>

int autocvar_g_survival_hide_chat = 0;
bool autocvar_g_survival_permanent_corpses;
bool autocvar_g_survival_detective_reveal_fragger = true;
float autocvar_g_survival_detective_count = 0.095;
float autocvar_g_survival_hunter_count = 0.25;
float autocvar_g_survival_round_timelimit = 120;
bool autocvar_g_survival_round_timelimit_fragreset = false;
float autocvar_g_survival_warmup = 10;
bool autocvar_g_survival_punish_teamkill = true;
bool autocvar_g_survival_reward_survival = true;
float autocvar_g_survival_round_enddelay;

int surv_state; // required for connecting clients
enum
{
	SURV_STATE_PLAYING, SURV_STATE_REVEAL, SURV_STATE_RESET
};

/// Sends a bitset describing all players with role `role`
void SurvRoles_SendEntity_RoleBitset(int role)
{
	for (int b, B, i = 1; i <= maxclients; )
	{
		B = 0;
		for (b = BIT(0); b < BIT(8) && i <= maxclients; b <<= 1, ++i)
			if (INGAME(edict_num(i)) && edict_num(i).survival_role == role)
				B |= b; // they have the role
		WriteByte(MSG_ENTITY, B);
	}
}

bool SurvRoles_SendEntity(entity this, entity to, int sf)
{
	if (sf == 0xFFFFFF) // set by the engine, need to fix this
		switch (surv_state)
		{
			default:
			case SURV_STATE_PLAYING:  sf = SF_SURV_START;   break;
			case SURV_STATE_REVEAL:   sf = SF_SURV_REVEAL;  break;
			case SURV_STATE_RESET:    sf = SF_SURV_RESET;   break;
		}

	if ((sf & SF_SURV_REVEAL) // to reveal we must send everyone the Hunters
	|| (!(sf & SF_SURV_RESET) && (to.survival_role == SURV_ROLE_HUNTER || !INGAME(to)))) // send Hunters and specs/observers the Hunters
		sf |= SF_SURV_HUNTERS;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_SURV_ROLES);
	WriteByte(MSG_ENTITY, sf);
	if (sf & SF_SURV_START)   // send Detectives, in a bitset
		SurvRoles_SendEntity_RoleBitset(SURV_ROLE_DETECTIVE);
	if (sf & SF_SURV_HUNTERS) // send Hunters, in a bitset
		SurvRoles_SendEntity_RoleBitset(SURV_ROLE_HUNTER);
	return true;
}

entity survRoles;
void SurvRoles_Init()
{
	if (survRoles)
	{
		backtrace("Can't spawn survRoles again!");
		return;
	}
	Net_LinkEntity(survRoles = new_pure(survRoles), false, 0, SurvRoles_SendEntity);
}

bool surv_IsAlivePlayer(entity e)
{
	return IS_PLAYER(e) && !IS_DEAD(e);
}

/// Give players their hard-earned kills now that the round is over
void Surv_UpdateScores(bool timed_out)
{
	FOREACH_CLIENT(true,
	{
		it.totalfrags += it.survival_validkills;
		if (it.survival_validkills)
			GameRules_scoring_add(it, SCORE, it.survival_validkills);
		it.survival_validkills = 0;

		if (!surv_IsAlivePlayer(it))
			continue;

		// player survived the round
		switch (it.survival_role)
		{
			case SURV_ROLE_SURVIVOR:
			case SURV_ROLE_DETECTIVE:
				GameRules_scoring_add(it, SURV_SURVIVALS, 1);
				if (autocvar_g_survival_reward_survival)
					GameRules_scoring_add(it, SCORE, 1); // reward survivors who survived the round
				break;
			case SURV_ROLE_HUNTER:
				GameRules_scoring_add(it, SURV_HUNTS, 1);
				if (!timed_out)
					GameRules_scoring_add(it, SCORE, 1); // reward hunters who survived the round (more than hunters who died)
				break;
			default:
				break;
		}
	});
}

bool Surv_CheckWinner()
{
	if (round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0
	&& round_handler_GetEndDelayTime() == -1)
	{
		// if the match times out, survivors win too!
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_SURVIVOR_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_SURVIVOR_WIN);
		FOREACH_CLIENT(IS_PLAYER(it), nades_RemovePlayer(it));

		Surv_UpdateScores(true);

		allowed_to_spawn = false;
		game_stopped = true;
		round_handler_Init(5, autocvar_g_survival_warmup, autocvar_g_survival_round_timelimit);
		surv_state = SURV_STATE_REVEAL;
		survRoles.SendFlags |= SF_SURV_REVEAL;
		return true;
	}

	int survivor_count = 0, hunter_count = 0;
	FOREACH_CLIENT(surv_IsAlivePlayer(it),
		switch (it.survival_role)
		{
			case SURV_ROLE_SURVIVOR:
			case SURV_ROLE_DETECTIVE:
				++survivor_count;
				break;
			case SURV_ROLE_HUNTER:
				++hunter_count;
				break;
			default:
				break;
		});
	if (survivor_count > 0 && hunter_count > 0)
	{
		// Dr. Jaska:
		// reset delay time here only for consistency
		// Survival players currently have no known ways to resurrect
		round_handler_ResetEndDelayTime();
		return false;
	}

	// delay round ending a bit
	if (round_handler_DelayRoundEnd(autocvar_g_survival_round_enddelay))
		return false;

	if (hunter_count > 0) // hunters win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_HUNTER_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_HUNTER_WIN);
	}
	else if (survivor_count > 0) // survivors win
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
	surv_state = SURV_STATE_REVEAL;
	survRoles.SendFlags |= SF_SURV_REVEAL;

	FOREACH_CLIENT(IS_PLAYER(it), nades_RemovePlayer(it));

	return true;
}

void Surv_RoundStart()
{
	allowed_to_spawn = boolean(warmup_stage);
	// First set everyone to Survivor
	int playercount = 0;
	FOREACH_CLIENT(true,
	{
		if (surv_IsAlivePlayer(it))
		{
			++playercount;
			it.survival_role = SURV_ROLE_SURVIVOR;
		}
		else
			it.survival_role = SURV_ROLE_NONE; // this is mostly a safety check; if a client manages to somehow maintain a survival role, clear it before the round starts!
		it.survival_validkills = 0;
	});

	// Choose role counts
	// Must be at least 2 Survivors (if there's >2 players) or else they know everyone else is a Hunter
	int hunter_count = (autocvar_g_survival_hunter_count >= 1)
		? autocvar_g_survival_hunter_count                      // absolute
		: rint(playercount * autocvar_g_survival_hunter_count); // proportion, rounded
	hunter_count = bound(1, hunter_count, playercount - 1);
	int detective_count;
	if (autocvar_g_survival_permanent_corpses)
	{
		detective_count = (autocvar_g_survival_detective_count >= 1 || autocvar_g_survival_detective_count <= 0)
			? autocvar_g_survival_detective_count                      // absolute
			: rint(playercount * autocvar_g_survival_detective_count); // proportion, rounded
		if (hunter_count + detective_count >= playercount - 1)
			detective_count = max(0, playercount - hunter_count - 2);
	}
	else
		detective_count = 0; // corpses need to be permanent for Detectives to use them
	// Might not be able to spawn `detective_count` Detectives, if `hunter_count` is high; Hunters take priority over Detectives
	int total_hunters    = 0;
	int total_detectives = 0;
	FOREACH_CLIENT_RANDOM(it.survival_role != SURV_ROLE_NONE,
	{
		if (total_hunters < hunter_count)
		{
			++total_hunters;
			it.survival_role = SURV_ROLE_HUNTER;
		}
		else if (total_detectives < detective_count)
		{
			++total_detectives;
			it.survival_role = SURV_ROLE_DETECTIVE;
		}
		else
			break;
	});

	surv_state = SURV_STATE_PLAYING;
	survRoles.SendFlags |= SF_SURV_START;

	Notification notif;
	FOREACH_CLIENT(it.survival_role != SURV_ROLE_NONE,
	{
		switch (it.survival_role)
		{
			case SURV_ROLE_SURVIVOR:   notif = CENTER_SURVIVAL_SURVIVOR;   break;
			case SURV_ROLE_DETECTIVE:  notif = CENTER_SURVIVAL_DETECTIVE;  break;
			case SURV_ROLE_HUNTER:     notif = CENTER_SURVIVAL_HUNTER;     break;
			default:                   notif = NULL;                       break;
		}
		if (notif)
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, notif);
	});
}

bool Surv_CheckPlayers()
{
	static int prev_missing_players;
	allowed_to_spawn = true;
	int playercount = 0;
	FOREACH_CLIENT(surv_IsAlivePlayer(it), ++playercount);
	// NOTE missing_teams_mask stat is used for missing players in ffa games
	if (playercount >= 2)
	{
		if (prev_missing_players > 0)
			missing_teams_mask = 0;
		prev_missing_players = -1;
		return true;
	}
	if (playercount == 0)
	{
		if (prev_missing_players > 0)
			missing_teams_mask = 0;
		prev_missing_players = -1;
		return false;
	}
	// if we get here, only 1 player is missing
	if (prev_missing_players != 1)
	{
		missing_teams_mask = 1;
		prev_missing_players = 1;
	}
	return false;
}

bool surv_isEliminated(entity e)
{
	if (INGAME_JOINED(e) && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
		return true;
	if (INGAME_JOINING(e))
		return true;
	return false;
}

/// Returns true if this is the last player on their 'team'
bool surv_IsLastOfTeam(entity this)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it != this && !surv_isEliminated(it),
	{
		if (SURV_SAMETEAM(it, this))
			return false;
	});
	return true;
}

void surv_Initialize() // run at the start of a match, initiates gametype
{
	GameRules_scoring(0, SFL_SORT_PRIO_PRIMARY, 0,
	{
		field(SP_SURV_SURVIVALS, "survivals", 0);
		field(SP_SURV_HUNTS, "hunts", SFL_SORT_PRIO_SECONDARY);
	});

	allowed_to_spawn = true;
	surv_state = SURV_STATE_RESET;
	round_handler_Spawn(Surv_CheckPlayers, Surv_CheckWinner, Surv_RoundStart);
	round_handler_Init(5, autocvar_g_survival_warmup, autocvar_g_survival_round_timelimit);
	EliminatedPlayers_Init(surv_isEliminated);
	SurvRoles_Init();
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(surv, ClientObituary)
{
	// In survival, announcing a frag would tell everyone who the Hunter is
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if (IS_PLAYER(frag_attacker) && frag_attacker != frag_target)
	{
		float frag_deathtype = M_ARGV(3, float);
		entity wep_ent = M_ARGV(4, entity);
		// "team" kill, a point is awarded to the player by default so we must take it away plus an extra one
		// unless the player is going to be punished for suicide, in which case just remove one
		if (SURV_SAMETEAM(frag_attacker, frag_target))
			GiveFrags(frag_attacker, frag_target, (autocvar_g_survival_punish_teamkill ? -1 : -2), frag_deathtype, wep_ent.weaponentity_fld);
	}

	if (SURV_SAMETEAM(frag_attacker, frag_target))
		// Can't make things anonymous if teamkills are punished
		M_ARGV(5, bool) = !autocvar_g_survival_punish_teamkill;
	else
		// Attacker anonymous, unless they killed the last member of the opposite team
		M_ARGV(5, bool) = !surv_IsLastOfTeam(frag_target);
}

MUTATOR_HOOKFUNCTION(surv, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.survival_role = SURV_ROLE_NONE;
	player.survival_validkills = 0;
	INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= SF_ELIMPLAYERS_ELIMS;
}

MUTATOR_HOOKFUNCTION(surv, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	// spectators / observers that weren't playing can join; they are
	// immediately forced to observe in the PutClientInServer hook
	// this way they are put in a team and can play in the next round
	return (!allowed_to_spawn && INGAME(player));
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
}

.float surv_antispam; ///< Last time a player investigated a corpse
MUTATOR_HOOKFUNCTION(surv, reset_map_players)
{
	FOREACH_CLIENT(true,
	{
		CS(it).killcount = 0;
		it.survival_role = SURV_ROLE_NONE;
		it.surv_antispam = 0;
		if (INGAME(it) || IS_BOT_CLIENT(it))
		{
			TRANSMUTE(Player, it);
			INGAME_STATUS_SET(it, INGAME_STATUS_JOINED);
			PutClientInServer(it);
		}
	});
	bot_relinkplayerlist();
	surv_state = SURV_STATE_RESET;
	survRoles.SendFlags |= SF_SURV_RESET;
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

// NOTE: if there's 2+ Hunters, this'll tell Survivors/Detectives they're both still alive, instead of leaving it ambiguous whether any had been killed yet
void surv_NotifyLastPlayerOnTeam(entity this)
{
	if (warmup_stage || !round_handler_IsActive() || !round_handler_IsRoundStarted())
		return;

	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this,
	{
		if (!IS_DEAD(it) && SURV_SAMETEAM(it, this))
		{
			if (!last_pl)
				last_pl = it;
			else
				return;
		}
	});
	if (last_pl)
		Send_Notification(NOTIF_ONE_ONLY, last_pl, MSG_CENTER, CENTER_ALONE);
}

MUTATOR_HOOKFUNCTION(surv, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	surv_NotifyLastPlayerOnTeam(frag_target);
	if (!allowed_to_spawn)
	{
		frag_target.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time + 2;
	}
	frag_target.respawn_flags |= RESPAWN_FORCE;
	if (!warmup_stage)
	{
		eliminatedPlayers.SendFlags |= SF_ELIMPLAYERS_ELIMS;
		if (IS_BOT_CLIENT(frag_target))
			bot_clearqueue(frag_target);
	}

	// killed an ally! punishment is death
	if (autocvar_g_survival_punish_teamkill
	&& frag_attacker != frag_target
	&& surv_IsAlivePlayer(frag_attacker)
	&& IS_PLAYER(frag_target)
	&& SURV_SAMETEAM(frag_attacker, frag_target)
	&& !warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted()) // don't autokill if the round hasn't started yet
		Damage(frag_attacker, frag_attacker, frag_attacker, 100000, DEATH_MIRRORDAMAGE.m_id, DMG_NOWEP, frag_attacker.origin, '0 0 0');
	return true;
}

.string fraggedby; ///< .netname of the player who fragged me
void surv_PlayerCorpseDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	// Allow detectives to find out info about corpses once they become cloned
	// Only after cloning, so the info isn't send immediately after a frag
	if (!surv_IsAlivePlayer(attacker) || attacker.survival_role != SURV_ROLE_DETECTIVE || time < attacker.surv_antispam)
		return;
	attacker.surv_antispam = time + 0.5;

	// FIXME: these strings will be translated using the server's language rather than the client.
	// If they were individual notifications, there'd be 12, with repeated text
	string str;
	switch (this.survival_role)
	{
		case SURV_ROLE_HUNTER:     str = _("^BG%s^BG was a ^xF11hunter^BG!");          break;
		case SURV_ROLE_SURVIVOR:   str = _("^BG%s^BG was a ^x1F1survivor^BG!");        break;
		case SURV_ROLE_DETECTIVE:  str = _("^BG%s^BG was also a ^x18Fdetective^BG!");  break;
		default:
			return;
	}
	str = sprintf(str, this.netname);
	if (autocvar_g_survival_detective_reveal_fragger && this.fraggedby != "")
		str = sprintf(_("%s %s"), str, sprintf(_("They were eliminated by %s"), this.fraggedby));
	str = CCR(str);

	Send_Notification(NOTIF_ONE_ONLY, attacker, MSG_CENTER, CENTER_SURVIVAL_INVESTIGATE, str);
	FOREACH_CLIENT(IS_SPEC(it) && it.enemy == attacker, // also send the notif to specs watching
		Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_SURVIVAL_INVESTIGATE, str));

	// Color the corpse in CSQC
	if (this.survival_role == SURV_ROLE_DETECTIVE) // corpse is already colored
		return;
	msg_entity = attacker;
	WriteHeader(MSG_ONE, CLIENT_SURV_INVESTIGATION);
	WriteByte(MSG_ONE, this.sv_entnum);
	WriteByte(MSG_ONE, this.survival_role);
	// Don't need to send this to specs since they know everyone's role
}

MUTATOR_HOOKFUNCTION(surv, PlayerDied)
{
	// It's now a corpse
	if (autocvar_g_survival_permanent_corpses)
	{
		entity player = M_ARGV(0, entity);
		entity attacker = M_ARGV(1, entity);
		player.fraggedby = attacker.netname;
		// Make it undestroyable
		if (player.damagedbycontents)
			IL_REMOVE(g_damagedbycontents, player);
		player.damagedbycontents = false;
		player.takedamage = DAMAGE_NO;
		player.event_damage = func_null;
		player.event_heal = func_null;
		// Make it immovable (except inertia) so it stays near the crime scene
		player.damageforcescale = 0;
	}

	// Reset the timer with each death if g_survival_round_timelimit_fragreset is enabled
	if (warmup_stage || !round_handler_IsActive() || !round_handler_IsRoundStarted()
	|| !autocvar_g_survival_round_timelimit_fragreset)
		return;

	bool survivors = false, hunters = false;
	FOREACH_CLIENT(surv_IsAlivePlayer(it),
		switch (it.survival_role)
		{
			case SURV_ROLE_SURVIVOR:
			case SURV_ROLE_DETECTIVE:
				survivors = true;
				break;
			case SURV_ROLE_HUNTER:
				hunters = true;
				break;
			default:
				break;
		});

	if (survivors && hunters) // this wasn't the final kill, so reset the timer
		round_handler_SetEndTime(autocvar_g_survival_round_timelimit);
}

MUTATOR_HOOKFUNCTION(surv, PreventGib)
{
	// Keep all corpses
	return (autocvar_g_survival_permanent_corpses
		&& !warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted());
}

MUTATOR_HOOKFUNCTION(surv, CopyBody)
{
	if (!autocvar_g_survival_permanent_corpses
	|| warmup_stage || !round_handler_IsActive() || !round_handler_IsRoundStarted())
		return false;

	entity player = M_ARGV(0, entity);
	if (!IS_DEAD(player))
		return false;

	// Make cloned corpses stay for the rest of the round
	entity clone = M_ARGV(1, entity);
	clone.netname = player.netname;
	clone.survival_role = player.survival_role;
	clone.fraggedby = player.fraggedby;
	clone.event_damage = surv_PlayerCorpseDamage;
	clone.CopyBody_nextthink = 0; // don't run the fade out think
	set_movetype(clone, MOVETYPE_NONE);
	clone.takedamage = DAMAGE_AIM;
	clone.solid = SOLID_CORPSE;
	setorigin(clone, clone.origin); // make it shootable
	return false;
}

MUTATOR_HOOKFUNCTION(surv, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if (surv_IsAlivePlayer(player))
		surv_NotifyLastPlayerOnTeam(player);
	return true;
}

MUTATOR_HOOKFUNCTION(surv, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);
	bool is_forced = M_ARGV(1, bool);
	if (is_forced && INGAME(player))
		INGAME_STATUS_CLEAR(player);

	if (surv_IsAlivePlayer(player))
		surv_NotifyLastPlayerOnTeam(player);
	if (player.killindicator_teamchange == -2) // player wants to spectate
		INGAME_STATUS_CLEAR(player);
	if (INGAME(player))
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= SF_ELIMPLAYERS_ELIMS;
	if (!INGAME(player))
	{
		player.survival_validkills = 0;
		player.survival_role = SURV_ROLE_NONE;
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
	if (!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
		frag_attacker.survival_validkills += M_ARGV(2, float);
	M_ARGV(2, float) = 0; // score will be given to the winner when the round ends
	return true;
}

MUTATOR_HOOKFUNCTION(surv, AddPlayerScore)
{
	entity scorefield = M_ARGV(0, entity);
	if (scorefield == SP_KILLS
	||  scorefield == SP_DEATHS
	||  scorefield == SP_SUICIDES
	||  scorefield == SP_DMG
	||  scorefield == SP_DMGTAKEN)
		M_ARGV(1, float) = 0; // don't report that the player has killed or been killed, that would out them as a hunter!
}

MUTATOR_HOOKFUNCTION(surv, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
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

MUTATOR_HOOKFUNCTION(surv, Bot_ForbidAttack)
{
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	if (SURV_SAMETEAM(targ, bot))
		return true;
}

bool surv_ChatRestricted()
{
	// chat is only restricted while a round is actually being played
	return (autocvar_g_survival_hide_chat
		&& !warmup_stage && !game_stopped && surv_state == SURV_STATE_PLAYING);
}

MUTATOR_HOOKFUNCTION(surv, ChatMessage)
{
	if (!surv_ChatRestricted())
		return false;

	entity sender = M_ARGV(0, entity);
	int ret = M_ARGV(1, int);
	string message = M_ARGV(2, string);
	entity privatesay = M_ARGV(3, entity);

	// ret <= 0 means it was already rejected or the sender is muted
	if (ret <= 0 || message == "")
		return false;

	// can privately message specs
	if (privatesay != NULL && !(surv_IsAlivePlayer(privatesay) && INGAME(privatesay)))
		return false;

	if (autocvar_g_survival_hide_chat >= 2)
		Send_Notification(NOTIF_ONE_ONLY, sender, MSG_INFO, INFO_SURVIVAL_CHAT_HIDDEN);

	return false;
}

MUTATOR_HOOKFUNCTION(surv, ChatMessageTo)
{
	if (!surv_ChatRestricted())
		return false;

	entity dest = M_ARGV(0, entity);
	entity sender = M_ARGV(1, entity);

	// if both players are alive, hide the message from the dest
	return (surv_IsAlivePlayer(dest) && INGAME(dest) && surv_IsAlivePlayer(sender) && INGAME(sender));
}
