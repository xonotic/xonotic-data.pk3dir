#ifdef IMPLEMENTATION
float autocvar_g_touchexplode_radius;
float autocvar_g_touchexplode_damage;
float autocvar_g_touchexplode_edgedamage;
float autocvar_g_touchexplode_force;

REGISTER_MUTATOR(touchexplode, cvar("g_touchexplode"));

.float touchexplode_time;

void PlayerTouchExplode(entity p1, entity p2)
{SELFPARAM();
	vector org = (p1.origin + p2.origin) * 0.5;
	org.z += (p1.mins.z + p2.mins.z) * 0.5;

	sound(self, CH_TRIGGER, SND_GRENADE_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_EXPLOSION_SMALL, org, '0 0 0', 1);

	entity e = spawn();
	setorigin(e, org);
	RadiusDamage(e, world, autocvar_g_touchexplode_damage, autocvar_g_touchexplode_edgedamage, autocvar_g_touchexplode_radius, world, world, autocvar_g_touchexplode_force, DEATH_TOUCHEXPLODE.m_id, world);
	remove(e);
}

MUTATOR_HOOKFUNCTION(touchexplode, PlayerPreThink)
{SELFPARAM();
	if(time > self.touchexplode_time)
	if(!gameover)
	if(!self.frozen)
	if(IS_PLAYER(self))
	if(self.deadflag == DEAD_NO)
	if (!IS_INDEPENDENT_PLAYER(self))
	FOR_EACH_PLAYER(other) if(self != other)
	{
		if(time > other.touchexplode_time)
		if(!other.frozen)
		if(other.deadflag == DEAD_NO)
		if (!IS_INDEPENDENT_PLAYER(other))
		if(boxesoverlap(self.absmin, self.absmax, other.absmin, other.absmax))
		{
			PlayerTouchExplode(self, other);
			self.touchexplode_time = other.touchexplode_time = time + 0.2;
		}
	}

	return false;
}
#endif
