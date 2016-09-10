#include "onslaught.qh"

#ifdef CSQC

REGISTER_MUTATOR(cl_ons, true);

float ons_roundlost;
vector generator_origin;
vector autocvar_cl_eventchase_generator_viewoffset = '0 0 80';
float autocvar_cl_eventchase_generator_distance = 400;
MUTATOR_HOOKFUNCTION(cl_ons, WantEventchase)
{
	ons_roundlost = STAT(ROUNDLOST);
	entity gen = NULL;
	if(ons_roundlost)
	{
		IL_EACH(g_onsgenerators, it.health <= 0,
		{
			gen = it;
			break;
		});
		if(!gen)
			ons_roundlost = false; // don't enforce the 3rd person camera if there is no dead generator to show
	}

	if(ons_roundlost)
	{
		generator_origin = gen.origin;
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ons, CustomizeEventchase)
{
	if(ons_roundlost)
	{
		M_ARGV(0, vector) = generator_origin;
		M_ARGV(1, vector) = autocvar_cl_eventchase_generator_viewoffset;
		M_ARGV(0, float) = autocvar_cl_eventchase_generator_distance;
		return true;
	}
	return false;
}

#endif
