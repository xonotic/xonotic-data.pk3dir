#include "dialog_hudpanel_radar.qh"

#include "checkbox.qh"
#include "textslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticHUDRadarDialog_fill(entity me)
{
	entity e;
	string panelname = "radar";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextSlider("hud_panel_radar"));
			e.addValue(e, _("Disable"), "0");
			e.addValue(e, _("Enable in team games"), "1");
			e.addValue(e, _("Always enable"), "2");
			e.configureXonoticTextSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Radar:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Alpha:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_radar_foreground_alpha"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Rotation:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_radar_rotation"));
				e.addValue(e, _("Forward"), "0");
				e.addValue(e, _("West"), "1");
				e.addValue(e, _("South"), "2");
				e.addValue(e, _("East"), "3");
				e.addValue(e, _("North"), "4");
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1024, 8192, 512, "hud_panel_radar_scale"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Zoom mode:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_radar_zoommode"));
				e.addValue(e, _("Zoomed in"), "0");
				e.addValue(e, _("Zoomed out"), "1");
				e.addValue(e, _("Always zoomed"), "2");
				e.addValue(e, _("Never zoomed"), "3");
				e.configureXonoticTextSliderValues(e);
}
