#ifdef INTERFACE
CLASS(XonoticScreenshotImage) EXTENDS(Image)
	METHOD(XonoticScreenshotImage, configureXonoticScreenshotImage, void(entity, string))
	METHOD(XonoticScreenshotImage, draw, void(entity))
	METHOD(XonoticScreenshotImage, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(XonoticScreenshotImage, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticScreenshotImage, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticScreenshotImage, showTitle, float, 1)
	ATTRIB(XonoticScreenshotImage, showTitleTime, float, 0)
	ATTRIB(XonoticScreenshotImage, screenshotTitle, string, string_null)
ENDCLASS(XonoticScreenshotImage)
entity makeXonoticScreenshotImage();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticScreenshotImage()
{
	entity me;
	me = spawnXonoticScreenshotImage();
	me.configureXonoticScreenshotImage(me, string_null);
	return me;
}

void XonoticScreenshotImage_configureXonoticScreenshotImage(entity me, string theImage)
{
	me.configureImage(me, theImage);
	me.forcedAspect = -1;
	me.showTitleTime = time + 3; // show title for 3 seconds
	me.updateAspect(me);
	if (me.screenshotTitle)
		strunzone(me.screenshotTitle);
	me.screenshotTitle = strzone(substring(me.src, 13, strlen(theImage) - 13)); //strip "/screenshots/"
}

void XonoticScreenshotImage_draw(entity me)
{
	if (me.src != "")
	{
		SUPER(XonoticScreenshotImage).draw(me);
		if (me.showTitle && time < me.showTitleTime + 1) // fade title out in 1 second
		{
			float theAlpha = (1 - (time - me.showTitleTime));
			draw_CenterText('0.5 0 0', me.screenshotTitle, me.realFontSize, '1 1 1', theAlpha, FALSE);
		}
	}
}

void XonoticScreenshotImage_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticScreenshotImage).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / absSize_y;
	me.realFontSize_x = me.fontSize / absSize_x;
}
#endif
