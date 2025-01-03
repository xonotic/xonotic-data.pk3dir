#include "dialog_hudpanel_pickup.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "textslider.qh"
#include "radiobutton.qh"

void XonoticHUDPickupDialog_fill(entity me)
{
	entity e;
	string panelname = "pickup";
	float i;

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
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_pickup_fade_out"));
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
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Icon size scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 3, 0.1, "hud_panel_pickup_iconsize"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Show timer:")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "0", _("Never")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "2", _("Spectating")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "1", _("Always")));
}
