#include "machinegun.qh"

#ifdef SVQC

spawnfunc(turret_machinegun) { if (!turret_initialize(this, TUR_MACHINEGUN)) delete(this); }

void W_MuzzleFlash_Model(entity wepent, entity muzzlemodel);
METHOD(MachineGunTurret, tr_attack, void(MachineGunTurret this, entity actor))
{
    .entity weaponentity = weaponentities[0]; // TODO
    fireBullet(actor, weaponentity, actor.tur_shotorg, actor.tur_shotdir_updated, actor.shot_spread, 0, actor.shot_dmg, 0, actor.shot_force, DEATH_TURRET_MACHINEGUN.m_id, EFFECT_BULLET);
    W_MuzzleFlash_Model(actor.(weaponentity), MDL_MACHINEGUN_MUZZLEFLASH);
    setattachment(actor.(weaponentity).muzzle_flash, actor.tur_head, "tag_fire");
}

METHOD(MachineGunTurret, tr_setup, void(MachineGunTurret this, entity it))
{
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
    it.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.turret_flags |= TUR_FLAG_HITSCAN;
}

#endif // SVQC
