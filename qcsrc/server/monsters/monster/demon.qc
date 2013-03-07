// cvars
float autocvar_g_monster_demon;
float autocvar_g_monster_demon_health;
float autocvar_g_monster_demon_attack_jump_damage;
float autocvar_g_monster_demon_damage;
float autocvar_g_monster_demon_speed_walk;
float autocvar_g_monster_demon_speed_run;

// size
const vector DEMON_MIN = '-32 -32 -24';
const vector DEMON_MAX = '32 32 24';

// animation
#define demon_anim_stand  0
#define demon_anim_walk   1
#define demon_anim_run	2
#define demon_anim_leap   3
#define demon_anim_pain   4
#define demon_anim_death  5
#define demon_anim_attack 6

void demon_think ()
{
	self.think = demon_think;
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_demon_speed_run, autocvar_g_monster_demon_speed_walk, 100, demon_anim_run, demon_anim_walk, demon_anim_stand);
}

void demon_attack_melee ()
{
	float bigdmg = autocvar_g_monster_demon_damage * self.scale;
	
	self.frame = demon_anim_attack;
	self.attack_finished_single = time + 1;
	
	monster_melee(self.enemy, bigdmg * monster_skill, 120, DEATH_MONSTER_FIEND);
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
	
	self.frame			= demon_anim_death;
	self.think		  	= Monster_Fade; 
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.movetype 		= MOVETYPE_TOSS;
	self.enemy		  	= world;
	self.nextthink	  	= time + 3;
	
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
	self.frame			  	= demon_anim_stand;
	self.think			  	= demon_think;
	self.sprite_height	  	= 30 * self.scale;
	
	monster_hook_spawn(); // for post-spawn mods
}

/* QUAKED monster_demon (1 0 0) (-32 -32 -24) (32 32 64) Ambush */
void spawnfunc_monster_demon ()
{	
	if not(autocvar_g_monster_demon) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_demon;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Fiend",
			 "models/monsters/demon.mdl",
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
