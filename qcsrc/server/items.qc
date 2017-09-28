#include "items.qh"

/// \file
/// \brief Source file that contains implementation of the functions related to
/// game items.
/// \copyright GNU GPLv2 or any later version.

.bool m_isloot; ///< Holds whether item is loot.

bool Item_IsLoot(entity e)
{
	return e.m_isloot || (e.classname == "droppedweapon");
}

void Item_SetLoot(entity e, bool isloot)
{
	e.m_isloot = isloot;
}
