#include "dialog_multiplayer_join.qh"

#include "serverlist.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "checkbox.qh"
#include "commandbutton.qh"
#include "leavematchbutton.qh"
#include "button.qh"

entity makeXonoticServerListTab()
{
	entity me;
	me = NEW(XonoticServerListTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerListTab_refresh(entity this, entity slist)
{
	slist.refreshServerList(slist, REFRESHSERVERLIST_ASK);
}

void XonoticServerListTab_fill(entity me)
{
	entity e, slist;

	slist  = makeXonoticServerList();

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 0.8, e = makeXonoticCheckBox(0, "menu_slist_categories", ZCTX(_("SRVS^Categories"))));
			e.onClickEntity = slist;
			e.onClick = ServerList_Categories_Click;
		/* FILTER CONTROLS */
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, 2, e = makeXonoticInputBox(0, string_null));
			e.onChange = ServerList_Filter_Change;
			e.onChangeEntity = slist;
			slist.controlledTextbox = e;
	me.gotoRC(me, 0.5, 0.8 + 0.5 + 2);
		me.TD(me, 1, 0.6, e = makeXonoticCheckBox_T(0, "menu_slist_showempty", ZCTX(_("SRVS^Empty")),
			_("Show empty servers")));
			slist.filterShowEmpty = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowEmpty_Click;
		me.TD(me, 1, 0.5, e = makeXonoticCheckBox_T(0, "menu_slist_showfull", ZCTX(_("SRVS^Full")),
			_("Show full servers that have no slots available")));
			slist.filterShowFull = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowFull_Click;
		me.TD(me, 1, 0.6, e = makeXonoticCheckBox_T(0, "menu_slist_showlaggy", ZCTX(_("SRVS^Laggy")),
			_("Show high latency servers")));
			slist.filterShowLaggy = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowLaggy_Click;
		/* END FILTER CONTROLS */
		me.TDempty(me, 0.05);
		me.TD(me, 1, 0.8, e = makeXonoticButton_T(_("Refresh"), '0 0 0', _("Reload the server list")));
			e.onClick = XonoticServerListTab_refresh;
			e.onClickEntity = slist;
		me.TD(me, 1, 0.65, e = makeXonoticCheckBox_T(0, "net_slist_pause", _("Pause"),
			_("Pause updating the server list to prevent servers from \"jumping around\"")));

	me.gotoRC(me, 2, 0);
		me.TD(me, 1, 1, slist.sortButton1 = makeXonoticButton(string_null, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton2 = makeXonoticButton(string_null, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton3 = makeXonoticButton(string_null, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton4 = makeXonoticButton(string_null, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton5 = makeXonoticButton(string_null, '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 5, me.columns, slist);

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(0, _("Address:")));
		me.TD(me, 1, 2.9, e = makeXonoticInputBox(0, string_null));
			e.onEnter = ServerList_Connect_Click;
			e.onEnterEntity = slist;
			e.onChange = ServerList_Update_favoriteButton;
			e.onChangeEntity = slist;
			slist.ipAddressBox = e;
		me.TD(me, 1, 1.5, e = makeXonoticButton("", '0 0 0'));
			e.onClick = ServerList_Favorite_Click;
			e.onClickEntity = slist;
			slist.favoriteButton = e;
		me.TD(me, 1, 1.5, e = makeXonoticButton_T(_("Info..."), '0 0 0',
			_("Show more information about the currently highlighted server")));
			e.onClick = ServerList_Info_Click;
			e.onClickEntity = slist;
			slist.infoButton = e;
	me.TR(me);
		me.TD(me, 1, me.columns * 0.5, e = makeXonoticLeaveMatchButton('0 0 0', 0));
		me.TD(me, 1, me.columns * 0.5, e = makeXonoticButton(_("Join!"), '0 0 0'));
			e.onClick = ServerList_Connect_Click;
			e.onClickEntity = slist;
			slist.connectButton = e;
}
