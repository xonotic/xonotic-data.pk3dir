#ifndef TURRET_FLAC_WEAPON_H
#define TURRET_FLAC_WEAPON_H

CLASS(FlacAttack, PortoLaunch)
/* flags     */ ATTRIB(FlacAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(FlacAttack, impulse, int, 5);
/* refname   */ ATTRIB(FlacAttack, netname, string, "turret_flac");
/* wepname   */ ATTRIB(FlacAttack, message, string, _("FLAC"));
ENDCLASS(FlacAttack)
REGISTER_WEAPON(FLAC, NEW(FlacAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void turret_flac_projectile_think_explode();
METHOD(FlacAttack, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.tur_impacttime = 10;
            weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }

        turret_tag_fire_update();

        entity proj = turret_projectile(SND(HAGAR_FIRE), 5, 0, DEATH_TURRET_FLAC.m_id, PROJECTILE_HAGAR, true, true);
        proj.missile_flags = MIF_SPLASH | MIF_PROXY;
        proj.think	  = turret_flac_projectile_think_explode;
        proj.nextthink  = time + actor.tur_impacttime + (random() * 0.01 - random() * 0.01);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);

        if (!isPlayer) {
            actor.tur_head.frame = actor.tur_head.frame + 1;
            if (actor.tur_head.frame >= 4)
                actor.tur_head.frame = 0;
        }
    }
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
