#ifndef TURRET_TESLA_H
#define TURRET_TESLA_H

#include "tesla_weapon.qc"

CLASS(TeslaCoil, Turret)
/* spawnflags */ ATTRIB(TeslaCoil, spawnflags, int, TUR_FLAG_HITSCAN | TUR_FLAG_PLAYER | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(TeslaCoil, mins, vector, '-60 -60 0');
/* maxs       */ ATTRIB(TeslaCoil, maxs, vector, '60 60 128');
/* modelname  */ ATTRIB(TeslaCoil, mdl, string, "tesla_base.md3");
/* model      */ ATTRIB(TeslaCoil, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(TeslaCoil, head_model, string, strzone(strcat("models/turrets/", "tesla_head.md3")));
/* netname    */ ATTRIB(TeslaCoil, netname, string, "tesla");
/* fullname   */ ATTRIB(TeslaCoil, turret_name, string, _("Tesla Coil"));
    ATTRIB(TeslaCoil, m_weapon, Weapon, WEP_TESLA);
ENDCLASS(TeslaCoil)
REGISTER_TURRET(TESLA, NEW(TeslaCoil));

#endif

#ifdef IMPLEMENTATION

#include "tesla_weapon.qc"

#ifdef SVQC

spawnfunc(turret_tesla) { if (!turret_initialize(TUR_TESLA)) remove(self); }

METHOD(TeslaCoil, tr_think, void(TeslaCoil thistur))
{
    if(!self.active)
    {
        self.tur_head.avelocity = '0 0 0';
        return;
    }

    if(self.ammo < self.shot_dmg)
    {
        self.tur_head.avelocity = '0 45 0' * (self.ammo / self.shot_dmg);
    }
    else
    {
        self.tur_head.avelocity = '0 180 0' * (self.ammo / self.shot_dmg);

        if(self.attack_finished_single > time)
            return;

        float f;
        f = (self.ammo / self.ammo_max);
        f = f * f;
        if(f > random())
            if(random() < 0.1)
                te_csqc_lightningarc(self.tur_shotorg,self.tur_shotorg + (randomvec() * 350));
    }
}

float turret_tesla_firecheck();
METHOD(TeslaCoil, tr_setup, void(TeslaCoil this, entity it))
{
    it.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                         TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

    it.turret_firecheckfunc = turret_tesla_firecheck;
    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                       TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

    it.firecheck_flags	= TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AMMO_OWN;
    it.shoot_flags		= TFL_SHOOT_CUSTOM;
    it.ammo_flags			= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags			= TFL_AIM_NO;
    it.track_flags		= TFL_TRACK_NO;
}

float turret_tesla_firecheck()
{SELFPARAM();
    // g_turrets_targetscan_maxdelay forces a target re-scan at least this often
    float do_target_scan = 0;

    if((self.target_select_time + autocvar_g_turrets_targetscan_maxdelay) < time)
        do_target_scan = 1;

    // Old target (if any) invalid?
    if(self.target_validate_time < time)
    if (turret_validate_target(self, self.enemy, self.target_validate_flags) <= 0)
    {
        self.enemy = world;
        self.target_validate_time = time + 0.5;
        do_target_scan = 1;
    }

    // But never more often then g_turrets_targetscan_mindelay!
    if (self.target_select_time + autocvar_g_turrets_targetscan_mindelay > time)
        do_target_scan = 0;

    if(do_target_scan)
    {
        self.enemy = turret_select_target();
        self.target_select_time = time;
    }

    if(!turret_firecheck())
        return 0;

    if(self.enemy)
        return 1;

    return 0;
}

#endif
#endif
