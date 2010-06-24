#ifdef INTERFACE
CLASS(XonoticNewsDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticNewsDialog, fill, void(entity))
	ATTRIB(XonoticNewsDialog, title, string, "News")
	ATTRIB(XonoticNewsDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(XonoticNewsDialog, intendedWidth, float, 0.96)
	ATTRIB(XonoticNewsDialog, rows, float, 24)
	ATTRIB(XonoticNewsDialog, columns, float, 1)
ENDCLASS(XonoticNewsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticNewsDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 24, 1, e = spawnGecko());
		e.configureBrowser( e, "http://alientrap.org/xonotic/index.php?module=news" );
}
#endif
