#include "sv_invasion.qh"

#include <common/mapobjects/triggers.qh>
#include <common/monsters/sv_spawn.qh>
#include <common/monsters/sv_spawner.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>

#include <server/bot/api.qh>
#include <server/world.qh>
#include <server/teamplay.qh>

float autocvar_g_invasion_round_timelimit;
float autocvar_g_invasion_spawnpoint_spawn_delay;
float autocvar_g_invasion_warmup;
int autocvar_g_invasion_monster_count;
bool autocvar_g_invasion_zombies_only;
float autocvar_g_invasion_spawn_delay;
string autocvar_g_invasion_monster_loot = "random";
float autocvar_g_invasion_monster_skill = 0.4;

.bool inv_spawned; // identifier for monsters spawned during the invasion

.int prev_team;

bool inv_warning_shown; // spammy

const int INV_SPAWNPOINT_FLYING = BIT(0); // spawn point will only ever allow flying monsters
const int INV_SPAWNPOINT_SWIMMING = BIT(1); // spawn point will only ever allow swimming monsters

void Invasion_count_alive_players()
{
	total_players = 0;
	Team_SetNumberOfAlivePlayers(Team_GetTeamFromIndex(1), 0);
	FOREACH_CLIENT(IS_PLAYER(it) && Entity_HasValidTeam(it),
	{
		++total_players;
		if (IS_DEAD(it))
		{
			continue;
		}
		entity team_ = Entity_GetTeam(it);
		int num_alive = Team_GetNumberOfAlivePlayers(team_);
		++num_alive;
		Team_SetNumberOfAlivePlayers(team_, num_alive);
	});
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		STAT(REDALIVE, it) = Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1));
	});
}

spawnfunc(invasion_wave)
{
	if(!g_invasion) { delete(this); return; }

	this.active = ACTIVE_ACTIVE;

	IL_PUSH(g_invasion_waves, this);
}

spawnfunc(invasion_spawnpoint)
{
	if(!g_invasion) { delete(this); return; }

	this.active = ACTIVE_ACTIVE;

	IL_PUSH(g_invasion_spawns, this);
}

void ClearWinners();

Monster invasion_PickMonster(entity sp, string preferred_list, int supermonster_count)
{
	RandomSelection_Init();

	// NOTE: flying monsters are still allowed if no spawnpoints exist
	bool only_flying = (sp && (sp.spawnflags & INV_SPAWNPOINT_FLYING));
	bool only_swimming = (sp && (sp.spawnflags & INV_SPAWNPOINT_SWIMMING));

	FOREACH(Monsters, it != MON_Null,
	{
		if((it.spawnflags & (MON_FLAG_HIDDEN | MONSTER_TYPE_PASSIVE | MONSTER_SIZE_QUAKE))
		|| ((it.spawnflags & MON_FLAG_SUPERMONSTER) && supermonster_count >= 1)
		|| ((sp && !only_flying && (it.spawnflags & MONSTER_TYPE_FLY)) || (only_flying && !(it.spawnflags & MONSTER_TYPE_FLY)))
		|| ((!only_swimming && (it.spawnflags & MONSTER_TYPE_SWIM)) || (only_swimming && !(it.spawnflags & MONSTER_TYPE_SWIM))))
			continue;
		if(autocvar_g_invasion_zombies_only && !(it.spawnflags & MONSTER_TYPE_UNDEAD))
			continue;
		int prio = 1;
		if(preferred_list != "" && strstrofs(preferred_list, it.netname, 0) >= 0)
			prio = 2;
		float weight = 1;
		if((it.spawnflags & MONSTER_TYPE_FLY) || (it.spawnflags & MONSTER_TYPE_SWIM))
			weight = 0.25; // even when allowed, low chance!
        RandomSelection_AddEnt(it, weight, prio);
	});

	return RandomSelection_chosen_ent;
}

entity invasion_PickSpawn()
{
	RandomSelection_Init();

	// spawnpoints that have been disabled are forbidden
	// recently used spawnpoints will have a lower priority
	// in zombies only mode, flying/swimming spawnpoints are excluded
	IL_EACH(g_invasion_spawns, it.active == ACTIVE_ACTIVE,
	{
		if(autocvar_g_invasion_zombies_only && ((it.spawnflags & INV_SPAWNPOINT_FLYING) || (it.spawnflags & INV_SPAWNPOINT_SWIMMING)))
			continue;
		RandomSelection_AddEnt(it, 1, (time > it.spawnshieldtime));
	});

	return RandomSelection_chosen_ent;
}

entity invasion_GetWaveEntity(int wavenum)
{
	RandomSelection_Init();
	IL_EACH(g_invasion_waves, it.active == ACTIVE_ACTIVE && it.cnt <= wavenum,
	{
		RandomSelection_AddEnt(it, 1, (it.cnt == wavenum));
	});

	return RandomSelection_chosen_ent;
}

void invasion_SpawnMonster(int supermonster_count)
{
	entity monster = spawn();
	entity spawn_point = invasion_PickSpawn();
	entity wave_ent = invasion_GetWaveEntity(inv_roundcnt);
	string preferred_list = "";

	// spawn point and wave ent monster lists are preferred over random selection
	if(spawn_point)
		preferred_list = cons(preferred_list, spawn_point.spawnmob);
	if(wave_ent)
		preferred_list = cons(preferred_list, wave_ent.spawnmob);

	Monster mon = invasion_PickMonster(spawn_point, preferred_list, supermonster_count);

	monster.inv_spawned = true;
	monster.monster_skill = inv_monsterskill;

	if(!spawn_point)
	{
		if(!inv_warning_shown)
		{
			inv_warning_shown = true;
			LOG_TRACE("Warning: couldn't find any invasion_spawnpoint spawnpoints, attempting to spawn monsters in random locations");
		}
		setsize(monster, mon.m_mins, mon.m_maxs);

		float maxaboveground = ((mon.spawnflags & MONSTER_TYPE_FLY) || (mon.spawnflags & MONSTER_TYPE_SWIM)) ? 2048 : 10;
		int badcontents = DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER;

		if(!(mon.spawnflags & MONSTER_TYPE_SWIM))
			badcontents |= DPCONTENTS_WATER;

		if(MoveToRandomMapLocation(monster, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, badcontents, Q3SURFACEFLAG_SKY, maxaboveground, 1024, 256))
		{
			monster = spawnmonster(monster, "", mon, NULL, NULL, monster.origin, false, false, 2);
			if (!monster)
				return;
			monster.angles_x = monster.angles_z = 0;
		}
		else
		{
			delete(monster);
			return;
		}
	}
	else // if spawnmob field falls through (unset), fallback to mon (relying on spawnmonster for that behaviour)
		monster = spawnmonster(monster, "", mon, spawn_point, spawn_point, spawn_point.origin, false, false, 2);

	if(!monster)
		return;

	StatusEffects_remove(STATUSEFFECT_SpawnShield, monster, STATUSEFFECT_REMOVE_NORMAL);

	if(spawn_point)
	{
		if(spawn_point.target_range)
			monster.target_range = spawn_point.target_range;
		monster.target2 = spawn_point.target2;

		spawn_point.spawnshieldtime = time + autocvar_g_invasion_spawnpoint_spawn_delay;
	}

	if(monster.monster_attack)
		IL_REMOVE(g_monster_targets, monster);
	monster.monster_attack = false; // it's the player's job to kill all the monsters

	// FIXME: vertical movement doesn't actually work, see Monster_Move
	monster.spawnflags |= MONSTERFLAG_FLY_VERTICAL;
}

bool Invasion_CheckWinner()
{
	Invasion_count_alive_players();

	if(total_players <= 0 || (round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0))
	{
		inv_maxspawned = 0;
		inv_maxcurrent = 0;
		inv_numspawned = 0;
		inv_numkilled = 0;

		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);
		return 1;
	}

	if(Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)) == 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);

		// all players eliminated, end the match
		ClearWinners();
		NextLevel();
		return 0;
	}

	float total_alive_monsters = 0, supermonster_count = 0;

	IL_EACH(g_monsters, it.inv_spawned && GetResource(it, RES_HEALTH) > 0,
	{
		if(it.monsterdef.spawnflags & MON_FLAG_SUPERMONSTER)
			++supermonster_count;
		++total_alive_monsters;
	});

	if((total_alive_monsters + inv_numkilled) < inv_maxspawned && inv_maxcurrent < inv_maxspawned)
	{
		if(time >= inv_lastcheck)
		{
			invasion_SpawnMonster(supermonster_count);
			inv_lastcheck = time + autocvar_g_invasion_spawn_delay;
		}

		return 0;
	}

	if(inv_numspawned < 1)
		return 0; // nothing has spawned yet

	if(inv_numkilled < inv_maxspawned)
		return 0;

	int winner_team = NUM_TEAM_1;

	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_SURVIVAL_SURVIVOR_WIN);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SURVIVAL_SURVIVOR_WIN);
	TeamScore_AddToTeam(winner_team, ST_INV_ROUNDS, +1);

	IL_EACH(g_invasion_waves, it.active == ACTIVE_ACTIVE && it.cnt == inv_roundcnt,
	{
		SUB_UseTargets(it, it, NULL);
	});

	inv_roundcnt += 1;

	inv_maxspawned = 0;
	inv_maxcurrent = 0;
	inv_numspawned = 0;
	inv_numkilled = 0;

	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);

	return 1;
}

bool Invasion_CheckPlayers()
{
	static int prev_missing_teams_mask;
	allowed_to_spawn = true;
	Invasion_count_alive_players();
	missing_teams_mask = 0;
	if (Team_GetNumberOfAliveTeams() == AVAILABLE_TEAMS)
		return true;
	if(total_players == 0)
		return false;
	for (int i = 1; i <= AVAILABLE_TEAMS; ++i)
	{
		if ((teamplay_bitmask & Team_IndexToBit(i)) &&
			(Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(i)) == 0))
		{
			missing_teams_mask |= Team_IndexToBit(i);
		}
	}
	if(prev_missing_teams_mask != missing_teams_mask)
		prev_missing_teams_mask = missing_teams_mask;
	return false;
}

void Invasion_RoundStart()
{
	int numplayers = 0;
	FOREACH_CLIENT(IS_PLAYER(it), {
		it.player_blocked = false;
		it.prev_team = it.team;
		++numplayers;
	});

	// TODO: configurable difficulty spike
	inv_monsterskill = max(0.025, autocvar_g_invasion_monster_skill) * inv_roundcnt;

	inv_maxcurrent = 0;
	inv_numspawned = 0;
	inv_numkilled = 0;

	inv_maxspawned = rint(max(autocvar_g_invasion_monster_count, (autocvar_g_invasion_monster_count * (inv_roundcnt * 0.5)) * max(1, numplayers * 0.3)));

	allowed_to_spawn = false;
}

bool inv_isEliminated(entity e)
{
	if(INGAME_JOINED(e) && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
		return true;
	if(INGAME_JOINING(e))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(inv, MonsterDropItem)
{
	if(autocvar_g_invasion_monster_loot == "none")
		M_ARGV(1, string) = "";
	else if(autocvar_g_invasion_monster_loot != "")
		M_ARGV(1, string) = autocvar_g_invasion_monster_loot;
}

MUTATOR_HOOKFUNCTION(inv, reset_map_players)
{
	FOREACH_CLIENT(true, {
		if (inv_isEliminated(it))
		{
			TRANSMUTE(Player, it);
			INGAME_STATUS_SET(it, INGAME_STATUS_JOINED);
			PutClientInServer(it);
		}
		it.prev_team = 0;
	});
	return true;
}

MUTATOR_HOOKFUNCTION(inv, reset_map_global)
{
	allowed_to_spawn = true;
	return true;
}

MUTATOR_HOOKFUNCTION(inv, MatchEnd_BeforeScores)
{
	MatchEnd_RestoreSpectatorAndTeamStatus(prev_team);
	return true;
}

MUTATOR_HOOKFUNCTION(inv, ReadLevelCvars)
{
	// incompatible
	warmup_stage = 0;
	sv_ready_restart_after_countdown = 0;
}

MUTATOR_HOOKFUNCTION(inv, MonsterDies)
{
	entity frag_target = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);

	if(frag_target.inv_spawned && !(frag_target.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		++inv_numkilled;
		--inv_maxcurrent;

		if(IS_PLAYER(frag_attacker))
		{
			if(SAME_TEAM(frag_attacker, frag_target))
				GameRules_scoring_add(frag_attacker, KILLS, -1);
			else
				GameRules_scoring_add(frag_attacker, KILLS, +1);
		}
	}
}

MUTATOR_HOOKFUNCTION(inv, MonsterSpawn)
{
	entity mon = M_ARGV(0, entity);
	mon.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_MONSTERCLIP;

	if(!mon.inv_spawned)
		return false;

	mon.spawnflags |= MONSTERFLAG_NORESPAWN;

	if(!(mon.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		++inv_numspawned;
		++inv_maxcurrent;
	}
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

MUTATOR_HOOKFUNCTION(inv, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	if (!allowed_to_spawn)
	{
		frag_target.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time + 2;
	}
	frag_target.respawn_flags |= RESPAWN_FORCE;
	eliminatedPlayers.SendFlags = 0xFFFFFF;
	return true;
}

MUTATOR_HOOKFUNCTION(inv, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	// spectators / observers that weren't playing can join; they are
	// immediately forced to observe in the PutClientInServer hook
	// this way they are put in a team and can play in the next round
	if (!allowed_to_spawn && INGAME(player))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(inv, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
	eliminatedPlayers.SendFlags = 0xFFFFFF;
}

MUTATOR_HOOKFUNCTION(inv, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if (!allowed_to_spawn && IS_PLAYER(player)) // this is true even when player is trying to join
	{
		TRANSMUTE(Observer, player);
		if (CS(player).jointime != time && !INGAME(player)) // not when connecting
		{
			INGAME_STATUS_SET(player, INGAME_STATUS_JOINING);
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}

	eliminatedPlayers.SendFlags = 0xFFFFFF;
}

MUTATOR_HOOKFUNCTION(inv, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	bool is_forced = M_ARGV(1, bool);
	if (is_forced && INGAME(player))
		INGAME_STATUS_CLEAR(player);

	if (player.killindicator_teamchange == -2) // player wants to spectate
	{
		entcs_update_players(player);
		INGAME_STATUS_CLEAR(player);
	}
	if (INGAME(player))
	{
		player.frags = FRAGS_PLAYER_OUT_OF_GAME;
		player.would_spectate = observe_blocked_if_eliminated; // if blocked from observing force to spectate now
	}
	eliminatedPlayers.SendFlags = 0xFFFFFF;
	if (!INGAME(player))
		return false;  // allow team reset
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(inv, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);
	vector frag_force = M_ARGV(6, vector);

	if (IS_PLAYER(frag_target) && (IS_PLAYER(frag_attacker) || DEATH_IS(frag_deathtype, DEATH_FALL)))
	{
		frag_damage = 0;
		if(frag_attacker != frag_target)
			frag_force = '0 0 0';

		M_ARGV(4, float) = frag_damage;
		M_ARGV(6, vector) = frag_force;
	}

	frag_mirrordamage = 0;

	M_ARGV(5, float) = frag_mirrordamage;
}

MUTATOR_HOOKFUNCTION(inv, Bot_ForbidAttack)
{
	entity targ = M_ARGV(1, entity);

	if(IS_MONSTER(targ))
		return false;

	// don't attack anything else
	return true;
}

MUTATOR_HOOKFUNCTION(inv, CalculateRespawnTime)
{
	// no respawn calculations needed, player is forced to spectate anyway
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

MUTATOR_HOOKFUNCTION(inv, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || INGAME_JOINED(it))
			++M_ARGV(0, int);
		++M_ARGV(1, int);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(inv, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if (INGAME(player))
	{
		// they're going to spec, we can do other checks
		if (autocvar_sv_spectate && (IS_SPEC(player) || IS_OBSERVER(player)))
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(inv, AllowMobSpawning)
{
	// monster spawning disabled during an invasion
	M_ARGV(1, string) = "You cannot spawn monsters during an invasion!";
	return true;
}

MUTATOR_HOOKFUNCTION(inv, AllowMobButcher)
{
	M_ARGV(0, string) = "This command does not work during an invasion!";
	return true;
}

void invasion_ScoreRules()
{
	GameRules_score_enabled(false);
	GameRules_scoring(teamplay_bitmask, SFL_SORT_PRIO_SECONDARY, SFL_SORT_PRIO_SECONDARY, {
		field_team(ST_INV_ROUNDS, "rounds", SFL_SORT_PRIO_PRIMARY);
		field(SP_KILLS, "kills", SFL_SORT_PRIO_PRIMARY);
	});
}

void invasion_DelayedInit(entity this)
{
	invasion_ScoreRules();

	allowed_to_spawn = true;
	round_handler_Spawn(Invasion_CheckPlayers, Invasion_CheckWinner, Invasion_RoundStart);
	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);
	EliminatedPlayers_Init(inv_isEliminated);
}

void invasion_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(false);
	GameRules_limit_lead(0);
	teamplay_bitmask = BIT(0);

	inv_roundcnt = 1;

	InitializeEntity(NULL, invasion_DelayedInit, INITPRIO_GAMETYPE);
}
