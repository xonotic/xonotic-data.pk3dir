#include "ammo.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;

#define REGISTER_AMMO(id, ...)                      \
    REGISTER_ITEM(id, Ammo, LAMBDA({                \
        MAP(WITH, __VA_ARGS__)                      \
        this.m_respawntime = SPAWNTIME_AMMO;        \
        this.m_respawntimejitter = SPAWNTIME_AMMO;  \
    }))

REGISTER_AMMO(Bullets
    , model     = "models/items/a_bullets.mdl"
    , sound     = "misc/itempickup.wav"
    , name      = "bullets"
    , itemid    = IT_NAILS
    , botvalue  = 2000
)
REGISTER_AMMO(Cells
    , model     = "models/items/a_cells.md3"
    , sound     = "misc/itempickup.wav"
    , name      = "cells"
    , itemid    = IT_ROCKETS
    , botvalue  = 2000
)
REGISTER_AMMO(Plasma
    , model     = "models/items/a_cells.md3"
    , sound     = "misc/itempickup.wav"
    , name      = "plasma"
    , itemid    = IT_ROCKETS
    , botvalue  = 2000
)
REGISTER_AMMO(Rockets
    , model     = "models/items/a_rockets.md3"
    , sound     = "misc/itempickup.wav"
    , name      = "rockets"
    , itemid    = IT_ROCKETS
    , botvalue  = 3000
)
REGISTER_AMMO(Shells
    , model     = "models/items/a_shells.md3"
    , sound     = "misc/itempickup.wav"
    , name      = "shells"
    , itemid    = IT_SHELLS
    , botvalue  = 500
)

#undef WITH
