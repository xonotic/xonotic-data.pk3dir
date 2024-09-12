#include "timer.qh"
#include "scoreboard.qh"

#include <client/draw.qh>
#include <client/view.qh>

// Timer (#5)

void HUD_Timer_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

string HUD_Timer_Color(float timeleft)
{
	if(timeleft <= 60)
		return CCR_C1; // red
	else if(timeleft <= 300)
		return CCR_C2; // yellow
	else
		return CCR_BG; // white
}

float HUD_Timer_TimeElapsed(float curtime, float starttime)
{
	float time_elapsed = curtime - starttime;
	if (!autocvar_hud_panel_timer_unbound)
		time_elapsed = max(0, time_elapsed);
	return floor(time_elapsed);
}

float HUD_Timer_TimeLeft(float curtime, float starttime, float timelimit)
{
	float timeleft = timelimit + starttime - curtime;
	if (!autocvar_hud_panel_timer_unbound)
		timeleft = bound(0, timeleft, timelimit);
	return ceil(timeleft);
}

void HUD_Timer()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_timer) return;
	}

	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_timer_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	string timer_str = string_null;
	string subtimer_str = string_null;
	string subtext = string_null;
	float curtime, timelimit, timeleft;
	vector timer_size, subtext_size, subtimer_size;
	string timer_color = CCR_BG;
	string subtimer_color = CCR_BG;
	bool swap = (autocvar_hud_panel_timer_secondary == 2 && STAT(ROUNDSTARTTIME));

	// Use real or frozen time and get the time limit
	curtime = (intermission_time ? intermission_time : time);
	timelimit = (warmup_stage ? STAT(WARMUP_TIMELIMIT) : STAT(TIMELIMIT) * 60);

	// Calculate time left
	timeleft = HUD_Timer_TimeLeft(curtime, STAT(GAMESTARTTIME), timelimit);

	// Timer color
	if(!intermission_time && !warmup_stage && timelimit > 0)
		timer_color = HUD_Timer_Color(timeleft);

	// Timer text
	if (autocvar_hud_panel_timer_increment || timelimit <= 0)
		timer = HUD_Timer_TimeElapsed(curtime, STAT(GAMESTARTTIME));
	else
		timer = timeleft;

	// Secondary timer for round-based game modes
	if(STAT(ROUNDSTARTTIME) && autocvar_hud_panel_timer_secondary)
	{
		if(STAT(ROUNDSTARTTIME) == -1) {
			// Round can't start
			subtimer_str = "--:--";
			subtimer_color = CCR_C1;
		} else {
			float round_curtime, round_timelimit, round_timeleft;

			// Use real or frozen time and get the time limit
			round_curtime = (game_stopped_time ? game_stopped_time : time);
			round_timelimit = STAT(ROUND_TIMELIMIT);

			// Calculate time left
			round_timeleft = HUD_Timer_TimeLeft(round_curtime, STAT(ROUNDSTARTTIME), round_timelimit);

			// Subtimer color
			if(!intermission_time && round_timelimit > 0)
				subtimer_color = HUD_Timer_Color(round_timeleft);

			// Subtimer text
			if (autocvar_hud_panel_timer_increment || round_timelimit <= 0)
				subtimer_str = seconds_tostring(HUD_Timer_TimeElapsed(round_curtime, STAT(ROUNDSTARTTIME)));
			else
				subtimer_str = seconds_tostring(round_timeleft);
		}
	}

	// Subtext
	int overtimes = STAT(OVERTIMES);

	if(warmup_stage || autocvar__hud_configure)
	{
		if (STAT(WARMUP_TIMELIMIT) > 0)
			subtext = _("Warmup");
		else
		{
			Scoreboard_UpdatePlayerTeams(); // ensure numplayers is current
			if (srv_minplayers - numplayers > 0)
				subtext = _("Warmup: too few players!");
			else if (teamnagger && (ts_max - ts_min) >= teamnagger)
				subtext = _("Warmup: teams unbalanced!");
			else
				subtext = _("Warmup: no time limit");
		}
	}
	else if(STAT(TIMEOUT_STATUS) == 2)
		subtext = _("Timeout");
	else if (overtimes == -1)
		subtext = _("Sudden Death");
	else if(overtimes == 1)
		subtext = _("Overtime");
	else if (overtimes >= 2)
		subtext = sprintf(_("Overtime #%d"), overtimes);

	subtext_size  = vec2(mySize.x, mySize.y / 3);
	timer_size    = vec2(mySize.x, mySize.y - subtext_size.y);
	subtimer_size = vec2(mySize.x / 3, mySize.y - subtext_size.y);
	timer_str     = seconds_tostring(timer);

	panel_size.y -= subtext_size.y;
	HUD_Panel_DrawBg();

	if(subtimer_str) {
		float subtimer_padding = subtimer_size.y / 5;
		timer_size.x -= subtimer_size.x;
		drawcolorcodedstring_aspect(pos + eX * timer_size.x + eY * subtimer_padding,
			strcat((swap ? timer_color : subtimer_color), swap ? timer_str : subtimer_str),
			subtimer_size - eY * 2 * subtimer_padding, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	drawcolorcodedstring_aspect(pos,
		strcat((swap ? subtimer_color : timer_color), swap ? subtimer_str : timer_str),
		timer_size, panel_fg_alpha, DRAWFLAG_NORMAL);

	if(subtext)
		drawcolorcodedstring_aspect(pos + eY * timer_size.y,
			strcat(CCR_F1, subtext),
			subtext_size, panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
