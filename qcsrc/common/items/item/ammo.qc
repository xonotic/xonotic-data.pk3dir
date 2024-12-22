#include "ammo.qh"

#ifdef MENUQC
#include <common/colors.qh>
#include <common/weapons/weapon/_mod.qh>
#include <common/mutators/mutator/overkill/_mod.qh>

METHOD(Shells, describe, string(Shells this))
{
    TC(Shells, this);
    return sprintf(_("The %s ammo type is used by the %s and %s"),
    COLORED_NAME(this), COLORED_NAME(WEP_SHOTGUN), COLORED_NAME(WEP_OVERKILL_SHOTGUN));
}

METHOD(Bullets, describe, string(Bullets this))
{
    TC(Bullets, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, and %s"),
    COLORED_NAME(this), COLORED_NAME(WEP_MACHINEGUN), COLORED_NAME(WEP_RIFLE), COLORED_NAME(WEP_OVERKILL_MACHINEGUN), COLORED_NAME(WEP_OVERKILL_HMG));
}

METHOD(Rockets, describe, string(Rockets this))
{
    TC(Rockets, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, %s, %s, and %s"),
    COLORED_NAME(this), COLORED_NAME(WEP_DEVASTATOR), COLORED_NAME(WEP_MORTAR), COLORED_NAME(WEP_HAGAR), COLORED_NAME(WEP_MINE_LAYER), COLORED_NAME(WEP_SEEKER), COLORED_NAME(WEP_OVERKILL_RPC));
}

METHOD(Cells, describe, string(Cells this))
{
    TC(Cells, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, %s, %s, and %s"),
    COLORED_NAME(this), COLORED_NAME(WEP_VORTEX), COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_ELECTRO), COLORED_NAME(WEP_HLAC), COLORED_NAME(WEP_VAPORIZER), COLORED_NAME(WEP_ARC));
}
#endif
