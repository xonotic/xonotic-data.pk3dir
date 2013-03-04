/**
 * Special purpose fields:
 * .delay - time at which to check if zombie's enemy is still in range
 * .enemy - enemy of this zombie
 */
 
// cvars
float autocvar_g_monster_zombie;
float autocvar_g_monster_zombie_stopspeed;
float autocvar_g_monster_zombie_attack_leap_damage;
float autocvar_g_monster_zombie_attack_leap_delay;
float autocvar_g_monster_zombie_attack_leap_force;
float autocvar_g_monster_zombie_attack_leap_speed;
float autocvar_g_monster_zombie_attack_stand_damage;
float autocvar_g_monster_zombie_attack_stand_delay;
float autocvar_g_monster_zombie_health;
float autocvar_g_monster_zombie_speed_walk;
float autocvar_g_monster_zombie_speed_run;

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
		Damage(self.enemy, self, self, bigdmg * monster_skill, DEATH_MONSTER_ZOMBIE, self.origin, '0 0 0');
	}
	
	if(self.enemy.health < 1)
		self.enemy = world;
		
	if (rand < 0.33)
		self.frame = zombie_anim_attackstanding1;
	else if (rand < 0.66)
		self.frame = zombie_anim_attackstanding2;
	else
		self.frame = zombie_anim_attackstanding3;

	self.nextthink = time + autocvar_g_monster_zombie_attack_stand_delay;
	self.attack_finished_single = self.nextthink;
}

void zombie_attack_leap_touch()
{
	vector angles_face;
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
	Damage(other, self, self, bigdmg * monster_skill, DEATH_MONSTER_ZOMBIE, trace_endpos, angles_face);	
		
	self.touch = MonsterTouch;
}

float zombie_attack_ranged()
{
	makevectors(self.angles);
	if(monster_leap(zombie_anim_attackleap, zombie_attack_leap_touch, v_forward * autocvar_g_monster_zombie_attack_leap_speed + '0 0 200', autocvar_g_monster_zombie_attack_leap_delay))
		return TRUE;
		
	return FALSE;
}

void zombie_think()
{
	self.think = zombie_think;
	self.nextthink = time + 0.1;

	monster_move(autocvar_g_monster_zombie_speed_run, autocvar_g_monster_zombie_speed_walk, autocvar_g_monster_zombie_stopspeed, zombie_anim_runforward, zombie_anim_runforward, zombie_anim_idle);
}

void zombie_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_zombie_health * self.scale;
	
	self.classname			= "monster_zombie";
	self.nextthink	  		= time + 2.1;
	self.frame		  		= zombie_anim_spawn;
	self.think		  		= zombie_think;
	self.sprite_height  	= 50 * self.scale;
	self.checkattack		= GenericCheckAttack;
	self.attack_melee		= zombie_attack_standing;
	self.attack_ranged		= zombie_attack_ranged;
	self.skin 				= rint(random() * 4);
	
	// some sounds
	if(self.msound_idle == "") self.msound_idle = "monsters/zombie_idle.wav";
	if(self.msound_death == "") self.msound_death = "monsters/zombie_death.wav";
	if(self.msound_pain == "") self.msound_pain = "monsters/zombie_pain.wav";
	if(self.msound_attack_melee == "") self.msound_attack_melee = "monsters/zombie_melee.wav";
	if(self.msound_attack_ranged == "") self.msound_attack_ranged = "monsters/zombie_attack.wav";
	if(self.msound_sight == "") self.msound_sight = "monsters/zombie_sight.wav";
	
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
	if not(autocvar_g_monster_zombie) { remove(self); return; }
	
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
