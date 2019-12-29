#include "dialog_multiplayer_join_serverinfo.qh"

#include "tabcontroller.qh"
#include "serverlist.qh"
#include "playerlist.qh"
#include "inputbox.qh"
#include "textlabel.qh"
#include "button.qh"
#include "dialog_multiplayer_join_serverinfotab.qh"
#include "dialog_multiplayer_join_ToS.qh"


void XonoticServerInfoDialog_loadServerInfo(entity me, float i)
{
    me.infoTab.loadServerInfo(me.infoTab, i);
}

void XonoticServerInfoDialog_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 1);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Status"), me.infoTab = makeXonoticServerInfoTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Terms of Service"), makeXonoticServerToSTab()));

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, mc);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Close"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
		//me.TD(me, 1, me.columns/3, e = makeXonoticButton("", '0 0 0')); // TODO: Add bookmark button here
		//	e.onClick = ServerList_Favorite_Click;
		//	e.onClickEntity = slist;
		//	slist.favoriteButton = e;
		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Join!"), '0 0 0'));
			e.onClick = Join_Click;
			e.onClickEntity = me;
}

void Join_Click(entity btn, entity me)
{
	localcmd("connect ", me.infoTab.currentServerCName, "\n");
}

