#ifndef TURRET_TESLA_WEAPON_H
#define TURRET_TESLA_WEAPON_H

CLASS(TeslaCoilTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(TeslaCoilTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
/* impulse   */ ATTRIB(TeslaCoilTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(TeslaCoilTurretAttack, netname, string, "turret_tesla");
/* wepname   */ ATTRIB(TeslaCoilTurretAttack, message, string, _("Tesla Coil"));
ENDCLASS(TeslaCoilTurretAttack)
REGISTER_WEAPON(TESLA, NEW(TeslaCoilTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

entity toast(entity from, float range, float damage);
METHOD(TeslaCoilTurretAttack, wr_think, void(entity thiswep, bool fire1, bool fire2)) {
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

        if (t == NULL) return;

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

#endif

#endif
