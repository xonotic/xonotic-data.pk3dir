#include "draw.qh"
#include <common/util.qh>
#include <common/constants.qh>

string draw_mousepointer;
vector draw_mousepointer_offset;
vector draw_mousepointer_size;

void draw_setMousePointer(string pic, vector theSize, vector theOffset)
{
	draw_mousepointer = strzone(draw_UseSkinFor(pic));
	draw_mousepointer_size = theSize;
	draw_mousepointer_offset = eX * (theOffset.x * theSize.x) + eY * (theOffset.y * theSize.y);
}

void draw_drawMousePointer(vector where)
{
	drawpic(boxToGlobal(where, draw_shift, draw_scale) - draw_mousepointer_offset, draw_mousepointer, draw_mousepointer_size, '1 1 1', draw_alpha, 0);
}

void draw_reset(float cw, float ch, float ox, float oy)
{
	draw_shift = '1 0 0' * ox + '0 1 0' * oy;
	draw_scale = '1 0 0' * cw + '0 1 0' * ch;
	draw_alpha = 1;
	draw_fontscale = '1 1 0';
	draw_endBoldFont();
}

vector globalToBox(vector v, vector theOrigin, vector theScale)
{
	v -= theOrigin;
	v.x /= theScale.x;
	v.y /= theScale.y;
	return v;
}

vector globalToBoxSize(vector v, vector theScale)
{
	v.x /= theScale.x;
	v.y /= theScale.y;
	return v;
}

vector boxToGlobal(vector v, vector theOrigin, vector theScale)
{
	v.x *= theScale.x;
	v.y *= theScale.y;
	v += theOrigin;
	return v;
}

vector boxToGlobalSize(vector v, vector theScale)
{
	v.x *= theScale.x;
	v.y *= theScale.y;
	return v;
}

string draw_PreloadPicture(string pic)
{
	pic = draw_UseSkinFor(pic);
	return precache_pic(pic);
}

string draw_PreloadPictureWithFlags(string pic, float f)
{
	pic = draw_UseSkinFor(pic);
	return precache_pic(pic, f);
}

void draw_Picture(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha)
{
	if(theSize.x == 0 || theSize.y <= 0) // no default sizing please
		return;
	pic = draw_UseSkinFor(pic);
	drawpic(boxToGlobal(theOrigin, draw_shift, draw_scale), pic, boxToGlobalSize(theSize, draw_scale), theColor, theAlpha * draw_alpha, 0);
}

vector draw_PictureSize(string pic)
{
	pic = draw_UseSkinFor(pic);
	return drawgetimagesize(pic);
}

bool draw_PictureExists(string pic)
{
	pic = draw_UseSkinFor(pic);
	if (fexists(strcat(pic, ".tga"))) return true;
	if (fexists(strcat(pic, ".png"))) return true;
	if (fexists(strcat(pic, ".jpg"))) return true;
	if (fexists(strcat(pic, ".pcx"))) return true;

	return false;
}

void draw_Fill(vector theOrigin, vector theSize, vector theColor, float theAlpha)
{
	drawfill(boxToGlobal(theOrigin, draw_shift, draw_scale), boxToGlobalSize(theSize, draw_scale), theColor, theAlpha * draw_alpha, 0);
}

// a button picture is a texture containing three parts:
//   1/4 width: left part
//   1/2 width: middle part (stretched)
//   1/4 width: right part
// it is assumed to be 4x as wide as high for aspect ratio purposes, which
// means, the parts are a square, two squares and a square.
void draw_ButtonPicture(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha)
{
	vector square;
	vector width, height;
	vector bW;
	pic = draw_UseSkinFor(pic);
	theOrigin = boxToGlobal(theOrigin, draw_shift, draw_scale);
	theSize = boxToGlobalSize(theSize, draw_scale);
	theAlpha *= draw_alpha;
	width = eX * theSize.x;
	height = eY * theSize.y;
	if(theSize.x <= theSize.y * 2)
	{
		// button not wide enough
		// draw just left and right part then
		square = eX * theSize.x * 0.5;
		bW = eX * (0.25 * theSize.x / (theSize.y * 2));
		drawsubpic(theOrigin,          square + height, pic, '0 0 0', eY + bW, theColor, theAlpha, 0);
		drawsubpic(theOrigin + square, square + height, pic, eX - bW, eY + bW, theColor, theAlpha, 0);
	}
	else
	{
		square = eX * theSize.y;
		drawsubpic(theOrigin,                  height  +     square, pic, '0    0 0', '0.25 1 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin +         square, theSize - 2 * square, pic, '0.25 0 0', '0.5  1 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin + width - square, height  +     square, pic, '0.75 0 0', '0.25 1 0', theColor, theAlpha, 0);
	}
}

// a vertical button picture is a texture containing three parts:
//   1/4 height: left part
//   1/2 height: middle part (stretched)
//   1/4 height: right part
// it is assumed to be 4x as high as wide for aspect ratio purposes, which
// means, the parts are a square, two squares and a square.
void draw_VertButtonPicture(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha)
{
	vector square;
	vector width, height;
	vector bH;
	pic = draw_UseSkinFor(pic);
	theOrigin = boxToGlobal(theOrigin, draw_shift, draw_scale);
	theSize = boxToGlobalSize(theSize, draw_scale);
	theAlpha *= draw_alpha;
	width = eX * theSize.x;
	height = eY * theSize.y;
	if(theSize.y <= theSize.x * 2)
	{
		// button not high enough
		// draw just upper and lower part then
		square = eY * theSize.y * 0.5;
		bH = eY * (0.25 * theSize.y / (theSize.x * 2));
		drawsubpic(theOrigin,          square + width, pic, '0 0 0', eX + bH, theColor, theAlpha, 0);
		drawsubpic(theOrigin + square, square + width, pic, eY - bH, eX + bH, theColor, theAlpha, 0);
	}
	else
	{
		square = eY * theSize.x;
		drawsubpic(theOrigin,                   width   +     square, pic, '0 0    0', '1 0.25 0', theColor, theAlpha, 0);
		drawsubpic(theOrigin +          square, theSize - 2 * square, pic, '0 0.25 0', '1 0.5  0', theColor, theAlpha, 0);
		drawsubpic(theOrigin + height - square, width   +     square, pic, '0 0.75 0', '1 0.25 0', theColor, theAlpha, 0);
	}
}

// a border picture is a texture containing nine parts:
//   1/4 width: left part
//   1/2 width: middle part (stretched)
//   1/4 width: right part
// divided into
//   1/4 height: top part
//   1/2 height: middle part (stretched)
//   1/4 height: bottom part
void draw_BorderPicture(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha, vector theBorderSize)
{
	vector dX, dY;
	vector width, height;
	vector bW, bH;
	pic = draw_UseSkinFor(pic);
	theOrigin = boxToGlobal(theOrigin, draw_shift, draw_scale);
	theSize = boxToGlobalSize(theSize, draw_scale);
	theBorderSize = boxToGlobalSize(theBorderSize, draw_scale);
	theAlpha *= draw_alpha;
	width = eX * theSize.x;
	height = eY * theSize.y;
	// zero size? bail out, we cannot handle this
	if(theSize.x <= 0 || theSize.y <= 0)
		return;
	if(theBorderSize.x <= 0) // no x border
	{
		if(theBorderSize.y <= 0)
		{
			drawsubpic(theOrigin,                            width          + height,          pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
		}
		else if(theSize.y <= theBorderSize.y * 2)
		{
			// not high enough... draw just top and bottom then
			bH = eY * (0.25 * theSize.y / (theBorderSize.y * 2));
			drawsubpic(theOrigin,                             width          + height * 0.5, pic, '0.25 0 0',           '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin              + height * 0.5, width          + height * 0.5, pic, '0.25 0 0' + eY - bH, '0.5  0 0' + bH, theColor, theAlpha, 0);
		}
		else
		{
			dY = theBorderSize.y * eY;
			drawsubpic(theOrigin,                            width                   +     dY, pic, '0.25 0    0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY,              width          + height - 2 * dY, pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY,              width                   +     dY, pic, '0.25 0.75 0', '0.5  0.25 0', theColor, theAlpha, 0);
		}
	}
	else if(theSize.x <= theBorderSize.x * 2)
	{
		// not wide enough... draw just left and right then
		bW = eX * (0.25 * theSize.x / (theBorderSize.x * 2));
		if(theBorderSize.y <= 0)
		{
			drawsubpic(theOrigin,                             width * 0.5 + height,          pic, '0 0.25 0',           '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5,               width * 0.5 + height,          pic, '0 0.25 0' + eX - bW, '0 0.5  0' + bW, theColor, theAlpha, 0);
		}
		else if(theSize.y <= theBorderSize.y * 2)
		{
			// not high enough... draw just corners
			bH = eY * (0.25 * theSize.y / (theBorderSize.y * 2));
			drawsubpic(theOrigin,                 width * 0.5 + height * 0.5, pic, '0 0 0',           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width   * 0.5, width * 0.5 + height * 0.5, pic, eX - bW,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + height  * 0.5, width * 0.5 + height * 0.5, pic, eY - bH,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + theSize * 0.5, width * 0.5 + height * 0.5, pic, eX + eY - bW - bH, bW + bH, theColor, theAlpha, 0);
		}
		else
		{
			dY = theBorderSize.y * eY;
			drawsubpic(theOrigin,                             width * 0.5          +     dY, pic, '0 0    0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5,               width * 0.5          +     dY, pic, '0 0    0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin                        + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0',           '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5          + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0' + eX - bW, '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin               + height - dY, width * 0.5          +     dY, pic, '0 0.75 0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5 + height - dY, width * 0.5          +     dY, pic, '0 0.75 0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
		}
	}
	else
	{
		if(theBorderSize.y <= 0)
		{
			dX = theBorderSize.x * eX;
			drawsubpic(theOrigin,                                        dX + height,          pic, '0    0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin                       + dX, width - 2 * dX + height,          pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin               + width - dX,             dX + height,          pic, '0.75 0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
		}
		else if(theSize.y <= theBorderSize.y * 2)
		{
			// not high enough... draw just top and bottom then
			bH = eY * (0.25 * theSize.y / (theBorderSize.y * 2));
			dX = theBorderSize.x * eX;
			drawsubpic(theOrigin,                                         dX + height * 0.5, pic, '0    0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX,                        width - 2 * dX + height * 0.5, pic, '0.25 0 0',           '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX,                            dX + height * 0.5, pic, '0.75 0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin              + height * 0.5,             dX + height * 0.5, pic, '0    0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX         + height * 0.5, width - 2 * dX + height * 0.5, pic, '0.25 0 0' + eY - bH, '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX + height * 0.5,             dX + height * 0.5, pic, '0.75 0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
		}
		else
		{
			dX = theBorderSize.x * eX;
			dY = theBorderSize.y * eY;
			drawsubpic(theOrigin,                                        dX          +     dY, pic, '0    0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin                  + dX,      width - 2 * dX          +     dY, pic, '0.25 0    0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + width - dX,                  dX          +     dY, pic, '0.75 0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY,                          dX + height - 2 * dY, pic, '0    0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY         + dX, width - 2 * dX + height - 2 * dY, pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY + width - dX,             dX + height - 2 * dY, pic, '0.75 0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY,                          dX          +     dY, pic, '0    0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY         + dX, width - 2 * dX          +     dY, pic, '0.25 0.75 0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY + width - dX,             dX          +     dY, pic, '0.75 0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
		}
	}
}
void draw_Text(vector theOrigin, string theText, vector theSize, vector theColor, float theAlpha, float ICanHasKallerz)
{
	if(theSize.x <= 0 || theSize.y <= 0) {
		LOG_TRACE("Drawing zero size text?");
		return;
	}

	//float wi;
	//wi = draw_TextWidth(theText, ICanHasKallerz, theSize);
	//draw_Fill(theOrigin, '1 0 0' * wi + '0 1 0' * theSize_y, '1 0 0', 0.3);

	if(ICanHasKallerz)
		drawcolorcodedstring(boxToGlobal(theOrigin, draw_shift, draw_scale), theText, globalToBoxSize(boxToGlobalSize(theSize, draw_scale), draw_fontscale), theAlpha * draw_alpha, 0);
	else
		drawstring(boxToGlobal(theOrigin, draw_shift, draw_scale), theText, globalToBoxSize(boxToGlobalSize(theSize, draw_scale), draw_fontscale), theColor, theAlpha * draw_alpha, 0);
}
void draw_CenterText(vector theOrigin, string theText, vector theSize, vector theColor, float theAlpha, float ICanHasKallerz)
{
	//dprint(strcat("orig = ", vtos(theOrigin) ," tx = ", ftos(draw_TextWidth(theText, ICanHasKallerz, theSize)), "\n"));
	draw_Text(theOrigin - eX * 0.5 * draw_TextWidth(theText, ICanHasKallerz, theSize), theText, theSize, theColor, theAlpha, ICanHasKallerz);
}

float draw_TextWidth(string theText, float ICanHasKallerz, vector SizeThxBye)
{
	//return strlen(theText);
	//dprint("draw_TextWidth \"", theText, "\"\n");
	vector v;
	v = '0 0 0';
	//float r;
	v.x = stringwidth(theText, ICanHasKallerz, globalToBoxSize(boxToGlobalSize(SizeThxBye, draw_scale), draw_fontscale));
	v = globalToBoxSize(v, draw_scale);
	return v.x;
}

float draw_CondensedFontFactor(string theText, float ICanHasKallerz, vector SizeThxBye, float maxWidth)
{
	float w = draw_TextWidth(theText, ICanHasKallerz, SizeThxBye);
	if (w > maxWidth) {
		//dprintf("NOTE: label text %s too wide for label, condensed by factor %f\n", theText, maxWidth / w);
		return maxWidth / w;
	}
	return 1.0;
}

IntrusiveList draw_clip;
STATIC_INIT(draw_clip) { draw_clip = IL_NEW(); }
CLASS(ClipFrame, Object)
	ATTRIB(ClipFrame, clip_shift, vector, '0 0 0');
	ATTRIB(ClipFrame, clip_scale, vector, '0 0 0');
ENDCLASS(ClipFrame)

void _draw_SetClip(vector o, vector s)
{
	ClipFrame prev = IL_PEEK(draw_clip);
	if (prev) {
		o.x = bound(prev.clip_shift.x, o.x, prev.clip_shift.x + prev.clip_scale.x);
		o.y = bound(prev.clip_shift.y, o.y, prev.clip_shift.y + prev.clip_scale.y);
		s.x = bound(0, s.x, prev.clip_scale.x - (o.x - prev.clip_shift.x));
		s.y = bound(0, s.y, prev.clip_scale.y - (o.y - prev.clip_shift.y));
	}
	ClipFrame e = NEW(ClipFrame);
	e.clip_shift = o;
	e.clip_scale = s;
	IL_PUSH(draw_clip, e);
	drawsetcliparea(o.x, o.y, s.x, s.y);
}

void draw_SetClip()
{
	_draw_SetClip(draw_shift, draw_scale);
}

void draw_SetClipRect(vector theOrigin, vector theScale)
{
	_draw_SetClip(
		boxToGlobal(theOrigin, draw_shift, draw_scale),
		boxToGlobalSize(theScale, draw_scale)
	);
}

void draw_ClearClip()
{
	if (IL_EMPTY(draw_clip)) {
		LOG_FATAL("Not clipping, can't clear it then");
	}
	entity currentSettings = IL_PEEK(draw_clip);
	IL_REMOVE(draw_clip, currentSettings);
	delete(currentSettings);
	drawresetcliparea();
	ClipFrame e = IL_PEEK(draw_clip);
	if (e) {
		drawsetcliparea(e.clip_shift.x, e.clip_shift.y, e.clip_scale.x, e.clip_scale.y);
	}
}

string draw_TextShortenToWidth(string theText, float maxWidth, float ICanHasKallerz, vector SizeThxBye)
{
	/*
	if(draw_TextWidth(theText, ICanHasKallerz, SizeThxBye) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, draw_TextLengthUpToWidth(theText, maxWidth - draw_TextWidth("...", ICanHasKallerz, SizeThxBye), ICanHasKallerz, SizeThxBye)), "...");
	*/
	if(ICanHasKallerz)
		return textShortenToWidth(theText, maxWidth, SizeThxBye, draw_TextWidth_WithColors);
	else
		return textShortenToWidth(theText, maxWidth, SizeThxBye, draw_TextWidth_WithoutColors);
}

float draw_TextWidth_WithColors(string s, vector theFontSize)
{
	return draw_TextWidth(s, true, theFontSize);
}

float draw_TextWidth_WithoutColors(string s, vector theFontSize)
{
	return draw_TextWidth(s, false, theFontSize);
}

float draw_TextLengthUpToWidth(string theText, float maxWidth, float allowColorCodes, vector theFontSize)
{
	if(allowColorCodes)
		return textLengthUpToWidth(theText, maxWidth, theFontSize, draw_TextWidth_WithColors);
	else
		return textLengthUpToWidth(theText, maxWidth, theFontSize, draw_TextWidth_WithoutColors);
}
