#ifndef MENUQC
// size
const vector OGRE_MIN = '-36 -36 -20';
const vector OGRE_MAX = '36 36 50';

// model
string OGRE_MODEL = "models/monsters/ogre.dpm";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_ogre;
float autocvar_g_monster_ogre_health;
float autocvar_g_monster_ogre_chainsaw_damage;
float autocvar_g_monster_ogre_speed_walk;
float autocvar_g_monster_ogre_speed_run;
float autocvar_g_monster_ogre_attack_uzi_bullets;

// animations
const float ogre_anim_idle 		= 0;
const float ogre_anim_walk 		= 1;
const float ogre_anim_run 		= 2;
const float ogre_anim_pain 		= 3;
const float ogre_anim_swing 	= 4;
const float ogre_anim_die 		= 5;

void chainsaw (float side)
{
	if (!self.enemy)
		return;

	if (vlen(self.enemy.origin - self.origin) > 100 * self.scale)
		return;

	Damage(self.enemy, self, self, autocvar_g_monster_ogre_chainsaw_damage * monster_skill, DEATH_MONSTER_OGRE_CHAINSAW, self.enemy.origin, normalize(self.enemy.origin - self.origin));
}

void ogre_think ()
{
	self.think = ogre_think;
	self.nextthink = time + self.ticrate;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	monster_move(autocvar_g_monster_ogre_speed_run, autocvar_g_monster_ogre_speed_walk, 300, ogre_anim_run, ogre_anim_walk, ogre_anim_idle);
}

.float ogre_cycles;
void ogre_swing ()
{
	self.ogre_cycles += 1;
	monsters_setframe(ogre_anim_swing);
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
	W_UZI_Attack(DEATH_MONSTER_OGRE_UZI);
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_uzi ()
{
	monsters_setframe(ogre_anim_pain);
	self.attack_finished_single = time + 0.8;
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_gl ()
{
	W_Grenade_Attack2();
	monsters_setframe(ogre_anim_pain);
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
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe(ogre_anim_die);
		
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
	self.attack_ranged	 	= ogre_missile;
	self.nextthink		  	= time + 0.1;
	self.think			  	= ogre_think;
	self.sprite_height	  	= 65;
	self.weapon				= WEP_GRENADE_LAUNCHER;
	
	monsters_setframe(ogre_anim_idle);
	
	monster_setupsounds("ogre");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_ogre ()
{	
	if not(autocvar_g_monster_ogre) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_ogre;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Ogre", MONSTER_OGRE,
			 OGRE_MIN, OGRE_MAX,
			 FALSE,
			 ogre_die, ogre_spawn))
	{
		remove(self);
		return;
	}
	
	weapon_action(WEP_GRENADE_LAUNCHER, WR_PRECACHE);
}

#endif // SVQC
