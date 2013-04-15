#ifndef MENUQC
// size
const vector FISH_MIN = '-16 -16 -24';
const vector FISH_MAX = '16 16 16';

// model
string FISH_MODEL = "models/monsters/fish.mdl";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_fish;
float autocvar_g_monster_fish_health;
float autocvar_g_monster_fish_damage;
float autocvar_g_monster_fish_speed_walk;
float autocvar_g_monster_fish_speed_run;

// animations
const float fish_anim_attack = 0;
const float fish_anim_death  = 1;
const float fish_anim_swim   = 2;
const float fish_anim_pain   = 3;

void fish_think ()
{
	self.think = fish_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_fish_speed_run, autocvar_g_monster_fish_speed_walk, 10, fish_anim_swim, fish_anim_swim, fish_anim_swim);
}

void fish_attack ()
{
	monsters_setframe(fish_anim_attack);
	self.attack_finished_single = time + 0.5;

	monster_melee(self.enemy, autocvar_g_monster_fish_damage, 0.1, DEATH_MONSTER_FISH, FALSE);
}

void fish_die ()
{
	Monster_CheckDropCvars ("fish");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(fish_anim_death);
	
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
	
	monster_setupsounds("fish");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_fish ()
{	
	if not(autocvar_g_monster_fish) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_fish;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Rotfish", MONSTER_FISH,
			 FISH_MIN, FISH_MAX,
			 TRUE,
			 fish_die, fish_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
