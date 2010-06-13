#ifdef INTERFACE
CLASS(XonoticHUDPowerupsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDPowerupsDialog, fill, void(entity))
	ATTRIB(XonoticHUDPowerupsDialog, title, string, "Powerups Panel Setup")
	ATTRIB(XonoticHUDPowerupsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDPowerupsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDPowerupsDialog, rows, float, 15)
	ATTRIB(XonoticHUDPowerupsDialog, columns, float, 4)
	ATTRIB(XonoticHUDPowerupsDialog, name, string, "HUDpowerups")
ENDCLASS(XonoticHUDPowerupsDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDPowerupsDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_powerups", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_powerups_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_powerups_bg_alpha"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_powerups_flip", "Flip"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_powerups_mirror", "Mirror"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
