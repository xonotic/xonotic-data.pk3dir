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
    ,   respawntime         =         GET(g_pickup_respawntime_short)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_short)
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
    ,   respawntime         =         GET(g_pickup_respawntime_short)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_short)
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
    ,   respawntime         =         GET(g_pickup_respawntime_medium)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_medium)
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
    ,   respawntime         =         GET(g_pickup_respawntime_long)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_long)
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
