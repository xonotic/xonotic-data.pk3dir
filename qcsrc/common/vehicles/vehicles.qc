#include "vehicles.qh"

#ifdef GAMEQC
float vehicle_altitude(entity this, float amax)
{
	tracebox(this.origin, this.mins, this.maxs, this.origin - ('0 0 1' * amax), MOVE_WORLDONLY, this);
	return vlen(this.origin - trace_endpos);
}

vector vehicles_force_fromtag_hover(entity this, string tag_name, float spring_length, float max_power)
{
	force_fromtag_origin = gettaginfo(this, gettagindex(this, tag_name));
	v_forward  = normalize(v_forward) * -1;
	traceline(force_fromtag_origin, force_fromtag_origin - (v_forward  * spring_length), MOVE_NORMAL, this);

	force_fromtag_power = (1 - trace_fraction) * max_power;
	force_fromtag_normpower = force_fromtag_power / max_power;

	return v_forward  * force_fromtag_power;
}

vector vehicles_force_fromtag_maglev(entity this, string tag_name, float spring_length, float max_power)
{
	force_fromtag_origin = gettaginfo(this, gettagindex(this, tag_name));
	v_forward  = normalize(v_forward) * -1;
	traceline(force_fromtag_origin, force_fromtag_origin - (v_forward  * spring_length), MOVE_NORMAL, this);

	// TODO - this may NOT be compatible with wall/celing movement, unhardcode 0.25 (engine count multiplier)
	if(trace_fraction == 1.0)
	{
		force_fromtag_normpower = -0.25;
		return '0 0 -200';
	}

	force_fromtag_power = ((1 - trace_fraction) - trace_fraction) * max_power;
	force_fromtag_normpower = force_fromtag_power / max_power;

	return v_forward  * force_fromtag_power;
}
#endif
