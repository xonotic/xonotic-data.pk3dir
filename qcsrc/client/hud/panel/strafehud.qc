// Author: Juhu

#include "strafehud.qh"

#include <client/draw.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>
#include <common/physics/movetypes/movetypes.qh>
#include "racetimer.qh"

// non-essential
#include <client/view.qh> // for v_flipped state

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
		if(!autocvar_hud_panel_strafehud
		|| (spectatee_status == -1 && (autocvar_hud_panel_strafehud == 1 || autocvar_hud_panel_strafehud == 3))
		|| (autocvar_hud_panel_strafehud == 3 && !MUTATOR_CALLHOOK(HUD_StrafeHUD_showoptional)))
		{
			hud_lasttime = time;
			return;
		}
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

	bool is_local = !(spectatee_status > 0 || isdemo());
	entity strafeplayer = StrafeHUD_GetStrafeplayer(is_local);

	if(!csqcplayer || !strafeplayer)
	{
		hud_lasttime = time;
		return;
	}

	// draw strafehud

	int keys = STAT(PRESSED_KEYS);
	bool jumpheld = StrafeHUD_DetermineJumpHeld(strafeplayer, keys, is_local);

	// does not get changed by ground timeout and is not affected by jump input
	bool real_onground = StrafeHUD_DetermineOnGround(strafeplayer, is_local);

	// does not get changed by ground timeout
	bool real_onslick = false;

	// if jump is held assume we are in air, avoids flickering of the hud when hitting the ground
	bool onground = real_onground && !jumpheld;
	bool onslick = real_onslick;

	// the hud will not work well while swimming
	float strafe_waterlevel = StrafeHUD_DetermineWaterLevel(strafeplayer);
	bool swimming = strafe_waterlevel >= WATERLEVEL_SWIMMING;

	static float onground_lasttime = 0;
	static bool onslick_last = false;
	if(onground)
	{
		real_onslick = onslick = StrafeHUD_DetermineOnSlick(strafeplayer);

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
	else if(onslick)
	{
		if(!autocvar__hud_configure)
			maxaccel = PHYS_SLICKACCELERATE(strafeplayer);
	}

	// move values are only valid for the local player
	vector movement = PHYS_INPUT_MOVEVALUES(strafeplayer);

	float movespeed;
	if(is_local)
	{
		movespeed = min(vlen(vec2(movement)), maxspeed);

		// assume maxspeed so that the hud remains useful even if no direction keys are pressed
		if(movespeed == 0) movespeed = maxspeed;
	}
	else
	{
		// the only information available is whether a movement key is pressed or not
		// which means the movespeed would be either maxspeed or zero
		// since we set it to maxspeed if it is zero the movespeed will always equal maxspeed if the player is not local
		movespeed = maxspeed;
	}

	// the following functions have to check themselves whether the player is local and use the move values accordingly
	int keys_fwd = StrafeHUD_DetermineForwardKeys(movement, keys, is_local);
	float wishangle = StrafeHUD_DetermineWishAngle(movement, keys, is_local);
	float absolute_wishangle = fabs(wishangle); // unmodified by side strafing code
	bool strafekeys = fabs(wishangle) > 45;

	// detect air strafe turning
	static bool turn = false;
	float strafity = 0;
	if(!strafekeys || onground || autocvar__hud_configure)
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

			if(PHYS_MAXAIRSTRAFESPEED(strafeplayer) != 0)
				maxspeed = min(maxspeed, GeomLerp(PHYS_MAXAIRSPEED(strafeplayer), strafity, PHYS_MAXAIRSTRAFESPEED(strafeplayer)));

			movespeed = min(movespeed, maxspeed);

			if(PHYS_AIRSTRAFEACCELERATE(strafeplayer) != 0)
				maxaccel = GeomLerp(PHYS_AIRACCELERATE(strafeplayer), strafity, PHYS_AIRSTRAFEACCELERATE(strafeplayer));
		}
	}

	float dt = StrafeHUD_DetermineFrameTime();

	maxaccel *= dt * movespeed;
	float bestspeed = max(movespeed - maxaccel, 0); // target speed to gain maximum acceleration

	// use local csqcmodel entity for this even when spectating, flickers too much otherwise
	vector strafevelocity = csqcplayer.velocity;

	float speed = !autocvar__hud_configure ? vlen(vec2(strafevelocity)) : 1337;
	bool moving = speed > 0;

	float frictionspeed; // speed lost from friction
	float strafespeed; // speed minus friction

	if(moving && onground)
	{
		float strafefriction = onslick ? PHYS_FRICTION_SLICK(strafeplayer) : PHYS_FRICTION(strafeplayer);

		if (strafefriction > 0)
		{
			float S = PHYS_STOPSPEED(strafeplayer);
			//strafespeed = speed * (1 - dt * strafefriction * ((speed < S) ? (S / speed) : 1));
			// NOTE: this is copied from ecs/systems/physics.qc
			float dt_r = PHYS_FRICTION_REPLICA_DT;
			//if (strafefriction * dt_r >= 1)
			//	strafespeed = 0;
			//else
			{
				float independent_geometric = (1 - strafefriction * dt_r) ** (dt / dt_r);
				if (S < speed && speed < S / independent_geometric)
					strafespeed = S - S * strafefriction * (dt - (dt_r * log(S / speed)) / log(1 - strafefriction * dt_r));
				else if (speed >= S)
					strafespeed = speed * independent_geometric;
				else
					strafespeed = speed - strafefriction * dt * S;
				strafespeed = max(0, strafespeed);
			}
		}
		else
			strafespeed = speed;
		frictionspeed = speed - strafespeed;
	}
	else
	{
		frictionspeed = 0;
		strafespeed = speed;
	}

	// get current strafing angle ranging from -180° to +180°
	float angle;
	bool fwd; // left & right variables are flipped when !fwd

	if(!autocvar__hud_configure)
	{
		if(moving)
		{
			// change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
			float vel_angle = vectoangles(strafevelocity).y;
			if(vel_angle > 180) vel_angle -= 360;
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

	float airstopaccel = PHYS_AIRSTOPACCELERATE(strafeplayer);
	if(airstopaccel == 0 || turn) // no airstopaccel while side strafing
		airstopaccel = 1; // values of 0 are equivalent to 1

	// best angle to strafe at
	// k9er: documentation here https://gitlab.com/otta8634/xonotic-physics
	float bestangle;
	float prebestangle;
	float overturnangle;
	if(!moving)
	{
		// these are unused (neutral fills whole strafe bar)
		prebestangle = bestangle = 0;
		overturnangle = 180;
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
			overturnangle = overturn_denom > fabs(overturn_numer)
				? acos(overturn_numer / overturn_denom) * RAD2DEG // case 1
				: (overturn_numer < 0 ? 180 : 0); // case 2 : case 3
			// case 1: normal. case 2: low speed, turning anywhere will gain speed. case 3: landed at high speed, turning anywhere will lose speed (due to friction)
		}
		if(overturnangle < bestangle || bestangle < prebestangle)
		{
			// these conditions occur when you land at high speed (above max onground speed), such that every wishangle will result in a speed loss due to friction
			if(autocvar_hud_panel_strafehud_onground_mode == STRAFEHUD_ONGROUND_OVERTURN)
			{
				// make overturn fill the whole strafe bar
				// most correct option by the true definition of accel, since every angle results in deceleration
				prebestangle = bestangle = 0;
				overturnangle = 0;
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
				overturnangle = bestangle;
				prebestangle = bestangle;
			}
			else
			{
				// use angles as if in air (see below), no range checks are needed
				// no need to check if numerator < denominator, since all numerators < max onground speed < speed = all denominators
				bestangle = acos(bestspeed / speed) * RAD2DEG;
				prebestangle = acos(movespeed / speed) * RAD2DEG;
				overturnangle = (airstopaccel == 1 || PHYS_AIRSTOPACCELERATE_FULL(strafeplayer))
					? acos(-(airstopaccel * maxaccel * 0.5) / speed) * RAD2DEG
					: acos(-maxaccel / (2 * speed - (airstopaccel - 1) * maxaccel)) * RAD2DEG;
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
		// with airstopaccel, delta_max = acos(airstopaccel * -a / 2v), only in air,
		// ... or if not applied fully, delta_max = acos(-a / (2v - (airstopaccel - 1) * a))
		overturnangle = speed > airstopaccel * maxaccel * 0.5
			? ((airstopaccel == 1 || PHYS_AIRSTOPACCELERATE_FULL(strafeplayer))
				? acos(-(airstopaccel * maxaccel * 0.5) / speed) * RAD2DEG
				: acos(-maxaccel / (2 * speed - (airstopaccel - 1) * maxaccel)) * RAD2DEG)
			: 180;
	}
	// absolute_* variables which are always positive with no wishangle offset
	float absolute_bestangle = bestangle;
	float absolute_prebestangle = prebestangle;
	float absolute_overturnangle = overturnangle;

	float aircontrol = PHYS_AIRCONTROL(strafeplayer);
	int aircontrol_flags = PHYS_AIRCONTROL_FLAGS(strafeplayer);
	bool is_aircontrol_keys = (keys_fwd == STRAFEHUD_KEYS_FORWARD)
		|| ((aircontrol_flags & BIT(0)) && keys_fwd == STRAFEHUD_KEYS_BACKWARD);
	bool is_aircontrol_direction = fwd || (aircontrol_flags & BIT(0));
	bool airaccel_qw = PHYS_AIRACCEL_QW(strafeplayer) == 1;

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
	bool wturning = (wishangle == 0) && !onground && is_aircontrol_keys;
	bool wturn_valid = false;
	float wturn_bestangle = 0;
	if(autocvar_hud_panel_strafehud_wturn && moving &&
		aircontrol && PHYS_AIRCONTROL_PENALTY(strafeplayer) == 0 &&
		(airaccel_qw || autocvar_hud_panel_strafehud_wturn_unrestricted == 1))
	{
		float wturn_power = PHYS_AIRCONTROL_POWER(strafeplayer);
		if(wturn_power == 2)
		{
			float wturn_a = 32 * fabs(aircontrol) * dt;
			if(aircontrol_flags & BIT(2)) // crouching has no impact
				wturn_a *= maxspeed / maxspeed_phys;
			float wturn_V = 1 - (wturn_a * wturn_a) / (speed * speed);
			if(autocvar_hud_panel_strafehud_wturn_proper && wturn_a > 1 && wturn_V < 1 && wturn_V > -1)
				wturn_bestangle = acos(-speed / wturn_a * (cos((acos(wturn_V) + M_PI * 2) / 3) * 2 + 1)) * RAD2DEG;
			else
				wturn_bestangle = ACOS_SQRT2_3_DEG;
			wturn_valid = true;
		}
		else if(!autocvar_hud_panel_strafehud_wturn_proper && wturn_power >= 0)
		{
			wturn_bestangle = acos(sqrt(wturn_power / (wturn_power + 1))) * RAD2DEG;
			wturn_valid = true;
		}
	}
	float absolute_wturn_bestangle = wturn_bestangle;

	// draw the switch indicators as if strafing normally (W+A style), while W-turning or side strafing
	float n_bestangle = 0;
	float absolute_n_prebestangle = 0; // also needed for W-turn angles
	bool draw_normal = ((autocvar_hud_panel_strafehud_switch >= STRAFEHUD_SWITCH_NORMAL && wturning)
		|| (autocvar_hud_panel_strafehud_switch == STRAFEHUD_SWITCH_SIDESTRAFE && turn));
	if(draw_normal || wturn_valid)
	{
		// recalculate bestangle as if strafing normally
		float n_maxspeed  = PHYS_MAXAIRSPEED(strafeplayer) * maxspeed_mod;
		float n_movespeed = n_maxspeed;
		float n_maxaccel  = PHYS_AIRACCELERATE(strafeplayer) * dt * n_movespeed;
		float n_bestspeed = max(n_movespeed - n_maxaccel, 0);
		n_bestangle = speed > n_bestspeed
			? acos(n_bestspeed / speed) * RAD2DEG - 45
			: -45;
		absolute_n_prebestangle = speed > n_movespeed
			? acos(n_movespeed / speed) * RAD2DEG
			: 0;
	}

	float hudangle = StrafeHUD_DetermineHudAngle(absolute_wishangle, absolute_overturnangle, strafity);

	float antiflicker_angle = bound(0, autocvar_hud_panel_strafehud_antiflicker_angle, 180);
	float direction = StrafeHUD_DetermineDirection(angle, wishangle, antiflicker_angle);

	if(direction == STRAFEHUD_DIRECTION_LEFT) // the angle becomes negative in case we strafe left
	{
		n_bestangle *= -1;
		bestangle *= -1;
		prebestangle *= -1;
		overturnangle *= -1;
	}
	float opposite_bestangle = -bestangle;
	float n_opposite_bestangle = -n_bestangle;

	bestangle -= wishangle;
	opposite_bestangle -= wishangle;
	n_opposite_bestangle -= wishangle;
	prebestangle -= wishangle;
	overturnangle -= wishangle;

	int mode;
	if(autocvar_hud_panel_strafehud_mode >= 0 && autocvar_hud_panel_strafehud_mode <= 1)
		mode = autocvar_hud_panel_strafehud_mode;
	else
		mode = STRAFEHUD_MODE_VIEW_CENTERED;

	// best strafe acceleration angle
	float changeangle = -bestangle;
	float n_changeangle = -n_bestangle;
	float n_opposite_changeangle = n_opposite_bestangle + n_bestangle * 2;

	// minimum speed for change indicators
	float minspeed = autocvar_hud_panel_strafehud_switch_minspeed;
	if(minspeed < 0)
		minspeed = bestspeed + frictionspeed;

	bool opposite_direction = false;
	float opposite_changeangle = 0;
	if((angle > -wishangle && direction == STRAFEHUD_DIRECTION_LEFT) || (angle < -wishangle && direction == STRAFEHUD_DIRECTION_RIGHT))
	{
		opposite_direction = true;
		opposite_changeangle = opposite_bestangle + bestangle * 2;
	}

	// best angle to aim at when W-turning to maximally rotate velocity vector
	float wturn_left_bestangle = wturn_bestangle;
	float wturn_right_bestangle = -wturn_bestangle;

	// shift hud if operating in view angle centered mode
	float shiftangle = 0;
	if(mode == STRAFEHUD_MODE_VIEW_CENTERED)
	{
		shiftangle = -angle;
		bestangle += shiftangle;
		changeangle += shiftangle;
		opposite_bestangle += shiftangle;
		opposite_changeangle += shiftangle;
		n_bestangle += shiftangle;
		n_changeangle += shiftangle;
		n_opposite_bestangle += shiftangle;
		n_opposite_changeangle += shiftangle;
		wturn_left_bestangle += shiftangle;
		wturn_right_bestangle += shiftangle;
	}

	StrafeHUD_DrawStrafeMeter(shiftangle, wishangle, absolute_bestangle, absolute_prebestangle, absolute_overturnangle, moving, hudangle);

	float text_offset_top;
	float text_offset_bottom;
	bool all_slick = PHYS_FRICTION(strafeplayer) == 0;
	text_offset_top = text_offset_bottom = StrafeHUD_DrawSlickDetector(strafeplayer, (all_slick && real_onground) || real_onslick);

	if(autocvar_hud_panel_strafehud_direction)
		StrafeHUD_DrawDirectionIndicator(direction, opposite_direction, fwd);

	// determine the strafing ratio and the angle indicator color
	vector currentangle_color = autocvar_hud_panel_strafehud_angle_neutral_color;
	float strafe_ratio = 0;
	if(moving)
	{
		float moveangle = fabs(angle + wishangle);
		if(moveangle > 180) moveangle = 360 - moveangle; // restricted to between 0 and 180

		// player is overturning
		if(moveangle >= absolute_overturnangle)
		{
			if(moveangle == absolute_overturnangle && absolute_overturnangle == 180)
			{} // everywhere gives acceleration, keep strafe_ratio as 0
			else
			{
				currentangle_color = autocvar_hud_panel_strafehud_angle_overturn_color;
				strafe_ratio = (moveangle - absolute_overturnangle) / (180 - absolute_overturnangle);
				// moveangle is always <= 180, so this code won't run if absolute_overturnangle == 180
				strafe_ratio *= -1;
			}
		}
		// player gains speed by strafing
		else if(moveangle >= absolute_bestangle)
		{
			currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
			strafe_ratio = (absolute_overturnangle - moveangle) / (absolute_overturnangle - absolute_bestangle);
			// if absolute_overturnangle == absolute_bestangle, this code won't run, no need to check if their difference is 0
		}
		else if(moveangle >= absolute_prebestangle)
		{
			if(autocvar_hud_panel_strafehud_bar_preaccel)
				currentangle_color = autocvar_hud_panel_strafehud_angle_preaccel_color;
			strafe_ratio = (moveangle - absolute_prebestangle) / (absolute_bestangle - absolute_prebestangle);
		}

		if(StrafeHUD_IsGradient(autocvar_hud_panel_strafehud_style))
			currentangle_color = StrafeHUD_MixColors(
				autocvar_hud_panel_strafehud_angle_neutral_color,
				currentangle_color, fabs(strafe_ratio));
	}

	float currentangle = 0;
	if(mode == STRAFEHUD_MODE_VELOCITY_CENTERED)
	{
		// avoid switching side too much at ±180° if anti flicker is triggered
		if(fabs(angle) <= 180 - antiflicker_angle)
			currentangle = angle;
	}

	float max_line_height = 0;
	float max_top_arrow_size = 0;
	float max_bottom_arrow_size = 0;

	// only draw switch indicators if minspeed is reached
	if(autocvar_hud_panel_strafehud_switch && autocvar_hud_panel_strafehud_switch_alpha > 0 && speed >= minspeed)
	{
		// change angle indicator style
		vector indicator_size;
		indicator_size.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_switch_line_width, 10), 1);
		indicator_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_switch_line_height, 10), 1);
		indicator_size.z = 0;

		float num_dashes = rint(autocvar_hud_panel_strafehud_switch_line);
		bool has_top_arrow = autocvar_hud_panel_strafehud_switch_arrow == 1 || autocvar_hud_panel_strafehud_switch_arrow >= 3;
		bool has_bottom_arrow = autocvar_hud_panel_strafehud_switch_arrow >= 2;

		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_switch_arrow_size, 10), 1);

		if(num_dashes > 0)
			max_line_height = max(max_line_height, indicator_size.y);
		if(has_top_arrow)
			max_top_arrow_size = max(max_top_arrow_size, arrow_size);
		if(has_bottom_arrow)
			max_bottom_arrow_size = max(max_bottom_arrow_size, arrow_size);

		// draw the change indicator(s)
		float current_changeangle = draw_normal
			? (opposite_direction ? n_opposite_changeangle : n_changeangle)
			: (opposite_direction ? opposite_changeangle : changeangle);
		float opposite_changeangle = draw_normal
			? (opposite_direction ? n_opposite_bestangle : n_bestangle)
			: (opposite_direction ? opposite_bestangle : bestangle);

		StrafeHUD_DrawAngleIndicator(
			current_changeangle, indicator_size, arrow_size, num_dashes,
			has_top_arrow, has_bottom_arrow, autocvar_hud_panel_strafehud_switch_color,
			autocvar_hud_panel_strafehud_switch_alpha, hudangle);

		if(direction == STRAFEHUD_DIRECTION_NONE || draw_normal)
		{
			StrafeHUD_DrawAngleIndicator(
				opposite_changeangle, indicator_size, arrow_size, num_dashes,
				has_top_arrow, has_bottom_arrow, autocvar_hud_panel_strafehud_switch_color,
				autocvar_hud_panel_strafehud_switch_alpha, hudangle);
		}
	}

	if(autocvar_hud_panel_strafehud_bestangle && autocvar_hud_panel_strafehud_bestangle_alpha > 0 &&
		(autocvar_hud_panel_strafehud_bestangle == 1 || turn) && direction != STRAFEHUD_DIRECTION_NONE)
	{
		// best angle indicator style
		vector indicator_size;
		indicator_size.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_bestangle_line_width, 10), 1);
		indicator_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_bestangle_line_height, 10), 1);
		indicator_size.z = 0;

		float num_dashes = rint(autocvar_hud_panel_strafehud_bestangle_line);
		bool has_top_arrow = autocvar_hud_panel_strafehud_bestangle_arrow == 1 || autocvar_hud_panel_strafehud_bestangle_arrow >= 3;
		bool has_bottom_arrow = autocvar_hud_panel_strafehud_bestangle_arrow >= 2;

		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_bestangle_arrow_size, 10), 1);

		if(num_dashes > 0)
			max_line_height = max(max_line_height, indicator_size.y);
		if(has_top_arrow)
			max_top_arrow_size = max(max_top_arrow_size, arrow_size);
		if(has_bottom_arrow)
			max_bottom_arrow_size = max(max_bottom_arrow_size, arrow_size);

		float ghostangle = opposite_direction ? opposite_bestangle : bestangle;

		StrafeHUD_DrawAngleIndicator(
			ghostangle, indicator_size, arrow_size, num_dashes,
			has_top_arrow, has_bottom_arrow, autocvar_hud_panel_strafehud_bestangle_color,
			autocvar_hud_panel_strafehud_bestangle_alpha, hudangle);
	}

	// only draw wturn indicators if conditions were met
	if(wturn_valid && !onground && is_aircontrol_direction &&
		autocvar_hud_panel_strafehud_wturn_alpha > 0 &&
		absolute_wturn_bestangle < absolute_n_prebestangle &&
		((autocvar_hud_panel_strafehud_wturn && wturning) ||
		(autocvar_hud_panel_strafehud_wturn == STRAFEHUD_WTURN_NORMAL && !turn) ||
		(autocvar_hud_panel_strafehud_wturn == STRAFEHUD_WTURN_SIDESTRAFE)))
	{
		// wturn angle indicator style
		vector indicator_size;
		indicator_size.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_wturn_line_width, 10), 1);
		indicator_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_wturn_line_height, 10), 1);
		indicator_size.z = 0;

		float num_dashes = rint(autocvar_hud_panel_strafehud_wturn_line);
		bool has_top_arrow = autocvar_hud_panel_strafehud_wturn_arrow == 1 || autocvar_hud_panel_strafehud_wturn_arrow >= 3;
		bool has_bottom_arrow = autocvar_hud_panel_strafehud_wturn_arrow >= 2;

		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_wturn_arrow_size, 10), 1);

		if(num_dashes > 0)
			max_line_height = max(max_line_height, indicator_size.y);
		if(has_top_arrow)
			max_top_arrow_size = max(max_top_arrow_size, arrow_size);
		if(has_bottom_arrow)
			max_bottom_arrow_size = max(max_bottom_arrow_size, arrow_size);

		// draw the wturn indicators
		StrafeHUD_DrawAngleIndicator(
			wturn_left_bestangle, indicator_size, arrow_size, num_dashes,
			has_top_arrow, has_bottom_arrow, autocvar_hud_panel_strafehud_wturn_color,
			autocvar_hud_panel_strafehud_wturn_alpha, hudangle);
		StrafeHUD_DrawAngleIndicator(
			wturn_right_bestangle, indicator_size, arrow_size, num_dashes,
			has_top_arrow, has_bottom_arrow, autocvar_hud_panel_strafehud_wturn_color,
			autocvar_hud_panel_strafehud_wturn_alpha, hudangle);
	}

	if(autocvar_hud_panel_strafehud_angle_alpha > 0)
	{
		// current angle indicator style
		vector indicator_size;
		indicator_size.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_angle_line_width, 10), 1);
		indicator_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_line_height, 10), 1);
		indicator_size.z = 0;

		float num_dashes = rint(autocvar_hud_panel_strafehud_angle_line);
		bool has_top_arrow = autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3;
		bool has_bottom_arrow = autocvar_hud_panel_strafehud_angle_arrow >= 2;

		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_arrow_size, 10), 1);

		if(num_dashes > 0)
			max_line_height = max(max_line_height, indicator_size.y);
		if(has_top_arrow)
			max_top_arrow_size = max(max_top_arrow_size, arrow_size);
		if(has_bottom_arrow)
			max_bottom_arrow_size = max(max_bottom_arrow_size, arrow_size);

		StrafeHUD_DrawAngleIndicator(
			currentangle, indicator_size, arrow_size, num_dashes,
			has_top_arrow, has_bottom_arrow, currentangle_color,
			autocvar_hud_panel_strafehud_angle_alpha, hudangle);
	}

	// offset text by amount the angle indicator extrudes from the strafehud bar
	{
		float line_height_offset = max_line_height;

		// amount line extrudes from the strafehud bar
		line_height_offset = (line_height_offset - panel_size.y) / 2;

		// further offset the top text offset if the top arrow is drawn
		float angle_offset_top;
		angle_offset_top = line_height_offset + max_top_arrow_size;

		// further offset the bottom text offset if the bottom arrow is drawn
		float angle_offset_bottom;
		angle_offset_bottom = line_height_offset + max_bottom_arrow_size;

		// make sure text does not draw inside the strafehud bar
		text_offset_top = max(angle_offset_top, text_offset_top);
		text_offset_bottom = max(angle_offset_bottom, text_offset_bottom);
	}

	StrafeHUD_DrawVerticalAngle(strafeplayer, text_offset_top, text_offset_bottom);

	draw_beginBoldFont();
	StrafeHUD_DrawStartSpeed(race_timespeed, text_offset_top, text_offset_bottom);
	StrafeHUD_DrawStrafeEfficiency(strafe_ratio, text_offset_top, text_offset_bottom);
	StrafeHUD_DrawJumpHeight(strafeplayer, real_onground, swimming, text_offset_top, text_offset_bottom);
	draw_endBoldFont();

	StrafeHUD_Sonar(strafe_ratio, StrafeHUD_UpdateSonarSound());

	hud_lasttime = time;
}
