#include "dialog_settings_game.qh"

METHOD(SettingSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	Lazy l = REGISTRY_GET(Settings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, string_null);
	return it;
}
METHOD(SettingSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	Lazy l = REGISTRY_GET(Settings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.titleTooltip);
	return it;
}
METHOD(SettingSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(Settings);
}

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

METHOD(XonoticRegisteredSettingsList, drawListBoxItem, void(entity me, int i, vector absSize, bool isSelected, bool isFocused))
{
	if (!me.source || !me.source.getEntry(me.source, i, XonoticRegisteredSettingsList_getNameIcon_cb))
		return;
	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}
	string s = draw_TextShortenToWidth(strdecolorize(XonoticRegisteredSettingsList_cb_name), 1, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (0.5 * me.realFontSize.x) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

METHOD(XonoticRegisteredSettingsList, focusedItemChangeNotify, void(entity me))
{
	if (me.focusedItem < 0 || !me.source)
	{
		clearTooltip(me);
		return;
	}
	if (!me.source.getEntryTooltip(me, me.focusedItem, XonoticRegisteredSettingsList_getTooltip_cb))
	{
		clearTooltip(me);
		return;
	}
	string theTooltip = XonoticRegisteredSettingsList_cb_tooltip;
	if (theTooltip != "")
		setZonedTooltip(me, theTooltip, string_null);
	else
		clearTooltip(me);
}

METHOD(XonoticRegisteredSettingsList, refilter, void(entity me))
{
	if (!me.source)
	{
		me.nItems = 0;
		return;
	}
	me.nItems = me.source.reload(me.source, me.stringFilter);
}
METHOD(XonoticRegisteredSettingsList, resizeNotify, void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
	SUPER(XonoticRegisteredSettingsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize = '0 0 0';
	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
}
METHOD(XonoticRegisteredSettingsList, setSelected, void(entity me, int i))
{
	SUPER(XonoticRegisteredSettingsList).setSelected(me, i);
	me.onChange(me, me.onChangeEntity);
}


entity makeXonoticGameSettingsTab()
{
	entity me = NEW(XonoticGameSettingsTab);
	me.configureDialog(me);
	return me;
}
METHOD(XonoticGameSettingsTab, topicChangeNotify, void(entity, entity me))
{
	entity s = NULL;
	entity c = me.currentPanel;
	if (c.classname == "XonoticScrollPanel")
	{
		s = me.currentPanel;
		s.viewportHeight = 15.5;
		c = s.currentPanel;
	}

	entity removing = me.currentItem;
	DataSource data = me.topicList.source;
	entity adding = data.getEntry(data, me.topicList.selectedItem, func_null);
	if (removing == adding)
		return;
	if (removing)
	{
		me.currentItem = NULL;
		c.removeItem(c, removing);
	}
	if (adding)
	{
		me.currentItem = adding;
		adding.resizeNotify(adding, '0 0 0', c.size, '0 0 0', c.size);
		c.addItem(c, adding, '0 0 0', '1 1 0', 1);
		if (s)
			s.resizeNotify(s, '0 0 0', s.size, '0 0 0', s.size);
	}
}
void XonoticGameSettingsTab_fill(entity me)
{
	entity topics = me.topicList;
		topics.onChange = me.topicChangeNotify;
		topics.onChangeEntity = me;

	int col = 0;
	int width = 1;
	me.gotoRC(me, 0, col);
		me.TD(me, me.rows, width, topics);

	col += width;
	width = me.columns - col;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, me.rows, width, me.currentPanel);

	me.topicChangeNotify(topics, me);
}
