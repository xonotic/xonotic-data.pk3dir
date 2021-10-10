#include "slider_particles.qh"

entity makeXonoticParticlesSlider()
{
	entity me;
	me = NEW(XonoticParticlesSlider);
	me.configureXonoticParticlesSlider(me);
	return me;
}
void XonoticParticlesSlider_configureXonoticParticlesSlider(entity me)
{
	me.configureXonoticTextSlider(me, "cl_particles_quality",
		_("Multiplier for amount of particles. Less means less particles, which in turn gives for better performance"));
	if(cvar("developer") > 0) { me.addValue(me, ZCTX(_("PART^OMG")),      "0.25 250 0"); }
	me.addValue(me,                         ZCTX(_("PARTQUAL^Low")),      "0.5 500 0");
	me.addValue(me,                         ZCTX(_("PARTQUAL^Medium")),   "0.75 750 0");
	me.addValue(me,                         ZCTX(_("PARTQUAL^Normal")),   "1.0 1000 1");
	me.addValue(me,                         ZCTX(_("PARTQUAL^High")),     "1.5 1500 1");
	me.addValue(me,                         ZCTX(_("PARTQUAL^Ultra")),    "2.0 2000 2");
	if(cvar("developer") > 0) { me.addValue(me, ZCTX(_("PARTQUAL^Ultimate")), "3.0 3000 2"); }
	me.configureXonoticTextSliderValues(me);
}
void XonoticParticlesSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier_noAnim(me, sprintf("%s %s %s",
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
