#include "entries.qh"

#include <menu/xonotic/listbox.qh>
#include <menu/xonotic/inputbox.qh>
#include <menu/xonotic/mainwindow.qh>

string XonoticEntryList_cb_name, XonoticEntryList_cb_icon;
void XonoticEntryList_cb(string _name, string _icon)
{
	XonoticEntryList_cb_name = _name;
	XonoticEntryList_cb_icon = _icon;
}

void XonoticEntryList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if (!me.source) return;
	if (!me.source.getEntry(me.source, i, XonoticEntryList_cb)) return;
	string name = XonoticEntryList_cb_name;
	string icon = XonoticEntryList_cb_icon;
	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}
	vector sz = draw_PictureSize(icon);
	if (!sz)
		sz = '1 1 0';
	float szr = sz.x / sz.y;
	if (strstrofs(icon, "map", 0) >= 0)
		szr = 4 / 3;
	float asr = me.itemAbsSize.x / me.itemAbsSize.y;
	sz.y = 1;
	sz.x = szr / asr;
	draw_Picture('0 0 0', icon, sz, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
	string s = draw_TextShortenToWidth(strdecolorize(name), 1 - sz.x - 2 * me.realFontSize.x, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (sz.x + 0.5 * me.realFontSize.x) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

METHOD(XonoticEntryList, keyDown, float(entity this, float scan, float ascii, float shift))
{
	if (this.nItems <= 0)
		return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
	else if ((ascii >= 32 || scan == K_BACKSPACE) && this.source.indexOf)
	{
		string save;
		if (scan == K_BACKSPACE)
			save = substring(this.typeToSearchString, 0, strlen(this.typeToSearchString) - 1);
		else
		{
			string ch = chr(ascii);
			save = (time > this.typeToSearchTime) ? ch : strcat(this.typeToSearchString, ch);
		}
		if (this.typeToSearchString)
			strunzone(this.typeToSearchString);
		this.typeToSearchString = strzone(save);
		this.typeToSearchTime = time + 0.5;
		if (strlen(this.typeToSearchString))
		{
			int idx = this.source.indexOf(this.source, this.typeToSearchString);
			if (idx >= 0)
				this.setSelected(this, idx);
		}
	}
	else if (shift & S_CTRL && scan == 'f')
		this.parent.setFocus(this.parent, this.stringFilterBox);
	else if (shift & S_CTRL && scan == 'u')
	{
		this.stringFilterBox.setText(this.stringFilterBox, "");
		if (this.stringFilter)
			strunzone(this.stringFilter);
		this.stringFilter = string_null;
		this.refilter(this);
	}
	return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
}

void XonoticEntryList_refilter(entity me)
{
	if (!me.source)
	{
		me.nItems = 0;
		return;
	}
	me.nItems = me.source.reload(me.source, me.stringFilter);
	for (int i = 0, n = me.nItems; i < n; ++i)
		if (me.source.getEntry(me.source, i, XonoticEntryList_cb))
			draw_PreloadPicture(XonoticEntryList_cb_icon);
}

void XonoticEntryList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticEntryList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize.y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize.x * (1 - me.controlWidth)));
	me.realUpperMargin1 = 0.5 * (1 - 2.5 * me.realFontSize.y);
	me.realUpperMargin2 = me.realUpperMargin1 + 1.5 * me.realFontSize.y;
}

void XonoticEntryList_setSelected(entity me, int i)
{
	SUPER(XonoticEntryList).setSelected(me, i);
	me.onChange(me, me.onChangeEntity);
}
