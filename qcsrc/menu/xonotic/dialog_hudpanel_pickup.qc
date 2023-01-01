#include "dialog_hudpanel_pickup.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "textslider.qh"

void XonoticHUDPickupDialog_fill(entity me)
{
	entity e;
	string panelname = "pickup";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Pickup messages:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 5, 1, "hud_panel_pickup_time"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Fade time:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0, 1, 0.05, "hud_panel_pickup_fade_out"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Show timer:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("hud_panel_pickup_showtimer"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Always"), "1");
			e.addValue(e, _("Spectating"), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Icon size scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 3, 0.1, "hud_panel_pickup_iconsize"));
}
