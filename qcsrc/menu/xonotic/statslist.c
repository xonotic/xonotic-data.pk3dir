#ifdef INTERFACE
CLASS(XonoticStatsList) EXTENDS(XonoticListBox)
	METHOD(XonoticStatsList, configureXonoticStatsList, void(entity))
	ATTRIB(XonoticStatsList, rowsPerItem, float, 1.25)
	METHOD(XonoticStatsList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticStatsList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticStatsList, getStats, void(entity))
	METHOD(XonoticStatsList, clickListBoxItem, void(entity, float, vector))
	METHOD(XonoticStatsList, keyDown, float(entity, float, float, float))
	METHOD(XonoticStatsList, destroy, void(entity))
	METHOD(XonoticStatsList, showNotify, void(entity))

	ATTRIB(XonoticStatsList, listStats, float, -1)
	ATTRIB(XonoticStatsList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticStatsList, realUpperMargin, float, 0)
	ATTRIB(XonoticStatsList, columnNameOrigin, float, 0)
	ATTRIB(XonoticStatsList, columnNameSize, float, 0)
	ATTRIB(XonoticStatsList, columnDataOrigin, float, 0)
	ATTRIB(XonoticStatsList, columnDataSize, float, 0)
	ATTRIB(XonoticStatsList, origin, vector, '0 0 0')
	ATTRIB(XonoticStatsList, itemAbsSize, vector, '0 0 0')

	ATTRIB(XonoticStatsList, lastClickedDemo, float, -1)
	ATTRIB(XonoticStatsList, lastClickedTime, float, 0)
ENDCLASS(XonoticStatsList)

entity statslist; // for reference elsewhere
entity makeXonoticStatsList();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticStatsList()
{
	entity me;
	me = spawnXonoticStatsList();
	me.configureXonoticStatsList(me);
	return me;
}

void XonoticStatsList_configureXonoticStatsList(entity me)
{
	me.configureXonoticListBox(me);
}

void XonoticStatsList_getStats(entity me)
{
	print("XonoticStatsList_getStats() at time: ", ftos(time), "\n");
	if (me.listStats >= 0)
		buf_del(me.listStats);
	me.listStats = buf_create();
	if (me.listStats < 0)
	{
		me.nItems = 0;
		return;
	}

	float order = 0;
	string e = "", en = "", data = "";
	
	string outstr = ""; // NOTE: out string MUST use underscores for spaces here, we'll replace them later

	float out_total_matches = -1;
	float out_total_wins = -1;
	float out_total_losses = -1;

	float out_total_kills = -1;
	float out_total_deaths = -1;
	
	for(e = PS_D_IN_EVL; (en = db_get(PS_D_IN_DB, e)) != ""; e = en)
	{
		order = 0;
		outstr = "";
		data = db_get(PS_D_IN_DB, sprintf("#%s", e));

		// non-gamemode specific stuff
		switch(e)
		{
			case "overall/joined_dt":
			{
				order = 1;
				outstr = _("Joined:");
				data = car(data);
				break;
			}
			case "overall/last_seen_dt":
			{
				order = 1;
				outstr = _("Last_Seen:");
				data = car(data);
				break;
			}
			case "overall/alivetime":
			{
				order = 1;
				outstr = _("Time_Played:");
				data = process_time(3, stof(data));
				break;
			}
			case "overall/matches":
			{
				order = -1;
				out_total_matches = stof(data);
				break;
			}
			case "overall/wins":
			{
				order = -1;
				out_total_wins = stof(data);
				break;
			}
			case "overall/total-kills":
			{
				order = -1;
				out_total_kills = stof(data);
				break;
			}
			case "overall/total-deaths":
			{
				order = -1;
				out_total_deaths = stof(data);
				break;
			}
		}

		if((order == -1) && (out_total_matches >= 0) && (out_total_wins >= 0))
		{
			bufstr_add(me.listStats, sprintf("02Matches: %d", out_total_matches), TRUE);
			
			if(out_total_matches > 0) // don't show extra info if there are no matches played
			{
				out_total_losses = max(0, (out_total_matches - out_total_wins));
				bufstr_add(me.listStats, sprintf("02Wins/Losses: %d/%d", out_total_wins, out_total_losses), TRUE);
				bufstr_add(me.listStats, sprintf("03Win_Percentage: %d%%", ((out_total_wins / out_total_matches) * 100)), TRUE);
			}

			out_total_matches = -1;
			out_total_wins = -1;
			out_total_losses = -1;
			continue;
		}

		if((order == -1) && (out_total_kills >= 0) && (out_total_deaths >= 0))
		{
			bufstr_add(me.listStats, sprintf("04Kills/Deaths: %d/%d", out_total_kills, out_total_deaths), TRUE);

			// if there are no deaths, just show kill count 
			if(out_total_deaths > 0)
				bufstr_add(me.listStats, sprintf("04Kill_Ratio: %.2f", (out_total_kills / out_total_deaths)), TRUE);
			else
				bufstr_add(me.listStats, sprintf("04Kill_Ratio: %.2f", out_total_kills), TRUE);

			out_total_kills = -1;
			out_total_deaths = -1;
			continue;
		}

		// game mode specific stuff
		if(!(order > 0))
		{
			//dividerpos = strstrofs(e, "/", 0);
			//switch(substring(e, dividerpos, strlen(e) - dividerpos))
			switch(e)
			{
				case "":
				{
					order = 5;
					outstr = _("Last_seen:");
					data = car(data);
					break;
				}
				
				default: continue; // nothing to see here
			}
		}

		bufstr_add(me.listStats, sprintf("%02d%s %s", order, outstr, data), TRUE);
	}

	me.nItems = buf_getsize(me.listStats);
	if(me.nItems > 0)
		buf_sort(me.listStats, 128, FALSE);
}

void XonoticStatsList_destroy(entity me)
{
	if(me.nItems > 0)
		buf_del(me.listStats);
}

void XonoticStatsList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticStatsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);

	me.columnNameOrigin = me.realFontSize_x;
	me.columnNameSize = 1 - 2 * me.realFontSize_x;
}

void XonoticStatsList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string data;
	data = bufstr_get(me.listStats, i);

	s = car(data);
	s = substring(s, 2, strlen(s) - 2);
	s = strreplace("_", " ", s);

	s = strcat(s, " ", cdr(data));

	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);
}

void XonoticStatsList_showNotify(entity me)
{
	PlayerStats_PlayerDetail();
}

void XonoticStatsList_clickListBoxItem(entity me, float i, vector where)
{
	if(i == me.lastClickedDemo)
		if(time < me.lastClickedTime + 0.3)
		{
			// DOUBLE CLICK!
			me.setSelected(me, i);
			//DemoConfirm_ListClick_Check_Gamestatus(me);
		}
	me.lastClickedDemo = i;
	me.lastClickedTime = time;
}

float XonoticStatsList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		//DemoConfirm_ListClick_Check_Gamestatus(me);
		return 1;
	}
	else
	{
		return SUPER(XonoticStatsList).keyDown(me, scan, ascii, shift);
	}
}
#endif

