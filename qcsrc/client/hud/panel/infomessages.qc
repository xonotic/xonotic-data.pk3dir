// Info messages panel (#14)

#define drawInfoMessage(s) MACRO_BEGIN {																			\
	if(autocvar_hud_panel_infomessages_flip)																		\
		o.x = pos.x + mySize.x - stringwidth(s, true, fontsize);													\
	drawcolorcodedstring(o, s, fontsize, a, DRAWFLAG_NORMAL);														\
	o.y += fontsize.y;																								\
} MACRO_END
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

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 5:1 aspect
	vector newSize = '0 0 0';
	if(mySize.x/mySize.y > 5)
	{
		newSize.x = 5 * mySize.y;
		newSize.y = mySize.y;

		pos.x = pos.x + (mySize.x - newSize.x) / 2;
	}
	else
	{
		newSize.y = 1/5 * mySize.x;
		newSize.x = mySize.x;

		pos.y = pos.y + (mySize.y - newSize.y) / 2;
	}

	mySize = newSize;
	entity tm;
	vector o;
	o = pos;

	vector fontsize;
	fontsize = '0.20 0.20 0' * mySize.y;

	float a;
	a = panel_fg_alpha;

	string s;
	if(!autocvar__hud_configure)
	{
		if(spectatee_status && !intermission)
		{
			a = 1;
			if(spectatee_status == -1)
				s = _("^1Observing");
			else
				s = sprintf(_("^1Spectating: ^7%s"), entcs_GetName(current_player));
			drawInfoMessage(s);

			if(spectatee_status == -1)
				s = sprintf(_("^1Press ^3%s^1 to spectate"), getcommandkey("primary fire", "+fire"));
			else
				s = sprintf(_("^1Press ^3%s^1 or ^3%s^1 for next or previous player"), getcommandkey("next weapon", "weapnext"), getcommandkey("previous weapon", "weapprev"));
			drawInfoMessage(s);

			if(spectatee_status == -1)
				s = sprintf(_("^1Use ^3%s^1 or ^3%s^1 to change the speed"), getcommandkey("next weapon", "weapnext"), getcommandkey("previous weapon", "weapprev"));
			else
				s = sprintf(_("^1Press ^3%s^1 to observe"), getcommandkey("secondary fire", "+fire2"));
			drawInfoMessage(s);

			s = sprintf(_("^1Press ^3%s^1 for gamemode info"), getcommandkey("server info", "+show_info"));
			drawInfoMessage(s);

			if(gametype == MAPINFO_TYPE_LMS)
			{
				entity sk;
				sk = playerslots[player_localnum];
				if(sk.(scores[ps_primary]) >= 666)
					s = _("^1Match has already begun");
				else if(sk.(scores[ps_primary]) > 0)
					s = _("^1You have no more lives left");
				else
					s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey("jump", "+jump"));
			}
			else
				s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey("jump", "+jump"));
			drawInfoMessage(s);

			//show restart countdown:
			if (time < STAT(GAMESTARTTIME)) {
				float countdown;
				//we need to ceil, otherwise the countdown would be off by .5 when using round()
				countdown = ceil(STAT(GAMESTARTTIME) - time);
				s = sprintf(_("^1Game starts in ^3%d^1 seconds"), countdown);
				drawcolorcodedstring(o, s, fontsize, a, DRAWFLAG_NORMAL);
				o.y += fontsize.y;
			}
		}
		if(warmup_stage && !intermission)
		{
			s = _("^2Currently in ^1warmup^2 stage!");
			drawInfoMessage(s);
		}

		string blinkcolor;
		if(time % 1 >= 0.5)
			blinkcolor = "^1";
		else
			blinkcolor = "^3";

		if(ready_waiting && !intermission && !spectatee_status)
		{
			if(ready_waiting_for_me)
			{
				if(warmup_stage)
					s = sprintf(_("%sPress ^3%s%s to end warmup"), blinkcolor, getcommandkey("ready", "ready"), blinkcolor);
				else
					s = sprintf(_("%sPress ^3%s%s once you are ready"), blinkcolor, getcommandkey("ready", "ready"), blinkcolor);
			}
			else
			{
				if(warmup_stage)
					s = _("^2Waiting for others to ready up to end warmup...");
				else
					s = _("^2Waiting for others to ready up...");
			}
			drawInfoMessage(s);
		}
		else if(warmup_stage && !intermission && !spectatee_status)
		{
			s = sprintf(_("^2Press ^3%s^2 to end warmup"), getcommandkey("ready", "ready"));
			drawInfoMessage(s);
		}

		if(teamplay && !intermission && !spectatee_status && gametype != MAPINFO_TYPE_CA && teamnagger)
		{
			float ts_min = 0, ts_max = 0;
			tm = teams.sort_next;
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
					if (tm)
					if (tm.team != NUM_SPECTATOR)
					if (tm.team_size == ts_max)
						s = strcat(s, sprintf(_(" Press ^3%s%s to adjust"), getcommandkey("team menu", "menu_showteamselect"), blinkcolor));
					drawInfoMessage(s);
				}
			}
		}
	}
	else
	{
		s = _("^7Press ^3ESC ^7to show HUD options.");
		drawInfoMessage(s);
		s = _("^3Doubleclick ^7a panel for panel-specific options.");
		drawInfoMessage(s);
		s = _("^3CTRL ^7to disable collision testing, ^3SHIFT ^7and");
		drawInfoMessage(s);
		s = _("^3ALT ^7+ ^3ARROW KEYS ^7for fine adjustments.");
		drawInfoMessage(s);
	}
}
