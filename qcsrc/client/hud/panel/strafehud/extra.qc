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

// epsilon value for the slick detector steps to avoid
// an infinite loop due to floating point rounding errors
// (works with current limits)
#define SLICKDETECT_STEPS_EPSILON 0.00001

// slick detector
// scans for slick in every direction downwards from the player's feet
// may cause performance issues on slower machines
float StrafeHUD_DrawSlickDetector(entity e, bool already_detected)
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
		bool allslick = PHYS_FRICTION(e) == 0;
		bool slickdetected = false;

		slicksteps = 90 * DEG2RAD / 2 ** slicksteps;

		// don't need to traceline if already touching slick
		slickdetected = already_detected;

		// coordinates at the bottom center of the player bbox
		vector traceorigin = e.origin + eZ * e.mins.z;

		// traceline downwards into every direction
		trace_dphitq3surfaceflags = 0;
		for(float i = 0; i < 90 * DEG2RAD - SLICKDETECT_STEPS_EPSILON && !slickdetected; i += slicksteps)
		{
			vector slickoffset;
			float slickrotate;

			// creates a vector angled 'i' degrees relative to the Z vector
			// negative cosine value to face downwards
			slickoffset.z = -cos(i) * autocvar_hud_panel_strafehud_slickdetector_range;
			slickrotate = sin(i) * autocvar_hud_panel_strafehud_slickdetector_range;

			for(float j = 0; j < 360 * DEG2RAD - SLICKDETECT_STEPS_EPSILON && !slickdetected; j += slicksteps)
			{
				// adjusts the vector so that it rotates 'j' degrees around the Z vector
				slickoffset.x = sin(j) * slickrotate;
				slickoffset.y = cos(j) * slickrotate;

				// trace a line, we hit slick if:
				//  - it hits something and surface friction is disabled
				//  - the slick surface flag got set
				// note: it is not guaranteed that the detected surface is actually
				//       a zero friction surface if PHYS_FRICTION_SLICK() does not equal zero
				traceline(traceorigin, traceorigin + slickoffset, MOVE_NOMONSTERS, e);
				if((allslick && trace_fraction < 1)
				|| (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK))
					slickdetected = true;

				// rotation does nothing when we are perpendicular to the ground, hence only one iteration
				if(i == 0) break;
			}
		}

		// if a traceline hit a slick surface
		if(slickdetected)
		{
			vector slickdetector_size = panel_size;
			slickdetector_size.y = slickdetector_height;

			// horizontal lines
			for(int i = 0; i <= 1; ++i)
			{
				float y_offset = (i == 0)
					? -slickdetector_size.y // top
					: panel_size.y;         // bottom
				drawfill(
					panel_pos + eY * y_offset,
					slickdetector_size, autocvar_hud_panel_strafehud_slickdetector_color,
					autocvar_hud_panel_strafehud_slickdetector_alpha * panel_fg_alpha,
					DRAWFLAG_NORMAL);
			}
		}

		return slickdetector_height;
	}

	return 0;
}

// vertical angle for weapon jumps
void StrafeHUD_DrawVerticalAngle(entity e, float text_offset_top, float text_offset_bottom)
{
	if(!autocvar_hud_panel_strafehud_vangle) return;

	float vangle = -PHYS_INPUT_ANGLES(e).x;
	float vangle_height = autocvar_hud_panel_strafehud_vangle_size * panel_size.y;
	string vangle_text = sprintf(_("%s°"), ftos_decimals(vangle, 2));

	StrafeHUD_DrawTextIndicator(
		vangle_text, vangle_height,
		autocvar_hud_panel_strafehud_vangle_color, 1,
		time, autocvar_hud_panel_strafehud_vangle_pos,
		text_offset_top, text_offset_bottom);
}

// show height achieved by a single jump
// FIXME: checking z position differences is unreliable (warpzones, teleporter, kill, etc), use velocity to calculate jump height instead
// FIXME: move capturing the jump height value out of the HUD
void StrafeHUD_DrawJumpHeight(entity e, bool onground, bool swimming, float text_offset_top, float text_offset_bottom)
{
	float length_conversion_factor = StrafeHUD_GetLengthUnitFactor(autocvar_hud_speed_unit);
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

	if(!autocvar_hud_panel_strafehud_jumpheight) return;

	// use more decimals when displaying km or miles
	int length_decimals = autocvar_hud_speed_unit >= 3 && autocvar_hud_speed_unit <= 5 ? 6 : 2;

	float jumpheight_height = autocvar_hud_panel_strafehud_jumpheight_size * panel_size.y;
	string jumpheight_text = ftos_decimals(jumpheight * length_conversion_factor, length_decimals);
	if(autocvar_hud_panel_strafehud_unit_show)
		jumpheight_text = strcat(jumpheight_text, StrafeHUD_GetLengthUnit(autocvar_hud_speed_unit));

	StrafeHUD_DrawTextIndicator(
		jumpheight_text, jumpheight_height,
		autocvar_hud_panel_strafehud_jumpheight_color,
		autocvar_hud_panel_strafehud_jumpheight_fade,
		jumptime, autocvar_hud_panel_strafehud_jumpheight_pos,
		text_offset_top, text_offset_bottom);
}

// strafe efficiency, percentage of how far away the current angle is from the optimal angle
// the percentage changes linearly with angular distance
void StrafeHUD_DrawStrafeEfficiency(float strafe_ratio, float text_offset_top, float text_offset_bottom)
{
	if(!autocvar_hud_panel_strafehud_strafeefficiency) return;

	float strafeeff_height = autocvar_hud_panel_strafehud_strafeefficiency_size * panel_size.y;
	string strafeeff_text = strcat(ftos_decimals(strafe_ratio * 100, 2), "%");
	vector strafeeff_color = StrafeHUD_MixColors('1 1 1', (strafe_ratio > 0 ? '0 1 0' : '1 0 0'), fabs(strafe_ratio));

	StrafeHUD_DrawTextIndicator(
		strafeeff_text, strafeeff_height,
		strafeeff_color, 1,
		time, autocvar_hud_panel_strafehud_strafeefficiency_pos,
		text_offset_top, text_offset_bottom);
}

// show speed when crossing the start trigger
// FIXME: move capturing the race start speed value out of the HUD
void StrafeHUD_DrawStartSpeed(float speed, float text_offset_top, float text_offset_bottom)
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

	if(!autocvar_hud_panel_strafehud_startspeed) return;

	float speed_conversion_factor = GetSpeedUnitFactor(autocvar_hud_speed_unit);
	float startspeed_height = autocvar_hud_panel_strafehud_startspeed_size * panel_size.y;
	string startspeed_text = ftos_decimals(startspeed * speed_conversion_factor, 2);
	if(autocvar_hud_panel_strafehud_unit_show)
		startspeed_text = strcat(startspeed_text, GetSpeedUnit(autocvar_hud_speed_unit));

	StrafeHUD_DrawTextIndicator(
		startspeed_text, startspeed_height,
		autocvar_hud_panel_strafehud_startspeed_color,
		autocvar_hud_panel_strafehud_startspeed_fade,
		starttime, autocvar_hud_panel_strafehud_startspeed_pos,
		text_offset_top, text_offset_bottom);
}

// strafe sonar for audible feedback when strafing
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

// update and precache the sonar sound and store the proper sound path
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
