#include "timer.qh"

#include <client/draw.qh>
#include <client/view.qh>

// Timer (#5)
float last_timeleft;
int autocvar_cl_timer_countdown = 3; // 0 = disabled, 1 = always on, 2 = only spec, 3 = as dictated by server

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
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	string timer_sub = "";
	float timelimit, timeleft, minutesLeft, overtimes, timeout_last;

	timelimit = STAT(TIMELIMIT);
	overtimes = STAT(OVERTIMESADDED);
	timeout_last = STAT(TIMEOUT_LAST);

	timeleft = bound(0, timelimit * 60 + STAT(GAMESTARTTIME) - time, timelimit * 60);
	timeleft = ceil(timeleft);

	// countdown sound
	// if 3 use server dictated option, otherwise the client's
	int countdown_type;
	if(autocvar_cl_timer_countdown == 3)
		countdown_type = sv_timer_countdown;
	else
		countdown_type = autocvar_cl_timer_countdown;
	
	if(countdown_type && !warmup_stage && timeleft > 0 && timeleft != last_timeleft && timeleft <= 10)
	{
		if(countdown_type == 1 || (countdown_type == 2 && spectatee_status))
			sound(NULL, CH_INFO, SND_ENDCOUNT, VOL_BASE, ATTN_NONE);
		
		last_timeleft = timeleft;
	}

	minutesLeft = floor(timeleft / 60);

	float warmup_timeleft = 0;
	if(warmup_stage)
	{
		float warmup_timelimit = STAT(WARMUP_TIMELIMIT);
		if(warmup_timelimit > 0)
			warmup_timeleft = max(0, warmup_timelimit - time + STAT(GAMESTARTTIME));
		else if(warmup_timelimit == 0)
			warmup_timeleft = timeleft;
		warmup_timeleft = ceil(warmup_timeleft);
	}

	vector timer_color;
	if(intermission_time || minutesLeft >= 5 || warmup_stage || timelimit == 0)
		timer_color = '1 1 1'; //white
	else if(minutesLeft >= 1)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (intermission_time) {
		timer = max(0, floor(intermission_time - STAT(GAMESTARTTIME)));
		timer_sub = "Intermission";
	//} else if (autocvar_hud_panel_timer_increment || (!warmup_stage && timelimit == 0) || (warmup_stage && warmup_timeleft <= 0)) {
	} else if (timeout_last) {
		if(autocvar_hud_panel_timer_increment)
			timer = max(0, floor(timeout_last - STAT(GAMESTARTTIME)));
		else
			timer = ceil(max(0, timelimit * 60 + STAT(GAMESTARTTIME) - timeout_last));
		timer_sub = "Timeout";
	} else if (autocvar_hud_panel_timer_increment || timelimit == 0) {
		// Time elapsed timer
		if((warmup_stage && warmup_timeleft <= 0) || time < STAT(GAMESTARTTIME))
			timer = 0;
		else
			timer = floor(time - STAT(GAMESTARTTIME));
	} else {
		// Time left timer
		if(warmup_stage) {
			if(warmup_timeleft <= 0)
				timer = floor(timelimit * 60);
			else
				timer = warmup_timeleft;
		} else {
			timer = timeleft;
		}
	}
	
	if(warmup_stage)
		timer_sub = "Warmup";
	else if(overtimes == 1)
		timer_sub = "Overtime";
	else if (overtimes > 1)
		timer_sub = sprintf("Overtime #%d", overtimes);
	
	drawstring_aspect(pos, seconds_tostring(timer), mySize, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	
	if(timer_sub != "") {
		pos.y += mySize.y;
		mySize.y = mySize.y / 2;
		drawstring_aspect(pos, timer_sub, mySize, '1 0 0', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	draw_endBoldFont();
}
