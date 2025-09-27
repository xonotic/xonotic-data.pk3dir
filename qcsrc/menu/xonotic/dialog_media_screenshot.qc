#include "dialog_media_screenshot.qh"

#include "dialog_media_screenshot_viewer.qh"
#include "screenshotlist.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "checkbox.qh"
#include "button.qh"

entity makeXonoticScreenshotBrowserTab()
{
	entity me;
	me = NEW(XonoticScreenshotBrowserTab);
	me.configureDialog(me);
	return me;
}
void XonoticScreenshotBrowserTab_loadPreviewScreenshot(entity me, string scrImage)
{
	if (me.currentScrPath == scrImage)
		return;
	strcpy(me.currentScrPath, scrImage);
	me.screenshotImage.load(me.screenshotImage, me.currentScrPath);
}
void XonoticScreenshotBrowserTab_fill(entity me)
{
	entity e, slist;
	slist = makeXonoticScreenshotList();

	me.gotoRC(me, 0.5, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, 2.4, e = makeXonoticInputBox(0, string_null));
			e.onChange = ScreenshotList_Filter_Would_Change;
			e.onChangeEntity = slist;
			slist.screenshotViewerDialog = main.screenshotViewerDialog;
			main.screenshotViewerDialog.scrList = slist;

	me.gotoRC(me, 0.5, 3.1);
		me.TD(me, 1, 1.9, e = makeXonoticCheckBoxEx(2, 1, "cl_autoscreenshot", _("Auto screenshot scoreboard")));
			e.sendCvars = true;
		me.TD(me, 1, 1, e = makeXonoticButton(_("Refresh"), '0 0 0'));
			e.onClick = ScreenshotList_Refresh_Click;
			e.onClickEntity = slist;

	/*me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, "Filter:"));
		me.TD(me, 1, me.columns - 1.5, e = makeXonoticInputBox(0, string_null));
			e.onChange = ScreenshotList_Filter_Would_Change;
			e.onChangeEntity = slist;
			slist.screenshotViewerDialog = main.screenshotViewerDialog;
			main.screenshotViewerDialog.scrList = slist;
		me.TD(me, 1, 1, e = makeXonoticButton(_("Refresh"), '0 0 0'));
			e.onClick = ScreenshotList_Refresh_Click;
			e.onClickEntity = slist;*/

	me.gotoRC(me, 2, 0);
		me.TD(me, me.rows - 3, me.columns, slist);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Open in the viewer"), '0 0 0'));
			e.onClick = StartScreenshot_Click;
			e.onClickEntity = slist;
/*
	me.TR(me);
		me.TD(me, me.rows - me.currentRow, me.columns, e = makeXonoticScreenshotImage());
			e.showTitle = false;
			me.screenshotImage = e;
			slist.screenshotPreview = e;
			slist.screenshotBrowserDialog = me;
*/
}
