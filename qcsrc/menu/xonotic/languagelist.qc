#include "languagelist.qh"

#include "../item/modalcontroller.qh"
#include "mainwindow.qh"

const int LANGPARM_ID = 0;
const int LANGPARM_NAME = 1;
const int LANGPARM_NAME_LOCALIZED = 2;
const int LANGPARM_PERCENTAGE = 3;
const int LANGPARM_COUNT = 4;

const string PERCENTAGE_FULL_ICON = "/gfx/scoreboard/player_ready";

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
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	string p = me.languageParameter(me, i, LANGPARM_PERCENTAGE);
	float alpha_factor;
	if(p == "") // 100%
		alpha_factor = 1;
	else
	{
		float percent = stof(p);
		if (percent >= 90)
			alpha_factor = 1;
		else if (percent >= 50)
			alpha_factor = 0.65;
		else
			alpha_factor = 0.3;
		p = ftos_decimals_percentage(percent / 100, 0); // make it translatable
	}

	string s = me.languageParameter(me, i, LANGPARM_NAME_LOCALIZED);

	vector save_fontscale = draw_fontscale;
	float f = draw_CondensedFontFactor(s, false, me.realFontSize, 1);
	draw_fontscale.x *= f;
	vector fs = me.realFontSize;
	fs.x *= f;
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, fs, SKINCOLOR_TEXT * alpha_factor, SKINALPHA_TEXT, 0);
	draw_fontscale = save_fontscale;

	if(p == "")
	{
		float x_ofs = me.columnPercentageOrigin + (me.columnPercentageSize - me.columnIconSize);
		draw_Picture(me.realUpperMargin * eY + x_ofs * eX, PERCENTAGE_FULL_ICON, me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
	}
	else
	{
		vector save_fontscale = draw_fontscale;
		float f = draw_CondensedFontFactor(p, false, me.realFontSize, 1);
		draw_fontscale.x *= f;
		vector fs = me.realFontSize;
		fs.x *= f;
		float x_ofs = me.columnPercentageOrigin + (me.columnPercentageSize - draw_TextWidth(p, 0, fs));
		draw_Text(me.realUpperMargin * eY + x_ofs * eX, p, fs, SKINCOLOR_TEXT, SKINALPHA_TEXT * alpha_factor, 0);
		draw_fontscale = save_fontscale;
	}
}

void XonoticLanguageList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticLanguageList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize.x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	vector sz = draw_PictureSize(PERCENTAGE_FULL_ICON);
	float aspect_ratio = sz.y ? sz.x / sz.y : 1;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x * aspect_ratio;

	me.columnPercentageSize = me.realFontSize.x * 3;
	me.columnPercentageOrigin = 1 - me.columnPercentageSize - 0.5 * me.realFontSize.x;
	me.columnNameOrigin = 0.5 * me.realFontSize.x;
	me.columnNameSize = me.columnPercentageOrigin - me.columnNameOrigin;
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
		bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_NAME_LOCALIZED, argv(2));
		string percent = argv(3);
		if(percent && percent != "100%")
			bufstr_set(buf, i * LANGPARM_COUNT + LANGPARM_PERCENTAGE, percent);
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

void XonoticLanguageList_focusedItemChangeNotify(entity me)
{
	if (me.focusedItem >= 0)
		setZonedTooltip(me, me.languageParameter(me, me.focusedItem, LANGPARM_NAME), string_null);
	else
		clearTooltip(me);
}
