#include "phaser_weapon.qh"

#ifdef IMPLEMENTATION

#ifdef SVQC
void beam_think(entity this);

.int fireflag;
SOUND(PhaserTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(PhaserTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_PhaserTurretAttack_FIRE, CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_speed = 1;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        entity beam = spawn();
        beam.ticrate = 0.1; //autocvar_sys_ticrate;
        setmodel(beam, MDL_TUR_PHASER_BEAM);
        beam.effects = EF_LOWPRECISION;
        beam.solid = SOLID_NOT;
        setthink(beam, beam_think);
        beam.cnt = time + actor.shot_speed;
        beam.shot_spread = time + 2;
        beam.nextthink = time;
        beam.owner = actor;
        beam.shot_dmg = actor.shot_dmg / (actor.shot_speed / beam.ticrate);
        beam.scale = actor.target_range / 256;
        set_movetype(beam, MOVETYPE_NONE);
        beam.enemy = actor.enemy;
        beam.bot_dodge = true;
        IL_PUSH(g_bot_dodge, beam);
        beam.bot_dodgerating = beam.shot_dmg;
        sound (beam, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
        actor.fireflag = 1;

        beam.attack_finished_single[0] = actor.attack_finished_single[0];
        actor.attack_finished_single[0] = time; // + autocvar_sys_ticrate;

        setattachment(beam,actor.tur_head, "tag_fire");

        soundat (actor, trace_endpos, CH_SHOTS, SND(NEXIMPACT), VOL_BASE, ATTEN_NORM);
        if (!isPlayer)
        if (actor.tur_head.frame == 0)
            actor.tur_head.frame = 1;
    }
}

void beam_think(entity this)
{
    if ((time > this.cnt) || (IS_DEAD(this.owner)))
    {
        this.owner.attack_finished_single[0] = time + this.owner.shot_refire;
        this.owner.fireflag = 2;
        this.owner.tur_head.frame = 10;
        sound (this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
        delete(this);
        return;
    }

    turret_do_updates(this.owner);

    if (time - this.shot_spread > 0)
    {
        this.shot_spread = time + 2;
        sound (this, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
    }


    this.nextthink = time + this.ticrate;

    this.owner.attack_finished_single[0] = time + frametime;
    FireImoBeam (   this.owner, this.tur_shotorg,
                    this.tur_shotorg + this.tur_shotdir_updated * this.target_range,
                    '-1 -1 -1' * this.shot_radius,
                    '1 1 1' * this.shot_radius,
                    this.shot_force,
                    this.shot_dmg,
                    0.75,
                    DEATH_TURRET_PHASER.m_id);
    this.scale = vlen(this.owner.tur_shotorg - trace_endpos) / 256;

}

#endif

#endif
