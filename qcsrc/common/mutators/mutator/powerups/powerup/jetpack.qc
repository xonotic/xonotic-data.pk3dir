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
