#include "dialog_hudpanel_strafehud.qh"

#include "checkbox_string.qh"
#include "colorpicker_string.qh"
#include "button.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "textslider.qh"

void StrafeHUD_CenterPanel(entity btn, entity me)
{
    vector size = stov(str_cvar("hud_panel_strafehud_size"));
    vector pos = stov(str_cvar("hud_panel_strafehud_pos"));
    pos.x = 0.5 - size.x / 2;
    cvar_set("hud_panel_strafehud_pos", strcat(ftos(pos.x), " ", ftos(pos.y)));
}

void StrafeHUD_ColorReset(entity btn, entity me)
{
    cvar_set("hud_panel_strafehud_bar_accel_color", cvar_defstring("hud_panel_strafehud_bar_accel_color"));
    cvar_set("hud_panel_strafehud_bar_neutral_color", cvar_defstring("hud_panel_strafehud_bar_neutral_color"));
    cvar_set("hud_panel_strafehud_bar_overturn_color", cvar_defstring("hud_panel_strafehud_bar_overturn_color"));
    cvar_set("hud_panel_strafehud_angle_accel_color", cvar_defstring("hud_panel_strafehud_angle_accel_color"));
    cvar_set("hud_panel_strafehud_angle_neutral_color", cvar_defstring("hud_panel_strafehud_angle_neutral_color"));
    cvar_set("hud_panel_strafehud_angle_overturn_color", cvar_defstring("hud_panel_strafehud_angle_overturn_color"));
    cvar_set("hud_panel_strafehud_switch_color", cvar_defstring("hud_panel_strafehud_switch_color"));
    cvar_set("hud_panel_strafehud_direction_color", cvar_defstring("hud_panel_strafehud_direction_color"));
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
            e.addValue(e, _("View angle centered"), "0");
            e.addValue(e, _("Velocity angle centered"), "1");
            e.configureXonoticTextSliderValues(e);
    me.TR(me);
        me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("StrafeHUD style:")));

        me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_strafehud_style"));
            e.addValue(e, _("no styling"), "0");
            e.addValue(e, _("progress bar"), "1");
            e.addValue(e, _("gradient"), "2");
            e.configureXonoticTextSliderValues(e);
    me.TR(me);
        me.TD(me, 1, 1.2, e = makeXonoticCheckBoxString("1", "0", "_hud_panel_strafehud_demo", _("Demo mode")));

        me.TDempty(me, 0.4);

        me.TD(me, 1, 0.6, e = makeXonoticTextLabel(0, _("Range:")));
        me.TD(me, 1, 1.8, e = makeXonoticSlider(0, 360, 5, "hud_panel_strafehud_range"));
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticButton(_("Center panel"), '0 0 0'));
            e.onClick = StrafeHUD_CenterPanel;
            e.onClickEntity = me;

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
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Switch indicators:")));

        me.TDempty(me, 0.2);

        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Direction caps:")));
    me.TR(me);
        me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_strafehud_switch_color", "hud_panel_strafehud_switch_color"));

        me.TDempty(me, 0.2);

        me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_strafehud_direction_color", "hud_panel_strafehud_direction_color"));
    me.TR(me);
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_switch_alpha"));

        me.TDempty(me, 0.2);

        me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_strafehud_direction_alpha"));
}
