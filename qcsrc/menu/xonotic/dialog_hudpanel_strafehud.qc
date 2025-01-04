#include "dialog_hudpanel_strafehud.qh"

#include "checkbox.qh"
#include "colorpicker_string.qh"
#include "button.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "textslider.qh"
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
		me.TD(me, 1, 4, e = makeXonoticTextSlider("hud_panel_strafehud"));
			e.addValue(e, _("Disable"), "0");
			e.addValue(e, _("Enable"), "1");
			e.addValue(e, _("Enable even observing"), "2");
			e.addValue(e, _("Enable only in Race/CTS"), "3");
			e.configureXonoticTextSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("StrafeHUD mode:")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_strafehud_mode", "0", _("View angle centered")));
			me.TD(me, 1, 2.6/2, e = makeXonoticRadioButton(2, "hud_panel_strafehud_mode", "1", _("Velocity angle centered")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("StrafeHUD style:")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "0", _("No styling")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "1", _("Status bar")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(3, "hud_panel_strafehud_style", "2", _("Gradient")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Range:")));
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_strafehud_range"));
			e.addValue(e, _("Dynamic"), "0");
			for(i = 10; i <= 360; i += 10)
			{
				string i_str = strzone(itos(i));
				e.addValue(e, i_str, i_str);
			}
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.9, e = makeXonoticCheckBox(0, "_hud_panel_strafehud_demo", _("Demo mode")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticButton(_("Reset colors"), '0 0 0'));
			e.onClick = StrafeHUD_ColorReset;
			e.onClickEntity = me;
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
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_accel_alpha"));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.56666666, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_overturn_alpha"));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_angle_alpha"));
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
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticCheckBox(0, "hud_panel_strafehud_switch", _("Enable")));

		me.TDempty(me, 0.2);

		me.TD(me, 1, 0.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bestangle_alpha"));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticCheckBox(0, "hud_panel_strafehud_bestangle", _("Enable")));
}
