#include "ammo.qh"

#ifdef SVQC
void nade_ammo_touch(entity this, entity toucher)
{
	if ((!IS_PLAYER(toucher) && !IS_MONSTER(toucher))
	|| IS_DEAD(toucher) || STAT(FROZEN, toucher))
		return;

	float new_load;
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (toucher.(weaponentity).clip_size)
		{
			new_load = (SAME_TEAM(toucher, this.realowner))
				? toucher.(weaponentity).clip_size
				: max(0, toucher.(weaponentity).clip_load - toucher.(weaponentity).clip_size * (autocvar_g_nades_ammo_clip_empty_rate * frametime * 0.5));

			toucher.(weaponentity).clip_load = toucher.(weaponentity).(weapon_load[toucher.(weaponentity).m_switchweapon.m_id]) = new_load;
		}
	}

	float ammo_factor = autocvar_g_nades_ammo_rate * frametime * 0.5;
	if (toucher != this.realowner)
		ammo_factor *= (SAME_TEAM(toucher, this))
			? autocvar_g_nades_ammo_friend
			: autocvar_g_nades_ammo_foe;

	if (ammo_factor > 0)
	{
		bool gave = false;
	#define GIVE_AMMO_RESOURCE(res_resource, max_resource) \
		if (GetResource(toucher, res_resource) < max_resource) \
		{ \
			GiveResourceWithLimit(toucher, res_resource, ammo_factor, max_resource); \
			gave = true; \
		}

		GIVE_AMMO_RESOURCE(RES_SHELLS,  autocvar_g_pickup_shells_max);
		GIVE_AMMO_RESOURCE(RES_BULLETS, autocvar_g_pickup_nails_max);
		GIVE_AMMO_RESOURCE(RES_ROCKETS, autocvar_g_pickup_rockets_max);
		GIVE_AMMO_RESOURCE(RES_CELLS,   autocvar_g_pickup_cells_max);
	#undef GIVE_AMMO_RESOURCE

		if (gave)
			nade_Effect(toucher, EFFECT_AMMO_REGEN, 1);
	}
	else if (ammo_factor < 0) // Foe drops ammo points
	{
		float amresource;
	#define DROP_AMMO_RESOURCE(res_resource) \
		amresource = GetResource(toucher, res_resource); \
		if (amresource > 0) \
			SetResource(toucher, res_resource, max(0, amresource + ammo_factor));

		DROP_AMMO_RESOURCE(RES_SHELLS);
		DROP_AMMO_RESOURCE(RES_BULLETS);
		DROP_AMMO_RESOURCE(RES_ROCKETS);
		DROP_AMMO_RESOURCE(RES_CELLS);
	#undef DROP_AMMO_RESOURCE

		return;
	}
}

void nade_ammo_boom(entity this)
{
	entity orb = nades_spawn_orb(this, autocvar_g_nades_ammo_time, autocvar_g_nades_ammo_radius);
	settouch(orb, nade_ammo_touch);
}
#endif // SVQC
#ifdef MENUQC
#include <common/mutators/mutator/buffs/buff/ammo.qh>

METHOD(AmmoNade, describe, string(AmmoNade this))
{
	TC(AmmoNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
	      "If your team members enter the orb they will recover ammo, and if enemies enter the sphere they will lose ammo."), COLORED_NAME(this));
	PAR(_("Similar to the %s buff, your weapon magazines remain full while you are inside the orb, so you don't need to reload."), COLORED_NAME(BUFF_AMMO));
	return PAGE_TEXT;
}
#endif // MENUQC
