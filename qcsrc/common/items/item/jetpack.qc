#ifdef SVQC
    #include "../../../server/t_items.qh"
    #include "../../../server/constants.qh"
#endif

#include "ammo.qh"
#include "powerup.qh"

REGISTER_ITEM(Jetpack, Powerup) {
    this.m_model                =   "models/items/g_jetpack.md3";
    this.m_name                 =   "Jet pack";
    this.m_icon                 =   "jetpack";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemid               =   IT_JETPACK;
    this.m_pickupevalfunc       =   commodity_pickupevalfunc;
#endif
}

REGISTER_ITEM(JetpackFuel, Ammo) {
    this.m_model    =   "models/items/g_fuel.md3";
    this.m_name     =   "Fuel";
    this.m_icon     =   "ammo_fuel";
#ifdef SVQC
    this.m_botvalue =   BOT_PICKUP_RATING_LOW;
    this.m_itemid   =   IT_FUEL;
#endif
}

REGISTER_ITEM(JetpackRegen, Pickup) {
    this.m_model                =   "models/items/g_fuelregen.md3";
    this.m_name                 =   "Fuel regenerator";
    this.m_icon                 =   "fuelregen";
#ifdef SVQC
    this.m_botvalue             =   BOT_PICKUP_RATING_LOW;
    this.m_itemflags            =   FL_POWERUP;
    this.m_itemid               =   IT_FUEL_REGEN;
    this.m_pickupevalfunc       =   commodity_pickupevalfunc;
    this.m_respawntime          =   GET(g_pickup_respawntime_powerup);
    this.m_respawntimejitter    =   GET(g_pickup_respawntimejitter_powerup);
#endif
}
