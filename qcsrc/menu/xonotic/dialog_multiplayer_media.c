#ifdef INTERFACE
CLASS(XonoticMediaTab) EXTENDS(XonoticTab)
	METHOD(XonoticMediaTab, fill, void(entity))
	ATTRIB(XonoticMediaTab, title, string, _("Media"))
	ATTRIB(XonoticMediaTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticMediaTab, rows, float, 23)
	ATTRIB(XonoticMediaTab, columns, float, 3)
	ATTRIB(XonoticMediaTab, name, string, "Media")	
ENDCLASS(XonoticMediaTab)
entity makeXonoticMediaTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticMediaTab()
{
	entity me;
	me = spawnXonoticMediaTab();
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
#endif
