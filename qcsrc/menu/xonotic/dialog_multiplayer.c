#ifdef INTERFACE
CLASS(XonoticMultiplayerDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticMultiplayerDialog, fill, void(entity))
	ATTRIB(XonoticMultiplayerDialog, title, string, "Multiplayer")
	ATTRIB(XonoticMultiplayerDialog, color, vector, SKINCOLOR_DIALOG_MULTIPLAYER)
	ATTRIB(XonoticMultiplayerDialog, intendedWidth, float, 0.96)
	ATTRIB(XonoticMultiplayerDialog, rows, float, 24)
	ATTRIB(XonoticMultiplayerDialog, columns, float, 6)
ENDCLASS(XonoticMultiplayerDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticMultiplayerDialog_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, "Servers",  makeXonoticServerListTab()));
			setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, "Create",  makeXonoticServerCreateTab()));
			setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Demos",   makeXonoticDemoBrowserTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, "Player Setup",  makeXonoticPlayerSettingsTab()));
			if(cvar_string("_cl_name") == "Player")
				e.onClick(e, e.onClickEntity); // lol animation

	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
