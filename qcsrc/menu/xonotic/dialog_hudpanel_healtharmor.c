#ifdef INTERFACE
CLASS(XonoticHUDHealthArmorDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDHealthArmorDialog, fill, void(entity))
	ATTRIB(XonoticHUDHealthArmorDialog, title, string, "Health/Armor Panel Setup")
	ATTRIB(XonoticHUDHealthArmorDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDHealthArmorDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDHealthArmorDialog, rows, float, 15)
	ATTRIB(XonoticHUDHealthArmorDialog, columns, float, 4)
	ATTRIB(XonoticHUDHealthArmorDialog, name, string, "HUDhealtharmor")
ENDCLASS(XonoticHUDHealthArmorDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDHealthArmorDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "hud_healtharmor", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_healtharmor_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_healtharmor_bg_alpha"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_healtharmor_flip", "Flip"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_healtharmor_mirror", "Mirror"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
