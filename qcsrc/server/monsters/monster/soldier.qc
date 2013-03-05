// size
const vector SOLDIER_MIN = '-16 -16 -30';
const vector SOLDIER_MAX = '16 16 32';

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
#define soldier_anim_die1 			0
#define soldier_anim_die2 			1
#define soldier_anim_draw 			2
#define soldier_anim_duck 			3
#define soldier_anim_duckwalk 		4
#define soldier_anim_duckjump 		5
#define soldier_anim_duckidle 		6
#define soldier_anim_idle 			7
#define soldier_anim_jump 			8
#define soldier_anim_pain1 			9
#define soldier_anim_pain2 			10
#define soldier_anim_shoot 			11
#define soldier_anim_taunt 			12
#define soldier_anim_run 			13
#define soldier_anim_runbackwards 	14
#define soldier_anim_strafeleft 	15
#define soldier_anim_straferight 	16
#define soldier_anim_dead1 			17
#define soldier_anim_dead2 			18
#define soldier_anim_forwardright 	19
#define soldier_anim_forwardleft 	20
#define soldier_anim_backright 		21
#define soldier_anim_backleft 		22

//#define soldier_anim_stand 	0
//#define soldier_anim_death1 1
//#define soldier_anim_death2 2
//#define soldier_anim_reload 3
//#define soldier_anim_pain1 	4
//#define soldier_anim_pain2 	5
//#define soldier_anim_pain3 	6
//#define soldier_anim_run 	7
//#define soldier_anim_shoot 	8
//#define soldier_anim_prowl 	9

void soldier_think ()
{
	self.think = soldier_think;
	self.nextthink = time + 0.1;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	if(time < self.attack_finished_single)
		monster_move(0, 0, 0, soldier_anim_shoot, soldier_anim_shoot, soldier_anim_shoot);
	else
		monster_move(autocvar_g_monster_soldier_speed_run, autocvar_g_monster_soldier_speed_walk, 50, soldier_anim_run, soldier_anim_run, soldier_anim_idle);
}

void soldier_reload ()
{
	self.frame = soldier_anim_draw;
	self.attack_finished_single = time + 2;
	self.currentammo = autocvar_g_monster_soldier_ammo;
	sound (self, CH_SHOTS, "weapons/reload.wav", VOL_BASE, ATTN_LARGE);
}

float SoldierCheckAttack ()
{
	local vector spot1 = '0 0 0', spot2 = '0 0 0';
	local entity targ = self.enemy;
	local float chance = 0;

	if (self.health <= 0 || targ.health < 1 || targ == world)
		return FALSE;

	if (vlen(targ.origin - self.origin) > 2000) // long traces are slow
		return FALSE;

	// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != targ)
		return FALSE; // don't have a clear shot

	if (trace_inwater)
	if (trace_inopen)
		return FALSE; // sight line crossed contents
		
	if(self.monster_delayedattack && self.delay != -1)
	{
		if(time < self.delay)
			return FALSE;
			
		self.monster_delayedattack();
	}

	// missile attack
	if (time < self.attack_finished_single)
		return FALSE;

	if (enemy_range() >= 2000)
		return FALSE;

	if (enemy_range() <= 120)
		chance = 0.9;
	else if (enemy_range() <= 500)
		chance = 0.6; // was 0.4
	else if (enemy_range() <= 1000)
		chance = 0.3; // was 0.05
	else
		chance = 0;

	if (chance > 0)
	if (chance > random())
		return FALSE;
		
	if(self.currentammo <= 0 && enemy_range() <= 120)
	{
		monster_sound(self.msound_attack_melee, 0, FALSE); // no delay for attack sounds
		self.attack_melee();
		return TRUE;
	}
	
	if(self.currentammo <= 0)
	{
		soldier_reload();
		return FALSE;
	}

	if (self.attack_ranged())
		return TRUE;

	return FALSE;
}

void soldier_laser ()
{
	self.frame = soldier_anim_shoot;
	self.attack_finished_single = time + 0.8;
	W_Laser_Attack(0);
}

float soldier_missile_laser ()
{
	// FIXME: check if it would hit
	soldier_laser();
	return TRUE;
}

.float grunt_cycles;
void soldier_uzi_fire ()
{
	self.currentammo -= 1;
	if(self.currentammo <= 0)
		return;
		
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

void soldier_uzi ()
{
	if(self.currentammo <= 0)
		return;
		
	self.frame = soldier_anim_shoot;
	self.attack_finished_single = time + 0.8;
	self.delay = time + 0.1;
	self.monster_delayedattack = soldier_uzi_fire;
}

float soldier_missile_uzi ()
{
	self.grunt_cycles = 0;
	// FIXME: check if it would hit
	soldier_uzi();
	return TRUE;
}

void soldier_shotgun ()
{
	self.currentammo -= 1;
	if(self.currentammo <= 0)
		return;
		
	self.frame = soldier_anim_shoot;
	self.attack_finished_single = time + 0.8;
	W_Shotgun_Attack();
}

float soldier_missile_shotgun ()
{
	// FIXME: check if it would hit
	self.grunt_cycles = 0;
	soldier_shotgun();
	return TRUE;
}

void soldier_rl ()
{
	self.currentammo -= 1;
	if(self.currentammo <= 0)
		return;
		
	self.frame = soldier_anim_shoot;
	self.attack_finished_single = time + 0.8;
	W_Rocket_Attack();
}

float soldier_missile_rl ()
{
	// FIXME: check if it would hit
	soldier_rl();
	return TRUE;
}

void soldier_bash ()
{
	self.frame = soldier_anim_shoot;
	self.attack_finished_single = time + 0.8;
	monster_melee(self.enemy, autocvar_g_monster_soldier_melee_damage, 70, DEATH_MONSTER_MARINE_SLAP);
}

void soldier_die()
{
	Monster_CheckDropCvars ("soldier");
	
	remove(self.weaponentity);
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.movetype		= MOVETYPE_TOSS;
	self.think			= Monster_Fade;
	self.nextthink	  	= time + 2.1;
	self.weaponentity	= world;
	
	if (self.attack_ranged == soldier_missile_uzi)
		W_ThrowNewWeapon(self, WEP_UZI, 0, self.origin, self.velocity);	   
	else if (self.attack_ranged == soldier_missile_shotgun)
		W_ThrowNewWeapon(self, WEP_SHOTGUN, 0, self.origin, self.velocity);
	else if (self.attack_ranged == soldier_missile_rl)
		W_ThrowNewWeapon(self, WEP_ROCKET_LAUNCHER, 0, self.origin, self.velocity);
	else
		W_ThrowNewWeapon(self, WEP_LASER, 0, self.origin, self.velocity);

	if (random() < 0.5)
		self.frame = soldier_anim_die1;
	else
		self.frame = soldier_anim_die2;
		
	monster_hook_death(); // for post-death mods
}

void soldier_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_soldier_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_soldier";
	self.checkattack	 	= SoldierCheckAttack;
	self.attack_melee		= soldier_bash;
	self.frame				= soldier_anim_draw;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= soldier_think;
	self.sprite_height	  	= 45 * self.scale;
	self.items				= (IT_SHELLS | IT_ROCKETS | IT_NAILS);
	
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
	
	if (RandomSelection_chosen_float == WEP_ROCKET_LAUNCHER)
	{
		self.weapon = WEP_ROCKET_LAUNCHER;
		self.currentammo = self.ammo_rockets;
		self.armorvalue = 10;
		self.attack_ranged = soldier_missile_rl;
	}
	else if (RandomSelection_chosen_float == WEP_UZI)
	{
		self.weapon = WEP_UZI;
		self.currentammo = self.ammo_nails;
		self.armorvalue = 100;
		self.attack_ranged = soldier_missile_uzi;
	}
	else if (RandomSelection_chosen_float == WEP_SHOTGUN)
	{
		self.weapon = WEP_SHOTGUN;
		self.currentammo = self.ammo_shells;
		self.armorvalue = 25;
		self.attack_ranged = soldier_missile_shotgun;
	}
	else
	{
		self.weapon = WEP_LASER;
		self.armorvalue = 60;
		self.currentammo = self.ammo_none;
		self.attack_ranged = soldier_missile_laser;
	}

	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_soldier ()
{	
	if not(autocvar_g_monster_soldier) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_soldier;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	if not (monster_initialize(
			 "Grunt",
			 "models/monsters/soldier.zym",
			 SOLDIER_MIN, SOLDIER_MAX,
			 FALSE,
			 soldier_die, soldier_spawn))
	{
		remove(self);
		return;
	}
	
	precache_sound ("weapons/shotgun_fire.wav");
	precache_sound ("weapons/uzi_fire.wav");
	precache_sound ("weapons/laser_fire.wav");
	precache_sound ("weapons/reload.wav");
}

// compatibility with old spawns
void spawnfunc_monster_army () { spawnfunc_monster_soldier(); }
