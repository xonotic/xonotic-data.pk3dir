#include "announcer.qh"

#include "mutators/events.qh"

#include "../common/notifications.qh"
#include "../common/stats.qh"

bool announcer_1min;
bool announcer_5min;
string AnnouncerOption()
{
	string ret = autocvar_cl_announcer;
	MUTATOR_CALLHOOK(AnnouncerOption, ret);
	ret = ret_string;
	return ret;
}

entity announcer_countdown;

void Announcer_Countdown()
{
	SELFPARAM();
	float starttime = STAT(GAMESTARTTIME);
	float roundstarttime = STAT(ROUNDSTARTTIME);
	if(roundstarttime == -1)
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_ROUNDSTOP);
		remove(this);
		announcer_countdown = NULL;
		return;
	}
	if(roundstarttime >= starttime)
		starttime = roundstarttime;
	if(starttime <= time && roundstarttime != starttime) // game start time has passed
		announcer_5min = announcer_1min = false; // reset maptime announcers now as well

	float countdown = (starttime - time);
	float countdown_rounded = floor(0.5 + countdown);

	if(countdown <= 0) // countdown has finished, starttime is now
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_BEGIN);
		Local_Notification(MSG_MULTI, MULTI_COUNTDOWN_BEGIN);
		remove(this);
		announcer_countdown = NULL;
		return;
	}
	else // countdown is still going
	{
		// if concomitant countdown to round start overrides countdown to game start
		if(roundstarttime == starttime)
		{
			Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_ROUNDSTART, countdown_rounded);
			Local_Notification(MSG_ANNCE, Announcer_PickNumber(CNT_ROUNDSTART, countdown_rounded));
		}
		else
		{
			Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_GAMESTART, countdown_rounded);
			Local_Notification(MSG_ANNCE, Announcer_PickNumber(CNT_GAMESTART, countdown_rounded));
		}

		this.nextthink = (starttime - (countdown - 1));
	}
}

/**
 * Checks whether the server initiated a map restart (stat_game_starttime changed)
 *
 * TODO: Use a better solution where a common shared entitiy is used that contains
 * timelimit, fraglimit and game_starttime! Requires engine changes (remove STAT_TIMELIMIT
 * and STAT_FRAGLIMIT to be auto-sent)
 */
 float previous_game_starttime;
void Announcer_Gamestart()
{
	float startTime = STAT(GAMESTARTTIME);
	float roundstarttime = STAT(ROUNDSTARTTIME);
	if(roundstarttime > startTime)
		startTime = roundstarttime;

	if(previous_game_starttime != startTime)
	{
		if(time < startTime)
		{
			if (!announcer_countdown)
			{
				announcer_countdown = new(announcer_countdown);
				announcer_countdown.think = Announcer_Countdown;
			}

			if(time + 5.0 < startTime) // if connecting to server while restart was active don't always play prepareforbattle
			if(time > announcer_countdown.nextthink) // don't play it again if countdown was already going
				Local_Notification(MSG_ANNCE, ANNCE_PREPARE);

			announcer_countdown.nextthink = startTime - floor(startTime - time); //synchronize nextthink to startTime
		}
	}

	previous_game_starttime = startTime;
}


// Plays the 1 minute or 5 minutes (of maptime) remaining sound, if client wants it
void Announcer_Time()
{
	float timelimit = STAT(TIMELIMIT);
	float timeleft = max(0, timelimit * 60 + STAT(GAMESTARTTIME) - time);
	float warmup_timeleft = 0;

	if(warmup_stage)
		if(autocvar_g_warmup_limit > 0)
			warmup_timeleft = max(0, autocvar_g_warmup_limit + STAT(GAMESTARTTIME) - time);

	// 5 minute check
	if(autocvar_cl_announcer_maptime >= 2)
	{
		// make sure that after connect (and e.g. 4 minutes left) we will not get a wrong sound
		if(announcer_5min)
		{
			if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timeleft > 300)
				|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft > 300))
					announcer_5min = false;
		}
		else
		{
			if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timelimit > 0 && timeleft < 300 && timeleft > 299)
				|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft < 300 && warmup_timeleft > 299))
			{
				//if we're in warmup mode, check whether there's a warmup timelimit
				if(!(autocvar_g_warmup_limit == -1 && warmup_stage))
				{
					announcer_5min = true;
					Local_Notification(MSG_ANNCE, ANNCE_REMAINING_MIN_5);
				}
			}
		}
	}

	// 1 minute check
	if((autocvar_cl_announcer_maptime == 1) || (autocvar_cl_announcer_maptime == 3))
	{
		if (announcer_1min)
		{
			if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timeleft > 60)
				|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft > 60))
					announcer_1min = false;
		}
		else if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timelimit > 0 && timeleft < 60)
			|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft < 60))
		{
			// if we're in warmup mode, check whether there's a warmup timelimit
			if(!(autocvar_g_warmup_limit == -1 && warmup_stage))
			{
				announcer_1min = true;
				Local_Notification(MSG_ANNCE, ANNCE_REMAINING_MIN_1);
			}
		}
	}
}

void Announcer()
{
	Announcer_Gamestart();
	Announcer_Time();
}
