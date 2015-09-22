#ifndef MENUQC
bool M_Wyvern(int);
#endif
REGISTER_MONSTER_SIMPLE(
/* MON_##id   */ WYVERN,
/* spawnflags */ MONSTER_TYPE_FLY | MONSTER_SIZE_BROKEN | MON_FLAG_RANGED | MON_FLAG_RIDE,
/* mins,maxs  */ '-20 -20 -58', '20 20 20',
/* model      */ "wizard.mdl",
/* netname    */ "wyvern",
/* fullname   */ _("Wyvern")
) {
#ifndef MENUQC
	this.monster_func = M_Wyvern;
	this.monster_func(MR_PRECACHE);
#endif
}

#ifdef SVQC
float autocvar_g_monster_wyvern_health;
float autocvar_g_monster_wyvern_damageforcescale = 0.6;
float autocvar_g_monster_wyvern_attack_fireball_damage;
float autocvar_g_monster_wyvern_attack_fireball_edgedamage;
float autocvar_g_monster_wyvern_attack_fireball_damagetime;
float autocvar_g_monster_wyvern_attack_fireball_force;
float autocvar_g_monster_wyvern_attack_fireball_radius;
float autocvar_g_monster_wyvern_attack_fireball_speed;
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
{SELFPARAM();
	entity e;
	if(self)
	{
		Send_Effect(EFFECT_FIREBALL_EXPLODE, self.origin, '0 0 0', 1);

		RadiusDamage(self, self.realowner, (autocvar_g_monster_wyvern_attack_fireball_damage), (autocvar_g_monster_wyvern_attack_fireball_edgedamage), (autocvar_g_monster_wyvern_attack_fireball_force), world, world, (autocvar_g_monster_wyvern_attack_fireball_radius), self.projectiledeathtype, world);

		for(e = world; (e = findfloat(e, takedamage, DAMAGE_AIM)); ) if(vlen(e.origin - self.origin) <= (autocvar_g_monster_wyvern_attack_fireball_radius))
			Fire_AddDamage(e, self, 5 * MONSTER_SKILLMOD(self), (autocvar_g_monster_wyvern_attack_fireball_damagetime), self.projectiledeathtype);

		remove(self);
	}
}

void M_Wyvern_Attack_Fireball_Touch()
{
	PROJECTILE_TOUCH;

	M_Wyvern_Attack_Fireball_Explode();
}

void M_Wyvern_Attack_Fireball()
{SELFPARAM();
	entity missile = spawn();
	vector dir = normalize((self.enemy.origin + '0 0 10') - self.origin);

	monster_makevectors(self.enemy);

	missile.owner = missile.realowner = self;
	missile.solid = SOLID_TRIGGER;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.projectiledeathtype = DEATH_MONSTER_WYVERN;
	setsize(missile, '-6 -6 -6', '6 6 6');
	setorigin(missile, self.origin + self.view_ofs + v_forward * 14);
	missile.flags = FL_PROJECTILE;
	missile.velocity = dir * (autocvar_g_monster_wyvern_attack_fireball_speed);
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 5;
	missile.think = M_Wyvern_Attack_Fireball_Explode;
	missile.enemy = self.enemy;
	missile.touch = M_Wyvern_Attack_Fireball_Touch;
	CSQCProjectile(missile, true, PROJECTILE_FIREMINE, true);
}

float M_Wyvern_Attack(float attack_type)
{SELFPARAM();
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			self.attack_finished_single = time + 1.2;
			self.anim_finished = time + 1.2;

			M_Wyvern_Attack_Fireball();

			return true;
		}
	}

	return false;
}

void spawnfunc_monster_wyvern() { Monster_Spawn(MON_WYVERN.monsterid); }
#endif // SVQC

bool M_Wyvern(int req)
{SELFPARAM();
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			return true;
		}
		case MR_PAIN:
		{
			self.pain_finished = time + 0.5;
			setanim(self, self.anim_pain1, true, true, false);
			return true;
		}
		case MR_DEATH:
		{
			setanim(self, self.anim_die1, false, true, true);
			self.velocity_x = -200 + 400 * random();
			self.velocity_y = -200 + 400 * random();
			self.velocity_z = 100 + 100 * random();
			return true;
		}
		#endif
		#ifndef MENUQC
		case MR_ANIM:
		{
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
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_wyvern_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_wyvern_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_wyvern_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_wyvern_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_wyvern_damageforcescale); }

			self.monster_loot = spawnfunc_item_cells;
			self.monster_attackfunc = M_Wyvern_Attack;

			return true;
		}
		case MR_PRECACHE:
		{
			return true;
		}
		#endif
	}

	return true;
}
