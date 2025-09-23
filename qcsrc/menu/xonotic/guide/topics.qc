#include "topics.qh"

#include <menu/xonotic/guide/entries.qh>

void XonoticTopicList_clickListBoxItem(entity me, float i, vector where)
{
	m_play_click_sound(MENU_SOUND_SELECT);
}

string XonoticTopicList_cb_name, XonoticTopicList_cb_icon;
void XonoticTopicList_cb(string _name, string _icon)
{
	XonoticTopicList_cb_name = _name;
	XonoticTopicList_cb_icon = _icon;
}

void XonoticTopicList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if (!me.source)
		return;
	if (!me.source.getEntry(me.source, i, XonoticTopicList_cb))
		return;

	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}
	draw_Picture(me.columnIconOrigin * eX, XonoticTopicList_cb_icon, me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);

	// condense text so it's shown without truncating, vertically centered
	const vector save_fontscale = draw_fontscale;
	const float f = draw_CondensedFontFactor(XonoticTopicList_cb_name, false, me.realFontSize, me.columnNameSize);
	draw_fontscale.x *= f;
	vector fs = me.realFontSize;
	fs.x *= f;
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, XonoticTopicList_cb_name, fs, '1 1 1', SKINALPHA_TEXT, 0);
	draw_fontscale = save_fontscale;
}

bool XonoticTopicList_keyDown(entity me, float scan, float ascii, float shift)
{
	if (scan == K_ENTER || scan == K_KP_ENTER)
	{
		m_play_click_sound(MENU_SOUND_EXECUTE);
		return true;
	}
	return SUPER(XonoticEntryList).keyDown(me, scan, ascii, shift);
}

void XonoticTopicList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticEntryList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
	me.columnIconOrigin = 0;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x;
	me.columnNameOrigin = me.columnIconOrigin + me.columnIconSize + (0.5 * me.realFontSize.x);
	me.columnNameSize = 1 - me.columnNameOrigin - me.realFontSize.x;
}

void XonoticTopicList_setSelected(entity me, int i)
{
	int curr = me.selectedItem;
	SUPER(XonoticEntryList).setSelected(me, i);
	if (curr != me.selectedItem)
		me.onChange(me, me.onChangeEntity);
}
