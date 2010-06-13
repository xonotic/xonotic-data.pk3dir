#ifdef INTERFACE
CLASS(XonoticHUDVoteDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDVoteDialog, fill, void(entity))
	ATTRIB(XonoticHUDVoteDialog, title, string, "Vote Panel Setup")
	ATTRIB(XonoticHUDVoteDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDVoteDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDVoteDialog, rows, float, 15)
	ATTRIB(XonoticHUDVoteDialog, columns, float, 4)
	ATTRIB(XonoticHUDVoteDialog, name, string, "HUDvote")
ENDCLASS(XonoticHUDVoteDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDVoteDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_vote", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_vote_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_vote_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
