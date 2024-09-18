#include "util.qh"

#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>
#include <common/physics/movetypes/movetypes.qh>

float StrafeHUD_AngleToWidth(float angle, float range)
{
	return angle / range * panel_size.x;
}

float StrafeHUD_AngleToOffset(float angle, float range)
{
	return StrafeHUD_AngleToWidth(angle, range) + panel_size.x / 2;
}

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

float StrafeHUD_ProjectOffset(float offset, float range, bool reverse)
{
	if(autocvar_hud_panel_strafehud_projection == STRAFEHUD_PROJECTION_LINEAR)
		return offset;

	float ratio = (offset - (panel_size.x / 2)) / (panel_size.x / 2);
	ratio = StrafeHUD_Project(ratio, range, reverse);
	offset = ratio * (panel_size.x / 2) + (panel_size.x / 2);
	return offset;
}

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

// determine frametime
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

	return dt;
}

// determine player wishdir
float StrafeHUD_DetermineWishAngle(vector movement, int keys, bool islocal)
{
	float wishangle;
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
		if(keys & KEY_FORWARD || keys & KEY_BACKWARD)
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

float StrafeHUD_DetermineHudAngle(float wishangle)
{
	float hudangle;
	if(isnan(autocvar_hud_panel_strafehud_range))
	{
		hudangle = 0;
	}
	else if(autocvar_hud_panel_strafehud_range == 0)
	{
		if(autocvar__hud_configure)
		{
			hudangle = 90;
		}
		else
		{
			// determine the minimal required HUD angle to contain the full strafing angle range
			// this is useful for the velocity centered mode where the zones do not follow the strafing angle
			// how it works:
			//   the angle where the most acceleration occurs moves relative to the player velocity
			//   from 0 - wishangle to 90 - wishangle
			//   the angle farther away from the center is the maximum the optimal strafing angle can
			//   diverge from the direction of velocity
			//   this angle has to be multiplied by two since the HUD extends in both directions which
			//   halves the amount it extends in a single direction
			float absolute_wishangle = fabs(wishangle);
			hudangle = max(absolute_wishangle, 90 - absolute_wishangle) * 2;
		}
	}
	else if(autocvar_hud_panel_strafehud_range < 0)
	{
		float hfov = getproperty(VF_FOVX);
		if(isnan(hfov)) hfov = 0;

		hudangle = hfov;
	}
	else
	{
		hudangle = bound(0, fabs(autocvar_hud_panel_strafehud_range), 360); // limit HUD range to 360 degrees, higher values do not make sense
	}

	// limit strafe-meter angle to values suitable for the current projection mode
	switch(autocvar_hud_panel_strafehud_projection)
	{
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
	{
		return STRAFEHUD_DIRECTION_RIGHT;
	}
	else if(wishangle < 0)
	{
		return STRAFEHUD_DIRECTION_LEFT;
	}
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

// try to ignore if track_canjump is enabled, does not work in spectator mode if spectated player uses +jetpack or cl_movement_track_canjump
bool StrafeHUD_DetermineJumpHeld(entity e, int keys, bool islocal)
{
	if(islocal)
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

vector StrafeHUD_MixColors(vector color1, vector color2, float ratio)
{
	vector mixedColor;
	if(ratio <= 0) return color1;
	if(ratio >= 1) return color2;
	mixedColor.x = color1.x + (color2.x - color1.x) * ratio;
	mixedColor.y = color1.y + (color2.y - color1.y) * ratio;
	mixedColor.z = color1.z + (color2.z - color1.z) * ratio;
	return mixedColor;
}
