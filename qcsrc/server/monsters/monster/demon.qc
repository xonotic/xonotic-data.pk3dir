#ifndef MENUQC
// size
const vector DEMON_MIN = '-32 -32 -24';
const vector DEMON_MAX = '32 32 24';

// model
string DEMON_MODEL = "models/monsters/demon.mdl";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_demon;
float autocvar_g_monster_demon_health;
float autocvar_g_monster_demon_attack_jump_damage;
float autocvar_g_monster_demon_damage;
float autocvar_g_monster_demon_speed_walk;
float autocvar_g_monster_demon_speed_run;

// animations
const float demon_anim_stand	= 0;
const float demon_anim_walk		= 1;
const float demon_anim_run		= 2;
const float demon_anim_leap		= 3;
const float demon_anim_pain		= 4;
const float demon_anim_death	= 5;
const float demon_anim_attack	= 6;

void demon_think ()
{
	self.think = demon_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_demon_speed_run, autocvar_g_monster_demon_speed_walk, 100, demon_anim_run, demon_anim_walk, demon_anim_stand);
}

void demon_attack_melee ()
{
	monsters_setframe(demon_anim_attack);
	self.attack_finished_single = time + 1;
	
	monster_melee(self.enemy, autocvar_g_monster_demon_damage, 0.3, DEATH_MONSTER_FIEND, TRUE);
}

void Demon_JumpTouch ()
{
	if (self.health <= 0)
		return;
		
	float bigdmg = autocvar_g_monster_demon_attack_jump_damage * self.scale;

	if (monster_isvalidtarget(other, self))
	{
		if (vlen(self.velocity) > 300)
		{
			Damage(other, self, self, bigdmg * monster_skill, DEATH_MONSTER_FIEND, other.origin, normalize(other.origin - self.origin));
			self.touch = MonsterTouch; // instantly turn it off to stop damage spam
		}
	}

	if(self.flags & FL_ONGROUND)
		self.touch = MonsterTouch;
}

float demon_jump ()
{
	makevectors(self.angles);
	if(monster_leap(demon_anim_leap, Demon_JumpTouch, v_forward * 700 + '0 0 300', 0.8))
		return TRUE;
		
	return FALSE;
}

void demon_die ()
{
	Monster_CheckDropCvars ("demon");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(demon_anim_death);
	
	monster_hook_death(); // for post-death mods
}

void demon_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_demon_health * self.scale;

	self.damageforcescale   = 0;
	self.classname			= "monster_demon";
	self.checkattack 		= GenericCheckAttack;
	self.attack_melee		= demon_attack_melee;
	self.attack_ranged		= demon_jump;
	self.nextthink		 	= time + random() * 0.5 + 0.1;
	self.think			  	= demon_think;
	
	monsters_setframe(demon_anim_stand);
	
	monster_setupsounds("demon");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_demon ()
{	
	if not(autocvar_g_monster_demon) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_demon;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Fiend", MONSTER_DEMON,
			 DEMON_MIN, DEMON_MAX,
			 FALSE,
			 demon_die, demon_spawn))
	{
		remove(self);
		return;
	}
}

// Compatibility with old spawns
void spawnfunc_monster_demon1 () { spawnfunc_monster_demon(); }

#endif // SVQC
