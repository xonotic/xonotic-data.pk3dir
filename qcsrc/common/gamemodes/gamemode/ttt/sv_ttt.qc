#include "sv_ttt.qh"

//set g_ttt_detective_count 0.125 "number of players who will become detectives, set between 0 and 0.9 to use a multiplier of the current players, or 1 and above to specify an exact number of players"
//float autocvar_g_ttt_detective_count = 0.125; //I don't think that it won't be used...
float autocvar_g_ttt_innocent_count = 0.625;
float autocvar_g_ttt_traitor_count = 0.25;
float autocvar_g_ttt_round_timelimit = 180;
float autocvar_g_ttt_warmup = 10;
bool autocvar_g_ttt_punish_teamkill = false;
bool autocvar_g_ttt_reward_innocent = true;
float autocvar_g_ttt_max_karma_points = 1000; //LegendGuard sets Karma points 21-02-2021
float autocvar_g_ttt_min_karma_points = 400;

// 27-02-2021
//Ideas: skills/items per each player-type: (these skills/items should be used once)
// Innocents: Shield and Strength; Traitors: Shield and Strength; Detectives: skill to detect any player to see what player-type is

//TODO: Add force to spec, kick and ban for low karma points 27-02-2021

// Detective is a created team, this team is added inside Innocents team

//TODO: 
// detective shouldn't be attacked by innocent bots.
// detective should detect the point of the corpses (new function).

void ttt_FakeTimeLimit(entity e, float t)
{
	if(!IS_REAL_CLIENT(e))
		return;
#if 0
	msg_entity = e;
	WriteByte(MSG_ONE, 3); // svc_updatestat
	WriteByte(MSG_ONE, 236); // STAT_TIMELIMIT
	if(t < 0)
		WriteCoord(MSG_ONE, autocvar_timelimit);
	else
		WriteCoord(MSG_ONE, (t + 1) / 60);
#else
	STAT(TTT_ROUNDTIMER, e) = t;
#endif
}

void nades_Clear(entity player);

void ttt_UpdateScores(bool timed_out)
{
	// give players their hard-earned kills now that the round is over
	FOREACH_CLIENT(true,
	{
		it.totalfrags += it.ttt_validkills;
		if(it.ttt_validkills)
		{
			GameRules_scoring_add(it, SCORE, it.ttt_validkills);
		}
		it.ttt_validkills = 0;
		// player survived the round
		if(IS_PLAYER(it) && !IS_DEAD(it)) // LegendGuard adds something for Karma 21-02-2021
		{
			//TODO: Detective doesn't need scores, but if investigated a corpse maybe yes 22-02-2021
			if(autocvar_g_ttt_reward_innocent && timed_out && it.ttt_status == TTT_STATUS_INNOCENT && it.ttt_status == TTT_STATUS_DETECTIVE)
			{
				GameRules_scoring_add(it, SCORE, 1); // reward innocents who make it to the end of the round time limit
				float increasekarma = 15; //15 points lol  //autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) );
				//PrintToChatAll(sprintf("^2REWARD ^7increasekarma: ^2%f", increasekarma));
				GameRules_scoring_add(it, TTT_KARMA, increasekarma);
				it.karmapoints = it.karmapoints + increasekarma;
				//PrintToChatAll(sprintf("^2REWARD ^7it.karmapoints: ^1%f", it.karmapoints));
				if(it.karmapoints >= autocvar_g_ttt_max_karma_points)
				{
					//Resets karmapoints to maintain the maximum
					//PrintToChatAll("^3REWARD ^1MAXIMUM RESET");
					GameRules_scoring_add(it, TTT_KARMA, autocvar_g_ttt_max_karma_points - it.karmapoints);
					it.karmapoints = autocvar_g_ttt_max_karma_points;
				}
				else if(it.karmapoints <= autocvar_g_ttt_min_karma_points)
					dropclient(it); //PrintToChatAll("GET OUT!!");
					//Ban_KickBanClient(entity client, float bantime, float masksize, string reason)

			}
			if(it.ttt_status == TTT_STATUS_INNOCENT)
			{
				GameRules_scoring_add(it, TTT_RESISTS, 1);
				float increasekarma = 25; //autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) );
				//PrintToChatAll(sprintf("^2INNOCENT ^7increasekarma: ^2%f", increasekarma));
				GameRules_scoring_add(it, TTT_KARMA, increasekarma);
				it.karmapoints = it.karmapoints + increasekarma;
				//PrintToChatAll(sprintf("^2INNOCENT ^7it.karmapoints: ^1%f", it.karmapoints));
				if(it.karmapoints >= autocvar_g_ttt_max_karma_points)
				{
					//Resets karmapoints to maintain the maximum
					//PrintToChatAll("^3INNOCENT ^1MAXIMUM RESET");
					GameRules_scoring_add(it, TTT_KARMA, autocvar_g_ttt_max_karma_points - it.karmapoints);
					it.karmapoints = autocvar_g_ttt_max_karma_points;
				}
				else if(it.karmapoints <= autocvar_g_ttt_min_karma_points)
					dropclient(it); //PrintToChatAll("GET OUT!!");
			}
			else if(it.ttt_status == TTT_STATUS_TRAITOR)
			{
				GameRules_scoring_add(it, TTT_HUNTS, 1);
				float increasekarma = 25; //autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) );
				//PrintToChatAll(sprintf("^1TRAITOR ^7increasekarma: ^2%f", increasekarma));
				GameRules_scoring_add(it, TTT_KARMA, increasekarma);
				it.karmapoints = it.karmapoints + increasekarma;
				//PrintToChatAll(sprintf("^1TRAITOR ^7it.karmapoints: ^1%f", it.karmapoints));
				if(it.karmapoints >= autocvar_g_ttt_max_karma_points)
				{
					//RESETS KARMAPOINTS TO MAINTAIN THE MAXIMUM
					//PrintToChatAll("^3TRAITOR ^1MAXIMUM RESET");
					GameRules_scoring_add(it, TTT_KARMA, autocvar_g_ttt_max_karma_points - it.karmapoints);
					it.karmapoints = autocvar_g_ttt_max_karma_points;
				}
				else if(it.karmapoints <= autocvar_g_ttt_min_karma_points)
					dropclient(it); //PrintToChatAll("GET OUT!!");
			}
		}
	});
}

float ttt_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		// if the match times out, innocents win too!
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TTT_INNOCENT_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TTT_INNOCENT_WIN);
		FOREACH_CLIENT(true,
		{
			if(IS_PLAYER(it))
				nades_Clear(it);
			ttt_FakeTimeLimit(it, -1);
		});

		ttt_UpdateScores(true);

		allowed_to_spawn = false;
		game_stopped = true;
		round_handler_Init(5, autocvar_g_ttt_warmup, autocvar_g_ttt_round_timelimit);
		return 1;
	}

	int innocent_count = 0, traitor_count = 0, detective_count = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(it.ttt_status == TTT_STATUS_INNOCENT)
			innocent_count++;
		else if(it.ttt_status == TTT_STATUS_TRAITOR)
			traitor_count++;
		else if(it.ttt_status == TTT_STATUS_DETECTIVE) //LegendGuard adds detective_count 20-02-2021 
			detective_count++;
	});
	if(innocent_count > 0 && traitor_count > 0)
	{
		return 0;
	}

	if(traitor_count > 0) // traitors win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TTT_TRAITOR_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TTT_TRAITOR_WIN);
	}
	else if(innocent_count > 0) // innocents win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TTT_INNOCENT_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TTT_INNOCENT_WIN);
	}
	else if (detective_count > 0 && innocent_count > 0) // detectives are same as innocents win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TTT_INNOCENT_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TTT_INNOCENT_WIN);
	}
	else
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	ttt_UpdateScores(false);

	allowed_to_spawn = false;
	game_stopped = true;
	round_handler_Init(5, autocvar_g_ttt_warmup, autocvar_g_ttt_round_timelimit);

	FOREACH_CLIENT(true,
	{
		if(IS_PLAYER(it))
		{
			it.respawn_flags = RESPAWN_SILENT; //CSQC print output respawn lib.qh error fix
			it.damagedbycontents = true;
			nades_Clear(it);
		}
		ttt_FakeTimeLimit(it, -1);
	});

	return 1;
}

void ttt_RoundStart()
{
	allowed_to_spawn = boolean(warmup_stage);
	int playercount = 0;

	// Fix number of detectives to 1
	FOREACH_CLIENT(true,
	{
		if(IS_PLAYER(it) && !IS_DEAD(it))
		{
			++playercount;
			it.ttt_status = TTT_STATUS_INNOCENT;
		}
		else
			it.ttt_status = 0; // this is mostly a safety check; if a client manages to somehow maintain a ttt status, clear it before the round starts!
		it.ttt_validkills = 0;
	});
	
	int innocent_count = bound(1, ((autocvar_g_ttt_innocent_count >= 1) ? autocvar_g_ttt_innocent_count : floor(playercount * autocvar_g_ttt_innocent_count)), playercount - 1); // 20%, but ensure at least 1 and less than total
	int total_innocents = 0;
	int traitor_count = bound(1, ((autocvar_g_ttt_traitor_count >= 1) ? autocvar_g_ttt_traitor_count : floor(playercount * autocvar_g_ttt_traitor_count)), playercount - 1); // 20%, but ensure at least 1 and less than total
	int total_traitors = 0;
	//int detective_count = bound(1, ((autocvar_g_ttt_detective_count >= 1) ? autocvar_g_ttt_detective_count : floor(playercount * autocvar_g_ttt_detective_count)), playercount - 1); // 20%, but ensure at least 1 and less than total
	int total_detectives = 0;
	//innocents TOTAL
	FOREACH_CLIENT_RANDOM(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(total_innocents >= innocent_count)
			break;
		total_innocents++;
		//LegendGuard fixes the round start 26-02-2021
		if (total_innocents <= 1)
		{
			if (total_traitors <= 1)
			{
				total_traitors++;
				it.ttt_status = TTT_STATUS_TRAITOR;
			}
		}
		else if (total_innocents == 3) // test this? && total_traitors >= 1)
		{
			if (total_detectives >= 1)
				break;
			else
			{
				total_detectives++;
				it.ttt_status = TTT_STATUS_DETECTIVE;
			}
		}
		else if (total_innocents >= 5)
		{
			if (total_detectives >= 2)
				break;
			else
			{
				total_detectives++;
				it.ttt_status = TTT_STATUS_DETECTIVE;
			}
		}
		else
			it.ttt_status = TTT_STATUS_INNOCENT;
	});
	
	//traitors TOTAL
	FOREACH_CLIENT_RANDOM(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(total_traitors >= traitor_count)
			break;
		total_traitors++;
		it.ttt_status = TTT_STATUS_TRAITOR;
	});

	//detectives TOTAL //Hey, is necessary? I don't think so...
	/*FOREACH_CLIENT_RANDOM(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(total_detectives >= detective_count)
			break;
		total_detectives++;
		//ROUND FIX
		if (total_detectives <= 1)
		{
			if (total_traitors <= 1)
				it.ttt_status = TTT_STATUS_INNOCENT;
		}
		else
			it.ttt_status = TTT_STATUS_DETECTIVE;
	});*/

	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		//PrintToChatAll(sprintf("it.karmapoints ^5begin: ^3%f",it.karmapoints));
		if(it.karmapoints <= 0)
		{
			//Resets karmapoints when match starts
			//PrintToChatAll("^2ZERO RESET");
			GameRules_scoring_add(it, TTT_KARMA, autocvar_g_ttt_max_karma_points - it.karmapoints);
			it.karmapoints = autocvar_g_ttt_max_karma_points;
		}
		else if(it.karmapoints >= autocvar_g_ttt_max_karma_points)
		{
			//Resets karmapoints to maintain the maximum
			//PrintToChatAll("^1MAXIMUM RESET");
			GameRules_scoring_add(it, TTT_KARMA, autocvar_g_ttt_max_karma_points - it.karmapoints);
			it.karmapoints = autocvar_g_ttt_max_karma_points;
		}
		else if(it.karmapoints <= autocvar_g_ttt_min_karma_points)
			dropclient(it); //PrintToChatAll("GET OUT!!");
		//PrintToChatAll(sprintf("it.karmapoints ^6end: ^3%f",it.karmapoints));

		if(it.ttt_status == TTT_STATUS_INNOCENT)
		{
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_TTT_INNOCENT);
			//PrintToChatAll(sprintf("^1DEBUG^7: %s is ^2Innocent^7!", it.netname));
		}
		else if(it.ttt_status == TTT_STATUS_TRAITOR)
		{
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_TTT_TRAITOR);
			//PrintToChatAll(sprintf("^1DEBUG^7: %s is ^1Traitor^7!", it.netname));
		}
		else if(it.ttt_status == TTT_STATUS_DETECTIVE)
		{
			Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_TTT_DETECTIVE); //Detective notification should be sent to all players to see who is
			PrintToChatAll(sprintf("%s is ^4Detective^7!", it.netname));
		}

		ttt_FakeTimeLimit(it, round_handler_GetEndTime());
	});
}

bool ttt_CheckPlayers()
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

bool ttt_isEliminated(entity e)
{
	if(e.caplayer == 1 && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
		return true;
	if(e.caplayer == 0.5)
		return true;
	return false;
}

void ttt_Initialize() // run at the start of a match, initiates game mode
{
	GameRules_scoring(0, SFL_SORT_PRIO_PRIMARY, 0, {
		field(SP_TTT_RESISTS, "resists", 0);
		field(SP_TTT_HUNTS, "hunts", SFL_SORT_PRIO_SECONDARY);
		field(SP_TTT_KARMA, "karma", SFL_SORT_PRIO_SECONDARY); //LegendGuard adds Karma points in the scoreboard 22-02-2021
	});

	allowed_to_spawn = true;
	round_handler_Spawn(ttt_CheckPlayers, ttt_CheckWinner, ttt_RoundStart);
	round_handler_Init(5, autocvar_g_ttt_warmup, autocvar_g_ttt_round_timelimit);
	EliminatedPlayers_Init(ttt_isEliminated);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ttt, ClientObituary)
{
	// LegendGuard's IDEA: To adjust the grade of severity of karma, 
	// we could add if sentence per weapons and adjust each weapon attack
	// its own grade. Instead doing random decrease grade 22-02-2021
	
	// in ttt, announcing a frag would tell everyone who the traitor is
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if(IS_PLAYER(frag_attacker) && frag_attacker != frag_target)
	{
		float frag_deathtype = M_ARGV(3, float);
		entity wep_ent = M_ARGV(4, entity);
		// "team" kill, a point is awarded to the player by default so we must take it away plus an extra one
		// unless the player is going to be punished for suicide, in which case just remove one
		if(frag_attacker.ttt_status == frag_target.ttt_status)
		{
			//PrintToChatAll("^1DEBUG^7: A ^2PLAYER^7 has fragged a ^2PLAYER OF HIS OWN TEAM^7, TOO BAD!");
			float decreasekarma = -( autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) * 0.25 );
			//PrintToChatAll(sprintf("decreasekarma: ^1%f", decreasekarma));
			GameRules_scoring_add(frag_attacker, TTT_KARMA, decreasekarma);
			frag_attacker.karmapoints = frag_attacker.karmapoints + decreasekarma;
			//PrintToChatAll(sprintf("frag_attacker.karmapoints: ^1%f", frag_attacker.karmapoints));
			GiveFrags(frag_attacker, frag_target, ((autocvar_g_ttt_punish_teamkill) ? -1 : -2), frag_deathtype, wep_ent.weaponentity_fld);
			if(frag_attacker.karmapoints <= autocvar_g_ttt_min_karma_points)
				dropclient(frag_attacker); //PrintToChatAll("GET OUT!!");
			//BASIC MATH THEORY: example: 1000 * 0.3 * (0.1 + 0.4) * 0.25 // karma points reduce when player attacked to other player
		}

		if(frag_attacker.ttt_status == TTT_STATUS_DETECTIVE)
		{
			if (frag_target.ttt_status == TTT_STATUS_INNOCENT)
			{	
				//PrintToChatAll("^1DEBUG^7: A ^4Detective^7 fragged an ^2Innocent^7, TOO BAD!");
				float decreasekarma = -( autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) * 0.25 );
				//PrintToChatAll(sprintf("decreasekarma: ^1%f", decreasekarma));
				GameRules_scoring_add(frag_attacker, TTT_KARMA, decreasekarma);
				frag_attacker.karmapoints = frag_attacker.karmapoints + decreasekarma;
				//PrintToChatAll(sprintf("frag_attacker.karmapoints: ^1%f", frag_attacker.karmapoints));
				GiveFrags(frag_attacker, frag_target, ((autocvar_g_ttt_punish_teamkill) ? -1 : -2), frag_deathtype, wep_ent.weaponentity_fld);
				if(frag_attacker.karmapoints <= autocvar_g_ttt_min_karma_points)
					dropclient(frag_attacker); //PrintToChatAll("GET OUT!!");
			}
		}

		if (frag_attacker.ttt_status == TTT_STATUS_INNOCENT)
		{
			if (frag_target.ttt_status == TTT_STATUS_DETECTIVE)
			{
				//PrintToChatAll("^1DEBUG^7: An ^2Innocent^7 fragged a ^4Detective^7, TOO BAD!");
				float decreasekarma = -( autocvar_g_ttt_max_karma_points * random() * ( 0.1 + random() ) * 0.25 );
				//PrintToChatAll(sprintf("decreasekarma: ^1%f", decreasekarma));
				GameRules_scoring_add(frag_attacker, TTT_KARMA, decreasekarma);
				frag_attacker.karmapoints = frag_attacker.karmapoints + decreasekarma;
				GiveFrags(frag_attacker, frag_target, ((autocvar_g_ttt_punish_teamkill) ? -1 : -2), frag_deathtype, wep_ent.weaponentity_fld);
				if(frag_attacker.karmapoints <= autocvar_g_ttt_min_karma_points)
					dropclient(frag_attacker); //PrintToChatAll(" GET OUT!!");
			}
		}
		//if ttt_status is 1, means innocent, 2 means traitor, 3 means detective, TODO: the bots: frag_attacker(1) shouldn't attack to frag_target(3)
		//PrintToChatAll(sprintf("^1DEBUG^7: frag_attacker.ttt_status is ^3%s^7",ftos(frag_attacker.ttt_status)));
		//PrintToChatAll(sprintf("^1DEBUG^7: frag_target.ttt_status is ^3%s^7",ftos(frag_target.ttt_status)));
	}
	//TODO: LegendGuard, try to do a "find out" if a traitor can see who fragged to who if possible 21-02-2021
	M_ARGV(5, bool) = true; // anonymous attacker
}

MUTATOR_HOOKFUNCTION(ttt, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);
	
	if(IS_PLAYER(player) || player.caplayer)
	{
		// update the scoreboard colour display to out the real killer at the end of the round
		// running this every frame to avoid cheats
		int plcolor = TTT_COLOR_INNOCENT;
		if(player.ttt_status == TTT_STATUS_INNOCENT && game_stopped) //Innocent status by default
			plcolor = TTT_COLOR_INNOCENT;
		if(player.ttt_status == TTT_STATUS_TRAITOR && game_stopped)
			plcolor = TTT_COLOR_TRAITOR;
		//LegendGuard adds for Detective 21-02-2021
		if(player.ttt_status == TTT_STATUS_DETECTIVE)// && game_stopped)
			plcolor = TTT_COLOR_DETECTIVE;
		setcolor(player, plcolor);
	}

	//CORPSE FEATURE 10-03-2021
	if (IS_DEAD(player))
	{
		player.event_damage = func_null;
		//player.health = 0;
		player.solid = SOLID_SLIDEBOX;
		set_movetype(player, MOVETYPE_STEP);
	}
}

MUTATOR_HOOKFUNCTION(ttt, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.ttt_status = 0;
	player.ttt_validkills = 0;
	player.caplayer = 1;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
}

MUTATOR_HOOKFUNCTION(ttt, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	// spectators / observers that weren't playing can join; they are
	// immediately forced to observe in the PutClientInServer hook
	// this way they are put in a team and can play in the next round
	if (!allowed_to_spawn && player.caplayer)
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ttt, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if (!allowed_to_spawn && IS_PLAYER(player)) // this is true even when player is trying to join
	{
		TRANSMUTE(Observer, player);
		if (CS(player).jointime != time && !player.caplayer) // not when connecting
		{
			player.caplayer = 0.5;
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}
}

MUTATOR_HOOKFUNCTION(ttt, reset_map_players)
{
	FOREACH_CLIENT(true, {
		CS(it).killcount = 0;
		it.ttt_status = 0;
		ttt_FakeTimeLimit(it, -1); // restore original timelimit
		if (!it.caplayer && IS_BOT_CLIENT(it))
			it.caplayer = 1;
		if (it.caplayer)
		{
			TRANSMUTE(Player, it);
			it.caplayer = 1;
			it.respawn_flags = RESPAWN_SILENT; //CSQC print output respawn lib.qh error fix
			it.damagedbycontents = true;
			PutClientInServer(it);
		}
	});
	bot_relinkplayerlist();
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, reset_map_global)
{
	allowed_to_spawn = true;
	return true;
}

entity ttt_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
		if (!IS_DEAD(it) && this.ttt_status == it.ttt_status)
		{
			if (!last_pl)
			{
				last_pl = it;
			}
			else
				return NULL;
		}
	});
	return last_pl;
}

void ttt_LastPlayerForTeam_Notify(entity this)
{
	if (!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
	{
		entity pl = ttt_LastPlayerForTeam(this);
		if (pl)
			Send_Notification(NOTIF_ONE_ONLY, pl, MSG_CENTER, CENTER_ALONE);
	}
}

MUTATOR_HOOKFUNCTION(ttt, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	ttt_LastPlayerForTeam_Notify(frag_target);
	if (!allowed_to_spawn)
	{
		frag_target.respawn_flags = RESPAWN_DENY;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time + 2;
	}
	frag_target.respawn_flags |= RESPAWN_DENY;
	frag_target.event_damage = func_null;
	frag_target.health = 0;
	
	if (!warmup_stage)
	{
		eliminatedPlayers.SendFlags |= 1;
		if (IS_BOT_CLIENT(frag_target))
			bot_clear(frag_target);
	}
	
	//if(frag_attacker.ttt_status == frag_target.ttt_status)
	// killed an ally! punishment is death
	if(autocvar_g_ttt_punish_teamkill && frag_attacker != frag_target && IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target) && frag_attacker.ttt_status == frag_target.ttt_status && !ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted()) // don't autokill if the round hasn't
		Damage(frag_attacker, frag_attacker, frag_attacker, 100000, DEATH_MIRRORDAMAGE.m_id, DMG_NOWEP, frag_attacker.origin, '0 0 0');	
	if(frag_attacker.ttt_status == TTT_STATUS_DETECTIVE)
	{
		if (frag_target.ttt_status == TTT_STATUS_INNOCENT)
		{
			//PrintToChatAll("^1DEBUG^7: ^4DETECTIVE ^1DAMAGE/DEAD^7 HAS TAKEN!");
			//30 damage points deal
			Damage(frag_attacker, frag_attacker, frag_attacker, 30, DEATH_MIRRORDAMAGE.m_id, DMG_NOWEP, frag_attacker.origin, '0 0 0');
		}
	}
	if (frag_attacker.ttt_status == TTT_STATUS_INNOCENT)
	{
		if (frag_target.ttt_status == TTT_STATUS_DETECTIVE)
		{
			//PrintToChatAll("^1DEBUG^7: ^2INNOCENT ^1DAMAGE/DEAD^7 HAS TAKEN!");
			//30 damage points deal
			Damage(frag_attacker, frag_attacker, frag_attacker, 30, DEATH_MIRRORDAMAGE.m_id, DMG_NOWEP, frag_attacker.origin, '0 0 0');
		}
	}
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		ttt_LastPlayerForTeam_Notify(player);
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, MakePlayerObserver)
{
	// LegendGuard, here is where spectators shouldn't talk to any players to say the hints or who is who 21-10-2021
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		ttt_LastPlayerForTeam_Notify(player);
	if (player.killindicator_teamchange == -2) // player wants to spectate
		player.caplayer = 0;
	if (player.caplayer)
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	if (!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	if (!player.caplayer)
	{
		player.ttt_validkills = 0;
		player.ttt_status = 0;
		ttt_FakeTimeLimit(player, -1); // restore original timelimit
		return false;  // allow team reset
	}
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(ttt, Scores_CountFragsRemaining)
{
	// announce remaining frags?
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	if(!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
		frag_attacker.ttt_validkills += M_ARGV(2, float);
	M_ARGV(2, float) = 0; // score will be given to the winner when the round ends
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, AddPlayerScore)
{
	// add scorefield for scoreboard here
	entity scorefield = M_ARGV(0, entity);
	if(scorefield == SP_KILLS || scorefield == SP_DEATHS || scorefield == SP_SUICIDES || scorefield == SP_DMG || scorefield == SP_DMGTAKEN)
		M_ARGV(1, float) = 0; // don't report that the player has killed or been killed, that would out them as a traitor!
}

MUTATOR_HOOKFUNCTION(ttt, CalculateRespawnTime)
{
	// no respawn calculations needed, player is forced to spectate anyway
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || it.caplayer == 1)
			++M_ARGV(0, int);
		++M_ARGV(1, int);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(ttt, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if (player.caplayer)
	{
		// they're going to spec, we can do other checks
		if (autocvar_sv_spectate && (IS_SPEC(player) || IS_OBSERVER(player)))
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(ttt, GetPlayerStatus)
{
	entity player = M_ARGV(0, entity);

	return player.caplayer == 1;
}

MUTATOR_HOOKFUNCTION(ttt, BotShouldAttack)
{
	//TODO: LegendGuard, try bots attack to innocents vs traitors, detectives must be on innocents team 21-02-2021
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	if(targ.ttt_status == bot.ttt_status)
	{
		return true;
	}
}
