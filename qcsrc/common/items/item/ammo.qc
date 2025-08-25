#include "ammo.qh"

#ifdef MENUQC
#include <common/weapons/all.qh>

METHOD(Ammo, describe, string(Ammo this))
{
	TC(Ammo, this);
	entity ammo = GetAmmoResource(this);
	PAGE_TEXT_INIT();
	PAR(_("The %s ammo type is used by the:"), COLORED_NAME(this));
	FOREACH(Weapons, it.ammo_type == ammo, {
		PAGE_TEXT = strcat(PAGE_TEXT, "\n* ", COLORED_NAME(it));
	});
	const string nname = this.netname == "bullets" ? "nails" : this.netname;
	PAR(_("By default, the pickup gives you ^9%s^7 ammo, to a maximum of %s."), cvar_defstring(strcat("g_pickup_", nname)), cvar_defstring(sprintf("g_pickup_%s_max", nname)));
	return PAGE_TEXT;
	// TODO: rename all *nails* cvars to bullets
}

METHOD(Fuel, describe, string(Fuel this))
{
	TC(Fuel, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s ammo type is used by the %s."), COLORED_NAME(this), COLORED_NAME(ITEM_Jetpack));
	PAR(_("By default, the pickup gives you ^9%s^7 ammo, to a maximum of %s."), cvar_defstring("g_pickup_fuel"), cvar_defstring("g_pickup_fuel_max"));
	return PAGE_TEXT;
}
#endif
