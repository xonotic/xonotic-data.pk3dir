#include "physics.qh"

bool autocvar_xon_com_phys_interpolate = true;

void com_phys_interpolate(entity it, float a)
{
	if (!autocvar_xon_com_phys_interpolate) a = 1;
	it.origin = it.com_phys_pos_prev * (1 - a) + it.com_phys_pos * a;
	it.angles = it.com_phys_ang_prev * (1 - a) + it.com_phys_ang * a;  // TODO: slerp, not lerp
}
