#ifdef INTERFACE
CLASS(XonoticHUDRaceTimerDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDRaceTimerDialog, fill, void(entity))
	ATTRIB(XonoticHUDRaceTimerDialog, title, string, "Race Timer Panel Setup")
	ATTRIB(XonoticHUDRaceTimerDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDRaceTimerDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDRaceTimerDialog, rows, float, 15)
	ATTRIB(XonoticHUDRaceTimerDialog, columns, float, 4)
	ATTRIB(XonoticHUDRaceTimerDialog, name, string, "HUDracetimer")
ENDCLASS(XonoticHUDRaceTimerDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDRaceTimerDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_racetimer", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_racetimer_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_racetimer_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
