#include "flac.qh"

#ifdef SVQC

spawnfunc(turret_flac) { if (!turret_initialize(this, TUR_FLAC)) delete(this); }

METHOD(Flac, tr_setup, void(Flac this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;
}

#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/devastator.qh>
#include <common/weapons/weapon/electro.qh>
#include <common/weapons/weapon/mortar.qh>

METHOD(Flac, describe, string(Flac this))
{
    TC(Flac, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a turret similar to flak cannons, instead firing anti-projectile flak shells to take down projectiles fired by its targets."), COLORED_NAME(this));
    PAR(_("The shells it shoots target projectiles such as the %s secondary fire grenade, %s secondary fire balls, %s rockets, and other missiles."), COLORED_NAME(WEP_MORTAR), COLORED_NAME(WEP_ELECTRO), COLORED_NAME(WEP_DEVASTATOR));
    return PAGE_TEXT;
}

#endif // MENUQC
