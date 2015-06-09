#ifndef PRIVATE_SERVERLIST_H
#define PRIVATE_SERVERLIST_H
#include "listbox.qc"
CLASS(XonoticPrivateServerList, XonoticListBox)
	METHOD(XonoticPrivateServerList, configureXonoticPrivateServerList, void(entity))
//	ATTRIB(XonoticPrivateServerList, rowsPerItem, float, 1)
	METHOD(XonoticPrivateServerList, draw, void(entity))
	METHOD(XonoticPrivateServerList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticPrivateServerList, doubleClickListBoxItem, void(entity, float, vector))
	METHOD(XonoticPrivateServerList, resizeNotify, void(entity, vector, vector, vector, vector))
//	METHOD(XonoticPrivateServerList, keyDown, float(entity, float, float, float))

	ATTRIB(XonoticPrivateServerList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticPrivateServerList, realUpperMargin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnNicknameOrigin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnNicknameSize, float, 0)
	ATTRIB(XonoticPrivateServerList, columnAddressOrigin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnAddressSize, float, 0)

	ATTRIB(XonoticPrivateServerList, selectedServer, string, string_null) // to restore selected server when needed
	ATTRIB(XonoticPrivateServerList, selectedServerNickname, string, string_null) // to restore selected server when needed
	METHOD(XonoticPrivateServerList, setSelected, void(entity, float))
	METHOD(XonoticPrivateServerList, setSortOrder, void(entity, float, float))
//	ATTRIB(XonoticPrivateServerList, filterShowEmpty, float, 1)
//	ATTRIB(XonoticPrivateServerList, filterShowFull, float, 1)
//	ATTRIB(XonoticPrivateServerList, filterString, string, string_null)
//	ATTRIB(XonoticPrivateServerList, controlledTextbox, entity, NULL)

	ATTRIB(XonoticPrivateServerList, ipAddressBox, entity, NULL)
	ATTRIB(XonoticPrivateServerList, nicknameBox, entity, NULL)
	ATTRIB(XonoticPrivateServerList, addButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, updateButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, removeButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, connectButton, entity, NULL)

//	ATTRIB(XonoticPrivateServerList, nextRefreshTime, float, 0)
	METHOD(XonoticPrivateServerList, refreshPrivateServerList, void(entity, float)) // refresh mode: REFRESHSERVERLIST_*
//	ATTRIB(XonoticPrivateServerList, needsRefresh, float, 1)
//	METHOD(XonoticPrivateServerList, focusEnter, void(entity))

	METHOD(XonoticPrivateServerList, positionSortButton, void(entity, entity, float, float, string, void(entity, entity)))
	ATTRIB(XonoticPrivateServerList, sortButton1, entity, NULL)
	ATTRIB(XonoticPrivateServerList, sortButton2, entity, NULL)

	ATTRIB(XonoticPrivateServerList, currentSortOrder, float, 0)
	ATTRIB(XonoticPrivateServerList, currentSortField, float, -1)
//
	ATTRIB(XonoticPrivateServerList, ipAddressBoxFocused, float, -1)
	ATTRIB(XonoticPrivateServerList, nicknameBoxFocused, float, -1)
//
//	ATTRIB(XonoticPrivateServerList, seenIPv4, float, 0)
//	ATTRIB(XonoticPrivateServerList, seenIPv6, float, 0)
//	ATTRIB(XonoticPrivateServerList, categoriesHeight, float, 1.25)
//
//	METHOD(XonoticPrivateServerList, getTotalHeight, float(entity))
//	METHOD(XonoticPrivateServerList, getItemAtPos, float(entity, float))
//	METHOD(XonoticPrivateServerList, getItemStart, float(entity, float))
//	METHOD(XonoticPrivateServerList, getItemHeight, float(entity, float))
ENDCLASS(XonoticPrivateServerList)
entity makeXonoticPrivateServerList();

#ifndef IMPLEMENTATION

const float REFRESHPRIVATESERVERLIST_RESORT = 0;    // sort the PRIVATESERVER list again
const float REFRESHPRIVATESERVERLIST_REFILTER = 1;  // ..., also update filter and sort criteria

//// function declarations
float getPrivateServerCount();
string getPrivateServerInfoFromListByIndex(float idx, string key);
float findInPrivateServerListByAddress(string address); // returns index if found; or -1 if not; -2 if error
void removePrivateServerFromList(string address);
void addPrivateServerToList(string address, string nickname);

void PrivateServerList_Connect_Click(entity btn, entity me);
void PrivateServerList_Remove_Click(entity btn, entity me);
void PrivateServerList_Add_Click(entity btn, entity me);

#endif
#endif
#ifdef IMPLEMENTATION
float getPslistFieldIndex(string s)
{
	if (s == "Nickname")
		return 1;
	else if (s == "Address")
		return 2;
	else
		return 0;
}
//bool IsServerInList(string list, string srv)
//{
//	string p;
//	int i, n;
//	if(srv == "")
//		return false;
//	srv = netaddress_resolve(srv, 26000);
//	if(srv == "")
//		return false;
//	p = crypto_getidfp(srv);
//	n = tokenize_console(list);
//	for(i = 0; i < n; ++i)
//	{
//		if(substring(argv(i), 0, 1) != "[" && strlen(argv(i)) == 44 && strstrofs(argv(i), ".", 0) < 0)
//		{
//			if(p)
//				if(argv(i) == p)
//					return true;
//		}
//		else
//		{
//			if(srv == netaddress_resolve(argv(i), 26000))
//				return true;
//		}
//	}
//	return false;
//}
//
//int CheckCategoryOverride(int cat)
//{
//	entity catent = RetrieveCategoryEnt(cat);
//	if(catent)
//	{
//		int override = (autocvar_menu_slist_categories ? catent.cat_enoverride : catent.cat_dioverride);
//		if(override) { return override; }
//		else { return cat; }
//	}
//	else
//	{
//		error(sprintf("CheckCategoryOverride(%d): Improper category number!\n", cat));
//		return cat;
//	}
//}
entity makeXonoticPrivateServerList()
{
	entity me;
	me = NEW(XonoticPrivateServerList);
	me.configureXonoticPrivateServerList(me);
	return me;
}
void XonoticPrivateServerList_configureXonoticPrivateServerList(entity me)
{
	me.configureXonoticListBox(me);
	me.nItems = getPrivateServerCount();
}
void XonoticPrivateServerList_setSelected(entity me, int i)
{
	SUPER(XonoticPrivateServerList).setSelected(me, i);
	if(me.nItems == 0 || getPrivateServerCount() != me.nItems || i >= me.nItems)
		return;

	if(me.selectedServer)
		strunzone(me.selectedServer);

	me.selectedServer = strzone(getPrivateServerInfoFromListByIndex(i, "Address"));
	me.ipAddressBox.setText(me.ipAddressBox, me.selectedServer);
	me.ipAddressBox.cursorPos = strlen(me.selectedServer);
	me.ipAddressBoxFocused = -1;

	if(me.selectedServerNickname)
		strunzone(me.selectedServerNickname);

	me.selectedServerNickname = strzone(getPrivateServerInfoFromListByIndex(i, "Nickname"));
	me.nicknameBox.setText(me.nicknameBox, me.selectedServerNickname);
	me.nicknameBox.cursorPos = strlen(me.selectedServerNickname);
	me.nicknameBoxFocused = -1;

	//me.addButton.disabled = true;
	//me.updateButton.disabled = true;
}
//void XonoticPrivateServerList_focusEnter(entity me)
//{
//	SUPER(XonoticPrivateServerList).focusEnter(me);
//	if(time < me.nextRefreshTime)
//	{
//		//print("sorry, no refresh yet\n");
//		return;
//	}
//	me.nextRefreshTime = time + 10;
//	me.refreshPrivateServerList(me, REFRESHSERVERLIST_ASK);
//}
//
void XonoticPrivateServerList_draw(entity me)
{
	me.refreshPrivateServerList(me, REFRESHPRIVATESERVERLIST_RESORT);
	me.connectButton.disabled = (me.ipAddressBox.text == "");
	SUPER(XonoticPrivateServerList).draw(me);
}
void XonoticPrivateServerList_setSortOrder(entity me, int fld, int direction)
{
	if(me.currentSortField == fld)
		direction = -me.currentSortOrder;
	me.currentSortOrder = direction;
	me.currentSortField = fld;
	me.sortButton1.forcePressed = (fld == getPslistFieldIndex("Nickname"));
	me.sortButton2.forcePressed = (fld == getPslistFieldIndex("Address"));
	me.selectedItem = 0;
	if(me.selectedServer)
		strunzone(me.selectedServer);
	me.selectedServer = string_null;
	//me.refreshPrivateServerList(me, REFRESHSERVERLIST_REFILTER);
}
void XonoticPrivateServerList_refreshPrivateServerList(entity me, float mode)
{
	if (mode == REFRESHSERVERLIST_RESORT)
		me.nItems = getPrivateServerCount();
	// update selected
	if (me.selectedItem > me.nItems)
		me.selectedItem = me.nItems;
	me.setSelected(me, me.selectedItem);	
}
void XonoticPrivateServerList_positionSortButton(entity me, entity btn, float theOrigin, float theSize, string theTitle, void(entity, entity) theFunc)
{
	vector originInLBSpace, sizeInLBSpace;
	originInLBSpace = eY * (-me.itemHeight);
	sizeInLBSpace = eY * me.itemHeight + eX * (1 - me.controlWidth);

	vector originInDialogSpace, sizeInDialogSpace;
	originInDialogSpace = boxToGlobal(originInLBSpace, me.Container_origin, me.Container_size);
	sizeInDialogSpace = boxToGlobalSize(sizeInLBSpace, me.Container_size);

	btn.Container_origin_x = originInDialogSpace.x + sizeInDialogSpace.x * theOrigin;
	btn.Container_size_x   =                         sizeInDialogSpace.x * theSize;
	btn.setText(btn, theTitle);
	btn.onClick = theFunc;
	btn.onClickEntity = me;
	btn.resized = 1;
}
void PrivateServerList_NicknameSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, getPslistFieldIndex("Nickname"), +1);
}
void PrivateServerList_AddressSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, getPslistFieldIndex("Address"), +1);
}
void XonoticPrivateServerList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticPrivateServerList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnAddressSize = me.realFontSize.x * 22;
	me.columnNicknameSize = 1 - me.columnAddressSize - me.realFontSize.x * 2;
	me.columnNicknameOrigin = 0;
	me.columnAddressOrigin = me.columnNicknameOrigin + me.columnNicknameSize + me.realFontSize.x;

	me.positionSortButton(me, me.sortButton1, me.columnNicknameOrigin, me.columnNicknameSize, _("Nickname"), PrivateServerList_NicknameSort_Click);
	me.positionSortButton(me, me.sortButton2, me.columnAddressOrigin, me.columnAddressSize, _("Address"), PrivateServerList_AddressSort_Click);

	int f = me.currentSortField;
	if(f >= 0) {
		me.currentSortField = -1;
		me.setSortOrder(me, f, me.currentSortOrder); // force resetting the sort order
	}
}
void PrivateServerList_Connect_Click(entity btn, entity me)
{
	localcmd(sprintf("connect %s\n",
		((me.ipAddressBox.text != "") ?
			me.ipAddressBox.text : me.selectedServer
		)
	));
}
void PrivateServerList_Remove_Click(entity btn, entity me)
{
	if (me.nItems == 0 || me.ipAddressBox.text == "")
		return;
	removePrivateServerFromList(me.ipAddressBox.text);
}
void PrivateServerList_Add_Click(entity btn, entity me)
{
	if (me.ipAddressBox.text == "" || me.nicknameBox.text == "")
		return;
	addPrivateServerToList(me.ipAddressBox.text, me.nicknameBox.text);
}
void XonoticPrivateServerList_doubleClickListBoxItem(entity me, int i, vector where)
{
	PrivateServerList_Connect_Click(NULL, me);
}
void XonoticPrivateServerList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected)
{
	vector theColor;
	float theAlpha;
	string s, nickname, address;

	theAlpha = 1;
	theColor = SKINCOLOR_SERVERLIST_FAVORITE;

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	// layout: Nickname, Address:Port
	
	nickname = getPrivateServerInfoFromListByIndex(i, "Nickname");
	s = draw_TextShortenToWidth(nickname, me.columnNicknameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNicknameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);

	address = getPrivateServerInfoFromListByIndex(i, "Address");
	s = draw_TextShortenToWidth(address, me.columnAddressSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnAddressOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);

}

// functions to manipulate net_private_server_list, which has the format:
// 192.168.1.50:20006,Server name and descripiton delimited by backslash\[FE80:0000:0000:0000:0202:B3FF:FE1E:8329]:26001,another server
float getPrivateServerCount()
{
	float count;
	string ps = cvar_string("net_private_server_list");
	count = tokenizebyseparator(ps, "\\");
	return count;
}
string getPrivateServerInfoFromListByIndex(float idx, string key)
{
	float count;
	string pss = cvar_string("net_private_server_list"); // private servers string
	count = tokenizebyseparator(pss, "\\");
	string ps1; // one server from private servers string
	float delimiter_pos;

	if (idx < 0 || idx > count) {
		return "";
	} else {
		ps1 = argv(idx);
		// the first comma is used to separate the server address and nickname
		delimiter_pos = strstrofs(ps1, ",", 0);
		if (delimiter_pos == -1) {
			return "";
		}

		if (key == "Address") {
			return substring(ps1, 0, delimiter_pos);	
		} else if (key == "Nickname") {
			return substring(ps1, delimiter_pos+1, strlen(ps1)-delimiter_pos-1);
		} else if (key == "All") {
			return ps1;
		} else {
			return "";
		}
	}
}
float findInPrivateServerListByAddress(string address)
{
	float count, i;
	if (address == "")
		return -2;
	address = strtolower(address);
	count = getPrivateServerCount();
	// TOOD consider compare after resolving
	//string resolved = netaddress_resolve(address, port);
	for (i = 0; i < count; i++) {
		if (address == strtolower(getPrivateServerInfoFromListByIndex(i, "Address"))) {
			return i;
		}
	}
	return -1;
}
void removePrivateServerFromList(string address)
{
	float count, i, searchIdx;
	string newList = "";

	if (address == "") {
		return;
	}

	address = strtolower(address);
	searchIdx = findInPrivateServerListByAddress(address);
	if (searchIdx < 0) {
		return;
	}

	string pss = cvar_string("net_private_server_list"); // private servers string
	count = tokenizebyseparator(pss, "\\");
	for (i = 0; i < count; i++) {
		if (i == searchIdx) {
			// this item is the one to remove; skip it
			continue;
		} else {
			// otherwise keep it in the list
			if (strlen(newList) == 0) {
				newList = argv(i);
			} else {
				newList = strcat(newList, "\\", argv(i));
			}
		}
	}
	localcmd(sprintf("seta net_private_server_list \"%s\"", MakeConsoleSafe(newList)));
	return;
}
void addPrivateServerToList(string address, string nickname)
{
	string newServer = "";
	string pss = cvar_string("net_private_server_list"); // private servers string

	if (findInPrivateServerListByAddress(address) >= 0) {
		// this shouldn't happen since the button should've been disabled when there's a match
		return;
	}

	newServer = sprintf("%s,%s", address, nickname);
	// sanitize address and nickname
	newServer = strreplace("\n", " ", newServer);
	newServer = strreplace("\\", "/", newServer);
    newServer = strreplace(";", ".", newServer);
	
	if (strlen(pss) == 0) {
		pss = newServer;
	} else {
		pss = strcat(pss, "\\", newServer);
	}
	// TODO is there a length limit with cvar?
	localcmd(sprintf("seta net_private_server_list \"%s\"", MakeConsoleSafe(pss)));
	return;
}

#endif
