#include "onslaught.qh"

#include <common/mutators/base.qh>

#ifdef GAMEQC
REGISTER_NET_LINKED(ENT_ONSCAMERA)
#endif

#ifdef CSQC

entity generator_camera;
NET_HANDLE(ENT_ONSCAMERA, bool isnew)
{
	this.origin = ReadVector();
	setorigin(this, this.origin);

	this.angles = ReadAngleVector();

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

#endif // CSQC
#ifdef MENUQC
#include <common/gamemodes/gamemode/assault/assault.qh>

METHOD(Onslaught, describe, string(Onslaught this))
{
	TC(Onslaught, this);
	return sprintf(_("%s is a team-based gamemode similar to %s where the final goal is to destroy the enemy team core generator. "
		"In order to destroy the generator, control points on the map (similar to those in %s) must first be captured.\n\n"
		"Since your team can only capture a control point if it is connected to another control point currently owned by your team, you have to systematically work through the map to reach the enemy generator.\n\n"
		"A control point is captured by walking into it then waiting for it to finish constructing. "
		"Control points of the opposing team are destroyed by attacking the \"info bot\" that hovers above them, converting the control point to neutral once it is destroyed.\n\n"
		"When in overtime, the enemy's generator will start to decay, at a faster rate the more control points your team has."),
	COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_ASSAULT));
}

#endif // MENUQC
