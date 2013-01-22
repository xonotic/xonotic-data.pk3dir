// size
const vector SPAWNER_MIN = '-35 -35 -10';
const vector SPAWNER_MAX = '35 35 70';

// cvars
float autocvar_g_monster_spawner;
float autocvar_g_monster_spawner_health;
float autocvar_g_monster_spawner_target_recheck_delay;
float autocvar_g_monster_spawner_target_range;
float autocvar_g_monster_spawner_spawn_range;
float autocvar_g_monster_spawner_maxmobs;
string autocvar_g_monster_spawner_forcespawn;

void() spawner_think;

void spawnmonsters ()
{
	if(self.spawner_monstercount >= autocvar_g_monster_spawner_maxmobs || self.frozen || self.freezetag_frozen)
		return;
		
	vector posi1 = '0 0 0', posi2 = '0 0 0', posi3 = '0 0 0', posi4 = '0 0 0', chosenposi = '0 0 0';
	float r = random();
	string type = string_null;
	entity e = world;
	
	self.spawner_monstercount += 1;
	
	if(self.spawnmob != "")
		type = self.spawnmob;
		
	if(autocvar_g_monster_spawner_forcespawn != "0")
		type = autocvar_g_monster_spawner_forcespawn;
		
	if(type == "" || type == "spawner") // spawner spawning spawners?!
		type = "knight";
	
	posi1 = self.origin - '0 70 -50' * self.scale;
	posi2 = self.origin + '0 70 50' * self.scale;
	posi3 = self.origin - '70 0 -50' * self.scale;
	posi4 = self.origin + '70 0 -50' * self.scale;
	   
	if (r < 0.20)
		chosenposi = posi1;
	else if (r < 0.50)
		chosenposi = posi2;
	else if (r < 80)
		chosenposi = posi3;
	else
		chosenposi = posi4;

	e = spawnmonster(type, self, self, chosenposi, FALSE, MONSTER_MOVE_WANDER);
	
	if(teamplay && autocvar_g_monsters_teams)
		e.team = self.team;
	
	if(self.spawnflags & MONSTERFLAG_GIANT)
		e.spawnflags = MONSTERFLAG_GIANT;
		
	if(self.flags & MONSTERFLAG_MINIBOSS)
		e.spawnflags = MONSTERFLAG_MINIBOSS;
}

void spawner_die () 
{
	setmodel(self, "");
	pointparticles(particleeffectnum(((self.scale > 3) ? "explosion_big" : "explosion_medium")), self.origin, '0 0 0', 1);
	sound (self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	
	self.solid		 	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.think		  	= Monster_Fade;
	self.nextthink	  	= time + 1;
	
	monster_hook_death(); // for post-death mods
}

void spawner_recount()
{
	self.spawner_monstercount = 0;
	self.think = spawner_think;
	self.nextthink = time;
}

void spawner_think() 
{
	float finished = FALSE, enemyDistance = 0;
	self.think = spawner_think;
	
	if(self.spawner_monstercount == autocvar_g_monster_spawner_maxmobs)
	{
		self.think = spawner_recount;
		self.nextthink = time + 20;
		return;
	}
	  
	// remove enemy that ran away
	if (self.enemy)
	if (self.delay <= time) // check if we can do the rescan now
	if (vlen(self.origin - self.enemy.origin) > autocvar_g_monster_spawner_target_range * self.scale)
		self.enemy = world;
	else
		self.delay = time + autocvar_g_monster_spawner_target_recheck_delay;
	
	if not(self.enemy) 
	{
		self.enemy = FindTarget(self);
		if (self.enemy)
			self.delay = time + autocvar_g_monster_spawner_target_recheck_delay;
	}

	if (self.enemy) 
	{
		// this spawner has an enemy
		traceline(self.origin, self.enemy.origin, FALSE, self);
		enemyDistance = vlen(trace_endpos - self.origin);
		
		if (trace_ent == self.enemy)
		if (self.enemy.deadflag == DEAD_NO)
		if (self.spawner_monstercount <= autocvar_g_monster_spawner_maxmobs)
		if (enemyDistance <= autocvar_g_monster_spawner_spawn_range * self.scale) 
		{
			spawnmonsters();
			finished = TRUE;
		}		
	}
	
	self.nextthink = time + 1;

	if(self.spawner_monstercount <= autocvar_g_monster_spawner_maxmobs)
		self.nextthink = time + 0.1;
	
	if not(finished) 
	{
		if (self.enemy)
			self.nextthink = time + 0.1;
	}  
}

void spawner_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_spawner_health * self.scale;
	
	self.classname	  		= "monster_spawner";
	self.nextthink	  		= time + 2.1;
	self.velocity	   		= '0 0 0';
	self.think		  		= spawner_think;
	self.touch				= func_null;	
	self.sprite_height  	= 80 * self.scale;
	
	self.spawner_monstercount = 0;
	
	droptofloor();
	self.movetype = MOVETYPE_NONE;
	
	monster_hook_spawn(); // for post-spawn mods
}

/*QUAKED monster_spawner (1 0 0) (-18 -18 -25) (18 18 47)
---------NOTES----------
Spawns monsters when a player is nearby
-------- MODEL FOR RADIANT ONLY - DO NOT SET THIS AS A KEY --------
modeldisabled="models/containers/crate01.md3"
*/
void spawnfunc_monster_spawner() 
{
	if not(autocvar_g_monster_spawner) 
	{
		remove(self);
		return;
	}
	
	self.monster_spawnfunc = spawnfunc_monster_spawner;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 0.8;
	
	if not (monster_initialize(
			 "Monster spawner",
			 "models/containers/crate01.md3",
			 SPAWNER_MIN, SPAWNER_MAX,
			 FALSE,
			 spawner_die, spawner_spawn))
	{
		remove(self);
		return;
	}

	precache_sound("weapons/rocket_impact.wav");
}
