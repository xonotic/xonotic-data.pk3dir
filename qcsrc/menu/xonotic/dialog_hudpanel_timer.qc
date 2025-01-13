#include "dialog_hudpanel_timer.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "radiobutton.qh"

void XonoticHUDTimerDialog_fill(entity me)
{
	entity e;
	string panelname = "timer";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_timer_increment", _("Show elapsed time")));

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Secondary timer:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_timer_secondary", "0", _("Disable")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_timer_secondary", "1", _("Enable")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_timer_secondary", "2", _("Swapped")));
}
