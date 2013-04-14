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
float autocvar_g_monster_soldier_attack_uzi_damage;
float autocvar_g_monster_soldier_attack_uzi_force;
float autocvar_g_monster_soldier_attack_shotgun_damage;
float autocvar_g_monster_soldier_attack_shotgun_force;
float autocvar_g_monster_soldier_attack_shotgun_spread;
float autocvar_g_monster_soldier_attack_shotgun_bullets;
float autocvar_g_monster_soldier_attack_rocket_damage;
float autocvar_g_monster_soldier_attack_rocket_edgedamage;
float autocvar_g_monster_soldier_attack_rocket_radius;
float autocvar_g_monster_soldier_attack_rocket_force;
float autocvar_g_monster_soldier_attack_rocket_lifetime;
float autocvar_g_monster_soldier_attack_rocket_speed;
float autocvar_g_monster_soldier_attack_laser_damage;
float autocvar_g_monster_soldier_attack_laser_edgedamage;
float autocvar_g_monster_soldier_attack_laser_radius;
float autocvar_g_monster_soldier_attack_laser_force;

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
	
	W_SetupShot (self, autocvar_g_antilag_bullets && 18000 >= autocvar_g_antilag_bullets, 0, "weapons/uzi_fire.wav", CH_WEAPON_A, autocvar_g_monster_soldier_attack_uzi_damage);
	fireBallisticBullet(w_shotorg, w_shotdir, 0.02, 18000, 5, autocvar_g_monster_soldier_attack_uzi_damage, autocvar_g_monster_soldier_attack_uzi_force, DEATH_MONSTER_MARINE, 0, 1, 115);
	endFireBallisticBullet();
	
	self.delay = time + 0.1;
	self.monster_delayedattack = soldier_uzi_fire;
}

void soldier_rocket_explode()
{
	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	
	pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
	sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);

	RadiusDamage (self, self.realowner, autocvar_g_monster_soldier_attack_rocket_damage, autocvar_g_monster_soldier_attack_rocket_edgedamage, autocvar_g_monster_soldier_attack_rocket_radius, world, autocvar_g_monster_soldier_attack_rocket_force, self.projectiledeathtype, other);

	remove (self);
}

void soldier_rocket_touch()
{
	PROJECTILE_TOUCH;
	
	soldier_rocket_explode();
}

void soldier_rocket_think()
{
	self.nextthink = time;
	if (time > self.cnt)
	{
		soldier_rocket_explode();
		return;
	}
}

void soldier_rocket_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
	
	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt
		
	self.health -= damage;
	self.angles = vectoangles(self.velocity);
	
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, soldier_rocket_explode);
}

void soldier_rocket_fire()
{
	entity missile;
	
	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 5, "weapons/rocket_fire.wav", CH_WEAPON_A, autocvar_g_monster_soldier_attack_rocket_damage);

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "rocket";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = autocvar_g_monster_soldier_attack_rocket_damage * 2; // * 2 because it can be detonated inflight which makes it even more dangerous

	missile.takedamage = DAMAGE_YES;
	missile.health = 50;
	missile.event_damage = soldier_rocket_damage;
	missile.damagedbycontents = TRUE;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = DEATH_MONSTER_MARINE;
	setsize (missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin (missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjectileVelocity(missile, autocvar_g_monster_soldier_attack_rocket_speed, 0);
	missile.angles = vectoangles (missile.velocity);

	missile.touch = soldier_rocket_touch;
	missile.think = soldier_rocket_think;
	missile.nextthink = time;
	missile.cnt = time + autocvar_g_monster_soldier_attack_rocket_lifetime;
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH; 

	CSQCProjectile(missile, TRUE, PROJECTILE_ROCKET, FALSE);
}

void soldier_shotgun_fire()
{
	float sc;
	W_SetupShot (self, autocvar_g_antilag_bullets && 18000 >= autocvar_g_antilag_bullets, 5, "weapons/shotgun_fire.wav", CH_WEAPON_A, autocvar_g_monster_soldier_attack_shotgun_damage * autocvar_g_monster_soldier_attack_shotgun_bullets);
	for (sc = 0;sc < autocvar_g_monster_soldier_attack_shotgun_bullets;sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, autocvar_g_monster_soldier_attack_shotgun_spread, 18000, 5, autocvar_g_monster_soldier_attack_shotgun_damage, autocvar_g_monster_soldier_attack_shotgun_force, DEATH_MONSTER_MARINE, 0, 1, 115);
	endFireBallisticBullet();
}

void soldier_laser_touch()
{
	PROJECTILE_TOUCH;

	self.event_damage = func_null;
	RadiusDamage (self, self.realowner, autocvar_g_monster_soldier_attack_laser_damage, autocvar_g_monster_soldier_attack_laser_edgedamage, autocvar_g_monster_soldier_attack_laser_radius, world, autocvar_g_monster_soldier_attack_laser_force, self.projectiledeathtype, other);

	remove (self);
}

void soldier_laser_fire()
{
	entity missile;
	
	W_SetupShot_Dir(self, v_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_monster_soldier_attack_laser_damage);
	
	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "laserbolt";
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = DEATH_MONSTER_MARINE;

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SETUPPROJECTILEVELOCITY(missile, g_monster_soldier_attack_laser);
	missile.angles = vectoangles(missile.velocity);
	missile.touch = soldier_laser_touch;

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;
	missile.movetype = MOVETYPE_FLY;
	
	missile.think = SUB_Remove;
	missile.nextthink = time + 5;
	
	CSQCProjectile(missile, TRUE, PROJECTILE_LASER, TRUE);
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
			soldier_rocket_fire();
			return TRUE;
		}
		case WEP_SHOTGUN:
		{
			self.currentammo -= 1;
			self.attack_finished_single = time + 0.8;
			soldier_shotgun_fire();
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
			soldier_laser_fire();
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
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
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
