#include "dialog_hudpanel_strafehud.qh"

#include "checkbox.qh"
#include "colorpicker_string.qh"
#include "button.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"

void StrafeHUD_ColorReset(entity btn, entity me)
{
	cvar_set("hud_panel_strafehud_bar_accel_color", cvar_defstring("hud_panel_strafehud_bar_accel_color"));
	cvar_set("hud_panel_strafehud_bar_neutral_color", cvar_defstring("hud_panel_strafehud_bar_neutral_color"));
	cvar_set("hud_panel_strafehud_bar_overturn_color", cvar_defstring("hud_panel_strafehud_bar_overturn_color"));
	cvar_set("hud_panel_strafehud_angle_accel_color", cvar_defstring("hud_panel_strafehud_angle_accel_color"));
	cvar_set("hud_panel_strafehud_angle_neutral_color", cvar_defstring("hud_panel_strafehud_angle_neutral_color"));
	cvar_set("hud_panel_strafehud_angle_overturn_color", cvar_defstring("hud_panel_strafehud_angle_overturn_color"));
	cvar_set("hud_panel_strafehud_switch_color", cvar_defstring("hud_panel_strafehud_switch_color"));
	cvar_set("hud_panel_strafehud_bestangle_color", cvar_defstring("hud_panel_strafehud_bestangle_color"));
}

void XonoticHUDStrafeHUDDialog_fill(entity me)
{
	entity e;
	string panelname = "strafehud";
	int i;

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticMixedSlider("hud_panel_strafehud"));
			e.setValueSpace(e, e.valueSpace * 1.2);
			e.addText(e, _("Disable"), 0);
			e.addText(e, _("Enable"), 1);
			e.addText(e, _("Enable even observing"), 2);
			e.addText(e, _("Enable only in Race/CTS"), 3);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Centered on:")));
			me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton(2, "hud_panel_strafehud_mode", "0", _("View angle")));
			me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton(2, "hud_panel_strafehud_mode", "1", _("Velocity angle")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Style:")));
		me.TD(me, 1, 2.8, e = makeXonoticMixedSlider("hud_panel_strafehud_style"));
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("STYL^Basic")), 0);
			e.addText(e, _("Status bar"),       1);
			e.addText(e, _("Gradient"),         2);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Range:")));
		me.TD(me, 1, 2.8, e = makeXonoticMixedSlider("hud_panel_strafehud_range"));
			e.formatString = _("%s°");
			e.addText(e, _("Dynamic"), 0);
			e.addRange(e, 10, 360, 10);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, (4 - 0.05) / 2, e = makeXonoticTextLabel(0, _("Strafe bar:")));

		me.TDempty(me, 0.05);

		me.TD(me, 1, (4 - 0.05) / 2, e = makeXonoticTextLabel(0, _("Angle indicator:")));
	me.TR(me);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Neutral:")));
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Good:")));
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Overturn:")));

		me.TDempty(me, 0.05);

		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Neutral:")));
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Good:")));
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticTextLabel(0, _("Overturn:")));
	me.TR(me);
		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_neutral_color", "hud_panel_strafehud_bar_neutral_color"));
			setDependentNOT(e, "hud_panel_strafehud_bar_neutral_alpha", 0);
		me.TDempty(me, 0.05);
		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_accel_color", "hud_panel_strafehud_bar_accel_color"));
			setDependentNOT(e, "hud_panel_strafehud_bar_accel_alpha", 0);
		me.TDempty(me, 0.05);
		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_overturn_color", "hud_panel_strafehud_bar_overturn_color"));
			setDependentNOT(e, "hud_panel_strafehud_bar_overturn_alpha", 0);

		me.TDempty(me, 0.05);

		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_neutral_color", "hud_panel_strafehud_angle_neutral_color"));
			setDependentNOT(e, "hud_panel_strafehud_angle_alpha", 0);
		me.TDempty(me, 0.05);
		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_accel_color", "hud_panel_strafehud_angle_accel_color"));
			setDependentNOT(e, "hud_panel_strafehud_angle_alpha", 0);
		me.TDempty(me, 0.05);
		me.TD(me, 2, (4 - 0.25) / 6, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_overturn_color", "hud_panel_strafehud_angle_overturn_color"));
			setDependentNOT(e, "hud_panel_strafehud_angle_alpha", 0);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_neutral_alpha"));
			e.formatString = "%";
			e.setValueSpace(e, e.valueSpace * 1.25);
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_accel_alpha"));
			e.formatString = "%";
			e.setValueSpace(e, e.valueSpace * 1.25);
		me.TDempty(me, 0.05);
		me.TD(me, 1, (4 - 0.25) / 6, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_overturn_alpha"));
			e.formatString = "%";
			e.setValueSpace(e, e.valueSpace * 1.25);

		me.TDempty(me, 0.05);

		me.TD(me, 1, (4 - 0.05) / 2, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_angle_alpha"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox_T(0, "hud_panel_strafehud_switch", _("Switch:"),
			_("Indicator on the angle to aim at when switching strafing direction")));

		me.TDempty(me, 0.1);

		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox_T(0, "hud_panel_strafehud_wturn", _("W-turn:"),
			_("Indicator on the angle to aim at when W-turning to rotate as fast as possible")));

		me.TDempty(me, 0.1);

		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox_T(0, "hud_panel_strafehud_bestangle", _("Best angle:"),
			_("Indicator on the angle to aim at for maximal acceleration")));
	me.TR(me);
		me.TD(me, 2, (4 - 0.2) / 3, e = makeXonoticColorpickerString("hud_panel_strafehud_switch_color", "hud_panel_strafehud_switch_color"));
			setDependentNOT(e, "hud_panel_strafehud_switch_alpha", 0);
			setDependentAND(e, "hud_panel_strafehud_switch", 1, 3);

		me.TDempty(me, 0.1);

		me.TD(me, 2, (4 - 0.2) / 3, e = makeXonoticColorpickerString("hud_panel_strafehud_wturn_color", "hud_panel_strafehud_wutrn_color"));
			setDependentNOT(e, "hud_panel_strafehud_wturn_alpha", 0);
			setDependentAND(e, "hud_panel_strafehud_wturn", 1, 3);

		me.TDempty(me, 0.1);

		me.TD(me, 2, (4 - 0.2) / 3, e = makeXonoticColorpickerString("hud_panel_strafehud_bestangle_color", "hud_panel_strafehud_bestangle_color"));
			setDependentNOT(e, "hud_panel_strafehud_bestangle_alpha", 0);
			setDependentAND(e, "hud_panel_strafehud_bestangle", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_switch_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_panel_strafehud_switch", 1, 3);

		me.TDempty(me, 0.1);

		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_wturn_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_panel_strafehud_wturn", 1, 3);

		me.TDempty(me, 0.1);

		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bestangle_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_panel_strafehud_bestangle", 1, 1);
	me.TR(me);
		me.TD(me, 1, (4 - 0.1) / 2, e = makeXonoticCheckBox(0, "_hud_panel_strafehud_demo", _("Demo mode")));

		me.TDempty(me, 0.1);

		me.TD(me, 1, (4 - 0.1) / 2, e = makeXonoticButton(_("Reset colors"), '0 0 0'));
			e.onClick = StrafeHUD_ColorReset;
			e.onClickEntity = me;
}
