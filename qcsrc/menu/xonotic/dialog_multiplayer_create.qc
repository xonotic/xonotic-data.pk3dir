#ifndef DIALOG_MULTIPLAYER_CREATE_H
#define DIALOG_MULTIPLAYER_CREATE_H
#include "tab.qc"
CLASS(XonoticServerCreateTab, XonoticTab)
	METHOD(XonoticServerCreateTab, fill, void(entity))
	METHOD(XonoticServerCreateTab, gameTypeChangeNotify, void(entity))
	METHOD(XonoticServerCreateTab, gameTypeSelectNotify, void(entity))
	ATTRIB(XonoticServerCreateTab, title, string, _("Create"))
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

void GameType_ConfigureSliders(entity e, entity l, string pLabel, float pMin, float pMax, float pStep, string pCvar)
{
	if(pCvar == "")
	{
		e.configureXonoticTextSlider(e, string_null);
		l.setText(l, pLabel);
		e.disabled = l.disabled = true;
	}
	else
	{
		e.configureXonoticTextSlider(e, pCvar);

		// clear old values
		int i;
		for(i = 0; i <= e.nValues; ++i);
		{
			if(e.(valueStrings[i])) { strunzone(e.(valueStrings[i])); }
			if(e.(valueIdentifiers[i])) { strunzone(e.(valueIdentifiers[i])); }
		}
		e.clearValues(e);

		// set new values
		e.addValue(e, strzone(_("Default")), strzone("-1"));
		for(i = pMin; i <= pMax; i += pStep) { e.addValue(e, strzone(ftos(i)), strzone(ftos(i))); }
		e.addValue(e, strzone(_("Unlimited")), strzone("0"));
		e.configureXonoticTextSliderValues(e);

		// set text field
		l.setText(l, pLabel);
		e.disabled = l.disabled = false;
	}
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

	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 3, makeXonoticHeaderLabel(_("Gametype")));
	me.TR(me);
		me.TD(me, 10.5, 3, e = makeXonoticGametypeList());

	me.gotoRC(me, 12.5, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Time limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("timelimit_override"));
			e.addValue(e, ZCTX(_("TIMLIM^Default")), "-1");
			e.addValue(e, ZCTX(_("TIMLIM^1 minute")), "1");
			e.addValue(e, ZCTX(_("TIMLIM^2 minutes")), "2");
			e.addValue(e, ZCTX(_("TIMLIM^3 minutes")), "3");
			e.addValue(e, ZCTX(_("TIMLIM^4 minutes")), "4");
			e.addValue(e, ZCTX(_("TIMLIM^5 minutes")), "5");
			e.addValue(e, ZCTX(_("TIMLIM^6 minutes")), "6");
			e.addValue(e, ZCTX(_("TIMLIM^7 minutes")), "7");
			e.addValue(e, ZCTX(_("TIMLIM^8 minutes")), "8");
			e.addValue(e, ZCTX(_("TIMLIM^9 minutes")), "9");
			e.addValue(e, ZCTX(_("TIMLIM^10 minutes")), "10");
			e.addValue(e, ZCTX(_("TIMLIM^15 minutes")), "15");
			e.addValue(e, ZCTX(_("TIMLIM^20 minutes")), "20");
			e.addValue(e, ZCTX(_("TIMLIM^25 minutes")), "25");
			e.addValue(e, ZCTX(_("TIMLIM^30 minutes")), "30");
			e.addValue(e, ZCTX(_("TIMLIM^40 minutes")), "40");
			e.addValue(e, ZCTX(_("TIMLIM^50 minutes")), "50");
			e.addValue(e, ZCTX(_("TIMLIM^60 minutes")), "60");
			e.addValue(e, ZCTX(_("TIMLIM^Infinite")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, me.labelFraglimit = makeXonoticTextLabel(0, _("Frag limit:")));
		me.TD(me, 1, 2, me.sliderFraglimit = makeXonoticTextSlider("fraglimit_override"));
			GameType_ConfigureSliders(me.sliderFraglimit, me.labelFraglimit, _("Frag limit:"), 5, 100, 5, "fraglimit_override");

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
		me.TD(me, 1, 2, makeXonoticSlider(1, 32, 1, "menu_maxplayers"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Number of bots:")));
		me.TD(me, 1, 2, makeXonoticSlider(0, 9, 1, "bot_number"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bot skill:")));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("skill"));
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

	me.gotoRC(me, me.rows - 3.5, 0);
		me.TD(me, 1, 3, e0 = makeXonoticTextLabel(0.5, string_null));
			e0.textEntity = main.mutatorsDialog;
			e0.allowCut = 1;
			//e0.allowWrap = 1;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Mutators"), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.mutatorsDialog;
			main.mutatorsDialog.refilterEntity = me.mapListBox;

	me.gotoRC(me, 0.5, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.mapListBox = makeXonoticMapList();
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Maplist")));
			makeCallback(e, me.mapListBox, me.mapListBox.refilterCallback);
	me.TR(me);
		me.TD(me, me.rows - 4, 3, me.mapListBox);
	me.gotoRC(me, me.rows - 2.5, 3.2);
		me.TDempty(me, 0.375);
		me.TD(me, 1, 1.125, e = makeXonoticButton(_("Select all"), '0 0 0'));
			e.onClick = MapList_All;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1.125, e = makeXonoticButton(_("Select none"), '0 0 0'));
			e.onClick = MapList_None;
			e.onClickEntity = me.mapListBox;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Start Multiplayer!"), '0 0 0'));
			e.onClick = MapList_LoadMap;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;

	me.gameTypeChangeNotify(me);
}

void XonoticServerCreateTab_gameTypeChangeNotify(entity me)
{
	// tell the map list to update
	float gt;
	entity e, l;
	gt = MapInfo_CurrentGametype();
	e = me.sliderFraglimit;
	l = me.labelFraglimit;

	switch(gt)
	{
		case MAPINFO_TYPE_CTF:        GameType_ConfigureSliders(e, l, _("Capture limit:"),   1,   20, 1, "capturelimit_override");     break;
		case MAPINFO_TYPE_DOMINATION: GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "g_domination_point_limit"); break;
		case MAPINFO_TYPE_KEYHUNT:    GameType_ConfigureSliders(e, l, _("Point limit:"),   200, 1500, 50, "g_keyhunt_point_limit");    break;
		case MAPINFO_TYPE_LMS:        GameType_ConfigureSliders(e, l, _("Lives:"),           3,   50,  1, "g_lms_lives_override");     break;
		case MAPINFO_TYPE_RACE:       GameType_ConfigureSliders(e, l, _("Laps:"),            1,   25,  1, "g_race_laps_limit");        break;
		case MAPINFO_TYPE_NEXBALL:    GameType_ConfigureSliders(e, l, _("Goals:"),           1,   50,  1, "g_nexball_goallimit");      break;
		case MAPINFO_TYPE_ASSAULT:    GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "");                         break;
		case MAPINFO_TYPE_ONSLAUGHT:  GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "");                         break;
		case MAPINFO_TYPE_CTS:        GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "");                         break;
		case MAPINFO_TYPE_INVASION:   GameType_ConfigureSliders(e, l, _("Point limit:"),     5,    0,  5, "");                         break;
	case MAPINFO_TYPE_TEAM_DEATHMATCH:GameType_ConfigureSliders(e, l, _("Point limit:"),     5,  100,  5, "g_tdm_point_limit");        break;
		default:                      GameType_ConfigureSliders(e, l, _("Frag limit:"),      5,  100,  5, "fraglimit_override");       break;
	}

	string x = string_null;
	e = me.sliderTeams;
	switch(gt)
	{
		case MAPINFO_TYPE_CA:               x = "g_ca_teams_override";          break;
		case MAPINFO_TYPE_DOMINATION:       x = "g_domination_teams_override";  break;
		case MAPINFO_TYPE_FREEZETAG:        x = "g_freezetag_teams_override";   break;
		case MAPINFO_TYPE_KEYHUNT:          x = "g_keyhunt_teams_override";     break;
		case MAPINFO_TYPE_TEAM_DEATHMATCH:  x = "g_tdm_teams_override";         break;
	}
	e.configureXonoticTextSlider(e, x);
	e.configureXonoticTextSliderValues(e);
	if(!x)
		e.value = 0;
	me.sliderTeams.disabled = me.labelTeams.disabled = !x;

	me.mapListBox.refilter(me.mapListBox);
}

void XonoticServerCreateTab_gameTypeSelectNotify(entity me)
{
	me.setFocus(me, me.mapListBox);
}

#endif
