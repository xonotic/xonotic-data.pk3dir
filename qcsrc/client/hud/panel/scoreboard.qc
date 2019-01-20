#include "scoreboard.qh"

#include <client/autocvars.qh>
#include <client/defs.qh>
#include <client/main.qh>
#include <client/miscfunctions.qh>
#include "quickmenu.qh"
#include <common/ent_cs.qh>
#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/scores.qh>
#include <common/stats.qh>
#include <common/teams.qh>

// Scoreboard (#24)

const int MAX_SBT_FIELDS = MAX_SCORE;

PlayerScoreField sbt_field[MAX_SBT_FIELDS + 1];
float sbt_field_size[MAX_SBT_FIELDS + 1];
string sbt_field_title[MAX_SBT_FIELDS + 1];
int sbt_num_fields;

string autocvar_hud_fontsize;
string hud_fontsize_str;
float max_namesize;

float sbt_bg_alpha;
float sbt_fg_alpha;
float sbt_fg_alpha_self;
bool sbt_highlight;
float sbt_highlight_alpha;
float sbt_highlight_alpha_self;

// provide basic panel cvars to old clients
// TODO remove them after a future release (0.8.2+)
noref string autocvar_hud_panel_scoreboard_pos = "0.150000 0.150000";
noref string autocvar_hud_panel_scoreboard_size = "0.700000 0.700000";
noref string autocvar_hud_panel_scoreboard_bg = "border_default";
noref string autocvar_hud_panel_scoreboard_bg_color = "0 0.3 0.5";
noref string autocvar_hud_panel_scoreboard_bg_color_team = "";
noref string autocvar_hud_panel_scoreboard_bg_alpha = "0.7";
noref string autocvar_hud_panel_scoreboard_bg_border = "";
noref string autocvar_hud_panel_scoreboard_bg_padding = "";

float autocvar_hud_panel_scoreboard_fadeinspeed = 10;
float autocvar_hud_panel_scoreboard_fadeoutspeed = 5;
float autocvar_hud_panel_scoreboard_respawntime_decimals = 1;
float autocvar_hud_panel_scoreboard_table_bg_alpha = 0;
float autocvar_hud_panel_scoreboard_table_bg_scale = 0.25;
float autocvar_hud_panel_scoreboard_table_fg_alpha = 0.9;
float autocvar_hud_panel_scoreboard_table_fg_alpha_self = 1;
bool autocvar_hud_panel_scoreboard_table_highlight = true;
float autocvar_hud_panel_scoreboard_table_highlight_alpha = 0.2;
float autocvar_hud_panel_scoreboard_table_highlight_alpha_self = 0.4;
float autocvar_hud_panel_scoreboard_bg_teams_color_team = 0;
float autocvar_hud_panel_scoreboard_namesize = 15;

bool autocvar_hud_panel_scoreboard_accuracy = true;
bool autocvar_hud_panel_scoreboard_accuracy_doublerows = false;
bool autocvar_hud_panel_scoreboard_accuracy_nocolors = false;
float autocvar_hud_panel_scoreboard_accuracy_showdelay = 2;
float autocvar_hud_panel_scoreboard_accuracy_showdelay_minpos = 0.75;

bool autocvar_hud_panel_scoreboard_ctf_leaderboard = true;

bool autocvar_hud_panel_scoreboard_dynamichud = false;

float autocvar_hud_panel_scoreboard_maxheight = 0.6;
bool autocvar_hud_panel_scoreboard_others_showscore = true;
bool autocvar_hud_panel_scoreboard_spectators_showping = true;
bool autocvar_hud_panel_scoreboard_spectators_aligned = false;
float autocvar_hud_panel_scoreboard_minwidth = 0.4;

// mode 0: returns translated label
// mode 1: prints name and description of all the labels
string Label_getInfo(string label, int mode)
{
	if (mode == 1)
		label = "bckills"; // first case in the switch

	switch(label)
	{
		case "bckills":      if (!mode) return CTX(_("SCO^bckills"));      else LOG_INFO(strcat("^3", "bckills", "            ^7", _("Number of ball carrier kills")));
		case "bctime":       if (!mode) return CTX(_("SCO^bctime"));       else LOG_INFO(strcat("^3", "bctime", "             ^7", _("Total amount of time holding the ball in Keepaway")));
		case "caps":         if (!mode) return CTX(_("SCO^caps"));         else LOG_INFO(strcat("^3", "caps", "               ^7", _("How often a flag (CTF) or a key (KeyHunt) was captured")));
		case "captime":      if (!mode) return CTX(_("SCO^captime"));      else LOG_INFO(strcat("^3", "captime", "            ^7", _("Time of fastest capture (CTF)")));
		case "deaths":       if (!mode) return CTX(_("SCO^deaths"));       else LOG_INFO(strcat("^3", "deaths", "             ^7", _("Number of deaths")));
		case "destroyed":    if (!mode) return CTX(_("SCO^destroyed"));    else LOG_INFO(strcat("^3", "destroyed", "          ^7", _("Number of keys destroyed by pushing them into void")));
		case "dmg":          if (!mode) return CTX(_("SCO^damage"));       else LOG_INFO(strcat("^3", "dmg", "                ^7", _("The total damage done")));
		case "dmgtaken":     if (!mode) return CTX(_("SCO^dmgtaken"));     else LOG_INFO(strcat("^3", "dmgtaken", "           ^7", _("The total damage taken")));
		case "drops":        if (!mode) return CTX(_("SCO^drops"));        else LOG_INFO(strcat("^3", "drops", "              ^7", _("Number of flag drops")));
		case "elo":          if (!mode) return CTX(_("SCO^elo"));          else LOG_INFO(strcat("^3", "elo", "                ^7", _("Player ELO")));
		case "fastest":      if (!mode) return CTX(_("SCO^fastest"));      else LOG_INFO(strcat("^3", "fastest", "            ^7", _("Time of fastest lap (Race/CTS)")));
		case "faults":       if (!mode) return CTX(_("SCO^faults"));       else LOG_INFO(strcat("^3", "faults", "             ^7", _("Number of faults committed")));
		case "fckills":      if (!mode) return CTX(_("SCO^fckills"));      else LOG_INFO(strcat("^3", "fckills", "            ^7", _("Number of flag carrier kills")));
		case "fps":          if (!mode) return CTX(_("SCO^fps"));          else LOG_INFO(strcat("^3", "fps", "                ^7", _("FPS")));
		case "frags":        if (!mode) return CTX(_("SCO^frags"));        else LOG_INFO(strcat("^3", "frags", "              ^7", _("Number of kills minus suicides")));
		case "goals":        if (!mode) return CTX(_("SCO^goals"));        else LOG_INFO(strcat("^3", "goals", "              ^7", _("Number of goals scored")));
		case "kckills":      if (!mode) return CTX(_("SCO^kckills"));      else LOG_INFO(strcat("^3", "kckills", "            ^7", _("Number of keys carrier kills")));
		case "kd":           if (!mode) return CTX(_("SCO^k/d"));          else LOG_INFO(strcat("^3", "kd", "                 ^7", _("The kill-death ratio")));
		case "kdr":          if (!mode) return CTX(_("SCO^kdr"));          else LOG_INFO(strcat("^3", "kdr", "                ^7", _("The kill-death ratio")));
		case "kdratio":      if (!mode) return CTX(_("SCO^kdratio"));      else LOG_INFO(strcat("^3", "kdratio", "            ^7", _("The kill-death ratio")));
		case "kills":        if (!mode) return CTX(_("SCO^kills"));        else LOG_INFO(strcat("^3", "kills", "              ^7", _("Number of kills")));
		case "laps":         if (!mode) return CTX(_("SCO^laps"));         else LOG_INFO(strcat("^3", "laps", "               ^7", _("Number of laps finished (Race/CTS)")));
		case "lives":        if (!mode) return CTX(_("SCO^lives"));        else LOG_INFO(strcat("^3", "lives", "              ^7", _("Number of lives (LMS)")));
		case "losses":       if (!mode) return CTX(_("SCO^losses"));       else LOG_INFO(strcat("^3", "losses", "             ^7", _("Number of times a key was lost")));
		case "name":         if (!mode) return CTX(_("SCO^name"));         else LOG_INFO(strcat("^3", "name", "               ^7", _("Player name")));
		case "nick":         if (!mode) return CTX(_("SCO^nick"));         else LOG_INFO(strcat("^3", "nick", "               ^7", _("Player name")));
		case "objectives":   if (!mode) return CTX(_("SCO^objectives"));   else LOG_INFO(strcat("^3", "objectives", "         ^7", _("Number of objectives destroyed")));
		case "pickups":      if (!mode) return CTX(_("SCO^pickups"));      else LOG_INFO(strcat("^3", "pickups", "            ^7", _("How often a flag (CTF) or a key (KeyHunt) or a ball (Keepaway) was picked up")));
		case "ping":         if (!mode) return CTX(_("SCO^ping"));         else LOG_INFO(strcat("^3", "ping", "               ^7", _("Ping time")));
		case "pl":           if (!mode) return CTX(_("SCO^pl"));           else LOG_INFO(strcat("^3", "pl", "                 ^7", _("Packet loss")));
		case "pushes":       if (!mode) return CTX(_("SCO^pushes"));       else LOG_INFO(strcat("^3", "pushes", "             ^7", _("Number of players pushed into void")));
		case "rank":         if (!mode) return CTX(_("SCO^rank"));         else LOG_INFO(strcat("^3", "rank", "               ^7", _("Player rank")));
		case "returns":      if (!mode) return CTX(_("SCO^returns"));      else LOG_INFO(strcat("^3", "returns", "            ^7", _("Number of flag returns")));
		case "revivals":     if (!mode) return CTX(_("SCO^revivals"));     else LOG_INFO(strcat("^3", "revivals", "           ^7", _("Number of revivals")));
		case "rounds":       if (!mode) return CTX(_("SCO^rounds won"));   else LOG_INFO(strcat("^3", "rounds", "             ^7", _("Number of rounds won")));
		case "score":        if (!mode) return CTX(_("SCO^score"));        else LOG_INFO(strcat("^3", "score", "              ^7", _("Total score")));
		case "suicides":     if (!mode) return CTX(_("SCO^suicides"));     else LOG_INFO(strcat("^3", "suicides", "           ^7", _("Number of suicides")));
		case "sum":          if (!mode) return CTX(_("SCO^sum"));          else LOG_INFO(strcat("^3", "sum", "                ^7", _("Number of kills minus deaths")));
		case "takes":        if (!mode) return CTX(_("SCO^takes"));        else LOG_INFO(strcat("^3", "takes", "              ^7", _("Number of domination points taken (Domination)")));
		case "teamkills":    if (!mode) return CTX(_("SCO^teamkills"));    else LOG_INFO(strcat("^3", "teamkills", "          ^7", _("Number of teamkills")));
		case "ticks":        if (!mode) return CTX(_("SCO^ticks"));        else LOG_INFO(strcat("^3", "ticks", "              ^7", _("Number of ticks (Domination)")));
		case "time":         if (!mode) return CTX(_("SCO^time"));         else LOG_INFO(strcat("^3", "time", "               ^7", _("Total time raced (Race/CTS)")));
		default: return label;
	}
	return label;
}

void PrintScoresLabels() { Label_getInfo(string_null, 1); }
string TranslateScoresLabel(string label) { return Label_getInfo(label, 0); }

void Scoreboard_InitScores()
{
	int i, f;

	ps_primary = ps_secondary = NULL;
	ts_primary = ts_secondary = -1;
	FOREACH(Scores, true, {
		f = (scores_flags(it) & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = it;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = it;
	});
	if(ps_secondary == NULL)
		ps_secondary = ps_primary;

	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		f = (teamscores_flags(i) & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if(ts_secondary == -1)
		ts_secondary = ts_primary;

	Cmd_Scoreboard_SetFields(0);
}

//float lastpnum;
void Scoreboard_UpdatePlayerTeams()
{
	entity pl, tmp;
	//int num = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		//num += 1;
		int Team = entcs_GetScoreTeam(pl.sv_entnum);
		if(SetTeam(pl, Team))
		{
			tmp = pl.sort_prev;
			Scoreboard_UpdatePlayerPos(pl);
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

int Scoreboard_CompareScore(int vl, int vr, int f)
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

float Scoreboard_ComparePlayerScores(entity left, entity right)
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

	r = Scoreboard_CompareScore(left.scores(ps_primary), right.scores(ps_primary), scores_flags(ps_primary));
	if (r >= 0)
		return r;

	r = Scoreboard_CompareScore(left.scores(ps_secondary), right.scores(ps_secondary), scores_flags(ps_secondary));
	if (r >= 0)
		return r;

	FOREACH(Scores, true, {
		r = Scoreboard_CompareScore(left.scores(it), right.scores(it), scores_flags(it));
		if (r >= 0) return r;
	});

	if (left.sv_entnum < right.sv_entnum)
		return true;

	return false;
}

void Scoreboard_UpdatePlayerPos(entity player)
{
	entity ent;
	for(ent = player.sort_next; ent && Scoreboard_ComparePlayerScores(player, ent); ent = player.sort_next)
	{
		SORT_SWAP(player, ent);
	}
	for(ent = player.sort_prev; ent != players && Scoreboard_ComparePlayerScores(ent, player); ent = player.sort_prev)
	{
		SORT_SWAP(ent, player);
	}
}

float Scoreboard_CompareTeamScores(entity left, entity right)
{
	int i, r;

	if(left.team == NUM_SPECTATOR)
		return 1;
	if(right.team == NUM_SPECTATOR)
		return 0;

	r = Scoreboard_CompareScore(left.teamscores(ts_primary), right.teamscores(ts_primary), teamscores_flags(ts_primary));
	if (r >= 0)
		return r;

	r = Scoreboard_CompareScore(left.teamscores(ts_secondary), right.teamscores(ts_secondary), teamscores_flags(ts_secondary));
	if (r >= 0)
		return r;

	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		r = Scoreboard_CompareScore(left.teamscores(i), right.teamscores(i), teamscores_flags(i));
		if (r >= 0)
			return r;
	}

	if (left.team < right.team)
		return true;

	return false;
}

void Scoreboard_UpdateTeamPos(entity Team)
{
	entity ent;
	for(ent = Team.sort_next; ent && Scoreboard_CompareTeamScores(Team, ent); ent = Team.sort_next)
	{
		SORT_SWAP(Team, ent);
	}
	for(ent = Team.sort_prev; ent != teams && Scoreboard_CompareTeamScores(ent, Team); ent = Team.sort_prev)
	{
		SORT_SWAP(ent, Team);
	}
}

void Cmd_Scoreboard_Help()
{
	LOG_INFO(_("You can modify the scoreboard using the ^2scoreboard_columns_set command."));
	LOG_INFO(_("Usage:"));
	LOG_INFO("^2scoreboard_columns_set ^3default");
	LOG_INFO(_("^2scoreboard_columns_set ^3field1 field2 ..."));
	LOG_INFO(_("^2scoreboard_columns_set ^7without arguments reads the arguments from the cvar scoreboard_columns"));
	LOG_INFO(_("  ^5Note: ^7scoreboard_columns_set without arguments is executed on every map start"));
	LOG_INFO(_("^2scoreboard_columns_set ^3expand_default ^7loads default layout and expands it into the cvar scoreboard_columns so you can edit it"));
	LOG_INFO(_("You can use a ^3|^7 to start the right-aligned fields."));
	LOG_INFO(_("The following field names are recognized (case insensitive):"));
	LOG_INFO("");

	PrintScoresLabels();
	LOG_INFO("");

	LOG_INFO(_("Before a field you can put a + or - sign, then a comma separated list\n"
	        "of game types, then a slash, to make the field show up only in these\n"
	        "or in all but these game types. You can also specify 'all' as a\n"
	        "field to show all fields available for the current game mode."));
	LOG_INFO("");

	LOG_INFO(_("The special game type names 'teams' and 'noteams' can be used to\n"
	        "include/exclude ALL teams/noteams game modes."));
	LOG_INFO("");

	LOG_INFO(_("Example: scoreboard_columns_set name ping pl | +ctf/field3 -dm/field4"));
	LOG_INFO(_("will display name, ping and pl aligned to the left, and the fields\n"
	        "right of the vertical bar aligned to the right."));
	LOG_INFO(_("'field3' will only be shown in CTF, and 'field4' will be shown in all\n"
			"other gamemodes except DM."));
}

// NOTE: adding a gametype with ? to not warn for an optional field
// make sure it's excluded in a previous exclusive rule, if any
// otherwise the previous exclusive rule warns anyway
// e.g. -teams,rc,cts,lms/kills ?+rc/kills
#define SCOREBOARD_DEFAULT_COLUMNS \
"ping pl fps name |" \
" -teams,rc,cts,inv,lms/kills +ft,tdm/kills ?+rc,inv/kills" \
" -teams,lms/deaths +ft,tdm/deaths" \
" +tdm/sum" \
" -teams,lms,rc,cts,inv,ka/suicides +ft,tdm/suicides ?+rc,inv/suicides" \
" -cts,dm,tdm,ka,ft/frags" /* tdm already has this in "score" */ \
" +tdm,ft,dom,ons,as/teamkills"\
" -rc,cts,nb/dmg -rc,cts,nb/dmgtaken" \
" +ctf/pickups +ctf/fckills +ctf/returns +ctf/caps +ons/takes +ons/caps" \
" +lms/lives +lms/rank" \
" +kh/kckills +kh/losses +kh/caps" \
" ?+rc/laps ?+rc/time +rc,cts/fastest" \
" +as/objectives +nb/faults +nb/goals" \
" +ka/pickups +ka/bckills +ka/bctime +ft/revivals" \
" +dom/ticks +dom/takes" \
" -lms,rc,cts,inv,nb/score"

void Cmd_Scoreboard_SetFields(int argc)
{
	TC(int, argc);
	int i, slash;
	string str, pattern;
	bool have_name = false, have_primary = false, have_secondary = false, have_separator = false;
	int missing;

	if(!gametype)
		return; // do nothing, we don't know gametype and scores yet

	// sbt_fields uses strunzone on the titles!
	if(!sbt_field_title[0])
		for(i = 0; i < MAX_SBT_FIELDS; ++i)
			sbt_field_title[i] = strzone("(null)");

	// TODO: re enable with gametype dependant cvars?
	if(argc < 3) // no arguments provided
		argc = tokenizebyseparator(strcat("0 1 ", autocvar_scoreboard_columns), " ");

	if(argc < 3)
		argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");

	if(argc == 3)
	{
		if(argv(2) == "default" || argv(2) == "expand_default")
		{
			if(argv(2) == "expand_default")
				cvar_set("scoreboard_columns", SCOREBOARD_DEFAULT_COLUMNS);
			argc = tokenizebyseparator(strcat("0 1 ", SCOREBOARD_DEFAULT_COLUMNS), " ");
		}
		else if(argv(2) == "all")
		{
			string s = "ping pl name |"; // scores without a label
			FOREACH(Scores, true, {
				if(it != ps_primary)
				if(it != ps_secondary)
				if(scores_label(it) != "")
					s = strcat(s, " ", scores_label(it));
			});
			if(ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label(ps_secondary));
			s = strcat(s, " ", scores_label(ps_primary));
			argc = tokenizebyseparator(strcat("0 1 ", s), " ");
		}
	}


	sbt_num_fields = 0;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	for(i = 1; i < argc - 1; ++i)
	{
		str = argv(i+1);
		bool nocomplain = false;
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

		strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(str));
		sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
		str = strtolower(str);

		PlayerScoreField j;
		switch(str)
		{
			case "ping": sbt_field[sbt_num_fields] = SP_PING; break;
			case "pl": sbt_field[sbt_num_fields] = SP_PL; break;
			case "kd": case "kdr": case "kdratio": sbt_field[sbt_num_fields] = SP_KDRATIO; break;
			case "sum": case "diff": case "k-d": sbt_field[sbt_num_fields] = SP_SUM; break;
			case "name": case "nick": sbt_field[sbt_num_fields] = SP_NAME; have_name = true; break;
			case "|": sbt_field[sbt_num_fields] = SP_SEPARATOR; have_separator = true; break;
			case "elo": sbt_field[sbt_num_fields] = SP_ELO; break;
			case "dmg": case "damage": sbt_field[sbt_num_fields] = SP_DMG; break;
			case "dmgtaken": case "damagetaken": sbt_field[sbt_num_fields] = SP_DMGTAKEN; break;
			case "fps": sbt_field[sbt_num_fields] = SP_FPS; break;
			default:
			{
				FOREACH(Scores, true, {
					if (str == strtolower(scores_label(it))) {
						j = it;
						goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
					}
				});

LABEL(notfound)
				if(str == "frags")
					j = SP_FRAGS;
				else
				{
					if(!nocomplain)
						LOG_INFOF("^1Error:^7 Unknown score field: '%s'", str);
					continue;
				}
LABEL(found)
				sbt_field[sbt_num_fields] = j;
				if(j == ps_primary)
					have_primary = true;
				if(j == ps_secondary)
					have_secondary = true;

			}
		}
		++sbt_num_fields;
		if(sbt_num_fields >= MAX_SBT_FIELDS)
			break;
	}

	if(scores_flags(ps_primary) & SFL_ALLOW_HIDE)
		have_primary = true;
	if(scores_flags(ps_secondary) & SFL_ALLOW_HIDE)
		have_secondary = true;
	if(ps_primary == ps_secondary)
		have_secondary = true;
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
			LOG_INFO("fixed missing field 'name'");

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
				LOG_INFO("fixed missing field '|'");
			}
		}
		else if(!have_separator)
		{
			strcpy(sbt_field_title[sbt_num_fields], "|");
			sbt_field_size[sbt_num_fields] = stringwidth("|", false, hud_fontsize);
			sbt_field[sbt_num_fields] = SP_SEPARATOR;
			++sbt_num_fields;
			LOG_INFO("fixed missing field '|'");
		}
		if(!have_secondary)
		{
			strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(scores_label(ps_secondary)));
			sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
			sbt_field[sbt_num_fields] = ps_secondary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'", scores_label(ps_secondary));
		}
		if(!have_primary)
		{
			strcpy(sbt_field_title[sbt_num_fields], TranslateScoresLabel(scores_label(ps_primary)));
			sbt_field_size[sbt_num_fields] = stringwidth(sbt_field_title[sbt_num_fields], false, hud_fontsize);
			sbt_field[sbt_num_fields] = ps_primary;
			++sbt_num_fields;
			LOG_INFOF("fixed missing field '%s'", scores_label(ps_primary));
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
string Scoreboard_GetName(entity pl)
{
	if(ready_waiting && pl.ready)
	{
		sbt_field_icon0 = "gfx/scoreboard/player_ready";
	}
	else if(!teamplay)
	{
		int f = entcs_GetClientColors(pl.sv_entnum);
		{
			sbt_field_icon0 = "gfx/scoreboard/playercolor_base";
			sbt_field_icon1 = "gfx/scoreboard/playercolor_shirt";
			sbt_field_icon1_rgb = colormapPaletteColor(floor(f / 16), 0);
			sbt_field_icon2 = "gfx/scoreboard/playercolor_pants";
			sbt_field_icon2_rgb = colormapPaletteColor(f % 16, 1);
		}
	}
	return entcs_GetName(pl.sv_entnum);
}
string Scoreboard_GetField(entity pl, PlayerScoreField field)
{
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
			return Scoreboard_GetName(pl);

		case SP_FRAGS:
			f = pl.(scores(SP_KILLS));
			f -= pl.(scores(SP_SUICIDES));
			return ftos(f);

		case SP_KDRATIO:
			num = pl.(scores(SP_KILLS));
			denom = pl.(scores(SP_DEATHS));

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
			f = pl.(scores(SP_KILLS));
			f -= pl.(scores(SP_DEATHS));

			if(f > 0) {
				sbt_field_rgb = '0 1 0';
			} else if(f == 0) {
				sbt_field_rgb = '1 1 1';
			} else {
				sbt_field_rgb = '1 0 0';
			}
			return ftos(f);

		case SP_ELO:
		{
			float elo = pl.(scores(SP_ELO));
			switch (elo) {
				case -1: return "...";
				case -2: return _("N/A");
				default: return ftos(elo);
			}
		}

		case SP_FPS:
		{
			float fps = pl.(scores(SP_FPS));
			if(fps == 0)
			{
				sbt_field_rgb = '1 1 1';
				return ((pl.ping == 0) ? _("N/A") : "..."); // if 0 ping, either connecting or bot (either case can't show proper score)
			}
			//sbt_field_rgb = HUD_Get_Num_Color(fps, 200);
			sbt_field_rgb = '1 0 0' + '0 1 1' * (bound(0, fps, 60) / 60);
			return ftos(fps);
		}

		case SP_DMG: case SP_DMGTAKEN:
			return sprintf("%.1f k", pl.(scores(field)) / 1000);

		default: case SP_SCORE:
			tmp = pl.(scores(field));
			f = scores_flags(field);
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

string Scoreboard_FixColumnWidth(int i, string str)
{
	TC(int, i);
	float f;
	vector sz;

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

	if(sbt_fixcolumnwidth_iconlen != 0)
	{
		sbt_fixcolumnwidth_iconlen *= hud_fontsize.y / hud_fontsize.x; // fix icon aspect
		sbt_fixcolumnwidth_marginlen = stringwidth(" ", false, hud_fontsize);
	}
	else
		sbt_fixcolumnwidth_marginlen = 0;

	if(sbt_field[i] == SP_NAME) // name gets all remaining space
	{
		int j;
		float remaining_space = 0;
		for(j = 0; j < sbt_num_fields; ++j)
			if(j != i)
				if (sbt_field[i] != SP_SEPARATOR)
					remaining_space += sbt_field_size[j] + hud_fontsize.x;
		sbt_field_size[i] = panel_size.x - remaining_space;

		if (sbt_fixcolumnwidth_iconlen != 0)
			remaining_space += sbt_fixcolumnwidth_marginlen + sbt_fixcolumnwidth_iconlen * hud_fontsize.x;
		float namesize = panel_size.x - remaining_space;
		str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		sbt_fixcolumnwidth_len = stringwidth(str, true, hud_fontsize);

		max_namesize = vid_conwidth - remaining_space;
	}
	else
		sbt_fixcolumnwidth_len = stringwidth(str, false, hud_fontsize);

	f = sbt_fixcolumnwidth_len + sbt_fixcolumnwidth_marginlen + sbt_fixcolumnwidth_iconlen * hud_fontsize.x;
	if(sbt_field_size[i] < f)
		sbt_field_size[i] = f;

	return str;
}

void Scoreboard_initFieldSizes()
{
	for(int i = 0; i < sbt_num_fields; ++i)
	{
		sbt_field_size[i] = stringwidth(sbt_field_title[i], false, hud_fontsize);
		Scoreboard_FixColumnWidth(i, "");
	}
}

vector Scoreboard_DrawHeader(vector pos, vector rgb, bool other_players)
{
	int i;
	vector column_dim = eY * panel_size.y;
	if(other_players)
		column_dim.y -= 1.25 * hud_fontsize.y;
	vector text_offset = eY * (1.25 - 1) / 2 * hud_fontsize.y;
	pos.x += hud_fontsize.x * 0.5;
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
		pos.x = panel_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		for(i = sbt_num_fields - 1; i > 0; --i)
		{
			if(sbt_field[i] == SP_SEPARATOR)
				break;

			pos.x -= sbt_field_size[i];

			if (sbt_highlight)
				if (!(i % 2))
				{
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

void Scoreboard_DrawItem(vector item_pos, vector rgb, entity pl, bool is_self, int pl_number)
{
	TC(bool, is_self); TC(int, pl_number);
	string str;
	bool is_spec = entcs_IsSpectating(pl.sv_entnum);

	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);
	// alternated rows highlighting
	if(is_self)
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if((sbt_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	float fg_alpha = (is_self ? sbt_fg_alpha_self : sbt_fg_alpha);

	vector pos = item_pos;
	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically
	vector tmp = '0 0 0';
	int i;
	PlayerScoreField field;
	for(i = 0; i < sbt_num_fields; ++i)
	{
		field = sbt_field[i];
		if(field == SP_SEPARATOR)
			break;

		if(is_spec && field != SP_NAME && field != SP_PING) {
			pos.x += sbt_field_size[i] + hud_fontsize.x;
			continue;
		}
		str = Scoreboard_GetField(pl, field);
		str = Scoreboard_FixColumnWidth(i, str);

		pos.x += sbt_field_size[i] + hud_fontsize.x;

		if(field == SP_NAME) {
			tmp.x = sbt_field_size[i] - hud_fontsize.x * sbt_fixcolumnwidth_iconlen - sbt_fixcolumnwidth_marginlen + hud_fontsize.x;
			drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);
		} else {
			tmp.x = sbt_fixcolumnwidth_len + hud_fontsize.x;
			drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
		}

		tmp.x = sbt_field_size[i] + hud_fontsize.x;
		if(sbt_field_icon0 != "")
			drawpic(pos - tmp, sbt_field_icon0, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon1_rgb, fg_alpha, DRAWFLAG_NORMAL);
		if(sbt_field_icon1 != "")
			drawpic(pos - tmp, sbt_field_icon1, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon1_rgb, fg_alpha, DRAWFLAG_NORMAL);
		if(sbt_field_icon2 != "")
			drawpic(pos - tmp, sbt_field_icon2, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon2_rgb, fg_alpha, DRAWFLAG_NORMAL);
	}

	if(sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = item_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		for(i = sbt_num_fields-1; i > 0; --i)
		{
			field = sbt_field[i];
			if(field == SP_SEPARATOR)
				break;

			if(is_spec && field != SP_NAME && field != SP_PING) {
				pos.x -= sbt_field_size[i] + hud_fontsize.x;
				continue;
			}

			str = Scoreboard_GetField(pl, field);
			str = Scoreboard_FixColumnWidth(i, str);

			if(field == SP_NAME) {
				tmp.x = sbt_fixcolumnwidth_len; // left or right aligned? let's put it right...
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);
			} else {
				tmp.x = sbt_fixcolumnwidth_len;
				drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
			}

			tmp.x = sbt_field_size[i];
			if(sbt_field_icon0 != "")
				drawpic(pos - tmp, sbt_field_icon0, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon1_rgb, fg_alpha, DRAWFLAG_NORMAL);
			if(sbt_field_icon1 != "")
				drawpic(pos - tmp, sbt_field_icon1, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon1_rgb, fg_alpha, DRAWFLAG_NORMAL);
			if(sbt_field_icon2 != "")
				drawpic(pos - tmp, sbt_field_icon2, vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen, hud_fontsize.y), sbt_field_icon2_rgb, fg_alpha, DRAWFLAG_NORMAL);
			pos.x -= sbt_field_size[i] + hud_fontsize.x;
		}
	}

	if(pl.eliminated)
		drawfill(h_pos, h_size, '0 0 0', 0.5 * panel_fg_alpha, DRAWFLAG_NORMAL);
}

vector Scoreboard_DrawOthers(vector item_pos, vector rgb, int this_team, entity ignored_pl, entity pl, int pl_number)
{
	int i = 0;
	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);

	bool complete = (this_team == NUM_SPECTATOR);

	if(!complete)
	if((sbt_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	vector pos = item_pos;
	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically

	float width_limit = item_pos.x + panel_size.x - hud_fontsize.x;
	if(!complete)
		width_limit -= stringwidth("...", false, hud_fontsize);
	float namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
	static float max_name_width = 0;
	string field = "";
	float fieldsize = 0;
	float min_fieldsize = 0;
	float fieldpadding = hud_fontsize.x * 0.25;
	if(this_team == NUM_SPECTATOR)
	{
		if(autocvar_hud_panel_scoreboard_spectators_showping)
			min_fieldsize = stringwidth("999", false, hud_fontsize);
	}
	else if(autocvar_hud_panel_scoreboard_others_showscore)
		min_fieldsize = stringwidth("99", false, hud_fontsize);
	for(i = 0; pl; pl = pl.sort_next)
	{
		if(pl.team != this_team)
			continue;
		if(pl == ignored_pl)
			continue;

		field = "";
		if(this_team == NUM_SPECTATOR)
		{
			if(autocvar_hud_panel_scoreboard_spectators_showping)
				field = Scoreboard_GetField(pl, SP_PING);
		}
		else if(autocvar_hud_panel_scoreboard_others_showscore)
			field = Scoreboard_GetField(pl, SP_SCORE);

		string str = textShortenToWidth(entcs_GetName(pl.sv_entnum), namesize, hud_fontsize, stringwidth_colors);
		float column_width = stringwidth(str, true, hud_fontsize);
		if((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned)
		{
			if(column_width > max_name_width)
				max_name_width = column_width;
			column_width = max_name_width;
		}
		if(field != "")
		{
			fieldsize = stringwidth(field, false, hud_fontsize);
			column_width += hud_fontsize.x * 0.25 + max(fieldsize, min_fieldsize) + 2 * fieldpadding;
		}

		if(pos.x + column_width > width_limit)
		{
			++i;
			if(!complete)
			{
				drawstring(pos, "...", hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
				break;
			}
			else
			{
				pos.x = item_pos.x + hud_fontsize.x * 0.5;
				pos.y += hud_fontsize.y * 1.25;
			}
		}

		vector name_pos = pos;
		if((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned)
			name_pos.x += max(fieldsize, min_fieldsize) + 2 * fieldpadding + hud_fontsize.x * 0.25;
		drawcolorcodedstring(name_pos, str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);
		if(field != "")
		{
			h_size.x = max(fieldsize, min_fieldsize) + 2 * fieldpadding;
			h_size.y = hud_fontsize.y;
			vector field_pos = pos;
			if(!((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned))
				field_pos.x += column_width - h_size.x;
			if(sbt_highlight)
				drawfill(field_pos, h_size, '1 1 1', sbt_highlight_alpha, DRAWFLAG_NORMAL);
			field_pos.x += fieldpadding + (max(fieldsize, min_fieldsize) - fieldsize) * 0.5;
			drawstring(field_pos, field, hud_fontsize, sbt_field_rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
		}
		if(pl.eliminated)
		{
			h_size.x = column_width + hud_fontsize.x * 0.25;
			h_size.y = hud_fontsize.y;
			drawfill(pos - hud_fontsize.x * 0.25 * eX, h_size, '0 0 0', 0.5 * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		pos.x += column_width;
		pos.x += hud_fontsize.x;
	}
	return vec2(item_pos.x, item_pos.y + i * hud_fontsize.y * 1.25);
}

vector Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size)
{
	int max_players = 999;
	if(autocvar_hud_panel_scoreboard_maxheight > 0)
	{
		float height = autocvar_hud_panel_scoreboard_maxheight * vid_conheight;
		if(teamplay)
		{
			height -= (panel_bg_padding * 2 + hud_fontsize.y * 1.25) * team_count; // - padding and header
			height -= hud_fontsize.y * (team_count - 1); // - spacing between tables
			height /= team_count;
		}
		else
			height -= panel_bg_padding * 2; // - padding
		max_players = floor(height / (hud_fontsize.y * 1.25));
		if(max_players <= 1)
			max_players = 1;
		if(max_players == tm.team_size)
			max_players = 999;
	}

	entity pl;
	entity me = playerslots[current_player];
	panel_pos = pos;
	panel_size.y = 1.25 * hud_fontsize.y * (1 + bound(1, tm.team_size, max_players));
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + hud_fontsize.y);
	if(panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = vec2(panel_size.x, 1.25 * hud_fontsize.y);

	// rounded header
	if (sbt_bg_alpha)
		drawpic(pos, "gfx/scoreboard/scoreboard_tableheader", tmp, rgb + '0.5 0.5 0.5', sbt_bg_alpha, DRAWFLAG_NORMAL);

	pos.y += 1.25 * hud_fontsize.y;

	// table background
	tmp.y = panel_size.y - 1.25 * hud_fontsize.y;
	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);


	// print header row and highlight columns
	pos = Scoreboard_DrawHeader(panel_pos, rgb, (max_players < tm.team_size));

	// fill the table and draw the rows
	bool is_self = false;
	bool self_shown = false;
	int i = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != tm.team)
			continue;
		if(i == max_players - 2 && pl != me)
		{
			if(!self_shown && me.team == tm.team)
			{
				Scoreboard_DrawItem(pos, rgb, me, true, i);
				self_shown = true;
				pos.y += 1.25 * hud_fontsize.y;
				++i;
			}
		}
		if(i >= max_players - 1)
		{
			pos = Scoreboard_DrawOthers(pos, rgb, tm.team, (self_shown ? me : NULL), pl, i);
			break;
		}
		is_self = (pl.sv_entnum == current_player);
		Scoreboard_DrawItem(pos, rgb, pl, is_self, i);
		if(is_self)
			self_shown = true;
		pos.y += 1.25 * hud_fontsize.y;
		++i;
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

bool Scoreboard_WouldDraw()
{
	if (MUTATOR_CALLHOOK(DrawScoreboard))
		return false;
	else if (QuickMenu_IsOpened())
		return false;
	else if (HUD_Radar_Clickable())
		return false;
	else if (scoreboard_showscores)
		return true;
	else if (intermission == 1)
		return true;
	else if (intermission == 2)
		return false;
	else if (spectatee_status != -1 && STAT(HEALTH) <= 0 && autocvar_cl_deathscoreboard && !ISGAMETYPE(CTS) && !active_minigame)
		return true;
	else if (scoreboard_showscores_force)
		return true;
	return false;
}

float average_accuracy;
vector Scoreboard_AccuracyStats_Draw(vector pos, vector rgb, vector bg_size)
{
	if (frametime)
	{
		if (scoreboard_fade_alpha == 1)
			scoreboard_acc_fade_alpha = min(1, scoreboard_acc_fade_alpha + frametime * 10);
		else
			scoreboard_acc_fade_alpha = 1; // sync fading with the scoreboard
	}
	vector initial_pos = pos;

	WepSet weapons_stat = WepSet_GetFromStat();
	WepSet weapons_inmap = WepSet_GetFromStat_InMap();
	int disownedcnt = 0;
	int nHidden = 0;
	FOREACH(Weapons, it != WEP_Null, {
		int weapon_stats = weapon_accuracy[i - WEP_FIRST];

		WepSet set = it.m_wepset;
		if(it.spawnflags & WEP_TYPE_OTHER)
		{
			++nHidden;
			continue;
		}
		if (weapon_stats < 0 && !((weapons_stat & set) || (weapons_inmap & set)))
		{
			if (((it.spawnflags & WEP_FLAG_HIDDEN) || (it.spawnflags & WEP_FLAG_MUTATORBLOCKED)))
				++nHidden;
			else
				++disownedcnt;
		}
	});

	int weapon_cnt = (Weapons_COUNT - 1) - disownedcnt - nHidden;
	if (weapon_cnt <= 0) return pos;

	int rows = 1;
	if (autocvar_hud_panel_scoreboard_accuracy_doublerows && weapon_cnt >= floor((Weapons_COUNT - nHidden - 1) * 0.5))
		rows = 2;
	int columnns = ceil(weapon_cnt / rows);

	float weapon_height = 29;
	float height = hud_fontsize.y + weapon_height;

	drawstring(pos + eX * panel_bg_padding, sprintf(_("Accuracy stats (average %d%%)"), average_accuracy), hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if(panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = height * rows;
	panel_size.y += panel_bg_padding * 2;

	float panel_bg_alpha_save = panel_bg_alpha;
	panel_bg_alpha *= scoreboard_acc_fade_alpha;
	HUD_Panel_DrawBg();
	panel_bg_alpha = panel_bg_alpha_save;

	vector end_pos = panel_pos + eY * (panel_size.y + hud_fontsize.y);
	if(panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	float weapon_width = tmp.x / columnns / rows;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);

	if(sbt_highlight)
	{
		// column highlighting
		for (int i = 0; i < columnns; ++i)
			if ((i % 2) == 0)
				drawfill(pos + eX * weapon_width * rows * i, vec2(weapon_width * rows, height * rows), '0 0 0', sbt_highlight_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);

		// row highlighting
		for (int i = 0; i < rows; ++i)
			drawfill(pos + eY * (weapon_height + height * i), vec2(tmp.x, hud_fontsize.y), rgb, sbt_highlight_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
	}

	average_accuracy = 0;
	int weapons_with_stats = 0;
	if (rows == 2)
		pos.x += weapon_width / 2;

	if (autocvar_hud_panel_scoreboard_accuracy_nocolors)
		rgb = '1 1 1';
	else
		Accuracy_LoadColors();

	float oldposx = pos.x;
	vector tmpos = pos;

	int column = 0;
	FOREACH(Weapons, it != WEP_Null, {
		int weapon_stats = weapon_accuracy[i - WEP_FIRST];

		WepSet set = it.m_wepset;
		if (weapon_stats < 0 && !((weapons_stat & set) || (weapons_inmap & set)))
			continue;
		if (it.spawnflags & WEP_TYPE_OTHER)
			continue;

		float weapon_alpha;
		if (weapon_stats >= 0)
			weapon_alpha = sbt_fg_alpha;
		else
			weapon_alpha = 0.2 * sbt_fg_alpha;

		// weapon icon
		drawpic_aspect_skin(tmpos, it.model2, vec2(weapon_width, weapon_height), '1 1 1', weapon_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		// the accuracy
		if (weapon_stats >= 0) {
			weapons_with_stats += 1;
			average_accuracy += weapon_stats; // store sum of all accuracies in average_accuracy

			string s;
			s = sprintf("%d%%", weapon_stats * 100);

			float padding;
			padding = (weapon_width - stringwidth(s, false, hud_fontsize)) / 2; // center the accuracy value

			if(!autocvar_hud_panel_scoreboard_accuracy_nocolors)
				rgb = Accuracy_GetColor(weapon_stats);

			drawstring(tmpos + vec2(padding, weapon_height), s, hud_fontsize, rgb, sbt_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
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

	if (scoreboard_acc_fade_alpha == 1)
		return end_pos;
	return initial_pos + (end_pos - initial_pos) * scoreboard_acc_fade_alpha;
}

vector MapStats_DrawKeyValue(vector pos, string key, string value) {
	float px = pos.x;
	pos.x += hud_fontsize.x * 0.25;
	drawstring(pos, key, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = panel_pos.x + panel_size.x - stringwidth(value, false, hud_fontsize) - hud_fontsize.x * 0.25;
	drawstring(pos, value, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = px;
	pos.y += hud_fontsize.y;

	return pos;
}

vector Scoreboard_MapStats_Draw(vector pos, vector rgb, vector bg_size) {
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
	if(panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = hud_fontsize.y * rows;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + hud_fontsize.y);
	if(panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

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
		pos = MapStats_DrawKeyValue(pos, _("Monsters killed:"), val);
	}

	// draw secrets
	if(stat_secrets_total)
	{
		val = sprintf("%d/%d", stat_secrets_found, stat_secrets_total);
		pos = MapStats_DrawKeyValue(pos, _("Secrets found:"), val);
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}


vector Scoreboard_Rankings_Draw(vector pos, entity pl, vector rgb, vector bg_size)
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
	drawstring(pos + eX * panel_bg_padding, ((ISGAMETYPE(CTF)) ? _("Capture time rankings") : _("Rankings")), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if(panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;

	float namesize = 0;
	for(i = 0; i < RANKINGS_RECEIVED_CNT; ++i)
	{
		float f = stringwidth(ColorTranslateRGB(grecordholder[i]), true, hud_fontsize);
		if(f > namesize)
			namesize = f;
	}
	bool cut = false;
	if(namesize > autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x)
	{
		namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
		cut = true;
	}

	float ranksize = 3 * hud_fontsize.x;
	float timesize = 5 * hud_fontsize.x;
	vector columnsize = vec2(ranksize + timesize + namesize + hud_fontsize.x, 1.25 * hud_fontsize.y);
	int columns = max(1, floor((panel_size.x - 2 * panel_bg_padding) / columnsize.x));
	columns = min(columns, RANKINGS_RECEIVED_CNT);

	// expand name column to fill the entire row
	float available_space = (panel_size.x - 2 * panel_bg_padding - columnsize.x * columns) / columns;
	namesize += available_space;
	columnsize.x += available_space;

	panel_size.y = ceil(RANKINGS_RECEIVED_CNT / columns) * 1.25 * hud_fontsize.y;
	panel_size.y += panel_bg_padding * 2;

	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + hud_fontsize.y);
	if(panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, panel_size, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	vector text_ofs = vec2(0.5 * hud_fontsize.x, (1.25 - 1) / 2 * hud_fontsize.y); // center text vertically
	string str = "";
	int column = 0, j = 0;
	string zoned_name_self = strzone(strdecolorize(entcs_GetName(player_localnum)));
	for(i = 0; i < RANKINGS_RECEIVED_CNT; ++i)
	{
		float t;
		t = grecordtime[i];
		if (t == 0)
			continue;

		if(strdecolorize(grecordholder[i]) == zoned_name_self)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
		else if(!((j + column) & 1) && sbt_highlight)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

		str = count_ordinal(i+1);
		drawstring(pos + text_ofs, str, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + text_ofs + eX * ranksize, TIME_ENCODED_TOSTRING(t), hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		str = ColorTranslateRGB(grecordholder[i]);
		if(cut)
			str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		drawcolorcodedstring(pos + text_ofs + eX * (ranksize + timesize), str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);

		pos.y += 1.25 * hud_fontsize.y;
		j++;
		if(j >= ceil(RANKINGS_RECEIVED_CNT / columns))
		{
			column++;
			j = 0;
			pos.x += panel_size.x / columns;
			pos.y = panel_pos.y;
		}
	}
	strfree(zoned_name_self);

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

float scoreboard_time;
bool have_weapon_stats;
bool Scoreboard_AccuracyStats_WouldDraw(float ypos)
{
	if (ISGAMETYPE(CTS) || ISGAMETYPE(RACE) || ISGAMETYPE(NEXBALL))
		return false;
	if (!autocvar_hud_panel_scoreboard_accuracy || warmup_stage || ypos > 0.91 * vid_conheight)
		return false;

	if (time < scoreboard_time + autocvar_hud_panel_scoreboard_accuracy_showdelay
		&& ypos > autocvar_hud_panel_scoreboard_accuracy_showdelay_minpos * vid_conheight
		&& !intermission)
	{
		return false;
	}

	if (!have_weapon_stats)
	{
		FOREACH(Weapons, it != WEP_Null, {
			int weapon_stats = weapon_accuracy[i - WEP_FIRST];
			if (weapon_stats >= 0)
			{
				have_weapon_stats = true;
				break;
			}
		});
		if (!have_weapon_stats)
			return false;
	}

	return true;
}

void Scoreboard_Draw()
{
	if(!autocvar__hud_configure)
	{
		if(!hud_draw_maximized) return;

		// frametime checks allow to toggle the scoreboard even when the game is paused
		if(scoreboard_active) {
			if (scoreboard_fade_alpha < 1)
				scoreboard_time = time;
			if(hud_configure_menu_open == 1)
				scoreboard_fade_alpha = 1;
			float scoreboard_fadeinspeed = autocvar_hud_panel_scoreboard_fadeinspeed;
			if (scoreboard_fadeinspeed && frametime)
				scoreboard_fade_alpha = min(1, scoreboard_fade_alpha + frametime * scoreboard_fadeinspeed);
			else
				scoreboard_fade_alpha = 1;
			if(hud_fontsize_str != autocvar_hud_fontsize)
			{
				hud_fontsize = HUD_GetFontsize("hud_fontsize");
				Scoreboard_initFieldSizes();
				strcpy(hud_fontsize_str, autocvar_hud_fontsize);
			}
		}
		else {
			float scoreboard_fadeoutspeed = autocvar_hud_panel_scoreboard_fadeoutspeed;
			if (scoreboard_fadeoutspeed && frametime)
				scoreboard_fade_alpha = max(0, scoreboard_fade_alpha - frametime * scoreboard_fadeoutspeed);
			else
				scoreboard_fade_alpha = 0;
		}

		if (!scoreboard_fade_alpha)
		{
			scoreboard_acc_fade_alpha = 0;
			return;
		}
	}
	else
		scoreboard_fade_alpha = 0;

	if (autocvar_hud_panel_scoreboard_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	if(scoreboard_fade_alpha <= 0)
		return;
	panel_fade_alpha *= scoreboard_fade_alpha;
	HUD_Panel_LoadCvars();

	sbt_bg_alpha = autocvar_hud_panel_scoreboard_table_bg_alpha * panel_fg_alpha;
	sbt_highlight = autocvar_hud_panel_scoreboard_table_highlight;
	sbt_highlight_alpha = autocvar_hud_panel_scoreboard_table_highlight_alpha * panel_fg_alpha;
	sbt_highlight_alpha_self = autocvar_hud_panel_scoreboard_table_highlight_alpha_self * panel_fg_alpha;
	sbt_fg_alpha = autocvar_hud_panel_scoreboard_table_fg_alpha * panel_fg_alpha;
	sbt_fg_alpha_self = autocvar_hud_panel_scoreboard_table_fg_alpha_self * panel_fg_alpha;

	// don't overlap with con_notify
	if(!autocvar__hud_configure)
		panel_pos.y = max((autocvar_con_notify * autocvar_con_notifysize), panel_pos.y);

	float excess = max(0, max_namesize - autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x);
	float fixed_scoreboard_width = bound(vid_conwidth * autocvar_hud_panel_scoreboard_minwidth, vid_conwidth - excess, vid_conwidth * 0.93);
	panel_pos.x = 0.5 * (vid_conwidth - fixed_scoreboard_width);
	panel_size.x = fixed_scoreboard_width;

	Scoreboard_UpdatePlayerTeams();

	vector pos = panel_pos;
	entity pl, tm;
	string str;
	vector str_pos;

	// Heading
	vector sb_heading_fontsize;
	sb_heading_fontsize = hud_fontsize * 2;
	draw_beginBoldFont();
	drawstring(pos + eX * panel_bg_padding, _("Scoreboard"), sb_heading_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	draw_endBoldFont();

	pos.y += sb_heading_fontsize.y;
	if(panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	// Draw the scoreboard
	float scale = autocvar_hud_panel_scoreboard_table_bg_scale;
	if(scale <= 0)
		scale = 0.25;
	vector bg_size = draw_getimagesize("gfx/scoreboard/scoreboard_bg") * scale;

	if(teamplay)
	{
		vector panel_bg_color_save = panel_bg_color;
		vector team_score_baseoffset = eY * hud_fontsize.y - eX * hud_fontsize.x * 0.5;
		if(panel.current_panel_bg != "0")
			team_score_baseoffset.x -= panel_bg_border;
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == NUM_SPECTATOR)
				continue;
			if(!tm.team)
				continue;

			draw_beginBoldFont();
			vector rgb = Team_ColorRGB(tm.team);
			str = ftos(tm.(teamscores(ts_primary)));
			str_pos = pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize * 1.5);
			drawstring(str_pos, str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

			if(ts_primary != ts_secondary)
			{
				str = ftos(tm.(teamscores(ts_secondary)));
				str_pos = pos + team_score_baseoffset - vec2(stringwidth(str, false, hud_fontsize), hud_fontsize.y * 1.5);
				drawstring(str_pos, str, hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			draw_endBoldFont();
			if(autocvar_hud_panel_scoreboard_bg_teams_color_team > 0)
				panel_bg_color = rgb * autocvar_hud_panel_scoreboard_bg_teams_color_team;
			else if(panel_bg_color_team > 0)
				panel_bg_color = rgb * panel_bg_color_team;
			else
				panel_bg_color = rgb;
			pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
		}
		panel_bg_color = panel_bg_color_save;
	}
	else
	{
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
			if(tm.team != NUM_SPECTATOR)
				break;
		// display it anyway
		pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
	}

	if (Scoreboard_AccuracyStats_WouldDraw(pos.y))
		pos = Scoreboard_AccuracyStats_Draw(pos, panel_bg_color, bg_size);

	if(ISGAMETYPE(CTS) || ISGAMETYPE(RACE) || (autocvar_hud_panel_scoreboard_ctf_leaderboard && ISGAMETYPE(CTF) && STAT(CTF_SHOWLEADERBOARD))) {
		if(race_speedaward) {
			drawcolorcodedstring(pos, sprintf(_("Speed award: %d%s ^7(%s^7)"), race_speedaward, race_speedaward_unit, ColorTranslateRGB(race_speedaward_holder)), hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		if(race_speedaward_alltimebest) {
			drawcolorcodedstring(pos, sprintf(_("All-time fastest: %d%s ^7(%s^7)"), race_speedaward_alltimebest, race_speedaward_alltimebest_unit, ColorTranslateRGB(race_speedaward_alltimebest_holder)), hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y;
		}
		pos = Scoreboard_Rankings_Draw(pos, playerslots[player_localnum], panel_bg_color, bg_size);
	}

	pos = Scoreboard_MapStats_Draw(pos, panel_bg_color, bg_size);

	// List spectators
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team == NUM_SPECTATOR)
		{
			for(tm = teams.sort_next; tm; tm = tm.sort_next)
				if(tm.team == NUM_SPECTATOR)
					break;
			str = sprintf("%s (%d)", _("Spectators"), tm.team_size);
			draw_beginBoldFont();
			drawstring(pos, str, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			draw_endBoldFont();
			pos.y += 1.25 * hud_fontsize.y;

			pos = Scoreboard_DrawOthers(pos, '0 0 0', pl.team, NULL, pl, 0);
			pos.y += 1.25 * hud_fontsize.y;

			break;
		}
	}

	// Print info string
	float tl, fl, ll;
	str = sprintf(_("playing ^3%s^7 on ^2%s^7"), MapInfo_Type_ToText(gametype), shortmapname);
	tl = STAT(TIMELIMIT);
	fl = STAT(FRAGLIMIT);
	ll = STAT(LEADLIMIT);
	if(ISGAMETYPE(LMS))
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
				str = strcat(str, sprintf(_(" until ^3%s %s^7"), ScoreString(teamscores_flags(ts_primary), fl),
					(teamscores_label(ts_primary) == "score")   ? CTX(_("SCO^points")) :
					(teamscores_label(ts_primary) == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(teamscores_label(ts_primary))));
			}
			else
			{
				str = strcat(str, sprintf(_(" until ^3%s %s^7"), ScoreString(scores_flags(ps_primary), fl),
					(scores_label(ps_primary) == "score")   ? CTX(_("SCO^points")) :
					(scores_label(ps_primary) == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(scores_label(ps_primary))));
			}
		}
		if(ll > 0)
		{
			if(tl > 0 || fl > 0)
				str = strcat(str, _(" or"));
			if(teamplay)
			{
				str = strcat(str, sprintf(_(" until a lead of ^3%s %s^7"), ScoreString(teamscores_flags(ts_primary), ll),
					(teamscores_label(ts_primary) == "score")   ? CTX(_("SCO^points")) :
					(teamscores_label(ts_primary) == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(teamscores_label(ts_primary))));
			}
			else
			{
				str = strcat(str, sprintf(_(" until a lead of ^3%s %s^7"), ScoreString(scores_flags(ps_primary), ll),
					(scores_label(ps_primary) == "score")   ? CTX(_("SCO^points")) :
					(scores_label(ps_primary) == "fastest") ? CTX(_("SCO^is beaten")) :
					TranslateScoresLabel(scores_label(ps_primary))));
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

			if(respawn_time < time) // it happens for a few frames when server is respawning the player
				str = ""; // draw an empty string to not change suddenly scoreboard_bottom
			else
				str = sprintf(_("^1Respawning in ^3%s^1..."),
					(autocvar_hud_panel_scoreboard_respawntime_decimals ?
						count_seconds_decs(respawn_time - time, autocvar_hud_panel_scoreboard_respawntime_decimals)
						:
						count_seconds(ceil(respawn_time - time))
					)
				);
		}
		else if(time < respawn_time)
		{
			str = sprintf(_("You are dead, wait ^3%s^7 before respawning"),
				(autocvar_hud_panel_scoreboard_respawntime_decimals ?
					count_seconds_decs(respawn_time - time, autocvar_hud_panel_scoreboard_respawntime_decimals)
					:
					count_seconds(ceil(respawn_time - time))
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
