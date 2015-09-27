#ifndef IMPLEMENTATION
REGISTER_TURRET(
/* TUR_##id   */ MLRS,
/* function   */ t_mlrs,
/* spawnflags */ TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER,
/* mins,maxs  */ '-32 -32 0', '32 32 64',
/* model	  */ "base.md3",
/* head_model */ "mlrs.md3",
/* netname	  */ "mlrs",
/* fullname   */ _("MLRS Turret")
);
#else
#ifdef SVQC
void spawnfunc_turret_mlrs() { SELFPARAM(); if(!turret_initialize(TUR_MLRS.m_id)) remove(self); }

float t_mlrs(float req)
{SELFPARAM();
    switch(req)
    {
        case TR_ATTACK:
        {
            entity missile;

            turret_tag_fire_update();
            missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_MLRS, PROJECTILE_ROCKET, TRUE, TRUE);
            missile.nextthink = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
            missile.missile_flags = MIF_SPLASH;
            te_explosion (missile.origin);

            return true;
        }
        case TR_THINK:
        {
            // 0 = full, 6 = empty
            self.tur_head.frame = bound(0, 6 - floor(0.1 + self.ammo / self.shot_dmg), 6);
            if(self.tur_head.frame < 0)
            {
                LOG_TRACE("ammo:",ftos(self.ammo),"\n");
                LOG_TRACE("shot_dmg:",ftos(self.shot_dmg),"\n");
            }

            return true;
        }
        case TR_DEATH:
        {
            return true;
        }
        case TR_SETUP:
        {
            self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;

            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.shoot_flags  |= TFL_SHOOT_VOLLYALWAYS;
            self.volly_counter = self.shot_volly;

            return true;
        }
        case TR_PRECACHE:
        {
            return true;
        }
    }

    return true;
}

#endif // SVQC
#ifdef CSQC
float t_mlrs(float req)
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
