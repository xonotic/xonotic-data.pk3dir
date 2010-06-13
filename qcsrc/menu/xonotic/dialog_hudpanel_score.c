#ifdef INTERFACE
CLASS(XonoticHUDScoreDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDScoreDialog, fill, void(entity))
	ATTRIB(XonoticHUDScoreDialog, title, string, "Score Panel Setup")
	ATTRIB(XonoticHUDScoreDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDScoreDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDScoreDialog, rows, float, 15)
	ATTRIB(XonoticHUDScoreDialog, columns, float, 4)
	ATTRIB(XonoticHUDScoreDialog, name, string, "HUDscore")
ENDCLASS(XonoticHUDScoreDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDScoreDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_score", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_score_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_score_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
