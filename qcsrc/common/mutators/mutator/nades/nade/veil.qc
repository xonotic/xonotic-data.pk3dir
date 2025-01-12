#include "veil.qh"

#ifdef SVQC
#include "entrap.qh"

void nade_veil_touch(entity this, entity toucher)
{
	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity show_tint = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;

		float tint_alpha = 0.75;
		if(SAME_TEAM(toucher, this.realowner))
		{
			tint_alpha = 0.45;
			if(!show_tint.nade_veil_time)
			{
				toucher.nade_veil_prevalpha = toucher.alpha;
				toucher.alpha = -1;
			}
		}
		show_tint.nade_veil_time = time + 0.1;
	}
}

void nade_veil_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_veil_time, autocvar_g_nades_veil_radius);

	settouch(orb, nade_veil_touch);
	orb.colormod = NADE_TYPE_VEIL.m_color;
}

void nade_veil_Apply(entity player)
{
	if(player.nade_veil_time && player.nade_veil_time <= time)
	{
		player.nade_veil_time = 0;
		if(player.vehicle)
			player.vehicle.alpha = player.vehicle.nade_veil_prevalpha;
		else
			player.alpha = player.nade_veil_prevalpha;
	}
}
#endif // SVQC
