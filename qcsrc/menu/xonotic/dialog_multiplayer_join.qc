#ifndef DIALOG_MULTIPLAYER_JOIN_H
#define DIALOG_MULTIPLAYER_JOIN_H
#include "tab.qc"
CLASS(XonoticServerListTab, XonoticTab)
	METHOD(XonoticServerListTab, fill, void(entity));
	ATTRIB(XonoticServerListTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticServerListTab, rows, float, 23)
	ATTRIB(XonoticServerListTab, columns, float, 6.5)
ENDCLASS(XonoticServerListTab)
entity makeXonoticServerListTab();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticServerListTab()
{
	entity me;
	me = NEW(XonoticServerListTab);
	me.configureDialog(me);
	return me;
}
void XonoticServerListTab_fill(entity me)
{
	entity e, slist;

	slist  = makeXonoticServerList();

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, 2.8, e = makeXonoticInputBox(0, string_null));
			e.onChange = ServerList_Filter_Change;
			e.onChangeEntity = slist;
			slist.controlledTextbox = e;

	me.gotoRC(me, 0.5, 3.6);
		me.TD(me, 1, 0.9, e = makeXonoticCheckBox(0, "menu_slist_categories", ZCTX(_("SRVS^Categories"))));
			e.onClickEntity = slist;
			e.onClick = ServerList_Categories_Click;
		me.TD(me, 1, 0.6, e = makeXonoticCheckBox(0, "menu_slist_showempty", ZCTX(_("SRVS^Empty"))));
			slist.filterShowEmpty = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowEmpty_Click;
		me.TD(me, 1, 0.6, e = makeXonoticCheckBox(0, "menu_slist_showfull", ZCTX(_("SRVS^Full"))));
			slist.filterShowFull = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowFull_Click;
		me.TD(me, 1, 0.6, e = makeXonoticCheckBox(0, "net_slist_pause", _("Pause")));

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
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Info..."), '0 0 0'));
			e.onClick = ServerList_Info_Click;
			e.onClickEntity = slist;
			slist.infoButton = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Join!"), '0 0 0'));
			e.onClick = ServerList_Connect_Click;
			e.onClickEntity = slist;
			slist.connectButton = e;
}
#endif
