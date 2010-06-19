#ifdef INTERFACE
CLASS(XonoticHUDWeaponIconsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDWeaponIconsDialog, fill, void(entity))
	ATTRIB(XonoticHUDWeaponIconsDialog, title, string, "Weapon Icons Panel Setup")
	ATTRIB(XonoticHUDWeaponIconsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDWeaponIconsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDWeaponIconsDialog, rows, float, 15)
	ATTRIB(XonoticHUDWeaponIconsDialog, columns, float, 4)
	ATTRIB(XonoticHUDWeaponIconsDialog, name, string, "HUDweaponicons")
ENDCLASS(XonoticHUDWeaponIconsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDWeaponIconsDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_weaponicons", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_weaponicons_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_weaponicons_bg_alpha"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "hud_weaponicons_number", "Show Weapon Number"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
