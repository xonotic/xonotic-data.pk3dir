#include "timer.qh"

#include <client/autocvars.qh>
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
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	string timer;
	float timelimit, timeleft, minutesLeft;

	timelimit = STAT(TIMELIMIT);

	timeleft = max(0, timelimit * 60 + STAT(GAMESTARTTIME) - time);
	timeleft = ceil(timeleft);

	minutesLeft = floor(timeleft / 60);

	float warmup_timeleft = 0;
	if(warmup_stage)
	{
		float warmup_timelimit = STAT(WARMUP_TIMELIMIT);
		if(warmup_timelimit > 0)
			warmup_timeleft = max(0, warmup_timelimit - time);
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
		timer = seconds_tostring(max(0, floor(intermission_time - STAT(GAMESTARTTIME))));
	} else if (warmup_stage && warmup_timeleft >= 60) {
		timer = _("WARMUP");
	} else if (autocvar_hud_panel_timer_increment || (!warmup_stage && timelimit == 0) || (warmup_stage && warmup_timeleft <= 0)) {
		if (time < STAT(GAMESTARTTIME))
			timer = seconds_tostring(0); //while restart is still active, show 00:00
		else
			timer = seconds_tostring(floor(time - STAT(GAMESTARTTIME)));
	} else {
		if(warmup_stage)
			timer = seconds_tostring(warmup_timeleft);
		else
			timer = seconds_tostring(timeleft);
	}

	drawstring_aspect(pos, timer, mySize, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
