#include "timer.qh"

#include <client/draw.qh>
#include <client/view.qh>

// Timer (#5)

void HUD_Timer_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
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

	string timer, subtimer, subtext;
	float timelimit, timeleft, overtimes;
	float round_timelimit, round_timeleft;

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
	timeleft = bound(0, timelimit + STAT(GAMESTARTTIME) - time, timelimit);
	timeleft = ceil(timeleft);

	// Timer color
	vector timer_color;
	if(intermission_time || timeleft >= 300 || warmup_stage || timelimit <= 0)
		timer_color = '1 1 1'; //white
	else if(timeleft >= 60)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	// Timer text
	if (intermission_time) {
		timer = seconds_tostring(max(0, floor(intermission_time - STAT(GAMESTARTTIME))));
	} else if (autocvar_hud_panel_timer_increment || timelimit <= 0) {
		float time_elapsed = floor(time - STAT(GAMESTARTTIME));
		timer = seconds_tostring(max(0, time_elapsed));
	} else {
		timer = seconds_tostring(timeleft);
	}
	
	// Subtimer text
	if(STAT(ROUNDSTARTTIME))
	{
		round_timelimit = STAT(ROUND_TIMELIMIT);
		
		if (autocvar_hud_panel_timer_increment || round_timelimit <= 0) {
			float round_time_elapsed = floor(time - STAT(ROUNDSTARTTIME));
			subtimer = seconds_tostring(max(0, round_time_elapsed));
		} else {
			round_timeleft = bound(0, round_timelimit + STAT(ROUNDSTARTTIME) - time, round_timelimit);
			round_timeleft = ceil(round_timeleft);
			
			subtimer = seconds_tostring(round_timeleft);
		}
	}
	else
		subtimer = string_null;

	// Subtext
	overtimes = STAT(OVERTIMESADDED);
	
	if(warmup_stage || autocvar__hud_configure)
		subtext = _("Warmup");
	else if(intermission_time)
		subtext = _("Intermission");
	else if(STAT(TIMEOUT_STATUS))
		subtext = _("Timeout");
	else if(overtimes == 1)
		subtext = _("Overtime");
	else if (overtimes > 1)
		subtext = sprintf(_("Overtime #%d"), overtimes);
	else
		subtext = string_null;

	vector timer_size, subtext_size, subtimer_size;
	
	subtext_size  = vec2(mySize.x, mySize.y / 3);
	timer_size    = vec2(mySize.x, mySize.y - subtext_size.y);
	subtimer_size = vec2(mySize.x / 3, mySize.y - subtext_size.y);
	
	panel_size.y -= subtext_size.y;
	HUD_Panel_DrawBg();
	
	if(subtimer) {
		timer_size.x -= subtimer_size.x;
		drawstring_aspect(pos + eX * timer_size.x, subtimer, subtimer_size, '1 1 0', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	
	drawstring_aspect(pos, timer, timer_size, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	
	if(subtext)
		drawstring_aspect(pos + eY * timer_size.y, subtext, subtext_size, '1 0 0', panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
