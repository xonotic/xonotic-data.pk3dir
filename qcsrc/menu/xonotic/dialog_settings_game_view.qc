#include "dialog_settings_game_view.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticGameViewSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameViewSettingsTab()
{
	entity me;
	me = NEW(XonoticGameViewSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameViewSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Perspective")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Field of view:")));
		me.TD(me, 1, 1.8, e = makeXonoticSlider_T(60, 130, 5, "fov",
			_("Field of vision in degrees")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "0", _("1st person perspective")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(2, 0, "cl_eventchase_death", _("Slide to third person upon death")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_bobfall", _("Smooth the view when landing from a jump")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_smoothviewheight", _("Smooth the view while crouching")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(1, 0, "v_idlescale", _("View waving while idle")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx_T(0.01, 0, "cl_bob", _("View bobbing while walking around"), "-"));
		makeMulti(e, "cl_bob2");
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "1", _("3rd person perspective")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Back distance")));
		setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(10, 100, 1, "chase_back"));
		setDependent(e, "chase_active", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Up distance")));
		setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(10, 50, 1, "chase_up"));
		setDependent(e, "chase_active", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_clippedspectating", _("Allow passing through walls while spectating")));
			e.sendCvars = true;

	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Zooming")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom factor:"))));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(2, 30, 0.5, "cl_zoomfactor",
			_("How big the zoom factor is when the zoom button is pressed")));
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom speed:"))));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("cl_zoomspeed",
			_("How fast the view will be zoomed, disable to zoom instantly")));
			e.addRange(e, 1, 8, 1);
			e.addText(e, ZCTX(_("ZOOM^Instant")), -1);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		//me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("ZOOM^Zoom sensitivity:"))));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 1, 0.1, "cl_zoomsensitivity",
			_("How zoom changes sensitivity, from 0 (lower sensitivity) to 1 (no sensitivity change)")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "cl_zoomscroll", _("Zoom scrolling")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Scale:")));
			setDependent(e, "cl_zoomscroll", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(-1, 1, 0.1, "cl_zoomscroll_scale")); // would be better if this could skip 0
			setDependent(e, "cl_zoomscroll", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed:")));
			setDependent(e, "cl_zoomscroll", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_zoomscroll_speed"));
			e.addRange(e, 2, 16, 2);
			e.addText(e, ZCTX(_("ZOOM^Instant")), -1);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "cl_zoomscroll", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_velocityzoom_enabled", _("Velocity zoom")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, ZCTX(_("VZOOM^Factor"))));
			setDependentAND(e, "cl_velocityzoom_enabled", 1, 1, "cl_velocityzoom_type", 1, 3);
		me.TD(me, 1, 2, e = makeXonoticSlider(-1, 1, 0.1, "cl_velocityzoom_factor"));
			setDependentAND(e, "cl_velocityzoom_enabled", 1, 1, "cl_velocityzoom_type", 1, 3);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(3, 1, "cl_velocityzoom_type", _("Forward movement only")));
			setDependent(e, "cl_velocityzoom_enabled", 1, 1);
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
