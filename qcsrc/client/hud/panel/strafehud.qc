// Author: Juhu

#include "strafehud.qh"

#include <client/draw.qh>
#include <client/hud/panel/racetimer.qh>
#include <client/view.qh>
#include <common/animdecide.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <common/resources/cl_resources.qh>
#include <lib/csqcmodel/cl_player.qh>

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
bool fwd = true;
bool state_fwd = true;
bool state_fwd_prev = true;
float state_fwd_time = 0;
float starttime = 0;
float startspeed = -1;

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
        float  maxspeed_crouch_mod           = IS_DUCKED(strafeplayer) && !swimming ? .5 : 1;
        float  maxspeed_water_mod            = swimming ? .7 : 1; // very simplified water physics, the hud will not work well (and is not supposed to) while swimming
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = !autocvar__hud_configure ? maxspeed_phys * maxspeed_crouch_mod * maxspeed_water_mod : 320;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y;
        float  view_angle                    = PHYS_INPUT_ANGLES(strafeplayer).y + 180;
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
        float  overturn_offset;
        float  overturn_width;
        float  slickdetector_height;
        vector direction_size_vertical       = '0 0 0';
        vector direction_size_horizontal     = '0 0 0';
        float  range_minangle;

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

        strafekeys = fabs(wishangle) == 90;

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

        if((keys & KEY_FORWARD) || (keys & KEY_BACKWARD) || swimming || autocvar__hud_configure)
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
            else if((time - state_strafekeys_time) >= autocvar_hud_panel_strafehud_timeout_turn) // timeout for jumping with strafe keys only
            {
                turn = false;
            }
        }
        if(turn)
        {
            maxspeed = PHYS_MAXAIRSTRAFESPEED(strafeplayer); // no modifiers here because they don't affect air strafing
            wishangle = turnangle;
        }

        minspeed = autocvar_hud_panel_strafehud_switch_minspeed < 0 ? maxspeed + antiflicker_speed : autocvar_hud_panel_strafehud_switch_minspeed;

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
                    if(wishangle < 0) // detect direction using wishangle since the direction is not yet set
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
        bestangle = (speed > maxspeed ? acos(maxspeed / speed) : 0) * RAD2DEG * (direction < 0 ? -1 : 1);
        odd_bestangle = -bestangle - wishangle;
        bestangle -= wishangle;

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
        bestangle_width = max(panel_size.x * autocvar_hud_panel_strafehud_switch_width, 1);

        if(((angle > -wishangle && direction < 0) || (angle < -wishangle && direction > 0)) && (direction != 0))
        {
            odd_angles = true;
            odd_bestangle_offset = odd_bestangle/hudangle * panel_size.x + panel_size.x/2;
            switch_odd_bestangle_offset = (odd_bestangle+bestangle*2)/hudangle * panel_size.x + panel_size.x/2;
        }
        // direction indicator
        direction_size_vertical.x = max(panel_size.y * min(autocvar_hud_panel_strafehud_direction_width, .5), 1);
        direction_size_vertical.y = panel_size.y;
        direction_size_horizontal.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5), direction_size_vertical.x);
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
            accelzone_width = overturn_offset = (90 - fabs(bestangle + wishangle))/hudangle * panel_size.x;
            accelzone_right_offset = 0;
            accelzone_left_offset = overturn_offset + overturn_width;
            neutral_width = 360/hudangle * panel_size.x - accelzone_width*2 - overturn_width;
            neutral_offset = direction < 0 ? accelzone_left_offset + accelzone_width : -neutral_width;

            // remove switch indicator width from offset
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
            overturn_offset += shift_offset;

            // draw left acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_left_offset, accelzone_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 1);

            // draw right acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_right_offset, accelzone_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 2);

            // draw overturn zone
            HUD_Panel_DrawStrafeHUD(overturn_offset, overturn_width, autocvar_hud_panel_strafehud_bar_overturn_color, autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 3);

            // draw neutral zone
            HUD_Panel_DrawStrafeHUD(neutral_offset, neutral_width, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, 0);

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
                if(direction_size_vertical.y > 0) drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x), direction_size_vertical, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                // top horizontal line
                drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x - direction_size_horizontal.x + direction_size_vertical.x) - eY * direction_size_horizontal.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                // bottom horizontal line
                drawfill(panel_pos + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x - direction_size_horizontal.x + direction_size_vertical.x) + eY * panel_size.y, direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color, autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }

            if(speed >= minspeed) // only draw indicators if minspeed is reached
            {
                // draw best angles for acceleration
                float offset = !odd_angles ? bestangle_offset : odd_bestangle_offset;
                float switch_offset = !odd_angles ? switch_bestangle_offset : switch_odd_bestangle_offset;
                // both indicators are inactive if no direction can be determined
                vector switch_color = direction != 0 ? autocvar_hud_panel_strafehud_switch_active_color : autocvar_hud_panel_strafehud_switch_inactive_color;
                float switch_alpha = direction != 0 ? autocvar_hud_panel_strafehud_switch_active_alpha : autocvar_hud_panel_strafehud_switch_inactive_alpha;
                // draw the switch indicators
                HUD_Panel_DrawStrafeHUD(switch_offset, bestangle_width, autocvar_hud_panel_strafehud_switch_inactive_color, autocvar_hud_panel_strafehud_switch_inactive_alpha * panel_fg_alpha, 0, 0);
                HUD_Panel_DrawStrafeHUD(offset, bestangle_width, switch_color, switch_alpha * panel_fg_alpha, 0, 0);
            }
        }

        // experimental: slick detector
        slickdetector_height = panel_size.y * bound(0, autocvar_hud_panel_strafehud_slickdetector_height, 0.5);
        if(autocvar_hud_panel_strafehud_slickdetector_range > 0 && autocvar_hud_panel_strafehud_slickdetector_alpha > 0 && slickdetector_height > 0 && panel_size.x > 0) // dunno if slick detection works in spectate
        {
            float slicksteps = 90 / pow(2, bound(0, autocvar_hud_panel_strafehud_slickdetector_granularity, 4));
            bool slickdetected = false;

            slickdetected = IS_ONSLICK(strafeplayer); // don't need to traceline if already touching slick

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
                        if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) slickdetected = true;
                    }
                }
                else
                {
                    slickoffset.x = slickoffset.y = 0;
                    traceline(strafeplayer.origin, strafeplayer.origin + slickoffset, MOVE_WORLDONLY, NULL);
                    if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) slickdetected = true;
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

        draw_beginBoldFont();
        // show speed when crossing the start trigger
        if(autocvar_hud_panel_strafehud_startspeed_fade > 0)
        {
            float text_alpha = 0;
            if(race_checkpoint == 254) // checkpoint 254 is the start trigger
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
                startspeed_size.y = panel_size.y * min(autocvar_hud_panel_strafehud_startspeed_size, 5);
                string speed_unit = GetSpeedUnit(autocvar_hud_panel_strafehud_unit);
                drawstring_aspect(panel_pos + eY * panel_size.y, strcat(ftos_decimals(startspeed * speed_conversion_factor, 2), autocvar_hud_panel_strafehud_unit_show ? speed_unit : ""), startspeed_size, autocvar_hud_panel_strafehud_startspeed_color, text_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }
        else
        {
            starttime = 0;
            startspeed = -1;
        }

        // show height achieved by a single jump
        if(autocvar_hud_panel_strafehud_jumpheight_fade > 0 && autocvar_hud_panel_strafehud_jumpheight_size > 0)
        {
            static float height_min = 0, height_max = 0; // ground and peak of jump z coordinates
            static float jumpheight = 0, jumptime = 0;   // displayed value and timestamp for fade out

            // tries to catch kill and spectate but those are not reliable, should just hook to kill/spectate/teleport and reset jump height there
            if((strafeplayer.velocity.z <= 0 && height_max >= strafeplayer.origin.z) || IS_ONGROUND(strafeplayer) || swimming || IS_DEAD(strafeplayer) || spectating)
            {
                height_min = height_max = strafeplayer.origin.z;
            }
            else if(strafeplayer.origin.z > height_max)
            {
                height_max = strafeplayer.origin.z;
                jumpheight = (height_max - height_min) * length_conversion_factor;

                if(jumpheight > max(autocvar_hud_panel_strafehud_jumpheight_min, 0))
                    jumptime = time;
            }

            if((time - jumptime) <= autocvar_hud_panel_strafehud_jumpheight_fade)
            {
                float text_alpha = cos(((time - jumptime) / autocvar_hud_panel_strafehud_jumpheight_fade) * 90 * DEG2RAD); // fade non-linear like the physics panel does
                vector jumpheight_size = panel_size;
                jumpheight_size.y = panel_size.y * min(autocvar_hud_panel_strafehud_jumpheight_size, 5);
                string length_unit = GetLengthUnit(autocvar_hud_panel_strafehud_unit);
                drawstring_aspect(panel_pos - eY * jumpheight_size.y, strcat(ftos_decimals(jumpheight, length_decimals), autocvar_hud_panel_strafehud_unit_show ? length_unit : ""), jumpheight_size, autocvar_hud_panel_strafehud_jumpheight_color, text_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
            }
        }
        draw_endBoldFont();

        if(speed < (maxspeed + antiflicker_speed) && !immobile)
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

        if(currentangle_size.x > 0 && currentangle_size.y > 0 && autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha > 0)
        {
            drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (currentangle_offset - currentangle_size.x/2), currentangle_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
        }
    }
}

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_DrawStrafeHUD(float offset, float width, vector color, float alpha, int type, int gradientType)
{
    float mirror_offset, mirror_width;
    vector size = panel_size;
    vector mirror_size = panel_size;

    float original_width = width;
    float hiddencolor_width;

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

    if(width < 0) width = 0;
    if(mirror_width < 0) mirror_width = 0;
    hiddencolor_width = original_width - width - mirror_width;

    if(direction < 0) // swap mirror and non-mirror values if direction points left
    {
        offset += mirror_offset;
        mirror_offset = offset - mirror_offset;
        offset -= mirror_offset;

        width += mirror_width;
        mirror_width = width - mirror_width;
        width -= mirror_width;
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
            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, mirror_size, original_width, mirror_offset, alpha, width + (mirror_offset == 0 ? hiddencolor_width : 0), gradientType);
            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, size, original_width, offset, alpha, (offset == 0 ? hiddencolor_width : 0), gradientType);
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
