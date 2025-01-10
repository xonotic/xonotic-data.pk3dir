#include "dialog_hudpanel_infomessages.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "mixedslider.qh"

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
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_infomessages_group_fadetime"));
			e.addText(e, ZCTX(_("FADESPEED^Instant")), 0);
			e.addRange(e, 0.05, 1, 0.05);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_infomessages_flip", _("Flip align")));
}
