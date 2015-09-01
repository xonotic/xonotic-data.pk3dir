bool autocvar_cl_polytrails = false;
float autocvar_cl_polytrail_segmentsize = 10;
float autocvar_cl_polytrail_lifetime = .2;
float autocvar_cl_polytrail_noise = 10;

CLASS(PolyTrail, Object)
    ATTRIB(PolyTrail, polytrail_follow, entity, NULL)
    ATTRIB(PolyTrail, polytrail_tex, string, string_null)
    /** Lifetime per segment */
    ATTRIB(PolyTrail, polytrail_lifetime, float, autocvar_cl_polytrail_lifetime)
    ATTRIBARRAY(PolyTrail, polytrail_rgb, vector, 3)
    ATTRIBARRAY(PolyTrail, polytrail_alpha, float, 3)
    ATTRIBARRAY(PolyTrail, polytrail_thickness, float, 3)

    /**
     * Increase as necessary if the buffer is overflowing
     * symptom: tail of trail is wrong
     * cause: projectiles are too fast for the segment size
     */
    const int POLYTRAIL_BUFSIZE = 1 << 7;
    /** One or more positional points */
    ATTRIBARRAY(PolyTrail, polytrail_bufpos, vector, POLYTRAIL_BUFSIZE)
    /** Noise for ending position */
    ATTRIBARRAY(PolyTrail, polytrail_bufnoise, vector, POLYTRAIL_BUFSIZE)
    /** Time of input */
    ATTRIBARRAY(PolyTrail, polytrail_buftime, float, POLYTRAIL_BUFSIZE)
    /** Current read index */
    ATTRIB(PolyTrail, polytrail_bufidx, float, -1)
    /** Counts positions stored */
    ATTRIB(PolyTrail, polytrail_cnt, float, 0)
    #define POLYTRAIL_SEEK(_p, _rel) ((POLYTRAIL_BUFSIZE + (_p).polytrail_bufidx + (_rel)) % POLYTRAIL_BUFSIZE)

    void Trail_draw();
    ATTRIB(PolyTrail, draw, void(), Trail_draw)
    void Trail_draw() {
        PolyTrail this = self;
        if (wasfreed(this.polytrail_follow)) this.polytrail_follow = NULL;
        if (!this.polytrail_follow) {
            float when = this.polytrail_buftime[this.polytrail_bufidx];
            if (time - when > this.polytrail_lifetime) {
                remove(this);
                return;
            }
        } else {
            setorigin(this, this.polytrail_follow.origin);
            if (this.polytrail_cnt < 0 || vlen(this.origin - this.polytrail_bufpos[this.polytrail_bufidx]) >= autocvar_cl_polytrail_segmentsize) {
                int i = POLYTRAIL_SEEK(this, 1);
                this.polytrail_bufpos[i] = this.origin;
                float f = autocvar_cl_polytrail_noise;
                this.polytrail_bufnoise[i] = randompos(f * '-1 -1 -1', f * '1 1 1');
                this.polytrail_buftime[i] = time;
                this.polytrail_bufidx = i;
                this.polytrail_cnt = bound(this.polytrail_cnt, i + 1, POLYTRAIL_BUFSIZE);
            }
        }

        int count = this.polytrail_cnt;
        for (int i = 0; i < count; ++i) {
            int idx = POLYTRAIL_SEEK(this, -i);
            float when = this.polytrail_buftime[idx];
            if (time - when >= this.polytrail_lifetime) {
                count = i + 1;
                break;
            }
        }

        vector from = this.origin;
        for (int i = 0, n = count; i < n; ++i) {
            int idx = POLYTRAIL_SEEK(this, -i);
            float when = this.polytrail_buftime[idx];
            vector to = this.polytrail_bufpos[idx];
            // head: 0, tail: 1
            float rtime = (time - when) / this.polytrail_lifetime;
            noref float rdist = i / n;
            to += lerpvratio('0 0 0', this.polytrail_bufnoise[idx], rtime);
            vector rgb = lerpv3ratio(this.polytrail_rgb[0], this.polytrail_rgb[1], this.polytrail_rgb[2], rtime);
            float a = lerp3ratio(this.polytrail_alpha[0], this.polytrail_thickness[1], this.polytrail_alpha[2], rtime);
            int thickness = lerp3ratio(this.polytrail_thickness[0], this.polytrail_thickness[1], this.polytrail_thickness[2], rtime);
            vector thickdir = normalize(cross(normalize(to - from), view_origin - from)) * (thickness / 2);
            vector A = from + thickdir;
            vector B = from - thickdir;
            vector C = to + thickdir;
            vector D = to - thickdir;
            R_BeginPolygon(this.polytrail_tex, DRAWFLAG_SCREEN);
            R_PolygonVertex(B, '0 0 0', rgb, a);
            R_PolygonVertex(A, '0 1 0', rgb, a);
            R_PolygonVertex(C, '1 1 0', rgb, a);
            R_PolygonVertex(D, '1 0 0', rgb, a);
            R_EndPolygon();
            from = to;
        }
    }
    CONSTRUCTOR(PolyTrail, entity _follow) {
        CONSTRUCT(PolyTrail);
        this.polytrail_follow = _follow;
    }
ENDCLASS(PolyTrail)

REGISTER_MUTATOR(polytrails, true);

MUTATOR_HOOKFUNCTION(polytrails, EditProjectile) {
    return = false;
    if (!autocvar_cl_polytrails) return;
    PolyTrail t = NEW(PolyTrail, self);
    t.polytrail_tex = "gfx/trails/plain.tga";
    t.polytrail_rgb[0] = '1 0 0';
    t.polytrail_rgb[1] = '0 1 0';
    t.polytrail_rgb[2] = '0 0 1';
    t.polytrail_alpha[0] = 1;
    t.polytrail_alpha[1] = 0.5;
    t.polytrail_alpha[2] = 0;
    t.polytrail_thickness[0] = 10;
    t.polytrail_thickness[1] = 5;
    t.polytrail_thickness[2] = 0;
}
