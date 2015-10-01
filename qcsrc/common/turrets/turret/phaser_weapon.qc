#ifndef TURRET_PHASER_WEAPON_H
#define TURRET_PHASER_WEAPON_H

CLASS(PhaserTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(PhaserTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
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

METHOD(PhaserTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2))
{
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(self);
            W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            self.tur_shotdir_updated = w_shotdir;
            self.tur_shotorg = w_shotorg;
            self.tur_head = self;
            self.shot_speed = 1;
            weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        entity beam = spawn();
        beam.ticrate = 0.1; //autocvar_sys_ticrate;
        setmodel(beam, MDL_TUR_PHASER_BEAM);
        beam.effects = EF_LOWPRECISION;
        beam.solid = SOLID_NOT;
        beam.think = beam_think;
        beam.cnt = time + self.shot_speed;
        beam.shot_spread = time + 2;
        beam.nextthink = time;
        beam.owner = self;
        beam.shot_dmg = self.shot_dmg / (self.shot_speed / beam.ticrate);
        beam.scale = self.target_range / 256;
        beam.movetype = MOVETYPE_NONE;
        beam.enemy = self.enemy;
        beam.bot_dodge = true;
        beam.bot_dodgerating = beam.shot_dmg;
        sound (beam, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
        self.fireflag = 1;

        beam.attack_finished_single = self.attack_finished_single;
        self.attack_finished_single = time; // + autocvar_sys_ticrate;

        setattachment(beam,self.tur_head, "tag_fire");

        soundat (self, trace_endpos, CH_SHOTS, SND(NEXIMPACT), VOL_BASE, ATTEN_NORM);
        if (!isPlayer)
        if (self.tur_head.frame == 0)
            self.tur_head.frame = 1;
    }
    return true;
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
                    DEATH_TURRET_PHASER);
    setself(this);
    self.scale = vlen(self.owner.tur_shotorg - trace_endpos) / 256;

}

#endif

#endif
