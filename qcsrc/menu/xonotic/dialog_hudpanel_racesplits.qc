#include "dialog_hudpanel_racesplits.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticHUDRaceSplitsDialog_fill(entity me)
{
	entity e;
	string panelname = "racesplits";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Race Splits:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8/4, e = makeXonoticTextLabel(0, _("Align:")));
		me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_racesplits_align", "0", _("Left")));
		me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_racesplits_align", "0.5", _("Center")));
		me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_racesplits_align", "1", _("Right")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_racesplits_flip", _("Flip splits order")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Splits to keep on screen:")));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 50, 1, "hud_panel_racesplits_lines"));
}
