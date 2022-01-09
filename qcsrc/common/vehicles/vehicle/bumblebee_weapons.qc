#include "bumblebee_weapons.qh"

#ifdef GAMEQC
REGISTER_NET_LINKED(ENT_CLIENT_BUMBLE_RAYGUN)
#endif

#ifdef SVQC

void bumblebee_fire_cannon(entity this, entity _gun, string _tagname, entity _owner)
{
    vector v = gettaginfo(_gun, gettagindex(_gun, _tagname));
    vehicles_projectile(this, EFFECT_BIGPLASMA_MUZZLEFLASH, SND_VEH_BUMBLEBEE_FIRE,
                        v, normalize(v_forward + randomvec() * autocvar_g_vehicle_bumblebee_cannon_spread) * autocvar_g_vehicle_bumblebee_cannon_speed,
                        autocvar_g_vehicle_bumblebee_cannon_damage, autocvar_g_vehicle_bumblebee_cannon_radius, autocvar_g_vehicle_bumblebee_cannon_force,  0,
                        DEATH_VH_BUMB_GUN.m_id, PROJECTILE_BUMBLE_GUN, 0, true, true, _owner);
}

bool bumble_raygun_send(entity this, entity to, float sf)
{
    WriteHeader(MSG_ENTITY, ENT_CLIENT_BUMBLE_RAYGUN);

    WriteByte(MSG_ENTITY, sf);
    if(sf & BRG_SETUP)
    {
        WriteByte(MSG_ENTITY, etof(this.realowner));
        WriteByte(MSG_ENTITY, this.realowner.team);
        WriteByte(MSG_ENTITY, this.cnt);
    }

    if(sf & BRG_START)
    {
        WriteVector(MSG_ENTITY, this.hook_start);
    }

    if(sf & BRG_END)
    {
        WriteVector(MSG_ENTITY, this.hook_end);
    }

    return true;
}

#endif

#ifdef CSQC

void bumble_raygun_draw(entity this);

.vector bumble_origin;

NET_HANDLE(ENT_CLIENT_BUMBLE_RAYGUN, bool isnew)
{
    int sf = ReadByte();

    if(sf & BRG_SETUP)
    {
        this.cnt  = ReadByte();
        this.team = ReadByte();
        this.count  = ReadByte();

        if(this.count)
            this.colormod = '1 0 0';
        else
            this.colormod = '0 1 0';

        this.traileffect = EFFECT_BUMBLEBEE_HEAL_MUZZLEFLASH.m_id;
        this.lip = particleeffectnum(EFFECT_BUMBLEBEE_HEAL_IMPACT);

        this.draw = bumble_raygun_draw;
        if (isnew) IL_PUSH(g_drawables, this);
    }


    if(sf & BRG_START)
    {
        this.origin = ReadVector();
        setorigin(this, this.origin);
    }

    if(sf & BRG_END)
    {
        this.bumble_origin = ReadVector();
    }
    return true;
}

.float bumble_raygun_nextdraw;
void bumble_raygun_draw(entity this)
{
    float _len;
    vector _dir;
    vector _vtmp1, _vtmp2;

    _len = vlen(this.origin - this.bumble_origin);
    _dir = normalize(this.bumble_origin - this.origin);

    if(this.bumble_raygun_nextdraw < time)
    {
        entity eff = REGISTRY_GET(Effects, this.traileffect);
        boxparticles(particleeffectnum(eff), this, this.origin, this.origin + _dir * -64, _dir * -_len , _dir * -_len, 1, PARTICLES_USEALPHA);
        boxparticles(this.lip, this, this.bumble_origin, this.bumble_origin + _dir * -64, _dir * -200 , _dir * -200, 1, PARTICLES_USEALPHA);
        this.bumble_raygun_nextdraw = time + 0.1;
    }

    float i, df, sz, al;
    for(i = -0.1; i < 0.2; i += 0.1)
    {
        df = DRAWFLAG_NORMAL; //((random() < 0.5) ? DRAWFLAG_ADDITIVE : DRAWFLAG_SCREEN);
        sz = 5 + random() * 5;
        al = 0.25 + random() * 0.5;
        _vtmp1 = this.origin + _dir * _len * (0.25 + i);
        _vtmp1 += (randomvec() * (_len * 0.2) * (frametime * 2));       //this.raygun_l1;
        Draw_CylindricLine(this.origin, _vtmp1, sz, "gfx/colors/white", 1, 1, this.colormod, al, df, view_origin);

        _vtmp2 = this.origin + _dir * _len * (0.5 + i);
        _vtmp2 += (randomvec() * (_len * 0.2) * (frametime * 5));       //this.raygun_l2;
        Draw_CylindricLine(_vtmp1, _vtmp2, sz, "gfx/colors/white", 1, 1, this.colormod, al, df, view_origin);

        _vtmp1 = this.origin + _dir * _len * (0.75 + i);
        _vtmp1 += randomvec() * (_len * 0.2) * (frametime * 10);     //this.raygun_l3;
        Draw_CylindricLine(_vtmp2, _vtmp1, sz, "gfx/colors/white", 1, 1, this.colormod, al, df, view_origin);

        Draw_CylindricLine(_vtmp1, this.bumble_origin +  randomvec() * 32, sz, "gfx/colors/white", 1, 1, this.colormod, al, df, view_origin);
    }
}

#endif
