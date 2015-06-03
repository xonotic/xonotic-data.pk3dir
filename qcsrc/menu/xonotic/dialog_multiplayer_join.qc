#ifndef DIALOG_MULTIPLAYER_JOIN_H
#define DIALOG_MULTIPLAYER_JOIN_H
#include "tab.qc"
CLASS(XonoticJoinTab, XonoticTab)
	METHOD(XonoticJoinTab, fill, void(entity))
	ATTRIB(XonoticJoinTab, title, string, _("Join"))
	ATTRIB(XonoticJoinTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticJoinTab, rows, float, 23)
	ATTRIB(XonoticJoinTab, columns, float, 3)
	ATTRIB(XonoticJoinTab, name, string, "Join")
ENDCLASS(XonoticJoinTab)
entity makeXonoticJoinTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticJoinTab()
{
	entity me;
	me = NEW(XonoticJoinTab);
	me.configureDialog(me);
	return me;
}
void XonoticJoinTab_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 2);

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 1.5, e = mc.makeTabButton(mc, _("Public"), makeXonoticServerListTab()));
		me.TD(me, 1, 1.5, e = mc.makeTabButton(mc, _("Private"), makeXonoticPrivateServerListTab()));

	me.gotoRC(me, 3, 0);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
