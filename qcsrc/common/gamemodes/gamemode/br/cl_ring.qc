#include "cl_ring.qh"

// TODO: support dark colors

entity br_ring;
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
        IL_REMOVE(g_drawables, this);
        return;
    }

    this.scale = current_radius / RING_MODEL_RADIUS;
    float dist_to_ring = max(current_radius - vlen((csqcplayer.origin + csqcplayer.view_ofs) - this.origin), 0);
    this.alpha = max((1 - min(dist_to_ring / max(current_radius * this.br_ring_fadedistance, this.br_ring_fadedistance_min), 1)) * this.br_ring_alpha, 0.01);
}

void ring_draw2d(entity this)
{
    float current_radius = ring_calculate_current_radius(this);

    // if outside of the ring, color the player's view in the ring color
    if(vlen((csqcplayer.origin + csqcplayer.view_ofs) - this.origin) > current_radius)
    {
        const float weaken_factor = 0.75;
        R_BeginPolygon("", DRAWFLAG_NORMAL, true);
        R_PolygonVertex('0 0 0', '0 0 0', this.colormod, max(this.br_ring_alpha * weaken_factor, 0.01));
        R_PolygonVertex(autocvar_vid_conwidth * '1 0 0', '1 0 0', this.colormod, max(this.br_ring_alpha * weaken_factor, 0.01));
        R_PolygonVertex(autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', '1 1 0', this.colormod, max(this.br_ring_alpha * weaken_factor, 0.01));
        R_PolygonVertex(autocvar_vid_conheight * '0 1 0', '0 1 0', this.colormod, max(this.br_ring_alpha * weaken_factor, 0.01));
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
        if(br_ring)
            LOG_FATAL("server sent ring entity twice");

        br_ring = this;
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

        this.br_ring_fadedistance = max(ReadCoord(), 0);
        this.br_ring_fadedistance_min = max(ReadCoord(), 1);

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

void draw_circle_fill_inverted(vector clip_pos, vector clip_size, vector center, float r, vector c, float a);
void draw_teamradar_ring(vector clip_pos, vector clip_size, float fg)
{
    if(fg <= 0)
        return;

    if(!br_ring)
        return;

    float a = max(fg / 3, 0.01);
    float radius = ring_calculate_current_radius(br_ring);
    float radius_at_height = 0;
    float height_offset = view_origin.z - br_ring.origin.z;

    if(fabs(height_offset) < radius)
        radius_at_height = sqrt(radius ** 2 - height_offset ** 2);

    draw_circle_fill_inverted(clip_pos, clip_size, br_ring.origin, radius, br_ring.colormod, a);
    draw_circle_fill_inverted(clip_pos, clip_size, br_ring.origin, radius_at_height, br_ring.colormod, a);
}

void draw_circle_fill_inverted(vector clip_pos, vector clip_size, vector center, float r, vector c, float a)
{
    float diameter = r * 2;

    // all four clipping corners in texture coordinates
    vector _clip_pos0 = teamradar_2dcoord_to_texcoord(clip_pos + eY * clip_size.y);
    vector _clip_pos1 = teamradar_2dcoord_to_texcoord(clip_pos + clip_size);
    vector _clip_pos2 = teamradar_2dcoord_to_texcoord(clip_pos + eX * clip_size.x);
    vector _clip_pos3 = teamradar_2dcoord_to_texcoord(clip_pos);

    // find the minimum and maximum extents in texture coordinates
    vector _clip_mins, _clip_maxs;
    _clip_mins.x = _clip_mins.y = min(_clip_pos0.x, _clip_pos0.y, _clip_pos1.x, _clip_pos1.y, _clip_pos2.x, _clip_pos2.y, _clip_pos3.x, _clip_pos3.y);
    _clip_maxs.x = _clip_maxs.y = max(_clip_pos0.x, _clip_pos0.y, _clip_pos1.x, _clip_pos1.y, _clip_pos2.x, _clip_pos2.y, _clip_pos3.x, _clip_pos3.y);
    _clip_mins.z = _clip_maxs.z = 0;

    // each of the corners of the clipping rectangle in texture coordinates
    vector _clip_rect_coord0 = eX * _clip_mins.x + eY * _clip_maxs.y;
    vector _clip_rect_coord1 = _clip_maxs;
    vector _clip_rect_coord2 = eX * _clip_maxs.x + eY * _clip_mins.y;
    vector _clip_rect_coord3 = _clip_mins;

    if(diameter > 0)
    {
        // convert diameter to texture coordinates
        vector _circle_size;
        _circle_size.x = diameter / (mi_picmax.x - mi_picmin.x);
        _circle_size.y = diameter / (mi_picmax.y - mi_picmin.y);
        _circle_size.z = 0;

        // convert center to origin in texture coordinates
        vector _circle_origin = teamradar_3dcoord_to_texcoord(center) - _circle_size / 2;

        // each of the corners of the circle square in texture coordinates
        vector _circle_coord0 = _circle_origin + eY * _circle_size.y;
        vector _circle_coord1 = _circle_origin + _circle_size;
        vector _circle_coord2 = _circle_origin + eX * _circle_size.x;
        vector _circle_coord3 = _circle_origin;

        // clip the circle square
        _circle_coord0.x = bound(_clip_mins.x, _circle_coord0.x, _clip_maxs.x);
        _circle_coord0.y = bound(_clip_mins.y, _circle_coord0.y, _clip_maxs.y);
        _circle_coord1.x = bound(_clip_mins.x, _circle_coord1.x, _clip_maxs.x);
        _circle_coord1.y = bound(_clip_mins.y, _circle_coord1.y, _clip_maxs.y);
        _circle_coord2.x = bound(_clip_mins.x, _circle_coord2.x, _clip_maxs.x);
        _circle_coord2.y = bound(_clip_mins.y, _circle_coord2.y, _clip_maxs.y);
        _circle_coord3.x = bound(_clip_mins.x, _circle_coord3.x, _clip_maxs.x);
        _circle_coord3.y = bound(_clip_mins.y, _circle_coord3.y, _clip_maxs.y);

        // top fill rectangle corners in 2D screen coordinates
        vector rect0_coord0 = teamradar_texcoord_to_2dcoord(_clip_rect_coord0);
        vector rect0_coord1 = teamradar_texcoord_to_2dcoord(_clip_rect_coord1);
        vector rect0_coord2 = teamradar_texcoord_to_2dcoord(eX * _clip_rect_coord1.x + eY * _circle_coord1.y);
        vector rect0_coord3 = teamradar_texcoord_to_2dcoord(eX * _clip_rect_coord0.x + eY * _circle_coord0.y);

        // bottom fill rectangle corners in 2D screen coordinates
        vector rect2_coord0 = teamradar_texcoord_to_2dcoord(_clip_rect_coord2);
        vector rect2_coord1 = teamradar_texcoord_to_2dcoord(_clip_rect_coord3);
        vector rect2_coord2 = teamradar_texcoord_to_2dcoord(eX * _clip_rect_coord3.x + eY * _circle_coord3.y);
        vector rect2_coord3 = teamradar_texcoord_to_2dcoord(eX * _clip_rect_coord2.x + eY * _circle_coord2.y);

        // right fill rectangle corners in 2D screen coordinates
        vector rect1_coord0 = rect0_coord2;
        vector rect1_coord1 = rect2_coord3;
        vector rect1_coord2 = teamradar_texcoord_to_2dcoord(_circle_coord2);
        vector rect1_coord3 = teamradar_texcoord_to_2dcoord(_circle_coord1);

        // left fill rectangle corners in 2D screen coordinates
        vector rect3_coord0 = rect2_coord2;
        vector rect3_coord1 = rect0_coord3;
        vector rect3_coord2 = teamradar_texcoord_to_2dcoord(_circle_coord0);
        vector rect3_coord3 = teamradar_texcoord_to_2dcoord(_circle_coord3);

        // draw top fill rectangle
        if((_circle_origin.y + _circle_size.y) < _clip_maxs.y)
        {
            R_BeginPolygon("", DRAWFLAG_NORMAL, true);
            R_PolygonVertex(rect0_coord0, '0 0 0', c, a);
            R_PolygonVertex(rect0_coord1, '1 0 0', c, a);
            R_PolygonVertex(rect0_coord2, '1 1 0', c, a);
            R_PolygonVertex(rect0_coord3, '0 1 0', c, a);
            R_EndPolygon();
        }

        // draw right fill rectangle
        if((_circle_origin.x + _circle_size.x) < _clip_maxs.x)
        {
            R_BeginPolygon("", DRAWFLAG_NORMAL, true);
            R_PolygonVertex(rect1_coord0, '0 0 0', c, a);
            R_PolygonVertex(rect1_coord1, '1 0 0', c, a);
            R_PolygonVertex(rect1_coord2, '1 1 0', c, a);
            R_PolygonVertex(rect1_coord3, '0 1 0', c, a);
            R_EndPolygon();
        }

        // draw bottom fill rectangle
        if(_circle_origin.y > _clip_mins.y)
        {
            R_BeginPolygon("", DRAWFLAG_NORMAL, true);
            R_PolygonVertex(rect2_coord0, '0 0 0', c, a);
            R_PolygonVertex(rect2_coord1, '1 0 0', c, a);
            R_PolygonVertex(rect2_coord2, '1 1 0', c, a);
            R_PolygonVertex(rect2_coord3, '0 1 0', c, a);
            R_EndPolygon();
        }

        // draw left fill rectangle
        if(_circle_origin.x > _clip_mins.x)
        {
            R_BeginPolygon("", DRAWFLAG_NORMAL, true);
            R_PolygonVertex(rect3_coord0, '0 0 0', c, a);
            R_PolygonVertex(rect3_coord1, '1 0 0', c, a);
            R_PolygonVertex(rect3_coord2, '1 1 0', c, a);
            R_PolygonVertex(rect3_coord3, '0 1 0', c, a);
            R_EndPolygon();
        }

        // draw circle square
        if((_circle_origin.x < _clip_maxs.x) && (_circle_origin.y < _clip_maxs.y) && ((_circle_origin.x + _circle_size.x) > _clip_mins.x) && ((_circle_origin.y + _circle_size.y) > _clip_mins.y))
        {
            // circle square corners in 2D screen coordinates
            vector circle_coord0 = teamradar_texcoord_to_2dcoord(_circle_coord0);
            vector circle_coord1 = teamradar_texcoord_to_2dcoord(_circle_coord1);
            vector circle_coord2 = teamradar_texcoord_to_2dcoord(_circle_coord2);
            vector circle_coord3 = teamradar_texcoord_to_2dcoord(_circle_coord3);

            // calculate texture coordinates in case of clipping
            vector circle_tex0, circle_tex1, circle_tex2, circle_tex3;
            circle_tex0.x = circle_tex3.x = max(0, (_clip_mins.x - _circle_origin.x) / _circle_size.x);
            circle_tex1.x = circle_tex2.x = min(1 - ((_circle_origin.x + _circle_size.x) - _clip_maxs.x) / _circle_size.x, 1);
            circle_tex2.y = circle_tex3.y = 1 - max(0, (_clip_mins.y - _circle_origin.y) / _circle_size.y);
            circle_tex0.y = circle_tex1.y = 1 - min(1 - ((_circle_origin.y + _circle_size.y) - _clip_maxs.y) / _circle_size.y, 1);
            circle_tex0.z = circle_tex1.z = circle_tex2.z = circle_tex3.z = 0;

            R_BeginPolygon("gfx/inverted_circle", DRAWFLAG_NORMAL, true);
            R_PolygonVertex(circle_coord0, circle_tex0, c, a);
            R_PolygonVertex(circle_coord1, circle_tex1, c, a);
            R_PolygonVertex(circle_coord2, circle_tex2, c, a);
            R_PolygonVertex(circle_coord3, circle_tex3, c, a);
            R_EndPolygon();
        }
    }
    else
    {
        // circle with zero length diameter, draw a single fill rectangle
        vector fill_coord0 = teamradar_texcoord_to_2dcoord(_clip_rect_coord0);
        vector fill_coord1 = teamradar_texcoord_to_2dcoord(_clip_rect_coord1);
        vector fill_coord2 = teamradar_texcoord_to_2dcoord(_clip_rect_coord2);
        vector fill_coord3 = teamradar_texcoord_to_2dcoord(_clip_rect_coord3);

        R_BeginPolygon("", DRAWFLAG_NORMAL, true);
        R_PolygonVertex(fill_coord0, '0 0 0', c, a);
        R_PolygonVertex(fill_coord1, '1 0 0', c, a);
        R_PolygonVertex(fill_coord2, '1 1 0', c, a);
        R_PolygonVertex(fill_coord3, '0 1 0', c, a);
        R_EndPolygon();
    }
}
