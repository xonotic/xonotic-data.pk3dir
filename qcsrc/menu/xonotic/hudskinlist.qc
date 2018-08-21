#include "hudskinlist.qh"

#include "inputbox.qh"

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
	me.nItems = 0;
}

const float HUDSKINPARM_NAME = 0;
const float HUDSKINPARM_PATH = 1;
const float HUDSKINPARM_TITLE = 2;
const float HUDSKINPARM_AUTHOR = 3;
const float HUDSKINPARM_COUNT = 4;
string XonoticHUDSkinList_hudskinName(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_NAME);
}
string XonoticHUDSkinList_hudskinPath(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_PATH);
}
string XonoticHUDSkinList_hudskinTitle(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_TITLE);
}
string XonoticHUDSkinList_hudskinAuthor(entity me, float i)
{
	return bufstr_get(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_AUTHOR);
}

// subdir can be a regular expression
void getHUDSkinFiles(entity me, int sortbuf, string subdir)
{
	string s;
	if(me.filterString)
		s = me.filterString;
	else
		s = "*";
	s = strcat(subdir, "hud_", s, ".cfg");

	int list = search_begin(s, false, true);
	if(list >= 0)
	{
		int n = search_getsize(list);
		for(int i = 0; i < n; ++i)
		{
			string s = search_getfilename(list, i);
			int subdir_ofs = strstrofs(s, "/", 0);
			if(subdir_ofs >= 0)
			{
				int ofs = subdir_ofs;
				while(ofs != -1)
				{
					subdir_ofs = ofs;
					ofs = strstrofs(s, "/", subdir_ofs + 1);
				}
			}

			if(subdir_ofs == -1)
				bufstr_add(sortbuf, s, true);
			else
			{
				subdir = substring(s, 0, subdir_ofs);
				string filename = substring(s, subdir_ofs + 1, -1);
				// invert path and filename position so we can sort sortbuf by filename
				bufstr_add(sortbuf, strcat(filename, "/", subdir), true);
			}
		}
		search_end(list);
	}
}

void getAllHUDSkins(entity me, int sortbuf)
{
	int n = buf_getsize(sortbuf);
	for(int i = 0; i < n; ++i)
	{
		string entry = bufstr_get(sortbuf, i);
		int ofs = strstrofs(entry, "/", 0);
		string s = "";
		string filename = entry;
		if(ofs >= 0)
		{
			s = substring(entry, ofs + 1, -1); // skip initial "/"
			s = strcat(s, "/");
			bufstr_set(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_PATH, s);
			filename = strcat(s, substring(entry, 0, ofs));
		}
		else
			ofs = strlen(entry);
		s = substring(entry, 4, ofs - 4 - 4); // remove "hud_" prefix and ".cfg" suffix
		bufstr_set(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_NAME, s);

		int fh = fopen(filename, FILE_READ);
		if(fh < 0)
			continue;
		while((s = fgets(fh)) && substring(s, 0, 2) == "//")
		{
			tokenize_console(substring(s, 2, -1));
			if(argv(0) == "title")
				bufstr_set(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_TITLE, argv(1));
			else if(argv(0) == "author")
				bufstr_set(me.listHUDSkin, i * HUDSKINPARM_COUNT + HUDSKINPARM_AUTHOR, argv(1));
		}
		fclose(fh);
	}
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
	int sortbuf = buf_create();
	getHUDSkinFiles(me, sortbuf, "");
	getHUDSkinFiles(me, sortbuf, "data/");
	buf_sort(sortbuf, 128, 0);
	getAllHUDSkins(me, sortbuf);
	buf_del(sortbuf);
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

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNameOrigin = me.realFontSize.x;
	me.columnNameSize = 1 - 2 * me.realFontSize.x;
}

void XonoticHUDSkinList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s, s2;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	s = me.hudskinTitle(me, i);
	if(s == "")
		s = me.hudskinName(me, i);
	s2 = me.hudskinAuthor(me, i);
	if(s2 != "")
		s = strcat(s, " (", s2, ")");
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

void HUDSkinList_SavedName_Change(entity box, entity me)
{
	strfree(me.savedName);

	if(box.text != "")
		me.savedName = strzone(box.text);
}

void HUDSkinList_Filter_Change(entity box, entity me)
{
	strfree(me.filterString);

	if(box.text != "")
	{
		if (strstrofs(box.text, "*", 0) >= 0 || strstrofs(box.text, "?", 0) >= 0)
			me.filterString = strzone(box.text);
		else
			me.filterString = strzone(strcat("*", box.text, "*"));
	}

	me.getHUDSkins(me);
}

void SaveHUDSkin_Click(entity btn, entity me)
{
	string s = me.savedName;
	if(s == "")
		s = "myconfig";
	localcmd(sprintf("hud save \"%s\"\n", s));
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
	localcmd("exec \"", cfg, "\"\n");
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
