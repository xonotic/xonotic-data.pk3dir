#include "dialog_multiplayer_create_mutators.qh"
#include <common/weapons/_all.qh>

#include "textbox.qh"
#include "textlabel.qh"
#include "button.qh"

const string MUTATOR_ENABLED_ICON = "/gfx/scoreboard/player_ready";


METHOD(MenuMutatorSource, getEntry, entity(entity me, int i, void(string name, string description) returns))
{
	if (i == MENU_MUTATOR_HEADER_1 || i == MENU_MUTATOR_HEADER_2)
	{
		if (returns)
			returns((i == MENU_MUTATOR_HEADER_1 ? _("Weapon & item mutators:") : _("Gameplay mutators:")), "");
		return NULL;
	}
	if (i > MENU_MUTATOR_HEADER_2)
		--i;
	if (i > MENU_MUTATOR_HEADER_1)
		--i;
	Lazy l = REGISTRY_GET(MenuMutators, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, it.describe(it));
	return it;
}
METHOD(MenuMutatorSource, getEntryOther, entity(entity me, int i, void(bool show_tick, bool disabled, string tree) returns))
{
	string tree_type;
	if (i + 1 == REGISTRY_COUNT(MenuMutators) + 2 || i + 1 == MENU_MUTATOR_HEADER_2)
		tree_type = "tree_elbow";
	else if (i == MENU_MUTATOR_HEADER_1 + 1 || i == MENU_MUTATOR_HEADER_2 + 1)
		tree_type = "tree_branch_start";
	else
		tree_type = "tree_branch";

	if (i > MENU_MUTATOR_HEADER_2)
		--i;
	if (i > MENU_MUTATOR_HEADER_1)
		--i;
	Lazy l = REGISTRY_GET(MenuMutators, i);
	entity it = l.m_get();
	// canEnable with input true returns whether the mutator is enabled currently,
	// input false returns whether the mutator can be enabled (all prerequisite cvars set correctly)
	if (returns)
		returns(it.canEnable(it, true), !it.canEnable(it, false), tree_type);
	return it;
}

METHOD(MenuMutatorSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(MenuMutators) + 2; // two headers
}

string XonoticRegisteredMutatorsList_cb_name;
string XonoticRegisteredMutatorsList_cb_description;
void XonoticRegisteredMutatorsList_getNameDescription_cb(string _name, string _description)
{
	XonoticRegisteredMutatorsList_cb_name = _name;
	XonoticRegisteredMutatorsList_cb_description = _description;
}

bool XonoticRegisteredMutatorsList_cb_show_tick;
bool XonoticRegisteredMutatorsList_cb_disabled;
string XonoticRegisteredMutatorsList_cb_tree;
void XonoticRegisteredMutatorsList_getOther_cb(bool _show_tick, bool _disabled, string _tree)
{
	XonoticRegisteredMutatorsList_cb_show_tick = _show_tick;
	XonoticRegisteredMutatorsList_cb_disabled = _disabled;
	XonoticRegisteredMutatorsList_cb_tree = _tree;
}

entity makeXonoticRegisteredMutatorsList()
{
	entity me = NEW(XonoticRegisteredMutatorsList);
	me.configureXonoticListBox(me);
	me.refilter(me);
	me.setSelected(me, MENU_MUTATOR_HEADER_1 + 1);
	return me;
}

METHOD(XonoticRegisteredMutatorsList, drawListBoxItem, void(entity me, int i, vector absSize, bool isSelected, bool isFocused))
{
	if (!me.source)
		return;
	me.source.getEntry(me.source, i, XonoticRegisteredMutatorsList_getNameDescription_cb);
	if (XonoticRegisteredMutatorsList_cb_description != "") // no description means it's a header
	{
		if (isSelected)
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
		else if (isFocused)
		{
			me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
		}
	}

	vector theColor;
	float theAlpha, nameSize, nameOrigin;
	if (XonoticRegisteredMutatorsList_cb_description == "")
	{
		theColor = SKINCOLOR_MUTATORS_TITLES;
		theAlpha = SKINALPHA_MUTATORS_TITLES;
		nameSize = 1;
		nameOrigin = 0;
	}
	else
	{
		nameSize = me.columnNameSize;
		nameOrigin = me.columnNameOrigin;
		me.source.getEntryOther(me.source, i, XonoticRegisteredMutatorsList_getOther_cb);
		if (XonoticRegisteredMutatorsList_cb_show_tick) // draw check if mutator is enabled
			draw_Picture(me.columnIconOrigin * eX, MUTATOR_ENABLED_ICON, me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
		if (XonoticRegisteredMutatorsList_cb_disabled) // draw text darker if mutator can't be enabled
		{
			theColor = SKINCOLOR_MUTATORS_DISABLED;
			theAlpha = SKINALPHA_MUTATORS_DISABLED;
		}
		else
		{
			theColor = SKINCOLOR_MUTATORS_ENTRIES;
			theAlpha = SKINALPHA_MUTATORS_ENTRIES;
		}
		// draw tree
		draw_Picture('0 0 0', sprintf("/gfx/menu/%s/%s", cvar_string("menu_skin"), XonoticRegisteredMutatorsList_cb_tree),
			me.columnTreeIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
	}

	string s = draw_TextShortenToWidth(strdecolorize(XonoticRegisteredMutatorsList_cb_name), nameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + nameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

METHOD(XonoticRegisteredMutatorsList, refilter, void(entity me))
{
	if (!me.source)
	{
		me.nItems = 0;
		return;
	}
	me.nItems = me.source.reload(me.source, "");
}

METHOD(XonoticRegisteredMutatorsList, resizeNotify, void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
	SUPER(XonoticRegisteredMutatorsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize = '0 0 0';
	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x;
	me.columnIconOrigin = 1 - me.columnIconSize;
	me.columnTreeIconSize = me.columnIconSize; // 1:1 aspect ratio
	me.columnNameOrigin = me.columnTreeIconSize + 0.5 * me.realFontSize.x;
	me.columnNameSize = me.columnIconOrigin - me.columnNameOrigin - me.realFontSize.x;
}

METHOD(XonoticRegisteredMutatorsList, setSelected, void(entity me, int i))
{
	i = bound(0, i, me.nItems - 1);
	me.source.getEntry(me.source, i, XonoticRegisteredMutatorsList_getNameDescription_cb);

	// handling of "unselectable" items
	// skip over unselectables if selected via keyboard, otherwise ignore mouse input
	if (!me.pressed)
	{
		if (i < me.previouslySelected)
		{
			while ((i > 0) && XonoticRegisteredMutatorsList_cb_description == "")
				me.source.getEntry(me.source, --i, XonoticRegisteredMutatorsList_getNameDescription_cb);
		}
		else
		{
			while ((i < me.nItems - 1) && XonoticRegisteredMutatorsList_cb_description == "")
				me.source.getEntry(me.source, ++i, XonoticRegisteredMutatorsList_getNameDescription_cb);
		}
	}
	if (XonoticRegisteredMutatorsList_cb_description == "")
		i = me.previouslySelected;
	else
		me.previouslySelected = i;

	SUPER(XonoticRegisteredMutatorsList).setSelected(me, i);
	if (me.onChange)
		me.onChange(me, me.onChangeEntity);
}


entity makeXonoticMutatorsDialog()
{
	entity me = NEW(XonoticMutatorsDialog);
	me.configureDialog(me);
	return me;
}

METHOD(XonoticMutatorsDialog, topicChangeNotify, void(entity, entity me))
{
	entity s = NULL;
	entity c = me.currentPanel;

	entity removing = me.currentItem;
	DataSource data = me.topicList.source;
	entity adding = data.getEntry(data, me.topicList.selectedItem, XonoticRegisteredMutatorsList_getNameDescription_cb);
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

	me.currentItem.showNotify(me.currentItem);
	me.labelTitle.setText(me.labelTitle, XonoticRegisteredMutatorsList_cb_name);
	me.descriptionLabel.setText(me.descriptionLabel, strcat("\n", XonoticRegisteredMutatorsList_cb_description, "\n"));
}

void XonoticMutatorsDialog_fill(entity me)
{
	entity topics = me.topicList;
		topics.onChange = me.topicChangeNotify;
		topics.onChangeEntity = me;
	entity e;

	int col = 0;
	int width = 1.75;
	me.gotoRC(me, 0, col);
		me.TD(me, me.rows - 1.5, width, topics);

	col += width + 0.1;
	width = me.columns - col;
	me.gotoRC(me, 0, col); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, width, me.labelTitle = makeXonoticHeaderLabel(""));
	me.TR(me);
		me.TD(me, me.rows - 6.5, width, me.currentPanel);
	me.gotoRC(me, me.rows - 5.5, col);
		me.TD(me, 4, width, e = makeXonoticTextBox());
			e.align = 0.5;
			e.allowColors = true;
			me.descriptionLabel = e;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;

	me.topicChangeNotify(topics, me);
}

void XonoticMutatorsDialog_close(entity me)
{
	if (me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	SUPER(XonoticMutatorsDialog).close(me);
}
