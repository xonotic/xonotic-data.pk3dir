#ifndef TURRET_EWHEEL_H
#define TURRET_EWHEEL_H

//#define EWHEEL_FANCYPATH

#include "ewheel_weapon.qc"

CLASS(EWheel, Turret)
/* spawnflags */ ATTRIB(EWheel, spawnflags, int, TUR_FLAG_PLAYER | TUR_FLAG_MOVE | TUR_FLAG_ROAM);
/* mins       */ ATTRIB(EWheel, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(EWheel, maxs, vector, '32 32 48');
/* modelname  */ ATTRIB(EWheel, mdl, string, "ewheel-base2.md3");
/* model      */ ATTRIB_STRZONE(EWheel, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(EWheel, head_model, string, strcat("models/turrets/", "ewheel-gun1.md3"));
/* netname    */ ATTRIB(EWheel, netname, string, "ewheel");
/* fullname   */ ATTRIB(EWheel, turret_name, string, _("eWheel Turret"));
    ATTRIB(EWheel, m_weapon, Weapon, WEP_EWHEEL);
ENDCLASS(EWheel)
REGISTER_TURRET(EWHEEL, NEW(EWheel));

#endif

#ifdef IMPLEMENTATION

#include "ewheel_weapon.qc"

#ifdef SVQC

float autocvar_g_turrets_unit_ewheel_speed_fast;
float autocvar_g_turrets_unit_ewheel_speed_slow;
float autocvar_g_turrets_unit_ewheel_speed_slower;
float autocvar_g_turrets_unit_ewheel_speed_stop;
float autocvar_g_turrets_unit_ewheel_turnrate;

const float ewheel_anim_stop = 0;
const float ewheel_anim_fwd_slow = 1;
const float ewheel_anim_fwd_fast = 2;
const float ewheel_anim_bck_slow = 3;
const float ewheel_anim_bck_fast = 4;

void ewheel_move_path()
{SELFPARAM();
#ifdef EWHEEL_FANCYPATH
    // Are we close enougth to a path node to switch to the next?
    if (vlen(self.origin  - self.pathcurrent.origin) < 64)
        if (self.pathcurrent.path_next == world)
        {
            // Path endpoint reached
            pathlib_deletepath(self.pathcurrent.owner);
            self.pathcurrent = world;

            if (self.pathgoal)
            {
                if (self.pathgoal.use)
                    self.pathgoal.use();

                if (self.pathgoal.enemy)
                {
                    self.pathcurrent = pathlib_astar(self.pathgoal.origin,self.pathgoal.enemy.origin);
                    self.pathgoal = self.pathgoal.enemy;
                }
            }
            else
                self.pathgoal = world;
        }
        else
            self.pathcurrent = self.pathcurrent.path_next;

#else
    if (vlen(self.origin - self.pathcurrent.origin) < 64)
        self.pathcurrent = self.pathcurrent.enemy;
#endif

    if (self.pathcurrent)
    {

        self.moveto = self.pathcurrent.origin;
        self.steerto = steerlib_attract2(self.moveto, 0.5, 500, 0.95);

        movelib_move_simple(v_forward, (autocvar_g_turrets_unit_ewheel_speed_fast), 0.4);
    }
}

void ewheel_move_enemy()
{SELFPARAM();
    float newframe;

    self.steerto = steerlib_arrive(self.enemy.origin,self.target_range_optimal);

    self.moveto  = self.origin + self.steerto * 128;

    if (self.tur_dist_enemy > self.target_range_optimal)
    {
        if ( self.tur_head.spawnshieldtime < 1 )
        {
            newframe = ewheel_anim_fwd_fast;
            movelib_move_simple(v_forward, (autocvar_g_turrets_unit_ewheel_speed_fast), 0.4);
        }
        else if (self.tur_head.spawnshieldtime < 2)
        {

            newframe = ewheel_anim_fwd_slow;
            movelib_move_simple(v_forward, (autocvar_g_turrets_unit_ewheel_speed_slow), 0.4);
       }
        else
        {
            newframe = ewheel_anim_fwd_slow;
            movelib_move_simple(v_forward, (autocvar_g_turrets_unit_ewheel_speed_slower), 0.4);
        }
    }
    else if (self.tur_dist_enemy < self.target_range_optimal * 0.5)
    {
        newframe = ewheel_anim_bck_slow;
        movelib_move_simple(v_forward * -1, (autocvar_g_turrets_unit_ewheel_speed_slow), 0.4);
    }
    else
    {
        newframe = ewheel_anim_stop;
        movelib_beak_simple((autocvar_g_turrets_unit_ewheel_speed_stop));
    }

    turrets_setframe(newframe, false);
}

void ewheel_move_idle()
{SELFPARAM();
    if(self.frame != 0)
    {
        self.SendFlags |= TNSF_ANIM;
        self.anim_start_time = time;
    }

    self.frame = 0;
    if (vlen(self.velocity))
        movelib_beak_simple((autocvar_g_turrets_unit_ewheel_speed_stop));
}

spawnfunc(turret_ewheel) { if(!turret_initialize(TUR_EWHEEL)) remove(self); }

        METHOD(EWheel, tr_think, void(EWheel thistur))
        {
            SELFPARAM();
            float vz;
            vector wish_angle, real_angle;

            vz = self.velocity_z;

            self.angles_x = anglemods(self.angles_x);
            self.angles_y = anglemods(self.angles_y);

            fixedmakevectors(self.angles);

            wish_angle = normalize(self.steerto);
            wish_angle = vectoangles(wish_angle);
            real_angle = wish_angle - self.angles;
            real_angle = shortangle_vxy(real_angle, self.tur_head.angles);

            self.tur_head.spawnshieldtime = fabs(real_angle_y);
            real_angle_y  = bound(-self.tur_head.aim_speed, real_angle_y, self.tur_head.aim_speed);
            self.angles_y = (self.angles_y + real_angle_y);

            if(self.enemy)
                ewheel_move_enemy();
            else if(self.pathcurrent)
                ewheel_move_path();
            else
                ewheel_move_idle();

            self.velocity_z = vz;

            if(vlen(self.velocity))
                self.SendFlags |= TNSF_MOVE;
        }
        METHOD(EWheel, tr_death, void(EWheel this, entity it))
        {
            it.velocity = '0 0 0';

#ifdef EWHEEL_FANCYPATH
            if (self.pathcurrent)
                pathlib_deletepath(it.pathcurrent.owner);
#endif
            it.pathcurrent = NULL;
        }
        METHOD(EWheel, tr_setup, void(EWheel this, entity it))
        {
            entity e;

            if(it.movetype == MOVETYPE_WALK)
            {
                it.velocity = '0 0 0';
                it.enemy = world;

                setorigin(it, it.pos1);

                if (it.target != "")
                {
                    e = find(world, targetname, it.target);
                    if (!e)
                    {
                        LOG_TRACE("Initital waypoint for ewheel does NOT exsist, fix your map!\n");
                        it.target = "";
                    }

                    if (e.classname != "turret_checkpoint")
                        LOG_TRACE("Warning: not a turrret path\n");
                    else
                    {

#ifdef EWHEEL_FANCYPATH
                        it.pathcurrent = WALKER_PATH(it.origin,e.origin);
                        it.pathgoal = e;
#else
                        it.pathcurrent  = e;
#endif
                    }
                }
            }

            it.iscreature				= true;
            it.teleportable			= TELEPORT_NORMAL;
            it.damagedbycontents		= true;
            it.movetype				= MOVETYPE_WALK;
            it.solid					= SOLID_SLIDEBOX;
            it.takedamage				= DAMAGE_AIM;
            it.idle_aim				= '0 0 0';
            it.pos1					= it.origin;
            it.target_select_flags	= TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
            it.target_validate_flags	= TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
            it.frame					= it.tur_head.frame = 1;
            it.ammo_flags				= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;

            // Convert from dgr / sec to dgr / tic
            it.tur_head.aim_speed = (autocvar_g_turrets_unit_ewheel_turnrate);
            it.tur_head.aim_speed = it.tur_head.aim_speed / (1 / it.ticrate);
        }

#endif // SVQC
#ifdef CSQC

void ewheel_draw(entity this)
{
    float dt;

    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;

    fixedmakevectors(self.angles);
    setorigin(self, self.origin + self.velocity * dt);
    self.tur_head.angles += dt * self.tur_head.move_avelocity;
    self.angles_y = self.move_angles_y;

    if (self.health < 127)
    if(random() < 0.05)
        te_spark(self.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);
}

        METHOD(EWheel, tr_setup, void(EWheel this, entity it))
        {
            it.gravity		= 1;
            it.movetype		= MOVETYPE_BOUNCE;
            it.move_movetype	= MOVETYPE_BOUNCE;
            it.move_origin	= it.origin;
            it.move_time		= time;
            it.draw			= ewheel_draw;
        }

#endif // CSQC
#endif
