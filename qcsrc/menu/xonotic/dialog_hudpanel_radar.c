#ifdef INTERFACE
CLASS(XonoticHUDRadarDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDRadarDialog, fill, void(entity))
	ATTRIB(XonoticHUDRadarDialog, title, string, "Radar Panel")
	ATTRIB(XonoticHUDRadarDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDRadarDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDRadarDialog, rows, float, 15)
	ATTRIB(XonoticHUDRadarDialog, columns, float, 4)
	ATTRIB(XonoticHUDRadarDialog, name, string, "HUDradar")
ENDCLASS(XonoticHUDRadarDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDRadarDialog_fill(entity me)
{
	entity e;
	string panelname = "radar";
	float i;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("hud_panel_radar"));
			e.addValue(e, "Panel disabled", "0");
			e.addValue(e, "Panel enabled in teamgames", "1");
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
		me.TD(me, 2, 2.4, e = makeXonoticColorpickerString(strzone(strcat("hud_panel_", panelname, "_bg_color"))));
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
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Radar:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Alpha:"));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_radar_foreground_alpha"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Rotation:"));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_radar_rotation"));
				e.addValue(e, "Forward", "0");
				e.addValue(e, "West", "1");
				e.addValue(e, "South", "2");
				e.addValue(e, "East", "3");
				e.addValue(e, "North", "4");
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Scale:"));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_scale"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Zoom mode:"));
			me.TD(me, 1, 1.6, e = makeXonoticTextSlider("hud_panel_radar_zoommode"));
				e.addValue(e, "Zoomed in", "0");
				e.addValue(e, "Zoomed out", "1");
				e.addValue(e, "Always zoomed", "2");
				e.addValue(e, "Never zoomed", "3");
				e.configureXonoticTextSliderValues(e);
}
#endif
