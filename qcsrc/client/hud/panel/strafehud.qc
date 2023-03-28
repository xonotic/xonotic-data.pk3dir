// Author: Juhu

#include "strafehud.qh"

#include <client/draw.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>
#include <common/physics/movetypes/movetypes.qh>

// non-essential
#include <client/view.qh> // for v_flipped state

// non-local players
#include <common/animdecide.qh> // anim_implicit_state
#include <common/ent_cs.qh> // CSQCModel_server2csqc()

// start speed
#include <client/hud/panel/racetimer.qh> // checkpoint information (race_*)

// jump height
#include <lib/csqcmodel/common.qh> // for IS_PLAYER() macro
#include <common/resources/cl_resources.qh> // IS_DEAD() macro

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

float GeomLerp(float a, float _lerp, float b); // declare GeomLerp here since there's no header file for it

void HUD_StrafeHUD()
{
    static float hud_lasttime = 0;
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
           (autocvar_hud_panel_strafehud == 3 && !MUTATOR_CALLHOOK(HUD_StrafeHUD_showoptional))) { hud_lasttime = time; return; }
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
        float strafe_waterlevel;

        // check the player waterlevel without affecting the player entity, this way we can fetch waterlevel even if client prediction is disabled
        {
            // store old values
            void old_contentstransition(int, int) = strafeplayer.contentstransition;
            float old_watertype = strafeplayer.watertype;
            float old_waterlevel = strafeplayer.waterlevel;

            strafeplayer.contentstransition = func_null; // unset the contentstransition function if present
            _Movetype_CheckWater(strafeplayer);
            strafe_waterlevel = strafeplayer.waterlevel; // store the player waterlevel

            // restore old values
            strafeplayer.contentstransition = old_contentstransition;
            strafeplayer.watertype = old_watertype;
            strafeplayer.waterlevel = old_waterlevel;
        }

        // persistent
        static float onground_lasttime       = 0;
        static bool  onslick_last            = false;
        static float turn_lasttime           = 0;
        static bool  turn                    = false;
        static float turnangle;
        static float dt_update               = 0;
        static int   dt_time                 = 0;
        static float dt_sum                  = 0;
        static float dt                      = 0;

        // physics
        int    keys                          = STAT(PRESSED_KEYS);
        bool   jumpheld                      = (islocal ? ((PHYS_INPUT_BUTTON_JUMP(strafeplayer) || PHYS_INPUT_BUTTON_JETPACK(strafeplayer))) && !PHYS_CL_TRACK_CANJUMP(strafeplayer) : (keys & KEY_JUMP)) && !PHYS_TRACK_CANJUMP(strafeplayer); // try to ignore if track_canjump is enabled, doesn't work in spectator mode if spectated player uses +jetpack or cl_movement_track_canjump
        bool   real_onground                 = islocal ? IS_ONGROUND(strafeplayer) : !(strafeplayer.anim_implicit_state & ANIMIMPLICITSTATE_INAIR); // doesn't get changed by ground timeout and isn't affected by jump input
        bool   real_onslick                  = false; // doesn't get changed by ground timeout
        bool   onground                      = real_onground && !jumpheld; // if jump is held assume we are in air, avoids flickering of the hud when hitting the ground
        bool   onslick                       = real_onslick;
        bool   onground_expired;
        bool   strafekeys;
        bool   swimming                      = strafe_waterlevel >= WATERLEVEL_SWIMMING; // the hud will not work well while swimming
        float  speed                         = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337; // use local csqcmodel entity for this even when spectating, flickers too much otherwise
        float  maxspeed_mod                  = IS_DUCKED(csqcplayer) ? .5 : 1; // only the local csqcplayer entity contains this information even when spectating
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = !autocvar__hud_configure ? maxspeed_phys * maxspeed_mod : 320;
        float  movespeed;
        float  bestspeed;
        float  maxaccel_phys                 = onground ? PHYS_ACCELERATE(strafeplayer) : PHYS_AIRACCELERATE(strafeplayer);
        float  maxaccel                      = !autocvar__hud_configure ? maxaccel_phys : 1;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y - (vectoangles(strafeplayer.velocity).y > 180 ? 360 : 0); // change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
        float  view_angle                    = PHYS_INPUT_ANGLES(strafeplayer).y;
        float  angle;
        vector movement                      = PHYS_INPUT_MOVEVALUES(strafeplayer);
        bool   fwd;
        int    keys_fwd;
        float  wishangle;
        int    direction;

        // HUD
        int    mode                          = autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1 ? autocvar_hud_panel_strafehud_mode : STRAFEHUD_MODE_VIEW_CENTERED;
        float  speed_conversion_factor       = GetSpeedUnitFactor(autocvar_hud_panel_strafehud_unit);
        float  length_conversion_factor      = GetLengthUnitFactor(autocvar_hud_panel_strafehud_unit);
        int    length_decimals               = autocvar_hud_panel_strafehud_unit >= 3 && autocvar_hud_panel_strafehud_unit <= 5 ? 6 : 2; // use more decimals when displaying km or miles
        float  antiflicker_angle             = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);
        float  minspeed;
        float  shift_offset                  = 0;
        bool   straight_overturn             = false;
        bool   immobile                      = speed <= 0;
        float  hudangle;
        float  hidden_width;
        float  neutral_offset;
        float  neutral_width;
        vector currentangle_color            = autocvar_hud_panel_strafehud_angle_neutral_color;
        float  currentangle_offset;
        vector currentangle_size;
        float  real_bestangle; // positive with no wishangle offset
        float  real_prebestangle;  // positive with no wishangle offset
        float  bestangle;
        float  prebestangle;
        float  odd_bestangle;
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
        vector direction_size_vertical;
        vector direction_size_horizontal;
        float  range_minangle;
        float  arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_arrow_size, 10), 0); // there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
        float  text_offset_top = 0;
        float  text_offset_bottom = 0;
        float  hfov                     = getproperty(VF_FOVX);

        if(onground)
        {
            if(PHYS_FRICTION(strafeplayer) == 0) {
                onslick = true;
            }
            else { // don't use IS_ONSLICK(), it only works for the local player and only if client prediction is enabled
                trace_dphitq3surfaceflags = 0;
                tracebox(strafeplayer.origin, strafeplayer.mins, strafeplayer.maxs, strafeplayer.origin - '0 0 1', MOVE_NOMONSTERS, strafeplayer);
                onslick = trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK;
            }
            real_onslick = onslick;

            onground_lasttime = time;
            onslick_last = onslick;
        }
        else if(jumpheld || swimming) onground_lasttime = 0;

        if(onground_lasttime == 0)
            onground_expired = true;
        else
            onground_expired = (time - onground_lasttime) >= autocvar_hud_panel_strafehud_timeout_ground; // timeout for slick ramps

        if(!onground && !onground_expired) // if ground timeout hasn't expired yet use ground physics
        {
            onground = true;
            onslick = onslick_last;

            if(!autocvar__hud_configure)
            {
                maxspeed = PHYS_MAXSPEED(strafeplayer) * maxspeed_mod;
                maxaccel = PHYS_ACCELERATE(strafeplayer);
            }
        }

        movespeed = vlen(vec2(movement));
        if(movespeed == 0) movespeed = maxspeed;
        else movespeed = min(movespeed, maxspeed);

        if(!autocvar_hud_panel_strafehud_uncapped)
            arrow_size = max(arrow_size, 1);

        // determine frametime
        if((csqcplayer_status == CSQCPLAYERSTATUS_PREDICTED) && (input_timelength > 0))
        {
            float dt_client = input_timelength;

            if(dt_client > .05) // server splits frames longer than 50 ms into two moves
                dt_client /= 2; // doesn't ensure frames are smaller than 50 ms, just splits large frames in half, matches server behaviour

            // calculate average frametime
            dt_sum += dt_client*dt_client;
            dt_time += dt_client;

            if(((time - dt_update) > autocvar_hud_panel_strafehud_fps_update) || (dt_update == 0))
            {
                dt = dt_sum / dt_time;
                dt_update = time;
                dt_time = dt_sum = 0;
            }
        }
        else // when spectating other players server ticrate will be used, this may not be accurate but there is no way to find other player's frametime
        {
            dt = ticrate;
            dt_update = dt_time = dt_sum = 0;
        }

        // determine whether the player is pressing forwards or backwards keys
        if(islocal) // if entity is local player
        {
            if(movement.x > 0)
            {
                keys_fwd = STRAFEHUD_KEYS_FORWARD;
            }
            else if(movement.x < 0)
            {
                keys_fwd = STRAFEHUD_KEYS_BACKWARD;
            }
            else
            {
                keys_fwd = STRAFEHUD_KEYS_NONE;
            }
        }
        else // alternatively determine direction by querying pressed keys
        {
            if((keys & KEY_FORWARD) && !(keys & KEY_BACKWARD))
            {
                keys_fwd = STRAFEHUD_KEYS_FORWARD;
            }
            else if(!(keys & KEY_FORWARD) && (keys & KEY_BACKWARD))
            {
                keys_fwd = STRAFEHUD_KEYS_BACKWARD;
            }
            else
            {
                keys_fwd = STRAFEHUD_KEYS_NONE;
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
        else if(autocvar_hud_panel_strafehud_range < 0)
        {
            hudangle = hfov;
        }
        else
        {
            hudangle = bound(0, fabs(autocvar_hud_panel_strafehud_range), 360); // limit HUD range to 360 degrees, higher values don't make sense
        }

        // limit strafe-meter angle to values suitable for the current projection mode
        switch(autocvar_hud_panel_strafehud_projection) {
            case STRAFEHUD_PROJECTION_PERSPECTIVE:
                hudangle = min(hudangle, 170);
                break;
            case STRAFEHUD_PROJECTION_PANORAMIC:
                hudangle = min(hudangle, 350);
                break;
        }

        // detect air strafe turning
        if((!strafekeys && vlen(vec2(movement)) > 0) || onground || autocvar__hud_configure)
        {
            turn = false;
        }
        else // air strafe only
        {
            bool turn_expired = (time - turn_lasttime) >= autocvar_hud_panel_strafehud_timeout_turn; // timeout for jumping with strafe keys only

            if(strafekeys)
                turn = true;
            else if(turn_expired)
                turn = false;

            if(turn) // CPMA turning
            {
                if(strafekeys)
                {
                    turn_lasttime = time;
                    turnangle = wishangle;
                }
                else // retain last state until strafe turning times out
                {
                    wishangle = turnangle;
                }

                // calculate the maximum air strafe speed and acceleration
                float strafity = 1 - (90 - fabs(wishangle)) / 45;

                if(PHYS_MAXAIRSTRAFESPEED(strafeplayer) != 0)
                {
                    maxspeed = min(maxspeed, GeomLerp(PHYS_MAXAIRSPEED(strafeplayer), strafity, PHYS_MAXAIRSTRAFESPEED(strafeplayer)));
                }
                movespeed = min(movespeed, maxspeed);

                if(PHYS_AIRSTRAFEACCELERATE(strafeplayer) != 0)
                {
                    maxaccel = GeomLerp(PHYS_AIRACCELERATE(strafeplayer), strafity, PHYS_AIRSTRAFEACCELERATE(strafeplayer));
                }
            }
        }

        maxaccel *= dt * movespeed;
        bestspeed = max(movespeed - maxaccel, 0); // target speed to gain maximum acceleration

        float frictionspeed; // speed lost from friction
        float strafespeed; // speed minus friction

        if((speed > 0) && onground)
        {
            float strafefriction = onslick ? PHYS_FRICTION_SLICK(strafeplayer) : PHYS_FRICTION(strafeplayer);

            frictionspeed = speed * dt * strafefriction * max(PHYS_STOPSPEED(strafeplayer) / speed, 1);
            strafespeed = max(speed - frictionspeed, 0);
        }
        else
        {
            frictionspeed = 0;
            strafespeed = speed;
        }

        minspeed = autocvar_hud_panel_strafehud_switch_minspeed;
        if(minspeed < 0) minspeed = bestspeed + frictionspeed;

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
                    if(keys_fwd == STRAFEHUD_KEYS_FORWARD)
                    {
                        fwd = true;
                    }
                    else if(keys_fwd == STRAFEHUD_KEYS_BACKWARD)
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
                fwd = true;
            }
        }
        else // simulate turning for HUD setup
        {
            const float demo_maxangle = 55; // maximum angle before changing direction
            const float demo_turnspeed = 40; // turning speed in degrees per second

            static float demo_position = -37 / demo_maxangle; // current positioning value between -1 and +1

            if(autocvar__hud_panel_strafehud_demo)
            {
                float demo_dt = time - hud_lasttime;
                float demo_step = (demo_turnspeed / demo_maxangle) * demo_dt;
                demo_position = ((demo_position + demo_step) % 4 + 4) % 4;
            }

            // triangle wave function
            if(demo_position > 3)
                angle = -1 + (demo_position - 3);
            else if(demo_position > 1)
                angle = +1 - (demo_position - 1);
            else
                angle = demo_position;
            angle *= demo_maxangle;

            fwd = true;
            wishangle = 45;
            if(angle < 0) wishangle *= -1;
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
        if(wishangle > 0)
        {
            direction = STRAFEHUD_DIRECTION_RIGHT;
        }
        else if(wishangle < 0)
        {
            direction = STRAFEHUD_DIRECTION_LEFT;
        }
        else
        {
            if(angle > antiflicker_angle && angle < (180 - antiflicker_angle))
                direction = STRAFEHUD_DIRECTION_RIGHT;
            else if(angle < -antiflicker_angle && angle > (-180 + antiflicker_angle))
                direction = STRAFEHUD_DIRECTION_LEFT;
            else
                direction = STRAFEHUD_DIRECTION_NONE;
        }

        // best angle to strafe at
        // in case of ground friction we may decelerate if the acceleration is smaller than the speed loss from friction
        real_bestangle = bestangle = (strafespeed > bestspeed ? acos(bestspeed / strafespeed) * RAD2DEG : 0);
        real_prebestangle = prebestangle = (strafespeed > movespeed ? acos(movespeed / strafespeed) * RAD2DEG : 0);
        if(direction == STRAFEHUD_DIRECTION_LEFT) // the angle becomes negative in case we strafe left
        {
            bestangle *= -1;
            prebestangle *= -1;
        }
        odd_bestangle = -bestangle - wishangle;
        bestangle -= wishangle;
        prebestangle -= wishangle;

        // various offsets and size calculations of hud indicator elements
        // how much is hidden by the current hud angle
        hidden_width = (360 - hudangle) / hudangle * panel_size.x;
        // current angle
        currentangle_size.x = autocvar_hud_panel_strafehud_angle_width;
        currentangle_size.y = autocvar_hud_panel_strafehud_angle_height;
        currentangle_size.z = 0;
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
        if(mode == STRAFEHUD_MODE_VIEW_CENTERED)
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

        if((angle > -wishangle && direction == STRAFEHUD_DIRECTION_LEFT) || (angle < -wishangle && direction == STRAFEHUD_DIRECTION_RIGHT))
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
        direction_size_vertical.z = 0;
        direction_size_horizontal.x = panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5);
        direction_size_horizontal.y = direction_size_vertical.x;
        direction_size_horizontal.z = 0;

        // the neutral zone fills the whole strafe bar
        if(immobile)
        {
            // draw neutral zone
            if(panel_size.x > 0 && panel_size.y > 0 && autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha > 0)
            {
                switch(autocvar_hud_panel_strafehud_style)
                {
                    default:
                    case STRAFEHUD_STYLE_DRAWFILL:
                        drawfill(panel_pos, panel_size, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        break;

                    case STRAFEHUD_STYLE_PROGRESSBAR:
                        HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
            }
        }
        else
        {
            // calculate various zones of the strafe-o-meter
            if(autocvar_hud_panel_strafehud_bar_preaccel)
                preaccelzone_width = (fabs(bestangle - prebestangle))/hudangle * panel_size.x;
            else
                preaccelzone_width = 0;
            accelzone_width = (90 - fabs(bestangle + wishangle))/hudangle * panel_size.x;
            overturn_width = 180/hudangle * panel_size.x;
            neutral_width = 360/hudangle * panel_size.x - accelzone_width*2 - preaccelzone_width*2 - overturn_width;

            {
                float current_offset = 0;
                preaccelzone_right_offset = current_offset;
                current_offset += preaccelzone_width;

                accelzone_right_offset = current_offset;
                current_offset += accelzone_width;

                overturn_offset = current_offset;
                current_offset += overturn_width;

                accelzone_left_offset = current_offset;
                current_offset += accelzone_width;

                preaccelzone_left_offset = current_offset;
                current_offset += preaccelzone_width;

                neutral_offset = direction == STRAFEHUD_DIRECTION_LEFT ? current_offset : -neutral_width; // the wrapping code may struggle if we always append it on the right side
            }

            // shift hud if operating in view angle centered mode
            if(mode == STRAFEHUD_MODE_VIEW_CENTERED)
            {
                shift_offset = -currentangle_offset;
                bestangle_offset += shift_offset;
                switch_bestangle_offset += shift_offset;
                odd_bestangle_offset += shift_offset;
                switch_odd_bestangle_offset += shift_offset;
            }
            if(direction == STRAFEHUD_DIRECTION_LEFT) shift_offset += -360/hudangle * panel_size.x;
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
            HUD_Panel_DrawStrafeHUD(accelzone_left_offset, accelzone_width, hidden_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT, true, hudangle);
            if(autocvar_hud_panel_strafehud_bar_preaccel)
                HUD_Panel_DrawStrafeHUD(preaccelzone_left_offset, preaccelzone_width, hidden_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT, true, hudangle);

            // draw right acceleration zone
            HUD_Panel_DrawStrafeHUD(accelzone_right_offset, accelzone_width, hidden_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT, true, hudangle);
            if(autocvar_hud_panel_strafehud_bar_preaccel)
                HUD_Panel_DrawStrafeHUD(preaccelzone_right_offset, preaccelzone_width, hidden_width, autocvar_hud_panel_strafehud_bar_accel_color, autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT, true, hudangle);

            // draw overturn zone (technically incorrect, acceleration decreases at 90 degrees but speed loss happens a little bit after 90 degrees, however due to sv_airstopaccelerate that's hard to calculate)
            HUD_Panel_DrawStrafeHUD(overturn_offset, overturn_width, hidden_width, autocvar_hud_panel_strafehud_bar_overturn_color, autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_BOTH, true, hudangle);

            // draw neutral zone
            HUD_Panel_DrawStrafeHUD(neutral_offset, neutral_width, hidden_width, autocvar_hud_panel_strafehud_bar_neutral_color, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_NONE, true, hudangle);

            if(autocvar_hud_panel_strafehud_switch && speed >= minspeed && bestangle_width > 0 && autocvar_hud_panel_strafehud_switch_alpha > 0) // only draw indicators if minspeed is reached
            {
                // draw the switch indicator(s)
                float offset = !odd_angles ? bestangle_offset : odd_bestangle_offset;
                float switch_offset = !odd_angles ? switch_bestangle_offset : switch_odd_bestangle_offset;

                offset = StrafeHUD_projectOffset(offset, hudangle);
                switch_offset = StrafeHUD_projectOffset(switch_offset, hudangle);

                // remove switch indicator width from offset
                if(direction == STRAFEHUD_DIRECTION_LEFT)
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

                HUD_Panel_DrawStrafeHUD(switch_offset, bestangle_width, hidden_width, autocvar_hud_panel_strafehud_switch_color, autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha, STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, false, hudangle);
                if(direction == STRAFEHUD_DIRECTION_NONE) HUD_Panel_DrawStrafeHUD(offset, bestangle_width, hidden_width, autocvar_hud_panel_strafehud_switch_color, autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha, STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, false, hudangle);
            }
        }

        // slick detector
        slickdetector_height = max(autocvar_hud_panel_strafehud_slickdetector_height, 0);
        if(!autocvar_hud_panel_strafehud_uncapped)
             slickdetector_height = min(slickdetector_height, 1);
        slickdetector_height *= panel_size.y;
        if(autocvar_hud_panel_strafehud_slickdetector && autocvar_hud_panel_strafehud_slickdetector_range > 0 && autocvar_hud_panel_strafehud_slickdetector_alpha > 0 && slickdetector_height > 0 && panel_size.x > 0)
        {
            float slicksteps = max(autocvar_hud_panel_strafehud_slickdetector_granularity, 0);
            bool slickdetected = false;

            if(!autocvar_hud_panel_strafehud_uncapped)
                slicksteps = min(slicksteps, 4);
            slicksteps = 90 / 2 ** slicksteps;

            slickdetected = real_onslick; // don't need to traceline if already touching slick

            // traceline into every direction
            trace_dphitq3surfaceflags = 0;
            vector traceorigin = strafeplayer.origin + eZ * strafeplayer.mins.z;
            for(float i = 0; i < 90 && !slickdetected; i += slicksteps)
            {
                vector slickoffset;
                float slickrotate;
                slickoffset.z = -cos(i * DEG2RAD) * autocvar_hud_panel_strafehud_slickdetector_range;
                slickrotate = sin(i * DEG2RAD) * autocvar_hud_panel_strafehud_slickdetector_range;

                for(float j = 0; j < 360 && !slickdetected; j += slicksteps)
                {
                    slickoffset.x = sin(j * DEG2RAD) * slickrotate;
                    slickoffset.y = cos(j * DEG2RAD) * slickrotate;

                    traceline(traceorigin, traceorigin + slickoffset, MOVE_NOMONSTERS, strafeplayer);
                    if((PHYS_FRICTION(strafeplayer) == 0 && trace_fraction < 1) || trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) slickdetected = true;
                    if(i == 0) break;
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

            text_offset_top = text_offset_bottom = slickdetector_height;
        }

        if(autocvar_hud_panel_strafehud_direction && direction != STRAFEHUD_DIRECTION_NONE && direction_size_vertical.x > 0 && autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha > 0)
        {
            bool indicator_direction = direction == STRAFEHUD_DIRECTION_LEFT;
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

        string newsound = autocvar_hud_panel_strafehud_sonar_audio;
        static string cursound = string_null;
        static string sonarsound = string_null;
        if(newsound == "") {
            cursound = sonarsound = string_null;
        }
        else if(newsound != cursound) {
            strfree(cursound);
            cursound = strzone(newsound);

            strfree(sonarsound);
            sonarsound = _Sound_fixpath(newsound);
            if(sonarsound) {
                sonarsound = strzone(sonarsound);
                precache_sound(sonarsound);
            }
        }

        // draw the actual strafe angle
        if(!immobile) {
            float moveangle = fabs(angle + wishangle);
            float strafe_ratio = 0;

            // player is overturning
            if(moveangle >= 90)
            {
                currentangle_color = autocvar_hud_panel_strafehud_angle_overturn_color;
                strafe_ratio = (moveangle - 90) / 90;
                if(strafe_ratio > 1) strafe_ratio = 2 - strafe_ratio;
                strafe_ratio *= -1;
            }
            // player gains speed by strafing
            else if(moveangle >= real_bestangle)
            {
                currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
                strafe_ratio = (90 - moveangle) / (90 - real_bestangle);
            }
            else if(moveangle >= real_prebestangle)
            {
                if(autocvar_hud_panel_strafehud_bar_preaccel)
                    currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
                strafe_ratio = (moveangle - real_prebestangle) / (real_bestangle - real_prebestangle);
            }

            if(autocvar_hud_panel_strafehud_style == STRAFEHUD_STYLE_GRADIENT)
            {
                currentangle_color = StrafeHUD_mixColors(autocvar_hud_panel_strafehud_angle_neutral_color, currentangle_color, fabs(strafe_ratio));
            }

            // reuse strafe ratio for strafe sonar
            static float sonar_time = 0;

            float sonar_start = bound(0, autocvar_hud_panel_strafehud_sonar_start, 1);
            float sonar_ratio = strafe_ratio - sonar_start;
            if(sonar_start != 1)
                sonar_ratio /= 1 - sonar_start;
            else
                sonar_ratio = 1;

            float sonar_interval = max(0, autocvar_hud_panel_strafehud_sonar_interval_start);
            sonar_interval += autocvar_hud_panel_strafehud_sonar_interval_range * sonar_ratio ** max(1, autocvar_hud_panel_strafehud_sonar_interval_exponent);
            bool sonar_ready = (sonar_time == 0) || ((time - sonar_time) >= sonar_interval);
            if(autocvar_hud_panel_strafehud_sonar && sonar_ready && (strafe_ratio >= sonar_start)) {
                sonar_time = time;

                float sonar_volume = bound(0, autocvar_hud_panel_strafehud_sonar_volume_start, 1);
                sonar_volume += autocvar_hud_panel_strafehud_sonar_volume_range * sonar_ratio ** max(1, autocvar_hud_panel_strafehud_sonar_volume_exponent);

                float sonar_pitch = max(0, autocvar_hud_panel_strafehud_sonar_pitch_start);
                sonar_pitch += autocvar_hud_panel_strafehud_sonar_pitch_range * sonar_ratio ** max(1, autocvar_hud_panel_strafehud_sonar_pitch_exponent);

                if(sonarsound && (sonar_volume > 0)) {
                    sound7(csqcplayer, CH_INFO, sonarsound, bound(0, sonar_volume, 1) * VOL_BASE, ATTN_NONE, max(0.000001, sonar_pitch * 100), 0);
                }
            }
        }

        if(mode == STRAFEHUD_MODE_VIEW_CENTERED || straight_overturn)
        {
            currentangle_offset = panel_size.x/2;
        }

        float angleheight_offset = currentangle_size.y;
        float ghost_offset = 0;
        if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
        {
            ghost_offset = bound(0, (odd_angles ? odd_bestangle_offset : bestangle_offset), panel_size.x);
        }

        currentangle_offset = StrafeHUD_projectOffset(currentangle_offset, hudangle);
        ghost_offset = StrafeHUD_projectOffset(ghost_offset, hudangle);

        switch(autocvar_hud_panel_strafehud_angle_style)
        {
            case STRAFEHUD_INDICATOR_SOLID:
                if(currentangle_size.x > 0 && currentangle_size.y > 0)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE) drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (ghost_offset - currentangle_size.x/2), currentangle_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (currentangle_offset - currentangle_size.x/2), currentangle_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                break;
            case STRAFEHUD_INDICATOR_DASHED:
                if(currentangle_size.x > 0 && currentangle_size.y > 0)
                {
                    vector line_size = currentangle_size;
                    line_size.y = currentangle_size.y / (bound(2, autocvar_hud_panel_strafehud_angle_dashes, currentangle_size.y)*2-1);
                    for(float i = 0; i < currentangle_size.y; i += line_size.y*2)
                    {
                        if(i + line_size.y*2 >= currentangle_size.y) line_size.y = currentangle_size.y - i;
                        if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE) drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (ghost_offset - line_size.x/2), line_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                        drawfill(panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (currentangle_offset - line_size.x/2), line_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    }
                }
                break;
            case STRAFEHUD_INDICATOR_NONE:
            default:
                // don't offset text and arrows if the angle indicator line isn't drawn
                angleheight_offset = panel_size.y;
                currentangle_size = '0 0 0';
        }

        float angle_offset_top = 0, angle_offset_bottom = 0;

        // offset text if any angle indicator is drawn
        if((autocvar_hud_panel_strafehud_angle_alpha > 0) || (autocvar_hud_panel_strafehud_bestangle && autocvar_hud_panel_strafehud_bestangle_alpha > 0))
            angle_offset_top = angle_offset_bottom = (angleheight_offset - panel_size.y) / 2; // offset text by amount the angle indicator extrudes from the strafehud bar

        if(autocvar_hud_panel_strafehud_angle_arrow > 0)
        {
            if(arrow_size > 0)
            {
                if(autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE) StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * ghost_offset, arrow_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, true, currentangle_size.x);
                    StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * currentangle_offset, arrow_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, true, currentangle_size.x);

                    angle_offset_top += arrow_size; // further offset the top text offset if the top arrow is drawn
                }
                if(autocvar_hud_panel_strafehud_angle_arrow >= 2)
                {
                    if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE) StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * ghost_offset, arrow_size, autocvar_hud_panel_strafehud_bestangle_color, autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, false, currentangle_size.x);
                    StrafeHUD_drawStrafeArrow(panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * currentangle_offset, arrow_size, currentangle_color, autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, false, currentangle_size.x);

                    angle_offset_bottom += arrow_size; // further offset the bottom text offset if the bottom arrow is drawn
                }
            }
        }

        // make sure text doesn't draw inside the strafehud bar
        text_offset_top = max(angle_offset_top, text_offset_top);
        text_offset_bottom = max(angle_offset_bottom, text_offset_bottom);

        // vertical angle for weapon jumps
        {
            if(autocvar_hud_panel_strafehud_vangle)
            {
                float vangle = -PHYS_INPUT_ANGLES(strafeplayer).x;
                float vangle_height = autocvar_hud_panel_strafehud_vangle_size * panel_size.y;
                string vangle_text = strcat(ftos_decimals(vangle, 2), "°");

                if(StrafeHUD_drawTextIndicator(vangle_text, vangle_height, autocvar_hud_panel_strafehud_vangle_color, 1, time, text_offset_bottom, STRAFEHUD_TEXT_BOTTOM))
                    text_offset_bottom += vangle_height;
            }
        }

        draw_beginBoldFont();

        // show speed when crossing the start trigger
        {
            static float startspeed = 0, starttime = 0; // displayed value and timestamp for fade out

            if((race_nextcheckpoint == 1) || (race_checkpoint == 254 && race_nextcheckpoint == 255)) // check if the start trigger was hit (will also trigger if the finish trigger was hit if those have the same ID)
            {
                if((race_checkpointtime > 0) && (starttime != race_checkpointtime))
                {
                    starttime = race_checkpointtime;
                    startspeed = speed;
                }
            }

            if(autocvar_hud_panel_strafehud_startspeed)
            {
                float startspeed_height = autocvar_hud_panel_strafehud_startspeed_size * panel_size.y;
                string startspeed_text = ftos_decimals(startspeed * speed_conversion_factor, 2);
                if(autocvar_hud_panel_strafehud_unit_show)
                    startspeed_text = strcat(startspeed_text, GetSpeedUnit(autocvar_hud_panel_strafehud_unit));

                if(StrafeHUD_drawTextIndicator(startspeed_text, startspeed_height, autocvar_hud_panel_strafehud_startspeed_color, autocvar_hud_panel_strafehud_startspeed_fade, starttime, text_offset_bottom, STRAFEHUD_TEXT_BOTTOM))
                    text_offset_bottom += startspeed_height;
            }
        }

        // show height achieved by a single jump
        // FIXME: checking z position differences is unreliable (warpzones, teleporter, kill, etc) but using velocity to calculate jump height would be
        //        inaccurate in hud code (possibly different tick rate than physics, doesn't run when hud isn't drawn, rounding errors)
        {
            static float height_min = 0, height_max = 0; // ground and peak of jump z coordinates
            static float jumpheight = 0, jumptime = 0;   // displayed value and timestamp for fade out

            // tries to catch kill and spectate but those are not reliable
            if((strafeplayer.velocity.z <= 0) || real_onground || swimming || IS_DEAD(strafeplayer) || !IS_PLAYER(strafeplayer))
            {
                height_min = height_max = strafeplayer.origin.z;
            }
            else if(strafeplayer.origin.z > height_max)
            {
                height_max = strafeplayer.origin.z;
                float jumpheight_new = height_max - height_min;

                if((jumpheight_new * length_conversion_factor) > max(autocvar_hud_panel_strafehud_jumpheight_min, 0))
                {
                    jumpheight = jumpheight_new;
                    jumptime = time;
                }
            }

            if(autocvar_hud_panel_strafehud_jumpheight)
            {
                float jumpheight_height = autocvar_hud_panel_strafehud_jumpheight_size * panel_size.y;
                string jumpheight_text = ftos_decimals(jumpheight * length_conversion_factor, length_decimals);
                if(autocvar_hud_panel_strafehud_unit_show)
                    jumpheight_text = strcat(jumpheight_text, GetLengthUnit(autocvar_hud_panel_strafehud_unit));

                if(StrafeHUD_drawTextIndicator(jumpheight_text, jumpheight_height, autocvar_hud_panel_strafehud_jumpheight_color, autocvar_hud_panel_strafehud_jumpheight_fade, jumptime, text_offset_top, STRAFEHUD_TEXT_TOP))
                    text_offset_top += jumpheight_height;
            }
        }

        draw_endBoldFont();
    }
    hud_lasttime = time;
}

float StrafeHUD_projectOffset(float offset, float range) {
    range *= DEG2RAD / 2;
    float angle = (offset - (panel_size.x/2)) / (panel_size.x/2) * range;
    switch(autocvar_hud_panel_strafehud_projection) {
        default:
        case STRAFEHUD_PROJECTION_LINEAR:
            return offset;
        case STRAFEHUD_PROJECTION_PERSPECTIVE:
            offset = tan(angle) / tan(range);
            break;
        case STRAFEHUD_PROJECTION_PANORAMIC:
            offset = tan(angle/2) / tan(range/2);
            break;
    }
    offset = offset * (panel_size.x/2) + (panel_size.x/2);
    return offset;
}

float StrafeHUD_projectWidth(float offset, float width, float range) {
    return StrafeHUD_projectOffset(offset + width, range) - StrafeHUD_projectOffset(offset, range);
}

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_DrawStrafeHUD(float offset, float width, float hidden_width, vector color, float alpha, int type, int gradientType, bool doProject, float range)
{
    float mirror_offset, mirror_width;
    vector size = panel_size;
    vector mirror_size = panel_size;
    float overflow_width = 0, overflow_mirror_width = 0;
    float original_width = width; // required for gradient

    if(type == STRAFEHUD_STYLE_GRADIENT && gradientType == STRAFEHUD_GRADIENT_NONE) type = STRAFEHUD_STYLE_DRAWFILL;

    if(alpha <= 0 && type != STRAFEHUD_STYLE_GRADIENT || width <= 0) return;

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

    width = max(width, 0);
    if((offset + width) > panel_size.x)
    {
        overflow_width = (offset + width) - panel_size.x;
        width = panel_size.x - offset;
    }
    size.x = width;

    vector original_size = size;
    float original_offset = offset;
    if(doProject) {
        if(size.x > 0) size.x = StrafeHUD_projectWidth(offset, size.x, range);
        offset = StrafeHUD_projectOffset(offset, range);
    }

    if(mirror_offset < 0)
    {
        mirror_width += mirror_offset;
        mirror_offset = 0;
    }

    mirror_width = max(mirror_width, 0);
    if((mirror_offset + mirror_width) > panel_size.x)
    {
        overflow_mirror_width = (mirror_offset + mirror_width) - panel_size.x;
        mirror_width = panel_size.x - mirror_offset;
    }
    mirror_size.x = mirror_width;

    vector original_mirror_size = mirror_size;
    float original_mirror_offset = mirror_offset;
    if(doProject) {
        if(mirror_size.x > 0) mirror_size.x = StrafeHUD_projectWidth(mirror_offset, mirror_size.x, range);
        mirror_offset = StrafeHUD_projectOffset(mirror_offset, range);
    }

    switch(type)
    {
        default:
        case STRAFEHUD_STYLE_DRAWFILL: // no styling (drawfill)
            if(mirror_size.x > 0 && mirror_size.y > 0) drawfill(panel_pos + eX * mirror_offset, mirror_size, color, alpha, DRAWFLAG_NORMAL);
            if(size.x > 0 && size.y > 0) drawfill(panel_pos + eX * offset, size, color, alpha, DRAWFLAG_NORMAL);
            break;

        case STRAFEHUD_STYLE_PROGRESSBAR: // progress bar style
            if(mirror_size.x > 0 && mirror_size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * mirror_offset, mirror_size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
            if(size.x > 0 && size.y > 0) HUD_Panel_DrawProgressBar(panel_pos + eX * offset, size, "progressbar", 1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
            break;

        case STRAFEHUD_STYLE_GRADIENT: // gradient style (types: 1 = left, 2 = right, 3 = both)
            // determine whether the gradient starts in the mirrored or the non-mirrored area
            int gradient_start;
            float gradient_offset, gradient_mirror_offset;

            if(offset == 0 && mirror_offset == 0) gradient_start = width > mirror_width ? 2 : 1;
            else if(offset == 0) gradient_start = 2;
            else if(mirror_offset == 0) gradient_start = 1;
            else gradient_start = 0;

            switch(gradient_start)
            {
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

            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, original_mirror_size, original_width, original_mirror_offset, alpha, gradient_mirror_offset, gradientType, doProject, range);
            StrafeHUD_drawGradient(color, autocvar_hud_panel_strafehud_bar_neutral_color, original_size, original_width, original_offset, alpha, gradient_offset, gradientType, doProject, range);
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

void StrafeHUD_drawGradient(vector color1, vector color2, vector size, float original_width, float offset, float alpha, float gradientOffset, int gradientType, bool doProject, float range)
{
    float color_ratio, alpha1, alpha2;
    vector segment_size = size;
    alpha1 = bound(0, alpha, 1);
    alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha, 1);
    if((alpha1+alpha2) == 0) return;
    color_ratio = alpha1/(alpha1+alpha2);
    for(int i = 0; i < size.x; ++i)
    {
        float ratio, alpha_ratio, combine_ratio1, combine_ratio2, segment_offset;
        segment_size.x = min(size.x - i, 1); // each gradient segment is 1 unit wide except if there is less than 1 unit of gradient remaining
        segment_offset = offset + i;
        ratio = (i + segment_size.x/2 + gradientOffset) / original_width * (gradientType == STRAFEHUD_GRADIENT_BOTH ? 2 : 1);
        if(doProject)
        {
            segment_size.x = StrafeHUD_projectWidth(segment_offset, segment_size.x, range);
            segment_offset = StrafeHUD_projectOffset(segment_offset, range);
        }
        if(ratio > 1) ratio = 2 - ratio;
        if(gradientType != STRAFEHUD_GRADIENT_RIGHT) ratio = 1 - ratio;
        alpha_ratio = alpha1 - (alpha1 - alpha2) * ratio;
        combine_ratio1 = ratio*(1-color_ratio);
        combine_ratio2 = (1-ratio)*color_ratio;
        ratio = (combine_ratio1 + combine_ratio2) == 0 ? 1 : combine_ratio1/(combine_ratio1 + combine_ratio2);
        if(alpha_ratio > 0) drawfill(panel_pos + eX * segment_offset, segment_size, StrafeHUD_mixColors(color1, color2, ratio), alpha_ratio, DRAWFLAG_NORMAL);
    }
}

// draw the strafe arrows (inspired by drawspritearrow() in common/mutators/mutator/waypoints/waypointsprites.qc)
void StrafeHUD_drawStrafeArrow(vector origin, float size, vector color, float alpha, bool flipped, float connection_width)
{
    origin = HUD_Shift(origin);
    float width = HUD_ScaleX(size * 2 + connection_width);
    float height = HUD_ScaleY(size);
    if(flipped) origin -= size * eY;
    R_BeginPolygon("", DRAWFLAG_NORMAL, true);
    if(connection_width > 0)
    {
        R_PolygonVertex(origin + (connection_width / 2 * eX) + (flipped ? height * eY : '0 0 0'), '0 0 0', color, alpha);
        R_PolygonVertex(origin - (connection_width / 2 * eX) + (flipped ? height * eY : '0 0 0'), '0 0 0', color, alpha);
    }
    else
    {
        R_PolygonVertex(origin + (flipped ? height * eY : '0 0 0'), '0 0 0', color, alpha);
    }
    R_PolygonVertex(origin + (flipped ? '0 0 0' : height * eY) - (width / 2) * eX, '0 0 0', color, alpha);
    R_PolygonVertex(origin + (flipped ? '0 0 0' : height * eY) + (width / 2) * eX, '0 0 0', color, alpha);
    R_EndPolygon();
}

// draw a fading text indicator above or below the strafe meter, return true if something was displayed
bool StrafeHUD_drawTextIndicator(string text, float height, vector color, float fadetime, float lasttime, float offset, int position)
{
    if((height <= 0) || (lasttime <= 0) || (fadetime <= 0) || ((time - lasttime) >= fadetime))
        return false;

    float alpha = cos(((time - lasttime) / fadetime) * 90 * DEG2RAD); // fade non-linear like the physics panel does
    vector size = panel_size;
    size.y = height;

    switch(position) {
        case STRAFEHUD_TEXT_TOP:
            offset += size.y;
            offset *= -1;
            break;
        case STRAFEHUD_TEXT_BOTTOM:
            offset += panel_size.y;
            break;
    }

    drawstring_aspect(panel_pos + eY * offset, text, size, color, alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
    return true;
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
