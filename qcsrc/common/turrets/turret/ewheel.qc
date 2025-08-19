#include "ewheel.qh"

#ifdef SVQC

float autocvar_g_turrets_unit_ewheel_speed_fast;
float autocvar_g_turrets_unit_ewheel_speed_slow;
float autocvar_g_turrets_unit_ewheel_speed_slower;
float autocvar_g_turrets_unit_ewheel_speed_stop;
float autocvar_g_turrets_unit_ewheel_turnrate;

const int ewheel_anim_stop     = 0;
const int ewheel_anim_fwd_slow = 1;
const int ewheel_anim_fwd_fast = 2;
const int ewheel_anim_bck_slow = 3;
const int ewheel_anim_bck_fast = 4;

void ewheel_move_path(entity this)
{
    // Are we close enough to a path node to switch to the next?
    if(turret_closetotarget(this, this.pathcurrent.origin, 64))
    {
#ifdef EWHEEL_FANCYPATH
        if (this.pathcurrent.path_next == NULL)
        {
            // Path endpoint reached
            pathlib_deletepath(this.pathcurrent.owner);
            this.pathcurrent = NULL;

            if (this.pathgoal)
            {
                if (this.pathgoal.use)
                    this.pathgoal.use(this.pathgoal, NULL, NULL);

                if (this.pathgoal.enemy)
                {
                    this.pathcurrent = pathlib_astar(this, this.pathgoal.origin,this.pathgoal.enemy.origin);
                    this.pathgoal = this.pathgoal.enemy;
                }
            }
            else
                this.pathgoal = NULL;
        }
        else
            this.pathcurrent = this.pathcurrent.path_next;
#else
        this.pathcurrent = this.pathcurrent.enemy;
#endif
    }

    if (this.pathcurrent)
    {
        this.moveto = this.pathcurrent.origin;
        this.steerto = steerlib_attract2(this, this.moveto, 0.5, 500, 0.95);

        movelib_move_simple(this, v_forward, (autocvar_g_turrets_unit_ewheel_speed_fast), 0.4);
    }
}

void ewheel_move_enemy(entity this)
{
    int newframe;

    this.steerto = steerlib_arrive(this, this.enemy.origin,this.target_range_optimal);

    this.moveto = this.origin + this.steerto * 128;

    if (this.tur_dist_enemy > this.target_range_optimal)
    {
        if ( this.tur_head.spawnshieldtime < 1 )
        {
            newframe = ewheel_anim_fwd_fast;
            movelib_move_simple(this, v_forward, (autocvar_g_turrets_unit_ewheel_speed_fast), 0.4);
        }
        else if (this.tur_head.spawnshieldtime < 2)
        {
            newframe = ewheel_anim_fwd_slow;
            movelib_move_simple(this, v_forward, (autocvar_g_turrets_unit_ewheel_speed_slow), 0.4);
        }
        else
        {
            newframe = ewheel_anim_fwd_slow;
            movelib_move_simple(this, v_forward, (autocvar_g_turrets_unit_ewheel_speed_slower), 0.4);
        }
    }
    else if (this.tur_dist_enemy < this.target_range_optimal * 0.5)
    {
        newframe = ewheel_anim_bck_slow;
        movelib_move_simple(this, v_forward * -1, (autocvar_g_turrets_unit_ewheel_speed_slow), 0.4);
    }
    else
    {
        newframe = ewheel_anim_stop;
        movelib_brake_simple(this, (autocvar_g_turrets_unit_ewheel_speed_stop));
    }

    turrets_setframe(this, newframe, false);
}

void ewheel_move_idle(entity this)
{
    if(this.frame != 0)
    {
        this.SendFlags |= TNSF_ANIM;
        this.anim_start_time = time;
    }

    this.frame = 0;
    if(this.velocity)
        movelib_brake_simple(this, (autocvar_g_turrets_unit_ewheel_speed_stop));
}

void ewheel_findtarget(entity this)
{
    entity e = find(NULL, targetname, this.target);
    if (!e)
    {
        LOG_TRACE("Initital waypoint for ewheel does NOT exist, fix your map!");
        this.target = "";
    }

    if (e.classname != "turret_checkpoint")
        LOG_TRACE("Warning: not a turret path");
    else
    {

#ifdef EWHEEL_FANCYPATH
        this.pathcurrent = pathlib_astar(this, this.origin, e.origin);
        this.pathgoal = e;
#else
        this.pathcurrent  = e;
#endif
    }
}

spawnfunc(turret_ewheel) { if(!turret_initialize(this, TUR_EWHEEL)) delete(this); }

METHOD(EWheel, tr_think, void(EWheel thistur, entity it))
{
    vector wish_angle, real_angle;

    float vz = it.velocity_z;

    it.angles_x = anglemods(it.angles_x);
    it.angles_y = anglemods(it.angles_y);

    fixedmakevectors(it.angles);

    wish_angle = normalize(it.steerto);
    wish_angle = vectoangles(wish_angle);
    real_angle = wish_angle - it.angles;
    real_angle = shortangle_vxy(real_angle, it.tur_head.angles);

    it.tur_head.spawnshieldtime = fabs(real_angle_y);

    float f = it.tur_head.aim_speed * frametime;
    real_angle_y = bound(-f, real_angle_y, f);
    it.angles_y = (it.angles_y + real_angle_y);

    if(it.enemy)
        ewheel_move_enemy(it);
    else if(it.pathcurrent)
        ewheel_move_path(it);
    else
        ewheel_move_idle(it);

    it.velocity_z = vz;

    if(it.velocity)
        it.SendFlags |= TNSF_MOVE;
}

METHOD(EWheel, tr_death, void(EWheel this, entity it))
{
    it.velocity = '0 0 0';

#ifdef EWHEEL_FANCYPATH
    if (it.pathcurrent)
        pathlib_deletepath(it.pathcurrent.owner);
#endif
    it.pathcurrent = NULL;
}

METHOD(EWheel, tr_setup, void(EWheel this, entity it))
{
    if(it.move_movetype == MOVETYPE_WALK)
    {
        it.velocity = '0 0 0';
        it.enemy = NULL;

        setorigin(it, it.pos1);

        if (it.target != "")
            InitializeEntity(it, ewheel_findtarget, INITPRIO_FINDTARGET);
    }

    it.iscreature				= true;
    it.teleportable			= TELEPORT_NORMAL;
    if(!it.damagedbycontents)
        IL_PUSH(g_damagedbycontents, it);
    it.damagedbycontents        = true;
    set_movetype(it, MOVETYPE_WALK);
    it.solid					= SOLID_SLIDEBOX;
    it.takedamage				= DAMAGE_AIM;
    it.idle_aim				= '0 0 0';
    it.pos1					= it.origin;
    it.target_select_flags	= TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
    it.target_validate_flags	= TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
    it.frame					= it.tur_head.frame = 1;
    it.ammo_flags				= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;

    it.tur_head.aim_speed = autocvar_g_turrets_unit_ewheel_turnrate;
}

#endif // SVQC
#ifdef CSQC

void ewheel_draw(entity this)
{
    float dt;

    dt = time - this.move_time;
    this.move_time = time;
    if(dt <= 0)
        return;

    fixedmakevectors(this.angles);
    setorigin(this, this.origin + this.velocity * dt);
    this.tur_head.angles += dt * this.tur_head.avelocity;

    if(GetResource(this, RES_HEALTH) < 127)
    if(random() < 0.05)
        te_spark(this.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);
}

METHOD(EWheel, tr_setup, void(EWheel this, entity it))
{
    it.gravity		= 1;
    set_movetype(it, MOVETYPE_BOUNCE);
    it.move_time		= time;
    it.draw			= ewheel_draw;
}

#endif // CSQC
#ifdef MENUQC
#include <common/weapons/weapon/blaster.qh>

METHOD(EWheel, describe, string(EWheel this))
{
    TC(Ewheel, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a mobile turret that rolls around, attacking its targets when they enter its line of sight."), COLORED_NAME(this));
    PAR(_("It attacks by shooting laser beams similar to those of the %s, from both of its two cannons."), COLORED_NAME(WEP_BLASTER));
    return PAGE_TEXT;
}

#endif // MENUQC
