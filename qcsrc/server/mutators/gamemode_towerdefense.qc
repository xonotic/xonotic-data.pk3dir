// Tower Defense
// Gamemode by Mario
 
void spawnfunc_td_controller()
{
	if not(g_td) { remove(self); return; }
	
	if(autocvar_g_td_force_settings)
	{
		// TODO: find a better way to do this?
		self.dontend = FALSE;
		self.maxwaves = 0;
		self.monstercount = 0;
		self.startwave = 0;
		self.maxturrets = 0;
		self.buildtime = 0;
		self.mspeed_walk = 0;
		self.mspeed_run = 0;
		self.spawndelay = 0;
		self.maxcurrent = 0;
		self.ignoreturrets = 0;
	}
		
	self.netname = "Tower Defense controller entity";
	self.classname = "td_controller";
		
	gensurvived = FALSE;
	
	td_dont_end = ((self.dontend == 0) ? autocvar_g_td_generator_dontend : self.dontend);
	max_waves = ((self.maxwaves == 0) ? autocvar_g_td_max_waves : self.maxwaves);
	totalmonsters = ((self.monstercount == 0) ? autocvar_g_td_monster_count : self.monstercount);
	wave_count = ((self.startwave == 0) ? autocvar_g_td_start_wave : self.startwave);
	max_turrets = ((self.maxturrets == 0) ? autocvar_g_td_turret_max : self.maxturrets);
	build_time = ((self.buildtime == 0) ? autocvar_g_td_buildphase_time : self.buildtime);
	m_speed_walk = ((self.mspeed_walk == 0) ? autocvar_g_td_monsters_speed_walk : self.mspeed_walk);
	m_speed_run = ((self.mspeed_run == 0) ? autocvar_g_td_monsters_speed_run : self.mspeed_run);
	spawn_delay = ((self.spawndelay == 0) ? autocvar_g_td_monsters_spawn_delay : self.spawndelay);
	max_current = ((self.maxcurrent == 0) ? autocvar_g_td_current_monsters : self.maxcurrent);
	ignore_turrets = ((self.ignoreturrets == 0) ? autocvar_g_td_monsters_ignore_turrets : self.ignoreturrets);
	
	if(autocvar_g_td_monsters_skill_start)
		monster_skill = autocvar_g_td_monsters_skill_start;
		
	wave_end(TRUE);
}

void td_generator_die() 
{
	if(autocvar_sv_eventlog)
		GameLogEcho(":gendestroyed");
		
	gendestroyed = TRUE;
	
	pointparticles(particleeffectnum("explosion_medium"), self.origin, '0 0 0', 1);
	sound(self, CH_TRIGGER, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	
	Send_Notification(NOTIF_ALL, world, MSG_MULTI, MULTI_TD_GENDESTROYED);
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	td_gencount			-= 1;
	
	WaypointSprite_Kill(self.sprite);
}

void td_generator_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) 
{
	if(IS_PLAYER(attacker) || attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET || attacker.vehicle_flags & VHF_ISVEHICLE || self.takedamage == DAMAGE_NO)
		return;
		
	if (time > self.pain_finished)
	{
		self.pain_finished = time + 10;
		play2all("onslaught/generator_underattack.wav");
	}
	
	if (random() < 0.5)
		spamsound(self, CH_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
	else
		spamsound(self, CH_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);
	
	Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_TD_GENDAMAGED);
	
	self.health -= damage;
	
	WaypointSprite_UpdateHealth(self.sprite, self.health);
		
	if(self.health <= 0) 
		td_generator_die();
		
	self.SendFlags |= GSF_STATUS;
}

void td_generator_setup()
{
	self.think 			= func_null;
	self.nextthink 		= -1;
	self.solid		    = SOLID_BBOX;
	self.takedamage	    = DAMAGE_AIM;
	self.event_damage   = td_generator_damage;
	self.enemy		    = world;
	self.max_health	    = self.health;
	self.movetype	    = MOVETYPE_NONE;
	self.monster_attack = TRUE;
	self.netname		= "Generator";
	
	self.SendFlags |= GSF_SETUP;
	
	WaypointSprite_SpawnFixed(self.netname, self.origin + '0 0 90', self, sprite, RADARICON_OBJECTIVE, '1 0.5 0');	
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
}

void spawnfunc_td_generator() 
{
	if not(g_td) { remove(self); return; }
	
	precache_sound("onslaught/generator_underattack.wav");
	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	precache_sound("weapons/rocket_impact.wav");
	
	gendestroyed = FALSE;
	
	if not(self.health)
		self.health = autocvar_g_td_generator_health;
	
	self.classname = "td_generator";
	td_gencount += 1;
	
	setsize(self, GENERATOR_MIN, GENERATOR_MAX);
	
	setorigin(self, self.origin + '0 0 20');
	droptofloor();
	
	generator_link(td_generator_setup);
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
	if not(g_td) {remove(self); return; }
	
	self.ammo_fuel = fuel_size * monster_skill;
	StartItem("models/items/g_fuel.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "Turret Fuel", IT_FUEL, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
	
	self.velocity = randomvec() * 175 + '0 0 325';
}

void spawnfunc_td_waypoint() 
{
	if not(g_td) { remove(self); return; }
	
	self.classname = "td_waypoint";
}

void spawnfunc_monster_swarm()
{
	if not(g_td) { remove(self); return; }
	
	self.flags = SWARM_NORMAL; // marked as a spawnpoint
	self.classname = "monster_swarm";
	
	if(self.spawntype == SWARM_SWIM) waterspawns_count += 1;
	if(self.spawntype == SWARM_FLY) flyspawns_count += 1;
	
	WaypointSprite_SpawnFixed("Monsters", self.origin + '0 0 60', self, sprite, RADARICON_HERE, '0 0 1');
	
	if(self.target == "")
		dprint("Warning: monster_swarm entity without a set target\n");
}

void barricade_touch()
{
	if not(other.flags & FL_MONSTER)
		return;
		
	if(time < self.dmg_time)
		return;
		
	Damage(other, self, self, autocvar_g_td_barricade_damage, DEATH_HURTTRIGGER, self.origin, '0 0 0');
	
	self.dmg_time = time + 1;
}

void barricade_die()
{
	self.takedamage = DAMAGE_NO;
	self.event_damage = func_null;
	
	WaypointSprite_Kill(self.sprite);
	
	pointparticles(particleeffectnum("explosion_medium"), self.origin, '0 0 0', 1);
	sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	
	if(self.realowner)
		self.realowner.turret_cnt -= 1;
		
	self.think = SUB_Remove;
	self.nextthink = time;
}

void barricade_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if not(attacker.flags & FL_MONSTER) return;
	
	self.health -= damage;
	
	WaypointSprite_UpdateHealth(self.sprite, self.health);
	
	if(self.health < 1)
		barricade_die();
}

void spawn_barricade()
{
	self.health = 2000;
	self.max_health = self.health;
	self.dmg_time = time;
	self.touch = barricade_touch;
	self.think = func_null;
	self.nextthink = -1;
	self.takedamage = DAMAGE_AIM;
	self.turrcaps_flags = TFL_TURRCAPS_ISTURRET; // for turretremove commands etc.
	self.solid = SOLID_CORPSE; // hax
	self.event_damage = barricade_damage;
	self.netname = "Barricade";
	
	WaypointSprite_Spawn(self.netname, 0, 1200, self, '0 0 110', world, 0, self, sprite, FALSE, RADARICON_DOMPOINT, '1 1 0');	
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
	
	precache_model("models/td/barricade.md3");
	setmodel(self, "models/td/barricade.md3");
	
	droptofloor();
	
	self.movetype = MOVETYPE_NONE;
}

float td_checkfuel(entity ent, string tur)
{
	float turcost = cvar(strcat("g_td_turret_", tur, "_cost"));
	
	if(ent.ammo_fuel < turcost)
	{
		Send_Notification(NOTIF_ONE, ent, MSG_INFO, INFO_TD_NOFUEL);
		return FALSE;
	}
	
	ent.ammo_fuel -= turcost;
	
	return TRUE;
}	

void spawnturret(entity spawnedby, entity own, string turet, vector orig)
{
	if not(IS_PLAYER(spawnedby)) { dprint("Warning: A non-player entity tried to spawn a turret\n"); return; }
	if not(td_checkfuel(spawnedby, turet)) { return; }
		
	entity oldself;
	
	oldself = self;
	self = spawn();
	
	setorigin(self, orig);
	self.spawnflags = TSL_NO_RESPAWN;
	self.monster_attack = TRUE;
	self.realowner = own;
	self.playerid = own.playerid;
	self.angles_y = spawnedby.v_angle_y;
	spawnedby.turret_cnt += 1;
	self.colormap = spawnedby.colormap;
	self.colormod = '1 1 1';
	
	switch(turet)
	{
		case "plasma": spawnfunc_turret_plasma(); break;
		case "mlrs": spawnfunc_turret_mlrs(); break;
		case "walker": spawnfunc_turret_walker(); break;
		case "flac": spawnfunc_turret_flac(); break;
		case "towerbuff": spawnfunc_turret_fusionreactor(); break;
		case "barricade": spawn_barricade(); break;
		default: Send_Notification(NOTIF_ONE, spawnedby, MSG_INFO, INFO_TD_INVALID); remove(self); self = oldself; return;
	}
	
	Send_Notification(NOTIF_ONE, spawnedby, MSG_INFO, INFO_TD_SPAWN);
		
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
	Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_TD_ANNOUNCE_SPAWN, anounce);
}

entity PickSpawn (float strngth, float type)
{
	entity e;
	RandomSelection_Init();
	for(e = world;(e = find(e, classname, "monster_swarm")); )
	{
		if(flyspawns_count > 0 && type == SWARM_FLY && e.spawntype != SWARM_FLY) continue;
		if(waterspawns_count > 0 && type == SWARM_SWIM && e.spawntype != SWARM_SWIM) continue;
		
		RandomSelection_Add(e, 0, string_null, 1, 1);
	}

	return RandomSelection_chosen_ent;
}

void TD_SpawnMonster(string mnster, float strngth, float type)
{
	entity e, mon;
	
	e = PickSpawn(strngth, type);
	
	if(e == world) // couldn't find anything for our class, so check for normal spawns
		e = PickSpawn(SWARM_NORMAL, SWARM_NORMAL);
		
	if(e == world)
	{
		dprint("Warning: couldn't find any monster_swarm spawnpoints, no monsters will spawn!\n");
		return;
	}
  
	mon = spawnmonster(mnster, e, e, e.origin, FALSE, 0);
	if(e.target2)
	{
		if(random() > 0.5)
			mon.target2 = e.target2;
		else
			mon.target2 = e.target;
	}
	else
		mon.target2 = e.target;
}

float Monster_GetStrength(string mnster)
{
	switch(mnster)
	{
		case "knight":
		case "wizard":
		case "soldier":
		case "zombie":
		case "tarbaby":
		case "dog":
		case "spider":
		case "fish":
			return SWARM_WEAK;
		case "ogre":
		case "shambler":
		case "shalrath":
		case "hellknight":
		case "demon":
			return SWARM_STRONG;
		default:
			return SWARM_NORMAL;
	}
}

float Monster_GetType(string mnster)
{
	switch(mnster)
	{
		default:
		case "knight":
		case "soldier":
		case "zombie":
		case "spider":
		case "tarbaby":
		case "dog":
		case "ogre":
		case "shambler":
		case "shalrath":
		case "hellknight":
		case "demon":
			return SWARM_NORMAL;
		case "wizard":
			return SWARM_FLY;
		case "fish":
			return SWARM_SWIM;
	}
}

string RandomMonster()
{
	RandomSelection_Init();
	
	if(n_demons) RandomSelection_Add(world, 0, "demon", 1, 1);
	if(n_shalraths) RandomSelection_Add(world, 0, "vore", 1, 1);
	if(n_soldiers) RandomSelection_Add(world, 0, "soldier", 1, 1);
	if(n_hknights) RandomSelection_Add(world, 0, "hellknight", 1, 1);
	if(n_zombies) RandomSelection_Add(world, 0, "zombie", 1, 1);
	if(n_spiders) RandomSelection_Add(world, 0, "spider", 1, 1);
	if(n_ogres) RandomSelection_Add(world, 0, "ogre", 1, 1);
	if(n_dogs) RandomSelection_Add(world, 0, "dog", 1, 1);
	if(n_knights) RandomSelection_Add(world, 0, "knight", 1, 1);
	if(n_shamblers) RandomSelection_Add(world, 0, "shambler", 0.2, 0.2);
	if(n_tarbabies) RandomSelection_Add(world, 0, "spawn", 0.2, 0.2);
	if(n_wizards && flyspawns_count) RandomSelection_Add(world, 0, "scrag", 1, 1);
	if(n_fish && waterspawns_count) RandomSelection_Add(world, 0, "fish", 0.2, 0.2);
	
	return RandomSelection_chosen_string;
}

void combat_phase()
{
	string whichmon;
	float mstrength, montype;
	
	current_phase = PHASE_COMBAT;
	
	if(monster_count <= 0)
	{
		wave_end(FALSE);
		return;
	}
	
	self.think = combat_phase;
	
	whichmon = RandomMonster();
	
	mstrength = Monster_GetStrength(whichmon);
	montype = Monster_GetType(whichmon);
	
	if(current_monsters <= max_current && whichmon != "")
	{
		TD_SpawnMonster(whichmon, mstrength, montype);
		self.nextthink = time + spawn_delay;
	}
	else
		self.nextthink = time + 6;
}

void queue_monsters(float maxmonsters)
{
	float mc = 10; // note: shambler + tarbaby = 1
	
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
	entity gen;
	
	Send_Notification(NOTIF_ALL, world, MSG_MULTI, MULTI_TD_PHASE_COMBAT);
	
	if(autocvar_sv_eventlog)
		GameLogEcho(":combatphase");
		
	self.think = combat_phase;
	self.nextthink = time + 1;
	
	for(gen = world;(gen = find(gen, classname, "td_generator")); )
		gen.takedamage = DAMAGE_AIM;
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
	float n_players = 0, gen_washealed = FALSE, mcount, mskill;
	
	current_phase = PHASE_BUILD;
	
	for(head = world;(head = find(head, classname, "td_generator")); )
	{
		if(head.health <= 15 && head.max_health > 100)
			Announce("lastsecond");
			
		if(head.health < head.max_health)
		{
			gen_washealed = TRUE;
			head.health = head.max_health;
			WaypointSprite_UpdateHealth(head.sprite, head.health);
			head.SendFlags |= GSF_STATUS;
		}
		head.takedamage = DAMAGE_NO;
	}
	
	FOR_EACH_PLAYER(head)
	{
		if(head.health < 100) head.health = 100;
		if(gen_washealed) PlayerScore_Add(head, SP_TD_SCORE, -autocvar_g_td_generator_damaged_points);
			
        n_players += 1;
	}
	
	mcount = autocvar_g_td_monster_count_increment * wave_count;
	mskill = n_players * 0.02;
		
	totalmonsters += mcount;
	monster_skill += autocvar_g_td_monsters_skill_increment;
	monster_skill += mskill;
	
	if(monster_skill < 1) monster_skill = 1;
	if(totalmonsters < 1) totalmonsters = ((autocvar_g_td_monster_count > 0) ? autocvar_g_td_monster_count : 10);
	if(wave_count < 1) wave_count = 1;
	
	Send_Notification(NOTIF_ALL, world, MSG_MULTI, MULTI_TD_PHASE_BUILD, wave_count, totalmonsters, build_time);
    
    FOR_EACH_MONSTER(head)
    {
		if(head.health <= 0)
			continue;
			
        dprint(strcat("Warning: Monster still alive during build phase! Monster name: ", head.netname, "\n"));
		
		WaypointSprite_Kill(head.sprite);
        remove(head);
    }
	
	monsters_total = totalmonsters;
	monsters_killed = 0;
		
	queue_monsters(totalmonsters);
	
	cphase_updates = -1;
	
	if(autocvar_sv_eventlog)
        GameLogEcho(strcat(":buildphase:", ftos(wave_count), ":", ftos(totalmonsters)));
	
	self.think = combat_phase_announce;
	self.nextthink = time + build_time - 6;
}

void wave_end(float starting)
{
	if not(starting)
	{
		Send_Notification(NOTIF_ALL, world, MSG_MULTI, MULTI_TD_VICTORY, ((wave_count >= max_waves) ? "Level" : "Wave"));
		
		if(autocvar_sv_eventlog)
            GameLogEcho(strcat(":wave:", ftos(wave_count), ":victory"));
	}
	
	if(wave_count >= max_waves)
	{
		gensurvived = TRUE;
		return;
	}
	
	if not(starting)
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

void td_Initialize()
{
	InitializeEntity(world, td_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(td_TurretValidateTarget)
{
	if(turret_flags & TFL_TARGETSELECT_MISSILESONLY)
    if(turret_target.flags & FL_PROJECTILE)
	if(turret_target.owner.flags & FL_MONSTER)
        return TRUE; // flac support
			
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

MUTATOR_HOOKFUNCTION(td_PlayerDamage)
{
	if(frag_attacker.realowner == frag_target)
		frag_damage = 0;
		
	if(frag_target.flags & FL_MONSTER && time < frag_target.spawnshieldtime)
		frag_damage = 0;
		
	if(frag_target.vehicle_flags & VHF_ISVEHICLE && !(frag_attacker.flags & FL_MONSTER))
		frag_damage = 0;
		
	if(frag_attacker.vehicle_flags & VHF_ISVEHICLE && !(frag_target.flags & FL_MONSTER))
		frag_damage = 0;
		
	if(!autocvar_g_td_pvp && frag_attacker != frag_target && IS_PLAYER(frag_target) && IS_PLAYER(frag_attacker))
	{
		frag_attacker.typehitsound += 1;
		frag_damage = 0;
	}
		
	if(frag_attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET && IS_PLAYER(frag_target))
		frag_damage = 0;
		
	if((frag_target.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && !(frag_attacker.flags & FL_MONSTER || frag_attacker.turrcaps_flags & TFL_TURRCAPS_SUPPORT))
		frag_damage = 0;
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_TurretDies)
{
	if(self.realowner)
		self.realowner.turret_cnt -= 1;
			
	return FALSE;
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
	
	if not(self.enemy) // don't change targets while attacking
	if((vlen(self.goalentity.origin - self.origin) <= 100 && self.goalentity.classname == "td_waypoint") || (vlen(self.goalentity.origin - self.origin) <= 200 && (self.flags & FL_FLY) && self.goalentity.classname == "td_waypoint"))
	{
		if(self.goalentity.target2)
		{
			if(random() > 0.5)
				self.target2 = self.goalentity.target2;
			else
				self.target2 = self.goalentity.target;
		}
		else
			self.target2 = self.goalentity.target;
				
		self.goalentity = find(world, targetname, self.target2);
		
		if(self.goalentity == world)
			self.goalentity = PickGenerator();
	}
	
	monster_speed_run = m_speed_run * monster_skill;
	monster_speed_walk = m_speed_walk * monster_skill;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterSpawn)
{
	if(self.realowner == world) // nothing spawned it, so kill it
	{
		WaypointSprite_Kill(self.sprite);
		remove(self);
		return TRUE;
	}
	
	current_monsters += 1;
	
	self.spawnshieldtime = time + autocvar_g_td_monsters_spawnshield_time;
	
	self.drop_size = self.health * 0.05;
	
	self.target_range = 600;
	
	if(self.drop_size < 1) self.drop_size = 1;
	
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_BODY;
	
	self.origin += '0 0 25'; // hopefully this fixes monsters falling through the floor
	
	switch(self.monsterid)
	{
		case MONSTER_ZOMBIE: n_zombies -= 1; break;
		case MONSTER_OGRE: n_ogres -= 1; break;
		case MONSTER_DEMON: n_demons -= 1; break;
		case MONSTER_SHAMBLER: n_shamblers -= 1; break;
		case MONSTER_KNIGHT: n_knights -= 1; break;
		case MONSTER_MARINE: n_soldiers -= 1; break;
		case MONSTER_SCRAG: n_wizards -= 1; break;
		case MONSTER_DOG: n_dogs -= 1; break;
		case MONSTER_TARBABY: n_tarbabies -= 1; break;
		case MONSTER_HELLKNIGHT: n_hknights -= 1; break;
		case MONSTER_FISH: n_fish -= 1; break;
		case MONSTER_MAGE: n_shalraths -= 1; break;
		case MONSTER_SPIDER: n_spiders -= 1; break;
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
	
	if(IS_PLAYER(frag_attacker))
	{
		PlayerScore_Add(frag_attacker, SP_TD_SCORE, autocvar_g_td_kill_points);
		PlayerScore_Add(frag_attacker, SP_TD_KILLS, 1);
	}
	else if(IS_PLAYER(frag_attacker.realowner) && frag_attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
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
		if(ignore_turrets)
		if(e.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
			continue;
		
		if(monster_isvalidtarget(e, self))
		if((vlen(trace_endpos - self.origin) < 200 && e.turrcaps_flags & TFL_TURRCAPS_ISTURRET) || (vlen(trace_endpos - self.origin) < 200 && e.classname != "td_generator") || (vlen(trace_endpos - self.origin) < 500 && e.classname == "td_generator"))
		{
			self.enemy = e;
		}
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_SetStartItems)
{
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

MUTATOR_HOOKFUNCTION(td_DisableVehicles)
{
	// you shall not spawn!
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) { return FALSE; } // command was already handled?
	
	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 100, MOVE_HITMODEL, self);
	
	if(cmd_name == "turretspawn")
	{
		if(argv(1) == "list")
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_LIST, "mlrs walker plasma towerbuff flac barricade");
			return TRUE;
		}
		if(!IS_PLAYER(self) || self.health <= 0)
		{ 
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_CANTSPAWN);
			return TRUE;
		}
		if(max_turrets <= 0)
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_TURRETS_DISABLED);
			return TRUE;
		}
		if(self.turret_cnt >= max_turrets)
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_MAXTURRETS, max_turrets);
			return TRUE;
		}
		
		spawnturret(self, self, argv(1), trace_endpos);
		
		return TRUE;
	}
	if(cmd_name == "repairturret")
	{
		if((trace_ent.playerid != self.playerid || trace_ent.realowner != self) || !(trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET))
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_AIM_REPAIR);
			return TRUE;
		}
		if(self.ammo_fuel < autocvar_g_td_turret_repair_cost)	
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_NOFUEL_REPAIR, autocvar_g_td_turret_repair_cost);
			return TRUE;
		}
		if(trace_ent.health >= trace_ent.max_health)
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_MAXHEALTH);
			return TRUE;
		}
		
		self.ammo_fuel -= autocvar_g_td_turret_repair_cost;
		trace_ent.SendFlags |= TNSF_STATUS;
		trace_ent.health = bound(1, trace_ent.health + 100, trace_ent.max_health);
		WaypointSprite_UpdateHealth(trace_ent.sprite, trace_ent.health);
		Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_REPAIR);
		
		return TRUE;
	}
	if(cmd_name == "buffturret")
	{
		if((trace_ent.playerid != self.playerid || trace_ent.realowner != self) || !(trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET))
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_AIM_UPGRADE);
			return TRUE;
		}
		if(self.ammo_fuel < autocvar_g_td_turret_upgrade_cost)	
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_NOFUEL_UPGRADE, autocvar_g_td_turret_upgrade_cost);
			return TRUE;
		}
		if(trace_ent.turret_buff >= 3)
		{
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_MAXPOWER);
			return TRUE;
		}
		
		self.ammo_fuel -= autocvar_g_td_turret_upgrade_cost;
		trace_ent.SendFlags |= TNSF_STATUS;
		buffturret(trace_ent, 1.2);
		WaypointSprite_UpdateHealth(trace_ent.sprite, trace_ent.health);
		Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_UPGRADE);
		
		return TRUE;
	}
	if(cmd_name == "turretremove")
	{
		if((trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && (trace_ent.playerid == self.playerid || trace_ent.realowner == self))
		{
			self.turret_cnt -= 1;
			Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_REMOVE);
			WaypointSprite_Kill(trace_ent.sprite);
			remove(trace_ent.tur_head);
			remove(trace_ent);
			return TRUE;
		}
		Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_TD_AIM_REMOVE);
		return TRUE;
	}
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_ClientConnect)
{
	entity t;
	
	self.turret_cnt = 0;
	
	for(t = world; (t = findflags(t, turrcaps_flags, TFL_TURRCAPS_ISTURRET)); )
	if(t.playerid == self.playerid)
	{
		t.realowner = self;
		self.turret_cnt += 1;
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
	MUTATOR_HOOK(TurretDies, td_TurretDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, td_GiveFragsForKill, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, td_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, td_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, td_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, td_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(VehicleSpawn, td_DisableVehicles, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_ParseClientCommand, td_PlayerCommand, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientConnect, td_ClientConnect, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");	
		cvar_settemp("g_monsters", "1");
		cvar_settemp("g_turrets", "1");
		td_Initialize();
	}
	
	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back td_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return FALSE;
}
