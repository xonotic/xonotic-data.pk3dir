#include "ammo.qh"

#ifdef SVQC
METHOD(AmmoBuff, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(!wasactive)
	{
		actor.buff_ammo_prev_infitems = (actor.items & IT_UNLIMITED_AMMO);
		actor.items |= IT_UNLIMITED_AMMO;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(!actor.(weaponentity))
				continue;
			if(actor.(weaponentity).clip_load)
				actor.(weaponentity).buff_ammo_prev_clipload = actor.(weaponentity).clip_load;
			if(actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}
	}
	SUPER(AmmoBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(AmmoBuff, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
	{
		actor.items = BITSET(actor.items, IT_UNLIMITED_AMMO, actor.buff_ammo_prev_infitems);
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(!actor.(weaponentity))
				continue;
			if(actor.(weaponentity).buff_ammo_prev_clipload)
			{
				actor.(weaponentity).clip_load = actor.(weaponentity).buff_ammo_prev_clipload;
				actor.(weaponentity).buff_ammo_prev_clipload = 0;
			}
		}
	}
	actor.buff_ammo_prev_infitems = 0;
	SUPER(AmmoBuff).m_remove(this, actor, removal_type);
}
METHOD(AmmoBuff, m_tick, void(StatusEffect this, entity actor))
{
	if(IS_PLAYER(actor))
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}
	}

	SUPER(AmmoBuff).m_tick(this, actor);
}
#endif // SVQC
