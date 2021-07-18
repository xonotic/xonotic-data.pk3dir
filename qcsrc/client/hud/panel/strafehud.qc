// Author: Juhu

#include "strafehud.qh"

#include <client/draw.qh>
#include <client/hud/panel/racetimer.qh>
#include <client/resources.qh>
#include <client/view.qh>
#include <common/animdecide.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <lib/csqcmodel/cl_player.qh>

AUTOCVAR_SAVE(hud_panel_strafehud_pos, string, "0.320000 0.570000", "position of this base of the panel");
AUTOCVAR_SAVE(hud_panel_strafehud_size, string, "0.360000 0.020000", "size of this panel");
AUTOCVAR_SAVE(hud_panel_strafehud_bg, string, "0", "if set to something else than \"\" = override default background");
AUTOCVAR_SAVE(hud_panel_strafehud_bg_color, string, "", "if set to something else than \"\" = override default panel background color");
AUTOCVAR_SAVE(hud_panel_strafehud_bg_color_team, string, "", "override panel color with team color in team based games");
AUTOCVAR_SAVE(hud_panel_strafehud_bg_alpha, string, "0.7", "if set to something else than \"\" = override default panel background alpha");
AUTOCVAR_SAVE(hud_panel_strafehud_bg_border, string, "", "if set to something else than \"\" = override default size of border around the background");
AUTOCVAR_SAVE(hud_panel_strafehud_bg_padding, string, "", "if set to something else than \"\" = override default padding of contents from border");

// StrafeHUD (#25)

void HUD_StrafeHUD_Export(int fh)
{
    // allow saving cvars that aesthetically change the panel into hud skin files
}

float hidden_width;
int direction;
float demo_angle = -37;
float demo_direction = 1;
float demo_time = 0;
bool state_onground = false;
float state_onground_time = 0;
bool state_strafekeys = false;
float state_strafekeys_time = 0;
bool turn = false;
float turnangle;
float turnspeed;
float turnaccel;
bool fwd = true;
float starttime = 0;
float startspeed = -1;
float jumptime = 0;
float jumpheight = -1;
float jumpheight_persistent = -1;
float jumpheight_prev = 0;
float jumpspeed_prev = 0;
bool  jumprestart = true;

void HUD_StrafeHUD()
{
    entity strafeplayer;
    bool islocal;

    if(false)
    {
        autocvar_hud_panel_strafehud_pos = autocvar_hud_panel_strafehud_pos;
        autocvar_hud_panel_strafehud_size = autocvar_hud_panel_strafehud_size;
        autocvar_hud_panel_strafehud_bg = autocvar_hud_panel_strafehud_bg;
        autocvar_hud_panel_strafehud_bg_color = autocvar_hud_panel_strafehud_bg_color;
        autocvar_hud_panel_strafehud_bg_color_team = autocvar_hud_panel_strafehud_bg_color_team;
        autocvar_hud_panel_strafehud_bg_alpha = autocvar_hud_panel_strafehud_bg_alpha;
        autocvar_hud_panel_strafehud_bg_border = autocvar_hud_panel_strafehud_bg_border;
        autocvar_hud_panel_strafehud_bg_padding = autocvar_hud_panel_strafehud_bg_padding;
    }

    // generic hud routines
    if(!autocvar__hud_configure)
    {
        if(!autocvar_hud_panel_strafehud ||
           (spectatee_status == -1 && (autocvar_hud_panel_strafehud == 1 || autocvar_hud_panel_strafehud == 3)) ||
           (autocvar_hud_panel_strafehud == 3 && !MUTATOR_CALLHOOK(HUD_StrafeHUD_showoptional))) return;
    }

    HUD_Panel_LoadCvars();

    if(autocvar_hud_panel_strafehud_dynamichud)
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

    // find out whether the local csqcmodel entity is valid
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
        bool   swimming                      = strafeplayer.waterlevel >= WATERLEVEL_SWIMMING;
        bool   spectating                    = entcs_GetSpecState(strafeplayer.sv_entnum) == ENTCS_SPEC_PURE;
        float  speed                         = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337; // use local csqcmodel entity for this even when spectating, flickers too much otherwise
        float  crouch_mod                    = IS_DUCKED(csqcplayer) && !swimming ? .5 : 1;
        float  water_mod                     = swimming ? .7 : 1; // very simplified water physics, the hud will not work well (and is not supposed to) while swimming
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = !autocvar__hud_configure ? maxspeed_phys * crouch_mod * water_mod : 320;
        float  movespeed;
        float  maxaccel_phys                 = onground ? PHYS_ACCELERATE(strafeplayer) : PHYS_AIRACCELERATE(strafeplayer);
        float  maxaccel                      = !autocvar__hud_configure ? maxaccel_phys * crouch_mod * water_mod : 1;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y - (vectoangles(strafeplayer.velocity).y > 180 ? 360 : 0); // change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
        float  view_angle                    = PHYS_INPUT_ANGLES(strafeplayer).y;
        float  angle;
        vector movement                      = PHYS_INPUT_MOVEVALUES(strafeplayer);
        int    keys                          = STAT(PRESSED_KEYS);
        int    keys_fwd;
        float  wishangle                     = 0;

        // HUD
        int    mode                          = autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1 ? autocvar_hud_panel_strafehud_mode : 0;
        float  speed_conversion_factor       = GetSpeedUnitFactor(autocvar_hud_panel_strafehud_unit);
        float  length_conversion_factor      = GetLengthUnitFactor(autocvar_hud_panel_strafehud_unit);
        int    length_decimals               = autocvar_hud_panel_strafehud_unit >= 3 && autocvar_hud_panel_strafehud_unit <= 5 ? 6 : 2; // use more decimals when displaying km or miles
        float  antiflicker_angle             = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);
        float  antiflicker_speed             = max(0, autocvar_hud_panel_strafehud_antiflicker_speed);
        float  minspeed;
        float  shift_offset                  = 0;
        bool   straight_overturn             = false;
        bool   immobile                      = speed <= (swimming ? antiflicker_speed : 0);
        float  hudangle;
        float  neutral_offset;
        float  neutral_width;
        vector currentangle_color            = autocvar_hud_panel_strafehud_angle_neutral_color;
        float  currentangle_offset;
        vector currentangle_size             = '0 0 0';
        float  bestangle;
        float  prebestangle;
        float  odd_bestangle;
        bool   bestangle_anywhere            = false;
        float  bestangle_offset;
        float  switch_bestangle_offset;
        bool   odd_angles                    = false;
        float  odd_bestangle_offset          = 0;
        float  switch_odd_bestangle_offset   = 0;
        float  bestangle_width;
        float  accelzone_left_offset;
        float  accelzone_right_offset;
        float  accelzone_width;
        float  preaccelzone_left_offset;
        float  preaccelzone_right_offset;
        float  preaccelzone_width;
        float  overturn_offset;
        float  overturn_width;
        float  slickdetector_height;
        vector direction_size_vertical       = '0 0 0';
        vector direction_size_horizontal     = '0 0 0';
        float  range_minangle;
        float  arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_arrow_size, 10), 0); // there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing

        if(!autocvar_hud_panel_strafehud_uncapped)
            arrow_size = max(arrow_size, 1);

        // determine whether the player is pressing forwards or backwards keys
        if(islocal) // if entity is local player
        {
            if(movement.x > 0)
            {
                keys_fwd = 1;
            }
            else if(movement.x < 0)
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
            if(movement.x == 0)
            {
                if(movement.y < 0)
                {
                    wishangle = -90;
                }
                else if(movement.y > 0)
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
                if(movement.y == 0)
                {
                    wishangle = 0;
                }
                else
                {
                    wishangle = RAD2DEG * atan2(movement.y, movement.x);
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

        strafekeys = fabs(wishangle) > 45;

        // determine minimum required angle to display full strafe range
        range_minangle = fabs(wishangle) % 90; // maximum range is 90 degree
        if(range_minangle > 45) // minimum angle range is 45
        {
            range_minangle = 45 - fabs(wishangle) % 45;
        }
        range_minangle = 90 - range_minangle; // calculate value which is never >90 or <45
        range_minangle *= 2; // multiply to accommodate for both sides of the hud

        if(autocvar_hud_panel_strafehud_range == 0)
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
            hudangle = bound(0, fabs(autocvar_hud_panel_strafehud_range), 360); // limit HUD range to 360 degrees, higher values don't make sense
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

        if((!strafekeys && vlen(vec2(movement)) > 0) || swimming || autocvar__hud_configure)
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

                    // calculate the maximum air strafe speed and acceleration
                    if(PHYS_MAXAIRSPEED(strafeplayer) == 0){
                        maxspeed = 0;
                    }
                    else if(PHYS_MAXAIRSTRAFESPEED(strafeplayer) == 0 || PHYS_MAXAIRSPEED(strafeplayer) <= PHYS_MAXAIRSTRAFESPEED(strafeplayer)){
                        maxspeed = PHYS_MAXAIRSPEED(strafeplayer);
                    }
                    else{
                        maxspeed = PHYS_MAXAIRSPEED(strafeplayer) * pow(fabs(PHYS_MAXAIRSTRAFESPEED(strafeplayer) / PHYS_MAXAIRSPEED(strafeplayer)), 1 - (90 - fabs(wishangle)) / 45); // no modifiers here because they don't affect air strafing
                    }
                    turnspeed = vlen(vec2(movement));
                    if(turnspeed == 0) turnspeed = maxspeed;
                    else turnspeed = min(turnspeed, maxspeed);

                    if(PHYS_AIRACCELERATE(strafeplayer) == 0){
                        maxaccel = 0;
                    }
                    else if(PHYS_AIRSTRAFEACCELERATE(strafeplayer) == 0 || PHYS_AIRACCELERATE(strafeplayer) <= PHYS_AIRSTRAFEACCELERATE(strafeplayer)){
                        maxaccel = PHYS_AIRACCELERATE(strafeplayer);
                    }
                    else{
                        maxaccel = PHYS_AIRACCELERATE(strafeplayer) * pow(fabs(PHYS_AIRSTRAFEACCELERATE(strafeplayer) / PHYS_AIRACCELERATE(strafeplayer)), 1 - (90 - fabs(wishangle)) / 45); // no modifiers here because they don't affect air strafing
                    }
                    turnaccel = maxaccel;
                }
            }
            else if((time - state_strafekeys_time) >= autocvar_hud_panel_strafehud_timeout_turn) // timeout for jumping with strafe keys only
            {
                turn = false;
            }
        }
        if(turn && (onground || !strafekeys)) // retain last state until strafe turning times out
        {
            wishangle = turnangle;
            movespeed = turnspeed;
            maxaccel = turnaccel;
        }
        else{
            movespeed = vlen(vec2(movement));
            if(movespeed == 0) movespeed = maxspeed;
            else movespeed = min(movespeed, maxspeed);

            if(onground)
            {
                if((keys & KEY_JUMP) && ((time - state_onground_time) < autocvar_hud_panel_strafehud_timeout_ground)) // if ground timeout hasn't expired yet use air accelerate
                {
                    maxaccel = !autocvar__hud_configure ? PHYS_AIRACCELERATE(strafeplayer) * crouch_mod * water_mod : 1;
                }
            }
            else
            {
                if(!(keys & KEY_JUMP) && ((time - state_onground_time) < autocvar_hud_panel_strafehud_timeout_air)) // if air timeout hasn't expired yet use ground accelerate
                {
                    maxaccel = !autocvar__hud_configure ? PHYS_ACCELERATE(strafeplayer) * crouch_mod * water_mod : 1;
                }
            }
        }

        minspeed = autocvar_hud_panel_strafehud_switch_minspeed < 0 ? (movespeed - maxaccel) + antiflicker_speed : autocvar_hud_panel_strafehud_switch_minspeed;

        // get current strafing angle ranging from -180° to +180°
        if(!autocvar__hud_configure)
        {
            if(speed > 0)
            {
                // calculate view angle relative to the players current velocity direction
                angle = vel_angle - view_angle;

                // if the angle goes above 180° or below -180° wrap it to the opposite side since we want the interior angle
                if (angle > 180) angle -= 360;
                else if(angle < -180) angle += 360;

                // determine whether the player is strafing forwards or backwards
                // if the player isn't strafe turning use forwards/backwards keys to determine direction
                if(fabs(wishangle) != 90)
                {
                    if(keys_fwd > 0)
                    {
                        fwd = true;
                    }
                    else if(keys_fwd < 0)
                    {
                        fwd = false;
                    }
                    else
                    {
                        fwd = fabs(angle) <= 90;
                    }
                }
                // otherwise determine by examining the strafe angle
                else
                {
                    if(wishangle < 0) // detect direction using wishangle since the direction is not yet set
                    {
                        fwd = angle <= -wishangle;
                    }
                    else
                    {
                        fwd = angle >= -wishangle;
                    }
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
            fwd = true;
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

        // determine whether the player is strafing left or right
        if(wishangle != 0)
        {
            direction = wishangle > 0 ? 1 : -1;
        }
        else
        {
            direction = (angle > antiflicker_angle && angle < (180 - antiflicker_angle)) ? 1 : (angle < -antiflicker_angle && angle > (-180 + antiflicker_angle)) ? -1 : 0;
        }

        // best angle to strafe at
        bestangle = (speed > (movespeed - maxaccel) ? acos((movespeed - maxaccel) / speed) : 0) * RAD2DEG * (direction < 0 ? -1 : 1);
        prebestangle = (speed > movespeed ? acos(movespeed / speed) : 0) * RAD2DEG * (direction < 0 ? -1 : 1);
        odd_bestangle = -bestangle - wishangle;
        bestangle -= wishangle;
        prebestangle -= wishangle;

        // various offsets and size calculations of hud indicator elements
        // how much is hidden by the current hud angle
        hidden_width = (360 - hudangle) / hudangle * panel_size.x;
        // current angle
        currentangle_size.x = autocvar_hud_panel_strafehud_angle_width;
        currentangle_size.y = autocvar_hud_panel_strafehud_angle_height;
        if(!autocvar_hud_panel_strafehud_uncapped)
        {
            currentangle_size.x = min(currentangle_size.x, 10);
            currentangle_size.y = min(currentangle_size.y, 10);
        }
        currentangle_size.x *= panel_size.x;
        currentangle_size.y *= panel_size.y;
        if(!autocvar_hud_panel_strafehud_uncapped)
        {
            currentangle_size.x = max(currentangle_size.x, 1);
            currentangle_size.y = max(currentangle_size.y, 1);
        }
        else
        {
            currentangle_size.y = max(currentangle_size.y, 0);
        }
        if(mode == 0)
        {
            currentangle_offset = angle/hudangle * panel_size.x;
        }
        else
        {
            currentangle_offset = bound(-hudangle/2, angle, hudangle/2)/hudangle * panel_size.x + panel_size.x/2;
        }
        // best strafe acceleration angle
        bestangle_offset        =  bestangle/hudangle * panel_size.x + panel_size.x/2;
        switch_bestangle_offset = -bestangle/hudangle * panel_size.x + panel_size.x/2;
        bestangle_width = panel_size.x * autocvar_hud_panel_strafehud_switch_width;
        if(!autocvar_hud_panel_strafehud_uncapped)
            bestangle_width = max(bestangle_width, 1);

        if(((angle > -wishangle && direction < 0) || (angle < -wishangle && direction > 0)) && (direction != 0))
        {
            odd_angles = true;
            odd_bestangle_offset = odd_bestangle/hudangle * panel_size.x + panel_size.x/2;
            switch_odd_bestangle_offset = (odd_bestangle+bestangle*2)/hudangle * panel_size.x + panel_size.x/2;
        }
        // direction indicator
        direction_size_vertical.x = autocvar_hud_panel_strafehud_direction_width;
        if(!autocvar_hud_panel_strafehud_uncapped)
            direction_size_vertical.x = min(direction_size_vertical.x, 1);
        direction_size_vertical.x *= panel_size.y;
        if(!autocvar_hud_panel_strafehud_uncapped)
            direction_size_vertical.x = max(direction_size_vertical.x, 1);
        direction_size_vertical.y = panel_size.y + direction_size_vertical.x*2;
        direction_size_horizontal.x = panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5);
        direction_size_horizontal.y = direction_size_vertical.x;
        // overturn
        overturn_width = 180/hudangle * panel_size.x;

        // the neutral zone fills the whole strafe bar
        if(immobile)
        {
            // draw neutral zone
            if(panel_size.x > 0 && panel_size.y > 0 && autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha > 0)
            {
                switch(autocvar_hud_panel_strafehud_style)
                {
                    default:
                    case 0:
                        drawfill(panel_pos, panel_size, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        break;

                    case 1:
                        HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
            }
        }
        else
        {
            // calculate various zones of the strafe-o-meter
            accelzone_width = (90 - fabs(bestangle + wishangle))/hudangle * panel_size.x;
            preaccelzone_width = (fabs(bestangle - prebestangle))/hudangle * panel_size.x;
            overturn_offset = accelzone_width + preaccelzone_width;
            accelzone_right_offset = preaccelzone_width;
            accelzone_left_offset = overturn_offset + overturn_width;
            preaccelzone_right_offset = 0;
            preaccelzone_left_offset = accelzone_left_offset + accelzone_width;
            neutral_width = 360/hudangle * panel_size.x - accelzone_width*2 - preaccelzone_width*2 - overturn_width;
            neutral_offset = direction < 0 ? preaccelzone_left_offset + preaccelzone_width : -neutral_width;

            // shift hud if operating in view angle centered mode
            if(mode == 0)
            {
                shift_offset = -currentangle_offset;
                bestangle_offset += shift_offset;
                switch_bestangle_offset += shift_offset;
                odd_bestangle_offset += shift_offset;
                switch_odd_bestangle_offset += shift_offset;
            }
            if(direction < 0) shift_offset += -360/hudangle * panel_size.x;
            // calculate how far off-center the strafe zones currently are
            shift_offset += (panel_size.x + neutral_width)/2 - wishangle/hudangle * panel_size.x;
            // shift strafe zones into correct place
            neutral_offset += shift_offset;
            accelzone_left_offset += shift_offset;
            accelzone_right_offset += shift_offset;
            preaccelzone_left_offset += shift_offset;
            preaccelzone_right_offset += shift_offset;
            overturn_offset += shift_offset;

            // draw left acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_left_offset, accelzone_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 1);
            HUD_Panel_DrawStrafeHUD(preaccelzone_left_offset, preaccelzone_width, autocvar_hud_panel_strafehud_bar_preaccel_color, autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 0);

            // draw right acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_right_offset, accelzone_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 2);
            HUD_Panel_DrawStrafeHUD(preaccelzone_right_offset, preaccelzone_width, autocvar_hud_panel_strafehud_bar_preaccel_color, autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 0);

            // draw overturn zone
            HUD_Panel_DrawStrafeHUD(overturn_offset, overturn_width, autocvar_hud_panel_strafehud_bar_overturn_color, autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 3);

            // draw neutral zone
            HUD_Panel_DrawStrafeHUD(neutral_offset, neutral_width, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 0);

            if(speed >= minspeed && bestangle_width > 0) // only draw indicators if minspeed is reached
            {
                // draw the switch indicator(s)
                float offset = !odd_angles ? bestangle_offset : odd_bestangle_offset;
                float switch_offset = !odd_angles ? switch_bestangle_offset : switch_odd_bestangle_offset;

                // remove switch indicator width from offset
                if(direction < 0)
                {
                    if(!odd_angles)
                        offset -= bestangle_width;
                    else
                        switch_offset -= bestangle_width;
                }
                else
                {
                    if(!odd_angles)
                        switch_offset -= bestangle_width;
                    else
                        offset -= bestangle_width;
                }

                HUD_Panel_DrawStrafeHUD(switch_offset, bestangle_width, autocvar_hud_panel_strafehud_switch_color, autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha, 0, 0);
                if(direction == 0) HUD_Panel_DrawStrafeHUD(offset, bestangle_width, autocvar_hud_panel_strafehud_switch_color, autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha, 0, 0);
            }
        }

        // slick detector
        slickdetector_height = max(autocvar_hud_panel_strafehud_slickdetector_height, 0);
        if(!autocvar_hud_panel_strafehud_uncapped)
             slickdetector_height = min(slickdetector_height, 1);
        slickdetector_height *= panel_size.y;
        if(autocvar_hud_panel_strafehud_slickdetector_range > 0 && autocvar_hud_panel_strafehud_slickdetector_alpha > 0 && slickdetector_height > 0 && panel_size.x > 0)
        {
            float slicksteps = max(autocvar_hud_panel_strafehud_slickdetector_granularity, 0);
            bool slickdetected = false;

            if(!autocvar_hud_panel_strafehud_uncapped)
                slicksteps = min(slicksteps, 4);
            slicksteps = 90 / pow(2, slicksteps);

            if(islocal) slickdetected = IS_ONSLICK(strafeplayer); // don't need to traceline if already touching slick

            // traceline into every direction
            trace_dphitq3surfaceflags = 0;
            for(float i = 0; i < 360 && !slickdetected; i += slicksteps)
            {
                vector slickoffset;
                float slickrotate;
                slickoffset.z = -cos(i * DEG2RAD) * autocvar_hud_panel_strafehud_slickdetector_range;
                slickrotate = sin(i * DEG2RAD) * autocvar_hud_panel_strafehud_slickdetector_range;
                if(i != 0 && i != 180)
                {
                    for(float j = 0; j < 180 && !slickdetected; j += slicksteps)
                    {
                        slickoffset.x = sin(j * DEG2RAD) * slickrotate;
                        slickoffset.y = cos(j * DEG2RAD) * slickrotate;

                        traceline(strafeplayer.origin, strafeplayer.origin + slickoffset, MOVE_WORLDONLY, NULL);
                        if((PHYS_FRICTION(strafeplayer) == 0 && trace_fraction < 1) || trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) slickdetected = true;
                    }
                }
                else
                {
                    slickoffset.x = slickoffset.y = 0;
                    traceline(strafeplayer.origin, strafeplayer.origin + slickoffset, MOVE_WORLDONLY, NULL);
                    if((PHYS_FRICTION(strafeplayer) == 0 && trace_fraction < 1) || trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) slickdetected = true;
                }
            }

            // if a traceline hit a slick surface
            if(slickdetected)
            {
                vector slickdetector_size = panel_size;
                slickdetector_size.y = slickdetector_height;
                // top horizontal line
                drawfill(panel_pos - eY * slickdetector_size.y, slickdetector_size, autocvar_hud_panel_strafehud_slickdetector_color, autocvar_hud_panel_strafehud_slickdetector_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                // bottom horizontal line
                drawfill(panel_pos + eY * panel_size.y, slickdetector_size, autocvar_hud_panel_strafehud_slickdetector_color, autocvar_hud_panel_strafehud_slickdetector_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }

        if(direction != 0 && direction_size_vertical.x > 0 && autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha > 0)
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
            if(direction_size_vertical.y > 0) drawfill(panel_pos - eY * direction_size_horizontal.y + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x), direction_size_vertical, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            // top horizontal line
            drawfill(panel_pos + eX * (indicator_direction ? 0 : panel_size.x - direction_size_horizontal.x) - eY * direction_size_horizontal.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            // bottom horizontal line
            drawfill(panel_pos + eX * (indicator_direction ? 0 : panel_size.x - direction_size_horizontal.x) + eY * panel_size.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
        }

        if(speed < ((movespeed - maxaccel) + antiflicker_speed) && !immobile)
        {
            bestangle_anywhere = true; // moving forward should suffice to gain speed
        }

        // draw the actual strafe angle
        if(!bestangle_anywhere && !immobile) // player gains speed with strafing
        {
            if((direction > 0 && (angle >= bestangle || angle <= -(bestangle + wishangle*2))) ||
               (direction < 0 && (angle <= bestangle || angle >= -(bestangle + wishangle*2))))
            currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
        }

        if(fabs(angle + wishangle) > 90) // player is overturning
        {
            currentangle_color = autocvar_hud_panel_strafehud_angle_overturn_color;
        }
        else if(bestangle_anywhere) // player gains speed without strafing
        {
            currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
        }

        if(mode == 0 || straight_overturn)
        {
            currentangle_offset = panel_size.x/2;
        }

        if(autocvar_hud_panel_strafehud_style == 2 && !immobile)
        {
            float moveangle = angle + wishangle;
            float strafeangle = (bestangle + wishangle) * (direction < 0 ? -1 : 1);
            float strafe_ratio = 0;
            if(fabs(moveangle) > 90)
            {
                strafe_ratio = -((fabs(moveangle) - 90) / 90);
                if(strafe_ratio < -1) strafe_ratio = -2 - strafe_ratio;
            }
            else
            {
                if(moveangle >= strafeangle)
                {
                    strafe_ratio = 1 - (moveangle - strafeangle) / (90 - strafeangle);
                }
                else if(moveangle <= -strafeangle)
                {
                    strafe_ratio = 1 - (moveangle + strafeangle) / (-90 + strafeangle);
                }
            }
            if(strafe_ratio < 0)
            {
                currentangle_color = StrafeHUD_mixColors(autocvar_hud_panel_strafehud_angle_neutral_color, autocvar_hud_panel_strafehud_angle_overturn_color, -strafe_ratio);
            }
            else
            {
                currentangle_color = StrafeHUD_mixColors(autocvar_hud_panel_strafehud_angle_neutral_color, autocvar_hud_panel_strafehud_angle_accel_color, strafe_ratio);
            }
        }

        float angleheight_offset = currentangle_size.y;
        float ghost_offset = 0;
        if(autocvar_hud_panel_strafehud_bestangle && direction != 0)
        {
            ghost_offset = !odd_angles ? bestangle_offset : odd_bestangle_offset;
            if(ghost_offset < 0) ghost_offset = 0;
            if(ghost_offset > panel_size.x) ghost_offset = panel_size.x;
        }

        switch(autocvar_hud_panel_strafehud_angle_style)
        {
            case 1:
                if(currentangle_size.x > 0 && currentangle_size.y > 0)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != 0) drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (ghost_offset - currentangle_size.x/2), currentangle_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (currentangle_offset - currentangle_size.x/2), currentangle_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                break;
            case 2:
                if(currentangle_size.x > 0 && currentangle_size.y > 0)
                {
                    vector line_size = currentangle_size;
                    line_size.y = currentangle_size.y / (bound(2, autocvar_hud_panel_strafehud_angle_dashes, currentangle_size.y)*2-1);
                    for(float i = 0; i < currentangle_size.y; i += line_size.y*2)
                    {
                        if(i + line_size.y*2 >= currentangle_size.y) line_size.y = currentangle_size.y - i;
                        if(autocvar_hud_panel_strafehud_bestangle && direction != 0) drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (ghost_offset - line_size.x/2), line_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (currentangle_offset - line_size.x/2), line_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    }
                }
                break;
            case 0:
            default:
                // don't offset text and arrows if the angle indicator line isn't drawn
                angleheight_offset = panel_size.y;
        }

        if(autocvar_hud_panel_strafehud_angle_arrow > 0)
        {
            if(arrow_size > 0)
            {
                if(autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != 0) StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * ghost_offset, arrow_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, true);
                    StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * currentangle_offset, arrow_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, true);
                }
                if(autocvar_hud_panel_strafehud_angle_arrow >= 2)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != 0) StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * ghost_offset, arrow_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, false);
                    StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * currentangle_offset, arrow_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, false);
                }
            }
        }

        draw_beginBoldFont();
        // show speed when crossing the start trigger
        if(autocvar_hud_panel_strafehud_startspeed_fade > 0)
        {
            float text_alpha = 0;
            if((race_nextcheckpoint == 1) || (race_checkpoint == 254 && race_nextcheckpoint == 255)) // check if the start trigger was hit (will also trigger if the finish trigger was hit if those have the same ID)
            {
                if(starttime != race_checkpointtime)
                {
                    starttime = race_checkpointtime;
                    startspeed = speed;
                }
            }
            if(startspeed >= 0)
            {
                text_alpha = cos(((time - starttime) / autocvar_hud_panel_strafehud_startspeed_fade) * 90 * DEG2RAD); // fade non-linear like the physics panel does
                if((time - starttime) > autocvar_hud_panel_strafehud_startspeed_fade)
                {
                    startspeed = -1;
                }
            }
            if(startspeed >= 0 && text_alpha > 0 && autocvar_hud_panel_strafehud_startspeed_size > 0)
            {
                vector startspeed_size = panel_size;
                startspeed_size.y = autocvar_hud_panel_strafehud_startspeed_size;
                if(!autocvar_hud_panel_strafehud_uncapped)
                    startspeed_size.y = min(startspeed_size.y, 10);
                startspeed_size.y *= panel_size.y;
                if(!autocvar_hud_panel_strafehud_uncapped)
                    startspeed_size.y = max(startspeed_size.y, 1);

                float text_offset = 0;
                if((autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha > 0) || (autocvar_hud_panel_strafehud_bestangle && autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha > 0))
                {
                    text_offset = (angleheight_offset - panel_size.y) / 2;
                    if(arrow_size > 0 && autocvar_hud_panel_strafehud_angle_arrow >= 2)
                        text_offset += arrow_size;
                    // make sure text doesn't draw inside the strafehud bar
                    text_offset = max(text_offset, 0);
                }

                string speed_unit = GetSpeedUnit(autocvar_hud_panel_strafehud_unit);
                drawstring_aspect(panel_pos + eY * (panel_size.y + text_offset), strcat(ftos_decimals(startspeed * speed_conversion_factor, 2), autocvar_hud_panel_strafehud_unit_show ? speed_unit : ""), startspeed_size, autocvar_hud_panel_strafehud_startspeed_color, text_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }
        else
        {
            starttime = 0;
            startspeed = -1;
        }

        // experimental: show height achieved by a single jump (doesn't work in low gravity and may not be 100% accurate)
        if(autocvar_hud_panel_strafehud_jumpheight_fade > 0)
        {
            float text_alpha = 0;
            float jumpheight_min = max(autocvar_hud_panel_strafehud_jumpheight_min, 0);
            float jumpheight_current = strafeplayer.origin.z;
            float jumpspeed_current = strafeplayer.velocity.z;
            if(jumpspeed_prev <= jumpspeed_current || jumpheight_prev > jumpheight_current || onground || swimming || IS_DEAD(strafeplayer) || spectating)
            {
                // tries to catch kill and spectate but those are not reliable, should just hook to kill/spectate/teleport and reset jump height there
                jumprestart = true;
            }
            else
            {
                if(jumpheight < 0 || jumprestart)
                {
                    jumprestart = false;
                    jumpheight = 0;
                }
                else
                {
                    jumpheight += jumpheight_current - jumpheight_prev;
                }
                if((jumpheight * length_conversion_factor) > jumpheight_min && jumpheight > jumpheight_persistent)
                {
                    jumptime = time;
                    jumpheight_persistent = jumpheight;
                }
            }
            jumpheight_prev = jumpheight_current;
            jumpspeed_prev = jumpspeed_current;
            if(jumpheight_persistent > 0)
            {
                text_alpha = cos(((time - jumptime) / autocvar_hud_panel_strafehud_jumpheight_fade) * 90 * DEG2RAD); // fade non-linear like the physics panel does
                if((time - jumptime) > autocvar_hud_panel_strafehud_jumpheight_fade)
                {
                    jumpheight_persistent = -1;
                }
            }
            if(jumpheight_persistent > 0 && text_alpha > 0 && autocvar_hud_panel_strafehud_jumpheight_size > 0)
            {
                vector jumpheight_size = panel_size;
                jumpheight_size.y = autocvar_hud_panel_strafehud_jumpheight_size;
                if(!autocvar_hud_panel_strafehud_uncapped)
                    jumpheight_size.y = min(jumpheight_size.y, 10);
                jumpheight_size.y *= panel_size.y;
                if(!autocvar_hud_panel_strafehud_uncapped)
                    jumpheight_size.y = max(jumpheight_size.y, 1);

                float text_offset = 0;
                if((autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha > 0) || (autocvar_hud_panel_strafehud_bestangle && autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha > 0))
                {
                    text_offset = (angleheight_offset - panel_size.y) / 2;
                    if(arrow_size > 0 && autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3)
                        text_offset += arrow_size;
                    // make sure text doesn't draw inside the strafehud bar
                    text_offset = max(text_offset, 0);
                }

                string length_unit = GetLengthUnit(autocvar_hud_panel_strafehud_unit);
                drawstring_aspect(panel_pos - eY * (jumpheight_size.y + text_offset), strcat(ftos_decimals(jumpheight_persistent * length_conversion_factor, length_decimals), autocvar_hud_panel_strafehud_unit_show ? length_unit : ""), jumpheight_size, autocvar_hud_panel_strafehud_jumpheight_color, text_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }
        else
        {
            jumpheight_prev = jumpspeed_prev = 0;
            jumpheight = jumpheight_persistent = -1;
        }
        draw_endBoldFont();
    }
}

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_DrawStrafeHUD(float offset, float width, vector color, float alpha, int type, int gradientType)
{
    float mirror_offset, mirror_width;
    vector size = panel_size;
    vector mirror_size = panel_size;
    int gradient_start;
    float gradient_offset, gradient_mirror_offset;
    float overflow_width = 0, overflow_mirror_width = 0;

    float original_width = width;

    if(alpha <= 0 && type != 2 || width <= 0) return;

    if(type == 2 && gradientType == 0) type = 0;

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

    if(width < 0) width = 0;
    if((offset + width) > panel_size.x)
    {
        overflow_width = (offset + width) - panel_size.x;
        width = panel_size.x - offset;
    }
    if(mirror_offset < 0)
    {
        mirror_width += mirror_offset;
        mirror_offset = 0;
    }

    if(mirror_width < 0) mirror_width = 0;
    if((mirror_offset + mirror_width) > panel_size.x)
    {
        overflow_mirror_width = (mirror_offset + mirror_width) - panel_size.x;
        mirror_width = panel_size.x - mirror_offset;
    }

    if(direction < 0) // swap mirror and non-mirror values if direction points left
    {
        offset += mirror_offset;
        mirror_offset = offset - mirror_offset;
        offset -= mirror_offset;

        width += mirror_width;
        mirror_width = width - mirror_width;
        width -= mirror_width;

        overflow_width += overflow_mirror_width;
        overflow_mirror_width = overflow_width - overflow_mirror_width;
        overflow_width -= overflow_mirror_width;
    }

    size.x = width;
    mirror_size.x = mirror_width;

    switch(type)
    {
        default:
        case 0: // no styling (drawfill)
            if(mirror_size.x > 0 && mirror_size.y > 0) drawfill(panel_pos + eX * mirror_offset, mirror_size, color, alpha, DRAWFLAG_NORMAL);
            if(size.x > 0 && size.y > 0) drawfill(panel_pos + eX * offset, size, color, alpha, DRAWFLAG_NORMAL);
            break;

        case 1: // progress bar style
            if(mirror_size.x > 0 && mirror_size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * mirror_offset, mirror_size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
            if(size.x > 0 && size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * offset, size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
            break;

        case 2: // gradient style (types: 1 = left, 2 = right, 3 = both)
            // determine whether the gradient starts in the mirrored or the non-mirrored area
            if(offset == 0 && mirror_offset == 0) gradient_start = width > mirror_width ? 2 : 1;
            else if(offset == 0) gradient_start = 2;
            else if(mirror_offset == 0) gradient_start = 1;
            else gradient_start = 0;

            switch(gradient_start){
                default:
                case 0: // no offset required
                    gradient_offset = gradient_mirror_offset = 0;
                    break;
                case 1: // offset starts in non-mirrored area, mirrored area requires offset
                    gradient_offset = 0;
                    gradient_mirror_offset = original_width - (mirror_width + overflow_mirror_width);
                    break;
                case 2: // offset starts in mirrored area, non-mirrored area requires offset
                    gradient_offset = original_width - (width + overflow_width);
                    gradient_mirror_offset = 0;
            }

            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, mirror_size, original_width, mirror_offset, alpha, gradient_mirror_offset, gradientType);
            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, size, original_width, offset, alpha, gradient_offset, gradientType);
    }
}

vector StrafeHUD_mixColors(vector color1, vector color2, float ratio)
{
    vector mixedColor;
    if(ratio <= 0) return color1;
    if(ratio >= 1) return color2;
    mixedColor.x = color1.x + (color2.x - color1.x) * ratio;
    mixedColor.y = color1.y + (color2.y - color1.y) * ratio;
    mixedColor.z = color1.z + (color2.z - color1.z) * ratio;
    return mixedColor;
}

void StrafeHUD_drawGradient(vector color1, vector color2, vector size, float original_width, float offset, float alpha, float gradientOffset, int gradientType)
{
    float color_ratio, alpha1, alpha2;
    vector gradient_size = size;
    alpha1 = bound(0, alpha, 1);
    alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha, 1);
    if((alpha1+alpha2) == 0) return;
    color_ratio = alpha1/(alpha1+alpha2);
    for(int i = 0; i < size.x; ++i)
    {
        float ratio, alpha_ratio, combine_ratio1, combine_ratio2;
        gradient_size.x = size.x - i < 1 ? size.x - i : 1;
        ratio = (i + gradientOffset) / original_width * (gradientType == 3 ? 2 : 1);
        if(ratio > 1) ratio = 2 - ratio;
        if(gradientType != 2) ratio = 1 - ratio;
        alpha_ratio = alpha1 - (alpha1 - alpha2) * ratio;
        combine_ratio1 = ratio*(1-color_ratio);
        combine_ratio2 = (1-ratio)*color_ratio;
        ratio = (combine_ratio1 + combine_ratio2) == 0 ? 1 : combine_ratio1/(combine_ratio1 + combine_ratio2);
        if(alpha_ratio > 0) drawfill(panel_pos + eX * (offset + i), gradient_size, StrafeHUD_mixColors(color1, color2, ratio), alpha_ratio, DRAWFLAG_NORMAL);
    }
}

// draw the strafe arrows (inspired by drawspritearrow() in common/mutators/mutator/waypoints/waypointsprites.qc)
void StrafeHUD_drawStrafeArrow(vector origin, float size, vector color, float alpha, bool flipped)
{
    if(flipped) origin -= size*eY;
    R_BeginPolygon("", DRAWFLAG_NORMAL, true);
    R_PolygonVertex(origin + (flipped ? size*eY : '0 0 0')          , '0 0 0', color, alpha);
    R_PolygonVertex(origin + (flipped ? '0 0 0' : size*eY) - size*eX, '0 0 0', color, alpha);
    R_PolygonVertex(origin + (flipped ? '0 0 0' : size*eY) + size*eX, '0 0 0', color, alpha);
    R_EndPolygon();
}

// length unit conversion (km and miles are only included to match the GetSpeedUnit* functions)
float GetLengthUnitFactor(int length_unit)
{
    switch(length_unit)
    {
        default:
        case 1: return 1.0;
        case 2: return 0.0254;
        case 3: return 0.0254 * 0.001;
        case 4: return 0.0254 * 0.001 * 0.6213711922;
        case 5: return 0.0254 * 0.001 * 0.5399568035;
    }
}

string GetLengthUnit(int length_unit)
{
    switch(length_unit)
    {
        // translator-friendly strings without the initial space
        default:
        case 1: return strcat(" ", _("qu"));
        case 2: return strcat(" ", _("m"));
        case 3: return strcat(" ", _("km"));
        case 4: return strcat(" ", _("mi"));
        case 5: return strcat(" ", _("nmi"));
    }
}
