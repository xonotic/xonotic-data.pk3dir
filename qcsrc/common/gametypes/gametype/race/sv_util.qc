#include "sv_util.qh"

#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/mutators/base.qh>
#include <common/state.qh>
#include <server/race.qh>
#include <server/scores.qh>


// legacy bot roles
.float race_checkpoint;
void race_util_havocbot_role(entity this)
{
	if (IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		bool raw_touch_check = true;
		int cp = this.race_checkpoint;

		LABEL(search_racecheckpoints)
		IL_EACH(g_racecheckpoints, it.cnt == cp || cp == -1,
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
		});

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}


// Mutator hook functions

void race_util_PlayerPhysics()
{
	entity player = M_ARGV(0, entity);
	float dt = M_ARGV(1, float);

	player.race_movetime_frac += dt;
	float f = floor(player.race_movetime_frac);
	player.race_movetime_frac -= f;
	player.race_movetime_count += f;
	player.race_movetime = player.race_movetime_frac + player.race_movetime_count;

	if (IS_PLAYER(player))
	{
		if (player.race_penalty
		&& time > player.race_penalty)
			player.race_penalty = 0;
		if (player.race_penalty)
		{
			player.velocity = '0 0 0';
			set_movetype(player, MOVETYPE_NONE);
			player.disableclientprediction = 2;
		}
	}

	// force kbd movement for fairness
	vector wishvel;

	// if record times matter
	// ensure nothing EVIL is being done (i.e. div0_evade)
	// this hinders joystick users though
	// but it still gives SOME analog control
	wishvel.x = fabs(CS(player).movement.x);
	wishvel.y = fabs(CS(player).movement.y);
	if (wishvel.x != 0 && wishvel.y != 0 && wishvel.x != wishvel.y)
	{
		wishvel.z = 0;
		float wishspeed = vlen(wishvel);
		if (wishvel.x >= 2 * wishvel.y)
		{
			// pure X motion
			if (CS(player).movement.x > 0)
				CS(player).movement.x = wishspeed;
			else
				CS(player).movement.x = -wishspeed;
			CS(player).movement.y = 0;
		}
		else if (wishvel.y >= 2 * wishvel.x)
		{
			// pure Y motion
			CS(player).movement.x = 0;
			if (CS(player).movement.y > 0)
				CS(player).movement.y = wishspeed;
			else
				CS(player).movement.y = -wishspeed;
		}
		else
		{
			// diagonal
			if (CS(player).movement.x > 0)
				CS(player).movement.x = M_SQRT1_2 * wishspeed;
			else
				CS(player).movement_x = -M_SQRT1_2 * wishspeed;
			if (CS(player).movement.y > 0)
				CS(player).movement.y = M_SQRT1_2 * wishspeed;
			else
				CS(player).movement.y = -M_SQRT1_2 * wishspeed;
		}
	}
}

void race_util_AbortSpeedrun()
{
	entity player = M_ARGV(0, entity);

	if (autocvar_g_allow_checkpoints)
		race_PreparePlayer(player); // nice try
}

void race_util_reset_map_global(void(string, entity) log)
{
	Score_NicePrint(NULL);

	race_ClearRecords();
	PlayerScore_Sort(race_place, 0, true, false);

	float s;
	FOREACH_CLIENT(true,
	{
		if (it.race_place)
		{
			s = GameRules_scoring_add(it, RACE_FASTEST, 0);
			if (!s)
				it.race_place = 0;
		}
		cts_EventLog(ftos(it.race_place), it);
	});

	if (g_race_qualifying == 2)
	{
		g_race_qualifying = 0;
		independent_players = 0;
		cvar_set("fraglimit", ftos(race_fraglimit));
		cvar_set("leadlimit", ftos(race_leadlimit));
		cvar_set("timelimit", ftos(race_timelimit));
		cts_ScoreRules();
	}
}

void race_util_ClientConnect()
{
	entity player = M_ARGV(0, entity);

	race_PreparePlayer(player);
	player.race_checkpoint = -1;

	race_SendAll(player, false);
}

void race_util_MakePlayerObserver()
{
	entity player = M_ARGV(0, entity);

	race_PreparePlayer(player);
	player.race_checkpoint = -1;
}

void race_util_PlayerSpawn()
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);

	if (spawn_spot.target == "")
		// Emergency: this wasn't a real spawnpoint. Can this ever happen?
		race_PreparePlayer(player);

	// if we need to respawn, do it right
	player.race_respawn_checkpoint = player.race_checkpoint;
	player.race_respawn_spotref = spawn_spot;

	player.race_place = 0;
}

void race_util_PutClientInServer()
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player)
	&& !game_stopped)
	{
		if (CS(player).killcount == FRAGS_SPECTATOR /* initial spawn */ || g_race_qualifying) // spawn
			race_PreparePlayer(player);
		else // respawn
			race_RetractPlayer(player);

		race_AbandonRaceCheck(player);
	}
}

void race_util_PlayerDies()
{
	entity frag_target = M_ARGV(2, entity);

	frag_target.respawn_flags |= RESPAWN_FORCE;
	race_AbandonRaceCheck(frag_target);
}

bool race_util_HavocBot_ChooseRole()
{
	entity bot = M_ARGV(0, entity);

	bot.havocbot_role = race_util_havocbot_role;
	return true;
}

void race_util_GetPressedKeys()
{
	entity player = M_ARGV(0, entity);

	race_checkAndWriteName(player);
	race_SpeedAwardFrame(player);
}

void race_util_GetRecords()
{
	int record_page = M_ARGV(0, int);
	string ret_string = M_ARGV(1, string);

	int start = record_page * 200;
	for (int i = start; i < MapInfo_count && i < start + 200; ++i)
		if (MapInfo_Get_ByID(i))
		{
			float r = race_readTime(MapInfo_Map_bspname, 1);
			if (!r)
				continue;

			string h = race_readName(MapInfo_Map_bspname, 1);
			ret_string = strcat(ret_string, strpad(32, MapInfo_Map_bspname), " ", strpad(-8, TIME_ENCODED_TOSTRING(r, false)), " ", h, "\n");
		}

	M_ARGV(1, string) = ret_string;
}

void race_util_FixClientCvars()
{
	entity player = M_ARGV(0, entity);

	stuffcmd(player, "cl_cmd settemp cl_movecliptokeyboard 2\n");
}
