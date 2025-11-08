#include "slider_sbfadetime.qh"

entity makeXonoticScoreboardFadeTimeSlider()
{
	entity me;
	me = NEW(XonoticScoreboardFadeTimeSlider);
	me.configureXonoticScoreboardFadeTimeSlider(me);
	return me;
}
void XonoticScoreboardFadeTimeSlider_configureXonoticScoreboardFadeTimeSlider(entity me)
{
	me.configureXonoticTextSlider(me, "hud_panel_scoreboard_fadeinspeed", string_null);
	me.addValue(me, ZCTX(_("FADESPEED^Slow")),     "5 2.5");
	me.addValue(me, ZCTX(_("FADESPEED^Normal")),   "10 5");
	me.addValue(me, ZCTX(_("FADESPEED^Fast")),     "15 7.5");
	me.addValue(me, ZCTX(_("FADESPEED^Instant")),  "0 0");
	me.configureXonoticTextSliderValues(me);
}
void XonoticScoreboardFadeTimeSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier(me, sprintf("%s %s",
		cvar_string("hud_panel_scoreboard_fadeinspeed"),
		cvar_string("hud_panel_scoreboard_fadeoutspeed")
	), false);
}
void XonoticScoreboardFadeTimeSlider_saveCvars(entity me)
{
	if(me.value >= 0 || me.value < me.nValues)
	{
		tokenize_console(me.getIdentifier(me));
		cvar_set("hud_panel_scoreboard_fadeinspeed", argv(0));
		cvar_set("hud_panel_scoreboard_fadeoutspeed", argv(1));
	}
}
