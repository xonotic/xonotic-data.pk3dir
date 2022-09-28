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
    if (b) {
        //LOG_DEBUGF("entity %i picked up %s", player, this.m_name);
        entity store = IS_PLAYER(player) ? PS(player) : player;
        store.inventory.inv_items[this.m_id]++;
        Inventory_update(store);
    }
    return b;
}

#endif
