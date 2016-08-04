#include "scoreboard.qh"

#include "quickmenu.qh"
#include <common/ent_cs.qh>
#include <common/constants.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/stats.qh>
#include <common/teams.qh>

float sbt_bg_alpha;
float sbt_fg_alpha;
float sbt_fg_alpha_self;
bool sbt_highlight;
float sbt_highlight_alpha;
float sbt_highlight_alpha_self;

// TODO init autocvars
float autocvar_hud_panel_scoreboard_table_bg_alpha;
float autocvar_hud_panel_scoreboard_table_fg_alpha;
float autocvar_hud_panel_scoreboard_table_fg_alpha_self;
bool autocvar_hud_panel_scoreboard_table_highlight;
float autocvar_hud_panel_scoreboard_table_highlight_alpha;
float autocvar_hud_panel_scoreboard_table_highlight_alpha_self;

void drawstringright(vector, string, vector, vector, float, float);
void drawstringcenter(vector, string, vector, vector, float, float);

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
		case "dmg": return CTX(_("SCO^dmg"));
		case "dmgtaken": return CTX(_("SCO^dmgtaken"));
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

	Cmd_Scoreboard_SetFields(0);
}

float SetTeam(entity pl, float Team);
//float lastpnum;
void Scoreboard_UpdatePlayerTeams()
{
	float Team;
	entity pl, tmp;
	float num;

	num = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		num += 1;
		Team = entcs_GetScoreTeam(pl.sv_entnum);
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

int HUD_CompareScore(int vl, int vr, int f)
{
    TC(int, vl); TC(int, vr); TC(int, f);
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
	vl = entcs_GetTeam(left.sv_entnum);
	vr = entcs_GetTeam(right.sv_entnum);

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
	entity ent;
	for(ent = player.sort_next; ent && HUD_ComparePlayerScores(player, ent); ent = player.sort_next)
	{
		SORT_SWAP(player, ent);
	}
	for(ent = player.sort_prev; ent != players && HUD_ComparePlayerScores(ent, player); ent = player.sort_prev)
	{
		SORT_SWAP(ent, player);
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
	entity ent;
	for(ent = Team.sort_next; ent && HUD_CompareTeamScores(Team, ent); ent = Team.sort_next)
	{
		SORT_SWAP(Team, ent);
	}
	for(ent = Team.sort_prev; ent != teams && HUD_CompareTeamScores(ent, Team); ent = Team.sort_prev)
	{
		SORT_SWAP(ent, Team);
	}
}

void Cmd_Scoreboard_Help()
{
	LOG_INFO(_("You can modify the scoreboard using the ^2scoreboard_columns_set command.\n"));
	LOG_INFO(_("^3|---------------------------------------------------------------|\n"));
	LOG_INFO(_("Usage:\n"));
	LOG_INFO(_("^2scoreboard_columns_set default\n"));
	LOG_INFO(_("^2scoreboard_columns_set ^7field1 field2 ...\n"));
	LOG_INFO(_("The following field names are recognized (case insensitive):\n"));
	LOG_INFO(_("You can use a ^3|^7 to start the right-aligned fields.\n\n"));

	LOG_INFO(_("^3name^7 or ^3nick^7             Name of a player\n"));
	LOG_INFO(_("^3ping^7                     Ping time\n"));
	LOG_INFO(_("^3pl^7                       Packet loss\n"));
	LOG_INFO(_("^3kills^7                    Number of kills\n"));
	LOG_INFO(_("^3deaths^7                   Number of deaths\n"));
	LOG_INFO(_("^3suicides^7                 Number of suicides\n"));
	LOG_INFO(_("^3frags^7                    kills - suicides\n"));
	LOG_INFO(_("^3kd^7                       The kill-death ratio\n"));
	LOG_INFO(_("^3dmg^7                      The total damage done\n"));
	LOG_INFO(_("^3dmgtaken^7                 The total damage taken\n"));
	LOG_INFO(_("^3sum^7                      frags - deaths\n"));
	LOG_INFO(_("^3caps^7                     How often a flag (CTF) or a key (KeyHunt) was captured\n"));
	LOG_INFO(_("^3pickups^7                  How often a flag (CTF) or a key (KeyHunt) or a ball (Keepaway) was picked up\n"));
	LOG_INFO(_("^3captime^7                  Time of fastest cap (CTF)\n"));
	LOG_INFO(_("^3fckills^7                  Number of flag carrier kills\n"));
	LOG_INFO(_("^3returns^7                  Number of flag returns\n"));
	LOG_INFO(_("^3drops^7                    Number of flag drops\n"));
	LOG_INFO(_("^3lives^7                    Number of lives (LMS)\n"));
	LOG_INFO(_("^3rank^7                     Player rank\n"));
	LOG_INFO(_("^3pushes^7                   Number of players pushed into void\n"));
	LOG_INFO(_("^3destroyed^7                Number of keys destroyed by pushing them into void\n"));
	LOG_INFO(_("^3kckills^7                  Number of keys carrier kills\n"));
	LOG_INFO(_("^3losses^7                   Number of times a key was lost\n"));
	LOG_INFO(_("^3laps^7                     Number of laps finished (race/cts)\n"));
	LOG_INFO(_("^3time^7                     Total time raced (race/cts)\n"));
	LOG_INFO(_("^3fastest^7                  Time of fastest lap (race/cts)\n"));
	LOG_INFO(_("^3ticks^7                    Number of ticks (DOM)\n"));
	LOG_INFO(_("^3takes^7                    Number of domination points taken (DOM)\n"));
	LOG_INFO(_("^3bckills^7                  Number of ball carrier kills\n"));
	LOG_INFO(_("^3bctime^7                   Total amount of time holding the ball in Keepaway\n"));
	LOG_INFO(_("^3score^7                    Total score\n\n"));

	LOG_INFO(_("Before a field you can put a + or - sign, then a comma separated list\n"
	        "of game types, then a slash, to make the field show up only in these\n"
	        "or in all but these game types. You can also specify 'all' as a\n"
	        "field to show all fields available for the current game mode.\n\n"));

	LOG_INFO(_("The special game type names 'teams' and 'noteams' can be used to\n"
	        "include/exclude ALL teams/noteams game modes.\n\n"));

	LOG_INFO(_("Example: scoreboard_columns_set name ping pl | +ctf/field3 -dm/field4\n"));
	LOG_INFO(_("will display name, ping and pl aligned to the left, and the fields\n"
	        "right of the vertical bar aligned to the right.\n"));
	LOG_INFO(_("'field3' will only be shown in CTF, and 'field4' will be shown in all\n"
	        "other gamemodes except DM.\n"));
}

// NOTE: adding a gametype with ? to not warn for an optional field
// make sure it's excluded in a previous exclusive rule, if any
// otherwise the previous exclusive rule warns anyway
// e.g. -teams,rc,cts,lms/kills ?+rc/kills
#define SCOREBOARD_DEFAULT_COLUMNS \
"ping pl name |" \
" -teams,rc,cts,inv,lms/kills +ft,tdm/kills ?+rc,inv/kills" \
" -teams,lms/deaths +ft,tdm/deaths" \
" -teams,lms,rc,cts,inv,ka/suicides +ft,tdm/suicides ?+rc,inv/suicides" \
" -cts,dm,tdm,ka,ft/frags" /* tdm already has this in "score" */ \
" -rc,cts,nb/dmg -rc,cts,nb/dmgtaken" \
" +ctf/caps +ctf/pickups +ctf/fckills +ctf/returns +ons/caps +ons/takes" \
" +lms/lives +lms/rank" \
" +kh/caps +kh/pushes +kh/destroyed" \
" ?+rc/laps ?+rc/time +rc,cts/fastest" \
" +as/objectives +nb/faults +nb/goals" \
" +ka/pickups +ka/bckills +ka/bctime +ft/revivals" \
" -lms,rc,cts,inv,nb/score"

void Cmd_Scoreboard_SetFields(int argc)
{
    TC(int, argc);
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
		argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");

	if(argc == 3)
	{
		if(argv(2) == "default")
			argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");
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


	sbt_num_fields = 0;

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

		strunzone(sbt_field_title[sbt_num_fields]);
		sbt_field_title[sbt_num_fields] = strzone(TranslateScoresLabel(str));
		sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
		str = strtolower(str);

		switch(str)
		{
			case "ping": sbt_field[sbt_num_fields] = SP_PING; break;
			case "pl": sbt_field[sbt_num_fields] = SP_PL; break;
			case "kd": case "kdr": case "kdratio": case "k/d": sbt_field[sbt_num_fields] = SP_KDRATIO; break;
			case "sum": case "diff": case "k-d": sbt_field[sbt_num_fields] = SP_SUM; break;
			case "name": case "nick": sbt_field[sbt_num_fields] = SP_NAME; have_name = true; break;
			case "|": sbt_field[sbt_num_fields] = SP_SEPARATOR; have_separator = true; break;
			case "dmg": sbt_field[sbt_num_fields] = SP_DMG; break;
			case "dmgtaken": sbt_field[sbt_num_fields] = SP_DMGTAKEN; break;
			default:
			{
				for(j = 0; j < MAX_SCORE; ++j)
					if(str == strtolower(scores_label[j]))
						goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"

LABEL(notfound)
				if(str == "frags")
					j = SP_FRAGS;
				else
				{
					if(!nocomplain)
						LOG_INFOF("^1Error:^7 Unknown score field: '%s'\n", str);
					continue;
				}
LABEL(found)
				sbt_field[sbt_num_fields] = j;
				if(j == ps_primary)
					have_primary = 1;
				if(j == ps_secondary)
					have_secondary = 1;

			}
		}
		++sbt_num_fields;
		if(sbt_num_fields >= MAX_SBT_FIELDS)
			break;
	}

	if(scores_flags[ps_primary] & SFL_ALLOW_HIDE)
		have_primary = 1;
	if(scores_flags[ps_secondary] & SFL_ALLOW_HIDE)
		have_secondary = 1;
	if(ps_primary == ps_secondary)
		have_secondary = 1;
	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

	if(sbt_num_fields + missing < MAX_SBT_FIELDS)
	{
		if(!have_name)
		{
			strunzone(sbt_field_title[sbt_num_fields]);
			for(i = sbt_num_fields; i > 0; --i)
			{
				sbt_field_title[i] = sbt_field_title[i-1];
				sbt_field_size[i] = sbt_field_size[i-1];
				sbt_field[i] = sbt_field[i-1];
			}
			sbt_field_title[0] = strzone(TranslateScoresLabel("name"));
			sbt_field[0] = SP_NAME;
			++sbt_num_fields;
			LOG_INFO("fixed missing field 'name'\n");

			if(!have_separator)
			{
				strunzone(sbt_field_title[sbt_num_fields]);
				for(i = sbt_num_fields; i > 1; --i)
				{
					sbt_field_title[i] = sbt_field_title[i-1];
					sbt_field_size[i] = sbt_field_size[i-1];
					sbt_field[i] = sbt_field[i-1];
				}
				sbt_field_title[1] = strzone("|");
				sbt_field[1] = SP_SEPARATOR;
				sbt_field_size[1] = stringwidth("|", false, hud_fontsize);
				++sbt_num_fields;
				LOG_INFO("fixed missing field '|'\n");
			}
		}
		else if(!have_separator)
		{
			strunzone(sbt_field_title[sbt_num_fields]);
			sbt_field_title[sbt_num_fields] = strzone("|");
			sbt_field_size[sbt_num_fields] = stringwidth("|", false, hud_fontsize);
			sbt_field[sbt_num_fields] = SP_SEPARATOR;
			++sbt_num_fields;
			LOG_INFO("fixed missing field '|'\n");
		}
		if(!have_secondary)
		{
			strunzone(sbt_field_title[sbt_num_fields]);
			sbt_field_title[sbt_num_fields] = strzone(TranslateScoresLabel(scores_label[ps_secondary]));
			sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
			sbt_field[sbt_num_fields] = ps_secondary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'\n", scores_label[ps_secondary]);
		}
		if(!have_primary)
		{
			strunzone(sbt_field_title[sbt_num_fields]);
			sbt_field_title[sbt_num_fields] = strzone(TranslateScoresLabel(scores_label[ps_primary]));
			sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
			sbt_field[sbt_num_fields] = ps_primary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'\n", scores_label[ps_primary]);
		}
	}

	sbt_field[sbt_num_fields] = SP_END;
}

// MOVEUP::
vector sbt_field_rgb;
string sbt_field_icon0;
string sbt_field_icon1;
string sbt_field_icon2;
vector sbt_field_icon0_rgb;
vector sbt_field_icon1_rgb;
vector sbt_field_icon2_rgb;
float sbt_field_icon0_alpha;
float sbt_field_icon1_alpha;
float sbt_field_icon2_alpha;
string HUD_GetField(entity pl, int field)
{
    TC(int, field);
	float tmp, num, denom;
	int f;
	string str;
	sbt_field_rgb = '1 1 1';
	sbt_field_icon0 = "";
	sbt_field_icon1 = "";
	sbt_field_icon2 = "";
	sbt_field_icon0_rgb = '1 1 1';
	sbt_field_icon1_rgb = '1 1 1';
	sbt_field_icon2_rgb = '1 1 1';
	sbt_field_icon0_alpha = 1;
	sbt_field_icon1_alpha = 1;
	sbt_field_icon2_alpha = 1;
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
			sbt_field_rgb = '1 1 1' - '0 1 1' * tmp;
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
			sbt_field_rgb = '1 0.5 0.5' - '0 0.5 0.5' * tmp;
			return str;

		case SP_NAME:
			if(ready_waiting && pl.ready)
			{
				sbt_field_icon0 = "gfx/scoreboard/player_ready";
			}
			else if(!teamplay)
			{
				f = stof(getplayerkeyvalue(pl.sv_entnum, "colors"));
				{
					sbt_field_icon0 = "gfx/scoreboard/playercolor_base";
					sbt_field_icon1 = "gfx/scoreboard/playercolor_shirt";
					sbt_field_icon1_rgb = colormapPaletteColor(floor(f / 16), 0);
					sbt_field_icon2 = "gfx/scoreboard/playercolor_pants";
					sbt_field_icon2_rgb = colormapPaletteColor(f % 16, 1);
				}
			}
			return entcs_GetName(pl.sv_entnum);

		case SP_FRAGS:
			f = pl.(scores[SP_KILLS]);
			f -= pl.(scores[SP_SUICIDES]);
			return ftos(f);

		case SP_KDRATIO:
			num = pl.(scores[SP_KILLS]);
			denom = pl.(scores[SP_DEATHS]);

			if(denom == 0) {
				sbt_field_rgb = '0 1 0';
				str = sprintf("%d", num);
			} else if(num <= 0) {
				sbt_field_rgb = '1 0 0';
				str = sprintf("%.1f", num/denom);
			} else
				str = sprintf("%.1f", num/denom);
			return str;

		case SP_SUM:
			f = pl.(scores[SP_KILLS]);
			f -= pl.(scores[SP_DEATHS]);

			if(f > 0) {
				sbt_field_rgb = '0 1 0';
			} else if(f == 0) {
				sbt_field_rgb = '1 1 1';
			} else {
				sbt_field_rgb = '1 0 0';
			}
			return ftos(f);

		case SP_DMG:
			num = pl.(scores[SP_DMG]);
			denom = 1000;

			str = sprintf("%.1f k", num/denom);
			return str;

		case SP_DMGTAKEN:
			num = pl.(scores[SP_DMGTAKEN]);
			denom = 1000;

			str = sprintf("%.1f k", num/denom);
			return str;

		default:
			tmp = pl.(scores[field]);
			f = scores_flags[field];
			if(field == ps_primary)
				sbt_field_rgb = '1 1 0';
			else if(field == ps_secondary)
				sbt_field_rgb = '0 1 1';
			else
				sbt_field_rgb = '1 1 1';
			return ScoreString(f, tmp);
	}
	//return "error";
}

float sbt_fixcolumnwidth_len;
float sbt_fixcolumnwidth_iconlen;
float sbt_fixcolumnwidth_marginlen;

string HUD_FixScoreboardColumnWidth(int i, string str)
{
    TC(int, i);
	float field, f;
	vector sz;
	field = sbt_field[i];

	sbt_fixcolumnwidth_iconlen = 0;

	if(sbt_field_icon0 != "")
	{
		sz = draw_getimagesize(sbt_field_icon0);
		f = sz.x / sz.y;
		if(sbt_fixcolumnwidth_iconlen < f)
			sbt_fixcolumnwidth_iconlen = f;
	}

	if(sbt_field_icon1 != "")
	{
		sz = draw_getimagesize(sbt_field_icon1);
		f = sz.x / sz.y;
		if(sbt_fixcolumnwidth_iconlen < f)
			sbt_fixcolumnwidth_iconlen = f;
	}

	if(sbt_field_icon2 != "")
	{
		sz = draw_getimagesize(sbt_field_icon2);
		f = sz.x / sz.y;
		if(sbt_fixcolumnwidth_iconlen < f)
			sbt_fixcolumnwidth_iconlen = f;
	}

	sbt_fixcolumnwidth_iconlen *= hud_fontsize.y / hud_fontsize.x; // fix icon aspect

	if(sbt_fixcolumnwidth_iconlen != 0)
		sbt_fixcolumnwidth_marginlen = stringwidth(" ", false, hud_fontsize);
	else
		sbt_fixcolumnwidth_marginlen = 0;

	if(field == SP_NAME) // name gets all remaining space
	{
		int j;
		float namesize;
		namesize = panel_size.x;
		for(j = 0; j < sbt_num_fields; ++j)
			if(j != i)
				if (sbt_field[i] != SP_SEPARATOR)
					namesize -= sbt_field_size[j] + hud_fontsize.x;
		namesize += hud_fontsize.x;
		sbt_field_size[i] = namesize;

		if (sbt_fixcolumnwidth_iconlen != 0)
			namesize -= sbt_fixcolumnwidth_marginlen + sbt_fixcolumnwidth_iconlen;
		str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		sbt_fixcolumnwidth_len = stringwidth(str, true, hud_fontsize);
	}
	else
		sbt_fixcolumnwidth_len = stringwidth(str, false, hud_fontsize);

	f = sbt_fixcolumnwidth_len + sbt_fixcolumnwidth_marginlen + sbt_fixcolumnwidth_iconlen;
	if(sbt_field_size[i] < f)
		sbt_field_size[i] = f;

	return str;
}

vector HUD_PrintScoreboardHeader(vector pos, vector rgb)
{
	int i;
	vector column_dim = eY * panel_size.y;
	vector text_offset = eY * (1.25 - 1) / 2 * hud_fontsize.y;
	for(i = 0; i < sbt_num_fields; ++i)
	{
		if(sbt_field[i] == SP_SEPARATOR)
			break;
		column_dim.x = sbt_field_size[i] + hud_fontsize.x;
		if (sbt_highlight)
			if (i % 2)
				drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
		pos.x += column_dim.x;
	}
	if(sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = panel_pos.x + panel_size.x;
		for(i = sbt_num_fields - 1; i > 0; --i)
		{
			if(sbt_field[i] == SP_SEPARATOR)
				break;

			pos.x -= sbt_field_size[i];

			if (sbt_highlight)
				if (!(i % 2))
				{
					if (i == sbt_num_fields-1)
						column_dim.x = sbt_field_size[i] + hud_fontsize.x * 0.5;
					else
						column_dim.x = sbt_field_size[i] + hud_fontsize.x;
					drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);
				}

			text_offset.x = sbt_field_size[i] - stringwidth(sbt_field_title[i], false, hud_fontsize);
			drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
			pos.x -= hud_fontsize.x;
		}
	}

	pos.x = panel_pos.x;
	pos.y += 1.25 * hud_fontsize.y;
	return pos;
}

void HUD_PrintScoreboardItem(vector item_pos, vector rgb, entity pl, bool is_self, int pl_number)
{
    TC(bool, is_self); TC(int, pl_number);
	string str;
	int field;
	float is_spec;
	is_spec = (entcs_GetTeam(pl.sv_entnum) == NUM_SPECTATOR);
	if(is_spec && !is_self)
		rgb = '0 0 0';

	vector h_pos = item_pos;
	vector h_size = eX * panel_size.x + eY * hud_fontsize.y * 1.25;
	// alternated rows highlighting
	if(is_self)
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if((sbt_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	vector pos = item_pos;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically
	vector tmp = '0 0 0';
	int i;
	for(i = 0; i < sbt_num_fields; ++i)
	{
		field = sbt_field[i];
		if(field == SP_SEPARATOR)
			break;

		if(is_spec && field != SP_NAME && field != SP_PING) {
			pos.x += sbt_field_size[i] + hud_fontsize.x;
			continue;
		}
		str = HUD_GetField(pl, field);
		str = HUD_FixScoreboardColumnWidth(i, str);

		pos.x += sbt_field_size[i] + hud_fontsize.x;

		if(field == SP_NAME) {
			tmp.x = sbt_field_size[i] - hud_fontsize.x * sbt_fixcolumnwidth_iconlen - sbt_fixcolumnwidth_marginlen + hud_fontsize.x;
			if (is_self)
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, sbt_fg_alpha_self, DRAWFLAG_NORMAL);
			else
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);
		} else {
			tmp.x = sbt_fixcolumnwidth_len + hud_fontsize.x;
			if (is_self)
				drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, sbt_fg_alpha_self, DRAWFLAG_NORMAL);
			else
				drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
		}

		tmp.x = sbt_field_size[i] + hud_fontsize.x;
		if(sbt_field_icon0 != "")
			if (is_self)
				drawpic(pos - tmp, sbt_field_icon0, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon0_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, sbt_field_icon0, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon0_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
		if(sbt_field_icon1 != "")
			if (is_self)
				drawpic(pos - tmp, sbt_field_icon1, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon1_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, sbt_field_icon1, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon1_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
		if(sbt_field_icon2 != "")
			if (is_self)
				drawpic(pos - tmp, sbt_field_icon2, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon2_rgb, sbt_field_icon2_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
			else
				drawpic(pos - tmp, sbt_field_icon2, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon2_rgb, sbt_field_icon2_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = item_pos.x + panel_size.x;
		for(i = sbt_num_fields-1; i > 0; --i)
		{
			field = sbt_field[i];
			if(field == SP_SEPARATOR)
				break;

			if(is_spec && field != SP_NAME && field != SP_PING) {
				pos.x -= sbt_field_size[i] + hud_fontsize.x;
				continue;
			}

			str = HUD_GetField(pl, field);
			str = HUD_FixScoreboardColumnWidth(i, str);

			if(field == SP_NAME) {
				tmp.x = sbt_fixcolumnwidth_len; // left or right aligned? let's put it right...
				if(is_self)
					drawcolorcodedstring(pos - tmp, str, hud_fontsize, sbt_fg_alpha_self, DRAWFLAG_NORMAL);
				else
					drawcolorcodedstring(pos - tmp, str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);
			} else {
				tmp.x = sbt_fixcolumnwidth_len;
				if(is_self)
					drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, sbt_fg_alpha_self, DRAWFLAG_NORMAL);
				else
					drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
			}

			tmp.x = sbt_field_size[i];
			if(sbt_field_icon0 != "")
				if (is_self)
					drawpic(pos - tmp, sbt_field_icon0, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon0_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, sbt_field_icon0, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon0_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
			if(sbt_field_icon1 != "")
				if (is_self)
					drawpic(pos - tmp, sbt_field_icon1, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon1_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, sbt_field_icon1, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon1_rgb, sbt_field_icon1_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
			if(sbt_field_icon2 != "")
				if (is_self)
					drawpic(pos - tmp, sbt_field_icon2, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon2_rgb, sbt_field_icon2_alpha * sbt_fg_alpha_self, DRAWFLAG_NORMAL);
				else
					drawpic(pos - tmp, sbt_field_icon2, eY * hud_fontsize.y + eX * hud_fontsize.x * sbt_fixcolumnwidth_iconlen, sbt_field_icon2_rgb, sbt_field_icon2_alpha * sbt_fg_alpha, DRAWFLAG_NORMAL);
			pos.x -= sbt_field_size[i] + hud_fontsize.x;
		}
	}

	if(pl.eliminated)
		drawfill(h_pos, h_size, '0 0 0', 0.5 * panel_fg_alpha, DRAWFLAG_NORMAL);
}

vector HUD_Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size)
{
	entity pl;

	panel_pos = pos;
	panel_size.y = 1.25 * hud_fontsize.y * (1 + max(1, tm.team_size));
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg(scoreboard_fade_alpha);

	vector end_pos = panel_pos + eY * (panel_size.y + panel_bg_border * 2 + hud_fontsize.y);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = eX * panel_size.x + eY * 1.25 * hud_fontsize.y;

	// rounded header
	if (sbt_bg_alpha)
		drawpic(pos, "gfx/scoreboard/scoreboard_tableheader", tmp, rgb + '0.5 0.5 0.5', sbt_bg_alpha, DRAWFLAG_NORMAL);

	pos.y += 1.25 * hud_fontsize.y;

	// table background
	tmp.y = panel_size.y - 1.25 * hud_fontsize.y;
	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);


	// print header row and highlight columns
	pos = HUD_PrintScoreboardHeader(panel_pos, rgb);

	// fill the table and draw the rows
	int i = 0;
	if (teamplay)
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team != tm.team)
				continue;
			HUD_PrintScoreboardItem(pos, rgb, pl, (pl.sv_entnum == player_localnum), i);
			pos.y += 1.25 * hud_fontsize.y;
			++i;
		}
	else
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team == NUM_SPECTATOR)
				continue;
			HUD_PrintScoreboardItem(pos, rgb, pl, (pl.sv_entnum == player_localnum), i);
			pos.y += 1.25 * hud_fontsize.y;
			++i;
		}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

float HUD_WouldDrawScoreboard() {
	if (QuickMenu_IsOpened())
		return 0;
	else if (HUD_Radar_Clickable())
		return 0;
	else if (scoreboard_showscores)
		return 1;
	else if (intermission == 1)
		return 1;
	else if (intermission == 2)
		return 0;
	else if (spectatee_status != -1 && STAT(HEALTH) <= 0 && autocvar_cl_deathscoreboard && gametype != MAPINFO_TYPE_CTS && !active_minigame)
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
	int disownedcnt = 0;
	FOREACH(Weapons, it != WEP_Null, {
		int weapon_stats = weapon_accuracy[i - WEP_FIRST];

		WepSet set = it.m_wepset;
		if (weapon_stats < 0 && !(weapons_stat & set || weapons_inmap & set))
			++disownedcnt;
	});

	int weapon_cnt = (Weapons_COUNT - 1) - disownedcnt;
	if (weapon_cnt <= 0) return pos;

	int rows = 1;
	if (autocvar_scoreboard_accuracy_doublerows && weapon_cnt >= floor((Weapons_COUNT - 1) * 0.5))
		rows = 2;
	int columnns = ceil(weapon_cnt / rows);

	float height = 40;

	drawstring(pos + eX * panel_bg_padding, sprintf(_("Accuracy stats (average %d%%)"), average_accuracy), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = height * rows;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg(scoreboard_fade_alpha);

	vector end_pos = panel_pos + eY * (panel_size.y + panel_bg_border * 2 + hud_fontsize.y);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	float fontsize = height * 1/3;
	float weapon_height = height * 2/3;
	float weapon_width = tmp.x / columnns / rows;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	// column highlighting
	for (int i = 0; i < columnns; ++i)
		if ((i % 2) == 0)
			drawfill(pos + eX * weapon_width * rows * i, eY * height * rows + eX * weapon_width * rows, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);

	// row highlighting
	for (int i = 0; i < rows; ++i)
		drawfill(pos + eY * weapon_height + eY * height * i, eX * tmp.x + eY * fontsize, '1 1 1', sbt_highlight_alpha, DRAWFLAG_NORMAL);

	average_accuracy = 0;
	int weapons_with_stats = 0;
	if (rows == 2)
		pos.x += weapon_width / 2;

	if (autocvar_scoreboard_accuracy_nocolors)
		rgb = '1 1 1';
	else
		Accuracy_LoadColors();

	float oldposx = pos.x;
	vector tmpos = pos;

	int column = 0;
	FOREACH(Weapons, it != WEP_Null, {
		int weapon_stats = weapon_accuracy[i - WEP_FIRST];

		WepSet set = it.m_wepset;
		if (weapon_stats < 0 && !(weapons_stat & set || weapons_inmap & set))
			continue;

		float weapon_alpha;
		if (weapon_stats >= 0)
			weapon_alpha = sbt_fg_alpha;
		else
			weapon_alpha = 0.2 * sbt_fg_alpha;

		// weapon icon
		drawpic_aspect_skin(tmpos, it.model2, eX * weapon_width + eY * weapon_height, '1 1 1', weapon_alpha, DRAWFLAG_NORMAL);
		// the accuracy
		if (weapon_stats >= 0) {
			weapons_with_stats += 1;
			average_accuracy += weapon_stats; // store sum of all accuracies in average_accuracy

			string s;
			s = sprintf("%d%%", weapon_stats * 100);

			float padding;
			padding = (weapon_width - stringwidth(s, false, eX * fontsize)) / 2; // center the accuracy value

			if(!autocvar_scoreboard_accuracy_nocolors)
				rgb = Accuracy_GetColor(weapon_stats);

			drawstring(tmpos + eX * padding + eY * weapon_height, s, '1 1 0' * fontsize, rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
		}
		tmpos.x += weapon_width * rows;
		pos.x += weapon_width * rows;
		if (rows == 2 && column == columnns - 1) {
			tmpos.x = oldposx;
			tmpos.y += height;
			pos.y += height;
		}
		++column;
	});

	if (weapons_with_stats)
		average_accuracy = floor((average_accuracy * 100 / weapons_with_stats) + 0.5);

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

vector HUD_DrawKeyValue(vector pos, string key, string value) {
	float px = pos.x;
	pos.x += hud_fontsize.x * 0.25;
	drawstring(pos, key, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = panel_pos.x + panel_size.x - stringwidth(value, false, hud_fontsize) - hud_fontsize.x * 0.25;
	drawstring(pos, value, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = px;
	pos.y += hud_fontsize.y;

	return pos;
}

vector HUD_DrawMapStats(vector pos, vector rgb, vector bg_size) {
	float stat_secrets_found, stat_secrets_total;
	float stat_monsters_killed, stat_monsters_total;
	float rows = 0;
	string val;

	// get monster stats
	stat_monsters_killed = STAT(MONSTERS_KILLED);
	stat_monsters_total = STAT(MONSTERS_TOTAL);

	// get secrets stats
	stat_secrets_found = STAT(SECRETS_FOUND);
	stat_secrets_total = STAT(SECRETS_TOTAL);

	// get number of rows
	if(stat_secrets_total)
		rows += 1;
	if(stat_monsters_total)
		rows += 1;

	// if no rows, return
	if (!rows)
		return pos;

	//  draw table header
	drawstring(pos + eX * panel_bg_padding, _("Map stats:"), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = hud_fontsize.y * rows;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg(scoreboard_fade_alpha);

	vector end_pos = panel_pos + eY * (panel_size.y + panel_bg_border * 2 + hud_fontsize.y);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

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

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}


vector HUD_DrawScoreboardRankings(vector pos, entity pl, vector rgb, vector bg_size)
{
	int i;
	RANKINGS_RECEIVED_CNT = 0;
	for (i=RANKINGS_CNT-1; i>=0; --i)
		if (grecordtime[i])
			++RANKINGS_RECEIVED_CNT;

	if (RANKINGS_RECEIVED_CNT == 0)
		return pos;

	vector hl_rgb = rgb + '0.5 0.5 0.5';

	pos.y += hud_fontsize.y;
	drawstring(pos + eX * panel_bg_padding, _("Rankings"), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = 1.25 * hud_fontsize.y * RANKINGS_RECEIVED_CNT;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg(scoreboard_fade_alpha);

	vector end_pos = panel_pos + eY * (panel_size.y + panel_bg_border * 2 + hud_fontsize.y);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	// row highlighting
	for(i = 0; i < RANKINGS_RECEIVED_CNT; ++i)
	{
		string n, p;
		float t;
		t = grecordtime[i];
		if (t == 0)
			continue;
		n = grecordholder[i];
		p = count_ordinal(i+1);
		if(grecordholder[i] == entcs_GetName(player_localnum))
			drawfill(pos, eX * panel_size.x + '0 1.25 0' * hud_fontsize.y, hl_rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
		else if(!(i % 2) && sbt_highlight)
			drawfill(pos, eX * panel_size.x + '0 1.25 0' * hud_fontsize.y, hl_rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);
		drawstring(pos, p, '1 1 0' * hud_fontsize.y, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + '3 0 0' * hud_fontsize.y, TIME_ENCODED_TOSTRING(t), '1 1 0' * hud_fontsize.y, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '8 0 0' * hud_fontsize.y, n, '1 1 0' * hud_fontsize.y, sbt_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

float hud_woulddrawscoreboard_prev;
float hud_woulddrawscoreboard_change; // "time" at which HUD_WouldDrawScoreboard() changed
void HUD_DrawScoreboard()
{
	if(!autocvar__hud_configure)
	{
		float hud_woulddrawscoreboard;
		hud_woulddrawscoreboard = scoreboard_active;
		if(hud_woulddrawscoreboard != hud_woulddrawscoreboard_prev) {
			hud_woulddrawscoreboard_change = time;
			hud_woulddrawscoreboard_prev = hud_woulddrawscoreboard;
		}

		if(hud_woulddrawscoreboard) {
			if(menu_enabled == 1)
				scoreboard_fade_alpha = 1;
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
	}
	else
		scoreboard_fade_alpha = 0;

	if (autocvar_scoreboard_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	float hud_fade_alpha_save = hud_fade_alpha;
	if(menu_enabled == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = scoreboard_fade_alpha * (1 - autocvar__menu_alpha);
	HUD_Panel_UpdateCvars();

	sbt_bg_alpha = autocvar_hud_panel_scoreboard_table_bg_alpha * panel_fg_alpha;
	sbt_highlight = autocvar_hud_panel_scoreboard_table_highlight;
	sbt_highlight_alpha = autocvar_hud_panel_scoreboard_table_highlight_alpha * panel_fg_alpha;
	sbt_highlight_alpha_self = autocvar_hud_panel_scoreboard_table_highlight_alpha_self * panel_fg_alpha;
	sbt_fg_alpha = autocvar_hud_panel_scoreboard_table_fg_alpha * panel_fg_alpha;
	sbt_fg_alpha_self = autocvar_hud_panel_scoreboard_table_fg_alpha_self * panel_fg_alpha;

	hud_fade_alpha = hud_fade_alpha_save;

	// don't overlap with con_notify
	if(!autocvar__hud_configure)
		panel_pos.y = max((autocvar_con_notify * autocvar_con_notifysize), panel_pos.y);

	Scoreboard_UpdatePlayerTeams();

	vector pos, tmp;
	entity pl, tm;
	string str;

	// Initializes position
	pos = panel_pos;

	// Heading
	vector sb_heading_fontsize;
	sb_heading_fontsize = hud_fontsize * 2;
	draw_beginBoldFont();
	drawstring(pos + eX * panel_bg_padding, _("Scoreboard"), sb_heading_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	draw_endBoldFont();

	pos.y += sb_heading_fontsize.y;
	pos.y += panel_bg_border;

	// Draw the scoreboard
	vector bg_size = draw_getimagesize("gfx/scoreboard/scoreboard_bg") * ((autocvar_scoreboard_bg_scale > 0) ? autocvar_scoreboard_bg_scale : 0.25);

	if(teamplay)
	{
		vector team_score_baseoffset = eY * hud_fontsize.y - eX * (panel_bg_border + hud_fontsize.x * 0.5);
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == NUM_SPECTATOR)
				continue;
			if(!tm.team && teamplay)
				continue;

			draw_beginBoldFont();
			vector rgb = Team_ColorRGB(tm.team);
			str = ftos(tm.(teamscores[ts_primary]));
			drawstring(pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize * 1.5), str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

			if(ts_primary != ts_secondary)
			{
				str = ftos(tm.(teamscores[ts_secondary]));
				drawstring(pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize) + eY * hud_fontsize.y * 1.5, str, hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			draw_endBoldFont();

			panel_bg_color = rgb * panel_bg_color_team;
			pos = HUD_Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
		}
		panel_bg_color = Team_ColorRGB(myteam) * panel_bg_color_team;
	}
	else
	{
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == NUM_SPECTATOR)
				continue;
			if(!tm.team && teamplay)
				continue;

			pos = HUD_Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
		}
	}

	if(gametype == MAPINFO_TYPE_CTS || gametype == MAPINFO_TYPE_RACE) {
		if(race_speedaward) {
			drawcolorcodedstring(pos, sprintf(_("Speed award: %d%s ^7(%s^7)"), race_speedaward, race_speedaward_unit, race_speedaward_holder), hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		if(race_speedaward_alltimebest) {
			drawcolorcodedstring(pos, sprintf(_("All-time fastest: %d%s ^7(%s^7)"), race_speedaward_alltimebest, race_speedaward_alltimebest_unit, race_speedaward_alltimebest_holder), hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		pos = HUD_DrawScoreboardRankings(pos, playerslots[player_localnum], panel_bg_color, bg_size);
	}
	else if (autocvar_scoreboard_accuracy && !warmup_stage && gametype != MAPINFO_TYPE_NEXBALL) {
		pos = HUD_DrawScoreboardAccuracyStats(pos, panel_bg_color, bg_size);
	}

	pos = HUD_DrawMapStats(pos, panel_bg_color, bg_size);

	// List spectators
	float specs = 0;
	tmp = pos;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != NUM_SPECTATOR)
			continue;
		pos.y += 1.25 * hud_fontsize.y;
		HUD_PrintScoreboardItem(pos, panel_bg_color, pl, (pl.sv_entnum == player_localnum), specs);
		++specs;
	}

	if(specs)
	{
		draw_beginBoldFont();
		drawstring(tmp, _("Spectators"), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
		pos.y += 1.25 * hud_fontsize.y;
	}

	// Print info string
	float tl, fl, ll;
	str = sprintf(_("playing ^3%s^7 on ^2%s^7"), MapInfo_Type_ToText(gametype), shortmapname);
	tl = STAT(TIMELIMIT);
	fl = STAT(FRAGLIMIT);
	ll = STAT(LEADLIMIT);
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
	drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, hud_fontsize)), str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

	// print information about respawn status
	float respawn_time = STAT(RESPAWN_TIME);
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
		drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, hud_fontsize)), str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	scoreboard_bottom = pos.y + 2 * hud_fontsize.y;
}
