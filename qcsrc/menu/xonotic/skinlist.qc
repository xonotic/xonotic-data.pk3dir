#include "skinlist.qh"

const float SKINPARM_NAME = 0;
const float SKINPARM_TITLE = 1;
const float SKINPARM_AUTHOR = 2;
const float SKINPARM_PREVIEW = 3;
const float SKINPARM_COUNT = 4;

entity makeXonoticSkinList()
{
	entity me;
	me = NEW(XonoticSkinList);
	me.configureXonoticSkinList(me);
	return me;
}

void XonoticSkinList_configureXonoticSkinList(entity me)
{
	me.configureXonoticListBox(me);
	me.getSkins(me);
	me.loadCvars(me);
}

void XonoticSkinList_loadCvars(entity me)
{
	string s;
	float i, n;
	s = cvar_string("menu_skin");
	n = me.nItems;
	for(i = 0; i < n; ++i)
	{
		if(me.skinParameter(me, i, SKINPARM_NAME) == s)
		{
			me.setSelected(me, i);
			break;
		}
	}
}

void XonoticSkinList_saveCvars(entity me)
{
	cvar_set("menu_skin", me.skinParameter(me, me.selectedItem, SKINPARM_NAME));
}

string XonoticSkinList_skinParameter(entity me, float i, float key)
{
	return bufstr_get(me.skinlist, i * SKINPARM_COUNT + key);
}

void XonoticSkinList_getSkins(entity me)
{
	float glob, buf, i, n, fh;
	string s, name;

	buf = buf_create();
	glob = search_begin("gfx/menu/*/skinvalues.txt", true, true);
	if(glob < 0)
	{
		me.skinlist = buf;
		me.nItems = 0;
		return;
	}

	n = search_getsize(glob);
	for(i = 0; i < n; ++i)
	{
		s = search_getfilename(glob, i);
		name = substring(s, 9, strlen(s) - 24); // the * part
		bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_NAME, name);
		bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_TITLE, _("<TITLE>"));
		bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_AUTHOR, _("<AUTHOR>"));
		if(draw_PictureSize(strcat("/gfx/menu/", substring(s, 9, strlen(s) - 24), "/skinpreview")) == '0 0 0')
			bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_PREVIEW, "nopreview_menuskin");
		else
			bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_PREVIEW, strcat("/gfx/menu/", substring(s, 9, strlen(s) - 24), "/skinpreview"));
		fh = fopen(s, FILE_READ);
		if(fh < 0)
		{
			LOG_INFO("Warning: can't open skinvalues.txt file");
			continue;
		}
		while((s = fgets(fh)))
		{
			// these two are handled by skinlist.qc
			if(substring(s, 0, 6) == "title ")
			{
				if (name == cvar_defstring("menu_skin"))
					bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_TITLE, strcat(substring(s, 6, strlen(s) - 6), " (", _("Default"), ")"));
				else
					bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_TITLE, substring(s, 6, strlen(s) - 6));
			}
			else if(substring(s, 0, 7) == "author ")
				bufstr_set(buf, i * SKINPARM_COUNT + SKINPARM_AUTHOR, substring(s, 7, strlen(s) - 7));
		}
		fclose(fh);
	}

	search_end(glob);

	me.skinlist = buf;
	me.nItems = n;
}

void XonoticSkinList_destroy(entity me)
{
	buf_del(me.skinlist);
}

void XonoticSkinList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticSkinList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

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
}

void XonoticSkinList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	s = me.skinParameter(me, i, SKINPARM_PREVIEW);
	draw_Picture(me.columnPreviewOrigin * eX, s, me.columnPreviewSize * eX + eY, '1 1 1', 1);

	s = me.skinParameter(me, i, SKINPARM_TITLE);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_SKINLIST_TITLE, SKINALPHA_TEXT, 0);

	s = me.skinParameter(me, i, SKINPARM_AUTHOR);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 1.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_SKINLIST_AUTHOR, SKINALPHA_TEXT, 0);
}

void XonoticSkinList_setSkin(entity me)
{
	me.saveCvars(me);
	localcmd("\nmenu_restart\nmenu_cmd skinselect\n");
}

void SetSkin_Click(entity btn, entity me)
{
	me.setSkin(me);
}

void XonoticSkinList_doubleClickListBoxItem(entity me, float i, vector where)
{
	m_play_click_sound(MENU_SOUND_EXECUTE);
	me.setSkin(me);
}

float XonoticSkinList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		m_play_click_sound(MENU_SOUND_EXECUTE);
		me.setSkin(me);
		return 1;
	}
	else
		return SUPER(XonoticSkinList).keyDown(me, scan, ascii, shift);
}
