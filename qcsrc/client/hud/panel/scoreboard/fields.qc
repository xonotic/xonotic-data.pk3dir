#include "fields.qh"

#include "scoreboard.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/main.qh>
#include <common/ent_cs.qh>
#include <common/mutators/base.qh>
#include <common/util.qh>

string autocvar_hud_panel_scoreboard_playerid_prefix = "#";
string autocvar_hud_panel_scoreboard_playerid_suffix = " ";


// log_all false: returns translated label
// log_all true:  prints name and description of all the labels
string Label_getInfo(string label, bool log_all)
{
	switch (label)
	{
	#define SCO_LABEL(strlabel, label, padding, help) \
		case label: \
			if (!log_all) \
				return CTX(strlabel); \
			LOG_HELP("^3", label, padding, "^7", help); \
			/* fallthrough when logging all labels */

		default:
			if (!log_all)
				break;
			// else fallthrough
		SCO_LABEL(_("SCO^bckills"),       "bckills", "            ", _("Number of ball carrier kills"));
		SCO_LABEL(_("SCO^bctime"),        "bctime", "             ", _("Total amount of time holding the ball in Keepaway"));
		SCO_LABEL(_("SCO^caps"),          "caps", "               ", _("How often a flag (CTF) or a key (Key Hunt) was captured"));
		SCO_LABEL(_("SCO^captime"),       "captime", "            ", _("Time of fastest capture (CTF)"));
		SCO_LABEL(_("SCO^deaths"),        "deaths", "             ", _("Number of deaths"));
		SCO_LABEL(_("SCO^destructions"),  "destructions", "       ", _("Number of keys destroyed by pushing them into the void"));
		SCO_LABEL(_("SCO^damage dealt"),  "dmg", "                ", _("The total damage dealt"));
		SCO_LABEL(_("SCO^damage taken"),  "dmgtaken", "           ", _("The total damage taken"));
		SCO_LABEL(_("SCO^drops"),         "drops", "              ", _("Number of flag drops"));
		SCO_LABEL(_("SCO^fastest"),       "fastest", "            ", _("Time of fastest lap (Race/CTS)"));
		SCO_LABEL(_("SCO^faults"),        "faults", "             ", _("Number of faults committed"));
		SCO_LABEL(_("SCO^fckills"),       "fckills", "            ", _("Number of flag carrier kills"));
		SCO_LABEL(_("SCO^fps"),           "fps", "                ", _("Frames per second"));
		SCO_LABEL(_("SCO^frags"),         "frags", "              ", _("Number of kills minus suicides"));
		SCO_LABEL(_("SCO^generators"),    "generators", "         ", _("Number of generators destroyed"));
		SCO_LABEL(_("SCO^goals"),         "goals", "              ", _("Number of goals scored"));
		SCO_LABEL(_("SCO^hunts"),         "hunts", "              ", _("Number of hunts (Survival)"));
		SCO_LABEL(_("SCO^kckills"),       "kckills", "            ", _("Number of key carrier kills"));
		SCO_LABEL(_("SCO^k/d"),           "kd", "                 ", _("The kill-death ratio"));
		SCO_LABEL(_("SCO^kdr"),           "kdr", "                ", _("The kill-death ratio"));
		SCO_LABEL(_("SCO^kdratio"),       "kdratio", "            ", _("The kill-death ratio"));
		SCO_LABEL(_("SCO^kills"),         "kills", "              ", _("Number of kills"));
		SCO_LABEL(_("SCO^laps"),          "laps", "               ", _("Number of laps finished (Race/CTS)"));
		SCO_LABEL(_("SCO^lives"),         "lives", "              ", _("Number of lives (LMS)"));
		SCO_LABEL(_("SCO^losses"),        "losses", "             ", _("Number of times a key was lost"));
		SCO_LABEL(_("SCO^name"),          "name", "               ", _("Player name"));
		SCO_LABEL(_("SCO^nick"),          "nick", "               ", _("Player name"));
		SCO_LABEL(_("SCO^objectives"),    "objectives", "         ", _("Number of objectives destroyed"));
		SCO_LABEL(_("SCO^pickups"),       "pickups", "            ", _("How often a flag (CTF), a key (Key Hunt), or a ball (Keepaway) was picked up"));
		SCO_LABEL(_("SCO^ping"),          "ping", "               ", _("Ping time"));
		SCO_LABEL(_("SCO^pl"),            "pl", "                 ", _("Packet loss"));
		SCO_LABEL(_("SCO^pushes"),        "pushes", "             ", _("Number of players pushed into the void"));
		SCO_LABEL(_("SCO^rank"),          "rank", "               ", _("Player rank"));
		SCO_LABEL(_("SCO^returns"),       "returns", "            ", _("Number of flag returns"));
		SCO_LABEL(_("SCO^revivals"),      "revivals", "           ", _("Number of revivals"));
		SCO_LABEL(_("SCO^rounds won"),    "rounds", "             ", _("Number of rounds won"));
		SCO_LABEL(_("SCO^rounds played"), "rounds_pl", "          ", _("Number of rounds played"));
		SCO_LABEL(_("SCO^score"),         "score", "              ", _("Total score"));
		SCO_LABEL(_("SCO^skill"),         "skill", "              ", _("Player skill"));
		SCO_LABEL(_("SCO^suicides"),      "suicides", "           ", _("Number of suicides"));
		SCO_LABEL(_("SCO^sum"),           "sum", "                ", _("Number of kills minus deaths"));
		SCO_LABEL(_("SCO^survivals"),     "survivals", "          ", _("Number of survivals"));
		SCO_LABEL(_("SCO^takes"),         "takes", "              ", _("Number of domination points taken (Domination)"));
		SCO_LABEL(_("SCO^teamkills"),     "teamkills", "          ", _("Number of teamkills"));
		SCO_LABEL(_("SCO^ticks"),         "ticks", "              ", _("Number of ticks (Domination)"));
		SCO_LABEL(_("SCO^time"),          "time", "               ", _("Total time raced (Race/CTS)"));
	#undef SCO_LABEL
	}
	return label;
}

void PrintScoresLabels()
{
	Label_getInfo(string_null, true);
}
string TranslateScoresLabel(string label)
{
	return Label_getInfo(label, false);
}

void Cmd_Scoreboard_Help()
{
	LOG_HELP(_("You can modify the scoreboard using the ^2scoreboard_columns_set command."));
	LOG_HELP(_("Usage:"));
	LOG_HELP("^2scoreboard_columns_set ^3default");
	LOG_HELP(_("^2scoreboard_columns_set ^3field1 field2 ..."));
	LOG_HELP(_("^2scoreboard_columns_set ^7without arguments reads the arguments from the cvar scoreboard_columns"));
	LOG_HELP(_("  ^5Note: ^7scoreboard_columns_set without arguments is executed on every map start"));
	LOG_HELP(_("^2scoreboard_columns_set ^3expand_default ^7loads default layout and expands it into the cvar scoreboard_columns so you can edit it"));
	LOG_HELP(_("You can use a ^3|^7 to start the right-aligned fields."));
	LOG_HELP(_("The following field names are recognized (case insensitive):"));

	LOG_HELP("");
	PrintScoresLabels();

	LOG_HELP("");
	LOG_HELP(_("Before a field you can put a + or - sign, then a comma separated list\n"
	           "of gametypes, then a slash, to make the field show up only in these\n"
	           "or in all but these gametypes. You can also specify 'all' as a\n"
	           "field to show all fields available for the current gametype."));

	LOG_HELP("");
	LOG_HELP(_("The special gametype names 'teams' and 'noteams' can be used to\n"
	           "include/exclude ALL teams/noteams gametypes."));

	LOG_HELP("");
	LOG_HELP(_("Example: scoreboard_columns_set name ping pl | +ctf/field3 -dm/field4"));
	LOG_HELP(_("will display name, ping and pl aligned to the left, and the fields\n"
	           "right of the vertical bar aligned to the right."));
	LOG_HELP(_("'field3' will only be shown in CTF, and 'field4' will be shown in all\n"
	           "other gametypes except DM."));
}

// NOTE: adding a gametype with ? to not warn for an optional field
// make sure it's excluded in a previous exclusive rule, if any
// otherwise the previous exclusive rule warns anyway
// e.g. -teams,rc,cts,lms/kills ?+rc/kills
#define SCOREBOARD_DEFAULT_COLUMNS \
"ping pl fps skill name |" \
" -teams,rc,cts,surv,inv,lms/kills +ft,tdm,tmayhem/kills ?+rc,inv/kills" \
" -teams,surv,lms/deaths +ft,tdm,tmayhem/deaths" \
" +tdm/sum" \
" -teams,lms,rc,cts,surv,inv,ka/suicides +ft,tdm,tmayhem/suicides ?+rc,inv/suicides" \
" -cts,dm,tdm,surv,ka,ft,mayhem,tmayhem/frags" /* tdm already has this in "score" */ \
" +tdm,ft,dom,ons,as,tmayhem/teamkills"\
" -rc,cts,surv,nb/dmg -rc,cts,surv,nb/dmgtaken" \
" +surv/survivals +surv/hunts" \
" +ctf/pickups +ctf/fckills +ctf/returns +ctf/caps +ons/takes +ons/caps" \
" +lms/lives +lms/rank" \
" +kh/kckills +kh/losses +kh/caps" \
" ?+rc/laps ?+rc/time +rc,cts/fastest" \
" +as/objectives +nb/faults +nb/goals" \
" +ka,tka/pickups +ka,tka/bckills +ka,tka/bctime +ft/revivals" \
" +dom/ticks +dom/takes" \
" -lms,rc,cts,inv,nb/score"

void Cmd_Scoreboard_SetFields(int argc)
{
	TC(int, argc);
	if (!gametype)
		return; // do nothing, we don't know gametype and scores yet

	int i;
	bool have_name = false, have_primary = false, have_secondary = false, have_separator = false;

	// sbt_fields uses strunzone on the titles!
	if (!sbt_field_title[0])
		for (i = 0; i < MAX_SBT_FIELDS; ++i)
			sbt_field_title[i] = strzone("(null)");

	// TODO: re-enable with gametype-dependent cvars?
	if (argc < 3) // no arguments provided
		argc = tokenizebyseparator(strcat("0 1 ", autocvar_scoreboard_columns), " ");

	if (argc < 3)
		argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");

	if (argc == 3)
	{
		if (argv(2) == "default" || argv(2) == "expand_default")
		{
			if (argv(2) == "expand_default")
				cvar_set("scoreboard_columns", SCOREBOARD_DEFAULT_COLUMNS);
			argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");
		}
		else if (argv(2) == "all" || argv(2) == "ALL")
		{
			string s = "ping pl name |"; // scores without label (not really scores)
			if (argv(2) == "ALL")
			{
				// scores without label
				s = strcat(s, " ", "sum");
				s = strcat(s, " ", "kdratio");
				s = strcat(s, " ", "frags");
			}
			FOREACH(Scores, it != ps_primary && it != ps_secondary && scores_label(it) != "",
				s = strcat(s, " ", scores_label(it)));
			if (ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label(ps_secondary));
			s = strcat(s, " ", scores_label(ps_primary));
			argc = tokenizebyseparator(strcat("0 1 ", s), " ");
		}
	}


	sbt_num_fields = 0;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	string str, pattern;
	int slash;
	bool nocomplain;
	for (i = 1; i < argc - 1; ++i)
	{
		str = argv(i+1);
		nocomplain = false;
		if (substring(str, 0, 1) == "?")
		{
			nocomplain = true;
			str = substring(str, 1, strlen(str) - 1);
		}

		slash = strstrofs(str, "/", 0);
		if (slash >= 0)
		{
			pattern = substring(str, 0, slash);
			str = substring(str, slash + 1, strlen(str) - (slash + 1));

			if (!isGametypeInFilter(gametype, teamplay, false, pattern))
				continue;
		}

		str = strtolower(str);
		strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(str));

		PlayerScoreField j;
		switch (str)
		{
			// fields without a label (not networked via the score system)
			case "ping":     sbt_field[sbt_num_fields] = SP_PING; break;
			case "pl":       sbt_field[sbt_num_fields] = SP_PL; break;
			case "name":
			case "nick":     sbt_field[sbt_num_fields] = SP_NAME; have_name = true; break;
			case "|":        sbt_field[sbt_num_fields] = SP_SEPARATOR; have_separator = true; break;
			case "kd":
			case "kdr":
			case "kdratio":  sbt_field[sbt_num_fields] = SP_KDRATIO; break;
			case "sum":
			case "diff":
			case "k-d":      sbt_field[sbt_num_fields] = SP_SUM; break;
			case "frags":    sbt_field[sbt_num_fields] = SP_FRAGS; break;
			default: // fields with a label
			{
				// map alternative labels
				if (str == "damage")
					str = "dmg";
				if (str == "damagetaken")
					str = "dmgtaken";

				FOREACH(Scores, str == strtolower(scores_label(it)),
				{
					j = it;
					goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
				});

				// NOTE: can't check STAT(SHOWFPS) here, if checked too early it returns false anyway
				if (!nocomplain && str != "fps" && str != "skill") // server can disable the fps or skill fields
					LOG_INFOF("^1Error:^7 Unknown score field: '%s'", str);

				strfree(sbt_field_title[sbt_num_fields]);
				continue;

				LABEL(found)
				sbt_field[sbt_num_fields] = j;
				if (j == ps_primary)
					have_primary = true;
				if (j == ps_secondary)
					have_secondary = true;

			}
		}
		++sbt_num_fields;
		if (sbt_num_fields >= MAX_SBT_FIELDS)
			break;
	}

	if (scores_flags(ps_primary) & SFL_ALLOW_HIDE)
		have_primary = true;
	if (scores_flags(ps_secondary) & SFL_ALLOW_HIDE)
		have_secondary = true;
	if (ps_primary == ps_secondary)
		have_secondary = true;
	int missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

	if (sbt_num_fields + missing < MAX_SBT_FIELDS)
	{
		if (!have_name)
		{
			strfree(sbt_field_title[sbt_num_fields]);
			for (i = sbt_num_fields; i > 0; --i)
			{
				sbt_field_title[i] = sbt_field_title[i-1];
				sbt_field[i] = sbt_field[i-1];
			}
			sbt_field_title[0] = strzone(TranslateScoresLabel("name"));
			sbt_field[0] = SP_NAME;
			++sbt_num_fields;
			LOG_INFO("fixed missing field 'name'");

			if (!have_separator)
			{
				strfree(sbt_field_title[sbt_num_fields]);
				for (i = sbt_num_fields; i > 1; --i)
				{
					sbt_field_title[i] = sbt_field_title[i-1];
					sbt_field[i] = sbt_field[i-1];
				}
				sbt_field_title[1] = strzone("|");
				sbt_field[1] = SP_SEPARATOR;
				++sbt_num_fields;
				LOG_INFO("fixed missing field '|'");
			}
		}
		else if (!have_separator)
		{
			strcpy(sbt_field_title[sbt_num_fields], "|");
			sbt_field[sbt_num_fields] = SP_SEPARATOR;
			++sbt_num_fields;
			LOG_INFO("fixed missing field '|'");
		}
		if (!have_secondary)
		{
			strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(scores_label(ps_secondary)));
			sbt_field[sbt_num_fields] = ps_secondary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'", scores_label(ps_secondary));
		}
		if (!have_primary)
		{
			strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(scores_label(ps_primary)));
			sbt_field[sbt_num_fields] = ps_primary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'", scores_label(ps_primary));
		}
	}

	sbt_field[sbt_num_fields] = SP_END;
	sb_field_sizes_init = 1;
}
#undef SCOREBOARD_DEFAULT_COLUMNS

string Scoreboard_AddPlayerId(string pl_name, entity pl)
{
	return strcat(autocvar_hud_panel_scoreboard_playerid_prefix, itos(pl.sv_entnum + 1),
		autocvar_hud_panel_scoreboard_playerid_suffix, pl_name);
}

void Scoreboard_AddGametypeIcon(string icon)
{
	if (sbt_field_icon_gametype_set < MAX_SBT_FIELD_ICON_GAMETYPE)
	{
		sbt_field_icon_gametype[sbt_field_icon_gametype_set] = icon;
		++sbt_field_icon_gametype_set;
	}
	else
		LOG_INFO("^1ERROR:^7 Tried to add too many scoreboard gametype icons");
}

string Scoreboard_GetName(entity pl)
{
	// playercolor
	int i;
	if (!teamplay)
	{
		// NOTE: always adding 1024 allows saving the colormap 0 as a value != 0
		i = (playerslots[pl.sv_entnum].colormap >= 1024)
			? playerslots[pl.sv_entnum].colormap - 1024 // override server-side player colors
			: entcs_GetClientColors(pl.sv_entnum);

		sbt_field_icon_playercolor_rgb[2] = colormapPaletteColor(i & BITS(4), 1);
		sbt_field_icon_playercolor_rgb[1] = colormapPaletteColor(i >> 4, 0);
		sbt_field_icon_playercolor_rgb[0] = sbt_field_icon_playercolor_rgb[1];
		sbt_field_icon_playercolor_set = 3;
	}

	// extra
	float f;
	if (ready_waiting && pl.ready)
	{
		f = min(1, 1 + sin(2*M_PI * time));
		sbt_field_icon_extra_rgb[sbt_field_icon_extra_set] = vec3(f, 1, f); // pulses from white to green
		sbt_field_icon_extra[sbt_field_icon_extra_set] = "gfx/scoreboard/player_ready";
		++sbt_field_icon_extra_set;
	}
	if ((i = entcs_GetHandicapLevel(pl.sv_entnum)) != 0)
	{
		f = (16 - i) / 15;
		sbt_field_icon_extra_rgb[sbt_field_icon_extra_set] = vec3(1, f, f); // goes from white to red over level 1 to 16
		sbt_field_icon_extra[sbt_field_icon_extra_set] = "gfx/scoreboard/player_handicap";
		++sbt_field_icon_extra_set;
	}
	if (pl.ignored)
	{
		sbt_field_icon_extra_rgb[sbt_field_icon_extra_set] = '1 1 1';
		sbt_field_icon_extra[sbt_field_icon_extra_set] = "gfx/scoreboard/player_ignored";
		++sbt_field_icon_extra_set;
	}

	// gametype
	if (entcs_GetSpecState(pl.sv_entnum) != ENTCS_SPEC_PURE)
		MUTATOR_CALLHOOK(SetScoreboardGametypeIcons, playerslots[pl.sv_entnum]);

	return entcs_GetName(pl.sv_entnum);
}

int autocvar_hud_panel_scoreboard_ping_low = 20;
int autocvar_hud_panel_scoreboard_ping_medium = 80;
int autocvar_hud_panel_scoreboard_ping_high = 200;
vector autocvar_hud_panel_scoreboard_ping_low_color = '0 1 0';
vector autocvar_hud_panel_scoreboard_ping_medium_color = '1 1 0';
vector autocvar_hud_panel_scoreboard_ping_high_color = '1 0 0';
string Scoreboard_GetField(entity pl, PlayerScoreField field, bool per_round)
{
	float tmp, num, denom;
	int f;
	string str;
	sbt_field_rgb = '1 1 1';
	sbt_field_icon_playercolor_set = 0;
	sbt_field_icon_extra_set = 0;
	sbt_field_icon_gametype_set = 0;

	int rounds_played = 0;
	if (per_round)
		rounds_played = pl.(scores(SP_ROUNDS_PL));
	switch (field)
	{
		case SP_PING:
		#define PING_LOW autocvar_hud_panel_scoreboard_ping_low
		#define PING_MED autocvar_hud_panel_scoreboard_ping_medium
		#define PING_HIGH autocvar_hud_panel_scoreboard_ping_high
		#define COLOR_LOW autocvar_hud_panel_scoreboard_ping_low_color
		#define COLOR_MED autocvar_hud_panel_scoreboard_ping_medium_color
		#define COLOR_HIGH autocvar_hud_panel_scoreboard_ping_high_color
			if (!pl.gotscores)
				return "\xE2\x96\xB6\xE2\x96\xB6\xE2\x96\xB6"; // >>> sign using U+25B6 (Black Right-Pointing Triangle)
			//str = getplayerkeyvalue(pl.sv_entnum, "ping");
			f = pl.ping;
			if (f == 0)
				return _("N/A");
			// this colour selection code should match menuqc XonoticServerList_drawListBoxItem()
			if (f < PING_LOW)
				sbt_field_rgb = COLOR_LOW;
			else if (f < PING_MED)
				sbt_field_rgb = COLOR_LOW + (COLOR_MED - COLOR_LOW) * ((f - PING_LOW) / (PING_MED - PING_LOW));
			else if (f < PING_HIGH)
				sbt_field_rgb = COLOR_MED + (COLOR_HIGH - COLOR_MED) * ((f - PING_MED) / (PING_HIGH - PING_MED));
			else
				sbt_field_rgb = COLOR_HIGH;
			return ftos(f);
		#undef PING_LOW
		#undef PING_MED
		#undef PING_HIGH
		#undef COLOR_LOW
		#undef COLOR_MED
		#undef COLOR_HIGH

		case SP_PL:
			if (!pl.gotscores)
				return _("N/A");
			f = pl.ping_packetloss;
			tmp = pl.ping_movementloss;
			if (f == 0 && tmp == 0)
				return "";
			str = ftos(ceil(f * 100));
			if (tmp != 0)
				str = strcat(str, "~", ftos(ceil(tmp * 100)));
			tmp = bound(0, f / 0.2 + tmp / 0.04, 1); // 20% is REALLY BAD pl
			sbt_field_rgb = '1 0.5 0.5' - '0 0.5 0.5' * tmp;
			return str;

		case SP_NAME:
			str = Scoreboard_GetName(pl);
			if (autocvar_hud_panel_scoreboard_playerid)
				str = Scoreboard_AddPlayerId(str, pl);
			return str;

		case SP_FRAGS:
			f = pl.(scores(SP_KILLS)) - pl.(scores(SP_SUICIDES));
			if (rounds_played)
				return sprintf("%.1f", f / rounds_played);
			return ftos(f);

		case SP_KDRATIO:
			num = pl.(scores(SP_KILLS));
			denom = pl.(scores(SP_DEATHS));

			if (denom == 0)
			{
				sbt_field_rgb = '0 1 0';
				if (rounds_played)
					str = sprintf("%.1f", num / rounds_played);
				else
					str = sprintf("%d", num);
			}
			else if (num <= 0)
			{
				sbt_field_rgb = '1 0 0';
				if (rounds_played)
					str = sprintf("%.2f", num / (denom * rounds_played));
				else
					str = sprintf("%.1f", num / denom);
			}
			else
			{
				if (rounds_played)
					str = sprintf("%.2f", num / (denom * rounds_played));
				else
					str = sprintf("%.1f", num / denom);
			}
			return str;

		case SP_SUM:
			f = pl.(scores(SP_KILLS)) - pl.(scores(SP_DEATHS));

			if (f > 0)
				sbt_field_rgb = '0 1 0';
			else if (f == 0)
				sbt_field_rgb = '1 1 1';
			else
				sbt_field_rgb = '1 0 0';
			if (rounds_played)
				return sprintf("%.1f", f / rounds_played);
			return ftos(f);

		case SP_SKILL:
			tmp = pl.(scores(SP_SKILL));
			switch (tmp)
			{
				case -1: return "...";
				case -2: return _("N/A");
				default: return ftos(tmp);
			}

		case SP_FPS:
			tmp = pl.(scores(SP_FPS));
			if (tmp == 0)
			{
				sbt_field_rgb = '1 1 1';
				return ((pl.ping == 0) ? _("N/A") : "..."); // if 0 ping, either connecting or bot (either case can't show proper score)
			}
			// <=32fps full red, 64fps to 96fps (inclusive) full yellow, >=128fps white
			// A little opinionated but representative of what's adequate for a competitive experience,
			// with consideration to the default and supported ticrates and the minimum USB polling rate.
			sbt_field_rgb.x = 1;
			sbt_field_rgb.y = bound(0, (tmp - 32) * 0.03125, 1); // 0 at 32fps, 1 at 64fps
			sbt_field_rgb.z = bound(0, (tmp - 96) * 0.03125, 1); // 0 at 96fps, 1 at 128fps
			return ftos(tmp);

		case SP_ROUNDS_PL:
			return ftos(pl.(scores(field)));

		case SP_DMG: case SP_DMGTAKEN:
			if (rounds_played)
				return sprintf("%.2f k", pl.(scores(field)) / (1000 * rounds_played));
			return sprintf("%.1f k", pl.(scores(field)) / 1000);

		default: case SP_SCORE:
			tmp = pl.(scores(field));
			f = scores_flags(field);
			if (field == ps_primary)
				sbt_field_rgb = '1 1 0';
			else if (field == ps_secondary)
				sbt_field_rgb = '0 1 1';
			else
				sbt_field_rgb = '1 1 1';
			return ScoreString(f, tmp, rounds_played);
	}
	//return "error";
}

string Scoreboard_FixColumnWidth(int i, string str, bool init)
{
	TC(int, i);
	vector sz;
	int j;
	float f;

	sbt_fixcolumnwidth_iconlen_playercolor = 0;
	for (j = 0; j < sbt_field_icon_extra_set; ++j)
		sbt_fixcolumnwidth_iconlen_extra[j] = 0;
	for (j = 0; j < sbt_field_icon_gametype_set; ++j)
		sbt_fixcolumnwidth_iconlen_gametype[j] = 0;

	for (j = 0; j < sbt_field_icon_playercolor_set; ++j)
	{
		sz = draw_getimagesize(sbt_field_icon_playercolor[j]);
		f = sz.x / sz.y;
		if (sbt_fixcolumnwidth_iconlen_playercolor < f)
			sbt_fixcolumnwidth_iconlen_playercolor = f;
	}
	// NOTE: extra icons (player_ready and player_handicap) are squares (32x32), so this may not be necessary
	// simply setting sbt_fixcolumnwidth_iconlen_extra* = 1 would be equivalent
	for (j = 0; j < sbt_field_icon_extra_set; ++j)
	{
		sz = draw_getimagesize(sbt_field_icon_extra[j]);
		// XONRELEASE TODO: xonotic-v0.9.0 after release remove if (sz == 0) case
		if (sz == '0 0 0') // it happens in previous engine versions (Xonotic 0.8.6 or lower) when the image is missing
			sz = '1 1 0';
		sbt_fixcolumnwidth_iconlen_extra[j] = sz.x / sz.y;
	}
	for (j = 0; j < sbt_field_icon_gametype_set; ++j)
	{
		sz = draw_getimagesize_skin(sbt_field_icon_gametype[j]);
		sbt_fixcolumnwidth_iconlen_gametype[j] = sz.x / sz.y;;
	}

	// fix icon aspect
	sbt_fixcolumnwidth_iconlen_playercolor *= hud_fontsize.y / hud_fontsize.x;
	for (j = 0; j < sbt_field_icon_extra_set; ++j)
		sbt_fixcolumnwidth_iconlen_extra[j] *= hud_fontsize.y / hud_fontsize.x;
	for (j = 0; j < sbt_field_icon_gametype_set; ++j)
		sbt_fixcolumnwidth_iconlen_gametype[j] *= hud_fontsize.y / hud_fontsize.x;

	sbt_fixcolumnwidth_marginlen = stringwidth(" ", false, hud_fontsize);
	if (init)
		sbt_field_title_width[i] = stringwidth(sbt_field_title[i], false, hud_fontsize);

#define ADD_ICON_PADDING(val) \
	val += hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor; \
	for (j = 0; j < sbt_field_icon_extra_set; ++j) \
		val += hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j]; \
	for (j = 0; j < sbt_field_icon_gametype_set; ++j) \
		val += hud_fontsize.x * sbt_fixcolumnwidth_iconlen_gametype[j]; \
	if (sbt_fixcolumnwidth_iconlen_playercolor || sbt_field_icon_extra_set) \
		val += sbt_fixcolumnwidth_marginlen; \
	if (sbt_field_icon_gametype_set) \
		val += sbt_fixcolumnwidth_marginlen;

	if (sbt_field[i] == SP_NAME) // name gets all remaining space
	{
		float used_space = 0;
		for (j = 0; j < sbt_num_fields; ++j)
			if (j != i && sbt_field[i] != SP_SEPARATOR)
				used_space += sbt_field_size[j] + hud_fontsize.x;
		sbt_field_size[i] = max(sbt_field_title_width[i], panel_size.x - used_space);

		ADD_ICON_PADDING(used_space);
		float namesize = max(sbt_field_title_width[i], panel_size.x - used_space);
		str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		sbt_fixcolumnwidth_len = stringwidth(str, true, hud_fontsize);

		max_namesize = max(sbt_field_title_width[i], vid_conwidth - used_space);
	}
	else
	{
		if (init)
		{
			sbt_field_size[i] = sbt_field_title_width[i];
			float title_maxwidth = sbt_field_title_maxwidth * sbt_field_title_maxwidth_factor;
			if (sbt_field_size[i] && sbt_field_size[i] > title_maxwidth)
				sbt_field_size[i] = title_maxwidth;
		}
		sbt_fixcolumnwidth_len = stringwidth(str, false, hud_fontsize);
	}

	f = sbt_fixcolumnwidth_len;
	if (sbt_field[i] == SP_NAME)
		ADD_ICON_PADDING(f);
#undef ADD_ICON_PADDING
	if (sbt_field_size[i] < f)
		sbt_field_size[i] = f;

	sbt_field_title_condense_factor[i] = 0;
	if (sbt_field_title_width[i] > sbt_field_size[i])
	{
		float real_maxwidth = sbt_field_size[i];
		float title_maxwidth = sbt_field_title_maxwidth * sbt_field_title_maxwidth_factor;
		if (sbt_field_title_width[i] > title_maxwidth)
			real_maxwidth = max(sbt_field_size[i], title_maxwidth);
		sbt_field_title_condense_factor[i] = real_maxwidth / sbt_field_title_width[i];
	}

	return str;
}

void Scoreboard_InitFieldSizes(bool compress_more)
{
	if (compress_more)
	{
		float sbt_field_title_maxwidth_factor_prev = sbt_field_title_maxwidth_factor;
		sbt_field_title_maxwidth_factor -= 0.05;
		if (sbt_field_title_maxwidth * sbt_field_title_maxwidth_factor < 0.01 * vid_conwidth)
		{
			sbt_field_title_maxwidth_factor = (0.01 * vid_conwidth) / sbt_field_title_maxwidth;
			if (sbt_field_title_maxwidth_factor_prev == sbt_field_title_maxwidth_factor)
				return;
		}
	}
	else
		sbt_field_title_maxwidth_factor = 1;

	for (int i = 0; i < sbt_num_fields; ++i)
	{
		if (sbt_field[i] == SP_NAME)
		{
			name_field_index = i;
			continue;
		}

		Scoreboard_FixColumnWidth(i, "", true);
	}

	// Update name field size in the end as it takes remaining space
	Scoreboard_FixColumnWidth(name_field_index, "", true);
}
