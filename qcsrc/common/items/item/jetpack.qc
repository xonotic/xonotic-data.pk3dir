#include "jetpack.qh"

#ifdef SVQC
METHOD(Jetpack, m_spawnfunc_hookreplace, GameItem(Jetpack this, entity e))
{
	if (start_items & ITEM_Jetpack.m_itemid)
		return ITEM_JetpackFuel;
	return this;
}

METHOD(JetpackRegen, m_spawnfunc_hookreplace, GameItem(JetpackRegen this, entity e))
{
	if (start_items & ITEM_JetpackRegen.m_itemid)
		return ITEM_JetpackFuel;
	return this;
}
#endif

#ifdef MENUQC
METHOD(Jetpack, describe, string(Jetpack this))
{
	TC(Jetpack, this);
	return sprintf(_("The %s powerup allows you to fly around the map for a short period, "
		"providing increased mobility, maneuverability, and the ability to reach higher ground.\n\n"
		"It consumes Fuel ammo while operating, so make sure you don't run out when you're high up!"),
	COLORED_NAME(this));
}

METHOD(JetpackFuel, describe, string(JetpackFuel this))
{
	TC(JetpackFuel, this);
	string s = sprintf(_("The %s ammo type is used by the %s."),
	COLORED_NAME(this), COLORED_NAME(ITEM_Jetpack));
	s = sprintf(_("%s\n\nBy default, the pickup gives you %s ammo, to a maximum of %s."),
		s, cvar_defstring("g_pickup_fuel"), cvar_defstring("g_pickup_fuel_max"));
	return s;
}

METHOD(JetpackRegen, describe, string(JetpackRegen this))
{
	TC(JetpackRegen, this);
	return sprintf(_("The %s powerup regenerates %s needed for the %s until the powerup expires, "
		"so you can continue flying around for longer.\n\n"
		"Since it is a powerup, it will drop if you die while holding it."),
	COLORED_NAME(this), COLORED_NAME(ITEM_JetpackFuel), COLORED_NAME(ITEM_Jetpack));
}
#endif
