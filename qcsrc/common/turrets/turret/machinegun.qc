#ifndef TUR_MACHINEGUN_H
#define TUR_MACHINEGUN_H

CLASS(MachineGunTurret, Turret)
/* spawnflags */ ATTRIB(MachineGunTurret, spawnflags, int, TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MachineGunTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MachineGunTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MachineGunTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(MachineGunTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(MachineGunTurret, head_model, string, strzone(strcat("models/turrets/", "machinegun.md3")));
/* netname    */ ATTRIB(MachineGunTurret, netname, string, "machinegun");
/* fullname   */ ATTRIB(MachineGunTurret, turret_name, string, _("Machinegun Turret"));
ENDCLASS(MachineGunTurret)

REGISTER_TURRET(MACHINEGUN, NEW(MachineGunTurret));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
void spawnfunc_turret_machinegun() { SELFPARAM(); if(!turret_initialize(TUR_MACHINEGUN.m_id)) remove(self); }

void W_MachineGun_MuzzleFlash(void);

        METHOD(MachineGunTurret, tr_attack, bool(MachineGunTurret thistur))
        {
            fireBullet (self.tur_shotorg, self.tur_shotdir_updated, self.shot_spread, 0, self.shot_dmg, self.shot_force, DEATH_TURRET_MACHINEGUN, 0);

            W_MachineGun_MuzzleFlash();
            setattachment(self.muzzle_flash, self.tur_head, "tag_fire");

            return true;
        }
        METHOD(MachineGunTurret, tr_think, bool(MachineGunTurret thistur))
        {
            return true;
        }
        METHOD(MachineGunTurret, tr_death, bool(MachineGunTurret thistur))
        {
            return true;
        }
        METHOD(MachineGunTurret, tr_setup, bool(MachineGunTurret thistur))
        {
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
            self.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
            self.turret_flags |= TUR_FLAG_HITSCAN;

            return true;
        }
        METHOD(MachineGunTurret, tr_precache, bool(MachineGunTurret thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(MachineGunTurret, tr_setup, bool(MachineGunTurret thistur))
        {
            return true;
        }
        METHOD(MachineGunTurret, tr_precache, bool(MachineGunTurret thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
