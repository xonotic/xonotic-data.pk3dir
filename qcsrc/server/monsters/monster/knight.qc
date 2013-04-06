// size
const vector KNIGHT_MIN = '-16 -16 -24';
const vector KNIGHT_MAX = '16 16 32';
	
// cvars
float autocvar_g_monster_knight;
float autocvar_g_monster_knight_health;
float autocvar_g_monster_knight_melee_damage;
float autocvar_g_monster_knight_speed_walk;
float autocvar_g_monster_knight_speed_run;

// animations
#define knight_anim_stand 		0
#define knight_anim_run 		1
#define knight_anim_runattack 	2
#define knight_anim_pain1 		3
#define knight_anim_pain2 		4
#define knight_anim_attack 		5
#define knight_anim_walk 		6
#define knight_anim_kneel 		7
#define knight_anim_standing 	8
#define knight_anim_death1 		9
#define knight_anim_death2 		10

void knight_think ()
{
	self.think = knight_think;
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_knight_speed_run, autocvar_g_monster_knight_speed_walk, 50, knight_anim_run, knight_anim_walk, knight_anim_stand);
}

void knight_attack ()
{
	local float len = vlen(self.velocity);

	self.frame = ((len < 50) ? knight_anim_attack : knight_anim_runattack);
	
	self.attack_finished_single = time + 0.9;
	
	monster_melee(self.enemy, autocvar_g_monster_knight_melee_damage, 80, DEATH_MONSTER_KNIGHT);
}

void knight_die ()
{
	Monster_CheckDropCvars ("knight");
		
	self.frame 			= ((random() > 0.5) ? knight_anim_death1 : knight_anim_death2);
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.think			= Monster_Fade;
	self.movetype 		= MOVETYPE_TOSS;
	self.nextthink	  	= time + 2.1;
	
	monster_hook_death(); // for post-death mods
}

void knight_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_knight_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_knight";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_melee		= knight_attack;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= knight_think;
	self.sprite_height	  	= 30;
	self.frame 				= knight_anim_stand;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_knight ()
{	
	if not(autocvar_g_monster_knight) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_knight;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Knight",
			 "models/monsters/knight.mdl",
			 KNIGHT_MIN, KNIGHT_MAX,
			 FALSE,
			 knight_die, knight_spawn))
	{
		remove(self);
		return;
	}
}
