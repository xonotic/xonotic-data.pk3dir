#ifndef MAGE_H
#define MAGE_H

#ifndef MENUQC
MODEL(MON_MAGE, M_Model("mage.dpm"));
#endif

CLASS(Mage, Monster)
    ATTRIB(Mage, spawnflags, int, MON_FLAG_MELEE | MON_FLAG_RANGED);
    ATTRIB(Mage, mins, vector, '-36 -36 -24');
    ATTRIB(Mage, maxs, vector, '36 36 50');
#ifndef MENUQC
    ATTRIB(Mage, m_model, Model, MDL_MON_MAGE);
#endif
    ATTRIB(Mage, netname, string, "mage");
    ATTRIB(Mage, monster_name, string, _("Mage"));
ENDCLASS(Mage)

REGISTER_MONSTER(MAGE, NEW(Mage)) {
#ifndef MENUQC
    this.mr_precache(this);
#endif
}

#include <common/weapons/all.qh>
#include <common/items/all.qc>

CLASS(MageSpike, PortoLaunch)
/* flags     */ ATTRIB(MageSpike, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(MageSpike, impulse, int, 9);
/* refname   */ ATTRIB(MageSpike, netname, string, "magespike");
/* wepname   */ ATTRIB(MageSpike, m_name, string, _("Mage spike"));
ENDCLASS(MageSpike)
REGISTER_WEAPON(MAGE_SPIKE, NEW(MageSpike));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

SOUND(MageSpike_FIRE, W_Sound("electro_fire"));
void M_Mage_Attack_Spike(entity this, vector dir);
void M_Mage_Attack_Push(entity this);
METHOD(MageSpike, wr_think, void(MageSpike thiswep, entity actor, .entity weaponentity, int fire)) {
    if (fire & 1)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, false, 0.2)) {
        if (!actor.target_range) actor.target_range = autocvar_g_monsters_target_range;
        actor.enemy = Monster_FindTarget(actor);
        W_SetupShot_Dir(actor, v_forward, false, 0, SND(MageSpike_FIRE), CH_WEAPON_B, 0);
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
	if(targ == world)
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

void M_Mage_Attack_Spike_Explode(entity this)
{
	this.event_damage = func_null;

	sound(this, CH_SHOTS, SND_GRENADE_IMPACT, VOL_BASE, ATTEN_NORM);

	this.realowner.mage_spike = world;

	Send_Effect(EFFECT_EXPLOSION_SMALL, this.origin, '0 0 0', 1);
	RadiusDamage (this, this.realowner, (autocvar_g_monster_mage_attack_spike_damage), (autocvar_g_monster_mage_attack_spike_damage) * 0.5, (autocvar_g_monster_mage_attack_spike_radius), world, world, 0, DEATH_MONSTER_MAGE.m_id, other);

	remove (this);
}

void M_Mage_Attack_Spike_Touch()
{
	PROJECTILE_TOUCH;

	M_Mage_Attack_Spike_Explode(self);
}

.float wait;

// copied from W_Seeker_Think
void M_Mage_Attack_Spike_Think()
{SELFPARAM();
	if (time > self.ltime || (self.enemy && self.enemy.health <= 0) || self.owner.health <= 0) {
		self.projectiledeathtype |= HITTYPE_SPLASH;
		M_Mage_Attack_Spike_Explode(self);
	}

	float spd = vlen(self.velocity);
	spd = bound(
		spd - (autocvar_g_monster_mage_attack_spike_decel) * frametime,
		(autocvar_g_monster_mage_attack_spike_speed_max),
		spd + (autocvar_g_monster_mage_attack_spike_accel) * frametime
	);

	if (self.enemy != world)
		if (self.enemy.takedamage != DAMAGE_AIM || IS_DEAD(self.enemy))
			self.enemy = world;

	if (self.enemy != world)
	{
		entity e = self.enemy;
		vector eorg = 0.5 * (e.absmin + e.absmax);
		float turnrate = (autocvar_g_monster_mage_attack_spike_turnrate); // how fast to turn
		vector desireddir = normalize(eorg - self.origin);
		vector olddir = normalize(self.velocity); // get my current direction

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if ((autocvar_g_monster_mage_attack_spike_smart) && vdist(eorg - self.origin, >, autocvar_g_monster_mage_attack_spike_smart_mindist))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if ( vlen2(self.origin + olddir * self.wait) < vlen2(eorg - self.origin))
				traceline(self.origin, self.origin + olddir * self.wait, false, self);
			else
				traceline(self.origin, eorg, false, self);

			// Setup adaptive tracelength
			self.wait = bound((autocvar_g_monster_mage_attack_spike_smart_trace_min), vlen(self.origin - trace_endpos), self.wait = (autocvar_g_monster_mage_attack_spike_smart_trace_max));

			// Calc how important it is that we turn and add this to the desierd (enemy) dir.
			desireddir = normalize(((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction)) * 0.5);
		}

		vector newdir = normalize(olddir + desireddir * turnrate); // take the average of the 2 directions; not the best method but simple & easy
		self.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	}

	///////////////

	//self.angles = vectoangles(self.velocity);			// turn model in the new flight direction
	self.nextthink = time;// + 0.05; // csqc projectiles
	UpdateCSQCProjectile(self);
}

void M_Mage_Attack_Spike(entity this, vector dir)
{
	makevectors(this.angles);

	entity missile = spawn();
	missile.owner = missile.realowner = this;
	missile.think = M_Mage_Attack_Spike_Think;
	missile.ltime = time + 7;
	missile.nextthink = time;
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.flags = FL_PROJECTILE;
	setorigin(missile, this.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	setsize(missile, '0 0 0', '0 0 0');
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.enemy = this.enemy;
	missile.touch = M_Mage_Attack_Spike_Touch;

	this.mage_spike = missile;

	CSQCProjectile(missile, true, PROJECTILE_MAGE_SPIKE, true);
}

void M_Mage_Defend_Heal(entity this)
{
	entity head;
	float washealed = false;

	for(head = findradius(this.origin, (autocvar_g_monster_mage_heal_range)); head; head = head.chain) if(M_Mage_Defend_Heal_Check(this, head))
	{
		washealed = true;
		string fx = "";
		if(IS_PLAYER(head))
		{
			switch(this.skin)
			{
				case 0:
					if(head.health < autocvar_g_balance_health_regenstable) head.health = bound(0, head.health + (autocvar_g_monster_mage_heal_allies), autocvar_g_balance_health_regenstable);
					fx = EFFECT_HEALING.eent_eff_name;
					break;
				case 1:
					if(head.ammo_cells) head.ammo_cells = bound(head.ammo_cells, head.ammo_cells + 1, g_pickup_cells_max);
					if(head.ammo_plasma) head.ammo_plasma = bound(head.ammo_plasma, head.ammo_plasma + 1, g_pickup_plasma_max);
					if(head.ammo_rockets) head.ammo_rockets = bound(head.ammo_rockets, head.ammo_rockets + 1, g_pickup_rockets_max);
					if(head.ammo_shells) head.ammo_shells = bound(head.ammo_shells, head.ammo_shells + 2, g_pickup_shells_max);
					if(head.ammo_nails) head.ammo_nails = bound(head.ammo_nails, head.ammo_nails + 5, g_pickup_nails_max);
					fx = "ammoregen_fx";
					break;
				case 2:
					if(head.armorvalue < autocvar_g_balance_armor_regenstable)
					{
						head.armorvalue = bound(0, head.armorvalue + (autocvar_g_monster_mage_heal_allies), autocvar_g_balance_armor_regenstable);
						fx = "armorrepair_fx";
					}
					break;
				case 3:
					head.health = bound(0, head.health - ((head == this)  ? (autocvar_g_monster_mage_heal_self) : (autocvar_g_monster_mage_heal_allies)), autocvar_g_balance_health_regenstable);
					fx = EFFECT_RAGE.eent_eff_name;
					break;
			}

			Send_Effect_(fx, head.origin, '0 0 0', 1);
		}
		else
		{
			Send_Effect(EFFECT_HEALING, head.origin, '0 0 0', 1);
			head.health = bound(0, head.health + (autocvar_g_monster_mage_heal_allies), head.max_health);
			if(!(head.spawnflags & MONSTERFLAG_INVINCIBLE) && head.sprite)
				WaypointSprite_UpdateHealth(head.sprite, head.health);
		}
	}

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
	RadiusDamage (this, this, (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_radius), world, world, (autocvar_g_monster_mage_attack_push_force), DEATH_MONSTER_MAGE.m_id, this.enemy);
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

bool M_Mage_Attack(int attack_type, entity actor, entity targ)
{
    .entity weaponentity = weaponentities[0];
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

spawnfunc(monster_mage) { Monster_Spawn(this, MON_MAGE.monsterid); }

#endif // SVQC

		#ifdef SVQC
		METHOD(Mage, mr_think, bool(Mage thismon, entity actor))
		{
			bool need_help = false;

			FOREACH_ENTITY_FLOAT(iscreature, true,
			{
				if(it != actor)
				if(vdist(it.origin - actor.origin, <=, autocvar_g_monster_mage_heal_range))
				if(M_Mage_Defend_Heal_Check(actor, it))
				{
					need_help = true;
					break;
				}
			});

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
		METHOD(Mage, mr_pain, bool(Mage thismon, entity actor))
		{
			return true;
		}
		METHOD(Mage, mr_death, bool(Mage thismon, entity actor))
		{
			setanim(actor, actor.anim_die1, false, true, true);
			return true;
		}
		#endif
		#ifndef MENUQC
		METHOD(Mage, mr_anim, bool(Mage thismon, entity actor))
		{
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
		spawnfunc(item_health_large);
		METHOD(Mage, mr_setup, bool(Mage thismon, entity actor))
		{
			if(!actor.health) actor.health = (autocvar_g_monster_mage_health);
			if(!actor.speed) { actor.speed = (autocvar_g_monster_mage_speed_walk); }
			if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_mage_speed_run); }
			if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_mage_speed_stop); }
			if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_mage_damageforcescale); }

			actor.monster_loot = spawnfunc_item_health_large;
			actor.monster_attackfunc = M_Mage_Attack;

			return true;
		}
		METHOD(Mage, mr_precache, bool(Mage thismon))
		{
			return true;
		}
		#endif

#endif
