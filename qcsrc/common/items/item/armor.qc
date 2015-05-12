#include "armor.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;

#define REGISTER_ARMOR(id, ...)         \
    REGISTER_ITEM(id, Armor, LAMBDA({   \
        MAP(WITH, __VA_ARGS__)          \
    }))

REGISTER_ARMOR(ArmorSmall
    , model             = "models/items/item_armor_small.md3"
    , sound             = "misc/armor1.wav"
    , respawntime       = SPAWNTIME_SHORT
    , respawntimejitter = SPAWNTIME_SHORT
    , name              = "5 Armor"
    , itemid            = IT_ARMOR_SHARD
    , botvalue          = BOT_PICKUP_RATING_LOW
)

REGISTER_ARMOR(ArmorMedium
    , model             = "models/items/item_armor_medium.md3"
    , sound             = "misc/armor10.wav"
    , respawntime       = SPAWNTIME_MEDIUM
    , respawntimejitter = SPAWNTIME_MEDIUM
    , name              = "25 Armor"
    , itemid            = IT_ARMOR
    , botvalue          = BOT_PICKUP_RATING_MID
)

REGISTER_ARMOR(ArmorBig
    , model             = "models/items/item_armor_big.md3"
    , sound             = "misc/armor17_5.wav"
    , respawntime       = SPAWNTIME_LONG
    , respawntimejitter = SPAWNTIME_LONG
    , name              = "50 Armor"
    , itemid            = IT_ARMOR
    , botvalue          = 20000 // FIXME: higher than BOT_PICKUP_RATING_HIGH?
)

REGISTER_ARMOR(ArmorLarge
    , model             = "models/items/item_armor_large.md3"
    , sound             = "misc/armor25.wav"
    , respawntime       = SPAWNTIME_LONG
    , respawntimejitter = SPAWNTIME_LONG
    , name              = "100 Armor"
    , itemid            = IT_ARMOR
    , botvalue          = BOT_PICKUP_RATING_HIGH
)

#undef WITH
