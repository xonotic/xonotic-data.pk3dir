#ifndef SLIDER_SBFADETIME_H
#define SLIDER_SBFADETIME_H
#include "textslider.qc"
CLASS(XonoticScoreboardFadeTimeSlider, XonoticTextSlider)
	METHOD(XonoticScoreboardFadeTimeSlider, configureXonoticScoreboardFadeTimeSlider, void(entity));
	METHOD(XonoticScoreboardFadeTimeSlider, loadCvars, void(entity));
	METHOD(XonoticScoreboardFadeTimeSlider, saveCvars, void(entity));
ENDCLASS(XonoticScoreboardFadeTimeSlider)
entity makeXonoticScoreboardFadeTimeSlider();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticScoreboardFadeTimeSlider()
{
	entity me;
	me = NEW(XonoticScoreboardFadeTimeSlider);
	me.configureXonoticScoreboardFadeTimeSlider(me);
	return me;
}
void XonoticScoreboardFadeTimeSlider_configureXonoticScoreboardFadeTimeSlider(entity me)
{
	me.configureXonoticTextSlider(me, "scoreboard_fadeinspeed", string_null);
	me.addValue(me, ZCTX(_("PART^Slow")),     "5 2.5");
	me.addValue(me, ZCTX(_("PART^Normal")),   "10 5");
	me.addValue(me, ZCTX(_("PART^Fast")),     "15 7.5");
	me.addValue(me, ZCTX(_("PART^Instant")),  "0 0");
	me.configureXonoticTextSliderValues(me);
}
void XonoticScoreboardFadeTimeSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier_noAnim(me, sprintf("%s %s",
		cvar_string("scoreboard_fadeinspeed"),
		cvar_string("scoreboard_fadeoutspeed")
	));
}
void XonoticScoreboardFadeTimeSlider_saveCvars(entity me)
{
	if(me.value >= 0 || me.value < me.nValues)
	{
		tokenize_console(me.getIdentifier(me));
		cvar_set("scoreboard_fadeinspeed", argv(0));
		cvar_set("scoreboard_fadeoutspeed", argv(1));
	}
}
#endif
