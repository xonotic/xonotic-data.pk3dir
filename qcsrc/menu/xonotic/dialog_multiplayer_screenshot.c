#ifdef INTERFACE
CLASS(XonoticScreenshotBrowserTab) EXTENDS(XonoticTab)
	METHOD(XonoticScreenshotBrowserTab, fill, void(entity))
	ATTRIB(XonoticScreenshotBrowserTab, title, string, "Screenshot")
	ATTRIB(XonoticScreenshotBrowserTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticScreenshotBrowserTab, rows, float, 22)
	ATTRIB(XonoticScreenshotBrowserTab, columns, float, 6.5)
	ATTRIB(XonoticScreenshotBrowserTab, name, string, "ScreenshotBrowser")
	
	METHOD(XonoticScreenshotBrowserTab, loadPreviewScreenshot, void(entity, string))
	ATTRIB(XonoticScreenshotBrowserTab, screenshotImage, entity, NULL)
	ATTRIB(XonoticScreenshotBrowserTab, currentScrPath, string, string_null)
ENDCLASS(XonoticScreenshotBrowserTab)
entity makeXonoticScreenshotBrowserTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticScreenshotBrowserTab()
{
	entity me;
	me = spawnXonoticScreenshotBrowserTab();
	me.configureDialog(me);
	return me;
}
void XonoticScreenshotBrowserTab_loadPreviewScreenshot(entity me, string scrImage)
{
	if (me.currentScrPath)
		strunzone(me.currentScrPath);
	me.currentScrPath = strzone(scrImage);
	me.screenshotImage.configureXonoticScreenshotImage(me.screenshotImage, me.currentScrPath);
}
void XonoticScreenshotBrowserTab_fill(entity me)
{
	entity e, btn, slist;
	slist = makeXonoticScreenshotList();
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, "Filter:"));
		me.TD(me, 1, 0.5, btn = makeXonoticButton("Clear", '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, me.columns - 1.5, e = makeXonoticInputBox(0, string_null));
			e.onChange = ScreenshotList_Filter_Change;
			e.onChangeEntity = slist;
			btn.onClickEntity = e;
			slist.controlledTextbox = e;
			slist.screenshotViewerDialog = main.screenshotViewerDialog;
			main.screenshotViewerDialog.scrList = slist;
		me.TD(me, 1, 0.5, e = makeXonoticButton("Refresh", '0 0 0'));
			e.onClick = ScreenshotList_Refresh_Click;
			e.onClickEntity = slist;
	me.TR(me);
		me.TD(me, 8, me.columns, slist);
	me.gotoRC(me, 9, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton("Open in the viewer", '0 0 0'));
			e.onClick = StartScreenshot_Click;
			e.onClickEntity = slist;
	me.TR(me);
		me.TD(me, me.rows - 10, me.columns, e = makeXonoticScreenshotImage());
			e.showTitle = 0;
			me.screenshotImage = e;
			slist.screenshotPreview = e;
			slist.screenshotBrowserDialog = me;
}
#endif
