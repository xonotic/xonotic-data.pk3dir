// size
const vector DOG_MIN = '-16 -16 -24';
const vector DOG_MAX = '16 16 12';

// model
string DOG_MODEL = "models/monsters/dog.dpm";

#ifdef SVQC
// cvars
float autocvar_g_monster_dog;
float autocvar_g_monster_dog_health;
float autocvar_g_monster_dog_bite_damage;
float autocvar_g_monster_dog_attack_jump_damage;
float autocvar_g_monster_dog_speed_walk;
float autocvar_g_monster_dog_speed_run;

// animations
const float dog_anim_idle	= 0;
const float dog_anim_walk	= 1;
const float dog_anim_run	= 2;
const float dog_anim_attack	= 3;
const float dog_anim_die	= 4;
const float dog_anim_pain	= 5;

void Dog_JumpTouch ()
{
	if (self.health <= 0)
		return;

	if (other.takedamage)
	{
		if (vlen(self.velocity) > 300)
			Damage(self.enemy, self, self, autocvar_g_monster_dog_attack_jump_damage * monster_skill, DEATH_MONSTER_DOG_JUMP, self.enemy.origin, normalize(self.enemy.origin - self.origin));
	}

	if(self.flags & FL_ONGROUND)
		self.touch = MonsterTouch;
}

void dog_think ()
{
	self.think = dog_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_dog_speed_run, autocvar_g_monster_dog_speed_walk, 50, dog_anim_run, dog_anim_walk, dog_anim_idle);
}

float dog_attack ()
{
	monsters_setframe(dog_anim_attack);
	self.attack_finished_single = time + 0.7;

	monster_melee(self.enemy, autocvar_g_monster_dog_bite_damage, 0.2, DEATH_MONSTER_DOG_BITE, TRUE);
	
	return TRUE;
}

float dog_jump ()
{
	makevectors(self.angles);
	if(monster_leap(dog_anim_attack, Dog_JumpTouch, v_forward * 300 + '0 0 200', 0.8))
		return TRUE;
		
	return FALSE;
}

void dog_die ()
{
	Monster_CheckDropCvars ("dog");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(dog_anim_die);
	
	monster_hook_death(); // for post-death mods
}

void dog_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_dog_health;

	self.damageforcescale   = 0;
	self.classname			= "monster_dog";
	self.attack_melee	   	= dog_attack;
	self.attack_ranged	  	= dog_jump;
	self.checkattack	 	= GenericCheckAttack;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= dog_think;
	
	monsters_setframe(dog_anim_idle);
	
	monster_setupsounds("dog");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_dog ()
{	
	if not(autocvar_g_monster_dog) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_dog;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Cerberus", MONSTER_DOG,
			 DOG_MIN, DOG_MAX,
			 FALSE,
			 dog_die, dog_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
