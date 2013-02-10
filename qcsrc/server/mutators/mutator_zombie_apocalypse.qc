// Zombie Apocalypse mutator - small side project
// Spawns a defined number of zombies at the start of a match

float za_numspawns, totalzombies, roundcnt, numzoms;
entity PickZombieSpawn()
{
	entity sp;
	
	RandomSelection_Init();
	
	if(teamplay)
	{
		for(sp = world; (sp = find(sp, classname, "info_player_team1")); )
		{
			RandomSelection_Add(sp, 0, string_null, 1, 1);
		}
	}
	else
	{
		for(sp = world; (sp = find(sp, classname, "info_player_deathmatch")); )
		{
			RandomSelection_Add(sp, 0, string_null, 1, 1);
		}
	}
	
	return RandomSelection_chosen_ent;
}

void zombie_spawn_somewhere ()
{
	if(gameover) { return; }
    
    entity mon, sp;
	
	if(MoveToRandomMapLocation(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
	{
		mon = spawnmonster("zombie", self, self, self.origin, TRUE, 2);
		tracebox(mon.origin, mon.mins, mon.maxs, mon.origin, MOVE_NOMONSTERS, mon);
		mon.spawnflags |= MONSTERFLAG_NORESPAWN;

		if(trace_startsolid)
		{
			sp = PickZombieSpawn();
			if(sp)
				setorigin(mon, sp.origin);
		}
			
        za_numspawns += 1;
	}
	else
		zombie_spawn_somewhere();
}

void() spawn_zombies;
void za_roundwon()
{
	entity head;
	FOR_EACH_PLAYER(head)
	{
		Send_CSQC_Centerprint_Generic(head, CPID_MINSTA_FINDAMMO, "All the zombies have been exterminated! Prepare for round 2!", 0, 0);
	}
	
	roundcnt += 1;
	
	numzoms = autocvar_g_za_monster_count * roundcnt;
	
	monsters_total = numzoms;
	totalzombies = numzoms;
	
	self.think = spawn_zombies;
	self.nextthink = time + 10;
}

void spawn_zombies ()
{
	self.nextthink = time + 1;
	
	if(totalzombies < 1)
	{
		self.think = za_roundwon;
		self.nextthink = time;
		return;
	}
	
	if(gameover || numzoms <= 0)
		return;
		
    entity e;
    
    print("Them zombies be spawnin'!\n");

	while(numzoms > 0)
	{
        e = spawn();
		e.think = zombie_spawn_somewhere;
        e.nextthink = time;

		numzoms -= 1;
	}
}

void za_init ()
{
    entity e;
	
	roundcnt = 1;
	
    numzoms = autocvar_g_za_monster_count * roundcnt;
	
	monsters_total = numzoms;
	totalzombies = numzoms;
	
    e = spawn();
	e.think = spawn_zombies;
	e.nextthink = time + 3;
}

MUTATOR_HOOKFUNCTION(za_ZombieDies)
{
	if(frag_attacker.classname == "player")
		PlayerScore_Add(frag_attacker, SP_SCORE, 1);
	
	totalzombies -= 1;
	monsters_killed += 1;
	return FALSE;
}

MUTATOR_HOOKFUNCTION(za_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":Zombies");
	return 0;
}

MUTATOR_HOOKFUNCTION(za_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Zombies");
	return 0;
}

MUTATOR_DEFINITION(mutator_zombie_apocalypse)
{
	MUTATOR_HOOK(MonsterDies, za_ZombieDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, za_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, za_BuildMutatorsPrettyString, CBC_ORDER_ANY);
    
    MUTATOR_ONADD
    {
        za_init();
    }

	return 0;
}
