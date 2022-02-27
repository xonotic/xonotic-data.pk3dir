#include "dialog_hudpanel_timer.qh"

#include "textslider.qh"
#include "checkbox.qh"
#include "textlabel.qh"

void XonoticHUDTimerDialog_fill(entity me)
{
	entity e;
	string panelname = "timer";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Timer:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_timer_increment", _("Show elapsed time")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Secondary timer:")));
        me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_timer_secondary"));
            e.addValue(e, _("Disable"), "0");
            e.addValue(e, _("Enable"), "1");
            e.addValue(e, _("Swapped"), "2");
            e.configureXonoticTextSliderValues(e);
}
