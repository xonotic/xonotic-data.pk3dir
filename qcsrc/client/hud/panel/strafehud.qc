// Name:   StrafeHUD
// Author: Juhu

#include "strafehud.qh"

#include <client/autocvars.qh>
#include <client/miscfunctions.qh>
#include <common/animdecide.qh>
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
        float strafehud_bar_alpha                  = autocvar_hud_panel_strafehud_bar_alpha;
        vector strafehud_bar_color                 = autocvar_hud_panel_strafehud_bar_color;
        vector strafehud_bestangle_color           = autocvar_hud_panel_strafehud_indicator_color;
        vector strafehud_bestangle_opposite_color  = autocvar_hud_panel_strafehud_indicator_switch_color;
        vector strafehud_good_color                = autocvar_hud_panel_strafehud_good_color;
        vector strafehud_warning_color             = autocvar_hud_panel_strafehud_warning_color;
        vector strafehud_alert_color               = autocvar_hud_panel_strafehud_alert_color;
        vector strafehud_direction_color           = autocvar_hud_panel_strafehud_direction_color;
        float strafehud_timeout_air                = autocvar_hud_panel_strafehud_timeout_air;    // timeout for slick ramps
        float strafehud_timeout_ground             = autocvar_hud_panel_strafehud_timeout_ground; // timeout for strafe jumping in general
        float strafehud_timeout_strafe             = autocvar_hud_panel_strafehud_timeout_strafe; // timeout for jumping with strafe keys only
        float strafehud_indicator_minspeed         = autocvar_hud_panel_strafehud_indicator_minspeed;

        // physics
        float  strafehud_onground                  = strafeplayer == csqcplayer ? IS_ONGROUND(strafeplayer) : !(strafeplayer.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
        float  strafehud_speed                     = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337; // use local csqcmodel entity for this even when spectating, flickers too much otherwise
        float  strafehud_maxspeed_crouch_mod       = IS_DUCKED(strafeplayer) ? .5 : 1;
        float  strafehud_maxspeed_swamp_mod        = strafeplayer.in_swamp ? strafeplayer.swamp_slowdown : 1;
        float  strafehud_maxspeed_phys             = strafehud_onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  strafehud_maxspeed                  = !autocvar__hud_configure ? (strafehud_maxspeed_phys * strafehud_maxspeed_crouch_mod * strafehud_maxspeed_swamp_mod) : 320;
        float  strafehud_vel_angle                 = vectoangles(strafeplayer.velocity).y;
        float  strafehud_view_angle                = view_angles.y + 180;
        float  strafehud_angle;
        float  strafehud_direction;
        vector strafehud_movement                  = PHYS_INPUT_MOVEVALUES(strafeplayer);
        int    strafehud_keys                      = STAT(PRESSED_KEYS);
        float  strafehud_wishangle;
        float  strafehud_moveangle;

        // HUD
        float  strafehud_hudangle;
        vector strafehud_currentangle_color        = strafehud_warning_color;
        vector strafehud_currentangle_size         = '0 0 0';
        float  strafehud_currentangle_offset;
        vector strafehud_bestangle_size            = '0 0 0';
        bool   strafehud_bestangle_anywhere        = false;
        float  strafehud_bestangle                 = 0;
        float  strafehud_bestangle_offset;
        float  strafehud_bestangle_opposite_offset;
        float  strafehud_accelzone_offset;
        vector strafehud_accelzone_size            = panel_size;
        float  strafehud_overturn_offset;
        vector strafehud_overturn_size             = panel_size;
        float  strafehud_mirrorangle;
        float  strafehud_mirror_overturn_offset;
        vector strafehud_mirror_overturn_size      = panel_size;
        vector strafehud_direction_size_vertical   = '0 0 0';
        vector strafehud_direction_size_horizontal = '0 0 0';
        float  strafehud_maxangle;
        float  strafehud_range_minangle;

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

        // determine minimum required angle to display full strafe range
        strafehud_range_minangle = fabs(strafehud_wishangle) % 90; // maximum range is 90 degree
        if(strafehud_range_minangle > 45) // minimum angle range is 45
        {
            strafehud_range_minangle = 45 - fabs(strafehud_wishangle) % 45;
        }
        strafehud_range_minangle = 90 - strafehud_range_minangle; // calculate value which is never >90 or <45

        if(autocvar_hud_panel_strafehud_angle == 0)
        {
            if(autocvar__hud_configure)
            {
                strafehud_hudangle = 45;
            }
            else
            {
                strafehud_hudangle = strafehud_range_minangle; // use minimum angle required if dynamically setting hud angle
            }
        }
        else
        {
            strafehud_hudangle = bound(1, fabs(autocvar_hud_panel_strafehud_angle), 360) / 2; // limit HUD range to 360 degrees, higher values don't make sense and break the code
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

        strafehud_indicator_minspeed = strafehud_indicator_minspeed < 0 ? strafehud_maxspeed + .1 : strafehud_indicator_minspeed;

        // add a background to the strafe-o-meter
        if(panel_size.x != 0 && panel_size.y != 0)
        {
            HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, strafehud_bar_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
        }

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

        // decelerating at this angle
        strafehud_maxangle = 90 - fabs(strafehud_wishangle);
        // best angle to strafe at
        strafehud_bestangle = (strafehud_speed > strafehud_maxspeed ? acos(strafehud_maxspeed / strafehud_speed) : 0) * RAD2DEG * (strafehud_direction < 0 ? -1 : 1) - strafehud_wishangle;
        // various offsets and size calculations of hud indicators elements
        // best strafe acceleration angle
        strafehud_bestangle_offset          = floor( strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
        strafehud_bestangle_opposite_offset = floor(-strafehud_bestangle/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
        strafehud_bestangle_size.x = floor(panel_size.x * .01 + .5);
        strafehud_bestangle_size.y = panel_size.y;
        // current angle
        strafehud_currentangle_offset = floor(bound(-strafehud_hudangle, strafehud_angle, strafehud_hudangle)/strafehud_hudangle * panel_size.x/2 + panel_size.x/2 + .5);
        strafehud_currentangle_size.x = floor(panel_size.x * .005 + .5);
        strafehud_currentangle_size.y = floor(panel_size.y * 1.5 + .5);
        // direction indicator
        strafehud_direction_size_vertical.x = floor(panel_size.x * .0075 + .5);
        strafehud_direction_size_vertical.y = panel_size.y;
        strafehud_direction_size_horizontal.x = floor(strafehud_direction_size_vertical.x * 3 + .5);
        strafehud_direction_size_horizontal.y = strafehud_direction_size_vertical.x;
        // overturn
        strafehud_mirrorangle = strafehud_maxangle + strafehud_hudangle - 180; // how many degrees of overturn area are on the opposite side of the hud
        strafehud_overturn_size.x = floor((panel_size.x * (strafehud_hudangle - strafehud_maxangle) / strafehud_hudangle) / 2 + .5);
        strafehud_mirror_overturn_size.x = floor(panel_size.x * strafehud_mirrorangle / (strafehud_hudangle * 2) + .5);

        // mark the ideal strafe angle
        if(strafehud_speed >= strafehud_indicator_minspeed) // draw indicators if strafing is required to gain speed
        {
            if (fabs(strafehud_bestangle) <= strafehud_hudangle) // don't draw angle indicator and acceleration zones if outside of hud range
            {
                if (strafehud_direction != 0) // only draw acceleration zones if strafe direction can be determined
                {
                    // calculate zone in which strafe acceleration happens
                    if(strafehud_direction < 0) // moving left
                    {
                        strafehud_accelzone_offset = 0;
                        strafehud_accelzone_size.x = strafehud_bestangle_offset;
                    }
                    else // moving right
                    {
                        strafehud_accelzone_offset = strafehud_bestangle_offset + strafehud_bestangle_size.x;
                        strafehud_accelzone_size.x = panel_size.x - strafehud_accelzone_offset;
                    }

                    if(strafehud_hudangle > strafehud_maxangle) // draw overturn area and move acceleration zone
                    {
                        if(strafehud_direction < 0) // moving left
                        {
                            // calculate offset of overturn area
                            strafehud_overturn_offset = 0;
                            // move/adjust acceleration zone
                            strafehud_accelzone_offset += strafehud_overturn_size.x;
                            strafehud_accelzone_size.x -= strafehud_overturn_size.x;
                            // calculate the remainder of the overturn zone on the opposite side
                            strafehud_mirror_overturn_offset = panel_size.x - strafehud_mirror_overturn_size.x;
                        }
                        else // moving right
                        {
                            // calculate offset of overturn area
                            strafehud_overturn_offset = panel_size.x - strafehud_overturn_size.x;
                            // adjust acceleration zone
                            strafehud_accelzone_size.x -= strafehud_overturn_size.x;
                            // calculate the remainder of the overturn zone on the opposite side
                            strafehud_mirror_overturn_offset = 0;
                        }
                        // draw overturn area
                        if(strafehud_overturn_size.x != 0 && strafehud_overturn_size.y != 0)
                        {
                            HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_overturn_offset, strafehud_overturn_size, "progressbar", 1, 0, 0, strafehud_alert_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        }
                        // draw remaining overturn area on the opposite side if there is any (180 degree in total)
                        if(strafehud_mirrorangle > 0 && strafehud_mirror_overturn_size.x != 0 && strafehud_mirror_overturn_size.y != 0)
                        {
                            HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_mirror_overturn_offset, strafehud_mirror_overturn_size, "progressbar", 1, 0, 0, strafehud_alert_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        }
                    }

                    // draw acceleration zone
                    if(strafehud_accelzone_size.x != 0 && strafehud_accelzone_size.y != 0)
                    {
                        HUD_Panel_DrawProgressBar(panel_pos + eX * strafehud_accelzone_offset, strafehud_accelzone_size, "progressbar", 1, 0, 0, strafehud_bestangle_color, strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    }

                    // draw the direction indicator caps at the sides of the hud
                    // vertical line
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_vertical.x : panel_size.x), strafehud_direction_size_vertical, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    // top horizontal line
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_vertical.x : panel_size.x - strafehud_direction_size_horizontal.x + strafehud_direction_size_vertical.x) - eY * strafehud_direction_size_horizontal.y, strafehud_direction_size_horizontal, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    // bottom horizontal line
                    drawfill(panel_pos + eX * (strafehud_direction < 0 ? -strafehud_direction_size_vertical.x : panel_size.x - strafehud_direction_size_horizontal.x + strafehud_direction_size_vertical.x) + eY * panel_size.y, strafehud_direction_size_horizontal, strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);

                    // draw opposite best strafe angle
                    drawfill(panel_pos + eX * (strafehud_bestangle_opposite_offset - (-strafehud_direction < 0 ? strafehud_bestangle_size.x : 0)), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    // draw current best strafe angle
                    drawfill(panel_pos + eX * (strafehud_bestangle_offset - (strafehud_direction < 0 ? strafehud_bestangle_size.x : 0)), strafehud_bestangle_size, strafehud_bestangle_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                else
                {
                    // draw best angles for acceleration
                    drawfill(panel_pos + eX * (strafehud_bestangle_opposite_offset - strafehud_bestangle_size.x), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos + eX * (strafehud_bestangle_offset), strafehud_bestangle_size, strafehud_bestangle_opposite_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                }
            }
        }
        else
        {
            strafehud_bestangle_anywhere = true; // no indicators, moving forward should suffice to gain speed
        }

        // draw the actual strafe angle
        if (!strafehud_bestangle_anywhere) // player gains speed with strafing
        {
            if ((strafehud_direction > 0 && strafehud_angle >= strafehud_bestangle) ||
                (strafehud_direction < 0 && strafehud_angle <= strafehud_bestangle))
            strafehud_currentangle_color = strafehud_good_color;
        }

        if (fabs(strafehud_moveangle) > 89.9) // player is overturning
        {
            strafehud_currentangle_color = strafehud_alert_color;
        }

        if (strafehud_speed <= (strafehud_maxspeed + .1) && strafehud_currentangle_color != strafehud_alert_color) // player gains speed without strafing
        {
            strafehud_currentangle_color = strafehud_good_color;
        }

        drawfill(panel_pos - '0 1 0'*floor(panel_size.y * .25 + .5) + eX * (strafehud_currentangle_offset - strafehud_currentangle_size.x/2), strafehud_currentangle_size, strafehud_currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
    }
}
