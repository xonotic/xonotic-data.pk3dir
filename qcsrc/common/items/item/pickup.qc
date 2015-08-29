#include "pickup.qh"

#ifdef SVQC
bool ITEM_HANDLE(Pickup, entity this, entity item, entity player) {
    bool b = this.giveTo(this, item, player);
    if (b) {
        LOG_TRACEF("entity %i picked up %s\n", player, this.m_name);
        player.inventory.inv_items[this.m_id]++;
        Inventory_update(player);
    }
    return b;
}
#endif
