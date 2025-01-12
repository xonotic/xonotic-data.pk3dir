#include "draw_core.qh"

#include <client/draw.qh>

void StrafeHUD_DrawStrafeMeter(
	float shiftangle, float wishangle, float absolute_bestangle,
	float absolute_prebestangle, float absolute_overturnangle,
	bool moving, float hudangle)
{
	// the neutral zone fills the whole strafe bar
	if(!moving)
	{
		// draw neutral zone
		if(panel_size.x > 0 && panel_size.y > 0 && autocvar_hud_panel_strafehud_bar_neutral_alpha > 0)
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
		float accelzone_left_startangle;
		float accelzone_right_startangle;
		float preaccelzone_left_startangle;
		float preaccelzone_right_startangle;
		float neutral_startangle;
		float overturn_startangle;

		float accelzone_offsetangle = absolute_overturnangle - absolute_bestangle;
		float preaccelzone_offsetangle = fabs(absolute_bestangle - absolute_prebestangle);
		float neutral_offsetangle = 360;
		float overturn_offsetangle = 360 - absolute_overturnangle * 2;

		if(!autocvar_hud_panel_strafehud_bar_preaccel)
			preaccelzone_offsetangle = 0;

		// assign starting angles and shift the current offset for every element
		float current_startangle = 0;

		preaccelzone_right_startangle = current_startangle;
		current_startangle += preaccelzone_offsetangle;

		accelzone_right_startangle = current_startangle;
		current_startangle += accelzone_offsetangle;

		overturn_startangle = current_startangle;
		current_startangle += overturn_offsetangle;

		accelzone_left_startangle = current_startangle;
		current_startangle += accelzone_offsetangle;

		preaccelzone_left_startangle = current_startangle;
		current_startangle += preaccelzone_offsetangle;

		neutral_startangle = current_startangle;
		neutral_offsetangle = 360 - current_startangle;

		// calculate how far off-center the strafe zones currently are
		shiftangle += neutral_offsetangle / 2 - wishangle;

		// shift strafe zones into correct place
		neutral_startangle += shiftangle;
		accelzone_left_startangle += shiftangle;
		accelzone_right_startangle += shiftangle;
		preaccelzone_left_startangle += shiftangle;
		preaccelzone_right_startangle += shiftangle;
		overturn_startangle += shiftangle;

		// draw left acceleration zone
		if(accelzone_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				accelzone_left_startangle, accelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_accel_color,
				autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT,
				hudangle);

		if(autocvar_hud_panel_strafehud_bar_preaccel && preaccelzone_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				preaccelzone_left_startangle, preaccelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_preaccel_color,
				autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT,
				hudangle);

		// draw right acceleration zone
		if(accelzone_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				accelzone_right_startangle, accelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_accel_color,
				autocvar_hud_panel_strafehud_bar_accel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_RIGHT,
				hudangle);

		if(autocvar_hud_panel_strafehud_bar_preaccel && preaccelzone_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				preaccelzone_right_startangle, preaccelzone_offsetangle,
				autocvar_hud_panel_strafehud_bar_preaccel_color,
				autocvar_hud_panel_strafehud_bar_preaccel_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_LEFT,
				hudangle);

		// draw overturn zone
		if(overturn_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				overturn_startangle, overturn_offsetangle,
				autocvar_hud_panel_strafehud_bar_overturn_color,
				autocvar_hud_panel_strafehud_bar_overturn_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_BOTH,
				hudangle);

		// draw neutral zone
		if(neutral_offsetangle > 0)
			StrafeHUD_DrawStrafeHUD(
				neutral_startangle, neutral_offsetangle,
				autocvar_hud_panel_strafehud_bar_neutral_color,
				autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha,
				autocvar_hud_panel_strafehud_style, STRAFEHUD_GRADIENT_NONE,
				hudangle);
	}
}

// draw the actual strafe angle indicator
void StrafeHUD_DrawAngleIndicator(
	float angle, vector line_size, float arrow_size, int num_dashes,
	bool has_top_arrow, bool has_bottom_arrow, vector color, float alpha, float hudangle)
{
	if(alpha <= 0) return;

	// bound to HUD area
	angle = bound(-hudangle / 2, angle, hudangle / 2);

	float offset = StrafeHUD_AngleToOffset(angle, hudangle);
	offset = StrafeHUD_ProjectOffset(offset, hudangle, false);

	StrafeHUD_DrawAngleIndicatorLine(line_size, offset, num_dashes, color, alpha);

	if(has_top_arrow)
		StrafeHUD_DrawAngleIndicatorArrow(arrow_size, offset, line_size, color, alpha, true);

	if(has_bottom_arrow)
		StrafeHUD_DrawAngleIndicatorArrow(arrow_size, offset, line_size, color, alpha, false);
}

// draw the line of the angle indicator
void StrafeHUD_DrawAngleIndicatorLine(vector size, float offset, int num_dashes, vector color, float alpha)
{
	if(num_dashes <= 0 || size.x <= 0 || size.y <= 0) return;

	vector segment_size = size;
	segment_size.y = size.y / (bound(1, num_dashes, size.y) * 2 - 1);

	for(float i = 0; i < size.y; i += segment_size.y * 2)
	{
		// check if last iteration
		if(i + segment_size.y * 2 >= size.y)
			segment_size.y = size.y - i;

		drawfill(
			panel_pos - eY * ((size.y - panel_size.y) / 2 - i) + eX * (offset - segment_size.x / 2),
			segment_size, color, alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}

// draw the arrows on the angle indicator
void StrafeHUD_DrawAngleIndicatorArrow(float size, float offset, vector line_size, vector color, float alpha, bool top)
{
	if(size <= 0) return;

	if(top)
	{
		StrafeHUD_DrawStrafeArrow(
			panel_pos + eY * ((panel_size.y - line_size.y) / 2) + eX * offset,
			size, color, alpha * panel_fg_alpha, true, line_size.x);
	}
	else
	{
		StrafeHUD_DrawStrafeArrow(
			panel_pos + eY * ((panel_size.y - line_size.y) / 2 + line_size.y) + eX * offset,
			size, color, alpha * panel_fg_alpha, false, line_size.x);
	}
}

// direction indicator
void StrafeHUD_DrawDirectionIndicator(int direction, bool opposite_direction, bool fwd)
{
	vector direction_size_vertical;
	direction_size_vertical.x = max(panel_size.y * min(autocvar_hud_panel_strafehud_direction_width, 1), 1);
	direction_size_vertical.y = panel_size.y + direction_size_vertical.x * 2;
	direction_size_vertical.z = 0;

	vector direction_size_horizontal;
	direction_size_horizontal.x = panel_size.x * min(autocvar_hud_panel_strafehud_direction_length, .5);
	direction_size_horizontal.y = direction_size_vertical.x;
	direction_size_horizontal.z = 0;

	if(direction != STRAFEHUD_DIRECTION_NONE &&
	   direction_size_vertical.x > 0 &&
	   autocvar_hud_panel_strafehud_direction_alpha > 0)
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
