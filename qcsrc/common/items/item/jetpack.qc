#include "jetpack.qh"

#ifdef SVQC

METHOD(Jetpack, m_spawnfunc_hookreplace, GameItem(Jetpack this, entity e))
{
	if(start_items & ITEM_Jetpack.m_itemid)
	{
		return ITEM_JetpackFuel;
	}
	return this;
}

METHOD(JetpackRegen, m_spawnfunc_hookreplace, GameItem(JetpackRegen this, entity e))
{
	if (start_items & ITEM_JetpackRegen.m_itemid)
	{
		return ITEM_JetpackFuel;
	}
	return this;
}

#endif
