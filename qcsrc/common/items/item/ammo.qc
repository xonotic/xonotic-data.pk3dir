#include "ammo.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...)                             \
    REGISTER_ITEM(id, Ammo, LAMBDA(                 \
        IF(SV, CONFIGURE                            \
        ,   respawntime         = SPAWNTIME_AMMO    \
        ,   respawntimejitter   = SPAWNTIME_AMMO    \
        )                                           \
        MAP(IDENTITY, __VA_ARGS__)                  \
    ))

DEFINE(Bullets
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_bullets.mdl"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "bullets"
    ,   itemid              =   IT_NAILS
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    )
)
DEFINE(Cells
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_cells.md3"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "cells"
    ,   itemid              =   IT_ROCKETS
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    )
)
DEFINE(Plasma
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_cells.md3"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "plasma"
    ,   itemid              =   IT_ROCKETS
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    )
)
DEFINE(Rockets
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_rockets.md3"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "rockets"
    ,   itemid              =   IT_ROCKETS
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   3000
    )
)
DEFINE(Shells
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_shells.md3"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "shells"
    ,   itemid              =   IT_SHELLS
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   500
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
