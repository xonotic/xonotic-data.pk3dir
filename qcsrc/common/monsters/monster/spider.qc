#include "spider.qh"

#ifdef SVQC

.float spider_slowness; // effect time of slowness inflicted by spiders

.float spider_web_delay;

float autocvar_g_monster_spider_attack_web_damagetime;
float autocvar_g_monster_spider_attack_web_speed;
float autocvar_g_monster_spider_attack_web_speed_up;
float autocvar_g_monster_spider_attack_web_delay;

float autocvar_g_monster_spider_attack_bite_damage;
float autocvar_g_monster_spider_attack_bite_delay;

void M_Spider_Attack_Web(entity this);

REGISTER_MUTATOR(spiderweb, true);

MUTATOR_HOOKFUNCTION(spiderweb, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);

	if(time < player.spider_slowness)
		STAT(MOVEVARS_HIGHSPEED, player) *= 0.5;
}

MUTATOR_HOOKFUNCTION(spiderweb, MonsterMove)
{
    entity mon = M_ARGV(0, entity);

	if(time < mon.spider_slowness)
	{
		M_ARGV(1, float) *= 0.5; // run speed
		M_ARGV(2, float) *= 0.5; // walk speed
	}
}

MUTATOR_HOOKFUNCTION(spiderweb, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.spider_slowness = 0;
	return false;
}

MUTATOR_HOOKFUNCTION(spiderweb, MonsterSpawn)
{
    entity mon = M_ARGV(0, entity);

	mon.spider_slowness = 0;
}

SOUND(SpiderAttack_FIRE, W_Sound("electro_fire"));
METHOD(SpiderAttack, wr_think, void(SpiderAttack thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(SpiderAttack, thiswep);
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
        W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_SpiderAttack_FIRE, CH_WEAPON_B, 0, DEATH_MONSTER_SPIDER.m_id);
    	if (!isPlayer) w_shotdir = normalize((actor.enemy.origin + '0 0 10') - actor.origin);
		M_Spider_Attack_Web(actor);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
        return;
    }
    if (fire & 2)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, true, 0.5)) {
    	if (isPlayer) {
    		actor.enemy = Monster_FindTarget(actor);
    		actor.attack_range = 60;
    	}
    	Monster_Attack_Melee(actor, actor.enemy, (autocvar_g_monster_spider_attack_bite_damage), ((random() > 0.5) ? actor.anim_melee : actor.anim_shoot), actor.attack_range, (autocvar_g_monster_spider_attack_bite_delay), DEATH_MONSTER_SPIDER.m_id, true);
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

void M_Spider_Attack_Web_Explode(entity this)
{
	if(this)
	{
		Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);
		RadiusDamage(this, this.realowner, 0, 0, 25, NULL, NULL, 25, this.projectiledeathtype, DMG_NOWEP, NULL);

		FOREACH_ENTITY_RADIUS(this.origin, 25, it != this && it.takedamage && !IS_DEAD(it) && GetResource(it, RES_HEALTH) > 0 && it.monsterid != MON_SPIDER.monsterid,
		{
			it.spider_slowness = time + (autocvar_g_monster_spider_attack_web_damagetime);
		});

		delete(this);
	}
}

void M_Spider_Attack_Web_Explode_use(entity this, entity actor, entity trigger)
{
	M_Spider_Attack_Web_Explode(this);
}

void M_Spider_Attack_Web_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	M_Spider_Attack_Web_Explode(this);
}

void adaptor_think2use_hittype_splash(entity this);

void M_Spider_Attack_Web(entity this)
{
	monster_makevectors(this, this.enemy);

	sound(this, CH_SHOTS, SND_ELECTRO_FIRE2, VOL_BASE, ATTEN_NORM);

	entity proj = new(plasma);
	proj.owner = proj.realowner = this;
	proj.use = M_Spider_Attack_Web_Explode_use;
	setthink(proj, adaptor_think2use_hittype_splash);
	proj.bot_dodge = true;
	proj.bot_dodgerating = 0;
	proj.nextthink = time + 5;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = DEATH_MONSTER_SPIDER.m_id;
	setorigin(proj, CENTER_OR_VIEWOFS(this));

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	set_movetype(proj, MOVETYPE_BOUNCE);
	W_SetupProjVelocity_Explicit(proj, v_forward, v_up, (autocvar_g_monster_spider_attack_web_speed), (autocvar_g_monster_spider_attack_web_speed_up), 0, 0, false);
	settouch(proj, M_Spider_Attack_Web_Touch);
	setsize(proj, '-4 -4 -4', '4 4 4');
	proj.takedamage = DAMAGE_NO;
	proj.damageforcescale = 0;
	SetResource(proj, RES_HEALTH, 500);
	proj.event_damage = func_null;
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, proj);

	proj.bouncefactor = 0.3;
	proj.bouncestop = 0.05;
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO, true);
}

bool M_Spider_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	Weapon wep = WEP_SPIDER_ATTACK;
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			wep.wr_think(wep, actor, weaponentity, 2);
			return true;
		}
		case MONSTER_ATTACK_RANGED:
		{
			wep.wr_think(wep, actor, weaponentity, 1);
			return true;
		}
	}

	return false;
}

spawnfunc(monster_spider) { Monster_Spawn(this, true, MON_SPIDER.monsterid); }
#endif // SVQC

#ifdef SVQC
METHOD(Spider, mr_think, bool(Spider this, entity actor))
{
    TC(Spider, this);
    return true;
}

METHOD(Spider, mr_pain, float(Spider this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Spider, this);
    return damage_take;
}

METHOD(Spider, mr_death, bool(Spider this, entity actor))
{
    TC(Spider, this);
    setanim(actor, actor.anim_melee, false, true, true);
    actor.angles_x = 180;
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Spider, mr_anim, bool(Spider this, entity actor))
{
    TC(Spider, this);
    vector none = '0 0 0';
    actor.anim_walk = animfixfps(actor, '1 1 1', none);
    actor.anim_idle = animfixfps(actor, '0 1 1', none);
    actor.anim_melee = animfixfps(actor, '2 1 5', none); // analyze models and set framerate
    actor.anim_shoot = animfixfps(actor, '3 1 5', none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, '1 1 1', none);
    return true;
}
#endif
#ifdef SVQC
METHOD(Spider, mr_setup, bool(Spider this, entity actor))
{
    TC(Spider, this);
    if(!GetResource(this, RES_HEALTH)) SetResource(actor, RES_HEALTH, autocvar_g_monster_spider_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_spider_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_spider_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_spider_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_spider_damageforcescale); }

    actor.monster_loot = ITEM_HealthMedium;
    actor.monster_attackfunc = M_Spider_Attack;

    return true;
}
#endif
