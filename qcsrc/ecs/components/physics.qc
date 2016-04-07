#include "physics.qh"

bool autocvar_xon_com_phys_interpolate = true;

void com_phys_interpolate(entity it, float a)
{
	if (!autocvar_xon_com_phys_interpolate) a = 1;
	it.origin = it.com_phys_pos * a + it.com_phys_pos_prev * (1 - a);
	// TODO: orientation (slerp it)
}
