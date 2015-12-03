#ifndef GAMEMODE_RACE_H
#define GAMEMODE_RACE_H

void rc_SetLimits();
void race_Initialize();

REGISTER_MUTATOR(rc, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");

		rc_SetLimits();
		race_Initialize();
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back race_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

float race_teams;

// scores
const float ST_RACE_LAPS = 1;
const float SP_RACE_LAPS = 4;
const float SP_RACE_TIME = 5;
const float SP_RACE_FASTEST = 6;
#endif

#ifdef IMPLEMENTATION

#include "../../race.qh"

#define autocvar_g_race_laps_limit cvar("g_race_laps_limit")
float autocvar_g_race_qualifying_timelimit;
float autocvar_g_race_qualifying_timelimit_override;
int autocvar_g_race_teams;

// legacy bot roles
.float race_checkpoint;
void havocbot_role_race()
{SELFPARAM();
	if(self.deadflag != DEAD_NO)
		return;

	entity e;
	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();

		for(e = world; (e = find(e, classname, "trigger_race_checkpoint")) != world; )
		{
			if(e.cnt == self.race_checkpoint)
			{
				navigation_routerating(e, 1000000, 5000);
			}
			else if(self.race_checkpoint == -1)
			{
				navigation_routerating(e, 1000000, 5000);
			}
		}

		navigation_goalrating_end();
	}
}

void race_ScoreRules()
{
	ScoreRules_basics(race_teams, 0, 0, false);
	if(race_teams)
	{
		ScoreInfo_SetLabel_TeamScore(  ST_RACE_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
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
		GameLogEcho(strcat(":race:", mode, ":", ((actor != world) ? (strcat(":", ftos(actor.playerid))) : "")));
}

float WinningCondition_Race(float fraglimit)
{
	float wc;
	entity p;
	float n, c;

	n = 0;
	c = 0;
	FOR_EACH_PLAYER(p)
	{
		++n;
		if(p.race_completed)
			++c;
	}
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

MUTATOR_HOOKFUNCTION(rc, PlayerPhysics)
{SELFPARAM();
	self.race_movetime_frac += PHYS_INPUT_TIMELENGTH;
	float f = floor(self.race_movetime_frac);
	self.race_movetime_frac -= f;
	self.race_movetime_count += f;
	self.race_movetime = self.race_movetime_frac + self.race_movetime_count;

#ifdef SVQC
	if(IS_PLAYER(self))
	{
		if (self.race_penalty)
			if (time > self.race_penalty)
				self.race_penalty = 0;
		if(self.race_penalty)
		{
			self.velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
			self.disableclientprediction = 2;
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
	wishvel.x = fabs(self.movement.x);
	wishvel.y = fabs(self.movement.y);
	if(wishvel.x != 0 && wishvel.y != 0 && wishvel.x != wishvel.y)
	{
		wishvel.z = 0;
		wishspeed = vlen(wishvel);
		if(wishvel.x >= 2 * wishvel.y)
		{
			// pure X motion
			if(self.movement.x > 0)
				self.movement_x = wishspeed;
			else
				self.movement_x = -wishspeed;
			self.movement_y = 0;
		}
		else if(wishvel.y >= 2 * wishvel.x)
		{
			// pure Y motion
			self.movement_x = 0;
			if(self.movement.y > 0)
				self.movement_y = wishspeed;
			else
				self.movement_y = -wishspeed;
		}
		else
		{
			// diagonal
			if(self.movement.x > 0)
				self.movement_x = M_SQRT1_2 * wishspeed;
			else
				self.movement_x = -M_SQRT1_2 * wishspeed;
			if(self.movement.y > 0)
				self.movement_y = M_SQRT1_2 * wishspeed;
			else
				self.movement_y = -M_SQRT1_2 * wishspeed;
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(rc, reset_map_global)
{
	float s;

	Score_NicePrint(world);

	race_ClearRecords();
	PlayerScore_Sort(race_place, 0, 1, 0);

	entity e;
	FOR_EACH_CLIENT(e)
	{
		if(e.race_place)
		{
			s = PlayerScore_Add(e, SP_RACE_FASTEST, 0);
			if(!s)
				e.race_place = 0;
		}
		race_EventLog(ftos(e.race_place), e);
	}

	if(g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		race_ScoreRules();
	}

	return false;
}

MUTATOR_HOOKFUNCTION(rc, ClientConnect)
{SELFPARAM();
	race_PreparePlayer();
	self.race_checkpoint = -1;

	string rr = RACE_RECORD;

	if(IS_REAL_CLIENT(self))
	{
		msg_entity = self;
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

	return false;
}

MUTATOR_HOOKFUNCTION(rc, MakePlayerObserver)
{SELFPARAM();
	if(g_race_qualifying)
	if(PlayerScore_Add(self, SP_RACE_FASTEST, 0))
		self.frags = FRAGS_LMS_LOSER;
	else
		self.frags = FRAGS_SPECTATOR;

	race_PreparePlayer();
	self.race_checkpoint = -1;

	return false;
}

MUTATOR_HOOKFUNCTION(rc, PlayerSpawn)
{SELFPARAM();
	if(spawn_spot.target == "")
		// Emergency: this wasn't a real spawnpoint. Can this ever happen?
		race_PreparePlayer();

	// if we need to respawn, do it right
	self.race_respawn_checkpoint = self.race_checkpoint;
	self.race_respawn_spotref = spawn_spot;

	self.race_place = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(rc, PutClientInServer)
{SELFPARAM();
	if(IS_PLAYER(self))
	if(!gameover)
	{
		if(self.killcount == FRAGS_SPECTATOR /* initial spawn */ || g_race_qualifying) // spawn
			race_PreparePlayer();
		else // respawn
			race_RetractPlayer();

		race_AbandonRaceCheck(self);
	}
	return false;
}

MUTATOR_HOOKFUNCTION(rc, PlayerDies)
{SELFPARAM();
	self.respawn_flags |= RESPAWN_FORCE;
	race_AbandonRaceCheck(self);
	return false;
}

MUTATOR_HOOKFUNCTION(rc, HavocBot_ChooseRole)
{SELFPARAM();
	self.havocbot_role = havocbot_role_race;
	return true;
}

MUTATOR_HOOKFUNCTION(rc, GetPressedKeys)
{SELFPARAM();
	if(self.cvar_cl_allow_uidtracking == 1 && self.cvar_cl_allow_uid2name == 1)
	{
		if (!self.stored_netname)
			self.stored_netname = strzone(uid2name(self.crypto_idfp));
		if(self.stored_netname != self.netname)
		{
			db_put(ServerProgsDB, strcat("/uid2name/", self.crypto_idfp), self.netname);
			strunzone(self.stored_netname);
			self.stored_netname = strzone(self.netname);
		}
	}

	if (!IS_OBSERVER(self))
	{
		if (vlen(self.velocity - self.velocity_z * '0 0 1') > speedaward_speed)
		{
			speedaward_speed = vlen(self.velocity - self.velocity_z * '0 0 1');
			speedaward_holder = self.netname;
			speedaward_uid = self.crypto_idfp;
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
	return false;
}

MUTATOR_HOOKFUNCTION(rc, ForbidPlayerScore_Clear)
{
	if(g_race_qualifying)
		return true; // in qualifying, you don't lose score by observing

	return false;
}

MUTATOR_HOOKFUNCTION(rc, GetTeamCount, CBC_ORDER_EXCLUSIVE)
{
	ret_float = race_teams;
	return false;
}

MUTATOR_HOOKFUNCTION(rc, Scores_CountFragsRemaining)
{
	// announce remaining frags if not in qualifying mode
	if(!g_race_qualifying)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(rc, GetRecords)
{
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

	return false;
}

MUTATOR_HOOKFUNCTION(rc, FixClientCvars)
{
	stuffcmd(fix_client, "cl_cmd settemp cl_movecliptokeyboard 2\n");
	return false;
}

MUTATOR_HOOKFUNCTION(rc, CheckRules_World)
{
	if(checkrules_timelimit >= 0)
	{
		if(!g_race_qualifying)
		{
			ret_float = WinningCondition_QualifyingThenRace(checkrules_fraglimit);
			return true;
		}
		else if(g_race_qualifying == 2)
		{
			ret_float = WinningCondition_QualifyingThenRace(checkrules_fraglimit);
			return true;
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(rc, ReadLevelCvars)
{
	if(g_race_qualifying == 2)
		warmup_stage = 0;
	return false;
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
		have_team_spawns = -1; // request team spawns
	}
	else
		race_teams = 0;

	qualifying_override = autocvar_g_race_qualifying_timelimit_override;
	fraglimit_override = autocvar_g_race_laps_limit;
	leadlimit_override = 0; // currently not supported by race
	timelimit_override = -1; // use default if we don't set it below

	// we need to find out the correct value for g_race_qualifying
	float want_qualifying = ((qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit) > 0;

	if(autocvar_g_campaign)
	{
		g_race_qualifying = 1;
		independent_players = 1;
	}
	else if(!autocvar_g_campaign && want_qualifying)
	{
		g_race_qualifying = 2;
		independent_players = 1;
		race_fraglimit = (race_fraglimit >= 0) ? fraglimit_override : autocvar_fraglimit;
		race_leadlimit = (race_leadlimit >= 0) ? leadlimit_override : autocvar_leadlimit;
		race_timelimit = (race_timelimit >= 0) ? timelimit_override : autocvar_timelimit;
		fraglimit_override = 0;
		leadlimit_override = 0;
		timelimit_override = autocvar_g_race_qualifying_timelimit;
	}
	else
		g_race_qualifying = 0;

	SetLimits(fraglimit_override, leadlimit_override, timelimit_override, qualifying_override);
}

#endif
