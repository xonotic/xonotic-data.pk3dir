#include "hellion.qh"

#ifdef SVQC

float autocvar_g_turrets_unit_hellion_shot_speed_gain;
float autocvar_g_turrets_unit_hellion_shot_speed_max;

void turret_hellion_missile_think(entity this)
{
    vector olddir,newdir;
    vector pre_pos;
    float itime;

    this.nextthink = time + 0.05;

    olddir = normalize(this.velocity);

    if(this.max_health < time)
        turret_projectile_explode(this);

    // Enemy dead? just keep on the current heading then.
    if ((this.enemy == NULL) || (IS_DEAD(this.enemy)))
    {

        // Make sure we dont return to tracking a respawned player
        this.enemy = NULL;

        // Turn model
        this.angles = vectoangles(this.velocity);

        if(vdist(this.origin - this.owner.origin, >, (this.owner.shot_radius * 5)))
            turret_projectile_explode(this);

        // Accelerate
        this.velocity = olddir * min(vlen(this.velocity) * (autocvar_g_turrets_unit_hellion_shot_speed_gain), (autocvar_g_turrets_unit_hellion_shot_speed_max));

        UpdateCSQCProjectile(this);

        return;
    }

    // Enemy in range?
    if(vdist(this.origin - this.enemy.origin, <, this.owner.shot_radius * 0.2))
        turret_projectile_explode(this);

    // Predict enemy position
    itime = vlen(this.enemy.origin - this.origin) / vlen(this.velocity);
    pre_pos = this.enemy.origin + this.enemy.velocity * itime;

    pre_pos = (pre_pos + this.enemy.origin) * 0.5;

    // Find out the direction to that place
    newdir = normalize(pre_pos - this.origin);

    // Turn
    newdir = normalize(olddir + newdir * 0.35);

    // Turn model
    this.angles = vectoangles(this.velocity);

    // Accelerate
    this.velocity = newdir * min(vlen(this.velocity) * (autocvar_g_turrets_unit_hellion_shot_speed_gain), (autocvar_g_turrets_unit_hellion_shot_speed_max));

    if (itime < 0.05)
        setthink(this, turret_projectile_explode);

    UpdateCSQCProjectile(this);
}

spawnfunc(turret_hellion) { if (!turret_initialize(this, TUR_HELLION)) delete(this); }

SOUND(HellionAttack_FIRE, W_Sound("rocket_fire"));
METHOD(Hellion, tr_attack, void(Hellion this, entity actor))
{
    if (actor.tur_head.frame != 0)
        actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire"));
    else
        actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire2"));

    entity missile = turret_projectile(actor, SND_HellionAttack_FIRE, 6, 10, DEATH_TURRET_HELLION.m_id, PROJECTILE_ROCKET, false, false);
    te_explosion (missile.origin);
    setthink(missile, turret_hellion_missile_think);
    missile.nextthink = time;
    missile.max_health = time + 9;
    missile.tur_aimpos = randomvec() * 128;
    missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_HEAT;

    actor.tur_head.frame += 1;
}

METHOD(Hellion, tr_think, void(Hellion thistur, entity it))
{
    if (it.tur_head.frame != 0)
        it.tur_head.frame += 1;

    if (it.tur_head.frame >= 7)
        it.tur_head.frame = 0;
}
METHOD(Hellion, tr_setup, void(Hellion this, entity it))
{
    it.aim_flags = TFL_AIM_SIMPLE;
    it.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK ;
    it.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_TEAMCHECK | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF | TFL_FIRECHECK_AMMO_OWN;
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
}

#endif
