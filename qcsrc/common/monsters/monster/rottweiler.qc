#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ ROTTWEILER,
/* functions  */ M_Rottweiler, M_Rottweiler_Attack,
/* spawnflags */ MON_FLAG_MELEE | MONSTER_SIZE_BROKEN | MON_FLAG_RIDE,
/* mins,maxs  */ '-16 -16 -24', '16 16 12',
/* model      */ "dog.mdl",
/* netname    */ "rottweiler",
/* fullname   */ _("Rottweiler")
);

#else
#ifdef SVQC
float autocvar_g_monster_rottweiler_health;
float autocvar_g_monster_rottweiler_damageforcescale = 0.7;
float autocvar_g_monster_rottweiler_attack_melee_damage;
float autocvar_g_monster_rottweiler_attack_melee_delay;
float autocvar_g_monster_rottweiler_speed_stop;
float autocvar_g_monster_rottweiler_speed_run;
float autocvar_g_monster_rottweiler_speed_walk;

/*
const float rottweiler_anim_attack1		= 0;
const float rottweiler_anim_death1		= 1;
const float rottweiler_anim_death2		= 2;
const float rottweiler_anim_attack2		= 3;
const float rottweiler_anim_pain		= 4;
const float rottweiler_anim_run			= 5;
const float rottweiler_anim_leap		= 6;
const float rottweiler_anim_idle		= 7;
const float rottweiler_anim_walk		= 8;
*/

float M_Rottweiler_Attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			return Monster_Attack_Melee(self.enemy, (autocvar_g_monster_rottweiler_attack_melee_damage), ((random() >= 0.5) ? self.anim_melee1 : self.anim_melee2), self.attack_range, (autocvar_g_monster_rottweiler_attack_melee_delay), DEATH_MONSTER_ROTTWEILER, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			// rottweiler has no ranged attack yet!
			return false;
		}
	}

	return false;
}

void spawnfunc_monster_rottweiler() { Monster_Spawn(MON_ROTTWEILER); }
#endif // SVQC

bool M_Rottweiler(int req)
{
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			return true;
		}
		case MR_PAIN:
		{
			if(random() <= 0.3)
			{
				self.pain_finished = time + 1.5;
				setanim(self, self.anim_pain1, true, true, false);
			}
			return true;
		}
		case MR_DEATH:
		{
			setanim(self, ((random() > 0.5) ? self.anim_die1 : self.anim_die2), false, true, true);
			return true;
		}
		#endif
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '5 1 0.5', none); // 2 seconds
			self.anim_die2 = animfixfps(self, '1 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '2 1 1', none);
			self.anim_idle = animfixfps(self, '7 1 1', none);
			self.anim_pain1 = animfixfps(self, '4 1 2', none); // 0.5 seconds
			self.anim_melee1 = animfixfps(self, '0 1 5', none); // analyze models and set framerate
			self.anim_melee2 = animfixfps(self, '3 1 5', none); // analyze models and set framerate
			self.anim_shoot = animfixfps(self, '6 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '5 1 1', none);

			return true;
		}
		#ifdef SVQC
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_rottweiler_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_rottweiler_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_rottweiler_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_rottweiler_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_rottweiler_damageforcescale); }

			self.monster_loot = spawnfunc_item_health_small;

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

#endif // REGISTER_MONSTER
