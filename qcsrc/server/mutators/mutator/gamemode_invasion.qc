#include "gamemode_invasion.qh"

#include <common/monsters/sv_spawn.qh>
#include <common/monsters/sv_monsters.qh>

#include <server/teamplay.qh>

IntrusiveList g_invasion_waves;
STATIC_INIT(g_invasion_waves) { g_invasion_waves = IL_NEW(); }

IntrusiveList g_invasion_spawns;
STATIC_INIT(g_invasion_spawns) { g_invasion_spawns = IL_NEW(); }

float autocvar_g_invasion_round_timelimit;
float autocvar_g_invasion_spawnpoint_spawn_delay;
float autocvar_g_invasion_warmup;
int autocvar_g_invasion_monster_count;
bool autocvar_g_invasion_zombies_only;
float autocvar_g_invasion_spawn_delay;

.string spawnmob;

spawnfunc(invasion_wave)
{
	if(!g_invasion) { delete(this); return; }

	IL_PUSH(g_invasion_waves, this);
}

spawnfunc(invasion_spawnpoint)
{
	if(!g_invasion) { delete(this); return; }

	this.classname = "invasion_spawnpoint";
	IL_PUSH(g_invasion_spawns, this);
}

Monster invasion_PickMonster(int supermonster_count)
{
	RandomSelection_Init();

	FOREACH(Monsters, it != MON_Null,
	{
		if((it.spawnflags & MON_FLAG_HIDDEN) || (it.spawnflags & MONSTER_TYPE_PASSIVE) || (it.spawnflags & MONSTER_TYPE_FLY) || (it.spawnflags & MONSTER_TYPE_SWIM) ||
			(it.spawnflags & MONSTER_SIZE_QUAKE) || ((it.spawnflags & MON_FLAG_SUPERMONSTER) && supermonster_count >= 1))
			continue;
		if(autocvar_g_invasion_zombies_only && !(it.spawnflags & MONSTER_TYPE_UNDEAD))
			continue;
        RandomSelection_AddEnt(it, 1, 1);
	});

	return RandomSelection_chosen_ent;
}

entity invasion_PickSpawn()
{
	RandomSelection_Init();

	IL_EACH(g_invasion_spawns, true,
	{
		RandomSelection_AddEnt(it, 1, ((time < it.spawnshieldtime) ? 0.2 : 1)); // give recently used spawnpoints a very low rating
		it.spawnshieldtime = time + autocvar_g_invasion_spawnpoint_spawn_delay;
	});

	return RandomSelection_chosen_ent;
}

entity invasion_GetWaveEntity(int wavenum)
{
	IL_EACH(g_invasion_waves, it.cnt == wavenum,
	{
		return it; // found one
	});

	// if no specific one is found, find the last existing wave ent
	entity best = NULL;
	IL_EACH(g_invasion_waves, it.cnt <= wavenum,
	{
		if(!best || it.cnt > best.cnt)
			best = it;
	});

	return best;
}

void invasion_SpawnChosenMonster(Monster mon)
{
	entity monster;
	entity spawn_point = invasion_PickSpawn();
	entity wave_ent = invasion_GetWaveEntity(inv_roundcnt);

	string tospawn = "";
	if(wave_ent && wave_ent.spawnmob && wave_ent.spawnmob != "")
	{
		RandomSelection_Init();
		FOREACH_WORD(wave_ent.spawnmob, true,
		{
			RandomSelection_AddString(it, 1, 1);
		});

		tospawn = RandomSelection_chosen_string;
	}

	if(spawn_point == NULL)
	{
		LOG_TRACE("Warning: couldn't find any invasion_spawnpoint spawnpoints, attempting to spawn monsters in random locations");
		entity e = spawn();
		setsize(e, mon.mins, mon.maxs);

		if(MoveToRandomMapLocation(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
			monster = spawnmonster(e, tospawn, mon.monsterid, NULL, NULL, e.origin, false, false, 2);
		else
		{
			delete(e);
			return;
		}
	}
	else // if spawnmob field falls through (unset), fallback to mon (relying on spawnmonster for that behaviour)
		monster = spawnmonster(spawn(), ((spawn_point.spawnmob && spawn_point.spawnmob != "") ? spawn_point.spawnmob : tospawn), mon.monsterid, spawn_point, spawn_point, spawn_point.origin, false, false, 2);

	if(!monster)
		return;

	monster.spawnshieldtime = time;

	if(spawn_point)
	{
		if(spawn_point.target_range)
			monster.target_range = spawn_point.target_range;
		monster.target2 = spawn_point.target2;
	}

	if(teamplay)
	{
		if(spawn_point && spawn_point.team && inv_monsters_perteam[spawn_point.team] > 0)
			monster.team = spawn_point.team;
		else
		{
			RandomSelection_Init();
			if(inv_monsters_perteam[NUM_TEAM_1] > 0) RandomSelection_AddFloat(NUM_TEAM_1, 1, 1);
			if(inv_monsters_perteam[NUM_TEAM_2] > 0) RandomSelection_AddFloat(NUM_TEAM_2, 1, 1);
			if(invasion_teams >= 3) if(inv_monsters_perteam[NUM_TEAM_3] > 0) { RandomSelection_AddFloat(NUM_TEAM_3, 1, 1); }
			if(invasion_teams >= 4) if(inv_monsters_perteam[NUM_TEAM_4] > 0) { RandomSelection_AddFloat(NUM_TEAM_4, 1, 1); }

			monster.team = RandomSelection_chosen_float;
		}

		monster_setupcolors(monster);

		if(monster.sprite)
		{
			WaypointSprite_UpdateTeamRadar(monster.sprite, RADARICON_DANGER, ((monster.team) ? Team_ColorRGB(monster.team) : '1 0 0'));

			monster.sprite.team = 0;
			monster.sprite.SendFlags |= 1;
		}
	}

	monster.monster_attack = false; // it's the player's job to kill all the monsters

	if(inv_roundcnt >= inv_maxrounds)
		monster.spawnflags |= MONSTERFLAG_MINIBOSS; // last round spawns minibosses
}

void invasion_SpawnMonsters(int supermonster_count)
{
	Monster chosen_monster = invasion_PickMonster(supermonster_count);

	invasion_SpawnChosenMonster(chosen_monster);
}

bool Invasion_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		IL_EACH(g_monsters, true,
		{
			Monster_Remove(it);
		});
		IL_CLEAR(g_monsters);

		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);
		return 1;
	}

	float total_alive_monsters = 0, supermonster_count = 0, red_alive = 0, blue_alive = 0, yellow_alive = 0, pink_alive = 0;

	IL_EACH(g_monsters, it.health > 0,
	{
		if((get_monsterinfo(it.monsterid)).spawnflags & MON_FLAG_SUPERMONSTER)
			++supermonster_count;
		++total_alive_monsters;

		if(teamplay)
		switch(it.team)
		{
			case NUM_TEAM_1: ++red_alive; break;
			case NUM_TEAM_2: ++blue_alive; break;
			case NUM_TEAM_3: ++yellow_alive; break;
			case NUM_TEAM_4: ++pink_alive; break;
		}
	});

	if((total_alive_monsters + inv_numkilled) < inv_maxspawned && inv_maxcurrent < inv_maxspawned)
	{
		if(time >= inv_lastcheck)
		{
			invasion_SpawnMonsters(supermonster_count);
			inv_lastcheck = time + autocvar_g_invasion_spawn_delay;
		}

		return 0;
	}

	if(inv_numspawned < 1)
		return 0; // nothing has spawned yet

	if(teamplay)
	{
		if(((red_alive > 0) + (blue_alive > 0) + (yellow_alive > 0) + (pink_alive > 0)) > 1)
			return 0;
	}
	else if(inv_numkilled < inv_maxspawned)
		return 0;

	entity winner = NULL;
	float winning_score = 0, winner_team = 0;


	if(teamplay)
	{
		if(red_alive > 0) { winner_team = NUM_TEAM_1; }
		if(blue_alive > 0)
		if(winner_team) { winner_team = 0; }
		else { winner_team = NUM_TEAM_2; }
		if(yellow_alive > 0)
		if(winner_team) { winner_team = 0; }
		else { winner_team = NUM_TEAM_3; }
		if(pink_alive > 0)
		if(winner_team) { winner_team = 0; }
		else { winner_team = NUM_TEAM_4; }
	}
	else
	{
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
			float cs = PlayerScore_Add(it, SP_KILLS, 0);
			if(cs > winning_score)
			{
				winning_score = cs;
				winner = it;
			}
		));
	}

	IL_EACH(g_monsters, true,
	{
		Monster_Remove(it);
	});
	IL_CLEAR(g_monsters);

	if(teamplay)
	{
		if(winner_team)
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		}
	}
	else if(winner)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_PLAYER_WIN, winner.netname);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_PLAYER_WIN, winner.netname);
	}

	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);

	return 1;
}

bool Invasion_CheckPlayers()
{
	return true;
}

void Invasion_RoundStart()
{
	int numplayers = 0;
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		it.player_blocked = false;
		++numplayers;
	));

	if(inv_roundcnt < inv_maxrounds)
		inv_roundcnt += 1; // a limiter to stop crazy counts

	inv_monsterskill = inv_roundcnt + max(1, numplayers * 0.3);

	inv_maxcurrent = 0;
	inv_numspawned = 0;
	inv_numkilled = 0;

	inv_maxspawned = rint(max(autocvar_g_invasion_monster_count, autocvar_g_invasion_monster_count * (inv_roundcnt * 0.5)));

	if(teamplay)
	{
		DistributeEvenly_Init(inv_maxspawned, invasion_teams);
		inv_monsters_perteam[NUM_TEAM_1] = DistributeEvenly_Get(1);
		inv_monsters_perteam[NUM_TEAM_2] = DistributeEvenly_Get(1);
		if(invasion_teams >= 3) inv_monsters_perteam[NUM_TEAM_3] = DistributeEvenly_Get(1);
		if(invasion_teams >= 4) inv_monsters_perteam[NUM_TEAM_4] = DistributeEvenly_Get(1);
	}
}

MUTATOR_HOOKFUNCTION(inv, MonsterDies)
{
	entity frag_target = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);

	if(!(frag_target.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		inv_numkilled += 1;
		inv_maxcurrent -= 1;
		if(teamplay) { inv_monsters_perteam[frag_target.team] -= 1; }

		if(IS_PLAYER(frag_attacker))
		if(SAME_TEAM(frag_attacker, frag_target)) // in non-teamplay modes, same team = same player, so this works
			PlayerScore_Add(frag_attacker, SP_KILLS, -1);
		else
		{
			PlayerScore_Add(frag_attacker, SP_KILLS, +1);
			if(teamplay)
				TeamScore_AddToTeam(frag_attacker.team, ST_INV_KILLS, +1);
		}
	}
}

MUTATOR_HOOKFUNCTION(inv, MonsterSpawn)
{
	entity mon = M_ARGV(0, entity);

	if(!(mon.spawnflags & MONSTERFLAG_SPAWNED))
		return true;

	if(!(mon.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		inv_numspawned += 1;
		inv_maxcurrent += 1;
	}

	mon.monster_skill = inv_monsterskill;

	if((get_monsterinfo(mon.monsterid)).spawnflags & MON_FLAG_SUPERMONSTER)
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_INVASION_SUPERMONSTER, mon.monster_name);

	mon.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_MONSTERCLIP;
}

MUTATOR_HOOKFUNCTION(inv, OnEntityPreSpawn)
{
	entity ent = M_ARGV(0, entity);

	// TODO: allow these as "rogues" or something
	if(startsWith(ent.classname, "monster_"))
	if(!(ent.spawnflags & MONSTERFLAG_SPAWNED))
		return true;
}

MUTATOR_HOOKFUNCTION(inv, SV_StartFrame)
{
	monsters_total = inv_maxspawned; // TODO: make sure numspawned never exceeds maxspawned
	monsters_killed = inv_numkilled;
}

MUTATOR_HOOKFUNCTION(inv, PlayerRegen)
{
	// no regeneration in invasion
	return true;
}

MUTATOR_HOOKFUNCTION(inv, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(player.bot_attack)
		IL_REMOVE(g_bot_targets, player);
	player.bot_attack = false;
}

MUTATOR_HOOKFUNCTION(inv, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(6, vector);

	if(IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target) && frag_attacker != frag_target)
	{
		frag_damage = 0;
		frag_force = '0 0 0';

		M_ARGV(4, float) = frag_damage;
		M_ARGV(6, vector) = frag_force;
	}
}

MUTATOR_HOOKFUNCTION(inv, SV_ParseClientCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return;

	entity player = M_ARGV(0, entity);
	string cmd_name = M_ARGV(1, string);

	if(cmd_name == "debuginvasion")
	{
		sprint(player, strcat("inv_maxspawned = ", ftos(inv_maxspawned), "\n"));
		sprint(player, strcat("inv_numspawned = ", ftos(inv_numspawned), "\n"));
		sprint(player, strcat("inv_numkilled = ", ftos(inv_numkilled), "\n"));
		sprint(player, strcat("inv_roundcnt = ", ftos(inv_roundcnt), "\n"));
		sprint(player, strcat("monsters_total = ", ftos(monsters_total), "\n"));
		sprint(player, strcat("monsters_killed = ", ftos(monsters_killed), "\n"));
		sprint(player, strcat("inv_monsterskill = ", ftos(inv_monsterskill), "\n"));

		return true;
	}
}

MUTATOR_HOOKFUNCTION(inv, BotShouldAttack)
{
	entity targ = M_ARGV(1, entity);

	if(!IS_MONSTER(targ))
		return true;
}

MUTATOR_HOOKFUNCTION(inv, SetStartItems)
{
	start_health = 200;
	start_armorvalue = 200;
}

MUTATOR_HOOKFUNCTION(inv, AccuracyTargetValid)
{
	entity frag_target = M_ARGV(1, entity);

	if(IS_MONSTER(frag_target))
		return MUT_ACCADD_INVALID;
	return MUT_ACCADD_INDIFFERENT;
}

MUTATOR_HOOKFUNCTION(inv, AllowMobSpawning)
{
	// monster spawning disabled during an invasion
	M_ARGV(1, string) = "You cannot spawn monsters during an invasion!";
	return true;
}

MUTATOR_HOOKFUNCTION(inv, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = invasion_teams;
}

MUTATOR_HOOKFUNCTION(inv, AllowMobButcher)
{
	M_ARGV(0, string) = "This command does not work during an invasion!";
	return true;
}

void invasion_ScoreRules(int inv_teams)
{
	if(inv_teams) { CheckAllowedTeams(NULL); }
	ScoreRules_basics(inv_teams, 0, 0, false);
	if(inv_teams) ScoreInfo_SetLabel_TeamScore(ST_INV_KILLS, "frags", SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_KILLS, "frags", ((inv_teams) ? SFL_SORT_PRIO_SECONDARY : SFL_SORT_PRIO_PRIMARY));
	ScoreRules_basics_end();
}

void invasion_DelayedInit(entity this) // Do this check with a delay so we can wait for teams to be set up.
{
	if(autocvar_g_invasion_teams)
	{
		invasion_teams = bound(2, autocvar_g_invasion_teams, 4);
		int teams = 0;
		if(invasion_teams >= 1) teams |= BIT(0);
		if(invasion_teams >= 2) teams |= BIT(1);
		if(invasion_teams >= 3) teams |= BIT(2);
		if(invasion_teams >= 4) teams |= BIT(3);

		invasion_teams = teams; // now set it?
	}
	else
		invasion_teams = 0;

	independent_players = 1; // to disable extra useless scores

	invasion_ScoreRules(invasion_teams);

	independent_players = 0;

	round_handler_Spawn(Invasion_CheckPlayers, Invasion_CheckWinner, Invasion_RoundStart);
	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);

	inv_roundcnt = 0;
	inv_maxrounds = 15; // 15?
}

void invasion_Initialize()
{
	InitializeEntity(NULL, invasion_DelayedInit, INITPRIO_GAMETYPE);
}
