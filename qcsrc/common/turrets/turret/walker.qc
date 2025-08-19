#include "walker.qh"

#ifdef SVQC

float autocvar_g_turrets_unit_walker_melee_damage;
float autocvar_g_turrets_unit_walker_melee_force;
float autocvar_g_turrets_unit_walker_melee_range;
float autocvar_g_turrets_unit_walker_rocket_damage;
float autocvar_g_turrets_unit_walker_rocket_radius;
float autocvar_g_turrets_unit_walker_rocket_force;
float autocvar_g_turrets_unit_walker_rocket_speed;
float autocvar_g_turrets_unit_walker_rocket_range;
float autocvar_g_turrets_unit_walker_rocket_range_min;
float autocvar_g_turrets_unit_walker_rocket_refire;
float autocvar_g_turrets_unit_walker_rocket_turnrate;
float autocvar_g_turrets_unit_walker_speed_stop;
float autocvar_g_turrets_unit_walker_speed_walk;
float autocvar_g_turrets_unit_walker_speed_run;
float autocvar_g_turrets_unit_walker_speed_jump;
float autocvar_g_turrets_unit_walker_speed_swim;
float autocvar_g_turrets_unit_walker_speed_roam;
float autocvar_g_turrets_unit_walker_turn;
float autocvar_g_turrets_unit_walker_turn_walk;
float autocvar_g_turrets_unit_walker_turn_strafe;
float autocvar_g_turrets_unit_walker_turn_swim;
float autocvar_g_turrets_unit_walker_turn_run;

const int ANIM_NO         = 0;
const int ANIM_TURN       = 1;
const int ANIM_WALK       = 2;
const int ANIM_RUN        = 3;
const int ANIM_STRAFE_L   = 4;
const int ANIM_STRAFE_R   = 5;
const int ANIM_JUMP       = 6;
const int ANIM_LAND       = 7;
const int ANIM_PAIN       = 8;
const int ANIM_MELEE      = 9;
const int ANIM_SWIM       = 10;
const int ANIM_ROAM       = 11;

.float animflag;
.float idletime;

bool walker_firecheck(entity this)
{
    if (this.animflag == ANIM_MELEE)
        return false;

    return turret_firecheck(this);
}

void walker_melee_do_dmg(entity this)
{
    vector where;
    entity e;

    makevectors(this.angles);
    where = this.origin + v_forward * 128;

    e = findradius(where,32);
    while (e)
    {
        if (turret_validate_target(this, e, this.target_validate_flags))
            if (e != this && e.owner != this)
                Damage(e, this, this, (autocvar_g_turrets_unit_walker_melee_damage), DEATH_TURRET_WALK_MELEE.m_id, DMG_NOWEP, '0 0 0', v_forward * (autocvar_g_turrets_unit_walker_melee_force));

        e = e.chain;
    }
}

void walker_setnoanim(entity this)
{
    turrets_setframe(this, ANIM_NO, false);
    this.animflag = this.frame;
}
void walker_rocket_explode(entity this)
{
    RadiusDamage (this, this.owner, (autocvar_g_turrets_unit_walker_rocket_damage), 0, (autocvar_g_turrets_unit_walker_rocket_radius), this, NULL, (autocvar_g_turrets_unit_walker_rocket_force), DEATH_TURRET_WALK_ROCKET.m_id, DMG_NOWEP, NULL);
    delete(this);
}

void walker_rocket_touch(entity this, entity toucher)
{
    walker_rocket_explode(this);
}

void walker_rocket_damage(entity this, entity inflictor, entity attacker, float damage, float deathtype, .entity weaponentity, vector hitloc, vector vforce)
{
    TakeResource(this, RES_HEALTH, damage);
    this.velocity = this.velocity + vforce;

    if (GetResource(this, RES_HEALTH) <= 0)
        W_PrepareExplosionByDamage(this, this.owner, walker_rocket_explode);
}

#define WALKER_ROCKET_MOVE(s) movelib_move_simple((s), newdir, (autocvar_g_turrets_unit_walker_rocket_speed), (autocvar_g_turrets_unit_walker_rocket_turnrate)); UpdateCSQCProjectile(s)
void walker_rocket_loop(entity this);
void walker_rocket_think(entity this)
{
    vector newdir;
    float edist;
    float itime;
    float m_speed;

    this.nextthink = time;

    edist = vlen(this.enemy.origin - this.origin);

    // Simulate crude guidance
    if (this.cnt < time)
    {
        if (edist < 1000)
            this.tur_shotorg = randomvec() * min(edist, 64);
        else
            this.tur_shotorg = randomvec() * min(edist, 256);

        this.cnt = time + 0.5;
    }

    if (edist < 128)
        this.tur_shotorg = '0 0 0';

    if (this.max_health < time)
    {
        setthink(this, walker_rocket_explode);
        this.nextthink  = time;
        return;
    }

    if (this.shot_dmg != 1337 && random() < 0.01)
    {
        walker_rocket_loop(this);
        return;
    }

    m_speed = vlen(this.velocity);

    // Enemy dead? just keep on the current heading then.
    if (this.enemy == NULL || IS_DEAD(this.enemy))
        this.enemy = NULL;

    if (this.enemy)
    {
        itime = max(edist / m_speed, 1);
        newdir = steerlib_pull(this, this.enemy.origin + this.tur_shotorg);
    }
    else
        newdir  = normalize(this.velocity);

    WALKER_ROCKET_MOVE(this);
}

void walker_rocket_loop3(entity this)
{
    this.nextthink = time;

    if (this.max_health < time)
    {
        setthink(this, walker_rocket_explode);
        return;
    }

    if(vdist(this.origin - this.tur_shotorg, <, 100))
    {
        setthink(this, walker_rocket_think);
        return;
    }

    vector newdir = steerlib_pull(this, this.tur_shotorg);
    WALKER_ROCKET_MOVE(this);

    this.angles = vectoangles(this.velocity);
}

void walker_rocket_loop2(entity this)
{
    this.nextthink = time;

    if (this.max_health < time)
    {
        setthink(this, walker_rocket_explode);
        return;
    }

    if(vdist(this.origin - this.tur_shotorg, <, 100))
    {
        this.tur_shotorg = this.origin - '0 0 200';
        setthink(this, walker_rocket_loop3);
        return;
    }

    vector newdir = steerlib_pull(this, this.tur_shotorg);
    WALKER_ROCKET_MOVE(this);
}

void walker_rocket_loop(entity this)
{
    this.nextthink = time;
    this.tur_shotorg = this.origin + '0 0 300';
    setthink(this, walker_rocket_loop2);
    this.shot_dmg = 1337;
}

void walker_fire_rocket(entity this, vector org)
{
    fixedmakevectors(this.angles);

    te_explosion (org);

    entity rocket = new(walker_rocket);
    setorigin(rocket, org);
    rocket.solid			  = SOLID_BBOX; // before setsize so it will be linked to the area grid
    sound (this, CH_WEAPON_A, SND_TUR_WALKER_FIRE, VOL_BASE, ATTEN_NORM);
    setsize (rocket, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

    rocket.owner			  = this;
    rocket.bot_dodge		  = true;
    rocket.bot_dodgerating	= 50;
    rocket.takedamage		 = DAMAGE_YES;
    rocket.damageforcescale   = 2;
    SetResourceExplicit(rocket, RES_HEALTH, 25);
    rocket.tur_shotorg		= randomvec() * 512;
    rocket.cnt				= time + 1;
    rocket.enemy			  = this.enemy;

    if (random() < 0.01)
        setthink(rocket, walker_rocket_loop);
    else
        setthink(rocket, walker_rocket_think);

    rocket.event_damage	   = walker_rocket_damage;

    rocket.nextthink		  = time;
    set_movetype(rocket, MOVETYPE_FLY);
    rocket.velocity		   = normalize((v_forward + v_up * 0.5) + (randomvec() * 0.2)) * (autocvar_g_turrets_unit_walker_rocket_speed);
    rocket.angles			 = vectoangles(rocket.velocity);
    settouch(rocket, walker_rocket_touch);
    rocket.flags = FL_PROJECTILE;
    IL_PUSH(g_projectiles, rocket);
    IL_PUSH(g_bot_dodge, rocket);
    rocket.max_health		 = time + 9;
    rocket.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_HEAT;

    CSQCProjectile(rocket, false, PROJECTILE_ROCKET, false); // no culling, has fly sound
}

.vector enemy_last_loc;
.float enemy_last_time;
void walker_move_to(entity this, vector _target, float _dist)
{
    switch (this.waterlevel)
    {
        case WATERLEVEL_NONE:
            if (_dist > 500)
                this.animflag = ANIM_RUN;
            else
                this.animflag = ANIM_WALK;
        case WATERLEVEL_WETFEET:
        case WATERLEVEL_SWIMMING:
            if (this.animflag != ANIM_SWIM)
                this.animflag = ANIM_WALK;
            else
                this.animflag = ANIM_SWIM;
            break;
        case WATERLEVEL_SUBMERGED:
            this.animflag = ANIM_SWIM;
    }

    this.moveto = _target;
    this.steerto = steerlib_attract2(this, this.moveto, 0.5, 500, 0.95);

    if(this.enemy)
    {
        this.enemy_last_loc = _target;
        this.enemy_last_time = time;
    }
}

void walker_move_path(entity this)
{
#ifdef WALKER_FANCYPATHING
    // Are we close enougth to a path node to switch to the next?
    if(turret_closetotarget(this, this.pathcurrent.origin, 64))
    {
        if (this.pathcurrent.path_next == NULL)
        {
            // Path endpoint reached
            pathlib_deletepath(this.pathcurrent.owner);
            this.pathcurrent = NULL;

            if (this.pathgoal)
            {
                if (this.pathgoal.use)
                    this.pathgoal.use(this, NULL, NULL);

                if (this.pathgoal.enemy)
                {
                    this.pathcurrent = pathlib_astar(this, this.pathgoal.origin, this.pathgoal.enemy.origin);
                    this.pathgoal = this.pathgoal.enemy;
                }
            }
            else
                this.pathgoal = NULL;
        }
        else
            this.pathcurrent = this.pathcurrent.path_next;
    }

    this.moveto = this.pathcurrent.origin;
    this.steerto = steerlib_attract2(this, this.moveto,0.5,500,0.95);
    walker_move_to(this, this.moveto, 0);

#else
    if(turret_closetotarget(this, this.pathcurrent.origin, 64))
        this.pathcurrent = this.pathcurrent.enemy;

    if(!this.pathcurrent)
        return;

    this.moveto = this.pathcurrent.origin;
    this.steerto = steerlib_attract2(this, this.moveto, 0.5, 500, 0.95);
    walker_move_to(this, this.moveto, 0);
#endif
}

void walker_findtarget(entity this)
{
    entity e = find(NULL, targetname, this.target);
    if (!e)
    {
        LOG_TRACE("Initital waypoint for walker does NOT exist, fix your map!");
        this.target = "";
    }

    if (e.classname != "turret_checkpoint")
        LOG_TRACE("Warning: not a turrret path");
    else
    {
#ifdef WALKER_FANCYPATHING
        this.pathcurrent = pathlib_astar(this, this.origin, e.origin);
        this.pathgoal = e;
#else
        this.pathcurrent = e;
#endif
    }

    // TODO: this doesn't reset target, so tur_defend will be the checkpoint too!
}

spawnfunc(turret_walker) { if(!turret_initialize(this, TUR_WALKER)) delete(this); }

METHOD(WalkerTurret, tr_think, void(WalkerTurret thistur, entity it))
{
    fixedmakevectors(it.angles);

    if ((it.spawnflags & TSF_NO_PATHBREAK) && it.pathcurrent)
        walker_move_path(it);
    else if (it.enemy == NULL)
    {
        if(it.pathcurrent)
            walker_move_path(it);
        else
        {
            if(it.enemy_last_time != 0)
            {
                if(vdist(it.origin - it.enemy_last_loc, <, 128) || time - it.enemy_last_time > 10)
                    it.enemy_last_time = 0;
                else
                    walker_move_to(it, it.enemy_last_loc, 0);
            }
            else
            {
                if(it.animflag != ANIM_NO)
                {
                    traceline(it.origin + '0 0 64', it.origin + '0 0 64' + v_forward * 128, MOVE_NORMAL, it);

                    if(trace_fraction != 1.0)
                        it.tur_head.idletime = -1337;
                    else
                    {
                        traceline(trace_endpos, trace_endpos - '0 0 256', MOVE_NORMAL, it);
                        if(trace_fraction == 1.0)
                            it.tur_head.idletime = -1337;
                    }

                    if(it.tur_head.idletime == -1337)
                    {
                        it.moveto = it.origin + randomvec() * 256;
                        it.tur_head.idletime = 0;
                    }

                    it.moveto = it.moveto * 0.9 + ((it.origin + v_forward * 500) + randomvec() * 400) * 0.1;
                    it.moveto_z = it.origin_z + 64;
                    walker_move_to(it, it.moveto, 0);
                }

                if(it.idletime < time)
                {
                    if(random() < 0.5 || !(it.spawnflags & TSL_ROAM))
                    {
                        it.idletime = time + 1 + random() * 5;
                        it.moveto = it.origin;
                        it.animflag = ANIM_NO;
                    }
                    else
                    {
                        it.animflag = ANIM_WALK;
                        it.idletime = time + 4 + random() * 2;
                        it.moveto = it.origin + randomvec() * 256;
                        it.tur_head.moveto = it.moveto;
                        it.tur_head.idletime = 0;
                    }
                }
            }
        }
    }
    else
    {
        if (it.tur_dist_enemy < (autocvar_g_turrets_unit_walker_melee_range) && it.animflag != ANIM_MELEE)
        {
            vector wish_angle;

            wish_angle = angleofs(it, it.enemy);
            if (it.animflag != ANIM_SWIM)
            if (fabs(wish_angle_y) < 15)
            {
                it.moveto   = it.enemy.origin;
                it.steerto  = steerlib_attract2(it, it.moveto, 0.5, 500, 0.95);
                it.animflag = ANIM_MELEE;
            }
        }
        else if (it.tur_head.attack_finished_single[0] < time)
        {
            if(it.tur_head.shot_volly)
            {
                it.animflag = ANIM_NO;

                it.tur_head.shot_volly = it.tur_head.shot_volly -1;
                if(it.tur_head.shot_volly == 0)
                    it.tur_head.attack_finished_single[0] = time + (autocvar_g_turrets_unit_walker_rocket_refire);
                else
                    it.tur_head.attack_finished_single[0] = time + 0.2;

                if(it.tur_head.shot_volly > 1)
                    walker_fire_rocket(it, gettaginfo(it, gettagindex(it, "tag_rocket01")));
                else
                    walker_fire_rocket(it, gettaginfo(it, gettagindex(it, "tag_rocket02")));
            }
            else
            {
                if (it.tur_dist_enemy > (autocvar_g_turrets_unit_walker_rocket_range_min))
                if (it.tur_dist_enemy < (autocvar_g_turrets_unit_walker_rocket_range))
                    it.tur_head.shot_volly = 4;
            }
        }
        else
        {
            if (it.animflag != ANIM_MELEE)
                walker_move_to(it, it.enemy.origin, it.tur_dist_enemy);
        }
    }

    {
        vector real_angle;
        float turny = 0, turnx = 0;
        float vz;

        real_angle = vectoangles(it.steerto) - it.angles;
        vz = it.velocity_z;

        switch (it.animflag)
        {
            case ANIM_NO:
                movelib_brake_simple(it, (autocvar_g_turrets_unit_walker_speed_stop));
                break;

            case ANIM_TURN:
                turny = (autocvar_g_turrets_unit_walker_turn);
                movelib_brake_simple(it, (autocvar_g_turrets_unit_walker_speed_stop));
                break;

            case ANIM_WALK:
                turny = (autocvar_g_turrets_unit_walker_turn_walk);
                movelib_move_simple(it, v_forward, (autocvar_g_turrets_unit_walker_speed_walk), 0.6);
                break;

            case ANIM_RUN:
                turny = (autocvar_g_turrets_unit_walker_turn_run);
                movelib_move_simple(it, v_forward, (autocvar_g_turrets_unit_walker_speed_run), 0.6);
                break;

            case ANIM_STRAFE_L:
                turny = (autocvar_g_turrets_unit_walker_turn_strafe);
                movelib_move_simple(it, v_right * -1, (autocvar_g_turrets_unit_walker_speed_walk), 0.8);
                break;

            case ANIM_STRAFE_R:
                turny = (autocvar_g_turrets_unit_walker_turn_strafe);
                movelib_move_simple(it, v_right, (autocvar_g_turrets_unit_walker_speed_walk), 0.8);
                break;

            case ANIM_JUMP:
                it.velocity += '0 0 1' * (autocvar_g_turrets_unit_walker_speed_jump);
                break;

            case ANIM_LAND:
                break;

            case ANIM_PAIN:
                if(it.frame != ANIM_PAIN)
                    defer(it, 0.25, walker_setnoanim);

                break;

            case ANIM_MELEE:
                if(it.frame != ANIM_MELEE)
                {
                    defer(it, 0.41, walker_setnoanim);
                    defer(it, 0.21, walker_melee_do_dmg);
                }

                movelib_brake_simple(it, (autocvar_g_turrets_unit_walker_speed_stop));
                break;

            case ANIM_SWIM:
                turny = (autocvar_g_turrets_unit_walker_turn_swim);
                turnx = (autocvar_g_turrets_unit_walker_turn_swim);

                it.angles_x += bound(-10, shortangle_f(real_angle_x, it.angles_x), 10);
                movelib_move_simple(it, v_forward, (autocvar_g_turrets_unit_walker_speed_swim), 0.3);
                vz = it.velocity_z + sin(time * 4) * 8;
                break;

            case ANIM_ROAM:
                turny = (autocvar_g_turrets_unit_walker_turn_walk);
                movelib_move_simple(it, v_forward ,(autocvar_g_turrets_unit_walker_speed_roam), 0.5);
                break;
        }

        if(turny)
        {
            turny = bound( turny * -1, shortangle_f(real_angle_y, it.angles_y), turny );
            it.angles_y += turny;
        }

        if(turnx)
        {
            turnx = bound( turnx * -1, shortangle_f(real_angle_x, it.angles_x), turnx );
            it.angles_x += turnx;
        }

        it.velocity_z = vz;
    }


    if(it.origin != it.oldorigin)
        it.SendFlags |= TNSF_MOVE;

    it.oldorigin = it.origin;
    turrets_setframe(it, it.animflag, false);
}
METHOD(WalkerTurret, tr_death, void(WalkerTurret this, entity it))
{
#ifdef WALKER_FANCYPATHING
    if (it.pathcurrent)
        pathlib_deletepath(it.pathcurrent.owner);
#endif
    it.pathcurrent = NULL;
}
METHOD(WalkerTurret, tr_setup, void(WalkerTurret this, entity it))
{
    // Respawn is called & first spawn to, to set team. need to make sure we do not move the initial spawn.
    if(it.move_movetype == MOVETYPE_WALK)
    {
        if(it.pos1)
            setorigin(it, it.pos1);
        if(it.pos2)
            it.angles = it.pos2;
    }

    it.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD;
    it.turret_flags |= TUR_FLAG_HITSCAN;

    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
    it.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
    it.iscreature = true;
    it.teleportable = TELEPORT_NORMAL;
    if(!it.damagedbycontents)
        IL_PUSH(g_damagedbycontents, it);
    it.damagedbycontents = true;
    it.solid = SOLID_SLIDEBOX;
    it.takedamage = DAMAGE_AIM;
    if(it.move_movetype != MOVETYPE_WALK)
    {
        setorigin(it, it.origin);
        tracebox(it.origin + '0 0 128', it.mins, it.maxs, it.origin - '0 0 10000', MOVE_NORMAL, it);
        setorigin(it, trace_endpos + '0 0 4');
        it.pos1 = it.origin;
        it.pos2 = it.angles;
    }
    set_movetype(it, MOVETYPE_WALK);
    it.idle_aim = '0 0 0';
    it.turret_firecheckfunc = walker_firecheck;

    if (it.target != "")
        InitializeEntity(it, walker_findtarget, INITPRIO_FINDTARGET);
}

#endif // SVQC
#ifdef CSQC

#include <common/physics/movelib.qh>

void walker_draw(entity this)
{
    float dt;

    dt = time - this.move_time;
    this.move_time = time;
    if(dt <= 0)
        return;

    fixedmakevectors(this.angles);
    movelib_groundalign4point(this, 300, 100, 0.25, 45);
    setorigin(this, this.origin + this.velocity * dt);
    this.tur_head.angles += dt * this.tur_head.avelocity;

    if(GetResource(this, RES_HEALTH) < 127)
    if(random() < 0.15)
        te_spark(this.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);
}

METHOD(WalkerTurret, tr_setup, void(WalkerTurret this, entity it))
{
    it.gravity		= 1;
    set_movetype(it, MOVETYPE_BOUNCE);
    it.move_time		= time;
    it.draw			= walker_draw;
}

#endif // CSQC
#ifdef MENUQC
#include <common/weapons/weapon/devastator.qh>
#include <common/weapons/weapon/machinegun.qh>

METHOD(WalkerTurret, describe, string(WalkerTurret this))
{
    TC(WalkerTurret, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is an arachnid-like walking turret that hunts down its targets."), COLORED_NAME(this));
    PAR(_("It has two weapons, both a machinegun like the %s for medium range combat, and a rocket launcher shooting homing missiles like the %s for long range targets. "
          "It also has the ability to melee close by targets."), COLORED_NAME(WEP_MACHINEGUN), COLORED_NAME(WEP_DEVASTATOR));
    return PAGE_TEXT;
}

#endif // MENUQC
