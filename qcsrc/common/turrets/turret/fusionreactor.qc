#ifndef TUR_FUSIONREACTOR_H
#define TUR_FUSIONREACTOR_H

CLASS(FusionReactor, Turret)
/* spawnflags */ ATTRIB(FusionReactor, spawnflags, int, TUR_FLAG_SUPPORT | TUR_FLAG_AMMOSOURCE);
/* mins       */ ATTRIB(FusionReactor, mins, vector, '-34 -34 0');
/* maxs       */ ATTRIB(FusionReactor, maxs, vector, '34 34 90');
/* modelname  */ ATTRIB(FusionReactor, mdl, string, "base.md3");
/* model      */ ATTRIB(FusionReactor, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(FusionReactor, head_model, string, strzone(strcat("models/turrets/", "reactor.md3")));
/* netname    */ ATTRIB(FusionReactor, netname, string, "fusionreactor");
/* fullname   */ ATTRIB(FusionReactor, turret_name, string, _("Fusion Reactor"));
ENDCLASS(FusionReactor)

REGISTER_TURRET(FUSIONREACTOR, NEW(FusionReactor));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
bool turret_fusionreactor_firecheck()
{SELFPARAM();
    if (self.attack_finished_single > time)
        return false;

    if (self.enemy.deadflag != DEAD_NO)
        return false;

    if (self.enemy == world)
        return false;

    if (self.ammo < self.shot_dmg)
        return false;

    if (self.enemy.ammo >= self.enemy.ammo_max)
        return false;

    if (vlen(self.enemy.origin - self.origin) > self.target_range)
        return false;

    if(self.team != self.enemy.team)
        return false;

    if(!(self.enemy.ammo_flags & TFL_AMMO_ENERGY))
        return false;

    return true;
}

void spawnfunc_turret_fusionreactor() { SELFPARAM(); if(!turret_initialize(TUR_FUSIONREACTOR.m_id)) remove(self); }

        METHOD(FusionReactor, tr_attack, void(FusionReactor thistur))
        {
            vector fl_org;

            self.enemy.ammo = min(self.enemy.ammo + self.shot_dmg,self.enemy.ammo_max);
            fl_org = 0.5 * (self.enemy.absmin + self.enemy.absmax);
            te_smallflash(fl_org);
        }
        METHOD(FusionReactor, tr_think, bool(FusionReactor thistur))
        {
            self.tur_head.avelocity = '0 250 0' * (self.ammo / self.ammo_max);

            return true;
        }
        METHOD(FusionReactor, tr_death, bool(FusionReactor thistur))
        {
            return true;
        }
        METHOD(FusionReactor, tr_setup, bool(FusionReactor thistur))
        {
            self.ammo_flags				= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE;
            self.target_select_flags	= TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_OWNTEAM | TFL_TARGETSELECT_RANGELIMITS;
            self.firecheck_flags		= TFL_FIRECHECK_AMMO_OWN | TFL_FIRECHECK_AMMO_OTHER | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_DEAD;
            self.shoot_flags			= TFL_SHOOT_HITALLVALID;
            self.aim_flags				= TFL_AIM_NO;
            self.track_flags			= TFL_TRACK_NO;

            self.tur_head.scale = 0.75;
            self.tur_head.avelocity = '0 50 0';

            self.turret_firecheckfunc = turret_fusionreactor_firecheck;

            return true;
        }
        METHOD(FusionReactor, tr_precache, bool(FusionReactor thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(FusionReactor, tr_setup, bool(FusionReactor thistur))
        {
            return true;
        }
        METHOD(FusionReactor, tr_precache, bool(FusionReactor thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
