#include "ammo.qh"

#ifdef MENUQC
#include <common/weapons/all.qh>

METHOD(Ammo, describe, string(Ammo this))
{
    TC(Ammo, this);
    entity ammo = GetAmmoResource(this);
    string s = sprintf(_("The %s ammo type is used by the:"), COLORED_NAME(this));
    FOREACH(Weapons, it.ammo_type == ammo, {
        s = strcat(s, "\n  ", COLORED_NAME(it));
    });
	const string nname = this.netname == "bullets" ? "nails" : this.netname;
	s = sprintf(_("%s\n\nBy default, the pickup gives you %s ammo, to a maximum of %s."),
		s, cvar_defstring(strcat("g_pickup_", nname)), cvar_defstring(sprintf("g_pickup_%s_max", nname)));
	// TODO: rename all *nails* cvars to bullets
    return s;
}

METHOD(Fuel, describe, string(Fuel this))
{
	TC(Fuel, this);
	string s = sprintf(_("The %s ammo type is used by the %s."),
	COLORED_NAME(this), COLORED_NAME(ITEM_Jetpack));
	s = sprintf(_("%s\n\nBy default, the pickup gives you %s ammo, to a maximum of %s."),
		s, cvar_defstring("g_pickup_fuel"), cvar_defstring("g_pickup_fuel_max"));
	return s;
}
#endif
