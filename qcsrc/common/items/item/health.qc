#include "health.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

REGISTER_ITEM(HealthSmall, Health) {
    this.m_model                =   "models/items/g_h1.md3";
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

REGISTER_ITEM(HealthMedium, Health) {
    this.m_model                =   "models/items/g_h25.md3";
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

REGISTER_ITEM(HealthLarge, Health) {
    this.m_model                =   "models/items/g_h50.md3";
    this.m_sound                =   "misc/mediumhealth.wav";
    this.m_name                 =   "50 Health";
    this.m_icon                 =   "health";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_MID;
    this.m_itemid               =   IT_25HP;
    this.m_respawntime          =   GET(g_pickup_respawntime_medium);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_medium);
#endif
}

REGISTER_ITEM(HealthMega, Health) {
    this.m_model                =   "models/items/g_h100.md3";
    this.m_sound                =   "misc/megahealth.wav";
    this.m_name                 =   "100 Health";
    this.m_icon                 =   "item_mega_health";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_HIGH;
    this.m_itemid               =   IT_HEALTH;
    this.m_respawntime          =   GET(g_pickup_respawntime_long);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_long);
#endif
}
