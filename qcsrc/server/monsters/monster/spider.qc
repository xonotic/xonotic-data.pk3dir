// cvars
float autocvar_g_monster_spider;
float autocvar_g_monster_spider_stopspeed;
float autocvar_g_monster_spider_attack_leap_delay;
float autocvar_g_monster_spider_attack_stand_damage;
float autocvar_g_monster_spider_attack_stand_delay;
float autocvar_g_monster_spider_health;
float autocvar_g_monster_spider_speed_walk;
float autocvar_g_monster_spider_speed_run;
float autocvar_g_monster_spider_attack_type;

// spider animations
#define spider_anim_idle		 	0
#define spider_anim_walk		 	1
#define spider_anim_attack		 	2
#define spider_anim_attack2			3

const vector SPIDER_MIN				 = '-18 -18 -25';
const vector SPIDER_MAX				 = '18 18 30';

.float spider_type; // used to switch between fire & ice attacks
const float SPIDER_TYPE_ICE		= 0;
const float SPIDER_TYPE_FIRE	= 1;

void spider_spawn();
void spawnfunc_monster_spider();
void spider_think();

void spider_die ()
{
	Monster_CheckDropCvars ("spider");
	
	self.angles += '180 0 0';
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.movetype		= MOVETYPE_TOSS;
	self.think			= Monster_Fade;
	self.nextthink	  	= time + 2.1;
	self.frame			= spider_anim_attack;
	
	monster_hook_death(); // for post-death mods
}

/**
 * Performe a standing attack on self.enemy.
 */
void spider_attack_standing()
{
	float dot = 0, bigdmg = autocvar_g_monster_spider_attack_stand_damage * self.scale;

	self.velocity_x = 0;
	self.velocity_y = 0;

	makevectors (self.angles);
	dot = normalize (self.enemy.origin - self.origin) * v_forward;
	if(dot > 0.3)
		Damage(self.enemy, self, self, bigdmg * monster_skill, DEATH_MONSTER_SPIDER, self.origin, '0 0 0');
		
	if(random() < 0.50)
		self.frame = spider_anim_attack;
	else
		self.frame = spider_anim_attack2;

	self.attack_finished_single = time + autocvar_g_monster_spider_attack_stand_delay;
}

void spider_web_explode ()
{
	RadiusDamage (self, self.realowner, 0, 0, 1, world, 0, self.projectiledeathtype, other);
	remove (self);
}

void spider_web_touch ()
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
		Freeze(other, 0.3);
		
	spider_web_explode();
}

void spider_shootweb()
{
	// clone of the electro secondary attack, with less bouncing
	entity proj = world;
	
	makevectors(self.angles);

	W_SetupShot_ProjectileSize (self, '0 0 -4', '0 0 -4', FALSE, 2, "weapons/electro_fire2.wav", CH_WEAPON_A, 0);

	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma";
	proj.owner = proj.realowner = self;
	proj.use = spider_web_touch;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = 0;
	proj.nextthink = time + autocvar_g_balance_electro_secondary_lifetime;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SETUPPROJECTILEVELOCITY_UP(proj, g_balance_electro_secondary);
	proj.touch = spider_web_touch;
	setsize(proj, '0 0 -4', '0 0 -4');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = 0;
	proj.health = 500;
	proj.event_damage = W_Plasma_Damage;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = TRUE;

	proj.bouncefactor = 0.3;
	proj.bouncestop = 0.05;
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO, FALSE); // no culling, it has sound

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void spider_attack_leap()
{
	vector angles_face = vectoangles(self.enemy.origin - self.origin);

	// face the enemy	
	self.frame = spider_anim_attack2;
	self.angles_y = angles_face_y ;
	self.nextthink = time + autocvar_g_monster_spider_attack_leap_delay;
	
	makevectors(self.angles);
	
	switch(self.spider_type)
	{
		default:
		case SPIDER_TYPE_ICE:
			spider_shootweb(); break; // must... remember... breaks!
		case SPIDER_TYPE_FIRE:
			W_Fireball_Attack2(); break;
	}
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
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_spider_speed_run, autocvar_g_monster_spider_speed_walk, autocvar_g_monster_spider_stopspeed, spider_anim_walk, spider_anim_walk, spider_anim_idle);
}

/**
 * Spawn the spider.
 */
void spider_spawn() 
{
	if not(self.health)
		self.health = autocvar_g_monster_spider_health * self.scale;
	
	self.classname			= "monster_spider";
	self.nextthink	  		= time + random() * 0.5 + 0.1;
	self.frame		  		= spider_anim_idle;
	self.checkattack		= GenericCheckAttack;
	self.attack_melee		= spider_attack_standing;
	self.attack_ranged		= spider_attack_ranged;
	self.think		  		= spider_think;
	self.sprite_height  	= 40 * self.scale;
	
	monster_hook_spawn(); // for post-spawn mods
}

/*QUAKED monster_spider (1 0 0) (-18 -18 -25) (18 18 47)
Spider, 60 health points.
-------- KEYS --------
-------- SPAWNFLAGS --------
MONSTERFLAG_APPEAR: monster will spawn when triggered.
---------NOTES----------
-------- MODEL FOR RADIANT ONLY - DO NOT SET THIS AS A KEY --------
modeldisabled="models/monsters/spider.dpm"
*/
void spawnfunc_monster_spider() 
{
	if not(autocvar_g_monster_spider) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_spider;
	self.classname = "monster_spider";
	if(!self.spider_type)
		self.spider_type = autocvar_g_monster_spider_attack_type;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	if not (monster_initialize(
			 "Spider",
			 "models/monsters/spider.dpm",
			 SPIDER_MIN, SPIDER_MAX,
			 FALSE,
			 spider_die, spider_spawn))
	{
		remove(self);
		return;
	}
}
