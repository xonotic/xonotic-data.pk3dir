#include "dialog_hudpanel_powerups.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "radiobutton.qh"

void XonoticHUDPowerupsDialog_fill(entity me)
{
	entity e;
	string panelname = "powerups";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_powerups_progressbar", _("Enable status bar")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticTextLabel(0, _("Status bar alignment:")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.4);
			me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "0", _("Left")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "1", _("Right")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "2", _("Inward")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "3", _("Outward")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Icon alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "0", _("Left")));
			me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "1", _("Right")));
			me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "2", _("Inward")));
			me.TD(me, 1, 3.8/4, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "3", _("Outward")));
}
