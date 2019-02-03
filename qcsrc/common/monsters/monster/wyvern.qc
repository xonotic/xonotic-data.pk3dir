#include "wyvern.qh"

#ifdef SVQC

float autocvar_g_monster_wyvern_attack_fireball_damage;
float autocvar_g_monster_wyvern_attack_fireball_edgedamage;
float autocvar_g_monster_wyvern_attack_fireball_damagetime;
float autocvar_g_monster_wyvern_attack_fireball_force;
float autocvar_g_monster_wyvern_attack_fireball_radius;
float autocvar_g_monster_wyvern_attack_fireball_speed;

void M_Wyvern_Attack_Fireball_Explode(entity this);
void M_Wyvern_Attack_Fireball_Touch(entity this, entity toucher);

SOUND(WyvernAttack_FIRE, W_Sound("electro_fire"));
METHOD(WyvernAttack, wr_think, void(WyvernAttack thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(WyvernAttack, thiswep);
    if (fire & 1)
    if (time > actor.attack_finished_single[0] || weapon_prepareattack(thiswep, actor, weaponentity, false, 1.2)) {
        if (IS_PLAYER(actor)) W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_WyvernAttack_FIRE, CH_WEAPON_B, 0, DEATH_MONSTER_WYVERN.m_id);
		if (IS_MONSTER(actor)) {
			actor.attack_finished_single[0] = time + 1.2;
			actor.anim_finished = time + 1.2;
			monster_makevectors(actor, actor.enemy);
		}

		entity missile = spawn();
		missile.owner = missile.realowner = actor;
		missile.solid = SOLID_TRIGGER;
		set_movetype(missile, MOVETYPE_FLYMISSILE);
		missile.projectiledeathtype = DEATH_MONSTER_WYVERN.m_id;
		setsize(missile, '-6 -6 -6', '6 6 6');
		setorigin(missile, actor.origin + actor.view_ofs + v_forward * 14);
		missile.flags = FL_PROJECTILE;
        IL_PUSH(g_projectiles, missile);
        IL_PUSH(g_bot_dodge, missile);
		missile.velocity = w_shotdir * (autocvar_g_monster_wyvern_attack_fireball_speed);
		missile.avelocity = '300 300 300';
		missile.nextthink = time + 5;
		setthink(missile, M_Wyvern_Attack_Fireball_Explode);
		settouch(missile, M_Wyvern_Attack_Fireball_Touch);
		CSQCProjectile(missile, true, PROJECTILE_FIREMINE, true);

        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
    }
}

METHOD(WyvernAttack, wr_checkammo1, bool(WyvernAttack this, entity actor, .entity weaponentity)) {
    TC(WyvernAttack, this);
	return true;
}

float autocvar_g_monster_wyvern_health;
float autocvar_g_monster_wyvern_damageforcescale = 0.6;
float autocvar_g_monster_wyvern_speed_stop;
float autocvar_g_monster_wyvern_speed_run;
float autocvar_g_monster_wyvern_speed_walk;

/*
const float wyvern_anim_hover	= 0;
const float wyvern_anim_fly		= 1;
const float wyvern_anim_magic	= 2;
const float wyvern_anim_pain	= 3;
const float wyvern_anim_death	= 4;
*/

void M_Wyvern_Attack_Fireball_Explode(entity this)
{
	Send_Effect(EFFECT_FIREBALL_EXPLODE, this.origin, '0 0 0', 1);

	entity own = this.realowner;

	RadiusDamage(this, own, autocvar_g_monster_wyvern_attack_fireball_damage, autocvar_g_monster_wyvern_attack_fireball_edgedamage, autocvar_g_monster_wyvern_attack_fireball_force,
						NULL, NULL, autocvar_g_monster_wyvern_attack_fireball_radius, this.projectiledeathtype, DMG_NOWEP, NULL);

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_monster_wyvern_attack_fireball_radius, it.takedamage == DAMAGE_AIM,
	{
		Fire_AddDamage(it, own, 5 * MONSTER_SKILLMOD(own), autocvar_g_monster_wyvern_attack_fireball_damagetime, this.projectiledeathtype);
	});

	delete(this);
}

void M_Wyvern_Attack_Fireball_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	M_Wyvern_Attack_Fireball_Explode(this);
}

bool M_Wyvern_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			w_shotdir = normalize((actor.enemy.origin + '0 0 10') - actor.origin);
			Weapon wep = WEP_WYVERN_ATTACK;
			wep.wr_think(wep, actor, weaponentity, 1);
			return true;
		}
	}

	return false;
}

spawnfunc(monster_wyvern) { Monster_Spawn(this, true, MON_WYVERN.monsterid); }
#endif // SVQC

#ifdef SVQC
METHOD(Wyvern, mr_think, bool(Wyvern this, entity actor))
{
    TC(Wyvern, this);
    return true;
}

METHOD(Wyvern, mr_pain, float(Wyvern this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Wyvern, this);
    actor.pain_finished = time + 0.5;
    setanim(actor, actor.anim_pain1, true, true, false);
    return damage_take;
}

METHOD(Wyvern, mr_death, bool(Wyvern this, entity actor))
{
    TC(Wyvern, this);
    setanim(actor, actor.anim_die1, false, true, true);
    actor.velocity_x = -200 + 400 * random();
    actor.velocity_y = -200 + 400 * random();
    actor.velocity_z = 100 + 100 * random();
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Wyvern, mr_anim, bool(Wyvern this, entity actor))
{
    TC(Wyvern, this);
    vector none = '0 0 0';
    actor.anim_die1 = animfixfps(actor, '4 1 0.5', none); // 2 seconds
    actor.anim_walk = animfixfps(actor, '1 1 1', none);
    actor.anim_idle = animfixfps(actor, '0 1 1', none);
    actor.anim_pain1 = animfixfps(actor, '3 1 2', none); // 0.5 seconds
    actor.anim_shoot = animfixfps(actor, '2 1 5', none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, '1 1 1', none);
    return true;
}
#endif
#ifdef SVQC
METHOD(Wyvern, mr_setup, bool(Wyvern this, entity actor))
{
    TC(Wyvern, this);
    if(!GetResource(this, RES_HEALTH)) SetResource(actor, RES_HEALTH, autocvar_g_monster_wyvern_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_wyvern_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_wyvern_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_wyvern_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_wyvern_damageforcescale); }

    actor.monster_loot = ITEM_Cells;
    actor.monster_attackfunc = M_Wyvern_Attack;

    return true;
}
#endif
