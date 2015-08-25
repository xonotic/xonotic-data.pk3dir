#ifdef REGISTER_TURRET
REGISTER_TURRET(
/* TUR_##id   */ PLASMA,
/* function   */ t_plasma,
/* spawnflags */ TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER,
/* mins,maxs  */ '-32 -32 0', '32 32 64',
/* model	  */ "base.md3",
/* head_model */ "plasma.md3",
/* netname	  */ "plasma",
/* fullname   */ _("Plasma Cannon")
);
#else
#ifdef SVQC
void spawnfunc_turret_plasma() { if(!turret_initialize(TUR_PLASMA)) remove(self); }

float t_plasma(float req)
{
    switch(req)
    {
        case TR_ATTACK:
        {
            if(g_instagib)
            {
                float flying;
                flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

                FireRailgunBullet (self.tur_shotorg, self.tur_shotorg + self.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                                   800, 0, 0, 0, 0, DEATH_TURRET_PLASMA);

                Send_Effect("nex_muzzleflash", self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

                // teamcolor / hit beam effect
                vector v;
                string s;
                v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
                s = strcat("TE_TEI_G3", ((self.team) ? Static_Team_ColorName_Upper(self.team) : ""));

                WarpZone_TrailParticles(world, particleeffectnum(s), self.tur_shotorg, v);

                if (self.tur_head.frame == 0)
                    self.tur_head.frame = 1;
            }
            else
            {
                entity missile = turret_projectile(W_Sound("hagar_fire"), 1, 0, DEATH_TURRET_PLASMA, PROJECTILE_ELECTRO_BEAM, TRUE, TRUE);
                missile.missile_flags = MIF_SPLASH;

                Send_Effect("laser_muzzleflash", self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
                if (self.tur_head.frame == 0)
                    self.tur_head.frame = 1;
            }

            return true;
        }
        case TR_THINK:
        {
            if (self.tur_head.frame != 0)
                self.tur_head.frame = self.tur_head.frame + 1;

            if (self.tur_head.frame > 5)
                self.tur_head.frame = 0;

            return true;
        }
        case TR_DEATH:
        {
            return true;
        }
        case TR_SETUP:
        {
            self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.firecheck_flags |= TFL_FIRECHECK_AFF;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_SPLASH;

            turret_do_updates(self);

            return true;
        }
        case TR_PRECACHE:
        {
            precache_model ("models/turrets/base.md3");
            precache_model ("models/turrets/plasma.md3");
            return true;
        }
    }

    return true;
}

#endif // SVQC
#ifdef CSQC
float t_plasma(float req)
{
    switch(req)
    {
        case TR_SETUP:
        {
            return true;
        }
        case TR_PRECACHE:
        {
            return true;
        }
    }

    return true;
}

#endif // CSQC
#endif // REGISTER_TURRET
