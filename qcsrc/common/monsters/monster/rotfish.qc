#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ ROTFISH,
/* functions  */ M_Rotfish, M_Rotfish_Attack,
/* spawnflags */ MON_FLAG_MELEE | MONSTER_SIZE_BROKEN | MONSTER_TYPE_SWIM,
/* mins,maxs  */ '-20 -20 -31', '20 20 20',
/* model      */ "fish.mdl",
/* netname    */ "rotfish",
/* fullname   */ _("Rotfish")
);

#else
#ifdef SVQC
float autocvar_g_monster_rotfish_health;
float autocvar_g_monster_rotfish_damageforcescale = 0.8;
float autocvar_g_monster_rotfish_attack_range;
float autocvar_g_monster_rotfish_attack_melee_damage;
float autocvar_g_monster_rotfish_attack_melee_delay;
float autocvar_g_monster_rotfish_speed_stop;
float autocvar_g_monster_rotfish_speed_run;
float autocvar_g_monster_rotfish_speed_walk;

/*
const float rotfish_anim_attack = 0;
const float rotfish_anim_death  = 1;
const float rotfish_anim_swim   = 2;
const float rotfish_anim_pain   = 3;
*/


float M_Rotfish_Attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			return Monster_Attack_Melee(self.enemy, (autocvar_g_monster_rotfish_attack_melee_damage), self.anim_melee, self.attack_range, (autocvar_g_monster_rotfish_attack_melee_delay), DEATH_MONSTER_ROTFISH_MELEE, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			// rotfish has no ranged attack yet
			return false;
		}
	}

	return false;
}

void spawnfunc_monster_rotfish() { Monster_Spawn(MON_ROTFISH); }
void spawnfunc_monster_fish() { spawnfunc_monster_rotfish(); }

float M_Rotfish(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			return true;
		}
		case MR_PAIN:
		{
			self.pain_finished = 0.8;
			setanim(self, self.anim_pain1, true, true, false);
			return true;
		}
		case MR_DEATH:
		{
			setanim(self, self.anim_die1, false, true, true);
			return true;
		}
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '1 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '2 1 1', none);
			self.anim_idle = animfixfps(self, '2 1 1', none);
			self.anim_pain1 = animfixfps(self, '3 1 2', none); // 0.5 seconds
			self.anim_melee = animfixfps(self, '0 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '2 1 1', none);

			return true;
		}
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_rotfish_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_rotfish_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_rotfish_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_rotfish_speed_stop); }
			if(!self.attack_range) { self.attack_range = autocvar_g_monster_rotfish_attack_range; }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_rotfish_damageforcescale); }

			self.monster_loot = spawnfunc_item_armor_small;

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
