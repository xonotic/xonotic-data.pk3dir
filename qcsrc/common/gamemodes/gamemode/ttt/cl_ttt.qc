#include "cl_ttt.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

void HUD_Mod_TTT(vector pos, vector mySize)
{
	mod_active = 1; // ttt should always show the mod HUD

	int mystatus = entcs_receiver(player_localnum).ttt_status;
	string player_text = "";
	vector player_color = '1 1 1';
	//string player_icon = "";
	if(mystatus == TTT_STATUS_TRAITOR)
	{
		player_text = _("Traitor");
		player_color = '1 0 0';
		//player_icon = "player_red";
	}
	else if(mystatus == TTT_STATUS_INNOCENT)
	{
		player_text = _("Innocent");
		player_color = '0 1 0';
		//player_icon = "player_neutral";
	}
	else if(mystatus == TTT_STATUS_DETECTIVE)
	{
		player_text = _("Detective");
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
	if(!STAT(GAME_STOPPED) && !warmup_stage && STAT(TTT_ROUNDTIMER) > 0)
	{
		float timeleft = max(0, STAT(TTT_ROUNDTIMER) - time);
		timeleft = ceil(timeleft);
		float minutesLeft = floor(timeleft / 60);
		time_text = seconds_tostring(timeleft);
		if(intermission_time || minutesLeft >= 5 || warmup_stage || STAT(TTT_ROUNDTIMER) == 0)
			timer_color = '1 1 1'; //white
		else if(minutesLeft >= 1)
			timer_color = '1 1 0'; //yellow
		else
			timer_color = '1 0 0'; //red
	}

	//drawpic_aspect_skin(pos, player_icon, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if(!time_text)
		drawstring_aspect(pos, player_text, vec2(mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	else
	{
		drawstring_aspect(pos, player_text, vec2(0.5 * mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos + eX * (0.5 * mySize.x), time_text, vec2(0.5 * mySize.x, mySize.y), timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}

REGISTER_MUTATOR(cl_ttt, true);

MUTATOR_HOOKFUNCTION(cl_ttt, ForcePlayercolors_Skip, CBC_ORDER_LAST)
{
	if(!ISGAMETYPE(TTT))
		return false;
		
	entity player = M_ARGV(0, entity);
	entity e = entcs_receiver(player.entnum - 1);
	int otherplayer_status = ((e) ? e.ttt_status : 0);
	int mystatus = entcs_receiver(player_localnum).ttt_status;

	int plcolor = TTT_COLOR_INNOCENT; // default to innocent

	if((mystatus == TTT_STATUS_TRAITOR || intermission || STAT(GAME_STOPPED)) && otherplayer_status == TTT_STATUS_TRAITOR)
	{
		plcolor = TTT_COLOR_TRAITOR;
	}
	
	//LegendGuard adds INNOCENT part 21-02-2021
	if((mystatus == TTT_STATUS_INNOCENT || intermission || STAT(GAME_STOPPED)) && otherplayer_status == TTT_STATUS_INNOCENT)
	{
		plcolor = TTT_COLOR_INNOCENT;
	}

	//LegendGuard adds if sentence for Detective model color which will shown for everyone 21-02-2021
	if (otherplayer_status == TTT_STATUS_DETECTIVE)
	{
		plcolor = TTT_COLOR_DETECTIVE;
	}

	player.colormap = 1024 + plcolor;
	return true;
}

MUTATOR_HOOKFUNCTION(cl_ttt, DrawScoreboard_Force)
{
	// show the scoreboard when the round ends, so players can see who the traitor was
	return STAT(GAME_STOPPED);
}
