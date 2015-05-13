#include "powerup.qh"
#include "../../../server/t_items.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)
#define DEFINE(id, ...)                                                     \
    REGISTER_ITEM(id, Ammo, LAMBDA(                                         \
        IF(SV, CONFIGURE                                                    \
        ,   botvalue            =   100000                                  \
        ,   itemflags           =   FL_POWERUP                              \
        ,   respawntime         =         GET(g_pickup_respawntime_powerup) \
        ,   respawntimejitter   =   GET(g_pickup_respawntimejitter_powerup) \
        )                                                                   \
        MAP(IDENTITY, __VA_ARGS__)                                          \
    ))

DEFINE(Strength
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_strength.md3"
    ,   sound               =   "misc/powerup.wav"
    ,   name                =   "Strength Powerup"
    )
    ,IF(SV, CONFIGURE
    ,   itemid              =   IT_STRENGTH
    )
)
DEFINE(Shield
    ,APPLY(CONFIGURE
    ,   model               =   "models/items/g_invincible.md3"
    ,   sound               =   "misc/powerup_shield.wav"
    ,   name                =   "Shield"
    )
    ,IF(SV, CONFIGURE
    ,   itemid              =   IT_INVINCIBLE
    )
)

#undef WITH
#undef CONFIGURE
#undef DEFINE
