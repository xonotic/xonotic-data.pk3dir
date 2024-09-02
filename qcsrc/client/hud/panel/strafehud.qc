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

	// generic hud routines
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_strafehud ||
		   (spectatee_status == -1 && (autocvar_hud_panel_strafehud == 1 || autocvar_hud_panel_strafehud == 3)) ||
		   (autocvar_hud_panel_strafehud == 3 && !MUTATOR_CALLHOOK(HUD_StrafeHUD_showoptional))) { hud_lasttime = time; return; }
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
		int keys = STAT(PRESSED_KEYS);

		// try to ignore if track_canjump is enabled, does not work in spectator mode if spectated player uses +jetpack or cl_movement_track_canjump
		bool jumpheld = false;
		if(islocal)
		{
			if((PHYS_INPUT_BUTTON_JUMP(strafeplayer) || PHYS_INPUT_BUTTON_JETPACK(strafeplayer)) && !PHYS_CL_TRACK_CANJUMP(strafeplayer))
				jumpheld = true;
		}
		else
		{
			if((keys & KEY_JUMP) && !PHYS_TRACK_CANJUMP(strafeplayer))
				jumpheld = true;
		}

		// does not get changed by ground timeout and is not affected by jump input
		bool real_onground = islocal ? IS_ONGROUND(strafeplayer) : !(strafeplayer.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);

		// does not get changed by ground timeout
		bool real_onslick = false;

		// if jump is held assume we are in air, avoids flickering of the hud when hitting the ground
		bool onground = real_onground && !jumpheld;
		bool onslick = real_onslick;

		// the hud will not work well while swimming
		float strafe_waterlevel = DetectWaterLevel(strafeplayer);
		bool swimming = strafe_waterlevel >= WATERLEVEL_SWIMMING;

		static float onground_lasttime = 0;
		static bool onslick_last = false;

		if(onground)
		{
			if(PHYS_FRICTION(strafeplayer) == 0)
			{
				onslick = true;
			}
			else // do not use IS_ONSLICK(), it only works for the local player and only if client prediction is enabled
			{
				trace_dphitq3surfaceflags = 0;
				tracebox(strafeplayer.origin, strafeplayer.mins, strafeplayer.maxs, strafeplayer.origin - '0 0 1', MOVE_NOMONSTERS, strafeplayer);
				onslick = trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK;
			}
			real_onslick = onslick;

			onground_lasttime = time;
			onslick_last = onslick;
		}
		else if(jumpheld || swimming)
		{
			onground_lasttime = 0;
		}

		bool onground_expired;
		if(onground_lasttime == 0)
			onground_expired = true;
		else
			onground_expired = (time - onground_lasttime) >= autocvar_hud_panel_strafehud_timeout_ground; // timeout for slick ramps

		// only the local csqcplayer entity contains this information even when spectating
		float maxspeed_mod = IS_DUCKED(csqcplayer) ? .5 : 1;
		float maxspeed_phys = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
		float maxspeed = !autocvar__hud_configure ? maxspeed_phys * maxspeed_mod : 320;
		float maxaccel_phys = onground ? PHYS_ACCELERATE(strafeplayer) : PHYS_AIRACCELERATE(strafeplayer);
		float maxaccel = !autocvar__hud_configure ? maxaccel_phys : 1;

		if(!onground && !onground_expired) // if ground timeout has not expired yet use ground physics
		{
			onground = true;
			onslick = onslick_last;

			if(!autocvar__hud_configure)
			{
				maxspeed = PHYS_MAXSPEED(strafeplayer) * maxspeed_mod;
				maxaccel = PHYS_ACCELERATE(strafeplayer);
			}
		}

		vector movement = PHYS_INPUT_MOVEVALUES(strafeplayer);
		float movespeed = vlen(vec2(movement));
		if(movespeed == 0)
			movespeed = maxspeed;
		else
			movespeed = min(movespeed, maxspeed);

		float dt = DetectFrameTime();

		// determine whether the player is pressing forwards or backwards keys
		int keys_fwd;
		if(islocal) // if entity is local player
		{
			if(movement.x > 0)
				keys_fwd = STRAFEHUD_KEYS_FORWARD;
			else if(movement.x < 0)
				keys_fwd = STRAFEHUD_KEYS_BACKWARD;
			else
				keys_fwd = STRAFEHUD_KEYS_NONE;
		}
		else // alternatively determine direction by querying pressed keys
		{
			if((keys & KEY_FORWARD) && !(keys & KEY_BACKWARD))
				keys_fwd = STRAFEHUD_KEYS_FORWARD;
			else if(!(keys & KEY_FORWARD) && (keys & KEY_BACKWARD))
				keys_fwd = STRAFEHUD_KEYS_BACKWARD;
			else
				keys_fwd = STRAFEHUD_KEYS_NONE;
		}

		float wishangle = DetectWishAngle(movement, keys, islocal);
		bool strafekeys = fabs(wishangle) > 45;

		// determine minimum required angle to display full strafe range
		float range_minangle = fabs(wishangle) % 90; // maximum range is 90 degree
		if(range_minangle > 45) range_minangle = 45 - fabs(wishangle) % 45; // minimum angle range is 45
		range_minangle = 90 - range_minangle; // calculate value which is never >90 or <45
		range_minangle *= 2; // multiply to accommodate for both sides of the hud

		float hudangle = StrafeHUD_determineHudAngle(range_minangle);

		// detect air strafe turning
		static bool turn = false;
		if((!strafekeys && vlen(vec2(movement)) > 0) || onground || autocvar__hud_configure)
		{
			turn = false;
		}
		else // air strafe only
		{
			static float turn_lasttime = 0;
			static float turnangle;
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
					maxspeed = min(maxspeed, GeomLerp(PHYS_MAXAIRSPEED(strafeplayer), strafity, PHYS_MAXAIRSTRAFESPEED(strafeplayer)));

				movespeed = min(movespeed, maxspeed);

				if(PHYS_AIRSTRAFEACCELERATE(strafeplayer) != 0)
					maxaccel = GeomLerp(PHYS_AIRACCELERATE(strafeplayer), strafity, PHYS_AIRSTRAFEACCELERATE(strafeplayer));
			}
		}

		maxaccel *= dt * movespeed;
		float bestspeed = max(movespeed - maxaccel, 0); // target speed to gain maximum acceleration

		// use local csqcmodel entity for this even when spectating, flickers too much otherwise
		float speed = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) : 1337;

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

		float minspeed = autocvar_hud_panel_strafehud_switch_minspeed;
		if(minspeed < 0)
			minspeed = bestspeed + frictionspeed;

		// get current strafing angle ranging from -180° to +180°
		float angle;
		bool fwd;
		bool straight_overturn = false;
		float antiflicker_angle = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);

		if(!autocvar__hud_configure)
		{
			if(speed > 0)
			{
				// change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
				float vel_angle = vectoangles(strafeplayer.velocity).y - (vectoangles(strafeplayer.velocity).y > 180 ? 360 : 0);
				float view_angle = PHYS_INPUT_ANGLES(strafeplayer).y;

				// calculate view angle relative to the players current velocity direction
				angle = vel_angle - view_angle;

				// if the angle goes above 180° or below -180° wrap it to the opposite side since we want the interior angle
				if(angle > 180)
					angle -= 360;
				else if(angle < -180)
					angle += 360;

				// determine whether the player is strafing forwards or backwards
				// if the player is not strafe turning use forwards/backwards keys to determine direction
				if(fabs(wishangle) != 90)
				{
					if(keys_fwd == STRAFEHUD_KEYS_FORWARD)
						fwd = true;
					else if(keys_fwd == STRAFEHUD_KEYS_BACKWARD)
						fwd = false;
					else
						fwd = fabs(angle) <= 90;
				}
				// otherwise determine by examining the strafe angle
				else
				{
					if(wishangle < 0) // detect direction using wishangle since the direction is not yet set
						fwd = angle <= -wishangle;
					else
						fwd = angle >= -wishangle;
				}

				// shift the strafe angle by 180° when strafing backwards
				if(!fwd)
				{
					if(angle < 0)
						angle += 180;
					else
						angle -= 180;
				}

				// do not make the angle indicator switch side too much at ±180° if anti flicker is turned on
				if(angle > (180 - antiflicker_angle) || angle < (-180 + antiflicker_angle))
					straight_overturn = true;
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
			if(angle < 0)
				wishangle *= -1;
		}

		// invert the wish angle when strafing backwards
		if(!fwd)
			wishangle *= -1;

		// flip angles if v_flipped is enabled
		if(autocvar_v_flipped)
		{
			angle *= -1;
			wishangle *= -1;
		}

		// best angle to strafe at
		// in case of ground friction we may decelerate if the acceleration is smaller than the speed loss from friction
		float bestangle    = (strafespeed > bestspeed ? acos(bestspeed / strafespeed) * RAD2DEG : 0);
		float prebestangle = (strafespeed > movespeed ? acos(movespeed / strafespeed) * RAD2DEG : 0);
		float opposite_bestangle = -bestangle;

		// absolute_* variables which are always positive with no wishangle offset
		float absolute_bestangle = bestangle;
		float absolute_prebestangle = prebestangle;

		float direction = StrafeHUD_determineDirection(angle, wishangle, antiflicker_angle);

		if(direction == STRAFEHUD_DIRECTION_LEFT) // the angle becomes negative in case we strafe left
		{
			bestangle *= -1;
			opposite_bestangle *= -1;
			prebestangle *= -1;
		}

		bestangle -= wishangle;
		opposite_bestangle -= wishangle;
		prebestangle -= wishangle;

		int mode;
		if(autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1)
			mode = autocvar_hud_panel_strafehud_mode;
		else
			mode = STRAFEHUD_MODE_VIEW_CENTERED;

		// best strafe acceleration angle
		float changeangle = -bestangle;
		float bestangle_width = max(panel_size.x * autocvar_hud_panel_strafehud_switch_width, 1);

		bool opposite_direction = false;
		float opposite_changeangle = 0;
		if((angle > -wishangle && direction == STRAFEHUD_DIRECTION_LEFT) || (angle < -wishangle && direction == STRAFEHUD_DIRECTION_RIGHT))
		{
			opposite_direction = true;
			opposite_changeangle = opposite_bestangle + bestangle * 2;
		}

		bool immobile = speed <= 0;

		float currentangle = angle;
		if(mode == STRAFEHUD_MODE_VELOCITY_CENTERED)
			currentangle = bound(-hudangle / 2, currentangle, hudangle / 2);

		// shift hud if operating in view angle centered mode
		float shift_angle = 0;
		if(mode == STRAFEHUD_MODE_VIEW_CENTERED)
		{
			shift_angle = -currentangle;
			bestangle += shift_angle;
			changeangle += shift_angle;
			opposite_bestangle += shift_angle;
			opposite_changeangle += shift_angle;
		}

		if(mode == STRAFEHUD_MODE_VIEW_CENTERED || straight_overturn)
			currentangle = 0;

		currentangle = StrafeHUD_projectAngle(currentangle, hudangle, false);

		StrafeHUD_DrawStrafeMeter(
			speed, minspeed, shift_angle, wishangle, currentangle, changeangle, bestangle,
			bestangle_width, absolute_bestangle, absolute_prebestangle,
			opposite_bestangle, opposite_changeangle, immobile,
			opposite_direction, direction, hudangle);

		float text_offset_top;
		float text_offset_bottom;
		text_offset_top = text_offset_bottom = StrafeHUD_DrawSlickDetector(strafeplayer, real_onslick);

		StrafeHUD_DrawDirectionIndicator(direction, opposite_direction, fwd);

		vector angle_indicator_info = StrafeHUD_DrawAngleIndicator(
			angle, wishangle, currentangle, bestangle, absolute_bestangle,
			absolute_prebestangle, opposite_bestangle, immobile,
			opposite_direction, direction, hudangle);

		// unpack return value from vector
		float strafe_ratio = angle_indicator_info.x;
		float angle_offset_top = angle_indicator_info.y;
		float angle_offset_bottom = angle_indicator_info.z;

		// make sure text does not draw inside the strafehud bar
		text_offset_top = max(angle_offset_top, text_offset_top);
		text_offset_bottom = max(angle_offset_bottom, text_offset_bottom);

		text_offset_bottom += StrafeHUD_drawVerticalAngle(text_offset_bottom);

		draw_beginBoldFont();
		text_offset_bottom += StrafeHUD_drawStartSpeed(speed, text_offset_bottom);
		text_offset_top += StrafeHUD_drawStrafeEfficiency(strafe_ratio, text_offset_top);
		text_offset_top += StrafeHUD_drawJumpHeight(strafeplayer, real_onground, swimming, text_offset_top);
		draw_endBoldFont();

		StrafeHUD_Sonar(strafe_ratio, StrafeHUD_UpdateSonarSound());
	}

	hud_lasttime = time;
}
