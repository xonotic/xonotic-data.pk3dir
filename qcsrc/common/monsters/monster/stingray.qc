#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ STINGRAY,
/* function   */ m_stingray,
/* spawnflags */ MONSTER_TYPE_SWIM | MONSTER_SIZE_BROKEN,
/* mins,maxs  */ '-20 -20 -31', '20 20 20',
/* model      */ "fish.mdl",
/* netname    */ "stingray",
/* fullname   */ _("Stingray")
);

#else
#ifdef SVQC
float autocvar_g_monster_stingray;
float autocvar_g_monster_stingray_health;
float autocvar_g_monster_stingray_damage;
float autocvar_g_monster_stingray_speed_walk;
float autocvar_g_monster_stingray_speed_run;

const float stingray_anim_attack = 0;
const float stingray_anim_death  = 1;
const float stingray_anim_swim   = 2;
const float stingray_anim_pain   = 3;

float stingray_attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			monsters_setframe(stingray_anim_attack);
			self.attack_finished_single = time + 0.5;
			monster_melee(self.enemy, autocvar_g_monster_stingray_damage, 0.1, DEATH_MONSTER_STINGRAY, FALSE);
			
			return TRUE;
		}
		case MONSTER_ATTACK_RANGED:
	}
	
	return FALSE;
}

void spawnfunc_monster_stingray()
{
	if not(autocvar_g_monster_stingray) { remove(self); return; }
	
	self.classname = "monster_stingray";
	
	self.monster_spawnfunc = spawnfunc_monster_stingray;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not(monster_initialize(MON_STINGRAY, TRUE)) { remove(self); return; }
}

float m_stingray(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			monster_move(autocvar_g_monster_stingray_speed_run, autocvar_g_monster_stingray_speed_walk, 10, stingray_anim_swim, stingray_anim_swim, stingray_anim_swim);
			return TRUE;
		}
		case MR_DEATH:
		{
			monsters_setframe(stingray_anim_swim);
			return TRUE;
		}
		case MR_SETUP:
		{
			if not(self.health) self.health = autocvar_g_monster_stingray_health;
				
			self.monster_attackfunc	= stingray_attack;
			monsters_setframe(stingray_anim_death);
			
			return TRUE;
		}
		case MR_INIT:
		{
			// nothing
			return TRUE;
		}
	}
	
	return TRUE;
}

#endif // SVQC
#ifdef CSQC
float m_stingray(float req)
{
	switch(req)
	{
		case MR_DEATH:
		{
			// nothing
			return TRUE;
		}
		case MR_INIT:
		{
			precache_model ("models/monsters/fish.mdl");
			return TRUE;
		}
	}
	
	return TRUE;
}

#endif // CSQC
#endif // REGISTER_MONSTER
