#ifndef SPIDER_H
#define SPIDER_H

#ifndef MENUQC
MODEL(MON_SPIDER, M_Model("spider.dpm"));
#endif

CLASS(Spider, Monster)
    ATTRIB(Spider, spawnflags, int, MON_FLAG_MELEE | MON_FLAG_RANGED | MON_FLAG_RIDE);
    ATTRIB(Spider, mins, vector, '-18 -18 -25');
    ATTRIB(Spider, maxs, vector, '18 18 30');
#ifndef MENUQC
    ATTRIB(Spider, m_model, Model, MDL_MON_SPIDER);
#endif
    ATTRIB(Spider, netname, string, "spider");
    ATTRIB(Spider, monster_name, string, _("Spider"));
ENDCLASS(Spider)

REGISTER_MONSTER(SPIDER, NEW(Spider)) {
#ifndef MENUQC
    this.mr_precache(this);
#endif
}

#include "../../weapons/all.qh"

CLASS(SpiderAttack, PortoLaunch)
/* flags     */ ATTRIB(SpiderAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(SpiderAttack, impulse, int, 9);
/* refname   */ ATTRIB(SpiderAttack, netname, string, "spider");
/* wepname   */ ATTRIB(SpiderAttack, m_name, string, _("Spider attack"));
ENDCLASS(SpiderAttack)
REGISTER_WEAPON(SPIDER_ATTACK, NEW(SpiderAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

.float spider_slowness; // effect time of slowness inflicted by spiders

.float spider_web_delay;

float autocvar_g_monster_spider_attack_web_damagetime;
float autocvar_g_monster_spider_attack_web_speed;
float autocvar_g_monster_spider_attack_web_speed_up;
float autocvar_g_monster_spider_attack_web_delay;

float autocvar_g_monster_spider_attack_bite_damage;
float autocvar_g_monster_spider_attack_bite_delay;

void M_Spider_Attack_Web();

REGISTER_MUTATOR(spiderweb, true);

MUTATOR_HOOKFUNCTION(spiderweb, PlayerPhysics)
{
	if (time >= self.spider_slowness)
		return false;
	PHYS_MAXSPEED(self) *= 0.5; // half speed while slow from spider
	PHYS_MAXAIRSPEED(self) *= 0.5;
	PHYS_AIRSPEEDLIMIT_NONQW(self) *= 0.5;
	PHYS_AIRSTRAFEACCELERATE(self) *= 0.5;
	return false;
}

MUTATOR_HOOKFUNCTION(spiderweb, MonsterMove)
{
	if(time < self.spider_slowness)
	{
		monster_speed_run *= 0.5;
		monster_speed_walk *= 0.5;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(spiderweb, PlayerSpawn)
{
	self.spider_slowness = 0;
	return false;
}

MUTATOR_HOOKFUNCTION(spiderweb, MonsterSpawn)
{
	self.spider_slowness = 0;
	return false;
}

SOUND(SpiderAttack_FIRE, W_Sound("electro_fire"));
METHOD(SpiderAttack, wr_think, void(SpiderAttack thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if ((!isPlayer && time >= actor.spider_web_delay) || weapon_prepareattack(thiswep, actor, weaponentity, false, autocvar_g_monster_spider_attack_web_delay)) {
		if (!isPlayer) {
			actor.spider_web_delay = time + 3;
			setanim(actor, actor.anim_shoot, true, true, true);
			actor.attack_finished_single[0] = time + (autocvar_g_monster_spider_attack_web_delay);
			actor.anim_finished = time + 1;
		}
        if (isPlayer) actor.enemy = Monster_FindTarget(actor);
        W_SetupShot_Dir(actor, v_forward, false, 0, SND(SpiderAttack_FIRE), CH_WEAPON_B, 0);
    	if (!isPlayer) w_shotdir = normalize((actor.enemy.origin + '0 0 10') - actor.origin);
		M_Spider_Attack_Web();
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
        return;
    }
    if (fire & 2)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, true, 0.5)) {
    	if (isPlayer) {
    		actor.enemy = Monster_FindTarget(actor);
    		actor.attack_range = 60;
    	}
    	Monster_Attack_Melee(actor.enemy, (autocvar_g_monster_spider_attack_bite_damage), ((random() > 0.5) ? self.anim_melee : self.anim_shoot), self.attack_range, (autocvar_g_monster_spider_attack_bite_delay), DEATH_MONSTER_SPIDER.m_id, true);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}

float autocvar_g_monster_spider_health;
float autocvar_g_monster_spider_damageforcescale = 0.6;
float autocvar_g_monster_spider_speed_stop;
float autocvar_g_monster_spider_speed_run;
float autocvar_g_monster_spider_speed_walk;

/*
const float spider_anim_idle		= 0;
const float spider_anim_walk		= 1;
const float spider_anim_attack		= 2;
const float spider_anim_attack2		= 3;
*/

void M_Spider_Attack_Web_Explode()
{SELFPARAM();
	entity e;
	if(self)
	{
		Send_Effect(EFFECT_ELECTRO_IMPACT, self.origin, '0 0 0', 1);
		RadiusDamage(self, self.realowner, 0, 0, 25, world, world, 25, self.projectiledeathtype, world);

		for(e = findradius(self.origin, 25); e; e = e.chain) if(e != self) if(e.takedamage && e.deadflag == DEAD_NO) if(e.health > 0) if(e.monsterid != MON_SPIDER.monsterid)
			e.spider_slowness = time + (autocvar_g_monster_spider_attack_web_damagetime);

		remove(self);
	}
}

void M_Spider_Attack_Web_Touch()
{
	PROJECTILE_TOUCH;

	M_Spider_Attack_Web_Explode();
}

void adaptor_think2use_hittype_splash();

void M_Spider_Attack_Web()
{SELFPARAM();
	monster_makevectors(self.enemy);

	sound(self, CH_SHOTS, SND_ELECTRO_FIRE2, VOL_BASE, ATTEN_NORM);

	entity proj = new(plasma);
	proj.owner = proj.realowner = self;
	proj.use = M_Spider_Attack_Web_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = true;
	proj.bot_dodgerating = 0;
	proj.nextthink = time + 5;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = DEATH_MONSTER_SPIDER.m_id;
	setorigin(proj, CENTER_OR_VIEWOFS(self));

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SetupProjVelocity_Explicit(proj, v_forward, v_up, (autocvar_g_monster_spider_attack_web_speed), (autocvar_g_monster_spider_attack_web_speed_up), 0, 0, false);
	proj.touch = M_Spider_Attack_Web_Touch;
	setsize(proj, '-4 -4 -4', '4 4 4');
	proj.takedamage = DAMAGE_NO;
	proj.damageforcescale = 0;
	proj.health = 500;
	proj.event_damage = func_null;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = true;

	proj.bouncefactor = 0.3;
	proj.bouncestop = 0.05;
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO, true);
}

bool M_Spider_Attack(int attack_type, entity targ)
{SELFPARAM();
    .entity weaponentity = weaponentities[0];
	switch(attack_type)
	{
		Weapon wep = WEP_SPIDER_ATTACK;
		case MONSTER_ATTACK_MELEE:
		{
			wep.wr_think(wep, self, weaponentity, 2);
			return true;
		}
		case MONSTER_ATTACK_RANGED:
		{
			wep.wr_think(wep, self, weaponentity, 1);
			return true;
		}
	}

	return false;
}

spawnfunc(monster_spider) { Monster_Spawn(MON_SPIDER.monsterid); }
#endif // SVQC

		#ifdef SVQC
		METHOD(Spider, mr_think, bool(Spider thismon))
		{
			return true;
		}
		METHOD(Spider, mr_pain, bool(Spider thismon))
		{
			return true;
		}
		METHOD(Spider, mr_death, bool(Spider thismon))
		{
			SELFPARAM();
			setanim(self, self.anim_melee, false, true, true);
			self.angles_x = 180;
			return true;
		}
		#endif
		#ifndef MENUQC
		METHOD(Spider, mr_anim, bool(Spider thismon))
		{
			SELFPARAM();
			vector none = '0 0 0';
			self.anim_walk = animfixfps(self, '1 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_melee = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_shoot = animfixfps(self, '3 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '1 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		spawnfunc(item_health_medium);
		METHOD(Spider, mr_setup, bool(Spider thismon))
		{
			SELFPARAM();
			if(!self.health) self.health = (autocvar_g_monster_spider_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_spider_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_spider_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_spider_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_spider_damageforcescale); }

			self.monster_loot = spawnfunc_item_health_medium;
			self.monster_attackfunc = M_Spider_Attack;

			return true;
		}
		METHOD(Spider, mr_precache, bool(Spider thismon))
		{
			return true;
		}
		#endif

#endif
