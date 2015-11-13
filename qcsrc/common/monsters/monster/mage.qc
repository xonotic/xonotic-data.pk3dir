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

#include "../../weapons/all.qh"
#include "../../items/all.qc"

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
void M_Mage_Attack_Spike(vector dir);
void M_Mage_Attack_Push();
METHOD(MageSpike, wr_think, void(MageSpike thiswep, entity actor, .entity weaponentity, int fire)) {
    if (fire & 1)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, false, 0.2)) {
        if (!actor.target_range) actor.target_range = autocvar_g_monsters_target_range;
        actor.enemy = Monster_FindTarget(actor);
        W_SetupShot_Dir(actor, v_forward, false, 0, SND(MageSpike_FIRE), CH_WEAPON_B, 0);
    	if (!IS_PLAYER(actor)) w_shotdir = normalize((actor.enemy.origin + '0 0 10') - actor.origin);
        M_Mage_Attack_Spike(w_shotdir);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
    }
    if (fire & 2)
    if (!IS_PLAYER(actor) || weapon_prepareattack(thiswep, actor, weaponentity, true, 0.5)) {
        M_Mage_Attack_Push();
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}

void M_Mage_Attack_Teleport();

CLASS(OffhandMageTeleport, OffhandWeapon)
    .bool OffhandMageTeleport_key_pressed;
    METHOD(OffhandMageTeleport, offhand_think, void(OffhandMageTeleport this, entity player, bool key_pressed))
    {
        if (key_pressed && !player.OffhandMageTeleport_key_pressed)
            WITH(entity, self, player, M_Mage_Attack_Teleport());
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

void() M_Mage_Defend_Heal;
void() M_Mage_Defend_Shield;

.entity mage_spike;
.float mage_shield_delay;
.float mage_shield_time;

float M_Mage_Defend_Heal_Check(entity e)
{SELFPARAM();
	if(e == world)
		return false;
	if(e.health <= 0)
		return false;
	if(DIFF_TEAM(e, self) && e != self.monster_follow)
		return false;
	if(e.frozen)
		return false;
	if(!IS_PLAYER(e))
		return (IS_MONSTER(e) && e.health < e.max_health);
	if(e.items & ITEM_Shield.m_itemid)
		return false;

	switch(self.skin)
	{
		case 0: return (e.health < autocvar_g_balance_health_regenstable);
		case 1: return ((e.ammo_cells && e.ammo_cells < g_pickup_cells_max) || (e.ammo_plasma && e.ammo_plasma < g_pickup_plasma_max) || (e.ammo_rockets && e.ammo_rockets < g_pickup_rockets_max) || (e.ammo_nails && e.ammo_nails < g_pickup_nails_max) || (e.ammo_shells && e.ammo_shells < g_pickup_shells_max));
		case 2: return (e.armorvalue < autocvar_g_balance_armor_regenstable);
		case 3: return (e.health > 0);
	}

	return false;
}

void M_Mage_Attack_Spike_Explode()
{SELFPARAM();
	self.event_damage = func_null;

	sound(self, CH_SHOTS, SND_GRENADE_IMPACT, VOL_BASE, ATTEN_NORM);

	self.realowner.mage_spike = world;

	Send_Effect(EFFECT_EXPLOSION_SMALL, self.origin, '0 0 0', 1);
	RadiusDamage (self, self.realowner, (autocvar_g_monster_mage_attack_spike_damage), (autocvar_g_monster_mage_attack_spike_damage) * 0.5, (autocvar_g_monster_mage_attack_spike_radius), world, world, 0, DEATH_MONSTER_MAGE.m_id, other);

	remove (self);
}

void M_Mage_Attack_Spike_Touch()
{
	PROJECTILE_TOUCH;

	M_Mage_Attack_Spike_Explode();
}

.float wait;

// copied from W_Seeker_Think
void M_Mage_Attack_Spike_Think()
{SELFPARAM();
	if (time > self.ltime || (self.enemy && self.enemy.health <= 0) || self.owner.health <= 0) {
		self.projectiledeathtype |= HITTYPE_SPLASH;
		M_Mage_Attack_Spike_Explode();
	}

	float spd = vlen(self.velocity);
	spd = bound(
		spd - (autocvar_g_monster_mage_attack_spike_decel) * frametime,
		(autocvar_g_monster_mage_attack_spike_speed_max),
		spd + (autocvar_g_monster_mage_attack_spike_accel) * frametime
	);

	if (self.enemy != world)
		if (self.enemy.takedamage != DAMAGE_AIM || self.enemy.deadflag != DEAD_NO)
			self.enemy = world;

	if (self.enemy != world)
	{
		entity e = self.enemy;
		vector eorg = 0.5 * (e.absmin + e.absmax);
		float turnrate = (autocvar_g_monster_mage_attack_spike_turnrate); // how fast to turn
		vector desireddir = normalize(eorg - self.origin);
		vector olddir = normalize(self.velocity); // get my current direction
		float dist = vlen(eorg - self.origin);

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if ((autocvar_g_monster_mage_attack_spike_smart) && (dist > (autocvar_g_monster_mage_attack_spike_smart_mindist)))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if ( vlen(self.origin + olddir * self.wait) < dist)
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

void M_Mage_Attack_Spike(vector dir)
{
	SELFPARAM();
	makevectors(self.angles);

	entity missile = spawn();
	missile.owner = missile.realowner = self;
	missile.think = M_Mage_Attack_Spike_Think;
	missile.ltime = time + 7;
	missile.nextthink = time;
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.flags = FL_PROJECTILE;
	setorigin(missile, self.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	setsize(missile, '0 0 0', '0 0 0');
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.enemy = self.enemy;
	missile.touch = M_Mage_Attack_Spike_Touch;

	self.mage_spike = missile;

	CSQCProjectile(missile, true, PROJECTILE_MAGE_SPIKE, true);
}

void M_Mage_Defend_Heal()
{SELFPARAM();
	entity head;
	float washealed = false;

	for(head = findradius(self.origin, (autocvar_g_monster_mage_heal_range)); head; head = head.chain) if(M_Mage_Defend_Heal_Check(head))
	{
		washealed = true;
		string fx = "";
		if(IS_PLAYER(head))
		{
			switch(self.skin)
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
					head.health = bound(0, head.health - ((head == self)  ? (autocvar_g_monster_mage_heal_self) : (autocvar_g_monster_mage_heal_allies)), autocvar_g_balance_health_regenstable);
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
		setanim(self, self.anim_shoot, true, true, true);
		self.attack_finished_single[0] = time + (autocvar_g_monster_mage_heal_delay);
		self.anim_finished = time + 1.5;
	}
}

void M_Mage_Attack_Push()
{SELFPARAM();
	sound(self, CH_SHOTS, SND_TAGEXP1, 1, ATTEN_NORM);
	RadiusDamage (self, self, (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_damage), (autocvar_g_monster_mage_attack_push_radius), world, world, (autocvar_g_monster_mage_attack_push_force), DEATH_MONSTER_MAGE.m_id, self.enemy);
	Send_Effect(EFFECT_TE_EXPLOSION, self.origin, '0 0 0', 1);

	setanim(self, self.anim_shoot, true, true, true);
	self.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_push_delay);
}

void M_Mage_Attack_Teleport()
{SELFPARAM();
	entity targ = self.enemy;
	if (!targ) return;
	if (vlen(targ.origin - self.origin) > 1500) return;

	makevectors(targ.angles);
	tracebox(targ.origin + ((v_forward * -1) * 200), self.mins, self.maxs, self.origin, MOVE_NOMONSTERS, self);

	if(trace_fraction < 1)
		return;

	Send_Effect(EFFECT_SPAWN_NEUTRAL, self.origin, '0 0 0', 1);
	setorigin(self, targ.origin + ((v_forward * -1) * 200));

	vector a = vectoangles(targ.origin - self.origin);
	a.x = -a.x;
	self.angles_x = a.x;
	self.angles_y = a.y;
	self.fixangle = true;
	self.velocity *= 0.5;

	self.attack_finished_single[0] = time + 0.2;
}

void M_Mage_Defend_Shield_Remove()
{SELFPARAM();
	self.effects &= ~(EF_ADDITIVE | EF_BLUE);
	self.armorvalue = autocvar_g_monsters_armor_blockpercent;
}

void M_Mage_Defend_Shield()
{SELFPARAM();
	self.effects |= (EF_ADDITIVE | EF_BLUE);
	self.mage_shield_delay = time + (autocvar_g_monster_mage_shield_delay);
	self.armorvalue = (autocvar_g_monster_mage_shield_blockpercent);
	self.mage_shield_time = time + (autocvar_g_monster_mage_shield_time);
	setanim(self, self.anim_shoot, true, true, true);
	self.attack_finished_single[0] = time + 1;
	self.anim_finished = time + 1;
}

float M_Mage_Attack(float attack_type, entity targ)
{SELFPARAM();
    .entity weaponentity = weaponentities[0];
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() <= 0.7)
			{
				Weapon wep = WEP_MAGE_SPIKE;

				wep.wr_think(wep, self, weaponentity, 2);
				return true;
			}

			return false;
		}
		case MONSTER_ATTACK_RANGED:
		{
			if(!self.mage_spike)
			{
				if(random() <= 0.4)
				{
					OffhandWeapon off = OFFHAND_MAGE_TELEPORT;
					off.offhand_think(off, self, true);
					return true;
				}
				else
				{
					setanim(self, self.anim_shoot, true, true, true);
					self.attack_finished_single[0] = time + (autocvar_g_monster_mage_attack_spike_delay);
					self.anim_finished = time + 1;
					Weapon wep = WEP_MAGE_SPIKE;
					wep.wr_think(wep, self, weaponentity, 1);
					return true;
				}
			}

			if(self.mage_spike)
				return true;
			else
				return false;
		}
	}

	return false;
}

spawnfunc(monster_mage) { Monster_Spawn(MON_MAGE.monsterid); }

#endif // SVQC

		#ifdef SVQC
		METHOD(Mage, mr_think, bool(Monster thismon))
		{
			SELFPARAM();
			entity head;
			bool need_help = false;

			for(head = world; (head = findfloat(head, iscreature, true)); )
			if(head != self)
			if(vlen(head.origin - self.origin) <= (autocvar_g_monster_mage_heal_range))
			if(M_Mage_Defend_Heal_Check(head))
			{
				need_help = true;
				break;
			}

			if(self.health < (autocvar_g_monster_mage_heal_minhealth) || need_help)
			if(time >= self.attack_finished_single[0])
			if(random() < 0.5)
				M_Mage_Defend_Heal();

			if(time >= self.mage_shield_time && self.armorvalue)
				M_Mage_Defend_Shield_Remove();

			if(self.enemy)
			if(self.health < self.max_health)
			if(time >= self.mage_shield_delay)
			if(random() < 0.5)
				M_Mage_Defend_Shield();

			return true;
		}
		METHOD(Mage, mr_pain, bool(Monster thismon))
		{
			return true;
		}
		METHOD(Mage, mr_death, bool(Monster thismon))
		{
			SELFPARAM();
			setanim(self, self.anim_die1, false, true, true);
			return true;
		}
		#endif
		#ifndef MENUQC
		METHOD(Mage, mr_anim, bool(Monster thismon))
		{
			SELFPARAM();
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '4 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '1 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_pain1 = animfixfps(self, '3 1 2', none); // 0.5 seconds
			self.anim_shoot = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '5 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		.float speed;
		spawnfunc(item_health_large);
		METHOD(Mage, mr_setup, bool(Monster thismon))
		{
			SELFPARAM();
			if(!self.health) self.health = (autocvar_g_monster_mage_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_mage_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_mage_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_mage_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_mage_damageforcescale); }

			self.monster_loot = spawnfunc_item_health_large;
			self.monster_attackfunc = M_Mage_Attack;

			return true;
		}
		METHOD(Mage, mr_precache, bool(Monster thismon))
		{
			return true;
		}
		#endif

#endif
