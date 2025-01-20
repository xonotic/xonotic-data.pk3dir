#include "dialog_hudpanel_healtharmor.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticHUDHealthArmorDialog_fill(entity me)
{
	entity e;
	string panelname = "healtharmor";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_healtharmor_combined", _("Combine health and armor")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_healtharmor_flip", _("Flip health and armor positions")));
			setDependent(e, "hud_panel_healtharmor_combined", 0, 0);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_healtharmor_progressbar", _("Enable status bar")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticTextLabel(0, _("Status bar alignment:")));
			setDependent(e, "hud_panel_healtharmor_progressbar", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_healtharmor_baralign", "0", _("Left")));
			setDependent(e, "hud_panel_healtharmor_progressbar", 1, 1);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_healtharmor_baralign", "1", _("Right")));
			setDependent(e, "hud_panel_healtharmor_progressbar", 1, 1);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_healtharmor_baralign", "2", _("Inward")));
			setDependent(e, "hud_panel_healtharmor_progressbar", 1, 1);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_healtharmor_baralign", "3", _("Outward")));
			setDependent(e, "hud_panel_healtharmor_progressbar", 1, 1);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Icon alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_healtharmor_iconalign", "0", _("Left")));
		me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_healtharmor_iconalign", "1", _("Right")));
		me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_healtharmor_iconalign", "2", _("Inward")));
		me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_healtharmor_iconalign", "3", _("Outward")));
}
