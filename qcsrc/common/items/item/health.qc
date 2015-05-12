#include "health.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...) REGISTER_ITEM(id, Health, MAP(IDENTITY, __VA_ARGS__))

DEFINE(HealthSmall
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_h1.md3"
    ,   sound               =   "misc/minihealth.wav"
    ,   name                =   "5 Health"
    ,   itemid              =   IT_5HP
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   respawntime         =   SPAWNTIME_SHORT
    ,   respawntimejitter   =   SPAWNTIME_SHORT
    )
)

DEFINE(HealthMedium
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_h25.md3"
    ,   sound               =   "misc/mediumhealth.wav"
    ,   name                =   "25 Health"
    ,   itemid              =   IT_25HP
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   respawntime         =   SPAWNTIME_SHORT
    ,   respawntimejitter   =   SPAWNTIME_SHORT
    )
)

DEFINE(HealthLarge
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_h50.md3"
    ,   sound               =   "misc/mediumhealth.wav"
    ,   name                =   "50 Health"
    ,   itemid              =   IT_25HP
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   respawntime         =   SPAWNTIME_MEDIUM
    ,   respawntimejitter   =   SPAWNTIME_MEDIUM
    )
)

DEFINE(HealthMega
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_h100.md3"
    ,   sound               =   "misc/megahealth.wav"
    ,   name                =   "100 Health"
    ,   itemid              =   IT_HEALTH
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_HIGH
    ,   respawntime         =   SPAWNTIME_LONG
    ,   respawntimejitter   =   SPAWNTIME_LONG
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
