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
			e.addText(e, _("Disable"), 0);
			e.addText(e, _("Enable in team games"), 1);
			e.addText(e, _("Always enable"), 2);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Alpha:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_radar_foreground_alpha"));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Rotation:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_rotation"));
				e.addText(e, _("Forward"), 0);
				e.addText(e, _("West"),    1);
				e.addText(e, _("South"),   2);
				e.addText(e, _("East"),    3);
				e.addText(e, _("North"),   4);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_scale"));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Zoom mode:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_zoommode"));
				e.addText(e, _("Zoomed in"),     0);
				e.addText(e, _("Zoomed out"),    1);
				e.addText(e, _("Always zoomed"), 2);
				e.addText(e, _("Never zoomed"),  3);
				e.configureXonoticMixedSliderValues(e);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Maximized radar:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Rotation:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_maximized_rotation"));
				e.addText(e, _("Forward"), 0);
				e.addText(e, _("West"),    1);
				e.addText(e, _("South"),   2);
				e.addText(e, _("East"),    3);
				e.addText(e, _("North"),   4);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_maximized_scale"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Zoom mode:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_radar_maximized_zoommode"));
				e.addText(e, _("Zoomed in"),     0);
				e.addText(e, _("Zoomed out"),    1);
				e.addText(e, _("Always zoomed"), 2);
				e.addText(e, _("Never zoomed"),  3);
				e.configureXonoticMixedSliderValues(e);
}
