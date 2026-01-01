#include "maplist.qh"

#include <common/mapinfo.qh>
#include "dialog_multiplayer_create_mapinfo.qh"
#include "mainwindow.qh"
#include "inputbox.qh"

.bool disabled;

void XonoticMapList_destroy(entity me)
{
	MapInfo_Shutdown();
}

entity makeXonoticMapList()
{
	entity me;
	me = NEW(XonoticMapList);
	me.configureXonoticMapList(me);
	return me;
}

entity MapList_Set_StringFilterBox(entity me, entity e)
{
	me.stringFilterBox = e;
	return e;
}

void XonoticMapList_configureXonoticMapList(entity me)
{
	me.configureXonoticListBox(me);
	me.refilter(me);
}

void XonoticMapList_loadCvars(entity me)
{
	me.refilter(me);
}


float XonoticMapList_g_maplistCacheQuery(entity me, float i)
{
	return stof(substring(me.g_maplistCache, i, 1));
}
void XonoticMapList_g_maplistCacheToggle(entity me, float i)
{
	string a, b, c, s, bspname;
	float n;
	s = me.g_maplistCache;
	if (!s)
		return;
	b = substring(s, i, 1);
	if(b == "0")
		b = "1";
	else if(b == "1")
		b = "0";
	else
		return; // nothing happens
	a = substring(s, 0, i);
	c = substring(s, i+1, strlen(s) - (i+1));
	strunzone(s);
	me.g_maplistCache = strzone(strcat(a, b, c));
	// TODO also update the actual cvar
	if (!((bspname = MapInfo_BSPName_ByID(i))))
		return;
	if(b == "1")
		cvar_set("g_maplist", strcat(bspname, " ", cvar_string("g_maplist")));
	else
	{
		s = "";
		n = tokenize_console(cvar_string("g_maplist"));
		for(i = 0; i < n; ++i)
			if(argv(i) != bspname)
				s = strcat(s, " ", argv(i));
		cvar_set("g_maplist", substring(s, 1, strlen(s) - 1));
	}
}

void XonoticMapList_draw(entity me)
{
	if(me.startButton)
		me.startButton.disabled = ((me.selectedItem < 0) || (me.selectedItem >= me.nItems)
			|| ((gamestatus & (GAME_ISSERVER | GAME_CONNECTED)) && cvar("g_campaign")));
	SUPER(XonoticMapList).draw(me);
}

void XonoticMapList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticMapList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin1 = 0.5 * (1 - 2.5 * me.realFontSize.y);
	me.realUpperMargin2 = me.realUpperMargin1 + 1.5 * me.realFontSize.y;

	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize.y / me.itemAbsSize.x * 4 / 3;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize.x;
	me.columnNameSize = 1 - me.columnPreviewSize - 2 * me.realFontSize.x;

	me.checkMarkSize = (eX * (me.itemAbsSize.y / me.itemAbsSize.x) + eY) * 0.5;
	me.checkMarkOrigin = eY + eX * (me.columnPreviewOrigin + me.columnPreviewSize) - me.checkMarkSize;
}

void XonoticMapList_clickListBoxItem(entity me, float i, vector where)
{
	if(where.x <= me.columnPreviewOrigin + me.columnPreviewSize)
		if(where.x >= 0)
		{
			m_play_click_sound(MENU_SOUND_SELECT);
			me.g_maplistCacheToggle(me, i);
		}
}

void XonoticMapList_doubleClickListBoxItem(entity me, float i, vector where)
{
	if(where.x >= me.columnNameOrigin)
		if(where.x <= 1)
		{
			// pop up map info screen
			m_play_click_sound(MENU_SOUND_OPEN);
			main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, i, me);
			DialogOpenButton_Click_withCoords(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size.x) + eY * ((me.itemHeight * i - me.scrollPos) * me.size.y), eY * me.itemAbsSize.y + eX * (me.itemAbsSize.x * me.columnNameSize));
		}
}

void XonoticMapList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	// layout: Ping, Map name, Map name, NP, TP, MP
	string s;
	float theAlpha;
	float included;

	if(!MapInfo_Get_ByID(i))
		return;

	included = me.g_maplistCacheQuery(me, i);
	if(included || isSelected)
		theAlpha = SKINALPHA_MAPLIST_INCLUDEDFG;
	else
		theAlpha = SKINALPHA_MAPLIST_NOTINCLUDEDFG;

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else
	{
		if(included)
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_MAPLIST_INCLUDEDBG, SKINALPHA_MAPLIST_INCLUDEDBG);
		if(isFocused)
		{
			me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
		}
	}

	if(draw_PictureSize(strcat("/maps/", MapInfo_Map_bspname)) == '0 0 0')
	{
		if(draw_PictureSize(strcat("/levelshots/", MapInfo_Map_bspname)) == '0 0 0')
			draw_Picture(me.columnPreviewOrigin * eX, "nopreview_map", me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
		else
			draw_Picture(me.columnPreviewOrigin * eX, strcat("/levelshots/", MapInfo_Map_bspname), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	}
	else
		draw_Picture(me.columnPreviewOrigin * eX, strcat("/maps/", MapInfo_Map_bspname), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);

	if(included)
		draw_Picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);
	s = draw_TextShortenToWidth(strdecolorize(MapInfo_Map_titlestring), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_TITLE, theAlpha, 0);
	s = draw_TextShortenToWidth(strdecolorize(MapInfo_Map_author), me.columnNameSize, 0,  me.realFontSize);
	draw_Text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 1.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_AUTHOR, theAlpha, 0);

	MapInfo_ClearTemps();
}

void XonoticMapList_refilter(entity me)
{
	float i, j, n;
	string s;
	Gametype gt = MapInfo_CurrentGametype();
	int f = MapInfo_CurrentFeatures();
	MapInfo_FilterGametype(gt, f, MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	if (me.stringFilter)
		MapInfo_FilterString(me.stringFilter);
	me.nItems = MapInfo_count;

	for(i = 0; i < MapInfo_count; ++i)
	{
		if(draw_PreloadPicture(strcat("/maps/", MapInfo_BSPName_ByID(i))) == "")
			draw_PreloadPicture(strcat("/levelshots/", MapInfo_BSPName_ByID(i)));
	}
	s = "0";
	for(i = 1; i < MapInfo_count; i *= 2)
		s = strcat(s, s);
	n = tokenize_console(cvar_string("g_maplist"));
	for(i = 0; i < n; ++i)
	{
		j = MapInfo_FindName(argv(i));
		if(j >= 0)
		{
			// double check that the two mapnames are "identical", not just share the same prefix
			if (strlen(MapInfo_BSPName_ByID(j)) == strlen(argv(i)))
				s = strcat(
					substring(s, 0, j),
					"1",
					substring(s, j+1, MapInfo_count - (j+1))
				);
		}
	}
	strcpy(me.g_maplistCache, s);
	if(gt != me.lastGametype || f != me.lastFeatures)
	{
		me.lastGametype = gt;
		me.lastFeatures = f;
		me.setSelected(me, 0);
	}
}

void XonoticMapList_refilterCallback(entity me, entity cb)
{
	me.refilter(me);
}

void MapList_StringFilterBox_Change(entity box, entity me)
{
	strfree(me.stringFilter);
	if(box.text != "")
		me.stringFilter = strzone(box.text);

	me.refilter(me);
}

void MapList_Add_Shown(entity btn, entity me)
{
	float i, n;
	n = strlen(me.g_maplistCache);
	for (i = 0 ; i < n; ++i)
	{
		if (!me.g_maplistCacheQuery(me, i))
			me.g_maplistCacheToggle(me, i);
	}
	me.refilter(me);
}

void MapList_Remove_Shown(entity btn, entity me)
{
	float i, n;
	n = strlen(me.g_maplistCache);
	for (i = 0 ; i < n; ++i)
	{
		if (me.g_maplistCacheQuery(me, i))
			me.g_maplistCacheToggle(me, i);
	}
	me.refilter(me);
}

void MapList_Add_All(entity btn, entity me)
{
	float i;
	string s;
	_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, MapInfo_ForbiddenFlags(), 0); // all
	s = "";
	for(i = 0; i < MapInfo_count; ++i)
		s = cons(s, MapInfo_BSPName_ByID(i));
	cvar_set("g_maplist", s);
	me.refilter(me);
}

void MapList_Remove_All(entity btn, entity me)
{
	cvar_set("g_maplist", "");
	me.refilter(me);
}

void MapList_LoadMap(entity btn, entity me)
{
	string m;
	float i;

	i = me.selectedItem;

	if(btn.parent.instanceOfXonoticMapInfoDialog)
	{
		i = btn.parent.currentMapIndex;
		Dialog_Close(btn, btn.parent);
	}

	if(i >= me.nItems || i < 0)
		return;

	m = MapInfo_BSPName_ByID(i);
	if (!m)
	{
		LOG_INFO(_("Huh? Can't play this (m is NULL). Refiltering so this won't happen again."));
		me.refilter(me);
		return;
	}
	if(MapInfo_CheckMap(m))
	{
		localcmd("\nmenu_loadmap_prepare\n");
		if(cvar("menu_use_default_hostname"))
			localcmd("hostname \"", sprintf(_("%s's Xonotic Server"), strdecolorize(cvar_string("_cl_name"))), "\"\n");
		MapInfo_LoadMap(m, 1);
	}
	else
	{
		LOG_INFO(_("Huh? Can't play this (invalid gametype). Refiltering so this won't happen again."));
		me.refilter(me);
		return;
	}
}

float XonoticMapList_keyDown(entity me, float scan, float ascii, float shift)
{
	string ch, save;
	if(me.nItems <= 0)
		return SUPER(XonoticMapList).keyDown(me, scan, ascii, shift);
	if(scan == K_MOUSE2 || scan == K_SPACE || scan == K_ENTER || scan == K_KP_ENTER)
	{
		// pop up map info screen
		m_play_click_sound(MENU_SOUND_OPEN);
		main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, me.selectedItem, me);
		DialogOpenButton_Click_withCoords(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size.x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size.y), eY * me.itemAbsSize.y + eX * (me.itemAbsSize.x * me.columnNameSize));
	}
	else if(scan == K_MOUSE3 || scan == K_INS || scan == K_KP_INS || ((shift & S_CTRL) && scan == K_MOUSE1))
	{
		m_play_click_sound(MENU_SOUND_SELECT);
		me.g_maplistCacheToggle(me, me.selectedItem);
	}
	else if(ascii == '+')
	{
		if (!me.g_maplistCacheQuery(me, me.selectedItem))
		{
			m_play_click_sound(MENU_SOUND_SELECT);
			me.g_maplistCacheToggle(me, me.selectedItem);
		}
	}
	else if(ascii == '-')
	{
		if(me.g_maplistCacheQuery(me, me.selectedItem))
		{
			m_play_click_sound(MENU_SOUND_SELECT);
			me.g_maplistCacheToggle(me, me.selectedItem);
		}
	}
	else if(scan == K_BACKSPACE)
	{
		if(time < me.typeToSearchTime)
		{
			save = substring(me.typeToSearchString, 0, strlen(me.typeToSearchString) - 1);
			strcpy(me.typeToSearchString, save);
			me.typeToSearchTime = time + 0.5;
			if(strlen(me.typeToSearchString))
			{
				MapInfo_FindName(me.typeToSearchString);
				if(MapInfo_FindName_firstResult >= 0)
					me.setSelected(me, MapInfo_FindName_firstResult);
			}
		}
	}
	else if(ascii >= 32 && ascii != 127)
	{
		ch = chr(ascii);
		if(time > me.typeToSearchTime)
			save = ch;
		else
			save = strcat(me.typeToSearchString, ch);
		strcpy(me.typeToSearchString, save);
		me.typeToSearchTime = time + 0.5;
		MapInfo_FindName(me.typeToSearchString);
		if(MapInfo_FindName_firstResult >= 0)
			me.setSelected(me, MapInfo_FindName_firstResult);
	}
	else if((shift & S_CTRL) && scan == 'f') // ctrl-f (as in "F"ind)
	{
		me.parent.setFocus(me.parent, me.stringFilterBox);
	}
	else if((shift & S_CTRL) && scan == 'u') // ctrl-u (remove stringFilter line)
	{
		me.stringFilterBox.setText(me.stringFilterBox, "");
		MapList_StringFilterBox_Change(me.stringFilterBox, me);
	}
	else
		return SUPER(XonoticMapList).keyDown(me, scan, ascii, shift);
	return 1;
}

float MapList_StringFilterBox_keyDown(entity me, float scan, float ascii, float shift)
{
	// in this section, note that onChangeEntity has the ref to mapListBox
	// we make use of that, instead of extending a class to add one more attrib
	switch(scan)
	{
		case K_KP_ENTER:
		case K_ENTER:
			// move the focus to the mapListBox
			me.onChangeEntity.parent.setFocus(me.onChangeEntity.parent, me.onChangeEntity);
			return 1;
		case K_KP_UPARROW:
		case K_UPARROW:
		case K_KP_DOWNARROW:
		case K_DOWNARROW:
			// pass the event to the mapListBox (to scroll up and down)
			return me.onChangeEntity.keyDown(me.onChangeEntity, scan, ascii, shift);
	}
	return SUPER(XonoticInputBox).keyDown(me, scan, ascii, shift);
}
