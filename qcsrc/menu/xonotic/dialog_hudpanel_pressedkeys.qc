#include "dialog_hudpanel_pressedkeys.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticHUDPressedKeysDialog_fill(entity me)
{
	entity e;
	string panelname = "pressedkeys";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticMixedSlider("hud_panel_pressedkeys"));
			e.addText(e, (_("Disable")), 0);
			e.addText(e, (_("Enable spectating")), 1);
			e.addText(e, (_("Always enable")), 2);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Forced aspect:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.2, 4, 0.1, "hud_panel_pressedkeys_aspect"));

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_pressedkeys_attack", _("Show attack keys")));
}
