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

MUTATOR_HOOKFUNCTION(ctscup, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if(IS_PLAYER(player))
	if(!game_stopped)
	{
		if(CS(player).killcount == FRAGS_SPECTATOR /* initial spawn */ || g_race_qualifying) // spawn
			race_PreparePlayer(player);
		else // respawn
			race_RetractPlayer(player);

		race_AbandonRaceCheck(player);
	}
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



int roundCounter; // unused?
int roundPlayers; // amount of players currently in the game, does not include spectators
int nextRoundPlayers; // how many players should participate in the next round
bool tournamentStarted; // has the warmup ended
float roundFirstFinisherTime; // time when the first finisher crossed the finish line

int autocvar_g_ctscup_minplayers; // how many players are required to start a tournament  
float autocvar_g_ctscup_warmup; // how long is the warmup round after loading into a map
float autocvar_g_ctscup_finishwait; // time before ending the round prematurely after first finish
float autocvar_g_ctscup_maxroundlength; // round length unless it ends prematurely

.bool tournamentParticipant; // is this player an active player? if not then they must be an eliminated player or a spectator

MUTATOR_HOOKFUNCTION(ctscup, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

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

	// debug print
	//print(sprintf("%f", time), " time \n");
	//print(sprintf("%f", round_handler_GetEndTime()), " round_handler_GetEndTime() \n");
	//print(sprintf("%f", (roundFirstFinisherTime + autocvar_g_ctscup_finishwait)), " (roundFirstFinisherTime + autocvar_g_ctscup_finishwait) \n\n");

	// upon spawning for a new round, save a savestate instead of loading an old one
	// for whatever reason on the frame players are reset and spawned for a new round to start
	// round_handler_GetEndTime() still gives the end time for last round and time should be bigger than that
	if (tournamentStarted && player.tournamentParticipant)
	{
		if ((time > round_handler_GetEndTime()) || (roundFirstFinisherTime && (time > (roundFirstFinisherTime + autocvar_g_ctscup_finishwait))))
		{
			SaveSaveState(player);
		}
		// if somehow dying during a round and respawning, load last savestate
		else
		{
			LoadSaveState(player);
		}
	}
}

// a player is made a spectator
MUTATOR_HOOKFUNCTION(ctscup, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if(tournamentStarted && player.frags != FRAGS_PLAYER_OUT_OF_GAME)
		player.frags = FRAGS_SPECTATOR;

	// race state reset
	race_PreparePlayer(player);
	player.race_checkpoint = -1;

	// delete any savestate entities the player is associated with
	DeleteSaveState(player);

	// prevents resetting FRAGS_PLAYER_OUT_OF_GAME to FRAGS_SPECTATOR and
	// setting team to Spectator in PutObserverInServer, this is already handled here
	// it turns out this also makes it impossible to see which players are spectating...
	//return true;
}

MUTATOR_HOOKFUNCTION(ctscup, Race_FinalCheckpoint)
{
	//entity player = M_ARGV(0, entity);

	// CTS comment: useful to prevent cheating by running back to the start line and starting out with more speed
	// I don't think we want to respawn players who finish in CTS Cup? commented out next 2 lines for now
	//if(autocvar_g_cts_finish_kill_delay)
	//	ClientKill_Silent(player, autocvar_g_cts_finish_kill_delay);

	if (roundFirstFinisherTime == 0 && tournamentStarted) roundFirstFinisherTime = time;
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
	else if (((GetResource(frag_target, RES_HEALTH) + GetResource(frag_target, RES_ARMOR)) - frag_damage) <= 0)
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
		return true;

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

	CTSCUP_AliveParticipants(); //count players, not including spectators
	nextRoundPlayers = floor(roundPlayers * 0.9); // up to 90% of those players are allowed into the next round
}

bool CTSCUP_CheckRoundEnd()
{
	if(roundFirstFinisherTime) // check if someone has finished
		// if g_ctscup_finishwait has passed since someone finished end the current round
		if(time>=(roundFirstFinisherTime + autocvar_g_ctscup_finishwait))
		{
			game_stopped = true;
			round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
			return true;
		}

	// max timelimit for current round
	if(time > round_handler_GetEndTime())
	{
		game_stopped = true;
		round_handler_Init(5, 1, autocvar_g_ctscup_maxroundlength);
		return true;
	}

	// 1 player or less
	// optimize and move this to player changing teams and disconnecting?
	CTSCUP_AliveParticipants();

	return false;
}

// When a tournament round ends find all the slowest players and
// eliminate until we have the desired amount of players left
void CTSCUP_EliminatePlayers()
{
	// 255 is engine limit on maxclients, 256 players
	// this global array could be smaller as it's very unlikely that 255 players would ever play on a server
	// but array lengths have to be constants in QC which makes it very iffy
	// To optimize and prevent this many players from playing at once or not to
	entity sortRoundParticipants[255];

	CTSCUP_AliveParticipants(); // count players, not including spectators
	int unsortedPlayers = roundPlayers; // how many players there still is left to sort into the array

	// go through all entities which are clients, find players and store them in a new array
	// so we don't need to go through the whole entity list many, many times
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER,
	{
		// when finding a player find their right spot
		for (int k = 0 ; k < roundPlayers ; k++)
		{
			// if this index is empty, store them there and go find the next player
			if (sortRoundParticipants[k] == NULL)
			{
				sortRoundParticipants[k] = it;
				unsortedPlayers--;
				break;
			}
			else // this index is not empty
			{
				// those who didn't finish, place them right at the end of the array

				// the player we found did not finish, place them to the end of the array
				if (PlayerScore_Get(it, SP_RACE_FASTEST) == 0)
				{
					sortRoundParticipants[roundPlayers - unsortedPlayers] = it;
					unsortedPlayers--;
					break;
				}

				// if this spot has a player who didn't finish push the old entries 1 further and place our new player in this spot
				if (PlayerScore_Get(sortRoundParticipants[k], SP_RACE_FASTEST) == 0)
				{
					for (int j = (roundPlayers - unsortedPlayers) ; j >= k ; j--)
					{
						// j-1 is fine because this can not be reached with 0 players sorted
						// reaching this with 1 players sorted would move index 0 to index 1 which is fine
						sortRoundParticipants[j] = sortRoundParticipants[j-1];
					}
					sortRoundParticipants[k] = it;
					unsortedPlayers--;
					break;
				}

				// those players who did not finish have a time of 0
				// those players who finished have a score which is LOWER the better they did
				// this makes it so that comparing size only would place those who didn't finish as the fastest players
				// thus previous 2 ifs are necessary

				// after this only those who have a clear time are handled

				// if new player is faster than current index push old entries 1 further and place our new player in this spot
				if (PlayerScore_Get(it, SP_RACE_FASTEST) < PlayerScore_Get(sortRoundParticipants[k], SP_RACE_FASTEST))
				{
					for (int j = (roundPlayers - unsortedPlayers) ; j >= k ; j--)
					{
						// j-1 is fine because this can not be reached with 0 players sorted
						// reaching this with 1 players sorted would move index 0 to index 1 which is fine
						sortRoundParticipants[j] = sortRoundParticipants[j-1];
					}
					sortRoundParticipants[k] = it;
					unsortedPlayers--;
					break;
				}
			}
		}
	});

	// Move players to spectator until we only have the allowed amount of players left
	// int playersToEliminate = (roundPlayers - nextRoundPlayers);
	for (int i = 0 ; i < (roundPlayers - nextRoundPlayers) ; i++)
	{
		// - 1 is index offset, if we have 2 players the 2nd player is in index 1
		//int indexOfEliminatedPlayer = ((roundPlayers - i) - 1)
		sortRoundParticipants[((roundPlayers - i) - 1)].tournamentParticipant = false;
		sortRoundParticipants[((roundPlayers - i) - 1)].frags = FRAGS_PLAYER_OUT_OF_GAME;
		TRANSMUTE(Observer, sortRoundParticipants[((roundPlayers - i) - 1)]);
	}

	return;
}

// this is called when fake warmup ends
void CTSCUP_TournamentStart()
{
	if(tournamentStarted)return; // double calls shouldn't ever happen but handle those just in case

	// = 0 is for initialization which is for whatever reason required by compiler or it warns
	float autocvar_g_start_delay = 0;
	if (time >= (autocvar_g_start_delay + autocvar_g_ctscup_warmup))
	{
		roundCounter = 0;

		tournamentStarted = true;

		print("Tournament started! GLHF! \n");

		// register every tournament participant here
		FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER,
		{
			it.tournamentParticipant = true;
		});

		return;
	}

	// implement feature: skip warmup if all players ready up?
}

// upon map reset
// if tournament has started eliminate player(s) and increment round counter
// if tournament has not started start the tournament
// always clear scores and reset and restart players
MUTATOR_HOOKFUNCTION(ctscup, reset_map_players)
{
	if (tournamentStarted)
	{
		roundCounter++;

		CTSCUP_EliminatePlayers();
	}
	else
		CTSCUP_TournamentStart();

	Score_ClearAll();

	FOREACH_CLIENT(true, {
		if (it.tournamentParticipant)
		{
			TRANSMUTE(Player, it);
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

// when a player touches any checkpoint update their savestate
MUTATOR_HOOKFUNCTION(ctscup, Race_Checkpoint)
{
	entity player = M_ARGV(0, entity);

	SaveSaveState(player);
}

// when a player changes their own team to spectator
MUTATOR_HOOKFUNCTION(ctscup, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if(tournamentStarted && (player.frags == FRAGS_PLAYER_OUT_OF_GAME || player.frags == FRAGS_PLAYER))
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
	round_handler_Init(5, 1, autocvar_g_ctscup_warmup);
}
