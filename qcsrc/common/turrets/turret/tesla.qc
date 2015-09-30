#ifndef TUR_TESLA_H
#define TUR_TESLA_H

CLASS(TeslaCoil, Turret)
/* spawnflags */ ATTRIB(TeslaCoil, spawnflags, int, TUR_FLAG_HITSCAN | TUR_FLAG_PLAYER | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(TeslaCoil, mins, vector, '-60 -60 0');
/* maxs       */ ATTRIB(TeslaCoil, maxs, vector, '60 60 128');
/* modelname  */ ATTRIB(TeslaCoil, mdl, string, "tesla_base.md3");
/* model      */ ATTRIB(TeslaCoil, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(TeslaCoil, head_model, string, strzone(strcat("models/turrets/", "tesla_head.md3")));
/* netname    */ ATTRIB(TeslaCoil, netname, string, "tesla");
/* fullname   */ ATTRIB(TeslaCoil, turret_name, string, _("Tesla Coil"));
ENDCLASS(TeslaCoil)

REGISTER_TURRET(TESLA, NEW(TeslaCoil));

CLASS(TeslaCoilTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(TeslaCoilTurretAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(TeslaCoilTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(TeslaCoilTurretAttack, netname, string, "turret_tesla");
/* wepname   */ ATTRIB(TeslaCoilTurretAttack, message, string, _("Tesla Coil"));
ENDCLASS(TeslaCoilTurretAttack)
REGISTER_WEAPON(TESLA, NEW(TeslaCoilTurretAttack));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
entity toast(entity from, float range, float damage);
METHOD(TeslaCoilTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(self);
            W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            self.tur_shotdir_updated = w_shotdir;
            self.tur_shotorg = w_shotorg;
            self.tur_head = self;
            weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }

        float d = self.shot_dmg;
        float r = self.target_range;
        entity e = spawn();
        setorigin(e,self.tur_shotorg);

        self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

        entity t = toast(e,r,d);
        remove(e);

        if (t == NULL) return true;

        self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_TEAMCHECK;

        self.attack_finished_single = time + self.shot_refire;
        for (int i = 0; i < 10; ++i) {
            d *= 0.75;
            r *= 0.85;
            t = toast(t, r, d);
            if (t == world) break;

        }

        e = findchainfloat(railgunhit, 1);
        while (e) {
            e.railgunhit = 0;
            e = e.chain;
        }

    }
    return true;
}

entity toast(entity from, float range, float damage)
{SELFPARAM();
    entity e;
    entity etarget = world;
    float d,dd;
    float r;

    dd = range + 1;

    e = findradius(from.origin,range);
    while (e)
    {
        if ((e.railgunhit != 1) && (e != from))
        {
            r = turret_validate_target(self,e,self.target_validate_flags);
            if (r > 0)
            {
                traceline(from.origin,0.5 * (e.absmin + e.absmax),MOVE_WORLDONLY,from);
                if (trace_fraction == 1.0)
                {
                    d = vlen(e.origin - from.origin);
                    if (d < dd)
                    {
                        dd = d;
                        etarget = e;
                    }
                }
            }
        }
        e = e.chain;
    }

    if (etarget)
    {
        te_csqc_lightningarc(from.origin,etarget.origin);
        Damage(etarget, self, self, damage, DEATH_TURRET_TESLA, etarget.origin, '0 0 0');
        etarget.railgunhit = 1;
    }

    return etarget;
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

void spawnfunc_turret_tesla() { SELFPARAM(); if(!turret_initialize(TUR_TESLA.m_id)) remove(self); }

        METHOD(TeslaCoil, tr_attack, void(TeslaCoil thistur))
        {
            Weapon wep = WEP_TESLA;
            wep.wr_think(wep, true, false);
        }
        METHOD(TeslaCoil, tr_think, bool(TeslaCoil thistur))
        {
            if(!self.active)
            {
                self.tur_head.avelocity = '0 0 0';
                return true;
            }

            if(self.ammo < self.shot_dmg)
            {
                self.tur_head.avelocity = '0 45 0' * (self.ammo / self.shot_dmg);
            }
            else
            {
                self.tur_head.avelocity = '0 180 0' * (self.ammo / self.shot_dmg);

                if(self.attack_finished_single > time)
                    return true;

                float f;
                f = (self.ammo / self.ammo_max);
                f = f * f;
                if(f > random())
                    if(random() < 0.1)
                        te_csqc_lightningarc(self.tur_shotorg,self.tur_shotorg + (randomvec() * 350));
            }

            return true;
        }
        METHOD(TeslaCoil, tr_death, bool(TeslaCoil thistur))
        {
            return true;
        }
        METHOD(TeslaCoil, tr_setup, bool(TeslaCoil thistur))
        {
            self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                                 TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

            self.turret_firecheckfunc = turret_tesla_firecheck;
            self.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                               TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

            self.firecheck_flags	= TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AMMO_OWN;
            self.shoot_flags		= TFL_SHOOT_CUSTOM;
            self.ammo_flags			= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.aim_flags			= TFL_AIM_NO;
            self.track_flags		= TFL_TRACK_NO;

            return true;
        }
        METHOD(TeslaCoil, tr_precache, bool(TeslaCoil thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(TeslaCoil, tr_setup, bool(TeslaCoil thistur))
        {
            return true;
        }
        METHOD(TeslaCoil, tr_precache, bool(TeslaCoil thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
