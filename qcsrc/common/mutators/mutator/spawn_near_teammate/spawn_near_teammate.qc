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
{SELFPARAM();
	if(autocvar_g_spawn_near_teammate_ignore_spawnpoint == 1 || (autocvar_g_spawn_near_teammate_ignore_spawnpoint == 2 && self.cvar_cl_spawn_near_teammate))
		return 0;

	spawn_spot.msnt_lookat = world;

	if(!teamplay)
		return 0;

	RandomSelection_Init();
	FOREACH_CLIENT(IS_PLAYER(it) && it != self && SAME_TEAM(it, self) && it.deadflag == DEAD_NO, LAMBDA(
		float l = vlen(spawn_spot.origin - it.origin);
		if(l > autocvar_g_spawn_near_teammate_distance)
			continue;
		if(l < 48)
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
	else if(self.team == spawn_spot.team)
		spawn_score.x += SPAWN_PRIO_NEAR_TEAMMATE_SAMETEAM; // prefer same team, if we can't find a spawn near teammate

	return 0;
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerSpawn)
{SELFPARAM();
	if(!teamplay) { return false; }
	// Note: when entering this, fixangle is already set.
	if(autocvar_g_spawn_near_teammate_ignore_spawnpoint == 1 || (autocvar_g_spawn_near_teammate_ignore_spawnpoint == 2 && self.cvar_cl_spawn_near_teammate))
	{
		if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death)
			self.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay_death;

		entity best_mate = world;
		vector best_spot = '0 0 0';
		float pc = 0, best_dist = 0, dist = 0;
		FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
			if((autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health >= 0 && it.health >= autocvar_g_balance_health_regenstable) || autocvar_g_spawn_near_teammate_ignore_spawnpoint_check_health == 0)
			if(it.deadflag == DEAD_NO)
			if(it.msnt_timer < time)
			if(SAME_TEAM(self, it))
			if(time > it.spawnshieldtime) // spawn shielding
			if(it.frozen == 0)
			if(it != self)
			{
				tracebox(it.origin, PL_MIN, PL_MAX, it.origin - '0 0 100', MOVE_WORLDONLY, it);
				if(trace_fraction != 1.0)
				if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
				{
					pc = pointcontents(trace_endpos + '0 0 1');
					if(pc == CONTENT_EMPTY)
					{
						if(vlen(it.velocity) > 5)
							fixedmakevectors(vectoangles(it.velocity));
						else
							fixedmakevectors(it.angles);

						for(pc = 0; pc < 5; ++pc) // test 5 diffrent spots close to mate
						{
							switch(pc)
							{
								case 0:
									tracebox(it.origin , PL_MIN, PL_MAX, it.origin + v_right * 128, MOVE_NORMAL, it);
									break;
								case 1:
									tracebox(it.origin , PL_MIN, PL_MAX, it.origin - v_right * 128 , MOVE_NORMAL, it);
									break;
								case 2:
									tracebox(it.origin , PL_MIN, PL_MAX, it.origin + v_right * 64 - v_forward * 64, MOVE_NORMAL, it);
									break;
								case 3:
									tracebox(it.origin , PL_MIN, PL_MAX, it.origin - v_right * 64 - v_forward * 64, MOVE_NORMAL, it);
									break;
								case 4:
									tracebox(it.origin , PL_MIN, PL_MAX, it.origin - v_forward * 128, MOVE_NORMAL, it);
									break;
							}

							if(trace_fraction == 1.0)
							{
								traceline(trace_endpos + '0 0 4', trace_endpos - '0 0 100', MOVE_NORMAL, it);
								if(trace_fraction != 1.0)
								{
									if(autocvar_g_spawn_near_teammate_ignore_spawnpoint_closetodeath)
									{
										dist = vlen(trace_endpos - self.msnt_deathloc);
										if(dist < best_dist || best_dist == 0)
										{
											best_dist = dist;
											best_spot = trace_endpos;
											best_mate = it;
										}
									}
									else
									{
										setorigin(self, trace_endpos);
										self.angles = it.angles;
										self.angles_z = 0; // never spawn tilted even if the spot says to
										it.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
										return 0;
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
			setorigin(self, best_spot);
			self.angles = best_mate.angles;
			self.angles_z = 0; // never spawn tilted even if the spot says to
			best_mate.msnt_timer = time + autocvar_g_spawn_near_teammate_ignore_spawnpoint_delay;
		}
	}
	else if(spawn_spot.msnt_lookat)
	{
		self.angles = vectoangles(spawn_spot.msnt_lookat.origin - self.origin);
		self.angles_x = -self.angles.x;
		self.angles_z = 0; // never spawn tilted even if the spot says to
		/*
		sprint(self, "You should be looking at ", spawn_spot.msnt_lookat.netname, "^7.\n");
		sprint(self, "distance: ", vtos(spawn_spot.msnt_lookat.origin - self.origin), "\n");
		sprint(self, "angles: ", vtos(self.angles), "\n");
		*/
	}

	return 0;
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, PlayerDies)
{SELFPARAM();
	self.msnt_deathloc = self.origin;
	return 0;
}

MUTATOR_HOOKFUNCTION(spawn_near_teammate, GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_spawn_near_teammate, "cl_spawn_near_teammate");
	return false;
}
#endif
