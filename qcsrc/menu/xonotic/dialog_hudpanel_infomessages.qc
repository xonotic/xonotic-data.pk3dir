#include "dialog_hudpanel_infomessages.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "mixedslider.qh"
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
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.25);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade time:")));
			setDependentNOT(e, "hud_panel_infomessages_group_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_infomessages_group_fadetime"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("FADESPEED^Instant")), 0);
			e.addRange(e, 0.05, 1, 0.05);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "hud_panel_infomessages_group_time", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Text alignment:")));
			setDependentNOT(e, "hud_panel_infomessages_group_time", 0);
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_infomessages_flip", "0", _("Left")));
				setDependentNOT(e, "hud_panel_infomessages_group_time", 0);
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_infomessages_flip", "1", _("Right")));
				setDependentNOT(e, "hud_panel_infomessages_group_time", 0);
}
