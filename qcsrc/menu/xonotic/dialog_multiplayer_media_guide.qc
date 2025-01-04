#include "dialog_multiplayer_media_guide.qh"

#include "inputbox.qh"
#include "maplist.qh"
#include "textlabel.qh"

void XonoticGuideTab_fill(entity me)
{
	entity topics = me.topicList;
		topics.onChange = XonoticGuideTab_topicChangeNotify;
		topics.onChangeEntity = me;
	entity entries = me.entryList;
		entries.onChange = XonoticGuideTab_entryChangeNotify;
		entries.onChangeEntity = me;
	entity filter = entries.stringFilterBox = makeXonoticInputBox(false, string_null);
		filter.keyDown = MapList_StringFilterBox_keyDown;
		filter.onChange = MapList_StringFilterBox_Change;
		filter.onChangeEntity = entries;
	entries.controlledTextbox = filter;
	entity description = me.descriptionPane;

	int
	col = 0, width = 1.5;
	me.gotoRC(me, 0, col);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Topic")));
	me.TR(me);
		me.TD(me, me.rows - 1, width, topics);

	col += width, width = 2;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Entry")));
	me.TR(me);
		me.TD(me, me.rows - 1 - 1, width, entries);
	me.gotoRC(me, me.rows - 1, col);
		me.TD(me, 1, 0.3, makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, width - 0.3, filter);

	col += width, width = 2.5;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, width, makeXonoticHeaderLabel(_("Description")));
	me.TR(me);
		me.TD(me, me.rows - 1, width, description);

	me.topicChangeNotify(topics, me);
}

void XonoticGuideTab_topicChangeNotify(entity, entity me)
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

void XonoticGuideTab_entryChangeNotify(entity, entity me)
{
	entity desc = me.descriptionPane;
	entity entries = me.entryList;
	entity e = entries.source.getEntry(entries.source, entries.selectedItem, func_null);
	string s = e.describe(e);
	if (gamestatus & GAME_DEVELOPER)
		s = sprintf("entity %i\n\n%s", e, s);
	desc.setDescription(desc, s);
}
