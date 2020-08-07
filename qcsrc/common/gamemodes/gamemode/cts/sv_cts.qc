#include "sv_cts.qh"

#include <server/race.qh>
#include <server/items.qh>

float autocvar_g_cts_finish_kill_delay;
bool autocvar_g_cts_selfdamage;
bool autocvar_g_cts_removeprojectiles;

// legacy bot roles
.float race_checkpoint;
void havocbot_role_cts(entity this)
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
				// the same workaround is applied in Race game mode
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

void cts_ScoreRules()
{
    GameRules_score_enabled(false);
    GameRules_scoring(0, 0, 0, {
        if (g_race_qualifying) {
            field(SP_RACE_FASTEST, "fastest", SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
        } else {
            field(SP_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
            field(SP_RACE_TIME, "time", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
            field(SP_RACE_FASTEST, "fastest", SFL_LOWER_IS_BETTER | SFL_TIME);
        }
    });
}

void cts_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":cts:", mode, ":", ((actor != NULL) ? (strcat(":", ftos(actor.playerid))) : "")));
}

MUTATOR_HOOKFUNCTION(cts, PlayerPhysics)
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

MUTATOR_HOOKFUNCTION(cts, reset_map_global)
{
	float s;

	Score_NicePrint(NULL);

	race_ClearRecords();
	PlayerScore_Sort(race_place, 0, 1, 0);

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

MUTATOR_HOOKFUNCTION(cts, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	race_PreparePlayer(player);
	player.race_checkpoint = -1;

	if(IS_REAL_CLIENT(player))
	{
		string rr = CTS_RECORD;

		msg_entity = player;
		race_send_recordtime(MSG_ONE);
		race_send_speedaward(MSG_ONE);

		speedaward_alltimebest = stof(db_get(ServerProgsDB, strcat(GetMapname(), rr, "speed/speed")));
		speedaward_alltimebest_holder = uid2name(db_get(ServerProgsDB, strcat(GetMapname(), rr, "speed/crypto_idfp")));
		race_send_speedaward_alltimebest(MSG_ONE);

		float i;
		int m = min(RANKINGS_CNT, autocvar_g_cts_send_rankings_cnt);
		race_send_rankings_cnt(MSG_ONE);
		for (i = 1; i <= m; ++i)
		{
			race_SendRankings(i, 0, 0, MSG_ONE);
		}
	}
}

MUTATOR_HOOKFUNCTION(cts, AbortSpeedrun)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_allow_checkpoints)
		race_PreparePlayer(player); // nice try
}

MUTATOR_HOOKFUNCTION(cts, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if(GameRules_scoring_add(player, RACE_FASTEST, 0))
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
	else
		player.frags = FRAGS_SPECTATOR;

	race_PreparePlayer(player);
	player.race_checkpoint = -1;
}

MUTATOR_HOOKFUNCTION(cts, PlayerSpawn)
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

MUTATOR_HOOKFUNCTION(cts, PutClientInServer)
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

MUTATOR_HOOKFUNCTION(cts, PlayerDies)
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

MUTATOR_HOOKFUNCTION(cts, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	bot.havocbot_role = havocbot_role_cts;
	return true;
}

MUTATOR_HOOKFUNCTION(cts, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	if(CS(player).cvar_cl_allow_uidtracking == 1 && CS(player).cvar_cl_allow_uid2name == 1)
	{
		if (!player.stored_netname)
			player.stored_netname = strzone(uid2name(player.crypto_idfp));
		if(player.stored_netname != player.netname)
		{
			db_put(ServerProgsDB, strcat("/uid2name/", player.crypto_idfp), player.netname);
			strcpy(player.stored_netname, player.netname);
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
}

MUTATOR_HOOKFUNCTION(cts, ForbidThrowCurrentWeapon)
{
	// no weapon dropping in CTS
	return true;
}

MUTATOR_HOOKFUNCTION(cts, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (Item_IsLoot(item))
	{
		return true;
	}
}

MUTATOR_HOOKFUNCTION(cts, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if(frag_target == frag_attacker || frag_deathtype == DEATH_FALL.m_id)
	if(!autocvar_g_cts_selfdamage)
	{
		frag_damage = 0;
		M_ARGV(4, float) = frag_damage;
	}
}

MUTATOR_HOOKFUNCTION(cts, ForbidPlayerScore_Clear)
{
	return true; // in CTS, you don't lose score by observing
}

MUTATOR_HOOKFUNCTION(cts, GetRecords)
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

MUTATOR_HOOKFUNCTION(cts, ClientKill)
{
	M_ARGV(1, float) = 0; // kill delay
}

MUTATOR_HOOKFUNCTION(cts, Race_FinalCheckpoint)
{
	entity player = M_ARGV(0, entity);

	// useful to prevent cheating by running back to the start line and starting out with more speed
	if(autocvar_g_cts_finish_kill_delay)
		ClientKill_Silent(player, autocvar_g_cts_finish_kill_delay);
}

MUTATOR_HOOKFUNCTION(cts, HideTeamNagger)
{
	return true; // doesn't work so well (but isn't cts a teamless mode?)
}

MUTATOR_HOOKFUNCTION(cts, FixClientCvars)
{
	entity player = M_ARGV(0, entity);

	stuffcmd(player, "cl_cmd settemp cl_movecliptokeyboard 2\n");
}

MUTATOR_HOOKFUNCTION(cts, WantWeapon)
{
	M_ARGV(1, float) = (M_ARGV(0, entity) == WEP_SHOTGUN); // want weapon = weapon info
	M_ARGV(3, bool) = true; // want mutator blocked
	return true;
}

MUTATOR_HOOKFUNCTION(cts, ForbidDropCurrentWeapon)
{
	return true;
}

void cts_Initialize()
{
	cts_ScoreRules();
}
