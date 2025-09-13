#include "mage.qh"

#ifdef SVQC
float autocvar_g_monster_mage_health;
string autocvar_g_monster_mage_loot = "health_big";
float autocvar_g_monster_mage_damageforcescale = 0.5;
float autocvar_g_monster_mage_attack_spike_damage;
float autocvar_g_monster_mage_attack_spike_radius;
float autocvar_g_monster_mage_attack_spike_delay;
float autocvar_g_monster_mage_attack_spike_accel;
float autocvar_g_monster_mage_attack_spike_decel;
float autocvar_g_monster_mage_attack_spike_chance = 0.45;
float autocvar_g_monster_mage_attack_spike_turnrate;
float autocvar_g_monster_mage_attack_spike_speed_max;
float autocvar_g_monster_mage_attack_spike_smart;
float autocvar_g_monster_mage_attack_spike_smart_trace_min;
float autocvar_g_monster_mage_attack_spike_smart_trace_max;
float autocvar_g_monster_mage_attack_spike_smart_mindist;
float autocvar_g_monster_mage_attack_push_chance = 0.7;
float autocvar_g_monster_mage_attack_push_damage;
float autocvar_g_monster_mage_attack_push_radius;
float autocvar_g_monster_mage_attack_push_delay;
float autocvar_g_monster_mage_attack_push_force;
float autocvar_g_monster_mage_attack_teleport_chance = 0.2;
float autocvar_g_monster_mage_attack_teleport_delay = 2;
float autocvar_g_monster_mage_attack_teleport_random = 0.4;
float autocvar_g_monster_mage_attack_teleport_random_range = 1200;
float autocvar_g_monster_mage_heal_allies;
float autocvar_g_monster_mage_heal_minhealth;
float autocvar_g_monster_mage_heal_range;
float autocvar_g_monster_mage_heal_delay;
float autocvar_g_monster_mage_shield_time;
float autocvar_g_monster_mage_shield_delay;
float autocvar_g_monster_mage_shield_blockpercent;
float autocvar_g_monster_mage_speed_stop;
float autocvar_g_monster_mage_speed_run;
float autocvar_g_monster_mage_speed_walk;

SOUND(MageSpike_FIRE, W_Sound("electro_fire"));
SOUND(MageSpike_IMPACT, W_Sound("grenade_impact"));
SOUND(MageSpike_PUSH, W_Sound("tagexp1"));
void M_Mage_Attack_Spike(entity this, vector dir);
void M_Mage_Attack_Push(entity this);
METHOD(MageSpike, wr_think, void(MageSpike thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(MageSpike, thiswep);
    if (fire & 1)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, false, 0.2)) {
        if (!actor.target_range) actor.target_range = autocvar_g_monsters_target_range;
        actor.enemy = Monster_FindTarget(actor);
        monster_makevectors(actor, actor.enemy);
        W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_MageSpike_FIRE, CH_WEAPON_B, 0, DEATH_MONSTER_MAGE.m_id);
    	if (!IS_PLAYER(actor)) w_shotdir = normalize((actor.enemy.origin + '0 0 10') - actor.origin);
        M_Mage_Attack_Spike(actor, w_shotdir);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
    }
    if (fire & 2)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, true, 0.5)) {
        M_Mage_Attack_Push(actor);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}

void M_Mage_Attack_Teleport(entity this, entity targ);

CLASS(OffhandMageTeleport, OffhandWeapon)
    .bool OffhandMageTeleport_key_pressed;
    METHOD(OffhandMageTeleport, offhand_think, void(OffhandMageTeleport this, entity player, bool key_pressed))
    {
        TC(OffhandMageTeleport, this);
        if (key_pressed && !player.OffhandMageTeleport_key_pressed)
        	M_Mage_Attack_Teleport(player, player.enemy);
        player.OffhandMageTeleport_key_pressed = key_pressed;
    }
ENDCLASS(OffhandMageTeleport)
OffhandMageTeleport OFFHAND_MAGE_TELEPORT;
STATIC_INIT(OFFHAND_MAGE_TELEPORT) { OFFHAND_MAGE_TELEPORT = NEW(OffhandMageTeleport); }

void M_Mage_Defend_Heal(entity this);
void M_Mage_Defend_Shield(entity this);

.entity mage_spike;
.float mage_shield_delay;

bool M_Mage_Defend_Heal_Check(entity this, entity targ)
{
	// TODO: mutator hook to choose valid healing targets?
	if(!targ)
		return false;
	if(GetResource(targ, RES_HEALTH) <= 0)
		return false;
	if(DIFF_TEAM(targ, this) && targ != this.monster_follow)
		return false;
	if(STAT(FROZEN, targ))
		return false;
	if(!IS_PLAYER(targ))
		return (IS_MONSTER(targ) && GetResource(targ, RES_HEALTH) < targ.max_health);
	if(StatusEffects_active(STATUSEFFECT_Shield, targ))
		return false;

	switch(this.skin)
	{
		case 0: return (GetResource(targ, RES_HEALTH) < autocvar_g_balance_health_regenstable);
		case 1:
		{
			return ((GetResource(targ, RES_CELLS) && GetResource(targ, RES_CELLS) < autocvar_g_pickup_cells_max)
			     || (GetResource(targ, RES_ROCKETS) && GetResource(targ, RES_ROCKETS) < autocvar_g_pickup_rockets_max)
			     || (GetResource(targ, RES_BULLETS) && GetResource(targ, RES_BULLETS) < autocvar_g_pickup_nails_max)
			     || (GetResource(targ, RES_SHELLS) && GetResource(targ, RES_SHELLS) < autocvar_g_pickup_shells_max)
			);
		}
		case 2: return (GetResource(targ, RES_ARMOR) < autocvar_g_balance_armor_regenstable);
	}

	return false;
}

void M_Mage_Attack_Spike_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;

	sound(this, CH_SHOTS, SND_MageSpike_IMPACT, VOL_BASE, ATTEN_NORM);

	this.realowner.mage_spike = NULL;

	Send_Effect(EFFECT_EXPLOSION_SMALL, this.origin, '0 0 0', 1);
	RadiusDamage (this, this.realowner, (autocvar_g_monster_mage_attack_spike_damage), (autocvar_g_monster_mage_attack_spike_damage) * 0.5, (autocvar_g_monster_mage_attack_spike_radius),
						NULL, NULL, 0, DEATH_MONSTER_MAGE.m_id, DMG_NOWEP, directhitentity);

	delete(this);
}

void M_Mage_Attack_Spike_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	M_Mage_Attack_Spike_Explode(this, toucher);
}

.float wait;

// copied from W_Seeker_Think
void M_Mage_Attack_Spike_Think(entity this)
{
	if (time > this.ltime || (this.enemy && GetResource(this.enemy, RES_HEALTH) <= 0) || !this.owner || GetResource(this.owner, RES_HEALTH) <= 0) {
		this.projectiledeathtype |= HITTYPE_SPLASH;
		M_Mage_Attack_Spike_Explode(this, NULL);
	}

	float spd = vlen(this.velocity);
	spd = bound(
		spd - (autocvar_g_monster_mage_attack_spike_decel) * frametime,
		(autocvar_g_monster_mage_attack_spike_speed_max),
		spd + (autocvar_g_monster_mage_attack_spike_accel) * frametime
	);

	if (this.enemy != NULL)
		if (this.enemy.takedamage != DAMAGE_AIM || IS_DEAD(this.enemy))
			this.enemy = NULL;

	if (this.enemy != NULL)
	{
		entity e = this.enemy;
		vector eorg = 0.5 * (e.absmin + e.absmax);
		float turnrate = (autocvar_g_monster_mage_attack_spike_turnrate); // how fast to turn
		vector desireddir = normalize(eorg - this.origin);
		vector olddir = normalize(this.velocity); // get my current direction

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if ((autocvar_g_monster_mage_attack_spike_smart) && vdist(eorg - this.origin, >, autocvar_g_monster_mage_attack_spike_smart_mindist))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if ( vlen2(this.origin + olddir * this.wait) < vlen2(eorg - this.origin))
				traceline(this.origin, this.origin + olddir * this.wait, false, this);
			else
				traceline(this.origin, eorg, false, this);

			// Setup adaptive tracelength
			this.wait = bound((autocvar_g_monster_mage_attack_spike_smart_trace_min), vlen(this.origin - trace_endpos), this.wait = (autocvar_g_monster_mage_attack_spike_smart_trace_max));

			// Calc how important it is that we turn and add this to the desierd (enemy) dir.
			desireddir = normalize(((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction)) * 0.5);
		}

		vector newdir = normalize(olddir + desireddir * turnrate); // take the average of the 2 directions; not the best method but simple & easy
		this.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	}

	///////////////

	//this.angles = vectoangles(this.velocity);			// turn model in the new flight direction
	this.nextthink = time;// + 0.05; // csqc projectiles
	UpdateCSQCProjectile(this);
}

void M_Mage_Attack_Spike(entity this, vector dir)
{
	makevectors(this.angles);

	entity missile = new(M_Mage_Attack_Spike);
	missile.owner = missile.realowner = this;
	setthink(missile, M_Mage_Attack_Spike_Think);
	missile.ltime = time + 7;
	missile.nextthink = time;
	missile.solid = SOLID_BBOX;
	set_movetype(missile, MOVETYPE_FLYMISSILE);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	setorigin(missile, this.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	setsize(missile, '0 0 0', '0 0 0');
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.enemy = this.enemy;
	settouch(missile, M_Mage_Attack_Spike_Touch);

	this.mage_spike = missile;

	CSQCProjectile(missile, true, PROJECTILE_MAGE_SPIKE, true);
}

void M_Mage_Defend_Heal(entity this)
{
	bool washealed = false;

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_monster_mage_heal_range, M_Mage_Defend_Heal_Check(this, it),
	{
		washealed = true;
		entity fx = EFFECT_Null;
		if(IS_PLAYER(it))
		{
			switch(this.skin)
			{
				case 0:
				{
					Heal(it, this, autocvar_g_monster_mage_heal_allies, autocvar_g_balance_health_regenstable);
					fx = EFFECT_HEALING;
					break;
				}
				case 1:
				{
					if(GetResource(it, RES_CELLS)) GiveResourceWithLimit(it, RES_CELLS, 1, autocvar_g_pickup_cells_max);
					if(GetResource(it, RES_ROCKETS)) GiveResourceWithLimit(it, RES_ROCKETS, 1, autocvar_g_pickup_rockets_max);
					if(GetResource(it, RES_SHELLS)) GiveResourceWithLimit(it, RES_SHELLS, 2, autocvar_g_pickup_shells_max);
					if(GetResource(it, RES_BULLETS)) GiveResourceWithLimit(it, RES_BULLETS, 5, autocvar_g_pickup_nails_max);
					// TODO: fuel?
					fx = EFFECT_AMMO_REGEN;
					break;
				}
				case 2:
					if(GetResource(it, RES_ARMOR) < autocvar_g_balance_armor_regenstable)
					{
						GiveResourceWithLimit(it, RES_ARMOR, autocvar_g_monster_mage_heal_allies, autocvar_g_balance_armor_regenstable);
						fx = EFFECT_ARMOR_REPAIR;
					}
					break;
			}

			Send_Effect(fx, it.origin, '0 0 0', 1);
		}
		else
		{
			Send_Effect(EFFECT_HEALING, it.origin, '0 0 0', 1);
			Heal(it, this, autocvar_g_monster_mage_heal_allies, RES_LIMIT_NONE);
			if(!(it.spawnflags & MONSTERFLAG_INVINCIBLE) && it.sprite)
				WaypointSprite_UpdateHealth(it.sprite, GetResource(it, RES_HEALTH));
		}
	});

	if(washealed)
	{
		setanim(this, this.anim_melee, true, true, true);
		this.attack_finished_single[0] = time + (autocvar_g_monster_mage_heal_delay);
		this.state = MONSTER_ATTACK_MELEE;
		this.anim_finished = time + 1.5;
	}
}

void M_Mage_Attack_Push(entity this)
{
	sound(this, CH_SHOTS, SND_MageSpike_PUSH, 1, ATTEN_NORM);
	RadiusDamage (this, this, (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_radius),
						NULL, NULL, (autocvar_g_monster_mage_attack_push_force), DEATH_MONSTER_MAGE.m_id, DMG_NOWEP, this.enemy);
	Send_Effect(EFFECT_TE_EXPLOSION, this.origin, '0 0 0', 1);

	setanim(this, this.anim_duckjump, true, true, true);
	this.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_push_delay);
	this.anim_finished = time + 1;
	this.state = MONSTER_ATTACK_MELEE; // prevent moving while firing spike
}

void M_Mage_Attack_Teleport(entity this, entity targ)
{
	if(!targ) return;
	if(vdist(targ.origin - this.origin, >, autocvar_g_monster_mage_attack_teleport_random_range)) return;

	if(autocvar_g_monster_mage_attack_teleport_random && random() <= autocvar_g_monster_mage_attack_teleport_random)
	{
		vector oldpos = this.origin;
		vector extrasize = '1 1 1' * autocvar_g_monster_mage_attack_teleport_random_range;
		if(MoveToRandomLocationWithinBounds(this, this.absmin - extrasize, this.absmax + extrasize,
											DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, 
											Q3SURFACEFLAG_SKY, 10, 64, 256, true))
		{
			vector a = vectoangles(targ.origin - this.origin);
			this.angles = '0 1 0' * a.y;
			this.fixangle = true;
			Send_Effect(EFFECT_SPAWN, oldpos, '0 0 0', 1);
			Send_Effect(EFFECT_SPAWN, this.origin, '0 0 0', 1);
			this.attack_finished_single[0] = time + autocvar_g_monster_mage_attack_teleport_delay;
			return;
		}
	}

	if(!IS_ONGROUND(targ)) return;

	makevectors(targ.angles);
	tracebox(CENTER_OR_VIEWOFS(targ), this.mins, this.maxs, CENTER_OR_VIEWOFS(targ) + ((v_forward * -1) * 200), MOVE_NOMONSTERS, this);

	if(trace_fraction < 1)
		return;

	vector newpos = trace_endpos;

	Send_Effect(EFFECT_SPAWN, this.origin, '0 0 0', 1);
	Send_Effect(EFFECT_SPAWN, newpos, '0 0 0', 1);

	setorigin(this, newpos);

	vector a = vectoangles(targ.origin - this.origin);
	a.x = -a.x;
	this.angles_x = a.x;
	this.angles_y = a.y;
	this.fixangle = true;
	this.velocity *= 0.5;

	this.attack_finished_single[0] = time + autocvar_g_monster_mage_attack_teleport_delay;
}

void M_Mage_Defend_Shield(entity this)
{
	StatusEffects_apply(STATUSEFFECT_Shield, this, time + autocvar_g_monster_mage_shield_time, 0);
	this.mage_shield_delay = time + (autocvar_g_monster_mage_shield_delay);
	SetResourceExplicit(this, RES_ARMOR, autocvar_g_monster_mage_shield_blockpercent);
	setanim(this, this.anim_shoot, true, true, true);
	this.attack_finished_single[0] = time + 1; // give just a short cooldown on attacking
	this.anim_finished = time + 1;
}

bool M_Mage_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() <= autocvar_g_monster_mage_attack_push_chance)
			{
				Weapon wep = WEP_MAGE_SPIKE;

				wep.wr_think(wep, actor, weaponentity, 2);
				return true;
			}

			return false;
		}
		case MONSTER_ATTACK_RANGED:
		{
			if(random() <= autocvar_g_monster_mage_attack_teleport_chance)
			{
				OffhandWeapon off = OFFHAND_MAGE_TELEPORT;
				actor.OffhandMageTeleport_key_pressed = 0;
				off.offhand_think(off, actor, 1);
				return true;
			}
			else if(!actor.mage_spike && random() <= autocvar_g_monster_mage_attack_spike_chance)
			{
				setanim(actor, actor.anim_shoot, true, true, true);
				actor.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_spike_delay);
				actor.anim_finished = time + 1;
				actor.state = MONSTER_ATTACK_MELEE; // prevent moving while firing spike
				Weapon wep = WEP_MAGE_SPIKE;
				wep.wr_think(wep, actor, weaponentity, 1);
				return true;
			}

			return false;
		}
	}

	return false;
}

spawnfunc(monster_mage) { Monster_Spawn(this, true, MON_MAGE); }

#endif // SVQC

#ifdef SVQC
METHOD(Mage, mr_think, bool(Mage thismon, entity actor))
{
    TC(Mage, thismon);
    bool need_help = false;

    FOREACH_CLIENT(IS_PLAYER(it) && it != actor,
    {
    	if(vdist(it.origin - actor.origin, <=, autocvar_g_monster_mage_heal_range))
        if(M_Mage_Defend_Heal_Check(actor, it))
        {
            need_help = true;
            break;
        }
    });

    if(!need_help)
    {
    	IL_EACH(g_monsters, it != actor,
    	{
    		if(vdist(it.origin - actor.origin, <=, autocvar_g_monster_mage_heal_range))
	        if(M_Mage_Defend_Heal_Check(actor, it))
	        {
	            need_help = true;
	            break;
	        }
    	});
    }

    if(GetResource(actor, RES_HEALTH) < (autocvar_g_monster_mage_heal_minhealth) || need_help)
    if(time >= actor.attack_finished_single[0])
    if(random() < 0.5)
        M_Mage_Defend_Heal(actor);

    if(actor.enemy && time >= actor.mage_shield_delay && random() < 0.5)
    if(GetResource(actor, RES_HEALTH) < actor.max_health && !StatusEffects_active(STATUSEFFECT_Shield, actor))
        M_Mage_Defend_Shield(actor);

    return true;
}

METHOD(Mage, mr_pain, float(Mage this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(Mage, this);
    return damage_take;
}

METHOD(Mage, mr_death, bool(Mage this, entity actor))
{
    TC(Mage, this);
    setanim(actor, ((random() > 0.5) ? actor.anim_die2 : actor.anim_die1), false, true, true);
    return true;
}

#endif
#ifdef GAMEQC
METHOD(Mage, mr_anim, bool(Mage this, entity actor))
{
    TC(Mage, this);
    vector none = '0 0 0';
    actor.anim_idle = animfixfps(actor, '0 1 1', none);
    actor.anim_walk = animfixfps(actor, '1 1 1', none);
    actor.anim_run = animfixfps(actor, '1 1 1', none);
    actor.anim_shoot = animfixfps(actor, '2 1 5', none); // analyze models and set framerate
    actor.anim_duckjump = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    actor.anim_melee = animfixfps(actor, '5 1 5', none); // analyze models and set framerate
    //actor.anim_fire1 = animfixfps(actor, '3 1 5', none); // analyze models and set framerate
    //actor.anim_fire2 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
    //actor.anim_fire3 = animfixfps(actor, '5 1 5', none); // analyze models and set framerate
    actor.anim_pain1 = animfixfps(actor, '6 1 2', none); // 0.5 seconds
    actor.anim_pain2 = animfixfps(actor, '7 1 2', none); // 0.5 seconds
    //actor.anim_pain3 = animfixfps(actor, '8 1 2', none); // 0.5 seconds
    actor.anim_die1 = animfixfps(actor, '9 1 0.5', none); // 2 seconds
    actor.anim_die2 = animfixfps(actor, '10 1 0.5', none); // 2 seconds
    //actor.anim_dead1 = animfixfps(actor, '11 1 0.5', none); // 2 seconds
    //actor.anim_dead2 = animfixfps(actor, '12 1 0.5', none); // 2 seconds
    return true;
}
#endif
#ifdef SVQC
.float speed;
METHOD(Mage, mr_setup, bool(Mage this, entity actor))
{
    TC(Mage, this);
    if(!GetResource(this, RES_HEALTH)) SetResourceExplicit(actor, RES_HEALTH, autocvar_g_monster_mage_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_mage_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_mage_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_mage_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_mage_damageforcescale); }

    actor.monster_loot = autocvar_g_monster_mage_loot;
    actor.monster_attackfunc = M_Mage_Attack;

    return true;
}
#endif
#ifdef MENUQC
METHOD(Mage, describe, string(Mage this))
{
	TC(Mage, this);
	PAGE_TEXT_INIT();
	PAR(_("Wielding nanotechnology as if it were sorcery, the Mage employs a range of unique abilities of its own creation in combat."));
	PAR(_("As a primary attack, the Mage throws a homing electric sphere towards the player. "
	      "This sphere will track its target at high speed, exploding on impact or if it does not reach its target in time."));
	PAR(_("When threatened, the Mage may deploy an energy shield to protect itself from damage briefly. "
	      "Enemies approaching too closely during this time may be pushed away with explosive force!"));
	PAR(_("Defensively the Mage is capable of healing itself and nearby allies, with some variants also providing armor and ammunition."));
	PAR(_("The Mage may sometimes appear to blink out of existence as it teleports behind its target for a sneak attack."));
	return PAGE_TEXT;
}
#endif
