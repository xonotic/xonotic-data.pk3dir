#include "golem.qh"

#ifdef SVQC
float autocvar_g_monster_golem_health;
string autocvar_g_monster_golem_loot = "health_mega electro";
float autocvar_g_monster_golem_damageforcescale = 0.1;
float autocvar_g_monster_golem_attack_smash_damage;
float autocvar_g_monster_golem_attack_smash_force = 100;
float autocvar_g_monster_golem_attack_smash_range = 200;
float autocvar_g_monster_golem_attack_claw_damage;
float autocvar_g_monster_golem_attack_lightning_damage;
float autocvar_g_monster_golem_attack_lightning_damage_zap = 15;
float autocvar_g_monster_golem_attack_lightning_force;
float autocvar_g_monster_golem_attack_lightning_radius;
float autocvar_g_monster_golem_attack_lightning_radius_zap;
float autocvar_g_monster_golem_attack_lightning_speed;
float autocvar_g_monster_golem_attack_lightning_speed_up;
float autocvar_g_monster_golem_speed_stop;
float autocvar_g_monster_golem_speed_run;
float autocvar_g_monster_golem_speed_walk;

.float golem_lastattack; // delay attacks separately

void M_Golem_Attack_Smash(entity this)
{
	makevectors(this.angles);
	Send_Effect(EFFECT_EXPLOSION_MEDIUM, (this.origin + (v_forward * 150)) - ('0 0 1' * this.maxs.z), '0 0 0', 1);
	sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

	vector loc = this.origin + v_forward * 50;

	entity dmgent = spawn();
	dmgent.owner = dmgent.realowner = this;
	setorigin(dmgent, loc);
	RadiusDamage (dmgent, this, (autocvar_g_monster_golem_attack_smash_damage) * MONSTER_SKILLMOD(this), (autocvar_g_monster_golem_attack_smash_damage * 0.5) * MONSTER_SKILLMOD(this), 
					autocvar_g_monster_golem_attack_smash_range, this, NULL, autocvar_g_monster_golem_attack_smash_force, DEATH_MONSTER_GOLEM_SMASH.m_id, DMG_NOWEP, NULL);
	delete(dmgent);
}

void M_Golem_Attack_Swing(entity this)
{
	Monster_Attack_Melee(this, this.enemy, (autocvar_g_monster_golem_attack_claw_damage), ((random() >= 0.5) ? this.anim_melee2 : this.anim_melee3), this.attack_range, 0.8, DEATH_MONSTER_GOLEM_CLAW.m_id, true);
}

#include <common/effects/qc/_mod.qh>

void M_Golem_Attack_Lightning_Explode(entity this, entity directhitentity)
{
	sound(this, CH_SHOTS, SND_MON_GOLEM_LIGHTNING_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;
	set_movetype(this, MOVETYPE_NONE);
	this.velocity = '0 0 0';

	if(this.move_movetype == MOVETYPE_NONE)
		this.velocity = this.oldvelocity;

	RadiusDamage (this, this.realowner, (autocvar_g_monster_golem_attack_lightning_damage), (autocvar_g_monster_golem_attack_lightning_damage), (autocvar_g_monster_golem_attack_lightning_radius),
					NULL, NULL, (autocvar_g_monster_golem_attack_lightning_force), this.projectiledeathtype, DMG_NOWEP, directhitentity);

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_monster_golem_attack_lightning_radius_zap, it != this.realowner && it.takedamage,
	{
		te_csqc_lightningarc(this.origin, it.origin);
		Damage(it, this, this.realowner, (autocvar_g_monster_golem_attack_lightning_damage_zap) * MONSTER_SKILLMOD(this), DEATH_MONSTER_GOLEM_ZAP.m_id, DMG_NOWEP, it.origin, '0 0 0');
	});

	setthink(this, SUB_Remove);
	this.nextthink = time + 0.2;
}

void M_Golem_Attack_Lightning_Explode_use(entity this, entity actor, entity trigger)
{
	M_Golem_Attack_Lightning_Explode(this, trigger);
}

void M_Golem_Attack_Lightning_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if (GetResource(this, RES_HEALTH) <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);

	if (GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, adaptor_think2use);
}

void M_Golem_Attack_Lightning_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	this.use(this, NULL, toucher);
}

void M_Golem_Attack_Lightning_Think(entity this)
{
	this.nextthink = time;
	if (time > this.cnt)
	{
		M_Golem_Attack_Lightning_Explode(this, NULL);
		return;
	}
}

void M_Golem_Attack_Lightning(entity this)
{
	entity gren;

	monster_makevectors(this, this.enemy);

	gren = new(grenade);
	gren.owner = gren.realowner = this;
	gren.bot_dodge = true;
	gren.bot_dodgerating = (autocvar_g_monster_golem_attack_lightning_damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = DEATH_MONSTER_GOLEM_ZAP.m_id;
	setorigin(gren, CENTER_OR_VIEWOFS(this));
	setsize(gren, '-8 -8 -8', '8 8 8');
	gren.scale = 2.5;

	gren.cnt = time + 5;
	gren.nextthink = time;
	setthink(gren, M_Golem_Attack_Lightning_Think);
	gren.use = M_Golem_Attack_Lightning_Explode_use;
	settouch(gren, M_Golem_Attack_Lightning_Touch);

	gren.takedamage = DAMAGE_YES;
	SetResourceExplicit(gren, RES_HEALTH, 50);
	gren.damageforcescale = 0;
	gren.event_damage = M_Golem_Attack_Lightning_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_Explicit(gren, v_forward, v_up, (autocvar_g_monster_golem_attack_lightning_speed), (autocvar_g_monster_golem_attack_lightning_speed_up), 0, 0, false);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	CSQCProjectile(gren, true, PROJECTILE_GOLEM_LIGHTNING, true);
}

.int state;

bool M_Golem_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			setanim(actor, ((random() >= 0.5) ? actor.anim_melee2 : actor.anim_melee3), false, true, true);
			int swing_cnt = bound(1, floor(random() * 4), 3);
			Monster_Delay(actor, swing_cnt, 0.5, M_Golem_Attack_Swing);
			actor.anim_finished = actor.attack_finished_single[0] = time + (0.5 * swing_cnt); // set this for the delay
			return true;
		}
		case MONSTER_ATTACK_RANGED:
		{
			float randomness = random();

			if(time < actor.golem_lastattack || !IS_ONGROUND(actor))
				return false;

			if(randomness <= 0.5 && vdist(actor.enemy.origin - actor.origin, <=, autocvar_g_monster_golem_attack_smash_range))
			{
				setanim(actor, actor.anim_melee1, false, true, true);
				Monster_Delay(actor, 1, 1.1, M_Golem_Attack_Smash);
				if(actor.animstate_endtime > time)
					actor.anim_finished = actor.animstate_endtime;
				else
					actor.anim_finished = time + 1.2;
				actor.attack_finished_single[0] = actor.anim_finished + 0.2;
				actor.state = MONSTER_ATTACK_MELEE; // kinda a melee attack
				actor.golem_lastattack = time + 3 + random() * 1.5;
				return true;
			}
			else if(randomness <= 0.1 && vdist(actor.enemy.origin - actor.origin, >=, autocvar_g_monster_golem_attack_smash_range * 1.5)) // small chance, don't want this spammed
			{
				setanim(actor, actor.anim_melee2, true, true, false);
				actor.state = MONSTER_ATTACK_MELEE; // maybe we should rename this to something more general
				actor.attack_finished_single[0] = time + 1.1;
				actor.anim_finished = 1.1;
				actor.golem_lastattack = time + 3 + random() * 1.5;
				Monster_Delay(actor, 1, 0.6, M_Golem_Attack_Lightning);
				return true;
			}

			return false;
		}
	}

	return false;
}

spawnfunc(monster_golem) { Monster_Spawn(this, true, MON_GOLEM); }
// compatibility
spawnfunc(monster_shambler) { spawnfunc_monster_golem(this); }
#endif // SVQC

#ifdef SVQC
METHOD(Golem, mr_think, bool(Golem this, entity actor))
{
    TC(Golem, this);
    return true;
}

METHOD(Golem, mr_pain, float(Golem this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Golem, this);
    actor.pain_finished = time + 0.5;
    setanim(actor, ((random() >= 0.5) ? actor.anim_pain2 : actor.anim_pain1), true, true, false);
    return damage_take;
}

METHOD(Golem, mr_death, bool(Golem this, entity actor))
{
    TC(Golem, this);
    setanim(actor, actor.anim_die1, false, true, true);
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Golem, mr_anim, bool(Golem this, entity actor))
{
    TC(Golem, this);
    vector none = '0 0 0';
    actor.anim_idle = animfixfps(actor, '0 1 1', none);
    actor.anim_walk = animfixfps(actor, '1 1 1', none);
    actor.anim_run = animfixfps(actor, '2 1 1', none);
    //actor.anim_melee1 = animfixfps(actor, '3 1 5', none); // analyze models and set framerate
    actor.anim_melee2 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee3 = animfixfps(actor, '5 1 5', none); // analyze models and set framerate
    //actor.anim_melee4 = animfixfps(actor, '6 1 5', none); // analyze models and set framerate
    actor.anim_melee1 = animfixfps(actor, '6 1 5', none); // analyze models and set framerate
    actor.anim_pain1 = animfixfps(actor, '7 1 2', none); // 0.5 seconds
    actor.anim_pain2 = animfixfps(actor, '8 1 2', none); // 0.5 seconds
    //actor.anim_pain3 = animfixfps(actor, '9 1 2', none); // 0.5 seconds
    //actor.anim_pain4 = animfixfps(actor, '10 1 2', none); // 0.5 seconds
    //actor.anim_pain5 = animfixfps(actor, '11 1 2', none); // 0.5 seconds
    actor.anim_spawn = animfixfps(actor, '12 1 5', none); // analyze models and set framerate
    actor.anim_die1 = animfixfps(actor, '13 1 0.5', none); // 2 seconds
    //actor.anim_dead = animfixfps(actor, '14 1 0.5', none); // 2 seconds
    actor.anim_die2 = animfixfps(actor, '15 1 0.5', none); // 2 seconds
    // dead2 16
    //actor.anim_dieback = animfixfps(actor, '16 1 0.5', none); // 2 seconds
    //actor.anim_deadback = animfixfps(actor, '17 1 0.5', none); // 2 seconds
    //actor.anim_dead2 = animfixfps(actor, '18 1 0.5', none); // 2 seconds
    //actor.anim_dead3 = animfixfps(actor, '19 1 0.5', none); // 2 seconds
    //actor.anim_dead4 = animfixfps(actor, '20 1 0.5', none); // 2 seconds
    //actor.anim_dead5 = animfixfps(actor, '21 1 0.5', none); // 2 seconds
    //actor.anim_dead6 = animfixfps(actor, '22 1 0.5', none); // 2 seconds
    return true;
}
#endif
#ifdef SVQC
.float animstate_endtime;
METHOD(Golem, mr_setup, bool(Golem this, entity actor))
{
    TC(Golem, this);
    if(!GetResource(actor, RES_HEALTH)) SetResourceExplicit(actor, RES_HEALTH, autocvar_g_monster_golem_health);
    if(!actor.attack_range) actor.attack_range = 150;
    if(!actor.speed) { actor.speed = (autocvar_g_monster_golem_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_golem_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_golem_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_golem_damageforcescale); }

    actor.monster_loot = autocvar_g_monster_golem_loot;

    setanim(actor, actor.anim_spawn, false, true, true);
    actor.spawn_time = actor.animstate_endtime;
    StatusEffects_apply(STATUSEFFECT_SpawnShield, actor, actor.spawn_time, 0);
    actor.monster_attackfunc = M_Golem_Attack;

    return true;
}
#endif
#ifdef MENUQC
METHOD(Golem, describe, string(Golem this))
{
	TC(Golem, this);
	PAGE_TEXT_INIT();
	PAR(_("Golems are large powerful brutes capable of taking and dealing a beating. Keeping your distance is advised."));
	PAR(_("The Golem's primary melee attack is a series of punches. "
	      "On occasion the Golem may jump into the air, dealing massive damage in an area as it slams the ground."));
	PAR(_("To deal with distant foes, the Golem may throw a chunk of its electrified rocky exterior, zapping nearby targets on impact."));
	return PAGE_TEXT;
}
#endif
