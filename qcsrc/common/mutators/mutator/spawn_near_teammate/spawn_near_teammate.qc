#ifdef IMPLEMENTATION

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

	M_ARGV(2, vector) = spawn_score;
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerSpawn)
{
	if(!teamplay) { return; }
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);

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

	// Note: when entering this, fixangle is already set.
	if(autocvar_g_spawn_near_teammate_ignore_spawnpoint == 1 || (autocvar_g_spawn_near_teammate_ignore_spawnpoint == 2 && player.cvar_cl_spawn_near_teammate))
	{
		if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death)
			player.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death;

		entity best_mate = NULL;
		vector best_spot = '0 0 0';
		float pc = 0, best_dist = 0, dist = 0;
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
			if((autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health >= 0 && it.health >= autocvar_g_balance_health_regenstable) || autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health == 0)
			if(!IS_DEAD(it))
			if(it.msnt_timer < time)
			if(SAME_TEAM(player, it))
			if(time > it.spawnshieldtime) // spawn shielding
			if(STAT(FROZEN, it) == 0)
			if(it != player)
			{
				tracebox(it.origin, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - '0 0 100', MOVE_NOMONSTERS, it);
				if(trace_fraction != 1.0)
				if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
				{
					pc = pointcontents(trace_endpos + '0 0 1');
					if(pc == CONTENT_EMPTY)
					{
						if(vdist(it.velocity, >, 5))
							fixedmakevectors(vectoangles(it.velocity));
						else
							fixedmakevectors(it.angles);

						for(pc = 0; pc < 4; ++pc) // test 4 diffrent spots close to mate
						{
							switch(pc)
							{
								case 0:
									tracebox(it.origin , STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin + v_right * 128, MOVE_NOMONSTERS, it);
									break;
								case 1:
									tracebox(it.origin , STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - v_right * 128 , MOVE_NOMONSTERS, it);
									break;
								case 2:
									tracebox(it.origin , STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin + v_right * 128 - v_forward * 64, MOVE_NOMONSTERS, it);
									break;
								case 3:
									tracebox(it.origin , STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - v_right * 128 - v_forward * 64, MOVE_NOMONSTERS, it);
									break;
								//case 4:
									//tracebox(it.origin , STAT(PL_MIN, NULL), STAT(PL_MAX, NULL), it.origin - v_forward * 128, MOVE_NOMONSTERS, it);
									//break;
							}

							if(trace_fraction == 1.0)
							{
								traceline(trace_endpos + '0 0 4', trace_endpos - '0 0 100', MOVE_NOMONSTERS, it);
								if(trace_fraction != 1.0)
								{
									if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath)
									{
										dist = vlen(trace_endpos - player.msnt_deathloc);
										if(dist < best_dist || best_dist == 0)
										{
											best_dist = dist;
											best_spot = trace_endpos;
											best_mate = it;
										}
									}
									else
									{
										setorigin(player, trace_endpos);
										player.angles = it.angles;
										player.angles_z = 0; // never spawn tilted even if the spot says to
										it.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
										return;
									}
								}
							}
						}
					}
				}
			}
		));

		if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath)
		if(best_dist)
		{
			setorigin(player, best_spot);
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
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerDies)
{
	entity frag_target = M_ARGV(0, entity);

	frag_target.msnt_deathloc = frag_target.origin;
}

REPLICATE(cvar_cl_spawn_near_teammate, bool, "cl_spawn_near_teammate");

#endif
