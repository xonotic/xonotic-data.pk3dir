// Author: Juhu

#include "compass.qh"

#include <client/draw.qh>
#include <client/view.qh>
#include <common/physics/player.qh>
#include <lib/csqcmodel/cl_player.qh>

// Compass (#26)

void HUD_Compass_Export(int fh)
{
    // allow saving cvars that aesthetically change the panel into hud skin files
}

// provide basic panel cvars to old clients
// TODO remove them after a future release (0.8.2+)
noref string autocvar_hud_panel_compass_pos = "0.290000 0.530000";
noref string autocvar_hud_panel_compass_size = "0.420000 0.030000";
noref string autocvar_hud_panel_compass_bg = "0";
noref string autocvar_hud_panel_compass_bg_color = "";
noref string autocvar_hud_panel_compass_bg_color_team = "";
noref string autocvar_hud_panel_compass_bg_alpha = "0.7";
noref string autocvar_hud_panel_compass_bg_border = "";
noref string autocvar_hud_panel_compass_bg_padding = "";

void HUD_Compass()
{
    // generic hud routines
    if(!autocvar__hud_configure)
    {
        if(!autocvar_hud_panel_compass ||
           (spectatee_status == -1 && (autocvar_hud_panel_compass == 1 || autocvar_hud_panel_compass == 3)) ||
           (autocvar_hud_panel_compass == 3 && !MUTATOR_CALLHOOK(HUD_Compass_showoptional))) return;
    }

    HUD_Panel_LoadCvars();

    if(autocvar_hud_panel_compass_dynamichud)
    {
        HUD_Scale_Enable();
    }
    else
    {
        HUD_Scale_Disable();
    }

    HUD_Panel_DrawBg();

    if(panel_bg_padding)
    {
        panel_pos  += '1 1 0' * panel_bg_padding;
        panel_size -= '2 2 0' * panel_bg_padding;
    }

    // draw compass
    if(csqcplayer)
    {
        // get the world axis
        float angle = !autocvar__hud_configure ? PHYS_INPUT_ANGLES(csqcplayer).y : 0;
        float move_angle = !autocvar__hud_configure ? vectoangles(csqcplayer.velocity).y : 0;
        float speed = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 320;
        vector line_size = panel_size;
        line_size.x = line_size.y = autocvar_hud_panel_compass_line_size * panel_size.y;
        if(angle < 0)
            angle += 360;

        // make the compass move opposite to the rotation direction
        if(!autocvar_v_flipped)
        {
            angle = 360 - angle;
            move_angle = 360 - move_angle;
        }

        // get the size of one quarter of the compass
        vector quarter_size = panel_size;
        quarter_size.x /= 4;

        // calculate how much the compass quarters differ from their 90° alignment
        float alignment_offset = angle % 90 / 90 * quarter_size.x;

        // draw the four compass quarters
        for(int i = 0; i < 4; ++i){
            float offset = quarter_size.x*i;
            vector color;

            // calculate an angle to determine which compass quarter to draw next
            float draw_angle = angle + 90*i;
            if(draw_angle >= 360)
                draw_angle -= 360;

            // chooses the color for each compass quarter
            if(draw_angle < 90)
                color = !autocvar_v_flipped ? autocvar_hud_panel_compass_south_color : autocvar_hud_panel_compass_east_color;
            else if(draw_angle < 180)
                color = !autocvar_v_flipped ? autocvar_hud_panel_compass_west_color : autocvar_hud_panel_compass_north_color;
            else if(draw_angle < 270)
                color = !autocvar_v_flipped ? autocvar_hud_panel_compass_north_color : autocvar_hud_panel_compass_west_color;
            else
                color = !autocvar_v_flipped ? autocvar_hud_panel_compass_east_color : autocvar_hud_panel_compass_south_color;

            // if the compass quarter doesn't wrap around just draw it all at once
            if(offset - alignment_offset >= 0)
            {
                // draw the compass quarter
                drawfill(panel_pos + eX * (offset - alignment_offset), quarter_size, color, autocvar_hud_panel_compass_quarter_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                // draw the orienting lines
                drawfill(panel_pos + eX * (offset - alignment_offset + quarter_size.x/2 - line_size.x/2) + eY * (panel_size.y - line_size.y), line_size, autocvar_hud_panel_compass_line_color, autocvar_hud_panel_compass_line_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
            // if it does wrap around draw each part seperately on both ends of the hud panel
            else
            {
                // draw the compass quarter
                drawfill(panel_pos, quarter_size - eX * alignment_offset, color, autocvar_hud_panel_compass_quarter_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                drawfill(panel_pos + eX * (panel_size.x - alignment_offset), quarter_size - eX * (quarter_size.x - alignment_offset), color, autocvar_hud_panel_compass_quarter_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                // draw the orienting lines
                if(angle % 90 <= 45)
                    drawfill(panel_pos + eX * (quarter_size.x/2 - alignment_offset - line_size.x/2) + eY * (panel_size.y - line_size.y), line_size, autocvar_hud_panel_compass_line_color, autocvar_hud_panel_compass_line_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                if(angle % 90 >= 45)
                    drawfill(panel_pos + eX * (panel_size.x - alignment_offset + quarter_size.x/2 - line_size.x/2) + eY * (panel_size.y - line_size.y), line_size, autocvar_hud_panel_compass_line_color, autocvar_hud_panel_compass_line_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }

        // if the player is moving show the velocity direction relative to the view direction
        if(speed > 0)
        {
            bool bkwd = false;
            float offset_angle = move_angle - angle;

            // wrap around overflows
            if(offset_angle <= -180)
                offset_angle += 360;
            if(offset_angle > 180)
                offset_angle -= 360;

            // shift the arrow by 180 degrees and flip it if looking backwards
            if(fabs(offset_angle) > 90)
            {
                bkwd = true;
                offset_angle += 180;
                if(offset_angle > 180)
                    offset_angle -= 360;
            }
            Compass_drawArrow(panel_pos + eX * (offset_angle / 360 * panel_size.x + panel_size.x/2) + eY * (panel_size.y), autocvar_hud_panel_compass_arrow_size * panel_size.y, (!autocvar__hud_configure && move_angle % 90 == 0 ? autocvar_hud_panel_compass_arrow_snap_color : autocvar_hud_panel_compass_arrow_color), autocvar_hud_panel_compass_arrow_alpha, bkwd);
        }
    }
}

// draw an arrow (inspired by drawspritearrow() in common/mutators/mutator/waypoints/waypointsprites.qc)
void Compass_drawArrow(vector origin, float size, vector color, float alpha, bool flipped)
{
    R_BeginPolygon("", DRAWFLAG_NORMAL, true);
    R_PolygonVertex(origin + (flipped ? size*eY : '0 0 0')          , '0 0 0', color, alpha);
    R_PolygonVertex(origin + (flipped ? '0 0 0' : size*eY) - size*eX, '0 0 0', color, alpha);
    R_PolygonVertex(origin + (flipped ? '0 0 0' : size*eY) + size*eX, '0 0 0', color, alpha);
    R_EndPolygon();
}

