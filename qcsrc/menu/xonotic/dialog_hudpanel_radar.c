#ifdef INTERFACE
CLASS(XonoticHUDRadarDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDRadarDialog, fill, void(entity))
	ATTRIB(XonoticHUDRadarDialog, title, string, "Radar Panel Setup")
	ATTRIB(XonoticHUDRadarDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDRadarDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDRadarDialog, rows, float, 15)
	ATTRIB(XonoticHUDRadarDialog, columns, float, 4)
	ATTRIB(XonoticHUDRadarDialog, name, string, "HUDradar")
ENDCLASS(XonoticHUDRadarDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDRadarDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_radar", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_radar_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_radar_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
