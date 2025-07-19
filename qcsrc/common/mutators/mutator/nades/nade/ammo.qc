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
		ammo_factor = autocvar_g_nades_ammo_rate*frametime/2;
		if ( toucher != this.realowner )
			ammo_factor *= (SAME_TEAM(toucher, this)) ? autocvar_g_nades_ammo_friend : autocvar_g_nades_ammo_foe;

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
	}
#undef CHECK_AMMO_RESOURCE_LIMIT
#undef DROP_AMMO_RESOURCE

	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity show_tint = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;
		show_tint.nade_ammo_time = time + 0.1;
	}
}

void nade_ammo_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_ammo_time, autocvar_g_nades_nade_radius);

	settouch(orb, nade_ammo_touch);
	orb.colormod = NADE_TYPE_AMMO.m_color;
}
#endif // SVQC
