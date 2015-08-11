#ifdef SVQC
    #include "../../../server/t_items.qh"
    #include "../../../server/constants.qh"
#endif

REGISTER_ITEM(Jetpack, Pickup) {
    this.m_model                =   "models/items/g_jetpack.md3";
    this.m_name                 =   "Jet pack";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemflags            =   FL_POWERUP;
    this.m_itemid               =   IT_JETPACK;
    this.m_pickupevalfunc       =   commodity_pickupevalfunc;
    this.m_respawntime          =   GET(g_pickup_respawntime_powerup);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_powerup);
#endif
}

REGISTER_ITEM(JetpackFuel, Pickup) {
    this.m_model                =   "models/items/g_fuel.md3";
    this.m_name                 =   "Fuel";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemid               =   IT_FUEL;
    this.m_pickupevalfunc       =   commodity_pickupevalfunc;
    this.m_respawntime          =   GET(g_pickup_respawntime_ammo);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_ammo);
#endif
}

REGISTER_ITEM(JetpackRegen, Pickup) {
    this.m_model                =   "models/items/g_fuelregen.md3";
    this.m_name                 =   "Fuel regenerator";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemflags            =   FL_POWERUP;
    this.m_itemid               =   IT_FUEL_REGEN;
    this.m_pickupevalfunc       =   commodity_pickupevalfunc;
    this.m_respawntime          =   GET(g_pickup_respawntime_powerup);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_powerup);
#endif
}
