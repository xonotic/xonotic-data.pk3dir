#include "armor.qh"
#include "../../../server/t_items.qh"

#define REGISTER_ARMOR(id, model, sound, resp, name, itemid, botvalue)  \
REGISTER_ITEM(id, Armor, LAMBDA({                                       \
    this.m_model = model;                                               \
    this.m_sound = sound;                                               \
    this.m_respawntime = resp;                                          \
    this.m_respawntimejitter = resp;                                    \
    this.m_name = name;                                                 \
    this.m_itemid = itemid;                                             \
    this.m_botvalue = botvalue;                                         \
}))

REGISTER_ARMOR(ArmorSmall
    , "models/items/item_armor_small.md3"
    , "misc/armor1.wav"
    , SPAWNTIME_SHORT
    , "5 Armor"
    , IT_ARMOR_SHARD
    , BOT_PICKUP_RATING_LOW
)

REGISTER_ARMOR(ArmorMedium
    , "models/items/item_armor_medium.md3"
    , "misc/armor10.wav"
    , SPAWNTIME_MEDIUM
    , "25 Armor"
    , IT_ARMOR
    , BOT_PICKUP_RATING_MID
)

REGISTER_ARMOR(ArmorBig
    , "models/items/item_armor_big.md3"
    , "misc/armor17_5.wav"
    , SPAWNTIME_LONG
    , "50 Armor"
    , IT_ARMOR
    , 20000 // FIXME: higher than BOT_PICKUP_RATING_HIGH?
)

REGISTER_ARMOR(ArmorLarge
    , "models/items/item_armor_large.md3"
    , "misc/armor25.wav"
    , SPAWNTIME_LONG
    , "100 Armor"
    , IT_ARMOR
    , BOT_PICKUP_RATING_HIGH
)
