#ifndef DIALOG_MULTIPLAYER_H
#define DIALOG_MULTIPLAYER_H
#include "dialog.qc"
CLASS(XonoticMultiplayerDialog, XonoticDialog)
	METHOD(XonoticMultiplayerDialog, fill, void(entity));
	ATTRIB(XonoticMultiplayerDialog, title, string, _("Multiplayer"))
	ATTRIB(XonoticMultiplayerDialog, tooltip, string, _("Play online, against your friends in LAN, view demos or change player settings"))
	ATTRIB(XonoticMultiplayerDialog, color, vector, SKINCOLOR_DIALOG_MULTIPLAYER)
	ATTRIB(XonoticMultiplayerDialog, intendedWidth, float, 0.96)
	ATTRIB(XonoticMultiplayerDialog, rows, float, 24)
	ATTRIB(XonoticMultiplayerDialog, columns, float, 4)
ENDCLASS(XonoticMultiplayerDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticMultiplayerDialog_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 1);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton_T(mc, _("Servers"), makeXonoticServerListTab(),
			_("Find servers to play on")));
		me.TD(me, 1, 1, e = mc.makeTabButton_T(mc, _("Create"), makeXonoticServerCreateTab(),
			_("Host your own game")));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Media"), makeXonoticMediaTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Profile"), makeXonoticProfileTab()));

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, mc);
}
#endif
