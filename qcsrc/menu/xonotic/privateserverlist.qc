#ifndef PRIVATE_SERVERLIST_H
#define PRIVATE_SERVERLIST_H
#include "listbox.qc"
CLASS(XonoticPrivateServerList, XonoticListBox)
	METHOD(XonoticPrivateServerList, configureXonoticPrivateServerList, void(entity))
	METHOD(XonoticPrivateServerList, destroy, void(entity))

	METHOD(XonoticPrivateServerList, draw, void(entity))
	METHOD(XonoticPrivateServerList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticPrivateServerList, clickListBoxItem, void(entity, float, vector))
	METHOD(XonoticPrivateServerList, doubleClickListBoxItem, void(entity, float, vector))
	METHOD(XonoticPrivateServerList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticPrivateServerList, keyDown, bool(entity, int, bool, bool))

	ATTRIB(XonoticPrivateServerList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticPrivateServerList, realUpperMargin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnNicknameOrigin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnNicknameSize, float, 0)
	ATTRIB(XonoticPrivateServerList, columnAddressOrigin, float, 0)
	ATTRIB(XonoticPrivateServerList, columnAddressSize, float, 0)

	METHOD(XonoticPrivateServerList, setSelected, void(entity, float))
	ATTRIB(XonoticPrivateServerList, selectedServerIndex, float, 0)
	ATTRIB(XonoticPrivateServerList, selectedServerAddress, string, string_null)
	ATTRIB(XonoticPrivateServerList, selectedServerNickname, string, string_null)

	ATTRIB(XonoticPrivateServerList, filterBox, entity, NULL)
	ATTRIB(XonoticPrivateServerList, addressBox, entity, NULL)
	ATTRIB(XonoticPrivateServerList, nicknameBox, entity, NULL)
	ATTRIB(XonoticPrivateServerList, addressNicknameBoxTrashable, float, 1)
	ATTRIB(XonoticPrivateServerList, addButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, updateButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, removeButton, entity, NULL)
	ATTRIB(XonoticPrivateServerList, connectButton, entity, NULL)

	METHOD(XonoticPrivateServerList, refreshPrivateServerList, void(entity, string))

	METHOD(XonoticPrivateServerList, positionSortButton, void(entity, entity, float, float, string, void(entity, entity)))
	ATTRIB(XonoticPrivateServerList, sortButtonNickname, entity, NULL)
	ATTRIB(XonoticPrivateServerList, sortButtonAddress, entity, NULL)

ENDCLASS(XonoticPrivateServerList)
entity makeXonoticPrivateServerList();

#ifndef IMPLEMENTATION

// variables, function declarations

float privateServers_complete = -1;
float privateServers_complete_allocated = 0;
float privateServers_filtered = -1;
float privateServers_filtered_allocated = 0;

void privateServerList_cvar_load(float buf);
void privateServerList_cvar_save(float buf);

// sorting and helper functions
string sortOrder;
string sortField;
void privateServers_filtered_sort(string sort_field, string sort_order);
void _privateServers_filtered_swap(float i, float j, entity pass);
float _privateServers_filtered_cmp_by_address_asc(float i, float j, entity pass);
float _privateServers_filtered_cmp_by_address_desc(float i, float j, entity pass);
float _privateServers_filtered_cmp_by_nickname_asc(float i, float j, entity pass);
float _privateServers_filtered_cmp_by_nickname_desc(float i, float j, entity pass);

string makePrivateServerString(string address, string nickname);
string parsePrivateServerString(string s, string key);

float privateServers_complete_findByAddress(string address); // returns index if found; or -1 if not; -2 if address is empty
float privateServers_filtered_findByAddress(string address); // returns index if found; or -1 if not; -2 if address is empty
float _privateServers_buf_findByAddress(string address, float buf);

void addPrivateServerToList(string address, string nickname);
void updatePrivateServerInList(string address, string nickname);
void removePrivateServerFromList(string address);

void PrivateServerList_Connect_Click(entity btn, entity me);
void PrivateServerList_Add_Click(entity btn, entity me);
void PrivateServerList_Update_Click(entity btn, entity me);
void PrivateServerList_Remove_Click(entity btn, entity me);
void PrivateServerList_onAddressNicknameBoxChange(entity box, entity me);
void PrivateServerList_onFilterBoxChange(entity box, entity me);
void _PrivateServerList_Filter_Switch(entity box, entity me, bool enbled);
void PrivateServerList_sortButtonClick(entity btn, entity me);

#endif
#endif
#ifdef IMPLEMENTATION
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

	if(sortField)
		strunzone(sortField);
	sortField = strzone("Nickname");

	if(sortOrder)
		strunzone(sortOrder);
	sortOrder = strzone("asc");

	if (privateServers_complete_allocated) {
		buf_del(privateServers_complete);
	}
	privateServers_complete = buf_create();
	privateServers_complete_allocated = 1;

	if (privateServers_filtered_allocated) {
		buf_del(privateServers_complete_allocated);
	}
	privateServers_filtered = buf_create();
	privateServers_filtered_allocated = 1;

	privateServerList_cvar_load(privateServers_complete);	
	// buf_copy doesn't work (darkplaces bug?) so we just create it again
	privateServerList_cvar_load(privateServers_filtered);	
	me.nItems = buf_getsize(privateServers_filtered);
}
void XonoticPrivateServerList_destroy(entity me)
{
	if (privateServers_complete_allocated) {
		buf_del(privateServers_complete);
	}
	if (privateServers_filtered_allocated) {
		buf_del(privateServers_filtered);
	}
}

float getPslistFieldIndex(string s)
{
	if (s == "Nickname")
		return 1;
	else if (s == "Address")
		return 2;
	else
		return 0;
}
void XonoticPrivateServerList_setSelected(entity me, int i)
{
	if (me.nItems == 0 || me.nItems != buf_getsize(privateServers_filtered) || i > me.nItems-1)
		return;
	// during editing
	if (me.addressBox.focused || me.nicknameBox.focused)
		return;

	me.selectedServerIndex = i;

	if(me.selectedServerAddress)
		strunzone(me.selectedServerAddress);
	me.selectedServerAddress = strzone(parsePrivateServerString(bufstr_get(privateServers_filtered, i), "Address"));

	if(me.selectedServerNickname)
		strunzone(me.selectedServerNickname);
	me.selectedServerNickname = strzone(parsePrivateServerString(bufstr_get(privateServers_filtered, i), "Nickname"));

	if (me.addressNicknameBoxTrashable) {
		me.addressBox.setText(me.addressBox, me.selectedServerAddress);
		me.addressBox.cursorPos = strlen(me.selectedServerAddress);
		me.addressBox.focused = 0;

		me.nicknameBox.setText(me.nicknameBox, me.selectedServerNickname);
		me.nicknameBox.cursorPos = strlen(me.selectedServerNickname);
		me.nicknameBox.focused = 0;

		// we just copied the address and nickname, so there shouldn't be any ADD/UPDATE available
		me.addButton.disabled = true;
		me.updateButton.disabled = true;
		me.removeButton.disabled = false;

		_PrivateServerList_Filter_Switch(me.filterBox, me, true);
	}
	SUPER(XonoticPrivateServerList).setSelected(me, i);
}
void XonoticPrivateServerList_draw(entity me)
{
	me.refreshPrivateServerList(me, me.selectedServerAddress);
	me.connectButton.disabled = (me.addressBox.text == "");
	SUPER(XonoticPrivateServerList).draw(me);
}
void XonoticPrivateServerList_refreshPrivateServerList(entity me, string addressToSelect)
{
	me.nItems = buf_getsize(privateServers_filtered);
	me.selectedItem = privateServers_filtered_findByAddress(addressToSelect);	
	
	if (me.selectedItem < 0) {
		me.selectedItem = 0;
	}
	me.setSelected(me, me.selectedItem);
}
void PrivateServerList_onAddressNicknameBoxChange(entity box, entity me)
{
	if (me.addressBox.text == me.selectedServerAddress) {
		// address is the same as the selected server; no adding duplicated record allowed
		me.addButton.disabled = true;
		// the record is in this list shown, the filter is fine; leave it on
		_PrivateServerList_Filter_Switch(me.filterBox, me, true);
		// now check the nickname
		if (me.nicknameBox.text == me.selectedServerNickname) {
			// the nickname is also the same, no point to update
			me.updateButton.disabled = true;
			me.removeButton.disabled = false;
			me.addressNicknameBoxTrashable = 1;
		} else {
			// the nickname is different, allow update
			me.updateButton.disabled = false;
			me.removeButton.disabled = true;
			me.addressNicknameBoxTrashable = 0;
		}
	} else {
		// user provides an address
		me.addressNicknameBoxTrashable = 0;
		// disable REMOVE button, to avoid confusion or what's actually being deleted
		me.removeButton.disabled = true;
		// check whether it's the same as other server in the list
		float index = privateServers_filtered_findByAddress(me.addressBox.text);
		if (index >= 0) {
			// this address already exists; no ADD, but allow UPDATE
			me.addButton.disabled = true;
			me.updateButton.disabled = false;
			// since the record is in this list shown, the filter is fine
			_PrivateServerList_Filter_Switch(me.filterBox, me, true);
			// move cursor to the existing server, but leave the textboxes alone
			if(me.selectedServerAddress)
				strunzone(me.selectedServerAddress);
			me.selectedServerAddress = strzone(me.addressBox.text);
			if(me.selectedServerNickname)
				strunzone(me.selectedServerNickname);
			me.selectedServerNickname = strzone(me.nicknameBox.text);
			SUPER(XonoticPrivateServerList).setSelected(me, index);
		} else {
			// this address is new, allow ADD
			me.addButton.disabled = false;
			me.updateButton.disabled = true;
			// check whether it's in the complete list
			float index2 = privateServers_complete_findByAddress(me.addressBox.text);
			if (index2 >= 0) {
				// the big list has it; disable the filter to show all servers
				// so users can see the server being updated
				_PrivateServerList_Filter_Switch(me.filterBox, me, false);
				// move cursor to the existing server
				if(me.selectedServerAddress)
					strunzone(me.selectedServerAddress);
				me.selectedServerAddress = strzone(me.addressBox.text);
				if(me.selectedServerNickname)
					strunzone(me.selectedServerNickname);
				me.selectedServerNickname = strzone(me.nicknameBox.text);
				SUPER(XonoticPrivateServerList).setSelected(me, index);
			} else {
				// the big list doesn't have it, no need to change the filter
				;
			}
		}
	}
}
void _PrivateServerList_Filter_Switch(entity box, entity me, bool enabled)
{
	if (box.disabled == !enabled) {
		return;
	}
	me.filterBox.disabled = !enabled;

	// We can toggle Filter Switch without erasing user's filterString.
	// However, it could be confusing for users when it turns back on.
	// To avoid that, we delete FilterString altogether.
	if (box.disabled) {
		box.setText(box, "");
		box.disabled = false;
	}

	PrivateServerList_onFilterBoxChange(box, me);
}
void PrivateServerList_onFilterBoxChange(entity box, entity me)
{
	// throw away the old copy and rebuild a new one
	if (privateServers_filtered_allocated) {
		buf_del(privateServers_filtered);
	}
	privateServers_filtered = buf_create();
	privateServers_filtered_allocated = 1;

	// if the filterString is empty (or box disabled), just copy the whole list
	if (box.text == "" || box.disabled) {
		// buf_copy doesn't work; darkplaces bug?
		//buf_copy(privateServers_complete, privateServers_filtered);
		privateServerList_cvar_load(privateServers_filtered);	
	} else {
		// otherwise filter through the whole list
		float size = buf_getsize(privateServers_complete);
		string serverString;
		string filterString = strtolower(box.text);
		for (float i = 0; i < size; i++) {
			serverString = bufstr_get(privateServers_complete, i);
			if (strstrofs(strtolower(parsePrivateServerString(serverString, "Address")), filterString, 0) >= 0
				|| strstrofs(strtolower(parsePrivateServerString(serverString, "Nickname")), filterString, 0) >= 0
			) {
				bufstr_add(privateServers_filtered, serverString, true);
			}
		}
	}
	me.refreshPrivateServerList(me, me.selectedServerAddress);
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
void PrivateServerList_sortButtonClick(entity btn, entity me)
{
	if (btn.text == sortField) {
		// user clicked the same field button, flip sortOrder
		if (sortOrder == "desc") {
			strunzone(sortOrder);
			sortOrder = strzone("asc");
		} else {
			strunzone(sortOrder);
			sortOrder = strzone("desc");
		}
	} else {
		// user changes the sort field
		strunzone(sortOrder);
		sortOrder = strzone("asc");
		strunzone(sortField);
		sortOrder = strzone(btn.text);
	}
	privateServers_filtered_sort(sortField, sortOrder);
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

	me.positionSortButton(me, me.sortButtonNickname, me.columnNicknameOrigin, me.columnNicknameSize, _("Nickname"), PrivateServerList_sortButtonClick);
	me.positionSortButton(me, me.sortButtonAddress, me.columnAddressOrigin, me.columnAddressSize, _("Address"), PrivateServerList_sortButtonClick);

}
bool XonoticPrivateServerList_keyDown(entity me, int scan, bool ascii, bool shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER) {
		ServerList_Connect_Click(NULL, me);
		return true;
	} else if(scan == K_INS || scan == K_MOUSE3 || scan == K_KP_INS) {
		// add new
		me.addressBox.setText(me.addressBox, "");
		me.addressBox.cursorPos = 0;
		me.nicknameBox.setText(me.nicknameBox, "");
		me.nicknameBox.cursorPos = 0;
		me.addressBox.focused = 1;
		return false;
	} else {
		me.addressNicknameBoxTrashable = 1;
		if(SUPER(XonoticServerList).keyDown(me, scan, ascii, shift))
			return true;
		else if(!me.filterBox)
			return false;
		else
			return me.filterBox.keyDown(me.filterBox, scan, ascii, shift);
	}

}
void PrivateServerList_Connect_Click(entity btn, entity me)
{
	localcmd(sprintf("connect %s\n",
		((me.addressBox.text != "") ?
			me.addressBox.text : me.selectedServerAddress
		)
	));
}
void PrivateServerList_Add_Click(entity btn, entity me)
{
	if (me.addressBox.text == "" || me.nicknameBox.text == "")
		return;
	addPrivateServerToList(me.addressBox.text, me.nicknameBox.text);
	me.addressNicknameBoxTrashable = 1;
	me.refreshPrivateServerList(me, me.addressBox.text);
}
void PrivateServerList_Update_Click(entity btn, entity me)
{
	if (me.addressBox.text == "" || me.nicknameBox.text == "")
		return;
	updatePrivateServerInList(me.addressBox.text, me.nicknameBox.text);
	me.addressNicknameBoxTrashable = 1;
	me.refreshPrivateServerList(me, me.addressBox.text);
	PrivateServerList_onFilterBoxChange(me.filterBox, me);
}
void PrivateServerList_Remove_Click(entity btn, entity me)
{
	if (me.nItems == 0 || me.addressBox.text == "")
		return;
	// remember the NEXT server to move cursor to, after removing this server
	string address = "";
	if (me.selectedServerIndex+1 < me.nItems) {
		address = parsePrivateServerString(bufstr_get(privateServers_filtered, me.selectedServerIndex+1), "Address");
	}
	// now remove the server from the list
	removePrivateServerFromList(me.addressBox.text);
	me.addressNicknameBoxTrashable = 1;
	me.refreshPrivateServerList(me, address);
}
void XonoticPrivateServerList_clickListBoxItem(entity me, int i, vector where)
{
	me.addressNicknameBoxTrashable = 1;
	SUPER(XonoticPrivateServerList).clickListBoxItem(me, i, where);
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

	string ps = bufstr_get(privateServers_filtered, i);

	nickname = parsePrivateServerString(ps, "Nickname");
	s = draw_TextShortenToWidth(nickname, me.columnNicknameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNicknameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);

	address = parsePrivateServerString(ps, "Address");
	s = draw_TextShortenToWidth(address, me.columnAddressSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnAddressOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

// functions to manipulate net_private_server_list, which has the format:
// 192.168.1.50:20006,Server name and descripiton delimited by backslash\[FE80:0000:0000:0000:0202:B3FF:FE1E:8329]:26001,another server
void privateServerList_cvar_load(float buf)
{
	float count, i;

	// empty it
	for (i = buf_getsize(buf)-1; i>=0; i--)
		bufstr_free(buf, i);

	string cvar = cvar_string("net_private_server_list");
	count = tokenizebyseparator(cvar, "\\");
	for (i = 0; i < count; i++) {
		if (argv(i)) {
			bufstr_add(buf, argv(i), true);
		}
	}
	privateServers_filtered_sort(sortField, sortOrder);	
}
void privateServerList_cvar_save(float buf)
{
	// TODO is there a length limit with cvar? If so, consider using a file instead
	string psl = buf_implode(buf, "\\");
	// implode adds leading \ to the result, weird!
	float length = strlen(psl);
	float i = 0;
	while (i < length && substring(psl, i, 1) == "\\")
		i++;
	psl = substring(psl, i, length - i);
	cvar_set("net_private_server_list", psl);
}
void privateServers_filtered_sort(string sort_field, string sort_order)
{
	if (sort_field == "Address") {
		if (sort_order == "desc") {
			heapsort(buf_getsize(privateServers_filtered), _privateServers_filtered_swap, _privateServers_filtered_cmp_by_address_desc, world);
		} else {	
			heapsort(buf_getsize(privateServers_filtered), _privateServers_filtered_swap, _privateServers_filtered_cmp_by_address_asc, world);
		}
	} else {
		if (sort_order == "desc") {
			heapsort(buf_getsize(privateServers_filtered), _privateServers_filtered_swap, _privateServers_filtered_cmp_by_nickname_desc, world);
		} else {
			heapsort(buf_getsize(privateServers_filtered), _privateServers_filtered_swap, _privateServers_filtered_cmp_by_nickname_asc, world);
		}
	}
}
void _privateServers_filtered_swap(float i, float j, entity pass)
{
	string h;
	h = bufstr_get(privateServers_filtered, i);
	bufstr_set(privateServers_filtered, i, bufstr_get(privateServers_filtered, j));
	bufstr_set(privateServers_filtered, j, h);
}
float _privateServers_filtered_cmp_by_address_asc(float i, float j, entity pass)
{
	string a, b;
	a = parsePrivateServerString(bufstr_get(privateServers_filtered, i), "Address");
	b = parsePrivateServerString(bufstr_get(privateServers_filtered, j), "Address");
	return strcasecmp(a, b);
}
float _privateServers_filtered_cmp_by_address_desc(float i, float j, entity pass)
{
	return _privateServers_filtered_cmp_by_address_asc(i,j,pass)*-1;
}
float _privateServers_filtered_cmp_by_nickname_asc(float i, float j, entity pass)
{
	string a, b;
	a = parsePrivateServerString(bufstr_get(privateServers_filtered, i), "Nickname");
	b = parsePrivateServerString(bufstr_get(privateServers_filtered, j), "Nickname");
	return strcasecmp(a, b);
}
float _privateServers_filtered_cmp_by_nickname_desc(float i, float j, entity pass)
{
	return _privateServers_filtered_cmp_by_nickname_asc(i,j,pass)*-1;
}

float privateServers_complete_findByAddress(string address)
{
	return _privateServers_buf_findByAddress(address, privateServers_complete);
}
float privateServers_filtered_findByAddress(string address)
{
	return _privateServers_buf_findByAddress(address, privateServers_filtered);
}
float _privateServers_buf_findByAddress(string address, float buf)
{
	float count, i;
	if (address == "")
		return -2;
	count = buf_getsize(buf);
	for (i = 0; i < count; i++)
		if (0 == strcasecmp(address, parsePrivateServerString(bufstr_get(buf, i), "Address")))
			return i;
	return -1;
}
string parsePrivateServerString(string s, string key)
{
	// the first comma is used to separate the server address and nickname
	float delimiter_pos = strstrofs(s, ",", 0);
	if (delimiter_pos == -1) {
		return "";
	}

	if (key == "Address") {
		return substring(s, 0, delimiter_pos);	
	} else if (key == "Nickname") {
		return substring(s, delimiter_pos+1, strlen(s)-delimiter_pos-1);
	} else if (key == "All") {
		return s;
	} else {
		return "";
	}
}
string makePrivateServerString(string address, string nickname)
{
	string newServer = sprintf("%s,%s", address, nickname);
	// sanitize address and nickname
	newServer = strreplace("\n", " ", newServer);
	newServer = strreplace("\\", "/", newServer);
    newServer = strreplace(";", ".", newServer);
	return newServer;
}
void addPrivateServerToList(string address, string nickname)
{
	if (address == "" || privateServers_complete_findByAddress(address) >= 0) {
		// this shouldn't happen since the button should've been disabled when there's a match
		return;
	}
	bufstr_add(privateServers_complete, makePrivateServerString(address, nickname), true);
	privateServerList_cvar_save(privateServers_complete); 
	privateServerList_cvar_load(privateServers_filtered);
	// move the added server to the right place
	privateServers_filtered_sort(sortField, sortOrder);	
}
void updatePrivateServerInList(string address, string nickname)
{
	if (address == "") {
		return;
	}
	float searchIdx = privateServers_complete_findByAddress(address);
	if (searchIdx < 0) {
		return;
	}
	bufstr_set(privateServers_complete, searchIdx, makePrivateServerString(address, nickname));
	privateServerList_cvar_save(privateServers_complete);
	privateServerList_cvar_load(privateServers_filtered);
}
void removePrivateServerFromList(string address)
{
	if (address == "") {
		return;
	}
	float searchIdx = privateServers_complete_findByAddress(address);
	if (searchIdx < 0) {
		return;
	}
	// create a new buf to hold the new contents
	float temp_buf = buf_create();
	float count = buf_getsize(privateServers_complete);
	for (float i = 0; i < count; i++) {
		// copy everything but one
		if (i != searchIdx) {
			bufstr_add(temp_buf, bufstr_get(privateServers_complete, i), true);
		}
	}
	// now we replace the old buf with this new one
	buf_del(privateServers_complete);
	privateServers_complete = temp_buf;
	privateServerList_cvar_save(privateServers_complete);
	privateServerList_cvar_load(privateServers_filtered);
}
#endif
