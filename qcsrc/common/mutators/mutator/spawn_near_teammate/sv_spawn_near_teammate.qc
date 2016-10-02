#include "sv_spawn_near_teammate.qh"

float autocvar_g_spawn_near_teammate_distance;
int autocvar_g_spawn_near_teammate_ignore_spawnpoint;
float autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
float autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death;
int autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health;
bool autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath;

REGISTER_MUTATOR(spawn_near_teammate, cvar("g_spawn_near_teammate"));

.entity msnt_lookat;

.float msnt_timer;
.vector msnt_deathloc;

.float cvar_cl_spawn_near_teammate;

MUTATOR_HOOKFUNCTION(spawn_near_teammate, Spawn_Score)
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);
	vector spawn_score = M_ARGV(2, vector);

	//LOG_INFOF("Spawn_Score player: %s %v spawn_spot: %v spawn_score: %f\n", player.netname, player.origin, spawn_spot.origin, spawn_score);

	if(autocvar_g_spawn_near_teammate_ignore_spawnpoint == 1 || (autocvar_g_spawn_near_teammate_ignore_spawnpoint == 2 && player.cvar_cl_spawn_near_teammate))
		return;

	spawn_spot.msnt_lookat = NULL;

	if(!teamplay)
		return;

	RandomSelection_Init();
	FOREACH_CLIENT(IS_PLAYER(it) && it != player && SAME_TEAM(it, player) && !IS_DEAD(it), LAMBDA(
		if(vdist(spawn_spot.origin - it.origin, >, autocvar_g_spawn_near_teammate_distance))
			continue;
		if(vdist(spawn_spot.origin - it.origin, <, 48))
			continue;
		if(!checkpvs(spawn_spot.origin, it))
			continue;
		RandomSelection_Add(it, 0, string_null, 1, 1);
	));

	if(RandomSelection_chosen_ent)
	{
		spawn_spot.msnt_lookat = RandomSelection_chosen_ent;
		spawn_score.x += SPAWN_PRIO_NEAR_TEAMMATE_FOUND;
	}
	else if(player.team == spawn_spot.team)
		spawn_score.x += SPAWN_PRIO_NEAR_TEAMMATE_SAMETEAM; // prefer same team, if we can't find a spawn near teammate

	//LOG_INFOF("Spawn_Score ret %v", spawn_score);
	M_ARGV(2, vector) = spawn_score;
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerSpawn)
{
	//if(!teamplay) { return; } // TODO DEBUGGING
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);

	LOG_INFOF("PlayerSpawn for player: %s %v spawn_spot: %v\n", player.netname, player.origin, spawn_spot.origin);

	/*
	int num_red = 0, num_blue = 0, num_yellow = 0, num_pink = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		switch(it.team)
		{
			case NUM_TEAM_1: ++num_red; break;
			case NUM_TEAM_2: ++num_blue; break;
			case NUM_TEAM_3: ++num_yellow; break;
			case NUM_TEAM_4: ++num_pink; break;
		}
	});

	if(num_red == 1 || num_blue == 1 || num_yellow == 1 || num_pink == 1)
		return; // at least 1 team has only 1 player, let's not give the bigger team too much of an advantage!
	*/ // // TODO DEBUGING

	// Note: when entering this, fixangle is already set.
	if(autocvar_g_spawn_near_teammate_ignore_spawnpoint == 1 || (autocvar_g_spawn_near_teammate_ignore_spawnpoint == 2 && player.cvar_cl_spawn_near_teammate))
	{
		if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death)
			player.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death;

		entity best_mate = NULL;
		vector best_pos = '0 0 0';
		float pc = 0, best_dist = 0, dist = 0;
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
			LOG_INFOF("  for client: %s %v\n", it.netname, it.origin);
			//if (!SAME_TEAM(player, it)) continue; // TODO DEBUGING
			if (autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health >= 0 && it.health < autocvar_g_balance_health_regenstable) continue;
			if (IS_DEAD(it)) continue;
			if (time < it.msnt_timer) continue;
			if (time < it.spawnshieldtime) continue;
			if (forbidWeaponUse(it)) continue;
			if (STAT(FROZEN, it)) continue;
			if (it == player) continue;

			// TODO check for nades

			vector horiz_vel = vec2(it.velocity);
			if(vdist(horiz_vel, >, 450)) {
				fixedmakevectors(vectoangles(horiz_vel));
				LOG_INFOF("    using velocity -> forward: %v\n", v_forward);
			} else {
				fixedmakevectors(it.angles); // .angles is the angle of the model - usually/always 0 pitch
				LOG_INFOF("    using angles -> forward: %v\n", v_forward);
			}

			// test diffrent spots close to mate - trace upwards so it works on uneven surfaces
			for(pc = 0; pc < 4; ++pc)
			{
				switch(pc)
				{
					case 0:
						tracebox(it.origin, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin + v_right * 128 + v_up * 64, MOVE_NOMONSTERS, it);
						break;
					case 1:
						tracebox(it.origin, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - v_right * 128 + v_up * 64, MOVE_NOMONSTERS, it);
						break;
					case 2:
						tracebox(it.origin, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin + v_right * 128 - v_forward * 64 + v_up * 64, MOVE_NOMONSTERS, it);
						break;
					case 3:
						tracebox(it.origin, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - v_right * 128 - v_forward * 64 + v_up * 64, MOVE_NOMONSTERS, it);
						break;
				}
				vector prev_endpos = trace_endpos;
				te_lightning1(NULL, it.origin, trace_endpos);
				LOG_INFOF("    pc: %d trace_fraction %f\n", pc, trace_fraction);
				if(trace_fraction != 1.0) continue;

				// 400 is slightly more than a typical laser jump (in overkill)
				tracebox(trace_endpos + '0 0 4', STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), trace_endpos - '0 0 400', MOVE_NORMAL, it);
				te_lightning2(NULL, prev_endpos, trace_endpos);
				LOG_INFOF("      trace_fraction2 %f\n", trace_fraction);
				if (trace_startsolid) continue; // inside another player
				if (trace_fraction == 1.0) continue; // above void or too high
				if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY) continue;
				if (pointcontents(trace_endpos + '0 0 1') != CONTENT_EMPTY) continue; // this also prevents spawning in water which i assume would be annoying
				// TODO top of implosion towers

				if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath)
				{
					dist = vlen(trace_endpos - player.msnt_deathloc);
					LOG_INFOF("      dist: %f, best_dist %f\n", dist, best_dist);
					if(dist < best_dist || best_dist == 0)
					{
						LOG_INFOF("      new best dist - pos: %v\n", trace_endpos);
						best_dist = dist;
						best_pos = trace_endpos;
						best_mate = it;
					}
				}
				else // TODO random to avoid favoring players who joined early
				{
					setorigin(player, trace_endpos);
					player.angles = it.angles;
					player.angles_z = 0; // never spawn tilted even if the spot says to
					it.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
					LOG_INFOF("      PlayerSpawn return %v\n", player.origin);
					if (player.origin != trace_endpos) LOG_WARNF("wrong origin\n");
					return;
				}
			}
		));

		if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath)
		if(best_dist)
		{
			tracebox(best_pos, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), best_pos + '0 0 1', MOVE_NOMONSTERS, player);
			if (trace_startsolid || trace_fraction != 1.0) LOG_WARNF("bad spawn? %d %f", trace_startsolid, trace_fraction);
			setorigin(player, best_pos);
			LOG_INFOF("PlayerSpawn best_dist: pos: %v\n", best_pos);
			if (player.origin != best_pos) LOG_WARNF("wrong origin: %v", player.origin);

			player.angles = best_mate.angles;
			player.angles_z = 0; // never spawn tilted even if the spot says to
			best_mate.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
		}
	}
	else if(spawn_spot.msnt_lookat)
	{
		player.angles = vectoangles(spawn_spot.msnt_lookat.origin - player.origin);
		player.angles_x = -player.angles.x;
		player.angles_z = 0; // never spawn tilted even if the spot says to
		/*
		sprint(player, "You should be looking at ", spawn_spot.msnt_lookat.netname, "^7.\n");
		sprint(player, "distance: ", vtos(spawn_spot.msnt_lookat.origin - player.origin), "\n");
		sprint(player, "angles: ", vtos(player.angles), "\n");
		*/
	}

	LOG_INFOF("PlayerSpawn end player: %s %v spawn_spot: %v\n", player.netname, player.origin, spawn_spot.origin);
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerDies)
{
	entity frag_target = M_ARGV(0, entity);

	frag_target.msnt_deathloc = frag_target.origin;
}

REPLICATE(cvar_cl_spawn_near_teammate, bool, "cl_spawn_near_teammate");
