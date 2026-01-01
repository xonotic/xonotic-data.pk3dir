#include "zombie.qh"

#ifdef SVQC
float autocvar_g_monster_zombie_health;
string autocvar_g_monster_zombie_loot = "health_medium";
float autocvar_g_monster_zombie_damageforcescale = 0.55;
float autocvar_g_monster_zombie_attack_melee_damage;
float autocvar_g_monster_zombie_attack_melee_delay;
float autocvar_g_monster_zombie_attack_leap_damage;
float autocvar_g_monster_zombie_attack_leap_force;
float autocvar_g_monster_zombie_attack_leap_speed;
float autocvar_g_monster_zombie_attack_leap_delay;
float autocvar_g_monster_zombie_speed_stop;
float autocvar_g_monster_zombie_speed_run;
float autocvar_g_monster_zombie_speed_walk;

.vector moveto;

void M_Zombie_Attack_Leap_Touch(entity this, entity toucher)
{
	if (GetResource(this, RES_HEALTH) <= 0)
		return;

	vector angles_face;

	if(toucher.takedamage)
	{
		angles_face = vectoangles(this.moveto - this.origin);
		angles_face = normalize(angles_face) * (autocvar_g_monster_zombie_attack_leap_force);
		Damage(toucher, this, this, (autocvar_g_monster_zombie_attack_leap_damage) * MONSTER_SKILLMOD(this), DEATH_MONSTER_ZOMBIE_JUMP.m_id, DMG_NOWEP, toucher.origin, angles_face);
		settouch(this, Monster_Touch); // instantly turn it off to stop damage spam
		this.state = 0;
	}

	if (trace_dphitcontents)
	{
		this.state = 0;
		settouch(this, Monster_Touch);
	}
}

void M_Zombie_Defend_Block_End(entity this)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	setanim(this, this.anim_blockend, false, true, true);
	SetResourceExplicit(this, RES_ARMOR, autocvar_g_monsters_armor_blockpercent);
}

bool M_Zombie_Defend_Block(entity this)
{
	SetResourceExplicit(this, RES_ARMOR, 0.9);
	this.state = MONSTER_ATTACK_MELEE; // freeze monster
	this.attack_finished_single[0] = time + 2.1;
	this.anim_finished = this.attack_finished_single[0];
	setanim(this, this.anim_blockstart, false, true, true);

	Monster_Delay(this, 1, 2, M_Zombie_Defend_Block_End);

	return true;
}

bool M_Zombie_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() < 0.3 && GetResource(actor, RES_HEALTH) < 75 && GetResource(actor.enemy, RES_HEALTH) > 10)
				return M_Zombie_Defend_Block(actor);

			float anim_chance = random();
			vector chosen_anim;

			if(anim_chance < 0.33)
				chosen_anim = actor.anim_melee1;
			else if(anim_chance < 0.66)
				chosen_anim = actor.anim_melee2;
			else
				chosen_anim = actor.anim_melee3;

			return Monster_Attack_Melee(actor, actor.enemy, (autocvar_g_monster_zombie_attack_melee_damage), chosen_anim, actor.attack_range, (autocvar_g_monster_zombie_attack_melee_delay), DEATH_MONSTER_ZOMBIE_MELEE.m_id, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(actor.angles);
			return Monster_Attack_Leap(actor, actor.anim_shoot, M_Zombie_Attack_Leap_Touch, v_forward * (autocvar_g_monster_zombie_attack_leap_speed) + '0 0 200', (autocvar_g_monster_zombie_attack_leap_delay));
		}
	}

	return false;
}

spawnfunc(monster_zombie) { Monster_Spawn(this, true, MON_ZOMBIE); }
#endif // SVQC

#ifdef SVQC
METHOD(Zombie, mr_think, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    if(time >= actor.spawn_time)
        actor.damageforcescale = autocvar_g_monster_zombie_damageforcescale;
    return true;
}

METHOD(Zombie, mr_pain, float(Zombie this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Zombie, this);
    actor.pain_finished = time + 0.34;
    if(time >= actor.spawn_time)
    	setanim(actor, ((random() > 0.5) ? actor.anim_pain1 : actor.anim_pain2), true, true, false);
    return damage_take;
}

METHOD(Zombie, mr_death, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    SetResourceExplicit(actor, RES_ARMOR, autocvar_g_monsters_armor_blockpercent);

    setanim(actor, ((random() > 0.5) ? actor.anim_die1 : actor.anim_die2), false, true, true);
    return true;
}
#endif
#ifdef GAMEQC
METHOD(Zombie, mr_anim, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    vector none = '0 0 0';
    actor.anim_die1 = animfixfps(actor, '9 1 0.5', none); // 2 seconds
    actor.anim_die2 = animfixfps(actor, '12 1 0.5', none); // 2 seconds
    actor.anim_spawn = animfixfps(actor, '30 1 3', none);
    actor.anim_walk = animfixfps(actor, '27 1 1', none);
    actor.anim_idle = animfixfps(actor, '19 1 1', none);
    actor.anim_pain1 = animfixfps(actor, '20 1 2', none); // 0.5 seconds
    actor.anim_pain2 = animfixfps(actor, '22 1 2', none); // 0.5 seconds
    actor.anim_melee1 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee2 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee3 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_shoot = animfixfps(actor, '0 1 5', none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, '27 1 1', none);
    actor.anim_blockstart = animfixfps(actor, '8 1 1', none);
    actor.anim_blockend = animfixfps(actor, '7 1 1', none);
    return true;
}
#endif
#ifdef SVQC
METHOD(Zombie, mr_setup, bool(Zombie this, entity actor))
{
    TC(Zombie, this);
    if(!GetResource(actor, RES_HEALTH)) SetResourceExplicit(actor, RES_HEALTH, autocvar_g_monster_zombie_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_zombie_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_zombie_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_zombie_speed_stop); }

    if(actor.spawnflags & MONSTERFLAG_NORESPAWN)
        actor.spawnflags &= ~MONSTERFLAG_NORESPAWN; // zombies always respawn

    actor.spawnflags &= ~MONSTERFLAG_APPEAR; // once it's appeared, it will respawn quickly, we don't want it to appear

    actor.spawnflags |= MONSTER_RESPAWN_DEATHPOINT;

    actor.monster_loot = autocvar_g_monster_zombie_loot;
    actor.monster_attackfunc = M_Zombie_Attack;
    StatusEffects_apply(STATUSEFFECT_SpawnShield, actor, actor.spawn_time, 0);
    actor.respawntime = 0.2;
    actor.damageforcescale = 0.0001; // no push while spawning

    setanim(actor, actor.anim_spawn, false, true, true);
    actor.spawn_time = actor.animstate_endtime;

    return true;
}
#endif
#ifdef MENUQC
METHOD(Zombie, describe, string(Zombie this))
{
	TC(Zombie, this);
	PAGE_TEXT_INIT();
	PAR(_("Zombies are the undead remains of deceased soldiers, risen with a ravenous hunger and no sense of self-preservation."));
	PAR(_("When a Zombie senses a nearby player it will begin to charge its target at high speeds. "
	      "While charging, a Zombie may leap towards the player, dealing massive damage on contact. "
	      "If it gets close, the Zombie will punch and bite repeatedly."));
	PAR(_("When threatened the Zombie may hold up its hands to block incoming attacks briefly."));
	PAR(_("It is no small task to kill that which is already dead. Once a Zombie is defeated, destroy its corpse to prevent it from rising again!"));
	return PAGE_TEXT;
}
#endif
