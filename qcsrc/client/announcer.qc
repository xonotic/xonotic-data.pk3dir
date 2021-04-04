#include "announcer.qh"

#include <client/hud/panel/centerprint.qh>
#include <client/mutators/_mod.qh>

#include <common/notifications/all.qh>
#include <common/stats.qh>
#include <common/mapinfo.qh>

#include <common/ent_cs.qh>
#include <common/gamemodes/gamemode/duel/duel.qh>

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
	float game_timeout = STAT(GAME_TIMEOUT);
	
	bool rounds;
	float countdown;
	
	if(roundstarttime == -1 || game_timeout)
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_ROUNDSTOP);
		delete(this);
		announcer_countdown = NULL;
		return;
	}

	//if(roundstarttime >= starttime)
	//	starttime = roundstarttime;
	if(starttime <= time && roundstarttime != starttime) // game start time has passed
		announcer_5min = announcer_1min = false; // reset maptime announcers now as well

	if(roundstarttime && time >= starttime) {
		rounds = true;
		countdown = (roundstarttime - time);
	} else {
		rounds = false;
		countdown = (starttime - time);
	}
	
	float countdown_rounded = floor(0.5 + countdown);

	if(time >= starttime) centerprint_ClearTitle();
	
	if(countdown <= 0) // countdown has finished, starttime is now
	{
		Local_Notification(MSG_CENTER, CENTER_COUNTDOWN_BEGIN);
		Local_Notification(MSG_MULTI, MULTI_COUNTDOWN_BEGIN);
		delete(this);
		announcer_countdown = NULL;
		centerprint_ClearTitle();
		return;
	}
	else // countdown is still going
	{
		// counting down to rounds
		if(rounds)
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
			if(!roundstarttime && annce_num != NULL) // count only if the gametype has no rounds
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

			// z411 set title
			if(time < STAT(GAMESTARTTIME) && !warmup_stage) {
				if(gametype == MAPINFO_TYPE_DUEL) {
					entity pl1 = players.sort_next;
					entity pl2 = pl1.sort_next;
					
					centerprint_SetTitle(strcat(entcs_GetName(pl1.sv_entnum), " vs ", entcs_GetName(pl2.sv_entnum)));
				} else {
					centerprint_SetTitle(MapInfo_Type_ToText(gametype));
				}
			}
			
			if(time + 5.0 < startTime) // if connecting to server while restart was active don't always play prepareforbattle
			if(time > announcer_countdown.nextthink && !warmup_stage && time < STAT(GAMESTARTTIME)) { // don't play it again if countdown was already going
				if(teamplay)
					Local_Notification(MSG_ANNCE, ANNCE_PREPARE_TEAM);
				else
					Local_Notification(MSG_ANNCE, ANNCE_PREPARE);
			}
			
			announcer_countdown.nextthink = startTime - floor(startTime - time); //synchronize nextthink to startTime
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
	if(intermission)
		return;

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
		timeleft = max(0, STAT(TIMELIMIT) * 60 + STAT(GAMESTARTTIME) - time);

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
