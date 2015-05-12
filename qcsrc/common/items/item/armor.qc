#include "armor.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...) REGISTER_ITEM(id, Armor, MAP(IDENTITY, __VA_ARGS__))

DEFINE(ArmorSmall
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/item_armor_small.md3"
    ,   sound               =   "misc/armor1.wav"
    ,   name                =   "5 Armor"
    ,   itemid              =   IT_ARMOR_SHARD
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   respawntime         =         g_pickup_respawntime_short
    ,   respawntimejitter   =   g_pickup_respawntimejitter_short
    )
)

DEFINE(ArmorMedium
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/item_armor_medium.md3"
    ,   sound               =   "misc/armor10.wav"
    ,   name                =   "25 Armor"
    ,   itemid              =   IT_ARMOR
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   respawntime         =         g_pickup_respawntime_medium
    ,   respawntimejitter   =   g_pickup_respawntimejitter_medium
    )
)

DEFINE(ArmorBig
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/item_armor_big.md3"
    ,   sound               =   "misc/armor17_5.wav"
    ,   name                =   "50 Armor"
    ,   itemid              =   IT_ARMOR
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   20000 // FIXME: higher than BOT_PICKUP_RATING_HIGH?
    ,   respawntime         =         g_pickup_respawntime_long
    ,   respawntimejitter   =   g_pickup_respawntimejitter_long
    )
)

DEFINE(ArmorLarge
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/item_armor_large.md3"
    ,   sound               =   "misc/armor25.wav"
    ,   name                =   "100 Armor"
    ,   itemid              =   IT_ARMOR
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_HIGH
    ,   respawntime         =         g_pickup_respawntime_long
    ,   respawntimejitter   =   g_pickup_respawntimejitter_long
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
