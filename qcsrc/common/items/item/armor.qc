#include "armor.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#ifndef MENUQC
MODEL(ArmorSmall_ITEM, Item_Model("item_armor_small.md3"));
SOUND(ArmorSmall, "misc/armor1");
#endif

REGISTER_ITEM(ArmorSmall, Armor) {
#ifndef MENUQC
    this.m_model                =   MDL_ArmorSmall_ITEM;
    this.m_sound                =   SND_ArmorSmall;
#endif
    this.m_name                 =   "5 Armor";
    this.m_icon                 =   "armor";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemid               =   IT_ARMOR_SHARD;
    this.m_respawntime          =   GET(g_pickup_respawntime_short);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_short);
#endif
}

#ifndef MENUQC
MODEL(ArmorMedium_ITEM, Item_Model("item_armor_medium.md3"));
SOUND(ArmorMedium, "misc/armor10");
#endif

REGISTER_ITEM(ArmorMedium, Armor) {
#ifndef MENUQC
    this.m_model                =   MDL_ArmorMedium_ITEM;
    this.m_sound                =   SND_ArmorMedium;
#endif
    this.m_name                 =   "25 Armor";
    this.m_icon                 =   "armor";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_MID;
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_medium);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_medium);
#endif
}

#ifndef MENUQC
MODEL(ArmorLarge_ITEM, Item_Model("item_armor_big.md3"));
SOUND(ArmorLarge, "misc/armor17_5");
#endif

REGISTER_ITEM(ArmorLarge, Armor) {
#ifndef MENUQC
    this.m_model                =   MDL_ArmorLarge_ITEM;
    this.m_sound                =   SND_ArmorLarge;
#endif
    this.m_name                 =   "50 Armor";
    this.m_icon                 =   "armor";
    this.m_color                =   '0 1 0';
    this.m_waypoint             =   _("Large armor");
#ifdef SVQC
    this.m_botvalue             =   20000; // FIXME: higher than BOT_PICKUP_RATING_HIGH?
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}

#ifndef MENUQC
MODEL(ArmorMega_ITEM, Item_Model("item_armor_large.md3"));
SOUND(ArmorMega, "misc/armor25");
#endif

REGISTER_ITEM(ArmorMega, Armor) {
#ifndef MENUQC
    this.m_model                =   MDL_ArmorMega_ITEM;
    this.m_sound                =   SND_ArmorMega;
#endif
    this.m_name                 =   "100 Armor";
    this.m_icon                 =   "item_large_armor";
    this.m_color                =   '0 1 0';
    this.m_waypoint             =   _("Mega armor");
    this.m_waypointblink        =   2;
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_HIGH;
    this.m_itemid               =   IT_ARMOR;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}
