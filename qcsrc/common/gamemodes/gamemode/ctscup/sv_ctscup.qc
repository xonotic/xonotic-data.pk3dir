#include "sv_ctscup.qh"

#include <server/client.qh>
#include <server/race.qh>
#include <server/world.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
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

MUTATOR_HOOKFUNCTION(ctscup, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	player.frags = FRAGS_SPECTATOR;

	race_PreparePlayer(player);
	player.race_checkpoint = -1;
}

MUTATOR_HOOKFUNCTION(ctscup, PlayerSpawn)
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

MUTATOR_HOOKFUNCTION(ctscup, Damage_Calculate)
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

MUTATOR_HOOKFUNCTION(ctscup, Race_FinalCheckpoint)
{
	entity player = M_ARGV(0, entity);

	// useful to prevent cheating by running back to the start line and starting out with more speed
	if(autocvar_g_cts_finish_kill_delay)
		ClientKill_Silent(player, autocvar_g_cts_finish_kill_delay);
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

// unused as of now, edit sv_ctscup.qh to use this if this becomes used
void ctscup_Initialize()
{
	cts_Initialize();
}
