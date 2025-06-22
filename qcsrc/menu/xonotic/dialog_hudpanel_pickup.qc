#include "dialog_hudpanel_pickup.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"

void XonoticHUDPickupDialog_fill(entity me)
{
	entity e;
	string panelname = "pickup";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 5, 1, "hud_panel_pickup_time"));
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.25);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade time:")));
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_pickup_fade_out"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("FADESPEED^Instant")), 0);
			e.addRange(e, 0.05, 1, 0.05);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Icon size scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 3, 0.1, "hud_panel_pickup_iconsize"));
			e.formatString = _("%sx");

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Show timer:")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "0", _("Never")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "2", _("Spectating")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_pickup_showtimer", "1", _("Always")));
}
