#include "ammo.qh"

#define REGISTER_AMMO(id) REGISTER_ITEM(id, Ammo, LAMBDA(this.ammoName = #id))
REGISTER_AMMO(nails)
REGISTER_AMMO(rockets)
REGISTER_AMMO(cells)
REGISTER_AMMO(plasma)
REGISTER_AMMO(fuel)

bool Ammo_respondTo(entity this, int request)
{
    switch (request) {
        default: return false;
        case ITEM_SIGNAL(Default):
            print(strcat(this.ammoName, " responding\n"));
            return true;
    }
}
