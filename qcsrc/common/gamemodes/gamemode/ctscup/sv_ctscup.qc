#include "sv_ctscup.qh"

#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/race.qh>
#include <server/scores.qh>
#include <server/world.qh>
#include <server/items/spawning.qh>
#include <server/weapons/common.qh>

#include <common/mapobjects/triggers.qh>

MUTATOR_HOOKFUNCTION(ctscup, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	float dt = M_ARGV(1, float);

	player.race_movetime_frac += dt;
	float f = floor(player.race_movetime_frac);
	player.race_movetime_frac -= f;
	player.race_movetime_count += f;
	player.race_movetime = player.race_movetime_frac + player.race_movetime_count;

	if(IS_PLAYER(player))
	{
		if (player.race_penalty)
			if (time > player.race_penalty)
				player.race_penalty = 0;
		if(player.race_penalty)
		{
			player.velocity = '0 0 0';
			set_movetype(player, MOVETYPE_NONE);
			player.disableclientprediction = 2;
		}
	}

	// force kbd movement for fairness
	float wishspeed;
	vector wishvel;

	// if record times matter
	// ensure nothing EVIL is being done (i.e. div0_evade)
	// this hinders joystick users though
	// but it still gives SOME analog control
	wishvel.x = fabs(CS(player).movement.x);
	wishvel.y = fabs(CS(player).movement.y);
	if(wishvel.x != 0 && wishvel.y != 0 && wishvel.x != wishvel.y)
	{
		wishvel.z = 0;
		wishspeed = vlen(wishvel);
		if(wishvel.x >= 2 * wishvel.y)
		{
			// pure X motion
			if(CS(player).movement.x > 0)
				CS(player).movement_x = wishspeed;
			else
				CS(player).movement_x = -wishspeed;
			CS(player).movement_y = 0;
		}
		else if(wishvel.y >= 2 * wishvel.x)
		{
			// pure Y motion
			CS(player).movement_x = 0;
			if(CS(player).movement.y > 0)
				CS(player).movement_y = wishspeed;
			else
				CS(player).movement_y = -wishspeed;
		}
		else
		{
			// diagonal
			if(CS(player).movement.x > 0)
				CS(player).movement_x = M_SQRT1_2 * wishspeed;
			else
				CS(player).movement_x = -M_SQRT1_2 * wishspeed;
			if(CS(player).movement.y > 0)
				CS(player).movement_y = M_SQRT1_2 * wishspeed;
			else
				CS(player).movement_y = -M_SQRT1_2 * wishspeed;
		}
	}
}

MUTATOR_HOOKFUNCTION(ctscup, reset_map_global)
{
	float s;

	Score_NicePrint(NULL);

	race_ClearRecords();
	PlayerScore_Sort(race_place, 0, true, false);

	FOREACH_CLIENT(true, {
		if(it.race_place)
		{
			s = GameRules_scoring_add(it, RACE_FASTEST, 0);
			if(!s)
				it.race_place = 0;
		}
		cts_EventLog(ftos(it.race_place), it);
	});

	if(g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		cts_ScoreRules();
	}
}

MUTATOR_HOOKFUNCTION(ctscup, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	race_PreparePlayer(player);
	player.race_checkpoint = -1;

	race_SendAll(player, false);
}

MUTATOR_HOOKFUNCTION(ctscup, AbortSpeedrun)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_allow_checkpoints)
		race_PreparePlayer(player); // nice try
}

MUTATOR_HOOKFUNCTION(ctscup, PlayerDamaged)
{
	int frag_deathtype = M_ARGV(5, int);
	if (frag_deathtype == DEATH_KILL.m_id)
		return true; // forbid logging damage
}

MUTATOR_HOOKFUNCTION(ctscup, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	frag_target.respawn_flags |= RESPAWN_FORCE;
	race_AbandonRaceCheck(frag_target);

	if(autocvar_g_cts_removeprojectiles)
	{
		IL_EACH(g_projectiles, it.owner == frag_target && (it.flags & FL_PROJECTILE),
		{
			delete(it);
		});
	}
}

MUTATOR_HOOKFUNCTION(ctscup, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	bot.havocbot_role = havocbot_role_cts;
	return true;
}

MUTATOR_HOOKFUNCTION(ctscup, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	race_checkAndWriteName(player);
	race_SpeedAwardFrame(player);
}

MUTATOR_HOOKFUNCTION(ctscup, ForbidThrowCurrentWeapon)
{
	// no weapon dropping in CTS
	return true;
}

MUTATOR_HOOKFUNCTION(ctscup, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (Item_IsLoot(item))
	{
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ctscup, GetRecords)
{
	int record_page = M_ARGV(0, int);
	string ret_string = M_ARGV(1, string);

	for(int i = record_page * 200; i < MapInfo_count && i < record_page * 200 + 200; ++i)
	{
		if(MapInfo_Get_ByID(i))
		{
			float r = race_readTime(MapInfo_Map_bspname, 1);

			if(!r)
				continue;

			string h = race_readName(MapInfo_Map_bspname, 1);
			ret_string = strcat(ret_string, strpad(32, MapInfo_Map_bspname), " ", strpad(-8, TIME_ENCODED_TOSTRING(r)), " ", h, "\n");
		}
	}

	M_ARGV(1, string) = ret_string;
}

MUTATOR_HOOKFUNCTION(ctscup, ClientKill)
{
	M_ARGV(1, float) = 0; // kill delay
}

MUTATOR_HOOKFUNCTION(ctscup, HideTeamNagger)
{
	return true; // doesn't work so well (but isn't cts a teamless mode?)
}

MUTATOR_HOOKFUNCTION(ctscup, FixClientCvars)
{
	entity player = M_ARGV(0, entity);

	stuffcmd(player, "cl_cmd settemp cl_movecliptokeyboard 2\n");
}

MUTATOR_HOOKFUNCTION(ctscup, WantWeapon)
{
	M_ARGV(1, float) = (M_ARGV(0, entity) == WEP_SHOTGUN); // want weapon = weapon info
	M_ARGV(3, bool) = true; // want mutator blocked
	return true;
}

MUTATOR_HOOKFUNCTION(ctscup, ForbidDropCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ctscup, ForbidPlayerScore_Clear)
{
	return true; // in CTS, you don't lose score by observing
}



// ============================================================================
//              END OF PURE CTS, START OF SHARED FUNCTIONS
// ============================================================================



int roundCounter; // how many rounds have there been
int roundPlayers; // amount of players currently in the game, does not include spectators
int nextRoundPlayers; // how many players should participate in the next round
bool tournamentStarted; // has the warmup ended
// are we currently in a round?
// checked by turning this to false on round end and true when first player
// touches a checkpoint (a start trigger)
bool roundStarted;
float roundFirstFinisherTime; // time when the first finisher crossed the finish line
int roundFinisherCount; // how many players have reached the finish line

int autocvar_g_ctscup_minplayers; // how many players are required to start a tournament  
float autocvar_g_ctscup_warmup; // how long is the warmup round after loading into a map
float autocvar_g_ctscup_finishwait; // time before ending the round prematurely after first finish
float autocvar_g_ctscup_maxroundlength; // round length unless it ends prematurely

// is this player an active player?
// if not then they must be an eliminated player or a spectator
.bool tournamentParticipant;

// when a player or a bot connects, initialize their race values
// if it's a bot which isn't a tournament participant and the tournament has started
// override their forced join and keep them in spectator
MUTATOR_HOOKFUNCTION(ctscup, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if(IS_PLAYER(player))
	{
		if(!game_stopped)
		{
			if(CS(player).killcount == FRAGS_SPECTATOR /* initial spawn */ )
				race_PreparePlayer(player);
			else // respawn
				// only reset player race state during warmup when respawning
				if (!tournamentStarted)
					race_RetractPlayer(player);

			race_AbandonRaceCheck(player);
		}

		// override bot force join in PutClientInServer()
		if (IS_BOT_CLIENT(player) && tournamentStarted && !player.tournamentParticipant)
			TRANSMUTE(Observer, player);
	}
}

MUTATOR_HOOKFUNCTION(ctscup, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	// if tournament has not started register the player for the tournament
	// if they're a tournament player respawning make sure they still are in
	if (!tournamentStarted || player.tournamentParticipant)
	{
		player.frags = FRAGS_PLAYER;
		player.tournamentParticipant = true;
	}

	// only spectators and connecting players do not have a savestate so here:
	// newly connected player has spawned for the first time
	// or during warmup a player who was spectating has joined (back)
	// and as they're now a participant they're given a savestate
	if (player.tournamentParticipant && player.savestate == NULL)
	{
		player.savestate = new_pure(savestate);
		SaveSaveState(player);
	}

	// upon spawning for a new round, save a savestate instead of loading an old one
	// for whatever reason on the frame players are reset and spawned for a new round to start
	// round_handler_GetEndTime() still gives the end time for last round and time should be bigger than that
	if (tournamentStarted && player.tournamentParticipant)
	{
		// if somehow dying during a round and respawning, try toload last savestate
		if (roundStarted && player.savestate.loadCounter < 5)
			LoadSaveState(player);
		else
		{
			// did loading fail due to exceeding load counter
			if (player.savestate.loadCounter >= 5)
				// frontend notification

			// anyways as we couldn't load a savestate, save one here
			race_PreparePlayer(player);
			SaveSaveState(player);
		}
	}
	else
	{
		race_PreparePlayer(player);
		SaveSaveState(player);
	}
}

// a player is made a spectator
MUTATOR_HOOKFUNCTION(ctscup, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	// if the player wasn't an eliminated player
	// give them frags which correspond to being a spec
	if(player.frags != FRAGS_PLAYER_OUT_OF_GAME)
		player.frags = FRAGS_SPECTATOR;

	// they're no longer a tournament participant
	// if they were they've now forfeit
	player.tournamentParticipant = false;

	// race state reset
	race_PreparePlayer(player);

	// delete any savestate entities the player is associated with
	DeleteSaveState(player);

	// prevents resetting FRAGS_PLAYER_OUT_OF_GAME to FRAGS_SPECTATOR and
	// setting team to Spectator in PutObserverInServer, this is already handled here
	// it turns out this also makes it impossible to see which players are spectating...
	//return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ctscup, Race_FinalCheckpoint)
{
	entity player = M_ARGV(0, entity);

	// CTS comment: useful to prevent cheating by running back to the start line and starting out with more speed
	// I don't think we want to respawn players who finish in CTS Cup? commented out next 2 lines for now
	//if(autocvar_g_cts_finish_kill_delay)
	//	ClientKill_Silent(player, autocvar_g_cts_finish_kill_delay);

	if (tournamentStarted)
	{
		roundFinisherCount++;

		// if there are no round finish times, log this one as the first one
		if (roundFirstFinisherTime == 0)
			roundFirstFinisherTime = time;
	}

	// softlock player's race checkpoint progress
	// until next round, prevents 2nd laps and
	// registering the better time out of those 2
	// while waiting for slow players
	player.race_checkpoint = -3;
}

MUTATOR_HOOKFUNCTION(ctscup, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(7, vector);

	// do nothing if a non-player is dealt damage
	if (!IS_PLAYER(frag_target))return;

	// when selfdamage is disabled and player hurts themselves or receives splat damage nullify that damage
	if((frag_target == frag_attacker || frag_deathtype == DEATH_FALL.m_id) && !autocvar_g_cts_selfdamage)
	{
		frag_damage = 0;
		M_ARGV(4, float) = frag_damage;
	}

	// if the player were to be about to die, try to save them and restore a loadstate if possible
	else if (tournamentStarted &&
		(((GetResource(frag_target, RES_HEALTH) + GetResource(frag_target, RES_ARMOR)) - frag_damage) <= 0))
			if (LoadSaveState(frag_target))
			{
				// if savestate loading was successful
				// try to cheat death by offsetting the incoming damage
				frag_damage = 0;
				frag_force = '0 0 0';
				M_ARGV(4, float) = frag_damage;
				M_ARGV(6, vector) = frag_force;
			}
}



// ============================================================================
//              END OF SHARED FUNCTIONS, START OF CTS CUP
//=============================================================================

// count current players who are not in spectator
int CTSCUP_AliveParticipants()
{
	roundPlayers = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER,
	{
		roundPlayers++;
	});

	// if there are 1 or less players in an active tournament, end the tournament as it has finished
	if (tournamentStarted && (roundPlayers <= 1))
		cvar_set("_endmatch", "1");

	return roundPlayers;
}

// this is called when fake warmup ends
void CTSCUP_TournamentStart()
{
	if(tournamentStarted)return; // double calls shouldn't ever happen but handle those just in case

	tournamentStarted = true;

	// tournament started, make timelimit infinite to make sure tournament can go its full length
	// tournaments can not go on forever as at least 1 player has to get eliminated each round,
	// no one can join mid-game and there is a max round length
	// admins can override this timelimit as it's only set once at the start if they so please
	cvar_set("timelimit", "0");

	PrintToChatAll(" \n");
	PrintToChatAll("^1Tournament started! ^2GLHF! \n");
	PrintToChatAll(" \n");

	// register every tournament participant here
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER,
	{
		it.tournamentParticipant = true;
	});

	return;
	
}

// return true if we have any active players
// increase required amount in the future when this is not as WIP
bool CTSCUP_CanRoundStart()
{
	CTSCUP_AliveParticipants();

	// tournament started and there are 2 or more players
	if (tournamentStarted && (roundPlayers >= 2))
		return true;

	// tournament has yet to start but there are enough players to start the warmup timer
	if (!tournamentStarted && (roundPlayers >= autocvar_g_ctscup_minplayers))
	{
		PrintToChatAll(" \n");
		PrintToChatAll("^3W A R M U P  started! \n");
		PrintToChatAll(" \n");
		return true;
	}

	return false;
}

// this is called when a round starts
void CTSCUP_RoundStart()
{
	// reset this only after a round starts so it can be used to determinate current round
	// state when spawning players (after a new round starts when last round ended prematurely
	// due to someone finishing and g_ctscup_finishwait time ending the current round before
	// max roundtimelimit would end it)
	roundFirstFinisherTime = 0;
	roundFinisherCount = 0;

	CTSCUP_AliveParticipants(); //count players, not including spectators
	nextRoundPlayers = floor(roundPlayers * 0.9); // up to 90% of those players are allowed into the next round
}

bool CTSCUP_CheckRoundEnd()
{
	if (roundFirstFinisherTime) // check if someone has finished in active tournament
		// if g_ctscup_finishwait has passed since someone finished, end the current round
		if (time>=(roundFirstFinisherTime + autocvar_g_ctscup_finishwait))
		{
			game_stopped = true;
			round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
			return true;
		}

	// 1 player or less left playing in tournament
	CTSCUP_AliveParticipants();

	// max timelimit for current round
	if (time > round_handler_GetEndTime())
	{
		// start the tournament if enough players are present as warmup ended
		if (!tournamentStarted && (roundPlayers >= autocvar_g_ctscup_minplayers))
		{
			roundCounter = -1;
			game_stopped = true;
			round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
			return true;
		}

		// not enough players present, restart warmup
		if (!tournamentStarted && (roundPlayers < autocvar_g_ctscup_minplayers))
		{
			PrintToChatAll(" \n");
			PrintToChatAll("^3Not enough players!  W A R M U P  restarted! \n");
			PrintToChatAll(" \n");
			roundCounter = -1;
			game_stopped = true;
			round_handler_Init(0, 0.5, autocvar_g_ctscup_warmup);
			return true;
		}

		// to reach here the tournament has started and current round time has ended
		// just restart another round
		else
		{
			game_stopped = true;
			round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
			return true;
		}
	}

	// when all players playing the round have a clear time
	if (tournamentStarted && (roundPlayers == roundFinisherCount))
	{
		game_stopped = true;
		round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
		return true;
	}

	// if tournament has yet to start
	if (!tournamentStarted)
	{
		// if there are enough players to start a tournament
		if (roundPlayers >= autocvar_g_ctscup_minplayers)
		{
			// if all players have a clear time start the tournament
			bool everyoneHasAClearTime = true;

			FOREACH_CLIENT(IS_PLAYER(it) && !IS_BOT_CLIENT(it) && it.frags == FRAGS_PLAYER && it.tournamentParticipant == true,
			{
				if (PlayerScore_Get(it, SP_RACE_FASTEST) == 0)
				{
					// found someone who is playing warmup and is without a clear time
					everyoneHasAClearTime = false;
				}
			});

			if (everyoneHasAClearTime)
			{
				PrintToChatAll(" \n");
				PrintToChatAll("^3Everyone has a clear time! Ending warmup and starting the tournament! \n");
				//PrintToChatAll(" \n");
				roundCounter = -1;
				game_stopped = true;
				round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
				return true;
			}
		}
	}

	// condition recap:
	// round continues if:
	// early finish timer triggered by first finisher hasn't expired,
	// 2 or more players,
	// round's timelimit is not over,
	// and not everyone playing has a clear time
	return false;
}

// When a tournament round ends find all the slowest players and
// eliminate until we have the desired amount of players left
// implementation #3
// improvements from #2:
// spectators with scorekeeper entities are no longer kept in the linked list
// non-finishers are eliminated at random instead of connection order
.entity chain;
void CTSCUP_EliminatePlayers()
{
	// sort scorekeeper entities into a forwards non-round linked list
	entity fastestPlayer = PlayerScore_Sort(scoreboard_pos, 0, true, false);
	entity index = fastestPlayer;

	// abort, oh no how are we here
	// 2 last players on the server disconnected at the same time?
	// unknown if actually possible
	if (fastestPlayer == NULL)return;

	CTSCUP_AliveParticipants(); // count players, not including spectators
	int amountOfPlayersToEliminate = (roundPlayers - nextRoundPlayers);

	// rebuild the linked list as two new linked lists which do not have any spectators in them
	// one list for those who finished and one for those who did not

	entity lastFinishingPlayer = NULL, lastNonFinishingPlayer = NULL; // pointer storage entities
	entity backwardsLinkedListHelperPointer = NULL;
	entity finishers = NULL, nonFinishers = NULL; // linked lists' first entities
	int finishersCheckerValue = 0; // this should always match roundFinisherCount
	int nonFinishersCheckerValue = 0; // this should always match (roundPlayers - roundFinisherCount)

	// while old linked list has entries in it
	while (index)
	{
		// is our current list entry a tournament participant?
		if (index.tournamentParticipant)
		{
			// do they have a finish time?
			if (PlayerScore_Get(index, SP_RACE_FASTEST) == 0)
			{
				// we found a non-finisher
				nonFinishersCheckerValue++;

				// forwards linked list of non-finishers in connection
				// order excluding reused disconnected player slots
				if (nonFinishers)
				{
					// we found a +1 non-finisher
					lastNonFinishingPlayer.chain = index;

					// update our "last in the list" to be the latest entry
					lastNonFinishingPlayer = lastNonFinishingPlayer.chain;
				}
				else
				{
					// we found our first non-finisher
					lastNonFinishingPlayer = index;

					// initialize our linked list
					nonFinishers = lastNonFinishingPlayer;
				}

				// move the index over to the next list entry
				index = index.chain;
			}
			else
			{
				// we found a finisher
				finishersCheckerValue++;

				// backwards linked list
				// 1st -> 5th -> 4th -> 3rd -> 2nd -> 1st
				if (finishers)
				{
					// we found a +1 finisher
					backwardsLinkedListHelperPointer = index;

					// move the index over to the next list entry
					index = index.chain;

					// reverse chain order
					backwardsLinkedListHelperPointer.chain = lastFinishingPlayer;

					// update our "laTEst in the list" to be the latest entry
					lastFinishingPlayer = backwardsLinkedListHelperPointer;
				}
				else
				{
					// we found our first finisher
					lastFinishingPlayer = index;

					// initialize our linked list
					finishers = lastFinishingPlayer;

					// move the index over to the next list entry
					index = index.chain;
				}
			}
		}
		else
		{
			// found a spectator or etc., skip over them
			index = index.chain;
		}
	}

	// make the linked lists round
	if (finishers) finishers.chain = lastFinishingPlayer;

	if (nonFinishers) lastNonFinishingPlayer.chain = nonFinishers;

	if (finishersCheckerValue != roundFinisherCount && tournamentStarted)
		print("^1 ", sprintf("%f", finishersCheckerValue), " finishersCheckerValue != ", sprintf("%f", roundFinisherCount), " roundFinisherCount! \n");
	if (nonFinishersCheckerValue != (roundPlayers - roundFinisherCount) && tournamentStarted)
		print("^1 ", sprintf("%f", nonFinishersCheckerValue), " nonFinishersCheckerValue != ", sprintf("%f", (roundPlayers - roundFinisherCount)), " (roundPlayers - roundFinisherCount)! \n");

	// find and move players to spectator until we only have the allowed amount of players left

	if (amountOfPlayersToEliminate > 0 && (finishers || nonFinishers))
	{
		// eliminate the non-finishers at random while they last
		index = nonFinishers;
		while (nonFinishers && amountOfPlayersToEliminate > 0)
		{
			// if we have more than 1 player who didn't finish
			if (nonFinishersCheckerValue > 1)
			{
				// randomize who out of them gets eliminated
				for (int i = 0; i < ((random() * roundPlayers)); i++)
				{
					index = index.chain;
				}
			}

			// elimination
			index.chain.tournamentParticipant = false;
			index.chain.frags = FRAGS_PLAYER_OUT_OF_GAME;
			TRANSMUTE(Observer, index.chain);

			// repair the linked list so it can be looped again in case we 
			// would ever need to eliminate 2 or more random players
			index.chain = index.chain.chain;
			amountOfPlayersToEliminate--;
		}

		// if we've ran out of non-finishers move to slowest finishing player
		// do not bother to check if they have the same time at decimal level 
		// as it's far too unlikely to happen to matter

		index = finishers.chain; // start with the slowest player
		// finishers is fastest -> .chain slowest -> .chain.chain 2nd slowest etc.
		while (finishers && amountOfPlayersToEliminate > 0)
		{
			// elimination
			index.tournamentParticipant = false;
			index.frags = FRAGS_PLAYER_OUT_OF_GAME;
			TRANSMUTE(Observer, index);

			index = index.chain;
			amountOfPlayersToEliminate--;
		}

		if (amountOfPlayersToEliminate) 
			print("^1TRIED TO ELIMINATE ",
			sprintf("%f", amountOfPlayersToEliminate),
			" MORE PLAYERS THAN IN LINKED LISTS \n");
	}
}

// upon map reset
// if tournament has started eliminate player(s) and increment round counter
// if tournament has not started start the tournament
// always clear scores and reset and restart players
MUTATOR_HOOKFUNCTION(ctscup, reset_map_players)
{
	// reset rounds after warmup
	if (tournamentStarted && roundCounter >= 0)
	{
		roundCounter++;

		CTSCUP_EliminatePlayers();

		Score_ClearAll();
	}

	// mark round as not started as it's being reset
	roundStarted = false;

	// reset warmup ending round
	if (roundCounter == -1)
	{
		CTSCUP_TournamentStart();
		roundCounter++;
		Score_ClearAll();
	}

	// respawn players
	FOREACH_CLIENT(true, {
		if (it.tournamentParticipant)
		{
			TRANSMUTE(Player, it);
		}
		else
		{
			TRANSMUTE(Observer, it);
		}
		PutClientInServer(it);
	});
	return true;
}

//MUTATOR_HOOKFUNCTION(ctscup, reset_map_global) in CTS code, unchanged for now

// if player trying to spawn is not a valid tournament participant don't allow spawning
MUTATOR_HOOKFUNCTION(ctscup, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	bool blockSpawning = false;

	if (tournamentStarted && !player.tournamentParticipant)
		blockSpawning = true;

	return blockSpawning;
}

// someone disconnected
MUTATOR_HOOKFUNCTION(ctscup, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	// if the player disconnecting was a player who had finished
	// redact one from the amount players waiting at the finish line
	if (player.tournamentParticipant && PlayerScore_Get(player, SP_RACE_FASTEST))
		roundFinisherCount--;

	// delete possible savestate entities they may have had
	DeleteSaveState(player);
}

// when a player touches any checkpoint update their savestate
MUTATOR_HOOKFUNCTION(ctscup, Race_Checkpoint)
{
	entity player = M_ARGV(0, entity);

	// mark round as started if we're in a tournament
	if (tournamentStarted)
		roundStarted = true;

			// do not register savestates with corpses that hit checkpoints
	if (tournamentStarted && (GetResource(player, RES_HEALTH) >= 1))
		SaveSaveState(player);
}

// when a player changes their own team to spectator
MUTATOR_HOOKFUNCTION(ctscup, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	// if the player moving to spectator was a player who had finished
	// redact one from the amount players waiting at the finish line
	if (player.tournamentParticipant && PlayerScore_Get(player, SP_RACE_FASTEST))
		roundFinisherCount--;

	if (tournamentStarted && (player.frags == FRAGS_PLAYER_OUT_OF_GAME || player.frags == FRAGS_PLAYER))
	{
		player.tournamentParticipant = false;
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	}
	else player.frags = FRAGS_SPECTATOR;

	if (INGAME(player))
	{
		// CA relic in comments, should probably be refactored to announce a player forfeit
		// they're going to spec, we can do other checks
		//if (autocvar_sv_spectate && (IS_SPEC(player) || IS_OBSERVER(player)))
		//	Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

void ctscup_Initialize()
{
	cts_Initialize();

	tournamentStarted = false;

	//arguments: can round start, can round end (prematurely), called when round starts
	round_handler_Spawn(CTSCUP_CanRoundStart, CTSCUP_CheckRoundEnd, CTSCUP_RoundStart);
	//arguments: time until this round starts, pre-round preparation time, round timelimit
	round_handler_Init(5, 0.5, autocvar_g_ctscup_warmup);
}
