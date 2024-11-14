// Author: Juhu

#include "strafehud.qh"
#include <client/hud/common_physics.qh>

#include <client/draw.qh>

// non-essential
#include <client/view.qh> // for v_flipped state

// start speed
#include <client/hud/panel/racetimer.qh> // checkpoint information (race_*)

// GeomLerp
#include <common/physics/player.qh>

// StrafeHUD (#25)

void HUD_StrafeHUD_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_StrafeHUD()
{
	static float hud_lasttime = 0;

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

	// draw strafehud
	if(csqc_and_strafe_player)
	{
		float friction  = friction_phys;
		float speed     = speed_phys;
		vector movement = movement_phys;

		if(autocvar__hud_configure)
		{
			speed    = 1337;
			immobile = false;
			maxspeed = 320;
			maxaccel = 1;
		}

		// persistent
		static float turn_lasttime          = 0;
		static bool  turn                   = false;
		static float turnangle;
		static float dt_update              = 0;
		static int   dt_time                = 0;
		static float dt_sum                 = 0;
		static float dt                     = 0;

		// physics
		bool   onground_expired;
		bool   strafekeys;
		float  movespeed;
		float  bestspeed;
		float  angle;
		bool   fwd; // left & right variables are flipped when !fwd
		int    keys_fwd;
		float  wishangle;
		int    direction;
		float  strafity                     = 0;

		// HUD
		int    mode;
		float  speed_conversion_factor      = GetSpeedUnitFactor(autocvar_hud_speed_unit);
		float  length_conversion_factor     = GetLengthUnitFactor(autocvar_hud_speed_unit);
		// use more decimals when displaying km or miles
		int    length_decimals              = autocvar_hud_speed_unit >= 3 && autocvar_hud_speed_unit <= 5 ? 6 : 2;
		float  antiflicker_angle            = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);
		float  minspeed;
		float  shift_offset                 = 0;
		bool   straight_overturn            = false;
		float  hudangle;
		float  hidden_width;
		float  neutral_offset;
		float  neutral_width;
		vector currentangle_color           = autocvar_hud_panel_strafehud_angle_neutral_color;
		float  currentangle_offset;
		vector currentangle_size;
		float  bestangle;
		float  prebestangle;
		float  overturn_angle;
		float  odd_bestangle;
		float  bestangle_offset             = 0;
		float  switch_bestangle_offset      = 0;
		bool   odd_angles                   = false;
		float  odd_bestangle_offset         = 0;
		float  switch_odd_bestangle_offset  = 0;
		float  switch_bestangle_width       = 0;
		float  wturn_bestangle              = 0;
		float  wturn_left_bestangle_offset  = 0;
		float  wturn_right_bestangle_offset = 0;
		float  wturn_bestangle_width        = 0;
		float  accelzone_left_offset;
		float  accelzone_right_offset;
		float  accelzone_width;
		float  preaccelzone_left_offset;
		float  preaccelzone_right_offset;
		float  preaccelzone_width;
		float  overturn_offset;
		float  overturn_width;
		float  slickdetector_height;
		vector direction_size_vertical      = '0 0 0';
		vector direction_size_horizontal    = '0 0 0';
		float  range_minangle;
		float  text_offset_top              = 0;
		float  text_offset_bottom           = 0;

		// real_* variables which are always positive with no wishangle offset
		float  real_bestangle;
		float  real_prebestangle;
		float  real_overturn_angle;
		float  real_wturn_bestangle         = 0;

		if(autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1)
			mode = autocvar_hud_panel_strafehud_mode;
		else
			mode = STRAFEHUD_MODE_VIEW_CENTERED;

		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_arrow_size, 10), 0);

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
				maxspeed = maxspeed_ground * maxspeed_mod;
				maxaccel = maxaccel_ground;
			}
		}

		movespeed = vlen(vec2(movement));
		if(movespeed == 0)
			movespeed = maxspeed;
		else
			movespeed = min(movespeed, maxspeed);

		if(!autocvar_hud_panel_strafehud_uncapped)
			arrow_size = max(arrow_size, 1);

		// determine frametime
		if(predicted && (input_timelength > 0))
		{
			float dt_client = input_timelength;

			if(dt_client > .05) // server splits frames longer than 50 ms into two moves
				dt_client /= 2; // doesn't ensure frames are smaller than 50 ms, just splits large frames in half, matches server behaviour

			// calculate average frametime
			dt_sum += dt_client * dt_client;
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

		// determine player wishdir
		if(islocal) // if entity is local player
		{
			if(movement.x == 0)
			{
				if(movement.y < 0)
					wishangle = -90;
				else if(movement.y > 0)
					wishangle = 90;
				else
					wishangle = 0;
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
						if(wishangle < 0)
							wishangle += 180;
						else
							wishangle -= 180;

						wishangle *= -1;
					}
				}
			}
		}
		else // alternatively calculate wishdir by querying pressed keys
		{
			if((keys & KEY_FORWARD) || (keys & KEY_BACKWARD))
				wishangle = 45;
			else
				wishangle = 90;
			if(keys & KEY_LEFT)
				wishangle *= -1;
			else if(!(keys & KEY_RIGHT))
				wishangle = 0; // wraps at 180°
		}

		float real_wishangle = fabs(wishangle); // unmodified by side strafing code
		strafekeys = real_wishangle > 45;

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

			if(turn) // side strafing (A/D)
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
				strafity = 1 - (90 - fabs(wishangle)) / 45;

				if(maxspeed_airstrafe != 0)
					maxspeed = min(maxspeed, GeomLerp(maxspeed_air, strafity, maxspeed_airstrafe));

				movespeed = min(movespeed, maxspeed);

				if(maxaccel_airstrafe != 0)
					maxaccel = GeomLerp(maxaccel_air, strafity, maxaccel_airstrafe);
			}
		}

		maxaccel *= dt * movespeed;
		bestspeed = max(movespeed - maxaccel, 0); // target speed to gain maximum acceleration

		float frictionspeed; // speed lost from friction
		float strafespeed; // speed minus friction

		if((speed > 0) && onground)
		{
			frictionspeed = speed * dt * strafefriction * max(stopspeed / speed, 1);
			strafespeed = max(speed - frictionspeed, 0);
		}
		else
		{
			frictionspeed = 0;
			strafespeed = speed;
		}

		minspeed = autocvar_hud_panel_strafehud_switch_minspeed;
		if(minspeed < 0)
			minspeed = bestspeed + frictionspeed;

		// get current strafing angle ranging from -180° to +180°
		if(!autocvar__hud_configure)
		{
			if(speed > 0)
			{
				// calculate view angle relative to the players current velocity direction
				angle = vel_angle - view_angle;

				// if the angle goes above 180° or below -180° wrap it to the opposite side since we want the interior angle
				if(angle > 180)
					angle -= 360;
				else if(angle < -180)
					angle += 360;

				// determine whether the player is strafing forwards or backwards
				// if the player isn't strafe turning use forwards/backwards keys to determine direction
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

				// don't make the angle indicator switch side too much at ±180° if anti flicker is turned on
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
		if(immobile)
		{
			// these are unused (neutral fills whole strafe bar)
			prebestangle = bestangle = 0;
			overturn_angle = 180;
		}
		else if(onground && autocvar_hud_panel_strafehud_onground_friction)
		{
			// draw ground angles
			{
				// delta_opt = acos((s - a) / v_f), same in air
				bestangle = strafespeed > bestspeed
					? acos(bestspeed / strafespeed) * RAD2DEG // case 1
					: 0; // case 2
				// case 1: normal. case 2: low speed, best angle is forwards
			}
			{
				// needed later if autocvar_hud_panel_strafehud_wturn != STRAFEHUD_WTURN_NONE,
				// ... so calculate even if autocvar_hud_panel_strafehud_bar_preaccel == 0
				float prebestangle_sqrt = movespeed * movespeed + strafespeed * strafespeed - speed * speed;
				// delta_min = acos(sqrt(s^2 - v_f^2 + v^2) / v_f), or just acos(s / v) in air
				prebestangle = (prebestangle_sqrt > 0 && strafespeed > sqrt(prebestangle_sqrt))
					? acos(sqrt(prebestangle_sqrt) / strafespeed) * RAD2DEG // case 1
					: (prebestangle_sqrt > 0 ? 0 : 90); // case 2 : case 3
				// case 1: normal. case 2: low speed, best angle is forwards. case 3: landed at high speed, neutral zone is very large (see explanation below)
			}
			{
				float overturn_numer = speed * speed - strafespeed * strafespeed - maxaccel * maxaccel;
				float overturn_denom = 2 * maxaccel * strafespeed;
				// delta_max = acos((v^2 - v_f^2 - a^2) / (2av_f)), or just acos(-a / 2v) if in air
				overturn_angle = overturn_denom > fabs(overturn_numer)
					? acos(overturn_numer / overturn_denom) * RAD2DEG // case 1
					: (overturn_numer < 0 ? 180 : 0); // case 2 : case 3
				// case 1: normal. case 2: low speed, turning anywhere will gain speed. case 3: landed at high speed, turning anywhere will lose speed (due to friction)
			}
			if(overturn_angle < bestangle || bestangle < prebestangle)
			{
				// these conditions occur when you land at high speed (above max onground speed), such that every wishangle will result in a speed loss due to friction
				if(autocvar_hud_panel_strafehud_onground_mode == STRAFEHUD_ONGROUND_OVERTURN)
				{
					// make overturn fill the whole strafe bar
					// most correct option by the true definition of accel, since every angle results in deceleration
					prebestangle = bestangle = 0;
					overturn_angle = 0;
				}
				else if(autocvar_hud_panel_strafehud_onground_mode == STRAFEHUD_ONGROUND_GROUND)
				{
					/* k9er: these aren't the true angles -- the real ones are very convoluted and difficult to understand
					 * essentially the prior definitions of the zones now overlap,
					 * ... with the overturn zone extending below bestangle, and eventually covering the whole hud
					 * ... and somehow the neutral zone extends above bestangle, and eventually covers the whole hud (i think)
					 * overall showing it accurately is just confusing and unnecessary to add
					 * thankfully the bestangle formula is unchanged, so the least confusing option is likely as follows:
					 */
					overturn_angle = bestangle;
					prebestangle = bestangle;
				}
				else
				{
					// use angles as if in air
					// no need to check if numerator < denominator, since all numerators < max onground speed < speed = all denominators
					bestangle = acos(bestspeed / speed) * RAD2DEG;
					prebestangle = acos(movespeed / speed) * RAD2DEG;
					overturn_angle = acos(-(airstopaccel * maxaccel / 2) / speed) * RAD2DEG;
				}
			}
		}
		else
		{
			// draw airborne angles. see above for documentation
			bestangle = speed > bestspeed
				? acos(bestspeed / speed) * RAD2DEG
				: 0;
			prebestangle = speed > movespeed
				? acos(movespeed / speed) * RAD2DEG
				: 0;
			// with airstopaccel, delta_max = acos(airstopaccel * -a / 2v), only in air
			overturn_angle = speed > airstopaccel * maxaccel / 2
				? acos(-(airstopaccel * maxaccel / 2) / speed) * RAD2DEG
				: 180;
		}
		real_bestangle = bestangle;
		real_prebestangle = prebestangle;
		real_overturn_angle = overturn_angle;

		/*
		 * k9er: proper W-turn angle assuming sv_aircontrol_power == 2 is acos(-speed/a * (cos((acos(V) + M_PI * 2) / 3) * 2 + 1)) rad,
		 * ... where a=dt*32*aircontrol, and V=1-(a*a)/(speed*speed),
		 * ... but this very quickly loses accuracy -- should be a strictly decreasing function, yet it increases at only speed=722 with 125 fps
		 * also note this is only valid when such angle is not in the accelzone, formula taking acceleration into account is unfathomably complicated
		 * afaik there's no simplified version of this formula that doesn't involve complex numbers, other than one valid for only speed<27.1 roughly
		 * furthermore, this function quite rapidly approaches its asymptote of ~35.26, e.g. being ~0.68 away when at only speed=600
		 * this asymptote is independent of whether the player is crouching or has haste, although they must be airborne
		 * thus, the best option is to just draw the asymptote (acos(sqrt(2/3))),
		 * ... but the proper angle can be drawn too if the player wants (hud_panel_strafehud_wturn_proper 1)
		 * this is only enabled if sv_airaccel_qw == 1 since otherwise W-turning gives acceleration, unless hud_panel_strafehud_wturn_unrestricted 1
		 * when sv_aircontrol_power != 2 (abbr. "p"), the asymptote is instead acos(sqrt(p/(p+1))). full formula is too difficult to calculate,
		 * ... so the angle will only be shown with hud_panel_strafehud_wturn_proper 0
		 * this doesn't have support for sv_aircontrol_sideways == 1
		 */
		bool wturning    = !onground && wishangle == 0 && (keys_fwd == STRAFEHUD_KEYS_FORWARD || (aircontrol_backwards == 1 && keys_fwd == STRAFEHUD_KEYS_BACKWARD));
		bool wturn_valid = aircontrol && aircontrol_penalty == 0 && (airaccel_qw == 1 || autocvar_hud_panel_strafehud_wturn_unrestricted == 1);
		bool wturn_check = autocvar_hud_panel_strafehud_wturn && !immobile && wturn_valid;
		if(wturn_check)
		{
			if(aircontrol_power == 2)
			{
				float wturn_a = 32 * aircontrol * dt;
				float wturn_V = 1 - (wturn_a * wturn_a) / (speed * speed);
				if(autocvar_hud_panel_strafehud_wturn_proper && wturn_a > 1 && wturn_V < 1 && wturn_V > -1)
					wturn_bestangle = acos(-speed / wturn_a * (cos((acos(wturn_V) + M_PI * 2) / 3) * 2 + 1)) * RAD2DEG;
				else
					wturn_bestangle = ACOS_SQRT2_3_DEG;
				real_wturn_bestangle = wturn_bestangle;
			}
			else if(!autocvar_hud_panel_strafehud_wturn_proper && aircontrol_power >= 0)
			{
				wturn_bestangle = acos(sqrt(aircontrol_power / (aircontrol_power + 1))) * RAD2DEG;
				real_wturn_bestangle = wturn_bestangle;
			}
			else
			{
				wturn_valid = false;
				wturn_check = false;
			}
		}

		// draw the switch indicators as if strafing normally (W+A style), while W-turning or side strafing
		float n_bestangle                   = 0;
		float n_odd_bestangle;
		float n_bestangle_offset            = 0;
		float n_switch_bestangle_offset     = 0;
		float n_odd_bestangle_offset        = 0;
		float n_switch_odd_bestangle_offset = 0;
		bool  draw_normal = ((autocvar_hud_panel_strafehud_switch >= STRAFEHUD_SWITCH_NORMAL && wturning)
			|| (autocvar_hud_panel_strafehud_switch == STRAFEHUD_SWITCH_SIDESTRAFE && turn));
		if(draw_normal)
		{
			// recalculate bestangle as if strafing normally
			float n_maxspeed  = maxspeed_air * maxspeed_mod;
			float n_movespeed = n_maxspeed;
			float n_maxaccel  = maxaccel_air * dt * n_movespeed;
			float n_bestspeed = max(n_movespeed - n_maxaccel, 0);
			n_bestangle = speed > n_bestspeed
				? acos(n_bestspeed / speed) * RAD2DEG - 45
				: -45;
		}

		// determine the minimal required HUD angle to contain the full strafing angle range
		// this is useful for the velocity centered mode where the zones do not follow the strafing angle
		// how it works:
		//   the angle where the most acceleration occurs moves relative to the player velocity
		//   from 0 - wishangle to real_overturn_angle - wishangle
		//   the angle farther away from the center is the maximum the optimal strafing angle can
		//   diverge from the direction of velocity
		//   this angle has to be multiplied by two since the HUD extends in both directions which
		//   halves the amount it extends in a single direction
		range_minangle = max(real_wishangle, real_overturn_angle - real_wishangle) * 2;

		float range_normal = autocvar_hud_panel_strafehud_range;
		float range_side   = autocvar_hud_panel_strafehud_range_sidestrafe;
		float range_used;
		if(range_normal == 0)
			range_normal = autocvar__hud_configure ? 90 : range_minangle; // use minimum angle required if dynamically setting hud angle
		if(range_side == -1) // use the normal range
			range_used = range_normal;
		else
		{
			if(range_side == 0)
				range_side = autocvar__hud_configure ? 90 : range_minangle;
			range_used = GeomLerp(range_normal, strafity, range_side);
		}
		hudangle = bound(0, fabs(range_used), 360); // limit HUD range to 360 degrees, higher values don't make sense

		if(direction == STRAFEHUD_DIRECTION_LEFT) // the angle becomes negative in case we strafe left
		{
			n_bestangle *= -1;
			bestangle *= -1;
			prebestangle *= -1;
			overturn_angle *= -1;
		}
		odd_bestangle = -bestangle - wishangle;
		n_odd_bestangle = -n_bestangle - wishangle;
		bestangle -= wishangle;
		prebestangle -= wishangle;
		overturn_angle -= wishangle;

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
			currentangle_offset = angle / hudangle * panel_size.x;
		else
			currentangle_offset = bound(-hudangle / 2, angle, hudangle / 2) / hudangle * panel_size.x + panel_size.x / 2;

		// best strafe acceleration angle
		if((autocvar_hud_panel_strafehud_switch || autocvar_hud_panel_strafehud_bestangle) && speed >= minspeed)
		{
			bestangle_offset        =  bestangle / hudangle * panel_size.x + panel_size.x / 2;
			switch_bestangle_offset = -bestangle / hudangle * panel_size.x + panel_size.x / 2;
			switch_bestangle_width  = panel_size.x * autocvar_hud_panel_strafehud_switch_width;
			if(!autocvar_hud_panel_strafehud_uncapped)
				switch_bestangle_width = max(switch_bestangle_width, 1);

			if((angle > -wishangle && direction == STRAFEHUD_DIRECTION_LEFT) || (angle < -wishangle && direction == STRAFEHUD_DIRECTION_RIGHT))
			{
				odd_angles = true;
				odd_bestangle_offset        = odd_bestangle / hudangle * panel_size.x + panel_size.x / 2;
				switch_odd_bestangle_offset = (odd_bestangle + bestangle * 2) / hudangle * panel_size.x + panel_size.x / 2;
			}
			if(draw_normal)
			{
				n_bestangle_offset        =  n_bestangle / hudangle * panel_size.x + panel_size.x / 2;
				n_switch_bestangle_offset = -n_bestangle / hudangle * panel_size.x + panel_size.x / 2;
				if(odd_angles)
				{
					n_odd_bestangle_offset        = n_odd_bestangle / hudangle * panel_size.x + panel_size.x / 2;
					n_switch_odd_bestangle_offset = (n_odd_bestangle + n_bestangle * 2) / hudangle * panel_size.x + panel_size.x / 2;
				}
			}
		}

		// best angle to aim at when W-turning to maximally rotate velocity vector
		if(wturn_check)
		{
			bool wturn_show = autocvar_hud_panel_strafehud_wturn == STRAFEHUD_WTURN_SIDESTRAFE ? (fwd || aircontrol_backwards)
				: autocvar_hud_panel_strafehud_wturn == STRAFEHUD_WTURN_NORMAL ? ((fwd || aircontrol_backwards) && !turn)
				: autocvar_hud_panel_strafehud_wturn == STRAFEHUD_WTURN_NONE ? false
				: wturning;
			if(wturn_show && real_wturn_bestangle < real_prebestangle && !onground)
			{
				wturn_left_bestangle_offset  =  wturn_bestangle / hudangle * panel_size.x + panel_size.x / 2;
				wturn_right_bestangle_offset = -wturn_bestangle / hudangle * panel_size.x + panel_size.x / 2;
				wturn_bestangle_width        = panel_size.x * autocvar_hud_panel_strafehud_wturn_width;
				if(!autocvar_hud_panel_strafehud_uncapped)
					wturn_bestangle_width = max(wturn_bestangle_width, 1);
			}
		}

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
						drawfill(
							panel_pos, panel_size,
							autocvar_hud_panel_strafehud_bar_neutral_color,
							autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha,
							DRAWFLAG_NORMAL);
						break;

					case STRAFEHUD_STYLE_PROGRESSBAR:
						HUD_Panel_DrawProgressBar(
							panel_pos, panel_size, "progressbar", 1, 0, 0,
							autocvar_hud_panel_strafehud_bar_neutral_color,
							autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha,
							DRAWFLAG_NORMAL);
				}
			}
		}
		else
		{
			// calculate various zones of the strafe-o-meter
			if(autocvar_hud_panel_strafehud_bar_preaccel)
				preaccelzone_width = fabs(real_bestangle - real_prebestangle) / hudangle * panel_size.x;
			else
				preaccelzone_width = 0;
			accelzone_width = (real_overturn_angle - real_bestangle) / hudangle * panel_size.x;
			overturn_width = (360 - real_overturn_angle * 2) / hudangle * panel_size.x;
			neutral_width = 360 / hudangle * panel_size.x - accelzone_width * 2 - preaccelzone_width * 2 - overturn_width;

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

				// the wrapping code may struggle if we always append it on the right side
				neutral_offset = direction == STRAFEHUD_DIRECTION_LEFT ? current_offset : -neutral_width;
			}

			// shift hud if operating in view angle centered mode
			if(mode == STRAFEHUD_MODE_VIEW_CENTERED)
			{
				shift_offset = -currentangle_offset;
				bestangle_offset += shift_offset;
				switch_bestangle_offset += shift_offset;
				odd_bestangle_offset += shift_offset;
				switch_odd_bestangle_offset += shift_offset;
				n_bestangle_offset += shift_offset;
				n_switch_bestangle_offset += shift_offset;
				n_odd_bestangle_offset += shift_offset;
				n_switch_odd_bestangle_offset += shift_offset;
				wturn_left_bestangle_offset += shift_offset;
				wturn_right_bestangle_offset += shift_offset;
			}
			if(direction == STRAFEHUD_DIRECTION_LEFT)
				shift_offset += -360 / hudangle * panel_size.x;

			// calculate how far off-center the strafe zones currently are
			shift_offset += (panel_size.x + neutral_width) / 2 - wishangle / hudangle * panel_size.x;

			// shift strafe zones into correct place
			neutral_offset += shift_offset;
			accelzone_left_offset += shift_offset;
			accelzone_right_offset += shift_offset;
			preaccelzone_left_offset += shift_offset;
			preaccelzone_right_offset += shift_offset;
			overturn_offset += shift_offset;

			// draw left acceleration zone
			if(accelzone_width > 0)
				HUD_Panel_DrawStrafeHUD(
					accelzone_left_offset, accelzone_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_accel_color,
					autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT, false);

			if(autocvar_hud_panel_strafehud_bar_preaccel && preaccelzone_width > 0)
				HUD_Panel_DrawStrafeHUD(
					preaccelzone_left_offset, preaccelzone_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_preaccel_color,
					autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT, false);

			// draw right acceleration zone
			if(accelzone_width > 0)
				HUD_Panel_DrawStrafeHUD(
					accelzone_right_offset, accelzone_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_accel_color,
					autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT, false);

			if(autocvar_hud_panel_strafehud_bar_preaccel && preaccelzone_width > 0)
				HUD_Panel_DrawStrafeHUD(
					preaccelzone_right_offset, preaccelzone_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_preaccel_color,
					autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT, false);

			// draw overturn zone
			if(overturn_width > 0)
				HUD_Panel_DrawStrafeHUD(
					overturn_offset, overturn_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_overturn_color,
					autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_BOTH, false);

			// draw neutral zone
			if(neutral_width > 0)
				HUD_Panel_DrawStrafeHUD(
					neutral_offset, neutral_width, hidden_width,
					autocvar_hud_panel_strafehud_bar_neutral_color,
					autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha,
					autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_NONE, false);

			// only draw switch indicators if minspeed is reached (switch_bestangle_width init to 0)
			if(autocvar_hud_panel_strafehud_switch && switch_bestangle_width > 0 && autocvar_hud_panel_strafehud_switch_alpha > 0)
			{
				// draw the switch indicator(s)
				float offset = draw_normal
					? (odd_angles ? n_odd_bestangle_offset : n_bestangle_offset)
					: (odd_angles ? odd_bestangle_offset : bestangle_offset);
				float switch_offset = draw_normal
					? (odd_angles ? n_switch_odd_bestangle_offset : n_switch_bestangle_offset)
					: (odd_angles ? switch_odd_bestangle_offset : switch_bestangle_offset);

				HUD_Panel_DrawStrafeHUD(
					switch_offset, switch_bestangle_width, hidden_width,
					autocvar_hud_panel_strafehud_switch_color,
					autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha,
					STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, true);

				if(direction == STRAFEHUD_DIRECTION_NONE || draw_normal)
					HUD_Panel_DrawStrafeHUD(
						offset, switch_bestangle_width, hidden_width,
						autocvar_hud_panel_strafehud_switch_color,
						autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha,
						STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, true);
			}

			// only draw wturn indicators if conditions were met (wturn_bestangle_width init to 0)
			if(autocvar_hud_panel_strafehud_wturn && wturn_bestangle_width > 0 && autocvar_hud_panel_strafehud_wturn_alpha > 0)
			{
				// draw the wturn indicators
				HUD_Panel_DrawStrafeHUD(
					wturn_left_bestangle_offset, wturn_bestangle_width, hidden_width,
					autocvar_hud_panel_strafehud_wturn_color,
					autocvar_hud_panel_strafehud_wturn_alpha * panel_fg_alpha,
					STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, true);
				HUD_Panel_DrawStrafeHUD(
					wturn_right_bestangle_offset, wturn_bestangle_width, hidden_width,
					autocvar_hud_panel_strafehud_wturn_color,
					autocvar_hud_panel_strafehud_wturn_alpha * panel_fg_alpha,
					STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE, true);
			}
		}

		// slick detector
		slickdetector_height = max(autocvar_hud_panel_strafehud_slickdetector_height, 0);
		if(!autocvar_hud_panel_strafehud_uncapped)
			slickdetector_height = min(slickdetector_height, 1);
		slickdetector_height *= panel_size.y;
		if(autocvar_hud_panel_strafehud_slickdetector &&
		   autocvar_hud_panel_strafehud_slickdetector_range > 0 &&
		   autocvar_hud_panel_strafehud_slickdetector_alpha > 0 &&
		   slickdetector_height > 0 &&
		   panel_size.x > 0)
		{
			float slicksteps = max(autocvar_hud_panel_strafehud_slickdetector_granularity, 0);
			bool slickdetected = false;

			if(!autocvar_hud_panel_strafehud_uncapped)
				slicksteps = min(slicksteps, 4);
			slicksteps = 90 * DEG2RAD / 2 ** slicksteps;

			slickdetected = real_onslick; // don't need to traceline if already touching slick

			// traceline into every direction
			trace_dphitq3surfaceflags = 0;
			vector traceorigin = strafeplayer.origin + eZ * strafeplayer.mins.z;
			for(float i = 0; i < 90 * DEG2RAD - 0.00001 && !slickdetected; i += slicksteps)
			{
				vector slickoffset;
				float slickrotate;
				slickoffset.z = -cos(i) * autocvar_hud_panel_strafehud_slickdetector_range;
				slickrotate = sin(i) * autocvar_hud_panel_strafehud_slickdetector_range;

				for(float j = 0; j < 360 * DEG2RAD - 0.00001 && !slickdetected; j += slicksteps)
				{
					slickoffset.x = sin(j) * slickrotate;
					slickoffset.y = cos(j) * slickrotate;

					traceline(traceorigin, traceorigin + slickoffset, MOVE_NOMONSTERS, strafeplayer);
					if((friction == 0 && trace_fraction < 1)
					|| (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK))
						slickdetected = true;
					if(i == 0)
						break;
				}
			}

			// if a traceline hit a slick surface
			if(slickdetected)
			{
				vector slickdetector_size = panel_size;
				slickdetector_size.y = slickdetector_height;

				// top horizontal line
				drawfill(
					panel_pos - eY * slickdetector_size.y, slickdetector_size,
					autocvar_hud_panel_strafehud_slickdetector_color,
					autocvar_hud_panel_strafehud_slickdetector_alpha * panel_fg_alpha,
					DRAWFLAG_NORMAL);

				// bottom horizontal line
				drawfill(
					panel_pos + eY * panel_size.y,
					slickdetector_size, autocvar_hud_panel_strafehud_slickdetector_color,
					autocvar_hud_panel_strafehud_slickdetector_alpha * panel_fg_alpha,
					DRAWFLAG_NORMAL);
			}

			text_offset_top = text_offset_bottom = slickdetector_height;
		}

		// direction indicator
		if(autocvar_hud_panel_strafehud_direction)
		{
			direction_size_vertical.x = autocvar_hud_panel_strafehud_direction_width;
			if(!autocvar_hud_panel_strafehud_uncapped)
				direction_size_vertical.x = min(direction_size_vertical.x, 1);
			direction_size_vertical.x *= panel_size.y;
			if(!autocvar_hud_panel_strafehud_uncapped)
				direction_size_vertical.x = max(direction_size_vertical.x, 1);
			direction_size_vertical.y = panel_size.y + direction_size_vertical.x * 2;
			direction_size_vertical.z = 0;
			direction_size_horizontal.x = panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5);
			direction_size_horizontal.y = direction_size_vertical.x;
			direction_size_horizontal.z = 0;
		}

		if(autocvar_hud_panel_strafehud_direction &&
		   direction != STRAFEHUD_DIRECTION_NONE &&
		   direction_size_vertical.x > 0 &&
		   autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha > 0)
		{
			bool indicator_direction = direction == STRAFEHUD_DIRECTION_LEFT;
			// invert left/right when strafing backwards or when strafing towards the opposite side indicated by the direction variable
			// if both conditions are true then it's inverted twice hence not inverted at all
			if(!fwd != odd_angles)
				indicator_direction = !indicator_direction;

			// draw the direction indicator caps at the sides of the hud
			// vertical line
			if(direction_size_vertical.y > 0)
				drawfill(
					panel_pos - eY * direction_size_horizontal.y + eX * (indicator_direction ? -direction_size_vertical.x : panel_size.x),
					direction_size_vertical, autocvar_hud_panel_strafehud_direction_color,
					autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha,
					DRAWFLAG_NORMAL);

			// top horizontal line
			drawfill(
				panel_pos + eX * (indicator_direction ? 0 : panel_size.x - direction_size_horizontal.x) - eY * direction_size_horizontal.y,
				direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color,
				autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha,
				DRAWFLAG_NORMAL);

			// bottom horizontal line
			drawfill(
				panel_pos + eX * (indicator_direction ? 0 : panel_size.x - direction_size_horizontal.x) + eY * panel_size.y,
				direction_size_horizontal, autocvar_hud_panel_strafehud_direction_color,
				autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha,
				DRAWFLAG_NORMAL);
		}

		// draw the actual strafe angle
		if(!immobile)
		{
			float moveangle = fabs(angle + wishangle);
			if(moveangle > 180) moveangle = 360 - moveangle; // restricted to between 0 and 180
			float strafe_ratio = 0;

			// player is overturning
			if(moveangle >= real_overturn_angle)
			{
				if(moveangle == real_overturn_angle && real_overturn_angle == 180)
					; // everywhere gives acceleration, keep strafe_ratio as 0
				else
				{
					currentangle_color = autocvar_hud_panel_strafehud_angle_overturn_color;
					strafe_ratio = (moveangle - real_overturn_angle) / (180 - real_overturn_angle);
					// moveangle is always <= 180, so this code won't run if real_overturn_angle == 180
					strafe_ratio *= -1;
				}
			}
			// player gains speed by strafing
			else if(moveangle >= real_bestangle)
			{
				currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
				strafe_ratio = (real_overturn_angle - moveangle) / (real_overturn_angle - real_bestangle);
				// if real_overturn_angle == real_bestangle, this code won't run, no need to check if their difference is 0
			}
			else if(moveangle >= real_prebestangle)
			{
				if(autocvar_hud_panel_strafehud_bar_preaccel)
					currentangle_color = autocvar_hud_panel_strafehud_angle_preaccel_color;
				strafe_ratio = (moveangle - real_prebestangle) / (real_bestangle - real_prebestangle);
			}

			if(autocvar_hud_panel_strafehud_style == STRAFEHUD_STYLE_GRADIENT)
				currentangle_color = StrafeHUD_mixColors(autocvar_hud_panel_strafehud_angle_neutral_color, currentangle_color, fabs(strafe_ratio));
		}

		if(mode == STRAFEHUD_MODE_VIEW_CENTERED || straight_overturn)
			currentangle_offset = panel_size.x / 2;

		float angleheight_offset = currentangle_size.y;
		float ghost_offset = 0;
		bool draw_bestangle = autocvar_hud_panel_strafehud_bestangle && (autocvar_hud_panel_strafehud_bestangle == 1 || turn) && direction != STRAFEHUD_DIRECTION_NONE;
		if(draw_bestangle)
			ghost_offset = bound(0, (odd_angles ? odd_bestangle_offset : bestangle_offset), panel_size.x);

		switch(autocvar_hud_panel_strafehud_angle_style)
		{
			case STRAFEHUD_INDICATOR_SOLID:
				if(currentangle_size.x > 0 && currentangle_size.y > 0)
				{
					if(draw_bestangle)
						drawfill(
							panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (ghost_offset - currentangle_size.x / 2),
							currentangle_size, autocvar_hud_panel_strafehud_bestangle_color,
							autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha,
							DRAWFLAG_NORMAL);
					drawfill(
						panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (currentangle_offset - currentangle_size.x / 2),
						currentangle_size, currentangle_color,
						autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha,
						DRAWFLAG_NORMAL);
				}
				break;
			case STRAFEHUD_INDICATOR_DASHED:
				if(currentangle_size.x > 0 && currentangle_size.y > 0)
				{
					vector line_size = currentangle_size;
					line_size.y = currentangle_size.y / (bound(2, autocvar_hud_panel_strafehud_angle_dashes, currentangle_size.y) * 2 - 1);
					for(float i = 0; i < currentangle_size.y; i += line_size.y * 2)
					{
						if(i + line_size.y * 2 >= currentangle_size.y)
							line_size.y = currentangle_size.y - i;
						if(draw_bestangle)
							drawfill(
								panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (ghost_offset - line_size.x / 2),
								line_size, autocvar_hud_panel_strafehud_bestangle_color,
								autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
						drawfill(
							panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (currentangle_offset - line_size.x / 2),
							line_size, currentangle_color,
							autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
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
		if((autocvar_hud_panel_strafehud_angle_alpha > 0) ||
		   (autocvar_hud_panel_strafehud_bestangle && autocvar_hud_panel_strafehud_bestangle_alpha > 0))
		{
			// offset text by amount the angle indicator extrudes from the strafehud bar
			angle_offset_top = angle_offset_bottom = (angleheight_offset - panel_size.y) / 2;
		}

		if(autocvar_hud_panel_strafehud_angle_arrow > 0)
		{
			if(arrow_size > 0)
			{
				if(autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3)
				{
					if(draw_bestangle)
						StrafeHUD_drawStrafeArrow(
							panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * ghost_offset,
							arrow_size, autocvar_hud_panel_strafehud_bestangle_color,
							autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, true, currentangle_size.x);
					StrafeHUD_drawStrafeArrow(
						panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * currentangle_offset,
						arrow_size, currentangle_color,
						autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, true, currentangle_size.x);

					angle_offset_top += arrow_size; // further offset the top text offset if the top arrow is drawn
				}
				if(autocvar_hud_panel_strafehud_angle_arrow >= 2)
				{
					if(draw_bestangle)
						StrafeHUD_drawStrafeArrow(
							panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * ghost_offset,
							arrow_size, autocvar_hud_panel_strafehud_bestangle_color,
							autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, false, currentangle_size.x);
					StrafeHUD_drawStrafeArrow(
						panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * currentangle_offset,
						arrow_size, currentangle_color,
						autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, false, currentangle_size.x);

					angle_offset_bottom += arrow_size; // further offset the bottom text offset if the bottom arrow is drawn
				}
			}
		}

		// make sure text doesn't draw inside the strafehud bar
		text_offset_top = max(angle_offset_top, text_offset_top);
		text_offset_bottom = max(angle_offset_bottom, text_offset_bottom);

		draw_beginBoldFont();

		// show speed when crossing the start trigger
		{
			static float startspeed = 0, starttime = 0; // displayed value and timestamp for fade out

			// check if the start trigger was hit (will also trigger if the finish trigger was hit if those have the same ID)
			if((race_nextcheckpoint == 1) || (race_checkpoint == 254 && race_nextcheckpoint == 255))
			{
				if((race_checkpointtime > 0) && (starttime != race_checkpointtime))
				{
					starttime = race_checkpointtime;
					startspeed = race_timespeed;
				}
			}

			if(autocvar_hud_panel_strafehud_startspeed)
			{
				float startspeed_height = autocvar_hud_panel_strafehud_startspeed_size * panel_size.y;
				string startspeed_text = ftos_decimals(startspeed * speed_conversion_factor, 2);
				if(autocvar_hud_panel_strafehud_unit_show)
					startspeed_text = strcat(startspeed_text, GetSpeedUnit(autocvar_hud_speed_unit));

				bool was_drawn = StrafeHUD_drawTextIndicator(
					startspeed_text, startspeed_height,
					autocvar_hud_panel_strafehud_startspeed_color,
					autocvar_hud_panel_strafehud_startspeed_fade,
					starttime, text_offset_bottom, STRAFEHUD_TEXT_BOTTOM);

				if(was_drawn)
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
			if((strafeplayer.velocity.z <= 0) || real_onground || swimming || !alive_player)
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
					jumpheight_text = strcat(jumpheight_text, GetLengthUnit(autocvar_hud_speed_unit));

				bool was_drawn = StrafeHUD_drawTextIndicator(
					jumpheight_text, jumpheight_height,
					autocvar_hud_panel_strafehud_jumpheight_color,
					autocvar_hud_panel_strafehud_jumpheight_fade,
					jumptime, text_offset_top, STRAFEHUD_TEXT_TOP);

				if(was_drawn)
					text_offset_top += jumpheight_height;
			}
		}

		draw_endBoldFont();
	}
	hud_lasttime = time;
}

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_DrawStrafeHUD(float offset, float width, float hidden_width, vector color, float alpha, int type, int gradientType, bool offset_centered)
{
	float mirror_offset, mirror_width;
	vector size = panel_size;
	vector mirror_size = panel_size;
	float overflow_width = 0, overflow_mirror_width = 0;
	float original_width = width; // required for gradient

	if(offset_centered) // offset gives the center of the bar, not left edge
		offset -= original_width / 2;

	if(type == STRAFEHUD_STYLE_GRADIENT && gradientType == STRAFEHUD_GRADIENT_NONE)
		type = STRAFEHUD_STYLE_DRAWFILL;

	if(alpha <= 0 && type != STRAFEHUD_STYLE_GRADIENT || width <= 0)
		return;

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

	switch(type)
	{
		default:
		case STRAFEHUD_STYLE_DRAWFILL: // no styling (drawfill)
			if(mirror_size.x > 0 && mirror_size.y > 0)
				drawfill(panel_pos + eX * mirror_offset, mirror_size, color, alpha, DRAWFLAG_NORMAL);
			if(size.x > 0 && size.y > 0)
				drawfill(panel_pos + eX * offset, size, color, alpha, DRAWFLAG_NORMAL);
			break;

		case STRAFEHUD_STYLE_PROGRESSBAR: // progress bar style
			if(mirror_size.x > 0 && mirror_size.y > 0)
				HUD_Panel_DrawProgressBar(
					panel_pos + eX * mirror_offset,
					mirror_size, "progressbar",
					1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
			if(size.x > 0 && size.y > 0)
				HUD_Panel_DrawProgressBar(
					panel_pos + eX * offset,
					size, "progressbar",
					1, 0, 0, color, alpha, DRAWFLAG_NORMAL);
			break;

		case STRAFEHUD_STYLE_GRADIENT: // gradient style (types: 1 = left, 2 = right, 3 = both)
			// determine whether the gradient starts in the mirrored or the non-mirrored area
			int gradient_start;
			float gradient_offset, gradient_mirror_offset;

			if(offset == 0 && mirror_offset == 0)
				gradient_start = width > mirror_width ? 2 : 1;
			else if(offset == 0)
				gradient_start = 2;
			else if(mirror_offset == 0)
				gradient_start = 1;
			else
				gradient_start = 0;

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

			StrafeHUD_drawGradient(
				color, autocvar_hud_panel_strafehud_bar_neutral_color,
				mirror_size, original_width, mirror_offset,
				alpha, gradient_mirror_offset, gradientType);

			StrafeHUD_drawGradient(
				color, autocvar_hud_panel_strafehud_bar_neutral_color,
				size, original_width, offset,
				alpha, gradient_offset, gradientType);
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
	vector segment_size = size;
	alpha1 = bound(0, alpha, 1);
	alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, 1);
	if((alpha1 + alpha2) == 0) return;
	color_ratio = alpha1 / (alpha1 + alpha2);
	for(int i = 0; i < size.x; ++i)
	{
		float ratio, alpha_ratio, combine_ratio1, combine_ratio2;
		segment_size.x = min(size.x - i, 1); // each gradient segment is 1 unit wide except if there is less than 1 unit of gradient remaining
		ratio = (i + segment_size.x / 2 + gradientOffset) / original_width * (gradientType == STRAFEHUD_GRADIENT_BOTH ? 2 : 1);
		if(ratio > 1) ratio = 2 - ratio;
		if(gradientType != STRAFEHUD_GRADIENT_RIGHT) ratio = 1 - ratio;
		alpha_ratio = alpha1 - (alpha1 - alpha2) * ratio;
		combine_ratio1 = ratio * (1 - color_ratio);
		combine_ratio2 = (1 - ratio) * color_ratio;
		ratio = (combine_ratio1 + combine_ratio2) == 0 ? 1 : combine_ratio1 / (combine_ratio1 + combine_ratio2);

		if(alpha_ratio > 0)
			drawfill(
				panel_pos + eX * (offset + i),
				segment_size,
				StrafeHUD_mixColors(color1, color2, ratio),
				alpha_ratio,
				DRAWFLAG_NORMAL);
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

	float alpha = cos(((time - lasttime) / fadetime) * M_PI_2); // fade non-linear like the physics panel does
	vector size = panel_size;
	size.y = height;

	switch(position)
	{
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
