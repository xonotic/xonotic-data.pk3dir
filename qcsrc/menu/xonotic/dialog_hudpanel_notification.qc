#include "dialog_hudpanel_notification.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "textslider.qh"

void XonoticHUDNotificationDialog_fill(entity me)
{
	entity e;
	string panelname = "notify";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Entry lifetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(3, 15, 1, "hud_panel_notify_time"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Entry fadetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_notify_fadetime"));
			e.addValue(e, ZCTX(_("FADESPEED^Instant")), "0");
			for(i = 1; i <= 10; ++i)
				e.addValue(e, strzone(ftos_decimals(i / 2, 1)), strzone(ftos_mindecimals(i / 2)));
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_notify_flip", _("Flip notify order")));
}
