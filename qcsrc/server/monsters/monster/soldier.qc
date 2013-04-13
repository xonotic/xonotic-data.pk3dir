#ifndef MENUQC
// size
const vector SOLDIER_MIN = '-16 -16 -30';
const vector SOLDIER_MAX = '16 16 32';

// model
string SOLDIER_MODEL = "models/monsters/soldier.zym";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_soldier;
float autocvar_g_monster_soldier_health;
float autocvar_g_monster_soldier_melee_damage;
float autocvar_g_monster_soldier_speed_walk;
float autocvar_g_monster_soldier_speed_run;
float autocvar_g_monster_soldier_ammo;
float autocvar_g_monster_soldier_weapon_laser_chance;
float autocvar_g_monster_soldier_weapon_shotgun_chance;
float autocvar_g_monster_soldier_weapon_machinegun_chance;
float autocvar_g_monster_soldier_weapon_rocketlauncher_chance;
float autocvar_g_monster_soldier_attack_uzi_bullets;

// animations
const float soldier_anim_die1 			= 0;
const float soldier_anim_die2 			= 1;
const float soldier_anim_draw 			= 2;
const float soldier_anim_duck 			= 3;
const float soldier_anim_duckwalk 		= 4;
const float soldier_anim_duckjump 		= 5;
const float soldier_anim_duckidle 		= 6;
const float soldier_anim_idle 			= 7;
const float soldier_anim_jump 			= 8;
const float soldier_anim_pain1 			= 9;
const float soldier_anim_pain2 			= 10;
const float soldier_anim_shoot 			= 11;
const float soldier_anim_taunt 			= 12;
const float soldier_anim_run 			= 13;
const float soldier_anim_runbackwards 	= 14;
const float soldier_anim_strafeleft 	= 15;
const float soldier_anim_straferight 	= 16;
const float soldier_anim_dead1 			= 17;
const float soldier_anim_dead2 			= 18;
const float soldier_anim_forwardright 	= 19;
const float soldier_anim_forwardleft 	= 20;
const float soldier_anim_backright 		= 21;
const float soldier_anim_backleft 		= 22;

void soldier_think ()
{
	self.think = soldier_think;
	self.nextthink = time + self.ticrate;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	if(time < self.attack_finished_single)
		monster_move(0, 0, 0, soldier_anim_shoot, soldier_anim_shoot, soldier_anim_shoot);
	else
		monster_move(autocvar_g_monster_soldier_speed_run, autocvar_g_monster_soldier_speed_walk, 50, soldier_anim_run, soldier_anim_run, soldier_anim_idle);
}

void soldier_reload ()
{
	self.monster_delayedattack = func_null; // out of ammo, don't keep attacking
	self.delay = -1;
	monsters_setframe(soldier_anim_draw);
	self.attack_finished_single = time + 2;
	self.currentammo = autocvar_g_monster_soldier_ammo;
	sound (self, CH_SHOTS, "weapons/reload.wav", VOL_BASE, ATTN_LARGE);
}

.float grunt_cycles;
void soldier_uzi_fire ()
{
	self.currentammo -= 1;
	if(self.currentammo <= 0)
	{
		soldier_reload();
		return;
	}
		
	self.grunt_cycles += 1;
	
	if(self.grunt_cycles > autocvar_g_monster_soldier_attack_uzi_bullets)
	{
		self.monster_delayedattack = func_null;
		self.delay = -1;
		return;
	}
	W_UZI_Attack(DEATH_MONSTER_MARINE_UZI);
	self.delay = time + 0.1;
	self.monster_delayedattack = soldier_uzi_fire;
}

float soldier_attack()
{
	monsters_setframe(soldier_anim_shoot);
	makevectors(self.angles);
	
	if(self.currentammo <= 0)
	{
		soldier_reload();
		return FALSE;
	}
	
	self.grunt_cycles = 0;
	
	switch(self.weapon)
	{
		case WEP_ROCKET_LAUNCHER:
		{
			self.currentammo -= 1;
			self.attack_finished_single = time + 0.8;
			W_Rocket_Attack();
			return TRUE;
		}
		case WEP_SHOTGUN:
		{
			self.currentammo -= 1;
			self.attack_finished_single = time + 0.8;
			W_Shotgun_Attack();
			return TRUE;
		}
		case WEP_UZI:
		{
			self.attack_finished_single = time + 0.8;
			self.delay = time + 0.1;
			self.monster_delayedattack = soldier_uzi_fire;
			return TRUE;
		}
		case WEP_LASER:
		{
			self.attack_finished_single = time + 0.8;
			W_Laser_Attack(0);
			return TRUE;
		}
		default:
			return FALSE; // no weapon?
	}
}

void soldier_melee ()
{
	monsters_setframe(soldier_anim_shoot);
	self.attack_finished_single = time + 0.8;
	monster_melee(self.enemy, autocvar_g_monster_soldier_melee_damage, 0.3, DEATH_MONSTER_MARINE_SLAP, TRUE);
}

void soldier_die()
{
	Monster_CheckDropCvars ("soldier");
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe((random() > 0.5) ? soldier_anim_die1 : soldier_anim_die2);
		
	monster_hook_death(); // for post-death mods
}

void soldier_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_soldier_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_soldier";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_melee		= soldier_melee;
	self.attack_ranged		= soldier_attack;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= soldier_think;
	self.currentammo		= 3;
	self.sprite_height	  	= 45;
	self.items				= (IT_SHELLS | IT_ROCKETS | IT_NAILS);
	
	monsters_setframe(soldier_anim_draw);
	
	monster_setupsounds("soldier");
	
	setmodel(self, SOLDIER_MODEL);
	
	RandomSelection_Init();
	RandomSelection_Add(world, WEP_LASER, string_null, autocvar_g_monster_soldier_weapon_laser_chance, 1);
	RandomSelection_Add(world, WEP_SHOTGUN, string_null, autocvar_g_monster_soldier_weapon_shotgun_chance, 1);
	RandomSelection_Add(world, WEP_UZI, string_null, autocvar_g_monster_soldier_weapon_machinegun_chance, 1);
	RandomSelection_Add(world, WEP_ROCKET_LAUNCHER, string_null, autocvar_g_monster_soldier_weapon_rocketlauncher_chance, 1);
	
	self.weaponentity = spawn();
	self.weaponentity.movetype = MOVETYPE_NOCLIP;
	self.weaponentity.team = self.team;
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self.weaponentity.realowner = self;
	setmodel(self.weaponentity, "models/weapons/v_seeker.md3");
	setattachment(self.weaponentity, self, "bip01 r hand");
	
	self.armorvalue = bound(0.5, random(), 1);
	self.weapon = RandomSelection_chosen_float;

	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_soldier ()
{	
	if not(autocvar_g_monster_soldier) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_soldier;
	
	if(Monster_CheckAppearFlags(self))
		return;
		
	precache_model("models/weapons/v_seeker.md3");
	precache_model(SOLDIER_MODEL);
	
	if not (monster_initialize(
			 "Marine", MONSTER_MARINE,
			 SOLDIER_MIN, SOLDIER_MAX,
			 FALSE,
			 soldier_die, soldier_spawn))
	{
		remove(self);
		return;
	}
}

// compatibility with old spawns
void spawnfunc_monster_army () { spawnfunc_monster_soldier(); }

#endif // SVQC
