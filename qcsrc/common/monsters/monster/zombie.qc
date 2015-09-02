#ifndef MENUQC
bool M_Zombie(int);
#endif
REGISTER_MONSTER_SIMPLE(
/* MON_##id   */ ZOMBIE,
/* spawnflags */ MON_FLAG_MELEE | MON_FLAG_RIDE,
/* mins,maxs  */ '-18 -18 -25', '18 18 47',
/* model      */ "zombie.dpm",
/* netname    */ "zombie",
/* fullname   */ _("Zombie")
) {
#ifndef MENUQC
	this.monster_func = M_Zombie;
	this.monster_func(MR_PRECACHE);
#endif
}

#ifdef SVQC
float autocvar_g_monster_zombie_health;
float autocvar_g_monster_zombie_damageforcescale = 0.55;
float autocvar_g_monster_zombie_attack_melee_damage;
float autocvar_g_monster_zombie_attack_melee_delay;
float autocvar_g_monster_zombie_attack_leap_damage;
float autocvar_g_monster_zombie_attack_leap_force;
float autocvar_g_monster_zombie_attack_leap_speed;
float autocvar_g_monster_zombie_attack_leap_delay;
float autocvar_g_monster_zombie_speed_stop;
float autocvar_g_monster_zombie_speed_run;
float autocvar_g_monster_zombie_speed_walk;

/*
const float zombie_anim_attackleap			= 0;
const float zombie_anim_attackrun1			= 1;
const float zombie_anim_attackrun2			= 2;
const float zombie_anim_attackrun3			= 3;
const float zombie_anim_attackstanding1		= 4;
const float zombie_anim_attackstanding2		= 5;
const float zombie_anim_attackstanding3		= 6;
const float zombie_anim_blockend			= 7;
const float zombie_anim_blockstart			= 8;
const float zombie_anim_deathback1			= 9;
const float zombie_anim_deathback2			= 10;
const float zombie_anim_deathback3			= 11;
const float zombie_anim_deathfront1			= 12;
const float zombie_anim_deathfront2			= 13;
const float zombie_anim_deathfront3			= 14;
const float zombie_anim_deathleft1			= 15;
const float zombie_anim_deathleft2			= 16;
const float zombie_anim_deathright1			= 17;
const float zombie_anim_deathright2			= 18;
const float zombie_anim_idle				= 19;
const float zombie_anim_painback1			= 20;
const float zombie_anim_painback2			= 21;
const float zombie_anim_painfront1			= 22;
const float zombie_anim_painfront2			= 23;
const float zombie_anim_runbackwards		= 24;
const float zombie_anim_runbackwardsleft	= 25;
const float zombie_anim_runbackwardsright	= 26;
const float zombie_anim_runforward			= 27;
const float zombie_anim_runforwardleft		= 28;
const float zombie_anim_runforwardright		= 29;
const float zombie_anim_spawn				= 30;
*/

void M_Zombie_Attack_Leap_Touch()
{
	if (self.health <= 0)
		return;

	vector angles_face;

	if(other.takedamage)
	{
		angles_face = vectoangles(self.moveto - self.origin);
		angles_face = normalize(angles_face) * (autocvar_g_monster_zombie_attack_leap_force);
		Damage(other, self, self, (autocvar_g_monster_zombie_attack_leap_damage) * MONSTER_SKILLMOD(self), DEATH_MONSTER_ZOMBIE_JUMP, other.origin, angles_face);
		self.touch = Monster_Touch; // instantly turn it off to stop damage spam
		self.state = 0;
	}

	if (trace_dphitcontents)
	{
		self.state = 0;
		self.touch = Monster_Touch;
	}
}

void M_Zombie_Defend_Block_End()
{
	if(self.health <= 0)
		return;

	setanim(self, self.anim_blockend, false, true, true);
	self.armorvalue = autocvar_g_monsters_armor_blockpercent;
}

float M_Zombie_Defend_Block()
{
	self.armorvalue = 0.9;
	self.state = MONSTER_ATTACK_MELEE; // freeze monster
	self.attack_finished_single = time + 2.1;
	self.anim_finished = self.attack_finished_single;
	setanim(self, self.anim_blockstart, false, true, true);

	Monster_Delay(1, 0, 2, M_Zombie_Defend_Block_End);

	return true;
}

float M_Zombie_Attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(random() < 0.3 && self.health < 75 && self.enemy.health > 10)
				return M_Zombie_Defend_Block();

			float rand = random();
			vector chosen_anim;

			if(rand < 0.33)
				chosen_anim = self.anim_melee1;
			else if(rand < 0.66)
				chosen_anim = self.anim_melee2;
			else
				chosen_anim = self.anim_melee3;

			return Monster_Attack_Melee(self.enemy, (autocvar_g_monster_zombie_attack_melee_damage), chosen_anim, self.attack_range, (autocvar_g_monster_zombie_attack_melee_delay), DEATH_MONSTER_ZOMBIE_MELEE, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(self.angles);
			return Monster_Attack_Leap(self.anim_shoot, M_Zombie_Attack_Leap_Touch, v_forward * (autocvar_g_monster_zombie_attack_leap_speed) + '0 0 200', (autocvar_g_monster_zombie_attack_leap_delay));
		}
	}

	return false;
}

void spawnfunc_monster_zombie() { Monster_Spawn(MON_ZOMBIE.monsterid); }
#endif // SVQC

bool M_Zombie(int req)
{
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			if(time >= self.spawn_time)
				self.damageforcescale = autocvar_g_monster_zombie_damageforcescale;
			return true;
		}
		case MR_PAIN:
		{
			self.pain_finished = time + 0.34;
			setanim(self, ((random() > 0.5) ? self.anim_pain1 : self.anim_pain2), true, true, false);
			return true;
		}
		case MR_DEATH:
		{
			self.armorvalue = autocvar_g_monsters_armor_blockpercent;

			setanim(self, ((random() > 0.5) ? self.anim_die1 : self.anim_die2), false, true, true);
			return true;
		}
		#endif
		#ifndef MENUQC
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '9 1 0.5', none); // 2 seconds
			self.anim_die2 = animfixfps(self, '12 1 0.5', none); // 2 seconds
			self.anim_spawn = animfixfps(self, '30 1 3', none);
			self.anim_walk = animfixfps(self, '27 1 1', none);
			self.anim_idle = animfixfps(self, '19 1 1', none);
			self.anim_pain1 = animfixfps(self, '20 1 2', none); // 0.5 seconds
			self.anim_pain2 = animfixfps(self, '22 1 2', none); // 0.5 seconds
			self.anim_melee1 = animfixfps(self, '4 1 5', none); // analyze models and set framerate
			self.anim_melee2 = animfixfps(self, '4 1 5', none); // analyze models and set framerate
			self.anim_melee3 = animfixfps(self, '4 1 5', none); // analyze models and set framerate
			self.anim_shoot = animfixfps(self, '0 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '27 1 1', none);
			self.anim_blockstart = animfixfps(self, '8 1 1', none);
			self.anim_blockend = animfixfps(self, '7 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_zombie_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_zombie_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_zombie_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_zombie_speed_stop); }

			if(self.spawnflags & MONSTERFLAG_NORESPAWN)
				self.spawnflags &= ~MONSTERFLAG_NORESPAWN; // zombies always respawn

			self.spawnflags |= MONSTER_RESPAWN_DEATHPOINT;

			self.monster_loot = spawnfunc_item_health_medium;
			self.monster_attackfunc = M_Zombie_Attack;
			self.spawnshieldtime = self.spawn_time;
			self.respawntime = 0.2;
			self.damageforcescale = 0.0001; // no push while spawning

			setanim(self, self.anim_spawn, false, true, true);
			self.spawn_time = self.animstate_endtime;

			return true;
		}
		case MR_PRECACHE:
		{
			precache_model("models/monsters/zombie.dpm");
			return true;
		}
		#endif
	}

	return true;
}
