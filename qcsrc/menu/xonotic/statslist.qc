#include "statslist.qh"

#include <common/playerstats.qh>

entity makeXonoticStatsList()
{
	entity me = NEW(XonoticStatsList);
	me.configureXonoticStatsList(me);
	return me;
}

void XonoticStatsList_configureXonoticStatsList(entity me)
{
	me.configureXonoticListBox(me);
	me.getStats(me);

	for (int i = 0; i < GameType_GetTotalCount(); ++i)
		if (SKINBOOL_STATSLIST_ICON_BLUR)
			draw_PreloadPictureWithFlags(GameType_GetIcon(i), PRECACHE_PIC_MIPMAP);
		else
			draw_PreloadPicture(GameType_GetIcon(i));
}

string XonoticStatsList_convertDate(string input)
{
	// 2013-12-21
	// 0123456789
	if (strlen(input) != 10)
		return input;

	string monthname;
	switch (stoi(substring(input, 5, 2)))
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
	string date = CTX(_("DATE^%m %d, %Y"));
	date = strreplace("%Y", substring(input, 0, 4), date);
	date = strreplace("%d", ftos(stof(substring(input, 8, 2))), date); // ftos-stof removes leading 0
	date = strreplace("%m", monthname, date);
	return strzone(date);
}

void XonoticStatsList_getStats(entity me)
{
	LOG_TRACE("XonoticStatsList_getStats() at time: ", ftos(time));
	// delete the old buffer if it exists
	if (me.listStats >= 0)
		buf_del(me.listStats);

	// create the new buffer if we have a stats buffer
	if (PS_D_IN_DB >= 0)
		me.listStats = buf_create();

	// now confirmation, if we didn't create a buffer then just return now
	if (me.listStats < 0)
	{
		me.nItems = 0;
		return;
	}

	int order;
	string data, extra;
	string outstr; // NOTE: out string MUST use underscores for spaces here, we'll replace them later
	string orderstr; // 3 chars
	// Strings added with bufstr_add are in the format: {orderstr}{outstr}\n{data}\n{extra}

	int out_total_matches = -1;
	int out_total_wins = -1;
	int out_total_losses = -1;
	int out_total_kills = -1;
	int out_total_deaths = -1;

	for (string en, e = PS_D_IN_EVL; (en = db_get(PS_D_IN_DB, e)) != ""; e = en)
	{
		order = 0;
		outstr = "";
		orderstr = "";
		data = db_get(PS_D_IN_DB, strcat("#", e));
		extra = "";

		// non-gametype specific stuff
		switch (e)
		{
			case "overall/joined_dt":
				order = 1;
				outstr = _("Joined:");
				data = XonoticStatsList_convertDate(car(data));
				break;
			case "overall/last_seen_dt":
				order = 1;
				outstr = _("Last match:");
				data = XonoticStatsList_convertDate(car(data));
				break;
			case "overall/alivetime":
				order = 1;
				outstr = _("Time played:");
				data = process_time(3, stoi(data));
				break;
			case "overall/favorite-map":
				order = 2;
				outstr = _("Favorite map:");
				data = car(data);
				break;
			case "overall/matches":
				order = -1;
				out_total_matches = stoi(data);
				break;
			case "overall/wins":
				order = -1;
				out_total_wins = stoi(data);
				break;
			case "overall/total-kills":
				order = -1;
				out_total_kills = stoi(data);
				break;
			case "overall/total-deaths":
				order = -1;
				out_total_deaths = stoi(data);
				break;
		}

		if (order == -1 && out_total_matches >= 0 && out_total_wins >= 0)
		{
			bufstr_add(me.listStats, sprintf("003%s\n%d\n", _("Matches:"), out_total_matches), true);

			if (out_total_matches > 0) // don't show extra info if there are no matches played
			{
				out_total_losses = max(0, out_total_matches - out_total_wins);
				bufstr_add(me.listStats, sprintf("003%s\n%d/%d\n", _("Wins/Losses:"), out_total_wins, out_total_losses), true);
				bufstr_add(me.listStats, sprintf("004%s\n%s\n", _("Win percentage:"), ftos_decimals_percentage(out_total_wins / out_total_matches, 0)), true);
			}

			out_total_matches = -1;
			out_total_wins = -1;
			out_total_losses = -1;
			continue;
		}

		if (order == -1 && out_total_kills >= 0 && out_total_deaths >= 0)
		{
			bufstr_add(me.listStats, sprintf("005%s\n%d/%d\n", _("Kills/Deaths:"), out_total_kills, out_total_deaths), true);

			// if there are no deaths, just show kill count
			if (out_total_deaths == 0)
				out_total_deaths = 1;

			bufstr_add(me.listStats, sprintf("006%s\n%.2f\n", _("Kill-death ratio:"), out_total_kills / out_total_deaths), true);

			out_total_kills = -1;
			out_total_deaths = -1;
			continue;
		}

		// gametype specific stuff
		if (order > 0)
			orderstr = sprintf("%03d", order);
		else
		{
			int dividerpos = strstrofs(e, "/", 0);
			string gametype = substring(e, 0, dividerpos);
			if (gametype == "overall")
				continue;

			string event = substring(e, dividerpos + 1, strlen(e) - (dividerpos + 1));

			// if we are ranked, read these sets of possible options
			if (stof(db_get(PS_D_IN_DB, strcat("#", gametype, "/rank"))))
			{
				switch (event)
				{
					case "matches":
						order = 1;
						outstr = CTX(_("GAMETYPE^%s Matches:"));
						extra = GameType_GetIcon_FromString(gametype);
						break;
				#if 0
					case "skill":
						order = 2;
						outstr = CTX(_("GAMETYPE^%s Skill:"));
						data = sprintf("%d", stoi(data));
						break;
					case "favorite-map":
						order = 3;
						outstr = CTX(_("GAMETYPE^%s Favorite map:"));
						break;
				#endif
					default:
						continue; // nothing to see here
				}

				outstr = sprintf(outstr, strtoupper(gametype));
				// now set up order for sorting later
				orderstr = sprintf("%2.2s%d", gametype, order);
			}
			else if (event == "matches")
			{
				outstr = sprintf(CTX(_("GAMETYPE^%s Matches:")), strtoupper(gametype));
				data = sprintf(_("%d (unranked)"), stoi(data));
				extra = GameType_GetIcon_FromString(gametype);

				// unranked gametypes ALWAYS get put last
				orderstr = "zzz";
			}
			else
				continue;
		}

		bufstr_add(me.listStats, strcat(orderstr, outstr, "\n", data, "\n", extra), true);
	}

	me.nItems = buf_getsize(me.listStats);
	if (me.nItems > 0)
		buf_sort(me.listStats, 128, false);
}

void XonoticStatsList_destroy(entity me)
{
	if (me.nItems > 0)
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

	me.columnIconOrigin = 0.25 * me.realFontSize.x;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x;
	me.columnNameOrigin = me.columnIconOrigin * 2 + me.columnIconSize; // .columnIconOrigin padding on both sides
	me.columnNameSize = 1 - me.columnIconOrigin - me.columnIconSize - me.realFontSize.x;
}

void XonoticStatsList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if (isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	string data = bufstr_get(me.listStats, i);
	int ofs_data  = strstrofs(data, "\n", 0);
	int ofs_extra = strstrofs(data, "\n", ofs_data + 1);

	string s    = substring(data, 3, ofs_data - 3); // column name -- first 3 chars are orderstr, discard
	string d    = substring(data, ofs_data + 1, ofs_extra - (ofs_data + 1)); // data
	string icon = substring(data, ofs_extra + 1, strlen(data) - (ofs_extra + 1)); // extra will be the gamtype icon path, or ""

	if (icon != "")
		draw_Picture(me.columnIconOrigin * eX, icon, me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);

	s = draw_TextShortenToWidth(s, 0.5 * me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);

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
	if (scan == K_ENTER || scan == K_KP_ENTER)
	{
		//DemoConfirm_ListClick_Check_Gamestatus(me);
		return 1;
	}
	return SUPER(XonoticStatsList).keyDown(me, scan, ascii, shift);
}
