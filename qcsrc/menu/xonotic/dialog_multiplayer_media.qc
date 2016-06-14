#include "dialog_multiplayer_media.qh"

#include "demolist.qh"
#include "dialog_multiplayer_media_demo.qh"
#include "dialog_multiplayer_media_screenshot.qh"
#include "dialog_multiplayer_media_musicplayer.qh"
#include "dialog_multiplayer_media_demo_timeconfirm.qh"
#include "dialog_multiplayer_media_demo_startconfirm.qh"

#include "tabcontroller.qh"

entity makeXonoticMediaTab()
{
	entity me;
	me = NEW(XonoticMediaTab);
	me.configureDialog(me);
	return me;
}
void XonoticMediaTab_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 2);

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Demos"), makeXonoticDemoBrowserTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Screenshots"), makeXonoticScreenshotBrowserTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Music Player"), makeXonoticMusicPlayerTab()));

	me.gotoRC(me, 3, 0);
		me.TD(me, me.rows - 2, me.columns, mc);
}
