#ifndef DIALOG_MEDIA_H
#define DIALOG_MEDIA_H
#include "dialog.qc"
CLASS(XonoticMediaDialog, XonoticDialog)
	METHOD(XonoticMediaDialog, fill, void(entity))
	ATTRIB(XonoticMediaDialog, title, string, _("Media"))
	ATTRIB(XonoticMediaDialog, color, vector, SKINCOLOR_DIALOG_MEDIA)
	ATTRIB(XonoticMediaDialog, intendedWidth, float, 0.80)
	ATTRIB(XonoticMediaDialog, rows, float, 21)
	ATTRIB(XonoticMediaDialog, columns, float, 3)
ENDCLASS(XonoticMediaDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticMediaDialog_fill(entity me)
{
	entity demos = makeXonoticDemoBrowserTab();
	entity screenshots = makeXonoticScreenshotBrowserTab();
	entity music = makeXonoticMusicPlayerTab();
	entity tabs = makeXonoticTabController(max(demos.rows, screenshots.rows, music.rows));
	me.TR(me);
		me.TD(me, 1, 1, tabs.makeTabButton(tabs, _("Demos"), demos));
		me.TD(me, 1, 1, tabs.makeTabButton(tabs, _("Screenshots"), screenshots));
		me.TD(me, 1, 1, tabs.makeTabButton(tabs, _("Music Player"), music));
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, tabs);
}
#endif
