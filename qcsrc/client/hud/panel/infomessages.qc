#include "infomessages.qh"

#include <client/draw.qh>
#include <common/ent_cs.qh>

// Info messages (#14)

void HUD_InfoMessages_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_infomessages_flip");
}

float autocvar_hud_panel_infomessages_group0 = 1;
float autocvar_hud_panel_infomessages_group_fadetime = 0.4;
float autocvar_hud_panel_infomessages_group_time = 6;
const int IMG_COUNT = 1; // number of InfoMessage Groups
float img_fade[IMG_COUNT];
int img_cur_msg[IMG_COUNT];
float img_time[IMG_COUNT];

int img_select(int group_id)
{
	float fadetime = max(0.001, autocvar_hud_panel_infomessages_group_fadetime);
	if (time > img_time[group_id])
	{
		img_fade[group_id] = max(0, img_fade[group_id] - frametime / fadetime);
		if (!img_fade[group_id])
		{
			++img_cur_msg[group_id];
			img_time[group_id] = floor(time) + autocvar_hud_panel_infomessages_group_time;
		}
	}
	else
		img_fade[group_id] = min(1, img_fade[group_id] + frametime / fadetime);
	return img_cur_msg[group_id];
}

vector InfoMessages_drawstring(string s, vector pos, vector sz, float a, vector fontsize)
{
	getWrappedLine_remaining = s;
	float offset = 0;
	while (getWrappedLine_remaining)
	{
		s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
		if (autocvar_hud_panel_infomessages_flip)
			offset = sz.x - stringwidth_colors(s, fontsize) - offset;
		drawcolorcodedstring(pos + eX * offset, s, fontsize, a, DRAWFLAG_NORMAL);
		pos.y += fontsize.y;
		offset = fontsize.x;
	}
	pos.y += fontsize.y * 0.25;
	return pos;
}

#define InfoMessage(s) MACRO_BEGIN \
	pos = InfoMessages_drawstring(s, pos, mySize, ((img_curr_group >= 0) ? panel_fg_alpha * img_fade[img_curr_group] : panel_fg_alpha), fontsize); \
	img_curr_group = -1; \
MACRO_END

string get_team_list(int team_mask, string suf_col)
{
	return strcat(
		((team_mask & BIT(0)) ? strcat(Team_ColoredFullName_WithSuffixColor(NUM_TEAM_1, suf_col), (team_mask >> 1) ? ", " : "") : ""),
		((team_mask & BIT(1)) ? strcat(Team_ColoredFullName_WithSuffixColor(NUM_TEAM_2, suf_col), (team_mask >> 2) ? ", " : "") : ""),
		((team_mask & BIT(2)) ? strcat(Team_ColoredFullName_WithSuffixColor(NUM_TEAM_3, suf_col), (team_mask >> 3) ? ", " : "") : ""),
		((team_mask & BIT(3)) ? Team_ColoredFullName_WithSuffixColor(NUM_TEAM_4, suf_col) : "")
	);
}

void HUD_InfoMessages()
{
	if (!autocvar__hud_configure && !autocvar_hud_panel_infomessages)
		return;

	HUD_Panel_LoadCvars();
	vector pos = panel_pos;
	vector mySize = panel_size;

	if (autocvar_hud_panel_infomessages_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if (panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	vector fontsize = '0.2 0.2 0' * mySize.y;
	int img_curr_group = -1;

	if (!autocvar__hud_configure)
	{
		string s;
		int wants_join = teamplay ? entcs_GetWantsJoin(current_player) : 0;

		if (spectatee_status)
		{
			if (spectatee_status == -1)
				s = _("^1Observing");
			else
				s = sprintf(_("^1Spectating: ^7%s"), entcs_GetName(current_player));
			InfoMessage(s);

			if (autocvar_hud_panel_infomessages_group0)
			{
				img_curr_group = 0;
				switch (img_select(img_curr_group) % 3)
				{
					default:
					case 0:
						if (spectatee_status == -1)
							s = sprintf(_("^1Press ^3%s^1 to spectate"), getcommandkey(_("primary fire"), "+fire"));
						else
							s = sprintf(_("^1Press ^3%s^1 or ^3%s^1 for next or previous player"), getcommandkey(_("next weapon"), "weapnext"), getcommandkey(_("previous weapon"), "weapprev"));
						break;
					case 1:
						if (spectatee_status == -1)
							s = sprintf(_("^1Use ^3%s^1 or ^3%s^1 to change the speed"), getcommandkey(_("next weapon"), "weapnext"), getcommandkey(_("previous weapon"), "weapprev"));
						else if (!observe_blocked)
							s = sprintf(_("^1Press ^3%s^1 to observe, ^3%s^1 to change camera mode"), getcommandkey(_("secondary fire"), "+fire2"), getcommandkey(_("drop weapon"), "dropweapon"));
						else
							s = sprintf(_("^1Press ^3%s^1 to change camera mode"), getcommandkey(_("drop weapon"), "dropweapon"));
						break;
					case 2:
						s = sprintf(_("^1Press ^3%s^1 for gametype info"), getcommandkey(_("server info"), "+show_info"));
						break;
				}
				InfoMessage(s);
			}

			bool mutator_returnvalue = MUTATOR_CALLHOOK(DrawInfoMessages, pos, mySize, img_curr_group);
			pos = M_ARGV(0, vector);
			img_curr_group = M_ARGV(2, int);

			if (!mutator_returnvalue && !wants_join)
				InfoMessage(sprintf(_("^1Press ^3%s^1 to join"), getcommandkey(_("jump"), "+jump")));
		}

		if (wants_join > 0)
		{
			wants_join = Team_IndexToTeam(wants_join);
			InfoMessage(sprintf(_("^2You're queued to join the %s%s^2 team"), Team_ColorCode(wants_join), Team_ColorName(wants_join)));
		}
		else if (wants_join < 0)
			InfoMessage(sprintf(_("^2You're queued to join any available team")));

		if (time < STAT(GAMESTARTTIME))
		{
			//we need to ceil, otherwise the countdown would be off by .5 when using round()
			float countdown = ceil(STAT(GAMESTARTTIME) - time);
			s = sprintf(_("^1Game starts in ^3%d^1 seconds"), countdown);
			InfoMessage(s);
		}

		string blinkcolor = (time % 1 >= 0.5) ? "^1" : "^3";

		if (warmup_stage)
		{
			InfoMessage(_("^2Currently in ^1warmup^2 stage!"));

			int players_needed = 0;
			Scoreboard_UpdatePlayerTeams(); // ensure numplayers, ts_min, ts_max are current
			if (STAT(WARMUP_TIMELIMIT) <= 0 && srv_minplayers)
				players_needed = srv_minplayers - numplayers;

			if (players_needed > 0)
			{
				if (players_needed == 1)
					s = _("^31^2 more player is needed for the match to start.");
				else
					s = sprintf(_("^3%d^2 more players are needed for the match to start."), players_needed);
				InfoMessage(s);
			}
			else if (teamnagger && (ts_max - ts_min) >= teamnagger)
			{
				// ready won't end warmup so don't display that message
				// see below for unbalanced teams warning
			}
			else if (!spectatee_status)
			{
				string ready_key = getcommandkey(_("ready"), "ready");
				if (ready_waiting)
				{
					if (ready_waiting_for_me)
						s = sprintf(_("%sPress ^3%s%s to end warmup"), blinkcolor, ready_key, blinkcolor);
					else
						s = _("^2Waiting for others to ready up to end warmup...");
				}
				else
					s = sprintf(_("^2Press ^3%s^2 to end warmup"), ready_key);
				InfoMessage(s);
			}
		}

		// NOTE: this stat is used for missing players in ffa games
		int missing_teams_mask = STAT(MISSING_TEAMS_MASK);
		if (missing_teams_mask)
		{
			if (teamplay)
				s = sprintf(_("%sNeed active players for: %s"), blinkcolor, get_team_list(missing_teams_mask, blinkcolor));
			else
			{
				if (missing_teams_mask == 1)
					s = sprintf(_("%sWaiting for 1 player to join..."), blinkcolor);
				else
					s = sprintf(_("%sWaiting for %d players to join..."), blinkcolor, missing_teams_mask);
			}
			InfoMessage(s);
		}

		if (teamplay && numplayers > 1 && teamnagger)
		{
			if (!warmup_stage) // in warmup this was done above
				Scoreboard_UpdatePlayerTeams();

			if ((ts_max - ts_min) >= teamnagger)
			{
				s = strcat(blinkcolor, _("Teams are unbalanced!"));
				entity tm = GetTeam(myteam, false);
				if (tm && tm.team != NUM_SPECTATOR && tm.team_size == ts_max)
					s = strcat(s, sprintf(_(" Press ^3%s%s to adjust"), getcommandkey(_("team selection"), "team_selection_show"), blinkcolor));
				fontsize *= 1.125; // perfect float
				draw_beginBoldFont();
				InfoMessage(s);
				draw_endBoldFont();
				fontsize /= 1.125;
			}
		}

		if (autocvar_cl_showspectators)
		if (num_spectators)
		//if (spectatee_status != -1)
		{
			s = ((spectatee_status) ? _("^1Spectating this player:") : _("^1Spectating you:"));
			// InfoMessage(s)
			string spec_name;
			int limit = min(num_spectators, MAX_SPECTATORS);
			for (int i = 0; i < limit; ++i)
			{
				spec_name = entcs_GetName(spectatorlist[i]);
				if (i == 0)
					s = strcat(s, " ^7", spec_name);
				else
					s = strcat("^7", spec_name);
				InfoMessage(s);
			}
		}
	}
	else
	{
		InfoMessage(_("^7Press ^3ESC ^7to show HUD options."));
		InfoMessage(_("^3Double-click ^7a panel for panel-specific options."));
		InfoMessage(_("^3CTRL ^7to disable collision testing, ^3SHIFT ^7and"));
		InfoMessage(_("^3ALT ^7+ ^3ARROW KEYS ^7for fine adjustments."));
	}
}
