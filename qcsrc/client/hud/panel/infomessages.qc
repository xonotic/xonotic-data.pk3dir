#include "infomessages.qh"

#include <common/ent_cs.qh>
#include <common/mapinfo.qh>

// Info messages panel (#14)

float autocvar_hud_panel_infomessages_group_fadetime = 0.4;
float autocvar_hud_panel_infomessages_group_time = 6;
const int IMG_COUNT = 1; // number of InfoMessage Groups
float img_fade[IMG_COUNT];
int img_id[IMG_COUNT];
float img_time[IMG_COUNT];

int img_select(int group_id, int msg_cnt)
{
	float fadetime = max(0.001, autocvar_hud_panel_infomessages_group_fadetime);
	if(time > img_time[group_id])
	{
		img_fade[group_id] = max(0, img_fade[group_id] - frametime / fadetime);
		if(!img_fade[group_id])
		{
			++img_id[group_id];
			img_time[group_id] = floor(time) + autocvar_hud_panel_infomessages_group_time;
		}
	}
	else
		img_fade[group_id] = min(1, img_fade[group_id] + frametime / fadetime);
	return img_id[group_id] % msg_cnt;
}

float stringwidth_colors(string s, vector theSize);
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
	return pos;
}

#define InfoMessage(s, a) pos = InfoMessages_drawstring(s, pos, mySize, a, fontsize)

void HUD_InfoMessages()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_infomessages) return;
	}

	HUD_Panel_UpdateCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_infomessages_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	vector fontsize = '0.2 0.2 0' * mySize.y;
	string s;
	if(!autocvar__hud_configure)
	{
		float img_group;
		if(spectatee_status)
		{
			if(spectatee_status == -1)
				s = _("^1Observing");
			else
				s = sprintf(_("^1Spectating: ^7%s"), entcs_GetName(current_player));
			InfoMessage(s, panel_fg_alpha);

			img_group = 0;
			switch(img_select(img_group, 3))
			{
				default:
				case 0:
					if(spectatee_status == -1)
						s = sprintf(_("^1Press ^3%s^1 to spectate"), getcommandkey(_("primary fire"), "+fire"));
					else
						s = sprintf(_("^1Press ^3%s^1 or ^3%s^1 for next or previous player"), getcommandkey(_("next weapon"), "weapnext"), getcommandkey(_("previous weapon"), "weapprev"));
					break;
				case 1:
					if(spectatee_status == -1)
						s = sprintf(_("^1Use ^3%s^1 or ^3%s^1 to change the speed"), getcommandkey(_("next weapon"), "weapnext"), getcommandkey(_("previous weapon"), "weapprev"));
					else
						s = sprintf(_("^1Press ^3%s^1 to observe, ^3%s^1 to change camera mode"), getcommandkey(_("secondary fire"), "+fire2"), getcommandkey(_("drop weapon"), "dropweapon"));
					break;
				case 2:
					s = sprintf(_("^1Press ^3%s^1 for gamemode info"), getcommandkey(_("server info"), "+show_info"));
					break;
			}
			InfoMessage(s, img_fade[img_group] * panel_fg_alpha);

			if(gametype == MAPINFO_TYPE_LMS)
			{
				entity sk;
				sk = playerslots[player_localnum];
				if(sk.(scores[ps_primary]) >= 666)
					s = _("^1Match has already begun");
				else if(sk.(scores[ps_primary]) > 0)
					s = _("^1You have no more lives left");
				else
					s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey(_("jump"), "+jump"));
			}
			else
				s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey(_("jump"), "+jump"));
			InfoMessage(s, panel_fg_alpha);
		}

		if (time < STAT(GAMESTARTTIME))
		{
			//we need to ceil, otherwise the countdown would be off by .5 when using round()
			float countdown = ceil(STAT(GAMESTARTTIME) - time);
			s = sprintf(_("^1Game starts in ^3%d^1 seconds"), countdown);
			InfoMessage(s, panel_fg_alpha);
		}

		if(warmup_stage)
		{
			s = _("^2Currently in ^1warmup^2 stage!");
			InfoMessage(s, panel_fg_alpha);
		}

		string blinkcolor;
		if(time % 1 >= 0.5)
			blinkcolor = "^1";
		else
			blinkcolor = "^3";

		if(ready_waiting && !spectatee_status)
		{
			if(ready_waiting_for_me)
			{
				if(warmup_stage)
					s = sprintf(_("%sPress ^3%s%s to end warmup"), blinkcolor, getcommandkey(_("ready"), "ready"), blinkcolor);
				else
					s = sprintf(_("%sPress ^3%s%s once you are ready"), blinkcolor, getcommandkey(_("ready"), "ready"), blinkcolor);
			}
			else
			{
				if(warmup_stage)
					s = _("^2Waiting for others to ready up to end warmup...");
				else
					s = _("^2Waiting for others to ready up...");
			}
			InfoMessage(s, panel_fg_alpha);
		}
		else if(warmup_stage && !spectatee_status)
		{
			s = sprintf(_("^2Press ^3%s^2 to end warmup"), getcommandkey(_("ready"), "ready"));
			InfoMessage(s, panel_fg_alpha);
		}

		if(teamplay && !spectatee_status && gametype != MAPINFO_TYPE_CA && teamnagger)
		{
			float ts_min = 0, ts_max = 0;
			entity tm = teams.sort_next;
			if (tm)
			{
				for (; tm.sort_next; tm = tm.sort_next)
				{
					if(!tm.team_size || tm.team == NUM_SPECTATOR)
						continue;
					if(!ts_min) ts_min = tm.team_size;
					else ts_min = min(ts_min, tm.team_size);
					if(!ts_max) ts_max = tm.team_size;
					else ts_max = max(ts_max, tm.team_size);
				}
				if ((ts_max - ts_min) > 1)
				{
					s = strcat(blinkcolor, _("Teamnumbers are unbalanced!"));
					tm = GetTeam(myteam, false);
					if (tm && tm.team != NUM_SPECTATOR && tm.team_size == ts_max)
						s = strcat(s, sprintf(_(" Press ^3%s%s to adjust"), getcommandkey(_("team menu"), "menu_showteamselect"), blinkcolor));
					InfoMessage(s, panel_fg_alpha);
				}
			}
		}
	}
	else
	{
		InfoMessage(_("^7Press ^3ESC ^7to show HUD options."), panel_fg_alpha);
		InfoMessage(_("^3Doubleclick ^7a panel for panel-specific options."), panel_fg_alpha);
		InfoMessage(_("^3CTRL ^7to disable collision testing, ^3SHIFT ^7and"), panel_fg_alpha);
		InfoMessage(_("^3ALT ^7+ ^3ARROW KEYS ^7for fine adjustments."), panel_fg_alpha);
	}
}
