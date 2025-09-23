#include "spider.qh"

#if defined(SVQC)
	#include <common/mutators/base.qh>
#endif

#ifdef SVQC
float autocvar_g_monster_spider_health;
string autocvar_g_monster_spider_loot = "health_medium";
float autocvar_g_monster_spider_damageforcescale = 0.6;
float autocvar_g_monster_spider_attack_bite_damage;
float autocvar_g_monster_spider_attack_bite_delay;
float autocvar_g_monster_spider_attack_web_damagetime;
float autocvar_g_monster_spider_attack_web_speed;
float autocvar_g_monster_spider_attack_web_speed_up;
float autocvar_g_monster_spider_attack_web_delay;
float autocvar_g_monster_spider_attack_web_range = 800;
float autocvar_g_monster_spider_speed_stop;
float autocvar_g_monster_spider_speed_run;
float autocvar_g_monster_spider_speed_walk;

.float spider_web_delay;

void M_Spider_Attack_Web(entity this);

REGISTER_MUTATOR(spiderweb, true);

MUTATOR_HOOKFUNCTION(spiderweb, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Webbed, player))
		STAT(MOVEVARS_HIGHSPEED, player) *= 0.5;
}

MUTATOR_HOOKFUNCTION(spiderweb, MonsterMove)
{
    entity mon = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Webbed, mon))
	{
		M_ARGV(1, float) *= 0.5; // run speed
		M_ARGV(2, float) *= 0.5; // walk speed
	}
}

SOUND(SpiderAttack_FIRE, W_Sound("electro_fire2"));
METHOD(SpiderAttack, wr_think, void(SpiderAttack thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(SpiderAttack, thiswep);
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if ((!isPlayer && time >= actor.spider_web_delay) || (isPlayer && weapon_prepareattack(thiswep, actor, weaponentity, false, autocvar_g_monster_spider_attack_web_delay))) {
		if (!isPlayer) {
			actor.spider_web_delay = time + autocvar_g_monster_spider_attack_web_delay;
			setanim(actor, actor.anim_shoot, true, true, true);
			if(actor.animstate_endtime > time)
				actor.anim_finished = actor.animstate_endtime;
			else
				actor.anim_finished = time + 1;
			actor.attack_finished_single[0] = actor.anim_finished + 0.2;
		}
        if (isPlayer) actor.enemy = Monster_FindTarget(actor);
        monster_makevectors(actor, actor.enemy);
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

void M_Spider_Attack_Web_Explode(entity this)
{
	if(this)
	{
		Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);
		RadiusDamage(this, this.realowner, 0, 0, 25, NULL, NULL, 25, this.projectiledeathtype, DMG_NOWEP, NULL);

		FOREACH_ENTITY_RADIUS(this.origin, 25, it != this && it.takedamage && !IS_DEAD(it) && GetResource(it, RES_HEALTH) > 0 && it.monsterdef != MON_SPIDER,
		{
			StatusEffects_apply(STATUSEFFECT_Webbed, it, time + autocvar_g_monster_spider_attack_web_damagetime, 0);
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

void M_Spider_Attack_Web(entity this)
{
	sound(this, CH_SHOTS, SND_SpiderAttack_FIRE, VOL_BASE, ATTEN_NORM);

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
	SetResourceExplicit(proj, RES_HEALTH, 500);
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
			if(vdist(actor.enemy.origin - actor.origin, <=, autocvar_g_monster_spider_attack_web_range))
			{
				wep.wr_think(wep, actor, weaponentity, 1);
				return true;
			}
		}
	}

	return false;
}

spawnfunc(monster_spider) { Monster_Spawn(this, true, MON_SPIDER); }
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
    setanim(actor, ((random() > 0.5) ? actor.anim_pain2 : actor.anim_pain1), true, true, false);
    actor.pain_finished = actor.animstate_endtime;
    return damage_take;
}

METHOD(Spider, mr_death, bool(Spider this, entity actor))
{
    TC(Spider, this);
    setanim(actor, ((random() > 0.5) ? actor.anim_die2 : actor.anim_die1), false, true, true);
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Spider, mr_anim, bool(Spider this, entity actor))
{
    TC(Spider, this);
    vector none = '0 0 0';
    actor.anim_melee = animfixfps(actor, '0 1 5', none); // analyze models and set framerate
    actor.anim_die1 = animfixfps(actor, '1 1 1', none);
    actor.anim_die2 = animfixfps(actor, '2 1 1', none);
    actor.anim_shoot = animfixfps(actor, '3 1 1', none);
    //actor.anim_fire2 = animfixfps(actor, '4 1 1', none);
    actor.anim_idle = animfixfps(actor, '5 1 1', none);
    //actor.anim_sight = animfixfps(actor, '6 1 1', none);
    actor.anim_pain1 = animfixfps(actor, '7 1 1', none);
    actor.anim_pain2 = animfixfps(actor, '8 1 1', none);
    //actor.anim_pain3 = animfixfps(actor, '9 1 1', none);
    actor.anim_walk = animfixfps(actor, '10 1 1', none);
    actor.anim_run = animfixfps(actor, '10 1 1', none); // temp?
    //actor.anim_forwardright = animfixfps(actor, '11 1 1', none);
    //actor.anim_walkright = animfixfps(actor, '12 1 1', none);
    //actor.anim_walkbackright = animfixfps(actor, '13 1 1', none);
    //actor.anim_walkback = animfixfps(actor, '14 1 1', none);
    //actor.anim_walkbackleft = animfixfps(actor, '15 1 1', none);
    //actor.anim_walkleft = animfixfps(actor, '16 1 1', none);
    //actor.anim_forwardleft = animfixfps(actor, '17 1 1', none);
    return true;
}
#endif
#ifdef SVQC
METHOD(Spider, mr_setup, bool(Spider this, entity actor))
{
    TC(Spider, this);
    if(!GetResource(this, RES_HEALTH)) SetResourceExplicit(actor, RES_HEALTH, autocvar_g_monster_spider_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_spider_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_spider_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_spider_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_spider_damageforcescale); }

    actor.monster_loot = autocvar_g_monster_spider_loot;
    actor.monster_attackfunc = M_Spider_Attack;

    return true;
}
#endif
#ifdef MENUQC
METHOD(Spider, describe, string(Spider this))
{
	TC(Spider, this);
	PAGE_TEXT_INIT();
	PAR(_("The Spider is a large mechanically-enhanced arachnoid adept at hunting speedy enemies."));
	PAR(_("To slow down its target, the Spider launches a synthetic web-like substance from its cannons. "
	      "Approaching its enwebbed prey, the Spider will inflict a series of high damage bites."));
	return PAGE_TEXT;
}
#endif
