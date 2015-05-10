#include "ammo.qh"
#include "../../../server/t_items.qh"

#define REGISTER_AMMO(id, model, sound, name, itemid, botvalue) \
REGISTER_ITEM(id, Ammo, LAMBDA({                                \
    this.m_model = model;                                       \
    this.m_sound = sound;                                       \
    this.m_respawntime = SPAWNTIME_AMMO;                        \
    this.m_respawntimejitter = SPAWNTIME_AMMO;                  \
    this.m_name = name;                                         \
    this.m_itemid = itemid;                                     \
    this.m_botvalue = botvalue;                                 \
}))

REGISTER_AMMO(Bullets
    , "models/items/a_bullets.mdl"
    , "misc/itempickup.wav"
    , "bullets"
    , IT_NAILS
    , 2000
)
REGISTER_AMMO(Cells
    , "models/items/a_cells.md3"
    , "misc/itempickup.wav"
    , "cells"
    , IT_ROCKETS
    , 2000
)
REGISTER_AMMO(Plasma
    , "models/items/a_cells.md3"
    , "misc/itempickup.wav"
    , "plasma"
    , IT_ROCKETS
    , 2000
)
REGISTER_AMMO(Rockets
    , "models/items/a_rockets.md3"
    , "misc/itempickup.wav"
    , "rockets"
    , IT_ROCKETS
    , 3000
)
REGISTER_AMMO(Shells
    , "models/items/a_shells.md3"
    , "misc/itempickup.wav"
    , "shells"
    , IT_SHELLS
    , 500
)
