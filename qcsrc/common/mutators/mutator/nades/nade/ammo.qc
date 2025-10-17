#include "ammo.qh"

#ifdef SVQC
void nade_ammo_touch(entity this, entity toucher)
{
	float maxammo = 999;
	float ammo_factor;
	float amshells = GetResource(toucher, RES_SHELLS);
	float ambullets = GetResource(toucher, RES_BULLETS);
	float amrockets = GetResource(toucher, RES_ROCKETS);
	float amcells = GetResource(toucher, RES_CELLS);
	if(IS_PLAYER(toucher) || IS_MONSTER(toucher))
	if(!IS_DEAD(toucher))
	if(!STAT(FROZEN, toucher))
	{
		float new_load;
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (toucher.(weaponentity).clip_size)
			{
				new_load = (SAME_TEAM(toucher, this.realowner))
					? toucher.(weaponentity).clip_size
					: max(0, toucher.(weaponentity).clip_load - toucher.(weaponentity).clip_size * (autocvar_g_nades_ammo_clip_empty_rate * frametime/2));

				toucher.(weaponentity).clip_load = toucher.(weaponentity).(weapon_load[toucher.(weaponentity).m_switchweapon.m_id]) = new_load;
			}
		}

		ammo_factor = autocvar_g_nades_ammo_rate*frametime/2;
		if ( toucher != this.realowner )
			ammo_factor *= (SAME_TEAM(toucher, this.realowner)) ? autocvar_g_nades_ammo_friend : autocvar_g_nades_ammo_foe;

#define CHECK_AMMO_RESOURCE_LIMIT(amresource, res_resource) \
	if (amresource < maxammo) \
		GiveResourceWithLimit(toucher, res_resource, ammo_factor, maxammo);

#define DROP_AMMO_RESOURCE(amresource, res_resource) \
	if (amresource > 0) \
		SetResource(toucher, res_resource, amresource + ammo_factor);
		
		if ( ammo_factor > 0 )
		{
			CHECK_AMMO_RESOURCE_LIMIT(amshells,  RES_SHELLS);
			CHECK_AMMO_RESOURCE_LIMIT(ambullets, RES_BULLETS);
			CHECK_AMMO_RESOURCE_LIMIT(amrockets, RES_ROCKETS);
			CHECK_AMMO_RESOURCE_LIMIT(amcells,   RES_CELLS);

			if (this.nade_show_particles)
				Send_Effect(EFFECT_HEALING, toucher.origin, '0 0 0', 1);
		}
		else if ( ammo_factor < 0 )
		{
			//Foe drops ammo points
			DROP_AMMO_RESOURCE(amshells,  RES_SHELLS);
			DROP_AMMO_RESOURCE(ambullets, RES_BULLETS);
			DROP_AMMO_RESOURCE(amrockets, RES_ROCKETS);
			DROP_AMMO_RESOURCE(amcells,   RES_CELLS);

			return;
		}
#undef CHECK_AMMO_RESOURCE_LIMIT
#undef DROP_AMMO_RESOURCE
	}
}

void nade_ammo_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_ammo_time, autocvar_g_nades_nade_radius);

	settouch(orb, nade_ammo_touch);
	orb.colormod = NADE_TYPE_AMMO.m_color;
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
