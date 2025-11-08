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

entity EntryList_Set_StringFilterBox(entity me, entity e)
{
	me.stringFilterBox = e;
	return e;
}

void XonoticEntryList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if (!me.source)
		return;
	if (!me.source.getEntry(me.source, i, XonoticEntryList_cb))
		return;

	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	vector sz;
	if (XonoticEntryList_cb_icon == "" || draw_PreloadPicture(XonoticEntryList_cb_icon) == "")
		sz = me.rowsPerItem * 0.5 * me.realFontSize.x * eX;
	else
	{
		sz = draw_PictureSize(XonoticEntryList_cb_icon);
		if (!sz)
			sz = '1 1 0';
		float szr = sz.x / sz.y;
		//if (strstrofs(XonoticEntryList_cb_icon, "map", 0) >= 0)
			//szr = 4 / 3;
		const float asr = me.itemAbsSize.x / me.itemAbsSize.y;
		sz.y = 1;
		sz.x = szr / asr;
		draw_Picture('0 0 0', XonoticEntryList_cb_icon, sz, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
		sz.x += 0.5 * me.realFontSize.x;
	}

	// display maximum 2 lines, last potentially truncated, vertically centered
	string s;
	vector pos = me.realUpperMargin * eY + sz.x * eX;
	const float maxWidth = 1 - sz.x - me.realFontSize.x;
	getWrappedLine_remaining = strdecolorize(XonoticEntryList_cb_name);
	s = getWrappedLine(maxWidth, me.realFontSize, draw_TextWidth_WithoutColors);
	if (getWrappedLine_remaining)
	{
		pos.y -= 0.5 * me.realFontSize.y;
		draw_Text(pos, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, false);
		s = draw_TextShortenToWidth(getWrappedLine_remaining, maxWidth, false, me.realFontSize);
		pos.y += me.realFontSize.y;
	}
	draw_Text(pos, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, false);
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
			const string ch = chr(ascii);
			save = (time > this.typeToSearchTime) ? ch : strcat(this.typeToSearchString, ch);
		}
		if (this.typeToSearchString)
			strunzone(this.typeToSearchString);
		this.typeToSearchString = strzone(save);
		this.typeToSearchTime = time + 0.5;
		if (strlen(this.typeToSearchString))
		{
			const int idx = this.source.indexOf(this.source, this.typeToSearchString);
			if (idx >= 0)
				this.setSelected(this, idx);
		}
	}
	else if ((shift & S_CTRL) && scan == 'f') // ctrl-f (as in "F"ind)
	{
		this.parent.setFocus(this.parent, this.stringFilterBox);
	}
	else if ((shift & S_CTRL) && scan == 'u') // ctrl-u (remove stringFilter line)
	{
		this.stringFilterBox.setText(this.stringFilterBox, "");
		EntryList_StringFilterBox_Change(this.stringFilterBox, this);
	}
	return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
}

float EntryList_StringFilterBox_keyDown(entity me, float scan, float ascii, float shift)
{
	// in this section, note that onChangeEntity has the ref to entryList
	// we make use of that, instead of extending a class to add one more attrib
	switch (scan)
	{
		case K_KP_ENTER:
		case K_ENTER:
			// move the focus to the entryList
			me.onChangeEntity.parent.setFocus(me.onChangeEntity.parent, me.onChangeEntity);
			return 1;
		case K_KP_UPARROW:
		case K_UPARROW:
		case K_KP_DOWNARROW:
		case K_DOWNARROW:
			// pass the event to the entryList (to scroll up and down)
			return me.onChangeEntity.keyDown(me.onChangeEntity, scan, ascii, shift);
	}
	return SUPER(XonoticInputBox).keyDown(me, scan, ascii, shift);
}

void XonoticEntryList_refilter(entity me)
{
	if (!me.source)
	{
		me.nItems = 0;
		return;
	}
	string oldName;
	if (me.selectedItem >= 0) // if negative we just switched source
	{
		me.source.getEntry(me.source, me.selectedItem, XonoticEntryList_cb);
		oldName = XonoticEntryList_cb_name; // keep oldName selected if still present
	}
	else
		oldName = "";

	int newSelectedItem = 0;
	me.nItems = me.source.reload(me.source, me.stringFilter);
	for (int i = 0, n = me.nItems; i < n; ++i)
		if (me.source.getEntry(me.source, i, XonoticEntryList_cb))
		{
			if (XonoticEntryList_cb_icon != "")
				draw_PreloadPicture(XonoticEntryList_cb_icon);
			if (XonoticEntryList_cb_name == oldName)
				newSelectedItem = i;
		}
	me.setSelected(me, newSelectedItem);
}

void EntryList_StringFilterBox_Change(entity box, entity me)
{
	strfree(me.stringFilter);
	if (box.text != "")
		me.stringFilter = strzone(box.text);

	me.refilter(me);
}

void XonoticEntryList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticEntryList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
}

void XonoticEntryList_setSelected(entity me, int i)
{
	SUPER(XonoticEntryList).setSelected(me, i);
	me.onChange(me, me.onChangeEntity);
}
