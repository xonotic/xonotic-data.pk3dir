#ifndef TUR_FLAC_H
#define TUR_FLAC_H

CLASS(Flac, Turret)
/* spawnflags */ ATTRIB(Flac, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_FASTPROJ | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(Flac, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(Flac, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(Flac, mdl, string, "base.md3");
/* model      */ ATTRIB(Flac, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(Flac, head_model, string, strzone(strcat("models/turrets/", "flac.md3")));
/* netname    */ ATTRIB(Flac, netname, string, "flac");
/* fullname   */ ATTRIB(Flac, turret_name, string, _("FLAC Cannon"));
ENDCLASS(Flac)

REGISTER_TURRET(FLAC, NEW(Flac));

CLASS(FlacAttack, PortoLaunch)
/* flags     */ ATTRIB(FlacAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(FlacAttack, impulse, int, 5);
/* refname   */ ATTRIB(FlacAttack, netname, string, "turret_flac");
/* wepname   */ ATTRIB(FlacAttack, message, string, _("FLAC"));
ENDCLASS(FlacAttack)
REGISTER_WEAPON(FLAC, NEW(FlacAttack));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
void turret_initparams(entity);
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
{SELFPARAM();
    if(self.enemy != world)
    if(vlen(self.origin - self.enemy.origin) < self.owner.shot_radius * 3)
        setorigin(self,self.enemy.origin + randomvec() * self.owner.shot_radius);

#ifdef TURRET_DEBUG
    float d;
    d = RadiusDamage (self, self.owner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
    self.owner.tur_dbg_dmg_t_h = self.owner.tur_dbg_dmg_t_h + d;
    self.owner.tur_dbg_dmg_t_f = self.owner.tur_dbg_dmg_t_f + self.owner.shot_dmg;
#else
    RadiusDamage (self, self.realowner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
#endif
    remove(self);
}

void spawnfunc_turret_flac() { SELFPARAM(); if(!turret_initialize(TUR_FLAC.m_id)) remove(self); }

        METHOD(Flac, tr_attack, void(Flac thistur))
        {
            Weapon wep = WEP_FLAC;
            wep.wr_think(wep, true, false);
        }
        METHOD(Flac, tr_think, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_death, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_setup, bool(Flac thistur))
        {
            self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;

            return true;
        }
        METHOD(Flac, tr_precache, bool(Flac thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(Flac, tr_setup, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_precache, bool(Flac thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
