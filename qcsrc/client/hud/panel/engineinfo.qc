// Engine info panel (#13)

float prevfps;
float prevfps_time;
int framecounter;

float frametimeavg;
float frametimeavg1; // 1 frame ago
float frametimeavg2; // 2 frames ago
void HUD_EngineInfo()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_engineinfo) return;
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

	float currentTime = gettime(GETTIME_REALTIME);
	if(cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage"))
	{
		float currentframetime = currentTime - prevfps_time;
		frametimeavg = (frametimeavg + frametimeavg1 + frametimeavg2 + currentframetime)/4; // average three frametimes into framecounter for slightly more stable fps readings :P
		frametimeavg2 = frametimeavg1;
		frametimeavg1 = frametimeavg;

		float weight;
		weight = cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage_new_weight");
		if(currentframetime > 0.0001) // filter out insane values which sometimes seem to occur and throw off the average? If you are getting 10,000 fps or more, then you don't need a framerate counter.
		{
			if(fabs(prevfps - (1/frametimeavg)) > prevfps * cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage_instantupdate_change_threshold")) // if there was a big jump in fps, just force prevfps at current (1/currentframetime) to make big updates instant
				prevfps = (1/currentframetime);
			prevfps = (1 - weight) * prevfps + weight * (1/frametimeavg); // framecounter just used so there's no need for a new variable, think of it as "frametime average"
		}
		prevfps_time = currentTime;
	}
	else
	{
		framecounter += 1;
		if(currentTime - prevfps_time > autocvar_hud_panel_engineinfo_framecounter_time)
		{
			prevfps = framecounter/(currentTime - prevfps_time);
			framecounter = 0;
			prevfps_time = currentTime;
		}
	}

	vector color;
	color = HUD_Get_Num_Color (prevfps, 100);
	drawstring_aspect(pos, sprintf(_("FPS: %.*f"), autocvar_hud_panel_engineinfo_framecounter_decimals, prevfps), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}
