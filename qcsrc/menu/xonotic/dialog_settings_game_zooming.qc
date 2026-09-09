#include "dialog_settings_game_zooming.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticGameZoomingSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameZoomingSettingsTab()
{
	entity me = NEW(XonoticGameZoomingSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameZoomingSettingsTab_fill(entity me)
{
	entity e;

	me.gotoRC(me, 0, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Zooming")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom factor:"))));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("cl_zoomfactor",
			_("How big the zoom factor is when the zoom button is pressed")));
			e.formatString = _("%sx");
			e.addRange(e, 2, 10, 0.5);
			e.addRange(e, 11, 30, 1);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom speed:"))));
			setDependentNOT(e, "cl_zoomfactor", 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("cl_zoomspeed",
			_("How fast the view will be zoomed, disable to zoom instantly")));
			e.addRange(e, 1, 8, 1);
			e.addText(e, ZCTX(_("ZOOM^Instant")), -1);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "cl_zoomfactor", 1);
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom sensitivity:"))));
			setDependentNOT(e, "cl_zoomfactor", 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.05, 1, 0.05, "cl_zoomsensitivity",
			_("How zoom changes sensitivity, from 0% (lower sensitivity) to 100% (no sensitivity change)")));
			e.formatString = "%";
			setDependentNOT(e, "cl_zoomfactor", 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_zoomscroll", _("Zoom scrolling")));
			setDependentNOT(e, "cl_zoomfactor", 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Scale:")));
			setDependentNOT(e, "cl_zoomfactor", 1);
			setDependentAND(e, "cl_zoomscroll", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(-1, 1, 0.1, "cl_zoomscroll_scale")); // would be better if this could skip 0
			e.formatString = _("%sx");
			setDependentNOT(e, "cl_zoomfactor", 1);
			setDependentAND(e, "cl_zoomscroll", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed:")));
			setDependentNOT(e, "cl_zoomfactor", 1);
			setDependentAND(e, "cl_zoomscroll", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_zoomscroll_speed"));
			e.addRange(e, 2, 16, 2);
			e.addText(e, ZCTX(_("ZOOM^Instant")), -1);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "cl_zoomfactor", 1);
			setDependentAND(e, "cl_zoomscroll", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_velocityzoom_enabled", _("Velocity zoom")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, ZCTX(_("VZOOM^Factor"))));
			setDependent(e, "cl_velocityzoom_enabled", 1, 1);
			setDependentAND(e, "cl_velocityzoom_type", 1, 3);
		me.TD(me, 1, 2, e = makeXonoticSlider(-1, 1, 0.1, "cl_velocityzoom_factor"));
			e.formatString = _("%sx");
			setDependent(e, "cl_velocityzoom_enabled", 1, 1);
			setDependentAND(e, "cl_velocityzoom_type", 1, 3);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(3, 1, "cl_velocityzoom_type", _("Forward movement only")));
			setDependentNOT(e, "cl_velocityzoom_factor", 0);
			setDependentAND(e, "cl_velocityzoom_enabled", 1, 1);

	me.TR(me);
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_reticle", _("Display reticle 2D overlay while zooming")));
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_unpress_zoom_on_death", _("Release zoom when you die or respawn"), "-"));
			makeMulti(e, "cl_unpress_zoom_on_spawn");
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_unpress_zoom_on_weapon_switch", _("Release zoom when you switch weapons")));
}
