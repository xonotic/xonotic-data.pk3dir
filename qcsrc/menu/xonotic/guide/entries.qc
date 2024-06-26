#include "entries.qh"

#include <menu/xonotic/listbox.qh>
#include <menu/xonotic/inputbox.qh>
#include <menu/xonotic/mainwindow.qh>

string XonoticEntryList_cb_name, XonoticEntryList_cb_icon;
void XonoticEntryList_cb(string _name, string _icon) {
    XonoticEntryList_cb_name = _name;
    XonoticEntryList_cb_icon = _icon;
}

void XonoticEntryList_drawListBoxItem(entity this, int i, vector absSize, bool isSelected, bool isFocused)
{
    if (!this.source) return;
    if (!this.source.getEntry(this.source, i, XonoticEntryList_cb)) return;
    string name = XonoticEntryList_cb_name;
    string icon = XonoticEntryList_cb_icon;
    if (isSelected) {
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
    } else if (isFocused) {
        this.focusedItemAlpha = getFadedAlpha(this.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, this.focusedItemAlpha);
    }
    vector sz = draw_PictureSize(icon);
    if (!sz) sz = '1 1 0';
    float szr = sz.x / sz.y;
    if (strstrofs(icon, "map", 0) >= 0) szr = 4 / 3;
    float asr = this.itemAbsSize.x / this.itemAbsSize.y;
    sz.y = 1; sz.x = szr / asr;
    draw_Picture('0 0 0', icon, sz, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
    string s = draw_TextShortenToWidth(strdecolorize(name), 1 - sz.x - 2 * this.realFontSize.x, 0, this.realFontSize);
    draw_Text(this.realUpperMargin1 * eY + (sz.x + 0.5 * this.realFontSize.x) * eX, s, this.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

METHOD(XonoticEntryList, keyDown, float(entity this, float scan, float ascii, float shift))
{
    if (this.nItems <= 0) {
        return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
    } else if ((ascii >= 32 || scan == K_BACKSPACE) && this.source.indexOf) {
        string save;
        if (scan == K_BACKSPACE) {
            save = substring(this.typeToSearchString, 0, strlen(this.typeToSearchString) - 1);
        } else {
            string ch = chr(ascii);
            save = (time > this.typeToSearchTime) ? ch : strcat(this.typeToSearchString, ch);
        }
        if (this.typeToSearchString) strunzone(this.typeToSearchString);
        this.typeToSearchString = strzone(save);
        this.typeToSearchTime = time + 0.5;
        if (strlen(this.typeToSearchString)) {
            int idx = this.source.indexOf(this.source, this.typeToSearchString);
            if (idx >= 0) this.setSelected(this, idx);
        }
    } else if (shift & S_CTRL && scan == 'f') {
        this.parent.setFocus(this.parent, this.stringFilterBox);
    } else if (shift & S_CTRL && scan == 'u') {
        this.stringFilterBox.setText(this.stringFilterBox, "");
        if (this.stringFilter) strunzone(this.stringFilter);
        this.stringFilter = string_null;
        this.refilter(this);
    }
    return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
}

void XonoticEntryList_refilter(entity this)
{
    if (!this.source) {
        this.nItems = 0;
        return;
    }
    this.nItems = this.source.reload(this.source, this.stringFilter);
    for (int i = 0, n = this.nItems; i < n; ++i) {
        if (this.source.getEntry(this.source, i, XonoticEntryList_cb)) {
            draw_PreloadPicture(XonoticEntryList_cb_icon);
        }
    }
}

void XonoticEntryList_resizeNotify(entity this, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
    this.itemAbsSize = '0 0 0';
    SUPER(XonoticEntryList).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

    this.realFontSize_y = this.fontSize / (this.itemAbsSize_y = (absSize.y * this.itemHeight));
    this.realFontSize_x = this.fontSize / (this.itemAbsSize_x = (absSize.x * (1 - this.controlWidth)));
    this.realUpperMargin1 = 0.5 * (1 - 2.5 * this.realFontSize.y);
    this.realUpperMargin2 = this.realUpperMargin1 + 1.5 * this.realFontSize.y;
}

void XonoticEntryList_setSelected(entity this, int i)
{
    SUPER(XonoticEntryList).setSelected(this, i);
    this.onChange(this, this.onChangeEntity);
}
