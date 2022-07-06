#include "timer.qh"

#include <client/draw.qh>
#include <client/view.qh>

// Timer (#5)

void HUD_Timer_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

vector HUD_Timer_Color(float timeleft)
{
	if(timeleft <= 60)
		return '1 0 0'; // red
	else if(timeleft <= 300)
		return '1 1 0'; // yellow
	else
		return '1 1 1'; // white
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

	string timer;
	string subtimer = string_null;
	string subtext = string_null;
	float curtime, timelimit, timeleft;
	vector timer_size, subtext_size, subtimer_size;
	vector timer_color = '1 1 1';
	vector subtimer_color = '1 1 1';
	bool swap = (autocvar_hud_panel_timer_secondary == 2 && STAT(ROUNDSTARTTIME));

	// Use real or frozen time and get the time limit
	curtime = (intermission_time ? intermission_time : time);
	if(warmup_stage)
	{
		timelimit = STAT(WARMUP_TIMELIMIT);
		if(timelimit == 0)
			timelimit = STAT(TIMELIMIT) * 60;
	}
	else
	{
		timelimit = STAT(TIMELIMIT) * 60;
	}

	// Calculate time left
	timeleft = HUD_Timer_TimeLeft(curtime, STAT(GAMESTARTTIME), timelimit);

	// Timer color
	if(!intermission_time && !warmup_stage && timelimit > 0)
		timer_color = HUD_Timer_Color(timeleft);

	// Timer text
	if (autocvar_hud_panel_timer_increment || timelimit <= 0)
		timer = seconds_tostring(HUD_Timer_TimeElapsed(curtime, STAT(GAMESTARTTIME)));
	else
		timer = seconds_tostring(timeleft);

	// Secondary timer for round-based game modes
	if(STAT(ROUNDSTARTTIME) && autocvar_hud_panel_timer_secondary)
	{
		if(STAT(ROUNDSTARTTIME) == -1) {
			// Round can't start
			subtimer = "--:--";
			subtimer_color = '1 0 0';
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
				subtimer = seconds_tostring(HUD_Timer_TimeElapsed(round_curtime, STAT(ROUNDSTARTTIME)));
			else
				subtimer = seconds_tostring(round_timeleft);
		}
	}

	// Subtext
	int overtimes = STAT(OVERTIMES);

	if(warmup_stage || autocvar__hud_configure)
		subtext = _("Warmup");
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

	panel_size.y -= subtext_size.y;
	HUD_Panel_DrawBg();

	if(subtimer) {
		float subtimer_padding = subtimer_size.y / 5;
		timer_size.x -= subtimer_size.x;
		drawstring_aspect(pos + eX * timer_size.x + eY * subtimer_padding, (swap ? timer : subtimer), subtimer_size - eY * subtimer_padding * 2, (swap ? timer_color : subtimer_color), panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	drawstring_aspect(pos, (swap ? subtimer : timer), timer_size, (swap ? subtimer_color : timer_color), panel_fg_alpha, DRAWFLAG_NORMAL);

	if(subtext)
		drawstring_aspect(pos + eY * timer_size.y, subtext, subtext_size, '0 1 0', panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
