void Net_Announcer(string announce_snd)
{
  sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/", announce_snd, ".wav"), VOL_BASEVOICE, ATTN_NONE);
}

/**
 * Checks whether the server initiated a map restart (stat_game_starttime changed)
 *
 * TODO: Use a better solution where a common shared entitiy is used that contains
 * timelimit, fraglimit and game_starttime! Requires engine changes (remove STAT_TIMELIMIT
 * and STAT_FRAGLIMIT to be auto-sent)
 */
void CheckForGamestartChange() {
	float startTime;
	startTime = getstatf(STAT_GAMESTARTTIME);
	if (previous_game_starttime != startTime) {
		if ((time + 5.0) < startTime) {
			//if connecting to server while restart was active don't always play prepareforbattle
			sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/prepareforbattle.wav"), VOL_BASEVOICE, ATTN_NONE);
		}
		if (time < startTime) {
			restartAnnouncer = spawn();
			restartAnnouncer.think = restartAnnouncer_Think;
			restartAnnouncer.nextthink = startTime - floor(startTime - time); //synchronize nextthink to startTime
		}
	}
	previous_game_starttime = startTime;
}

void restartAnnouncer_Think() {
	float countdown_rounded, countdown;
	countdown = getstatf(STAT_GAMESTARTTIME) - time;
	countdown_rounded = floor(0.5 + countdown);
	if(countdown <= 0) {
		if (!spectatee_status) //do cprint only for players
			centerprint_generic(CPID_GAME_STARTING, _("^1Begin!"), 1, 0);

		sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/begin.wav"), VOL_BASEVOICE, ATTN_NONE);
		//reset maptime announcers now as well
		announcer_5min = announcer_1min = FALSE;

		remove(self);
		return;
	}
	else {
		if (!spectatee_status) //do cprint only for players
			centerprint_generic(CPID_GAME_STARTING, _("^1Game starts in %d seconds"), 1, countdown_rounded);

		if(countdown_rounded <= 3 && countdown_rounded >= 1) {
			sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/", ftos(countdown_rounded), ".wav"), VOL_BASEVOICE, ATTN_NONE);
		}

		self.nextthink = getstatf(STAT_GAMESTARTTIME) - (countdown - 1);
	}
}

/**
 * Plays the 1minute or 5 minutes (of maptime) remaining sound, if client wants it
 */
void maptimeAnnouncer() {
	float timelimit;
	timelimit = getstatf(STAT_TIMELIMIT);
	float timeleft;
	timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);

	float warmuplimit;
	float warmuptimeleft;
	if(warmup_stage) {
		warmuplimit = autocvar_g_warmup_limit;
		if(warmuplimit > 0) {
			warmuptimeleft = max(0, warmuplimit + getstatf(STAT_GAMESTARTTIME) - time); 
		}
	}

	//5 minute check
	if (autocvar_cl_sound_maptime_warning >= 2) {
		//make sure that after connect (and e.g. 4 minutes left) we will not get a wrong sound
		if(announcer_5min)
		{
			if(((!warmup_stage || warmuplimit == 0) && timeleft > 300) || (warmup_stage && warmuplimit > 0 && warmuptimeleft > 300))
				announcer_5min = FALSE;
		}
		else if (((!warmup_stage || warmuplimit == 0) && timelimit > 0 && timeleft < 300 && timeleft > 299) || (warmup_stage && warmuplimit > 0 && warmuptimeleft < 300 && warmuptimeleft > 299))
			//if we're in warmup mode, check whether there's a warmup timelimit
			if not (warmuplimit == -1 && warmup_stage) {
				announcer_5min = TRUE;
				sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/5minutesremain.wav"), VOL_BASEVOICE, ATTN_NONE);
			}
	}

	//1 minute check
	if (autocvar_cl_sound_maptime_warning == 1 || autocvar_cl_sound_maptime_warning == 3) {
		if (announcer_1min)
		{
			if(((!warmup_stage || warmuplimit == 0) && timeleft > 60) || (warmup_stage && warmuplimit > 0 && warmuptimeleft > 60))
				announcer_1min = FALSE;
		}
		else if (((!warmup_stage || warmuplimit == 0) && timelimit > 0 && timeleft < 60) || (warmup_stage && warmuplimit > 0 && warmuptimeleft < 60))
			//if we're in warmup mode, check whether there's a warmup timelimit
			if not (warmuplimit == -1 && warmup_stage) {
				announcer_1min = TRUE;
				sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/1minuteremains.wav"), VOL_BASEVOICE, ATTN_NONE);
			}
	}
}

/**
 * Announce carried items (e.g. flags in CTF).
 */
float redflag_prev;
float blueflag_prev;
void carrierAnnouncer() {
	float stat_items, redflag, blueflag;
	float pickup;
	string item;

	if not(autocvar_cl_notify_carried_items)
		return;

	stat_items = getstati(STAT_ITEMS);

	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;

	if (redflag == 3 && redflag != redflag_prev) {
		item = _("^1RED^7 flag");
		pickup = (redflag_prev == 2);
	}

	if (blueflag == 3 && blueflag != blueflag_prev) {
		item = _("^4BLUE^7 flag");
		pickup = (blueflag_prev == 2);
	}

	if (item)
	{
		if (pickup) {
			if (autocvar_cl_notify_carried_items & 2)
				centerprint(sprintf(_("You picked up the %s!"), item));
		}
		else {
			if (autocvar_cl_notify_carried_items & 1)
				centerprint(sprintf(_("You got the %s!"), item));
		}
	}

	blueflag_prev = blueflag;
	redflag_prev = redflag;
}

void Announcer()
{
  CheckForGamestartChange();
	maptimeAnnouncer();
	carrierAnnouncer();
}

/**
 * Add all future announcer sounds precaches here.
 * TODO: announcer queues
 */
void Announcer_Precache () {
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