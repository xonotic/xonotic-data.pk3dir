#ifndef VEHICLE_RAPTOR_WEAPONS_H
#define VEHICLE_RAPTOR_WEAPONS_H

#include "../../weapons/all.qh"

CLASS(RaptorCannon, PortoLaunch)
/* flags     */ ATTRIB(RaptorCannon, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(RaptorCannon, impulse, int, 3);
/* refname   */ ATTRIB(RaptorCannon, netname, string, "raptorcannon");
/* wepname   */ ATTRIB(RaptorCannon, m_name, string, _("Raptor cannon"));
ENDCLASS(RaptorCannon)
REGISTER_WEAPON(RAPTOR, NEW(RaptorCannon));

CLASS(RaptorBomb, PortoLaunch)
/* flags     */ ATTRIB(RaptorBomb, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(RaptorBomb, impulse, int, 3);
/* refname   */ ATTRIB(RaptorBomb, netname, string, "raptorbomb");
/* wepname   */ ATTRIB(RaptorBomb, m_name, string, _("Raptor bomb"));
ENDCLASS(RaptorBomb)
REGISTER_WEAPON(RAPTOR_BOMB, NEW(RaptorBomb));

CLASS(RaptorFlare, PortoLaunch)
/* flags     */ ATTRIB(RaptorFlare, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(RaptorFlare, impulse, int, 3);
/* refname   */ ATTRIB(RaptorFlare, netname, string, "raptorflare");
/* wepname   */ ATTRIB(RaptorFlare, m_name, string, _("Raptor flare"));
ENDCLASS(RaptorFlare)
REGISTER_WEAPON(RAPTOR_FLARE, NEW(RaptorFlare));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_vehicle_raptor_cannon_cost;
float autocvar_g_vehicle_raptor_cannon_damage;
float autocvar_g_vehicle_raptor_cannon_radius;
float autocvar_g_vehicle_raptor_cannon_refire;
float autocvar_g_vehicle_raptor_cannon_speed;
float autocvar_g_vehicle_raptor_cannon_spread;
float autocvar_g_vehicle_raptor_cannon_force;

float autocvar_g_vehicle_raptor_bomblets;
float autocvar_g_vehicle_raptor_bomblet_alt;
float autocvar_g_vehicle_raptor_bomblet_time;
float autocvar_g_vehicle_raptor_bomblet_damage;
float autocvar_g_vehicle_raptor_bomblet_spread;
float autocvar_g_vehicle_raptor_bomblet_edgedamage;
float autocvar_g_vehicle_raptor_bomblet_radius;
float autocvar_g_vehicle_raptor_bomblet_force;
float autocvar_g_vehicle_raptor_bomblet_explode_delay;

METHOD(RaptorCannon, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    // 1 [wait] 1 [wait] 2 [wait] 2 [wait] [wait]
    float t = autocvar_g_vehicle_raptor_cannon_refire * (1 + veh.misc_bulletcounter == 4);
    if (fire & 1)
    if (weapon_prepareattack(thiswep, player, weaponentity, false, t)) {
        if (isPlayer) W_SetupShot_Dir(player, v_forward, false, 0, SND(Null), CH_WEAPON_B, 0);
        vector org = w_shotorg;
        vector dir = w_shotdir;
        if (veh) {
            veh.misc_bulletcounter += 1;
            org = (veh.misc_bulletcounter <= 2) ? gettaginfo(veh.gun1, gettagindex(veh.gun1, "fire1"))
              : (((veh.misc_bulletcounter == 4) ? veh.misc_bulletcounter = 0 : 0), gettaginfo(veh.gun2, gettagindex(veh.gun2, "fire1")));
            dir = v_forward;
            veh.vehicle_energy -= autocvar_g_vehicle_raptor_cannon_cost;
            actor.cnt = time;
        }
        vehicles_projectile(EFFECT_RAPTOR_MUZZLEFLASH.eent_eff_name, SND(LASERGUN_FIRE),
                               org, normalize(dir + randomvec() * autocvar_g_vehicle_raptor_cannon_spread) * autocvar_g_vehicle_raptor_cannon_speed,
                               autocvar_g_vehicle_raptor_cannon_damage, autocvar_g_vehicle_raptor_cannon_radius, autocvar_g_vehicle_raptor_cannon_force,  0,
                               DEATH_VH_RAPT_CANNON.m_id, PROJECTILE_RAPTORCANNON, 0, true, true, player);
        weapon_thinkf(player, weaponentity, WFRAME_FIRE1, 0, w_ready);
    }
}
METHOD(RaptorCannon, wr_checkammo1, bool(RacerAttack thiswep)) {
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    entity player = isPlayer ? self : self.owner;
    entity veh = player.vehicle;
    return isPlayer || veh.vehicle_energy >= autocvar_g_vehicle_raptor_cannon_cost;
}

float autocvar_g_vehicle_raptor_bombs_refire;

void raptor_bombdrop();
METHOD(RaptorBomb, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    if (fire & 2)
    if (!isPlayer || weapon_prepareattack(thiswep, player, weaponentity, true, autocvar_g_vehicle_raptor_bombs_refire)) {
        if (veh) setself(veh);
        raptor_bombdrop();
        weapon_thinkf(player, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}

float autocvar_g_vehicle_raptor_flare_refire;
float autocvar_g_vehicle_raptor_flare_lifetime;
float autocvar_g_vehicle_raptor_flare_chase;
float autocvar_g_vehicle_raptor_flare_range;

void raptor_flare_think();
void raptor_flare_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force);
void raptor_flare_touch();

METHOD(RaptorFlare, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    if (fire & 2)
    if (!isPlayer || weapon_prepareattack(thiswep, player, weaponentity, true, autocvar_g_vehicle_raptor_flare_refire)) {
        for(int i = 0; i < 3; ++i) {
            entity _flare = spawn();
            setmodel(_flare, MDL_VEH_RAPTOR_FLARE);
            _flare.effects = EF_LOWPRECISION | EF_FLAME;
            _flare.scale = 0.5;
            setorigin(_flare, actor.origin - '0 0 16');
            _flare.movetype = MOVETYPE_TOSS;
            _flare.gravity = 0.15;
            _flare.velocity = 0.25 * actor.velocity + (v_forward + randomvec() * 0.25)* -500;
            _flare.think = raptor_flare_think;
            _flare.nextthink = time;
            _flare.owner = veh ? veh : player;
            _flare.solid = SOLID_CORPSE;
            _flare.takedamage = DAMAGE_YES;
            _flare.event_damage = raptor_flare_damage;
            _flare.health = 20;
            _flare.tur_impacttime = time + autocvar_g_vehicle_raptor_flare_lifetime;
            _flare.touch = raptor_flare_touch;
        }
        weapon_thinkf(player, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}


void raptor_bomblet_boom()
{SELFPARAM();
    RadiusDamage (self, self.realowner, autocvar_g_vehicle_raptor_bomblet_damage,
                                    autocvar_g_vehicle_raptor_bomblet_edgedamage,
                                    autocvar_g_vehicle_raptor_bomblet_radius, world, world,
                                    autocvar_g_vehicle_raptor_bomblet_force, DEATH_VH_RAPT_BOMB.m_id, world);
    remove(self);
}

void raptor_bomblet_touch()
{SELFPARAM();
    if(other == self.owner)
        return;

    PROJECTILE_TOUCH;
    self.think = raptor_bomblet_boom;
    self.nextthink = time + random() * autocvar_g_vehicle_raptor_bomblet_explode_delay;
}

void raptor_bomb_burst()
{SELFPARAM();
    if(self.cnt > time)
    if(autocvar_g_vehicle_raptor_bomblet_alt)
    {
        self.nextthink = time;
        traceline(self.origin, self.origin + (normalize(self.velocity) * autocvar_g_vehicle_raptor_bomblet_alt), MOVE_NORMAL, self);
        if((trace_fraction == 1.0) || (vlen(self.origin - self.owner.origin) < autocvar_g_vehicle_raptor_bomblet_radius))
        {
            UpdateCSQCProjectile(self);
            return;
        }
    }

    entity bomblet;
    float i;

    Damage_DamageInfo(self.origin, 0, 0, 0, '0 0 0', DEATH_VH_RAPT_FRAGMENT.m_id, 0, self);

    for(i = 0; i < autocvar_g_vehicle_raptor_bomblets; ++i)
    {
        bomblet = spawn();
        setorigin(bomblet, self.origin);

        bomblet.movetype	= MOVETYPE_TOSS;
        bomblet.touch	   = raptor_bomblet_touch;
        bomblet.think	   = raptor_bomblet_boom;
        bomblet.nextthink   = time + 5;
        bomblet.owner	   = self.owner;
        bomblet.realowner   = self.realowner;
        bomblet.velocity	= normalize(normalize(self.velocity) + (randomvec() * autocvar_g_vehicle_raptor_bomblet_spread)) * vlen(self.velocity);

        PROJECTILE_MAKETRIGGER(bomblet);
        CSQCProjectile(bomblet, true, PROJECTILE_RAPTORBOMBLET, true);
    }

    remove(self);
}

void raptor_bombdrop()
{SELFPARAM();
    entity bomb_1, bomb_2;

    bomb_1 = spawn();
    bomb_2 = spawn();

    setorigin(bomb_1, gettaginfo(self, gettagindex(self, "bombmount_left")));
    setorigin(bomb_2, gettaginfo(self, gettagindex(self, "bombmount_right")));

    bomb_1.movetype	 = bomb_2.movetype   = MOVETYPE_BOUNCE;
    bomb_1.velocity	 = bomb_2.velocity   = self.velocity;
    bomb_1.touch		= bomb_2.touch	  = raptor_bomb_burst;
    bomb_1.think		= bomb_2.think	  = raptor_bomb_burst;
    bomb_1.cnt		  = bomb_2.cnt		= time + 10;

    if(autocvar_g_vehicle_raptor_bomblet_alt)
        bomb_1.nextthink = bomb_2.nextthink  = time;
    else
        bomb_1.nextthink = bomb_2.nextthink  = time + autocvar_g_vehicle_raptor_bomblet_time;

    bomb_1.owner	 = bomb_2.owner	  = self;
    bomb_1.realowner = bomb_2.realowner  = self.owner;
    bomb_1.solid	 = bomb_2.solid	  = SOLID_BBOX;
    bomb_1.gravity   = bomb_2.gravity	= 1;

    PROJECTILE_MAKETRIGGER(bomb_1);
    PROJECTILE_MAKETRIGGER(bomb_2);

    CSQCProjectile(bomb_1, true, PROJECTILE_RAPTORBOMB, true);
    CSQCProjectile(bomb_2, true, PROJECTILE_RAPTORBOMB, true);
}

void raptor_flare_touch()
{SELFPARAM();
    remove(self);
}

void raptor_flare_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
    self.health -= damage;
    if(self.health <= 0)
        remove(self);
}

void raptor_flare_think()
{SELFPARAM();
    self.nextthink = time + 0.1;
    entity _missile = findchainentity(enemy, self.owner);
    while(_missile)
    {
        if(_missile.flags & FL_PROJECTILE)
        if(vlen(self.origin - _missile.origin) < autocvar_g_vehicle_raptor_flare_range)
        if(random() > autocvar_g_vehicle_raptor_flare_chase)
            _missile.enemy = self;
        _missile = _missile.chain;
    }

    if(self.tur_impacttime < time)
        remove(self);
}

#endif

#ifdef CSQC

void RaptorCBShellfragDraw(entity this)
{
    if(wasfreed(self))
        return;

    Movetype_Physics_MatchTicrate(self, autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);
    self.move_avelocity += randomvec() * 15;
    self.renderflags = 0;

    if(self.cnt < time)
        self.alpha = bound(0, self.nextthink - time, 1);

    if(self.alpha < ALPHA_MIN_VISIBLE)
        remove(self);
}

void RaptorCBShellfragToss(vector _org, vector _vel, vector _ang)
{SELFPARAM();
    entity sfrag;

    sfrag = spawn();
    setmodel(sfrag, MDL_VEH_RAPTOR_CB_FRAGMENT);
    setorigin(sfrag, _org);

    sfrag.move_movetype = MOVETYPE_BOUNCE;
    sfrag.gravity = 0.15;
    sfrag.solid = SOLID_CORPSE;

    sfrag.draw = RaptorCBShellfragDraw;

    sfrag.move_origin = sfrag.origin = _org;
    sfrag.move_velocity = _vel;
    sfrag.move_avelocity = prandomvec() * vlen(sfrag.move_velocity);
    sfrag.angles = self.move_angles = _ang;

    sfrag.move_time = time;
    sfrag.damageforcescale = 4;

    sfrag.nextthink = time + 3;
    sfrag.cnt = time + 2;
    sfrag.alpha = 1;
    sfrag.drawmask = MASK_NORMAL;
}

#endif

#endif
