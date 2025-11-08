#include "dialog_multiplayer_create.qh"

#include "dialog_multiplayer_create_mapinfo.qh"
#include "dialog_multiplayer_create_mutators.qh"

#include "gametypelist.qh"
#include "maplist.qh"
#include <common/mapinfo.qh>

#include "checkbox.qh"
#include "image.qh"
#include "mixedslider.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "mainwindow.qh"
#include "button.qh"
#include "commandbutton.qh"
#include "leavematchbutton.qh"
#include "inputbox.qh"

void GameType_ConfigureSliders(entity me, string pLabel, float pMin, float pMax, float pStep, string pCvar, string tCvar, string pTooltip)
{
	int i;
	entity e = me.sliderFraglimit;
	entity l = me.labelFraglimit;
	e.configureXonoticMixedSlider(e, pCvar, pTooltip);
	e.disabled = l.disabled = !pCvar;
	l.setText(l, pLabel);

	// clear old values
	for(i = 0; i < e.nValues; ++i);
		strfree(e.(valueStrings[i]));
	e.clearValues(e);

	if(pCvar != "")
	{
		// set new values
		e.addText(e, strzone(_("Default")), -1);
		e.addRange(e, pMin, pMax, pStep);
		e.addText(e, strzone(_("Unlimited")), 0);
	}
	e.configureXonoticMixedSliderValues(e);


	entity t = me.sliderTeams;
	entity tl = me.labelTeams;
	t.configureXonoticMixedSlider(t, tCvar, string_null);
	tl.disabled = t.disabled = !tCvar;
	t.nValues = (tCvar == "") ? 0 : 4; // instead of clearing / readding the very same values
	t.configureXonoticMixedSliderValues(t);
}

void GameType_ConfigureSliders_for_CurrentGametype(entity me)
{
	Gametype gt = MapInfo_CurrentGametype();
	gt.m_configuremenu(gt, me, GameType_ConfigureSliders);
}

entity makeXonoticServerCreateTab()
{
	entity me;
	me = NEW(XonoticServerCreateTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerCreateTab_fill(entity me)
{
	entity e, e0;

	// the left half begins here

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 3, makeXonoticHeaderLabel(_("Gametype")));
	me.TR(me);
		me.TD(me, 10.5, 3, e = makeXonoticGametypeList());

	me.gotoRC(me, 12, 0);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "menu_create_show_all", _("Show all"),
			_("Show all available gametypes")));
	me.gotoRC(me, 13.5, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Time limit:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("timelimit_override",
			_("Time limit in minutes that when hit, will end the match")));
			e.formatString = "m";
			e.addText(e, ZCTX(_("TIMLIM^Default")), -1);
			e.addRange(e, 1, 10, 1);
			e.addRange(e, 15, 30, 5);
			e.addRange(e, 40, 60, 10);
			e.addText(e, ZCTX(_("TIMLIM^Infinite")), 0);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, me.labelFraglimit = makeXonoticTextLabel(0, _("Frag limit:")));
		me.TD(me, 1, 2, e = me.sliderFraglimit = makeXonoticMixedSlider("fraglimit_override"));

	me.gotoRC(me, 16, 0);
		me.TD(me, 1, 1, me.labelTeams = makeXonoticTextLabel(0, _("Teams:")));
		me.TD(me, 1, 2, e = me.sliderTeams = makeXonoticMixedSlider(string_null));
			e.addText(e, _("Default"), 0);
			e.addText(e, _("2 teams"), 2);
			e.addText(e, _("3 teams"), 3);
			e.addText(e, _("4 teams"), 4);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Player slots:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 32, 1, "menu_maxplayers",
			_("The maximum amount of players or bots that can be connected to your server at once")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Number of bots:")));
			setDependent(e, "g_campaign", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 9, 1, "bot_number",
			_("Amount of bots on your server")));
			setDependent(e, "g_campaign", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bot skill:")));
			setDependentNOT(e, "bot_number", 0);
			setDependentAND(e, "g_campaign", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("skill",
			_("Specify how experienced the bots will be")));
			e.addText(e, _("Botlike"), 0);
			e.addText(e, _("Beginner"), 1);
			e.addText(e, _("You will win"), 2);
			e.addText(e, _("You can win"), 3);
			e.addText(e, _("You might win"), 4);
			e.addText(e, _("Advanced"), 5);
			e.addText(e, _("Expert"), 6);
			e.addText(e, _("Pro"), 7);
			e.addText(e, _("Assassin"), 8);
			e.addText(e, _("Unhuman"), 9);
			e.addText(e, _("Godlike"), 10);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "bot_number", 0);
			setDependentAND(e, "g_campaign", 0, 0);

	// mapListBox is in the right column but the ref is needed for mutators dialog here
	me.mapListBox = makeXonoticMapList();
	// here we use the following line instead of me.TR(me) for better visual spacing;
	// this decision was made in this poll: http://forums.xonotic.org/showthread.php?tid=5445
	me.gotoRC(me, me.rows - 2.5, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Mutators..."), '0 0 0',
			_("Mutators and weapon arenas")));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.mutatorsDialog;
			main.mutatorsDialog.refilterEntity = me.mapListBox;
			setDependent(e, "g_campaign", 0, 0);

	// The right half begins here

	me.gotoRC(me, 0.5, 3.2); me.setFirstColumn(me, me.currentColumn);
		// the maplistbox
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Maplist")));
			makeCallback(e, me.mapListBox, me.mapListBox.refilterCallback);
	me.TR(me);
		// we use 5.8 here to visually match the bottom line of the component on the left (Bot Skill)
		me.TD(me, me.rows - 6.8, 3, me.mapListBox);

	me.gotoRC(me, me.rows - 4.5, me.firstColumn);
		// string filter label and box
		me.TD(me, 1, 0.35, e = makeXonoticTextLabel(1, _("Filter:")));
		me.mapListBox.stringFilterBox = makeXonoticInputBox_T(0, string_null,
			_("Click here or CTRL+F to provide a keyword to narrow down the list; CTRL+DEL to clear; ENTER when done."));
		me.TD(me, 1, me.columns - me.firstColumn - 0.35, e = me.mapListBox.stringFilterBox);
			e.onChange = MapList_StringFilterBox_Change;
			e.keyDown = MapList_StringFilterBox_keyDown;
			e.onChangeEntity = me.mapListBox;

	me.gotoRC(me, me.rows - 3.5, me.firstColumn);
		// the selection buttons
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.3, e = makeXonoticButton_T(_("Add shown"), '0 0 0',
			_("Add the maps shown in the list to your selection")));
			e.onClick = MapList_Add_Shown;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1.3, e = makeXonoticButton_T(_("Remove shown"), '0 0 0',
			_("Remove the maps shown in the list from your selection")));
			e.onClick = MapList_Remove_Shown;
			e.onClickEntity = me.mapListBox;
	me.gotoRC(me, me.rows - 2.5, me.firstColumn);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.3, e = makeXonoticButton_T(_("Add all"), '0 0 0',
			_("Add every available map to your selection")));
			e.onClick = MapList_Add_All;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1.3, e = makeXonoticButton_T(_("Remove all"), '0 0 0',
			_("Remove all the maps from your selection")));
			e.onClick = MapList_Remove_All;
			e.onClickEntity = me.mapListBox;

	// bottom row
	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, me.columns * 1/12);
		me.TD(me, 1, me.columns * 5/12, e = makeXonoticLeaveMatchButton('0 0 0', 0));
		me.TD(me, 1, me.columns * 5/12, e = makeXonoticButton(_("Start multiplayer!"), '0 0 0'));
			e.onClick = MapList_LoadMap;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;

	GameType_ConfigureSliders_for_CurrentGametype(me);
}

void XonoticServerCreateTab_gameTypeChangeNotify(entity me)
{
	GameType_ConfigureSliders_for_CurrentGametype(me);

	me.mapListBox.refilter(me.mapListBox);
}

void XonoticServerCreateTab_gameTypeSelectNotify(entity me)
{
	me.setFocus(me, me.mapListBox);
}
