#include "draw.qh"

#include <client/draw.qh>

// draw the strafe-o-meter bar
// aligns HUD elements perfectly in the hud area
// also deals with wrapping around on edges, different HUD styles, etc.
void StrafeHUD_DrawStrafeHUD(float startangle, float offsetangle, vector color, float alpha, int type, int gradient_type, float range)
{
	float offset = StrafeHUD_AngleToOffset(startangle % 360, range);
	float width = StrafeHUD_AngleToWidth(offsetangle, range);
	float mirror_offset;
	float mirror_width;

	if(width <= 0) return;

	if(StrafeHUD_IsGradient(type))
	{
		if(gradient_type == STRAFEHUD_GRADIENT_NONE)
		{
			type = STRAFEHUD_STYLE_DRAWFILL;
			if(alpha <= 0) return;
		}
	}
	else if(alpha <= 0) return;

	// how much is hidden by the current hud angle
	float hidden_width = (360 - range) / range * panel_size.x;
	float total_width = panel_size.x + hidden_width;
	float original_width = width; // required for gradient

	if(offset < 0)
	{
		mirror_width = min(fabs(offset), width);
		mirror_offset = offset + total_width;
		width += offset;
		offset = 0;
	}
	else
	{
		mirror_offset = offset - total_width;
		mirror_width = min(mirror_offset + width, width);
		if(mirror_offset < 0) mirror_offset = 0;
	}

	float overflow_width = offset + width - panel_size.x;
	width = max(width, 0);
	if(overflow_width > 0)
		width = panel_size.x - offset;
	else
		overflow_width = 0;

	vector size = panel_size;
	size.x = width;

	float original_offset = offset;

	// the accelerated gradient does the projection later
	if(type != STRAFEHUD_STYLE_GRADIENT)
	{
		if(size.x > 0)
			size.x = StrafeHUD_ProjectWidth(offset, size.x, range);

		offset = StrafeHUD_ProjectOffset(offset, range, false);
	}

	if(mirror_offset < 0)
	{
		mirror_width += mirror_offset;
		mirror_offset = 0;
	}

	float overflow_mirror_width = mirror_offset + mirror_width - panel_size.x;
	mirror_width = max(mirror_width, 0);
	if(overflow_mirror_width > 0)
		mirror_width = panel_size.x - mirror_offset;
	else
		overflow_mirror_width = 0;

	vector mirror_size = panel_size;
	mirror_size.x = mirror_width;

	float original_mirror_offset = mirror_offset;

	// the accelerated gradient does the projection later
	if(type != STRAFEHUD_STYLE_GRADIENT)
	{
		if(mirror_size.x > 0)
			mirror_size.x = StrafeHUD_ProjectWidth(mirror_offset, mirror_size.x, range);

		mirror_offset = StrafeHUD_ProjectOffset(mirror_offset, range, false);
	}

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
		case STRAFEHUD_STYLE_SOFT_GRADIENT:
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

			if(type == STRAFEHUD_STYLE_GRADIENT)
			{
				if(mirror_size.x > 0)
					StrafeHUD_DrawGradient(
						color, autocvar_hud_panel_strafehud_bar_neutral_color,
						mirror_size, original_width, mirror_offset, alpha,
						gradient_mirror_offset, gradient_type, range);

				if(size.x > 0)
					StrafeHUD_DrawGradient(
						color, autocvar_hud_panel_strafehud_bar_neutral_color,
						size, original_width, offset, alpha,
						gradient_offset, gradient_type, range);
			}
			else
			{
				if(mirror_size.x > 0)
					StrafeHUD_DrawSoftGradient(
						color, autocvar_hud_panel_strafehud_bar_neutral_color,
						mirror_size, original_width, mirror_offset, original_mirror_offset,
						alpha, gradient_mirror_offset, gradient_type, range);

				if(size.x > 0)
					StrafeHUD_DrawSoftGradient(
						color, autocvar_hud_panel_strafehud_bar_neutral_color,
						size, original_width, offset, original_offset,
						alpha, gradient_offset, gradient_type, range);
			}
	}
}

// accelerated gradient, does not support non-linear projection of the color and opacity within individual segments
void StrafeHUD_DrawGradient(
	vector color1, vector color2, vector size, float original_width,
	float offset, float alpha, float gradient_offset, int gradient_type, float range)
{
	if(gradient_type == STRAFEHUD_GRADIENT_BOTH)
	{
		original_width /= 2;

		vector size1 = size;
		size1.x = bound(0, original_width - gradient_offset, size.x);

		vector size2 = size;
		size2.x = size.x - size1.x;

		if(size1.x > 0)
			StrafeHUD_DrawGradient(color1, color2, size1, original_width, offset, alpha, gradient_offset, STRAFEHUD_GRADIENT_LEFT, range);

		if(size2.x > 0)
			StrafeHUD_DrawGradient(color1, color2, size2, original_width, offset + size1.x, alpha, max(0, gradient_offset - original_width), STRAFEHUD_GRADIENT_RIGHT, range);

		return;
	}

	vector gradient_start = eX * offset;
	float gradient_width = StrafeHUD_ProjectWidth(gradient_start.x, size.x, range);
	gradient_start.x = StrafeHUD_ProjectOffset(gradient_start.x, range, false);
	vector gradient_end = gradient_start + eX * gradient_width;
	vector gradient_height = eY * size.y;

	float alpha1 = bound(0, alpha, 1);
	float alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, 1);
	if(alpha1 + alpha2 == 0) return;

	float ratio1 = gradient_offset / original_width;
	float ratio2 = (gradient_offset + size.x) / original_width;
	if(gradient_type == STRAFEHUD_GRADIENT_LEFT)
	{
		ratio1 = 1 - ratio1;
		ratio2 = 1 - ratio2;
	}

	vector origin = HUD_Shift(panel_pos);
	gradient_start.x = HUD_ScaleX(gradient_start.x);
	gradient_end.x = HUD_ScaleX(gradient_end.x);
	gradient_height.y = HUD_ScaleY(gradient_height.y);

	R_BeginPolygon("", DRAWFLAG_NORMAL, true);
	R_PolygonVertex(origin + gradient_start,                   '0 0 0', color1, alpha1 * (1 - ratio1));
	R_PolygonVertex(origin + gradient_start + gradient_height, '0 0 0', color1, alpha1 * (1 - ratio1));
	R_PolygonVertex(origin + gradient_end   + gradient_height, '0 0 0', color1, alpha1 * (1 - ratio2));
	R_PolygonVertex(origin + gradient_end,                     '0 0 0', color1, alpha1 * (1 - ratio2));
	R_EndPolygon();

	R_BeginPolygon("", DRAWFLAG_NORMAL, true);
	R_PolygonVertex(origin + gradient_start,                   '0 0 0', color2, alpha2 * ratio1);
	R_PolygonVertex(origin + gradient_start + gradient_height, '0 0 0', color2, alpha2 * ratio1);
	R_PolygonVertex(origin + gradient_end   + gradient_height, '0 0 0', color2, alpha2 * ratio2);
	R_PolygonVertex(origin + gradient_end,                     '0 0 0', color2, alpha2 * ratio2);
	R_EndPolygon();
}

// more expensive gradient rendering which does not rely on vertex gradients (required to properly render the color/opacity of individual segments in non-linear projection modes)
void StrafeHUD_DrawSoftGradient(
	vector color1, vector color2, vector size, float original_width, float offset, float original_offset,
	float alpha, float gradient_offset, int gradient_type, float range)
{
	float alpha1 = bound(0, alpha, 1);
	float alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, 1);
	if(alpha1 + alpha2 == 0) return;

	float color_ratio = alpha1 / (alpha1 + alpha2);
	vector segment_size = size;
	for(int i = 0; i < size.x; ++i)
	{
		segment_size.x = min(size.x - i, 1); // each gradient segment is 1 unit wide except if there is less than 1 unit of gradient remaining
		float segment_offset = offset + i;
		float ratio_offset = segment_offset + segment_size.x / 2;
		ratio_offset = StrafeHUD_ProjectOffset(ratio_offset, range, true);
		ratio_offset += gradient_offset;
		float ratio = (ratio_offset - original_offset) / original_width * (gradient_type == STRAFEHUD_GRADIENT_BOTH ? 2 : 1);
		if(ratio > 1) ratio = 2 - ratio;
		if(gradient_type != STRAFEHUD_GRADIENT_RIGHT) ratio = 1 - ratio;
		float alpha_ratio = alpha1 - (alpha1 - alpha2) * ratio;
		float combine_ratio1 = ratio * (1 - color_ratio);
		float combine_ratio2 = (1 - ratio) * color_ratio;
		ratio = (combine_ratio1 + combine_ratio2) == 0 ? 1 : combine_ratio1 / (combine_ratio1 + combine_ratio2);

		if(alpha_ratio > 0)
			drawfill(
				panel_pos + eX * segment_offset,
				segment_size,
				StrafeHUD_MixColors(color1, color2, ratio),
				alpha_ratio,
				DRAWFLAG_NORMAL);
	}
}

// draw the strafe arrows (inspired by drawspritearrow() in common/mutators/mutator/waypoints/waypointsprites.qc)
void StrafeHUD_DrawStrafeArrow(vector origin, float size, vector color, float alpha, bool flipped, float connection_width)
{
	// alpha and size already checked

	origin = HUD_Shift(origin);
	float width  = HUD_ScaleX(size * 2 + connection_width);
	float height = HUD_ScaleY(size);
	if(flipped) origin.y -= size;
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

// draw a fading text indicator above or below the strafe meter
void StrafeHUD_DrawTextIndicator(
	string text, float height, vector color, float fadetime, float lasttime,
	vector pos, float offset_top, float offset_bottom)
{
	float time_frac = (time - lasttime) / fadetime;
	if(height <= 0 || lasttime <= 0 || fadetime <= 0 || time_frac > 1)
		return;

	float alpha = cos(time_frac * M_PI_2); // fade non-linear like the physics panel does
	vector size = panel_size;
	size.y = height;

	if(pos.y >= 1)
	{
		--pos.y; // for calculations the position should not start at +1
		pos = StrafeHUD_CalculateTextIndicatorPosition(pos);
		pos.y += size.y + offset_top;
		pos.y *= -1; // it's more intuitive for up to be positive
	}
	else if(pos.y <= -1)
	{
		++pos.y; // for calculations the position should not start at -1
		pos = StrafeHUD_CalculateTextIndicatorPosition(pos);
		pos.y *= -1; // it's more intuitive for down to be negative
		pos.y += panel_size.y + offset_bottom;
	}
	else return;

	drawstring_aspect(panel_pos + pos, text, size, color, alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
}

// checks whether the current style is a gradient style
bool StrafeHUD_IsGradient(int style)
{
	return style == STRAFEHUD_STYLE_GRADIENT || style == STRAFEHUD_STYLE_SOFT_GRADIENT;
}
