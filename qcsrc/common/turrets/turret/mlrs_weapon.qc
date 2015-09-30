#ifndef TURRET_MLRS_WEAPON_H
#define TURRET_MLRS_WEAPON_H

CLASS(MLRSTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MLRSTurretAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(MLRSTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MLRSTurretAttack, netname, string, "turret_mlrs");
/* wepname   */ ATTRIB(MLRSTurretAttack, message, string, _("MLRS"));
ENDCLASS(MLRSTurretAttack)
REGISTER_WEAPON(TUR_MLRS, NEW(MLRSTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

METHOD(MLRSTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2))
{
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(false, WEP_CVAR(machinegun, sustained_refire))) {
        if (isPlayer) {
            turret_initparams(self);
            W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            self.tur_shotdir_updated = w_shotdir;
            self.tur_shotorg = w_shotorg;
            self.tur_head = self;
            self.shot_radius = 500;
            weapon_thinkf(WFRAME_FIRE1, 0, w_ready);
        }
        turret_tag_fire_update();
        entity missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_MLRS, PROJECTILE_ROCKET, TRUE, TRUE);
        missile.nextthink = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
        missile.missile_flags = MIF_SPLASH;
        te_explosion (missile.origin);
    }
    return true;
}

#endif

#endif
