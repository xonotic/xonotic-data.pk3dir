#ifndef TURRET_PHASER_H
#define TURRET_PHASER_H

#include "phaser_weapon.qc"

CLASS(PhaserTurret, Turret)
/* spawnflags */ ATTRIB(PhaserTurret, spawnflags, int, TUR_FLAG_SNIPER | TUR_FLAG_HITSCAN | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(PhaserTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(PhaserTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(PhaserTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(PhaserTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(PhaserTurret, head_model, string, strzone(strcat("models/turrets/", "phaser.md3")));
/* netname    */ ATTRIB(PhaserTurret, netname, string, "phaser");
/* fullname   */ ATTRIB(PhaserTurret, turret_name, string, _("Phaser Cannon"));
    ATTRIB(PhaserTurret, m_weapon, Weapon, WEP_PHASER);
ENDCLASS(PhaserTurret)
REGISTER_TURRET(PHASER, NEW(PhaserTurret));

#endif

#ifdef IMPLEMENTATION

#include "phaser_weapon.qc"

#ifdef SVQC

spawnfunc(turret_phaser) { if (!turret_initialize(TUR_PHASER)) remove(self); }

METHOD(PhaserTurret, tr_think, void(PhaserTurret thistur))
{
    if (self.tur_head.frame != 0)
    {
        if (self.fireflag == 1)
        {
            if (self.tur_head.frame == 10)
                self.tur_head.frame = 1;
            else
                self.tur_head.frame = self.tur_head.frame +1;
        }
        else if (self.fireflag == 2 )
        {
            self.tur_head.frame = self.tur_head.frame +1;
            if (self.tur_head.frame == 15)
            {
                self.tur_head.frame = 0;
                self.fireflag = 0;
            }
        }
    }
}
float turret_phaser_firecheck();
METHOD(PhaserTurret, tr_setup, void(PhaserTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD;

    it.turret_firecheckfunc = turret_phaser_firecheck;
}
float turret_phaser_firecheck()
{
    SELFPARAM();
    if (self.fireflag != 0) return 0;
    return turret_firecheck();
}

#endif
#endif
