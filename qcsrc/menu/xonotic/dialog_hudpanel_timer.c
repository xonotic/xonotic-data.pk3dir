#ifdef INTERFACE
CLASS(XonoticHUDTimerDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDTimerDialog, fill, void(entity))
	ATTRIB(XonoticHUDTimerDialog, title, string, "Timer Panel Setup")
	ATTRIB(XonoticHUDTimerDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDTimerDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDTimerDialog, rows, float, 15)
	ATTRIB(XonoticHUDTimerDialog, columns, float, 4)
	ATTRIB(XonoticHUDTimerDialog, name, string, "HUDtimer")
ENDCLASS(XonoticHUDTimerDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDTimerDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_timer", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_timer_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_timer_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
