#include "dialog_hudpanel_notification.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "mixedslider.qh"

void XonoticHUDNotificationDialog_fill(entity me)
{
	entity e;
	string panelname = "notify";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Entry lifetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(3, 15, 1, "hud_panel_notify_time"));
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.25);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Entry fadetime:")));
			setDependentNOT(e, "hud_panel_notify_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_notify_fadetime"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("FADESPEED^Instant")), 0);
			e.addRange(e, 0.5, 5, 0.5);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "hud_panel_notify_time", 0);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_notify_flip", _("Flip notify order")));
			setDependentNOT(e, "hud_panel_notify_time", 0);
}
