#include "dialog_hudpanel_radar.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticHUDRadarDialog_fill(entity me)
{
	entity e;
	string panelname = "radar";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticMixedSlider("hud_panel_radar"));
			e.setValueSpace(e, e.valueSpace * 1.2);
			e.addText(e, _("Disable"), 0);
			e.addText(e, _("Enable in team games"), 1);
			e.addText(e, _("Always enable"), 2);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Opacity:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_radar_foreground_alpha"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Rotation:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_rotation"));
				e.addText(e, _("Forward"), 0);
				e.addText(e, _("West"),    1);
				e.addText(e, _("South"),   2);
				e.addText(e, _("East"),    3);
				e.addText(e, _("North"),   4);
				e.configureXonoticMixedSliderValues(e);
				setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Scale:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_scale"));
			e.formatString = _("%s qu");
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Zoom mode:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_zoommode"));
				e.setValueSpace(e, e.valueSpace * 1.25);
				e.addText(e, _("Zoomed in"),     0);
				e.addText(e, _("Zoomed out"),    1);
				e.addText(e, _("Always zoomed"), 2);
				e.addText(e, _("Never zoomed"),  3);
				e.configureXonoticMixedSliderValues(e);
				setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Maximized radar:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Rotation:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_maximized_rotation"));
				e.addText(e, _("Forward"), 0);
				e.addText(e, _("West"),    1);
				e.addText(e, _("South"),   2);
				e.addText(e, _("East"),    3);
				e.addText(e, _("North"),   4);
				e.configureXonoticMixedSliderValues(e);
				setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Scale:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_maximized_scale"));
			e.formatString = _("%s qu");
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Zoom mode:")));
			setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_maximized_zoommode"));
				e.setValueSpace(e, e.valueSpace * 1.25);
				e.addText(e, _("Zoomed in"),     0);
				e.addText(e, _("Zoomed out"),    1);
				e.addText(e, _("Always zoomed"), 2);
				e.addText(e, _("Never zoomed"),  3);
				e.configureXonoticMixedSliderValues(e);
				setDependentNOT(e, "hud_panel_radar_foreground_alpha", 0);
}
