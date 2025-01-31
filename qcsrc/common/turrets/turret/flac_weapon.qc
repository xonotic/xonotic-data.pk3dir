#include "flac_weapon.qh"

#ifdef SVQC

void turret_flac_projectile_think_explode(entity this);
SOUND(FlacAttack_FIRE, W_Sound("hagar_fire"));
METHOD(FlacAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_FlacAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_FLAC.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.tur_impacttime = 10;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }

        turret_tag_fire_update(actor);

        entity proj = turret_projectile(actor, SND_FlacAttack_FIRE, 5, 0, DEATH_TURRET_FLAC.m_id, PROJECTILE_HAGAR, true, true);
        proj.missile_flags = MIF_SPLASH | MIF_PROXY;
        setthink(proj, turret_flac_projectile_think_explode);
        proj.nextthink  = time + actor.tur_impacttime + (random() * 0.01 - random() * 0.01);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);

        if (!isPlayer) {
            actor.tur_head.frame = actor.tur_head.frame + 1;
            if (actor.tur_head.frame >= 4)
                actor.tur_head.frame = 0;
        }
    }
}

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

#endif
