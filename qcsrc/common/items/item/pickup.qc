#include "pickup.qh"
#include <common/items/inventory.qh>

#ifdef SVQC
bool ITEM_HANDLE(Pickup, entity this, entity item, entity player) {
    return this.giveTo(this, item, player);
}

METHOD(Pickup, giveTo, bool(Pickup this, entity item, entity player))
{
    TC(Pickup, this);
    bool b = Item_GiveTo(item, player);
    if (b)
        Inventory_pickupitem(this, player);
    return b;
}

#endif
