#include "draw.qh"

#include <client/draw.qh>

// functions to make hud elements align perfectly in the hud area
void StrafeHUD_DrawStrafeHUD(float startangle, float offsetangle, vector color, float alpha, int type, int gradientType, bool projectWidth, float range)
{
	float offset = StrafeHUD_AngleToOffset(startangle % 360, range);
	float width = StrafeHUD_AngleToWidth(offsetangle, range);
	float mirror_offset;
	float mirror_width;

	if(type == STRAFEHUD_STYLE_GRADIENT || type == STRAFEHUD_STYLE_FAST_GRADIENT)
	{
		projectWidth = true; // must be fully projected for gradients
		if(gradientType == STRAFEHUD_GRADIENT_NONE)
			type = STRAFEHUD_STYLE_DRAWFILL;
	}

	if(alpha <= 0 && type != STRAFEHUD_STYLE_GRADIENT && type != STRAFEHUD_STYLE_FAST_GRADIENT || width <= 0)
		return;

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
	if(projectWidth && size.x > 0)
		size.x = StrafeHUD_ProjectWidth(offset, size.x, range);

	offset = StrafeHUD_ProjectOffset(offset, range, false);

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
	if(projectWidth && mirror_size.x > 0)
		mirror_size.x = StrafeHUD_ProjectWidth(mirror_offset, mirror_size.x, range);

	mirror_offset = StrafeHUD_ProjectOffset(mirror_offset, range, false);

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
		case STRAFEHUD_STYLE_FAST_GRADIENT:
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

			if(type == STRAFEHUD_STYLE_FAST_GRADIENT && autocvar_hud_panel_strafehud_projection == STRAFEHUD_PROJECTION_LINEAR)
			{
				StrafeHUD_DrawGradientFast(
					color, autocvar_hud_panel_strafehud_bar_neutral_color,
					mirror_size, original_width, mirror_offset, alpha,
					gradient_mirror_offset, gradientType);

				StrafeHUD_DrawGradientFast(
					color, autocvar_hud_panel_strafehud_bar_neutral_color,
					size, original_width, offset, alpha,
					gradient_offset, gradientType);
			}
			else
			{
				StrafeHUD_DrawGradient(
					color, autocvar_hud_panel_strafehud_bar_neutral_color,
					mirror_size, original_width, mirror_offset, original_mirror_offset,
					alpha, gradient_mirror_offset, gradientType, range);

				StrafeHUD_DrawGradient(
					color, autocvar_hud_panel_strafehud_bar_neutral_color,
					size, original_width, offset, original_offset,
					alpha, gradient_offset, gradientType, range);
			}
	}
}

// slow gradient, required for projection modes other than linear
void StrafeHUD_DrawGradient(vector color1, vector color2, vector size, float original_width, float offset, float original_offset, float alpha, float gradientOffset, int gradientType, float range)
{
	if(size.x <= 0) return;

	float color_ratio, alpha1, alpha2;
	vector segment_size = size;
	alpha1 = bound(0, alpha, 1);
	alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, 1);
	if((alpha1 + alpha2) == 0) return;
	color_ratio = alpha1 / (alpha1 + alpha2);
	for(int i = 0; i < size.x; ++i)
	{
		float ratio, ratio_offset, alpha_ratio, combine_ratio1, combine_ratio2, segment_offset;
		segment_size.x = min(size.x - i, 1); // each gradient segment is 1 unit wide except if there is less than 1 unit of gradient remaining
		segment_offset = offset + i;
		ratio_offset = segment_offset + segment_size.x / 2;
		ratio_offset = StrafeHUD_ProjectOffset(ratio_offset, range, true);
		ratio_offset += gradientOffset;
		ratio = (ratio_offset - original_offset) / original_width * (gradientType == STRAFEHUD_GRADIENT_BOTH ? 2 : 1);
		if(ratio > 1) ratio = 2 - ratio;
		if(gradientType != STRAFEHUD_GRADIENT_RIGHT) ratio = 1 - ratio;
		alpha_ratio = alpha1 - (alpha1 - alpha2) * ratio;
		combine_ratio1 = ratio * (1 - color_ratio);
		combine_ratio2 = (1 - ratio) * color_ratio;
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

// optimized gradient, does not work with projection modes other than linear, decreased visual fidelity
void StrafeHUD_DrawGradientFast(vector color1, vector color2, vector size, float original_width, float offset, float alpha, float gradientOffset, int gradientType)
{
	if(size.x <= 0) return;

	if(gradientType == STRAFEHUD_GRADIENT_BOTH)
	{
		original_width /= 2;

		vector size1 = size;
		size1.x = bound(0, original_width - gradientOffset, size.x);

		vector size2 = size;
		size2.x = size.x - size1.x;

		if(size1.x > 0)
			StrafeHUD_DrawGradientFast(color1, color2, size1, original_width, offset, alpha, gradientOffset, STRAFEHUD_GRADIENT_LEFT);

		if(size2.x > 0)
			StrafeHUD_DrawGradientFast(color1, color2, size2, original_width, offset + size1.x, alpha, max(0, gradientOffset - original_width), STRAFEHUD_GRADIENT_RIGHT);

		return;
	}

	float alpha1 = bound(0, alpha, 1);
	float alpha2 = bound(0, autocvar_hud_panel_strafehud_bar_neutral_alpha * panel_fg_alpha, 1);
	if((alpha1 + alpha2) == 0) return;

	float ratio1 = gradientOffset / original_width;
	if(gradientType == STRAFEHUD_GRADIENT_LEFT)
		ratio1 = 1 - ratio1;

	float ratio2 = (gradientOffset + size.x) / original_width;
	if(gradientType == STRAFEHUD_GRADIENT_LEFT)
		ratio2 = 1 - ratio2;

	vector origin = HUD_Shift(panel_pos);
	offset = HUD_ScaleX(offset);
	size = HUD_Scale(size);

	R_BeginPolygon("", DRAWFLAG_NORMAL, true);
	R_PolygonVertex(origin + eX *  offset,                         '0 0 0', color1, alpha1 * (1 - ratio1));
	R_PolygonVertex(origin + eX *  offset           + eY * size.y, '0 0 0', color1, alpha1 * (1 - ratio1));
	R_PolygonVertex(origin + eX * (offset + size.x) + eY * size.y, '0 0 0', color1, alpha1 * (1 - ratio2));
	R_PolygonVertex(origin + eX * (offset + size.x),               '0 0 0', color1, alpha1 * (1 - ratio2));
	R_EndPolygon();

	R_BeginPolygon("", DRAWFLAG_NORMAL, true);
	R_PolygonVertex(origin + eX *  offset,                         '0 0 0', color2, alpha2 * ratio1);
	R_PolygonVertex(origin + eX *  offset           + eY * size.y, '0 0 0', color2, alpha2 * ratio1);
	R_PolygonVertex(origin + eX * (offset + size.x) + eY * size.y, '0 0 0', color2, alpha2 * ratio2);
	R_PolygonVertex(origin + eX * (offset + size.x),               '0 0 0', color2, alpha2 * ratio2);
	R_EndPolygon();
}

// draw the strafe arrows (inspired by drawspritearrow() in common/mutators/mutator/waypoints/waypointsprites.qc)
void StrafeHUD_DrawStrafeArrow(vector origin, float size, vector color, float alpha, bool flipped, float connection_width)
{
	origin = HUD_Shift(origin);
	float width = HUD_ScaleX(size * 2 + connection_width);
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

// draw a fading text indicator above or below the strafe meter, return true if something was displayed
bool StrafeHUD_DrawTextIndicator(string text, float height, vector color, float fadetime, float lasttime, float offset, int position)
{
	if((height <= 0) || (lasttime <= 0) || (fadetime <= 0) || ((time - lasttime) >= fadetime))
		return false;

	float alpha = cos(((time - lasttime) / fadetime) * 90 * DEG2RAD); // fade non-linear like the physics panel does
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
