#include "topics.qh"

#include "entries.qh"

void XonoticTopicList_clickListBoxItem(entity this, float i, vector where)
{
    m_play_click_sound(MENU_SOUND_SELECT);
}

string XonoticTopicList_cb_name, XonoticTopicList_cb_icon;
void XonoticTopicList_cb(string _name, string _icon) {
    XonoticTopicList_cb_name = _name;
    XonoticTopicList_cb_icon = _icon;
}

void XonoticTopicList_drawListBoxItem(entity this, int i, vector absSize, bool isSelected, bool isFocused)
{
    if (!this.source) return;
    if (!this.source.getEntry(this.source, i, XonoticTopicList_cb)) return;
    string icon = XonoticTopicList_cb_icon;
    string name = XonoticTopicList_cb_name;
    if (isSelected) {
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
    } else if (isFocused) {
        this.focusedItemAlpha = getFadedAlpha(this.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, this.focusedItemAlpha);
    }
    draw_Picture(this.columnIconOrigin * eX, icon, this.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
    vector save_fontscale = draw_fontscale;
    float f = draw_CondensedFontFactor(name, false, this.realFontSize, 1);
    draw_fontscale.x *= f;
    vector fs = this.realFontSize;
    fs.x *= f;
    draw_Text(this.realUpperMargin * eY + this.columnNameOrigin * eX, name, fs, '1 1 1', SKINALPHA_TEXT, 0);
    draw_fontscale = save_fontscale;
}

bool XonoticTopicList_keyDown(entity this, float scan, float ascii, float shift)
{
    if (scan == K_ENTER || scan == K_KP_ENTER) {
        m_play_click_sound(MENU_SOUND_EXECUTE);
        return true;
    }
    return SUPER(XonoticEntryList).keyDown(this, scan, ascii, shift);
}

void XonoticTopicList_resizeNotify(entity this, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
    this.itemAbsSize = '0 0 0';
    SUPER(XonoticEntryList).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

    this.realFontSize_y = this.fontSize / (this.itemAbsSize_y = (absSize.y * this.itemHeight));
    this.realFontSize_x = this.fontSize / (this.itemAbsSize_x = (absSize.x * (1 - this.controlWidth)));
    this.realUpperMargin = 0.5 * (1 - this.realFontSize.y);
    this.columnIconOrigin = 0;
    this.columnIconSize = this.itemAbsSize.y / this.itemAbsSize.x;
    this.columnNameOrigin = this.columnIconOrigin + this.columnIconSize + (0.5 * this.realFontSize.x);
    this.columnNameSize = 1 - this.columnIconSize - (1.5 * this.realFontSize.x);
}

void XonoticTopicList_setSelected(entity this, int i)
{
    SUPER(XonoticEntryList).setSelected(this, i);
    this.onChange(this, this.onChangeEntity);
}
