#include "health.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#ifndef MENUQC
MODEL(HealthSmall_ITEM, Item_Model("g_h1.md3"));
#endif

REGISTER_ITEM(HealthSmall, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthSmall_ITEM;
#endif
    this.m_sound                =   "misc/minihealth.wav";
    this.m_name                 =   "5 Health";
    this.m_icon                 =   "health";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemid               =   IT_5HP;
    this.m_respawntime          =   GET(g_pickup_respawntime_short);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_short);
#endif
}

#ifndef MENUQC
MODEL(HealthMedium_ITEM, Item_Model("g_h25.md3"));
#endif

REGISTER_ITEM(HealthMedium, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthMedium_ITEM;
#endif
    this.m_sound                =   "misc/mediumhealth.wav";
    this.m_name                 =   "25 Health";
    this.m_icon                 =   "health";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_MID;
    this.m_itemid               =   IT_25HP;
    this.m_respawntime          =   GET(g_pickup_respawntime_short);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_short);
#endif
}

#ifndef MENUQC
MODEL(HealthLarge_ITEM, Item_Model("g_h50.md3"));
#endif

REGISTER_ITEM(HealthLarge, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthLarge_ITEM;
#endif
    this.m_sound                =   "misc/mediumhealth.wav";
    this.m_name                 =   "50 Health";
    this.m_icon                 =   "health";
    this.m_color                =   '1 0 0';
    this.m_waypoint             =   _("Large health");
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_MID;
    this.m_itemid               =   IT_25HP;
    this.m_respawntime          =   GET(g_pickup_respawntime_medium);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_medium);
#endif
}

#ifndef MENUQC
MODEL(HealthMega_ITEM, Item_Model("g_h100.md3"));
#endif

REGISTER_ITEM(HealthMega, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthMega_ITEM;
#endif
    this.m_sound                =   "misc/megahealth.wav";
    this.m_name                 =   "100 Health";
    this.m_icon                 =   "item_mega_health";
    this.m_color                =   '1 0 0';
    this.m_waypoint             =   _("Mega health");
    this.m_waypointblink        =   2;
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_HIGH;
    this.m_itemid               =   IT_HEALTH;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}
