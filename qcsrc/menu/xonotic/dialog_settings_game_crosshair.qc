#include "dialog_settings_game_crosshair.qh"

#include "radiobutton.qh"
#include "crosshairpicker.qh"
#include "crosshairpreview.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "colorpicker_string.qh"
#include "checkbox.qh"
#include "textslider.qh"

void XonoticGameCrosshairSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameCrosshairSettingsTab()
{
	entity me;
	me = NEW(XonoticGameCrosshairSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameCrosshairSettingsTab_fill(entity me)
{
	entity e;

	// crosshair_enabled: 0 = no crosshair options, 1 = no crosshair selection, but everything else enabled, 2 = all crosshair options enabled
	// FIXME: In the future, perhaps make one global crosshair_type cvar which has 0 for disabled, 1 for custom, 2 for per weapon, etc?
	me.TR(me); //me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticRadioButton(3, "crosshair_enabled", "0", _("No crosshair")));
	//me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticRadioButton_T(3, "crosshair_per_weapon", string_null, _("Per weapon"),
			_("Set a different crosshair for each weapon, good if you play without weapon models")));
		makeMulti(e, "crosshair_enabled");
	//me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticRadioButton(3, "crosshair_enabled", "2", _("Custom")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 3, 2, e = makeXonoticCrosshairPicker());
			setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
		me.TD(me, 3, 0.9, e = makeXonoticCrosshairPreview());
			setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Size:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1.9, e = makeXonoticSlider(0.1, 1.0, 0.01, "crosshair_size"));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Alpha:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "crosshair_alpha"));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(5, "crosshair_color_special", "1", _("Per weapon")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1, e = makeXonoticRadioButton(5, "crosshair_color_special", "2", _("By health")));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticRadioButton(5, "crosshair_color_special", "0", _("Custom")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 2, 2, e = makeXonoticColorpickerString("crosshair_color", "crosshair_color"));
			setDependentAND(e, "crosshair_color_special", 0, 0, "crosshair_enabled", 1, 2);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "crosshair_ring", _("Use rings to indicate weapon status"), "-"));
			makeMulti(e, "crosshair_ring_reload");
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.3);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Size:")));
			setDependentAND(e, "crosshair_ring", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(2, 4, 0.1, "crosshair_ring_size"));
			setDependentAND(e, "crosshair_ring", 1, 1, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.3);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Alpha:")));
			setDependentAND(e, "crosshair_ring", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(0.1, 1, 0.1, "crosshair_ring_alpha"));
			setDependentAND(e, "crosshair_ring", 1, 1, "crosshair_enabled", 1, 2);

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "crosshair_dot", _("Enable center crosshair dot")));
		setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Size:")));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.2, 2, 0.1, "crosshair_dot_size"));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Alpha:")));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.1, "crosshair_dot_alpha"));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Color:")));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "crosshair_dot_color_custom", "0", _("Use normal crosshair color")));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticRadioButton(1, "crosshair_dot_color_custom", "1", _("Custom")));
			setDependentAND(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2);
		me.TD(me, 2, 2, e = makeXonoticColorpickerString("crosshair_dot_color", "crosshair_dot_color"));
			setDependentAND3(e, "crosshair_dot", 1, 1, "crosshair_enabled", 1, 2, "crosshair_dot_color_custom", 1, 1);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "crosshair_effect_scalefade", _("Smooth effects of crosshairs")));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "crosshair_hittest", _("Perform hit tests for the crosshair")));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox(0, "crosshair_hittest_blur_wall", _("Blur if obstructed by an obstacle")));
			setDependentAND(e, "crosshair_hittest", 1, 100, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox(0, "crosshair_hittest_blur_teammate", _("Blur if obstructed by a teammate")));
			setDependentAND(e, "crosshair_hittest", 1, 100, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx(1.25, 1, "crosshair_hittest", _("Shrink if obstructed by a teammate")));
			setDependentAND(e, "crosshair_enabled", 1, 2, "crosshair_hittest", 1, 100);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(0.5, 0, "crosshair_hitindication", _("Animate crosshair when hitting an enemy")));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(0.25, 0, "crosshair_pickup", _("Animate crosshair when picking up an item")));
			setDependent(e, "crosshair_enabled", 1, 2);
}
