#include "onslaught.qh"

#ifdef GAMEQC
REGISTER_NET_LINKED(ENT_ONSCAMERA)
#endif

#ifdef CSQC

entity generator_camera;
NET_HANDLE(ENT_ONSCAMERA, bool isnew)
{
	this.origin = ReadVector();
	setorigin(this, this.origin);

	this.angles_x = ReadAngle();
	this.angles_y = ReadAngle();
	this.angles_z = ReadAngle();

	this.drawmask  = MASK_NORMAL;
	setmodel(this, MDL_Null); // give it a size for clientcamera
	setsize(this, '-1 -1 -1', '1 1 1');

	generator_camera = this;
	return true;
}

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
		IL_EACH(g_onsgenerators, GetResource(it, RES_HEALTH) <= 0,
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
		M_ARGV(0, vector) = generator_camera.origin;
		M_ARGV(1, vector) = autocvar_cl_eventchase_generator_viewoffset;
		M_ARGV(0, float) = autocvar_cl_eventchase_generator_distance;
		return true;
	}
	return false;
}

#endif
