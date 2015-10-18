#ifdef IMPLEMENTATION
REGISTER_MUTATOR(vh, cvar("g_vampirehook"));

bool autocvar_g_vampirehook_teamheal;
float autocvar_g_vampirehook_damage;
float autocvar_g_vampirehook_damagerate;
float autocvar_g_vampirehook_health_steal;

.float last_dmg;

MUTATOR_HOOKFUNCTION(vh, GrappleHookThink)
{SELFPARAM();
	entity dmgent = ((SAME_TEAM(self.owner, self.aiment) && autocvar_g_vampirehook_teamheal) ? self.owner : self.aiment);

	if(IS_PLAYER(self.aiment))
	if(self.last_dmg < time)
	if(!self.aiment.frozen)
	if(time >= game_starttime)
	if(DIFF_TEAM(self.owner, self.aiment) || autocvar_g_vampirehook_teamheal)
	if(self.aiment.health > 0)
	if(autocvar_g_vampirehook_damage)
	{
		self.last_dmg = time + autocvar_g_vampirehook_damagerate;
		self.owner.damage_dealt += autocvar_g_vampirehook_damage;
		Damage(dmgent, self, self.owner, autocvar_g_vampirehook_damage, WEP_HOOK.m_id, self.origin, '0 0 0');
		if(SAME_TEAM(self.owner, self.aiment))
			self.aiment.health = min(self.aiment.health + autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max);
		else
			self.owner.health = min(self.owner.health + autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max);

		if(dmgent == self.owner)
			dmgent.health -= autocvar_g_vampirehook_damage; // FIXME: friendly fire?!
	}

	return false;
}

#endif
