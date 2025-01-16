#include "fuelregen.qh"

#ifdef SVQC
#include <common/items/item/ammo.qh>

METHOD(JetpackRegen, m_spawnfunc_hookreplace, GameItem(JetpackRegen this, entity e))
{
	if (start_items & ITEM_JetpackRegen.m_itemid)
		return ITEM_JetpackFuel;
	return this;
}
#endif
