#include "physics.qh"

bool autocvar_xon_com_phys_interpolate = true;

void com_phys_interpolate(entity it, float a)
{
	if (!autocvar_xon_com_phys_interpolate) a = 1;
	// TODO: network time
	// a = bound(0, (time - this.com_phys_time) / a, 1 /* + autocvar_cl_lerpexcess /* extrapolation frame limit */ */);
	it.origin = it.com_phys_pos * a + it.com_phys_pos_prev * (1 - a);
	it.angles = it.com_phys_ang * a + it.com_phys_ang_prev * (1 - a);  // TODO: slerp, not lerp
}
