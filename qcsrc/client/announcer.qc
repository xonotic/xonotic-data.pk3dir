float previous_announcement_time;
float previous_game_starttime;
string previous_announcement;

// remaining maptime announcer sounds, true when sound was already played
float announcer_1min;
float announcer_5min;

void Announcer_Play(string announcement)
{
	if((announcement != previous_announcement) || (time >= (previous_announcement_time + autocvar_cl_announcer_antispam)))
	{
		sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/", announcement, ".wav"), VOL_BASEVOICE, ATTN_NONE);

		if(previous_announcement) { strunzone(previous_announcement); }
		
		previous_announcement = strzone(announcement);
		previous_announcement_time = time;
	}
}

void Announcer_Countdown() 
{
	float starttime = getstatf(STAT_GAMESTARTTIME);
	float countdown = (starttime - time);
	float countdown_rounded = floor(0.5 + countdown);
	
	if(countdown <= 0) // countdown has finished, starttime is now
	{
		if (!spectatee_status) 
			centerprint_generic(CPID_GAME_STARTING, _("^1Begin!"), 1, 0);

		Announcer_Play("begin");
		announcer_5min = announcer_1min = FALSE; // reset maptime announcers now as well
		remove(self);
		return;
	}
	else // countdown is still going
	{
		if (!spectatee_status)
			centerprint_generic(CPID_GAME_STARTING, _("^1Game starts in %d seconds"), 1, countdown_rounded);

		if(countdown_rounded <= 3 && countdown_rounded >= 1) 
			Announcer_Play(ftos(countdown_rounded));

		self.nextthink = (starttime - (countdown - 1));
	}
}

/**
 * Checks whether the server initiated a map restart (stat_game_starttime changed)
 *
 * TODO: Use a better solution where a common shared entitiy is used that contains
 * timelimit, fraglimit and game_starttime! Requires engine changes (remove STAT_TIMELIMIT
 * and STAT_FRAGLIMIT to be auto-sent)
 */
void Announcer_Gamestart() 
{
	float startTime = getstatf(STAT_GAMESTARTTIME);
	
	if(previous_game_starttime != startTime) 
	{
		if((time + 5.0) < startTime) // if connecting to server while restart was active don't always play prepareforbattle
			Announcer_Play("prepareforbattle");
		
		if(time < startTime) 
		{
			entity e;
			e = spawn();
			e.think = Announcer_Countdown;
			e.nextthink = startTime - floor(startTime - time); //synchronize nextthink to startTime
		}
	}
	
	previous_game_starttime = startTime;
}


// Plays the 1 minute or 5 minutes (of maptime) remaining sound, if client wants it
void Announcer_Time() 
{
	float timelimit = getstatf(STAT_TIMELIMIT);
	float timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);
	float warmup_timeleft = 0;
	
	if(warmup_stage) 
		if(autocvar_g_warmup_limit > 0)
			warmup_timeleft = max(0, autocvar_g_warmup_limit + getstatf(STAT_GAMESTARTTIME) - time); 

	// 5 minute check
	if(autocvar_cl_announcer_maptime >= 2) 
	{
		// make sure that after connect (and e.g. 4 minutes left) we will not get a wrong sound
		if(announcer_5min)
		{
			if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timeleft > 300) 
				|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft > 300))
					announcer_5min = FALSE;
		}
		else 
		{
			if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timelimit > 0 && timeleft < 300 && timeleft > 299) 
				|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft < 300 && warmup_timeleft > 299))
			{
				//if we're in warmup mode, check whether there's a warmup timelimit
				if not(autocvar_g_warmup_limit == -1 && warmup_stage) 
				{
					announcer_5min = TRUE;
					Announcer_Play("5minutesremain");
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
					announcer_1min = FALSE;
		}
		else if(((!warmup_stage || autocvar_g_warmup_limit == 0) && timelimit > 0 && timeleft < 60) 
			|| (warmup_stage && autocvar_g_warmup_limit > 0 && warmup_timeleft < 60))
		{
			// if we're in warmup mode, check whether there's a warmup timelimit
			if not(autocvar_g_warmup_limit == -1 && warmup_stage) 
			{
				announcer_1min = TRUE;
				Announcer_Play("1minuteremains");
			}
		}
	}
}

void Announcer()
{
	Announcer_Gamestart();
	Announcer_Time();
}

void Announcer_Precache () 
{
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1minuteremains.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/5minutesremain.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/electrobitch.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/airshot.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/03kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/05kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/10kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/15kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/20kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/25kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/30kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/botlike.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/yoda.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/amazing.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/awesome.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/headshot.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/impressive.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/prepareforbattle.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/begin.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/timeoutcalled.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1fragleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/2fragsleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/3fragsleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/terminated.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/2.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/3.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/4.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/5.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/6.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/7.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/8.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/9.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/10.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/lastsecond.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/narrowly.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/voteaccept.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/votecall.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/votefail.wav"));
}
