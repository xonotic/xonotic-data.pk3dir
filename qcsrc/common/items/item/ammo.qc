#include "ammo.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...)                                                 \
    REGISTER_ITEM(id, Ammo, LAMBDA(                                     \
        IF(SV, CONFIGURE                                                \
        ,   respawntime         =       GET(g_pickup_respawntime_ammo)  \
        ,   respawntimejitter   = GET(g_pickup_respawntimejitter_ammo)  \
        )                                                               \
        MAP(IDENTITY, __VA_ARGS__)                                      \
    ))

DEFINE(Bullets
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_bullets.mdl"
    ,   name                =   "bullets"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    ,   itemid              =   IT_NAILS
    )
)
DEFINE(Cells
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_cells.md3"
    ,   name                =   "cells"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    ,   itemid              =   IT_CELLS
    )
)
DEFINE(Plasma
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_cells.md3"
    ,   name                =   "plasma"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   2000
    ,   itemid              =   IT_PLASMA
    )
)
DEFINE(Rockets
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_rockets.md3"
    ,   name                =   "rockets"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   3000
    ,   itemid              =   IT_ROCKETS
    )
)
DEFINE(Shells
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/a_shells.md3"
    ,   name                =   "shells"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   500
    ,   itemid              =   IT_SHELLS
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
