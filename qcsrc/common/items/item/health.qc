#include "health.qh"
#include "../../../server/t_items.qh"

#define REGISTER_HEALTH(id, model, sound, resp, name, itemid, botvalue) \
REGISTER_ITEM(id, Health, LAMBDA({                                      \
    this.m_model = model;                                               \
    this.m_sound = sound;                                               \
    this.m_respawntime = resp;                                          \
    this.m_respawntimejitter = resp;                                    \
    this.m_name = name;                                                 \
    this.m_itemid = itemid;                                             \
    this.m_botvalue = botvalue;                                         \
}))

REGISTER_HEALTH(HealthSmall
    , "models/items/g_h1.md3"
    , "misc/minihealth.wav"
    , SPAWNTIME_SHORT
    , "5 Health"
    , IT_5HP
    , BOT_PICKUP_RATING_LOW
)

REGISTER_HEALTH(HealthMedium
    , "models/items/g_h25.md3"
    , "misc/mediumhealth.wav"
    , SPAWNTIME_SHORT
    , "25 Health"
    , IT_25HP
    , BOT_PICKUP_RATING_MID
)

REGISTER_HEALTH(HealthLarge
    , "models/items/g_h50.md3"
    , "misc/mediumhealth.wav"
    , SPAWNTIME_MEDIUM
    , "50 Health"
    , IT_25HP
    , BOT_PICKUP_RATING_MID
)

REGISTER_HEALTH(HealthMega
    , "models/items/g_h100.md3"
    , "misc/megahealth.wav"
    , SPAWNTIME_LONG
    , "100 Health"
    , IT_HEALTH
    , BOT_PICKUP_RATING_HIGH
)
