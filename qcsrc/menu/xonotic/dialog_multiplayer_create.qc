#ifndef DIALOG_MULTIPLAYER_CREATE_H
#define DIALOG_MULTIPLAYER_CREATE_H
#include "tab.qc"
CLASS(XonoticServerCreateTab, XonoticTab)
	METHOD(XonoticServerCreateTab, fill, void(entity));
	METHOD(XonoticServerCreateTab, gameTypeChangeNotify, void(entity));
	METHOD(XonoticServerCreateTab, gameTypeSelectNotify, void(entity));
	ATTRIB(XonoticServerCreateTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticServerCreateTab, rows, float, 23)
	ATTRIB(XonoticServerCreateTab, columns, float, 6.2) // added extra .2 for center space

	ATTRIB(XonoticServerCreateTab, mapListBox, entity, NULL)
	ATTRIB(XonoticServerCreateTab, sliderFraglimit, entity, NULL)
	ATTRIB(XonoticServerCreateTab, sliderTeams, entity, NULL)
	ATTRIB(XonoticServerCreateTab, sliderTimelimit, entity, NULL)
	ATTRIB(XonoticServerCreateTab, labelFraglimit, entity, NULL)
	ATTRIB(XonoticServerCreateTab, labelTeams, entity, NULL)
ENDCLASS(XonoticServerCreateTab)
entity makeXonoticServerCreateTab();
#endif

#ifdef IMPLEMENTATION

void GameType_ConfigureSliders(entity me, string pLabel, float pMin, float pMax, float pStep, string pCvar, string tCvar, string pTooltip)
{
	int i;
	entity e = me.sliderFraglimit;
	entity l = me.labelFraglimit;
	e.configureXonoticTextSlider(e, pCvar, pTooltip);
	e.disabled = l.disabled = !pCvar;
	l.setText(l, pLabel);

	// clear old values
	for(i = 0; i < e.nValues; ++i);
	{
		if(e.(valueStrings[i]))
		{
			strunzone(e.(valueStrings[i]));
			e.(valueStrings[i]) = string_null;
		}
		if(e.(valueIdentifiers[i]))
		{
			strunzone(e.(valueIdentifiers[i]));
			e.(valueIdentifiers[i]) = string_null;
		}
	}
	e.clearValues(e);

	if(pCvar != "")
	{
		// set new values
		e.addValue(e, strzone(_("Default")), strzone("-1"));
		for(i = pMin; i <= pMax; i += pStep) { e.addValue(e, strzone(ftos(i)), strzone(ftos(i))); }
		e.addValue(e, strzone(_("Unlimited")), strzone("0"));
	}
	e.configureXonoticTextSliderValues(e);


	entity t = me.sliderTeams;
	entity tl = me.labelTeams;
	t.configureXonoticTextSlider(t, tCvar, string_null);
	tl.disabled = t.disabled = !tCvar;
	t.nValues = (tCvar == "") ? 0 : 4; // instead of clearing / readding the very same values
	t.configureXonoticTextSliderValues(t);
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

	me.gotoRC(me, 12.5, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Time limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("timelimit_override",
			_("Timelimit in minutes that when hit, will end the match")));
			#define ADDVALUE_MINUTES(i) e.addValue(e, strzone(sprintf(_("%d minutes"), i)), #i)
			e.addValue(e, ZCTX(_("TIMLIM^Default")), "-1");
			e.addValue(e, _("1 minute"), "1");
			ADDVALUE_MINUTES(2);
			ADDVALUE_MINUTES(3);
			ADDVALUE_MINUTES(4);
			ADDVALUE_MINUTES(5);
			ADDVALUE_MINUTES(6);
			ADDVALUE_MINUTES(7);
			ADDVALUE_MINUTES(8);
			ADDVALUE_MINUTES(9);
			ADDVALUE_MINUTES(10);
			ADDVALUE_MINUTES(15);
			ADDVALUE_MINUTES(20);
			ADDVALUE_MINUTES(25);
			ADDVALUE_MINUTES(30);
			ADDVALUE_MINUTES(40);
			ADDVALUE_MINUTES(50);
			ADDVALUE_MINUTES(60);
			e.addValue(e, ZCTX(_("TIMLIM^Infinite")), "0");
			e.configureXonoticTextSliderValues(e);
			#undef ADDVALUE_MINUTES
	me.TR(me);
		me.TD(me, 1, 1, me.labelFraglimit = makeXonoticTextLabel(0, _("Frag limit:")));
		me.TD(me, 1, 2, e = me.sliderFraglimit = makeXonoticTextSlider("fraglimit_override"));

	me.gotoRC(me, 15, 0);
		me.TD(me, 1, 1, me.labelTeams = makeXonoticTextLabel(0, _("Teams:")));
		me.TD(me, 1, 2, e = me.sliderTeams = makeXonoticTextSlider(string_null));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("2 teams"), "2");
			e.addValue(e, _("3 teams"), "3");
			e.addValue(e, _("4 teams"), "4");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Player slots:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 32, 1, "menu_maxplayers",
			_("The maximum amount of players or bots that can be connected to your server at once")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Number of bots:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 9, 1, "bot_number",
			_("Amount of bots on your server")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bot skill:")));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("skill",
			_("Specify how experienced the bots will be")));
			e.addValue(e, _("Botlike"), "0");
			e.addValue(e, _("Beginner"), "1");
			e.addValue(e, _("You will win"), "2");
			e.addValue(e, _("You can win"), "3");
			e.addValue(e, _("You might win"), "4");
			e.addValue(e, _("Advanced"), "5");
			e.addValue(e, _("Expert"), "6");
			e.addValue(e, _("Pro"), "7");
			e.addValue(e, _("Assassin"), "8");
			e.addValue(e, _("Unhuman"), "9");
			e.addValue(e, _("Godlike"), "10");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "bot_number", 0, -1);

	me.gotoRC(me, me.rows - 3.8, 0);
		me.TD(me, 1, 3, e0 = makeXonoticTextLabel(0.5, string_null));
			e0.textEntity = main.mutatorsDialog;
			e0.allowCut = 1;
			//e0.allowWrap = 1;

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
			_("Click here or Ctrl-F to provide a keyword to narrow down the map list. Ctrl-Delete to clear; Enter when done."));
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

	// The big button at the bottom

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Start Multiplayer!"), '0 0 0'));
			e.onClick = MapList_LoadMap;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;

	me.gameTypeChangeNotify(me);
}

void XonoticServerCreateTab_gameTypeChangeNotify(entity me)
{
	switch(MapInfo_CurrentGametype())
	{
		case MAPINFO_TYPE_CA:              GameType_ConfigureSliders(me, _("Frag limit:"),      5,  100,  5, "fraglimit_override",        "g_ca_teams_override",          _("The amount of frags needed before the match will end")); break;
		case MAPINFO_TYPE_FREEZETAG:       GameType_ConfigureSliders(me, _("Frag limit:"),      5,  100,  5, "fraglimit_override",        "g_freezetag_teams_override",   _("The amount of frags needed before the match will end")); break;
		case MAPINFO_TYPE_CTF:             GameType_ConfigureSliders(me, _("Capture limit:"),   1,   20,  1, "capturelimit_override",     string_null,                    _("The amount of captures needed before the match will end")); break;
		case MAPINFO_TYPE_DOMINATION:      GameType_ConfigureSliders(me, _("Point limit:"),    50,  500, 10, "g_domination_point_limit",  "g_domination_teams_override",  _("The amount of points needed before the match will end")); break;
		case MAPINFO_TYPE_KEYHUNT:         GameType_ConfigureSliders(me, _("Point limit:"),   200, 1500, 50, "g_keyhunt_point_limit",     "g_keyhunt_teams_override",     _("The amount of points needed before the match will end")); break;
		case MAPINFO_TYPE_LMS:             GameType_ConfigureSliders(me, _("Lives:"),           3,   50,  1, "g_lms_lives_override",      string_null,                    string_null); break;
		case MAPINFO_TYPE_RACE:            GameType_ConfigureSliders(me, _("Laps:"),            1,   25,  1, "g_race_laps_limit",         string_null,                    string_null); break;
		case MAPINFO_TYPE_NEXBALL:         GameType_ConfigureSliders(me, _("Goals:"),           1,   50,  1, "g_nexball_goallimit",       string_null,                    _("The amount of goals needed before the match will end")); break;
		case MAPINFO_TYPE_ASSAULT:         GameType_ConfigureSliders(me, _("Point limit:"),    50,  500, 10, string_null,                 string_null,                    string_null); break;
		case MAPINFO_TYPE_ONSLAUGHT:       GameType_ConfigureSliders(me, _("Point limit:"),    50,  500, 10, string_null,                 string_null,                    string_null); break;
		case MAPINFO_TYPE_CTS:             GameType_ConfigureSliders(me, _("Point limit:"),    50,  500, 10, string_null,                 string_null,                    string_null); break;
		case MAPINFO_TYPE_INVASION:        GameType_ConfigureSliders(me, _("Point limit:"),    50,  500, 10, string_null,                 string_null,                    string_null); break;
		case MAPINFO_TYPE_TEAM_DEATHMATCH: GameType_ConfigureSliders(me, _("Point limit:"),     5,  100,  5, "g_tdm_point_limit",         "g_tdm_teams_override",         _("The amount of points needed before the match will end")); break;
		default:                           GameType_ConfigureSliders(me, _("Frag limit:"),      5,  100,  5, "fraglimit_override",        string_null,                    _("The amount of frags needed before the match will end")); break;
	}

	me.mapListBox.refilter(me.mapListBox);
}

void XonoticServerCreateTab_gameTypeSelectNotify(entity me)
{
	me.setFocus(me, me.mapListBox);
}

#endif
