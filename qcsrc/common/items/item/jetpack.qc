#ifdef SVQC
    #include "../../../server/t_items.qh"
    #include "../../../server/constants.qh"
#endif

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...) REGISTER_ITEM(id, Pickup, MAP(IDENTITY, __VA_ARGS__))

DEFINE(Jetpack
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_jetpack.md3"
    ,   name                =   "Jet pack"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   itemflags           =   FL_POWERUP
    ,   itemid              =   IT_JETPACK
    ,   pickupevalfunc      =   commodity_pickupevalfunc
    ,   respawntime         =         GET(g_pickup_respawntime_powerup)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_powerup)
    )
)

DEFINE(JetpackFuel
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_fuel.md3"
    ,   name                =   "Fuel"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   itemid              =   IT_FUEL
    ,   pickupevalfunc      =   commodity_pickupevalfunc
    ,   respawntime         =         GET(g_pickup_respawntime_ammo)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_ammo)
    )
)

DEFINE(JetpackRegen
    ,IF(ALL, CONFIGURE
    ,   model               =   "models/items/g_fuelregen.md3"
    ,   name                =   "Fuel regenerator"
    )
    ,IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_LOW
    ,   itemflags           =   FL_POWERUP
    ,   itemid              =   IT_FUEL_REGEN
    ,   pickupevalfunc      =   commodity_pickupevalfunc
    ,   respawntime         =         GET(g_pickup_respawntime_powerup)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_powerup)
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
