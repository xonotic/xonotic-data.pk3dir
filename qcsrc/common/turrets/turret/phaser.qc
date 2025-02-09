#include "phaser.qh"

#ifdef SVQC

.int fireflag;

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

spawnfunc(turret_phaser) { if (!turret_initialize(this, TUR_PHASER)) delete(this); }

.int fireflag;
SOUND(PhaserTurretAttack_IMPACT, W_Sound("neximpact"));
METHOD(PhaserTurret, tr_attack, void(PhaserTurret this, entity actor))
{
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

    if (actor.tur_head.frame == 0)
        actor.tur_head.frame = 1;
}

METHOD(PhaserTurret, tr_think, void(PhaserTurret thistur, entity it))
{
    if (it.tur_head.frame != 0)
    {
        if (it.fireflag == 1)
        {
            if (it.tur_head.frame == 10)
                it.tur_head.frame = 1;
            else
                it.tur_head.frame = it.tur_head.frame +1;
        }
        else if (it.fireflag == 2 )
        {
            it.tur_head.frame = it.tur_head.frame +1;
            if (it.tur_head.frame == 15)
            {
                it.tur_head.frame = 0;
                it.fireflag = 0;
            }
        }
    }
}
bool turret_phaser_firecheck(entity this);
METHOD(PhaserTurret, tr_setup, void(PhaserTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD;

    it.turret_firecheckfunc = turret_phaser_firecheck;
}
bool turret_phaser_firecheck(entity this)
{
    if (this.fireflag != 0) return false;
    return turret_firecheck(this);
}

#endif
