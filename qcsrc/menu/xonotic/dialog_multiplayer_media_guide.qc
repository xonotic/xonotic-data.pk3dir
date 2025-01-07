#include "dialog_multiplayer_media_guide.qh"

#include "inputbox.qh"
#include "textlabel.qh"
#include <menu/xonotic/guide/entries.qh>

void XonoticGuideDialog_fill(entity me)
{
	entity e;

	int col = 0, width = 1.5;
	me.gotoRC(me, 0, col);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Topic")));
	me.TR(me);
		me.TD(me, me.rows - 1, width, e = me.topicList);
			e.onChange = XonoticGuideDialog_topicChangeNotify;
			e.onChangeEntity = me;

	col += width, width = 2;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Entry")));
	me.TR(me);
		me.TD(me, me.rows - 1 - 1, width, e = me.entryList);
			e.onChange = XonoticGuideDialog_entryChangeNotify;
			e.onChangeEntity = me;
	me.gotoRC(me, me.rows - 1, col);
		me.entryList.stringFilterBox = makeXonoticInputBox_T(false, string_null,
			_("Click here or Ctrl-F to provide a keyword to narrow down the map list. Ctrl-Delete to clear; Enter when done."));
		me.TD(me, 1, 0.3, makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, width - 0.3, e = me.entryList.stringFilterBox);
			e.onChange = EntryList_StringFilterBox_Change;
			e.keyDown = EntryList_StringFilterBox_keyDown;
			e.onChangeEntity = me.entryList;

	col += width, width = 2.5;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Description")));
	me.TR(me);
		me.TD(me, me.rows - 1, width, me.descriptionPane);

	me.topicChangeNotify(me.topicList, me);
}

void XonoticGuideDialog_topicChangeNotify(entity, entity me)
{
	entity topics = me.topicList;
	entity entries = me.entryList;
	int i = topics.selectedItem;
	int idx = 0;
	entity found = NULL;
	#define TOPIC(src, name, icon) \
		if (idx++ == i) \
		{ \
			static entity e; \
			if (!e) e = src; \
			found = e; \
			break; \
		}
	do { TOPICS(TOPIC); }
	while (0);
	#undef TOPIC
	entries.source = found;
	entries.refilter(entries);
	entries.setSelected(entries, 0);
}
void XonoticGuideDialog_entryChangeNotify(entity, entity me)
{
	entity desc = me.descriptionPane;
	entity entries = me.entryList;
	entity e = entries.source.getEntry(entries.source, entries.selectedItem, func_null);
	string s = e.describe(e);
	if (gamestatus & GAME_DEVELOPER)
		s = sprintf("entity %i\n\n%s", e, s);
	desc.setDescription(desc, s);
}
