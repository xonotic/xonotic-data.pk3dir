#include "ammo.qh"

#ifdef SVQC
METHOD(AmmoBuff, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	bool was_active = actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
	if (!was_active)
	{
		actor.buff_ammo_prev_infitems = (actor.items & IT_UNLIMITED_AMMO);
		actor.items |= IT_UNLIMITED_AMMO;
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (!actor.(weaponentity))
				continue;
			if (actor.(weaponentity).clip_load)
				actor.(weaponentity).buff_ammo_prev_clipload = actor.(weaponentity).clip_load;
			if (actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}
	}
	SUPER(AmmoBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(AmmoBuff, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	bool was_active = actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
	if (was_active)
	{
		actor.items = BITSET(actor.items, IT_UNLIMITED_AMMO, actor.buff_ammo_prev_infitems);
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (!actor.(weaponentity))
				continue;
			if (actor.(weaponentity).buff_ammo_prev_clipload)
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
	if (IS_PLAYER(actor))
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}

	SUPER(AmmoBuff).m_tick(this, actor);
}
#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/rifle.qh>
#include <common/mutators/mutator/overkill/okmachinegun.qh>

METHOD(AmmoBuff, describe, string(AmmoBuff this))
{
	TC(AmmoBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff gives you infinite ammo until the buff expires, so you don't need to worry about running out of ammo."), COLORED_NAME(this));
	PAR(_("It also removes the need to reload any weapons that require reloading, like the %s and %s."), COLORED_NAME(WEP_RIFLE), COLORED_NAME(WEP_OVERKILL_MACHINEGUN));
	return PAGE_TEXT;
}
#endif // MENUQC
