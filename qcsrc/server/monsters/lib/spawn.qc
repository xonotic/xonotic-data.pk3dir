float spawnmonster_checkinlist(string monster, string list)
{
	string l = strcat(" ", list, " ");
	
	if(strstrofs(l, strcat(" ", monster, " "), 0) >= 0)
		return TRUE;
	
	return FALSE;
}

entity spawnmonster (string monster, entity spawnedby, entity own, vector orig, float respwn, float moveflag)
{
	if not(autocvar_g_monsters)
	{
		if(IS_CLIENT(spawnedby))
			Send_Notification(NOTIF_ONE, spawnedby, MSG_INFO, INFO_MONSTERS_DISABLED);
			
		return world;
	}
	
	if(spawnedby.vehicle) // no vehicle player spawning...
		return world;
	
	if(!spawncode_first_load)
	{
		initialize_field_db();
		spawncode_first_load = TRUE;
	}
	
	entity e = spawn();
	
	e.spawnflags = MONSTERFLAG_SPAWNED;
	
	if not(respwn)
		e.spawnflags |= MONSTERFLAG_NORESPAWN;
	
	setorigin(e, orig);
	
	if not(spawnmonster_checkinlist(monster, autocvar_g_monsters_spawn_list))
		monster = "knight";
	
	e.realowner = spawnedby;
	
	if(moveflag)
		e.monster_moveflags = moveflag;
	
	if (spawnedby.classname == "monster_swarm")
		e.monster_owner = own;  
	else if(IS_CLIENT(spawnedby))
	{
		if(teamplay && autocvar_g_monsters_teams)
			e.team = spawnedby.team; // colors handled in spawn code
			
		if not(teamplay)
			e.colormap = spawnedby.colormap;
			
		if(autocvar_g_monsters_owners)
			e.monster_owner = own; // using owner makes the monster non-solid for its master
			
		e.angles = spawnedby.angles;
	}
	
	if(autocvar_g_monsters_giants_only)
		e.spawnflags |= MONSTERFLAG_GIANT;
		
	monster = strcat("$ spawnfunc_monster_", monster);
		
	target_spawn_edit_entity(e, monster, world, world, world, world, world);
		
	return e;
}
