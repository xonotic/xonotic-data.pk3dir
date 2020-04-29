// Name:   StrafeHUD
// Author: Juhu

// FIXME: strafehud doesn't properly work in spectate due to lack of IS_ONGROUND()

#include "strafehud.qh"

#include <client/autocvars.qh>
#include <client/miscfunctions.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/trigger/swamp.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <lib/csqcmodel/cl_player.qh>

bool strafehud_fwd = true;
float strafehud_demo_angle = -37;
float strafehud_demo_direction = 1;
float strafehud_demo_time = 0;
float strafehud_state_onground_time = 0;
float strafehud_state_strafekeys_time = 0;
bool strafehud_state_onground = true;
bool strafehud_state_strafekeys = false;
bool strafehud_turn = false;
float strafehud_turnangle;

void HUD_StrafeHUD()
{
    entity strafeplayer;

    if(!autocvar__hud_configure)
    {
        if(!autocvar_hud_panel_strafehud) return;
        if(spectatee_status == -1 && (autocvar_hud_panel_strafehud == 1 || autocvar_hud_panel_strafehud == 3)) return;
        if(autocvar_hud_panel_strafehud == 3 && !(ISGAMETYPE(RACE) || ISGAMETYPE(CTS))) return;
    }

    HUD_Panel_LoadCvars();

    draw_beginBoldFont();

    if (autocvar_hud_panel_strafehud_dynamichud)
        HUD_Scale_Enable();
    else
        HUD_Scale_Disable();
    HUD_Panel_DrawBg();
    if(panel_bg_padding)
    {
        panel_pos  += '1 1 0' * panel_bg_padding;
        panel_size -= '2 2 0' * panel_bg_padding;
    }

    if(spectatee_status > 0)
    {
        strafeplayer = CSQCModel_server2csqc(player_localentnum - 1);
    }
    else
    {
        strafeplayer = csqcplayer;
    }

    // draw strafehud
    if(csqcplayer && strafeplayer)
    {
        // autocvars
        float strafehud_bar_alpha                 = autocvar_hud_panel_strafehud_bar_alpha_default
                                                  ? .2
                                                  : autocvar_hud_panel_strafehud_bar_alpha;
        vector strafehud_bar_color                = autocvar_hud_panel_strafehud_bar_color_default
                                                  ? '1 1 1'
                                                  : autocvar_hud_panel_strafehud_bar_color;
        vector strafehud_bestangle_color          = autocvar_hud_panel_strafehud_indicator_color_default
                                                  ? '0 1 0'
                                                  : autocvar_hud_panel_strafehud_indicator_color;
        vector strafehud_bestangle_opposite_color = autocvar_hud_panel_strafehud_indicator_color_default
                                                  ? '1 1 0'
                                                  : autocvar_hud_panel_strafehud_indicator_switch_color;
        vector strafehud_good_color               = autocvar_hud_panel_strafehud_angle_color_default
                                                  ? '0 1 1'
                                                  : autocvar_hud_panel_strafehud_good_color;
        vector strafehud_warning_color            = autocvar_hud_panel_strafehud_angle_color_default
                                                  ? '1 1 0'
                                                  : autocvar_hud_panel_strafehud_warning_color;
        vector strafehud_alert_color              = autocvar_hud_panel_strafehud_angle_color_default
                                                  ? '1 0 1'
                                                  : autocvar_hud_panel_strafehud_alert_color;
        vector strafehud_direction_color          = autocvar_hud_panel_strafehud_direction_color_default
                                                  ? '.5 .25 1'
                                                  : autocvar_hud_panel_strafehud_direction_color;
        float strafehud_timeout_air               = autocvar_hud_panel_strafehud_timeout_air_default // timeout for slick ramps
                                                  ? 0
                                                  : autocvar_hud_panel_strafehud_timeout_air;
        float strafehud_timeout_ground            = autocvar_hud_panel_strafehud_timeout_ground_default // timeout for strafe jumping in general
                                                  ? .03333333
                                                  : autocvar_hud_panel_strafehud_timeout_ground;
        float strafehud_timeout_strafe            = autocvar_hud_panel_strafehud_timeout_strafe_default // timeout for jumping with strafe keys only
                                                  ? .1
                                                  : autocvar_hud_panel_strafehud_timeout_strafe;
        float strafehud_indicator_minspeed        = autocvar_hud_panel_strafehud_indicator_minspeed;

        // physics
        float  strafehud_onground                 = IS_ONGROUND(strafeplayer);
        float  strafehud_speed                    = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337; // use local csqcmodel entity for this even when spectating, flickers too much otherwise
        float  strafehud_maxspeed_crouch_mod      = IS_DUCKED(strafeplayer) ? .5 : 1;
        float  strafehud_maxspeed_swamp_mod       = strafeplayer.in_swamp ? strafeplayer.swamp_slowdown : 1;
        float  strafehud_maxspeed_phys            = strafehud_onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  strafehud_maxspeed                 = !autocvar__hud_configure ? (strafehud_maxspeed_phys * strafehud_maxspeed_crouch_mod * strafehud_maxspeed_swamp_mod) : 320;
        float  strafehud_vel_angle                = vectoangles(strafeplayer.velocity).y;
        float  strafehud_view_angle               = view_angles.y + 180;
        float  strafehud_angle;
        float  strafehud_direction;
        vector strafehud_movement                 = PHYS_INPUT_MOVEVALUES(strafeplayer);
        int    strafehud_keys                     = STAT(PRESSED_KEYS);
        float  strafehud_wishangle;
        float  strafehud_shiftangle;
        float  strafehud_moveangle;

        // HUD
        float  strafehud_hudangle;
        vector strafehud_currentangle_color       = strafehud_warning_color;
        vector strafehud_currentangle_size        = '0 0 0';
        float  strafehud_currentangle_offset;
        vector strafehud_bestangle_size           = '0 0 0';
        bool   strafehud_bestangle_visible        = true;
        float  strafehud_bestangle                = 0;
        float  strafehud_bestangle_offset;
        float  strafehud_accelzone_offset;
        vector strafehud_accelzone_size;
        float  strafehud_overturn_offset;
        vector strafehud_overturn_size;
        float  strafehud_mirror_overturn_offset;
        vector strafehud_mirror_overturn_size;
        vector strafehud_direction_size_1         = '0 0 0';
        vector strafehud_direction_size_2         = '0 0 0';

        strafehud_indicator_minspeed = strafehud_indicator_minspeed < 0 ? strafehud_maxspeed + .1 : strafehud_indicator_minspeed;

        // determine whether the player is strafing forwards or backwards
        if(strafeplayer == csqcplayer) // if entity is local player
        {
            if(strafehud_movement_x > 0)
            {
                strafehud_fwd = true;
            }
            else if(strafehud_movement_x < 0)
            {
                strafehud_fwd = false;
            }
        }
        else // alternatively determine direction by querying pressed keys
        {
            if((strafehud_keys & KEY_FORWARD) && !(strafehud_keys & KEY_BACKWARD))
            {
                strafehud_fwd = true;
            }
            else if(!(strafehud_keys & KEY_FORWARD) && (strafehud_keys & KEY_BACKWARD))
            {
                strafehud_fwd = false;
            }
        }

        // determine player wishdir
        if(strafeplayer == csqcplayer) // if entity is local player
        {
            if(strafehud_movement_x == 0)
            {
                if(strafehud_movement_y < 0)
                {
                    strafehud_wishangle = -90;
                }
                else if(strafehud_movement_y > 0)
                {
                    strafehud_wishangle = 90;
                }
                else
                {
                    strafehud_wishangle = 0;
                }
            }
            else
            {
                if(strafehud_movement_y == 0)
                {
                    strafehud_wishangle = 0;
                }
                else
                {
                    strafehud_wishangle = RAD2DEG * atan2(strafehud_movement_y, strafehud_movement_x);
                }
            }
        }
        else // alternatively calculate wishdir by querying pressed keys
        {
            if(strafehud_keys & KEY_FORWARD)
            {
                strafehud_wishangle = 45;
            }
            else if(strafehud_keys & KEY_BACKWARD)
            {
                strafehud_wishangle = 135;
            }
            else
            {
                strafehud_wishangle = 90;
            }
            if(strafehud_keys & KEY_LEFT)
            {
                strafehud_wishangle *= -1;
            }
            else if(!(strafehud_keys & KEY_RIGHT))
            {
                strafehud_wishangle = 0;
            }
        }

        // determine how much the angle shifts in the hud
        strafehud_shiftangle = fabs(remainder(strafehud_wishangle, 90));
        if(strafehud_shiftangle > 45)
        {
            strafehud_shiftangle = 45 - fabs(remainder(strafehud_wishangle, 45));
        }
        strafehud_shiftangle = 90 - strafehud_shiftangle;

        if(autocvar_hud_panel_strafehud_angle == 0)
        {
            if(autocvar__hud_configure)
            {
                strafehud_hudangle = 45;
            }
            else
            {
                strafehud_hudangle = strafehud_shiftangle;
            }
        }
        else
        {
            strafehud_hudangle = bound(1, fabs(autocvar_hud_panel_strafehud_angle), 360) / 2; // sanity check this cvar for now
        }

        // detecting strafe turning
        if(!autocvar__hud_configure)
        {
            if(strafehud_onground != strafehud_state_onground)
            {
                strafehud_state_onground_time = time;
            }
            strafehud_state_onground = strafehud_onground;
            if((fabs(strafehud_wishangle) == 90) != strafehud_state_strafekeys)
            {
                strafehud_state_strafekeys_time = time;
            }
            strafehud_state_strafekeys = fabs(strafehud_wishangle) == 90;
            if((strafehud_keys & KEY_FORWARD) || (strafehud_keys & KEY_BACKWARD))
            {
                strafehud_turn = false;
            }
            else if(strafehud_onground)
            {
                if((time - strafehud_state_onground_time) >= strafehud_timeout_ground)
                {
                    strafehud_turn = false;
                }
            }
            else // air strafe only
            {
                if(fabs(strafehud_wishangle) == 90)
                {
                    if((time - strafehud_state_onground_time) >= strafehud_timeout_air)
                    {
                        strafehud_turn = true; // CPMA turning
                        strafehud_turnangle = strafehud_wishangle;
                    }
                }
                else if((time - strafehud_state_strafekeys_time) >= strafehud_timeout_strafe)
                {
                    strafehud_turn = false;
                }
            }
            if(strafehud_turn)
            {
                strafehud_maxspeed = PHYS_MAXAIRSTRAFESPEED(strafeplayer) * strafehud_maxspeed_swamp_mod; // no crouching here because it doesn't affect air strafing
                strafehud_wishangle = strafehud_turnangle;
            }
        }

        // add a background to the strafe-o-meter
        HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, strafehud_bar_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);

        // get current strafing angle ranging from -180° to +180°
        if(!autocvar__hud_configure)
        {
            if(!strafehud_fwd) strafehud_wishangle += strafehud_wishangle < 0 ? 180 : strafehud_wishangle > 0 ? -180 : 0;
            if(strafehud_speed > 0)
            {
                if(!strafehud_fwd) strafehud_view_angle += strafehud_view_angle < 0 ? 180 : strafehud_view_angle > 0 ? -180 : 0;
                strafehud_angle = strafehud_view_angle - strafehud_vel_angle;

                if     (strafehud_angle >  180) strafehud_angle = -360 + strafehud_angle;
                else if(strafehud_angle < -180) strafehud_angle =  360 + strafehud_angle;

                strafehud_angle = 180 - strafehud_angle;
                if(strafehud_angle > 180)
                {
                    strafehud_angle = -fabs(360 - strafehud_angle);
                }

                // making the hud less flickery in case of rounding errors
                if(strafehud_angle > 179.9 || strafehud_angle < -179.9)
                {
                    strafehud_currentangle_color = strafehud_alert_color;
                    strafehud_angle = 0;
                }
                if(strafehud_angle < .1 && strafehud_angle > -.1)
                {
                    strafehud_angle = 0;
                }
            }
            else
            {
                strafehud_angle = 0;
            }
        }
        else // simulate turning for HUD setup
        {
            if(autocvar__hud_panel_strafehud_demo && ((time - strafehud_demo_time) >= .025))
            {
                strafehud_demo_time = time;
                strafehud_demo_angle += 1 * strafehud_demo_direction;
                if(fabs(strafehud_demo_angle) >= 55)
                {
                    strafehud_demo_direction = -strafehud_demo_direction;
                }
            }
            strafehud_angle = strafehud_demo_angle;
            strafehud_wishangle = 45 * (strafehud_demo_angle > 0 ? 1 : -1);
        }

        if (autocvar_v_flipped)
        {
            strafehud_angle = -strafehud_angle;
            strafehud_wishangle = -strafehud_wishangle;
        }

        strafehud_moveangle = strafehud_angle + strafehud_wishangle;

        if(strafehud_wishangle != 0)
        {
            strafehud_direction = strafehud_wishangle > 0 ? 1 : -1;
        }
        else
        {
            strafehud_direction = strafehud_moveangle > 0 ? 1 : strafehud_moveangle < 0 ? -1 : 0;
        }

        switch(autocvar_hud_panel_strafehud_mode)
        {
            default:
            case 0: // view centered

            // mark the ideal strafe angle
            if(strafehud_speed >= strafehud_indicator_minspeed)
            {
                strafehud_bestangle_size.x = floor(panel_size.x * .01 + .5);
                strafehud_bestangle_size.y = floor(panel_size.y + .5);
                if (strafehud_direction != 0)
                {
                    strafehud_bestangle = (strafehud_speed > strafehud_maxspeed ? acos(strafehud_maxspeed / strafehud_speed) : 0) * RAD2DEG * strafehud_direction - strafehud_wishangle;
                    if (fabs(strafehud_bestangle) <= strafehud_hudangle)
                    {
                        float strafehud_maxangle = 90 - fabs(strafehud_wishangle);
                        strafehud_bestangle_offset = floor(strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
                        strafehud_accelzone_offset = strafehud_direction < 0 ? 0 : strafehud_bestangle_offset + strafehud_bestangle_size.x;
                        strafehud_accelzone_size = panel_size;
                        strafehud_accelzone_size.x = strafehud_direction < 0 ? strafehud_bestangle_offset : panel_size.x - strafehud_accelzone_offset;
                        if(strafehud_hudangle > strafehud_maxangle)
                        {
                            float strafehud_mirrorangle = 90 - strafehud_shiftangle - (180 - strafehud_hudangle);
                            strafehud_overturn_size = strafehud_mirror_overturn_size = panel_size;
                            strafehud_overturn_size.x = floor((panel_size.x * (strafehud_hudangle - strafehud_maxangle) / strafehud_hudangle) / 2 + .5);
                            strafehud_mirror_overturn_size.x = panel_size.x * strafehud_mirrorangle / 360;
                            if(strafehud_direction < 0)
                            {
                                strafehud_overturn_offset = 0;
                                strafehud_accelzone_offset += strafehud_overturn_size.x;
                                strafehud_accelzone_size.x -= strafehud_overturn_size.x;
                                strafehud_mirror_overturn_offset = panel_size.x - strafehud_mirror_overturn_size.x;
                            }
                            else
                            {
                                strafehud_overturn_offset = panel_size.x - strafehud_overturn_size.x;
                                strafehud_accelzone_size.x -= strafehud_overturn_size.x;
                                strafehud_mirror_overturn_offset = 0;
                            }
                            HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_overturn_offset, strafehud_overturn_size, "progressbar", 1, 0, 0, strafehud_alert_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                            if(strafehud_mirrorangle > 0)
                            {
                                HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_mirror_overturn_offset, strafehud_mirror_overturn_size, "progressbar", 1, 0, 0, strafehud_alert_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                            }
                        }
                        HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_accelzone_offset, strafehud_accelzone_size, "progressbar", 1, 0, 0, strafehud_bestangle_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        strafehud_bestangle_offset = floor(-strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
                        drawfill(panel_pos + eX * (strafehud_bestangle_offset - (-strafehud_direction < 0 ? strafehud_bestangle_size.x : 0)), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                        strafehud_bestangle_offset = floor(strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
                        drawfill(panel_pos + eX * (strafehud_bestangle_offset - (strafehud_direction < 0 ? strafehud_bestangle_size.x : 0)), strafehud_bestangle_size, strafehud_bestangle_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    }
                    strafehud_direction_size_1.x = floor(panel_size.x * .0075 + .5);
                    strafehud_direction_size_1.y = panel_size.y;
                    strafehud_direction_size_2.x = floor(strafehud_direction_size_1.x * 3 + .5);
                    strafehud_direction_size_2.y = strafehud_direction_size_1.x;
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_1.x : panel_size.x), strafehud_direction_size_1, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_1.x : panel_size.x - strafehud_direction_size_2.x + strafehud_direction_size_1.x) - eY * strafehud_direction_size_2.y, strafehud_direction_size_2, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_1.x : panel_size.x - strafehud_direction_size_2.x + strafehud_direction_size_1.x) + eY * panel_size.y, strafehud_direction_size_2, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                else
                {
                    strafehud_bestangle = (strafehud_speed > strafehud_maxspeed ? acos(strafehud_maxspeed / strafehud_speed) : 0) * RAD2DEG;
                    if (fabs(strafehud_bestangle) <= strafehud_hudangle)
                    {
                        strafehud_bestangle_offset = floor(-strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
                        drawfill(panel_pos + eX * (strafehud_bestangle_offset - strafehud_bestangle_size.x), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                        strafehud_bestangle_offset = floor(strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
                        drawfill(panel_pos + eX * (strafehud_bestangle_offset), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    }
                }
            }
            else
            {
                strafehud_bestangle_visible = false;
            }

            // draw the actual strafe angle
            if (strafehud_bestangle_visible)
            {
                if ((strafehud_direction > 0 && strafehud_angle >= strafehud_bestangle) ||
                    (strafehud_direction < 0 && strafehud_angle <= strafehud_bestangle))
                strafehud_currentangle_color = strafehud_good_color;
            }

            if (fabs(strafehud_moveangle) > 89.9)
            {
                strafehud_currentangle_color = strafehud_alert_color;
            }

            if (strafehud_speed <= (strafehud_maxspeed + .1) && strafehud_currentangle_color != strafehud_alert_color)
            {
                strafehud_currentangle_color = strafehud_good_color;
            }

            strafehud_currentangle_offset = floor(bound(-strafehud_hudangle, strafehud_angle, strafehud_hudangle)/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);

            strafehud_currentangle_size.x = floor(panel_size.x * .005 + .5);
            strafehud_currentangle_size.y = floor(panel_size.y * 1.5 + .5);
            drawfill(panel_pos - '0 1 0'*floor(panel_size.y * .25 + .5) + eX * (strafehud_currentangle_offset - strafehud_currentangle_size.x/2), strafehud_currentangle_size, strafehud_currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            break;
            case 1: // angle centered
                // TODO: implement angle centered strafehud
        }
    }
    draw_endBoldFont();
}
