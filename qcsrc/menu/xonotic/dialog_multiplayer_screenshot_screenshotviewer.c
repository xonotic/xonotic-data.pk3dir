#ifdef INTERFACE
CLASS(XonoticScreenshotViewerDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticScreenshotViewerDialog, fill, void(entity))
	METHOD(XonoticScreenshotViewerDialog, loadScreenshot, void(entity, string))
	ATTRIB(XonoticScreenshotViewerDialog, title, string, "Screenshot Viewer")
	ATTRIB(XonoticScreenshotViewerDialog, intendedWidth, float, 1)
	ATTRIB(XonoticScreenshotViewerDialog, rows, float, 25)
	ATTRIB(XonoticScreenshotViewerDialog, columns, float, 6.5)
	ATTRIB(XonoticScreenshotViewerDialog, screenshotImage, entity, NULL)
	ATTRIB(XonoticScreenshotViewerDialog, scrList, entity, NULL)
ENDCLASS(XonoticScreenshotViewerDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticScreenshotViewerDialog_loadScreenshot(entity me, string scrImage)
{
	if (me.screenshotImage.src)
		strunzone(me.screenshotImage.src);
	me.screenshotImage.src = strzone(scrImage);
	me.screenshotImage.updateAspect(me.screenshotImage);
}
void prevScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, -1);
}
void nextScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, +1);
}
void XonoticScreenshotViewerDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, e = makeXonoticImage(string_null, -1));
		me.screenshotImage = e;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns/2, e = makeXonoticButton("Prev", '0 0 0'));
			e.onClick = prevScreenshot_Click;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns/2, e = makeXonoticButton("Next", '0 0 0'));
			e.onClick = nextScreenshot_Click;
			e.onClickEntity = me;
}
#endif
