#include "mlrs.qh"

#ifdef SVQC

spawnfunc(turret_mlrs) { if (!turret_initialize(this, TUR_MLRS)) delete(this); }

METHOD(MLRSTurret, tr_think, void(MLRSTurret thistur, entity it))
{
    // 0 = full, 6 = empty
    it.tur_head.frame = bound(0, 6 - floor(0.1 + it.ammo / it.shot_dmg), 6);
    if(it.tur_head.frame < 0)
    {
        LOG_TRACE("ammo:",ftos(it.ammo));
        LOG_TRACE("shot_dmg:",ftos(it.shot_dmg));
    }
}
METHOD(MLRSTurret, tr_setup, void(MLRSTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;

    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.shoot_flags  |= TFL_SHOOT_VOLLYALWAYS;
    it.volly_counter = it.shot_volly;
}

#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/devastator.qh>

METHOD(MLRSTurret, describe, string(MLRSTurret this))
{
    TC(MLRSTurret, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s fires a rapid burst of 6 rockets similar to those of the %s towards its targets."), COLORED_NAME(this), COLORED_NAME(WEP_DEVASTATOR));
    PAR(_("Getting caught in the line of fire of this turret can be very deadly, "
          "but thankfully it doesn't shoot if you get too close, so as to not damage itself."));
    return PAGE_TEXT;
}

#endif // MENUQC
