#ifndef TURRET_PHASER_WEAPON_H
#define TURRET_PHASER_WEAPON_H

CLASS(PhaserTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(PhaserTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(PhaserTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(PhaserTurretAttack, netname, string, "turret_phaser");
/* wepname   */ ATTRIB(PhaserTurretAttack, message, string, _("Phaser"));
ENDCLASS(PhaserTurretAttack)
REGISTER_WEAPON(PHASER, NEW(PhaserTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC
void beam_think();

.int fireflag;

METHOD(PhaserTurretAttack, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_speed = 1;
            weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        entity beam = spawn();
        beam.ticrate = 0.1; //autocvar_sys_ticrate;
        setmodel(beam, MDL_TUR_PHASER_BEAM);
        beam.effects = EF_LOWPRECISION;
        beam.solid = SOLID_NOT;
        beam.think = beam_think;
        beam.cnt = time + actor.shot_speed;
        beam.shot_spread = time + 2;
        beam.nextthink = time;
        beam.owner = actor;
        beam.shot_dmg = actor.shot_dmg / (actor.shot_speed / beam.ticrate);
        beam.scale = actor.target_range / 256;
        beam.movetype = MOVETYPE_NONE;
        beam.enemy = actor.enemy;
        beam.bot_dodge = true;
        beam.bot_dodgerating = beam.shot_dmg;
        sound (beam, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
        actor.fireflag = 1;

        beam.attack_finished_single = actor.attack_finished_single;
        actor.attack_finished_single = time; // + autocvar_sys_ticrate;

        setattachment(beam,actor.tur_head, "tag_fire");

        soundat (actor, trace_endpos, CH_SHOTS, SND(NEXIMPACT), VOL_BASE, ATTEN_NORM);
        if (!isPlayer)
        if (actor.tur_head.frame == 0)
            actor.tur_head.frame = 1;
    }
}

void beam_think()
{SELFPARAM();
    if ((time > self.cnt) || (self.owner.deadflag != DEAD_NO))
    {
        self.owner.attack_finished_single = time + self.owner.shot_refire;
        self.owner.fireflag = 2;
        self.owner.tur_head.frame = 10;
        sound (self, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
        remove(self);
        return;
    }

    turret_do_updates(self.owner);

    if (time - self.shot_spread > 0)
    {
        self.shot_spread = time + 2;
        sound (self, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
    }


    self.nextthink = time + self.ticrate;

    self.owner.attack_finished_single = time + frametime;
    setself(self.owner);
    FireImoBeam (   self.tur_shotorg,
                    self.tur_shotorg + self.tur_shotdir_updated * self.target_range,
                    '-1 -1 -1' * self.shot_radius,
                    '1 1 1' * self.shot_radius,
                    self.shot_force,
                    this.shot_dmg,
                    0.75,
                    DEATH_TURRET_PHASER.m_id);
    setself(this);
    self.scale = vlen(self.owner.tur_shotorg - trace_endpos) / 256;

}

#endif

#endif
