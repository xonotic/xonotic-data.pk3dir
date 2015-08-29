#ifndef LANGUAGELIST_H
#define LANGUAGELIST_H
#include "listbox.qc"
CLASS(XonoticLanguageList, XonoticListBox)
	METHOD(XonoticLanguageList, configureXonoticLanguageList, void(entity));
	ATTRIB(XonoticLanguageList, rowsPerItem, float, 1)
	METHOD(XonoticLanguageList, drawListBoxItem, void(entity, int, vector, bool, bool));
	METHOD(XonoticLanguageList, resizeNotify, void(entity, vector, vector, vector, vector));
	METHOD(XonoticLanguageList, setSelected, void(entity, float));
	METHOD(XonoticLanguageList, loadCvars, void(entity));
	METHOD(XonoticLanguageList, saveCvars, void(entity));

	ATTRIB(XonoticLanguageList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticLanguageList, realUpperMargin, float, 0)
	ATTRIB(XonoticLanguageList, columnNameOrigin, float, 0)
	ATTRIB(XonoticLanguageList, columnNameSize, float, 0)
	ATTRIB(XonoticLanguageList, columnPercentageOrigin, float, 0)
	ATTRIB(XonoticLanguageList, columnPercentageSize, float, 0)

	METHOD(XonoticLanguageList, doubleClickListBoxItem, void(entity, float, vector));
	METHOD(XonoticLanguageList, keyDown, float(entity, float, float, float)); // enter handling

	METHOD(XonoticLanguageList, destroy, void(entity));

	ATTRIB(XonoticLanguageList, languagelist, float, -1)
	METHOD(XonoticLanguageList, getLanguages, void(entity));
	METHOD(XonoticLanguageList, setLanguage, void(entity));
	METHOD(XonoticLanguageList, languageParameter, string(entity, float, float));

	ATTRIB(XonoticLanguageList, name, string, "languageselector") // change this to make it noninteractive (for first run dialog)
ENDCLASS(XonoticLanguageList)

entity makeXonoticLanguageList();
void SetLanguage_Click(entity btn, entity me);
#endif

#ifdef IMPLEMENTATION

const float LANGPARM_ID = 0;
const float LANGPARM_NAME = 1;
const float LANGPARM_NAME_LOCALIZED = 2;
const float LANGPARM_PERCENTAGE = 3;
const float LANGPARM_COUNT = 4;

entity makeXonoticLanguageList()
{
	entity me;
	me = NEW(XonoticLanguageList);
	me.configureXonoticLanguageList(me);
	return me;
}

void XonoticLanguageList_configureXonoticLanguageList(entity me)
{
	me.configureXonoticListBox(me);
	me.getLanguages(me);
	me.loadCvars(me);
}

void XonoticLanguageList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s, p;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	s = me.languageParameter(me, i, LANGPARM_NAME_LOCALIZED);

	vector save_fontscale = draw_fontscale;
	float f = draw_CondensedFontFactor(s, false, me.realFontSize, 1);
	draw_fontscale.x *= f;
	vector fs = me.realFontSize;
	fs.x *= f;
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, fs, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
	draw_fontscale = save_fontscale;

	p = me.languageParameter(me, i, LANGPARM_PERCENTAGE);
	if(p != "")
	{
		vector save_fontscale = draw_fontscale;
		float f = draw_CondensedFontFactor(p, false, me.realFontSize, 1);
		draw_fontscale.x *= f;
		vector fs = me.realFontSize;
		fs.x *= f;
		draw_Text(me.realUpperMargin * eY + (me.columnPercentageOrigin + (me.columnPercentageSize - draw_TextWidth(p, 0, fs))) * eX, p, fs, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
		draw_fontscale = save_fontscale;
	}
}

void XonoticLanguageList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticLanguageList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
	me.columnPercentageSize = me.realFontSize.x * 3;
	me.columnPercentageOrigin = 1 - me.columnPercentageSize;
	me.columnNameOrigin = 0;
	me.columnNameSize = me.columnPercentageOrigin;
}

void XonoticLanguageList_setSelected(entity me, float i)
{
	SUPER(XonoticLanguageList).setSelected(me, i);
	me.saveCvars(me);
}

void XonoticLanguageList_loadCvars(entity me)
{
	string s;
	float i, n;
	s = cvar_string("_menu_prvm_language");
	n = me.nItems;

	// default to English
	for(i = 0; i < n; ++i)
	{
		if(me.languageParameter(me, i, LANGPARM_ID) == "en")
		{
			SUPER(XonoticLanguageList).setSelected(me, i);
			break;
		}
	}

	// otherwise, find the language
	for(i = 0; i < n; ++i)
	{
		if(me.languageParameter(me, i, LANGPARM_ID) == s)
		{
			SUPER(XonoticLanguageList).setSelected(me, i);
			break;
		}
	}

	// save it off (turning anything unknown into "en")
	me.saveCvars(me);
}

void XonoticLanguageList_saveCvars(entity me)
{
	cvar_set("_menu_prvm_language", me.languageParameter(me, me.selectedItem, LANGPARM_ID));
}

void XonoticLanguageList_doubleClickListBoxItem(entity me, float i, vector where)
{
	m_play_click_sound(MENU_SOUND_EXECUTE);
	me.setLanguage(me);
}

float XonoticLanguageList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		m_play_click_sound(MENU_SOUND_EXECUTE);
		me.setLanguage(me);
		return 1;
	}
	else
		return SUPER(XonoticLanguageList).keyDown(me, scan, ascii, shift);
}

void XonoticLanguageList_destroy(entity me)
{
	buf_del(me.languagelist);
}

void XonoticLanguageList_getLanguages(entity me)
{
	float buf, i, n, fh;
	string s;

	buf = buf_create();

	fh = fopen("languages.txt", FILE_READ);
	i = 0;
	while((s = fgets(fh)))
	{
		n = tokenize_console(s);
		if(n < 3)
			continue;
		bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_ID, argv(0));
		bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_NAME, argv(1));
		float k = strstrofs(argv(2), "(", 0);
		if(k > 0)
		if(substring(argv(2), strlen(argv(2)) - 1, 1) == ")")
		{
			string percent = substring(argv(2), k + 1, -2);
			if(percent != "100%")
				bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_PERCENTAGE, percent);
		}
		bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_NAME_LOCALIZED, (k < 0) ? argv(2) : substring(argv(2), 0, k - 1));
		++i;
	}
	fclose(fh);

	me.languagelist = buf;
	me.nItems = i;
}

void XonoticLanguageList_setLanguage(entity me)
{
	if(prvm_language != cvar_string("_menu_prvm_language"))
	{
		if(!(gamestatus & GAME_CONNECTED))
			localcmd("\nprvm_language \"$_menu_prvm_language\"; menu_restart; menu_cmd languageselect\n");
		else
			DialogOpenButton_Click(me, main.languageWarningDialog);
	}
}

string XonoticLanguageList_languageParameter(entity me, float i, float key)
{
	return bufstr_get(me.languagelist, i * LANGPARM_COUNT + key);
}

void SetLanguage_Click(entity btn, entity me)
{
	me.setLanguage(me);
}

#endif
