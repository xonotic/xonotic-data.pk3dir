#include "flac.qh"

#ifdef SVQC

spawnfunc(turret_flac) { if (!turret_initialize(this, TUR_FLAC)) delete(this); }

void turret_flac_projectile_think_explode(entity this)
{
    if(this.enemy != NULL)
    if(vdist(this.origin - this.enemy.origin, <, this.owner.shot_radius * 3))
        setorigin(this, this.enemy.origin + randomvec() * this.owner.shot_radius);

#ifdef TURRET_DEBUG
    float d = RadiusDamage (this, this.owner, this.owner.shot_dmg, this.owner.shot_dmg, this.owner.shot_radius, this, NULL, this.owner.shot_force, this.projectiledeathtype, DMG_NOWEP, NULL);
    this.owner.tur_debug_dmg_t_h = this.owner.tur_debug_dmg_t_h + d;
    this.owner.tur_debug_dmg_t_f = this.owner.tur_debug_dmg_t_f + this.owner.shot_dmg;
#else
    RadiusDamage (this, this.realowner, this.owner.shot_dmg, this.owner.shot_dmg, this.owner.shot_radius, this, NULL, this.owner.shot_force, this.projectiledeathtype, DMG_NOWEP, NULL);
#endif
    delete(this);
}

SOUND(FlacAttack_FIRE, W_Sound("hagar_fire"));
METHOD(Flac, tr_attack, void(Flac this, entity actor))
{
    turret_tag_fire_update(actor);

    entity proj = turret_projectile(actor, SND_FlacAttack_FIRE, 5, 0, DEATH_TURRET_FLAC.m_id, PROJECTILE_HAGAR, true, true);
    proj.missile_flags = MIF_SPLASH | MIF_PROXY;
    setthink(proj, turret_flac_projectile_think_explode);
    proj.nextthink  = time + actor.tur_impacttime + (random() * 0.01 - random() * 0.01);
    Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);

    actor.tur_head.frame = actor.tur_head.frame + 1;
    if (actor.tur_head.frame >= 4)
        actor.tur_head.frame = 0;
}

METHOD(Flac, tr_setup, void(Flac this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;
}

#endif
