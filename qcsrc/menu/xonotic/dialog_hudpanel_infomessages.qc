#include "dialog_hudpanel_infomessages.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"

void XonoticHUDInfoMessagesDialog_fill(entity me)
{
	entity e;
	string panelname = "infomessages";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Info messages:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 10, 1, "hud_panel_infomessages_group_time"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Fade time:")));
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_infomessages_group_fadetime"));
			e.addValue(e, ZCTX(_("FADESPEED^Instant")), "0");
			int dps = 2;
			for(i = 1; i <= 19; ++i)
			{
				e.addValue(e, strzone(ftos_decimals(i / 20, 2)), strzone(ftos_decimals(i / 20, dps)));
				dps = 3 - dps; // alternate between 2 and 1
			}
			e.addValue(e, "1.00", "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_infomessages_flip", _("Flip align")));
}
