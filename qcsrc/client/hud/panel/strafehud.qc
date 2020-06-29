// Author: Juhu

#include "strafehud.qh"

#include <client/autocvars.qh>
#include <client/miscfunctions.qh>
#include <common/animdecide.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <lib/csqcmodel/cl_player.qh>

// StrafeHUD (#25)

void HUD_StrafeHUD_Export(int fh)
{
    // allow saving cvars that aesthetically change the panel into hud skin files
}

bool fwd = true;
bool state_fwd = true;
bool state_fwd_prev = true;
float hidden_width;
float demo_angle = -37;
float demo_direction = 1;
float demo_time = 0;
float state_onground_time = 0;
float state_strafekeys_time = 0;
float state_fwd_time = 0;
bool state_onground = false;
bool state_strafekeys = false;
bool turn = false;
float turnangle;

// provide basic panel cvars to old clients
// TODO remove them after a future release (0.8.2+)
noref string autocvar_hud_panel_strafehud_pos = "0.320000 0.570000";
noref string autocvar_hud_panel_strafehud_size = "0.360000 0.020000";
noref string autocvar_hud_panel_strafehud_bg = "0";
noref string autocvar_hud_panel_strafehud_bg_color = "";
noref string autocvar_hud_panel_strafehud_bg_color_team = "";
noref string autocvar_hud_panel_strafehud_bg_alpha = "0.7";
noref string autocvar_hud_panel_strafehud_bg_border = "";
noref string autocvar_hud_panel_strafehud_bg_padding = "";

void HUD_StrafeHUD()
{
    entity strafeplayer;
    bool islocal;

    if(!autocvar__hud_configure)
    {
        if(!autocvar_hud_panel_strafehud) return;
        if(spectatee_status == -1 && (autocvar_hud_panel_strafehud == 1 || autocvar_hud_panel_strafehud == 3)) return;
        if(autocvar_hud_panel_strafehud == 3 && !(ISGAMETYPE(RACE) || ISGAMETYPE(CTS))) return;
    }

    HUD_Panel_LoadCvars();

    if(autocvar_hud_panel_strafehud_dynamichud)
        HUD_Scale_Enable();
    else
        HUD_Scale_Disable();
    HUD_Panel_DrawBg();
    if(panel_bg_padding)
    {
        panel_pos  += '1 1 0' * panel_bg_padding;
        panel_size -= '2 2 0' * panel_bg_padding;
    }

    if(spectatee_status > 0 || isdemo())
    {
        islocal = false;
        strafeplayer = CSQCModel_server2csqc(player_localentnum - 1);
    }
    else
    {
        islocal = true;
        strafeplayer = csqcplayer;
    }

    // draw strafehud
    if(csqcplayer && strafeplayer)
    {
        // physics
        bool   onground                      = islocal ? IS_ONGROUND(strafeplayer) : !(strafeplayer.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
        bool   strafekeys;
        bool   is_swimming                   = strafeplayer.waterlevel >= WATERLEVEL_SWIMMING;
        float  speed                         = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337; // use local csqcmodel entity for this even when spectating, flickers too much otherwise
        float  maxspeed_crouch_mod           = IS_DUCKED(strafeplayer) && !is_swimming ? .5 : 1;
        float  maxspeed_water_mod            = is_swimming ? .7 : 1; // very simplified water physics, the hud will not work well (and is not supposed to) while swimming
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = !autocvar__hud_configure ? maxspeed_phys * maxspeed_crouch_mod * maxspeed_water_mod : 320;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y;
        float  view_angle                    = view_angles.y + 180;
        float  angle;
        int    direction;
        vector movement                      = PHYS_INPUT_MOVEVALUES(strafeplayer);
        int    keys                          = STAT(PRESSED_KEYS);
        int    keys_fwd;
        float  wishangle                     = 0;
        float  moveangle;

        // HUD
        int    mode                          = autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1 ? autocvar_hud_panel_strafehud_mode : 0;
        float  antiflicker_angle             = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);
        float  antiflicker_speed             = max(0, autocvar_hud_panel_strafehud_antiflicker_speed);
        float  minspeed;
        bool   straight_overturn             = false;
        float  hudangle;
        float  bar_offset;
        float  bar_width;
        vector currentangle_color            = autocvar_hud_panel_strafehud_warning_color;
        float  currentangle_offset;
        vector currentangle_size             = '0 0 0';
        bool   show_indicators;
        float  bestangle;
        bool   bestangle_anywhere            = false;
        float  bestangle_offset;
        float  bestangle_width;
        bool   odd_angles                    = false;
        float  switch_bestangle_offset;
        float  odd_bestangle_offset          = 0;
        float  switch_odd_bestangle_offset   = 0;
        float  accelzone_offset;
        float  accelzone_width;
        float  odd_accelzone_offset;
        float  odd_accelzone_width;
        float  overturn_offset;
        float  overturn_width;
        float  overturn_width_visible;
        vector direction_size_vertical       = '0 0 0';
        vector direction_size_horizontal     = '0 0 0';
        float  maxangle;
        float  range_minangle;

        // determine whether the player is pressing forwards or backwards keys
        if(islocal) // if entity is local player
        {
            if(movement_x > 0)
            {
                keys_fwd = 1;
            }
            else if(movement_x < 0)
            {
                keys_fwd = -1;
            }
            else
            {
                keys_fwd = 0;
            }
        }
        else // alternatively determine direction by querying pressed keys
        {
            if((keys & KEY_FORWARD) && !(keys & KEY_BACKWARD))
            {
                keys_fwd = 1;
            }
            else if(!(keys & KEY_FORWARD) && (keys & KEY_BACKWARD))
            {
                keys_fwd = -1;
            }
            else
            {
                keys_fwd = 0;
            }
        }

        // determine player wishdir
        if(islocal) // if entity is local player
        {
            if(movement_x == 0)
            {
                if(movement_y < 0)
                {
                    wishangle = -90;
                }
                else if(movement_y > 0)
                {
                    wishangle = 90;
                }
                else
                {
                    wishangle = 0;
                }
            }
            else
            {
                if(movement_y == 0)
                {
                    wishangle = 0;
                }
                else
                {
                    wishangle = RAD2DEG * atan2(movement_y, movement_x);
                    // wrap the wish angle if it exceeds ±90°
                    if(fabs(wishangle) > 90)
                    {
                        if(wishangle < 0) wishangle += 180;
                        else wishangle -= 180;
                        wishangle = -wishangle;
                    }
                }
            }
        }
        else // alternatively calculate wishdir by querying pressed keys
        {
            if(keys & KEY_FORWARD || keys & KEY_BACKWARD)
            {
                wishangle = 45;
            }
            else
            {
                wishangle = 90;
            }
            if(keys & KEY_LEFT)
            {
                wishangle *= -1;
            }
            else if(!(keys & KEY_RIGHT))
            {
                wishangle = 0; // wraps at 180°
            }
        }

        strafekeys = fabs(wishangle) == 90;

        // determine minimum required angle to display full strafe range
        range_minangle = fabs(wishangle) % 90; // maximum range is 90 degree
        if(range_minangle > 45) // minimum angle range is 45
        {
            range_minangle = 45 - fabs(wishangle) % 45;
        }
        range_minangle = 90 - range_minangle; // calculate value which is never >90 or <45
        range_minangle *= 2; // multiply to accommodate for both sides of the hud

        if(autocvar_hud_panel_strafehud_angle == 0)
        {
            if(autocvar__hud_configure)
            {
                hudangle = 90;
            }
            else
            {
                hudangle = range_minangle; // use minimum angle required if dynamically setting hud angle
            }
        }
        else
        {
            hudangle = bound(0, fabs(autocvar_hud_panel_strafehud_angle), 360); // limit HUD range to 360 degrees, higher values don't make sense
        }

        // detect air strafe turning
        if(onground != state_onground)
        {
            state_onground_time = time;
        }
        state_onground = onground;
        if(strafekeys != state_strafekeys)
        {
            state_strafekeys_time = time;
        }
        state_strafekeys = strafekeys;
        if((keys & KEY_FORWARD) || (keys & KEY_BACKWARD) || is_swimming || autocvar__hud_configure)
        {
            turn = false;
        }
        else if(onground)
        {
            if((time - state_onground_time) >= autocvar_hud_panel_strafehud_timeout_ground) // timeout for strafe jumping in general
            {
                turn = false;
            }
        }
        else // air strafe only
        {
            if(strafekeys)
            {
                if(((time - state_onground_time) >= autocvar_hud_panel_strafehud_timeout_air) || (keys & KEY_JUMP)) // timeout for slick ramps
                {
                    turn = true; // CPMA turning
                    turnangle = wishangle;
                }
            }
            else if((time - state_strafekeys_time) >= autocvar_hud_panel_strafehud_timeout_strafe) // timeout for jumping with strafe keys only
            {
                turn = false;
            }
        }
        if(turn)
        {
            maxspeed = PHYS_MAXAIRSTRAFESPEED(strafeplayer); // no modifiers here because they don't affect air strafing
            wishangle = turnangle;
        }

        minspeed = autocvar_hud_panel_strafehud_indicator_minspeed < 0 ? maxspeed + antiflicker_speed : autocvar_hud_panel_strafehud_indicator_minspeed;
        show_indicators = (autocvar_hud_panel_strafehud_indicators && (speed >= minspeed));

        // get current strafing angle ranging from -180° to +180°
        if(!autocvar__hud_configure)
        {
            if(speed > 0)
            {
                // calculate view angle relative to the players current velocity direction
                angle = vel_angle - view_angle;

                // if the angle goes above 180° or below -180° wrap it to the opposite side
                if (angle > 180) angle -= 360;
                else if(angle < -180) angle += 360;

                // shift the strafe angle by 180° for hud calculations
                if(angle < 0) angle += 180;
                else angle -= 180;

                // determine whether the player is strafing forwards or backwards
                // if the player isn't strafe turning use forwards/backwards keys to determine direction
                if(!strafekeys)
                {
                    if(keys_fwd > 0)
                    {
                    state_fwd = true;
                    }
                    else if(keys_fwd < 0)
                    {
                        state_fwd = false;
                    }
                    else
                    {
                        state_fwd = fabs(angle) <= 90;
                    }
                }
                // otherwise determine by examining the strafe angle
                else
                {
                    if(wishangle < 0) // detect direction since the direction is not yet set
                    {
                        state_fwd = angle <= -wishangle;
                    }
                    else
                    {
                        state_fwd = angle >= -wishangle;
                    }
                }

                if(state_fwd_prev != state_fwd)
                {
                    state_fwd_time = time;
                }
                state_fwd_prev = state_fwd;

                if((time - state_fwd_time) >= autocvar_hud_panel_strafehud_timeout_direction || speed < maxspeed || (strafekeys && mode == 0)) // timeout when changing between forwards and backwards movement
                {
                    fwd = state_fwd;
                }

                // shift the strafe angle by 180° when strafing backwards
                if(!fwd)
                {
                    if(angle < 0) angle += 180;
                    else angle -= 180;
                }

                // don't make the angle indicator switch side too much at ±180° if anti flicker is turned on
                if(angle > (180 - antiflicker_angle) || angle < (-180 + antiflicker_angle))
                {
                    straight_overturn = true;
                }
            }
            else
            {
                angle = 0;
            }
        }
        else // simulate turning for HUD setup
        {
            if(autocvar__hud_panel_strafehud_demo && ((time - demo_time) >= .025))
            {
                demo_time = time;
                demo_angle += demo_direction;
                if(fabs(demo_angle) >= 55)
                {
                    demo_direction = -demo_direction;
                }
            }
            angle = demo_angle;
            wishangle = 45 * (demo_angle > 0 ? 1 : -1);
        }

        // invert the wish angle when strafing backwards
        if(!fwd)
        {
            wishangle = -wishangle;
        }

        // flip angles if v_flipped is enabled
        if(autocvar_v_flipped)
        {
            angle = -angle;
            wishangle = -wishangle;
        }

        moveangle = angle + wishangle;

        // determine whether the player is strafing left or right
        if(wishangle != 0)
        {
            direction = wishangle > 0 ? 1 : -1;
        }
        else
        {
            direction = (angle > antiflicker_angle && angle < (180 - antiflicker_angle)) ? 1 : (angle < -antiflicker_angle && angle > (-180 + antiflicker_angle)) ? -1 : 0;
        }

        // decelerating at this angle
        maxangle = 90 - fabs(wishangle);
        // best angle to strafe at
        bestangle = (speed > maxspeed ? acos(maxspeed / speed) : 0) * RAD2DEG * (direction < 0 ? -1 : 1) - wishangle;

        // various offsets and size calculations of hud indicator elements
        // how much is hidden by the current hud angle
        hidden_width = (360 - hudangle) / hudangle * panel_size.x;
        // current angle
        currentangle_size.x = max(panel_size.x * autocvar_hud_panel_strafehud_angle_width, 1);
        if(mode == 0)
        {
            currentangle_offset = angle/hudangle * panel_size.x;
        }
        else
        {
            currentangle_offset = bound(-hudangle/2, angle, hudangle/2)/hudangle * panel_size.x + panel_size.x/2;
        }
        currentangle_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_height, 2), 1);
        // best strafe acceleration angle
        bestangle_offset        =  bestangle/hudangle * panel_size.x + panel_size.x/2;
        switch_bestangle_offset = -bestangle/hudangle * panel_size.x + panel_size.x/2;

        if(((angle > -wishangle && direction < 0) || (angle < -wishangle && direction > 0)) && (direction != 0))
        {
            odd_angles = true;
            float odd_bestangle = -(bestangle + wishangle) - wishangle;
            odd_bestangle_offset        = odd_bestangle/hudangle * panel_size.x + panel_size.x/2;
            switch_odd_bestangle_offset = (odd_bestangle+bestangle*2)/hudangle * panel_size.x + panel_size.x/2;
        }

        if(show_indicators)
        {
            bestangle_width = max(panel_size.x * autocvar_hud_panel_strafehud_indicator_width, 1);
        }
        else
        {
            bestangle_width = 0;
        }
        // direction indicator
        direction_size_vertical.x = max(panel_size.y * min(autocvar_hud_panel_strafehud_direction_width, .5), 1);
        direction_size_vertical.y = panel_size.y;
        direction_size_horizontal.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5), direction_size_vertical.x);
        direction_size_horizontal.y = direction_size_vertical.x;
        // overturn
        overturn_width = 180/hudangle * panel_size.x;
        overturn_width_visible = (hudangle/2 - maxangle) / hudangle * panel_size.x;

        // the strafe bar fills the whole hud panel
        if(speed <= (is_swimming ? antiflicker_speed : 0))
        {
            // add a background to the strafe-o-meter
            if(panel_size.x > 0 && panel_size.y > 0)
            {
                switch(autocvar_hud_panel_strafehud_style)
                {
                    default:
                    case 0:
                        drawfill(panel_pos, panel_size, autocvar_hud_panel_strafehud_bar_color, autocvar_hud_panel_strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        break;

                    case 1:
                        HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, autocvar_hud_panel_strafehud_bar_color, autocvar_hud_panel_strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
            }
        }
        else
        {
            // mark the ideal strafe angle
            if(direction < 0) // turning left
            {
                // calculate zone in which strafe acceleration happens
                accelzone_width = bestangle_offset;
                // calculate offset of overturn area
                overturn_offset = overturn_width_visible - overturn_width;
                // move/adjust acceleration zone
                accelzone_offset = overturn_width_visible;
                accelzone_width -= overturn_width_visible;
                // calculate zone in which strafe acceleration could also happen without changing wishdir
                odd_accelzone_width = accelzone_width;
                odd_accelzone_offset = overturn_offset - odd_accelzone_width;
                // calculate the background of the strafe-o-meter
                bar_offset = bestangle_offset;
                bar_width = 360/hudangle * panel_size.x - accelzone_width - odd_accelzone_width - overturn_width;
            }
            else // turning right or moving forward
            {
                // calculate zone in which strafe acceleration happens
                accelzone_offset = bestangle_offset;
                accelzone_width = panel_size.x - accelzone_offset;
                // calculate offset of overturn area
                overturn_offset = panel_size.x - overturn_width_visible;
                // adjust acceleration zone
                accelzone_width -= overturn_width_visible;
                // calculate zone in which strafe acceleration could also happen without changing wishdir
                odd_accelzone_width = accelzone_width;
                odd_accelzone_offset = overturn_offset + overturn_width;
                // calculate the background of the strafe-o-meter
                bar_offset = odd_accelzone_offset + odd_accelzone_width;
                bar_width = 360/hudangle * panel_size.x - accelzone_width - odd_accelzone_width - overturn_width;
            }

            // remove indicator width from offset
            if(direction < 0)
            {
                bestangle_offset -= bestangle_width;
                switch_odd_bestangle_offset -= bestangle_width;
            }
            else
            {
                switch_bestangle_offset -= bestangle_width;
                odd_bestangle_offset -= bestangle_width;
            }

            if(mode == 0)
            {
                bar_offset -= currentangle_offset;
                accelzone_offset -= currentangle_offset;
                odd_accelzone_offset -= currentangle_offset;
                overturn_offset -= currentangle_offset;
                bestangle_offset -= currentangle_offset;
                switch_bestangle_offset -= currentangle_offset;
                odd_bestangle_offset -= currentangle_offset;
                switch_odd_bestangle_offset -= currentangle_offset;
            }

            // draw acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_offset, accelzone_width, autocvar_hud_panel_strafehud_indicator_color, autocvar_hud_panel_strafehud_acceleration_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style);

            // draw odd acceleration zone
            HUD_Panel_DrawStrafeHUD(odd_accelzone_offset, odd_accelzone_width, autocvar_hud_panel_strafehud_indicator_color, autocvar_hud_panel_strafehud_acceleration_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style);

            // draw overturn area
            HUD_Panel_DrawStrafeHUD(overturn_offset, overturn_width, autocvar_hud_panel_strafehud_alert_color, autocvar_hud_panel_strafehud_overturn_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style);

            // draw the strafe bar background
            HUD_Panel_DrawStrafeHUD(bar_offset, bar_width, autocvar_hud_panel_strafehud_bar_color, autocvar_hud_panel_strafehud_bar_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style);

            if(autocvar_hud_panel_strafehud_direction_show && direction != 0)
            {
                bool indicator_direction = direction < 0;
                // invert left/right when strafing backwards or when strafing towards the opposite side indicated by the direction variable
                // if both conditions are true then it's inverted twice hence not inverted at all
                if(!fwd != odd_angles)
                {
                    indicator_direction = !indicator_direction;
                }
                // draw the direction indicator caps at the sides of the hud
                // vertical line
                drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x), direction_size_vertical, autocvar_hud_panel_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                // top horizontal line
                drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x - direction_size_horizontal.x + direction_size_vertical.x) - eY * direction_size_horizontal.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                // bottom horizontal line
                drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x - direction_size_horizontal.x + direction_size_vertical.x) + eY * panel_size.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
            }

            if(show_indicators) // only draw indicators if enabled and minspeed is reached
            {
                // draw best angles for acceleration
                vector indicator_color;
                float offset = !odd_angles ? bestangle_offset : odd_bestangle_offset;
                float switch_offset = !odd_angles ? switch_bestangle_offset : switch_odd_bestangle_offset;
                // both indicators are yellow if no direction can be determined
                indicator_color = direction != 0 ? autocvar_hud_panel_strafehud_indicator_color : autocvar_hud_panel_strafehud_indicator_switch_color;
                HUD_Panel_DrawStrafeHUD(switch_offset, bestangle_width, autocvar_hud_panel_strafehud_indicator_switch_color, panel_fg_alpha, 0);
                HUD_Panel_DrawStrafeHUD(offset, bestangle_width, indicator_color, panel_fg_alpha, 0);
            }
        }

        if(speed < (maxspeed + antiflicker_speed) && speed > 0)
        {
            bestangle_anywhere = true; // moving forward should suffice to gain speed
        }

        // draw the actual strafe angle
        if(!bestangle_anywhere) // player gains speed with strafing
        {
            if((direction > 0 && (angle >= bestangle || angle <= -(bestangle + wishangle*2))) ||
                (direction < 0 && (angle <= bestangle || angle >= -(bestangle + wishangle*2))))
            currentangle_color = autocvar_hud_panel_strafehud_good_color;
        }

        if(fabs(moveangle) > 90) // player is overturning
        {
            currentangle_color = autocvar_hud_panel_strafehud_alert_color;
        }
        else if(bestangle_anywhere) // player gains speed without strafing
        {
            currentangle_color = autocvar_hud_panel_strafehud_good_color;
        }

        if(mode == 0 || straight_overturn)
        {
            currentangle_offset = panel_size.x/2;
        }
        drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (currentangle_offset - currentangle_size.x/2), currentangle_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
    }
}

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_DrawStrafeHUD(float offset, float width, vector color, float alpha, int type)
{
    float mirror_offset, mirror_width;
    vector size = panel_size;
    vector mirror_size = panel_size;

    if(offset < 0)
    {
        mirror_width = min(fabs(offset), width);
        mirror_offset = panel_size.x + hidden_width - fabs(offset);
        width += offset;
        offset = 0;
    }
    else
    {
        mirror_width = min(offset + width - panel_size.x - hidden_width, width);
        mirror_offset = max(offset - panel_size.x - hidden_width, 0);
    }
    if((offset + width) > panel_size.x)
    {
        width = panel_size.x - offset;
    }
    if(mirror_offset < 0)
    {
        mirror_width += mirror_offset;
        mirror_offset = 0;
    }
    if((mirror_offset + mirror_width) > panel_size.x)
    {
        mirror_width = panel_size.x - mirror_offset;
    }

    size.x = width;
    mirror_size.x = mirror_width;

    switch(type)
    {
        default:
        case 0:
            if(mirror_width > 0) drawfill(panel_pos + eX * mirror_offset, mirror_size, color, alpha, DRAWFLAG_NORMAL);
            if(width > 0) drawfill(panel_pos + eX * offset, size, color, alpha, DRAWFLAG_NORMAL);
            break;

        case 1:
            if(mirror_size.x > 0 && mirror_size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * mirror_offset, mirror_size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
            if(size.x > 0 && size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * offset, size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
    }
}
