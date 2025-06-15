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
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "0", _("No styling")));
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "1", _("Status bar")));
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "2", _("Gradient")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Range:")));
		me.TD(me, 1, 2.8, e = makeXonoticMixedSlider("hud_panel_strafehud_range"));
			e.formatString = _("%s°");
			e.addText(e, _("Dynamic"), 0);
			e.addRange(e, 10, 360, 10);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Strafe bar:")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Angle indicator:")));
	me.TR(me);
		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Neutral:")));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Good:")));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Overturn:")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Neutral:")));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Good:")));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Overturn:")));
	me.TR(me);
		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_neutral_color", "hud_panel_strafehud_bar_neutral_color"));
		me.TDempty(me, 0.1);
		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_accel_color", "hud_panel_strafehud_bar_accel_color"));
		me.TDempty(me, 0.1);
		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_overturn_color", "hud_panel_strafehud_bar_overturn_color"));

		me.TDempty(me, 0.2);

		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_neutral_color", "hud_panel_strafehud_angle_neutral_color"));
		me.TDempty(me, 0.1);
		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_accel_color", "hud_panel_strafehud_angle_accel_color"));
		me.TDempty(me, 0.1);
		me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_angle_overturn_color", "hud_panel_strafehud_angle_overturn_color"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.56666666, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_neutral_alpha"));
			e.formatString = "%";
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_accel_alpha"));
			e.formatString = "%";
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_overturn_alpha"));
			e.formatString = "%";

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_angle_alpha"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Switch indicator:")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Best angle indicator:")));
	me.TR(me);
		me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_strafehud_switch_color", "hud_panel_strafehud_switch_color"));

		me.TDempty(me, 0.2);

		me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_strafehud_bestangle_color", "hud_panel_strafehud_bestangle_color"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_switch_alpha"));
			e.formatString = "%";
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticCheckBox(0, "hud_panel_strafehud_switch", _("Enable")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 0.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bestangle_alpha"));
			e.formatString = "%";
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticCheckBox(0, "hud_panel_strafehud_bestangle", _("Enable")));
	me.TR(me);
		me.TD(me, 1, 1.9, e = makeXonoticCheckBox(0, "_hud_panel_strafehud_demo", _("Demo mode")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticButton(_("Reset colors"), '0 0 0'));
			e.onClick = StrafeHUD_ColorReset;
			e.onClickEntity = me;
}
