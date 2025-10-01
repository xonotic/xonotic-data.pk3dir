#include "statslist.qh"
#include <common/playerstats.qh>

entity makeXonoticStatsList()
{
	entity me;
	me = NEW(XonoticStatsList);
	me.configureXonoticStatsList(me);
	return me;
}

void XonoticStatsList_configureXonoticStatsList(entity me)
{
	me.configureXonoticListBox(me);
	me.getStats(me);
}

string XonoticStatsList_convertDate(string input)
{
	// 2013-12-21
	// 0123456789
	if(strlen(input) != 10)
		return input;

	string monthname = "";

	switch(stof(substring(input, 5, 2)))
	{
		case 1:  monthname = _("January");    break;
		case 2:  monthname = _("February");   break;
		case 3:  monthname = _("March");      break;
		case 4:  monthname = _("April");      break;
		case 5:  monthname = _("May");        break;
		case 6:  monthname = _("June");       break;
		case 7:  monthname = _("July");       break;
		case 8:  monthname = _("August");     break;
		case 9:  monthname = _("September");  break;
		case 10: monthname = _("October");    break;
		case 11: monthname = _("November");   break;
		case 12: monthname = _("December");   break;
		default: return input; // failed, why?
	}

	// without no-c-format this string looks messed up in Transifex since only %d is a valid c placeholder
	/* xgettext:no-c-format */
	string date = ZCTX(_("DATE^%m %d, %Y"));
	date = strreplace("%Y", substring(input, 0, 4), date);
	date = strreplace("%d", ftos(stof(substring(input, 8, 2))), date); // ftos-stof removes leading 0
	date = strreplace("%m", monthname, date);
	return date;
}

void XonoticStatsList_getStats(entity me)
{
	LOG_TRACE("XonoticStatsList_getStats() at time: ", ftos(time));
	// delete the old buffer if it exists
	if(me.listStats >= 0)
		buf_del(me.listStats);

	// create the new buffer if we have a stats buffer
	if(PS_D_IN_DB >= 0)
		me.listStats = buf_create();

	// now confirmation, if we didn't create a buffer then just return now
	if(me.listStats < 0)
	{
		me.nItems = 0;
		return;
	}

	float order = 0;
	string e = "", en = "", data = "";

	string outstr = ""; // NOTE: out string MUST use underscores for spaces here, we'll replace them later
	string orderstr = "";

	float out_total_matches = -1;
	float out_total_wins = -1;
	float out_total_losses = -1;

	float out_total_kills = -1;
	float out_total_deaths = -1;

	for(e = PS_D_IN_EVL; (en = db_get(PS_D_IN_DB, e)) != ""; e = en)
	{
		order = 0;
		outstr = "";
		orderstr = "";
		data = db_get(PS_D_IN_DB, sprintf("#%s", e));

		// non-gametype specific stuff
		switch(e)
		{
			case "overall/joined_dt":
			{
				order = 1;
				outstr = _("Joined:");
				data = XonoticStatsList_convertDate(car(data));
				break;
			}
			case "overall/last_seen_dt":
			{
				order = 1;
				outstr = _("Last match:");
				data = XonoticStatsList_convertDate(car(data));
				break;
			}
			case "overall/alivetime":
			{
				order = 1;
				outstr = _("Time played:");
				data = process_time(3, stof(data));
				break;
			}
			case "overall/favorite-map":
			{
				order = 2;
				outstr = _("Favorite map:");
				data = car(data);
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
			bufstr_add(me.listStats, sprintf("003%s\n%d", _("Matches:"), out_total_matches), true);

			if(out_total_matches > 0) // don't show extra info if there are no matches played
			{
				out_total_losses = max(0, (out_total_matches - out_total_wins));
				bufstr_add(me.listStats, sprintf("003%s\n%d/%d", _("Wins/Losses:"), out_total_wins, out_total_losses), true);
				bufstr_add(me.listStats, sprintf("004%s\n%s", _("Win percentage:"), ftos_decimals_percentage(out_total_wins / out_total_matches, 0)), true);
			}

			out_total_matches = -1;
			out_total_wins = -1;
			out_total_losses = -1;
			continue;
		}

		if((order == -1) && (out_total_kills >= 0) && (out_total_deaths >= 0))
		{
			bufstr_add(me.listStats, sprintf("005%s\n%d/%d", _("Kills/Deaths:"), out_total_kills, out_total_deaths), true);

			// if there are no deaths, just show kill count
			if(out_total_deaths == 0)
				out_total_deaths = 1;

			bufstr_add(me.listStats, sprintf("006%s\n%.2f", _("Kill ratio:"), (out_total_kills / out_total_deaths)), true);

			out_total_kills = -1;
			out_total_deaths = -1;
			continue;
		}

		// gametype specific stuff
		if(order > 0)
		{
			orderstr = sprintf("%03d", order);
		}
		else
		{
			float dividerpos = strstrofs(e, "/", 0);

			string gametype = substring(e, 0, dividerpos);
			if(gametype == "overall") { continue; }

			string event = substring(e, (dividerpos + 1), strlen(e) - (dividerpos + 1));

			// if we are ranked, read these sets of possible options
			if(stof(db_get(PS_D_IN_DB, sprintf("#%s/rank", gametype))))
			{
				switch(event)
				{
					case "matches":
					{
						order = 1;
						outstr = _("Matches:");
						break;
					}
					#if 0
					case "skill":
					{
						order = 2;
						outstr = _("Skill:");
						data = sprintf("%d", stof(data));
						break;
					}
					case "favorite-map":
					{
						order = 3;
						outstr = _("Favorite map:");
						break;
					}
					#endif

					default: continue; // nothing to see here
				}

				outstr = strcat(strtoupper(gametype), " ", outstr);
				// now set up order for sorting later
				orderstr = sprintf("%2.2s%d", gametype, order);
			}
			else if(event == "matches")
			{
				outstr = _("Matches:");
				outstr = strcat(strtoupper(gametype), " ", outstr);
				data = sprintf(_("%d (unranked)"), stof(data));

				// unranked gametypes ALWAYS get put last
				orderstr = "zzz";
			}
			else { continue; }
		}

		bufstr_add(me.listStats, sprintf("%s%s\n%s", orderstr, outstr, data), true);
	}

	me.nItems = buf_getsize(me.listStats);
	if(me.nItems > 0)
		buf_sort(me.listStats, 128, false);
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

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

#if 0
	me.columnNameOrigin = me.realFontSize.x;
	me.columnNameSize = 0.5 - me.realFontSize.x; // end halfway at maximum length
	me.columnDataOrigin = me.columnNameOrigin + me.columnNameSize;
	me.columnDataSize = 1 - me.columnNameSize - me.realFontSize.x; // fill the rest of the control
#else
	me.columnNameOrigin = me.realFontSize.x;
	me.columnNameSize = 1 - 2 * me.realFontSize.x;
#endif
}

void XonoticStatsList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	string data = bufstr_get(me.listStats, i);
	int ofs = strstrofs(data, "\n", 0);

	string s = substring(data, 3, ofs - 3);
	s = draw_TextShortenToWidth(s, 0.5 * me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);

	string d = substring(data, ofs + 1, strlen(data) - (ofs + 1));
	d = draw_TextShortenToWidth(d, me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize), 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 1 * (me.columnNameSize - draw_TextWidth(d, 0, me.realFontSize))) * eX, d, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);
}

void XonoticStatsList_showNotify(entity me)
{
	PlayerStats_PlayerDetail_CheckUpdate();
}

void XonoticStatsList_doubleClickListBoxItem(entity me, float i, vector where)
{
	//DemoConfirm_ListClick_Check_Gamestatus(me);
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
