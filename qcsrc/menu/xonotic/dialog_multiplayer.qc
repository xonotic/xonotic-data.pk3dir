#include "dialog_multiplayer.qh"

#include "tabcontroller.qh"
#include "dialog_multiplayer_join.qh"
#include "dialog_multiplayer_create.qh"
#include "dialog_multiplayer_profile.qh"

void XonoticMultiplayerDialog_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 1);
	me.TR(me);
		me.TD(me, 1, 4/3, e = mc.makeTabButton_T(mc, _("Servers"), makeXonoticServerListTab(),
			_("Find servers to play on")));
		me.TD(me, 1, 4/3, e = mc.makeTabButton_T(mc, _("Create"), makeXonoticServerCreateTab(),
			_("Host your own game")));
		me.TD(me, 1, 4/3, e = mc.makeTabButton(mc, _("Profile"), makeXonoticProfileTab()));

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, mc);
}
