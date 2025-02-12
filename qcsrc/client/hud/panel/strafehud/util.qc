#include "util.qh"

#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>
#include <common/physics/movetypes/movetypes.qh>

// non-local players
#include <common/ent_cs.qh> // CSQCModel_server2csqc()
#include <common/animdecide.qh> // anim_implicit_state

// convert a strafe angle into a HUD width value
float StrafeHUD_AngleToWidth(float angle, float range)
{
	return angle / range * panel_size.x;
}

// convert a strafe angle into a centered HUD offset value
float StrafeHUD_AngleToOffset(float angle, float range)
{
	return StrafeHUD_AngleToWidth(angle, range) + panel_size.x / 2;
}

// turn a ratio into a projected ratio based on the total angular distance
float StrafeHUD_Project(float ratio, float range, bool reverse)
{
	range *= DEG2RAD / 2;
	switch(autocvar_hud_panel_strafehud_projection)
	{
		default:
		case STRAFEHUD_PROJECTION_LINEAR:
			return ratio;
		case STRAFEHUD_PROJECTION_PERSPECTIVE:
			if(!reverse)
			{
				ratio *= range;
				ratio = tan(ratio) / tan(range);
			}
			else
			{
				ratio = atan(ratio * tan(range));
				ratio /= range;
			}
			break;
		case STRAFEHUD_PROJECTION_PANORAMIC:
			if(!reverse)
			{
				ratio *= range;
				ratio = tan(ratio / 2) / tan(range / 2);
			}
			else
			{
				ratio = atan(ratio * tan(range / 2)) * 2;
				ratio /= range;
			}
			break;
	}
	return ratio;
}

// project a centered HUD offset value
float StrafeHUD_ProjectOffset(float offset, float range, bool reverse)
{
	if(autocvar_hud_panel_strafehud_projection == STRAFEHUD_PROJECTION_LINEAR)
		return offset;

	float ratio = (offset - (panel_size.x / 2)) / (panel_size.x / 2);
	ratio = StrafeHUD_Project(ratio, range, reverse);
	offset = ratio * (panel_size.x / 2) + (panel_size.x / 2);
	return offset;
}

// project a HUD width value
float StrafeHUD_ProjectWidth(float offset, float width, float range)
{
	if(autocvar_hud_panel_strafehud_projection == STRAFEHUD_PROJECTION_LINEAR)
		return width;

	return StrafeHUD_ProjectOffset(offset + width, range, false) - StrafeHUD_ProjectOffset(offset, range, false);
}

// length unit conversion (km and miles are only included to match the GetSpeedUnit* functions)
float StrafeHUD_GetLengthUnitFactor(int length_unit)
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

string StrafeHUD_GetLengthUnit(int length_unit)
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

entity StrafeHUD_GetStrafeplayer(bool is_local)
{
	// use the local csqcmodel entity if it's valid (i.e. is_local == true)
	return is_local
		? csqcplayer
		: CSQCModel_server2csqc(player_localentnum - 1);
}

// check the player waterlevel without affecting the player entity, this way we can fetch waterlevel even if client prediction is disabled
float StrafeHUD_DetermineWaterLevel(entity e)
{
	// store old values
	void old_contentstransition(int, int) = e.contentstransition;
	float old_watertype = e.watertype;
	float old_waterlevel = e.waterlevel;

	e.contentstransition = func_null; // unset the contentstransition function if present
	_Movetype_CheckWater(e);
	float new_waterlevel = e.waterlevel; // store the player waterlevel

	// restore old values
	e.contentstransition = old_contentstransition;
	e.watertype = old_watertype;
	e.waterlevel = old_waterlevel;

	return new_waterlevel;
}

// determine frametime, to avoid jitter, average the frametime in case client prediction is used
float StrafeHUD_DetermineFrameTime()
{
	static float dt_update = 0;
	static int dt_time = 0;
	static float dt_sum = 0;
	static float dt = 0;
	if((csqcplayer_status == CSQCPLAYERSTATUS_PREDICTED) && (input_timelength > 0))
	{
		float dt_client = input_timelength;

		if(dt_client > .05) // server splits frames longer than 50 ms into two moves (DarkPlaces behaviour)
			dt_client /= 2; // does not ensure frames are smaller than 50 ms, just splits large frames in half, matches server behaviour

		/* calculate average frametime
		 * calculated using a weighted arithmetic mean, where the weighting is equal to the frametime itself
		 * for example, given a 1 ms frame and a 9 ms frame we have:
		 *   a total time of 10 ms
		 *   a weighted sum of 1 ms * 1 ms + 9 ms * 9 ms = 82 ms^2
		 *   the final result is 82 ms^2 / 10 ms = 8.2 ms
		 */
		dt_sum += dt_client * dt_client; // weighted sum of all frametimes (mean numerator)
		dt_time += dt_client; // time spent averaging (mean denominator)

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

	return dt;
}

// determine player wishdir, non-local player movement is limited to 45 degree steps
float StrafeHUD_DetermineWishAngle(vector movement, int keys, bool is_local)
{
	float wishangle;
	if(is_local) // if entity is local player
	{
		if(movement.y == 0)
			wishangle = 0;
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
	else // alternatively calculate wishdir by querying pressed keys
	{
		if(keys & (KEY_FORWARD | KEY_BACKWARD))
			wishangle = 45;
		else
			wishangle = 90;
		if(keys & KEY_LEFT)
			wishangle *= -1;
		else if(!(keys & KEY_RIGHT))
			wishangle = 0; // wraps at 180°
	}

	return wishangle;
}

// determine whether the player is pressing forwards or backwards keys
int StrafeHUD_DetermineForwardKeys(vector movement, int keys, bool is_local)
{
	if(is_local) // if entity is local player
	{
		if(movement.x > 0)
			return STRAFEHUD_KEYS_FORWARD;
		else if(movement.x < 0)
			return STRAFEHUD_KEYS_BACKWARD;
		else
			return STRAFEHUD_KEYS_NONE;
	}
	else // alternatively determine direction by querying pressed keys
	{
		if((keys & KEY_FORWARD) && !(keys & KEY_BACKWARD))
			return STRAFEHUD_KEYS_FORWARD;
		else if(!(keys & KEY_FORWARD) && (keys & KEY_BACKWARD))
			return STRAFEHUD_KEYS_BACKWARD;
		else
			return STRAFEHUD_KEYS_NONE;
	}
}

float StrafeHUD_DetermineHudAngle(float absolute_wishangle, float absolute_overturnangle, float strafity)
{

	// determine the minimal required HUD angle to contain the full strafing angle range
	// this is useful for the velocity centered mode where the zones do not follow the strafing angle
	// how it works:
	//   the angle where the most acceleration occurs moves relative to the player velocity
	//   from 0 - wishangle to absolute_overturnangle - wishangle
	//   the angle farther away from the center is the maximum the optimal strafing angle can
	//   diverge from the direction of velocity
	//   this angle has to be multiplied by two since the HUD extends in both directions which
	//   halves the amount it extends in a single direction
	float range_minangle = max(absolute_wishangle, absolute_overturnangle - absolute_wishangle) * 2;

	float range_normal = autocvar_hud_panel_strafehud_range;
	float range_side   = autocvar_hud_panel_strafehud_range_sidestrafe;
	float range_used;

	float hfov = getproperty(VF_FOVX);
	if(isnan(range_normal) || isnan(range_side) || isnan(hfov)) return 360;

	// negative values enable different behaviour
	// no exact matching so that all negative values are caught
	if(range_normal == 0) // range = 0, use minimum angle required if dynamically setting hud angle
		range_normal = autocvar__hud_configure ? 90 : range_minangle;
	else if(range_normal < 0) // range = -1, use the current field of view
		range_normal = hfov;

	if(range_side < -1) // range = -2, use the normal range
		range_used = range_normal;
	else
	{
		if(range_side == 0)  // range = 0, use minimum angle required if dynamically setting hud angle
			range_side = autocvar__hud_configure ? 90 : range_minangle;
		else if(range_side < 0) // range = -1, use the current field of view
			range_side = hfov;

		range_used = GeomLerp(range_normal, strafity, range_side);
	}
	float hudangle = bound(0, fabs(range_used), 360); // limit HUD range to 360 degrees, higher values don't make sense

	// limit strafe-meter angle to values suitable for the current projection mode
	switch(autocvar_hud_panel_strafehud_projection)
	{
		// those limits are a little less than the maximal FOV the game allows
		// however, they suffice for all realistic use cases
		case STRAFEHUD_PROJECTION_PERSPECTIVE:
			hudangle = min(hudangle, 170);
			break;
		case STRAFEHUD_PROJECTION_PANORAMIC:
			hudangle = min(hudangle, 350);
			break;
	}

	return hudangle;
}

// determine whether the player is strafing left or right
float StrafeHUD_DetermineDirection(float angle, float wishangle, float antiflicker_angle)
{
	if(wishangle > 0)
		return STRAFEHUD_DIRECTION_RIGHT;
	else if(wishangle < 0)
		return STRAFEHUD_DIRECTION_LEFT;
	else
	{
		if(angle > antiflicker_angle && angle < (180 - antiflicker_angle))
			return STRAFEHUD_DIRECTION_RIGHT;
		else if(angle < -antiflicker_angle && angle > (-180 + antiflicker_angle))
			return STRAFEHUD_DIRECTION_LEFT;
		else
			return STRAFEHUD_DIRECTION_NONE;
	}
}

// determine whether the player holds the jump key
// try to ignore if track_canjump is enabled
// does not work in spectator mode if the spectated player uses +jetpack or cl_movement_track_canjump
bool StrafeHUD_DetermineJumpHeld(entity e, int keys, bool is_local)
{
	if(is_local)
	{
		if((PHYS_INPUT_BUTTON_JUMP(e) || PHYS_INPUT_BUTTON_JETPACK(e)) && !PHYS_CL_TRACK_CANJUMP(e))
			return true;
	}
	else
	{
		if((keys & KEY_JUMP) && !PHYS_TRACK_CANJUMP(e))
			return true;
	}

	return false;
}

// determine whether the player is on ground
// this return value is used in real_onground, not onground
bool StrafeHUD_DetermineOnGround(entity e, bool is_local)
{
	return is_local ? IS_ONGROUND(e) : !(e.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
}

// determine whether the player is standing on a slick surface
// NOTE: this isn't the only condition for the slick detector being drawn
bool StrafeHUD_DetermineOnSlick(entity e)
{
	// do not use IS_ONSLICK(), it only works for the local player and only if client prediction is enabled
	trace_dphitq3surfaceflags = 0;
	tracebox(e.origin, e.mins, e.maxs, e.origin - '0 0 1', MOVE_NOMONSTERS, e);
	return boolean(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK);
}

// mix two colors based on a ratio
// TODO: move mixing colors out of the HUD, this could be useful for other code
vector StrafeHUD_MixColors(vector color1, vector color2, float ratio)
{
	if(ratio <= 0) return color1;
	if(ratio >= 1) return color2;
	return color1 + (color2 - color1) * ratio;
}

vector StrafeHUD_CalculateTextIndicatorPosition(vector pos)
{
	pos.x *= panel_size.x / 2; // more intuitive since we start in the middle, this turns the range from -0.5 to +0.5 into -1 to +1
	pos.y *= panel_size.y;
	pos.z = 0;

	return pos;
}
