void HUD_Timer()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_timer) return;
	}

	HUD_Panel_UpdateCvars();

	draw_beginBoldFont();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	string timer;
	float timelimit, elapsedTime, timeleft, minutesLeft;

	timelimit = STAT(TIMELIMIT);

	timeleft = max(0, timelimit * 60 + STAT(GAMESTARTTIME) - time);
	timeleft = ceil(timeleft);

	minutesLeft = floor(timeleft / 60);

	vector timer_color;
	if(minutesLeft >= 5 || warmup_stage || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if(minutesLeft >= 1)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (autocvar_hud_panel_timer_increment || timelimit == 0 || warmup_stage) {
		if (time < STAT(GAMESTARTTIME)) {
			//while restart is still active, show 00:00
			timer = seconds_tostring(0);
		} else {
			elapsedTime = floor(time - STAT(GAMESTARTTIME)); //127
			timer = seconds_tostring(elapsedTime);
		}
	} else {
		timer = seconds_tostring(timeleft);
	}

	drawstring_aspect(pos, timer, mySize, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);

	draw_endBoldFont();
}
