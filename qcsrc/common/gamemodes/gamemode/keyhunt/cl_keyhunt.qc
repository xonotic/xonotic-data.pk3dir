#include "cl_keyhunt.qh"

#include <client/hud/panel/modicons.qh>

// Keyhunt HUD modicon section
vector KH_SLOTS[4];

void HUD_Mod_KH(vector pos, vector mySize)
{
	mod_active = 1; // keyhunt should never hide the mod icons panel

	// Read current state
	int state = STAT(OBJECTIVE_STATUS);
	if(!state) return;

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
		slot_size = vec2(mySize.x * 0.5, mySize.y * 0.5);
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
			slot_size = vec2(mySize.x / all_keys, mySize.y);
			for(i = 0; i < all_keys; ++i)
				KH_SLOTS[i] = pos + eX * slot_size.x * i;
		}
		else
		{
			// Vertical arrangement
			slot_size = vec2(mySize.x, mySize.y / all_keys);
			for(i = 0; i < all_keys; ++i)
				KH_SLOTS[i] = pos + eY * slot_size.y * i;
		}
	}

	// Make icons blink in case of RUN HERE

	float alpha = 1;
	if(carrying_keys)
	{
		float blink = 0.6 + sin(2 * M_PI * time) * 0.4; // Oscillate between 0.2 and 1
		switch(myteam)
		{
			case NUM_TEAM_1: if(team1_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_2: if(team2_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_3: if(team3_keys == all_keys) alpha = blink; break;
			case NUM_TEAM_4: if(team4_keys == all_keys) alpha = blink; break;
		}
	}
	alpha *= panel_fg_alpha;

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
