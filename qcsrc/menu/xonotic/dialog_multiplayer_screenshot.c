#ifdef INTERFACE
CLASS(XonoticScreenshotBrowserTab) EXTENDS(XonoticTab)
	METHOD(XonoticScreenshotBrowserTab, fill, void(entity))
	ATTRIB(XonoticScreenshotBrowserTab, title, string, "Screenshot")
	ATTRIB(XonoticScreenshotBrowserTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticScreenshotBrowserTab, rows, float, 22)
	ATTRIB(XonoticScreenshotBrowserTab, columns, float, 6.5)
	ATTRIB(XonoticScreenshotBrowserTab, screenshotImage, entity, NULL)
	ATTRIB(XonoticScreenshotBrowserTab, name, string, "ScreenshotBrowser")
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
void XonoticScreenshotBrowserTab_fill(entity me)
{
	entity e, btn, slist;
	me.TR(me);
	slist = makeXonoticScreenshotList();
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, "Filter:"));
		me.TD(me, 1, 0.5, btn = makeXonoticButton("Clear", '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, me.columns - 1, e = makeXonoticInputBox(0, string_null));
			e.onChange = ScreenshotList_Filter_Change;
			e.onChangeEntity = slist;
			btn.onClickEntity = e;
			slist.controlledTextbox = e;
			slist.screenshotViewerDialog = main.screenshotViewerDialog;
			main.screenshotViewerDialog.scrList = slist;
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, slist);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton("View", '0 0 0'));
			e.onClick = StartScreenshot_Click;
			e.onClickEntity = slist;
}
#endif
