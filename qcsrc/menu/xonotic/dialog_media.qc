#include "dialog_media.qh"
#include "dialog_media_guide.qh"
#include "dialog_media_demo.qh"
#include "dialog_media_screenshot.qh"
#include "dialog_media_musicplayer.qh"
#include "tabcontroller.qh"

void XonoticMediaDialog_fill(entity me)
{
	entity mc;
	mc = makeXonoticTabController(me.rows - 1);
	me.TR(me);
		me.TD(me, 1, 6/4, mc.makeTabButton(mc, _("Guide"),        makeXonoticGuideTab()));
		me.TD(me, 1, 6/4, mc.makeTabButton(mc, _("Demos"),        makeXonoticDemoBrowserTab()));
		me.TD(me, 1, 6/4, mc.makeTabButton(mc, _("Screenshots"),  makeXonoticScreenshotBrowserTab()));
		me.TD(me, 1, 6/4, mc.makeTabButton(mc, _("Music Player"), makeXonoticMusicPlayerTab()));
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, mc);
}
