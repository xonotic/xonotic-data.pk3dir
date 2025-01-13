#include "dialog_hudpanel_infomessages.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "textslider.qh"
#include "radiobutton.qh"

void XonoticHUDInfoMessagesDialog_fill(entity me)
{
	entity e;
	string panelname = "infomessages";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 10, 1, "hud_panel_infomessages_group_time"));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade time:")));
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_infomessages_group_fadetime"));
			e.addValue(e, ZCTX(_("FADESPEED^Instant")), "0");
			for(i = 1; i <= 19; ++i)
				e.addValue(e, strzone(ftos_decimals(i / 20, 2)), strzone(ftos_mindecimals(i / 20)));
			e.addValue(e, "1.00", "1");
			e.configureXonoticTextSliderValues(e);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Text alignment:")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_infomessages_flip", "0", _("Left")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_infomessages_flip", "1", _("Right")));
}
