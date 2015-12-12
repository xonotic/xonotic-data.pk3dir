#include "../../race.qh"

#ifndef GAMEMODE_CTS_H
#define GAMEMODE_CTS_H

void cts_Initialize();

REGISTER_MUTATOR(cts, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");

		g_race_qualifying = true;
		independent_players = 1;
		SetLimits(0, 0, -1, -1);

		cts_Initialize();
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back cts_Initialize here
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

// scores
const float ST_CTS_LAPS = 1;
const float SP_CTS_LAPS = 4;
const float SP_CTS_TIME = 5;
const float SP_CTS_FASTEST = 6;
#endif

#ifdef IMPLEMENTATION

#include "../../race.qh"

float autocvar_g_cts_finish_kill_delay;
bool autocvar_g_cts_selfdamage;

// legacy bot roles
.float race_checkpoint;
void havocbot_role_cts()
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

void cts_ScoreRules()
{
	ScoreRules_basics(0, 0, 0, false);
	if(g_race_qualifying)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_CTS_FASTEST, "fastest",   SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	else
	{
		ScoreInfo_SetLabel_PlayerScore(SP_CTS_LAPS,    "laps",      SFL_SORT_PRIO_PRIMARY);
		ScoreInfo_SetLabel_PlayerScore(SP_CTS_TIME,    "time",      SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		ScoreInfo_SetLabel_PlayerScore(SP_CTS_FASTEST, "fastest",   SFL_LOWER_IS_BETTER | SFL_TIME);
	}
	ScoreRules_basics_end();
}

void cts_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":cts:", mode, ":", ((actor != world) ? (strcat(":", ftos(actor.playerid))) : "")));
}

void CTS_ClientKill(entity e) // silent version of ClientKill, used when player finishes a CTS run. Useful to prevent cheating by running back to the start line and starting out with more speed
{
    e.killindicator = spawn();
    e.killindicator.owner = e;
    e.killindicator.think = KillIndicator_Think;
    e.killindicator.nextthink = time + (e.lip) * 0.05;
    e.killindicator.cnt = ceil(autocvar_g_cts_finish_kill_delay);
    e.killindicator.health = 1; // this is used to indicate that it should be silent
    e.lip = 0;
}

MUTATOR_HOOKFUNCTION(cts, PlayerPhysics)
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

MUTATOR_HOOKFUNCTION(cts, reset_map_global)
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
		cts_EventLog(ftos(e.race_place), e);
	}

	if(g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		cts_ScoreRules();
	}

	return false;
}

MUTATOR_HOOKFUNCTION(cts, ClientConnect)
{SELFPARAM();
	race_PreparePlayer();
	self.race_checkpoint = -1;

	if(IS_REAL_CLIENT(self))
	{
		string rr = CTS_RECORD;

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

MUTATOR_HOOKFUNCTION(cts, MakePlayerObserver)
{SELFPARAM();
	if(PlayerScore_Add(self, SP_RACE_FASTEST, 0))
		self.frags = FRAGS_LMS_LOSER;
	else
		self.frags = FRAGS_SPECTATOR;

	race_PreparePlayer();
	self.race_checkpoint = -1;

	return false;
}

MUTATOR_HOOKFUNCTION(cts, PlayerSpawn)
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

MUTATOR_HOOKFUNCTION(cts, PutClientInServer)
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

MUTATOR_HOOKFUNCTION(cts, PlayerDies)
{SELFPARAM();
	self.respawn_flags |= RESPAWN_FORCE;
	race_AbandonRaceCheck(self);
	return false;
}

MUTATOR_HOOKFUNCTION(cts, HavocBot_ChooseRole)
{SELFPARAM();
	self.havocbot_role = havocbot_role_cts;
	return true;
}

MUTATOR_HOOKFUNCTION(cts, GetPressedKeys)
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
			string rr = CTS_RECORD;
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

MUTATOR_HOOKFUNCTION(cts, ForbidThrowCurrentWeapon)
{
	// no weapon dropping in CTS
	return true;
}

MUTATOR_HOOKFUNCTION(cts, FilterItem)
{SELFPARAM();
	if(self.classname == "droppedweapon")
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(cts, PlayerDamage_Calculate)
{
	if(frag_target == frag_attacker || frag_deathtype == DEATH_FALL.m_id)
	if(!autocvar_g_cts_selfdamage)
		frag_damage = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(cts, ForbidPlayerScore_Clear)
{
	return true; // in CTS, you don't lose score by observing
}

MUTATOR_HOOKFUNCTION(cts, GetRecords)
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

MUTATOR_HOOKFUNCTION(cts, ClientKill)
{
	ret_float = 0;

	if(self.killindicator && self.killindicator.health == 1) // self.killindicator.health == 1 means that the kill indicator was spawned by CTS_ClientKill
	{
		remove(self.killindicator);
		self.killindicator = world;

		ClientKill_Now(); // allow instant kill in this case
		return;
	}

}

MUTATOR_HOOKFUNCTION(cts, Race_FinalCheckpoint)
{
	if(autocvar_g_cts_finish_kill_delay)
		CTS_ClientKill(race_player);

	return false;
}

MUTATOR_HOOKFUNCTION(cts, FixClientCvars)
{
	stuffcmd(fix_client, "cl_cmd settemp cl_movecliptokeyboard 2\n");
	return false;
}

MUTATOR_HOOKFUNCTION(cts, WantWeapon)
{
	ret_float = (want_weaponinfo == WEP_SHOTGUN);
	want_mutatorblocked = true;
	return true;
}

void cts_Initialize()
{
	cts_ScoreRules();
}

#endif
