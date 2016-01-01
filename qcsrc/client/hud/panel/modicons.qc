// Mod icons panel (#10)

bool mod_active; // is there any active mod icon?

void DrawCAItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
	int stat = -1;
	string pic = "";
	vector color = '0 0 0';
	switch(i)
	{
		case 0:
			stat = STAT(REDALIVE);
			pic = "player_red.tga";
			color = '1 0 0';
			break;
		case 1:
			stat = STAT(BLUEALIVE);
			pic = "player_blue.tga";
			color = '0 0 1';
			break;
		case 2:
			stat = STAT(YELLOWALIVE);
			pic = "player_yellow.tga";
			color = '1 1 0';
			break;
		default:
		case 3:
			stat = STAT(PINKALIVE);
			pic = "player_pink.tga";
			color = '1 0 1';
			break;
	}

	if(mySize.x/mySize.y > aspect_ratio)
	{
		i = aspect_ratio * mySize.y;
		myPos.x = myPos.x + (mySize.x - i) / 2;
		mySize.x = i;
	}
	else
	{
		i = 1/aspect_ratio * mySize.x;
		myPos.y = myPos.y + (mySize.y - i) / 2;
		mySize.y = i;
	}

	if(layout)
	{
		drawpic_aspect_skin(myPos, pic, eX * 0.7 * mySize.x + eY * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(myPos + eX * 0.7 * mySize.x, ftos(stat), eX * 0.3 * mySize.x + eY * mySize.y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
		drawstring_aspect(myPos, ftos(stat), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Clan Arena and Freeze Tag HUD modicons
void HUD_Mod_CA(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	int layout;
	if(gametype == MAPINFO_TYPE_CA)
		layout = autocvar_hud_panel_modicons_ca_layout;
	else //if(gametype == MAPINFO_TYPE_FREEZETAG)
		layout = autocvar_hud_panel_modicons_freezetag_layout;
	int rows, columns;
	float aspect_ratio;
	aspect_ratio = (layout) ? 2 : 1;
	rows = HUD_GetRowCount(team_count, mySize, aspect_ratio);
	columns = ceil(team_count/rows);

	int i;
	float row = 0, column = 0;
	vector pos, itemSize;
	itemSize = eX * mySize.x*(1/columns) + eY * mySize.y*(1/rows);
	for(i=0; i<team_count; ++i)
	{
		pos = myPos + eX * column * itemSize.x + eY * row * itemSize.y;

		DrawCAItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}

// CTF HUD modicon section
int redflag_prevframe, blueflag_prevframe, yellowflag_prevframe, pinkflag_prevframe, neutralflag_prevframe; // status during previous frame
int redflag_prevstatus, blueflag_prevstatus, yellowflag_prevstatus, pinkflag_prevstatus, neutralflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time, yellowflag_statuschange_time, pinkflag_statuschange_time, neutralflag_statuschange_time; // time when the status changed

void HUD_Mod_CTF_Reset()
{
	redflag_prevstatus = blueflag_prevstatus = yellowflag_prevstatus = pinkflag_prevstatus = neutralflag_prevstatus = 0;
	redflag_prevframe = blueflag_prevframe = yellowflag_prevframe = pinkflag_prevframe = neutralflag_prevframe = 0;
	redflag_statuschange_time = blueflag_statuschange_time = yellowflag_statuschange_time = pinkflag_statuschange_time = neutralflag_statuschange_time = 0;
}

void HUD_Mod_CTF(vector pos, vector mySize)
{
	vector redflag_pos, blueflag_pos, yellowflag_pos, pinkflag_pos, neutralflag_pos;
	vector flag_size;
	float f; // every function should have that

	int redflag, blueflag, yellowflag, pinkflag, neutralflag; // current status
	float redflag_statuschange_elapsedtime = 0, blueflag_statuschange_elapsedtime = 0, yellowflag_statuschange_elapsedtime = 0, pinkflag_statuschange_elapsedtime = 0, neutralflag_statuschange_elapsedtime = 0; // time since the status changed
	bool ctf_oneflag; // one-flag CTF mode enabled/disabled
	int stat_items = STAT(CTF_FLAGSTATUS);
	float fs, fs2, fs3, size1, size2;
	vector e1, e2;

	redflag = (stat_items/CTF_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/CTF_BLUE_FLAG_TAKEN) & 3;
	yellowflag = (stat_items/CTF_YELLOW_FLAG_TAKEN) & 3;
	pinkflag = (stat_items/CTF_PINK_FLAG_TAKEN) & 3;
	neutralflag = (stat_items/CTF_NEUTRAL_FLAG_TAKEN) & 3;

	ctf_oneflag = (stat_items & CTF_FLAG_NEUTRAL);

	mod_active = (redflag || blueflag || yellowflag || pinkflag || neutralflag);

	if (autocvar__hud_configure) {
		redflag = 1;
		blueflag = 2;
		if (team_count >= 3)
			yellowflag = 2;
		if (team_count >= 4)
			pinkflag = 3;
		ctf_oneflag = neutralflag = 0; // disable neutral flag in hud editor?
	}

	// when status CHANGES, set old status into prevstatus and current status into status
	#define X(team) MACRO_BEGIN {													\
		if (team##flag != team##flag_prevframe) {									\
    		team##flag_statuschange_time = time;									\
    		team##flag_prevstatus = team##flag_prevframe;							\
    		team##flag_prevframe = team##flag;										\
    	}																			\
    	team##flag_statuschange_elapsedtime = time - team##flag_statuschange_time; 	\
    } MACRO_END
	X(red);
	X(blue);
	X(yellow);
	X(pink);
	X(neutral);
	#undef X

	const float BLINK_FACTOR = 0.15;
	const float BLINK_BASE = 0.85;
	// note:
	//   RMS = sqrt(BLINK_BASE^2 + 0.5 * BLINK_FACTOR^2)
	// thus
	//   BLINK_BASE = sqrt(RMS^2 - 0.5 * BLINK_FACTOR^2)
	// ensure RMS == 1
	const float BLINK_FREQ = 5; // circle frequency, = 2*pi*frequency in hertz

	#define X(team, cond) \
	string team##_icon = string_null, team##_icon_prevstatus = string_null; \
	int team##_alpha, team##_alpha_prevstatus; \
	team##_alpha = team##_alpha_prevstatus = 1; \
	MACRO_BEGIN { \
		switch (team##flag) { \
			case 1: team##_icon = "flag_" #team "_taken"; break; \
			case 2: team##_icon = "flag_" #team "_lost"; break; \
			case 3: team##_icon = "flag_" #team "_carrying"; team##_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break; \
			default: \
				if ((stat_items & CTF_SHIELDED) && (cond)) { \
					team##_icon = "flag_" #team "_shielded"; \
				} else { \
					team##_icon = string_null; \
				} \
				break; \
		} \
		switch (team##flag_prevstatus) { \
			case 1: team##_icon_prevstatus = "flag_" #team "_taken"; break; \
			case 2: team##_icon_prevstatus = "flag_" #team "_lost"; break; \
			case 3: team##_icon_prevstatus = "flag_" #team "_carrying"; team##_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break; \
			default: \
				if (team##flag == 3) { \
					team##_icon_prevstatus = "flag_" #team "_carrying"; /* make it more visible */\
				} else if((stat_items & CTF_SHIELDED) && (cond)) { \
					team##_icon_prevstatus = "flag_" #team "_shielded"; \
				} else { \
					team##_icon_prevstatus = string_null; \
				} \
				break; \
		} \
	} MACRO_END
	X(red, myteam != NUM_TEAM_1);
	X(blue, myteam != NUM_TEAM_2);
	X(yellow, myteam != NUM_TEAM_3);
	X(pink, myteam != NUM_TEAM_4);
	X(neutral, true);
	#undef X

	if (ctf_oneflag) {
		// hacky, but these aren't needed
		red_icon = red_icon_prevstatus = blue_icon = blue_icon_prevstatus = yellow_icon = yellow_icon_prevstatus = pink_icon = pink_icon_prevstatus = string_null;
		fs = fs2 = fs3 = 1;
	} else switch (team_count) {
		default:
		case 2: fs = 0.5; fs2 = 0.5; fs3 = 0.5; break;
		case 3: fs = 1; fs2 = 0.35; fs3 = 0.35; break;
		case 4: fs = 0.75; fs2 = 0.25; fs3 = 0.5; break;
	}

	if (mySize_x > mySize_y) {
		size1 = mySize_x;
		size2 = mySize_y;
		e1 = eX;
		e2 = eY;
	} else {
		size1 = mySize_y;
		size2 = mySize_x;
		e1 = eY;
		e2 = eX;
	}

	switch (myteam) {
		default:
		case NUM_TEAM_1: {
			redflag_pos = pos;
			blueflag_pos = pos + eX * fs2 * size1;
			yellowflag_pos = pos - eX * fs2 * size1;
			pinkflag_pos = pos + eX * fs3 * size1;
			break;
		}
		case NUM_TEAM_2: {
			redflag_pos = pos + eX * fs2 * size1;
			blueflag_pos = pos;
			yellowflag_pos = pos - eX * fs2 * size1;
			pinkflag_pos = pos + eX * fs3 * size1;
			break;
		}
		case NUM_TEAM_3: {
			redflag_pos = pos + eX * fs3 * size1;
			blueflag_pos = pos - eX * fs2 * size1;
			yellowflag_pos = pos;
			pinkflag_pos = pos + eX * fs2 * size1;
			break;
		}
		case NUM_TEAM_4: {
			redflag_pos = pos - eX * fs2 * size1;
			blueflag_pos = pos + eX * fs3 * size1;
			yellowflag_pos = pos + eX * fs2 * size1;
			pinkflag_pos = pos;
			break;
		}
	}
	neutralflag_pos = pos;
	flag_size = e1 * fs * size1 + e2 * size2;

	#define X(team) MACRO_BEGIN { \
		f = bound(0, team##flag_statuschange_elapsedtime * 2, 1); \
		if (team##_icon_prevstatus && f < 1) \
			drawpic_aspect_skin_expanding(team##flag_pos, team##_icon_prevstatus, flag_size, '1 1 1', panel_fg_alpha * team##_alpha_prevstatus, DRAWFLAG_NORMAL, f); \
		if (team##_icon) \
			drawpic_aspect_skin(team##flag_pos, team##_icon, flag_size, '1 1 1', panel_fg_alpha * team##_alpha * f, DRAWFLAG_NORMAL); \
	} MACRO_END
	X(red);
	X(blue);
	X(yellow);
	X(pink);
	X(neutral);
	#undef X
}

// Keyhunt HUD modicon section
vector KH_SLOTS[4];

void HUD_Mod_KH(vector pos, vector mySize)
{
	mod_active = 1; // keyhunt should never hide the mod icons panel

	// Read current state

	int state = STAT(KH_KEYS);
	int i, key_state;
	int all_keys, team1_keys, team2_keys, team3_keys, team4_keys, dropped_keys, carrying_keys;
	all_keys = team1_keys = team2_keys = team3_keys = team4_keys = dropped_keys = carrying_keys = 0;

	for(i = 0; i < 4; ++i)
	{
		key_state = (bitshift(state, i * -5) & 31) - 1;

		if(key_state == -1)
			continue;

		if(key_state == 30)
		{
			++carrying_keys;
			key_state = myteam;
		}

		switch(key_state)
		{
			case NUM_TEAM_1: ++team1_keys; break;
			case NUM_TEAM_2: ++team2_keys; break;
			case NUM_TEAM_3: ++team3_keys; break;
			case NUM_TEAM_4: ++team4_keys; break;
			case 29: ++dropped_keys; break;
		}

		++all_keys;
	}

	// Calculate slot measurements

	vector slot_size;

	if(all_keys == 4 && mySize.x * 0.5 < mySize.y && mySize.y * 0.5 < mySize.x)
	{
		// Quadratic arrangement
		slot_size = eX * mySize.x * 0.5 + eY * mySize.y * 0.5;
		KH_SLOTS[0] = pos;
		KH_SLOTS[1] = pos + eX * slot_size.x;
		KH_SLOTS[2] = pos + eY * slot_size.y;
		KH_SLOTS[3] = pos + eX * slot_size.x + eY * slot_size.y;
	}
	else
	{
		if(mySize.x > mySize.y)
		{
			// Horizontal arrangement
			slot_size = eX * mySize.x / all_keys + eY * mySize.y;
			for(i = 0; i < all_keys; ++i)
				KH_SLOTS[i] = pos + eX * slot_size.x * i;
		}
		else
		{
			// Vertical arrangement
			slot_size = eX * mySize.x + eY * mySize.y / all_keys;
			for(i = 0; i < all_keys; ++i)
				KH_SLOTS[i] = pos + eY * slot_size.y * i;
		}
	}

	// Make icons blink in case of RUN HERE

	float blink = 0.6 + sin(2*M_PI*time) / 2.5; // Oscillate between 0.2 and 1
	float alpha;
	alpha = 1;

	if(carrying_keys)
		switch(myteam)
		{
			case NUM_TEAM_1: if(team1_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_2: if(team2_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_3: if(team3_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_4: if(team4_keys == all_keys) alpha = blink; break;
		}

	// Draw icons

	i = 0;

	while(team1_keys--)
		if(myteam == NUM_TEAM_1 && carrying_keys)
		{
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_red_carrying", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
			--carrying_keys;
		}
		else
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_red_taken", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);

	while(team2_keys--)
		if(myteam == NUM_TEAM_2 && carrying_keys)
		{
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_blue_carrying", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
			--carrying_keys;
		}
		else
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_blue_taken", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);

	while(team3_keys--)
		if(myteam == NUM_TEAM_3 && carrying_keys)
		{
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_yellow_carrying", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
			--carrying_keys;
		}
		else
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_yellow_taken", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);

	while(team4_keys--)
		if(myteam == NUM_TEAM_4 && carrying_keys)
		{
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_pink_carrying", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
			--carrying_keys;
		}
		else
			drawpic_aspect_skin(KH_SLOTS[i++], "kh_pink_taken", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);

	while(dropped_keys--)
		drawpic_aspect_skin(KH_SLOTS[i++], "kh_dropped", slot_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
}

// Keepaway HUD mod icon
int kaball_prevstatus; // last remembered status
float kaball_statuschange_time; // time when the status changed

// we don't need to reset for keepaway since it immediately
// autocorrects prevstatus as to if the player has the ball or not

void HUD_Mod_Keepaway(vector pos, vector mySize)
{
	mod_active = 1; // keepaway should always show the mod HUD

	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	float BLINK_FREQ = 5;
	float kaball_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);

	int stat_items = STAT(ITEMS);
	int kaball = (stat_items/IT_KEY1) & 1;

	if(kaball != kaball_prevstatus)
	{
		kaball_statuschange_time = time;
		kaball_prevstatus = kaball;
	}

	vector kaball_pos, kaball_size;

	if(mySize.x > mySize.y) {
		kaball_pos = pos + eX * 0.25 * mySize.x;
		kaball_size = eX * 0.5 * mySize.x + eY * mySize.y;
	} else {
		kaball_pos = pos + eY * 0.25 * mySize.y;
		kaball_size = eY * 0.5 * mySize.y + eX * mySize.x;
	}

	float kaball_statuschange_elapsedtime = time - kaball_statuschange_time;
	float f = bound(0, kaball_statuschange_elapsedtime*2, 1);

	if(kaball_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(kaball_pos, "keepawayball_carrying", kaball_size, '1 1 1', panel_fg_alpha * kaball_alpha, DRAWFLAG_NORMAL, f);

	if(kaball)
		drawpic_aspect_skin(pos, "keepawayball_carrying", eX * mySize.x + eY * mySize.y, '1 1 1', panel_fg_alpha * kaball_alpha * f, DRAWFLAG_NORMAL);
}


// Nexball HUD mod icon
void HUD_Mod_NexBall(vector pos, vector mySize)
{
	float nb_pb_starttime, dt, p;
	int stat_items;

	stat_items = STAT(ITEMS);
	nb_pb_starttime = STAT(NB_METERSTART);

	if (stat_items & IT_KEY1)
		mod_active = 1;
	else
		mod_active = 0;

	//Manage the progress bar if any
	if (nb_pb_starttime > 0)
	{
		dt = (time - nb_pb_starttime) % nb_pb_period;
		// one period of positive triangle
		p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", p, (mySize.x <= mySize.y), 0, autocvar_hud_progressbar_nexball_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if (stat_items & IT_KEY1)
		drawpic_aspect_skin(pos, "nexball_carrying", eX * mySize.x + eY * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Race/CTS HUD mod icons
float crecordtime_prev; // last remembered crecordtime
float crecordtime_change_time; // time when crecordtime last changed
float srecordtime_prev; // last remembered srecordtime
float srecordtime_change_time; // time when srecordtime last changed

float race_status_time;
int race_status_prev;
string race_status_name_prev;
void HUD_Mod_Race(vector pos, vector mySize)
{
	mod_active = 1; // race should never hide the mod icons panel
	entity me;
	me = playerslots[player_localnum];
	float score;
	float f; // yet another function has this
	score = me.(scores[ps_primary]);

	if(!(scores_flags[ps_primary] & SFL_TIME) || teamplay) // race/cts record display on HUD
		return; // no records in the actual race

	// clientside personal record
	string rr;
	if(gametype == MAPINFO_TYPE_CTS)
		rr = CTS_RECORD;
	else
		rr = RACE_RECORD;
	float t = stof(db_get(ClientProgsDB, strcat(shortmapname, rr, "time")));

	if(score && (score < t || !t)) {
		db_put(ClientProgsDB, strcat(shortmapname, rr, "time"), ftos(score));
		if(autocvar_cl_autodemo_delete_keeprecords)
		{
			f = autocvar_cl_autodemo_delete;
			f &= ~1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
	}

	if(t != crecordtime_prev) {
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}

	vector textPos, medalPos;
	float squareSize;
	if(mySize.x > mySize.y) {
		// text on left side
		squareSize = min(mySize.y, mySize.x/2);
		textPos = pos + eX * 0.5 * max(0, mySize.x/2 - squareSize) + eY * 0.5 * (mySize.y - squareSize);
		medalPos = pos + eX * 0.5 * max(0, mySize.x/2 - squareSize) + eX * 0.5 * mySize.x + eY * 0.5 * (mySize.y - squareSize);
	} else {
		// text on top
		squareSize = min(mySize.x, mySize.y/2);
		textPos = pos + eY * 0.5 * max(0, mySize.y/2 - squareSize) + eX * 0.5 * (mySize.x - squareSize);
		medalPos = pos + eY * 0.5 * max(0, mySize.y/2 - squareSize) + eY * 0.5 * mySize.y + eX * 0.5 * (mySize.x - squareSize);
	}

	f = time - crecordtime_change_time;

	if (f > 1) {
		drawstring_aspect(textPos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(pos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(pos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}

	// server record
	t = race_server_record;
	if(t != srecordtime_prev) {
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}
	f = time - srecordtime_change_time;

	if (f > 1) {
		drawstring_aspect(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}

	if (race_status != race_status_prev || race_status_name != race_status_name_prev) {
		race_status_time = time + 5;
		race_status_prev = race_status;
		if (race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = strzone(race_status_name);
	}

	// race "awards"
	float a;
	a = bound(0, race_status_time - time, 1);

	string s;
	s = textShortenToWidth(race_status_name, squareSize, '1 1 0' * 0.1 * squareSize, stringwidth_colors);

	float rank;
	if(race_status > 0)
		rank = race_CheckName(race_status_name);
	else
		rank = 0;
	string rankname;
	rankname = count_ordinal(rank);

	vector namepos;
	namepos = medalPos + '0 0.8 0' * squareSize;
	vector rankpos;
	rankpos = medalPos + '0 0.15 0' * squareSize;

	if(race_status == 0)
		drawpic_aspect_skin(medalPos, "race_newfail", '1 1 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	else if(race_status == 1) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newtime", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 2) {
		if(race_status_name == entcs_GetName(player_localnum) || !race_myrank || race_myrank < rank)
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankgreen", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		else
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankyellow", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 3) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrecordserver", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}

	if (race_status_time - time <= 0) {
		race_status_prev = -1;
		race_status = -1;
		if(race_status_name)
			strunzone(race_status_name);
		race_status_name = string_null;
		if(race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = string_null;
	}
}

void DrawDomItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
	float stat = -1;
	string pic = "";
	vector color = '0 0 0';
	switch(i)
	{
		case 0:
			stat = STAT(DOM_PPS_RED);
			pic = "dom_icon_red";
			color = '1 0 0';
			break;
		case 1:
			stat = STAT(DOM_PPS_BLUE);
			pic = "dom_icon_blue";
			color = '0 0 1';
			break;
		case 2:
			stat = STAT(DOM_PPS_YELLOW);
			pic = "dom_icon_yellow";
			color = '1 1 0';
			break;
		default:
		case 3:
			stat = STAT(DOM_PPS_PINK);
			pic = "dom_icon_pink";
			color = '1 0 1';
			break;
	}
	float pps_ratio = stat / STAT(DOM_TOTAL_PPS);

	if(mySize.x/mySize.y > aspect_ratio)
	{
		i = aspect_ratio * mySize.y;
		myPos.x = myPos.x + (mySize.x - i) / 2;
		mySize.x = i;
	}
	else
	{
		i = 1/aspect_ratio * mySize.x;
		myPos.y = myPos.y + (mySize.y - i) / 2;
		mySize.y = i;
	}

	if (layout) // show text too
	{
		//draw the text
		color *= 0.5 + pps_ratio * (1 - 0.5); // half saturated color at min, full saturated at max
		if (layout == 2) // average pps
			drawstring_aspect(myPos + eX * mySize.y, ftos_decimals(stat, 2), eX * (2/3) * mySize.x + eY * mySize.y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
		else // percentage of average pps
			drawstring_aspect(myPos + eX * mySize.y, strcat( ftos(floor(pps_ratio*100 + 0.5)), "%" ), eX * (2/3) * mySize.x + eY * mySize.y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	//draw the icon
	drawpic_aspect_skin(myPos, pic, '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (stat > 0)
	{
		drawsetcliparea(myPos.x, myPos.y + mySize.y * (1 - pps_ratio), mySize.y, mySize.y * pps_ratio);
		drawpic_aspect_skin(myPos, strcat(pic, "-highlighted"), '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawresetcliparea();
	}
}

void HUD_Mod_Dom(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	int layout = autocvar_hud_panel_modicons_dom_layout;
	int rows, columns;
	float aspect_ratio;
	aspect_ratio = (layout) ? 3 : 1;
	rows = HUD_GetRowCount(team_count, mySize, aspect_ratio);
	columns = ceil(team_count/rows);

	int i;
	float row = 0, column = 0;
	vector pos, itemSize;
	itemSize = eX * mySize.x*(1/columns) + eY * mySize.y*(1/rows);
	for(i=0; i<team_count; ++i)
	{
		pos = myPos + eX * column * itemSize.x + eY * row * itemSize.y;

		DrawDomItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}

void HUD_ModIcons_SetFunc()
{
	switch(gametype)
	{
		case MAPINFO_TYPE_KEYHUNT:		HUD_ModIcons_GameType = HUD_Mod_KH; break;
		case MAPINFO_TYPE_CTF:			HUD_ModIcons_GameType = HUD_Mod_CTF; break;
		case MAPINFO_TYPE_NEXBALL:		HUD_ModIcons_GameType = HUD_Mod_NexBall; break;
		case MAPINFO_TYPE_CTS:
		case MAPINFO_TYPE_RACE:		HUD_ModIcons_GameType = HUD_Mod_Race; break;
		case MAPINFO_TYPE_CA:
		case MAPINFO_TYPE_FREEZETAG:	HUD_ModIcons_GameType = HUD_Mod_CA; break;
		case MAPINFO_TYPE_DOMINATION:	HUD_ModIcons_GameType = HUD_Mod_Dom; break;
		case MAPINFO_TYPE_KEEPAWAY:	HUD_ModIcons_GameType = HUD_Mod_Keepaway; break;
	}
}

int mod_prev; // previous state of mod_active to check for a change
float mod_alpha;
float mod_change; // "time" when mod_active changed

void HUD_ModIcons()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_modicons) return;
		if(!HUD_ModIcons_GameType) return;
	}

	HUD_Panel_UpdateCvars();

	draw_beginBoldFont();

	if(mod_active != mod_prev) {
		mod_change = time;
		mod_prev = mod_active;
	}

	if(mod_active || autocvar__hud_configure)
		mod_alpha = bound(0, (time - mod_change) * 2, 1);
	else
		mod_alpha = bound(0, 1 - (time - mod_change) * 2, 1);

	if(mod_alpha)
		HUD_Panel_DrawBg(mod_alpha);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if(autocvar__hud_configure)
		HUD_Mod_CTF(panel_pos, panel_size);
	else
		HUD_ModIcons_GameType(panel_pos, panel_size);

	draw_endBoldFont();
}
