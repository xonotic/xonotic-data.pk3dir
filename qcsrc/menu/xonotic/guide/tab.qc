#include "tab.qh"

#include <menu/xonotic/inputbox.qh>
#include <menu/xonotic/maplist.qh>
#include <menu/xonotic/textlabel.qh>

void XonoticGuideTab_fill(entity this)
{
    entity topics = this.topicList;
        topics.onChange = XonoticGuideTab_topicChangeNotify;
        topics.onChangeEntity = this;
    entity entries = this.entryList;
        entries.onChange = XonoticGuideTab_entryChangeNotify;
        entries.onChangeEntity = this;
    entity filter = entries.stringFilterBox = makeXonoticInputBox(false, string_null);
        filter.keyDown = MapList_StringFilterBox_keyDown;
        filter.onChange = MapList_StringFilterBox_Change;
        filter.onChangeEntity = entries;
    entries.controlledTextbox = filter;
    entity description = this.descriptionPane;

    int
    col = 0, width = 1.5;
    this.gotoRC(this, 0, col);
        this.TD(this, 1, width, makeXonoticHeaderLabel(_("Topic")));
    this.TR(this);
        this.TD(this, this.rows - 1, width, topics);

    col += width, width = 2;
    this.gotoRC(this, 0, col); this.setFirstColumn(this, this.currentColumn);
        this.TD(this, 1, width, makeXonoticHeaderLabel(_("Entry")));
    this.TR(this);
        this.TD(this, this.rows - 1 - 1, width, entries);
    this.gotoRC(this, this.rows - 1, col);
        this.TD(this, 1, 0.3, makeXonoticTextLabel(0, _("Filter:")));
        this.TD(this, 1, width - 0.3, filter);

    col += width, width = 2.5;
    this.gotoRC(this, 0, col); this.setFirstColumn(this, this.currentColumn);
        this.TD(this, 1, width, makeXonoticHeaderLabel(_("Description")));
    this.TR(this);
        this.TD(this, this.rows - 1, width, description);

    this.topicChangeNotify(topics, this);
}

void XonoticGuideTab_topicChangeNotify(entity, entity this)
{
    entity topics = this.topicList;
    entity entries = this.entryList;
    int i = topics.selectedItem;
    int idx = 0;
    entity found = NULL;
    #define TOPIC(src, name, icon) if (idx++ == i) { static entity e; if (!e) e = src; found = e; break; }
    do { TOPICS(TOPIC); } while (0);
    #undef TOPIC
    entries.source = found;
    entries.refilter(entries);
    entries.setSelected(entries, 0);
}

void XonoticGuideTab_entryChangeNotify(entity, entity this)
{
    entity desc = this.descriptionPane;
    entity entries = this.entryList;
    entity e = entries.source.getEntry(entries.source, entries.selectedItem, func_null);
    string s = e.describe(e);
    if (cvar("developer")) { s = sprintf("entity %i\n%s", e, s); }
    desc.setDescription(desc, s);
}
