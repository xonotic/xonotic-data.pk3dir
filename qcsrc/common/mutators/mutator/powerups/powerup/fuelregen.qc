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
