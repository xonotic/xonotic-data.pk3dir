#include "sv_race.qh"

#include <server/client.qh>
#include <server/world.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/race.qh>
#include <common/ent_cs.qh>
#include <common/mapobjects/triggers.qh>

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

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		bool raw_touch_check = true;
		int cp = this.race_checkpoint;

		LABEL(search_racecheckpoints)
		IL_EACH(g_racecheckpoints, true,
		{
			if(it.cnt == cp || cp == -1)
			{
				// redirect bot to next goal if it touched the waypoint of an untouchable checkpoint
				// e.g. checkpoint in front of Stormkeep's warpzone
				// the same workaround is applied in CTS gametype
				if (raw_touch_check && vdist(this.origin - it.nearestwaypoint.origin, <, 30))
				{
					cp = race_NextCheckpoint(cp);
					raw_touch_check = false;
					goto search_racecheckpoints;
				}
				navigation_routerating(this, it, 1000000, 5000);
			}
		});

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void race_ScoreRules()
{
	GameRules_score_enabled(false);
	GameRules_scoring(race_teams, 0, 0, {
		if (race_teams)
			field_team(ST_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
		else if (g_race_qualifying)
			field(SP_RACE_FASTEST, "fastest", SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		if (race_teams || !g_race_qualifying)
		{
			field(SP_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
			field(SP_RACE_TIME, "time", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
			field(SP_RACE_FASTEST, "fastest", SFL_LOWER_IS_BETTER | SFL_TIME);
		}
	});
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
	FOREACH_CLIENT(IS_PLAYER(it), {
		++n;
		if(CS(it).race_completed)
			++c;
	});
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

MUTATOR_HOOKFUNCTION(rc, ClientKill)
{
	if(g_race_qualifying)
		M_ARGV(1, float) = 0; // killtime
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

MUTATOR_HOOKFUNCTION(rc, reset_map_global)
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
		race_EventLog(ftos(it.race_place), it);
	});

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

	race_SendAll(player, false);
}

MUTATOR_HOOKFUNCTION(rc, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if(g_race_qualifying)
	{
		if(GameRules_scoring_add(player, RACE_FASTEST, 0))
			player.frags = FRAGS_PLAYER_OUT_OF_GAME;
		else
			player.frags = FRAGS_SPECTATOR;
	}

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
		if(CS(player).killcount == FRAGS_SPECTATOR /* initial spawn */ || g_race_qualifying) // spawn
			race_PreparePlayer(player);
		else // respawn
			race_RetractPlayer(player);

		race_AbandonRaceCheck(player);
	}
}

MUTATOR_HOOKFUNCTION(rc, PlayerDamaged)
{
	int frag_deathtype = M_ARGV(5, int);
	if (frag_deathtype == DEATH_KILL.m_id)
		return true; // forbid logging damage
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

	race_checkAndWriteName(player);
	race_SpeedAwardFrame(player);
}

MUTATOR_HOOKFUNCTION(rc, ForbidPlayerScore_Clear)
{
	if(g_race_qualifying)
		return true; // in qualifying, you don't lose score by observing
}

MUTATOR_HOOKFUNCTION(rc, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = race_teams;
	return true;
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
			ret_string = strcat(ret_string, strpad(32, MapInfo_Map_bspname), " ", strpad(-8, TIME_ENCODED_TOSTRING(r, false)), " ", h, "\n");
		}
	}

	M_ARGV(1, string) = ret_string;
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
	radar_showenemies = true;
}

void rc_SetLimits()
{
	int fraglimit_override, leadlimit_override;
	float timelimit_override, qualifying_override;

	if(autocvar_g_race_teams)
	{
		GameRules_teams(true);
		race_teams = BITS(bound(2, autocvar_g_race_teams, 4));
	}
	else
		race_teams = 0;

	qualifying_override = autocvar_g_race_qualifying_timelimit_override;
	fraglimit_override = autocvar_g_race_laps_limit;
	leadlimit_override = 0; // currently not supported by race
	timelimit_override = autocvar_timelimit_override;

	float want_qualifying = ((qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit) > 0;

	record_type = RACE_RECORD;

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
	GameRules_limit_score(fraglimit_override);
	GameRules_limit_lead(leadlimit_override);
	GameRules_limit_time(timelimit_override);
	GameRules_limit_time_qualifying(qualifying_override);
}
