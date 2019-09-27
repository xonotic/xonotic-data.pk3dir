#include "dialog_settings_game.qh"

#include "../gamesettings.qh"

METHOD(SettingSource, getEntry, entity(entity this, int i, void(string name, string icon) returns))
{
    Lazy l = Settings_from(i);
    entity it = l.m_get();
    if (returns) returns(it.title, string_null);
    return it;
}
METHOD(SettingSource, getEntryTooltip, entity(entity this, int i, void(string theTooltip) returns))
{
    Lazy l = Settings_from(i);
    entity it = l.m_get();
    if (returns) returns(it.titleTooltip);
    return it;
}
METHOD(SettingSource, reload, int(entity this, string filter)) { return Settings_COUNT; }

string XonoticRegisteredSettingsList_cb_name;
string XonoticRegisteredSettingsList_cb_tooltip;
void XonoticRegisteredSettingsList_getNameIcon_cb(string _name, string _icon)
{
    XonoticRegisteredSettingsList_cb_name = _name;
}
void XonoticRegisteredSettingsList_getTooltip_cb(string _tooltip)
{
    XonoticRegisteredSettingsList_cb_tooltip = _tooltip;
}

METHOD(XonoticRegisteredSettingsList, drawListBoxItem, void(entity this, int i, vector absSize, bool isSelected, bool isFocused))
{
    if (!this.source) return;
    if (!this.source.getEntry(this.source, i, XonoticRegisteredSettingsList_getNameIcon_cb)) return;
    string name = XonoticRegisteredSettingsList_cb_name;
    if (isSelected) {
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
    } else if (isFocused) {
        this.focusedItemAlpha = getFadedAlpha(this.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, this.focusedItemAlpha);
    }
    string s = draw_TextShortenToWidth(strdecolorize(name), 1, 0, this.realFontSize);
    draw_Text(this.realUpperMargin * eY + (0.5 * this.realFontSize.x) * eX, s, this.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

METHOD(XonoticRegisteredSettingsList, focusedItemChangeNotify, void(entity this))
{
    if (this.focusedItem == -1 || !this.source)
    {
        clearTooltip(this);
        return;
    }
    if (!this.source.getEntryTooltip(this, this.focusedItem, XonoticRegisteredSettingsList_getTooltip_cb))
    {
        clearTooltip(this);
        return;
    }
    string theTooltip = XonoticRegisteredSettingsList_cb_tooltip;
    if(theTooltip != "")
        setZonedTooltip(this, theTooltip, string_null);
    else
        clearTooltip(this);
}

METHOD(XonoticRegisteredSettingsList, refilter, void(entity this))
{
    if (!this.source) {
        this.nItems = 0;
        return;
    }
    this.nItems = this.source.reload(this.source, this.stringFilter);
}
METHOD(XonoticRegisteredSettingsList, resizeNotify, void(entity this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
    SUPER(XonoticRegisteredSettingsList).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

    this.itemAbsSize = '0 0 0';
    this.realFontSize_y = this.fontSize / (this.itemAbsSize_y = (absSize.y * this.itemHeight));
    this.realFontSize_x = this.fontSize / (this.itemAbsSize_x = (absSize.x * (1 - this.controlWidth)));
    this.realUpperMargin = 0.5 * (1 - this.realFontSize.y);
}
METHOD(XonoticRegisteredSettingsList, setSelected, void(entity this, int i))
{
    SUPER(XonoticRegisteredSettingsList).setSelected(this, i);
    this.onChange(this, this.onChangeEntity);
}
CONSTRUCTOR(XonoticRegisteredSettingsList, DataSource _source) {
    CONSTRUCT(XonoticRegisteredSettingsList);
    this.source = _source;
    this.configureXonoticListBox(this);
    this.refilter(this);
}

METHOD(XonoticGameSettingsTab, topicChangeNotify, void(entity, entity this))
{
	entity s = NULL;
	entity c = this.currentPanel;
	if (c.classname == "XonoticScrollPanel")
	{
		s = this.currentPanel;
		s.viewportHeight = 15.5;
		c = s.currentPanel;
	}

    entity removing = this.currentItem;
    DataSource data = this.topicList.source;
    entity adding = data.getEntry(data, this.topicList.selectedItem, func_null);
    if (removing == adding) return;
    if (removing) {
        this.currentItem = NULL;
        c.removeItem(c, removing);
    }
    if (adding) {
        this.currentItem = adding;
        adding.resizeNotify(adding, '0 0 0', c.size, '0 0 0', c.size);
        c.addItem(c, adding, '0 0 0', '1 1 0', 1);
		if (s)
			s.resizeNotify(s, '0 0 0', s.size, '0 0 0', s.size);
    }
}
METHOD(XonoticGameSettingsTab, fill, void(entity this))
{
    entity topics = this.topicList;
        topics.onChange = this.topicChangeNotify;
        topics.onChangeEntity = this;

    int
    col = 0, width = 1;
    this.gotoRC(this, 0, col);
        this.TD(this, this.rows, width, topics);

    col += width, width = this.columns - col;
    this.gotoRC(this, 0, col); this.setFirstColumn(this, this.currentColumn);
        this.TD(this, this.rows, width, this.currentPanel);

    this.topicChangeNotify(topics, this);
}
