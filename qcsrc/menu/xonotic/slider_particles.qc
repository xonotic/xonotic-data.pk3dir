#ifndef SLIDER_PARTICLES_H
#define SLIDER_PARTICLES_H
#include "textslider.qc"
CLASS(XonoticParticlesSlider, XonoticTextSlider)
	METHOD(XonoticParticlesSlider, configureXonoticParticlesSlider, void(entity));
	METHOD(XonoticParticlesSlider, loadCvars, void(entity));
	METHOD(XonoticParticlesSlider, saveCvars, void(entity));
ENDCLASS(XonoticParticlesSlider)
entity makeXonoticParticlesSlider();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticParticlesSlider()
{
	entity me;
	me = NEW(XonoticParticlesSlider);
	me.configureXonoticParticlesSlider(me);
	return me;
}
void XonoticParticlesSlider_configureXonoticParticlesSlider(entity me)
{
	me.configureXonoticTextSlider(me, "cl_particles_quality");
	if(cvar("developer")) { me.addValue(me, ZCTX(_("PART^OMG")),      "0.4 250 0"); }
	me.addValue(me,                         ZCTX(_("PART^Low")),      "0.4 500 0");
	me.addValue(me,                         ZCTX(_("PART^Medium")),   "0.8 750 0");
	me.addValue(me,                         ZCTX(_("PART^Normal")),   "1.0 1000 1");
	me.addValue(me,                         ZCTX(_("PART^High")),     "1.0 1500 1");
	me.addValue(me,                         ZCTX(_("PART^Ultra")),    "1.0 2000 2");
	if(cvar("developer")) { me.addValue(me, ZCTX(_("PART^Ultimate")), "1.0 3000 2"); }
	me.configureXonoticTextSliderValues(me);
}
void XonoticParticlesSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier(me, sprintf("%s %s %s",
		cvar_string("cl_particles_quality"),
		cvar_string("r_drawparticles_drawdistance"),
		cvar_string("cl_damageeffect")
	));
}
void XonoticParticlesSlider_saveCvars(entity me)
{
	if(me.value >= 0 || me.value < me.nValues)
	{
		tokenize_console(me.getIdentifier(me));
		cvar_set("cl_particles_quality", argv(0));
		cvar_set("r_drawparticles_drawdistance", argv(1));
		cvar_set("cl_damageeffect", argv(2));
	}
}
#endif
