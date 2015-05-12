#include "health.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;

#define REGISTER_HEALTH(id, ...)        \
    REGISTER_ITEM(id, Health, LAMBDA({  \
        MAP(WITH, __VA_ARGS__)          \
    }))

REGISTER_HEALTH(HealthSmall
    , model             =   "models/items/g_h1.md3"
    , sound             =   "misc/minihealth.wav"
    , respawntime       =   SPAWNTIME_SHORT
    , respawntimejitter =   SPAWNTIME_SHORT
    , name              =   "5 Health"
    , itemid            =   IT_5HP
    , botvalue          =   BOT_PICKUP_RATING_LOW
)

REGISTER_HEALTH(HealthMedium
    , model             =   "models/items/g_h25.md3"
    , sound             =   "misc/mediumhealth.wav"
    , respawntime       =   SPAWNTIME_SHORT
    , respawntimejitter =   SPAWNTIME_SHORT
    , name              =   "25 Health"
    , itemid            =   IT_25HP
    , botvalue          =   BOT_PICKUP_RATING_MID
)

REGISTER_HEALTH(HealthLarge
    , model             =   "models/items/g_h50.md3"
    , sound             =   "misc/mediumhealth.wav"
    , respawntime       =   SPAWNTIME_MEDIUM
    , respawntimejitter =   SPAWNTIME_MEDIUM
    , name              =   "50 Health"
    , itemid            =   IT_25HP
    , botvalue          =   BOT_PICKUP_RATING_MID
)

REGISTER_HEALTH(HealthMega
    , model             =   "models/items/g_h100.md3"
    , sound             =   "misc/megahealth.wav"
    , respawntime       =   SPAWNTIME_LONG
    , respawntimejitter =   SPAWNTIME_LONG
    , name              =   "100 Health"
    , itemid            =   IT_HEALTH
    , botvalue          =   BOT_PICKUP_RATING_HIGH
)

#undef WITH
