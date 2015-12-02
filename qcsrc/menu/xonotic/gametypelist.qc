#ifndef GAMETYPELIST_H
#define GAMETYPELIST_H
#include "listbox.qc"
CLASS(XonoticGametypeList, XonoticListBox)
	METHOD(XonoticGametypeList, configureXonoticGametypeList, void(entity));
	ATTRIB(XonoticGametypeList, rowsPerItem, float, 2)
	METHOD(XonoticGametypeList, drawListBoxItem, void(entity, int, vector, bool, bool));
	METHOD(XonoticGametypeList, resizeNotify, void(entity, vector, vector, vector, vector));
	METHOD(XonoticGametypeList, setSelected, void(entity, float));
	METHOD(XonoticGametypeList, loadCvars, void(entity));
	METHOD(XonoticGametypeList, saveCvars, void(entity));
	METHOD(XonoticGametypeList, keyDown, float(entity, float, float, float));
	METHOD(XonoticGametypeList, clickListBoxItem, void(entity, float, vector));
	METHOD(XonoticGametypeList, focusedItemChangeNotify, void(entity));

	ATTRIB(XonoticGametypeList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticGametypeList, realUpperMargin, float, 0)
	ATTRIB(XonoticGametypeList, columnIconOrigin, float, 0)
	ATTRIB(XonoticGametypeList, columnIconSize, float, 0)
	ATTRIB(XonoticGametypeList, columnNameOrigin, float, 0)
	ATTRIB(XonoticGametypeList, columnNameSize, float, 0)
ENDCLASS(XonoticGametypeList)
entity makeXonoticGametypeList();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticGametypeList()
{
	entity me;
	me = NEW(XonoticGametypeList);
	me.configureXonoticGametypeList(me);
	return me;
}
void XonoticGametypeList_configureXonoticGametypeList(entity me)
{
	me.configureXonoticListBox(me);
	me.nItems = GameType_GetCount();

	if(SKINBOOL_GAMETYPELIST_ICON_BLUR)
	{
		for(int i = 0; i < GameType_GetCount(); ++i)
			draw_PreloadPictureWithFlags(GameType_GetIcon(i), PRECACHE_PIC_MIPMAP);
	}

	me.loadCvars(me);
}
void XonoticGametypeList_setSelected(entity me, float i)
{
	SUPER(XonoticGametypeList).setSelected(me, i);
	me.saveCvars(me);
}
void XonoticGametypeList_loadCvars(entity me)
{
	float t;
	t = MapInfo_CurrentGametype();
	float i;
	for(i = 0; i < GameType_GetCount(); ++i)
		if(t == GameType_GetID(i))
			break;
	if(i >= GameType_GetCount())
	{
		for(i = 0; i < GameType_GetCount(); ++i)
			if(t == MAPINFO_TYPE_DEATHMATCH)
				break;
		if(i >= GameType_GetCount())
			i = 0;
	}
	me.setSelected(me, i);
	// do we need this: me.parent.gameTypeChangeNotify(me.parent); // to make sure
}
void XonoticGametypeList_saveCvars(entity me)
{
	int t = GameType_GetID(me.selectedItem);
	if (t == MapInfo_CurrentGametype()) {
		return;
	}
	MapInfo_SwitchGameType(t);
	entity owner = me.parent;
	if (owner) { // not set immediately
		owner.gameTypeChangeNotify(owner);
	}
}
void XonoticGametypeList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s1, s2;

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	draw_Picture(me.columnIconOrigin * eX, GameType_GetIcon(i), me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
	s1 = GameType_GetName(i);

	if(_MapInfo_GetTeamPlayBool(GameType_GetID(i)))
		s2 = _("teamplay");
	else
		s2 = _("free for all");

	vector save_fontscale = draw_fontscale;
	float f = draw_CondensedFontFactor(strcat(s1, " ", s2), false, me.realFontSize, 1);
	draw_fontscale.x *= f;
	vector fs = me.realFontSize;
	fs.x *= f;
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s1, fs, '1 1 1', SKINALPHA_TEXT, 0);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 1.0 * (me.columnNameSize - draw_TextWidth(s2, 0, fs))) * eX, s2, fs, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
	draw_fontscale = save_fontscale;
}
void XonoticGametypeList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticServerList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize.y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize.x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
	me.columnIconOrigin = 0;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x;
	me.columnNameOrigin = me.columnIconOrigin + me.columnIconSize + (0.5 * me.realFontSize.x);
	me.columnNameSize = 1 - me.columnIconSize - (1.5 * me.realFontSize.x);
}
float XonoticGametypeList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		m_play_click_sound(MENU_SOUND_EXECUTE);
		me.parent.gameTypeSelectNotify(me.parent);
		return 1;
	}

	return SUPER(XonoticGametypeList).keyDown(me, scan, ascii, shift);
}
void XonoticGametypeList_clickListBoxItem(entity me, float i, vector where)
{
	m_play_click_sound(MENU_SOUND_SELECT);
}
void XonoticGametypeList_focusedItemChangeNotify(entity me)
{
	if(me.focusedItem >= 0)
		setZonedTooltip(me, MapInfo_Type_Description(GameType_GetID(me.focusedItem)), string_null);
	else
		clearTooltip(me);
}
#endif
