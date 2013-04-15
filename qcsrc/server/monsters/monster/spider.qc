#ifndef MENUQC
// size
const vector SPIDER_MIN = '-18 -18 -25';
const vector SPIDER_MAX = '18 18 30';

// model
string SPIDER_MODEL = "models/monsters/spider.dpm";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_spider;
float autocvar_g_monster_spider_stopspeed;
float autocvar_g_monster_spider_attack_leap_delay;
float autocvar_g_monster_spider_attack_stand_damage;
float autocvar_g_monster_spider_attack_stand_delay;
float autocvar_g_monster_spider_attack_fire_time;
float autocvar_g_monster_spider_health;
float autocvar_g_monster_spider_speed_walk;
float autocvar_g_monster_spider_speed_run;
float autocvar_g_monster_spider_attack_type;

// animations
const float spider_anim_idle		= 0;
const float spider_anim_walk		= 1;
const float spider_anim_attack		= 2;
const float spider_anim_attack2		= 3;

.float spider_type; // used to switch between fire & ice attacks
const float SPIDER_TYPE_ICE		= 0;
const float SPIDER_TYPE_FIRE	= 1;

void spider_attack_standing()
{
	float dot = 0, bigdmg = autocvar_g_monster_spider_attack_stand_damage * self.scale;

	self.velocity_x = 0;
	self.velocity_y = 0;

	makevectors (self.angles);
	dot = normalize (self.enemy.origin - self.origin) * v_forward;
	if(dot > 0.3)
		Damage(self.enemy, self, self, bigdmg * monster_skill, DEATH_MONSTER_SPIDER, self.origin, '0 0 0');
	
	monsters_setframe((random() > 0.5) ? spider_anim_attack : spider_anim_attack2);

	self.attack_finished_single = time + autocvar_g_monster_spider_attack_stand_delay;
}

void spider_web_explode ()
{
	float damg = 0, edamg = 0, rad = 1;
	switch(self.realowner.spider_type)
	{
		case SPIDER_TYPE_ICE:
			break; // no change
		case SPIDER_TYPE_FIRE:
			damg = 15;
			rad = 25;
			edamg = 6;
			break;
	}
	
	RadiusDamage (self, self.realowner, damg, edamg, rad, world, 0, self.projectiledeathtype, other);
	
	remove (self);
}

void spider_web_touch ()
{
	PROJECTILE_TOUCH;
	
	if(other.takedamage == DAMAGE_AIM)
	switch(self.realowner.spider_type)
	{
		case SPIDER_TYPE_ICE:
			Freeze(other, 0.3);
			break;
		case SPIDER_TYPE_FIRE:
			Fire_AddDamage(other, self.realowner, 5 * monster_skill, autocvar_g_monster_spider_attack_fire_time, DEATH_MONSTER_SPIDER_FIRE);
			break;
	}
		
	spider_web_explode();
}

void spider_shootweb(float ptype)
{
	float p = 0, dt = 0;
	string snd = "";
	switch(ptype)
	{
		case SPIDER_TYPE_ICE:
			p = PROJECTILE_ELECTRO;
			dt = WEP_ELECTRO;
			snd = "weapons/electro_fire2.wav";
			break;
		case SPIDER_TYPE_FIRE:
			p = ((self.scale >= 2) ? PROJECTILE_FIREBALL : PROJECTILE_FIREMINE);
			dt = WEP_FIREBALL;
			snd = "weapons/fireball_fire.wav";
			break;
	}
	
	vector fmins = ((self.scale >= 2) ? '-16 -16 -16' : '-4 -4 -4'), fmaxs = ((self.scale >= 2) ? '16 16 16' : '4 4 4');	
	
	entity proj = world;
	
	makevectors(self.angles);

	W_SetupShot_ProjectileSize(self, fmins, fmaxs, FALSE, 2, snd, CH_WEAPON_A, 0);

	w_shotdir = v_forward; // no TrueAim for grenades please

	proj = spawn ();
	proj.classname = "plasma";
	proj.owner = proj.realowner = self;
	proj.use = spider_web_touch;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = 0;
	proj.nextthink = time + 5;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = dt | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SETUPPROJECTILEVELOCITY_UP(proj, g_monster_spider_attack_web);
	proj.touch = spider_web_touch;
	setsize(proj, fmins, fmaxs);
	proj.takedamage = DAMAGE_NO;
	proj.damageforcescale = 0;
	proj.health = 500;
	proj.event_damage = func_null;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = TRUE;

	proj.bouncefactor = 0.3;
	proj.bouncestop = 0.05;
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	CSQCProjectile(proj, TRUE, p, FALSE); // no culling, it has sound
}

void spider_attack_leap()
{
	vector angles_face = vectoangles(self.enemy.origin - self.origin);

	// face the enemy
	monsters_setframe(spider_anim_attack2);
	self.angles_y = angles_face_y ;
	self.attack_finished_single = time + autocvar_g_monster_spider_attack_leap_delay;
	
	makevectors(self.angles);
	
	spider_shootweb(self.spider_type);
}

float spider_attack_ranged()
{
	if(self.enemy.frozen || self.enemy.freezetag_frozen)
		return FALSE;
		
	spider_attack_leap();
	return TRUE;
}

void spider_think()
{
	self.think = spider_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_spider_speed_run, autocvar_g_monster_spider_speed_walk, autocvar_g_monster_spider_stopspeed, spider_anim_walk, spider_anim_walk, spider_anim_idle);
}

void spider_die ()
{
	Monster_CheckDropCvars ("spider");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(spider_anim_attack);
	self.angles += '180 0 0';
	
	monster_hook_death(); // for post-death mods
}

void spider_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_spider_health * self.scale;
	
	self.classname			= "monster_spider";
	self.nextthink	  		= time + random() * 0.5 + 0.1;
	self.checkattack		= GenericCheckAttack;
	self.attack_melee		= spider_attack_standing;
	self.attack_ranged		= spider_attack_ranged;
	self.think		  		= spider_think;
	
	monsters_setframe(spider_anim_idle);
	
	monster_setupsounds("spider");
	
	if not(self.spider_type)
		self.spider_type = autocvar_g_monster_spider_attack_type;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_spider() 
{
	if not(autocvar_g_monster_spider) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_spider;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Spider", MONSTER_SPIDER,
			 SPIDER_MIN, SPIDER_MAX,
			 FALSE,
			 spider_die, spider_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
