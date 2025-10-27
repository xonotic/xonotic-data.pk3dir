#include "scoreboard.qh"

#include <client/csqcmodel_hooks.qh>
#include <client/draw.qh>
#include <client/hud/panel/chat.qh>
#include <client/hud/panel/physics.qh>
#include <client/hud/panel/quickmenu.qh>
#include <client/hud/panel/racetimer.qh>
#include <client/hud/panel/weapons.qh>
#include <common/constants.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/net_linked.qh>
#include <common/scores.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/items/inventory.qh>

// Scoreboard (#24)

void Scoreboard_Draw_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_scoreboard_fadeinspeed");
	HUD_Write_Cvar("hud_panel_scoreboard_fadeoutspeed");
	HUD_Write_Cvar("hud_panel_scoreboard_respawntime_decimals");
	HUD_Write_Cvar("hud_panel_scoreboard_table_bg_alpha");
	HUD_Write_Cvar("hud_panel_scoreboard_table_bg_scale");
	HUD_Write_Cvar("hud_panel_scoreboard_table_fg_alpha");
	HUD_Write_Cvar("hud_panel_scoreboard_table_fg_alpha_self");
	HUD_Write_Cvar("hud_panel_scoreboard_table_highlight");
	HUD_Write_Cvar("hud_panel_scoreboard_table_highlight_alpha");
	HUD_Write_Cvar("hud_panel_scoreboard_table_highlight_alpha_self");
	HUD_Write_Cvar("hud_panel_scoreboard_table_highlight_alpha_eliminated");
	HUD_Write_Cvar("hud_panel_scoreboard_bg_teams_color_team");
	HUD_Write_Cvar("hud_panel_scoreboard_accuracy_doublerows");
	HUD_Write_Cvar("hud_panel_scoreboard_accuracy_nocolors");
	HUD_Write_Cvar("hud_panel_scoreboard_spectators_position");
}

const int MAX_SBT_FIELDS = MAX_SCORE;

PlayerScoreField sbt_field[MAX_SBT_FIELDS + 1];
float sbt_field_size[MAX_SBT_FIELDS + 1];
string sbt_field_title[MAX_SBT_FIELDS + 1];
float sbt_field_title_condense_factor[MAX_SBT_FIELDS + 1];
float sbt_field_title_width[MAX_SBT_FIELDS + 1];
int sbt_num_fields;
float sbt_field_title_maxwidth;
float sbt_field_title_maxwidth_factor;

string autocvar_hud_fontsize;
float max_namesize;
float name_field_index;
int sb_field_sizes_init;

float sbt_bg_alpha;
float sbt_fg_alpha;
float sbt_fg_alpha_self;
bool sbt_highlight;
float sbt_highlight_alpha;
float sbt_highlight_alpha_self;
float sbt_highlight_alpha_eliminated;

float autocvar_hud_panel_scoreboard_fadeinspeed = 10;
float autocvar_hud_panel_scoreboard_fadeoutspeed = 5;
float autocvar_hud_panel_scoreboard_respawntime_decimals = 1;
float autocvar_hud_panel_scoreboard_table_bg_alpha = 0;
float autocvar_hud_panel_scoreboard_table_bg_scale = 0.25;
float autocvar_hud_panel_scoreboard_table_fg_alpha = 0.9;
float autocvar_hud_panel_scoreboard_table_fg_alpha_self = 1;
float autocvar_hud_panel_scoreboard_table_fieldtitle_maxwidth = 0.07;
bool autocvar_hud_panel_scoreboard_table_highlight = true;
float autocvar_hud_panel_scoreboard_table_highlight_alpha = 0.2;
float autocvar_hud_panel_scoreboard_table_highlight_alpha_self = 0.4;
float autocvar_hud_panel_scoreboard_table_highlight_alpha_eliminated = 0.6;
float autocvar_hud_panel_scoreboard_bg_teams_color_team = 0;
float autocvar_hud_panel_scoreboard_team_size_position = 0;
float autocvar_hud_panel_scoreboard_spectators_position = 1;

bool autocvar_hud_panel_scoreboard_accuracy = true;
bool autocvar_hud_panel_scoreboard_accuracy_doublerows = false;
bool autocvar_hud_panel_scoreboard_accuracy_nocolors = false;
float autocvar_hud_panel_scoreboard_accuracy_showdelay = 2;
float autocvar_hud_panel_scoreboard_accuracy_showdelay_minpos = 0.75;

bool autocvar_hud_panel_scoreboard_itemstats = true;
bool autocvar_hud_panel_scoreboard_itemstats_doublerows = false;
int autocvar_hud_panel_scoreboard_itemstats_filter = 1;
int autocvar_hud_panel_scoreboard_itemstats_filter_mask = 12;
float autocvar_hud_panel_scoreboard_itemstats_showdelay = 2.2; // slightly more delayed than accuracy
float autocvar_hud_panel_scoreboard_itemstats_showdelay_minpos = 0.75;

bool autocvar_hud_panel_scoreboard_dynamichud = false;

float autocvar_hud_panel_scoreboard_maxheight = 0.6;
bool autocvar_hud_panel_scoreboard_others_showscore = true;
bool autocvar_hud_panel_scoreboard_spectators_showping = true;
bool autocvar_hud_panel_scoreboard_spectators_aligned = false;
float autocvar_hud_panel_scoreboard_minwidth = 0.4;
bool autocvar_hud_panel_scoreboard_playerid = false;
string autocvar_hud_panel_scoreboard_playerid_prefix = "#";
string autocvar_hud_panel_scoreboard_playerid_suffix = " ";
bool autocvar_hud_panel_scoreboard_scores_per_round;

float scoreboard_time;

SHUTDOWN(scoreboard)
{
	if (autocvar_hud_panel_scoreboard_scores_per_round)
		cvar_set("hud_panel_scoreboard_scores_per_round", "0");
}

// mode 0: returns translated label
// mode 1: prints name and description of all the labels
string Label_getInfo(string label, int mode)
{
	if (mode == 1)
		label = "bckills"; // first case in the switch

#define SCO_LABEL(strlabel, label, padding, help) \
	case label: \
		if (!mode) \
			return CTX(strlabel); \
		LOG_HELP("^3", label, padding, "^7", help);

	switch (label)
	{
		SCO_LABEL(_("SCO^bckills"),       "bckills", "            ", _("Number of ball carrier kills"));
		SCO_LABEL(_("SCO^bctime"),        "bctime", "             ", _("Total amount of time holding the ball in Keepaway"));
		SCO_LABEL(_("SCO^caps"),          "caps", "               ", _("How often a flag (CTF) or a key (Key Hunt) was captured"));
		SCO_LABEL(_("SCO^captime"),       "captime", "            ", _("Time of fastest capture (CTF)"));
		SCO_LABEL(_("SCO^deaths"),        "deaths", "             ", _("Number of deaths"));
		SCO_LABEL(_("SCO^destructions"),  "destructions", "       ", _("Number of keys destroyed by pushing them into void"));
		SCO_LABEL(_("SCO^damage dealt"),  "dmg", "                ", _("The total damage dealt"));
		SCO_LABEL(_("SCO^damage taken"),  "dmgtaken", "           ", _("The total damage taken"));
		SCO_LABEL(_("SCO^drops"),         "drops", "              ", _("Number of flag drops"));
		SCO_LABEL(_("SCO^fastest"),       "fastest", "            ", _("Time of fastest lap (Race/CTS)"));
		SCO_LABEL(_("SCO^faults"),        "faults", "             ", _("Number of faults committed"));
		SCO_LABEL(_("SCO^fckills"),       "fckills", "            ", _("Number of flag carrier kills"));
		SCO_LABEL(_("SCO^fps"),           "fps", "                ", _("FPS"));
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
		SCO_LABEL(_("SCO^pushes"),        "pushes", "             ", _("Number of players pushed into void"));
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
	}
	return label;
#undef SCO_LABEL
}

bool scoreboard_ui_disabling;
void HUD_Scoreboard_UI_Disable()
{
	scoreboard_ui_disabling = true;
	sb_showscores = false;
}

void HUD_Scoreboard_UI_Disable_Instantly()
{
	scoreboard_ui_disabling = false;
	scoreboard_ui_enabled = 0;
	scoreboard_selected_panel = 0;
	scoreboard_selected_player = NULL;
	scoreboard_selected_team = NULL;
}

// mode: 0 normal, 1 team selection
void Scoreboard_UI_Enable(int mode)
{
	if (isdemo())
		return;

	if (mode == 1)
	{
		if (scoreboard_ui_enabled == 2 || !teamplay || intermission)
			return;

		// release player's pressed keys as they aren't released elsewhere
		// in particular jump needs to be released as it may open the team selection
		// (when server detects jump has been pressed it sends the command to open the team selection)
		Release_Common_Keys();
		scoreboard_ui_enabled = 2;
		scoreboard_selected_panel = SB_PANEL_SCOREBOARD;
	}
	else
	{
		if (scoreboard_ui_enabled == 1)
			return;
		scoreboard_ui_enabled = 1;
		scoreboard_selected_panel = SB_PANEL_FIRST;
	}
	scoreboard_selected_player = NULL;
	scoreboard_selected_team = NULL;
	scoreboard_selected_panel_time = time;
}

int rankings_start_column;
int rankings_rows = 0;
int rankings_columns = 0;
int rankings_cnt = 0;
float HUD_Scoreboard_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	string s;

	if(!scoreboard_ui_enabled || scoreboard_ui_disabling)
		return false;

	if(bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		return true;
	}

	if(bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	// ESC to exit (TAB-ESC works too)
	if(nPrimary == K_ESCAPE)
	{
		if (!key_pressed)
			return true;
		HUD_Scoreboard_UI_Disable();
		return true;
	}

	// block any input while a menu dialog is fading
	if(autocvar__menu_alpha)
	{
		hudShiftState = 0;
		return true;
	}

	// allow console bind to work
	string con_keys = findkeysforcommand("toggleconsole", 0);
	int keys = tokenize(con_keys); // findkeysforcommand returns data for this

	bool hit_con_bind = false;
	int i;
	for (i = 0; i < keys; ++i)
	{
		if(nPrimary == stof(argv(i)))
			hit_con_bind = true;
	}

	if(key_pressed) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
		if(nPrimary == K_TAB) hudShiftState |= S_TAB;
	}
	else {
		if(nPrimary == K_ALT) hudShiftState &= ~S_ALT;
		if(nPrimary == K_CTRL) hudShiftState &= ~S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState &= ~S_SHIFT;
		if(nPrimary == K_TAB) hudShiftState &= ~S_TAB;
	}

	if(nPrimary == K_TAB)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_ui_enabled == 2)
		{
			if (hudShiftState & S_SHIFT)
				goto uparrow_action;
			else
				goto downarrow_action;
		}

		if (hudShiftState & S_SHIFT)
		{
			--scoreboard_selected_panel;
			if (scoreboard_selected_panel == SB_PANEL_RANKINGS && !rankings_cnt)
				--scoreboard_selected_panel;
			if (scoreboard_selected_panel < SB_PANEL_FIRST)
				scoreboard_selected_panel = SB_PANEL_MAX;
		}
		else
		{
			++scoreboard_selected_panel;
			if (scoreboard_selected_panel == SB_PANEL_RANKINGS && !rankings_cnt)
				++scoreboard_selected_panel;
			if (scoreboard_selected_panel > SB_PANEL_MAX)
				scoreboard_selected_panel = SB_PANEL_FIRST;
		}

		scoreboard_selected_panel_time = time;
	}
	else if(nPrimary == K_DOWNARROW)
	{
		if (!key_pressed)
			return true;
		LABEL(downarrow_action);
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_ui_enabled == 2)
			{
				entity curr_team = NULL;
				bool scoreboard_selected_team_found = false;
				if (!scoreboard_selected_team)
					scoreboard_selected_team_found = true;

				for(entity tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if(tm.team == NUM_SPECTATOR)
						continue;
					curr_team = tm;
					if (scoreboard_selected_team_found)
						goto ok_team;
					if (scoreboard_selected_team == tm)
						scoreboard_selected_team_found = true;
				}
				LABEL(ok_team);
				if (curr_team == scoreboard_selected_team) // loop reached the last team
					curr_team = NULL;
				scoreboard_selected_team = curr_team;
			}
			else
			{
				entity pl, tm;
				entity curr_pl = NULL;
				bool scoreboard_selected_player_found = false;
				if (!scoreboard_selected_player)
					scoreboard_selected_player_found = true;

				for(tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if(tm.team != NUM_SPECTATOR)
					for(pl = players.sort_next; pl; pl = pl.sort_next)
					{
						if(pl.team != tm.team)
							continue;
						curr_pl = pl;
						if (scoreboard_selected_player_found)
							goto ok_done;
						if (scoreboard_selected_player == pl)
							scoreboard_selected_player_found = true;
					}
				}
				LABEL(ok_done);
				if (curr_pl == scoreboard_selected_player) // loop reached the last player
					curr_pl = NULL;
				scoreboard_selected_player = curr_pl;
			}
		}
	}
	else if(nPrimary == K_UPARROW)
	{
		if (!key_pressed)
			return true;
		LABEL(uparrow_action);
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_ui_enabled == 2)
			{
				entity prev_team = NULL;
				for(entity tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if(tm.team == NUM_SPECTATOR)
						continue;
					if (tm == scoreboard_selected_team)
						goto ok_team2;
					prev_team = tm;
				}
				LABEL(ok_team2);
				scoreboard_selected_team = prev_team;
			}
			else
			{
				entity prev_pl = NULL;
				entity pl, tm;
				for(tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if(tm.team != NUM_SPECTATOR)
					for(pl = players.sort_next; pl; pl = pl.sort_next)
					{
						if(pl.team != tm.team)
							continue;
						if (pl == scoreboard_selected_player)
							goto ok_done2;
						prev_pl = pl;
					}
				}
				LABEL(ok_done2);
				scoreboard_selected_player = prev_pl;
			}
		}
	}
	else if(nPrimary == K_RIGHTARROW)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
			rankings_start_column = min(rankings_start_column + 1, (ceil(RANKINGS_RECEIVED_CNT / rankings_rows) - rankings_columns));
	}
	else if(nPrimary == K_LEFTARROW)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
			rankings_start_column = max(rankings_start_column - 1, 0);
	}
	else if(nPrimary == K_ENTER || nPrimary == K_SPACE || nPrimary == K_KP_ENTER)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_ui_enabled == 2)
			{
				string team_name;
				if (!scoreboard_selected_team || (hudShiftState & S_SHIFT))
					team_name = "auto";
				else
					team_name = Static_Team_ColorName(scoreboard_selected_team.team);
				localcmd(sprintf("cmd selectteam %s; cmd join\n", team_name));
				HUD_Scoreboard_UI_Disable();
			}
			else if (scoreboard_selected_player)
				localcmd(sprintf("spectate %d\n", scoreboard_selected_player.sv_entnum + 1));
		}
	}
	else if(nPrimary == 'c' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_ui_enabled == 1 && scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			switch (scoreboard_selected_columns_layout)
			{
				case 0:
					if (autocvar_scoreboard_columns != "" && autocvar_scoreboard_columns != "all" && autocvar_scoreboard_columns != "default")
					{
						localcmd(sprintf("scoreboard_columns_set\n")); // sets the layout saved in scoreboard_columns
						scoreboard_selected_columns_layout = 1;
						break;
					}
					// fallthrough
				case 1:
					localcmd(sprintf("scoreboard_columns_set default\n"));
					scoreboard_selected_columns_layout = 2;
					break;
				case 2:
					localcmd(sprintf("scoreboard_columns_set all\n"));
					scoreboard_selected_columns_layout = 0;
					break;
			}
		}
	}
	else if(nPrimary == 'r' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
			localcmd("toggle hud_panel_scoreboard_scores_per_round\n");
	}
	else if(nPrimary == 't' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_selected_player)
			{
				localcmd(sprintf("commandmode tell \"%s^7\"\n", entcs_GetName(scoreboard_selected_player.sv_entnum)));
				HUD_Scoreboard_UI_Disable();
			}
		}
	}
	else if(nPrimary == 'k' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_selected_player)
				localcmd(sprintf("vcall kick \"%s^7\"\n", entcs_GetName(scoreboard_selected_player.sv_entnum)));
		}
	}
	else if(hit_con_bind || nPrimary == K_PAUSE)
		return false;

	return true;
}

void PrintScoresLabels() { Label_getInfo(string_null, 1); }
string TranslateScoresLabel(string label) { return Label_getInfo(label, 0); }

void Scoreboard_InitScores()
{
	int i, f;

	ps_primary = ps_secondary = NULL;
	ts_primary = ts_secondary = -1;
	FOREACH(Scores, true, {
		if (scores_flags(it) & SFL_NOT_SORTABLE)
			continue;
		f = (scores_flags(it) & SFL_SORT_PRIO_MASK);
		if (f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = it;
		if (f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = it;
	});
	if (ps_secondary == NULL)
		ps_secondary = ps_primary;

	for (i = 0; i < MAX_TEAMSCORE; ++i)
	{
		f = (teamscores_flags(i) & SFL_SORT_PRIO_MASK);
		if (f == SFL_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if (f == SFL_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if (ts_secondary == -1)
		ts_secondary = ts_primary;

	Cmd_Scoreboard_SetFields(0);
}

//float lastpnum;
void Scoreboard_UpdatePlayerTeams()
{
	static float update_time;
	if (time <= update_time)
		return;
	update_time = time;

	entity pl, tmp;
	numplayers = 0;
	//int num = 0;
	for (pl = players.sort_next; pl; pl = pl.sort_next)
	{
		numplayers += pl.team != NUM_SPECTATOR;
		//num += 1;
		int Team = entcs_GetScoreTeam(pl.sv_entnum);
		if (SetTeam(pl, Team))
		{
			tmp = pl.sort_prev;
			Scoreboard_UpdatePlayerPos(pl);
			if (tmp)
				pl = tmp;
			else
				pl = players.sort_next;
		}
	}
	/*
	if (num != lastpnum)
		print(strcat("PNUM: ", ftos(num), "\n"));
	lastpnum = num;
	*/

	// update the smallest and largest team sizes
	if (!teamplay || !teams.sort_next)
		ts_min = ts_max = 0;
	else
	{
		ts_min = 255, ts_max = 0;

		for (entity tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if (tm.team == NUM_SPECTATOR)
				continue;

			if (ts_min > tm.team_size)
				ts_min = tm.team_size;
			if (ts_max < tm.team_size)
				ts_max = tm.team_size;
		}
	}
}

int Scoreboard_CompareScore(int vl, int vr, int f)
{
	TC(int, vl); TC(int, vr); TC(int, f);
	if (f & SFL_ZERO_IS_WORST)
	{
		if (vl == 0 && vr != 0)
			return 1;
		if (vl != 0 && vr == 0)
			return 0;
	}
	if (vl > vr)
		return IS_INCREASING(f);
	if (vl < vr)
		return IS_DECREASING(f);
	return -1;
}

float Scoreboard_ComparePlayerScores(entity left, entity right)
{
	int vl = (left.gotscores) ? entcs_GetTeam(left.sv_entnum) : NUM_SPECTATOR;
	int vr = (right.gotscores) ? entcs_GetTeam(right.sv_entnum) : NUM_SPECTATOR;

	if (vl > vr)
		return true;
	if (vl < vr)
		return false;

	if (vl == NUM_SPECTATOR)
	{
		// FIRST the one with scores (spectators), THEN the ones without (downloaders)
		// no other sorting
		if (!left.gotscores && right.gotscores)
			return true;
		return false;
	}

	int res = Scoreboard_CompareScore(left.scores(ps_primary), right.scores(ps_primary), scores_flags(ps_primary));
	if (res >= 0)
		return res;

	if (ps_secondary && ps_secondary != ps_primary)
	{
		res = Scoreboard_CompareScore(left.scores(ps_secondary), right.scores(ps_secondary), scores_flags(ps_secondary));
		if (res >= 0)
			return res;
	}

	FOREACH(Scores, (it != ps_primary && it != ps_secondary), {
		res = Scoreboard_CompareScore(left.scores(it), right.scores(it), scores_flags(it));
		if (res >= 0)
			return res;
	});

	if (left.sv_entnum < right.sv_entnum)
		return true;

	return false;
}

void Scoreboard_UpdatePlayerPos(entity player)
{
	entity ent;
	for (ent = player.sort_next; ent && Scoreboard_ComparePlayerScores(player, ent); ent = player.sort_next)
		SORT_SWAP(player, ent);
	for (ent = player.sort_prev; ent != players && Scoreboard_ComparePlayerScores(ent, player); ent = player.sort_prev)
		SORT_SWAP(ent, player);
}

float Scoreboard_CompareTeamScores(entity left, entity right)
{
	if (left.team == NUM_SPECTATOR)
		return 1;
	if (right.team == NUM_SPECTATOR)
		return 0;

	int fld_idx = -1;
	int r;
	for (int i = -2; i < MAX_TEAMSCORE; ++i)
	{
		if (i < 0)
		{
			if (fld_idx == -1)
				fld_idx = ts_primary;
			else if (ts_secondary == ts_primary)
				continue;
			else
				fld_idx = ts_secondary;
		}
		else
		{
			fld_idx = i;
			if (fld_idx == ts_primary || fld_idx == ts_secondary)
				continue;
		}

		r = Scoreboard_CompareScore(left.teamscores(fld_idx), right.teamscores(fld_idx), teamscores_flags(fld_idx));
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
	for (ent = Team.sort_next; ent && Scoreboard_CompareTeamScores(Team, ent); ent = Team.sort_next)
		SORT_SWAP(Team, ent);
	for (ent = Team.sort_prev; ent != teams && Scoreboard_CompareTeamScores(ent, Team); ent = Team.sort_prev)
		SORT_SWAP(ent, Team);
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
	int i, slash;
	string str, pattern;
	bool have_name = false, have_primary = false, have_secondary = false, have_separator = false;
	int missing;

	if (!gametype)
		return; // do nothing, we don't know gametype and scores yet

	// sbt_fields uses strunzone on the titles!
	if (!sbt_field_title[0])
		for (i = 0; i < MAX_SBT_FIELDS; ++i)
			sbt_field_title[i] = strzone("(null)");

	// TODO: re enable with gametype dependant cvars?
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
			FOREACH(Scores, true, {
				if (it != ps_primary)
				if (it != ps_secondary)
				if (scores_label(it) != "")
					s = strcat(s, " ", scores_label(it));
			});
			if (ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label(ps_secondary));
			s = strcat(s, " ", scores_label(ps_primary));
			argc = tokenizebyseparator(strcat("0 1 ", s), " ");
		}
	}


	sbt_num_fields = 0;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	for (i = 1; i < argc - 1; ++i)
	{
		str = argv(i+1);
		bool nocomplain = false;
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
		switch(str)
		{
			// fields without a label (not networked via the score system)
			case "ping": sbt_field[sbt_num_fields] = SP_PING; break;
			case "pl": sbt_field[sbt_num_fields] = SP_PL; break;
			case "name": case "nick": sbt_field[sbt_num_fields] = SP_NAME; have_name = true; break;
			case "|": sbt_field[sbt_num_fields] = SP_SEPARATOR; have_separator = true; break;
			case "kd": case "kdr": case "kdratio": sbt_field[sbt_num_fields] = SP_KDRATIO; break;
			case "sum": case "diff": case "k-d": sbt_field[sbt_num_fields] = SP_SUM; break;
			case "frags": sbt_field[sbt_num_fields] = SP_FRAGS; break;
			default: // fields with a label
			{
				// map alternative labels
				if (str == "damage") str = "dmg";
				if (str == "damagetaken") str = "dmgtaken";

				FOREACH(Scores, true, {
					if (str == strtolower(scores_label(it)))
					{
						j = it;
						goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
					}
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
		if(sbt_num_fields >= MAX_SBT_FIELDS)
			break;
	}

	if (scores_flags(ps_primary) & SFL_ALLOW_HIDE)
		have_primary = true;
	if (scores_flags(ps_secondary) & SFL_ALLOW_HIDE)
		have_secondary = true;
	if (ps_primary == ps_secondary)
		have_secondary = true;
	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

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

string Scoreboard_AddPlayerId(string pl_name, entity pl)
{
	string pref = autocvar_hud_panel_scoreboard_playerid_prefix;
	string suf = autocvar_hud_panel_scoreboard_playerid_suffix;
	return strcat(pref, itos(pl.sv_entnum + 1), suf, pl_name);
}

// MOVEUP::
vector sbt_field_rgb;
// these are drawn overlapping
string sbt_field_icon_playercolor[3];
vector sbt_field_icon_playercolor_rgb[3];
// these are drawn side-by-side, next to playercolor (if present)
// 0: player_ready, 1: player_handicap
string sbt_field_icon_extra[2];
vector sbt_field_icon_extra_rgb[2];
string Scoreboard_GetName(entity pl)
{
	if (!teamplay)
	{
		int f;
		// NOTE: always adding 1024 allows saving the colormap 0 as a value != 0
		if (playerslots[pl.sv_entnum].colormap >= 1024)
			f = playerslots[pl.sv_entnum].colormap - 1024; // override server-side player colors
		else
			f = entcs_GetClientColors(pl.sv_entnum);

		sbt_field_icon_playercolor[0] = "gfx/scoreboard/playercolor_base";
		sbt_field_icon_playercolor[1] = "gfx/scoreboard/playercolor_shirt";
		sbt_field_icon_playercolor[2] = "gfx/scoreboard/playercolor_pants";
		sbt_field_icon_playercolor_rgb[2] = colormapPaletteColor(f % 16, 1);
		sbt_field_icon_playercolor_rgb[1] = colormapPaletteColor(floor(f / 16), 0);
		sbt_field_icon_playercolor_rgb[0] = sbt_field_icon_playercolor_rgb[1];
	}
	if (ready_waiting && pl.ready)
	{
		sbt_field_icon_extra[0] = "gfx/scoreboard/player_ready";
		sbt_field_icon_extra_rgb[0].y = 1;
		sbt_field_icon_extra_rgb[0].x = sbt_field_icon_extra_rgb[0].z = min(1, 1 + sin(2*M_PI*time));
	}
	int handicap_lvl = entcs_GetHandicapLevel(pl.sv_entnum);
	if (handicap_lvl != 0)
	{
		sbt_field_icon_extra[1] = "gfx/scoreboard/player_handicap";
		sbt_field_icon_extra_rgb[1] = '1 0 0' + '0 1 1' * ((16 - handicap_lvl) / 15);
		// goes from white to red over level 1 to 16
	}
	return entcs_GetName(pl.sv_entnum);
}

int autocvar_hud_panel_scoreboard_ping_low = 20;
int autocvar_hud_panel_scoreboard_ping_medium = 80;
int autocvar_hud_panel_scoreboard_ping_high = 200;
vector autocvar_hud_panel_scoreboard_ping_low_color = '0 1 0';
vector autocvar_hud_panel_scoreboard_ping_medium_color = '1 1 0';
vector autocvar_hud_panel_scoreboard_ping_high_color = '1 0 0';
#define PING_LOW autocvar_hud_panel_scoreboard_ping_low
#define PING_MED autocvar_hud_panel_scoreboard_ping_medium
#define PING_HIGH autocvar_hud_panel_scoreboard_ping_high
#define COLOR_LOW autocvar_hud_panel_scoreboard_ping_low_color
#define COLOR_MED autocvar_hud_panel_scoreboard_ping_medium_color
#define COLOR_HIGH autocvar_hud_panel_scoreboard_ping_high_color
string Scoreboard_GetField(entity pl, PlayerScoreField field, bool per_round)
{
	float tmp, num, denom;
	int f;
	string str;
	sbt_field_rgb = '1 1 1';
	sbt_field_icon_playercolor[0] = "";
	sbt_field_icon_playercolor[1] = "";
	sbt_field_icon_playercolor[2] = "";
	sbt_field_icon_playercolor_rgb[0] = '1 1 1';
	sbt_field_icon_playercolor_rgb[1] = '1 1 1';
	sbt_field_icon_playercolor_rgb[2] = '1 1 1';
	sbt_field_icon_extra[0] = "";
	sbt_field_icon_extra[1] = "";
	sbt_field_icon_extra_rgb[0] = '1 1 1';
	sbt_field_icon_extra_rgb[1] = '1 1 1';
	int rounds_played = 0;
	if (per_round)
		rounds_played = pl.(scores(SP_ROUNDS_PL));
	switch(field)
	{
		case SP_PING:
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
			f = pl.(scores(SP_KILLS));
			f -= pl.(scores(SP_SUICIDES));
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
			f = pl.(scores(SP_KILLS));
			f -= pl.(scores(SP_DEATHS));

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

float sbt_fixcolumnwidth_len;
float sbt_fixcolumnwidth_iconlen_playercolor;
float sbt_fixcolumnwidth_iconlen_extra[2];
float sbt_fixcolumnwidth_marginlen;

string Scoreboard_FixColumnWidth(int i, string str, bool init)
{
	TC(int, i);
	float f;
	vector sz;
	int j;

	sbt_fixcolumnwidth_iconlen_playercolor = 0;
	sbt_fixcolumnwidth_iconlen_extra[0] = 0;
	sbt_fixcolumnwidth_iconlen_extra[1] = 0;

	for (j = 0; j < 3; ++j)
		if (sbt_field_icon_playercolor[j] != "")
		{
			sz = draw_getimagesize(sbt_field_icon_playercolor[j]);
			f = sz.x / sz.y;
			if (sbt_fixcolumnwidth_iconlen_playercolor < f)
				sbt_fixcolumnwidth_iconlen_playercolor = f;
		}
	// NOTE: extra icons (player_ready and player_handicap) are squares (32x32), so this may not be necessary
	// simply setting sbt_fixcolumnwidth_iconlen_extra* = 1 would be equivalent
	for (j = 0; j < 2; ++j)
		if (sbt_field_icon_extra[j] != "")
		{
			sz = draw_getimagesize(sbt_field_icon_extra[j]);
			// XONRELEASE TODO: xonotic-v0.9.0 after release remove if (sz == 0) case
			if (sz == '0 0 0') // it happens in previous engine versions (Xonotic 0.8.6 or lower) when the image is missing
				sz = '1 1 0';
			sbt_fixcolumnwidth_iconlen_extra[j] = sz.x / sz.y;
		}

	if (sbt_fixcolumnwidth_iconlen_playercolor != 0)
		sbt_fixcolumnwidth_iconlen_playercolor *= hud_fontsize.y / hud_fontsize.x; // fix icon aspect
	for (j = 0; j < 2; ++j)
		if (sbt_fixcolumnwidth_iconlen_extra[j] != 0)
			sbt_fixcolumnwidth_iconlen_extra[j] *= hud_fontsize.y / hud_fontsize.x; // fix icon aspect

	if (sbt_fixcolumnwidth_iconlen_playercolor != 0
	||  sbt_fixcolumnwidth_iconlen_extra[0] != 0
	||  sbt_fixcolumnwidth_iconlen_extra[1] != 0)
		sbt_fixcolumnwidth_marginlen = stringwidth(" ", false, hud_fontsize);
	else
		sbt_fixcolumnwidth_marginlen = 0;

	if (init)
		sbt_field_title_width[i] = stringwidth(sbt_field_title[i], false, hud_fontsize);

	if (sbt_field[i] == SP_NAME) // name gets all remaining space
	{
		float used_space = 0;
		for (j = 0; j < sbt_num_fields; ++j)
			if (j != i)
				if (sbt_field[i] != SP_SEPARATOR)
					used_space += sbt_field_size[j] + hud_fontsize.x;
		sbt_field_size[i] = max(sbt_field_title_width[i], panel_size.x - used_space);

		used_space += sbt_fixcolumnwidth_marginlen
			+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor
			+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[0]
			+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[1];
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

	f = sbt_fixcolumnwidth_len + sbt_fixcolumnwidth_marginlen
		+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor
		+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[0]
		+ hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[1];
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

void Scoreboard_initFieldSizes(bool compress_more)
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

	// update name field size in the end as it takes remaining space
	Scoreboard_FixColumnWidth(name_field_index, "", true);
}

vector Scoreboard_DrawHeader(vector pos, vector rgb, bool other_players)
{
	int i;
	vector column_dim = eY * panel_size.y;
	if (other_players)
		column_dim.y -= 1.25 * hud_fontsize.y;
	vector text_offset = eY * (1.25 - 1) / 2 * hud_fontsize.y;
	pos.x += hud_fontsize.x * 0.5;
	for (i = 0; i < sbt_num_fields; ++i)
	{
		if (sbt_field[i] == SP_SEPARATOR)
			break;
		column_dim.x = sbt_field_size[i] + hud_fontsize.x;
		if (sbt_highlight)
			if (i % 2)
				drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);
		vector prev_drawfontscale = drawfontscale;
		if (sbt_field_title_condense_factor[i])
			drawfontscale.x *= sbt_field_title_condense_factor[i];
		drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
		if (sbt_field_title_condense_factor[i])
		{
			drawfontscale.x *= sbt_field_title_condense_factor[i];
			drawfontscale = prev_drawfontscale;
		}
		pos.x += column_dim.x;
	}

	if (sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = panel_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		for (i = sbt_num_fields - 1; i > 0; --i)
		{
			if (sbt_field[i] == SP_SEPARATOR)
				break;

			pos.x -= sbt_field_size[i];

			if (sbt_highlight)
				if (!(i % 2))
				{
					column_dim.x = sbt_field_size[i] + hud_fontsize.x;
					drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);
				}

			vector prev_drawfontscale = drawfontscale;
			float titlewidth = stringwidth(sbt_field_title[i], false, hud_fontsize);
			if (sbt_field_title_condense_factor[i])
			{
				drawfontscale.x *= sbt_field_title_condense_factor[i];
				text_offset.x = sbt_field_size[i] - titlewidth * sbt_field_title_condense_factor[i];
			}
			else
				text_offset.x = sbt_field_size[i] - titlewidth;
			drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
			if (sbt_field_title_condense_factor[i])
			{
				drawfontscale.x *= sbt_field_title_condense_factor[i];
				drawfontscale = prev_drawfontscale;
			}
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
	bool is_spec = (entcs_GetSpecState(pl.sv_entnum) == ENTCS_SPEC_PURE);

	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);
	// alternated rows highlighting
	if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD && scoreboard_ui_enabled == 1)
	{
		if (pl == scoreboard_selected_player)
			drawfill(h_pos, h_size, rgb, 0.44 * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if (is_self)
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if ((sbt_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	float fg_alpha = (is_self ? sbt_fg_alpha_self : sbt_fg_alpha);

	vector pos = item_pos;
	// put a "self indicator" beside the self row, unicode U+25C0 (black left-pointing triangle)
	if (is_self)
		drawstring(pos + eX * (panel_size.x + 0.5 * hud_fontsize.x) + eY, "\xE2\x97\x80", hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically
	vector tmp = '0 0 0';
	vector icon_sz;
	int i, j;
	PlayerScoreField field;
	for (i = 0; i < sbt_num_fields; ++i)
	{
		field = sbt_field[i];
		if (field == SP_SEPARATOR)
			break;

		if (is_spec && field != SP_NAME && field != SP_PING)
		{
			pos.x += sbt_field_size[i] + hud_fontsize.x;
			continue;
		}
		str = Scoreboard_GetField(pl, field, autocvar_hud_panel_scoreboard_scores_per_round);
		str = Scoreboard_FixColumnWidth(i, str, false);

		pos.x += sbt_field_size[i] + hud_fontsize.x;

		if (field == SP_NAME)
		{
			tmp.x = sbt_field_size[i] - sbt_fixcolumnwidth_marginlen + hud_fontsize.x
				- hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor
				- hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[0]
				- hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[1];
			if (teamplay)
			{
				int wants_join = entcs_GetWantsJoin(pl.sv_entnum);
				if (wants_join)
				{
					vector tmcolor = Team_ColorRGB(Team_IndexToTeam(wants_join)) * min(1, 1 + sin(2*M_PI*time));
					drawstring(pos - tmp, "(Q)", hud_fontsize, tmcolor, sbt_fg_alpha, DRAWFLAG_NORMAL);
					tmp.x -= stringwidth("(Q) ", true, hud_fontsize);
				}
			}
			drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);
		}
		else
		{
			tmp.x = sbt_fixcolumnwidth_len + hud_fontsize.x;
			drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
		}

		tmp.x = sbt_field_size[i] + hud_fontsize.x;
		icon_sz = vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor, hud_fontsize.y);
		for (j = 0; j < 3; ++j)
			if (sbt_field_icon_playercolor[j] != "")
				drawpic(pos - tmp, sbt_field_icon_playercolor[j], icon_sz, sbt_field_icon_playercolor_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
		for (j = 0; j < 2; ++j)
			if (sbt_field_icon_extra[j] != "")
			{
				tmp.x -= icon_sz.x;
				icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j];
				drawpic(pos - tmp, sbt_field_icon_extra[j], icon_sz, sbt_field_icon_extra_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
			}
	}

	if (sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = item_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		for (i = sbt_num_fields-1; i > 0; --i)
		{
			field = sbt_field[i];
			if (field == SP_SEPARATOR)
				break;

			if (is_spec && field != SP_NAME && field != SP_PING)
			{
				pos.x -= sbt_field_size[i] + hud_fontsize.x;
				continue;
			}

			str = Scoreboard_GetField(pl, field, autocvar_hud_panel_scoreboard_scores_per_round);
			str = Scoreboard_FixColumnWidth(i, str, false);

			if (field == SP_NAME)
			{
				tmp.x = sbt_fixcolumnwidth_len; // left or right aligned? let's put it right...
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);
			}
			else
			{
				tmp.x = sbt_fixcolumnwidth_len;
				drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
			}

			tmp.x = sbt_field_size[i];
			icon_sz = vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor, hud_fontsize.y);
			for (j = 0; j < 3; ++j)
				if (sbt_field_icon_playercolor[j] != "")
					drawpic(pos - tmp, sbt_field_icon_playercolor[j], icon_sz, sbt_field_icon_playercolor_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
			for (j = 0; j < 2; ++j)
				if (sbt_field_icon_extra[j] != "")
				{
					tmp.x -= icon_sz.x;
					icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j];
					drawpic(pos - tmp, sbt_field_icon_extra[j], icon_sz, sbt_field_icon_extra_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
				}
			pos.x -= sbt_field_size[i] + hud_fontsize.x;
		}
	}

	if (pl.eliminated)
		drawfill(h_pos, h_size, '0 0 0', sbt_highlight_alpha_eliminated, DRAWFLAG_NORMAL);
}

vector Scoreboard_DrawOthers(vector item_pos, vector rgb, int this_team, entity ignored_pl, entity pl, int pl_number)
{
	int i = 0;
	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);

	bool complete = (this_team == NUM_SPECTATOR);

	if (!complete)
	if ((sbt_highlight) && (!(pl_number % 2)))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	vector pos = item_pos;
	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically

	float width_limit = item_pos.x + panel_size.x - hud_fontsize.x;
	if (!complete)
		width_limit -= stringwidth("...", false, hud_fontsize);
	float namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
	static float max_name_width = 0;
	string field = "";
	float fieldsize = 0;
	float min_fieldsize = 0;
	float fieldpadding = hud_fontsize.x * 0.25;
	if (this_team == NUM_SPECTATOR)
	{
		if (autocvar_hud_panel_scoreboard_spectators_showping)
			min_fieldsize = stringwidth("999", false, hud_fontsize);
	}
	else if (autocvar_hud_panel_scoreboard_others_showscore)
		min_fieldsize = stringwidth("99", false, hud_fontsize);
	for (i = 0; pl; pl = pl.sort_next)
	{
		if (pl.team != this_team)
			continue;
		if (pl == ignored_pl)
			continue;

		if (teamplay)
		{
			int wants_join = entcs_GetWantsJoin(pl.sv_entnum);
			if (wants_join)
			{
				vector tmcolor = Team_ColorRGB(Team_IndexToTeam(wants_join)) * min(1, 1 + sin(2*M_PI*time));
				drawstring(pos, "(Q)", hud_fontsize, tmcolor, sbt_fg_alpha, DRAWFLAG_NORMAL);
				pos.x += stringwidth("(Q) ", true, hud_fontsize);
			}
		}

		field = "";
		if (this_team == NUM_SPECTATOR)
		{
			if (autocvar_hud_panel_scoreboard_spectators_showping)
				field = Scoreboard_GetField(pl, SP_PING, autocvar_hud_panel_scoreboard_scores_per_round);
		}
		else if (autocvar_hud_panel_scoreboard_others_showscore)
			field = Scoreboard_GetField(pl, SP_SCORE, autocvar_hud_panel_scoreboard_scores_per_round);

		string str = entcs_GetName(pl.sv_entnum);
		if (autocvar_hud_panel_scoreboard_playerid)
			str = Scoreboard_AddPlayerId(str, pl);
		str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		float column_width = stringwidth(str, true, hud_fontsize);
		if ((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned)
		{
			if (column_width > max_name_width)
				max_name_width = column_width;
			column_width = max_name_width;
		}
		if (field != "")
		{
			fieldsize = stringwidth(field, false, hud_fontsize);
			column_width += hud_fontsize.x * 0.25 + max(fieldsize, min_fieldsize) + 2 * fieldpadding;
		}

		if (pos.x + column_width > width_limit)
		{
			++i;
			if (!complete)
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

		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD && scoreboard_ui_enabled == 1)
		{
			if (pl == scoreboard_selected_player)
			{
				h_size.x = column_width + hud_fontsize.x * 0.25;
				h_size.y = hud_fontsize.y;
				drawfill(pos - hud_fontsize.x * 0.25 * eX, h_size, rgb, 0.44 * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}

		vector name_pos = pos;
		if ((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned)
			name_pos.x += max(fieldsize, min_fieldsize) + 2 * fieldpadding + hud_fontsize.x * 0.25;
		drawcolorcodedstring(name_pos, str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);
		if (field != "")
		{
			h_size.x = max(fieldsize, min_fieldsize) + 2 * fieldpadding;
			h_size.y = hud_fontsize.y;
			vector field_pos = pos;
			if (!((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned))
				field_pos.x += column_width - h_size.x;
			if (sbt_highlight)
				drawfill(field_pos, h_size, '1 1 1', sbt_highlight_alpha, DRAWFLAG_NORMAL);
			field_pos.x += fieldpadding + (max(fieldsize, min_fieldsize) - fieldsize) * 0.5;
			drawstring(field_pos, field, hud_fontsize, sbt_field_rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
		}
		if (pl.eliminated)
		{
			h_size.x = column_width + hud_fontsize.x * 0.25;
			h_size.y = hud_fontsize.y;
			drawfill(pos - hud_fontsize.x * 0.25 * eX, h_size, '0 0 0', sbt_highlight_alpha_eliminated, DRAWFLAG_NORMAL);
		}
		pos.x += column_width;
		pos.x += hud_fontsize.x;
	}
	return vec2(item_pos.x, item_pos.y + i * hud_fontsize.y * 1.25);
}

vector Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size)
{
	int max_players = 999;
	if (autocvar_hud_panel_scoreboard_maxheight > 0)
	{
		float height = autocvar_hud_panel_scoreboard_maxheight * vid_conheight;
		if (teamplay)
		{
			height -= (panel_bg_padding * 2 + hud_fontsize.y * 1.25) * team_count; // - padding and header
			height -= hud_fontsize.y * (team_count - 1); // - spacing between tables
			height /= team_count;
		}
		else
			height -= panel_bg_padding * 2; // - padding
		max_players = floor(height / (hud_fontsize.y * 1.25));
		if (max_players <= 1)
			max_players = 1;
		if (max_players == tm.team_size)
			max_players = 999;
	}

	entity pl;
	entity me = playerslots[current_player];
	panel_pos = pos;
	panel_size.y = 1.25 * hud_fontsize.y * (1 + bound(1, tm.team_size, max_players));
	panel_size.y += panel_bg_padding * 2;

	vector scoreboard_selected_hl_pos = pos;
	vector scoreboard_selected_hl_size = '0 0 0';
	scoreboard_selected_hl_size.x = scoreboard_right - scoreboard_left;
	scoreboard_selected_hl_size.y = panel_size.y;

	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
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
	for (pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if (pl.team != tm.team)
			continue;
		if (i == max_players - 2 && pl != me)
		{
			if (!self_shown && me.team == tm.team)
			{
				Scoreboard_DrawItem(pos, rgb, me, true, i);
				self_shown = true;
				pos.y += 1.25 * hud_fontsize.y;
				++i;
			}
		}
		if (i >= max_players - 1)
		{
			pos = Scoreboard_DrawOthers(pos, rgb, tm.team, (self_shown ? me : NULL), pl, i);
			break;
		}
		is_self = (pl.sv_entnum == current_player);
		Scoreboard_DrawItem(pos, rgb, pl, is_self, i);
		if (is_self)
			self_shown = true;
		pos.y += 1.25 * hud_fontsize.y;
		++i;
	}

	if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
	{
		if (scoreboard_ui_enabled == 1 || (tm && scoreboard_selected_team == tm))
		{
			float _alpha = (scoreboard_ui_enabled == 2) ? 0.2 : 0.3 * max(0, (1 - (time - scoreboard_selected_panel_time) * 2));
			_alpha *= panel_fg_alpha;
			if (_alpha)
				drawfill(scoreboard_selected_hl_pos, scoreboard_selected_hl_size, '1 1 1', _alpha, DRAWFLAG_NORMAL);
		}
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

bool Scoreboard_WouldDraw()
{
	if (scoreboard_ui_enabled)
	{
		if (scoreboard_ui_disabling)
		{
			if (scoreboard_fade_alpha == 0)
				HUD_Scoreboard_UI_Disable_Instantly();
			return false;
		}
		if (intermission && scoreboard_ui_enabled == 2)
		{
			HUD_Scoreboard_UI_Disable_Instantly();
			return false;
		}
		return true;
	}
	else if (MUTATOR_CALLHOOK(DrawScoreboard))
		return false;
	else if (QuickMenu_IsOpened())
		return false;
	else if (HUD_Radar_Clickable())
		return false;
	else if (sb_showscores) // set by +showscores engine command
		return true;
	else if (intermission == 1)
		return true;
	else if (intermission == 2)
		return false;
	else if (spectatee_status != -1 && STAT(HEALTH) <= 0 && autocvar_cl_deathscoreboard && !MUTATOR_CALLHOOK(DrawDeathScoreboard)
		&& time - CSQCModel_server2csqc(player_localentnum - 1).death_time >= autocvar_cl_deathscoreboard_delay
		&& (!HUD_MinigameMenu_IsOpened() || !active_minigame))
	{
		return true;
	}
	else if (scoreboard_showscores_force || MUTATOR_CALLHOOK(DrawScoreboard_Force))
		return true;
	return false;
}

float average_accuracy;
vector Scoreboard_AccuracyStats_Draw(vector pos, vector rgb, vector bg_size)
{
	scoreboard_acc_fade_alpha = min(scoreboard_fade_alpha, scoreboard_acc_fade_alpha + frametime * 10);

	WepSet weapons_stat = WepSet_GetFromStat();
	WepSet weapons_inmap = WepSet_GetFromStat_InMap();
	int disownedcnt = 0;
	int nHidden = 0;
	FOREACH(Weapons, it != WEP_Null, {
		int weapon_stats = weapon_accuracy[i - WEP_FIRST];

		WepSet set = it.m_wepset;
		if (it.spawnflags & WEP_TYPE_OTHER)
		{
			++nHidden;
			continue;
		}
		if (weapon_stats < 0 && !((weapons_stat & set) || (weapons_inmap & set)))
		{
			if (it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED))
				++nHidden;
			else
				++disownedcnt;
		}
	});

	int weapon_cnt = (REGISTRY_COUNT(Weapons) - 1) - disownedcnt - nHidden;
	if (weapon_cnt <= 0)
		return pos;

	int rows = 1;
	if (autocvar_hud_panel_scoreboard_accuracy_doublerows && weapon_cnt >= floor((REGISTRY_COUNT(Weapons) - nHidden - 1) * 0.5))
		rows = 2;
	int columns = ceil(weapon_cnt / rows);

	float aspect = max(0.001, autocvar_hud_panel_weapons_aspect);
	float weapon_height = hud_fontsize.y * 2.3 / aspect;
	float height = weapon_height + hud_fontsize.y;

	drawstring(pos + eX * panel_bg_padding, sprintf(_("Accuracy stats (average %d%%)"), average_accuracy), hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = height * rows;
	panel_size.y += panel_bg_padding * 2;

	float panel_bg_alpha_save = panel_bg_alpha;
	panel_bg_alpha *= scoreboard_acc_fade_alpha;
	HUD_Panel_DrawBg();
	panel_bg_alpha = panel_bg_alpha_save;

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	float weapon_width = tmp.x / columns / rows;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);

	if (sbt_highlight)
	{
		// column highlighting
		for (int i = 0; i < columns; ++i)
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
		if (weapon_stats >= 0)
		{
			weapons_with_stats += 1;
			average_accuracy += weapon_stats; // store sum of all accuracies in average_accuracy

			string s = ftos_decimals_percentage(weapon_stats, 0);
			float padding = (weapon_width - stringwidth(s, false, hud_fontsize)) / 2;

			if (!autocvar_hud_panel_scoreboard_accuracy_nocolors)
				rgb = Accuracy_GetColor(weapon_stats);

			drawstring(tmpos + vec2(padding, weapon_height), s, hud_fontsize, rgb, sbt_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		}
		tmpos.x += weapon_width * rows;
		pos.x += weapon_width * rows;
		if (rows == 2 && column == columns - 1)
		{
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

bool is_item_filtered(entity it)
{
	if (!autocvar_hud_panel_scoreboard_itemstats_filter)
		return false;
	int mask = autocvar_hud_panel_scoreboard_itemstats_filter_mask;
	if (mask <= 0)
		return false;
	if (it.instanceOfArmor || it.instanceOfHealth)
	{
		int ha_mask = floor(mask) % 10;
		switch (ha_mask)
		{
			default: return false;
			case 4: if (it == ITEM_HealthMega   || it == ITEM_ArmorMega)   return true; // else fallthrough
			case 3: if (it == ITEM_HealthBig    || it == ITEM_ArmorBig)    return true; // else fallthrough
			case 2: if (it == ITEM_HealthMedium || it == ITEM_ArmorMedium) return true; // else fallthrough
			case 1: if (it == ITEM_HealthSmall  || it == ITEM_ArmorSmall)  return true; // else fallthrough
		}
	}
	if (it.instanceOfAmmo)
	{
		int ammo_mask = floor(mask / 10) % 10;
		return (ammo_mask == 1);
	}
	return false;
}

vector Scoreboard_ItemStats_Draw(vector pos, vector rgb, vector bg_size)
{
	scoreboard_itemstats_fade_alpha = min(scoreboard_fade_alpha, scoreboard_itemstats_fade_alpha + frametime * 10);

	int disowned_cnt = 0;
	int uninteresting_cnt = 0;
	IL_EACH(default_order_items, true, {
		int q = g_inventory.inv_items[it.m_id];
		//q = 1; // debug: display all items
		if (is_item_filtered(it))
			++uninteresting_cnt;
		else if (!q)
			++disowned_cnt;
	});
	int items_cnt = REGISTRY_COUNT(Items) - uninteresting_cnt;
	int n = items_cnt - disowned_cnt;
	if (n <= 0)
		return pos;

	int rows = (autocvar_hud_panel_scoreboard_itemstats_doublerows && n >= floor(REGISTRY_COUNT(Items) / 2)) ? 2 : 1;
	int columns = max(6, ceil(n / rows));

	float item_height = hud_fontsize.y * 2.3;
	float height = item_height + hud_fontsize.y;

	drawstring(pos + eX * panel_bg_padding, _("Item stats"), hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = height * rows;
	panel_size.y += panel_bg_padding * 2;

	float panel_bg_alpha_save = panel_bg_alpha;
	panel_bg_alpha *= scoreboard_itemstats_fade_alpha;
	HUD_Panel_DrawBg();
	panel_bg_alpha = panel_bg_alpha_save;

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	float item_width = tmp.x / columns / rows;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);

	if (sbt_highlight)
	{
		// column highlighting
		for (int i = 0; i < columns; ++i)
			if ((i % 2) == 0)
				drawfill(pos + eX * item_width * rows * i, vec2(item_width * rows, height * rows), '0 0 0', sbt_highlight_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);

		// row highlighting
		for (int i = 0; i < rows; ++i)
			drawfill(pos + eY * (item_height + height * i), vec2(panel_size.x, hud_fontsize.y), rgb, sbt_highlight_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
	}

	if (rows == 2)
		pos.x += item_width / 2;

	float oldposx = pos.x;
	vector tmpos = pos;

	int column = 0;
	IL_EACH(default_order_items, !is_item_filtered(it), {
		int n = g_inventory.inv_items[it.m_id];
		//n = 1 + floor(i * 3 + 4.8) % 7; // debug: display a value for each item
		if (n <= 0)
			continue;
		drawpic_aspect_skin(tmpos, it.m_icon, eX * item_width + eY * item_height, '1 1 1', panel_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
		string s = ftos(n);
		float padding = (item_width - stringwidth(s, false, hud_fontsize)) / 2;
		drawstring(tmpos + vec2(padding, item_height), s, hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
		tmpos.x += item_width * rows;
		pos.x += item_width * rows;
		if (rows == 2 && column == columns - 1)
		{
			tmpos.x = oldposx;
			tmpos.y += height;
			pos.y += height;
		}
		++column;
	});

	panel_size.x += panel_bg_padding * 2; // restore initial width

	return end_pos;
}

vector MapStats_DrawKeyValue(vector pos, string key, string value)
{
	float px = pos.x;
	pos.x += hud_fontsize.x * 0.25;
	drawstring(pos, key, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = panel_pos.x + panel_size.x - stringwidth(value, false, hud_fontsize) - hud_fontsize.x * 0.25;
	drawstring(pos, value, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = px;
	pos.y += hud_fontsize.y;

	return pos;
}

vector Scoreboard_MapStats_Draw(vector pos, vector rgb, vector bg_size)
{
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
	if (stat_secrets_total)
		rows += 1;
	if (stat_monsters_total)
		rows += 1;

	// if no rows, return
	if (!rows)
		return pos;

	//  draw table header
	drawstring(pos + eX * panel_bg_padding, _("Map stats:"), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = hud_fontsize.y * rows;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = panel_size;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	// draw monsters
	if (stat_monsters_total)
	{
		val = sprintf("%d/%d", stat_monsters_killed, stat_monsters_total);
		pos = MapStats_DrawKeyValue(pos, _("Monsters killed:"), val);
	}

	// draw secrets
	if (stat_secrets_total)
	{
		val = sprintf("%d/%d", stat_secrets_found, stat_secrets_total);
		pos = MapStats_DrawKeyValue(pos, _("Secrets found:"), val);
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

vector Scoreboard_Rankings_Draw(vector pos, string ranktitle, entity pl, vector rgb, vector bg_size)
{
	int i;
	RANKINGS_RECEIVED_CNT = 0;
	for (i=RANKINGS_CNT-1; i>=0; --i)
		if (grecordtime[i])
			++RANKINGS_RECEIVED_CNT;

	if (RANKINGS_RECEIVED_CNT == 0)
		return pos;

	vector hl_rgb = rgb + '0.5 0.5 0.5';

	vector scoreboard_selected_hl_pos = pos;

	drawstring(pos + eX * panel_bg_padding, ranktitle, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	vector scoreboard_selected_hl_size = '0 0 0';
	scoreboard_selected_hl_size.x = scoreboard_right - scoreboard_left;
	scoreboard_selected_hl_size.y = pos.y - scoreboard_selected_hl_pos.y;

	panel_pos = pos;

	float namesize = 0;
	for (i = 0; i < RANKINGS_RECEIVED_CNT; ++i)
	{
		float f = stringwidth(ColorTranslateRGB(grecordholder[i]), true, hud_fontsize);
		if (f > namesize)
			namesize = f;
	}
	bool cut = false;
	if (namesize > autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x)
	{
		namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
		cut = true;
	}

	float ranksize = 3 * hud_fontsize.x;
	float timesize = 5 * hud_fontsize.x;
	vector columnsize = vec2(ranksize + timesize + namesize + hud_fontsize.x, 1.25 * hud_fontsize.y);
	rankings_columns = max(1, floor((panel_size.x - 2 * panel_bg_padding) / columnsize.x));
	rankings_columns = min(rankings_columns, RANKINGS_RECEIVED_CNT);
	if (!rankings_cnt)
	{
		rankings_cnt = RANKINGS_RECEIVED_CNT;
		rankings_rows = ceil(rankings_cnt / rankings_columns);
	}

	// expand name column to fill the entire row
	float available_space = (panel_size.x - 2 * panel_bg_padding - columnsize.x * rankings_columns) / rankings_columns;
	namesize += available_space;
	columnsize.x += available_space;

	panel_size.y = rankings_rows * 1.25 * hud_fontsize.y;
	panel_size.y += panel_bg_padding * 2;
	scoreboard_selected_hl_size.y += panel_size.y;

	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
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
	int start_item = rankings_start_column * rankings_rows;
	for (i = start_item; i < start_item + rankings_cnt; ++i)
	{
		int t = grecordtime[i];
		if (t == 0)
			continue;

		if (strdecolorize(grecordholder[i]) == zoned_name_self)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
		else if (!((j + rankings_start_column + column) & 1) && sbt_highlight)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

		str = count_ordinal(i+1);
		vector rank_color;
		switch(i)
		{
			case 0:  rank_color = '0.933 0.733 0.200'; break; // 1st; gold
			case 1:  rank_color = '0.667 0.667 0.667'; break; // 2nd; silver
			case 2:  rank_color = '0.800 0.467 0.267'; break; // 3rd; bronze
			default: rank_color = '1 1 1';
		}
		drawstring(pos + text_ofs, str, hud_fontsize, rank_color, sbt_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + text_ofs + eX * ranksize, TIME_ENCODED_TOSTRING(t, true), hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		str = ColorTranslateRGB(grecordholder[i]);
		if (cut)
			str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		drawcolorcodedstring(pos + text_ofs + eX * (ranksize + timesize), str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);

		pos.y += 1.25 * hud_fontsize.y;
		++j;
		if (j >= rankings_rows)
		{
			++column;
			j = 0;
			pos.x += panel_size.x / rankings_columns;
			pos.y = panel_pos.y;
		}
	}
	strfree(zoned_name_self);

	if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
	{
		float fade = max(0, (1 - (time - scoreboard_selected_panel_time) * 2));
		drawfill(scoreboard_selected_hl_pos, scoreboard_selected_hl_size, '1 1 1', fade * 0.44, DRAWFLAG_NORMAL);
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

bool have_weapon_stats;
bool Scoreboard_AccuracyStats_WouldDraw(float ypos)
{
	if (MUTATOR_CALLHOOK(DrawScoreboardAccuracy))
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

bool have_item_stats;
bool Scoreboard_ItemStats_WouldDraw(float ypos)
{
	if (MUTATOR_CALLHOOK(DrawScoreboardItemStats))
		return false;
	if (!autocvar_hud_panel_scoreboard_itemstats || !g_inventory || warmup_stage || ypos > 0.91 * vid_conheight)
		return false;

	if (time < scoreboard_time + autocvar_hud_panel_scoreboard_itemstats_showdelay
		&& ypos > autocvar_hud_panel_scoreboard_itemstats_showdelay_minpos * vid_conheight
		&& !intermission)
	{
		return false;
	}

	if (!have_item_stats)
	{
		IL_EACH(default_order_items, true, {
			if (!is_item_filtered(it))
			{
				int q = g_inventory.inv_items[it.m_id];
				//q = 1; // debug: display all items
				if (q)
				{
					have_item_stats = true;
					break;
				}
			}
		});
		if (!have_item_stats)
			return false;
	}

	return true;
}

vector Scoreboard_Spectators_Draw(vector pos)
{
	entity pl, tm;
	string str = "";

	for (pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if (pl.team == NUM_SPECTATOR)
		{
			for (tm = teams.sort_next; tm; tm = tm.sort_next)
				if (tm.team == NUM_SPECTATOR)
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
	if (str != "") // if there's at least one spectator
		pos.y += 0.5 * hud_fontsize.y;

	return pos;
}

string Scoreboard_Fraglimit_Draw(float limit, bool is_leadlimit)
{
	string s_label = (teamplay) ? teamscores_label(ts_primary) : scores_label(ps_primary);
	int s_flags = (teamplay) ? teamscores_flags(ts_primary) : scores_flags(ps_primary);
	return sprintf((is_leadlimit ? _("^2+%s %s") : _("^5%s %s")), ScoreString(s_flags, limit, 0),
		(s_label == "score") ? CTX(_("SCO^points")) :
		(s_label == "fastest") ? "" : TranslateScoresLabel(s_label));
}

void Scoreboard_Draw()
{
	if (!autocvar__hud_configure)
	{
		if (!hud_draw_maximized)
			return;

		// frametime checks allow to toggle the scoreboard even when the game is paused
		if (scoreboard_active)
		{
			if (scoreboard_fade_alpha == 0)
				scoreboard_time = time;
			if (hud_configure_menu_open == 1)
				scoreboard_fade_alpha = 1;
			float scoreboard_fadeinspeed = autocvar_hud_panel_scoreboard_fadeinspeed;
			if (scoreboard_fadeinspeed && frametime)
				scoreboard_fade_alpha = min(1, scoreboard_fade_alpha + frametime * scoreboard_fadeinspeed);
			else
				scoreboard_fade_alpha = 1;

			static string hud_fontsize_str;
			if (hud_fontsize_str != autocvar_hud_fontsize)
			{
				hud_fontsize = HUD_GetFontsize("hud_fontsize");
				strcpy(hud_fontsize_str, autocvar_hud_fontsize);
				sb_field_sizes_init = 1;
			}

			static float scoreboard_table_fieldtitle_maxwidth_prev;
			if (scoreboard_table_fieldtitle_maxwidth_prev != autocvar_hud_panel_scoreboard_table_fieldtitle_maxwidth)
			{
				scoreboard_table_fieldtitle_maxwidth_prev = autocvar_hud_panel_scoreboard_table_fieldtitle_maxwidth;
				sbt_field_title_maxwidth = bound(0.01, autocvar_hud_panel_scoreboard_table_fieldtitle_maxwidth, 0.1);
				sbt_field_title_maxwidth *= vid_conwidth;
				sb_field_sizes_init = 1;
			}
		}
		else
		{
			float scoreboard_fadeoutspeed = autocvar_hud_panel_scoreboard_fadeoutspeed;
			if (scoreboard_fadeoutspeed && frametime)
				scoreboard_fade_alpha = max(0, scoreboard_fade_alpha - frametime * scoreboard_fadeoutspeed);
			else
				scoreboard_fade_alpha = 0;
		}

		if (!scoreboard_fade_alpha)
		{
			scoreboard_acc_fade_alpha = 0;
			scoreboard_itemstats_fade_alpha = 0;
			return;
		}
	}
	else
		scoreboard_fade_alpha = 0;

	if (autocvar_hud_panel_scoreboard_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	if (scoreboard_fade_alpha <= 0)
		return;
	panel_fade_alpha *= scoreboard_fade_alpha;
	HUD_Panel_LoadCvars();

	sbt_bg_alpha = autocvar_hud_panel_scoreboard_table_bg_alpha * panel_fg_alpha;
	sbt_highlight = autocvar_hud_panel_scoreboard_table_highlight;
	sbt_highlight_alpha = autocvar_hud_panel_scoreboard_table_highlight_alpha * panel_fg_alpha;
	sbt_highlight_alpha_self = autocvar_hud_panel_scoreboard_table_highlight_alpha_self * panel_fg_alpha;
	sbt_highlight_alpha_eliminated = autocvar_hud_panel_scoreboard_table_highlight_alpha_eliminated * panel_fg_alpha;
	sbt_fg_alpha = autocvar_hud_panel_scoreboard_table_fg_alpha * panel_fg_alpha;
	sbt_fg_alpha_self = autocvar_hud_panel_scoreboard_table_fg_alpha_self * panel_fg_alpha;

	// don't overlap with con_notify
	if (!autocvar__hud_configure)
		panel_pos.y = max((autocvar_con_notify * autocvar_con_notifysize), panel_pos.y);

	float excess = max(0, max_namesize - autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x);
	float fixed_scoreboard_width = bound(vid_conwidth * autocvar_hud_panel_scoreboard_minwidth, vid_conwidth - excess, vid_conwidth * 0.93);
	scoreboard_left = 0.5 * (vid_conwidth - fixed_scoreboard_width);
	scoreboard_right = scoreboard_left + fixed_scoreboard_width;
	panel_pos.x = scoreboard_left;
	panel_size.x = fixed_scoreboard_width;

	// field sizes can be initialized now after panel_size.x calculation
	if (!sbt_field_size[0] || sb_field_sizes_init)
	{
		bool compress = (sb_field_sizes_init == 2);
		Scoreboard_initFieldSizes(compress);
		sb_field_sizes_init = 0;
	}

	Scoreboard_UpdatePlayerTeams();

	scoreboard_top = panel_pos.y;
	vector pos = panel_pos;
	entity tm;
	string str;
	vector str_pos;

	if (scoreboard_ui_enabled)
		drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, '0 0 0', 0.7 * panel_fade_alpha, DRAWFLAG_NORMAL);

	vector sb_gameinfo_type_fontsize, sb_gameinfo_detail_fontsize;

	// Begin of Game Info Section
	sb_gameinfo_type_fontsize = hud_fontsize * 2.5;
	sb_gameinfo_detail_fontsize = hud_fontsize * 1.3;

	if (GET_NEXTMAP() != "")
	{
		// NOTE: nextmap is drawn before title to avoid covering title in case of long map name
		str = strcat("^7", _("Next map:"), " ^9", GET_NEXTMAP());
		drawcolorcodedstring(pos + vec2(hud_fontsize.x * 0.5, sb_gameinfo_type_fontsize.y - hud_fontsize.y * 1.25),
			str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	// Game Info: Gametype
	if (scoreboard_ui_enabled == 2)
		str = _("Team Selection");
	else if (gametype_custom_name != "")
		str = gametype_custom_name;
	else
		str = MapInfo_Type_ToText(gametype);
	draw_beginBoldFont();
	drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, sb_gameinfo_type_fontsize)), str, sb_gameinfo_type_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	draw_endBoldFont();

	pos.y += sb_gameinfo_type_fontsize.y;
	// Game Info: Game Detail
	if (scoreboard_ui_enabled == 2)
	{
		if (scoreboard_selected_team)
			str = sprintf(_("^7Press ^3%s^7 to join the selected team"), translate_key("SPACE"));
		else
			str = sprintf(_("^7Press ^3%s^7 to auto-select a team and join"), translate_key("SPACE"));
		drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize)), str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

		pos.y += sb_gameinfo_detail_fontsize.y + hud_fontsize.y * 0.3;
		str = sprintf(_("^7Press ^3%s ^7to select a specific team"), translate_key("TAB"));
		drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize)), str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
	{
		float tl = STAT(TIMELIMIT);
		float fl = STAT(FRAGLIMIT);
		float ll = STAT(LEADLIMIT);
		float ll_and_fl = STAT(LEADLIMIT_AND_FRAGLIMIT);
		str = "";
		if (tl > 0)
			str = strcat(str, "^3", count_minutes(floor(tl)));
		if (!gametype.m_hidelimits)
		{
			if (fl > 0)
			{
				if (tl > 0)
					str = strcat(str, "^7 / "); // delimiter
				str = strcat(str, Scoreboard_Fraglimit_Draw(fl, false));
			}
			if (ll > 0 && (ll < fl || fl <= 0))
			{
				if (tl > 0 || fl > 0)
				{
					// delimiter
					if (ll_and_fl && fl > 0)
						str = strcat(str, "^7 & ");
					else
						str = strcat(str, "^7 / ");
				}
				str = strcat(str, Scoreboard_Fraglimit_Draw(ll, true));
			}
		}
		drawcolorcodedstring(pos + '1 0 0' * (panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize)), str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL); // align right
		// map name and player count
		if (campaign)
			str = "";
		else
			str = sprintf(_("^5%d^7/^5%d ^7players"), numplayers, srv_maxplayers ? srv_maxplayers : maxclients);
		str = strcat("^7", _("Map:"), " ^2", mi_shortname, "    ", str); // reusing "Map:" translatable string
		drawcolorcodedstring(pos, str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL); // align left
	}
	// End of Game Info Section

	pos.y += sb_gameinfo_detail_fontsize.y + hud_fontsize.y * 0.3; // space between Game Info Section and score table
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	// Draw the scoreboard
	float scale = autocvar_hud_panel_scoreboard_table_bg_scale;
	if (scale <= 0)
		scale = 0.25;
	vector bg_size = draw_getimagesize("gfx/scoreboard/scoreboard_bg") * scale;

	if (teamplay)
	{
		vector panel_bg_color_save = panel_bg_color;
		vector team_score_baseoffset;
		vector team_size_baseoffset;
		if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
		{
			// put team score to the left of scoreboard (and team size to the right)
			team_score_baseoffset = eY * hud_fontsize.y - eX * hud_fontsize.x * 0.5;
			team_size_baseoffset = eY * hud_fontsize.y + eX * hud_fontsize.x * 0.5;
			if (panel.current_panel_bg != "0")
			{
				team_score_baseoffset.x -= panel_bg_border;
				team_size_baseoffset.x += panel_bg_border;
			}
		}
		else
		{
			// put team score to the right of scoreboard (and team size to the left)
			team_score_baseoffset = eY * hud_fontsize.y + eX * hud_fontsize.x * 0.5;
			team_size_baseoffset = eY * hud_fontsize.y - eX * hud_fontsize.x * 0.5;
			if (panel.current_panel_bg != "0")
			{
				team_score_baseoffset.x += panel_bg_border;
				team_size_baseoffset.x -= panel_bg_border;
			}
		}

		int team_size_total = 0;
		if (autocvar_hud_panel_scoreboard_team_size_position != 0) // team size not off
		{
			// calculate team size total (sum of all team sizes)
			for (tm = teams.sort_next; tm; tm = tm.sort_next)
				if (tm.team != NUM_SPECTATOR)
					team_size_total += tm.team_size;
		}

		for (tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if (tm.team == NUM_SPECTATOR)
				continue;
			if (!tm.team)
				continue;

			draw_beginBoldFont();
			vector rgb = Team_ColorRGB(tm.team);
			str = ftos(tm.(teamscores(ts_primary)));
			if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
			{
				// team score on the left (default)
				str_pos = pos + team_score_baseoffset - eX * stringwidth(str, false, hud_fontsize * 1.5);
			}
			else
			{
				// team score on the right
				str_pos = pos + team_score_baseoffset + eX * (panel_size.x + hud_fontsize.x * 1.5);
			}
			drawstring(str_pos, str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

			// team size (if set to show on the side)
			if (autocvar_hud_panel_scoreboard_team_size_position != 0) // team size not off
			{
				// calculate the starting position for the whole team size info string
				str = sprintf("%d/%d", tm.team_size, team_size_total);
				if (autocvar_hud_panel_scoreboard_team_size_position == 1)
				{
					// team size on the left
					str_pos = pos + team_size_baseoffset - eX * stringwidth(str, false, hud_fontsize * 1.5);
				}
				else
				{
					// team size on the right
					str_pos = pos + team_size_baseoffset + eX * (panel_size.x + hud_fontsize.x * 1.5);
				}
				str = sprintf("%d", tm.team_size);
				drawstring(str_pos, str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
				str_pos += eX * stringwidth(str, true, hud_fontsize * 1.5) + eY * hud_fontsize.y * .5;
				str = sprintf("/%d", team_size_total);
				drawstring(str_pos, str, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			}


			// secondary score, e.g. keyhunt
			if (ts_primary != ts_secondary)
			{
				str = ftos(tm.(teamscores(ts_secondary)));
				if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
				{
					// left
					str_pos = pos + team_score_baseoffset - vec2(stringwidth(str, false, hud_fontsize), hud_fontsize.y * -1.5);
				}
				else
				{
					// right
					str_pos = pos + team_score_baseoffset + vec2(panel_size.x + hud_fontsize.x * 1.5, hud_fontsize.y * 1.5);
				}

				drawstring(str_pos, str, hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			draw_endBoldFont();
			if (autocvar_hud_panel_scoreboard_bg_teams_color_team > 0)
				panel_bg_color = rgb * autocvar_hud_panel_scoreboard_bg_teams_color_team;
			else if (panel_bg_color_team > 0)
				panel_bg_color = rgb * panel_bg_color_team;
			else
				panel_bg_color = rgb;
			pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
		}
		panel_bg_color = panel_bg_color_save;
	}
	else
	{
		for (tm = teams.sort_next; tm; tm = tm.sort_next)
			if (tm.team != NUM_SPECTATOR)
				break;

		// display it anyway
		pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size);
	}

	// if the name column is too small, try to compress all other field titles
	if (sbt_field_size[name_field_index] < sbt_field_title_width[name_field_index] + hud_fontsize.x)
		sb_field_sizes_init = 2;

	// draw scoreboard spectators before accuracy and item stats
	if (autocvar_hud_panel_scoreboard_spectators_position == 0)
		pos = Scoreboard_Spectators_Draw(pos);

	// draw accuracy and item stats
	if (Scoreboard_AccuracyStats_WouldDraw(pos.y))
		pos = Scoreboard_AccuracyStats_Draw(pos, panel_bg_color, bg_size);
	if (Scoreboard_ItemStats_WouldDraw(pos.y))
		pos = Scoreboard_ItemStats_Draw(pos, panel_bg_color, bg_size);

	// draw scoreboard spectators after accuracy and item stats and before rankings
	if (autocvar_hud_panel_scoreboard_spectators_position == 1)
		pos = Scoreboard_Spectators_Draw(pos);

	if (MUTATOR_CALLHOOK(ShowRankings))
	{
		string ranktitle = M_ARGV(0, string);
		string unit = GetSpeedUnit(autocvar_hud_speed_unit);
		float conversion_factor = GetSpeedUnitFactor(autocvar_hud_speed_unit);
		if (race_speedaward_alltimebest)
		{
			string name;
			float namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
			str = "";
			if (race_speedaward)
			{
				name = textShortenToWidth(ColorTranslateRGB(race_speedaward_holder), namesize, hud_fontsize, stringwidth_colors);
				str = sprintf(_("Speed award: %d%s ^7(%s^7)"), race_speedaward * conversion_factor, unit, name);
				str = strcat(str, " / ");
			}
			name = textShortenToWidth(ColorTranslateRGB(race_speedaward_alltimebest_holder), namesize, hud_fontsize, stringwidth_colors);
			str = strcat(str, sprintf(_("All-time fastest: %d%s ^7(%s^7)"), race_speedaward_alltimebest * conversion_factor, unit, name));
			drawcolorcodedstring(pos, str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y; // line height + line spacing
		}
		pos = Scoreboard_Rankings_Draw(pos, ranktitle, playerslots[player_localnum], panel_bg_color, bg_size);
	}
	else
		rankings_cnt = 0;

	// draw scoreboard spectators after rankings
	if (autocvar_hud_panel_scoreboard_spectators_position == 2)
		pos = Scoreboard_Spectators_Draw(pos);

	pos = Scoreboard_MapStats_Draw(pos, panel_bg_color, bg_size);

	// draw scoreboard spectators after mapstats
	if (autocvar_hud_panel_scoreboard_spectators_position == 3)
		pos = Scoreboard_Spectators_Draw(pos);


	// print information about respawn status
	float respawn_time = STAT(RESPAWN_TIME);
	if (!intermission && respawn_time)
	{
		if (respawn_time < 0)
		{
			// a negative number means we are awaiting respawn, time value is still the same
			respawn_time *= -1; // remove mark now that we checked it

			if (respawn_time < time) // it happens for a few frames when server is respawning the player
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
		else if (time < respawn_time)
		{
			str = sprintf(_("You are dead, wait ^3%s^7 before respawning"),
				(autocvar_hud_panel_scoreboard_respawntime_decimals ?
					count_seconds_decs(respawn_time - time, autocvar_hud_panel_scoreboard_respawntime_decimals)
					:
					count_seconds(ceil(respawn_time - time))
				)
			);
		}
		else if (time >= respawn_time)
			str = sprintf(_("You are dead, press ^2%s^7 to respawn"), getcommandkey(_("jump"), "+jump"));

		pos.y += 1.2 * hud_fontsize.y;
		drawcolorcodedstring(pos + '0.5 0 0' * (panel_size.x - stringwidth(str, true, hud_fontsize)), str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	pos.y += hud_fontsize.y;
	if (scoreboard_fade_alpha < 1)
		scoreboard_bottom = scoreboard_top + (pos.y - scoreboard_top) * scoreboard_fade_alpha;
	else if (pos.y != scoreboard_bottom)
	{
		if (pos.y > scoreboard_bottom)
			scoreboard_bottom = min(pos.y, scoreboard_bottom + frametime * 10 * (pos.y - scoreboard_top));
		else
			scoreboard_bottom = max(pos.y, scoreboard_bottom - frametime * 10 * (pos.y - scoreboard_top));
	}

	if (rankings_cnt)
	{
		if (scoreboard_fade_alpha == 1)
		{
			if (scoreboard_bottom > 0.95 * vid_conheight)
				rankings_rows = max(1, rankings_rows - 1);
			else if (scoreboard_bottom + 1.25 * hud_fontsize.y < 0.95 * vid_conheight)
				rankings_rows = min(ceil(RANKINGS_RECEIVED_CNT / rankings_columns), rankings_rows + 1);
		}
		rankings_cnt = rankings_rows * rankings_columns;
	}
}
