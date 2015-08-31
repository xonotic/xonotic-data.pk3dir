#ifndef DIALOG_HUDPANEL_POWERUPS_H
#define DIALOG_HUDPANEL_POWERUPS_H
#include "rootdialog.qc"
CLASS(XonoticHUDPowerupsDialog, XonoticRootDialog)
	METHOD(XonoticHUDPowerupsDialog, fill, void(entity));
	ATTRIB(XonoticHUDPowerupsDialog, title, string, _("Powerups Panel"))
	ATTRIB(XonoticHUDPowerupsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDPowerupsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDPowerupsDialog, rows, float, 14)
	ATTRIB(XonoticHUDPowerupsDialog, columns, float, 4)
	ATTRIB(XonoticHUDPowerupsDialog, name, string, "HUDpowerups")
	ATTRIB(XonoticHUDPowerupsDialog, requiresConnection, float, true)
ENDCLASS(XonoticHUDPowerupsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDPowerupsDialog_fill(entity me)
{
	entity e;
	string panelname = "powerups";

	DIALOG_HUDPANEL_COMMON();

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_powerups_progressbar", _("Enable status bar")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Status bar alignment:")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "0", _("Left")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "1", _("Right")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "2", _("Inward")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(2, "hud_panel_powerups_baralign", "3", _("Outward")));
			setDependent(e, "hud_panel_powerups_progressbar", 1, 1);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Icon alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "0", _("Left")));
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "1", _("Right")));
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "2", _("Inward")));
			me.TD(me, 1, 0.95, e = makeXonoticRadioButton(3, "hud_panel_powerups_iconalign", "3", _("Outward")));
}
#endif
