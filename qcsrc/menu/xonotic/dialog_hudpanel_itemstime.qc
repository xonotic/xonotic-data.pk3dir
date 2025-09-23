#include "dialog_hudpanel_itemstime.qh"

#include "textlabel.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"
#include "checkbox.qh"
#include "slider.qh"

void XonoticHUDItemsTimeDialog_fill(entity me)
{
	entity e;
	string panelname = "itemstime";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticMixedSlider("hud_panel_itemstime"));
			e.setValueSpace(e, e.valueSpace * 1.5);
			e.addText(e, _("Disable"), 0);
			e.addText(e, _("Enable spectating"), 1);
			e.addText(e, _("Enable even playing in warmup"), 2);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Text/icon ratio:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(2, 8, 0.5, "hud_panel_itemstime_ratio"));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Icon alignment:")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_itemstime_iconalign", "0", _("Left")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_itemstime_iconalign", "1", _("Right")));

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_panel_itemstime_progressbar", _("Enable status bar")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_panel_itemstime_progressbar_reduced", _("Reduced")));
			setDependent(e, "hud_panel_itemstime_progressbar", 1, 1);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_itemstime_hidespawned", _("Hide spawned items")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_itemstime_hidebig", _("Hide big armor and health")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_itemstime_dynamicsize", _("Dynamic size")));
}
