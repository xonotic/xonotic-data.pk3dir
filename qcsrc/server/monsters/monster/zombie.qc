/**
 * Special purpose fields:
 * .delay - time at which to check if zombie's enemy is still in range
 * .enemy - enemy of this zombie
 * .state - state of the zombie, see ZOMBIE_STATE_*
 */
 
// cvars
float autocvar_g_monster_zombie;
float autocvar_g_monster_zombie_stopspeed;
float autocvar_g_monster_zombie_attack_leap_damage;
float autocvar_g_monster_zombie_attack_leap_delay;
float autocvar_g_monster_zombie_attack_leap_force;
float autocvar_g_monster_zombie_attack_leap_range;
float autocvar_g_monster_zombie_attack_leap_speed;
float autocvar_g_monster_zombie_attack_stand_damage;
float autocvar_g_monster_zombie_attack_stand_delay;
float autocvar_g_monster_zombie_attack_stand_range;
float autocvar_g_monster_zombie_health;
float autocvar_g_monster_zombie_idle_timer;
float autocvar_g_monster_zombie_speed_walk;
float autocvar_g_monster_zombie_speed_run;
float autocvar_g_monster_zombie_target_recheck_delay;
float autocvar_g_monster_zombie_target_range;

// zombie animations
#define zombie_anim_attackleap		 	0
#define zombie_anim_attackrun1		 	1
#define zombie_anim_attackrun2		 	2
#define zombie_anim_attackrun3		 	3
#define zombie_anim_attackstanding1		4
#define zombie_anim_attackstanding2		5
#define zombie_anim_attackstanding3		6
#define zombie_anim_blockend		   	7
#define zombie_anim_blockstart		 	8
#define zombie_anim_deathback1		 	9
#define zombie_anim_deathback2		 	10
#define zombie_anim_deathback3		 	11
#define zombie_anim_deathfront1			12
#define zombie_anim_deathfront2			13
#define zombie_anim_deathfront3			14
#define zombie_anim_deathleft1		 	15
#define zombie_anim_deathleft2		 	16
#define zombie_anim_deathright1			17
#define zombie_anim_deathright2			18
#define zombie_anim_idle			   	19
#define zombie_anim_painback1		  	20
#define zombie_anim_painback2		  	21
#define zombie_anim_painfront1		 	22
#define zombie_anim_painfront2		 	23
#define zombie_anim_runbackwards	   	24
#define zombie_anim_runbackwardsleft   	25
#define zombie_anim_runbackwardsright  	26
#define zombie_anim_runforward		 	27
#define zombie_anim_runforwardleft	 	28
#define zombie_anim_runforwardright		29
#define zombie_anim_spawn			  	30

const vector ZOMBIE_MIN				 = '-18 -18 -25';
const vector ZOMBIE_MAX				 = '18 18 47';

#define ZOMBIE_STATE_SPAWNING		0
#define ZOMBIE_STATE_IDLE			1
#define ZOMBIE_STATE_ANGRY			2
#define ZOMBIE_STATE_ATTACK_LEAP	3

void zombie_spawn();
void spawnfunc_monster_zombie();
void zombie_think();

void zombie_die ()
{
	Monster_CheckDropCvars ("zombie");
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.movetype		= MOVETYPE_TOSS;
	self.think			= Monster_Fade;
	self.nextthink	  	= time + 2.1;
	self.pain_finished  = self.nextthink;
	
	if (random() > 0.5)
		self.frame = zombie_anim_deathback1;
	else
		self.frame = zombie_anim_deathfront1;
		
	monster_hook_death(); // for post-death mods
}

void zombie_attack_standing()
{
	float rand = random(), dot = 0, bigdmg = 0;

	self.velocity_x = 0;
	self.velocity_y = 0;
	
	if(self.monster_owner == self.enemy)
	{
		self.enemy = world;
		return;
	}
	
	bigdmg = autocvar_g_monster_zombie_attack_stand_damage * self.scale;

	//print("zombie attacks!\n");
	makevectors (self.angles);
	dot = normalize (self.enemy.origin - self.origin) * v_forward;
	if(dot > 0.3)
	{
		Damage(self.enemy, self, self, bigdmg * monster_skill, DEATH_MONSTER_MELEE, self.origin, '0 0 0');
	}
	
	if (!monster_isvalidtarget(self.enemy, self, FALSE))
		self.enemy = world;
		
	if (rand < 0.33)
		self.frame = zombie_anim_attackstanding1;
	else if (rand < 0.66)
		self.frame = zombie_anim_attackstanding2;
	else
		self.frame = zombie_anim_attackstanding3;

	self.nextthink = time + autocvar_g_monster_zombie_attack_stand_delay;
}

void zombie_attack_leap_touch()
{
	vector angles_face = '0 0 0';
	float bigdmg = autocvar_g_monster_zombie_attack_leap_damage * self.scale;
	
	if (other.deadflag != DEAD_NO)
		return;
		
	if (self.monster_owner == other)
		return;
	
	if (other.takedamage == DAMAGE_NO)
		return;
		
	//void Damage (entity targ, entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
	traceline(self.origin, other.origin, FALSE, self);

	angles_face = vectoangles(self.moveto - self.origin);
	angles_face = normalize(angles_face) * autocvar_g_monster_zombie_attack_leap_force;
	Damage(other, self, self, bigdmg * monster_skill, DEATH_MONSTER_MELEE, trace_endpos, angles_face);	

	// make this guy zombie's priority if it wasn't already
	if (other.deadflag == DEAD_NO)
	if (self.enemy != other)
		self.enemy = other;
		
	self.touch = MonsterTouch;
}

void zombie_attack_leap()
{
	vector angles_face = '0 0 0', vel = '0 0 0';

	// face the enemy	
	self.state = ZOMBIE_STATE_ATTACK_LEAP;
	self.frame = zombie_anim_attackleap;
	angles_face = vectoangles(self.enemy.origin - self.origin);
	self.angles_y = angles_face_y ;
	self.nextthink = time + autocvar_g_monster_zombie_attack_leap_delay;
	self.touch = zombie_attack_leap_touch;
	makevectors(self.angles);
	vel = normalize(v_forward);
	self.velocity = vel * autocvar_g_monster_zombie_attack_leap_speed;
}

void zombie_think()
{
	float finished = FALSE, enemyDistance = 0, mySpeed = 0;
	
	self.think = zombie_think;
	
	if (self.state == ZOMBIE_STATE_ATTACK_LEAP) {
		// reset to angry
		self.state = ZOMBIE_STATE_ANGRY;
		self.touch = func_null;
	}
	
	if (self.state == ZOMBIE_STATE_SPAWNING) {
		// become idle when zombie spawned
		self.frame = zombie_anim_idle;
		self.state = ZOMBIE_STATE_IDLE;
	}
	
	if(self.enemy && !monster_isvalidtarget(self.enemy, self, FALSE))
		self.enemy = world;
	
	if (self.enemy)
	if (self.enemy.team == self.team || self.monster_owner == self.enemy)
		self.enemy = world;
	
	if(teamplay && autocvar_g_monsters_teams && self.monster_owner.team != self.team)
		self.monster_owner = world;	
	
	// remove enemy that ran away
	if (self.enemy)
	if (self.delay <= time) // check if we can do the rescan now
	if (vlen(self.origin - self.enemy.origin) > autocvar_g_monster_zombie_target_range * self.scale) 
	{
		//print("removing enemy, he is too far: ", ftos(vlen(self.origin - self.enemy.origin)), "\n");
		//print("delay was ", ftos(self.delay), "\n");
		self.enemy = world;
	} 
	else
		self.delay = time + autocvar_g_monster_zombie_target_recheck_delay;
	
	// find an enemy if no enemy available
	if not(self.enemy) 
	{
		self.enemy = FindTarget(self);
		if (self.enemy)
			self.delay = time + autocvar_g_monster_zombie_target_recheck_delay;
	}

	if (self.enemy) 
	{
		// make sure zombie is angry
		self.state = ZOMBIE_STATE_ANGRY;
		

		// this zombie has an enemy, attack if close enough, go to it if not!
		traceline(self.origin, self.enemy.origin, FALSE, self);
		enemyDistance = vlen(trace_endpos - self.origin);
		mySpeed = vlen(self.velocity);
		
		//print("speed ", ftos(mySpeed), "\n");
		
		if (trace_ent == self.enemy)
		if (self.enemy.deadflag == DEAD_NO)
		if (mySpeed <= 30)
			if (enemyDistance <= autocvar_g_monster_zombie_attack_stand_range * self.scale) 
			{
				//RadiusDamage (entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float deathtype, entity directhitentity)
				zombie_attack_standing();
				finished = TRUE;
			} 
			else if (enemyDistance <= autocvar_g_monster_zombie_attack_leap_range * self.scale) 
			{
				// do attackleap (set yaw, velocity, and check do damage on the first player entity it touches)
				zombie_attack_leap();
				finished = TRUE;
			}
		
	}
	
	self.nextthink = time + 1;

	if not(finished) 
	{
		monster_move(autocvar_g_monster_zombie_speed_run, autocvar_g_monster_zombie_speed_walk, autocvar_g_monster_zombie_stopspeed, zombie_anim_runforward, zombie_anim_runforward, zombie_anim_idle);
		
		if (self.enemy || self.monster_owner)
		{
			self.nextthink = time + 0.1;
			return;
		}   
	}
	
	if not(self.enemy || self.monster_owner || self.goalentity) 
	{
		// stay idle
		//print("zombie is idling while waiting for some fresh meat...\n");
		self.frame = ((mySpeed <= 20) ? zombie_anim_idle : zombie_anim_runforward);
		self.nextthink = time + autocvar_g_monster_zombie_idle_timer * random();	
	}
}

void zombie_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_zombie_health * self.scale;
	
	self.classname			= "monster_zombie";
	self.nextthink	  		= time + 2.1;
	self.pain_finished  	= self.nextthink;
	self.state		  		= ZOMBIE_STATE_SPAWNING;
	self.frame		  		= zombie_anim_spawn;
	self.think		  		= zombie_think;
	self.sprite_height  	= 50 * self.scale;
	self.skin 				= rint(random() * 4);
	
	monster_hook_spawn(); // for post-spawn mods
}

/*QUAKED monster_zombie (1 0 0) (-18 -18 -25) (18 18 47)
Zombie, 60 health points.
-------- KEYS --------
-------- SPAWNFLAGS --------
MONSTERFLAG_APPEAR: monster will spawn when triggered.
---------NOTES----------
Original Quake 1 zombie entity used a smaller box ('-16 -16 -24', '16 16 32').
-------- MODEL FOR RADIANT ONLY - DO NOT SET THIS AS A KEY --------
modeldisabled="models/monsters/zombie.dpm"
*/
void spawnfunc_monster_zombie() 
{
	if not(autocvar_g_monster_zombie) 
	{
		remove(self);
		return;
	}
	
	self.monster_spawnfunc = spawnfunc_monster_zombie;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	if not (monster_initialize(
			 "Zombie",
			 "models/monsters/zombie.dpm",
			 ZOMBIE_MIN, ZOMBIE_MAX,
			 FALSE,
			 zombie_die, zombie_spawn))
	{
		remove(self);
		return;
	}
}
