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

#endif
