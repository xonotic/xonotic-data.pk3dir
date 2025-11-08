#include "entrap.qh"

#ifdef SVQC
#include "veil.qh"

void nade_entrap_touch(entity this, entity toucher)
{
	if(DIFF_TEAM(toucher, this.realowner)) // TODO: what if realowner changes team or disconnects?
	{
		if (!isPushable(toucher))
			return;

		float pushdeltatime = time - toucher.lastpushtime;
		if (pushdeltatime > 0.15) pushdeltatime = 0;
		toucher.lastpushtime = time;
		if(!pushdeltatime) return;

		// div0: ticrate independent, 1 = identity (not 20)
		toucher.velocity = toucher.velocity * (autocvar_g_nades_entrap_strength ** pushdeltatime);

	#ifdef SVQC
		UpdateCSQCProjectile(toucher);
	#endif
	}

	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity real_toucher = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;
		real_toucher.nade_entrap_time = time + 0.1;
	}
}

void nade_entrap_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_entrap_time, autocvar_g_nades_entrap_radius);

	settouch(orb, nade_entrap_touch);
	orb.colormod = NADE_TYPE_ENTRAP.m_color;
}

MUTATOR_HOOKFUNCTION(nades, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(player.nade_entrap_time > time)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_nades_entrap_speed;
}

MUTATOR_HOOKFUNCTION(nades, MonsterMove)
{
	entity mon = M_ARGV(0, entity);

	if (mon.nade_entrap_time > time)
	{
		M_ARGV(1, float) *= autocvar_g_nades_entrap_speed; // run speed
		M_ARGV(2, float) *= autocvar_g_nades_entrap_speed; // walk speed
	}

	if (mon.nade_veil_time && mon.nade_veil_time <= time)
	{
		mon.alpha = mon.nade_veil_prevalpha;
		mon.nade_veil_time = 0;
	}
}
#endif // SVQC
#ifdef MENUQC
METHOD(EntrapNade, describe, string(EntrapNade this))
{
	TC(EntrapNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
	      "Players and projectiles that enter the sphere will be slowed down, including yourself."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
