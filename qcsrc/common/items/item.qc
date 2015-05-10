#include "item.qh"

bool GameItem_respondTo(entity this, int request)
{
    switch (request) {
        default: return false;
        case ITEM_SIGNAL(Default):
            print("Item responding\n");
            return true;
    }
}
