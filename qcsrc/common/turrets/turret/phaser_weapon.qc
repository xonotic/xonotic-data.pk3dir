#include "phaser_weapon.qh"

#ifdef SVQC
void beam_think(entity this);

.int fireflag;
SOUND(PhaserTurretAttack_FIRE, W_Sound("electro_fire"));
SOUND(PhaserTurretAttack_IMPACT, W_Sound("neximpact"));
METHOD(PhaserTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_PhaserTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_PHASER.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_speed = 1;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }
        entity beam = new(PhaserTurret_beam);
        setmodel(beam, MDL_TUR_PHASER_BEAM);
        beam.effects = EF_LOWPRECISION;
        beam.solid = SOLID_NOT;
        setthink(beam, beam_think);
        beam.cnt = time + actor.shot_speed;
        beam.shot_spread = time + 2;
        beam.nextthink = time;
        beam.owner = actor;
        beam.shot_dmg = actor.shot_dmg / (actor.shot_speed / frametime);
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

        setattachment(beam, actor.tur_head, "tag_fire");

        soundat (actor, trace_endpos, CH_SHOTS, SND(PhaserTurretAttack_IMPACT), VOL_BASE, ATTEN_NORM);
        if (!isPlayer)
        if (actor.tur_head.frame == 0)
            actor.tur_head.frame = 1;
    }
}

void beam_think(entity this)
{
    entity actor = this.owner;
    if ((time > this.cnt) || (IS_DEAD(actor)))
    {
        actor.attack_finished_single[0] = time + actor.shot_refire;
        actor.fireflag = 2;
        actor.tur_head.frame = 10;
        sound (this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
        delete(this);
        return;
    }

    turret_do_updates(actor);

    if (time - this.shot_spread > 0)
    {
        this.shot_spread = time + 2;
        sound (this, CH_SHOTS_SINGLE, SND_TUR_PHASER, VOL_BASE, ATTEN_NORM);
    }

    this.nextthink = time;

    actor.attack_finished_single[0] = time + frametime;
    FireImoBeam (   actor, actor.tur_shotorg,
                    actor.tur_shotorg + actor.tur_shotdir_updated * actor.target_range,
                    '-1 -1 -1' * actor.shot_radius,
                    '1 1 1' * actor.shot_radius,
                    actor.shot_force,
                    this.shot_dmg,
                    0.75,
                    DEATH_TURRET_PHASER.m_id);
    this.scale = vlen(actor.tur_shotorg - trace_endpos) / 256;
}

#endif
