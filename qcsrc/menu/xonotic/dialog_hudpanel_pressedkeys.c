#ifdef INTERFACE
CLASS(XonoticHUDPressedKeysDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDPressedKeysDialog, fill, void(entity))
	ATTRIB(XonoticHUDPressedKeysDialog, title, string, "Pressed Keys Panel Setup")
	ATTRIB(XonoticHUDPressedKeysDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDPressedKeysDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDPressedKeysDialog, rows, float, 15)
	ATTRIB(XonoticHUDPressedKeysDialog, columns, float, 4)
	ATTRIB(XonoticHUDPressedKeysDialog, name, string, "HUDpressedkeys")
ENDCLASS(XonoticHUDPressedKeysDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDPressedKeysDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_pressedkeys", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_pressedkeys_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_pressedkeys_bg_alpha"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
