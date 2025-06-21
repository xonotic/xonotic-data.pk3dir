#include "jetpack.qh"

#ifdef SVQC
#include <common/items/item/ammo.qh>

METHOD(Jetpack, m_spawnfunc_hookreplace, GameItem(Jetpack this, entity e))
{
	if (start_items & ITEM_Jetpack.m_itemid)
		return ITEM_Fuel;
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
#endif
