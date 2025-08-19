#include "fuelregen.qh"

#ifdef SVQC
#include <common/items/item/ammo.qh>

METHOD(FuelRegen, m_spawnfunc_hookreplace, GameItem(FuelRegen this, entity e))
{
	if (start_items & ITEM_FuelRegen.m_itemid)
		return ITEM_Fuel;
	return this;
}
#endif

#ifdef MENUQC
METHOD(FuelRegen, describe, string(FuelRegen this))
{
	TC(FuelRegen, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s powerup regenerates %s needed for the %s until the powerup expires, "
	      "so you can continue flying around for longer."), COLORED_NAME(this), COLORED_NAME(ITEM_Fuel), COLORED_NAME(ITEM_Jetpack));
	PAR(_("Since it is a powerup, it will drop if you die while holding it.")); // shared message
	return PAGE_TEXT;
}
#endif
