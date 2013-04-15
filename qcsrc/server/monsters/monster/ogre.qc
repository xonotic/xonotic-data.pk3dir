#ifndef MENUQC
// size
const vector OGRE_MIN = '-36 -36 -20';
const vector OGRE_MAX = '36 36 50';

// model
string OGRE_MODEL = "models/monsters/ogre.dpm";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_ogre;
float autocvar_g_monster_ogre_health;
float autocvar_g_monster_ogre_chainsaw_damage;
float autocvar_g_monster_ogre_speed_walk;
float autocvar_g_monster_ogre_speed_run;
float autocvar_g_monster_ogre_attack_uzi_bullets;
float autocvar_g_monster_ogre_attack_uzi_damage;
float autocvar_g_monster_ogre_attack_uzi_force;
float autocvar_g_monster_ogre_attack_uzi_chance;
float autocvar_g_monster_ogre_attack_grenade_damage;
float autocvar_g_monster_ogre_attack_grenade_edgedamage;
float autocvar_g_monster_ogre_attack_grenade_force;
float autocvar_g_monster_ogre_attack_grenade_radius;

// animations
const float ogre_anim_idle 		= 0;
const float ogre_anim_walk 		= 1;
const float ogre_anim_run 		= 2;
const float ogre_anim_pain 		= 3;
const float ogre_anim_swing 	= 4;
const float ogre_anim_die 		= 5;

void chainsaw()
{
	if (!self.enemy)
		return;

	if (vlen(self.enemy.origin - self.origin) > 100 * self.scale)
		return;

	Damage(self.enemy, self, self, autocvar_g_monster_ogre_chainsaw_damage * monster_skill, DEATH_MONSTER_OGRE_CHAINSAW, self.enemy.origin, normalize(self.enemy.origin - self.origin));
}

void ogre_think()
{
	self.think = ogre_think;
	self.nextthink = time + self.ticrate;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	monster_move(autocvar_g_monster_ogre_speed_run, autocvar_g_monster_ogre_speed_walk, 300, ogre_anim_run, ogre_anim_walk, ogre_anim_idle);
}

.float ogre_cycles;
void ogre_swing()
{
	self.ogre_cycles += 1;
	monsters_setframe(ogre_anim_swing);
	if(self.ogre_cycles == 1)
		self.attack_finished_single = time + 1.3;
	self.angles_y = self.angles_y + random()* 25;
	self.nextthink = time + 0.2;
	self.think = ogre_swing;
	
	if(self.ogre_cycles <= 2)
		chainsaw();
	else if(self.ogre_cycles <= 4)
		chainsaw();
	else
		chainsaw();
	
	if(self.ogre_cycles >= 4)
		self.think = ogre_think;
}

void ogre_uzi_fire()
{
	self.ogre_cycles += 1;
	
	if(self.ogre_cycles > autocvar_g_monster_ogre_attack_uzi_bullets)
	{
		self.monster_delayedattack = func_null;
		self.delay = -1;
		return;
	}
	
	W_SetupShot (self, autocvar_g_antilag_bullets && 18000 >= autocvar_g_antilag_bullets, 0, "weapons/uzi_fire.wav", CH_WEAPON_A, autocvar_g_monster_ogre_attack_uzi_damage);
	fireBallisticBullet(w_shotorg, w_shotdir, 0.02, 18000, 5, autocvar_g_monster_ogre_attack_uzi_damage, autocvar_g_monster_ogre_attack_uzi_force, DEATH_MONSTER_OGRE_UZI, 0, 1, 115);
	endFireBallisticBullet();
	
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_uzi()
{
	monsters_setframe(ogre_anim_pain);
	self.attack_finished_single = time + 0.8;
	self.delay = time + 0.1;
	self.monster_delayedattack = ogre_uzi_fire;
}

void ogre_grenade_explode()
{
	pointparticles(particleeffectnum("grenade_explode"), self.origin, '0 0 0', 1);
	sound(self, CH_SHOTS, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.realowner, autocvar_g_monster_ogre_attack_grenade_damage, autocvar_g_monster_ogre_attack_grenade_edgedamage, autocvar_g_monster_ogre_attack_grenade_radius, world, autocvar_g_monster_ogre_attack_grenade_force, self.projectiledeathtype, other);

	remove (self);
}

void ogre_grenade_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
		
	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt
		
	self.health = self.health - damage;
	
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.use);
}

void ogre_grenade_touch()
{
	PROJECTILE_TOUCH;
	
	self.use ();
}

void ogre_grenade_think()
{
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		ogre_grenade_explode();
		return;
	}
}

void ogre_gl()
{
	entity gren;

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 4, "weapons/grenade_fire.wav", CH_WEAPON_A, autocvar_g_monster_ogre_attack_grenade_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = autocvar_g_monster_ogre_attack_grenade_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = DEATH_MONSTER_OGRE_GRENADE;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.cnt = time + 5;
	gren.nextthink = time;
	gren.think = ogre_grenade_think;
	gren.use = ogre_grenade_explode;
	gren.touch = ogre_grenade_touch;

	gren.takedamage = DAMAGE_YES;
	gren.health = autocvar_g_balance_grenadelauncher_primary_health;
	gren.damageforcescale = autocvar_g_balance_grenadelauncher_primary_damageforcescale;
	gren.event_damage = ogre_grenade_damage;
	gren.damagedbycontents = TRUE;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SETUPPROJECTILEVELOCITY_UP(gren, g_balance_grenadelauncher_primary);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
	
	
	monsters_setframe(ogre_anim_pain);
	self.attack_finished_single = time + 0.8;
}

float ogre_missile()
{
	self.ogre_cycles = 0;
	if (random() <= autocvar_g_monster_ogre_attack_uzi_chance)
	{
		ogre_uzi();
		return TRUE;
	}
	else
	{
		ogre_gl();
		return TRUE;
	}
}

void ogre_melee()
{
	self.ogre_cycles = 0;
	ogre_swing();
}

void ogre_die()
{
	Monster_CheckDropCvars ("ogre");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(ogre_anim_die);
		
	monster_hook_death(); // for post-death mods
}

void ogre_spawn()
{
	if not(self.health)
		self.health = autocvar_g_monster_ogre_health * self.scale;

	self.damageforcescale	= 0.003;
	self.classname			= "monster_ogre";
	self.checkattack		= GenericCheckAttack;
	self.attack_melee		= ogre_melee;
	self.attack_ranged		= ogre_missile;
	self.nextthink			= time + 0.1;
	self.think				= ogre_think;
	self.weapon				= WEP_GRENADE_LAUNCHER;
	
	monsters_setframe(ogre_anim_idle);
	
	monster_setupsounds("ogre");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_ogre()
{	
	if not(autocvar_g_monster_ogre) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_ogre;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Ogre", MONSTER_OGRE,
			 OGRE_MIN, OGRE_MAX,
			 FALSE,
			 ogre_die, ogre_spawn))
	{
		remove(self);
		return;
	}
	
	weapon_action(WEP_GRENADE_LAUNCHER, WR_PRECACHE);
}

#endif // SVQC
