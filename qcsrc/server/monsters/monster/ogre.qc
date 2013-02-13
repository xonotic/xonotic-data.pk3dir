// size
const vector OGRE_MIN = '-32 -32 -24';
const vector OGRE_MAX = '32 32 32';
 
// cvars
float autocvar_g_monster_ogre;
float autocvar_g_monster_ogre_health;
float autocvar_g_monster_ogre_chainsaw_damage;
float autocvar_g_monster_ogre_speed_walk;
float autocvar_g_monster_ogre_speed_run;
float autocvar_g_monster_ogre_attack_uzi_bullets;

// animations
#define ogre_anim_stand 	0
#define ogre_anim_walk 		1
#define ogre_anim_run 		2
#define ogre_anim_swing 	3
#define ogre_anim_smash 	4
#define ogre_anim_shoot 	5
#define ogre_anim_pain1 	6
#define ogre_anim_pain2 	7
#define ogre_anim_pain3 	8
#define ogre_anim_pain4 	9
#define ogre_anim_pain5 	10
#define ogre_anim_death1 	11
#define ogre_anim_death2 	12
#define ogre_anim_pull 		13

void chainsaw (float side)
{
	if (!self.enemy)
		return;

	if (enemy_range() > 100 * self.scale)
		return;

	Damage(self.enemy, self, self, autocvar_g_monster_ogre_chainsaw_damage * monster_skill, DEATH_MONSTER_OGRE_CHAINSAW, self.enemy.origin, normalize(self.enemy.origin - self.origin));
}

void ogre_think ()
{
	self.think = ogre_think;
	self.nextthink = time + 0.1;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	monster_move(autocvar_g_monster_ogre_speed_run, autocvar_g_monster_ogre_speed_walk, 300, ogre_anim_run, ogre_anim_walk, ogre_anim_stand);
}

.float ogre_cycles;
void ogre_swing ()
{
	self.ogre_cycles += 1;
	self.frame = ogre_anim_swing;
	if(self.ogre_cycles == 1)
		self.attack_finished_single = time + 1.3;
	self.angles_y = self.angles_y + random()* 25;
	self.nextthink = time + 0.2;
	self.think = ogre_swing;
	
	if(self.ogre_cycles <= 2)
		chainsaw(200);
	else if(self.ogre_cycles <= 4)
		chainsaw(-200);
	else
		chainsaw(0);
	
	if(self.ogre_cycles >= 4)
		self.think = ogre_think;
}

void ogre_uzi_fire ()
{
	self.ogre_cycles += 1;
	
	if(self.ogre_cycles > autocvar_g_monster_ogre_attack_uzi_bullets)
	{
		self.monster_delayedattack = func_null;
		self.delay = -1;
		return;
	}
	W_UZI_Attack(DEATH_MONSTER_OGRE_NAIL);
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_uzi ()
{
	self.frame = ogre_anim_shoot;
	self.attack_finished_single = time + 0.8;
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_gl ()
{
	W_Grenade_Attack2();
	self.frame = ogre_anim_shoot;
	self.attack_finished_single = time + 0.8;
}

float ogre_missile ()
{
	self.ogre_cycles = 0;
	if (random() < 0.20)
	{
		ogre_uzi();
		return TRUE;
	}
	else
	{
		ogre_gl();
		return TRUE;
	}
}

void ogre_melee ()
{
	self.ogre_cycles = 0;
	ogre_swing();
}

void ogre_die()
{
	Monster_CheckDropCvars ("ogre");
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.nextthink	  	= time + 2.1;
	self.pain_finished  = self.nextthink;
	self.movetype		= MOVETYPE_TOSS;
	self.think 			= Monster_Fade;
	
	W_ThrowNewWeapon(self, WEP_GRENADE_LAUNCHER, 0, self.origin, self.velocity);
	if (random() < 0.5)
		self.frame = ogre_anim_death1;
	else
		self.frame = ogre_anim_death2;
		
	monster_hook_death(); // for post-death mods
}

void ogre_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_ogre_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_ogre";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_melee		= ogre_melee;
	self.frame				= ogre_anim_pull;
	self.attack_ranged	 	= ogre_missile;
	self.nextthink		  	= time + 1;
	self.think			  	= ogre_think;
	self.sprite_height	  	= 40 * self.scale;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_ogre ()
{	
	if not(autocvar_g_monster_ogre) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_ogre;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Ogre",
			 "models/monsters/ogre.mdl",
			 OGRE_MIN, OGRE_MAX,
			 FALSE,
			 ogre_die, ogre_spawn))
	{
		remove(self);
		return;
	}
	
	weapon_action(WEP_GRENADE_LAUNCHER, WR_PRECACHE);
}
