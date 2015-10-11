#ifndef WYVERN_H
#define WYVERN_H

#ifndef MENUQC
MODEL(MON_WYVERN, "models/monsters/wizard.mdl");
#endif

CLASS(Wyvern, Monster)
    ATTRIB(Wyvern, spawnflags, int, MONSTER_TYPE_FLY | MONSTER_SIZE_BROKEN | MON_FLAG_RANGED | MON_FLAG_RIDE);
    ATTRIB(Wyvern, mins, vector, '-20 -20 -58');
    ATTRIB(Wyvern, maxs, vector, '20 20 20');
#ifndef MENUQC
    ATTRIB(Wyvern, m_model, Model, MDL_MON_WYVERN);
#endif
    ATTRIB(Wyvern, netname, string, "wyvern");
    ATTRIB(Wyvern, monster_name, string, _("Wyvern"));
ENDCLASS(Wyvern)

REGISTER_MONSTER(WYVERN, NEW(Wyvern)) {
#ifndef MENUQC
    this.mr_precache(this);
#endif
}

#include "../../weapons/all.qh"

CLASS(WyvernAttack, PortoLaunch)
/* flags     */ ATTRIB(WyvernAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(WyvernAttack, impulse, int, 9);
/* refname   */ ATTRIB(WyvernAttack, netname, string, "wyvern");
/* wepname   */ ATTRIB(WyvernAttack, message, string, _("Wyvern attack"));
ENDCLASS(WyvernAttack)
REGISTER_WEAPON(WYVERN_ATTACK, NEW(WyvernAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_monster_wyvern_attack_fireball_damage;
float autocvar_g_monster_wyvern_attack_fireball_edgedamage;
float autocvar_g_monster_wyvern_attack_fireball_damagetime;
float autocvar_g_monster_wyvern_attack_fireball_force;
float autocvar_g_monster_wyvern_attack_fireball_radius;
float autocvar_g_monster_wyvern_attack_fireball_speed;

void M_Wyvern_Attack_Fireball_Explode();
void M_Wyvern_Attack_Fireball_Touch();

METHOD(WyvernAttack, wr_think, void(WyvernAttack thiswep, entity actor, bool fire1, bool fire2)) {
    if (fire1)
    if (time > actor.attack_finished_single || weapon_prepareattack(thiswep, actor, false, 1.2)) {
        if (IS_PLAYER(actor)) W_SetupShot_Dir(actor, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
		if (IS_MONSTER(actor)) {
			actor.attack_finished_single = time + 1.2;
			actor.anim_finished = time + 1.2;
			monster_makevectors(actor.enemy);
		}

		entity missile = spawn();
		missile.owner = missile.realowner = actor;
		missile.solid = SOLID_TRIGGER;
		missile.movetype = MOVETYPE_FLYMISSILE;
		missile.projectiledeathtype = DEATH_MONSTER_WYVERN.m_id;
		setsize(missile, '-6 -6 -6', '6 6 6');
		setorigin(missile, actor.origin + actor.view_ofs + v_forward * 14);
		missile.flags = FL_PROJECTILE;
		missile.velocity = w_shotdir * (autocvar_g_monster_wyvern_attack_fireball_speed);
		missile.avelocity = '300 300 300';
		missile.nextthink = time + 5;
		missile.think = M_Wyvern_Attack_Fireball_Explode;
		missile.touch = M_Wyvern_Attack_Fireball_Touch;
		CSQCProjectile(missile, true, PROJECTILE_FIREMINE, true);

        weapon_thinkf(actor, WFRAME_FIRE1, 0, w_ready);
    }
}

METHOD(WyvernAttack, wr_checkammo1, bool(WyvernAttack thiswep)) {
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

void M_Wyvern_Attack_Fireball_Explode()
{
	SELFPARAM();
	Send_Effect(EFFECT_FIREBALL_EXPLODE, self.origin, '0 0 0', 1);

	entity owner = self.realowner;

	RadiusDamage(self, owner, autocvar_g_monster_wyvern_attack_fireball_damage, autocvar_g_monster_wyvern_attack_fireball_edgedamage, autocvar_g_monster_wyvern_attack_fireball_force, world, world, autocvar_g_monster_wyvern_attack_fireball_radius, self.projectiledeathtype, world);

	for (entity e = world; (e = findfloat(e, takedamage, DAMAGE_AIM)); )
	if (vlen(e.origin - self.origin) <= (autocvar_g_monster_wyvern_attack_fireball_radius))
		Fire_AddDamage(e, owner, 5 * MONSTER_SKILLMOD(owner), (autocvar_g_monster_wyvern_attack_fireball_damagetime), self.projectiledeathtype);

	remove(self);
}

void M_Wyvern_Attack_Fireball_Touch()
{
	PROJECTILE_TOUCH;

	M_Wyvern_Attack_Fireball_Explode();
}

float M_Wyvern_Attack(float attack_type, entity targ)
{
	SELFPARAM();
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			w_shotdir = normalize((self.enemy.origin + '0 0 10') - self.origin);
			Weapon wep = WEP_WYVERN_ATTACK;
			wep.wr_think(wep, self, true, false);
			return true;
		}
	}

	return false;
}

spawnfunc(monster_wyvern) { Monster_Spawn(MON_WYVERN.monsterid); }
#endif // SVQC

		#ifdef SVQC
		METHOD(Wyvern, mr_think, bool(Wyvern thismon))
		{
			return true;
		}
		METHOD(Wyvern, mr_pain, bool(Wyvern thismon))
		{
			SELFPARAM();
			self.pain_finished = time + 0.5;
			setanim(self, self.anim_pain1, true, true, false);
			return true;
		}
		METHOD(Wyvern, mr_death, bool(Wyvern thismon))
		{
			SELFPARAM();
			setanim(self, self.anim_die1, false, true, true);
			self.velocity_x = -200 + 400 * random();
			self.velocity_y = -200 + 400 * random();
			self.velocity_z = 100 + 100 * random();
			return true;
		}
		#endif
		#ifndef MENUQC
		METHOD(Wyvern, mr_anim, bool(Wyvern thismon))
		{
			SELFPARAM();
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '4 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '1 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_pain1 = animfixfps(self, '3 1 2', none); // 0.5 seconds
			self.anim_shoot = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '1 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		spawnfunc(item_cells);
		METHOD(Wyvern, mr_setup, bool(Wyvern thismon))
		{
			SELFPARAM();
			if(!self.health) self.health = (autocvar_g_monster_wyvern_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_wyvern_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_wyvern_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_wyvern_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_wyvern_damageforcescale); }

			self.monster_loot = spawnfunc_item_cells;
			self.monster_attackfunc = M_Wyvern_Attack;

			return true;
		}
		METHOD(Wyvern, mr_precache, bool(Wyvern thismon))
		{
			return true;
		}
		#endif

#endif
