#ifndef MENUQC
// size
const vector KNIGHT_MIN = '-16 -16 -24';
const vector KNIGHT_MAX = '16 16 32';

// model
string KNIGHT_MODEL = "models/monsters/knight.mdl";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_knight;
float autocvar_g_monster_knight_health;
//float autocvar_g_monster_knight_melee_damage;
float autocvar_g_monster_knight_speed_walk;
float autocvar_g_monster_knight_speed_run;

// animations
const float knight_anim_stand 		= 0;
const float knight_anim_run 		= 1;
const float knight_anim_runattack 	= 2;
const float knight_anim_pain1 		= 3;
const float knight_anim_pain2 		= 4;
const float knight_anim_attack 		= 5;
const float knight_anim_walk 		= 6;
const float knight_anim_kneel 		= 7;
const float knight_anim_standing 	= 8;
const float knight_anim_death1 		= 9;
const float knight_anim_death2 		= 10;

void knight_think ()
{
	self.think = knight_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_knight_speed_run, autocvar_g_monster_knight_speed_walk, 50, knight_anim_run, knight_anim_walk, knight_anim_stand);
}

void knight_attack ()
{
	float len = vlen(self.velocity);
	
	W_Shotgun_Attack2();

	monsters_setframe((len < 50) ? knight_anim_attack : knight_anim_runattack);
	
	self.attack_finished_single = time + 1.25;
	
	//monster_melee(self.enemy, autocvar_g_monster_knight_melee_damage, 0.3, DEATH_MONSTER_KNIGHT);
}

void knight_die ()
{
	Monster_CheckDropCvars ("knight");
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe((random() > 0.5) ? knight_anim_death1 : knight_anim_death2);
	
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
	self.view_ofs		   *= 0.5;
	
	monsters_setframe(knight_anim_stand);
	
	monster_setupsounds("knight");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_knight ()
{	
	if not(autocvar_g_monster_knight) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_knight;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Knight", MONSTER_KNIGHT,
			 KNIGHT_MIN, KNIGHT_MAX,
			 FALSE,
			 knight_die, knight_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
