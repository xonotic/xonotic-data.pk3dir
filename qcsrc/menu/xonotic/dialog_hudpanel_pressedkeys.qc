#include "dialog_hudpanel_pressedkeys.qh"

#include "textslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticHUDPressedKeysDialog_fill(entity me)
{
	entity e;
	string panelname = "pressedkeys";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextSlider("hud_panel_pressedkeys"));
			e.addValue(e, (_("Disable")), "0");
			e.addValue(e, (_("Enable spectating")), "1");
			e.addValue(e, (_("Always enable")), "2");
			e.configureXonoticTextSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Forced aspect:")));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(0.2, 4, 0.1, "hud_panel_pressedkeys_aspect"));
}
