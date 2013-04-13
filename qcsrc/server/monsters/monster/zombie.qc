#ifndef MENUQC
// size
const vector ZOMBIE_MIN = '-18 -18 -25';
const vector ZOMBIE_MAX = '18 18 47';

// model
string ZOMBIE_MODEL = "models/monsters/zombie.dpm";

#endif

#ifdef SVQC
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

// animations
const float zombie_anim_attackleap			= 0;
const float zombie_anim_attackrun1			= 1;
const float zombie_anim_attackrun2			= 2;
const float zombie_anim_attackrun3			= 3;
const float zombie_anim_attackstanding1		= 4;
const float zombie_anim_attackstanding2		= 5;
const float zombie_anim_attackstanding3		= 6;
const float zombie_anim_blockend		   	= 7;
const float zombie_anim_blockstart			= 8;
const float zombie_anim_deathback1			= 9;
const float zombie_anim_deathback2			= 10;
const float zombie_anim_deathback3			= 11;
const float zombie_anim_deathfront1			= 12;
const float zombie_anim_deathfront2			= 13;
const float zombie_anim_deathfront3			= 14;
const float zombie_anim_deathleft1			= 15;
const float zombie_anim_deathleft2			= 16;
const float zombie_anim_deathright1			= 17;
const float zombie_anim_deathright2			= 18;
const float zombie_anim_idle			   	= 19;
const float zombie_anim_painback1		  	= 20;
const float zombie_anim_painback2		  	= 21;
const float zombie_anim_painfront1			= 22;
const float zombie_anim_painfront2			= 23;
const float zombie_anim_runbackwards	   	= 24;
const float zombie_anim_runbackwardsleft   	= 25;
const float zombie_anim_runbackwardsright  	= 26;
const float zombie_anim_runforward			= 27;
const float zombie_anim_runforwardleft	 	= 28;
const float zombie_anim_runforwardright		= 29;
const float zombie_anim_spawn			  	= 30;

void zombie_attack_standing()
{
	float rand = random(), chosen_anim;
		
	if (rand < 0.33)
		chosen_anim = zombie_anim_attackstanding1;
	else if (rand < 0.66)
		chosen_anim = zombie_anim_attackstanding2;
	else
		chosen_anim = zombie_anim_attackstanding3;
		
	monsters_setframe(chosen_anim);

	self.attack_finished_single = time + autocvar_g_monster_zombie_attack_stand_delay;
	
	monster_melee(self.enemy, autocvar_g_monster_zombie_attack_stand_damage, 0.3, DEATH_MONSTER_ZOMBIE_MELEE, TRUE);
}

void zombie_attack_leap_touch ()
{
	if (self.health <= 0)
		return;
		
	vector angles_face;
	float bigdmg = autocvar_g_monster_zombie_attack_leap_damage * self.scale;

	if (monster_isvalidtarget(other, self))
	{
		angles_face = vectoangles(self.moveto - self.origin);
		angles_face = normalize(angles_face) * autocvar_g_monster_zombie_attack_leap_force;
		Damage(other, self, self, bigdmg * monster_skill, DEATH_MONSTER_ZOMBIE_JUMP, other.origin, angles_face);
		self.touch = MonsterTouch; // instantly turn it off to stop damage spam
	}

	if(self.flags & FL_ONGROUND)
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
	self.nextthink = time + self.ticrate;

	monster_move(autocvar_g_monster_zombie_speed_run, autocvar_g_monster_zombie_speed_walk, autocvar_g_monster_zombie_stopspeed, zombie_anim_runforward, zombie_anim_runforward, zombie_anim_idle);
}

void zombie_die ()
{
	Monster_CheckDropCvars ("zombie");
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe((random() > 0.5) ? zombie_anim_deathback1 : zombie_anim_deathfront1);
		
	monster_hook_death(); // for post-death mods
}

void zombie_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_zombie_health * self.scale;
	
	self.classname			= "monster_zombie";
	self.nextthink	  		= time + 2.1;
	self.think		  		= zombie_think;
	self.sprite_height  	= 50;
	self.checkattack		= GenericCheckAttack;
	self.attack_melee		= zombie_attack_standing;
	self.attack_ranged		= zombie_attack_ranged;
	self.respawntime		= 0.1;
	self.respawnflags		= MONSTER_RESPAWN_DEATHPOINT;
	
	monsters_setframe(zombie_anim_spawn);
	
	if not(self.monster_respawned)
		self.skin = rint(random() * 4);
	
	monster_setupsounds("zombie");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_zombie() 
{
	if not(autocvar_g_monster_zombie) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_zombie;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Zombie", MONSTER_ZOMBIE,
			 ZOMBIE_MIN, ZOMBIE_MAX,
			 FALSE,
			 zombie_die, zombie_spawn))
	{
		remove(self);
		return;
	}
}

#endif //SVQC
