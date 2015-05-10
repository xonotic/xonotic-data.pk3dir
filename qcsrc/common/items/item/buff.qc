#include "buff.qh"

REGISTER_ITEM(strength, Buff, LAMBDA())

bool Buff_respondTo(entity this, int request)
{
    switch (request) {
        default: return false;
        case ITEM_SIGNAL(Default):
            print("Buff responding\n");
            return true;
    }
}
