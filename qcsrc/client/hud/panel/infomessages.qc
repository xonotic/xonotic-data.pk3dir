#include "infomessages.qh"
#include "racetimer.qh" // for race_checkpoint_splits
#include <common/gamemodes/gamemode/race/race.qh> // for ISGAMETYPE(RACE)

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
	if(time > img_time[group_id])
	{
		img_fade[group_id] = max(0, img_fade[group_id] - frametime / fadetime);
		if(!img_fade[group_id])
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
	while(getWrappedLine_remaining)
	{
		s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
		if(autocvar_hud_panel_infomessages_flip)
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

void HUD_InfoMessages()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_infomessages) return;
	}

	HUD_Panel_LoadCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_infomessages_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	vector fontsize = '0.2 0.2 0' * mySize.y;
	string s;
	int img_curr_group = -1;
	if(!autocvar__hud_configure)
	{
		if(spectatee_status)
		{
			if(spectatee_status == -1)
				s = _("Observing");
			else
				s = sprintf(_("Spectating: %s"), strcat(CCR_BG, entcs_GetName(current_player)));
			s = strcat(CCR_F4, s);
			InfoMessage(s);

			if(autocvar_hud_panel_infomessages_group0)
			{
				img_curr_group = 0;
				switch(img_select(img_curr_group) % 3)
				{
					default:
					case 0:
						if(spectatee_status == -1)
							s = sprintf(_("Press %s to spectate"), strcat(CCR_F2, getcommandkey(_("primary fire"), "+fire"), CCR_F4));
						else
							s = sprintf(_("Press %s or %s for next or previous player"), strcat(CCR_F2, getcommandkey(_("next weapon"), "weapnext"), CCR_F4), strcat(CCR_F2, getcommandkey(_("previous weapon"), "weapprev"), CCR_F4));
						break;
					case 1:
						if(spectatee_status == -1)
							s = sprintf(_("Use %s or %s to change the speed"), strcat(CCR_F2, getcommandkey(_("next weapon"), "weapnext"), CCR_F4), strcat(CCR_F2, getcommandkey(_("previous weapon"), "weapprev"), CCR_F4));
						else if(!observe_blocked)
							s = sprintf(_("Press %s to observe, %s to change camera mode"), strcat(CCR_F2, getcommandkey(_("secondary fire"), "+fire2"), CCR_F4), strcat(CCR_F2, getcommandkey(_("drop weapon"), "dropweapon"), CCR_F4));
						else
							s = sprintf(_("Press %s to change camera mode"), strcat(CCR_F2, getcommandkey(_("drop weapon"), "dropweapon"), CCR_F4));
						break;
					case 2:
						s = sprintf(_("Press %s for gamemode info"), strcat(CCR_F2, getcommandkey(_("server info"), "+show_info"), CCR_F4));
						break;
				}
				s = strcat(CCR_F4, s);
				InfoMessage(s);
			}

			bool mutator_returnvalue = MUTATOR_CALLHOOK(DrawInfoMessages, pos, mySize, img_curr_group);
			pos = M_ARGV(0, vector);
			img_curr_group = M_ARGV(2, int);

			if(!mutator_returnvalue)
			{
				int tm = entcs_GetWantsJoin(current_player);
				if(tm > 0)
				{
					tm = Team_IndexToTeam(tm);
					s = strcat(CCR_F1, sprintf(_("You're queued to join the %s team"), strcat(Team_ColorCode(tm), Team_ColorName(tm), CCR_F1)));
				}
				else if (tm < 0)
					s = strcat(CCR_F1, sprintf(_("You're queued to join any available team")));
				else
					s = strcat(CCR_F4, sprintf(_("Press %s to join"), strcat(CCR_F2, getcommandkey(_("jump"), "+jump"), CCR_F4)));
				InfoMessage(s);
			}
		}

		if (time < STAT(GAMESTARTTIME))
		{
			//we need to ceil, otherwise the countdown would be off by .5 when using round()
			float countdown = ceil(STAT(GAMESTARTTIME) - time);
			s = strcat(CCR_F4, sprintf(_("Game starts in %s seconds"), strcat(CCR_F2, ftos_decimals(countdown, 0), CCR_F4)));
			InfoMessage(s);
		}

		string blinkcolor;
		if(time % 1 >= 0.5)
			blinkcolor = CCR_F4;
		else
			blinkcolor = CCR_F2;

		if(warmup_stage)
		{
			InfoMessage(strcat(CCR_F1, sprintf(_("Currently in %s stage!"), strcat(CCR_F4, _("warmup"), CCR_F1))));

			int players_needed = 0;
			Scoreboard_UpdatePlayerTeams(); // ensure numplayers, ts_min, ts_max are current
			if(STAT(WARMUP_TIMELIMIT) <= 0 && srv_minplayers)
				players_needed = srv_minplayers - numplayers;

			if(players_needed > 0)
			{
				if(players_needed == 1)
					s = sprintf(_("%s more player is needed for the match to start."), strcat(CCR_F2, "1", CCR_F1));
				else
					s = sprintf(_("%s more players are needed for the match to start."), strcat(CCR_F2, ftos_decimals(players_needed, 0), CCR_F1));
				InfoMessage(s);
			}
			else if(teamnagger && (ts_max - ts_min) >= teamnagger)
			{
				// ready won't end warmup so don't display that message
				// see below for unbalanced teams warning
			}
			else if(!spectatee_status)
			{
				if(ready_waiting)
				{
					if(ready_waiting_for_me)
						s = strcat(blinkcolor, sprintf(_("Press %s to end warmup"), strcat(CCR_F2, getcommandkey(_("ready"), "ready"), blinkcolor)));
					else
						s = strcat(CCR_F1, _("Waiting for others to ready up to end warmup..."));
				}
				else
					s = strcat(CCR_F1, sprintf(_("Press %s to end warmup"), strcat(CCR_F2, getcommandkey(_("ready"), "ready"), CCR_F1)));
				InfoMessage(s);
			}
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
					s = strcat(s, sprintf(_(" Press %s to adjust"), strcat(CCR_F2, getcommandkey(_("team selection"), "team_selection_show"), blinkcolor)));
				fontsize *= 1.125; // perfect float
				draw_beginBoldFont();
				InfoMessage(s);
				draw_endBoldFont();
				fontsize /= 1.125;
			}
		}

		if(autocvar_cl_showspectators)
		if(num_spectators)
		//if(spectatee_status != -1)
		{
			s = strcat(CCR_F4, (spectatee_status) ? _("Spectating this player:") : _("Spectating you:"));
			// InfoMessage(s)
			int limit = min(num_spectators, MAX_SPECTATORS);
			for(int i = 0; i < limit; ++i)
			{
				float slot = spectatorlist[i];
				if(i == 0)
					s = strcat(s, " ", CCR_BG, entcs_GetName(slot));
				else
					s = strcat(CCR_BG, entcs_GetName(slot));
				InfoMessage(s);
			}
		}
		if(autocvar_cl_race_checkpoint_splits_hud && !spectatee_status) {
			int lines[6];
			int ln = 5;
			// show up to race_nextcheckpoint (not including) or everything
			// if you are before start (0 or 254)
			// (except race_laptime != 0 for race, means next is
			// start+finish so don't show previous lap finish)
			int i;
			if (race_checkpoint != 0 && race_checkpoint != 254)
			{ // middle of run/race
				i = race_checkpoint;
			}
			else if (ISGAMETYPE(RACE) && race_nextcheckpoint == 0)
			{ // before start, but on race, so don't keep old finish visible
				i = 253;
			}
			else
			{ // before start, not on race (cts), keep old run cps visible
				i = 255;
			}
			for (; ln >= 0 && i >= 0; --i)
			{
				if (race_checkpoint_splits[i])
				{
					lines[ln] = i;
					--ln;
				}
			}
			for (int j = 0; j < 6; ++j)
				InfoMessage(race_checkpoint_splits[lines[j]]);
		}
	}
	else
	{
		InfoMessage(strcat(CCR_BG, sprintf(_("Press %s to show HUD options."), strcat(CCR_F2, "ESC", CCR_BG))));
		InfoMessage(sprintf(_("%s a panel for panel-specific options."), strcat(CCR_F2, "Doubleclick", CCR_BG)));
		InfoMessage(sprintf(_("%s to disable collision testing, %s and"), strcat(CCR_F2, "CTRL", CCR_BG), strcat(CCR_F2, "SHIFT", CCR_BG)));
		InfoMessage(sprintf(_("%s + %s for fine adjustments."), strcat(CCR_F2, "ALT", CCR_BG), strcat(CCR_F2, "ARROW KEYS", CCR_BG)));
	}
}
