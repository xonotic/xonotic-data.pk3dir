#include "cl_ring.qh"

// TODO: support dark colors

bool ring_is_closing(entity this);

#define RING_MODEL_PATH "models/sphere/sphere.md3"
#define RING_MODEL_RADIUS 64 // radius of model at 1.0 scale
void ring_draw(entity this)
{
    float current_radius = ring_calculate_current_radius(this);

    if(ring_is_closing(this)) // only move when we actually should, increases visual fidelity in case the server lags and sends the wait signal late
    {
        setorigin(this, this.origin + this.velocity * (time - this.move_time)); // 3D is drawn before 2D, the origin will also be used in ring_draw2d afterwards
        this.move_time = time;
    }

    if(current_radius <= 0)
    {
        setmodel(this, MDL_Null);
        this.scale = this.alpha = 0;
        this.velocity = '0 0 0';
        this.draw = func_null;
        return;
    }

    this.scale = current_radius / RING_MODEL_RADIUS;
    this.alpha = max((1 - min(max(current_radius - vlen((csqcplayer.origin + csqcplayer.view_ofs) - this.origin), 0) / this.br_ring_fadedistance, 1)) * this.br_ring_alpha, 0.01);
    if(vlen((csqcplayer.origin + csqcplayer.view_ofs) - this.origin) > current_radius)
        this.alpha = max(this.alpha / 4, 0.01); // let's weaken the ring visuals a bit, everything is already ring colored
}

void ring_draw2d(entity this)
{
    float current_radius = ring_calculate_current_radius(this);

    if(vlen((csqcplayer.origin + csqcplayer.view_ofs) - this.origin) > current_radius)
    {
        R_BeginPolygon("", DRAWFLAG_ADDITIVE, true);
        R_PolygonVertex('0 0 0', '0 0 0', this.colormod, min(this.br_ring_alpha, 0.5));
        R_PolygonVertex(autocvar_vid_conwidth * '1 0 0', '1 0 0', this.colormod, min(this.br_ring_alpha, 0.5));
        R_PolygonVertex(autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', '1 1 0', this.colormod, min(this.br_ring_alpha, 0.5));
        R_PolygonVertex(autocvar_vid_conheight * '0 1 0', '0 1 0', this.colormod, min(this.br_ring_alpha, 0.5));
        R_EndPolygon();
    }
}

void ring_construct(entity this, bool isnew)
{
    this.netname = BR_RING_NAME;

    setorigin(this, this.origin);
    setsize(this, '0 0 0', '0 0 0');
    set_movetype(this, MOVETYPE_NOCLIP);
    _setmodel(this, RING_MODEL_PATH);

    this.classname   = "ring";
    this.solid       = SOLID_NOT;
    this.draw        = ring_draw;
    this.drawmask    = MASK_NORMAL;
    this.draw2d      = ring_draw2d;

    if(isnew)
    {
        IL_PUSH(g_drawables, this);
        IL_PUSH(g_drawables_2d, this);
    }
}

NET_HANDLE(ENT_CLIENT_RING, bool isnew)
{
    float sf;
    sf = ReadByte();

    if(sf & BR_RING_SETUP)
    {
        this.origin = ReadVector();
        setorigin(this, this.origin);

        this.br_ring_start = ReadCoord();
        this.br_ring_duration = max(ReadCoord(), 1);

        this.radius = max(ReadCoord(), 0);

        this.colormod = normalize(ReadVector());

        this.br_ring_alpha = bound(0.01, ReadCoord(), 1);

        this.br_ring_fadedistance = max(ReadCoord(), 1);

        this.br_ring_stage_count = max(ReadByte(), 1);
        this.br_ring_stage_waittime = max(ReadCoord(), 0);
        for(int i = 0; i < (this.br_ring_stage_count + 1); ++i)
            this.br_ring_stage_timing[i] = ReadCoord();

        ring_construct(this, isnew);
    }

    if(sf & BR_RING_MOVE)
    {
        this.origin = ReadVector();
        setorigin(this, this.origin);

        this.velocity = ReadVector();

        this.move_time = time;
    }

    return true;
}

bool ring_is_closing(entity this)
{
    float time_elapsed = time - this.br_ring_start;

    for(int stage = 0; stage < this.br_ring_stage_count; ++stage)
    {
        float stage_duration = this.br_ring_duration * this.br_ring_stage_timing[stage];
        stage_duration += this.br_ring_stage_waittime * stage;

        if(time_elapsed > stage_duration)
        {
            if(time_elapsed < (stage_duration + this.br_ring_stage_waittime))
            {
                return false;
            }
        }
        else
            return true;
    }

    return (time_elapsed < (this.br_ring_duration + this.br_ring_stage_waittime * this.br_ring_stage_count));
}
