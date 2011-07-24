// =======================================================
//  Server side client commands code, reworked by Samual
//  Last updated: July 23rd, 2011
// =======================================================

#define CC_REQUEST_HELP 1
#define CC_REQUEST_COMMAND 2
#define CC_REQUEST_USAGE 3

entity nagger;

.float cmd_floodtime;
.float cmd_floodcount;
float readyrestart_happened;
float readycount;

string MapVote_Suggest(string m);

void ReadyCount();


// ============================
//  Misc. Supporting Functions
// ============================

float Nagger_SendEntity(entity to, float sendflags)
{
	float nags, i, f, b;
	entity e;
	WriteByte(MSG_ENTITY, ENT_CLIENT_NAGGER);

	nags = 0;
	if(readycount)
	{
		nags |= 1;
		if(to.ready == 0)
			nags |= 2;
	}
	if(votecalled)
	{
		nags |= 4;
		if(to.vote_vote == 0)
			nags |= 8;
	}
	if(inWarmupStage)
		nags |= 16;

	if(sendflags & 128)
		nags |= 128;

	if(!(nags & 4)) // no vote called? send no string
		nags &~= 128;

	WriteByte(MSG_ENTITY, nags);

	if(nags & 128)
	{
		WriteString(MSG_ENTITY, votecalledvote_display);
	}

	if(nags & 1)
	{
		for(i = 1; i <= maxclients; i += 8)
		{
			for(f = 0, e = edict_num(i), b = 1; b < 256; b *= 2, e = nextent(e))
				if(clienttype(e) != CLIENTTYPE_REAL || e.ready)
					f |= b;
			WriteByte(MSG_ENTITY, f);
		}
	}

	return TRUE;
}
void Nagger_Init()
{
	Net_LinkEntity(nagger = spawn(), FALSE, 0, Nagger_SendEntity);
}
void Nagger_VoteChanged()
{
	if(nagger)
		nagger.SendFlags |= 128;
}
void Nagger_VoteCountChanged()
{
	if(nagger)
		nagger.SendFlags |= 1;
}
void Nagger_ReadyCounted()
{
	if(nagger)
		nagger.SendFlags |= 1;
}

void ReadyRestartForce()
{
	local entity e;

	bprint("^1Server is restarting...\n");

	VoteReset();

	// clear overtime
	if (checkrules_overtimesadded > 0 && g_race_qualifying != 2) {
		//we have to decrease timelimit to its original value again!!
		float newTL;
		newTL = autocvar_timelimit;
		newTL -= checkrules_overtimesadded * autocvar_timelimit_overtime;
		cvar_set("timelimit", ftos(newTL));
	}

	checkrules_suddendeathend = checkrules_overtimesadded = checkrules_suddendeathwarning = 0;


	readyrestart_happened = 1;
	game_starttime = time;
	if(!g_ca && !g_arena)
		game_starttime += RESTART_COUNTDOWN;
	restart_mapalreadyrestarted = 0; //reset this var, needed when cvar sv_ready_restart_repeatable is in use

	inWarmupStage = 0; //once the game is restarted the game is in match stage

	//reset the .ready status of all players (also spectators)
	FOR_EACH_CLIENTSLOT(e)
		e.ready = 0;
	readycount = 0;
	Nagger_ReadyCounted(); // NOTE: this causes a resend of that entity, and will also turn off warmup state on the client

	if(autocvar_teamplay_lockonrestart && teamplay) {
		lockteams = 1;
		bprint("^1The teams are now locked.\n");
	}

	//initiate the restart-countdown-announcer entity
	if(autocvar_sv_ready_restart_after_countdown && !g_ca && !g_arena)
	{
		restartTimer = spawn();
		restartTimer.think = restartTimer_Think;
		restartTimer.nextthink = game_starttime;
	}

	//after a restart every players number of allowed timeouts gets reset, too
	if(autocvar_sv_timeout)
	{
		FOR_EACH_REALPLAYER(e)
			e.allowedTimeouts = autocvar_sv_timeout_number;
	}

	//reset map immediately if this cvar is not set
	if (!autocvar_sv_ready_restart_after_countdown)
		reset_map(TRUE);

	if(autocvar_sv_eventlog)
		GameLogEcho(":restart");
}

void ReadyRestart()
{
	// no arena, assault support yet...
	if(g_arena | g_assault | gameover | intermission_running | race_completing)
		localcmd("restart\n");
	else
		localcmd("\nsv_hook_gamerestart\n");

	ReadyRestartForce();

	// reset ALL scores, but only do that at the beginning
	//of the countdown if sv_ready_restart_after_countdown is off!
	//Otherwise scores could be manipulated during the countdown!
	if (!autocvar_sv_ready_restart_after_countdown)
		Score_ClearAll();
}

/**
 * Counts how many players are ready. If not enough players are ready, the function
 * does nothing. If all players are ready, the timelimit will be extended and the
 * restart_countdown variable is set to allow other functions like PlayerPostThink
 * to detect that the countdown is now active. If the cvar sv_ready_restart_after_countdown
 * is not set the map will be resetted.
 *
 * Function is called after the server receives a 'ready' sign from a player.
 */
void ReadyCount()
{
	local entity e;
	local float r, p;

	r = p = 0;

	FOR_EACH_REALPLAYER(e)
	{
		p += 1;
		if(e.ready)
			r += 1;
	}

	readycount = r;

	Nagger_ReadyCounted();

	if(r) // at least one is ready
	if(r == p) // and, everyone is ready
		ReadyRestart();
}

/**
 * Restarts the map after the countdown is over (and cvar sv_ready_restart_after_countdown
 * is set)
 */
void restartTimer_Think() {
	restart_mapalreadyrestarted = 1;
	reset_map(TRUE);
	Score_ClearAll();
	remove(self);
	return;
}

/**
 * Checks whether the player who calls the timeout is allowed to do so.
 * If so, it initializes the timeout countdown. It also checks whether another
 * timeout was already running at this time and reacts correspondingly.
 *
 * affected globals/fields: .allowedTimeouts, remainingTimeoutTime, remainingLeadTime,
 *                          timeoutInitiator, timeoutStatus, timeoutHandler
 *
 * This function is called when a player issues the calltimeout command.
 */
void evaluateTimeout() {
	if (inWarmupStage && !g_warmup_allow_timeout)
		return sprint(self, "^7Error: You can not call a timeout in warmup-stage!\n");
	if (time < game_starttime )
		return sprint(self, "^7Error: You can not call a timeout while the map is being restarted!\n");
	if (timeoutStatus != 2) {
		//if the map uses a timelimit make sure that timeout cannot be called right before the map ends
		if (autocvar_timelimit) {
			//a timelimit was used
			local float myTl;
			myTl = autocvar_timelimit;

			local float lastPossibleTimeout;
			lastPossibleTimeout = (myTl*60) - autocvar_sv_timeout_leadtime - 1;

			if (lastPossibleTimeout < time - game_starttime)
				return sprint(self, "^7Error: It is too late to call a timeout now!\n");
		}
	}
	//player may not call a timeout if he has no calls left
	if (self.allowedTimeouts < 1)
		return sprint(self, "^7Error: You already used all your timeout calls for this map!\n");
	//now all required checks are passed
	self.allowedTimeouts -= 1;
	bprint(self.netname, " ^7called a timeout (", ftos(self.allowedTimeouts), " timeouts left)!\n"); //write a bprint who started the timeout (and how many he has left)
	remainingTimeoutTime = autocvar_sv_timeout_length;
	remainingLeadTime = autocvar_sv_timeout_leadtime;
	timeoutInitiator = self;
	if (timeoutStatus == 0) { //if another timeout was already active, don't change its status (which was 1 or 2) to 1, only change it to 1 if no timeout was active yet
		timeoutStatus = 1;
		//create the timeout indicator which centerprints the information to all players and takes care of pausing/unpausing
		timeoutHandler = spawn();
		timeoutHandler.think = timeoutHandler_Think;
	}
	timeoutHandler.nextthink = time; //always let the entity think asap

	//inform all connected clients about the timeout call
	Announce("timeoutcalled");
}

/**
 * Checks whether a player is allowed to resume the game. If he is allowed to do it,
 * and the lead time for the timeout is still active, this countdown just will be aborted (the
 * game will never be paused). Otherwise the remainingTimeoutTime will be set to the corresponding
 * value of the cvar sv_timeout_resumetime.
 *
 * This function is called when a player issues the resumegame command.
 */
void evaluateTimein() {
	if (!timeoutStatus)
		return sprint(self, "^7Error: There is no active timeout which could be aborted!\n");
	if (self != timeoutInitiator)
		return sprint(self, "^7Error: You may not abort the active timeout. Only the player who called it can do that!\n");
	if (timeoutStatus == 1) {
		remainingTimeoutTime = timeoutStatus = 0;
		timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
		bprint(strcat("^7The timeout was aborted by ", self.netname, " !\n"));
	}
	else if (timeoutStatus == 2) {
		//only shorten the remainingTimeoutTime if it makes sense
		if( remainingTimeoutTime > (autocvar_sv_timeout_resumetime + 1) ) {
			bprint(strcat("^1Attention: ^7", self.netname, " resumed the game! Prepare for battle!\n"));
			remainingTimeoutTime = autocvar_sv_timeout_resumetime;
			timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
		}
		else
			sprint(self, "^7Error: Your resumegame call was discarded!\n");

	}
}


// =======================
//  Command Sub-Functions
// =======================

void ClientCommand_autoswitch(float request, entity client, float argc)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			print("  ^2autoswitch^7: Whether or not to switch automatically when getting a better weapon\n");
			return;
			
		case CC_REQUEST_COMMAND:
			client.autoswitch = ("0" != argv(1));
			sprint(client, strcat("^1autoswitch has been turned ", (client.autoswitch ? "on" : "off"), ".\n"));
			return;
			
		default:
		case CC_REQUEST_USAGE:
			print("\nUsage:^3 cl_cmd autoswitch\n");
			print("  No arguments required.\n");
			return;
	}
}


// ======================================
//  Main Function Called By Engine (cmd)
// ======================================
// If this function exists, server game code parses clientcommand before the engine code gets it.

float SV_ParseClientCommand_floodcheck()
{
	if (timeoutStatus != 2)
	{
		if(time == self.cmd_floodtime)
		{
			self.cmd_floodcount += 1;
			if(self.cmd_floodcount > 8)
				return FALSE; // too much spam, halt
		}
		else
		{
			self.cmd_floodtime = time;
			self.cmd_floodcount = 1;
		}
	}
	return TRUE; // continue, as we're not flooding yet
}
void SV_ParseClientCommand(string command)
{
	float search_request_type;
	float argc = tokenize_console(command);
	
	// for floodcheck
	switch(strtolower(argv(0)))
	{
		case "begin": break; // handled by engine in host_cmd.c
		case "pause": break; // handled by engine in host_cmd.c
		case "prespawn": break; // handled by engine in host_cmd.c
		case "reportcvar": break; // handled by server in this file
		case "sentcvar": break; // handled by server in this file
		case "spawn": break; // handled by engine in host_cmd.c
		default: 
			if(SV_ParseClientCommand_floodcheck())
				break; // "TRUE": continue, as we're not flooding yet
			else
				return; // "FALSE": not allowed to continue, halt
	}
	
	search_request_type = CC_REQUEST_COMMAND; // for now, we're not going to be sending 

	/*if(argv(0) == "help") 
	{
		if(argc == 1) 
		{
			print("\nUsage:^3 cl_cmd COMMAND...^7, where possible commands are:\n");
			ClientCommand_autoswitch(CC_REQUEST_HELP, world, 0);
			print("For help about specific commands, type cl_cmd help COMMAND\n");
			return;
		} 
		else
			search_request_type = CC_REQUEST_USAGE; // Instead of trying to call a command, we're going to see detailed information about it
	} 
	/*else if(GameCommand_Vote(command, world)) 
	{
		return; // handled by server/vote.qc 
	}
	else if(GameCommand_Ban(command)) 
	{
		return; // handled by server/ipban.qc
	}
	else if(GameCommand_Generic(command)) 
	{
		return; // handled by common/gamecommand.qc
	}
	else
		search_request_type = CC_REQUEST_COMMAND; // continue as usual and scan for normal commands
	*/
	
	//  ((argv(0) == "help") ? argv(1) : argv(0)) 
	switch(strtolower(argv(0))) // if first argument is help, then search for the second argument. Else, search for first. 
	{
		// Do not hard code aliases for these, instead create them in defaultXonotic.cfg
		// also: keep in alphabetical order, please ;)
		
		case "autoswitch": ClientCommand_autoswitch(search_request_type, self, argc); break;
		
		default:
			print("Invalid command. For a list of supported commands, try sv_cmd help.\n");
	}
}