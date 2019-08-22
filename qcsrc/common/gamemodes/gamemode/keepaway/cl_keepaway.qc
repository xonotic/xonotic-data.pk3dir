#include "cl_keepaway.qh"

#include <client/hud/panel/modicons.qh>

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
		kaball_size = vec2(0.5 * mySize.x, mySize.y);
	} else {
		kaball_pos = pos + eY * 0.25 * mySize.y;
		kaball_size = vec2(mySize.x, 0.5 * mySize.y);
	}

	float kaball_statuschange_elapsedtime = time - kaball_statuschange_time;
	float f = bound(0, kaball_statuschange_elapsedtime*2, 1);

	if(kaball_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(kaball_pos, "keepawayball_carrying", kaball_size, '1 1 1', panel_fg_alpha * kaball_alpha, DRAWFLAG_NORMAL, f);

	if(kaball)
		drawpic_aspect_skin(pos, "keepawayball_carrying", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * kaball_alpha * f, DRAWFLAG_NORMAL);
}
