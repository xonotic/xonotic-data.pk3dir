#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ BRUISER,
/* function   */ m_bruiser,
/* spawnflags */ MONSTER_SIZE_BROKEN,
/* mins,maxs  */ '-20 -20 -31', '20 20 53',
/* model      */ "knight.mdl",
/* netname    */ "bruiser",
/* fullname   */ _("Bruiser")
);

#else
#ifdef SVQC
float autocvar_g_monster_bruiser;
float autocvar_g_monster_bruiser_health;
float autocvar_g_monster_bruiser_melee_damage;
float autocvar_g_monster_bruiser_speed_walk;
float autocvar_g_monster_bruiser_speed_run;

const float bruiser_anim_stand 		= 0;
const float bruiser_anim_run 		= 1;
const float bruiser_anim_runattack 	= 2;
const float bruiser_anim_pain1 		= 3;
const float bruiser_anim_pain2 		= 4;
const float bruiser_anim_attack 	= 5;
const float bruiser_anim_walk 		= 6;
const float bruiser_anim_kneel 		= 7;
const float bruiser_anim_standing 	= 8;
const float bruiser_anim_death1 	= 9;
const float bruiser_anim_death2 	= 10;

float bruiser_attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			float len = vlen(self.velocity);
			monsters_setframe((len < 50) ? bruiser_anim_attack : bruiser_anim_runattack);
			self.attack_finished_single = time + 1.25;
			
			monster_melee(self.enemy, autocvar_g_monster_bruiser_melee_damage, 0.3, DEATH_MONSTER_BRUISER, FALSE);
			
			return TRUE;
		}
		case MONSTER_ATTACK_RANGED:
		{
			// no ranged attacks for bruiser
			return FALSE;
		}
	}
	
	return FALSE;
}

void spawnfunc_monster_bruiser()
{
	if not(autocvar_g_monster_bruiser) { remove(self); return; }
	
	self.classname = "monster_bruiser";
	
	self.monster_spawnfunc = spawnfunc_monster_bruiser;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not(monster_initialize(MON_BRUISER, FALSE)) { remove(self); return; }
}

float m_bruiser(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			monster_move(autocvar_g_monster_bruiser_speed_run, autocvar_g_monster_bruiser_speed_walk, 50, bruiser_anim_run, bruiser_anim_walk, bruiser_anim_stand);
			return TRUE;
		}
		case MR_DEATH:
		{
			monsters_setframe((random() > 0.5) ? bruiser_anim_death1 : bruiser_anim_death2);
			return TRUE;
		}
		case MR_SETUP:
		{
			if not(self.health) self.health = autocvar_g_monster_bruiser_health;
				
			self.monster_attackfunc	= bruiser_attack;
			monsters_setframe(bruiser_anim_stand);
			
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
float m_bruiser(float req)
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
			precache_model ("models/monsters/knight.mdl");
			return TRUE;
		}
	}
	
	return TRUE;
}

#endif // CSQC
#endif // REGISTER_MONSTER
