#ifdef INTERFACE
CLASS(XonoticMediaTab) EXTENDS(XonoticTab)
	METHOD(XonoticMediaTab, fill, void(entity))
	ATTRIB(XonoticMediaTab, title, string, _("Demo"))
	ATTRIB(XonoticMediaTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticMediaTab, rows, float, 22)
	ATTRIB(XonoticMediaTab, columns, float, 2)
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
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Demos"), makeXonoticDemoBrowserTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Screenshots"), makeXonoticScreenshotBrowserTab()));

	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
