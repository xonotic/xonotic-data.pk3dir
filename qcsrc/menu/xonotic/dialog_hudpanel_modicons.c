#ifdef INTERFACE
CLASS(XonoticHUDModIconsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDModIconsDialog, fill, void(entity))
	ATTRIB(XonoticHUDModIconsDialog, title, string, "Mod Icons Panel Setup")
	ATTRIB(XonoticHUDModIconsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDModIconsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDModIconsDialog, rows, float, 15)
	ATTRIB(XonoticHUDModIconsDialog, columns, float, 4)
	ATTRIB(XonoticHUDModIconsDialog, name, string, "HUDmodicons")
ENDCLASS(XonoticHUDModIconsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDModIconsDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_modicons", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_modicons_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_modicons_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
