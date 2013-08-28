#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ CERBERUS,
/* function   */ m_cerberus,
/* spawnflags */ 0,
/* mins,maxs  */ '-16 -16 -24', '16 16 12',
/* model      */ "dog.dpm",
/* netname    */ "cerberus",
/* fullname   */ _("Cerberus")
);

#else
#ifdef SVQC
float autocvar_g_monster_cerberus;
float autocvar_g_monster_cerberus_health;
float autocvar_g_monster_cerberus_bite_damage;
float autocvar_g_monster_cerberus_attack_jump_damage;
float autocvar_g_monster_cerberus_speed_walk;
float autocvar_g_monster_cerberus_speed_run;

const float cerberus_anim_idle		= 0;
const float cerberus_anim_walk		= 1;
const float cerberus_anim_run		= 2;
const float cerberus_anim_attack	= 3;
const float cerberus_anim_die		= 4;
const float cerberus_anim_pain		= 5;

void cerberus_touch_jump()
{
	if (other.takedamage)
	if (vlen(self.velocity) > 300)
	{
		Damage(self.enemy, self, self, autocvar_g_monster_cerberus_attack_jump_damage * monster_skill, DEATH_MONSTER_CERBERUS_JUMP, self.enemy.origin, normalize(self.enemy.origin - self.origin));
		self.touch = MonsterTouch;
	}

	if(trace_dphitcontents)
		self.touch = MonsterTouch;
}

float cerberus_attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			monsters_setframe(cerberus_anim_attack);
			self.attack_finished_single = time + 0.7;
			monster_melee(self.enemy, autocvar_g_monster_cerberus_bite_damage, 0.2, DEATH_MONSTER_CERBERUS_BITE, TRUE);
			
			return TRUE;
		}
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(self.angles);
			if(monster_leap(cerberus_anim_attack, cerberus_touch_jump, v_forward * 300 + '0 0 200', 0.8))
				return TRUE;
		}
	}
	
	return FALSE;
}

void spawnfunc_monster_cerberus()
{
	if not(autocvar_g_monster_cerberus) { remove(self); return; }
	
	self.classname = "monster_cerberus";
	
	self.monster_spawnfunc = spawnfunc_monster_cerberus;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not(monster_initialize(MON_CERBERUS, FALSE)) { remove(self); return; }
}

// compatibility with old spawns
void spawnfunc_monster_dog() { spawnfunc_monster_cerberus(); }

float m_cerberus(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			monster_move(autocvar_g_monster_cerberus_speed_run, autocvar_g_monster_cerberus_speed_walk, 50, cerberus_anim_run, cerberus_anim_walk, cerberus_anim_idle);
			return TRUE;
		}
		case MR_DEATH:
		{
			monsters_setframe(cerberus_anim_die);
			return TRUE;
		}
		case MR_SETUP:
		{
			if not(self.health) self.health = autocvar_g_monster_cerberus_health;
				
			self.monster_attackfunc	= cerberus_attack;
			monsters_setframe(cerberus_anim_idle);
			
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
float m_cerberus(float req)
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
			precache_model ("models/monsters/dog.dpm");
			return TRUE;
		}
	}
	
	return TRUE;
}

#endif // CSQC
#endif // REGISTER_MONSTER