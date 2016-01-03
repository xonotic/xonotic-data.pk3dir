#ifndef SHAMBLER_H
#define SHAMBLER_H

#ifndef MENUQC
MODEL(MON_SHAMBLER, M_Model("shambler.mdl"));
#endif

CLASS(Shambler, Monster)
    ATTRIB(Shambler, spawnflags, int, MONSTER_SIZE_BROKEN | MON_FLAG_SUPERMONSTER | MON_FLAG_MELEE | MON_FLAG_RANGED);
    ATTRIB(Shambler, mins, vector, '-41 -41 -31');
    ATTRIB(Shambler, maxs, vector, '41 41 65');
#ifndef MENUQC
    ATTRIB(Shambler, m_model, Model, MDL_MON_SHAMBLER);
#endif
    ATTRIB(Shambler, netname, string, "shambler");
    ATTRIB(Shambler, monster_name, string, _("Shambler"));
ENDCLASS(Shambler)

REGISTER_MONSTER(SHAMBLER, NEW(Shambler)) {
#ifndef MENUQC
    this.mr_precache(this);
#endif
}

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC
float autocvar_g_monster_shambler_health;
float autocvar_g_monster_shambler_damageforcescale = 0.1;
float autocvar_g_monster_shambler_attack_smash_damage;
float autocvar_g_monster_shambler_attack_smash_range;
float autocvar_g_monster_shambler_attack_claw_damage;
float autocvar_g_monster_shambler_attack_lightning_damage;
float autocvar_g_monster_shambler_attack_lightning_damage_zap = 15;
float autocvar_g_monster_shambler_attack_lightning_force;
float autocvar_g_monster_shambler_attack_lightning_radius;
float autocvar_g_monster_shambler_attack_lightning_radius_zap;
float autocvar_g_monster_shambler_attack_lightning_speed;
float autocvar_g_monster_shambler_attack_lightning_speed_up;
float autocvar_g_monster_shambler_speed_stop;
float autocvar_g_monster_shambler_speed_run;
float autocvar_g_monster_shambler_speed_walk;

/*
const float shambler_anim_stand		= 0;
const float shambler_anim_walk		= 1;
const float shambler_anim_run		= 2;
const float shambler_anim_smash		= 3;
const float shambler_anim_swingr	= 4;
const float shambler_anim_swingl	= 5;
const float shambler_anim_magic		= 6;
const float shambler_anim_pain		= 7;
const float shambler_anim_death		= 8;
*/

.float shambler_lastattack; // delay attacks separately

void M_Shambler_Attack_Smash(entity this)
{
	makevectors(this.angles);
	Send_Effect(EFFECT_EXPLOSION_MEDIUM, (this.origin + (v_forward * 150)) - ('0 0 1' * this.maxs.z), '0 0 0', 1);
	sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

	// RadiusDamage does NOT support custom starting location, which means we must use this hack...

	tracebox(this.origin + v_forward * 50, this.mins * 0.5, this.maxs * 0.5, this.origin + v_forward * autocvar_g_monster_shambler_attack_smash_range, MOVE_NORMAL, this);

	if(trace_ent.takedamage)
		Damage(trace_ent, this, this, (autocvar_g_monster_shambler_attack_smash_damage) * MONSTER_SKILLMOD(this), DEATH_MONSTER_SHAMBLER_SMASH.m_id, trace_ent.origin, normalize(trace_ent.origin - this.origin));
}

void M_Shambler_Attack_Swing(entity this)
{
	Monster_Attack_Melee(this, this.enemy, (autocvar_g_monster_shambler_attack_claw_damage), ((random() >= 0.5) ? this.anim_melee2 : this.anim_melee3), this.attack_range, 0.8, DEATH_MONSTER_SHAMBLER_CLAW.m_id, true);
}

#include <common/effects/qc/all.qh>

void M_Shambler_Attack_Lightning_Explode()
{SELFPARAM();
	entity head;

	sound(self, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_ELECTRO_IMPACT, self.origin, '0 0 0', 1);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.realowner, (autocvar_g_monster_shambler_attack_lightning_damage), (autocvar_g_monster_shambler_attack_lightning_damage), (autocvar_g_monster_shambler_attack_lightning_radius), world, world, (autocvar_g_monster_shambler_attack_lightning_force), self.projectiledeathtype, other);

	for(head = findradius(self.origin, (autocvar_g_monster_shambler_attack_lightning_radius_zap)); head; head = head.chain) if(head != self.realowner) if(head.takedamage)
	{
		te_csqc_lightningarc(self.origin, head.origin);
		Damage(head, self, self.realowner, (autocvar_g_monster_shambler_attack_lightning_damage_zap) * MONSTER_SKILLMOD(self), DEATH_MONSTER_SHAMBLER_ZAP.m_id, head.origin, '0 0 0');
	}

	self.think = SUB_Remove_self;
	self.nextthink = time + 0.2;
}

void M_Shambler_Attack_Lightning_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if (self.health <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;

	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.use);
}

void M_Shambler_Attack_Lightning_Touch()
{SELFPARAM();
	PROJECTILE_TOUCH;

	self.use ();
}

void M_Shambler_Attack_Lightning_Think()
{SELFPARAM();
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		M_Shambler_Attack_Lightning_Explode();
		return;
	}
}

void M_Shambler_Attack_Lightning(entity this)
{
	entity gren;

	monster_makevectors(this, this.enemy);

	gren = new(grenade);
	gren.owner = gren.realowner = this;
	gren.bot_dodge = true;
	gren.bot_dodgerating = (autocvar_g_monster_shambler_attack_lightning_damage);
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = DEATH_MONSTER_SHAMBLER_ZAP.m_id;
	setorigin(gren, CENTER_OR_VIEWOFS(this));
	setsize(gren, '-8 -8 -8', '8 8 8');
	gren.scale = 2.5;

	gren.cnt = time + 5;
	gren.nextthink = time;
	gren.think = M_Shambler_Attack_Lightning_Think;
	gren.use = M_Shambler_Attack_Lightning_Explode;
	gren.touch = M_Shambler_Attack_Lightning_Touch;

	gren.takedamage = DAMAGE_YES;
	gren.health = 50;
	gren.damageforcescale = 0;
	gren.event_damage = M_Shambler_Attack_Lightning_Damage;
	gren.damagedbycontents = true;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_Explicit(gren, v_forward, v_up, (autocvar_g_monster_shambler_attack_lightning_speed), (autocvar_g_monster_shambler_attack_lightning_speed_up), 0, 0, false);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, true, PROJECTILE_SHAMBLER_LIGHTNING, true);
}

.int state;

bool M_Shambler_Attack(int attack_type, entity actor, entity targ)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			int swing_cnt = bound(1, floor(random() * 4), 3);
			Monster_Delay(actor, swing_cnt, 0.5, M_Shambler_Attack_Swing);
			actor.anim_finished = actor.attack_finished_single[0] = time + (0.5 * swing_cnt); // set this for the delay
			return true;
		}
		case MONSTER_ATTACK_RANGED:
		{
			float randomness = random(), enemy_len = vlen(actor.enemy.origin - actor.origin);

			if(time >= actor.shambler_lastattack) // shambler doesn't attack much
			if(IS_ONGROUND(actor))
			if(randomness <= 0.5 && enemy_len <= autocvar_g_monster_shambler_attack_smash_range)
			{
				setanim(actor, actor.anim_melee2, true, true, false);
				Monster_Delay(actor, 1, 0.7, M_Shambler_Attack_Smash);
				actor.attack_finished_single[0] = time + 1.1;
				actor.anim_finished = time + 1.1;
				actor.state = MONSTER_ATTACK_MELEE; // kinda a melee attack
				actor.shambler_lastattack = time + 3 + random() * 1.5;
				return true;
			}
			else if(randomness <= 0.1 && enemy_len >= autocvar_g_monster_shambler_attack_smash_range * 1.5) // small chance, don't want this spammed
			{
				setanim(actor, actor.anim_shoot, true, true, false);
				actor.state = MONSTER_ATTACK_MELEE; // maybe we should rename this to something more general
				actor.attack_finished_single[0] = time + 1.1;
				actor.anim_finished = 1.1;
				actor.shambler_lastattack = time + 3 + random() * 1.5;
				Monster_Delay(actor, 1, 0.6, M_Shambler_Attack_Lightning);
				return true;
			}

			return false;
		}
	}

	return false;
}

spawnfunc(monster_shambler) { Monster_Spawn(this, MON_SHAMBLER.monsterid); }
#endif // SVQC

		#ifdef SVQC
		METHOD(Shambler, mr_think, bool(Shambler thismon, entity actor))
		{
			return true;
		}
		METHOD(Shambler, mr_pain, bool(Shambler thismon, entity actor))
		{
			actor.pain_finished = time + 0.5;
			setanim(actor, actor.anim_pain1, true, true, false);
			return true;
		}
		METHOD(Shambler, mr_death, bool(Shambler thismon, entity actor))
		{
			setanim(actor, actor.anim_die1, false, true, true);
			return true;
		}
		#endif
		#ifndef MENUQC
		METHOD(Shambler, mr_anim, bool(Shambler thismon, entity actor))
		{
			vector none = '0 0 0';
			actor.anim_die1 = animfixfps(actor, '8 1 0.5', none); // 2 seconds
			actor.anim_walk = animfixfps(actor, '1 1 1', none);
			actor.anim_idle = animfixfps(actor, '0 1 1', none);
			actor.anim_pain1 = animfixfps(actor, '7 1 2', none); // 0.5 seconds
			actor.anim_melee1 = animfixfps(actor, '3 1 5', none); // analyze models and set framerate
			actor.anim_melee2 = animfixfps(actor, '4 1 5', none); // analyze models and set framerate
			actor.anim_melee3 = animfixfps(actor, '5 1 5', none); // analyze models and set framerate
			actor.anim_shoot = animfixfps(actor, '6 1 5', none); // analyze models and set framerate
			actor.anim_run = animfixfps(actor, '2 1 1', none);
			return true;
		}
		#endif
		#ifdef SVQC
		spawnfunc(item_health_mega);
		.float animstate_endtime;
		METHOD(Shambler, mr_setup, bool(Shambler thismon, entity actor))
		{
			if(!actor.health) actor.health = (autocvar_g_monster_shambler_health);
			if(!actor.attack_range) actor.attack_range = 150;
			if(!actor.speed) { actor.speed = (autocvar_g_monster_shambler_speed_walk); }
			if(!actor.speed2) { actor.speed2 = (autocvar_g_monster_shambler_speed_run); }
			if(!actor.stopspeed) { actor.stopspeed = (autocvar_g_monster_shambler_speed_stop); }
			if(!actor.damageforcescale) { actor.damageforcescale = (autocvar_g_monster_shambler_damageforcescale); }

			actor.monster_loot = spawnfunc_item_health_mega;
			actor.weapon = WEP_ELECTRO.m_id; // matches attacks better than WEP_VORTEX

			setanim(actor, actor.anim_shoot, false, true, true);
			actor.spawn_time = actor.animstate_endtime;
			actor.spawnshieldtime = actor.spawn_time;
			actor.monster_attackfunc = M_Shambler_Attack;

			return true;
		}
		METHOD(Shambler, mr_precache, bool(Shambler thismon))
		{
			return true;
		}
		#endif

#endif
