#include "scoreboard.qh"

#include "accuracy_items.qh"
#include "mapstats.qh"
#include "rankings.qh"
#include "table.qh"

#include <client/csqcmodel_hooks.qh>
#include <client/draw.qh>
#include <client/hud/panel/chat.qh>
#include <client/hud/panel/physics.qh>
#include <client/hud/panel/quickmenu.qh>
#include <common/constants.qh>
#include <common/ent_cs.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/net_linked.qh>
#include <common/stats.qh>

// Scoreboard (#24)

ACCUMULATE void Scoreboard_Draw_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_scoreboard_fadeinspeed");
	HUD_Write_Cvar("hud_panel_scoreboard_fadeoutspeed");
	HUD_Write_Cvar("hud_panel_scoreboard_hide_panels");
	HUD_Write_Cvar("hud_panel_scoreboard_minimal");
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
	HUD_Write_Cvar("hud_panel_scoreboard_spectators_position");
}

string autocvar_hud_fontsize;

bool autocvar_cl_deathscoreboard;
float autocvar_cl_deathscoreboard_delay = 1;

float autocvar_hud_panel_scoreboard_fadeinspeed = 10;
float autocvar_hud_panel_scoreboard_fadeoutspeed = 5;
int autocvar_hud_panel_scoreboard_respawntime_decimals = 1;
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
int autocvar_hud_panel_scoreboard_spectators_position = 1;

bool autocvar_hud_panel_scoreboard_dynamichud = false;

float autocvar_hud_panel_scoreboard_minwidth = 0.4;

SHUTDOWN(scoreboard)
{
	if (autocvar_hud_panel_scoreboard_scores_per_round)
		cvar_set("hud_panel_scoreboard_scores_per_round", "0");
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

float HUD_Scoreboard_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	if (!scoreboard_ui_enabled || scoreboard_ui_disabling)
		return false;

	if (bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		return true;
	}

	if (bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = bInputType == 0;

	// ESC to exit (TAB-ESC works too)
	if (nPrimary == K_ESCAPE)
	{
		if (!key_pressed)
			return true;
		HUD_Scoreboard_UI_Disable();
		return true;
	}

	// block any input while a menu dialog is fading
	if (autocvar__menu_alpha)
	{
		hudShiftState = 0;
		return true;
	}

	// allow console bind to work
	string con_keys = findkeysforcommand("toggleconsole", 0);
	int keys = tokenize(con_keys); // findkeysforcommand returns data for this

	bool hit_con_bind = false;
	for (int i = 0; i < keys; ++i)
		if (nPrimary == stof(argv(i)))
			hit_con_bind = true;

	if (key_pressed)
	{
		if (nPrimary == K_ALT)    hudShiftState |= S_ALT;
		if (nPrimary == K_CTRL)   hudShiftState |= S_CTRL;
		if (nPrimary == K_SHIFT)  hudShiftState |= S_SHIFT;
		if (nPrimary == K_TAB)    hudShiftState |= S_TAB;
	}
	else
	{
		if (nPrimary == K_ALT)    hudShiftState &= ~S_ALT;
		if (nPrimary == K_CTRL)   hudShiftState &= ~S_CTRL;
		if (nPrimary == K_SHIFT)  hudShiftState &= ~S_SHIFT;
		if (nPrimary == K_TAB)    hudShiftState &= ~S_TAB;
	}

	if (nPrimary == K_TAB)
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
	else if (nPrimary == K_DOWNARROW)
	{
		if (!key_pressed)
			return true;
		LABEL(downarrow_action);
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_ui_enabled == 2)
			{
				bool scoreboard_selected_team_found = !scoreboard_selected_team;

				entity curr_team = NULL;
				for (entity tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if (tm.team == NUM_SPECTATOR)
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
				bool scoreboard_selected_player_found = !scoreboard_selected_player;

				entity curr_pl = NULL;
				for (entity pl, tm = teams.sort_next; tm; tm = tm.sort_next)
					if (tm.team != NUM_SPECTATOR)
						for (pl = players.sort_next; pl; pl = pl.sort_next)
						{
							if (pl.team != tm.team)
								continue;
							curr_pl = pl;
							if (scoreboard_selected_player_found)
								goto ok_done;
							if (scoreboard_selected_player == pl)
								scoreboard_selected_player_found = true;
						}
				LABEL(ok_done);
				if (curr_pl == scoreboard_selected_player) // loop reached the last player
					curr_pl = NULL;
				scoreboard_selected_player = curr_pl;
			}
		}
	}
	else if (nPrimary == K_UPARROW)
	{
		if (!key_pressed)
			return true;
		LABEL(uparrow_action);
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			if (scoreboard_ui_enabled == 2)
			{
				entity prev_team = NULL;
				for (entity tm = teams.sort_next; tm; tm = tm.sort_next)
				{
					if (tm.team == NUM_SPECTATOR)
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
				for (entity pl, tm = teams.sort_next; tm; tm = tm.sort_next)
					if (tm.team != NUM_SPECTATOR)
						for (pl = players.sort_next; pl; pl = pl.sort_next)
						{
							if (pl.team != tm.team)
								continue;
							if (pl == scoreboard_selected_player)
								goto ok_done2;
							prev_pl = pl;
						}
				LABEL(ok_done2);
				scoreboard_selected_player = prev_pl;
			}
		}
	}
	else if (nPrimary == K_RIGHTARROW)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
			rankings_start_column = min(rankings_start_column + 1, ceil(RANKINGS_RECEIVED_CNT / rankings_rows) - rankings_columns);
	}
	else if (nPrimary == K_LEFTARROW)
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
			rankings_start_column = max(rankings_start_column - 1, 0);
	}
	else if (nPrimary == K_ENTER || nPrimary == K_SPACE || nPrimary == K_KP_ENTER)
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
				localcmd(strcat("cmd join ", team_name, "\n"));
				HUD_Scoreboard_UI_Disable();
			}
			else if (scoreboard_selected_player)
				localcmd(sprintf("spectate %d\n", scoreboard_selected_player.sv_entnum + 1));
		}
	}
	else if (nPrimary == 'c' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_ui_enabled == 1 && scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
		{
			switch (scoreboard_selected_columns_layout)
			{
				case 0:
					if (autocvar_scoreboard_columns != ""
					&&  autocvar_scoreboard_columns != "all"
					&&  autocvar_scoreboard_columns != "default")
					{
						localcmd("scoreboard_columns_set\n"); // sets the layout saved in scoreboard_columns
						scoreboard_selected_columns_layout = 1;
						break;
					}
					// fallthrough
				case 1:
					localcmd("scoreboard_columns_set default\n");
					scoreboard_selected_columns_layout = 2;
					break;
				case 2:
					localcmd("scoreboard_columns_set all\n");
					scoreboard_selected_columns_layout = 0;
					break;
			}
		}
	}
	else if (nPrimary == 'r' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD)
			localcmd("toggle hud_panel_scoreboard_scores_per_round\n");
	}
	else if (nPrimary == 't' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD
		&&  scoreboard_selected_player)
		{
			localcmd(strcat("commandmode tell \"", entcs_GetName(scoreboard_selected_player.sv_entnum), "^7\"\n"));
			HUD_Scoreboard_UI_Disable();
		}
	}
	else if (nPrimary == 'k' && (hudShiftState & S_CTRL))
	{
		if (!key_pressed)
			return true;
		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD
		&&  scoreboard_selected_player)
			localcmd(strcat("vcall kick \"", entcs_GetName(scoreboard_selected_player.sv_entnum), "^7\"\n"));
	}
	else if (hit_con_bind || nPrimary == K_PAUSE)
		return false;

	return true;
}

void Scoreboard_InitScores()
{
	ps_primary = ps_secondary = NULL;
	ts_primary = ts_secondary = -1;

	int f;
	FOREACH(Scores, !(scores_flags(it) & SFL_NOT_SORTABLE),
	{
		f = (scores_flags(it) & SFL_SORT_PRIO_MASK);
		if (f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = it;
		if (f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = it;
	});
	if (ps_secondary == NULL)
		ps_secondary = ps_primary;

	for (int i = 0; i < MAX_TEAMSCORE; ++i)
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

	numplayers = 0;
	//int num = 0;
	for (entity tmp, pl = players.sort_next; pl; pl = pl.sort_next)
	{
		numplayers += pl.team != NUM_SPECTATOR;
		//++num;
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
		print(strcat("PNUM: ", itos(num), "\n"));
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

	FOREACH(Scores, (it != ps_primary && it != ps_secondary),
	{
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
	for (int r, i = -2; i < MAX_TEAMSCORE; ++i)
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

bool deathscoreboard; ///< Whether the scoreboard is displaying because we're dead - hide accuracy & item stats & rankings
bool Scoreboard_WouldDraw()
{
	deathscoreboard = false;
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
		if (gametype.m_1v1) // display all info if 1v1 even if dead - only 2 players, lots of room
			deathscoreboard = true;
		return true;
	}
	else if (scoreboard_showscores_force || MUTATOR_CALLHOOK(DrawScoreboard_Force))
		return true;
	return false;
}

vector Scoreboard_Spectators_Draw(vector pos)
{
	string str = "";

	for (entity tm, pl = players.sort_next; pl; pl = pl.sort_next)
		if (pl.team == NUM_SPECTATOR)
		{
			for (tm = teams.sort_next; tm; tm = tm.sort_next)
				if (tm.team == NUM_SPECTATOR)
					break;
			str = strcat(_("Spectators"), sprintf(_(" (%s)"), itos(tm.team_size)));
			draw_beginBoldFont();
			drawstring(pos, str, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			draw_endBoldFont();
			pos.y += 1.25 * hud_fontsize.y;

			pos = Scoreboard_DrawOthers(pos, '0 0 0', pl.team, NULL, pl, 0);
			pos.y += 1.25 * hud_fontsize.y;

			break;
		}

	if (str != "") // if there's at least one spectator
		pos.y += 0.5 * hud_fontsize.y;

	return pos;
}

string Scoreboard_Fraglimit_Draw(float limit, bool is_leadlimit, bool is_last)
{
	string s_label = (teamplay) ? teamscores_label(ts_primary) : scores_label(ps_primary);
	int s_flags = (teamplay) ? teamscores_flags(ts_primary) : scores_flags(ps_primary);

	if (autocvar_hud_panel_scoreboard_minimal && !is_last) // only add the label at the end (is_last) if minimal
		return strcat((is_leadlimit ? "^5+" : "^5"), ScoreString(s_flags, limit, 0));
	return strcat("^5", sprintf((is_leadlimit ? _("+%s %s") : _("%s %s")), ScoreString(s_flags, limit, 0),
		(s_label == "score") ? CTX(_("SCO^points")) :
		(s_label == "fastest") ? "" : TranslateScoresLabel(s_label)));
}

string sb_gameinfo_type_iconpath = string_null;
vector sb_gameinfo_type_iconsize;
void Scoreboard_Draw(bool should_draw)
{
	if (!should_draw)
		return;
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
			if (scoreboard_fade_alpha < 1 && autocvar_hud_panel_scoreboard_fadeinspeed && frametime)
				scoreboard_fade_alpha = min(1, scoreboard_fade_alpha + frametime * autocvar_hud_panel_scoreboard_fadeinspeed);
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
			if (scoreboard_fade_alpha > 0 && autocvar_hud_panel_scoreboard_fadeoutspeed && frametime)
				scoreboard_fade_alpha = max(0, scoreboard_fade_alpha - frametime * autocvar_hud_panel_scoreboard_fadeoutspeed);
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
	fixed_scoreboard_width = bound(vid_conwidth * autocvar_hud_panel_scoreboard_minwidth, vid_conwidth - excess, vid_conwidth * 0.9);
	panel_pos.x = 0.5 * (vid_conwidth - fixed_scoreboard_width);
	panel_size.x = fixed_scoreboard_width;

	// field sizes can be initialized now after panel_size.x calculation
	if (!sbt_field_size[0] || sb_field_sizes_init)
	{
		bool compress = (sb_field_sizes_init == 2);
		Scoreboard_InitFieldSizes(compress);
		sb_field_sizes_init = 0;
	}

	Scoreboard_UpdatePlayerTeams();

	vector pos = panel_pos;
	scoreboard_pos = pos;

	if (scoreboard_ui_enabled)
		drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), '0 0 0', 0.7 * panel_fade_alpha, DRAWFLAG_NORMAL);

	// Begin of Game Info Section
	vector sb_gameinfo_type_fontsize = hud_fontsize * 2;
	vector sb_gameinfo_detail_fontsize = hud_fontsize * 1.3;
	vector tmp, type_pos = pos;
	if (!autocvar_hud_panel_scoreboard_minimal) // will draw the gametype name, keep space for it
		pos.y += sb_gameinfo_type_fontsize.y;
	else // no gametype name, but keep space for the Next map text
		pos.y += hud_fontsize.y * 1.25;

	// Game Info: game detail
	string str;
	if (scoreboard_ui_enabled == 2)
	{
		if (scoreboard_selected_team)
			str = sprintf(_("^7Press ^3%s^7 to join the selected team"), translate_key("SPACE"));
		else
			str = sprintf(_("^7Press ^3%s^7 to auto-select a team and join"), translate_key("SPACE"));
		tmp = pos;
		tmp.x += 0.5 * (panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize)); // center
		drawcolorcodedstring(tmp, str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += sb_gameinfo_detail_fontsize.y + hud_fontsize.y * 0.3;

		str = sprintf(_("^7Press ^3%s ^7to select a specific team"), translate_key("TAB"));
		tmp = pos;
		tmp.x += 0.5 * (panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize)); // center
		drawcolorcodedstring(tmp, str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
	{
		// Next map
		if (GET_NEXTMAP() != "")
		{
			str = strcat("^7", _("Next map:"), " ^9", GET_NEXTMAP());
			tmp = pos;
			tmp.x += hud_fontsize.x * 0.5;
			tmp.y -= hud_fontsize.y * 1.25;
			drawcolorcodedstring(tmp, str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		}

		float tl = STAT(TIMELIMIT);
		float fl = STAT(FRAGLIMIT);
		float ll = STAT(LEADLIMIT);
		str = "";
		if (tl > 0)
			str = strcat(str, "^3", count_minutes(floor(tl)));
		if (!gametype.m_hidelimits)
		{
			bool draw_ll = (ll > 0 && (ll < fl || fl <= 0));
			if (fl > 0)
			{
				if (tl > 0)
					str = strcat(str, "^7 / "); // delimiter
				str = strcat(str, Scoreboard_Fraglimit_Draw(fl, false, !draw_ll));
			}
			if (draw_ll)
			{
				if (tl > 0 || fl > 0)
				{
					// delimiter
					if (STAT(LEADLIMIT_AND_FRAGLIMIT) && fl > 0)
						str = strcat(str, "^7 & ");
					else
						str = strcat(str, "^7 / ");
				}
				str = strcat(str, Scoreboard_Fraglimit_Draw(ll, true, true));
			}
		}
		tmp = pos;
		tmp.x += panel_size.x - stringwidth(str, true, sb_gameinfo_detail_fontsize); // align right
		drawcolorcodedstring(tmp, str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

		// Map name and player count
		if (campaign)
			str = "";
		else
			str = sprintf(_("^5%d^7/^5%d ^7players"), numplayers, srv_maxplayers ? srv_maxplayers : maxclients);
		if (autocvar_hud_panel_scoreboard_minimal)
			str = strcat("^2", mi_shortname, "    ", str);
		else
			str = strcat("^7", _("Map:"), " ^2", mi_shortname, "    ", str); // reusing "Map:" translatable string

		tmp = pos;
		if (autocvar_hud_panel_scoreboard_minimal) // gametype icon
		{
			string pic = (gametype_custom_name != "")
				? MapInfo_Type_ToIconPath(gametype_custom_netname, gametype_custom_basetype)
				: MapInfo_Type_ToIconPath(MapInfo_Type_ToString(gametype), "");
			if (pic != sb_gameinfo_type_iconpath)
			{
				sb_gameinfo_type_iconpath = pic;
				sb_gameinfo_type_iconsize = draw_getimagesize(sb_gameinfo_type_iconpath);
				// XONRELEASE TODO: xonotic-v0.9.0 after release remove if (sb_gameinfo_type_iconsize == 0) case
				if (sb_gameinfo_type_iconsize == '0 0 0') // it happens in previous engine versions (Xonotic 0.8.6 or lower) when the image is missing
					sb_gameinfo_type_iconsize = '1 1 0';
				sb_gameinfo_type_iconsize = vec2(sb_gameinfo_detail_fontsize.x * (sb_gameinfo_type_iconsize.x / sb_gameinfo_type_iconsize.y), sb_gameinfo_detail_fontsize.y);
			}

			drawpic(pos, sb_gameinfo_type_iconpath, sb_gameinfo_type_iconsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			tmp.x += sb_gameinfo_type_iconsize.x + sb_gameinfo_detail_fontsize.x * 0.25;
		}
		drawcolorcodedstring(tmp, str, sb_gameinfo_detail_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL); // align left
	}

	// Game Info: gametype name, drawn last to be on top
	if (!autocvar_hud_panel_scoreboard_minimal)
	{
		if (scoreboard_ui_enabled == 2)
			str = _("Team Selection");
		else if (gametype_custom_name != "")
			str = gametype_custom_name;
		else
			str = MapInfo_Type_ToText(gametype);

		draw_beginBoldFont();
		type_pos.x += 0.5 * (panel_size.x - stringwidth(str, true, sb_gameinfo_type_fontsize)); // center
		drawcolorcodedstring(type_pos, str, sb_gameinfo_type_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
	}

	// End of Game Info Section

	pos.y += sb_gameinfo_detail_fontsize.y + hud_fontsize.y * 0.3; // space between Game Info Section and score table
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	// Draw the scoreboard
	float scale = autocvar_hud_panel_scoreboard_table_bg_scale;
	if (scale <= 0)
		scale = 0.25;
	vector bg_size = draw_getimagesize(SCOREBOARD_BG_PATH) * scale;

	entity tm;
	if (teamplay)
	{
		vector panel_bg_color_save = panel_bg_color;
		vector team_score_baseoffset;
		vector team_size_baseoffset;
		float y_offset = panel_bg_padding + (autocvar_hud_panel_scoreboard_minimal ? 0 : 0.5) * hud_fontsize.y;
		if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
		{
			// put team score to the left of scoreboard (and team size to the right)
			team_score_baseoffset = vec2(-0.5 * hud_fontsize.x, y_offset);
			team_size_baseoffset  = vec2( 0.5 * hud_fontsize.x, y_offset);
			if (panel.current_panel_bg != "0")
			{
				team_score_baseoffset.x -= panel_bg_border;
				team_size_baseoffset.x  += panel_bg_border;
			}
		}
		else
		{
			// put team score to the right of scoreboard (and team size to the left)
			team_score_baseoffset = vec2( 0.5 * hud_fontsize.x, y_offset);
			team_size_baseoffset  = vec2(-0.5 * hud_fontsize.x, y_offset);
			if (panel.current_panel_bg != "0")
			{
				team_score_baseoffset.x += panel_bg_border;
				team_size_baseoffset.x  -= panel_bg_border;
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

		if (autocvar_hud_panel_scoreboard_minimal) // draw header table first
			pos = Scoreboard_MakeTable(pos, NULL, '0.5 0.5 0.5', bg_size, true);

		vector str_pos;
		for (tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if (tm.team == NUM_SPECTATOR)
				continue;
			if (!tm.team)
				continue;
			draw_beginBoldFont();

			// primary team score
			vector rgb = Team_ColorRGB(tm.team);
			str = ftos(tm.(teamscores(ts_primary)));
			str_pos = pos + team_score_baseoffset;
			if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
				// team score on the left (default)
				str_pos.x -= stringwidth(str, false, hud_fontsize * 1.5);
			else
				// team score on the right
				str_pos.x += panel_size.x + hud_fontsize.x * 0.5;
			drawstring(str_pos, str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

			// secondary team score, e.g. keyhunt
			if (ts_primary != ts_secondary)
			{
				str = ftos(tm.(teamscores(ts_secondary)));
				str_pos = pos + team_score_baseoffset;
				if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
					// left
					str_pos.x -= stringwidth(str, false, hud_fontsize);
				else
					// right
					str_pos.x += panel_size.x + hud_fontsize.x * 0.5;

				str_pos.y += hud_fontsize.y * (autocvar_hud_panel_scoreboard_minimal ? 1.125 : 1.5);
				drawstring(str_pos, str, hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
			}

			// team size (if set to show)
			if (autocvar_hud_panel_scoreboard_team_size_position != 0) // team size not off
			{
				str = sprintf("%d", tm.team_size);
				string denom_str = sprintf("/%d", team_size_total);;
				float numer_width = stringwidth(str, false, hud_fontsize * 1.5);

				str_pos = pos + team_size_baseoffset;
				if (autocvar_hud_panel_scoreboard_team_size_position == 1)
					// team size on the left
					str_pos.x -= numer_width + stringwidth(denom_str, false, hud_fontsize);
				else
					// team size on the right
					str_pos.x += panel_size.x + hud_fontsize.x * 0.5;

				drawstring(str_pos, str, hud_fontsize * 1.5, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
				str_pos.x += numer_width;
				str_pos.y += hud_fontsize.y * 0.5;
				drawstring(str_pos, denom_str, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			}

			draw_endBoldFont();
			if (autocvar_hud_panel_scoreboard_bg_teams_color_team > 0)
				panel_bg_color = rgb * autocvar_hud_panel_scoreboard_bg_teams_color_team;
			else if (panel_bg_color_team > 0)
				panel_bg_color = rgb * panel_bg_color_team;
			else
				panel_bg_color = rgb;
			pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size, false);
		}
		panel_bg_color = panel_bg_color_save;

		if (autocvar_hud_panel_scoreboard_minimal)
			pos.y += 0.5 * hud_fontsize.y;
	}
	else
	{
		for (tm = teams.sort_next; tm; tm = tm.sort_next)
			if (tm.team != NUM_SPECTATOR)
				break;

		// display it anyway
		pos = Scoreboard_MakeTable(pos, tm, panel_bg_color, bg_size, false);
	}

	// if the name column is too small, try to compress all other field titles
	if (sbt_field_size[name_field_index] < sbt_field_title_width[name_field_index] + hud_fontsize.x)
		sb_field_sizes_init = 2;

	// draw scoreboard spectators before accuracy and item stats
	if (autocvar_hud_panel_scoreboard_spectators_position == 0)
		pos = Scoreboard_Spectators_Draw(pos);

	// draw accuracy and item stats
	if (!deathscoreboard)
		pos = Scoreboard_AccuracyAndItemStats_Draw(pos, panel_bg_color, bg_size);

	// draw scoreboard spectators after accuracy and item stats and before rankings
	if (autocvar_hud_panel_scoreboard_spectators_position == 1)
		pos = Scoreboard_Spectators_Draw(pos);

	// draw rankings
	pos = Scoreboard_RankingsAndAwards_Draw(pos, bg_size, deathscoreboard);

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
				str = sprintf(_("^1Respawning in ^3%s^1..."), (autocvar_hud_panel_scoreboard_respawntime_decimals
					? count_seconds_decs(respawn_time - time, autocvar_hud_panel_scoreboard_respawntime_decimals)
					: count_seconds(ceil(respawn_time - time))));
		}
		else if (time < respawn_time)
			str = sprintf(_("You are dead, wait ^3%s^7 before respawning"), (autocvar_hud_panel_scoreboard_respawntime_decimals
				? count_seconds_decs(respawn_time - time, autocvar_hud_panel_scoreboard_respawntime_decimals)
				: count_seconds(ceil(respawn_time - time))));
		else if (time >= respawn_time)
			str = sprintf(_("You are dead, press ^2%s^7 to respawn"), getcommandkey(_("jump"), "+jump"));

		pos.y += 1.2 * hud_fontsize.y;
		tmp = pos;
		tmp.x += 0.5 * (panel_size.x - stringwidth(str, true, hud_fontsize)); // center
		drawcolorcodedstring(tmp, str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	pos.y += hud_fontsize.y;
	scoreboard_size = vec2(panel_size.x, pos.y - scoreboard_pos.y);
	scoreboard_bottom.x = scoreboard_pos.x + scoreboard_size.x;
	if (scoreboard_fade_alpha < 1)
		scoreboard_bottom.y = scoreboard_pos.y + scoreboard_size.y * scoreboard_fade_alpha;
	else if (pos.y != scoreboard_bottom.y)
	{
		if (pos.y > scoreboard_bottom.y)
			scoreboard_bottom.y = min(pos.y, scoreboard_bottom.y + frametime * 10 * scoreboard_size.y);
		else
			scoreboard_bottom.y = max(pos.y, scoreboard_bottom.y - frametime * 10 * scoreboard_size.y);
	}

	if (rankings_cnt)
	{
		if (scoreboard_fade_alpha == 1)
		{
			if (scoreboard_bottom.y > 0.95 * vid_conheight)
				rankings_rows = max(1, rankings_rows - 1);
			else if (scoreboard_bottom.y + 1.25 * hud_fontsize.y < 0.95 * vid_conheight)
				rankings_rows = min(ceil(RANKINGS_RECEIVED_CNT / rankings_columns), rankings_rows + 1);
		}
		rankings_cnt = rankings_rows * rankings_columns;
	}
}
