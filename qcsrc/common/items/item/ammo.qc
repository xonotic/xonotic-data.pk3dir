#include "ammo.qh"
#include "../../../server/t_items.qh"

#define REGISTER_AMMO(id, model, sound, name, itemid, basevalue) \
REGISTER_ITEM(id, Ammo, LAMBDA({    \
    this.ammoModel = model;         \
    this.ammoSound = sound;         \
    this.ammoName = name;           \
    this.ammoId = itemid;           \
    this.ammoQuantity = basevalue;  \
}))

REGISTER_AMMO(Bullets,
    "models/items/a_bullets.mdl",
    "misc/itempickup.wav",
    "bullets",
    IT_NAILS,
    2000
)
REGISTER_AMMO(Cells,
    "models/items/a_cells.md3",
    "misc/itempickup.wav",
    "cells",
    IT_ROCKETS,
    2000
)
REGISTER_AMMO(Plasma,
    "models/items/a_cells.md3",
    "misc/itempickup.wav",
    "plasma",
    IT_ROCKETS,
    2000
)
REGISTER_AMMO(Rockets,
    "models/items/a_rockets.md3",
    "misc/itempickup.wav",
    "rockets",
    IT_ROCKETS,
    3000
)
REGISTER_AMMO(Shells,
    "models/items/a_shells.md3",
    "misc/itempickup.wav",
    "shells",
    IT_SHELLS,
    500
)

bool Ammo_respondTo(entity this, int request)
{
    switch (request) {
        default: return false;
        case ITEM_SIGNAL(Default):
            print(strcat(this.ammoName, " responding\n"));
            return true;
    }
}
