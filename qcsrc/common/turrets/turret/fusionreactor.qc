#ifndef TURRET_FUSIONREACTOR_H
#define TURRET_FUSIONREACTOR_H

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

spawnfunc(turret_fusionreactor) { if (!turret_initialize(TUR_FUSIONREACTOR)) remove(self); }

METHOD(FusionReactor, tr_attack, void(FusionReactor this))
{
    self.enemy.ammo = min(self.enemy.ammo + self.shot_dmg,self.enemy.ammo_max);
    vector fl_org = 0.5 * (self.enemy.absmin + self.enemy.absmax);
    te_smallflash(fl_org);
}
METHOD(FusionReactor, tr_think, void(FusionReactor thistur))
{
    self.tur_head.avelocity = '0 250 0' * (self.ammo / self.ammo_max);
}
METHOD(FusionReactor, tr_setup, void(FusionReactor this, entity it))
{
    it.ammo_flags				= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE;
    it.target_select_flags	= TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_OWNTEAM | TFL_TARGETSELECT_RANGELIMITS;
    it.firecheck_flags		= TFL_FIRECHECK_AMMO_OWN | TFL_FIRECHECK_AMMO_OTHER | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_DEAD;
    it.shoot_flags			= TFL_SHOOT_HITALLVALID;
    it.aim_flags				= TFL_AIM_NO;
    it.track_flags			= TFL_TRACK_NO;

    it.tur_head.scale = 0.75;
    it.tur_head.avelocity = '0 50 0';

    it.turret_firecheckfunc = turret_fusionreactor_firecheck;
}

#endif
#endif
