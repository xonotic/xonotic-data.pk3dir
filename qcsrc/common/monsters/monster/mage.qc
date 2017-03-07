#include "mage.qh"

#ifdef SVQC

SOUND(MageSpike_FIRE, W_Sound("electro_fire"));
void M_Mage_Attack_Spike(entity this, vector dir);
void M_Mage_Attack_Push(entity this);
METHOD(MageSpike, wr_think, void(MageSpike thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(MageSpike, thiswep);
    if (fire & 1)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, false, 0.2)) {
        if (!actor.target_range) actor.target_range = autocvar_g_monsters_target_range;
        actor.enemy = Monster_FindTarget(actor);
        W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_MageSpike_FIRE, CH_WEAPON_B, 0);
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
OffhandMageTeleport OFFHAND_MAGE_TELEPORT; STATIC_INIT(OFFHAND_MAGE_TELEPORT) { OFFHAND_MAGE_TELEPORT = NEW(OffhandMageTeleport); }

float autocvar_g_monster_mage_health;
float autocvar_g_monster_mage_damageforcescale = 0.5;
float autocvar_g_monster_mage_attack_spike_damage;
float autocvar_g_monster_mage_attack_spike_radius;
float autocvar_g_monster_mage_attack_spike_delay;
float autocvar_g_monster_mage_attack_spike_accel;
float autocvar_g_monster_mage_attack_spike_decel;
float autocvar_g_monster_mage_attack_spike_turnrate;
float autocvar_g_monster_mage_attack_spike_speed_max;
float autocvar_g_monster_mage_attack_spike_smart;
float autocvar_g_monster_mage_attack_spike_smart_trace_min;
float autocvar_g_monster_mage_attack_spike_smart_trace_max;
float autocvar_g_monster_mage_attack_spike_smart_mindist;
float autocvar_g_monster_mage_attack_push_damage;
float autocvar_g_monster_mage_attack_push_radius;
float autocvar_g_monster_mage_attack_push_delay;
float autocvar_g_monster_mage_attack_push_force;
float autocvar_g_monster_mage_heal_self;
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

/*
const float mage_anim_idle		= 0;
const float mage_anim_walk		= 1;
const float mage_anim_attack	= 2;
const float mage_anim_pain		= 3;
const float mage_anim_death		= 4;
const float mage_anim_run		= 5;
*/

void M_Mage_Defend_Heal(entity this);
void M_Mage_Defend_Shield(entity this);

.entity mage_spike;
.float mage_shield_delay;
.float mage_shield_time;

bool M_Mage_Defend_Heal_Check(entity this, entity targ)
{
	if(targ == NULL)
		return false;
	if(targ.health <= 0)
		return false;
	if(DIFF_TEAM(targ, this) && targ != this.monster_follow)
		return false;
	if(STAT(FROZEN, targ))
		return false;
	if(!IS_PLAYER(targ))
		return (IS_MONSTER(targ) && targ.health < targ.max_health);
	if(targ.items & ITEM_Shield.m_itemid)
		return false;

	switch(this.skin)
	{
		case 0: return (targ.health < autocvar_g_balance_health_regenstable);
		case 1: return ((targ.ammo_cells && targ.ammo_cells < g_pickup_cells_max) || (targ.ammo_plasma && targ.ammo_plasma < g_pickup_plasma_max) || (targ.ammo_rockets && targ.ammo_rockets < g_pickup_rockets_max) || (targ.ammo_nails && targ.ammo_nails < g_pickup_nails_max) || (targ.ammo_shells && targ.ammo_shells < g_pickup_shells_max));
		case 2: return (targ.armorvalue < autocvar_g_balance_armor_regenstable);
		case 3: return (targ.health > 0);
	}

	return false;
}

void M_Mage_Attack_Spike_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;

	sound(this, CH_SHOTS, SND_GRENADE_IMPACT, VOL_BASE, ATTEN_NORM);

	this.realowner.mage_spike = NULL;

	Send_Effect(EFFECT_EXPLOSION_SMALL, this.origin, '0 0 0', 1);
	RadiusDamage (this, this.realowner, (autocvar_g_monster_mage_attack_spike_damage), (autocvar_g_monster_mage_attack_spike_damage) * 0.5, (autocvar_g_monster_mage_attack_spike_radius), NULL, NULL, 0, DEATH_MONSTER_MAGE.m_id, directhitentity);

	delete (this);
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
	if (time > this.ltime || (this.enemy && this.enemy.health <= 0) || this.owner.health <= 0) {
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

	entity missile = spawn();
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
	float washealed = false;

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_monster_mage_heal_range, M_Mage_Defend_Heal_Check(this, it),
	{
		washealed = true;
		string fx = "";
		if(IS_PLAYER(it))
		{
			switch(this.skin)
			{
				case 0:
					if(it.health < autocvar_g_balance_health_regenstable) it.health = bound(0, it.health + (autocvar_g_monster_mage_heal_allies), autocvar_g_balance_health_regenstable);
					fx = EFFECT_HEALING.eent_eff_name;
					break;
				case 1:
					if(it.ammo_cells) it.ammo_cells = bound(it.ammo_cells, it.ammo_cells + 1, g_pickup_cells_max);
					if(it.ammo_plasma) it.ammo_plasma = bound(it.ammo_plasma, it.ammo_plasma + 1, g_pickup_plasma_max);
					if(it.ammo_rockets) it.ammo_rockets = bound(it.ammo_rockets, it.ammo_rockets + 1, g_pickup_rockets_max);
					if(it.ammo_shells) it.ammo_shells = bound(it.ammo_shells, it.ammo_shells + 2, g_pickup_shells_max);
					if(it.ammo_nails) it.ammo_nails = bound(it.ammo_nails, it.ammo_nails + 5, g_pickup_nails_max);
					fx = "ammoregen_fx";
					break;
				case 2:
					if(it.armorvalue < autocvar_g_balance_armor_regenstable)
					{
						it.armorvalue = bound(0, it.armorvalue + (autocvar_g_monster_mage_heal_allies), autocvar_g_balance_armor_regenstable);
						fx = "armorrepair_fx";
					}
					break;
				case 3:
					it.health = bound(0, it.health - ((it == this)  ? (autocvar_g_monster_mage_heal_self) : (autocvar_g_monster_mage_heal_allies)), autocvar_g_balance_health_regenstable);
					fx = EFFECT_RAGE.eent_eff_name;
					break;
			}

			Send_Effect_(fx, it.origin, '0 0 0', 1);
		}
		else
		{
			Send_Effect(EFFECT_HEALING, it.origin, '0 0 0', 1);
			it.health = bound(0, it.health + (autocvar_g_monster_mage_heal_allies), it.max_health);
			if(!(it.spawnflags & MONSTERFLAG_INVINCIBLE) && it.sprite)
				WaypointSprite_UpdateHealth(it.sprite, it.health);
		}
	});

	if(washealed)
	{
		setanim(this, this.anim_shoot, true, true, true);
		this.attack_finished_single[0] = time + (autocvar_g_monster_mage_heal_delay);
		this.anim_finished = time + 1.5;
	}
}

void M_Mage_Attack_Push(entity this)
{
	sound(this, CH_SHOTS, SND_TAGEXP1, 1, ATTEN_NORM);
	RadiusDamage (this, this, (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_radius), NULL, NULL, (autocvar_g_monster_mage_attack_push_force), DEATH_MONSTER_MAGE.m_id, this.enemy);
	Send_Effect(EFFECT_TE_EXPLOSION, this.origin, '0 0 0', 1);

	setanim(this, this.anim_shoot, true, true, true);
	this.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_push_delay);
}

void M_Mage_Attack_Teleport(entity this, entity targ)
{
	if(!targ) return;
	if(vdist(targ.origin - this.origin, >, 1500)) return;

	makevectors(targ.angles);
	tracebox(targ.origin + ((v_forward * -1) * 200), this.mins, this.maxs, this.origin, MOVE_NOMONSTERS, this);

	if(trace_fraction < 1)
		return;

	vector newpos = targ.origin + ((v_forward * -1) * 200);

	Send_Effect(EFFECT_SPAWN_NEUTRAL, this.origin, '0 0 0', 1);
	Send_Effect(EFFECT_SPAWN_NEUTRAL, newpos, '0 0 0', 1);

	setorigin(this, newpos);

	vector a = vectoangles(targ.origin - this.origin);
	a.x = -a.x;
	this.angles_x = a.x;
	this.angles_y = a.y;
	this.fixangle = true;
	this.velocity *= 0.5;

	this.attack_finished_single[0] = time + 0.2;
}

void M_Mage_Defend_Shield_Remove(entity this)
{
	this.effects &= ~(EF_ADDITIVE | EF_BLUE);
	this.armorvalue = autocvar_g_monsters_armor_blockpercent;
}

void M_Mage_Defend_Shield(entity this)
{
	this.effects |= (EF_ADDITIVE | EF_BLUE);
	this.mage_shield_delay = time + (autocvar_g_monster_mage_shield_delay);
	this.armorvalue = (autocvar_g_monster_mage_shield_blockpercent);
	this.mage_shield_time = time + (autocvar_g_monster_mage_shield_time);
	setanim(this, this.anim_shoot, true, true, true);
	this.attack_finished_single[0] = time + 1;
	this.anim_finished = time + 1;
}

bool M_Mage_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() <= 0.7)
			{
				Weapon wep = WEP_MAGE_SPIKE;

				wep.wr_think(wep, actor, weaponentity, 2);
				return true;
			}

			return false;
		}
		case MONSTER_ATTACK_RANGED:
		{
			if(!actor.mage_spike)
			{
				if(random() <= 0.4)
				{
					OffhandWeapon off = OFFHAND_MAGE_TELEPORT;
					off.offhand_think(off, actor, true);
					return true;
				}
				else
				{
					setanim(actor, actor.anim_shoot, true, true, true);
					actor.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_spike_delay);
					actor.anim_finished = time + 1;
					Weapon wep = WEP_MAGE_SPIKE;
					wep.wr_think(wep, actor, weaponentity, 1);
					return true;
				}
			}

			if(actor.mage_spike)
				return true;
			else
				return false;
		}
	}

	return false;
}

spawnfunc(monster_mage) { Monster_Spawn(this, true, MON_MAGE.monsterid); }

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

    if(actor.health < (autocvar_g_monster_mage_heal_minhealth) || need_help)
    if(time >= actor.attack_finished_single[0])
    if(random() < 0.5)
        M_Mage_Defend_Heal(actor);

    if(time >= actor.mage_shield_time && actor.armorvalue)
        M_Mage_Defend_Shield_Remove(actor);

    if(actor.enemy)
    if(actor.health < actor.max_health)
    if(time >= actor.mage_shield_delay)
    if(random() < 0.5)
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
    setanim(actor, actor.anim_die1, false, true, true);
    return true;
}

#endif
#ifdef GAMEQC
METHOD(Mage, mr_anim, bool(Mage this, entity actor))
{
    TC(Mage, this);
    vector none = '0 0 0';
    actor.anim_die1 = animfixfps(actor, '4 1 0.5', none); // 2 seconds
    actor.anim_walk = animfixfps(actor, '1 1 1', none);
    actor.anim_idle = animfixfps(actor, '0 1 1', none);
    actor.anim_pain1 = animfixfps(actor, '3 1 2', none); // 0.5 seconds
    actor.anim_shoot = animfixfps(actor, '2 1 5', none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, '5 1 1', none);
    return true;
}
#endif
#ifdef SVQC
.float speed;
METHOD(Mage, mr_setup, bool(Mage this, entity actor))
{
    TC(Mage, this);
    if(!actor.health) actor.health = (autocvar_g_monster_mage_health);
    if(!actor.speed) { actor.speed = (autocvar_g_monster_mage_speed_walk); }
    if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_mage_speed_run); }
    if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_mage_speed_stop); }
    if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_mage_damageforcescale); }

    actor.monster_loot = ITEM_HealthBig;
    actor.monster_attackfunc = M_Mage_Attack;

    return true;
}

METHOD(Mage, mr_precache, bool(Mage this))
{
    TC(Mage, this);
    return true;
}
#endif
