// =======================================================
//  Server side client commands code, reworked by Samual
//  Last updated: August 4th, 2011
// =======================================================

#define CC_REQUEST_HELP 1
#define CC_REQUEST_COMMAND 2
#define CC_REQUEST_USAGE 3

entity nagger;

.float cmd_floodtime;
.float cmd_floodcount;
.float checkfail;

float readyrestart_happened;
float readycount;

string MapVote_Suggest(string m);

void ReadyCount();


// ============================
//  Misc. Supporting Functions
// ============================

float SV_ParseClientCommand_floodcheck()
{
	if (timeoutStatus != 2) // if the game is not paused... but wait, doesn't that mean it could be dos'd by pausing it? eh? (old code)
	{
		if(time == self.cmd_floodtime) // todo: add buffer time as well, ONLY one second is a short amount of time for someone to be spamming. 
		{
			self.cmd_floodcount += 1;
			if(self.cmd_floodcount > 8) // todo: replace constant 8 with a cvar for the server to control
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

float Nagger_SendEntity(entity to, float sendflags)
{
	float nags, i, f, b;
	entity e;
	WriteByte(MSG_ENTITY, ENT_CLIENT_NAGGER);

	// bits:
	//   1 = ready
	//   2 = player needs to ready up
	//   4 = vote
	//   8 = player needs to vote
	//  16 = warmup
	// sendflags:
	//  64 = vote counts
	// 128 = vote string

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

	if(sendflags & 64)
		nags |= 64;

	if(sendflags & 128)
		nags |= 128;

	if(!(nags & 4)) // no vote called? send no string
		nags &~= (64 | 128);

	WriteByte(MSG_ENTITY, nags);

	if(nags & 64)
	{
		WriteByte(MSG_ENTITY, vote_yescount);
		WriteByte(MSG_ENTITY, vote_nocount);
		WriteByte(MSG_ENTITY, vote_needed_absolute);
		WriteChar(MSG_ENTITY, to.vote_vote);
	}

	if(nags & 128)
		WriteString(MSG_ENTITY, votecalledvote_display);

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
		nagger.SendFlags |= 64;
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

void ClientCommand_autoswitch(float request, float argc)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2autoswitch^7: Whether or not to switch automatically when getting a better weapon\n");
			return;
			
		case CC_REQUEST_COMMAND:
			self.autoswitch = ("0" != argv(1));
			sprint(self, strcat("^1autoswitch is currently turned ", (self.autoswitch ? "on" : "off"), ".\n"));
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd autoswitch selection\n");
			sprint(self, "  Where 'selection' is 1 or 0 for on or off.\n"); 
			return;
	}
}

void ClientCommand_checkfail(float request, string command) // used only by client side code
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2checkfail^7: Report if a client-side check failed\n");
			return;
			
		case CC_REQUEST_COMMAND:
			print(sprintf("CHECKFAIL: %s (%s) epically failed check %s\n", self.netname, self.netaddress, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1))));
			self.checkfail = 1;
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd checkfail message\n");
			sprint(self, "  Where 'message' is the message reported by client about the fail.\n");
			return;
	}
}

void ClientCommand_clientversion(float request, float argc) // used only by client side code
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2clientversion^7: Release version of the game\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(self.flags & FL_CLIENT)
			{
				self.version = ((argv(1) == "$gameversion") ? 1 : stof(argv(1)));
				
				if(self.version < autocvar_gameversion_min || self.version > autocvar_gameversion_max)
				{
					self.version_mismatch = 1;
					ClientKill_TeamChange(-2); // observe
				} 
				else if(autocvar_g_campaign || autocvar_g_balance_teams || autocvar_g_balance_teams_force) 
				{
					//JoinBestTeam(self, FALSE, TRUE);
				} 
				else if(teamplay && !autocvar_sv_spectate && !(self.team_forced > 0)) 
				{
					self.classname = "observer"; // really?
					stuffcmd(self, "menu_showteamselect\n");
				}
			}
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd clientversion version\n");
			sprint(self, "  Where 'version' is the game version reported by self.\n");
			return;
	}
}

void ClientCommand_cvar_changes(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2cvar_changes^7: Prints a list of all changed server cvars\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, cvar_changes);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 sv_cmd cvar_changes\n");
			sprint(self, "  No arguments required.\n");
			//sprint(self, "See also: ^2cvar_purechanges^7\n");
			return;
	}
}

void ClientCommand_cvar_purechanges(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2cvar_purechanges^7: Prints a list of all changed gameplay cvars\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, cvar_purechanges);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 sv_cmd cvar_purechanges\n");
			sprint(self, "  No arguments required.\n");
			//sprint(self, "See also: ^2cvar_changes^7\n");
			return;
	}
}

void ClientCommand_info(float request, float argc)
{
	string command;
	
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2info^7: Request for unique server information set up by admin\n");
			return;
			
		case CC_REQUEST_COMMAND:
			command = cvar_string_builtin(strcat("sv_info_", argv(1))); 
			if(command)
				wordwrap_sprint(command, 1111); // why 1111?
			else
				sprint(self, "ERROR: unsupported info command\n");
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd info request\n");
			sprint(self, "  Where 'request' is the suffixed string appended onto the request for cvar.\n");
			return;
	}
}

void ClientCommand_join(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2join^7: Become a player in the game\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(self.flags & FL_CLIENT)
			{
				if(self.classname != "player" && !lockteams && !g_arena)
				{
					if(nJoinAllowed(1)) 
					{
						if(g_ca) { self.caplayer = 1; }
						if(autocvar_g_campaign) { campaign_bots_may_start = 1; }
						
						self.classname = "player";
						PlayerScore_Clear(self);
						bprint ("^4", self.netname, "^4 is playing now\n");
						PutClientInServer();
					}
					else 
					{
						//player may not join because of g_maxplayers is set
						centerprint_atprio(self, CENTERPRIO_MAPVOTE, PREVENT_JOIN_TEXT);
					}
				}
			}
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd join\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_ladder(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2ladder^7: Get information about top players if supported\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, ladder_reply);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd ladder\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_lsmaps(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2lsmaps^7: List maps which can be used with the current game mode\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, lsmaps_reply);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd lsmaps\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_lsnewmaps(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2lsnewmaps^7: List maps which TODO\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, lsnewmaps_reply);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd lsnewmaps\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_maplist(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2maplist^7: Full server maplist reply\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, maplist_reply);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd maplist\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_rankings(float request)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2rankings^7: Print information about rankings\n");
			return;
			
		case CC_REQUEST_COMMAND:
			sprint(self, rankings_reply);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd rankings\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_ready(float request) // TODO: reimplement how this works
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2ready^7: Qualify as ready to end warmup stage (or restart server if allowed)\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(self.flags & FL_CLIENT)
			{
				if(inWarmupStage || autocvar_sv_ready_restart || g_race_qualifying == 2)
				{
					if(!readyrestart_happened || autocvar_sv_ready_restart_repeatable)
					{
						if (self.ready) // toggle
						{
							self.ready = FALSE;
							bprint(self.netname, "^2 is ^1NOT^2 ready\n");
						}
						else
						{
							self.ready = TRUE;
							bprint(self.netname, "^2 is ready\n");
						}

						// cannot reset the game while a timeout is active!
						if(!timeoutStatus)
							ReadyCount();
					} else {
						sprint(self, "^1Game has already been restarted\n");
					}
				}
			}
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd ready\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_records(float request)
{
	float i;
	
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2records^7: List top 10 records for the current map\n");
			return;
			
		case CC_REQUEST_COMMAND:
			for(i = 0; i < 10; ++i)
				sprint(self, records_reply[i]);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd records\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_reportcvar(float request, float argc, string command)
{
	float tokens;
	string s;
	
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2reportcvar^7: Old system for sending a client cvar to the server\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(substring(argv(2), 0, 1) == "$") // undefined cvar: use the default value on the server then
			{
				s = strcat(substring(command, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
				tokens = tokenize_console(s);
			}
			GetCvars(1);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd reportcvar <cvar>\n");
			sprint(self, "  Where 'cvar' is the cvar plus arguments to send to the server.\n");
			return;
	}
}

void ClientCommand_say(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2say^7: Print a message to chat to all players\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(argc >= 2)
				Say(self, FALSE, world, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd say <message>\n");
			sprint(self, "  Where 'message' is the string of text to say.\n");
			return;
	}
}

void ClientCommand_say_team(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2say_team^7: Print a message to chat to all team mates\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(argc >= 2)
				Say(self, TRUE, world, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd say_team <message>\n");
			sprint(self, "  Where 'message' is the string of text to say.\n");
			return;
	}
}

void ClientCommand_selectteam(float request, float argc)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2selectteam^7: Attempt to choose a team to join into\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if (self.flags & FL_CLIENT)
			{
				if(teamplay)
					if not(self.team_forced > 0) 
						if not(lockteams) 
							switch(argv(1))
							{
								case "red": ClientKill_TeamChange(COLOR_TEAM1); break;
								case "blue": ClientKill_TeamChange(COLOR_TEAM2); break;
								case "yellow": ClientKill_TeamChange(COLOR_TEAM3); break;
								case "pink": ClientKill_TeamChange(COLOR_TEAM4); break;
								case "auto": ClientKill_TeamChange(-1); break;
								
								default: break;
							}
						else
							sprint(self, "^7The game has already begun, you must wait until the next map to be able to join a team.\n");
					else
						sprint(self, "selectteam can not be used as your team is forced\n");
				else
					sprint(self, "selectteam can only be used in teamgames\n");
			}
			return; // never fall through to usage

		default:
		case CC_REQUEST_USAGE:
			sprint( self, strcat( "selectteam none/red/blue/yellow/pink/auto - \"", argv(1), "\" not recognised\n" ) );
			sprint(self, "\nUsage:^3 cmd selectteam team\n");
			sprint(self, "  No arguments required.\n");
			return;
	}
}

void ClientCommand_sentcvar(float request, float argc, string command)
{
	float tokens;
	string s;
	
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(self, "  ^2sentcvar^7: New system for sending a client cvar to the server\n");
			return;
			
		case CC_REQUEST_COMMAND:
			if(argc == 2) // undefined cvar: use the default value on the server then
			{
				s = strcat(substring(command, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
				tokens = tokenize_console(s);
			}
			GetCvars(1);
			return; // never fall through to usage
			
		default:
		case CC_REQUEST_USAGE:
			sprint(self, "\nUsage:^3 cmd sentcvar <cvar>\n");
			sprint(self, "  Where 'cvar' is the cvar plus arguments to send to the server.\n");
			return;
	}
}


/*
void ClientCommand_(float request, entity client)
{
	switch(request)
	{
		case CC_REQUEST_HELP:
			sprint(client, "  ^2blah^7: foobar\n");
			return;
			
		case CC_REQUEST_COMMAND:
			
			return;
			
		default:
		case CC_REQUEST_USAGE:
			sprint(client, "\nUsage:^3 cmd \n");
			sprint(client, "  No arguments required.\n");
			return;
	}
}
*/


// ======================================
//  Main Function Called By Engine (cmd)
// ======================================
// If this function exists, server game code parses clientcommand before the engine code gets it.

void SV_ParseClientCommand(string command)
{
	float search_request_type;
	float argc = tokenize_console(command);
	
	// for floodcheck
	switch(strtolower(argv(0)))
	{
		// exempt commands which are not subject to floodcheck
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
	
	/* NOTE: totally disabled for now, however the functionality and descriptions are there if we ever want it.
	if(argv(0) == "help") 
	{
		if(argc == 1) 
		{
			sprint(self, "\nUsage:^3 cmd COMMAND...^7, where possible commands are:\n");
			ClientCommand_autoswitch(CC_REQUEST_HELP, 0);
			ClientCommand_checkfail(CC_REQUEST_HELP, "");
			ClientCommand_clientversion(CC_REQUEST_HELP, 0);
			ClientCommand_cvar_changes(CC_REQUEST_HELP);
			ClientCommand_cvar_purechanges(CC_REQUEST_HELP);
			ClientCommand_info(CC_REQUEST_HELP, 0);
			ClientCommand_join(CC_REQUEST_HELP); 
			ClientCommand_ladder(CC_REQUEST_HELP);
			ClientCommand_lsmaps(CC_REQUEST_HELP);
			ClientCommand_lsnewmaps(CC_REQUEST_HELP);
			ClientCommand_maplist(CC_REQUEST_HELP);
			ClientCommand_rankings(CC_REQUEST_HELP);
			ClientCommand_ready(CC_REQUEST_HELP);
			ClientCommand_records(CC_REQUEST_HELP);
			ClientCommand_reportcvar(CC_REQUEST_HELP, 0, "");
			ClientCommand_say(CC_REQUEST_HELP, 0, "");
			ClientCommand_say_team(CC_REQUEST_HELP, 0, "");
			ClientCommand_selectteam(CC_REQUEST_HELP, 0);
			ClientCommand_sentcvar(CC_REQUEST_HELP, 0, "");
			sprint(self, "For help about specific commands, type cmd help COMMAND\n");
			return;
		} 
		else
			search_request_type = CC_REQUEST_USAGE; // Instead of trying to call a command, we're going to see detailed information about it
	} 
	else*/ if(GameCommand_Vote(command, self)) 
	{
		return; // handled by server/vote.qc 
	}
	else if(GameCommand_MapVote(argv(0))) 
	{
		return; // handled by server/g_world.qc
	}
	else if(CheatCommand(argc)) 
	{
		return; // handled by server/cheats.qc
	}
	else
		search_request_type = CC_REQUEST_COMMAND; // continue as usual and scan for normal commands
	
	switch(strtolower((search_request_type == CC_REQUEST_USAGE) ? argv(1) : argv(0)))
	{
		// Do not hard code aliases for these, instead create them in defaultXonotic.cfg
		// also: keep in alphabetical order, please ;)
		
		case "autoswitch": ClientCommand_autoswitch(search_request_type, argc); break;
		case "checkfail": ClientCommand_checkfail(search_request_type, command); break;
		case "clientversion": ClientCommand_clientversion(search_request_type, argc); break;
		case "cvar_changes": ClientCommand_cvar_changes(search_request_type); break;
		case "cvar_purechanges": ClientCommand_cvar_purechanges(search_request_type); break;
		case "info": ClientCommand_info(search_request_type, argc); break;
		case "join": ClientCommand_join(search_request_type); break;
		case "ladder": ClientCommand_ladder(search_request_type); break;
		case "lsmaps": ClientCommand_lsmaps(search_request_type); break;
		case "lsnewmaps": ClientCommand_lsnewmaps(search_request_type); break;
		case "maplist": ClientCommand_maplist(search_request_type); break;
		case "rankings": ClientCommand_rankings(search_request_type); break;
		case "ready": ClientCommand_ready(search_request_type); break;
		case "records": ClientCommand_records(search_request_type); break;
		case "reportcvar": ClientCommand_reportcvar(search_request_type, argc, command); break;
		case "say": ClientCommand_say(search_request_type, argc, command); break;
		case "say_team": ClientCommand_say_team(search_request_type, argc, command); break;
		case "selectteam": ClientCommand_selectteam(search_request_type, argc); break;
		case "sentcvar": ClientCommand_sentcvar(search_request_type, argc, command); break;
		
		default:
			clientcommand(self, command); //print("Invalid command. For a list of supported commands, try cmd help.\n");
	}
}
