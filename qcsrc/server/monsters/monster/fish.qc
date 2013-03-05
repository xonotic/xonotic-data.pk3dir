// size
const vector FISH_MIN = '-16 -16 -24';
const vector FISH_MAX = '16 16 16';

// cvars
float autocvar_g_monster_fish;
float autocvar_g_monster_fish_health;
float autocvar_g_monster_fish_damage;
float autocvar_g_monster_fish_speed_walk;
float autocvar_g_monster_fish_speed_run;

// animations
#define fish_anim_attack 0
#define fish_anim_death  1
#define fish_anim_swim   2
#define fish_anim_pain   3

void fish_think ()
{
	self.think = fish_think;
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_fish_speed_run, autocvar_g_monster_fish_speed_walk, 10, fish_anim_swim, fish_anim_swim, fish_anim_swim);
}

void fish_attack ()
{
	float bigdmg = autocvar_g_monster_fish_damage * self.scale;
	
	self.frame = fish_anim_attack;
	self.attack_finished_single = time + 0.5;

	monster_melee(self.enemy, bigdmg * monster_skill, 60, DEATH_MONSTER_FISH);
}

void fish_die ()
{
	Monster_CheckDropCvars ("fish");
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.frame 			= fish_anim_death;
	self.think 			= Monster_Fade;
	self.nextthink 		= time + 2.1;
	
	monster_hook_death(); // for post-death mods
}

void fish_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_fish_health * self.scale;

	self.damageforcescale   = 0.5;
	self.classname			= "monster_fish";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_melee	  	= fish_attack;
	self.flags			   |= FL_SWIM;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= fish_think;
	self.sprite_height	  	= 20 * self.scale;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_fish ()
{	
	if not(autocvar_g_monster_fish) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_fish;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Rotfish",
			 "models/monsters/fish.mdl",
			 FISH_MIN, FISH_MAX,
			 TRUE,
			 fish_die, fish_spawn))
	{
		remove(self);
		return;
	}
}
