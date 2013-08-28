#ifdef REGISTER_MONSTER
REGISTER_MONSTER(
/* MON_##id   */ ANIMUS,
/* function   */ m_animus,
/* mins,maxs  */ '-41 -41 -31', '41 41 31',
/* model      */ "demon.mdl",
/* netname    */ "animus",
/* fullname   */ _("Animus")
);

#else
#ifdef SVQC
float autocvar_g_monster_animus;
float autocvar_g_monster_animus_health;
float autocvar_g_monster_animus_attack_jump_damage;
float autocvar_g_monster_animus_damage;
float autocvar_g_monster_animus_speed_walk;
float autocvar_g_monster_animus_speed_run;

const float animus_anim_stand	= 0;
const float animus_anim_walk	= 1;
const float animus_anim_run		= 2;
const float animus_anim_leap	= 3;
const float animus_anim_pain	= 4;
const float animus_anim_death	= 5;
const float animus_anim_attack	= 6;

void animus_touch_jump()
{
	if (self.health <= 0)
		return;

	if (monster_isvalidtarget(other, self))
	{
		if (vlen(self.velocity) > 300)
		{
			Damage(other, self, self, autocvar_g_monster_animus_attack_jump_damage * monster_skill, DEATH_MONSTER_ANIMUS, other.origin, normalize(other.origin - self.origin));
			self.touch = MonsterTouch; // instantly turn it off to stop damage spam
		}
	}

	if(trace_dphitcontents)
		self.touch = MonsterTouch;
}

float animus_attack(float attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			monsters_setframe(animus_anim_attack);
			self.attack_finished_single = time + 1;
			monster_melee(self.enemy, autocvar_g_monster_animus_damage, 0.3, DEATH_MONSTER_ANIMUS, TRUE);
			
			return TRUE;
		}
		case MONSTER_ATTACK_RANGED:
		{
			makevectors(self.angles);
			if(monster_leap(animus_anim_leap, animus_touch_jump, v_forward * 700 + '0 0 300', 0.8))
				return TRUE;
		}
	}
	
	return FALSE;
}

void spawnfunc_monster_animus()
{
	if not(autocvar_g_monster_animus) { remove(self); return; }
	
	self.classname = "monster_animus";
	
	self.monster_spawnfunc = spawnfunc_monster_animus;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not(monster_initialize(MON_ANIMUS, FALSE, MONSTER_SIZE_BROKEN)) { remove(self); return; }
}

// compatibility with old spawns
void spawnfunc_monster_demon1() { spawnfunc_monster_animus(); }
void spawnfunc_monster_demon() { spawnfunc_monster_animus(); }

float m_animus(float req)
{
	switch(req)
	{
		case MR_THINK:
		{
			monster_move(autocvar_g_monster_animus_speed_run, autocvar_g_monster_animus_speed_walk, 100, animus_anim_run, animus_anim_walk, animus_anim_stand);
			return TRUE;
		}
		case MR_DEATH:
		{
			monsters_setframe(animus_anim_death);
			return TRUE;
		}
		case MR_SETUP:
		{
			if not(self.health) self.health = autocvar_g_monster_animus_health;
				
			self.monster_attackfunc = animus_attack;
			monsters_setframe(animus_anim_stand);
			
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
float m_animus(float req)
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
			precache_model ("models/monsters/demon.mdl");
			return TRUE;
		}
	}
	
	return TRUE;
}

#endif // CSQC
#endif // REGISTER_MONSTER
