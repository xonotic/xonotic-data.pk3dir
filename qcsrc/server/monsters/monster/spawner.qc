// size
const vector SPAWNER_MIN = '-35 -35 -10';
const vector SPAWNER_MAX = '35 35 70';

// cvars
float autocvar_g_monster_spawner;
float autocvar_g_monster_spawner_health;
float autocvar_g_monster_spawner_maxmobs;
string autocvar_g_monster_spawner_forcespawn;

void() spawner_think;

void spawnmonsters ()
{
	if(self.spawner_monstercount >= autocvar_g_monster_spawner_maxmobs || self.frozen)
		return;
		
	vector p1, p2, p3, p4, chosenposi;
	float r = random();
	string type = self.spawnmob;
	entity e;
	
	self.spawner_monstercount += 1;
		
	if(autocvar_g_monster_spawner_forcespawn)
		type = autocvar_g_monster_spawner_forcespawn;
		
	if(type == "" || type == "spawner") // spawner spawning spawners?!
		type = "knight";
	
	p1 = self.origin - '0 70 -50' * self.scale;
	p2 = self.origin + '0 70 50' * self.scale;
	p3 = self.origin - '70 0 -50' * self.scale;
	p4 = self.origin + '70 0 -50' * self.scale;
	   
	if (r < 0.20)
		chosenposi = p1;
	else if (r < 0.50)
		chosenposi = p2;
	else if (r < 80)
		chosenposi = p3;
	else
		chosenposi = p4;

	e = spawnmonster(type, self, self, chosenposi, FALSE, MONSTER_MOVE_WANDER);
	
	e.team = self.team;
	e.candrop = FALSE;
	
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

void spawner_think() 
{
	self.think = spawner_think;
	
	if(self.spawner_monstercount >= autocvar_g_monster_spawner_maxmobs)
		self.nextthink = time + 15;

	if (self.spawner_monstercount <= autocvar_g_monster_spawner_maxmobs)
		spawnmonsters();

	self.nextthink = time + 1;

	if(self.spawner_monstercount <= autocvar_g_monster_spawner_maxmobs)
		self.nextthink = time + 0.1;
}

void spawner_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_spawner_health * self.scale;
	
	self.classname	  		= "monster_spawner";
	self.nextthink	  		= time + 0.2;
	self.velocity	   		= '0 0 0';
	self.think		  		= spawner_think;
	self.touch				= func_null;	
	self.sprite_height  	= 80 * self.scale;
	
	self.spawner_monstercount = 0;
	
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
	if not(autocvar_g_monster_spawner) { remove(self); return; }
	
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
