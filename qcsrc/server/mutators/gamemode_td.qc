// Tower Defense
// Gamemode by Mario
 
void spawnfunc_td_controller()
{
	if not(g_td)
	{
		remove(self);
		return;
	}
	if(autocvar_g_td_force_settings)
	{
		self.dontend = FALSE;
		self.maxwaves = 0;
		self.monstercount = 0;
		self.startwave = 0;
		self.maxturrets = 0;
	}
		
	self.netname = "Tower Defense controller entity";
	self.classname = "td_controller";
		
	gensurvived = FALSE;
	td_dont_end = ((self.dontend) ? self.dontend : autocvar_g_td_generator_dontend);		
	max_waves = ((self.maxwaves) ? self.maxwaves : autocvar_g_td_max_waves);	
	totalmonsters = ((self.monstercount) ? self.monstercount : autocvar_g_td_monster_count);
	wave_count = ((self.startwave) ? self.startwave : autocvar_g_td_start_wave);
	max_turrets = ((self.maxturrets) ? self.maxturrets : autocvar_g_td_turret_max);
	build_time = ((self.buildtime) ? self.buildtime : autocvar_g_td_buildphase_time);
		
	wave_end(TRUE);
}

void td_generator_die() 
{
	entity tail;
	
	print((td_gencount > 1) ? "A generator was destroyed!\n" : "The generator was destroyed.\n");
		
	if(autocvar_sv_eventlog)
		GameLogEcho(":gendestroyed");
		
	gendestroyed = TRUE;
		
	FOR_EACH_PLAYER(tail)
	{
		Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, ((td_gencount > 1) ? "A generator was destroyed!" : "The generator was destroyed."), 0, 0);
	}
	
	setmodel(self, "models/onslaught/generator_dead.md3");
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	td_gencount			-= 1;
		
	pointparticles(particleeffectnum("explosion_medium"), self.origin, '0 0 0', 1);
	
	WaypointSprite_Kill(self.sprite);
}

void td_generator_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) 
{
	if(attacker.classname == STR_PLAYER || attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET || attacker.vehicle_flags & VHF_ISVEHICLE)
		return;
		
	entity tail;
	
	FOR_EACH_PLAYER(tail)
	{
		Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, "The generator is under attack!", 0, 0);
	}
	
	self.health -= damage;
	
	WaypointSprite_UpdateHealth(self.sprite, self.health);
		
	if(self.health <= 0) 
		td_generator_die();
}

void spawnfunc_td_generator() 
{
	if not(g_td) 
	{
		remove(self);
		return;
	}
	
	gendestroyed = FALSE;
	
	if not(self.health)
		self.health = autocvar_g_td_generator_health;

	// precache generator model
	precache_model("models/onslaught/generator.md3");
	precache_model("models/onslaught/generator_dead.md3");   
	
	self.model		    = "models/onslaught/generator.md3";
	setmodel(self, self.model);
	self.classname	    = "td_generator";
	self.solid		    = SOLID_BBOX;
	self.takedamage	    = DAMAGE_AIM;
	self.event_damage   = td_generator_damage;
	self.enemy		    = world;
	self.nextthink	    = -1;
	self.think		    = func_null;
	self.max_health	    = self.health;
	self.movetype	    = MOVETYPE_NONE;
	self.monster_attack = TRUE;
	td_gencount		   += 1;
	self.netname		= "Generator";
	
	setsize(self, GENERATOR_MIN, GENERATOR_MAX);
	
	droptofloor();
	
	WaypointSprite_SpawnFixed(self.netname, self.origin + '0 0 60', self, sprite, RADARICON_OBJECTIVE, '1 0.5 0');	
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
}

entity PickGenerator()
{
	entity generator, head;
	if(td_gencount == 1)
		generator = find(world, classname, "td_generator");
	else
	{
		RandomSelection_Init();
		for(head = world;(head = find(head, classname, "td_generator")); )
		{
			RandomSelection_Add(head, 0, string_null, 1, 1);
		}
		generator = RandomSelection_chosen_ent;	
	}
	return generator;
}

void spawn_td_fuel(float fuel_size)
{
	if not(g_td)
	{
		remove(self);
		return;
	}
	self.ammo_fuel = fuel_size * monster_skill;
	StartItem("models/items/g_fuel.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "Turret Fuel", IT_FUEL, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
	
	self.velocity = randomvec() * 175 + '0 0 325';
}

void spawnfunc_td_waypoint() 
{
	if not(g_td)
	{
		remove(self);
		return;
	}
	string t1 = self.target;
	
	self.classname = "td_waypoint";
	
	if(self.target2 != "")
	{
		RandomSelection_Init();
		RandomSelection_Add(world, 0, t1, 1, 1);
		RandomSelection_Add(world, 0, self.target2, 1, 1);
		
		self.target = RandomSelection_chosen_string;
	}
}

void spawnfunc_monster_swarm()
{
	if not(g_td)
	{
		remove(self);
		return;
	}
	
	string t1 = self.target;
	
	switch(self.spawntype)
	{
		case SWARM_SWIM:
			waterspawns_count += 1; break;
		case SWARM_FLY:
			flyspawns_count += 1; break;
		default:
			break;
	}
	
	switch(self.spawnflags)
	{
		case SWARM_STRONG:
			self.classname = "swarm_strong"; break;
		case SWARM_WEAK:
			self.classname = "swarm_weak"; break;
		default:
			self.classname = "monster_swarm"; break;
	}
	
	if(self.target2 != "")
	{
		RandomSelection_Init();
		RandomSelection_Add(world, 0, t1, 1, 1);
		RandomSelection_Add(world, 0, self.target2, 1, 1);
		
		self.target = RandomSelection_chosen_string;
	}	
	
	WaypointSprite_SpawnFixed("Monsters", self.origin + '0 0 60', self, sprite, RADARICON_HERE, '1 0.5 0');
	
	if(self.target == "")
		print("monster_swarm entity without a valid target, monsters will try to follow waypoints instead.\n");
}

void spawnturret(entity spawnedby, entity own, string turet, vector orig)
{
	if(spawnedby.classname != STR_PLAYER)
	{
		print("Warning: A non-player entity tried to spawn a turret.\n");
		return;
	}
		
	entity oldself;
	
	oldself = self;
	self = spawn();
	
	setorigin(self, orig);
	self.spawnflags = TSL_NO_RESPAWN;
	self.monster_attack = TRUE;
	self.realowner = own;
	self.angles_y = spawnedby.v_angle_y;
	spawnedby.turret_cnt += 1;
	self.colormap = spawnedby.colormap;
	
	switch(turet)
	{
		default:
		case "turret_plasma": spawnfunc_turret_plasma(); break;
		case "turret_mlrs": spawnfunc_turret_mlrs(); break;
		case "turret_phaser": spawnfunc_turret_phaser(); break;
		case "turret_hellion": spawnfunc_turret_hellion(); break;
		case "turret_walker": spawnfunc_turret_walker(); break;
		case "turret_flac": spawnfunc_turret_flac(); break;
		case "turret_tesla": spawnfunc_turret_tesla(); break;
		case "turret_fusionreactor": spawnfunc_turret_fusionreactor(); break;
	}
		
	self = oldself;
}

void buffturret (entity tur, float buff)
{
	tur.turret_buff		  += 1;
	tur.max_health		  *= buff;
	tur.tur_health 		   = tur.max_health;
	tur.health			   = tur.max_health;
	tur.ammo_max		  *= buff;
	tur.ammo_recharge     *= buff;
    tur.shot_dmg          *= buff;
    tur.shot_refire       -= buff * 0.2;
    tur.shot_radius       *= buff;
    tur.shot_speed        *= buff;
    tur.shot_spread       *= buff;
    tur.shot_force        *= buff;
}

void AnnounceSpawn(string anounce)
{
	entity tail;
	FOR_EACH_PLAYER(tail)
	{
		Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, strcat("^1A ", anounce, " has arrived!"), 0, 0);
	}
}

entity PickSpawn (string strngth, string type)
{
	entity e;
	RandomSelection_Init();
	for(e = world;(e = find(e, classname, strngth)); ) 
	{
		RandomSelection_Add(e, 0, string_null, 1, 1); 
	}

	return RandomSelection_chosen_ent;
}

void TD_SpawnMonster(string mnster, string strngth, string type)
{
	entity e, mon;
	
	e = PickSpawn(strngth, type);
	
	if(e == world)
		e = PickSpawn("monster_swarm", "");
  
	mon = spawnmonster(mnster, e, e, e.origin, FALSE, 0);
	mon.target = e.target;
}

string Monster_GetStrength(string mnster)
{
	switch(mnster)
	{
		case "knight":
		case "wizard":
		case "soldier":
		case "enforcer":
		case "zombie":
		case "tarbaby":
		case "dog":
		case "spider":
		case "fish":
			return "swarm_weak";
		case "ogre":
		case "shambler":
		case "shalrath":
		case "hellknight":
		case "demon":
			return "swarm_strong";
		default:
			return "monster_swarm";
	}
}

string Monster_GetType(string mnster)
{
	switch(mnster)
	{
		default:
		case "knight":
		case "soldier":
		case "enforcer":
		case "zombie":
		case "spider":
		case "tarbaby":
		case "dog":
		case "ogre":
		case "shambler":
		case "shalrath":
		case "hellknight":
		case "demon":
			return "monster_swarm";
		case "wizard":
			return "monster_fly";
		case "fish":
			return "monster_swim";
	}
}

string RandomMonster()
{
	RandomSelection_Init();
	
	if(n_demons) RandomSelection_Add(world, 0, "demon", 1, 1);
	if(n_shalraths) RandomSelection_Add(world, 0, "vore", 1, 1);
	if(n_soldiers) RandomSelection_Add(world, 0, "soldier", 1, 1);
	if(n_hknights) RandomSelection_Add(world, 0, "hellknight", 1, 1);
	if(n_enforcers) RandomSelection_Add(world, 0, "enforcer", 1, 1);
	if(n_zombies) RandomSelection_Add(world, 0, "zombie", 1, 1);
	if(n_spiders) RandomSelection_Add(world, 0, "spider", 1, 1);
	if(n_ogres) RandomSelection_Add(world, 0, "ogre", 1, 1);
	if(n_dogs) RandomSelection_Add(world, 0, "dog", 1, 1);
	if(n_knights) RandomSelection_Add(world, 0, "knight", 1, 1);
	if(n_shamblers) RandomSelection_Add(world, 0, "shambler", 0.2, 0.2);
	if(n_tarbabies) RandomSelection_Add(world, 0, "spawn", 0.2, 0.2);
	if(n_wizards && flyspawns_count > 0) RandomSelection_Add(world, 0, "scrag", 1, 1);
	if(n_fish && waterspawns_count > 0) RandomSelection_Add(world, 0, "fish", 0.2, 0.2);
	
	return RandomSelection_chosen_string;
}

void combat_phase()
{
	string monstrngth, whichmon, montype;
	
	current_phase = PHASE_COMBAT;
	
	if(monster_count <= 0)
	{
		wave_end(FALSE);
		return;
	}
	
	self.think = combat_phase;
	
	whichmon = RandomMonster();
	
	monstrngth = Monster_GetStrength(whichmon);
	montype = Monster_GetType(whichmon);
	
	if(current_monsters <= autocvar_g_td_current_monsters && whichmon != "")
	{
		TD_SpawnMonster(whichmon, monstrngth, montype);
		self.nextthink = time + 3;
	}
	else
		self.nextthink = time + 6;
}

void queue_monsters(float maxmonsters)
{
	float mc = 11; // note: shambler + tarbaby = 1
	
	if(waterspawns_count > 0)
		mc += 1;
	if(flyspawns_count > 0)
		mc += 1;
		
	DistributeEvenly_Init(maxmonsters, mc);
	n_demons	= DistributeEvenly_Get(1);
	n_ogres	 	= DistributeEvenly_Get(1);
	n_dogs	  	= DistributeEvenly_Get(1);
	n_knights   = DistributeEvenly_Get(1);
	n_shalraths = DistributeEvenly_Get(1);
	n_soldiers  = DistributeEvenly_Get(1);
	n_hknights  = DistributeEvenly_Get(1);
	n_enforcers = DistributeEvenly_Get(1);
	n_zombies   = DistributeEvenly_Get(1);
	n_spiders   = DistributeEvenly_Get(1);
	n_tarbabies = DistributeEvenly_Get(0.7);
	n_shamblers = DistributeEvenly_Get(0.3);
	if(flyspawns_count > 0)
		n_wizards = DistributeEvenly_Get(1);
	if(waterspawns_count > 0)
		n_fish = DistributeEvenly_Get(1);
}

void combat_phase_begin()
{
	monster_count = totalmonsters;
	entity head, tail;
	
	print("^1Combat phase!\n");
	FOR_EACH_PLAYER(tail)
	{
		Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, "^1Combat phase!", 0, 0);
	}
	if(autocvar_sv_eventlog)
		GameLogEcho(":combatphase");
	self.think = combat_phase;
	self.nextthink = time + 1;
	
	for(head = world;(head = find(head, classname, "td_generator")); )
	{
		head.takedamage = DAMAGE_AIM;
	}
}

float cphase_updates;
void combat_phase_announce() // TODO: clean up these fail nextthinks...
{
	cphase_updates += 1;
	
	if(cphase_updates == 0)
		Announce("prepareforbattle");
	else if(cphase_updates == 3)
		Announce("3");
	else if(cphase_updates == 4)
		Announce("2");
	else if(cphase_updates == 5)
		Announce("1");
	else if(cphase_updates == 6)
	{
		Announce("begin");
		combat_phase_begin();
	}
	
	if(cphase_updates >= 6)
		return;

	self.think = combat_phase_announce;
	self.nextthink = time + 1;
}

void build_phase()
{
	entity head;
	float n_players = 0, gen_washealed = FALSE, player_washealed = FALSE;
    string buildmsg, healmsg, countmsg, startmsg, genhealmsg;
	
	current_phase = PHASE_BUILD;
	
	for(head = world;(head = find(head, classname, "td_generator")); )
	{
		if(head.health <= 5 && head.max_health > 10)
			Announce("lastsecond");
			
		if(head.health < head.max_health)
		{
			gen_washealed = TRUE;
			head.health = head.max_health;
			WaypointSprite_UpdateHealth(head.sprite, head.health);
		}
		head.takedamage = DAMAGE_NO;
	}
	
	FOR_EACH_PLAYER(head)
	{
		if(head.health < 100)
		{
			player_washealed = TRUE;
			break; // we found 1, so no need to check the others
		}
	}
		
	totalmonsters += autocvar_g_td_monster_count_increment * wave_count;
	monster_skill += autocvar_g_td_monsters_skill_increment;
	
	if(wave_count < 1) wave_count = 1;

	genhealmsg = (gen_washealed) ? ((td_gencount == 1) ? " and generator " : " and generators ") : "";
	buildmsg = sprintf("%s build phase... ", (wave_count == max_waves) ? "^1Final wave^3" : sprintf("Wave %d", wave_count));
	healmsg = (player_washealed) ? sprintf("All players %shealed. ", genhealmsg) : "";	
    countmsg = sprintf("Next monsters: %d. ", totalmonsters);
    startmsg = sprintf("Wave starts in %d seconds", autocvar_g_td_buildphase_time);
	
	FOR_EACH_PLAYER(head) 
    {
		if(head.health < 100)
			head.health = 100;
			
		if(gen_washealed)
			PlayerScore_Add(head, SP_TD_SCORE, -autocvar_g_td_generator_damaged_points);
			
        n_players += 1;
        Send_CSQC_Centerprint_Generic(head, CPID_KH_MSG, strcat(buildmsg, healmsg, countmsg, startmsg), 5, 0);
		
    }
    
    FOR_EACH_MONSTER(head)
    {
		if(head.health <= 0)
			continue;
        print(strcat("Warning: Monster still alive during build phase! Monster name: ", head.netname, "\n"));
		if(head.sprite)
			WaypointSprite_Kill(head.sprite);
        remove(head);
    }
	
	if(n_players >= 2)
	{
		totalmonsters += n_players;
		monster_skill += n_players * 0.05;
	}
	
	if(monster_skill < 1) monster_skill = 1;
		
	if(totalmonsters < 1) totalmonsters = ((autocvar_g_td_monster_count > 0) ? autocvar_g_td_monster_count : 10);
	
	monsters_total = totalmonsters;
	monsters_killed = 0;
	
	print(strcat(buildmsg, healmsg, countmsg, startmsg, "\n"));
		
	queue_monsters(totalmonsters);
	
	cphase_updates = -1;
	
	if(autocvar_sv_eventlog)
        GameLogEcho(sprintf(":buildphase:%d:%d", wave_count, totalmonsters));
	
	self.think = combat_phase_announce;
	self.nextthink = time + build_time - 6;
}

void wave_end(float starting)
{
	entity tail;
	FOR_EACH_PLAYER(tail)
	{
		if(starting)
			Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, "Defend the generator from waves of monsters!", 0, 0);
		else
			Send_CSQC_Centerprint_Generic(tail, CPID_KH_MSG, ((wave_count >= max_waves) ? "Level victory!" : "Wave victory!"), 0, 0);
	}
	
	if not(starting)
	{
		print((wave_count >= max_waves) ? "^2Level victory!\n" : "^2Wave victory!\n");
		if(autocvar_sv_eventlog)
            GameLogEcho(sprintf(":wave:%d:victory", wave_count));
	}
	
	if(wave_count >= max_waves)
	{
		gensurvived = TRUE;
		return;
	}
	
	if(starting)
	{
		if(autocvar_g_td_monsters_skill_start)
			monster_skill = autocvar_g_td_monsters_skill_start;
	}
	else
		wave_count += 1;
		
	self.think = build_phase;
	self.nextthink = time + 3;
}

void td_ScoreRules()
{
	ScoreInfo_SetLabel_PlayerScore(SP_TD_SCORE,		"score",	 SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_TD_KILLS,		"kills",	 SFL_LOWER_IS_BETTER);
	ScoreInfo_SetLabel_PlayerScore(SP_TD_TURKILLS,  "frags",  	 SFL_LOWER_IS_BETTER);
	ScoreInfo_SetLabel_PlayerScore(SP_TD_DEATHS,    "deaths",    SFL_LOWER_IS_BETTER);
	ScoreInfo_SetLabel_PlayerScore(SP_TD_SUICIDES,  "suicides",  SFL_LOWER_IS_BETTER | SFL_ALLOW_HIDE);
	ScoreRules_basics_end();
}

void td_SpawnController()
{
	entity oldself = self;
	self = spawn();
	self.classname = "td_controller";
	spawnfunc_td_controller();
	self = oldself;
}

void td_DelayedInit()
{
	if(find(world, classname, "td_controller") == world)
	{
		print("No ""td_controller"" entity found on this map, creating it anyway.\n");
		td_SpawnController();
	}
	
	td_ScoreRules();
}

void td_Init()
{
	InitializeEntity(world, td_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(td_TurretValidateTarget)
{
	if(turret.turrcaps_flags & TFL_TURRCAPS_SUPPORT && turret_target.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
		return TRUE;
	if not(turret_target.flags & FL_MONSTER)
		turret_target = world;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_PlayerThink)
{
	self.stat_current_wave = wave_count;
	self.stat_totalwaves = max_waves;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_PlayerSpawn)
{
	self.bot_attack = FALSE;
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_PlayerDies)
{
	if(frag_attacker.flags & FL_MONSTER)
		PlayerScore_Add(frag_target, SP_TD_DEATHS, 1);
		
	if(frag_target == frag_attacker)
		PlayerScore_Add(frag_attacker, SP_TD_SUICIDES, 1);

	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_GiveFragsForKill)
{
	frag_score = 0;
		
	return TRUE; // no frags counted in td
}

MUTATOR_HOOKFUNCTION(td_PlayerDamage_Calculate)
{
	if(frag_attacker.realowner == frag_target)
		frag_damage = 0;
		
	if(frag_target.flags & FL_MONSTER && time < frag_target.spawnshieldtime)
		frag_damage = 0;
		
	if(frag_target.vehicle_flags & VHF_ISVEHICLE && !(frag_attacker.flags & FL_MONSTER))
		frag_damage = 0;
		
	if(frag_attacker.vehicle_flags & VHF_ISVEHICLE && !(frag_target.flags & FL_MONSTER))
		frag_damage = 0;
		
	if(!autocvar_g_td_pvp && frag_attacker != frag_target && frag_target.classname == STR_PLAYER && frag_attacker.classname == STR_PLAYER)
		frag_damage = 0;
		
	if(frag_attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET && frag_target.classname == STR_PLAYER)
		frag_damage = 0;
		
	if((frag_target.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && !(frag_attacker.flags & FL_MONSTER || frag_attacker.turrcaps_flags & TFL_TURRCAPS_SUPPORT))
		frag_damage = 0;
		
	if((frag_target.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && frag_target.health <= 0)
	{
		// TODO: fix this? calling on damage may be unreliable
		if(frag_target.realowner)
			frag_target.realowner.turret_cnt -= 1;
	}
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_MonsterCheckBossFlag)
{
	// No minibosses in tower defense
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_MonsterMove)
{
	entity player;
	float n_players = 0;
	FOR_EACH_PLAYER(player) { ++n_players; }
	
	if(n_players < 1) // no players online, so do nothing
	{
		monster_target = world;
		monster_speed_run = monster_speed_walk = 0;
		return FALSE;
	}
	
	if((vlen(self.goalentity.origin - self.origin) <= 100 && self.goalentity.classname == "td_waypoint") || (vlen(self.goalentity.origin - self.origin) <= 200 && self.flags & FL_FLY && self.goalentity.classname == "td_waypoint"))
	{
		self.target = self.goalentity.target;
		self.goalentity = find(world, targetname, self.target);
	}
	
	if(self.goalentity == world)
		self.goalentity = PickGenerator();
	
	monster_speed_run = 110 * monster_skill;
	monster_speed_walk = 75 * monster_skill;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterSpawn)
{
	if(self.realowner && self.realowner.flags & FL_CLIENT)
	{
		sprint(self.realowner, "You can't spawn monsters in Tower Defense mode. Removed monster.\n");
		if(self.sprite)
			WaypointSprite_Kill(self.sprite);
		remove(self);
		return TRUE;
	}
	
	if(self.realowner == world) // nothing spawned it, so kill it
	{
		if(self.sprite)
			WaypointSprite_Kill(self.sprite);
		remove(self);
		return TRUE;
	}
	
	self.spawnshieldtime = time + autocvar_g_td_monsters_spawnshield_time;
	
	self.drop_size = self.health * 0.05;
	
	if(self.drop_size < 1) self.drop_size = 1;
	
	if(self.target) // follow target if available
		self.goalentity = find(world, targetname, self.target);
	
	self.origin += '0 0 25'; // hopefully this fixes monsters falling through the floor
	
	switch(self.classname)
	{
		case "monster_knight": n_knights -= 1; break;
		case "monster_dog": n_dogs -= 1; break;
		case "monster_ogre": n_ogres -= 1; break;
		case "monster_shambler": n_shamblers -= 1; AnnounceSpawn("Shambler"); break;
		case "monster_wizard": n_wizards -= 1; break;
		case "monster_shalrath": n_shalraths -= 1; break;
		case "monster_soldier": n_soldiers -= 1; break;
		case "monster_hellknight": n_hknights -= 1; break;
		case "monster_enforcer": n_enforcers -= 1; break;
		case "monster_demon": n_demons -= 1; break;
		case "monster_zombie": n_zombies -= 1; break;
		case "monster_spider": n_spiders -= 1; break;
		case "monster_tarbaby": n_tarbabies -= 1; break;
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_MonsterDies)
{
	entity oldself;
	vector backuporigin;

	monster_count -= 1;
	current_monsters -= 1;
	monsters_killed += 1;
	
	if(frag_attacker.classname == STR_PLAYER)
	{
		PlayerScore_Add(frag_attacker, SP_TD_SCORE, autocvar_g_td_kill_points);
		PlayerScore_Add(frag_attacker, SP_TD_KILLS, 1);
	}
	else if(frag_attacker.realowner.classname == STR_PLAYER)
	{
		PlayerScore_Add(frag_attacker.realowner, SP_TD_SCORE, autocvar_g_td_turretkill_points);
		PlayerScore_Add(frag_attacker.realowner, SP_TD_TURKILLS, 1);
	}

	backuporigin = self.origin;
	oldself = self;
	self = spawn();
	
	self.gravity = 1;
	setorigin(self, backuporigin + '0 0 5');
	spawn_td_fuel(oldself.drop_size);
	self.touch = M_Item_Touch;
	if(self == world)
	{
		self = oldself;
		return FALSE;
	}
	SUB_SetFade(self, time + 5, 1);
	
	self = oldself;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterFindTarget)
{
	float n_players = 0;
	entity player;
	local entity e;
	
	FOR_EACH_PLAYER(player) { ++n_players; }
	
	if(n_players < 1) // no players online, so do nothing
	{
		self.enemy = world;
		return TRUE;
	}
	
	for(e = world;(e = findflags(e, monster_attack, TRUE)); ) 
	{
		if(monster_isvalidtarget(e, self, FALSE))
		if((vlen(trace_endpos - self.origin) < 100 && e.turrcaps_flags & TFL_TURRCAPS_ISTURRET) || (vlen(trace_endpos - self.origin) < 200 && e.classname != "td_generator") || (vlen(trace_endpos - self.origin) < 500 && e.classname == "td_generator"))
		{
			self.enemy = e;
		}
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_SetStartItems)
{
	// no start ammo, so player must rely on monster droppings (TODO: random drops for monsters)
	start_ammo_rockets = 0;
	start_ammo_cells = 0;
	start_ammo_nails = 0;
	start_ammo_fuel = 150; // to be nice...
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_TurretSpawn)
{
	if(self.realowner == world)
		return TRUE; // wasn't spawned by a player
		
	self.bot_attack = FALSE;
	self.turret_buff = 1;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) { return FALSE; } // command was already handled?
	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 100, MOVE_NORMAL, self);
	if(cmd_name == "turretspawn")
	{
		if(argv(1) == "list")
		{
			sprint(self, "Available turrets:\n");
			sprint(self, "^3mlrs walker plasma towerbuff\n");
			return TRUE;
		}
		if(self.classname != STR_PLAYER || self.health <= 0)
		{ 
			sprint(self, "Can't spawn turrets while spectating/dead\n");
			return TRUE;
		}
		if(self.turret_cnt >= max_turrets)
		{
			sprint(self, strcat("Can't spawn more than ", ftos(max_turrets), " turrets\n"));
			return TRUE;
		}
		switch(argv(1))
		{
			case "plasma":
			{
                if(self.ammo_fuel < autocvar_g_td_turret_plasma_cost) break;
				self.ammo_fuel -= autocvar_g_td_turret_plasma_cost;
				spawnturret(self, self, "turret_plasma", trace_endpos);
				sprint(self, "Spawned 1 plasma turret", "\n");
				return TRUE;
			}
			case "mlrs":
			{
                if(self.ammo_fuel < autocvar_g_td_turret_mlrs_cost) break;
				self.ammo_fuel -= autocvar_g_td_turret_mlrs_cost;
				spawnturret(self, self, "turret_mlrs", trace_endpos);
				sprint(self, "Spawned 1 MLRS turret", "\n");
				return TRUE;
			}
			case "walker":
			{
                if(self.ammo_fuel < autocvar_g_td_turret_walker_cost) break;
				self.ammo_fuel -= autocvar_g_td_turret_walker_cost;
				spawnturret(self, self, "turret_walker", trace_endpos);
				sprint(self, "Spawned 1 walker turret", "\n");
				return TRUE;
			}
			case "towerbuff":
			{
                if(self.ammo_fuel < autocvar_g_td_tower_buff_cost) break;
				self.ammo_fuel -= autocvar_g_td_tower_buff_cost;
				spawnturret(self, self, "turret_fusionreactor", trace_endpos);
				sprint(self, "Spawned 1 tower buff turret\n");
				return TRUE;
			}
			default:
			{
				sprint(self, "Invalid turret. type 'cmd turret list' to see a list of all available turrets.\n");
				return TRUE;
			}
		}
		sprint(self, strcat("You do not have enough fuel to spawn a ", argv(1), " turret\n"));
		return TRUE;
	}
	if(cmd_name == "buffturret")
	{
		if(trace_ent.realowner != self || !(trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET))
		{
			sprint(self, "You need to aim at your turret to upgrade it\n");
			return TRUE;
		}
		if(self.ammo_fuel < autocvar_g_td_turret_upgrade_cost)	
		{
			sprint(self, strcat("You need ", ftos(autocvar_g_td_turret_upgrade_cost), " fuel to increase this turret's power\n"));
			return TRUE;
		}
		if(trace_ent.turret_buff >= 3)
		{
			sprint(self, "This turret cannot be buffed up any higher\n");
			return TRUE;
		}
		
		self.ammo_fuel -= autocvar_g_td_turret_upgrade_cost;
		trace_ent.SendFlags |= TNSF_STATUS;
		buffturret(trace_ent, 1.2);
		sprint(self, "Turret power increased by 20%!\n");
		
		return TRUE;
	}
	if(cmd_name == "turretremove")
	{
		if((trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && trace_ent.realowner == self)
		{
			self.turret_cnt -= 1;
			sprint(self, strcat("You removed your ", trace_ent.netname, "\n"));
			remove(trace_ent.tur_head);
			remove(trace_ent);
			return TRUE;
		}
		sprint(self, "You need to aim at your turret to remove it\n");
		return TRUE;
	}
	if(cmd_name == "debugmonsters")
	{
        sprint(self, strcat("^3Current wave: ^1", ftos(wave_count), "\n"));
		sprint(self, strcat("^3Maximum waves: ^1", ftos(max_waves), "\n"));
		sprint(self, strcat("^3Monster skill: ^1", ftos(monster_skill), "\n"));
		sprint(self, strcat("^3Current monsters: ^1", ftos(monster_count), "\n"));
		sprint(self, strcat("^3Maximum monsters: ^1", ftos(totalmonsters), "\n"));
        sprint(self, strcat("^3Current ogres: ^1", ftos(n_ogres), "\n"));
        sprint(self, strcat("^3Current knights: ^1", ftos(n_knights), "\n"));
        sprint(self, strcat("^3Current dogs: ^1", ftos(n_dogs), "\n"));
        sprint(self, strcat("^3Current shamblers: ^1", ftos(n_shamblers), "\n"));
        sprint(self, strcat("^3Current scrags: ^1", ftos(n_wizards), "\n"));
        sprint(self, strcat("^3Current vores: ^1", ftos(n_shalraths), "\n"));
        sprint(self, strcat("^3Current grunts: ^1", ftos(n_soldiers), "\n"));
        sprint(self, strcat("^3Current hell knights: ^1", ftos(n_hknights), "\n"));
        sprint(self, strcat("^3Current enforcers: ^1", ftos(n_enforcers), "\n"));
        sprint(self, strcat("^3Current fiends: ^1", ftos(n_demons), "\n"));
		sprint(self, strcat("^3Current zombies: ^1", ftos(n_zombies), "\n"));
		sprint(self, strcat("^3Current spawns: ^1", ftos(n_tarbabies), "\n"));
		sprint(self, strcat("^3Current rotfish: ^1", ftos(n_fish), "\n"));
		sprint(self, strcat("^3Current spiders: ^1", ftos(n_spiders), "\n"));
		return TRUE;
	}
	
	return FALSE;
}

MUTATOR_DEFINITION(gamemode_td)
{
	MUTATOR_HOOK(MonsterSpawn, td_MonsterSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterDies, td_MonsterDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterMove, td_MonsterMove, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterFindTarget, td_MonsterFindTarget, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterCheckBossFlag, td_MonsterCheckBossFlag, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, td_SetStartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(TurretValidateTarget, td_TurretValidateTarget, CBC_ORDER_ANY);
	MUTATOR_HOOK(TurretSpawn, td_TurretSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, td_GiveFragsForKill, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, td_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, td_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, td_PlayerDamage_Calculate, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, td_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_ParseClientCommand, td_PlayerCommand, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");	
		cvar_settemp("g_monsters", "1");
		cvar_settemp("g_turrets", "1");
		td_Init();
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
	}

	return FALSE;
}
