#include "dialog_media_guide.qh"

#include "button.qh"
#include "inputbox.qh"
#include "textlabel.qh"
#include <menu/xonotic/guide/entries.qh>

entity makeXonoticGuideTab()
{
	entity me;
	me = NEW(XonoticGuideTab);
	me.configureDialog(me);
	return me;
}
void XonoticGuideTab_fill(entity me)
{
	entity e;

	float col = 0;
	float width = 1.5;
	me.gotoRC(me, 0.5, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, me.rows - 0.5, width, e = me.topicList);
			e.onChange = XonoticGuideTab_topicChangeNotify;
			e.onChangeEntity = me;

	col += width;
	width = 1.75;
	me.gotoRC(me, 0.5, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, me.rows - 1.5, width, e = me.entryList);
			e.onChange = XonoticGuideTab_entryChangeNotify;
			e.onChangeEntity = me;
	me.gotoRC(me, me.rows - 1, col);
		me.entryList.stringFilterBox = makeXonoticInputBox_T(false, string_null,
			_("Click here or CTRL+F to provide a keyword to narrow down the list; CTRL+DEL to clear; ENTER when done."));
		me.TD(me, 1, 0.3, makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, width - 0.3, e = me.entryList.stringFilterBox);
			e.onChange = EntryList_StringFilterBox_Change;
			e.keyDown = EntryList_StringFilterBox_keyDown;
			e.onChangeEntity = me.entryList;

	col += width;
	width = 2.75;
	me.gotoRC(me, 0.5, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, me.rows - 0.5, width, me.descriptionPane);

	me.topicChangeNotify(me.topicList, me);
}

void XonoticGuideTab_topicChangeNotify(entity, entity me)
{
	entity entries = me.entryList;
	const int i = me.topicList.selectedItem;
	int idx = 0;
	entity found = NULL;
	#define TOPIC(src, name, icon) \
		if (idx++ == i) \
		{ \
			static entity e; \
			if (!e) \
				e = src; \
			found = e; \
			break; \
		}
	do { TOPICS(TOPIC); }
	while (0);
	#undef TOPIC
	entries.source = found;
	entries.selectedItem = -1; // signal that the source has changed
	entries.stringFilterBox.setText(entries.stringFilterBox, "");
	EntryList_StringFilterBox_Change(entries.stringFilterBox, entries); // this calls entries.refilter, which calls entries.setSelected, which calls entryChangeNotify
}
void XonoticGuideTab_entryChangeNotify(entity, entity me)
{
	entity entries = me.entryList;
	if (entries.nItems <= 0)
		return;
	entity e = entries.source.getEntry(entries.source, entries.selectedItem, func_null);
	me.descriptionPane.setDescription(me.descriptionPane, e.describe(e));
}
