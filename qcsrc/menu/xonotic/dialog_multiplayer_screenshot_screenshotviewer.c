#ifdef INTERFACE
CLASS(XonoticScreenshotViewerDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticScreenshotViewerDialog, fill, void(entity))
	METHOD(XonoticScreenshotViewerDialog, keyDown, float(entity, float, float, float))
	METHOD(XonoticScreenshotViewerDialog, loadScreenshot, void(entity, string))
	ATTRIB(XonoticScreenshotViewerDialog, title, string, "Screenshot Viewer")
	ATTRIB(XonoticScreenshotViewerDialog, name, string, "ScreenshotViewer")
	ATTRIB(XonoticScreenshotViewerDialog, intendedWidth, float, 1)
	ATTRIB(XonoticScreenshotViewerDialog, rows, float, 25)
	ATTRIB(XonoticScreenshotViewerDialog, columns, float, 6.5)
	ATTRIB(XonoticScreenshotViewerDialog, color, vector, SKINCOLOR_DIALOG_SCREENSHOTVIEWER)
	ATTRIB(XonoticScreenshotViewerDialog, scrList, entity, NULL)
	ATTRIB(XonoticScreenshotViewerDialog, screenshotImage, entity, NULL)
	ATTRIB(XonoticScreenshotViewerDialog, currentScrPath, string, string_null)
ENDCLASS(XonoticScreenshotViewerDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticScreenshotViewerDialog_loadScreenshot(entity me, string scrImage)
{
	if (me.currentScrPath == scrImage)
		return;
	if (me.currentScrPath)
		strunzone(me.currentScrPath);
	me.currentScrPath = strzone(scrImage);
	me.screenshotImage.configureXonoticScreenshotImage(me.screenshotImage, me.currentScrPath);
}
void prevScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, -1);
}
void nextScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, +1);
}
float XonoticScreenshotViewerDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_KP_LEFTARROW:
		case K_LEFTARROW:
			me.scrList.goScreenshot(me.scrList, -1);
			return 1;
		case K_KP_RIGHTARROW:
		case K_RIGHTARROW:
			me.scrList.goScreenshot(me.scrList, +1);
			return 1;
		default:
			if (me.scrList.keyDown(me.scrList, key, ascii, shift))
			{
				// keyDown has already changed the selected item
				me.scrList.goScreenshot(me.scrList, 0);
				return 1;
			}
			return SUPER(XonoticScreenshotViewerDialog).keyDown(me, key, ascii, shift);
	}
}
void XonoticScreenshotViewerDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, e = makeXonoticScreenshotImage());
			me.screenshotImage = e;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns/2, e = makeXonoticButton("Previous", '0 0 0'));
			e.onClick = prevScreenshot_Click;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns/2, e = makeXonoticButton("Next", '0 0 0'));
			e.onClick = nextScreenshot_Click;
			e.onClickEntity = me;
}
#endif
