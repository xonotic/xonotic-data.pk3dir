#include "dialog_hudpanel_strafehud.qh"

#include "checkbox_string.qh"
#include "colorpicker_string.qh"
#include "button.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "textslider.qh"

void StrafeHUD_ColorReset(entity btn, entity me)
{
    cvar_set("hud_panel_strafehud_bar_color", cvar_defstring("hud_panel_strafehud_bar_color"));
    cvar_set("hud_panel_strafehud_good_color", cvar_defstring("hud_panel_strafehud_good_color"));
    cvar_set("hud_panel_strafehud_warning_color", cvar_defstring("hud_panel_strafehud_warning_color"));
    cvar_set("hud_panel_strafehud_alert_color", cvar_defstring("hud_panel_strafehud_alert_color"));
    cvar_set("hud_panel_strafehud_direction_color", cvar_defstring("hud_panel_strafehud_direction_color"));
    cvar_set("hud_panel_strafehud_indicator_color", cvar_defstring("hud_panel_strafehud_indicator_color"));
    cvar_set("hud_panel_strafehud_indicator_switch_color", cvar_defstring("hud_panel_strafehud_indicator_switch_color"));
}

void XonoticHUDStrafeHUDDialog_fill(entity me)
{
    entity e;
    string panelname = "strafehud";

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

        me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_strafehud_mode"));
            e.addValue(e, _("View centered"), "0");
            e.addValue(e, _("Angle centered"), "1");
            e.configureXonoticTextSliderValues(e);
    me.TR(me);
        me.TD(me, 1, 1.2, e = makeXonoticCheckBoxString("1", "0", "_hud_panel_strafehud_demo", _("Demo mode")));
            setDependentStringNotEqual(e, "_hud_panel_strafehud_center", "1");

        me.TDempty(me, 0.4);
        me.TD(me, 1, 0.6, e = makeXonoticTextLabel(0, _("Range:")));
        me.TD(me, 1, 1.8, e = makeXonoticSlider(0, 360, 5, "hud_panel_strafehud_angle"));
    me.TR(me);
        me.TD(me, 1, 1.2, e = makeXonoticCheckBoxString("1", "0", "_hud_panel_strafehud_center", _("Center angle")));

        me.TDempty(me, 0.4);
        me.TD(me, 1, 2.4, e = makeXonoticButton(_("Reset colors"), '0 0 0'));
            e.onClick = StrafeHUD_ColorReset;
            e.onClickEntity = me;
    me.TR(me);
        me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Strafe bar:")));

        me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Current angle:")));
    me.TR(me);
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Color:")));
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Alpha:")));

        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Good:")));
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Neutral:")));
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.56666666, e = makeXonoticTextLabel(0, _("Overturn:")));
    me.TR(me);
        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_strafehud_bar_color", "hud_panel_strafehud_bar_color"));
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_bar_alpha"));

        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_good_color", "hud_panel_strafehud_good_color"));
        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_warning_color", "hud_panel_strafehud_warning_color"));
        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.56666666, e = makeXonoticColorpickerString("hud_panel_strafehud_alert_color", "hud_panel_strafehud_alert_color"));
    me.TR(me);
    me.TR(me);
        me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Ideal angle:")));

        me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Direction marker:")));
    me.TR(me);
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Active:")));
        me.TDempty(me, 0.1);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Inactive:")));
    me.TR(me);
        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_strafehud_indicator_color", "hud_panel_strafehud_indicator_color"));
        me.TDempty(me, 0.1);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_strafehud_indicator_switch_color", "hud_panel_strafehud_indicator_switch_color"));

        me.TDempty(me, 0.1);
        me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_strafehud_direction_color", "hud_panel_strafehud_direction_color"));
}
