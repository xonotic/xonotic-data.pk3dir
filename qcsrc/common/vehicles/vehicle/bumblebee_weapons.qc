#ifndef VEHICLE_BUMBLEBEE_WEAPONS_H
#define VEHICLE_BUMBLEBEE_WEAPONS_H

#include "../../weapons/all.qh"

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_vehicle_bumblebee_cannon_cost;
float autocvar_g_vehicle_bumblebee_cannon_damage;
float autocvar_g_vehicle_bumblebee_cannon_radius;
float autocvar_g_vehicle_bumblebee_cannon_refire;
float autocvar_g_vehicle_bumblebee_cannon_speed;
float autocvar_g_vehicle_bumblebee_cannon_spread;
float autocvar_g_vehicle_bumblebee_cannon_force;

bool bumble_raygun_send(entity this, entity to, int sf);

void bumblebee_fire_cannon(entity _gun, string _tagname, entity _owner)
{
    vector v = gettaginfo(_gun, gettagindex(_gun, _tagname));
    vehicles_projectile(EFFECT_BIGPLASMA_MUZZLEFLASH.eent_eff_name, SND(VEH_BUMBLEBEE_FIRE),
                        v, normalize(v_forward + randomvec() * autocvar_g_vehicle_bumblebee_cannon_spread) * autocvar_g_vehicle_bumblebee_cannon_speed,
                        autocvar_g_vehicle_bumblebee_cannon_damage, autocvar_g_vehicle_bumblebee_cannon_radius, autocvar_g_vehicle_bumblebee_cannon_force,  0,
                        DEATH_VH_BUMB_GUN.m_id, PROJECTILE_BUMBLE_GUN, 0, true, true, _owner);
}

bool bumble_raygun_send(entity this, entity to, float sf)
{
    WriteByte(MSG_ENTITY, ENT_CLIENT_BUMBLE_RAYGUN);

    WriteByte(MSG_ENTITY, sf);
    if(sf & BRG_SETUP)
    {
        WriteByte(MSG_ENTITY, num_for_edict(self.realowner));
        WriteByte(MSG_ENTITY, self.realowner.team);
        WriteByte(MSG_ENTITY, self.cnt);
    }

    if(sf & BRG_START)
    {
        WriteCoord(MSG_ENTITY, self.hook_start_x);
        WriteCoord(MSG_ENTITY, self.hook_start_y);
        WriteCoord(MSG_ENTITY, self.hook_start_z);
    }

    if(sf & BRG_END)
    {
        WriteCoord(MSG_ENTITY, self.hook_end_x);
        WriteCoord(MSG_ENTITY, self.hook_end_y);
        WriteCoord(MSG_ENTITY, self.hook_end_z);
    }

    return true;
}

#endif

#ifdef CSQC

void bumble_raygun_draw(entity this);

void bumble_raygun_read(bool bIsNew)
{SELFPARAM();
    int sf = ReadByte();

    if(sf & BRG_SETUP)
    {
        self.cnt  = ReadByte();
        self.team = ReadByte();
        self.cnt  = ReadByte();

        if(self.cnt)
            self.colormod = '1 0 0';
        else
            self.colormod = '0 1 0';

        self.traileffect = EFFECT_BUMBLEBEE_HEAL_MUZZLEFLASH.m_id;
        self.lip = particleeffectnum(EFFECT_BUMBLEBEE_HEAL_IMPACT);

        self.draw = bumble_raygun_draw;
    }


    if(sf & BRG_START)
    {
        self.origin_x = ReadCoord();
        self.origin_y = ReadCoord();
        self.origin_z = ReadCoord();
        setorigin(self, self.origin);
    }

    if(sf & BRG_END)
    {
        self.move_origin_x = ReadCoord();
        self.move_origin_y = ReadCoord();
        self.move_origin_z = ReadCoord();
    }
}

void bumble_raygun_draw(entity this)
{
    float _len;
    vector _dir;
    vector _vtmp1, _vtmp2;

    _len = vlen(self.origin - self.move_origin);
    _dir = normalize(self.move_origin - self.origin);

    if(self.total_damages < time)
    {
        boxparticles(particleeffectnum(Effects[self.traileffect]), self, self.origin, self.origin + _dir * -64, _dir * -_len , _dir * -_len, 1, PARTICLES_USEALPHA);
        boxparticles(self.lip, self, self.move_origin, self.move_origin + _dir * -64, _dir * -200 , _dir * -200, 1, PARTICLES_USEALPHA);
        self.total_damages = time + 0.1;
    }

    float i, df, sz, al;
    for(i = -0.1; i < 0.2; i += 0.1)
    {
        df = DRAWFLAG_NORMAL; //((random() < 0.5) ? DRAWFLAG_ADDITIVE : DRAWFLAG_SCREEN);
        sz = 5 + random() * 5;
        al = 0.25 + random() * 0.5;
        _vtmp1 = self.origin + _dir * _len * (0.25 + i);
        _vtmp1 += (randomvec() * (_len * 0.2) * (frametime * 2));       //self.raygun_l1;
        Draw_CylindricLine(self.origin, _vtmp1, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

        _vtmp2 = self.origin + _dir * _len * (0.5 + i);
        _vtmp2 += (randomvec() * (_len * 0.2) * (frametime * 5));       //self.raygun_l2;
        Draw_CylindricLine(_vtmp1, _vtmp2, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

        _vtmp1 = self.origin + _dir * _len * (0.75 + i);
        _vtmp1 += randomvec() * (_len * 0.2) * (frametime * 10);     //self.raygun_l3;
        Draw_CylindricLine(_vtmp2, _vtmp1, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

        Draw_CylindricLine(_vtmp1, self.move_origin +  randomvec() * 32, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);
    }
}

#endif

#endif
