#include "steerlib.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "pathlib/utility.qh"
#endif

/**
    Uniform pull towards a point
**/
#define steerlib_pull(ent,point) normalize(point - (ent).origin)
/*vector steerlib_pull(entity this, vector point)
{
    return normalize(point - this.origin);
}*/

/**
    Uniform push from a point
**/
#define steerlib_push(ent,point) normalize(ent.origin - point)
/*
vector steerlib_push(entity this, vector point)
{
    return normalize(this.origin - point);
}
*/
/**
    Pull toward a point, The further away, the stronger the pull.
**/
vector steerlib_arrive(entity this, vector point, float maximal_distance)
{
    float distance;
    vector direction;

    distance = bound(0.001,vlen(this.origin - point),maximal_distance);
    direction = normalize(point - this.origin);
    return  direction * (distance / maximal_distance);
}

/**
    Pull toward a point increasing the pull the closer we get
**/
vector steerlib_attract(entity this, vector point, float maximal_distance)
{
    float distance;
    vector direction;

    distance = bound(0.001,vlen(this.origin - point),maximal_distance);
    direction = normalize(point - this.origin);

    return  direction * (1-(distance / maximal_distance));
}

vector steerlib_attract2(entity this, vector point, float min_influense,float max_distance,float max_influense)
{
    float distance;
    vector direction;
    float influense;

    distance  = bound(0.00001,vlen(this.origin - point),max_distance);
    direction = normalize(point - this.origin);

    influense = 1 - (distance / max_distance);
    influense = min_influense + (influense * (max_influense - min_influense));

    return  direction * influense;
}

/*
vector steerlib_attract2(vector point, float maximal_distance,float min_influense,float max_influense,float distance)
{
    //float distance;
    vector current_direction;
    vector target_direction;
    float i_target,i_current;

    if(!distance)
        distance = vlen(this.origin - point);

    distance = bound(0.001,distance,maximal_distance);

    target_direction = normalize(point - this.origin);
    current_direction = normalize(this.velocity);

    i_target = bound(min_influense,(1-(distance / maximal_distance)),max_influense);
    i_current = 1 - i_target;

    // i_target = bound(min_influense,(1-(distance / maximal_distance)),max_influense);

    string s;
    s = ftos(i_target);
    bprint("IT: ",s,"\n");
    s = ftos(i_current);
    bprint("IC  : ",s,"\n");

    return  normalize((target_direction * i_target) + (current_direction * i_current));
}
*/
/**
    Move away from a point.
**/
vector steerlib_repell(entity this, vector point,float maximal_distance)
{
    float distance;
    vector direction;

    distance = bound(0.001,vlen(this.origin - point),maximal_distance);
    direction = normalize(this.origin - point);

    return  direction * (1-(distance / maximal_distance));
}

/**
    Try to keep at ideal_distance away from point
**/
vector steerlib_standoff(entity this, vector point,float ideal_distance)
{
    float distance;
    vector direction;

    distance = vlen(this.origin - point);


    if(distance < ideal_distance)
    {
        direction = normalize(this.origin - point);
        return direction * (distance / ideal_distance);
    }

    direction = normalize(point - this.origin);
    return direction * (ideal_distance / distance);

}

/**
    A random heading in a forward halfcicrle

    use like:
    this.target = steerlib_wander(256,32,this.target)

    where range is the cicrle radius and tresh is how close we need to be to pick a new heading.
**/
vector steerlib_wander(entity this, float range, float tresh, vector oldpoint)
{
    vector wander_point;
    wander_point = v_forward - oldpoint;

    if (vdist(wander_point, >, tresh))
        return oldpoint;

    range = bound(0,range,1);

    wander_point = this.origin + v_forward * 128;
    wander_point = wander_point + randomvec() * (range * 128) - randomvec() * (range * 128);

    return normalize(wander_point - this.origin);
}

/**
    Dodge a point. dont work to well.
**/
vector steerlib_dodge(entity this, vector point, vector dodge_dir, float min_distance)
{
    float distance;

    distance = max(vlen(this.origin - point),min_distance);
    if (min_distance < distance)
        return '0 0 0';

    return dodge_dir * (min_distance/distance);
}

/**
    flocking by .flock_id
    Group will move towards the unified direction while keeping close to eachother.
**/
.float flock_id;
vector steerlib_flock(entity this, float _radius, float standoff,float separation_force,float flock_force)
{
    entity flock_member;
    vector push = '0 0 0', pull = '0 0 0';
    float ccount = 0;

    flock_member = findradius(this.origin, _radius);
    while(flock_member)
    {
        if(flock_member != this)
        if(flock_member.flock_id == this.flock_id)
        {
            ++ccount;
            push = push + (steerlib_repell(this, flock_member.origin,standoff) * separation_force);
            pull = pull + (steerlib_arrive(this, flock_member.origin + flock_member.velocity, _radius) * flock_force);
        }
        flock_member = flock_member.chain;
    }
    return push + (pull* (1 / ccount));
}

/**
    flocking by .flock_id
    Group will move towards the unified direction while keeping close to eachother.
    xy only version (for ground movers).
**/
vector steerlib_flock2d(entity this, float _radius, float standoff,float separation_force,float flock_force)
{
    entity flock_member;
    vector push = '0 0 0', pull = '0 0 0';
    float ccount = 0;

    flock_member = findradius(this.origin,_radius);
    while(flock_member)
    {
        if(flock_member != this)
        if(flock_member.flock_id == this.flock_id)
        {
            ++ccount;
            push = push + (steerlib_repell(this, flock_member.origin, standoff) * separation_force);
            pull = pull + (steerlib_arrive(this, flock_member.origin + flock_member.velocity, _radius) * flock_force);
        }
        flock_member = flock_member.chain;
    }

    push.z = 0;
    pull.z = 0;

    return push + (pull * (1 / ccount));
}

/**
    All members want to be in the center, and keep away from eachother.
    The furtehr form the center the more they want to be there.

    This results in a aligned movement (?!) much like flocking.
**/
vector steerlib_swarm(entity this, float _radius, float standoff,float separation_force,float swarm_force)
{
    entity swarm_member;
    vector force = '0 0 0', center = '0 0 0';
    float ccount = 0;

    swarm_member = findradius(this.origin,_radius);

    while(swarm_member)
    {
        if(swarm_member.flock_id == this.flock_id)
        {
            ++ccount;
            center = center + swarm_member.origin;
            force = force + (steerlib_repell(this, swarm_member.origin,standoff) * separation_force);
        }
        swarm_member = swarm_member.chain;
    }

    center = center * (1 / ccount);
    force = force + (steerlib_arrive(this, center,_radius) * swarm_force);

    return force;
}

/**
    Steer towards the direction least obstructed.
    Run four tracelines in a forward funnel, bias each diretion negative if something is found there.
    You need to call makevectors() (or equivalent) before this function to set v_forward and v_right
**/
vector steerlib_traceavoid(entity this, float pitch,float length)
{
    vector vup_left,vup_right,vdown_left,vdown_right;
    float fup_left,fup_right,fdown_left,fdown_right;
    vector upwish,downwish,leftwish,rightwish;
    vector v_left,v_down;


    v_left = v_right * -1;
    v_down = v_up * -1;

    vup_left = (v_forward + (v_left * pitch + v_up * pitch)) * length;
    traceline(this.origin, this.origin +  vup_left,MOVE_NOMONSTERS,this);
    fup_left = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);

    vup_right = (v_forward + (v_right * pitch + v_up * pitch)) * length;
    traceline(this.origin,this.origin + vup_right ,MOVE_NOMONSTERS,this);
    fup_right = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);

    vdown_left = (v_forward + (v_left * pitch + v_down * pitch)) * length;
    traceline(this.origin,this.origin + vdown_left,MOVE_NOMONSTERS,this);
    fdown_left = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);

    vdown_right = (v_forward + (v_right * pitch + v_down * pitch)) * length;
    traceline(this.origin,this.origin + vdown_right,MOVE_NOMONSTERS,this);
    fdown_right = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);
    upwish    = v_up    * (fup_left   + fup_right);
    downwish  = v_down  * (fdown_left + fdown_right);
    leftwish  = v_left  * (fup_left   + fdown_left);
    rightwish = v_right * (fup_right  + fdown_right);

    return (upwish+leftwish+downwish+rightwish) * 0.25;

}

/**
    Steer towards the direction least obstructed.
    Run tracelines in a forward trident, bias each direction negative if something is found there.
**/
vector steerlib_traceavoid_flat(entity this, float pitch, float length, vector vofs)
{
    vector vt_left, vt_right,vt_front;
    float f_left, f_right,f_front;
    vector leftwish, rightwish,frontwish, v_left;

    v_left = v_right * -1;


    vt_front = v_forward * length;
    traceline(this.origin + vofs, this.origin + vofs + vt_front,MOVE_NOMONSTERS,this);
    f_front = trace_fraction;

    vt_left = (v_forward + (v_left * pitch)) * length;
    traceline(this.origin + vofs, this.origin + vofs + vt_left,MOVE_NOMONSTERS,this);
    f_left = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);

    vt_right = (v_forward + (v_right * pitch)) * length;
    traceline(this.origin + vofs, this.origin + vofs + vt_right ,MOVE_NOMONSTERS,this);
    f_right = trace_fraction;

    //te_lightning1(NULL,this.origin, trace_endpos);

    leftwish  = v_left    * f_left;
    rightwish = v_right   * f_right;
    frontwish = v_forward * f_front;

    return normalize(leftwish + rightwish + frontwish);
}

//#define BEAMSTEER_VISUAL
float beamsweep(entity this, vector from, vector dir,float length, float step,float step_up, float step_down)
{
    float i;
    vector a, b, u, d;

    u = '0 0 1' * step_up;
    d = '0 0 1' * step_down;

    traceline(from + u, from - d,MOVE_NORMAL,this);
    if(trace_fraction == 1.0)
        return 0;

    if(!location_isok(trace_endpos, false, false))
        return 0;

    a = trace_endpos;
    for(i = 0; i < length; i += step)
    {

        b = a + dir * step;
        tracebox(a + u,'-4 -4 -4','4 4 4', b + u,MOVE_NORMAL,this);
        if(trace_fraction != 1.0)
            return i / length;

        traceline(b + u, b - d,MOVE_NORMAL,this);
        if(trace_fraction == 1.0)
            return i / length;

        if(!location_isok(trace_endpos, false, false))
            return i / length;
#ifdef BEAMSTEER_VISUAL
        te_lightning1(NULL,a+u,b+u);
        te_lightning1(NULL,b+u,b-d);
#endif
        a = trace_endpos;
    }

    return 1;
}

vector steerlib_beamsteer(entity this, vector dir, float length, float step, float step_up, float step_down)
{
    float bm_forward, bm_right, bm_left,p;
    vector vr,vl;

    dir.z *= 0.15;
    vr = vectoangles(dir);
    //vr_x *= -1;

    tracebox(this.origin + '0 0 1' * step_up, this.mins, this.maxs, ('0 0 1' * step_up) + this.origin +  (dir * length), MOVE_NOMONSTERS, this);
    if(trace_fraction == 1.0)
    {
        //te_lightning1(this,this.origin,this.origin +  (dir * length));
        return dir;
    }

    makevectors(vr);
    bm_forward = beamsweep(this, this.origin, v_forward, length, step, step_up, step_down);

    vr = normalize(v_forward + v_right * 0.125);
    vl = normalize(v_forward - v_right * 0.125);

    bm_right = beamsweep(this, this.origin, vr, length, step, step_up, step_down);
    bm_left  = beamsweep(this, this.origin, vl, length, step, step_up, step_down);


    p = bm_left + bm_right;
    if(p == 2)
    {
        //te_lightning1(this,this.origin + '0 0 32',this.origin + '0 0 32' + vr * length);
        //te_lightning1(this.tur_head,this.origin + '0 0 32',this.origin + '0 0 32' + vl * length);

        return v_forward;
    }

    p = 2 - p;

    vr = normalize(v_forward + v_right * p);
    vl = normalize(v_forward - v_right * p);
    bm_right = beamsweep(this, this.origin, vr, length, step, step_up, step_down);
    bm_left  = beamsweep(this, this.origin, vl, length, step, step_up, step_down);


    if(bm_left + bm_right < 0.15)
    {
        vr = normalize((v_forward*-1) + v_right * 0.90);
        vl = normalize((v_forward*-1) - v_right * 0.90);

        bm_right = beamsweep(this, this.origin, vr, length, step, step_up, step_down);
        bm_left  = beamsweep(this, this.origin, vl, length, step, step_up, step_down);
    }

    //te_lightning1(this,this.origin + '0 0 32',this.origin + '0 0 32' + vr * length);
    //te_lightning1(this.tur_head,this.origin + '0 0 32',this.origin + '0 0 32' + vl * length);

    bm_forward *= bm_forward;
    bm_right   *= bm_right;
    bm_left    *= bm_left;

    vr = vr * bm_right;
    vl = vl * bm_left;

    return normalize(vr + vl);

}


//////////////////////////////////////////////
//     Testting                             //
// Everything below this point is a mess :D //
//////////////////////////////////////////////
//#define TLIBS_TETSLIBS
#ifdef TLIBS_TETSLIBS
void flocker_die(entity this)
{
	Send_Effect(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);

    this.owner.cnt += 1;
    this.owner = NULL;

    this.nextthink = time;
    setthink(this, SUB_Remove);
}


void flocker_think(entity this)
{
    vector dodgemove,swarmmove;
    vector reprellmove,wandermove,newmove;

    this.angles_x = this.angles.x * -1;
    makevectors(this.angles);
    this.angles_x = this.angles.x * -1;

    dodgemove   = steerlib_traceavoid(this, 0.35,1000);
    swarmmove   = steerlib_flock(this, 500,75,700,500);
    reprellmove = steerlib_repell(this, this.owner.enemy.origin+this.enemy.velocity,2000) * 700;

    if(dodgemove == '0 0 0')
    {
        this.pos1 = steerlib_wander(this, 0.5,0.1,this.pos1);
        wandermove  = this.pos1 * 50;
    }
    else
        this.pos1 = normalize(this.velocity);

    dodgemove = dodgemove * vlen(this.velocity) * 5;

    newmove = swarmmove + reprellmove + wandermove + dodgemove;
    this.velocity = movelib_inertmove_byspeed(this, newmove,300,0.2,0.9);
    //this.velocity  = movelib_inertmove(this, dodgemove,0.65);

    this.velocity = movelib_dragvec(this, 0.01,0.6);

    this.angles = vectoangles(this.velocity);

    if(this.health <= 0)
        flocker_die(this);
    else
        this.nextthink = time + 0.1;
}

MODEL(FLOCKER, "models/turrets/rocket.md3");

void spawn_flocker(entity this)
{
    entity flocker = new(flocker);

    setorigin(flocker, this.origin + '0 0 32');
    setmodel (flocker, MDL_FLOCKER);
    setsize (flocker, '-3 -3 -3', '3 3 3');

    flocker.flock_id   = this.flock_id;
    flocker.owner      = this;
    setthink(flocker, flocker_think);
    flocker.nextthink  = time + random() * 5;
    PROJECTILE_MAKETRIGGER(flocker);
    set_movetype(flocker, MOVETYPE_BOUNCEMISSILE);
    flocker.effects    = EF_LOWPRECISION;
    flocker.velocity   = randomvec() * 300;
    flocker.angles     = vectoangles(flocker.velocity);
    flocker.health     = 10;
    flocker.pos1      = normalize(flocker.velocity + randomvec() * 0.1);

    this.cnt = this.cnt -1;

}

void flockerspawn_think(entity this)
{
    if(this.cnt > 0)
        spawn_flocker(this);

    this.nextthink = time + this.delay;

}

void flocker_hunter_think(entity this)
{
    vector dodgemove,attractmove,newmove;
    entity ee;

    this.angles_x = this.angles.x * -1;
    makevectors(this.angles);
    this.angles_x = this.angles.x * -1;

    if(this.enemy)
    if(vdist(this.enemy.origin - this.origin, <, 64))
    {
        ee = this.enemy;
        ee.health = -1;
        this.enemy = NULL;

    }

    if(!this.enemy)
    {
        FOREACH_ENTITY_FLOAT(flock_id, this.flock_id,
        {
            if(it == this.owner || it == ee)
                continue;

            if(!this.enemy || vlen2(this.origin - it.origin) > vlen2(this.origin - this.enemy.origin))
                this.enemy = it;
        });
    }

    if(this.enemy)
        attractmove = steerlib_attract(this, this.enemy.origin+this.enemy.velocity * 0.1,5000) * 1250;
    else
        attractmove = normalize(this.velocity) * 200;

    dodgemove = steerlib_traceavoid(this, 0.35,1500) * vlen(this.velocity);

    newmove = dodgemove + attractmove;
    this.velocity = movelib_inertmove_byspeed(this, newmove,1250,0.3,0.7);
    this.velocity = movelib_dragvec(this, 0.01,0.5);

    this.angles = vectoangles(this.velocity);
    this.nextthink = time + 0.1;
}


float globflockcnt;
spawnfunc(flockerspawn)
{
    ++globflockcnt;

    if(!this.cnt)      this.cnt = 20;
    if(!this.delay)    this.delay = 0.25;
    if(!this.flock_id) this.flock_id = globflockcnt;

    setthink(this, flockerspawn_think);
    this.nextthink = time + 0.25;

    this.enemy = new(FLock Hunter);

    setmodel(this.enemy, MDL_FLOCKER);
    setorigin(this.enemy, this.origin + '0 0 768' + (randomvec() * 128));

    this.enemy.scale     = 3;
    this.enemy.effects   = EF_LOWPRECISION;
    set_movetype(this.enemy, MOVETYPE_BOUNCEMISSILE);
    PROJECTILE_MAKETRIGGER(this.enemy);
    setthink(this.enemy, flocker_hunter_think);
    this.enemy.nextthink = time + 10;
    this.enemy.flock_id  = this.flock_id;
    this.enemy.owner     = this;
}
#endif



