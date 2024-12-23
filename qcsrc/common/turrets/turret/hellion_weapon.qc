#include "hellion_weapon.qh"

#ifdef SVQC

float autocvar_g_turrets_unit_hellion_shot_speed_gain;
float autocvar_g_turrets_unit_hellion_shot_speed_max;

void turret_hellion_missile_think(entity this);
SOUND(HellionAttack_FIRE, W_Sound("rocket_fire"));
METHOD(HellionAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_HellionAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_HELLION.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_radius = 500;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }
        if (!isPlayer) {
            if (actor.tur_head.frame != 0)
                actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire"));
            else
                actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire2"));
        }

        entity missile = turret_projectile(actor, SND_HellionAttack_FIRE, 6, 10, DEATH_TURRET_HELLION.m_id, PROJECTILE_ROCKET, false, false);
        te_explosion (missile.origin);
        setthink(missile, turret_hellion_missile_think);
        missile.nextthink	= time;
        missile.max_health   = time + 9;
        missile.tur_aimpos   = randomvec() * 128;
        missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_HEAT;
        if (!isPlayer) actor.tur_head.frame += 1;
    }
}

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

#endif
