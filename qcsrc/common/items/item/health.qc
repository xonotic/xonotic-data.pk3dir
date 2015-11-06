#include "health.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#ifndef MENUQC
MODEL(HealthSmall_ITEM, Item_Model("g_h1.md3"));
SOUND(HealthSmall, "misc/minihealth");
#endif

REGISTER_ITEM(HealthSmall, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthSmall_ITEM;
    this.m_sound                =   SND_HealthSmall;
#endif
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
SOUND(HealthMedium, "misc/mediumhealth");
#endif

REGISTER_ITEM(HealthMedium, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthMedium_ITEM;
    this.m_sound                =   SND_HealthMedium;
#endif
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
SOUND(HealthLarge, "misc/mediumhealth");
#endif

REGISTER_ITEM(HealthLarge, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthLarge_ITEM;
    this.m_sound                =   SND_HealthLarge;
#endif
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
SOUND(HealthMega, "misc/megahealth");
#endif

REGISTER_ITEM(HealthMega, Health) {
#ifndef MENUQC
    this.m_model                =   MDL_HealthMega_ITEM;
    this.m_sound                =   SND_HealthMega;
#endif
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
