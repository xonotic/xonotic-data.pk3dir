#ifndef TURRET_FLAC_WEAPON_H
#define TURRET_FLAC_WEAPON_H

CLASS(FlacAttack, PortoLaunch)
/* flags     */ ATTRIB(FlacAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
/* impulse   */ ATTRIB(FlacAttack, impulse, int, 5);
/* refname   */ ATTRIB(FlacAttack, netname, string, "turret_flac");
/* wepname   */ ATTRIB(FlacAttack, message, string, _("FLAC"));
ENDCLASS(FlacAttack)
REGISTER_WEAPON(FLAC, NEW(FlacAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void turret_flac_projectile_think_explode();
METHOD(FlacAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
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
            self.tur_impacttime = 10;
            weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }

        turret_tag_fire_update();

        entity proj = turret_projectile(SND(HAGAR_FIRE), 5, 0, DEATH_TURRET_FLAC, PROJECTILE_HAGAR, true, true);
        proj.missile_flags = MIF_SPLASH | MIF_PROXY;
        proj.think	  = turret_flac_projectile_think_explode;
        proj.nextthink  = time + self.tur_impacttime + (random() * 0.01 - random() * 0.01);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

        if (!isPlayer) {
            self.tur_head.frame = self.tur_head.frame + 1;
            if (self.tur_head.frame >= 4)
                self.tur_head.frame = 0;
        }
    }
    return true;
}

void turret_flac_projectile_think_explode()
{
    SELFPARAM();
    if (self.enemy != world)
    if (vlen(self.origin - self.enemy.origin) < self.owner.shot_radius * 3)
        setorigin(self,self.enemy.origin + randomvec() * self.owner.shot_radius);

#ifdef TURRET_DEBUG
    float d = RadiusDamage (self, self.owner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
    self.owner.tur_dbg_dmg_t_h = self.owner.tur_dbg_dmg_t_h + d;
    self.owner.tur_dbg_dmg_t_f = self.owner.tur_dbg_dmg_t_f + self.owner.shot_dmg;
#else
    RadiusDamage (self, self.realowner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
#endif
    remove(self);
}

#endif

#endif
