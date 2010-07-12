#ifdef INTERFACE
CLASS(XonoticHUDWeaponIconsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDWeaponIconsDialog, fill, void(entity))
	ATTRIB(XonoticHUDWeaponIconsDialog, title, string, "Weapon Icons Panel")
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
	string panelname = "weaponicons";
	float i;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_weaponicons", "Enable panel"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Color:"));
		me.TD(me, 3, 2.4, e = makeXonoticColorpickerString(strzone(strcat("hud_", panelname, "_bg_color"))));
			setDependentStringNotEqual(e, strzone(strcat("hud_", panelname, "_bg_color")), "");
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 0.8, e = makeXonoticRadioButton(1, strzone(strcat("hud_", panelname, "_bg_color")), "", "Use default"));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 0.8, e = makeXonoticRadioButton(1, strzone(strcat("hud_", panelname, "_bg_color")), strzone(cvar_string("hud_bg_color")), "Custom"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Border size:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_", panelname, "_bg_border"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Alpha:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_", panelname, "_bg_alpha"))));
				e.addValue(e, "Default", "");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Team Color:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_", panelname, "_bg_color_team"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Padding:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_", panelname, "_bg_padding"))));
				e.addValue(e, "Default", "");
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Weapon icons:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, "Show weapon ID as:"));
			me.TD(me, 1, 0.8, e = makeXonoticRadioButton(2, "hud_weaponicons_number", "0", "None"));
			me.TD(me, 1, 0.8, e = makeXonoticRadioButton(2, "hud_weaponicons_number", "1", "Number"));
			me.TD(me, 1, 0.8, e = makeXonoticRadioButton(2, "hud_weaponicons_number", "2", "Bind"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_weaponicons_accuracy", "Show Accuracy"));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_weaponicons_ammo", "Show Ammo"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, "Ammo bar alpha:"));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_weaponicons_ammo_alpha"));
			setDependent(e, "hud_weaponicons_ammo", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Ammo bar color:"));
		me.TD(me, 2, 2.4, e = makeXonoticColorpickerString("hud_weaponicons_ammo_color"));
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
