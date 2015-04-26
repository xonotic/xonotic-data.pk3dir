#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ SCRAG,
/* functions  */ M_Scrag, M_Scrag_Attack,
/* spawnflags */ MONSTER_TYPE_FLY | MONSTER_SIZE_BROKEN | MON_FLAG_RANGED,
/* mins,maxs  */ '-20 -20 -58', '20 20 20',
/* model      */ "scrag.mdl",
/* netname    */ "scrag",
/* fullname   */ _("Scrag")
);

#else
#ifdef SVQC
float autocvar_g_monster_scrag_health;
float autocvar_g_monster_scrag_damageforcescale = 0.55;
float autocvar_g_monster_scrag_attack_spike_damage;
float autocvar_g_monster_scrag_attack_spike_edgedamage;
float autocvar_g_monster_scrag_attack_spike_force;
float autocvar_g_monster_scrag_attack_spike_radius;
float autocvar_g_monster_scrag_attack_spike_speed;
float autocvar_g_monster_scrag_speed_stop;
float autocvar_g_monster_scrag_speed_run;
float autocvar_g_monster_scrag_speed_walk;

/*
const float scrag_anim_hover	= 0;
const float scrag_anim_fly		= 1;
const float scrag_anim_magic	= 2;
const float scrag_anim_pain		= 3;
const float scrag_anim_death	= 4;
*/

void M_Scrag_Attack_Spike_Explode()
{
	if(self)
	{
		pointparticles(particleeffectnum("TE_WIZSPIKE"), self.origin, '0 0 0', 1);

		RadiusDamage(self, self.realowner, (autocvar_g_monster_scrag_attack_spike_damage), (autocvar_g_monster_scrag_attack_spike_edgedamage), (autocvar_g_monster_scrag_attack_spike_force), 
			self.owner, world, (autocvar_g_monster_scrag_attack_spike_radius), self.projectiledeathtype, world);

		remove(self);
	}
}

void M_Scrag_Attack_Spike_Touch()
{
	PROJECTILE_TOUCH;
	if(other == self.owner) { return; }

	M_Scrag_Attack_Spike_Explode();
}

void M_Scrag_Attack_Spike()
{
	entity missile = spawn();
	vector viewofs = self.view_ofs;
	vector dir = normalize(self.enemy.origin - self.origin);

	monster_makevectors(self.enemy);

	missile.owner = missile.realowner = self;
	missile.solid = SOLID_TRIGGER;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.projectiledeathtype = DEATH_MONSTER_SCRAG;
	setsize(missile, '-6 -6 -6', '6 6 6');
	setorigin(missile, self.origin + viewofs + v_forward * 14);
	missile.flags = FL_PROJECTILE;
	missile.velocity = dir * (autocvar_g_monster_scrag_attack_spike_speed);
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 5;
	missile.think = M_Scrag_Attack_Spike_Explode;
	missile.enemy = self.enemy;
	missile.touch = M_Scrag_Attack_Spike_Touch;
	CSQCProjectile(missile, true, PROJECTILE_SCRAG_SPIKE, true);
}

float M_Scrag_Attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			self.attack_finished_single = time + ((random() >= 0.8) ? 1.3 : 0.15);
			self.anim_finished = self.attack_finished_single;

			setanim(self, self.anim_shoot, true, true, false);

			M_Scrag_Attack_Spike();

			if(random() <= 0.1 || self.monster_moveto)
			{
				makevectors(self.angles);
				self.monster_moveto = self.origin + '1 1 0' * (random() >= 0.5) ? (v_right * 300) : (v_right * -300);
				self.monster_face = self.enemy.origin; // but still look at enemy
				if(random() <= 0.4)
					self.monster_moveto = self.monster_face = '0 0 0';
			}

			return true;
		}
	}

	return false;
}

void spawnfunc_monster_scrag() { Monster_Spawn(MON_SCRAG); }

// compatibility with old spawns
void spawnfunc_monster_wizard() { spawnfunc_monster_scrag(); }
void spawnfunc_monster_wyvern() { spawnfunc_monster_scrag(); }
#endif // SVQC

bool M_Scrag(int req)
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
			self.pain_finished = time + 0.3;
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
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '5 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '0 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_pain1 = animfixfps(self, '3 1 2', none); // 0.5 seconds
			self.anim_shoot = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '1 1 1', none);

			return true;
		}
		#ifdef SVQC
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_scrag_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_scrag_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_scrag_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_scrag_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_scrag_damageforcescale); }

			self.monster_loot = spawnfunc_item_shells;

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
