// CenterPrint (#16)

const int CENTERPRINT_MAX_MSGS = 10;
const int CENTERPRINT_MAX_ENTRIES = 50;
const float CENTERPRINT_SPACING = 0.7;
int cpm_index;
string centerprint_messages[CENTERPRINT_MAX_MSGS];
int centerprint_msgID[CENTERPRINT_MAX_MSGS];
float centerprint_time[CENTERPRINT_MAX_MSGS];
float centerprint_expire_time[CENTERPRINT_MAX_MSGS];
int centerprint_countdown_num[CENTERPRINT_MAX_MSGS];
bool centerprint_showing;

void centerprint_generic(int new_id, string strMessage, float duration, int countdown_num)
{
	//printf("centerprint_generic(%d, '%s^7', %d, %d);\n", new_id, strMessage, duration, countdown_num);
	int i, j;

	if(strMessage == "" && new_id == 0)
		return;

	// strip trailing newlines
	j = strlen(strMessage) - 1;
	while(substring(strMessage, j, 1) == "\n" && j >= 0)
		--j;
	if (j < strlen(strMessage) - 1)
		strMessage = substring(strMessage, 0, j + 1);

	if(strMessage == "" && new_id == 0)
		return;

	// strip leading newlines
	j = 0;
	while(substring(strMessage, j, 1) == "\n" && j < strlen(strMessage))
		++j;
	if (j > 0)
		strMessage = substring(strMessage, j, strlen(strMessage) - j);

	if(strMessage == "" && new_id == 0)
		return;

	if (!centerprint_showing)
		centerprint_showing = true;

	for (i=0, j=cpm_index; i<CENTERPRINT_MAX_MSGS; ++i, ++j)
	{
		if (j == CENTERPRINT_MAX_MSGS)
			j = 0;
		if (new_id && new_id == centerprint_msgID[j])
		{
			if (strMessage == "" && centerprint_messages[j] != "" && centerprint_countdown_num[j] == 0)
			{
				// fade out the current msg (duration and countdown_num are ignored)
				centerprint_time[j] = min(5, autocvar_hud_panel_centerprint_fade_out);
				if (centerprint_expire_time[j] > time + min(5, autocvar_hud_panel_centerprint_fade_out) || centerprint_expire_time[j] < time)
					centerprint_expire_time[j] = time + min(5, autocvar_hud_panel_centerprint_fade_out);
				return;
			}
			break; // found a msg with the same id, at position j
		}
	}

	if (i == CENTERPRINT_MAX_MSGS)
	{
		// a msg with the same id was not found, add the msg at the next position
		--cpm_index;
		if (cpm_index == -1)
			cpm_index = CENTERPRINT_MAX_MSGS - 1;
		j = cpm_index;
	}
	if(centerprint_messages[j])
		strunzone(centerprint_messages[j]);
	centerprint_messages[j] = strzone(strMessage);
	centerprint_msgID[j] = new_id;
	if (duration < 0)
	{
		centerprint_time[j] = -1;
		centerprint_expire_time[j] = time;
	}
	else
	{
		if(duration == 0)
			duration = max(1, autocvar_hud_panel_centerprint_time);
		centerprint_time[j] = duration;
		centerprint_expire_time[j] = time + duration;
	}
	centerprint_countdown_num[j] = countdown_num;
}

void centerprint_hud(string strMessage)
{
	centerprint_generic(0, strMessage, autocvar_hud_panel_centerprint_time, 0);
}

void reset_centerprint_messages()
{
	int i;
	for (i=0; i<CENTERPRINT_MAX_MSGS; ++i)
	{
		centerprint_expire_time[i] = 0;
		centerprint_time[i] = 1;
		centerprint_msgID[i] = 0;
		if(centerprint_messages[i])
			strunzone(centerprint_messages[i]);
		centerprint_messages[i] = string_null;
	}
}
float hud_configure_cp_generation_time;
void HUD_CenterPrint ()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_centerprint) return;

		if(hud_configure_prev)
			reset_centerprint_messages();
	}
	else
	{
		if(!hud_configure_prev)
			reset_centerprint_messages();
		if (time > hud_configure_cp_generation_time)
		{
			if(highlightedPanel == HUD_PANEL(CENTERPRINT))
			{
				float r;
				r = random();
				if (r > 0.8)
					centerprint_generic(floor(r*1000), strcat(sprintf("^3Countdown message at time %s", seconds_tostring(time)), ", seconds left: ^COUNT"), 1, 10);
				else if (r > 0.55)
					centerprint_generic(0, sprintf("^1Multiline message at time %s that\n^1lasts longer than normal", seconds_tostring(time)), 20, 0);
				else
					centerprint_hud(sprintf("Message at time %s", seconds_tostring(time)));
				hud_configure_cp_generation_time = time + 1 + random()*4;
			}
			else
			{
				centerprint_generic(0, sprintf("Centerprint message", seconds_tostring(time)), 10, 0);
				hud_configure_cp_generation_time = time + 10 - random()*3;
			}
		}
	}

	// this panel fades only when the menu does
	float hud_fade_alpha_save = 0;
	if(scoreboard_fade_alpha)
	{
		hud_fade_alpha_save = hud_fade_alpha;
		hud_fade_alpha = 1 - autocvar__menu_alpha;
	}
	HUD_Panel_UpdateCvars();

	if ( HUD_Radar_Clickable() )
	{
		if (hud_panel_radar_bottom >= 0.96 * vid_conheight)
			return;

		panel_pos = eY * hud_panel_radar_bottom + eX * 0.5 * (vid_conwidth - panel_size_x);
		panel_size_y = min(panel_size_y, vid_conheight - hud_panel_radar_bottom);
	}
	else if(scoreboard_fade_alpha)
	{
		hud_fade_alpha = hud_fade_alpha_save;

		// move the panel below the scoreboard
		if (scoreboard_bottom >= 0.96 * vid_conheight)
			return;
		vector target_pos;

		target_pos = eY * scoreboard_bottom + eX * 0.5 * (vid_conwidth - panel_size.x);

		if(target_pos.y > panel_pos.y)
		{
			panel_pos = panel_pos + (target_pos - panel_pos) * sqrt(scoreboard_fade_alpha);
			panel_size.y = min(panel_size.y, vid_conheight - scoreboard_bottom);
		}
	}

	HUD_Panel_DrawBg(1);

	if (!centerprint_showing)
		return;

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	int entries;
	float height;
	vector fontsize;
	// entries = bound(1, floor(CENTERPRINT_MAX_ENTRIES * 4 * panel_size_y/panel_size_x), CENTERPRINT_MAX_ENTRIES);
	// height = panel_size_y/entries;
	// fontsize = '1 1 0' * height;
	height = vid_conheight/50 * autocvar_hud_panel_centerprint_fontscale;
	fontsize = '1 1 0' * height;
	entries = bound(1, floor(panel_size.y/height), CENTERPRINT_MAX_ENTRIES);

	int i, j, k, n, g;
	float a, sz, align, current_msg_posY = 0, msg_size;
	vector pos;
	string ts;
	bool all_messages_expired = true;

	pos = panel_pos;
	if (autocvar_hud_panel_centerprint_flip)
		pos.y += panel_size.y;
	align = bound(0, autocvar_hud_panel_centerprint_align, 1);
	for (g=0, i=0, j=cpm_index; i<CENTERPRINT_MAX_MSGS; ++i, ++j)
	{
		if (j == CENTERPRINT_MAX_MSGS)
			j = 0;
		if (centerprint_expire_time[j] <= time)
		{
			if (centerprint_countdown_num[j] && centerprint_time[j] > 0)
			{
				centerprint_countdown_num[j] = centerprint_countdown_num[j] - 1;
				if (centerprint_countdown_num[j] == 0)
					continue;
				centerprint_expire_time[j] = centerprint_expire_time[j] + centerprint_time[j];
			}
			else if(centerprint_time[j] != -1)
				continue;
		}

		all_messages_expired = false;

		// fade the centerprint_hud in/out
		if(centerprint_time[j] < 0)  // Expired but forced. Expire time is the fade-in time.
			a = (time - centerprint_expire_time[j]) / max(0.0001, autocvar_hud_panel_centerprint_fade_in);
		else if(centerprint_expire_time[j] - autocvar_hud_panel_centerprint_fade_out > time)  // Regularily printed. Not fading out yet.
			a = (time - (centerprint_expire_time[j] - centerprint_time[j])) / max(0.0001, autocvar_hud_panel_centerprint_fade_in);
		else // Expiring soon, so fade it out.
			a = (centerprint_expire_time[j] - time) / max(0.0001, autocvar_hud_panel_centerprint_fade_out);

		// while counting down show it anyway in order to hold the current message position
		if (a <= 0.5/255.0 && centerprint_countdown_num[j] == 0)  // Guaranteed invisible - don't show.
			continue;
		if (a > 1)
			a = 1;

		// set the size from fading in/out before subsequent fading
		sz = autocvar_hud_panel_centerprint_fade_minfontsize + a * (1 - autocvar_hud_panel_centerprint_fade_minfontsize);

		// also fade it based on positioning
		if(autocvar_hud_panel_centerprint_fade_subsequent)
		{
			a = a * bound(autocvar_hud_panel_centerprint_fade_subsequent_passone_minalpha, (1 - (g / max(1, autocvar_hud_panel_centerprint_fade_subsequent_passone))), 1); // pass one: all messages after the first have half theAlpha
			a = a * bound(autocvar_hud_panel_centerprint_fade_subsequent_passtwo_minalpha, (1 - (g / max(1, autocvar_hud_panel_centerprint_fade_subsequent_passtwo))), 1); // pass two: after that, gradually lower theAlpha even more for each message
		}
		a *= panel_fg_alpha;

		// finally set the size based on the new theAlpha from subsequent fading
		sz = sz * (autocvar_hud_panel_centerprint_fade_subsequent_minfontsize + a * (1 - autocvar_hud_panel_centerprint_fade_subsequent_minfontsize));
		drawfontscale = sz * '1 1 0';

		if (centerprint_countdown_num[j])
			n = tokenizebyseparator(strreplace("^COUNT", count_seconds(centerprint_countdown_num[j]), centerprint_messages[j]), "\n");
		else
			n = tokenizebyseparator(centerprint_messages[j], "\n");

		if (autocvar_hud_panel_centerprint_flip)
		{
			// check if the message can be entirely shown
			for(k = 0; k < n; ++k)
			{
				getWrappedLine_remaining = argv(k);
				while(getWrappedLine_remaining)
				{
					ts = getWrappedLine(panel_size.x * sz, fontsize, stringwidth_colors);
					if (ts != "")
						pos.y -= fontsize.y;
					else
						pos.y -= fontsize.y * CENTERPRINT_SPACING/2;
				}
			}
			current_msg_posY = pos.y; // save starting pos (first line) of the current message
		}

		msg_size = pos.y;
		for(k = 0; k < n; ++k)
		{
			getWrappedLine_remaining = argv(k);
			while(getWrappedLine_remaining)
			{
				ts = getWrappedLine(panel_size.x * sz, fontsize, stringwidth_colors);
				if (ts != "")
				{
					if (align)
						pos.x = panel_pos.x + (panel_size.x - stringwidth(ts, true, fontsize)) * align;
					if (a > 0.5/255.0)  // Otherwise guaranteed invisible - don't show. This is checked a second time after some multiplications with other factors were done so temporary changes of these cannot cause flicker.
						drawcolorcodedstring(pos + eY * 0.5 * (1 - sz) * fontsize.y, ts, fontsize, a, DRAWFLAG_NORMAL);
					pos.y += fontsize.y;
				}
				else
					pos.y += fontsize.y * CENTERPRINT_SPACING/2;
			}
		}

		++g; // move next position number up

		msg_size = pos.y - msg_size;
		if (autocvar_hud_panel_centerprint_flip)
		{
			pos.y = current_msg_posY - CENTERPRINT_SPACING * fontsize.y;
			if (a < 1 && centerprint_msgID[j] == 0) // messages with id can be replaced just after they are faded out, so never move over them the next messages
				pos.y += (msg_size + CENTERPRINT_SPACING * fontsize.y) * (1 - sqrt(sz));

			if (pos.y < panel_pos.y) // check if the next message can be shown
			{
				drawfontscale = '1 1 0';
				return;
			}
		}
		else
		{
			pos.y += CENTERPRINT_SPACING * fontsize.y;
			if (a < 1 && centerprint_msgID[j] == 0) // messages with id can be replaced just after they are faded out, so never move over them the next messages
				pos.y -= (msg_size + CENTERPRINT_SPACING * fontsize.y) * (1 - sqrt(sz));

			if(pos.y > panel_pos.y + panel_size.y - fontsize.y) // check if the next message can be shown
			{
				drawfontscale = '1 1 0';
				return;
			}
		}
	}
	drawfontscale = '1 1 0';
	if (all_messages_expired)
	{
		centerprint_showing = false;
		reset_centerprint_messages();
	}
}
