#ifndef DIALOG_MULTIPLAYER_JOIN_PRIVATE_H
#define DIALOG_MULTIPLAYER_JOIN_PRIVATE_H
#include "tab.qc"
CLASS(XonoticPrivateServerListTab, XonoticTab)
	METHOD(XonoticPrivateServerListTab, fill, void(entity))
	ATTRIB(XonoticPrivateServerListTab, title, string, _("Private"))
	ATTRIB(XonoticPrivateServerListTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticPrivateServerListTab, rows, float, 21)
	ATTRIB(XonoticPrivateServerListTab, columns, float, 6.5)
ENDCLASS(XonoticPrivateServerListTab)
entity makeXonoticPrivateServerListTab();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticPrivateServerListTab()
{
	entity me;
	me = NEW(XonoticPrivateServerListTab);
	me.configureDialog(me);
	return me;
}
void XonoticPrivateServerListTab_fill(entity me)
{
	entity e, pslist;

	pslist  = makeXonoticPrivateServerList();

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, me.columns - 0.6, e = makeXonoticInputBox(0, string_null));
			e.onChange = PrivateServerList_Filter_Change;
			e.onChangeEntity = pslist;
			pslist.filterTextbox = e;

	me.gotoRC(me, 2, 0);
		me.TD(me, 1, 1, pslist.sortButtonNickname = makeXonoticButton("Nickname", '0 0 0'));
		me.TD(me, 1, 1, pslist.sortButtonAddress = makeXonoticButton("Address", '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 7, me.columns, pslist);

	me.gotoRC(me, me.rows - 4, 0);
		me.TD(me, 1, 0.4, e = makeXonoticTextLabel(0, _("Nickname:")));
		me.TD(me, 1, me.columns - 0.4, e = makeXonoticInputBox(0, string_null));
			e.onEnter = PrivateServerList_Connect_Click;
			e.onEnterEntity = pslist;
			e.onChange = PrivateServerList_onAddressNicknameBoxChange;
			e.onChangeEntity = pslist;
			pslist.nicknameBox = e;
	me.TR(me);
		me.TD(me, 1, 0.4, e = makeXonoticTextLabel(0, _("Address:")));
		me.TD(me, 1, me.columns - 0.4, e = makeXonoticInputBox(0, string_null));
			e.onEnter = PrivateServerList_Connect_Click;
			e.onEnterEntity = pslist;
			e.onChange = PrivateServerList_onAddressNicknameBoxChange;
			e.onChangeEntity = pslist;
			pslist.addressBox = e;
	me.TR(me);
		me.TD(me, 1, 2.16, e = makeXonoticButton("Add", '0 0 0'));
			e.onClick = PrivateServerList_Add_Click;
			e.onClickEntity = pslist;
			pslist.addButton = e;
		me.TD(me, 1, 2.16, e = makeXonoticButton(_("Update"), '0 0 0'));
			e.onClick = PrivateServerList_Update_Click;
			e.onClickEntity = pslist;
			pslist.updateButton = e;
		me.TD(me, 1, 2.16, e = makeXonoticButton("Remove", '0 0 0'));
			e.onClick = PrivateServerList_Remove_Click;
			e.onClickEntity = pslist;
			pslist.removeButton = e;
		me.TDempty(me, 0.02);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Join!"), '0 0 0'));
			e.onClick = PrivateServerList_Connect_Click;
			e.onClickEntity = pslist;
			pslist.connectButton = e;
}
#endif
