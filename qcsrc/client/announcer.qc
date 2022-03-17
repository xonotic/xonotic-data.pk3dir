#include "announcer.qh"

#include <client/hud/panel/centerprint.qh>
#include <client/mutators/_mod.qh>
#include <common/notifications/all.qh>
#include <common/stats.qh>

bool announcer_1min;
bool announcer_5min;
string AnnouncerOption()
{
	string ret = autocvar_cl_announcer;
	MUTATOR_CALLHOOK(AnnouncerOption, ret);
	ret = M_ARGV(0, string);
	return ret;
}

entity announcer_countdown;

void Announcer_Countdown(entity this)
{
	float starttime = STAT(GAMESTARTTIME);
	float roundstarttime = STAT(ROUNDSTARTTIME);
	if(roundstarttime == -1)
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_ROUNDSTOP);
		delete(this);
		announcer_countdown = NULL;
		return;
	}

	bool inround = (roundstarttime && time >= starttime);
	float countdown = (inround ? roundstarttime - time : starttime - time);
	float countdown_rounded = floor(0.5 + countdown);

	if(countdown <= 0) // countdown has finished, starttime is now
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_BEGIN);
		Local_Notification(MSG_MULTI, MULTI_COUNTDOWN_BEGIN);
		delete(this);
		announcer_countdown = NULL;
		return;
	}
	else // countdown is still going
	{
		if(inround)
		{
			Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_ROUNDSTART, countdown_rounded);
			Notification annce_num = Announcer_PickNumber(CNT_ROUNDSTART, countdown_rounded);
			if(annce_num != NULL)
				Local_Notification(MSG_ANNCE, annce_num);
			this.nextthink = (roundstarttime - (countdown - 1));
		}
		else
		{
			Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_GAMESTART, countdown_rounded);
			Notification annce_num = Announcer_PickNumber(CNT_GAMESTART, countdown_rounded);
			if(!roundstarttime && annce_num != NULL) // Don't announce game start in round based modes
				Local_Notification(MSG_ANNCE, annce_num);
			this.nextthink = (starttime - (countdown - 1));
		}
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
	if(intermission)
	{
		if(announcer_countdown)
		{
			centerprint_Kill(ORDINAL(CPID_ROUND));
			if(announcer_countdown)
			{
				delete(announcer_countdown);
				announcer_countdown = NULL;
			}
		}
		return;
	}

	if(previous_game_starttime != startTime)
	{
		if(time < startTime)
		{
			if (!announcer_countdown)
			{
				announcer_countdown = new(announcer_countdown);
				setthink(announcer_countdown, Announcer_Countdown);
			}

			if(time + 5.0 < startTime) // if connecting to server while restart was active don't always play prepareforbattle
			if(time > announcer_countdown.nextthink) // don't play it again if countdown was already going
				Local_Notification(MSG_ANNCE, ANNCE_PREPARE);

			announcer_countdown.nextthink = startTime - floor(startTime - time + 0.5); //synchronize nextthink to startTime
		}
	}

	previous_game_starttime = startTime;
}

#define ANNOUNCER_CHECKMINUTE(minute) MACRO_BEGIN \
	if(announcer_##minute##min) { \
		if(timeleft > minute * 60) \
			announcer_##minute##min = false; \
	} else { \
		if(timeleft < minute * 60 && timeleft > minute * 60 - 1) { \
			announcer_##minute##min = true; \
			Local_Notification(MSG_ANNCE, ANNCE_REMAINING_MIN_##minute); \
		} \
	} \
MACRO_END

void Announcer_Time()
{
	static bool warmup_stage_prev;

	if(intermission)
		return;

	if (warmup_stage != warmup_stage_prev)
	{
		announcer_5min = announcer_1min = false;
		warmup_stage_prev = warmup_stage;
		return;
	}

	float starttime = STAT(GAMESTARTTIME);
	if(time < starttime)
	{
		announcer_5min = announcer_1min = false;
		return;
	}

	float timeleft;
	if(warmup_stage)
	{
		float warmup_timelimit = STAT(WARMUP_TIMELIMIT);
		if(warmup_timelimit > 0)
			timeleft = max(0, warmup_timelimit - time);
		else
			timeleft = 0;
	}
	else
		timeleft = max(0, STAT(TIMELIMIT) * 60 + starttime - time);

	if(autocvar_cl_announcer_maptime >= 2)
		ANNOUNCER_CHECKMINUTE(5);

	if((autocvar_cl_announcer_maptime == 1) || (autocvar_cl_announcer_maptime == 3))
		ANNOUNCER_CHECKMINUTE(1);
}

void Announcer()
{
	Announcer_Gamestart();
	Announcer_Time();
}
