#include "phaser.qh"

#ifdef SVQC

spawnfunc(turret_phaser) { if (!turret_initialize(this, TUR_PHASER)) delete(this); }

.int fireflag;

METHOD(PhaserTurret, tr_think, void(PhaserTurret thistur, entity it))
{
    if (it.tur_head.frame != 0)
    {
        if (it.fireflag == 1)
        {
            if (it.tur_head.frame == 10)
                it.tur_head.frame = 1;
            else
                it.tur_head.frame = it.tur_head.frame +1;
        }
        else if (it.fireflag == 2 )
        {
            it.tur_head.frame = it.tur_head.frame +1;
            if (it.tur_head.frame == 15)
            {
                it.tur_head.frame = 0;
                it.fireflag = 0;
            }
        }
    }
}
bool turret_phaser_firecheck(entity this);
METHOD(PhaserTurret, tr_setup, void(PhaserTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD;

    it.turret_firecheckfunc = turret_phaser_firecheck;
}
bool turret_phaser_firecheck(entity this)
{
    if (this.fireflag != 0) return false;
    return turret_firecheck(this);
}

#endif // SVQC
#ifdef MENUQC

METHOD(PhaserTurret, describe, string(PhaserTurret this))
{
    TC(PhaserTurret, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a turret that fires an invisible beam of energy towards its targets."), COLORED_NAME(this));
    PAR(_("Looks are deceiving with the %s, since although the beam of energy can't be seen, it constantly deals damage to and slows down players who intercept its path."), COLORED_NAME(this));
    return PAGE_TEXT;
}

#endif // MENUQC
