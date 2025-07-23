#include "soundlist.qh"

#include "inputbox.qh"
#include "playlist.qh"

entity makeXonoticSoundList()
{
	entity me;
	me = NEW(XonoticSoundList);
	me.configureXonoticSoundList(me);
	return me;
}

void XonoticSoundList_configureXonoticSoundList(entity me)
{
	me.configureXonoticListBox(me);
	me.nItems = 0;
}

string XonoticSoundList_soundName(entity me, int i)
{
	string s;
	s = search_getfilename(me.listSound, i);
	s = substring(s, 15, strlen(s) - 15 - 4);  // sound/cdtracks/, .ogg
	return s;
}


void XonoticSoundList_getSounds(entity me)
{
	string s;

	if(me.filterString)
		//subdirectory in filterString allowed
		s = strcat("sound/cdtracks/*", me.filterString, "*.ogg");
	else
		s = "sound/cdtracks/*.ogg";

	if(me.listSound >= 0)
		search_end(me.listSound);

	me.listSound = search_begin(s, false, true);

	me.nItems = (me.listSound < 0) ? 0 : search_getsize(me.listSound);
}

void XonoticSoundList_destroy(entity me)
{
	if(me.listSound >= 0)
		search_end(me.listSound);
}

void XonoticSoundList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticSoundList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNumberOrigin = 0;
	me.columnNumberSize = me.realFontSize.x * 3;

	me.columnNameOrigin = me.columnNumberSize;
	me.columnNameSize = 1 - me.columnNameOrigin - me.realFontSize.x;
}

void XonoticSoundList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	s = me.soundName(me, i);
	if(s == cvar_string("menu_cdtrack")) // current menu track
		draw_CenterText((me.columnNumberOrigin + 0.5 * me.columnNumberSize) * eX + me.realUpperMargin * eY, "[C]", me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	else if(s == cvar_defstring("menu_cdtrack")) // default menu track
		draw_CenterText((me.columnNumberOrigin + 0.5 * me.columnNumberSize) * eX + me.realUpperMargin * eY, "[D]", me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);

	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

void XonoticSoundList_showNotify(entity me)
{
	me.getSounds(me);
}

void SoundList_Menu_Track_Change(entity box, entity me)
{
	cvar_set("menu_cdtrack", me.soundName(me, me.selectedItem));
}

void SoundList_Menu_Track_Reset(entity box, entity me)
{
	cvar_set("menu_cdtrack", cvar_defstring("menu_cdtrack"));
}

void SoundList_Filter_Change(entity box, entity me)
{
	strfree(me.filterString);

	if(box.text != "")
		me.filterString = strzone(box.text);

	me.getSounds(me);
}

void SoundList_Add(entity box, entity me)
{
	me.playlist.addToPlayList(me.playlist, me.soundName(me, me.selectedItem));
}

void SoundList_Add_All(entity box, entity me)
{
	int i;
	for(i = 0; i < me.nItems; ++i)
		me.playlist.addToPlayList(me.playlist, me.soundName(me, i));
}

void XonoticSoundList_doubleClickListBoxItem(entity me, int i, vector where)
{
	me.playlist.addToPlayList(me.playlist, me.soundName(me, i));
}

float XonoticSoundList_keyDown(entity me, float scan, float ascii, float shift)
{
	if (scan == K_ENTER || scan == K_KP_ENTER || scan == K_SPACE || ((shift & S_CTRL) && scan == K_MOUSE1)
		|| ascii == '+')
	{
		SoundList_Add(NULL, me);
		return 1;
	}
	else
		return SUPER(XonoticSoundList).keyDown(me, scan, ascii, shift);
}
