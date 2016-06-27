#ifndef TURRET_PHASER_H
#define TURRET_PHASER_H

#include "phaser_weapon.qh"

CLASS(PhaserTurret, Turret)
/* spawnflags */ ATTRIB(PhaserTurret, spawnflags, int, TUR_FLAG_SNIPER | TUR_FLAG_HITSCAN | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(PhaserTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(PhaserTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(PhaserTurret, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(PhaserTurret, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(PhaserTurret, head_model, string, strcat("models/turrets/", "phaser.md3"));
/* netname    */ ATTRIB(PhaserTurret, netname, string, "phaser");
/* fullname   */ ATTRIB(PhaserTurret, turret_name, string, _("Phaser Cannon"));
    ATTRIB(PhaserTurret, m_weapon, Weapon, WEP_PHASER);
ENDCLASS(PhaserTurret)
REGISTER_TURRET(PHASER, NEW(PhaserTurret));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

spawnfunc(turret_phaser) { if (!turret_initialize(this, TUR_PHASER)) remove(this); }

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
#endif
