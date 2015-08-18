#include "scoreboard.qh"
#include "_all.qh"

#include "hud.qh"
#include "sortlist.qh"

#include "../common/constants.qh"
#include "../common/counting.qh"
#include "../common/mapinfo.qh"
#include "../common/stats.qh"
#include "../common/teams.qh"
#include "../common/util.qh"

float scoreboard_alpha_bg;
float scoreboard_alpha_fg;
float scoreboard_highlight;
float scoreboard_highlight_alpha;
float scoreboard_highlight_alpha_self;
float scoreboard_alpha_name;
float scoreboard_alpha_name_self;

void drawstringright(vector, string, vector, vector, float, float);
void drawstringcenter(vector, string, vector, vector, float, float);

const float SCOREBOARD_OFFSET = 50;

// wrapper to put all possible scores titles through gettext
string TranslateScoresLabel(string l)
{
	switch(l)
	{
		case "bckills": return CTX(_("SCO^bckills"));
		case "bctime": return CTX(_("SCO^bctime"));
		case "caps": return CTX(_("SCO^caps"));
		case "captime": return CTX(_("SCO^captime"));
		case "deaths": return CTX(_("SCO^deaths"));
		case "destroyed": return CTX(_("SCO^destroyed"));
		case "drops": return CTX(_("SCO^drops"));
		case "faults": return CTX(_("SCO^faults"));
		case "fckills": return CTX(_("SCO^fckills"));
		case "goals": return CTX(_("SCO^goals"));
		case "kckills": return CTX(_("SCO^kckills"));
		case "kdratio": return CTX(_("SCO^kdratio"));
		case "k/d": return CTX(_("SCO^k/d"));
		case "kd": return CTX(_("SCO^kd"));
		case "kdr": return CTX(_("SCO^kdr"));
		case "kills": return CTX(_("SCO^kills"));
		case "laps": return CTX(_("SCO^laps"));
		case "lives": return CTX(_("SCO^lives"));
		case "losses": return CTX(_("SCO^losses"));
		case "name": return CTX(_("SCO^name"));
		case "sum": return CTX(_("SCO^sum"));
		case "nick": return CTX(_("SCO^nick"));
		case "objectives": return CTX(_("SCO^objectives"));
		case "pickups": return CTX(_("SCO^pickups"));
		case "ping": return CTX(_("SCO^ping"));
		case "pl": return CTX(_("SCO^pl"));
		case "pushes": return CTX(_("SCO^pushes"));
		case "rank": return CTX(_("SCO^rank"));
		case "returns": return CTX(_("SCO^returns"));
		case "revivals": return CTX(_("SCO^revivals"));
		case "score": return CTX(_("SCO^score"));
		case "suicides": return CTX(_("SCO^suicides"));
		case "takes": return CTX(_("SCO^takes"));
		case "ticks": return CTX(_("SCO^ticks"));
		default: return l;
	}
}

void HUD_InitScores()
{
	int i, f;

	ps_primary = ps_secondary = ts_primary = ts_secondary = -1;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		f = (scores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = i;
	}
	if(ps_secondary == -1)
		ps_secondary = ps_primary;

	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		f = (teamscores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if(ts_secondary == -1)
		ts_secondary = ts_primary;

	Cmd_HUD_SetFields(0);
}

float SetTeam(entity pl, float Team);
//float lastpnum;
void HUD_UpdatePlayerTeams()
{
	float Team;
	entity pl, tmp;
	float num;

	num = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		num += 1;
		Team = GetPlayerColor(pl.sv_entnum);
		if(SetTeam(pl, Team))
		{
			tmp = pl.sort_prev;
			HUD_UpdatePlayerPos(pl);
			if(tmp)
				pl = tmp;
			else
				pl = players.sort_next;
		}
	}
	/*
	if(num != lastpnum)
		print(strcat("PNUM: ", ftos(num), "\n"));
	lastpnum = num;
	*/
}

int HUD_CompareScore(float vl, float vr, int f)
{
	if(f & SFL_ZERO_IS_WORST)
	{
		if(vl == 0 && vr != 0)
			return 1;
		if(vl != 0 && vr == 0)
			return 0;
	}
	if(vl > vr)
		return IS_INCREASING(f);
	if(vl < vr)
		return IS_DECREASING(f);
	return -1;
}

float HUD_ComparePlayerScores(entity left, entity right)
{
	float vl, vr, r;
	vl = GetPlayerColor(left.sv_entnum);
	vr = GetPlayerColor(right.sv_entnum);

	if(!left.gotscores)
		vl = NUM_SPECTATOR;
	if(!right.gotscores)
		vr = NUM_SPECTATOR;

	if(vl > vr)
		return true;
	if(vl < vr)
		return false;

	if(vl == NUM_SPECTATOR)
	{
		// FIRST the one with scores (spectators), THEN the ones without (downloaders)
		// no other sorting
		if(!left.gotscores && right.gotscores)
			return true;
		return false;
	}

	r = HUD_CompareScore(left.scores[ps_primary], right.scores[ps_primary], scores_flags[ps_primary]);
	if (r >= 0)
		return r;

	r = HUD_CompareScore(left.scores[ps_secondary], right.scores[ps_secondary], scores_flags[ps_secondary]);
	if (r >= 0)
		return r;

	int i;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		r = HUD_CompareScore(left.scores[i], right.scores[i], scores_flags[i]);
		if (r >= 0)
			return r;
	}

	if (left.sv_entnum < right.sv_entnum)
		return true;

	return false;
}

void HUD_UpdatePlayerPos(entity player)
{
	for(other = player.sort_next; other && HUD_ComparePlayerScores(player, other); other = player.sort_next)
	{
		SORT_SWAP(player, other);
	}
	for(other = player.sort_prev; other != players && HUD_ComparePlayerScores(other, player); other = player.sort_prev)
	{
		SORT_SWAP(other, player);
	}
}

float HUD_CompareTeamScores(entity left, entity right)
{
	int i, r;

	if(left.team == NUM_SPECTATOR)
		return 1;
	if(right.team == NUM_SPECTATOR)
		return 0;

	r = HUD_CompareScore(left.teamscores[ts_primary], right.teamscores[ts_primary], teamscores_flags[ts_primary]);
	if (r >= 0)
		return r;

	r = HUD_CompareScore(left.teamscores[ts_secondary], right.teamscores[ts_secondary], teamscores_flags[ts_secondary]);
	if (r >= 0)
		return r;

	for(i = 0; i < MAX_SCORE; ++i)
	{
		r = HUD_CompareScore(left.teamscores[i], right.teamscores[i], teamscores_flags[i]);
		if (r >= 0)
			return r;
	}

	if (left.team < right.team)
		return true;

	return false;
}

void HUD_UpdateTeamPos(entity Team)
{
	for(other = Team.sort_next; other && HUD_CompareTeamScores(Team, other); other = Team.sort_next)
	{
		SORT_SWAP(Team, other);
	}
	for(other = Team.sort_prev; other != teams && HUD_CompareTeamScores(other, Team); other = Team.sort_prev)
	{
		SORT_SWAP(other, Team);
	}
}

void Cmd_HUD_Help()
{
	print(_("You can modify the scoreboard using the ^2scoreboard_columns_set command.\n"));
	print(_("^3|---------------------------------------------------------------|\n"));
	print(_("Usage:\n"));
	print(_("^2scoreboard_columns_set default\n"));
	print(_("^2scoreboard_columns_set ^7field1 field2 ...\n"));
	print(_("The following field names are recognized (case insensitive):\n"));
	print(_("You can use a ^3|^7 to start the right-aligned fields.\n\n"));

	print(_("^3name^7 or ^3nick^7             Name of a player\n"));
	print(_("^3ping^7                     Ping time\n"));
	print(_("^3pl^7                       Packet loss\n"));
	print(_("^3kills^7                    Number of kills\n"));
	print(_("^3deaths^7                   Number of deaths\n"));
	print(_("^3suicides^7                 Number of suicides\n"));
	print(_("^3frags^7                    kills - suicides\n"));
	print(_("^3kd^7                       The kill-death ratio\n"));
	print(_("^3sum^7                      frags - deaths\n"));
	print(_("^3caps^7                     How often a flag (CTF) or a key (KeyHunt) was captured\n"));
	print(_("^3pickups^7                  How often a flag (CTF) or a key (KeyHunt) or a ball (Keepaway) was picked up\n"));
	print(_("^3captime^7                  Time of fastest cap (CTF)\n"));
	print(_("^3fckills^7                  Number of flag carrier kills\n"));
	print(_("^3returns^7                  Number of flag returns\n"));
	print(_("^3drops^7                    Number of flag drops\n"));
	print(_("^3lives^7                    Number of lives (LMS)\n"));
	print(_("^3rank^7                     Player rank\n"));
	print(_("^3pushes^7                   Number of players pushed into void\n"));
	print(_("^3destroyed^7                Number of keys destroyed by pushing them into void\n"));
	print(_("^3kckills^7                  Number of keys carrier kills\n"));
	print(_("^3losses^7                   Number of times a key was lost\n"));
	print(_("^3laps^7                     Number of laps finished (race/cts)\n"));
	print(_("^3time^7                     Total time raced (race/cts)\n"));
	print(_("^3fastest^7                  Time of fastest lap (race/cts)\n"));
	print(_("^3ticks^7                    Number of ticks (DOM)\n"));
	print(_("^3takes^7                    Number of domination points taken (DOM)\n"));
	print(_("^3bckills^7                  Number of ball carrier kills\n"));
	print(_("^3bctime^7                   Total amount of time holding the ball in Keepaway\n"));
	print(_("^3score^7                    Total score\n\n"));

	print(_("Before a field you can put a + or - sign, then a comma separated list\n"
	        "of game types, then a slash, to make the field show up only in these\n"
	        "or in all but these game types. You can also specify 'all' as a\n"
	        "field to show all fields available for the current game mode.\n\n"));

	print(_("The special game type names 'teams' and 'noteams' can be used to\n"
	        "include/exclude ALL teams/noteams game modes.\n\n"));

	print(_("Example: scoreboard_columns_set name ping pl | +ctf/field3 -dm/field4\n"));
	print(_("will display name, ping and pl aligned to the left, and the fields\n"
	        "right of the vertical bar aligned to the right.\n"));
	print(_("'field3' will only be shown in CTF, and 'field4' will be shown in all\n"
	        "other gamemodes except DM.\n"));
}

#define HUD_DefaultColumnLayout() \
"ping pl name | " \
"-teams,race,lms/kills +ft,tdm/kills -teams,lms/deaths +ft,tdm/deaths -teams,lms,race,ka/suicides +ft,tdm/suicides -race,dm,tdm,ka,ft/frags " /* tdm already has this in "score" */ \
"+ctf/caps +ctf/pickups +ctf/fckills +ctf/returns +ons/caps +ons/takes " \
"+lms/lives +lms/rank " \
"+kh/caps +kh/pushes +kh/destroyed " \
"?+race/laps ?+race/time ?+race/fastest " \
"+as/objectives +nb/faults +nb/goals +ka/pickups +ka/bckills +ka/bctime +ft/revivals " \
"-lms,race,nb/score"

void Cmd_HUD_SetFields(float argc)
{
	int i, j, slash;
	string str, pattern;
	float have_name = 0, have_primary = 0, have_secondary = 0, have_separator = 0;
	float missing;

	if(!gametype)
	{
		// set up a temporary scoreboard layout
		// no layout can be properly set up until score_info data haven't been received
		argc = tokenizebyseparator("0 1 ping pl name | score", " ");
		ps_primary = 0;
		scores_label[ps_primary] = strzone("score");
		scores_flags[ps_primary] = SFL_ALLOW_HIDE;
	}

	// TODO: re enable with gametype dependant cvars?
	if(argc < 3) // no arguments provided
		argc = tokenizebyseparator(strcat("0 1 ", autocvar_scoreboard_columns), " ");

	if(argc < 3)
		argc = tokenizebyseparator(strcat("0 1 ", HUD_DefaultColumnLayout()), " ");

	if(argc == 3)
	{
		if(argv(2) == "default")
			argc = tokenizebyseparator(strcat("0 1 ", HUD_DefaultColumnLayout()), " ");
		else if(argv(2) == "all")
		{
			string s;
			s = "ping pl name |";
			for(i = 0; i < MAX_SCORE; ++i)
			{
				if(i != ps_primary)
				if(i != ps_secondary)
				if(scores_label[i] != "")
					s = strcat(s, " ", scores_label[i]);
			}
			if(ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label[ps_secondary]);
			s = strcat(s, " ", scores_label[ps_primary]);
			argc = tokenizebyseparator(strcat("0 1 ", s), " ");
		}
	}


	hud_num_fields = 0;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	for(i = 1; i < argc - 1; ++i)
	{
		float nocomplain;
		str = argv(i+1);

		nocomplain = false;
		if(substring(str, 0, 1) == "?")
		{
			nocomplain = true;
			str = substring(str, 1, strlen(str) - 1);
		}

		slash = strstrofs(str, "/", 0);
		if(slash >= 0)
		{
			pattern = substring(str, 0, slash);
			str = substring(str, slash + 1, strlen(str) - (slash + 1));

			if (!isGametypeInFilter(gametype, teamplay, false, pattern))
				continue;
		}

		strunzone(hud_title[hud_num_fields]);
		hud_title[hud_num_fields] = strzone(TranslateScoresLabel(str));
		hud_size[hud_num_fields] = stringwidth(hud_title[hud_num_fields], false, hud_fontsize);
		str = strtolower(str);

		if(str == "ping") {
			hud_field[hud_num_fields] = SP_PING;
		} else if(str == "pl") {
			hud_field[hud_num_fields] = SP_PL;
		} else if(str == "kd" || str == "kdr" || str == "kdratio" || str == "k/d") {
			hud_field[hud_num_fields] = SP_KDRATIO;
		} else if(str == "sum" || str == "diff" || str == "k-d") {
			hud_field[hud_num_fields] = SP_SUM;
		} else if(str == "name" || str == "nick") {
			hud_field[hud_num_fields] = SP_NAME;
			have_name = 1;
		} else if(str == "|") {
			hud_field[hud_num_fields] = SP_SEPARATOR;
			have_separator = 1;
		} else {
			for(j = 0; j < MAX_SCORE; ++j)
				if(str == strtolower(scores_label[j]))
					goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
:notfound
			if(str == "frags")
			{
				j = SP_FRAGS;
			}
			else
			{
				if (!nocomplain)
					printf("^1Error:^7 Unknown score field: '%s'\n", str);
				continue;
			}
:found
			hud_field[hud_num_fields] = j;
			if(j == ps_primary)
				have_primary = 1;
			if(j == ps_secondary)
				have_secondary = 1;
		}
		++hud_num_fields;
		if(hud_num_fields >= MAX_HUD_FIELDS)
			break;
	}

	if(scores_flags[ps_primary] & SFL_ALLOW_HIDE)
		have_primary = 1;
	if(scores_flags[ps_secondary] & SFL_ALLOW_HIDE)
		have_secondary = 1;
	if(ps_primary == ps_secondary)
		have_secondary = 1;
	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

	if(hud_num_fields+missing < MAX_HUD_FIELDS)
	{
		if(!have_name)
		{
			strunzone(hud_title[hud_num_fields]);
			for(i = hud_num_fields; i > 0; --i)
			{
				hud_title[i] = hud_title[i-1];
				hud_size[i] = hud_size[i-1];
				hud_field[i] = hud_field[i-1];
			}
			hud_title[0] = strzone(TranslateScoresLabel("name"));
			hud_field[0] = SP_NAME;
			++hud_num_fields;
			print("fixed missing field 'name'\n");

			if(!have_separator)
			{
				strunzone(hud_title[hud_num_fields]);
				for(i = hud_num_fields; i > 1; --i)
				{
					hud_title[i] = hud_title[i-1];
					hud_size[i] = hud_size[i-1];
					hud_field[i] = hud_field[i-1];
				}
				hud_title[1] = strzone("|");
				hud_field[1] = SP_SEPARATOR;
				hud_size[1] = stringwidth("|", false, hud_fontsize);
				++hud_num_fields;
				print("fixed missing field '|'\n");
			}
		}
		else if(!have_separator)
		{
			strunzone(hud_title[hud_num_fields]);
			hud_title[hud_num_fields] = strzone("|");
			hud_size[hud_num_fields] = stringwidth("|", false, hud_fontsize);
			hud_field[hud_num_fields] = SP_SEPARATOR;
			++hud_num_fields;
			print("fixed missing field '|'\n");
		}
		if(!have_secondary)
		{
			strunzone(hud_title[hud_num_fields]);
			hud_title[hud_num_fields] = strzone(TranslateScoresLabel(scores_label[ps_secondary]));
			hud_size[hud_num_fields] = stringwidth(hud_title[hud_num_fields], false, hud_fontsize);
			hud_field[hud_num_fields] = ps_secondary;
			++hud_num_fields;
			printf("fixed missing field '%s'\n", scores_label[ps_secondary]);
		}
		if(!have_primary)
		{
			strunzone(hud_title[hud_num_fields]);
			hud_title[hud_num_fields] = strzone(TranslateScoresLabel(scores_label[ps_primary]));
			hud_size[hud_num_fields] = stringwidth(hud_title[hud_num_fields], false, hud_fontsize);
			hud_field[hud_num_fields] = ps_primary;
			++hud_num_fields;
			printf("fixed missing field '%s'\n", scores_label[ps_primary]);
		}
	}

	hud_field[hud_num_fields] = SP_END;
}

// MOVEUP::
vector hud_field_rgb;
string hud_field_icon0;
string hud_field_icon1;
string hud_field_icon2;
vector hud_field_icon0_rgb;
vector hud_field_icon1_rgb;
vector hud_field_icon2_rgb;
float hud_field_icon0_alpha;
float hud_field_icon1_alpha;
float hud_field_icon2_alpha;
string HUD_GetField(entity pl, int field)
{
	float tmp, num, denom;
	int f;
	string str;
	hud_field_rgb = '1 1 1';
	hud_field_icon0 = "";
	hud_field_icon1 = "";
	hud_field_icon2 = "";
	hud_field_icon0_rgb = '1 1 1';
	hud_field_icon1_rgb = '1 1 1';
	hud_field_icon2_rgb = '1 1 1';
	hud_field_icon0_alpha = 1;
	hud_field_icon1_alpha = 1;
	hud_field_icon2_alpha = 1;
	switch(field)
	{
		case SP_PING:
			if (!pl.gotscores)
				return "\xE2\x96\xB6\xE2\x96\xB6\xE2\x96\xB6"; // >>> sign using U+25B6
			//str = getplayerkeyvalue(pl.sv_entnum, "ping");
			f = pl.ping;
			if(f == 0)
				return _("N/A");
			tmp = max(0, min(220, f-80)) / 220;
			hud_field_rgb = '1 1 1' - '0 1 1'*tmp;
			return ftos(f);

		case SP_PL:
			if (!pl.gotscores)
				return _("N/A");
			f = pl.ping_packetloss;
			tmp = pl.ping_movementloss;
			if(f == 0 && tmp == 0)
				return "";
			str = ftos(ceil(f * 100));
			if(tmp != 0)
				str = strcat(str, "~", ftos(ceil(tmp * 100)));
			tmp = bound(0, f / 0.2 + tmp / 0.04, 1); // 20% is REALLY BAD pl
			hud_field_rgb = '1 0.5 0.5' - '0 0.5 0.5'*tmp;
			return str;

		case SP_NAME:
			if(ready_waiting && pl.ready)
			{
				hud_field_icon0 = "gfx/scoreboard/player_ready";
			}
			else if(!teamplay)
			{
				f = stof(getplayerkeyvalue(pl.sv_entnum, "colors"));
				{
					hud_field_icon0 = "gfx/scoreboard/playercolor_base";
					hud_field_icon1 = "gfx/scoreboard/playercolor_shirt";
					hud_field_icon1_rgb = colormapPaletteColor(floor(f / 16), 0);
					hud_field_icon2 = "gfx/scoreboard/playercolor_pants";
					hud_field_icon2_rgb = colormapPaletteColor(f % 16, 1);
				}
			}
			return GetPlayerName(pl.sv_entnum);

		case SP_FRAGS:
			f = pl.(scores[SP_KILLS]);
			f -= pl.(scores[SP_SUICIDES]);
			return ftos(f);

		case SP_KDRATIO:
			num = pl.(scores[SP_KILLS]);
			denom = pl.(scores[SP_DEATHS]);

			if(denom == 0) {
				hud_field_rgb = '0 1 0';
				str = sprintf("%d", num);
			} else if(num <= 0) {
				hud_field_rgb = '1 0 0';
				str = sprintf("%.1f", num/denom);
			} else
				str = sprintf("%.1f", num/denom);
			return str;

		case SP_SUM:
			f = pl.(scores[SP_KILLS]);
			f -= pl.(scores[SP_DEATHS]);

			if(f > 0) {
				hud_field_rgb = '0 1 0';
			} else if(f == 0) {
				hud_field_rgb = '1 1 1';
			} else {
				hud_field_rgb = '1 0 0';
			}
			return ftos(f);

		default:
			tmp = pl.(scores[field]);
			f = scores_flags[field];
			if(field == ps_primary)
				hud_field_rgb = '1 1 0';
			else if(field == ps_secondary)
				hud_field_rgb = '0 1 1';
			else
				hud_field_rgb = '1 1 1';
			return ScoreString(f, tmp);
	}
	//return "error";
}

float hud_fixscoreboardcolumnwidth_len;
float hud_fixscoreboardcolumnwidth_iconlen;
float hud_fixscoreboardcolumnwidth_marginlen;

string HUD_FixScoreboardColumnWidth(int i, string str)
{
	float field, f;
	vector sz;
	field = hud_field[i];

	hud_fixscoreboardcolumnwidth_iconlen = 0;

	if(hud_field_icon0 != "")
	{
		sz = draw_getimagesize(hud_field_icon0);
		f = sz.x / sz.y;
		if(hud_fixscoreboardcolumnwidth_iconlen < f)
			hud_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(hud_field_icon1 != "")
	{
		sz = draw_getimagesize(hud_field_icon1);
		f = sz.x / sz.y;
		if(hud_fixscoreboardcolumnwidth_iconlen < f)
			hud_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(hud_field_icon2 != "")
	{
		sz = draw_getimagesize(hud_field_icon2);
		f = sz.x / sz.y;
		if(hud_fixscoreboardcolumnwidth_iconlen < f)
			hud_fixscoreboardcolumnwidth_iconlen = f;
	}

	hud_fixscoreboardcolumnwidth_iconlen *= hud_fontsize.y / hud_fontsize.x; // fix icon aspect

	if(hud_fixscoreboardcolumnwidth_iconlen != 0)
		hud_fixscoreboardcolumnwidth_marginlen = stringwidth(" ", false, hud_fontsize);
	else
		hud_fixscoreboardcolumnwidth_marginlen = 0;

	if(field == SP_NAME) // name gets all remaining space
	{
		int j;
		float namesize;
		namesize = sbwidth;// / hud_fontsize_x;
		for(j = 0; j < hud_num_fields; ++j)
			if(j != i)
				if (hud_field[i] != SP_SEPARATOR)
					namesize -= hud_size[j] + hud_fontsize.x;
		namesize += hud_fontsize.x;
		hud_size[i] = namesize;

		if (hud_fixscoreboardcolumnwidth_iconlen != 0)
			namesize -= hud_fixscoreboardcolumnwidth_marginlen + hud_fixscoreboardcolumnwidth_iconlen;
		str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		hud_fixscoreboardcolumnwidth_len = stringwidth(str, true, hud_fontsize);
	}
	else
		hud_fixscoreboardcolumnwidth_len = stringwidth(str, false, hud_fontsize);

	f = hud_fixscoreboardcolumnwidth_len + hud_fixscoreboardcolumnwidth_marginlen + hud_fixscoreboardcolumnwidth_iconlen;
	if(hud_size[i] < f)
		hud_size[i] = f;

	return str;
}

void HUD_PrintScoreboardItem(vector pos, vector item_size, entity pl, float is_self, int pl_number)
{
	vector tmp, rgb;
	rgb = Team_ColorRGB(pl.team);
	string str;
	int field;
	float is_spec;
	is_spec = (GetPlayerColor(pl.sv_entnum) == NUM_SPECTATOR);

	if((rgb == '1 1 1') && (!is_spec)) {
		rgb.x = autocvar_scoreboard_color_bg_r + 0.5;
		rgb.y = autocvar_scoreboard_color_bg_g + 0.5;
		rgb.z = autocvar_scoreboard_color_bg_b + 0.5; }

	vector h_pos = pos - '1 1 0';
	vector h_size = item_size + '2 0 0';
	// alternated rows highlighting
	if(is_self)
		drawfill(h_pos, h_size, rgb, scoreboard_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if((scoreboard_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, scoreboard_highlight_alpha, DRAWFLAG_NORMAL);

	tmp.x = item_size.x;
	tmp.y = 0;
	tmp.z = 0;
	int i;
	for(i = 0; i < hud_num_fields; ++i)
	{
		field = hud_field[i];
		if(field == SP_SEPARATOR)
			break;

		if(is_spec && field != SP_NAME && field != SP_PING) {
			pos.x += hud_size[i] + hud_fontsize.x;
			continue;
		}
		str = HUD_GetField(pl, field);
		str = HUD_FixScoreboardColumnWidth(i, str);

		pos.x += hud_size[i] + hud_fontsize.x;

		if(field == SP_NAME) {
			tmp.x = hud_size[i] - hud_fontsize.x*hud_fixscoreboardcolumnwidth_iconlen - hud_fixscoreboardcolumnwidth_marginlen + hud_fontsize.x;
			if (is_self)
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
			else
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, scoreboard_alpha_name, DRAWFLAG_NORMAL);
		} else {
			tmp.x = hud_fixscoreboardcolumnwidth_len + hud_fontsize.x;
			if (is_self)
				drawstring(pos - tmp, str, hud_fontsize, hud_field_rgb, scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
			else
				drawstring(pos - tmp, str, hud_fontsize, hud_field_rgb, scoreboard_alpha_name, DRAWFLAG_NORMAL);
		}

		tmp.x = hud_size[i] + hud_fontsize.x;
		if(hud_field_icon0 != "")
			if (is_self)
				drawpic(pos - tmp, hud_field_icon0, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon0_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, hud_field_icon0, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon0_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
		if(hud_field_icon1 != "")
			if (is_self)
				drawpic(pos - tmp, hud_field_icon1, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon1_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, hud_field_icon1, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon1_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
		if(hud_field_icon2 != "")
			if (is_self)
				drawpic(pos - tmp, hud_field_icon2, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon2_rgb, hud_field_icon2_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, hud_field_icon2, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon2_rgb, hud_field_icon2_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
	}

	if(hud_field[i] == SP_SEPARATOR)
	{
		pos.x = xmax;
		for(i = hud_num_fields-1; i > 0; --i)
		{
			field = hud_field[i];
			if(field == SP_SEPARATOR)
				break;

			if(is_spec && field != SP_NAME && field != SP_PING) {
				pos.x -= hud_size[i] + hud_fontsize.x;
				continue;
			}

			str = HUD_GetField(pl, field);
			str = HUD_FixScoreboardColumnWidth(i, str);

			if(field == SP_NAME) {
				tmp.x = hud_fixscoreboardcolumnwidth_len; // left or right aligned? let's put it right...
				if(is_self)
					drawcolorcodedstring(pos - tmp, str, hud_fontsize, scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
				else
					drawcolorcodedstring(pos - tmp, str, hud_fontsize, scoreboard_alpha_name, DRAWFLAG_NORMAL);
			} else {
				tmp.x = hud_fixscoreboardcolumnwidth_len;
				if(is_self)
					drawstring(pos - tmp, str, hud_fontsize, hud_field_rgb, scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
				else
					drawstring(pos - tmp, str, hud_fontsize, hud_field_rgb, scoreboard_alpha_name, DRAWFLAG_NORMAL);
			}

			tmp.x = hud_size[i];
			if(hud_field_icon0 != "")
				if (is_self)
					drawpic(pos - tmp, hud_field_icon0, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon0_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, hud_field_icon0, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon0_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
			if(hud_field_icon1 != "")
				if (is_self)
					drawpic(pos - tmp, hud_field_icon1, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon1_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, hud_field_icon1, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon1_rgb, hud_field_icon1_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
			if(hud_field_icon2 != "")
				if (is_self)
					drawpic(pos - tmp, hud_field_icon2, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon2_rgb, hud_field_icon2_alpha * scoreboard_alpha_name_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, hud_field_icon2, '0 1 0' * hud_fontsize.y + '1 0 0' * hud_fontsize.x * hud_fixscoreboardcolumnwidth_iconlen, hud_field_icon2_rgb, hud_field_icon2_alpha * scoreboard_alpha_name, DRAWFLAG_NORMAL);
			pos.x -= hud_size[i] + hud_fontsize.x;
		}
	}

	if(pl.eliminated)
		drawfill(h_pos, h_size, '0 0 0', 0.5, DRAWFLAG_NORMAL);
}

/*
 * HUD_Scoreboard_MakeTable
 *
 * Makes a table for a team (for all playing players in DM) and fills it
 */

vector HUD_Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size)
{
	float body_table_height;
	vector tmp = '0 0 0', column_dim = '0 0 0';
	entity pl;

	body_table_height = 1.25 * hud_fontsize.y * max(1, tm.team_size); // no player? show 1 empty line

	pos.y += autocvar_scoreboard_border_thickness;
	pos -= '1 1 0';

	tmp.x = sbwidth + 2;
	tmp.y = 1.25 * hud_fontsize.y;

	// rounded header
	if (teamplay)
		drawpic(pos, "gfx/scoreboard/scoreboard_tableheader", tmp, (rgb * autocvar_scoreboard_color_bg_team) + '0.5 0.5 0.5', scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	else
		drawpic(pos, "gfx/scoreboard/scoreboard_tableheader", tmp, rgb + '0.5 0.5 0.5', scoreboard_alpha_bg, DRAWFLAG_NORMAL);

	// table border
	tmp.y += autocvar_scoreboard_border_thickness;
	tmp.y += body_table_height;
	drawborderlines(autocvar_scoreboard_border_thickness, pos, tmp, '0 0 0', scoreboard_alpha_bg, DRAWFLAG_NORMAL); // more transparency for the scoreboard

	// separator header/table
	pos.y += 1.25 * hud_fontsize.y;
	tmp.y = autocvar_scoreboard_border_thickness;
	drawfill(pos, tmp, '0 0 0', scoreboard_alpha_bg, DRAWFLAG_NORMAL);

	pos.y += autocvar_scoreboard_border_thickness;

	// table background
	tmp.y = body_table_height;
	if (teamplay)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb * autocvar_scoreboard_color_bg_team, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	else
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, scoreboard_alpha_bg, DRAWFLAG_NORMAL);

	// anyway, apply some color
	//drawfill(pos, tmp + '2 0 0', rgb, 0.1, DRAWFLAG_NORMAL);

	// go back to the top to make alternated columns highlighting and to print the strings
	pos.y -= 1.25 * hud_fontsize.y;
	pos.y -= autocvar_scoreboard_border_thickness;

	pos += '1 1 0';

	if (scoreboard_highlight)
	{
		column_dim.y = 1.25 * hud_fontsize.y; // header
		column_dim.y += autocvar_scoreboard_border_thickness;
		column_dim.y += body_table_height;
	}

	// print the strings of the columns headers and draw the columns
	int i;
	for(i = 0; i < hud_num_fields; ++i)
	{
		if(hud_field[i] == SP_SEPARATOR)
			break;
		column_dim.x = hud_size[i] + hud_fontsize.x;
		if (scoreboard_highlight)
		{
			if (i % 2)
				drawfill(pos - '0 1 0' - hud_fontsize.x / 2 * '1 0 0', column_dim, '0 0 0', scoreboard_alpha_bg * 0.2, DRAWFLAG_NORMAL);
		}
		drawstring(pos, hud_title[i], hud_fontsize, rgb * 1.5, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		pos.x += column_dim.x;
	}
	if(hud_field[i] == SP_SEPARATOR)
	{
		pos.x = xmax;
		tmp.y = 0;
		for(i = hud_num_fields-1; i > 0; --i)
		{
			if(hud_field[i] == SP_SEPARATOR)
				break;

			pos.x -= hud_size[i];

			if (scoreboard_highlight)
			{
				if (!(i % 2))
				{
					if (i == hud_num_fields-1)
						column_dim.x = hud_size[i] + hud_fontsize.x / 2 + 1;
					else
						column_dim.x = hud_size[i] + hud_fontsize.x;
					drawfill(pos - '0 1 0' - hud_fontsize.x / 2 * '1 0 0', column_dim, '0 0 0', scoreboard_alpha_bg * 0.2, DRAWFLAG_NORMAL);
				}
			}

			tmp.x = stringwidth(hud_title[i], false, hud_fontsize);
			tmp.x = (hud_size[i] - tmp.x);
			drawstring(pos + tmp, hud_title[i], hud_fontsize, rgb * 1.5, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			pos.x -= hud_fontsize.x;
		}
	}

	pos.x = xmin;
	pos.y += 1.25 * hud_fontsize.y; // skip the header
	pos.y += autocvar_scoreboard_border_thickness;

	// item size
	tmp.x = sbwidth;
	tmp.y = hud_fontsize.y * 1.25;

	// fill the table and draw the rows
	i = 0;
	if (teamplay)
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team != tm.team)
				continue;
			HUD_PrintScoreboardItem(pos, tmp, pl, (pl.sv_entnum == player_localnum), i);
			pos.y += 1.25 * hud_fontsize.y;
			++i;
		}
	else
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team == NUM_SPECTATOR)
				continue;
			HUD_PrintScoreboardItem(pos, tmp, pl, (pl.sv_entnum == player_localnum), i);
			pos.y += 1.25 * hud_fontsize.y;
			++i;
		}

	if (i == 0)
		pos.y += 1.25 * hud_fontsize.y; // move to the end of the table
	pos.y += 1.25 * hud_fontsize.y; // move empty row (out of the table)

	return pos;
}

float HUD_WouldDrawScoreboard() {
	if (autocvar__hud_configure)
		return 0;
	else if (HUD_Radar_Clickable())
		return 0;
	else if (scoreboard_showscores)
		return 1;
	else if (intermission == 1)
		return 1;
	else if (intermission == 2)
		return 0;
	else if (spectatee_status != -1 && getstati(STAT_HEALTH) <= 0 && autocvar_cl_deathscoreboard && gametype != MAPINFO_TYPE_CTS)
		return 1;
	else if (scoreboard_showscores_force)
		return 1;
	return 0;
}

float average_accuracy;
vector HUD_DrawScoreboardAccuracyStats(vector pos, vector rgb, vector bg_size)
{
	WepSet weapons_stat = WepSet_GetFromStat();
	WepSet weapons_inmap = WepSet_GetFromStat_InMap();
	float initial_posx = pos.x;
	int i;
	float weapon_stats;
	int disownedcnt = 0;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if(!self.weapon)
			continue;

		weapon_stats = weapon_accuracy[i-WEP_FIRST];

		if(weapon_stats < 0 && !(weapons_stat & WepSet_FromWeapon(i) || weapons_inmap & WepSet_FromWeapon(i)))
			++disownedcnt;
	}

	int weapon_cnt = WEP_COUNT - disownedcnt;

	if(weapon_cnt <= 0)
		return pos;

	int rows;
	if(autocvar_scoreboard_accuracy_doublerows && weapon_cnt >= floor(WEP_COUNT * 0.5))
		rows = 2;
	else
		rows = 1;
	int columnns = ceil(weapon_cnt / rows);

	float height = 40;
	float fontsize = height * 1/3;
	float weapon_height = height * 2/3;
	float weapon_width = sbwidth / columnns / rows;

	drawstring(pos, sprintf(_("Accuracy stats (average %d%%)"), average_accuracy), hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y + autocvar_scoreboard_border_thickness;
	vector tmp = '0 0 0';
	tmp.x = sbwidth;
	tmp.y = height * rows;

	if (teamplay)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb * autocvar_scoreboard_color_bg_team, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	else
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	drawborderlines(autocvar_scoreboard_border_thickness, pos, tmp, '0 0 0', scoreboard_alpha_bg * 0.75, DRAWFLAG_NORMAL);

	// column highlighting
	for(i = 0; i < columnns; ++i)
	{
		if(!(i % 2))
			drawfill(pos + '1 0 0' * weapon_width * rows * i, '0 1 0' * height * rows + '1 0 0' * weapon_width * rows, '0 0 0', scoreboard_alpha_bg * 0.2, DRAWFLAG_NORMAL);
	}

	// row highlighting
	for(i = 0; i < rows; ++i)
	{
		drawfill(pos + '0 1 0' * weapon_height + '0 1 0' * height * i, '1 0 0' * sbwidth + '0 1 0' * fontsize, '1 1 1', scoreboard_highlight_alpha, DRAWFLAG_NORMAL);
	}

	average_accuracy = 0;
	int weapons_with_stats = 0;
	if(rows == 2)
		pos.x += weapon_width / 2;

	if(autocvar_scoreboard_accuracy_nocolors)
		rgb = '1 1 1';
	else
		Accuracy_LoadColors();

	float oldposx = pos.x;
	vector tmpos = pos;

	int column;
	for(i = WEP_FIRST, column = 0; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if (!self.weapon)
			continue;
		weapon_stats = weapon_accuracy[i-WEP_FIRST];

		if(weapon_stats < 0 && !(weapons_stat & WepSet_FromWeapon(i) || weapons_inmap & WepSet_FromWeapon(i)))
			continue;

		float weapon_alpha;
		if(weapon_stats >= 0)
			weapon_alpha = scoreboard_alpha_fg;
		else
			weapon_alpha = 0.2 * scoreboard_alpha_fg;

		// weapon icon
		drawpic_aspect_skin(tmpos, self.model2, '1 0 0' * weapon_width + '0 1 0' * weapon_height, '1 1 1', weapon_alpha, DRAWFLAG_NORMAL);
		// the accuracy
		if(weapon_stats >= 0) {
			weapons_with_stats += 1;
			average_accuracy += weapon_stats; // store sum of all accuracies in average_accuracy

			string s;
			s = sprintf("%d%%", weapon_stats*100);

			float padding;
			padding = (weapon_width - stringwidth(s, false, '1 0 0' * fontsize)) / 2; // center the accuracy value

			if(!autocvar_scoreboard_accuracy_nocolors)
				rgb = Accuracy_GetColor(weapon_stats);

			drawstring(tmpos + '1 0 0' * padding + '0 1 0' * weapon_height, s, '1 1 0' * fontsize, rgb, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		}
		tmpos.x += weapon_width * rows;
		pos.x += weapon_width * rows;
		if(rows == 2 && column == columnns - 1) {
			tmpos.x = oldposx;
			tmpos.y += height;
			pos.y += height;
		}
		++column;
	}

	if(weapons_with_stats)
		average_accuracy = floor((average_accuracy * 100 / weapons_with_stats) + 0.5);

	pos.y += height;
	pos.y += 1.25 * hud_fontsize.y;
	pos.x = initial_posx;
	return pos;
}

vector HUD_DrawKeyValue(vector pos, string key, string value) {
	float px = pos.x;
	pos.x += hud_fontsize.x * 0.25;
	drawstring(pos, key, hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	pos.x = xmax - stringwidth(value, false, hud_fontsize) - hud_fontsize.x * 0.25;
	drawstring(pos, value, hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	pos.x = px;
	pos.y+= hud_fontsize.y;

	return pos;
}

vector HUD_DrawMapStats(vector pos, vector rgb, vector bg_size) {
	float stat_secrets_found, stat_secrets_total;
	float stat_monsters_killed, stat_monsters_total;
	float rows = 0;
	string val;

	// get monster stats
	stat_monsters_killed = getstatf(STAT_MONSTERS_KILLED);
	stat_monsters_total = getstatf(STAT_MONSTERS_TOTAL);

	// get secrets stats
	stat_secrets_found = getstatf(STAT_SECRETS_FOUND);
	stat_secrets_total = getstatf(STAT_SECRETS_TOTAL);

	// get number of rows
	if(stat_secrets_total)
		rows += 1;
	if(stat_monsters_total)
		rows += 1;

	// if no rows, return
	if (!rows)
		return pos;

	//  draw table header
	drawstring(pos, _("Map stats:"), hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y + autocvar_scoreboard_border_thickness;

	// draw table
	vector tmp = '0 0 0';
	tmp.x = sbwidth;
	tmp.y = hud_fontsize.y * rows;

	if (teamplay)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb * autocvar_scoreboard_color_bg_team, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	else
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	drawborderlines(autocvar_scoreboard_border_thickness, pos, tmp, '0 0 0', scoreboard_alpha_bg * 0.75, DRAWFLAG_NORMAL);

	// draw monsters
	if(stat_monsters_total)
	{
		val = sprintf("%d/%d", stat_monsters_killed, stat_monsters_total);
		pos = HUD_DrawKeyValue(pos, _("Monsters killed:"), val);
	}

	// draw secrets
	if(stat_secrets_total)
	{
		val = sprintf("%d/%d", stat_secrets_found, stat_secrets_total);
		pos = HUD_DrawKeyValue(pos, _("Secrets found:"), val);
	}

	// update position
	pos.y += 1.25 * hud_fontsize.y;
	return pos;
}


vector HUD_DrawScoreboardRankings(vector pos, entity pl,  vector rgb, vector bg_size)
{
	int i;
	RANKINGS_RECEIVED_CNT = 0;
	for (i=RANKINGS_CNT-1; i>=0; --i)
		if (grecordtime[i])
			++RANKINGS_RECEIVED_CNT;

	if (RANKINGS_RECEIVED_CNT == 0)
		return pos;

	float is_spec;
	is_spec = (GetPlayerColor(pl.sv_entnum) == NUM_SPECTATOR);
	vector hl_rgb;
	hl_rgb.x = autocvar_scoreboard_color_bg_r + 0.5;
	hl_rgb.y = autocvar_scoreboard_color_bg_g + 0.5;
	hl_rgb.z = autocvar_scoreboard_color_bg_b + 0.5;

	pos.y += hud_fontsize.y;
	drawstring(pos, _("Rankings"), hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	pos.y += hud_fontsize.y + autocvar_scoreboard_border_thickness;
	vector tmp = '0 0 0';
	tmp.x = sbwidth;
	tmp.y = 1.25 * hud_fontsize.y * RANKINGS_RECEIVED_CNT;

	if (teamplay)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb * autocvar_scoreboard_color_bg_team, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	else
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, scoreboard_alpha_bg, DRAWFLAG_NORMAL);
	drawborderlines(autocvar_scoreboard_border_thickness, pos, tmp, '0 0 0', scoreboard_alpha_bg * 0.75, DRAWFLAG_NORMAL);

	// row highlighting
	for(i = 0; i<RANKINGS_RECEIVED_CNT; ++i)
	{
		string n, p;
		float t;
		t = grecordtime[i];
		if (t == 0)
			continue;
		n = grecordholder[i];
		p = count_ordinal(i+1);
		if(grecordholder[i] == GetPlayerName(player_localnum))
			drawfill(pos, '1 0 0' * sbwidth + '0 1.25 0' * hud_fontsize.y, hl_rgb, scoreboard_highlight_alpha_self, DRAWFLAG_NORMAL);
		else if(!(i % 2) && scoreboard_highlight)
			drawfill(pos, '1 0 0' * sbwidth + '0 1.25 0' * hud_fontsize.y, hl_rgb, scoreboard_highlight_alpha, DRAWFLAG_NORMAL);
		drawstring(pos, p, '1 1 0' * hud_fontsize.y, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + '3 0 0' * hud_fontsize.y, TIME_ENCODED_TOSTRING(t), '1 1 0' * hud_fontsize.y, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '8 0 0' * hud_fontsize.y, n, '1 1 0' * hud_fontsize.y, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
	}
	pos.y += autocvar_scoreboard_border_thickness;

	return pos;
}

float hud_woulddrawscoreboard_prev;
float hud_woulddrawscoreboard_change; // "time" at which HUD_WouldDrawScoreboard() changed
void HUD_DrawScoreboard()
{
	float hud_woulddrawscoreboard;
	hud_woulddrawscoreboard = scoreboard_active;
	if(hud_woulddrawscoreboard != hud_woulddrawscoreboard_prev) {
		hud_woulddrawscoreboard_change = time;
		hud_woulddrawscoreboard_prev = hud_woulddrawscoreboard;
	}

	if(hud_woulddrawscoreboard) {
		float scoreboard_fadeinspeed = autocvar_scoreboard_fadeinspeed;
		if (scoreboard_fadeinspeed)
			scoreboard_fade_alpha = bound (0, (time - hud_woulddrawscoreboard_change) * scoreboard_fadeinspeed, 1);
		else
			scoreboard_fade_alpha = 1;
	}
	else {
		float scoreboard_fadeoutspeed = autocvar_scoreboard_fadeoutspeed;
		if (scoreboard_fadeoutspeed)
			scoreboard_fade_alpha = bound (0, (1/scoreboard_fadeoutspeed - (time - hud_woulddrawscoreboard_change)) * scoreboard_fadeoutspeed, 1);
		else
			scoreboard_fade_alpha = 0;
	}

	if (!scoreboard_fade_alpha)
		return;

	HUD_UpdatePlayerTeams();

	scoreboard_alpha_bg = autocvar_scoreboard_alpha_bg * scoreboard_fade_alpha * (1 - autocvar__menu_alpha);
	scoreboard_alpha_fg = autocvar_scoreboard_alpha_fg * scoreboard_fade_alpha * (1 - autocvar__menu_alpha);
	scoreboard_highlight = autocvar_scoreboard_highlight;
	scoreboard_highlight_alpha = autocvar_scoreboard_highlight_alpha * scoreboard_alpha_fg;
	scoreboard_highlight_alpha_self = autocvar_scoreboard_highlight_alpha_self * scoreboard_alpha_fg;
	scoreboard_alpha_name = autocvar_scoreboard_alpha_name * scoreboard_alpha_fg;
	scoreboard_alpha_name_self = autocvar_scoreboard_alpha_name_self * scoreboard_alpha_fg;

	vector rgb, pos, tmp;
	entity pl, tm;
	string str;

	xmin = (autocvar_scoreboard_offset_left * vid_conwidth);
	ymin = max((autocvar_con_notify * autocvar_con_notifysize), (autocvar_scoreboard_offset_vertical * vid_conwidth));

	xmax = ((1 - autocvar_scoreboard_offset_right) * vid_conwidth);
	ymax = (vid_conheight - ymin);

	sbwidth = xmax - xmin;

	// Initializes position
	pos.x = xmin;
	pos.y = ymin;
	pos.z = 0;

	// Heading
	vector sb_heading_fontsize;
	sb_heading_fontsize = hud_fontsize * 2;
	draw_beginBoldFont();
	drawstring(pos, _("Scoreboard"), sb_heading_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	draw_endBoldFont();

	pos.y += sb_heading_fontsize.y + hud_fontsize.y * 0.25;

	// Draw the scoreboard
	vector bg_size = draw_getimagesize("gfx/scoreboard/scoreboard_bg") * autocvar_scoreboard_bg_scale;

	if(teamplay)
	{
		vector team_score_baseoffset;
		team_score_baseoffset = eY * (2 * autocvar_scoreboard_border_thickness + hud_fontsize.y) - eX * (autocvar_scoreboard_border_thickness + hud_fontsize.x * 0.25);
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == NUM_SPECTATOR)
				continue;

			draw_beginBoldFont();
			rgb = Team_ColorRGB(tm.team);
			str = ftos(tm.(teamscores[ts_primary]));
			drawstring(pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize * 1.5), str, hud_fontsize * 1.5, rgb, scoreboard_alpha_fg, DRAWFLAG_NORMAL);

			if(ts_primary != ts_secondary)
			{
				str = ftos(tm.(teamscores[ts_secondary]));
				drawstring(pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize) + eY * hud_fontsize.y * 1.5, str, hud_fontsize, rgb, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			}
			draw_endBoldFont();

			pos = HUD_Scoreboard_MakeTable(pos, tm, rgb, bg_size);
		}
		rgb.x = autocvar_scoreboard_color_bg_r;
		rgb.y = autocvar_scoreboard_color_bg_g;
		rgb.z = autocvar_scoreboard_color_bg_b;
	}
	else
	{
		rgb.x = autocvar_scoreboard_color_bg_r;
		rgb.y = autocvar_scoreboard_color_bg_g;
		rgb.z = autocvar_scoreboard_color_bg_b;

		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == NUM_SPECTATOR)
				continue;

			pos = HUD_Scoreboard_MakeTable(pos, tm, rgb, bg_size);
		}
	}

	if(gametype == MAPINFO_TYPE_CTS || gametype == MAPINFO_TYPE_RACE) {
		if(race_speedaward) {
			drawcolorcodedstring(pos, sprintf(_("Speed award: %d ^7(%s^7)"), race_speedaward, race_speedaward_holder), hud_fontsize, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		if(race_speedaward_alltimebest) {
			drawcolorcodedstring(pos, sprintf(_("All-time fastest: %d ^7(%s^7)"), race_speedaward_alltimebest, race_speedaward_alltimebest_holder), hud_fontsize, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		pos = HUD_DrawScoreboardRankings(pos, playerslots[player_localnum], rgb, bg_size);
	}
	else if(autocvar_scoreboard_accuracy && spectatee_status == 0 && !warmup_stage && gametype != MAPINFO_TYPE_NEXBALL) {
		if(teamplay)
			pos = HUD_DrawScoreboardAccuracyStats(pos, Team_ColorRGB(myteam), bg_size);
		else
			pos = HUD_DrawScoreboardAccuracyStats(pos, rgb, bg_size);
	}


	if(teamplay)
		pos = HUD_DrawMapStats(pos, Team_ColorRGB(myteam), bg_size);
	else
		pos = HUD_DrawMapStats(pos, rgb, bg_size);

	// List spectators
	float specs;
	specs = 0;
	tmp = pos;
	vector item_size;
	item_size.x = sbwidth;
	item_size.y = hud_fontsize.y * 1.25;
	item_size.z = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != NUM_SPECTATOR)
			continue;
		pos.y += 1.25 * hud_fontsize.y;
		HUD_PrintScoreboardItem(pos, item_size, pl, (pl.sv_entnum == player_localnum), specs);
		++specs;
	}

	if(specs)
	{
		draw_beginBoldFont();
		drawstring(tmp, _("Spectators"), hud_fontsize, '1 1 1', scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		draw_endBoldFont();
		pos.y += 1.25 * hud_fontsize.y;
	}

	// Print info string
	float tl, fl, ll;
	str = sprintf(_("playing ^3%s^7 on ^2%s^7"), MapInfo_Type_ToText(gametype), shortmapname);
	tl = getstatf(STAT_TIMELIMIT);
	fl = getstatf(STAT_FRAGLIMIT);
	ll = getstatf(STAT_LEADLIMIT);
	if(gametype == MAPINFO_TYPE_LMS)
	{
		if(tl > 0)
			str = strcat(str, sprintf(_(" for up to ^1%1.0f minutes^7"), tl));
	}
	else
	{
		if(tl > 0)
			str = strcat(str, sprintf(_(" for up to ^1%1.0f minutes^7"), tl));
		if(fl > 0)
		{
			if(tl > 0)
				str = strcat(str, _(" or"));
			if(teamplay)
			{
				str = strcat(str, sprintf(_(" until ^3%s %s^7"), ScoreString(teamscores_flags[ts_primary], fl),
					(teamscores_label[ts_primary] == "score")   ? CTX(_("SCO^points")) :
					(teamscores_label[ts_primary] == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(teamscores_label[ts_primary])));
			}
			else
			{
				str = strcat(str, sprintf(_(" until ^3%s %s^7"), ScoreString(scores_flags[ps_primary], fl),
					(scores_label[ps_primary] == "score")   ? CTX(_("SCO^points")) :
					(scores_label[ps_primary] == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(scores_label[ps_primary])));
			}
		}
		if(ll > 0)
		{
			if(tl > 0 || fl > 0)
				str = strcat(str, _(" or"));
			if(teamplay)
			{
				str = strcat(str, sprintf(_(" until a lead of ^3%s %s^7"), ScoreString(teamscores_flags[ts_primary], ll),
					(teamscores_label[ts_primary] == "score")   ? CTX(_("SCO^points")) :
					(teamscores_label[ts_primary] == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(teamscores_label[ts_primary])));
			}
			else
			{
				str = strcat(str, sprintf(_(" until a lead of ^3%s %s^7"), ScoreString(scores_flags[ps_primary], ll),
					(scores_label[ps_primary] == "score")   ? CTX(_("SCO^points")) :
					(scores_label[ps_primary] == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(scores_label[ps_primary])));
			}
		}
	}

	pos.y += 1.2 * hud_fontsize.y;
	drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - stringwidth(str, true, hud_fontsize)), str, hud_fontsize, scoreboard_alpha_fg, DRAWFLAG_NORMAL);

	// print information about respawn status
	float respawn_time = getstatf(STAT_RESPAWN_TIME);
	if(!intermission)
	if(respawn_time)
	{
		if(respawn_time < 0)
		{
			// a negative number means we are awaiting respawn, time value is still the same
			respawn_time *= -1; // remove mark now that we checked it
			respawn_time = max(time, respawn_time); // don't show a negative value while the server is respawning the player (lag)

			str = sprintf(_("^1Respawning in ^3%s^1..."),
				(autocvar_scoreboard_respawntime_decimals ?
					count_seconds_decs(respawn_time - time, autocvar_scoreboard_respawntime_decimals)
					:
					count_seconds(respawn_time - time)
				)
			);
		}
		else if(time < respawn_time)
		{
			str = sprintf(_("You are dead, wait ^3%s^7 before respawning"),
				(autocvar_scoreboard_respawntime_decimals ?
					count_seconds_decs(respawn_time - time, autocvar_scoreboard_respawntime_decimals)
					:
					count_seconds(respawn_time - time)
				)
			);
		}
		else if(time >= respawn_time)
			str = sprintf(_("You are dead, press ^2%s^7 to respawn"), getcommandkey("jump", "+jump"));

		pos.y += 1.2 * hud_fontsize.y;
		drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - stringwidth(str, true, hud_fontsize)), str, hud_fontsize, scoreboard_alpha_fg, DRAWFLAG_NORMAL);
	}

	scoreboard_bottom = pos.y + 2 * hud_fontsize.y;
}
