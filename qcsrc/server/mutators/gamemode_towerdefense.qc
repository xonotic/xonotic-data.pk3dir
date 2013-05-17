float redalive, bluealive, total_alive;

var float max_monsters = 20;
var float max_alive = 10;

float total_killed;

var float max_turrets = 3;

.float newfuel; // hack to not give players fuel every time they spawn

float last_check;

.float turret_cnt;

.float level;
.float last_trace;

void td_debug(string input)
{
	switch(autocvar_g_td_debug)
	{
		case 1: dprint(input); break;
		case 2: print(input); break;
	}
}

void td_waypoint_link(float tm, vector from, vector to)
{
	switch(tm)
	{
		case NUM_TEAM_1:
			WarpZone_TrailParticles(world, particleeffectnum("waypoint_link_red"), from, to);
			break;
		case NUM_TEAM_2:
			WarpZone_TrailParticles(world, particleeffectnum("waypoint_link_blue"), from, to);
			break;
	}
}

void td_waypoint_think()
{
	if(gameover)
	{
		remove(self);
		return;
	}
	
	if(time >= self.last_trace)
	{
		entity e, e2, e3;
		
		e = find(world, targetname, self.target);
		e2 = find(world, target, self.targetname);
		e3 = find(world, targetname, self.target2);
		
		if(e.classname == "td_waypoint" || e.flags & FL_GENERATOR)
			td_waypoint_link(self.team, self.origin, e.origin);
		if(e2.classname == "td_spawnpoint")
			td_waypoint_link(self.team, self.origin, e2.origin);
		if(e3.classname == "td_waypoint" || e3.flags & FL_GENERATOR)
			td_waypoint_link(self.team, self.origin, e3.origin);
		
		self.last_trace = time + 0.5;
	}
	
	self.nextthink = time + 0.1;
}

void td_generator_die() 
{
	if(autocvar_sv_eventlog)
		GameLogEcho(":gendestroyed");
	
	Send_Notification(NOTIF_ALL, world, MSG_MULTI, MULTI_TD_GENDESTROYED);
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	
	WaypointSprite_Kill(self.sprite);
}

void td_generator_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) 
{
	if(IS_PLAYER(attacker) || attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET || attacker.vehicle_flags & VHF_ISVEHICLE || self.takedamage == DAMAGE_NO)
		return;
		
	entity head;
		
	if (time > self.pain_finished)
	{
		self.pain_finished = time + 10;
		play2team(self.team, "onslaught/generator_underattack.wav");
	}
	
	if (random() < 0.5)
		spamsound(self, CH_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
	else
		spamsound(self, CH_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);
	
	
	FOR_EACH_REALPLAYER(head)
	if(!IsDifferentTeam(head, self))
		Send_Notification(NOTIF_ONE, head, MSG_CENTER, CENTER_TD_GENDAMAGED);
	
	self.health -= damage;
	
	WaypointSprite_UpdateHealth(self.sprite, self.health);
		
	if(self.health <= 0)
	{
		FOR_EACH_REALPLAYER(head)
		if(!IsDifferentTeam(head, attacker))
			PlayerScore_Add(head, SP_TD_DESTROYS, 1);
		
		TeamScore_AddToTeam(attacker.team, ST_TD_DESTROYS, 1);
		td_generator_die();
	}
		
	self.SendFlags |= GSF_STATUS;
}

void td_generator_setup()
{
	self.think 			= func_null;
	self.nextthink 		= -1;
	self.solid			= SOLID_BBOX;
	self.takedamage		= DAMAGE_AIM;
	self.event_damage	= td_generator_damage;
	self.movetype		= MOVETYPE_NONE;
	self.monster_attack	= TRUE;
	self.SendFlags		= GSF_SETUP;
	self.netname		= "Generator";
	self.SendFlags	   |= GSF_STATUS;
	
	WaypointSprite_SpawnFixed(self.netname, self.origin + '0 0 90', self, sprite, RADARICON_OBJECTIVE, Team_ColorRGB(self.team));	
	WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
}

void AnnounceSpawn(string anounce)
{
	entity e;
	Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_TD_ANNOUNCE_SPAWN, anounce);
	
	FOR_EACH_REALCLIENT(e) soundto(MSG_ONE, e, CHAN_AUTO, "kh/alarm.wav", VOL_BASE, ATTN_NONE);
}

entity PickSpawn (float tm)
{
	entity e;
	RandomSelection_Init();
	for(e = world;(e = find(e, classname, "td_spawnpoint")); )
	if(e.team == tm)
		RandomSelection_Add(e, 0, string_null, 1, 1);

	return RandomSelection_chosen_ent;
}

void TD_SpawnMonster(float tm, string mnster)
{
	entity e, mon;
	
	e = PickSpawn(tm);
		
	if(e == world)
	{
		td_debug("Warning: couldn't find any td_spawnpoint spawnpoints, no monsters will spawn!\n");
		return;
	}
  
	mon = spawnmonster(mnster, e, e, e.origin, FALSE, 2);
	if(e.target2)
	{
		if(random() <= 0.5 && e.target)
			mon.target2 = e.target;
		else
			mon.target2 = e.target2;
	}
	else
		mon.target2 = e.target;
}

string monster_type2string(float mnster)
{
	switch(mnster)
	{
		case MONSTER_ZOMBIE: return "zombie";
		case MONSTER_BRUTE: return "brute";
		case MONSTER_ANIMUS: return "animus";
		case MONSTER_SHAMBLER: return "shambler";
		case MONSTER_BRUISER: return "bruiser";
		case MONSTER_WYVERN: return "wyvern";
		case MONSTER_CERBERUS: return "cerberus";
		case MONSTER_SLIME: return "slime";
		case MONSTER_KNIGHT: return "knight";
		case MONSTER_STINGRAY: return "stingray";
		case MONSTER_MAGE: return "mage";
		case MONSTER_SPIDER: return "spider";
		default: return "";
	}
}

float RandomMonster()
{
	RandomSelection_Init();
	
	float i;
	
	for(i = MONSTER_FIRST + 1; i < MONSTER_LAST; ++i)
	{
		if(i == MONSTER_STINGRAY || i == MONSTER_WYVERN)
			continue; // flying/swimming monsters not yet supported
		
		RandomSelection_Add(world, i, "", 1, 1);
	}
	
	return RandomSelection_chosen_float;
}

void SpawnMonsters(float tm)
{
	float whichmon;
	
	whichmon = RandomMonster();
	
	TD_SpawnMonster(tm, monster_type2string(whichmon));
}

entity PickGenerator(float tm)
{
	entity head;
	
	RandomSelection_Init();
	for(head = world;(head = findflags(head, flags, FL_GENERATOR)); )
	if(head.team != tm)
		RandomSelection_Add(head, 0, string_null, 1, 1);
	
	return RandomSelection_chosen_ent;
}

float td_checkfuel(entity ent, string tur)
{
	float turcost = cvar(strcat("g_td_turret_", tur, "_cost"));
	
	if(ent.ammo_fuel < turcost)
	{
		Send_Notification(NOTIF_ONE, ent, MSG_MULTI, MULTI_TD_NOFUEL);
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
	self.team = own.team;
	
	switch(turet)
	{
		case "plasma": spawnfunc_turret_plasma(); break;
		case "mlrs": spawnfunc_turret_mlrs(); break;
		case "walker": spawnfunc_turret_walker(); break;
		case "flac": spawnfunc_turret_flac(); break;
		case "towerbuff": spawnfunc_turret_fusionreactor(); break;
		default: Send_Notification(NOTIF_ONE, spawnedby, MSG_INFO, INFO_TD_INVALID); remove(self); self = oldself; return;
	}
	
	Send_Notification(NOTIF_ONE, spawnedby, MSG_MULTI, MULTI_TD_SPAWN);
		
	self = oldself;
}

void spawn_td_fuel(float fuel_size)
{
	if not(g_td) {remove(self); return; }
	
	self.ammo_fuel = fuel_size * monster_skill;
	StartItem("models/items/g_fuel.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "Turret Fuel", IT_FUEL, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
	
	self.velocity = randomvec() * 175 + '0 0 325';
}

// round handling
#define TD_ALIVE_TEAMS() ((redalive > 0) + (bluealive > 0))
#define TD_ALIVE_TEAMS_OK() (TD_ALIVE_TEAMS() == 2)
void TD_RoundStart()
{
	allowed_to_spawn = TRUE;
}

void TD_count_alive_monsters()
{
	entity head;
	
	total_alive = 0;
	
	FOR_EACH_MONSTER(head)
	{
		if(head.health <= 0) continue;
		
		++total_alive;
		
		switch(head.team)
		{
			case NUM_TEAM_1:
				++redalive;
			case NUM_TEAM_2:
				++bluealive;
		}
	}
}

float TD_GetWinnerTeam()
{
	float winner_team = 0;
	if(redalive >= 1)
		winner_team = NUM_TEAM_1;
	if(bluealive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_2;
	}
	if(winner_team)
		return winner_team;
	return -1; // no monster left
}

float TD_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, 1, 180);
		return 1;
	}
	
	TD_count_alive_monsters();
	
	if(total_alive < max_alive && time >= last_check && total_killed < max_monsters)
	{
		SpawnMonsters(NUM_TEAM_1);
		SpawnMonsters(NUM_TEAM_2);
		
		last_check = time + 0.5;
	}
	
	if(total_killed < 1)
		return 0; // nothing has died, can't be a tie
	
	if(TD_ALIVE_TEAMS() > 1)
		return 0;

	float winner_team = TD_GetWinnerTeam();
	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, APP_TEAM_NUM_4(winner_team, CENTER_ROUND_TEAM_WIN_));
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_NUM_4(winner_team, INFO_ROUND_TEAM_WIN_));
		TeamScore_AddToTeam(winner_team, ST_SCORE, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_TIED);
	}

	round_handler_Init(5, 1, 180);
	return 1;
}

float TD_CheckTeams()
{
	allowed_to_spawn = TRUE;
	
	return TRUE;
}

// spawnfuncs	
void spawnfunc_td_generator()
{
	if not(g_td) { remove(self); return; }
	if not(self.team)
	{
		td_debug("Generator without a team, removing it.\n");
		remove(self);
		return;
	}
	
	precache_sound("onslaught/generator_underattack.wav");
	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	precache_sound("weapons/rocket_impact.wav");
	
	if not(self.health)
		self.health = 1000;
		
	self.max_health = self.health;
	self.classname = "td_generator";
	self.flags = FL_GENERATOR;
	
	setsize(self, GENERATOR_MIN, GENERATOR_MAX);
	
	setorigin(self, self.origin + '0 0 20');
	droptofloor();
	
	generator_link(td_generator_setup);
}

void spawnfunc_td_waypoint()
{
	if not(g_td) { remove(self); return; }
	if not(self.team)
	{
		td_debug("Tower Defense waypoint without a team, removing it.\n");
		remove(self);
		return;
	}
	
	setsize(self, '-6 -6 -6', '6 6 6');
	
	if not(self.noalign)
	{
		setorigin(self, self.origin + '0 0 20');
		droptofloor();
	}
	
	self.classname = "td_waypoint";
	self.think = td_waypoint_think;
	self.nextthink = time + 0.1;
}

void spawnfunc_td_controller()
{
	if not(g_td) { remove(self); return; }
}

void spawnfunc_td_spawnpoint()
{
	if not(g_td) { remove(self); return; }
	
	self.classname = "td_spawnpoint";
	
	self.effects = EF_STARDUST;
}

// initialization stuff
void td_ScoreRules()
{
	ScoreRules_basics(2, SFL_SORT_PRIO_SECONDARY, SFL_SORT_PRIO_SECONDARY, TRUE);
	ScoreInfo_SetLabel_TeamScore(ST_TD_DESTROYS,  "destroyed", SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_TD_DESTROYS,"destroyed", SFL_SORT_PRIO_PRIMARY);
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
	
	round_handler_Spawn(TD_CheckTeams, TD_CheckWinner, TD_RoundStart);
	round_handler_Init(5, 10, 180);
}

// mutator hooks
MUTATOR_HOOKFUNCTION(td_TurretSpawn)
{
	if(self.realowner == world)
		return TRUE;
		
	self.bot_attack = FALSE;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterSpawn)
{
	if(!self.team || !self.realowner)
	{
		td_debug(strcat("Removed monster ", self.netname, " with team ", ftos(self.team), "\n"));
		WaypointSprite_Kill(self.sprite);
		if(self.weaponentity) remove(self.weaponentity);
		remove(self);
		return FALSE;
	}
	
	self.candrop = FALSE;
	self.bot_attack = FALSE;
	self.ammo_fuel = bound(20, 20 * self.level, 100);
	self.target_range = 300;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_CORPSE | DPCONTENTS_MONSTERCLIP;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterDies)
{
	vector backuporigin;
	entity oldself;
	
	total_killed++;
	
	backuporigin = self.origin;
	oldself = self;
	self = spawn();
	
	self.gravity = 1;
	setorigin(self, backuporigin + '0 0 5');
	spawn_td_fuel(oldself.ammo_fuel);
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

MUTATOR_HOOKFUNCTION(td_MonsterThink)
{
	if(time <= game_starttime && round_handler_IsActive())
		return TRUE;
		
	if(IS_PLAYER(self.enemy))
		self.enemy = world;

	if not(self.enemy) // don't change targets while attacking
	if(vlen(monster_target.origin - self.origin) <= 100)
	{
		if(monster_target.target2)
		{
			if(random() > 0.5)
				self.target2 = monster_target.target2;
			else
				self.target2 = monster_target.target;
		}
		else
			self.target2 = monster_target.target;
				
		monster_target = find(world, targetname, self.target2);
		
		if(monster_target == world)
			monster_target = PickGenerator(self.team);
			
		if(monster_target == world)
			return TRUE; // no generators or waypoints?!
	}
	
	td_debug(sprintf("Monster target: %s. Monster target2: %s. Monster target entity: %s.\n", self.target, self.target2, etos(monster_target)));
	
	monster_speed_run = (150 + random() * 4) * monster_skill;
	monster_speed_walk = (100 + random() * 4) * monster_skill;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_MonsterFindTarget)
{
	entity e;
	
	for(e = world;(e = findflags(e, monster_attack, TRUE)); ) 
	{
		if(ignore_turrets)
		if(e.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
			continue;
			
		if(e.flags & FL_MONSTER)
			continue; // don't attack other monsters?
		
		if(monster_isvalidtarget(e, self))
			self.enemy = e;
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_PlayerSpawn)
{
	self.monster_attack = FALSE;
	self.bot_attack = FALSE;
	
	if(self.newfuel)
	{
		self.ammo_fuel = self.newfuel;
		self.newfuel = 0;
	}
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_Damage)
{
	if(IS_PLAYER(frag_attacker))
	if(frag_target.flags & FL_MONSTER)
		frag_damage = 0;
		
	if(IS_PLAYER(frag_target))
	{
		frag_damage = 0;
		if(frag_attacker != frag_target)
			frag_force = '0 0 0';
	}
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) { return FALSE; } // command was already handled?
	
	vector org;
	
	makevectors(self.v_angle);
	
	org = self.origin + self.view_ofs + v_forward * 100;
	
	tracebox(self.origin + self.view_ofs, '-16 -16 -16', '16 16 16', org, MOVE_NORMAL, self);
	entity targ = trace_ent;
	if(targ.owner.realowner == self)
		targ = targ.owner;
	
	if(cmd_name == "turretspawn")
	{
		if(argv(1) == "list")
		{
			Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_LIST, "mlrs walker plasma towerbuff flac");
			return TRUE;
		}
		if(!IS_PLAYER(self) || self.health <= 0)
		{ 
			Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_CANTSPAWN);
			return TRUE;
		}
		if(max_turrets <= 0)
		{
			Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_DISABLED);
			return TRUE;
		}
		if(self.turret_cnt >= max_turrets)
		{
			Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_MAXTURRETS, max_turrets);
			return TRUE;
		}
		
		spawnturret(self, self, argv(1), trace_endpos);
		
		return TRUE;
	}
	if(cmd_name == "turretremove")
	{
		if((targ.turrcaps_flags & TFL_TURRCAPS_ISTURRET) && (targ.playerid == self.playerid || targ.realowner == self))
		{
			self.turret_cnt -= 1;
			Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_REMOVE);
			WaypointSprite_Kill(targ.sprite);
			remove(targ.tur_head);
			remove(targ);
			return TRUE;
		}
		Send_Notification(NOTIF_ONE, self, MSG_MULTI, MULTI_TD_AIM_REMOVE);
		return TRUE;
	}
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_ClientConnect)
{
	self.newfuel = 75;
	
	entity t;
	
	self.turret_cnt = 0;
	
	for(t = world; (t = findflags(t, turrcaps_flags, TFL_TURRCAPS_ISTURRET)); )
	if(t.playerid == self.playerid)
	{
		t.realowner = self;
		self.turret_cnt += 1; // nice try
	}
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_DisableVehicles)
{
	return TRUE;
}

MUTATOR_HOOKFUNCTION(td_SetModname)
{
	g_cloaked = 1;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_TurretValidateTarget)
{
	if(time < game_starttime || (time <= game_starttime && round_handler_IsActive()) || gameover)
	{
		turret_target = world;
		return FALSE; // battle hasn't started
	}

	if(turret_flags & TFL_TARGETSELECT_MISSILESONLY)
    if(turret_target.flags & FL_PROJECTILE)
	if(turret_target.owner.flags & FL_MONSTER)
        return TRUE; // flac support
			
	if(turret.turrcaps_flags & TFL_TURRCAPS_SUPPORT && turret_target.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
		return TRUE;
	if not(turret_target.flags & FL_MONSTER)
		turret_target = world;
		
	if(!IsDifferentTeam(turret_target, turret))
		turret_target = world;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_TurretDies)
{
	if(self.realowner)
		self.realowner.turret_cnt -= 1;
			
	return FALSE;
}

MUTATOR_HOOKFUNCTION(td_GetTeamCount)
{
	ret_float = 2;
	
	return FALSE;
}

MUTATOR_DEFINITION(gamemode_towerdefense)
{
	MUTATOR_HOOK(TurretSpawn, td_TurretSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterSpawn, td_MonsterSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterDies, td_MonsterDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterMove, td_MonsterThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterFindTarget, td_MonsterFindTarget, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, td_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, td_Damage, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_ParseClientCommand, td_PlayerCommand, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientConnect, td_ClientConnect, CBC_ORDER_ANY);
	MUTATOR_HOOK(VehicleSpawn, td_DisableVehicles, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, td_SetModname, CBC_ORDER_ANY);
	MUTATOR_HOOK(TurretValidateTarget, td_TurretValidateTarget, CBC_ORDER_ANY);
	MUTATOR_HOOK(TurretDies, td_TurretDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(GetTeamCount, td_GetTeamCount, CBC_ORDER_ANY);

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
