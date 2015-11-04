#ifndef TURRET_PLASMA_WEAPON_H
#define TURRET_PLASMA_WEAPON_H

CLASS(PlasmaAttack, PortoLaunch)
/* flags     */ ATTRIB(PlasmaAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(PlasmaAttack, impulse, int, 5);
/* refname   */ ATTRIB(PlasmaAttack, netname, string, "turret_plasma");
/* wepname   */ ATTRIB(PlasmaAttack, m_name, string, _("Plasma"));
ENDCLASS(PlasmaAttack)
REGISTER_WEAPON(PLASMA, NEW(PlasmaAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC
SOUND(PlasmaAttack_FIRE, W_Sound("electro_fire"));
METHOD(PlasmaAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
	bool isPlayer = IS_PLAYER(actor);
	if (fire & 1)
	if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
		if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, SND(PlasmaAttack_FIRE), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        entity missile = turret_projectile(SND(HAGAR_FIRE), 1, 0, DEATH_TURRET_PLASMA.m_id, PROJECTILE_ELECTRO_BEAM, true, true);
        missile.missile_flags = MIF_SPLASH;
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);
	}
}

#endif

#endif
