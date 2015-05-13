#include "health.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...) REGISTER_ITEM(id, Health, UNWORDS(__VA_ARGS__))

DEFINE(HealthSmall
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_h1.md3"
    ,   sound               =   "misc/minihealth.wav"
    ,   name                =   "5 Health"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   itemid              =   IT_5HP
    ,   respawntime         =         GET(g_pickup_respawntime_short)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_short)
    )
)

DEFINE(HealthMedium
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_h25.md3"
    ,   sound               =   "misc/mediumhealth.wav"
    ,   name                =   "25 Health"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   itemid              =   IT_25HP
    ,   respawntime         =         GET(g_pickup_respawntime_short)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_short)
    )
)

DEFINE(HealthLarge
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_h50.md3"
    ,   sound               =   "misc/mediumhealth.wav"
    ,   name                =   "50 Health"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   itemid              =   IT_25HP
    ,   respawntime         =         GET(g_pickup_respawntime_medium)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_medium)
    )
)

DEFINE(HealthMega
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_h100.md3"
    ,   sound               =   "misc/megahealth.wav"
    ,   name                =   "100 Health"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_HIGH
    ,   itemid              =   IT_HEALTH
    ,   respawntime         =         GET(g_pickup_respawntime_long)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_long)
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
