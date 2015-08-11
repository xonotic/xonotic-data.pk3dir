#include "../../common/items/item.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)

float instagib_respawntime_ammo = 45;
float instagib_respawntimejitter_ammo = 0;
GETTER(float, instagib_respawntime_ammo)
GETTER(float, instagib_respawntimejitter_ammo)

REGISTER_ITEM(VaporizerCells, Pickup, ) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/a_cells.md3"
    ,   sound               =   "misc/itempickup.wav"
    ,   name                =   "Vaporizer Ammo"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   100
    ,   itemid              =   IT_CELLS
    ,   respawntime         =         GET(instagib_respawntime_ammo)
    ,   respawntimejitter   =   GET(instagib_respawntimejitter_ammo)
    )
}

REGISTER_ITEM(ExtraLife, Pickup, ) {
    APPLY(CONFIGURE
    ,   model               =   "models/items/g_h100.md3"
    ,   sound               =   "misc/megahealth.wav"
    ,   name                =   "Extralife"
    )
    IF(SV, CONFIGURE
    ,   botvalue            =   BOT_PICKUP_RATING_HIGH
    ,   itemflags           =   FL_POWERUP
    ,   itemid              =   IT_NAILS
    ,   respawntime         =         GET(g_pickup_respawntime_powerup)
    ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_powerup)
    )
}

#undef WITH
#undef CONFIGURE
