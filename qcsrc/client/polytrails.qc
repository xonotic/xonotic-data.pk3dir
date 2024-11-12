#include "polytrails.qh"

#include <lib/warpzone/common.qh>

#define POLYTRAIL_SEEK(_p, _rel) ((POLYTRAIL_BUFSIZE + (_p).polytrail_bufidx + (_rel)) % POLYTRAIL_BUFSIZE)
void Trail_draw(entity this)
{
	if (wasfreed(this.polytrail_follow))
		this.polytrail_follow = NULL;

	// NOTE: need an internal reset distance for warpzones to work properly TODO?
	float reset_distance = 200;

	if (!this.polytrail_follow) {
		float when = this.polytrail_buftime[this.polytrail_bufidx];
		if (time - when > this.polytrail_lifetime) {
			delete(this);
			return;
		}
	} else if(reset_distance > 0 && this.polytrail_cnt > 0 && vdist(this.origin - this.polytrail_follow.origin, >, reset_distance)) {
		Trail_recreate(this);
	} else {
		setorigin(this, this.polytrail_follow.origin);
		if (this.polytrail_cnt < 0 || vdist(this.origin - this.polytrail_bufpos[this.polytrail_bufidx], >=, this.polytrail_segmentsize)) {
			int i = POLYTRAIL_SEEK(this, 1);
			this.polytrail_bufpos[i] = this.origin;
			float f = this.polytrail_noise;
			// TODO: alternate noise functions (none, chaotic, helix, zigzag, waves, ...)
			switch(this.polytrail_noisefunc)
			{
				default:
				case "none": this.polytrail_bufnoise[i] = '0 0 0'; break;
				case "chaotic": this.polytrail_bufnoise[i] = randompos(f * '-1 -1 -1', f * '1 1 1'); break;
			}
			this.polytrail_buftime[i] = time;
			this.polytrail_bufidx = i;
			this.polytrail_cnt = bound(this.polytrail_cnt, i + 1, POLYTRAIL_BUFSIZE);
		}
	}

	vector from = this.origin;
	int count = this.polytrail_cnt;
	for (int i = 0; i < count; ++i) {
		int idx = POLYTRAIL_SEEK(this, -i);
		float when = this.polytrail_buftime[idx];
		// head: 0, tail: 1
		float rtime = (time - when) / this.polytrail_lifetime;
		if (rtime >= 1) {
			break;
		}
		vector to = this.polytrail_bufpos[idx];
		to += lerpvratio('0 0 0', this.polytrail_bufnoise[idx], rtime);
		vector rgb = lerpv3ratio(this.polytrail_rgb[0], this.polytrail_rgb[1], this.polytrail_rgb[2], rtime);
		float a = lerp3ratio(this.polytrail_alpha[0], this.polytrail_alpha[1], this.polytrail_alpha[2], rtime);
		int thickness = lerp3ratio(this.polytrail_thickness[0], this.polytrail_thickness[1], this.polytrail_thickness[2], rtime);
		vector thickdir = normalize(cross(normalize(to - from), view_origin - from)) * (thickness / 2);
		vector A = from + thickdir;
		vector B = from - thickdir;
		vector C = to + thickdir;
		vector D = to - thickdir;
		R_BeginPolygon(this.polytrail_tex, DRAWFLAG_SCREEN, false);
		R_PolygonVertex(B, '0 0 0', rgb, a);
		R_PolygonVertex(A, '0 1 0', rgb, a);
		R_PolygonVertex(C, '1 1 0', rgb, a);
		R_PolygonVertex(D, '1 0 0', rgb, a);
		R_EndPolygon();
		from = to;
	}
}
#undef POLYTRAIL_SEEK

void Trail_recreate(entity this)
{
	PolyTrail t = NEW(PolyTrail, this.polytrail_follow);
	t.polytrail_tex = this.polytrail_tex;
	t.polytrail_rgb[0] = this.polytrail_rgb[0];
	t.polytrail_rgb[1] = this.polytrail_rgb[1];
	t.polytrail_rgb[2] = this.polytrail_rgb[2];
	t.polytrail_alpha[0] = this.polytrail_alpha[0];
	t.polytrail_alpha[1] = this.polytrail_alpha[1];
	t.polytrail_alpha[2] = this.polytrail_alpha[2];
	t.polytrail_thickness[0] = this.polytrail_thickness[0];
	t.polytrail_thickness[1] = this.polytrail_thickness[1];
	t.polytrail_thickness[2] = this.polytrail_thickness[2];
	t.polytrail_lifetime = this.polytrail_lifetime;
	t.polytrail_segmentsize = this.polytrail_segmentsize;
	t.polytrail_noise = this.polytrail_noise;
	t.polytrail_noisefunc = this.polytrail_noisefunc;

	this.polytrail_follow = NULL;
}
