#include "topictab.qh"

// Must be implemented by derivative classes
METHOD(XonoticTopicTabSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	return NULL;
}
METHOD(XonoticTopicTabSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	return NULL;
}
METHOD(XonoticTopicTabSource, reload, int(entity me, string filter))
{
	return 0;
}

string XonoticTopicTabList_cb_name;
string XonoticTopicTabList_cb_tooltip;
void XonoticTopicTabList_getNameIcon_cb(string _name, string _icon)
{
	XonoticTopicTabList_cb_name = _name;
}
void XonoticTopicTabList_getTooltip_cb(string _tooltip)
{
	XonoticTopicTabList_cb_tooltip = _tooltip;
}

METHOD(XonoticTopicTabList, drawListBoxItem, void(entity me, int i, vector absSize, bool isSelected, bool isFocused))
{
	if (!me.source || !me.source.getEntry(me.source, i, XonoticTopicTabList_getNameIcon_cb))
		return;
	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}
	string s = draw_TextShortenToWidth(strdecolorize(XonoticTopicTabList_cb_name), 1, 0, me.realFontSize);
	draw_Text(vec2(0.5 * me.realFontSize.x, me.realUpperMargin), s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

METHOD(XonoticTopicTabList, focusedItemChangeNotify, void(entity me))
{
	if (me.focusedItem < 0 || !me.source)
	{
		clearTooltip(me);
		return;
	}
	if (!me.source.getEntryTooltip(me, me.focusedItem, XonoticTopicTabList_getTooltip_cb))
	{
		clearTooltip(me);
		return;
	}
	string theTooltip = XonoticTopicTabList_cb_tooltip;
	if (theTooltip != "")
		setZonedTooltip(me, theTooltip, string_null);
	else
		clearTooltip(me);
}

METHOD(XonoticTopicTabList, refilter, void(entity me))
{
	if (!me.source)
	{
		me.nItems = 0;
		return;
	}
	me.nItems = me.source.reload(me.source, me.stringFilter);
}
METHOD(XonoticTopicTabList, resizeNotify, void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
	SUPER(XonoticTopicTabList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize = '0 0 0';
	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
}
METHOD(XonoticTopicTabList, setSelected, void(entity me, int i))
{
	SUPER(XonoticTopicTabList).setSelected(me, i);
	me.onChange(me, me.onChangeEntity);
}


METHOD(XonoticTopicTab, topicChangeNotify, void(entity, entity me))
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
void XonoticTopicTab_fill(entity me)
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
