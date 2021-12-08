#include "cl_mh.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

void HUD_Mod_MH(vector pos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	int mystatus = entcs_receiver(player_localnum).mh_status;
	string player_text = "";
	vector player_color = '1 1 1';
	//string player_icon = "";
	if(mystatus == MH_STATUS_HUNTER)
	{
		player_text = _("Hunter");
		player_color = '1 0 0';
		//player_icon = "player_red";
	}
	else if(mystatus == MH_STATUS_RUNNER)
	{
		player_text = _("Runner");
		player_color = '0 0 1';
		//player_icon = "player_blue";
	}
	else
	{
		// if the player has no valid status, don't draw anything
		return;
	}

	string time_text = string_null;
	vector timer_color = '1 1 1';
	if(!STAT(GAME_STOPPED) && !warmup_stage && STAT(MH_ROUNDTIMER) > 0)
	{
		float timeleft = max(0, STAT(MH_ROUNDTIMER) - time);
		timeleft = ceil(timeleft);
		float minutesLeft = floor(timeleft / 60);
		time_text = seconds_tostring(timeleft);
		if(intermission_time || minutesLeft >= 5 || warmup_stage || STAT(MH_ROUNDTIMER) == 0)
			timer_color = '1 1 1'; //white
		else if(minutesLeft >= 1)
			timer_color = '1 1 0'; //yellow
		else
			timer_color = '1 0 0'; //red
	}

	// Autotaunt feature
	string timerrunnertaunt_text = string_null;
	vector timerrunnertaunt_color = '1 1 1';
	if(!STAT(GAME_STOPPED) && !warmup_stage && STAT(MH_ROUNDTIMER) > 0)
	{
		float timeleft_runnertaunt = max(0, STAT(MH_RUNNER_TAUNTTIMER) - time);
		timeleft_runnertaunt = ceil(timeleft_runnertaunt);
		timerrunnertaunt_text = strcat("Taunt: ", seconds_tostring(timeleft_runnertaunt));
		float secondsLeft = timeleft_runnertaunt;
		if(intermission_time || secondsLeft >= 20 || warmup_stage || STAT(MH_RUNNER_TAUNTTIMER) == 0)
			timerrunnertaunt_color = '1 1 1'; //white
		else if(secondsLeft >= 10)
			timerrunnertaunt_color = '1 1 0'; //yellow
		else
			timerrunnertaunt_color = '1 0 0'; //red
	}

	// Autotaunt feature
	if(mystatus == MH_STATUS_RUNNER)
		drawstring_aspect(pos + eX * (0.3 * mySize.x) + eY * (0.7 * mySize.y), timerrunnertaunt_text, vec2(0.3 * mySize.x, mySize.y), timerrunnertaunt_color, panel_fg_alpha, DRAWFLAG_NORMAL);

	//drawpic_aspect_skin(pos, player_icon, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if(!time_text)
		drawstring_aspect(pos, player_text, vec2(mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	else
	{
		drawstring_aspect(pos, player_text, vec2(0.5 * mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos + eX * (0.5 * mySize.x), time_text, vec2(0.5 * mySize.x, mySize.y), timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}
