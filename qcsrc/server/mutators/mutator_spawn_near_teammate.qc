float autocvar_g_spawn_near_teammate_distance;

MUTATOR_HOOKFUNCTION(msnt_Spawn_Score) {
	entity p;

	if(!teamplay)
		return 0;

	FOR_EACH_PLAYER(p) if(p != self) if(p.team == self.team) if(!p.deadflag)
	{
		if(vlen(spawn_score_spot.origin - p.origin) > autocvar_g_spawn_near_teammate_distance)
			continue;
		if(!checkpvs(spawn_score_spot.origin, p))
			continue;
		/*
		if(self == nextent(world))
		{
			te_explosion(p.origin);
			print(p.netname, " should be nearby\n");
		}
		*/
		spawn_score_x += SPAWN_PRIO_NEAR_TEAMMATE;
	}

	return 0;
}

MUTATOR_DEFINITION(mutator_spawn_near_teammate)
{
	MUTATOR_HOOK(Spawn_Score, msnt_Spawn_Score, CBC_ORDER_ANY);

	return 0;
}
