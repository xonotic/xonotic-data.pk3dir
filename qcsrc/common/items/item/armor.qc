#include "armor.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

REGISTER_ITEM(ArmorSmall, Armor) {
    this.m_model                =   "models/items/item_armor_small.md3";
    this.m_sound                =   "misc/armor1.wav";
    this.m_name                 =   "5 Armor";
    this.m_icon                 =   "armor";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemid               =   IT_ARMOR_SHARD;
    this.m_respawntime          =   GET(g_pickup_respawntime_short);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_short);
#endif
}

REGISTER_ITEM(ArmorMedium, Armor) {
    this.m_model                =   "models/items/item_armor_medium.md3";
    this.m_sound                =   "misc/armor10.wav";
    this.m_name                 =   "25 Armor";
    this.m_icon                 =   "armor";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_MID;
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_medium);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_medium);
#endif
}

REGISTER_ITEM(ArmorLarge, Armor) {
    this.m_model                =   "models/items/item_armor_big.md3";
    this.m_sound                =   "misc/armor17_5.wav";
    this.m_name                 =   "50 Armor";
    this.m_icon                 =   "armor";
#ifdef SVQC
    this.m_botvalue             =   20000; // FIXME: higher than BOT_PICKUP_RATING_HIGH?
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}

REGISTER_ITEM(ArmorMega, Armor) {
    this.m_model                =   "models/items/item_armor_large.md3";
    this.m_sound                =   "misc/armor25.wav";
    this.m_name                 =   "100 Armor";
    this.m_icon                 =   "item_large_armor";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_HIGH;
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}
