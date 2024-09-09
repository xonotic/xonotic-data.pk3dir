#include "extra.qh"

#include <client/csqcmodel_hooks.qh>
#include <client/draw.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>

// start speed
#include <client/hud/panel/racetimer.qh> // checkpoint information (race_*)

// jump height
#include <lib/csqcmodel/common.qh> // for IS_PLAYER() macro
#include <common/resources/cl_resources.qh> // IS_DEAD() macro

// slick detector
float StrafeHUD_DrawSlickDetector(entity e, bool onslick)
{
	float slickdetector_height = bound(0, autocvar_hud_panel_strafehud_slickdetector_height, 1);
	slickdetector_height *= panel_size.y;
	if(autocvar_hud_panel_strafehud_slickdetector &&
	   autocvar_hud_panel_strafehud_slickdetector_range > 0 &&
	   autocvar_hud_panel_strafehud_slickdetector_alpha > 0 &&
	   slickdetector_height > 0 &&
	   panel_size.x > 0)
	{
		float slicksteps = bound(0, autocvar_hud_panel_strafehud_slickdetector_granularity, 4);
		bool slickdetected = false;

		slicksteps = 90 / 2 ** slicksteps;

		slickdetected = onslick; // do not need to traceline if already touching slick

		// traceline downwards into every direction
		trace_dphitq3surfaceflags = 0;
		vector traceorigin = e.origin + eZ * e.mins.z;
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

				traceline(traceorigin, traceorigin + slickoffset, MOVE_NOMONSTERS, e);
				if((PHYS_FRICTION(e) == 0 && trace_fraction < 1) || trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
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

		return slickdetector_height;
	}

	return 0;
}

// vertical angle for weapon jumps
float StrafeHUD_drawVerticalAngle(float text_offset_bottom)
{
	if(autocvar_hud_panel_strafehud_vangle)
	{
		float vangle = -PHYS_INPUT_ANGLES(strafeplayer).x;
		float vangle_height = autocvar_hud_panel_strafehud_vangle_size * panel_size.y;
		string vangle_text = strcat(ftos_decimals(vangle, 2), "°");

		bool was_drawn = StrafeHUD_drawTextIndicator(
			vangle_text, vangle_height,
			autocvar_hud_panel_strafehud_vangle_color, 1,
			time, text_offset_bottom, STRAFEHUD_TEXT_BOTTOM);

		if(was_drawn)
			return vangle_height;
	}

	return 0;
}

// strafe sonar
void StrafeHUD_Sonar(float strafe_ratio, string sonarsound)
{
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
	if(autocvar_hud_panel_strafehud_sonar && sonar_ready && (strafe_ratio >= sonar_start))
	{
		sonar_time = time;

		float sonar_volume = bound(0, autocvar_hud_panel_strafehud_sonar_volume_start, 1);
		sonar_volume += autocvar_hud_panel_strafehud_sonar_volume_range * sonar_ratio ** max(1, autocvar_hud_panel_strafehud_sonar_volume_exponent);

		float sonar_pitch = max(0, autocvar_hud_panel_strafehud_sonar_pitch_start);
		sonar_pitch += autocvar_hud_panel_strafehud_sonar_pitch_range * sonar_ratio ** max(1, autocvar_hud_panel_strafehud_sonar_pitch_exponent);

		if(sonarsound && (sonar_volume > 0))
			sound7(csqcplayer, CH_INFO, sonarsound, bound(0, sonar_volume, 1) * VOL_BASE, ATTN_NONE, max(0.000001, sonar_pitch * 100), 0);
	}
}

string StrafeHUD_UpdateSonarSound()
{
	string newsound = autocvar_hud_panel_strafehud_sonar_audio;
	static string cursound = string_null;
	static string sonarsound = string_null;
	if(newsound == "")
	{
		strfree(cursound);
		strfree(sonarsound);
		cursound = sonarsound = string_null;
	}
	else if(newsound != cursound)
	{
		strfree(cursound);
		cursound = strzone(newsound);

		strfree(sonarsound);
		sonarsound = _Sound_fixpath(newsound);
		if(sonarsound)
		{
			sonarsound = strzone(sonarsound);
			precache_sound(sonarsound);
		}
	}

	return sonarsound;
}

// show height achieved by a single jump
// FIXME: checking z position differences is unreliable (warpzones, teleporter, kill, etc), use velocity to calculate jump height instead
// FIXME: move capturing the jump height value out of the HUD
float StrafeHUD_drawJumpHeight(entity e, bool onground, bool swimming, float text_offset_top)
{
	float length_conversion_factor = GetLengthUnitFactor(autocvar_hud_speed_unit);
	static float height_min = 0, height_max = 0; // ground and peak of jump z coordinates
	static float jumpheight = 0, jumptime = 0;   // displayed value and timestamp for fade out

	// tries to catch kill and spectate but those are not reliable
	if((e.velocity.z <= 0) || onground || swimming || IS_DEAD(e) || !IS_PLAYER(e))
	{
		height_min = height_max = e.origin.z;
	}
	else if(e.origin.z > height_max)
	{
		height_max = e.origin.z;
		float jumpheight_new = height_max - height_min;

		if((jumpheight_new * length_conversion_factor) > max(autocvar_hud_panel_strafehud_jumpheight_min, 0))
		{
			jumpheight = jumpheight_new;
			jumptime = time;
		}
	}

	if(autocvar_hud_panel_strafehud_jumpheight)
	{
		// use more decimals when displaying km or miles
		int length_decimals = autocvar_hud_speed_unit >= 3 && autocvar_hud_speed_unit <= 5 ? 6 : 2;

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
			return jumpheight_height;
	}

	return 0;
}

// strafe efficiency
float StrafeHUD_drawStrafeEfficiency(float strafe_ratio, float text_offset_top)
{
	{
		if(autocvar_hud_panel_strafehud_strafeefficiency)
		{
			float strafeeff_height = autocvar_hud_panel_strafehud_strafeefficiency_size * panel_size.y;
			string strafeeff_text = strcat(ftos_decimals(strafe_ratio * 100, 2), "%");
			vector strafeeff_color = '1 1 1' - (strafe_ratio > 0 ? '1 0 1' : '0 1 1') * fabs(strafe_ratio);

			bool was_drawn = StrafeHUD_drawTextIndicator(
				strafeeff_text, strafeeff_height,
				strafeeff_color, 1,
				time, text_offset_top, STRAFEHUD_TEXT_TOP);

			if(was_drawn)
				return strafeeff_height;
		}
	}

	return 0;
}

// show speed when crossing the start trigger
// FIXME: move capturing the race start speed value out of the HUD
float StrafeHUD_drawStartSpeed(float speed, float text_offset_bottom)
{
	static float startspeed = 0, starttime = 0; // displayed value and timestamp for fade out

	// check if the start trigger was hit (will also trigger if the finish trigger was hit if those have the same ID)
	if((race_nextcheckpoint == 1) || (race_checkpoint == 254 && race_nextcheckpoint == 255))
	{
		if((race_checkpointtime > 0) && (starttime != race_checkpointtime))
		{
			starttime = race_checkpointtime;
			startspeed = speed;
		}
	}

	if(autocvar_hud_panel_strafehud_startspeed)
	{
		float speed_conversion_factor = GetSpeedUnitFactor(autocvar_hud_speed_unit);
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
			return startspeed_height;
	}

	return 0;
}
