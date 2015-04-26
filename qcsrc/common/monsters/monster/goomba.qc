#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ GOOMBA,
/* functions  */ M_Goomba, M_Goomba_Attack,
/* spawnflags */ MON_FLAG_MELEE | MON_FLAG_CRUSH,
/* mins,maxs  */ '-18 -18 -20', '18 18 20',
/* model      */ "goomba.md3",
/* netname    */ "goomba",
/* fullname   */ _("Goomba")
);

#else
#ifdef SVQC

float autocvar_g_monster_goomba_health = 50;
float autocvar_g_monster_goomba_damageforcescale = 0.1;
float autocvar_g_monster_goomba_attack_bite_damage = 50;
float autocvar_g_monster_goomba_speed_stop = 100;
float autocvar_g_monster_goomba_speed_walk = 150;
bool  autocvar_g_monster_goomba_allow_jumpoff = true;

void M_Goomba_Touch()
{	
	if(!other.takedamage)
		return;
	if(!other.iscreature)
		return;
	if(time < self.attack_finished_single)
		return;
	if(other.monsterid == self.monsterid)
		return; // friendly
		
	vector vdir = normalize(other.origin - self.origin);
	if(vdir_z <= 0.7)
	{
		Damage(other, self, self, autocvar_g_monster_goomba_attack_bite_damage, DEATH_MONSTER_ZOMBIE_MELEE, other.origin, '0 0 0');
		self.attack_finished_single = time + 0.55;
	}
}

bool M_Goomba_Attack(int attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		case MONSTER_ATTACK_RANGED:
		{
			// goomba has no actual attacks, it just runs into players
			return false;
		}
	}

	return false;
}

void spawnfunc_monster_goomba() { Monster_Spawn(MON_GOOMBA); }
#endif // SVQC

bool M_Goomba(int req)
{
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			Monster_Move_2D(self.speed, autocvar_g_monster_goomba_allow_jumpoff);
			return false; // funny handler here, false means don't do regular moving
		}
		case MR_PAIN:
		{
			self.pain_finished = time + 0.5;

			setmodel(self, self.mdl_dead);
			return true;
		}
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_goomba_health);
			if(!self.speed) { self.speed2 = self.speed = (autocvar_g_monster_goomba_speed_walk); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_goomba_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_goomba_damageforcescale); }
			if(!self.mdl_dead) { self.mdl_dead = self.mdl; }

			precache_model(self.mdl_dead);

			self.touch = M_Goomba_Touch;

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
