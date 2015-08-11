#include "armor.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id) REGISTER_ITEM(id, Armor, )

DEFINE(ArmorSmall) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/item_armor_small.md3"
    ,   sound               =   "misc/armor1.wav"
    ,   name                =   "5 Armor"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   itemid              =   IT_ARMOR_SHARD
    ,   respawntime         =         GET(g_pickup_respawntime_short)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_short)
    )
}

DEFINE(ArmorMedium) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/item_armor_medium.md3"
    ,   sound               =   "misc/armor10.wav"
    ,   name                =   "25 Armor"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_MID
    ,   itemid              =   IT_ARMOR
    ,   respawntime         =         GET(g_pickup_respawntime_medium)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_medium)
    )
}

DEFINE(ArmorBig) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/item_armor_big.md3"
    ,   sound               =   "misc/armor17_5.wav"
    ,   name                =   "50 Armor"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   20000 // FIXME: higher than BOT_PICKUP_RATING_HIGH?
    ,   itemid              =   IT_ARMOR
    ,   respawntime         =         GET(g_pickup_respawntime_long)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_long)
    )
}

DEFINE(ArmorLarge) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/item_armor_large.md3"
    ,   sound               =   "misc/armor25.wav"
    ,   name                =   "100 Armor"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_HIGH
    ,   itemid              =   IT_ARMOR
    ,   respawntime         =         GET(g_pickup_respawntime_long)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_long)
    )
}

#undef WITH
#undef CONFIGURE
#undef DEFINE
