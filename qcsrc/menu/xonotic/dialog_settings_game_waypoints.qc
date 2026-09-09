#include "dialog_settings_game_waypoints.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticGameWaypointsSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameWaypointsSettingsTab()
{
	entity me = NEW(XonoticGameWaypointsSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameWaypointsSettingsTab_fill(entity me)
{
	entity e;

	me.gotoRC(me, 0, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Waypoints")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(1, "cl_hidewaypoints", _("Display waypoint markers for objectives on the map"),
			_("Show various gametype specific waypoints")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Opacity:")));
			setDependent(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.1, 1, 0.1, "g_waypointsprite_alpha", "-"));
			e.formatString = "%";
			setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Font size:")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "g_waypointsprite_fontsize"));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Edge offset:")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 0.3, 0.01, "g_waypointsprite_edgeoffset_bottom", "-"));
			makeMulti(e, "g_waypointsprite_edgeoffset_top g_waypointsprite_edgeoffset_left g_waypointsprite_edgeoffset_right");
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.25, 1, "g_waypointsprite_crosshairfadealpha", _("Fade when near the crosshair")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "g_waypointsprite_text", _("Display names instead of icons")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Player Names")));
	me.TR(me);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "hud_shownames", _("Show names above players")));
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "hud_shownames_status", _("Display health and armor")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Opacity:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.1, "hud_shownames_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Font size:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "hud_shownames_fontsize"));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Max distance:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(2000, 10000, 500, "hud_shownames_maxdistance"));
			e.formatString = _("%s qu");
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Decolorize:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("hud_shownames_decolorize"));
			e.addText(e, _("Never"),    0);
			e.addText(e, _("Teamplay"), 1);
			e.addText(e, _("Always"),   2);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(25, 0, "hud_shownames_crosshairdistance", _("Only when near crosshair")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
}
