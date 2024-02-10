#include "cl_tka.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

// Keepaway HUD mod icon
int tkaball_prevstatus; // last remembered status
float tkaball_statuschange_time; // time when the status changed

// we don't need to reset for team keepaway since it immediately
// autocorrects prevstatus as to if the player has the ball or not

void HUD_Mod_TeamKeepaway(vector pos, vector mySize)
{
	mod_active = 1; // team keepaway should always show the mod HUD

	float tkaball_alpha = blink(0.85, 0.15, 5);

	int stat_items = STAT(TKA_BALLSTATUS);
	int tkaball = (stat_items & TKA_BALL_CARRYING);

	if(tkaball != tkaball_prevstatus)
	{
		tkaball_statuschange_time = time;
		tkaball_prevstatus = tkaball;
	}

	vector tkaball_pos, tkaball_size;

	if(mySize.x > mySize.y) {
		tkaball_pos = pos + eX * 0.25 * mySize.x;
		tkaball_size = vec2(0.5 * mySize.x, mySize.y);
	} else {
		tkaball_pos = pos + eY * 0.25 * mySize.y;
		tkaball_size = vec2(mySize.x, 0.5 * mySize.y);
	}

	float tkaball_statuschange_elapsedtime = time - tkaball_statuschange_time;
	float f = bound(0, tkaball_statuschange_elapsedtime*2, 1);

	if(tkaball_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(tkaball_pos, "keepawayball_carrying", tkaball_size, '1 1 1', panel_fg_alpha * tkaball_alpha, DRAWFLAG_NORMAL, f);

	if(stat_items & TKA_BALL_CARRYING) // TODO: unique team based icon while carrying
		drawpic_aspect_skin(pos, "keepawayball_carrying", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * tkaball_alpha * f, DRAWFLAG_NORMAL);
	else if(stat_items & TKA_BALL_TAKEN_RED)
		drawpic_aspect_skin(pos, "tka_taken_red", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * tkaball_alpha * f, DRAWFLAG_NORMAL);
	else if(stat_items & TKA_BALL_TAKEN_BLUE)
		drawpic_aspect_skin(pos, "tka_taken_blue", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * tkaball_alpha * f, DRAWFLAG_NORMAL);
	else if(stat_items & TKA_BALL_TAKEN_YELLOW)
		drawpic_aspect_skin(pos, "tka_taken_yellow", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * tkaball_alpha * f, DRAWFLAG_NORMAL);
	else if(stat_items & TKA_BALL_TAKEN_PINK)
		drawpic_aspect_skin(pos, "tka_taken_pink", vec2(mySize.x, mySize.y), '1 1 1', panel_fg_alpha * tkaball_alpha * f, DRAWFLAG_NORMAL);
}
