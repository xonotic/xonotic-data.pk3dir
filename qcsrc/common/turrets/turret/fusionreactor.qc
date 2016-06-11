#ifndef TURRET_FUSIONREACTOR_H
#define TURRET_FUSIONREACTOR_H

CLASS(FusionReactor, Turret)
/* spawnflags */ ATTRIB(FusionReactor, spawnflags, int, TUR_FLAG_SUPPORT | TUR_FLAG_AMMOSOURCE);
/* mins       */ ATTRIB(FusionReactor, mins, vector, '-34 -34 0');
/* maxs       */ ATTRIB(FusionReactor, maxs, vector, '34 34 90');
/* modelname  */ ATTRIB(FusionReactor, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(FusionReactor, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(FusionReactor, head_model, string, strcat("models/turrets/", "reactor.md3"));
/* netname    */ ATTRIB(FusionReactor, netname, string, "fusionreactor");
/* fullname   */ ATTRIB(FusionReactor, turret_name, string, _("Fusion Reactor"));
ENDCLASS(FusionReactor)
REGISTER_TURRET(FUSIONREACTOR, NEW(FusionReactor));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
bool turret_fusionreactor_firecheck(entity this)
{
    if (this.attack_finished_single[0] > time)
        return false;

    if (IS_DEAD(this.enemy))
        return false;

    if (this.enemy == world)
        return false;

    if (this.ammo < this.shot_dmg)
        return false;

    if (this.enemy.ammo >= this.enemy.ammo_max)
        return false;

    if(vdist(this.enemy.origin - this.origin, >, this.target_range))
        return false;

    if(this.team != this.enemy.team)
        return false;

    if(!(this.enemy.ammo_flags & TFL_AMMO_ENERGY))
        return false;

    return true;
}

spawnfunc(turret_fusionreactor) { if (!turret_initialize(this, TUR_FUSIONREACTOR)) remove(this); }

METHOD(FusionReactor, tr_attack, void(FusionReactor this, entity it))
{
    it.enemy.ammo = min(it.enemy.ammo + it.shot_dmg,it.enemy.ammo_max);
    vector fl_org = 0.5 * (it.enemy.absmin + it.enemy.absmax);
    te_smallflash(fl_org);
}
METHOD(FusionReactor, tr_think, void(FusionReactor thistur, entity it))
{
    it.tur_head.avelocity = '0 250 0' * (it.ammo / it.ammo_max);
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
