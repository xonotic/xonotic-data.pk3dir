#include "veil.qh"

#ifdef SVQC
#include "entrap.qh"

void nade_veil_touch(entity this, entity toucher)
{
	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity real_toucher = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;

		float tint_alpha = 0.75;
		if(SAME_TEAM(toucher, this.realowner))
		{
			tint_alpha = 0.45;
			if(!real_toucher.nade_veil_time)
			{
				toucher.nade_veil_prevalpha = toucher.alpha;
				toucher.alpha = -1;
			}
		}
		real_toucher.nade_veil_time = time + 0.1;
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
#ifdef MENUQC
#include "darkness.qh"

METHOD(VeilNade, describe, string(VeilNade this))
{
	TC(VeilNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
	      "Players inside the orb will be invisible to those outside it."), COLORED_NAME(this));
	PAR(_("This is sort of the opposite of the %s."), COLORED_NAME(NADE_TYPE_DARKNESS));
	return PAGE_TEXT;
}
#endif // MENUQC
