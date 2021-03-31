#include "dialog_hudpanel_compass.qh"

#include "colorpicker_string.qh"
#include "button.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "textslider.qh"

void Compass_CenterPanel(entity btn, entity me)
{
    vector size = stov(str_cvar("hud_panel_compass_size"));
    vector pos = stov(str_cvar("hud_panel_compass_pos"));
    pos.x = 0.5 - size.x / 2;
    cvar_set("hud_panel_compass_pos", strcat(ftos(pos.x), " ", ftos(pos.y)));
}

void Compass_ColorReset(entity btn, entity me)
{
    cvar_set("hud_panel_compass_north_color", cvar_defstring("hud_panel_compass_north_color"));
    cvar_set("hud_panel_compass_east_color", cvar_defstring("hud_panel_compass_east_color"));
    cvar_set("hud_panel_compass_south_color", cvar_defstring("hud_panel_compass_south_color"));
    cvar_set("hud_panel_compass_west_color", cvar_defstring("hud_panel_compass_west_color"));
    cvar_set("hud_panel_compass_arrow_color", cvar_defstring("hud_panel_compass_arrow_color"));
    cvar_set("hud_panel_compass_arrow_snap_color", cvar_defstring("hud_panel_compass_arrow_snap_color"));
    cvar_set("hud_panel_compass_line_color", cvar_defstring("hud_panel_compass_line_color"));
}

void XonoticHUDCompassDialog_fill(entity me)
{
    entity e;
    string panelname = "compass";

    me.TR(me);
        me.TD(me, 1, 4, e = makeXonoticTextSlider("hud_panel_compass"));
            e.addValue(e, _("Disable"), "0");
            e.addValue(e, _("Enable"), "1");
            e.addValue(e, _("Enable even observing"), "2");
            e.addValue(e, _("Enable only in Race/CTS"), "3");
            e.configureXonoticTextSliderValues(e);

    dialog_hudpanel_main_settings(me, panelname);
    me.TR(me);

        me.TD(me, 1, 1.9, e = makeXonoticButton(_("Center panel"), '0 0 0'));
            e.onClick = Compass_CenterPanel;
            e.onClickEntity = me;
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticButton(_("Reset colors"), '0 0 0'));
            e.onClick = Compass_ColorReset;
            e.onClickEntity = me;
    me.TR(me);

        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("North:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("South:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("West:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("East:")));
    me.TR(me);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_compass_north_color", "hud_panel_compass_north_color"));
        me.TDempty(me, 0.2);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_compass_south_color", "hud_panel_compass_south_color"));
        me.TDempty(me, 0.2);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_compass_west_color", "hud_panel_compass_west_color"));
        me.TDempty(me, 0.2);
        me.TD(me, 2, 0.9, e = makeXonoticColorpickerString("hud_panel_compass_east_color", "hud_panel_compass_east_color"));
    me.TR(me);
    me.TR(me);
        me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Transparency:")));
    me.TR(me);
        me.TD(me, 1, 4, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_compass_quarter_alpha"));
    me.TR(me);

        me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Arrow:")));
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Normal:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Snap:")));
    me.TR(me);
        me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_compass_arrow_color", "hud_panel_compass_arrow_color"));
        me.TDempty(me, 0.2);
        me.TD(me, 2, 1.9, e = makeXonoticColorpickerString("hud_panel_compass_arrow_snap_color", "hud_panel_compass_arrow_snap_color"));
    me.TR(me);
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Transparency:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Size:")));
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_compass_arrow_alpha"));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticSlider(0.1, 0.75, 0.05, "hud_panel_compass_arrow_size"));
    me.TR(me);

        me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Orienting lines:")));
    me.TR(me);
        me.TD(me, 2, 4, e = makeXonoticColorpickerString("hud_panel_compass_line_color", "hud_panel_compass_line_color"));
    me.TR(me);
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Transparency:")));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticTextLabel(0, _("Size:")));
    me.TR(me);
        me.TD(me, 1, 1.9, e = makeXonoticSlider(0, 1, 0.1, "hud_panel_compass_line_alpha"));
        me.TDempty(me, 0.2);
        me.TD(me, 1, 1.9, e = makeXonoticSlider(0.1, 0.75, 0.05, "hud_panel_compass_line_size"));
}
