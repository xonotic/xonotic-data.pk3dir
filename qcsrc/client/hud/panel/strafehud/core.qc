#include "core.qh"

#include <client/draw.qh>

void StrafeHUD_DrawStrafeMeter(
	float speed, float minspeed, float shift_angle, float wishangle,
	float currentangle, float changeangle, float bestangle, float bestangle_width,
	float absolute_bestangle, float absolute_prebestangle,
	float opposite_bestangle, float opposite_changeangle,
	bool immobile, bool opposite_direction, int direction, float hudangle)
{
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
		float accelzone_left_startangle;
		float accelzone_right_startangle;
		float accelzone_offsetangle;
		float preaccelzone_left_startangle;
		float preaccelzone_right_startangle;
		float preaccelzone_offsetangle;
		float overturn_startangle;

		// calculate various zones of the strafe-o-meter
		if(autocvar_hud_panel_strafehud_bar_preaccel)
			preaccelzone_offsetangle = absolute_bestangle - absolute_prebestangle;
		else
			preaccelzone_offsetangle = 0;

		accelzone_offsetangle = 90 - absolute_bestangle;

		float neutral_startangle;
		float neutral_endangle = 180 - accelzone_offsetangle * 2 - preaccelzone_offsetangle * 2;

		{
			float current_offsetangle = 0;
			preaccelzone_right_startangle = current_offsetangle;
			current_offsetangle += preaccelzone_offsetangle;

			accelzone_right_startangle = current_offsetangle;
			current_offsetangle += accelzone_offsetangle;

			overturn_startangle = current_offsetangle;
			current_offsetangle += 180; // overturning area spans 180°

			accelzone_left_startangle = current_offsetangle;
			current_offsetangle += accelzone_offsetangle;

			preaccelzone_left_startangle = current_offsetangle;
			current_offsetangle += preaccelzone_offsetangle;

			neutral_startangle = current_offsetangle;
		}

		// calculate how far off-center the strafe zones currently are
		shift_angle += neutral_endangle / 2 - wishangle;

		// shift strafe zones into correct place
		neutral_startangle += shift_angle;
		accelzone_left_startangle += shift_angle;
		accelzone_right_startangle += shift_angle;
		preaccelzone_left_startangle += shift_angle;
		preaccelzone_right_startangle += shift_angle;
		overturn_startangle += shift_angle;

		// draw left acceleration zone
		HUD_Panel_drawStrafeHUD(
			accelzone_left_startangle, accelzone_offsetangle,
			autocvar_hud_panel_strafehud_bar_accel_color,
			autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
			autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT,
			true, hudangle);

		if(autocvar_hud_panel_strafehud_bar_preaccel)
			HUD_Panel_drawStrafeHUD(
				preaccelzone_left_startangle, preaccelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_accel_color,
				autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT,
				true, hudangle);

		// draw right acceleration zone
		HUD_Panel_drawStrafeHUD(
			accelzone_right_startangle, accelzone_offsetangle,
			autocvar_hud_panel_strafehud_bar_accel_color,
			autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
			autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT,
			true, hudangle);

		if(autocvar_hud_panel_strafehud_bar_preaccel)
			HUD_Panel_drawStrafeHUD(
				preaccelzone_right_startangle, preaccelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_accel_color,
				autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT,
				true, hudangle);

		// draw overturn zone
		//   this is technically incorrect
		//   acceleration decreases at 90 degrees but speed loss happens a little bit after 90 degrees,
		//   however due to sv_airstopaccelerate that's hard to calculate
		HUD_Panel_drawStrafeHUD(
			overturn_startangle, 180, // overturning area spans 180°
			autocvar_hud_panel_strafehud_bar_overturn_color,
			autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha,
			autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_BOTH,
			true, hudangle);

		// draw neutral zone
		HUD_Panel_drawStrafeHUD(
			neutral_startangle, neutral_endangle,
			autocvar_hud_panel_strafehud_bar_neutral_color,
			autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha,
			autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_NONE,
			true, hudangle);

		// only draw indicators if minspeed is reached
		if(autocvar_hud_panel_strafehud_switch && speed >= minspeed && bestangle_width > 0 && autocvar_hud_panel_strafehud_switch_alpha > 0)
		{
			// draw the change indicator(s)
			float offsetangle = !opposite_direction ? changeangle : opposite_changeangle;
			float opposite_offsetangle = !opposite_direction ? bestangle : opposite_bestangle;

			offsetangle = StrafeHUD_projectAngle(offsetangle, hudangle, false);
			opposite_offsetangle = StrafeHUD_projectAngle(opposite_offsetangle, hudangle, false);

			// remove change indicator width from offset
			if(direction == STRAFEHUD_DIRECTION_LEFT)
			{
				if(!opposite_direction)
					opposite_offsetangle -= StrafeHUD_offsetToAngle(bestangle_width, hudangle);
				else
					offsetangle -= StrafeHUD_offsetToAngle(bestangle_width, hudangle);
			}
			else
			{
				if(!opposite_direction)
					offsetangle -= StrafeHUD_offsetToAngle(bestangle_width, hudangle);
				else
					opposite_offsetangle -= StrafeHUD_offsetToAngle(bestangle_width, hudangle);
			}

			HUD_Panel_drawStrafeHUD(
				offsetangle, StrafeHUD_offsetToAngle(bestangle_width, hudangle),
				autocvar_hud_panel_strafehud_switch_color,
				autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha,
				STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE,
				false, hudangle);

			if(direction == STRAFEHUD_DIRECTION_NONE)
				HUD_Panel_drawStrafeHUD(
					opposite_offsetangle, StrafeHUD_offsetToAngle(bestangle_width, hudangle),
					autocvar_hud_panel_strafehud_switch_color,
					autocvar_hud_panel_strafehud_switch_alpha * panel_fg_alpha,
					STRAFEHUD_STYLE_DRAWFILL, STRAFEHUD_GRADIENT_NONE,
					false, hudangle);
		}
	}
}

// draw the actual strafe angle
vector StrafeHUD_DrawAngleIndicator(float angle, float wishangle, float currentangle,
	float bestangle, float absolute_bestangle, float absolute_prebestangle,
	float opposite_bestangle, bool immobile, bool opposite_direction, int direction,
	float hudangle)
{
	vector currentangle_color = autocvar_hud_panel_strafehud_angle_neutral_color;
	float strafe_ratio = 0;
	if(!immobile)
	{
		float moveangle = fabs(angle + wishangle);

		// player is overturning
		if(moveangle >= 90)
		{
			currentangle_color = autocvar_hud_panel_strafehud_angle_overturn_color;
			strafe_ratio = (moveangle - 90) / 90;
			if(strafe_ratio > 1) strafe_ratio = 2 - strafe_ratio;
			strafe_ratio *= -1;
		}
		// player gains speed by strafing
		else if(moveangle >= absolute_bestangle)
		{
			currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
			strafe_ratio = (90 - moveangle) / (90 - absolute_bestangle);
		}
		else if(moveangle >= absolute_prebestangle)
		{
			if(autocvar_hud_panel_strafehud_bar_preaccel)
				currentangle_color = autocvar_hud_panel_strafehud_angle_accel_color;
			strafe_ratio = (moveangle - absolute_prebestangle) / (absolute_bestangle - absolute_prebestangle);
		}

		if(autocvar_hud_panel_strafehud_style == STRAFEHUD_STYLE_GRADIENT)
			currentangle_color = StrafeHUD_mixColors(autocvar_hud_panel_strafehud_angle_neutral_color, currentangle_color, fabs(strafe_ratio));
	}

	// current angle size calculation
	vector currentangle_size;
	currentangle_size.x = max(panel_size.x * min(autocvar_hud_panel_strafehud_angle_width, 10), 1);
	currentangle_size.y = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_height, 10), 1);
	currentangle_size.z = 0;

	float angleheight_offset = currentangle_size.y;
	float ghost_angle = 0;
	if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
		ghost_angle = bound(-hudangle / 2, (opposite_direction ? opposite_bestangle : bestangle), hudangle / 2);

	ghost_angle = StrafeHUD_projectAngle(ghost_angle, hudangle, false);

	switch(autocvar_hud_panel_strafehud_angle_style)
	{
		case STRAFEHUD_INDICATOR_SOLID:
			if(currentangle_size.x > 0 && currentangle_size.y > 0)
			{
				if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
					drawfill(
						panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (StrafeHUD_angleToOffset(ghost_angle, hudangle) - currentangle_size.x / 2),
						currentangle_size, autocvar_hud_panel_strafehud_bestangle_color,
						autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha,
						DRAWFLAG_NORMAL);
				drawfill(
					panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2) + eX * (StrafeHUD_angleToOffset(currentangle, hudangle) - currentangle_size.x / 2),
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
					if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
						drawfill(
							panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (StrafeHUD_angleToOffset(ghost_angle, hudangle) - line_size.x / 2),
							line_size, autocvar_hud_panel_strafehud_bestangle_color,
							autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
					drawfill(
						panel_pos - eY * ((currentangle_size.y - panel_size.y) / 2 - i) + eX * (StrafeHUD_angleToOffset(currentangle, hudangle) - line_size.x / 2),
						line_size, currentangle_color,
						autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
			}
			break;
		case STRAFEHUD_INDICATOR_NONE:
		default:
			// do not offset text and arrows if the angle indicator line is not drawn
			angleheight_offset = panel_size.y;
			currentangle_size = '0 0 0';
	}

	vector angle_indicator_info = StrafeHUD_DrawAngleIndicatorArrow(
		currentangle, currentangle_size, currentangle_color, ghost_angle,
		angleheight_offset, direction, hudangle);

	// return infomration about the angle indicator packed into a vector
	angle_indicator_info.x = strafe_ratio;
	return angle_indicator_info;
}

// draw the arrows on the angle indicator
vector StrafeHUD_DrawAngleIndicatorArrow(float currentangle, vector currentangle_size,
	vector currentangle_color, float ghost_angle, float angleheight_offset,
	int direction, float hudangle)
{
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
		// there's only one size cvar for the arrows, they will always have a 45° angle to ensure proper rendering without antialiasing
		float arrow_size = max(panel_size.y * min(autocvar_hud_panel_strafehud_angle_arrow_size, 10), 1);

		if(arrow_size > 0)
		{
			if(autocvar_hud_panel_strafehud_angle_arrow == 1 || autocvar_hud_panel_strafehud_angle_arrow >= 3)
			{
				if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
					StrafeHUD_drawStrafeArrow(
						panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * StrafeHUD_angleToOffset(ghost_angle, hudangle),
						arrow_size, autocvar_hud_panel_strafehud_bestangle_color,
						autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, true, currentangle_size.x);
				StrafeHUD_drawStrafeArrow(
					panel_pos + eY * ((panel_size.y - angleheight_offset) / 2) + eX * StrafeHUD_angleToOffset(currentangle, hudangle),
					arrow_size, currentangle_color,
					autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, true, currentangle_size.x);

				angle_offset_top += arrow_size; // further offset the top text offset if the top arrow is drawn
			}
			if(autocvar_hud_panel_strafehud_angle_arrow >= 2)
			{
				if(autocvar_hud_panel_strafehud_bestangle && direction != STRAFEHUD_DIRECTION_NONE)
					StrafeHUD_drawStrafeArrow(
						panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * StrafeHUD_angleToOffset(ghost_angle, hudangle),
						arrow_size, autocvar_hud_panel_strafehud_bestangle_color,
						autocvar_hud_panel_strafehud_bestangle_alpha * panel_fg_alpha, false, currentangle_size.x);
				StrafeHUD_drawStrafeArrow(
					panel_pos + eY * ((panel_size.y - angleheight_offset) / 2 + angleheight_offset) + eX * StrafeHUD_angleToOffset(currentangle, hudangle),
					arrow_size, currentangle_color,
					autocvar_hud_panel_strafehud_angle_alpha * panel_fg_alpha, false, currentangle_size.x);

				angle_offset_bottom += arrow_size; // further offset the bottom text offset if the bottom arrow is drawn
			}
		}
	}

	// return top and bottom angle offsets packed into a vector
	vector angle_offsets = '0 0 0';
	angle_offsets.y = angle_offset_top;
	angle_offsets.z = angle_offset_bottom;
	return angle_offsets;
}

// direction indicator
void StrafeHUD_DrawDirectionIndicator(int direction, bool opposite_direction, bool fwd)
{
	vector direction_size_vertical;
	direction_size_vertical.x = autocvar_hud_panel_strafehud_direction_width;
	direction_size_vertical.x = max(panel_size.y * min(direction_size_vertical.x, 1), 1);
	direction_size_vertical.y = panel_size.y + direction_size_vertical.x * 2;
	direction_size_vertical.z = 0;

	vector direction_size_horizontal;
	direction_size_horizontal.x = panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5);
	direction_size_horizontal.y = direction_size_vertical.x;
	direction_size_horizontal.z = 0;

	if(autocvar_hud_panel_strafehud_direction &&
	   direction != STRAFEHUD_DIRECTION_NONE &&
	   direction_size_vertical.x > 0 &&
	   autocvar_hud_panel_strafehud_direction_alpha * panel_fg_alpha > 0)
	{
		bool indicator_direction = direction == STRAFEHUD_DIRECTION_LEFT;
		// invert left/right when strafing backwards or when strafing towards the opposite side indicated by the direction variable
		// if both conditions are true then it's inverted twice hence not inverted at all
		if(!fwd != opposite_direction)
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
}
