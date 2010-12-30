#ifdef INTERFACE
CLASS(XonoticHUDPhysicsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDPhysicsDialog, fill, void(entity))
	ATTRIB(XonoticHUDPhysicsDialog, title, string, "Physics Panel")
	ATTRIB(XonoticHUDPhysicsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDPhysicsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDPhysicsDialog, rows, float, 15)
	ATTRIB(XonoticHUDPhysicsDialog, columns, float, 4)
	ATTRIB(XonoticHUDPhysicsDialog, name, string, "HUDphysics")
	ATTRIB(XonoticHUDPhysicsDialog, sliderTopspeedTime, entity, NULL)
ENDCLASS(XonoticHUDPhysicsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDPhysicsDialog_fill(entity me)
{
	entity e;
	string panelname = "physics";
	float i;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("hud_panel_physics"));
			e.addValue(e, "Panel disabled", "0");
			e.addValue(e, "Panel enabled if not observing", "1");
			e.addValue(e, "Panel always enabled", "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, "Background:"));
			me.TD(me, 1, 1.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				e.addValue(e, strzone(strcat("border_", panelname)), strzone(strcat("border_", panelname)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Color:"));
		me.TD(me, 2, 2.4, e = makeXonoticColorpickerString(strzone(strcat("hud_panel_", panelname, "_bg_color")), "hud_panel_bg_color"));
			setDependentStringNotEqual(e, strzone(strcat("hud_panel_", panelname, "_bg_color")), "");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBoxString("", "1 1 1", strzone(strcat("hud_panel_", panelname, "_bg_color")), "Use default"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Border size:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_border"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Alpha:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_alpha"))));
				e.addValue(e, "Default", "");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Team Color:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_color_team"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_configure_teamcolorforced", "Test the team color in HUD configure mode"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Padding:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_padding"))));
				e.addValue(e, "Default", "");
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticCheckBox(0, "hud_panel_physics_progressbar", "Status bar"));
		me.TD(me, 1, 1.6, e = makeXonoticTextSlider("hud_panel_physics_baralign"));
			e.addValue(e, "Left align"   , "0");
			e.addValue(e, "Right align"  , "1");
			e.addValue(e, "Inward align" , "2");
			e.addValue(e, "Outward align", "3");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "hud_panel_physics_progressbar", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_physics_flip", "Flip speed/acceleration positions"));

//speed
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Speed:"));
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_physics_speed_z", "Include vertical speed"));
	// me.TR(me);
		// me.TDempty(me, 0.2);
		// me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, "Full status bar at:"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 1, e = makeXonoticInputBox(1, "hud_panel_physics_speed_max"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "qu/s"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Speed unit:"));
		me.TD(me, 1, 2.6/3*2, e = makeXonoticTextSlider("hud_panel_physics_speed_unit"));
			e.addValue(e, "qu/s" , "1");
			e.addValue(e, "m/s"  , "2");
			e.addValue(e, "km/h" , "3");
			e.addValue(e, "mph"  , "4");
			e.addValue(e, "knots", "5");
			e.configureXonoticTextSliderValues(e);
		me.TD(me, 1, 2.6/3, e = makeXonoticCheckBox(0, "hud_panel_physics_speed_unit_show", "Show"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8/2, e = makeXonoticCheckBox(0, "hud_panel_physics_topspeed", "Top Speed"));
		me.TD(me, 1, 3.8/2, e = makeXonoticSlider(1, 10, 1, "hud_panel_physics_topspeed_time"));
			setDependent(e, "hud_panel_physics_topspeed", 1, 1);

//acceleration
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Acceleration:"));
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_physics_acceleration_z", "Include vertical acc."));
	// me.TR(me);
		// me.TDempty(me, 0.2);
		// me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, "Full status bar at:"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 0.6, e = makeXonoticInputBox(1, "hud_panel_physics_acceleration_max"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
}
#endif