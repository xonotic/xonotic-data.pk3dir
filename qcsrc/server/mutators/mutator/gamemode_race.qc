#include "gamemode_race.qh"

#include <server/race.qh>

#define autocvar_g_race_laps_limit cvar("g_race_laps_limit")
float autocvar_g_race_qualifying_timelimit;
float autocvar_g_race_qualifying_timelimit_override;
int autocvar_g_race_teams;

// legacy bot roles
.float race_checkpoint;
void havocbot_role_race(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.bot_strategytime < time)
	{
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start(this);

		IL_EACH(g_racecheckpoints, true,
		{
			if(it.cnt == this.race_checkpoint)
			{
				navigation_routerating(this, it, 1000000, 5000);
			}
			else if(this.race_checkpoint == -1)
			{
				navigation_routerating(this, it, 1000000, 5000);
			}
		});

		navigation_goalrating_end(this);
	}
}

void race_ScoreRules()
{
	ScoreRules_basics(race_teams, 0, 0, false);
	if(race_teams)
	{
		ScoreInfo_SetLabel_TeamScore(  ST_RACE_LAPS,    "laps",       SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_TIME,    "time",      SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_FASTEST, "fastest",   SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	else if(g_race_qualifying)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_FASTEST, "fastest",   SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	else
	{
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_TIME,    "time",      SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		ScoreInfo_SetLabel_PlayerScore(SP_RACE_FASTEST, "fastest",   SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	ScoreRules_basics_end();
}

void race_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":race:", mode, ":", ((actor != NULL) ? (strcat(":", ftos(actor.playerid))) : "")));
}

float WinningCondition_Race(float fraglimit)
{
	float wc;
	float n, c;

	n = 0;
	c = 0;
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		++n;
		if(it.race_completed)
			++c;
	));
	if(n && (n == c))
		return WINNING_YES;
	wc = WinningCondition_Scores(fraglimit, 0);

	// ALWAYS initiate overtime, unless EVERYONE has finished the race!
	if(wc == WINNING_YES || wc == WINNING_STARTSUDDENDEATHOVERTIME)
	// do NOT support equality when the laps are all raced!
		return WINNING_STARTSUDDENDEATHOVERTIME;
	else
		return WINNING_NEVER;
}

float WinningCondition_QualifyingThenRace(float limit)
{
	float wc;
	wc = WinningCondition_Scores(limit, 0);

	// NEVER initiate overtime
	if(wc == WINNING_YES || wc == WINNING_STARTSUDDENDEATHOVERTIME)
	{
		return WINNING_YES;
	}

	return wc;
}

MUTATOR_HOOKFUNCTION(rc, AbortSpeedrun)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_allow_checkpoints)
		race_PreparePlayer(player); // nice try
}

MUTATOR_HOOKFUNCTION(rc, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	float dt = M_ARGV(1, float);

	player.race_movetime_frac += dt;
	float f = floor(player.race_movetime_frac);
	player.race_movetime_frac -= f;
	player.race_movetime_count += f;
	player.race_movetime = player.race_movetime_frac + player.race_movetime_count;

#ifdef SVQC
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
#endif

	// force kbd movement for fairness
	float wishspeed;
	vector wishvel;

	// if record times matter
	// ensure nothing EVIL is being done (i.e. div0_evade)
	// this hinders joystick users though
	// but it still gives SOME analog control
	wishvel.x = fabs(player.movement.x);
	wishvel.y = fabs(player.movement.y);
	if(wishvel.x != 0 && wishvel.y != 0 && wishvel.x != wishvel.y)
	{
		wishvel.z = 0;
		wishspeed = vlen(wishvel);
		if(wishvel.x >= 2 * wishvel.y)
		{
			// pure X motion
			if(player.movement.x > 0)
				player.movement_x = wishspeed;
			else
				player.movement_x = -wishspeed;
			player.movement_y = 0;
		}
		else if(wishvel.y >= 2 * wishvel.x)
		{
			// pure Y motion
			player.movement_x = 0;
			if(player.movement.y > 0)
				player.movement_y = wishspeed;
			else
				player.movement_y = -wishspeed;
		}
		else
		{
			// diagonal
			if(player.movement.x > 0)
				player.movement_x = M_SQRT1_2 * wishspeed;
			else
				player.movement_x = -M_SQRT1_2 * wishspeed;
			if(player.movement.y > 0)
				player.movement_y = M_SQRT1_2 * wishspeed;
			else
				player.movement_y = -M_SQRT1_2 * wishspeed;
		}
	}
}

MUTATOR_HOOKFUNCTION(rc, reset_map_global)
{
	float s;

	Score_NicePrint(NULL);

	race_ClearRecords();
	PlayerScore_Sort(race_place, 0, 1, 0);

	FOREACH_CLIENT(true, LAMBDA(
		if(it.race_place)
		{
			s = PlayerScore_Add(it, SP_RACE_FASTEST, 0);
			if(!s)
				it.race_place = 0;
		}
		race_EventLog(ftos(it.race_place), it);
	));

	if(g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		race_ScoreRules();
	}
}

MUTATOR_HOOKFUNCTION(rc, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	race_PreparePlayer(player);
	player.race_checkpoint = -1;

	string rr = RACE_RECORD;

	if(IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		race_send_recordtime(MSG_ONE);
		race_send_speedaward(MSG_ONE);

		speedaward_alltimebest = stof(db_get(ServerProgsDB, strcat(GetMapname(), rr, "speed/speed")));
		speedaward_alltimebest_holder = uid2name(db_get(ServerProgsDB, strcat(GetMapname(), rr, "speed/crypto_idfp")));
		race_send_speedaward_alltimebest(MSG_ONE);

		float i;
		for (i = 1; i <= RANKINGS_CNT; ++i)
		{
			race_SendRankings(i, 0, 0, MSG_ONE);
		}
	}
}

MUTATOR_HOOKFUNCTION(rc, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if(g_race_qualifying)
	if(PlayerScore_Add(player, SP_RACE_FASTEST, 0))
		player.frags = FRAGS_LMS_LOSER;
	else
		player.frags = FRAGS_SPECTATOR;

	race_PreparePlayer(player);
	player.race_checkpoint = -1;
}

MUTATOR_HOOKFUNCTION(rc, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);

	if(spawn_spot.target == "")
		// Emergency: this wasn't a real spawnpoint. Can this ever happen?
		race_PreparePlayer(player);

	// if we need to respawn, do it right
	player.race_respawn_checkpoint = player.race_checkpoint;
	player.race_respawn_spotref = spawn_spot;

	player.race_place = 0;
}

MUTATOR_HOOKFUNCTION(rc, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if(IS_PLAYER(player))
	if(!game_stopped)
	{
		if(player.killcount == FRAGS_SPECTATOR /* initial spawn */ || g_race_qualifying) // spawn
			race_PreparePlayer(player);
		else // respawn
			race_RetractPlayer(player);

		race_AbandonRaceCheck(player);
	}
}

MUTATOR_HOOKFUNCTION(rc, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	frag_target.respawn_flags |= RESPAWN_FORCE;
	race_AbandonRaceCheck(frag_target);
}

MUTATOR_HOOKFUNCTION(rc, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	bot.havocbot_role = havocbot_role_race;
	return true;
}

MUTATOR_HOOKFUNCTION(rc, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	if(player.cvar_cl_allow_uidtracking == 1 && player.cvar_cl_allow_uid2name == 1)
	{
		if (!player.stored_netname)
			player.stored_netname = strzone(uid2name(player.crypto_idfp));
		if(player.stored_netname != player.netname)
		{
			db_put(ServerProgsDB, strcat("/uid2name/", player.crypto_idfp), player.netname);
			strunzone(player.stored_netname);
			player.stored_netname = strzone(player.netname);
		}
	}

	if (!IS_OBSERVER(player))
	{
		if(vdist(player.velocity - player.velocity_z * '0 0 1', >, speedaward_speed))
		{
			speedaward_speed = vlen(player.velocity - player.velocity_z * '0 0 1');
			speedaward_holder = player.netname;
			speedaward_uid = player.crypto_idfp;
			speedaward_lastupdate = time;
		}
		if (speedaward_speed > speedaward_lastsent && time - speedaward_lastupdate > 1)
		{
			string rr = RACE_RECORD;
			race_send_speedaward(MSG_ALL);
			speedaward_lastsent = speedaward_speed;
			if (speedaward_speed > speedaward_alltimebest && speedaward_uid != "")
			{
				speedaward_alltimebest = speedaward_speed;
				speedaward_alltimebest_holder = speedaward_holder;
				speedaward_alltimebest_uid = speedaward_uid;
				db_put(ServerProgsDB, strcat(GetMapname(), rr, "speed/speed"), ftos(speedaward_alltimebest));
				db_put(ServerProgsDB, strcat(GetMapname(), rr, "speed/crypto_idfp"), speedaward_alltimebest_uid);
				race_send_speedaward_alltimebest(MSG_ALL);
			}
		}
	}
}

MUTATOR_HOOKFUNCTION(rc, ForbidPlayerScore_Clear)
{
	if(g_race_qualifying)
		return true; // in qualifying, you don't lose score by observing
}

MUTATOR_HOOKFUNCTION(rc, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = race_teams;
}

MUTATOR_HOOKFUNCTION(rc, Scores_CountFragsRemaining)
{
	// announce remaining frags if not in qualifying mode
	if(!g_race_qualifying)
		return true;
}

MUTATOR_HOOKFUNCTION(rc, GetRecords)
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

MUTATOR_HOOKFUNCTION(rc, HideTeamNagger)
{
	return true; // doesn't work so well
}

MUTATOR_HOOKFUNCTION(rc, FixClientCvars)
{
	entity player = M_ARGV(0, entity);

	stuffcmd(player, "cl_cmd settemp cl_movecliptokeyboard 2\n");
}

MUTATOR_HOOKFUNCTION(rc, CheckRules_World)
{
	float checkrules_timelimit = M_ARGV(1, float);
	float checkrules_fraglimit = M_ARGV(2, float);

	if(checkrules_timelimit >= 0)
	{
		if(!g_race_qualifying)
		{
			M_ARGV(0, float) = WinningCondition_Race(checkrules_fraglimit);
			return true;
		}
		else if(g_race_qualifying == 2)
		{
			M_ARGV(0, float) = WinningCondition_QualifyingThenRace(checkrules_fraglimit);
			return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(rc, ReadLevelCvars)
{
	if(g_race_qualifying == 2)
		warmup_stage = 0;
}

void race_Initialize()
{
	race_ScoreRules();
	if(g_race_qualifying == 2)
		warmup_stage = 0;
}

void rc_SetLimits()
{
	int fraglimit_override, leadlimit_override;
	float timelimit_override, qualifying_override;

	if(autocvar_g_race_teams)
	{
		ActivateTeamplay();
		race_teams = bound(2, autocvar_g_race_teams, 4);
		int teams = 0;
		if(race_teams >= 1) teams |= BIT(0);
		if(race_teams >= 2) teams |= BIT(1);
		if(race_teams >= 3) teams |= BIT(2);
		if(race_teams >= 4) teams |= BIT(3);

		race_teams = teams; // now set it?

		have_team_spawns = -1; // request team spawns
	}
	else
		race_teams = 0;

	qualifying_override = autocvar_g_race_qualifying_timelimit_override;
	fraglimit_override = autocvar_g_race_laps_limit;
	leadlimit_override = 0; // currently not supported by race
	timelimit_override = autocvar_timelimit_override;

	float want_qualifying = ((qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit) > 0;

	if(autocvar_g_campaign)
	{
		g_race_qualifying = 1;
		independent_players = 1;
	}
	else if(want_qualifying)
	{
		g_race_qualifying = 2;
		independent_players = 1;
		race_fraglimit = (fraglimit_override >= 0) ? fraglimit_override : autocvar_fraglimit;
		race_leadlimit = (leadlimit_override >= 0) ? leadlimit_override : autocvar_leadlimit;
		race_timelimit = (timelimit_override >= 0) ? timelimit_override : autocvar_timelimit;
		qualifying_override = (qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit;
		fraglimit_override = 0;
		leadlimit_override = 0;
		timelimit_override = qualifying_override;
	}
	else
		g_race_qualifying = 0;
	SetLimits(fraglimit_override, leadlimit_override, timelimit_override, qualifying_override);
}
