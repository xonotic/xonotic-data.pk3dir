void invasion_spawnpoint()
{
	if not(g_invasion) { remove(self); return; }
	
	self.classname = "invasion_spawnpoint";
}

float invasion_PickMonster()
{
	if(autocvar_g_invasion_zombies_only)
		return MONSTER_ZOMBIE;

	float i;
	
	RandomSelection_Init();
	
	for(i = MONSTER_FIRST + 1; i < MONSTER_LAST; ++i)
	{
		if(i == MONSTER_STINGRAY || i == MONSTER_WYVERN)
			continue; // flying/swimming monsters not yet supported
		
		RandomSelection_Add(world, i, "", 1, 1);
	}
	
	return RandomSelection_chosen_float;
}

entity invasion_PickSpawn()
{
	entity e;
	
	RandomSelection_Init();
	
	for(e = world;(e = find(e, classname, "invasion_spawnpoint")); )
		RandomSelection_Add(e, 0, string_null, 1, 1);
		
	return RandomSelection_chosen_ent;
}

void invasion_SpawnChosenMonster(float mon)
{
	entity spawn_point, monster;
	
	spawn_point = invasion_PickSpawn();
	
	if(spawn_point == world)
	{
		dprint("Warning: couldn't find any invasion_spawnpoint spawnpoints, no monsters will spawn!\n");
		return;
	}
	
	monster = spawnmonster("", mon, spawn_point, spawn_point, spawn_point.origin, FALSE, 2);
}

void invasion_SpawnMonsters()
{
	float chosen_monster = invasion_PickMonster();
	
	invasion_SpawnChosenMonster(chosen_monster);
}

float Invasion_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		entity head;
		FOR_EACH_MONSTER(head)
		{
			WaypointSprite_Kill(head.sprite);
			if(head.weaponentity) remove(head.weaponentity);
			remove(head);
		}
	
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);
		return 1;
	}

	if((numspawned - numkilled) < maxspawned)
	{
		if(time >= last_check)
		{
			invasion_SpawnMonsters();
			last_check = time + 0.5;
		}
		
		return 0;
	}
	
	if(numspawned > 1)
		return 0;
	
	if(roundcnt >= maxrounds)
	{
		NextLevel();
		return 1;
	}

	Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
	Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
	
	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);

	return 1;
}

float Invasion_CheckPlayers()
{
	return TRUE;
}

void Invasion_RoundStart()
{
	entity e;
	float numplayers = 0;
	FOR_EACH_PLAYER(e)
	{
		++numplayers;
		e.player_blocked = 0;
	}
		
	roundcnt += 1;
	
	numspawned = 0;
	numkilled = 0;
		
	if(roundcnt > 1)
		maxspawned = rint(autocvar_g_invasion_monster_count * roundcnt / 0.7);
	else
		maxspawned = autocvar_g_invasion_monster_count;
	
	monster_skill += 0.01 * numplayers;
}

MUTATOR_HOOKFUNCTION(invasion_MonsterDies)
{
	numkilled += 1;
	
	if(IS_PLAYER(frag_attacker))
		PlayerScore_Add(frag_attacker, SP_INVASION_KILLS, +1);
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(invasion_MonsterSpawn)
{
	if(self.realowner == world)
	{
		WaypointSprite_Kill(self.sprite);
		if(self.weaponentity) remove(self.weaponentity);
		remove(self);
		return FALSE;
	}
	
	numspawned += 1;
	
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_MONSTERCLIP;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(invasion_PlayerThink)
{
	monsters_total = maxspawned; // TODO: make sure numspawned never exceeds maxspawned
	monsters_killed = numkilled;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(invasion_PlayerDamage)
{
	if(IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target))
	{
		frag_damage = 0;
		frag_force = '0 0 0';
	}
	
	if(frag_attacker.flags & FL_MONSTER && frag_target.flags & FL_MONSTER)
		frag_damage = 0;
	
	return FALSE;
}

void invasion_ScoreRules()
{
	ScoreRules_basics(0, SFL_SORT_PRIO_SECONDARY, 0, FALSE);
	ScoreInfo_SetLabel_PlayerScore(SP_INVASION_KILLS, "kills", SFL_SORT_PRIO_PRIMARY);
	ScoreRules_basics_end();
}

void invasion_Initialize()
{
	invasion_ScoreRules();

	round_handler_Spawn(Invasion_CheckPlayers, Invasion_CheckWinner, Invasion_RoundStart);
	round_handler_Init(5, autocvar_g_invasion_warmup, autocvar_g_invasion_round_timelimit);
	
	allowed_to_spawn = TRUE;
	
	monster_skill = 0.01;
	
	roundcnt = 0;
}

MUTATOR_DEFINITION(gamemode_invasion)
{
	MUTATOR_HOOK(MonsterDies, invasion_MonsterDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterSpawn, invasion_MonsterSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, invasion_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, invasion_PlayerDamage, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		invasion_Initialize();
		
		cvar_settemp("g_monsters", "1");
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back invasion_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		print("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}
