#ifndef TUR_PHASER_H
#define TUR_PHASER_H

CLASS(PhaserTurret, Turret)
/* spawnflags */ ATTRIB(PhaserTurret, spawnflags, int, TUR_FLAG_SNIPER | TUR_FLAG_HITSCAN | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(PhaserTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(PhaserTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(PhaserTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(PhaserTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(PhaserTurret, head_model, string, strzone(strcat("models/turrets/", "phaser.md3")));
/* netname    */ ATTRIB(PhaserTurret, netname, string, "phaser");
/* fullname   */ ATTRIB(PhaserTurret, turret_name, string, _("Phaser Cannon"));
ENDCLASS(PhaserTurret)

REGISTER_TURRET(PHASER, NEW(PhaserTurret));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
.float fireflag;

float turret_phaser_firecheck()
{SELFPARAM();
    if (self.fireflag != 0) return 0;
    return turret_firecheck();
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

void spawnfunc_turret_phaser() { SELFPARAM(); if(!turret_initialize(TUR_PHASER.m_id)) remove(self); }

        METHOD(PhaserTurret, tr_attack, bool(PhaserTurret thistur))
        {
            entity beam;

            beam = spawn();
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

            setattachment(beam,self.tur_head,"tag_fire");

            soundat (self, trace_endpos, CH_SHOTS, SND(NEXIMPACT), VOL_BASE, ATTEN_NORM);

            if (self.tur_head.frame == 0)
                self.tur_head.frame = 1;

            return true;
        }
        METHOD(PhaserTurret, tr_think, bool(PhaserTurret thistur))
        {
            if (self.tur_head.frame != 0)
            {
                if (self.fireflag == 1)
                {
                    if (self.tur_head.frame == 10)
                        self.tur_head.frame = 1;
                    else
                        self.tur_head.frame = self.tur_head.frame +1;
                }
                else if (self.fireflag == 2 )
                {
                    self.tur_head.frame = self.tur_head.frame +1;
                    if (self.tur_head.frame == 15)
                    {
                        self.tur_head.frame = 0;
                        self.fireflag = 0;
                    }
                }
            }

            return true;
        }
        METHOD(PhaserTurret, tr_death, bool(PhaserTurret thistur))
        {
            return true;
        }
        METHOD(PhaserTurret, tr_setup, bool(PhaserTurret thistur))
        {
            self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.aim_flags = TFL_AIM_LEAD;

            self.turret_firecheckfunc = turret_phaser_firecheck;

            return true;
        }
        METHOD(PhaserTurret, tr_precache, bool(PhaserTurret thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(PhaserTurret, tr_setup, bool(PhaserTurret thistur))
        {
            return true;
        }
        METHOD(PhaserTurret, tr_precache, bool(PhaserTurret thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
