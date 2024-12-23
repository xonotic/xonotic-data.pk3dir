#include "plasma_weapon.qh"

#ifdef SVQC
SOUND(PlasmaAttack_FIRE, W_Sound("hagar_fire"));
METHOD(PlasmaAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
	bool isPlayer = IS_PLAYER(actor);
	if (fire & 1)
	if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
		if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_PlasmaAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_PLASMA.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }
        entity missile = turret_projectile(actor, SND_PlasmaAttack_FIRE, 1, 0, DEATH_TURRET_PLASMA.m_id, PROJECTILE_ELECTRO_BEAM, true, true);
        missile.missile_flags = MIF_SPLASH;
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);
	}
}

#endif
