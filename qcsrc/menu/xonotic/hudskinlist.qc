#ifndef HUDSKINLIST_H
#define HUDSKINLIST_H
#include "listbox.qc"
CLASS(XonoticHUDSkinList, XonoticListBox)
	METHOD(XonoticHUDSkinList, configureXonoticHUDSkinList, void(entity));
	ATTRIB(XonoticHUDSkinList, rowsPerItem, float, 1)
	METHOD(XonoticHUDSkinList, resizeNotify, void(entity, vector, vector, vector, vector));
	METHOD(XonoticHUDSkinList, draw, void(entity));
	METHOD(XonoticHUDSkinList, drawListBoxItem, void(entity, int, vector, bool, bool));
	METHOD(XonoticHUDSkinList, getHUDSkins, void(entity));
	METHOD(XonoticHUDSkinList, setHUDSkin, void(entity));
	METHOD(XonoticHUDSkinList, hudskinName, string(entity, float));
	METHOD(XonoticHUDSkinList, hudskinPath, string(entity, float));
	METHOD(XonoticHUDSkinList, doubleClickListBoxItem, void(entity, float, vector));
	METHOD(XonoticHUDSkinList, keyDown, float(entity, float, float, float));
	METHOD(XonoticHUDSkinList, destroy, void(entity));
	METHOD(XonoticHUDSkinList, showNotify, void(entity));

	ATTRIB(XonoticHUDSkinList, listHUDSkin, float, -1)
	ATTRIB(XonoticHUDSkinList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticHUDSkinList, columnNameOrigin, float, 0)
	ATTRIB(XonoticHUDSkinList, columnNameSize, float, 0)
	ATTRIB(XonoticHUDSkinList, realUpperMargin, float, 0)
	ATTRIB(XonoticHUDSkinList, origin, vector, '0 0 0')
	ATTRIB(XonoticHUDSkinList, itemAbsSize, vector, '0 0 0')

	ATTRIB(XonoticHUDSkinList, filterString, string, string_null)
	ATTRIB(XonoticHUDSkinList, delayedRefreshTime, float, 0)
ENDCLASS(XonoticHUDSkinList)

#ifndef IMPLEMENTATION
// public:
entity hudskinlist;
entity makeXonoticHUDSkinList();
void SaveHUDSkin_Click(entity btn, entity me);
void SetHUDSkin_Click(entity btn, entity me);
#endif
void HUDSkinList_Refresh_Click(entity btn, entity me);
void HUDSkinList_Filter_Change(entity box, entity me);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticHUDSkinList()
{
	entity me;
	me = NEW(XonoticHUDSkinList);
	me.configureXonoticHUDSkinList(me);
	return me;
}

void XonoticHUDSkinList_configureXonoticHUDSkinList(entity me)
{
	me.configureXonoticListBox(me);
	me.getHUDSkins(me);
}

const float HUDSKINPARM_NAME = 0;
const float HUDSKINPARM_PATH = 1;
const float HUDSKINPARM_COUNT = 2;
string XonoticHUDSkinList_hudskinName(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_NAME);
}
string XonoticHUDSkinList_hudskinPath(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_PATH);
}

void getAllHUDSkins(entity me, string subdir)
{
	string s;
	if(me.filterString)
		s = me.filterString;
	else
		s = "*";
	s = strcat(subdir, "hud_", s, ".cfg");
	float strlen_subdir = strlen(subdir);
	string zoned_subdir = strzone(subdir);

	float list, i, n;
	list = search_begin(s, false, true);
	if(list >= 0)
	{
		n = search_getsize(list);
		int bufsize = buf_getsize(me.listHUDSkin);
		for(i = 0; i < n; ++i)
		{
			bufstr_set(me.listHUDSkin, bufsize + i * HUDSKINPARM_COUNT + HUDSKINPARM_PATH, zoned_subdir);
			s = search_getfilename(list, i); // get initial full file name
			s = substring(s, strlen_subdir + 4, (strlen(s) - strlen_subdir - 4 - 4)); // remove "hud_" prefix and ".cfg" suffix
			bufstr_set(me.listHUDSkin, bufsize + i * HUDSKINPARM_COUNT + HUDSKINPARM_NAME, s);
		}
		search_end(list);
	}
	if(zoned_subdir)
		strunzone(zoned_subdir);
}

void XonoticHUDSkinList_getHUDSkins(entity me)
{
	if (me.listHUDSkin >= 0)
		buf_del(me.listHUDSkin);
	me.listHUDSkin = buf_create();
	if (me.listHUDSkin < 0)
	{
		me.nItems = 0;
		return;
	}
	getAllHUDSkins(me, "");
	getAllHUDSkins(me, "data/");
	me.nItems = buf_getsize(me.listHUDSkin) / HUDSKINPARM_COUNT;
}

void XonoticHUDSkinList_destroy(entity me)
{
	if(me.nItems > 0)
		buf_del(me.listHUDSkin);
}

void XonoticHUDSkinList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticHUDSkinList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize.y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize.x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNameOrigin = me.realFontSize.x;
	me.columnNameSize = 1 - 2 * me.realFontSize.x;
}

void XonoticHUDSkinList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	s = me.hudskinName(me,i);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 1);
}

void XonoticHUDSkinList_showNotify(entity me)
{
	me.getHUDSkins(me);
}

void HUDSkinList_Refresh_Click(entity btn, entity me)
{
	me.getHUDSkins(me);
	me.setSelected(me, 0); //always select the first element after a list update
}

void HUDSkinList_Filter_Change(entity box, entity me)
{
	if(me.filterString)
		strunzone(me.filterString);

	if(box.text != "")
	{
		if (strstrofs(box.text, "*", 0) >= 0 || strstrofs(box.text, "?", 0) >= 0)
			me.filterString = strzone(box.text);
		else
			me.filterString = strzone(strcat("*", box.text, "*"));
	}
	else
		me.filterString = string_null;

	me.getHUDSkins(me);
}

void SaveHUDSkin_Click(entity btn, entity me)
{
	localcmd("hud save myconfig\n");
	me.delayedRefreshTime = time + 1;
}

void XonoticHUDSkinList_draw(entity me)
{
	if(me.delayedRefreshTime > 0 && me.delayedRefreshTime < time)
	{
		HUDSkinList_Refresh_Click(NULL, me);
		me.delayedRefreshTime = 0;
	}
	SUPER(XonoticHUDSkinList).draw(me);
}

void XonoticHUDSkinList_setHUDSkin(entity me)
{
	string cfg = strcat(me.hudskinPath(me, me.selectedItem), "hud_", me.hudskinName(me, me.selectedItem), ".cfg");
	localcmd("exec ", cfg, "\n");
}

void SetHUDSkin_Click(entity btn, entity me)
{
	me.setHUDSkin(me);
}

void XonoticHUDSkinList_doubleClickListBoxItem(entity me, float i, vector where)
{
	m_play_click_sound(MENU_SOUND_EXECUTE);
	me.setHUDSkin(me);
}

float XonoticHUDSkinList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		me.setHUDSkin(me);
		return 1;
	}
	else
	{
		return SUPER(XonoticHUDSkinList).keyDown(me, scan, ascii, shift);
	}
}
#endif

