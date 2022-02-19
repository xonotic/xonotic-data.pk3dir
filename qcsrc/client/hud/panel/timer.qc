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
	if(timeleft >= 300)
		return '1 1 1'; //white
	else if(timeleft >= 60)
		return '1 1 0'; //yellow
	else
		return '1 0 0'; //red
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
	float timelimit, timeleft, overtimes;
	float round_timelimit, round_timeleft;
	vector timer_size, subtext_size, subtimer_size;
	vector timer_color = '1 1 1';
	vector subtimer_color = '1 1 1';
	bool swap = (autocvar_hud_panel_timer_secondary == 2);

	// Calculate timelimit
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
	timeleft = timelimit + STAT(GAMESTARTTIME) - time;
	if (!autocvar_hud_panel_timer_unbound)
		timeleft = bound(0, timeleft, timelimit);
	timeleft = ceil(timeleft);

	// Timer color
	if(!intermission_time && !warmup_stage && timelimit > 0)
		timer_color = HUD_Timer_Color(timeleft);

	// Timer text
	if (intermission_time) {
		timer = seconds_tostring(max(0, floor(intermission_time - STAT(GAMESTARTTIME))));
	} else if (autocvar_hud_panel_timer_increment || timelimit <= 0) {
		float time_elapsed = floor(time - STAT(GAMESTARTTIME));
		if (!autocvar_hud_panel_timer_unbound)
			time_elapsed = max(0, time_elapsed);

		timer = seconds_tostring(time_elapsed);
	} else {
		timer = seconds_tostring(timeleft);
	}
	
	// Round-based game modes
	if(STAT(ROUNDSTARTTIME) && autocvar_hud_panel_timer_secondary)
	{
		round_timelimit = STAT(ROUND_TIMELIMIT);

		// Calculate round time left
		round_timeleft = round_timelimit + STAT(ROUNDSTARTTIME) - time;
		if (!autocvar_hud_panel_timer_unbound)
			round_timeleft = bound(0, round_timeleft, round_timelimit);
		round_timeleft = ceil(round_timeleft);

		// Subtimer color
		if(!intermission_time && round_timelimit > 0)
			subtimer_color = HUD_Timer_Color(round_timeleft);

		// Subtimer text
		if (intermission_time) {
			subtimer = seconds_tostring(max(0, floor(intermission_time - STAT(ROUNDSTARTTIME))));
		} else if (autocvar_hud_panel_timer_increment || round_timelimit <= 0) {
			float round_time_elapsed = floor(time - STAT(ROUNDSTARTTIME));
			if (!autocvar_hud_panel_timer_unbound)
				round_time_elapsed = max(0, round_time_elapsed);

			subtimer = seconds_tostring(round_time_elapsed);
		} else {
			subtimer = seconds_tostring(round_timeleft);
		}
	}

	// Subtext
	overtimes = STAT(OVERTIMESADDED);

	if(warmup_stage || autocvar__hud_configure)
		subtext = _("Warmup");
	else if(intermission_time)
		subtext = _("Intermission");
	else if(STAT(TIMEOUT_STATUS))
		subtext = _("Timeout");
	else if (overtimes >= 2)
		subtext = sprintf(_("Overtime #%d"), overtimes);
	else if(overtimes)
		subtext = _("Overtime");

	subtext_size  = vec2(mySize.x, mySize.y / 3);
	timer_size    = vec2(mySize.x, mySize.y - subtext_size.y);
	subtimer_size = vec2(mySize.x / 3, mySize.y - subtext_size.y);
	
	panel_size.y -= subtext_size.y;
	HUD_Panel_DrawBg();
	
	if(subtimer) {
		timer_size.x -= subtimer_size.x;
		drawstring_aspect(pos + eX * timer_size.x, (swap ? timer : subtimer), subtimer_size, (swap ? timer_color : subtimer_color), panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	
	drawstring_aspect(pos, (swap ? subtimer : timer), timer_size, (swap ? subtimer_color : timer_color), panel_fg_alpha, DRAWFLAG_NORMAL);
	
	if(subtext)
		drawstring_aspect(pos + eY * timer_size.y, subtext, subtext_size, '0 1 0', panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
