#include "screenshotimage.qh"

entity makeXonoticScreenshotImage()
{
	entity me;
	me = NEW(XonoticScreenshotImage);
	me.configureXonoticScreenshotImage(me);
	return me;
}

void XonoticScreenshotImage_configureXonoticScreenshotImage(entity me)
{
	me.configureXonoticImage(me, string_null, -2);
	me.zoomLimitedByTheBox = false; // enable this to forbid enlarging the image more than the containing box (if making use of draw_SetClip is a too bad thing)
	me.zoomSnapToTheBox = false; // disabled: it's cooler
}

void XonoticScreenshotImage_load(entity me, string theImage)
{
	me.screenshotTime = time;
	me.src = theImage;
	strcpy(me.screenshotTitle, substring(me.src, 13, strlen(theImage) - 13)); //strip "/screenshots/"

	me.initZoom(me); // this image may have a different size
	me.setZoom(me, 0, 0);
}

METHOD(XonoticScreenshotImage, mousePress, bool(XonoticScreenshotImage this, vector pos))
{
	return this.drag_setStartPos(this, pos);
}

float XonoticScreenshotImage_mouseDrag(entity me, vector coords)
{
	return me.drag(me, coords);
}

float XonoticScreenshotImage_mouseMove(entity me, vector coords)
{
	return me.drag_setStartPos(me, coords);
}

void XonoticScreenshotImage_draw(entity me)
{
	if (me.src != "")
	{
		float theAlpha;
		SUPER(XonoticScreenshotImage).draw(me);
		if (me.showTitle && time < me.screenshotTime + 4) // 3 seconds at full alpha, 1 second fading out
		{
			theAlpha = (4 - (time - me.screenshotTime));
			draw_CenterText('0.5 0 0', me.screenshotTitle, me.realFontSize, '1 1 1', theAlpha, false);
		}
		if (time < me.zoomTime + 2) // 1 seconds at full alpha, 1 second fading out
		{
			float myzoom = me.zoomFactor;
			string zoomString = ftos_decimals_percentage(myzoom, (myzoom == floor(myzoom) ? 0 : 2));
			theAlpha = (2 - (time - me.zoomTime));
			draw_Text('0.05 0.95 0', zoomString, me.realFontSize, '1 1 1', theAlpha, false);
		}
	}
}

void XonoticScreenshotImage_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticScreenshotImage).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / absSize.y;
	me.realFontSize_x = me.fontSize / absSize.x;
}
