#include "draw.qh"

#include <client/draw.qh>

// functions to make hud elements align perfectly in the hud area
void HUD_Panel_drawStrafeHUD(float fromangle, float toangle, vector color, float alpha, int type, int gradientType, bool doProject, float range)
{
	if(toangle < fromangle)
	{
		float tmp = fromangle;
		fromangle = toangle;
		toangle = tmp;
	}

	float offset = StrafeHUD_angleToOffset(fromangle % 360, range);
	float width = StrafeHUD_angleToOffset(toangle, range) - StrafeHUD_angleToOffset(fromangle, range);

	float mirror_offset, mirror_width;
	vector size = panel_size;
	vector mirror_size = panel_size;
	float overflow_width = 0, overflow_mirror_width = 0;
	float original_width = width; // required for gradient

	if(type == STRAFEHUD_STYLE_GRADIENT && gradientType == STRAFEHUD_GRADIENT_NONE)
		type = STRAFEHUD_STYLE_DRAWFILL;

	if(alpha <= 0 && type != STRAFEHUD_STYLE_GRADIENT || width <= 0)
		return;

	// how much is hidden by the current hud angle
	float hidden_width = (360 - range) / range * panel_size.x;

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

	float original_offset = offset;
	if(doProject)
	{
		if(size.x > 0) size.x = StrafeHUD_projectWidth(offset, size.x, range);
		offset = StrafeHUD_projectOffset(offset, range, false);
	}

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

	float original_mirror_offset = mirror_offset;
	if(doProject)
	{
		if(mirror_size.x > 0) mirror_size.x = StrafeHUD_projectWidth(mirror_offset, mirror_size.x, range);
		mirror_offset = StrafeHUD_projectOffset(mirror_offset, range, false);
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
				mirror_size, original_width, mirror_offset, original_mirror_offset,
				alpha, gradient_mirror_offset, gradientType, doProject, range);

			StrafeHUD_drawGradient(
				color, autocvar_hud_panel_strafehud_bar_neutral_color,
				size, original_width, offset, original_offset,
				alpha, gradient_offset, gradientType, doProject, range);
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

void StrafeHUD_drawGradient(vector color1, vector color2, vector size, float original_width, float offset, float original_offset, float alpha, float gradientOffset, int gradientType, bool doProject, float range)
{
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
		if(doProject)
			ratio_offset = StrafeHUD_projectOffset(ratio_offset, range, true);
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
bool StrafeHUD_drawTextIndicator(string text, float height, vector color, float fadetime, float lasttime, float offset, int position)
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
