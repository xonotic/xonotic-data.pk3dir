#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ SPAWN,
/* functions  */ M_Spawn, M_Spawn_Attack,
/* spawnflags */ MON_FLAG_MELEE | MONSTER_SIZE_BROKEN,
/* mins,maxs  */ '-16 -16 -24', '16 16 16',
/* model      */ "tarbaby.mdl",
/* netname    */ "spawn",
/* fullname   */ _("Spawn")
);

#else
#ifdef SVQC
#include "../../effects.qh"

float autocvar_g_monster_spawn_health;
float autocvar_g_monster_spawn_damageforcescale = 0.6;
float autocvar_g_monster_spawn_attack_explode_damage;
float autocvar_g_monster_spawn_attack_explode_edgedamage;
float autocvar_g_monster_spawn_attack_explode_radius;
float autocvar_g_monster_spawn_attack_explode_force;
float autocvar_g_monster_spawn_attack_leap_speed;
float autocvar_g_monster_spawn_attack_leap_delay;
float autocvar_g_monster_spawn_speed_stop;
float autocvar_g_monster_spawn_speed_run;
float autocvar_g_monster_spawn_speed_walk;

/*
const float spawn_anim_walk 	= 0;
const float spawn_anim_run  	= 1;
const float spawn_anim_jump 	= 2;
const float spawn_anim_fly  	= 3;
const float spawn_anim_explode 	= 4;
*/

void M_Spawn_Attack_Explode()
{
	Send_Effect(EFFECT_GRENADE_EXPLODE, self.origin, '0 0 0', 1);
	sound(self, CH_SHOTS, W_Sound("rocket_impact"), VOL_BASE, ATTEN_NORM);

	RadiusDamage (self, self, (autocvar_g_monster_spawn_attack_explode_damage), (autocvar_g_monster_spawn_attack_explode_edgedamage), (autocvar_g_monster_spawn_attack_explode_radius), world, world, (autocvar_g_monster_spawn_attack_explode_force), DEATH_MONSTER_CREEPER, other);

	self.think = SUB_Remove;
	self.nextthink = time + 0.1;
}

void M_Spawn_Attack_Leap_Touch()
{
	if(self.health <= 0) { return; }

	if(other.takedamage)
	if(vlen(self.velocity) > 200)
	{
		Damage (self, world, world, self.health + self.max_health + 200, DEATH_KILL, self.origin, '0 0 0');
		self.touch = Monster_Touch; // instantly turn it off to stop damage spam
	}

	if (trace_dphitcontents)
	{
		self.movetype = MOVETYPE_WALK;
		self.touch = Monster_Touch;
	}
}

float M_Spawn_Attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(self.angles);
			float leap_success = Monster_Attack_Leap(self.anim_melee, M_Spawn_Attack_Leap_Touch, v_forward * (autocvar_g_monster_spawn_attack_leap_speed) + '0 0 200', (autocvar_g_monster_spawn_attack_leap_delay));
			if(leap_success)
			{
				self.movetype = MOVETYPE_BOUNCE;
				self.velocity_z += random() * 150;
			}
			return leap_success;
		}
	}

	return false;
}

void spawnfunc_monster_spawn() { Monster_Spawn(MON_SPAWN); }

float M_Spawn(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			// prevent standard code from breaking everything
			if(self.flags & FL_ONGROUND)
			if(self.movetype == MOVETYPE_BOUNCE)
			if(time >= self.attack_finished_single)
				self.movetype = MOVETYPE_WALK;
			return true;
		}
		case MR_PAIN:
		{
			return true;
		}
		case MR_DEATH:
		{
			// KABOOM!
			self.frame = 0;
			defer(0.05, M_Spawn_Attack_Explode); // simply defer to prevent recursion
			return true;
		}
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '4 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '0 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_melee = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '1 1 1', none);

			return true;
		}
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_spawn_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_spawn_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_spawn_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_spawn_speed_stop); }
			if(!self.attack_range) { self.attack_range = autocvar_g_monsters_target_range * 0.8; } // bounce from almost any distance
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_spawn_damageforcescale); }

			self.monster_loot = spawnfunc_item_rockets;

			return true;
		}
		case MR_PRECACHE:
		{
			return true;
		}
	}

	return true;
}

#endif // SVQC
#endif // REGISTER_MONSTER
