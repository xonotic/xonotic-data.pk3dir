#include "pickup.qh"

#ifdef SVQC
bool ITEM_HANDLE(Pickup, entity this, entity item, entity player) {
    return this.giveTo(this, item, player);
}
#endif
