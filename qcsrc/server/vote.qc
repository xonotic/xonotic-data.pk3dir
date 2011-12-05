// =============================================
//  Server side voting code, reworked by Samual
//  Last updated: December 4th, 2011
// =============================================

#define VC_REQUEST_COMMAND 1
#define VC_REQUEST_USAGE 2

#define VC_ASGNMNT_BOTH 1
#define VC_ASGNMNT_CLIENTONLY 2
#define VC_ASGNMNT_SERVERONLY 3

#define VOTE_SELECT_ABSTAIN -2
#define VOTE_SELECT_REJECT -1
#define VOTE_SELECT_NULL 0
#define VOTE_SELECT_ACCEPT 1

string GetKickVoteVictim_newcommand;
string GetKickVoteVictim_reason;

string RemapVote_display;
string RemapVote_vote;


// =============================================
//  Nagger for players to know status of voting
// =============================================

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
		if(to.vote_selection == 0)
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
		WriteChar(MSG_ENTITY, to.vote_selection);
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


// =======================
//  Game logic for voting
// =======================

void VoteStop(entity stopper) 
{
	bprint("\{1}^2* ^3", VoteCommand_getname(stopper), "^2 stopped ^3", VoteCommand_getname(votecaller), "^2's vote\n");
	if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vstop:", ftos(stopper.playerid))); }
	
	// Don't force them to wait for next vote, this way they can e.g. correct their vote.
	if(votecaller)
		if(stopper == votecaller) 
			votecaller.vote_next = time + autocvar_sv_vote_stop;

	VoteReset();
}


// ============================================
//  Misc. supporting functions for votecommand
// ============================================

float Votecommand_check_assignment(entity caller, float assignment)
{
	float from_server = (!caller);
	
	if((assignment == VC_ASGNMNT_BOTH) 
		|| ((!from_server && assignment == VC_ASGNMNT_CLIENTONLY) 
		|| (from_server && assignment == VC_ASGNMNT_SERVERONLY)))
	{
		return TRUE;
	}

	return FALSE;
}

string VoteCommand_getprefix(entity caller)
{
	if(caller)
		return "cmd";
	else
		return "sv_cmd";
}

string VoteCommand_getname(entity caller)
{
	if(caller)
		return caller.netname;
	else
		return ((autocvar_sv_adminnick != "") ? autocvar_sv_adminnick : autocvar_hostname);
}

string VoteCommand_extractcommand(string input, float startpos, float argc) 
{
	string output;
	
	if((argc - 1) < startpos)
		output = "";
	else
		output = substring(input, argv_start_index(startpos), argv_end_index(-1) - argv_start_index(startpos));
		
	print("VoteCommand_parse: '", output, "'. \n");
	return output;
}

float VoteCommand_checknasty(string vote_command)
{
	if((strstrofs(vote_command, ";", 0) >= 0)
		|| (strstrofs(vote_command, "\n", 0) >= 0)
		|| (strstrofs(vote_command, "\r", 0) >= 0)
		|| (strstrofs(vote_command, "$", 0) >= 0))
		return TRUE;
		
	return FALSE;
}

entity GetKickVoteVictim(string vote, string cmd, entity caller) // todo re-write this
{
	float tokens;
	string ns;
	entity e;
	string reason;

	tokens = tokenize_console(vote);
	ns = "";

	e = GetCommandPlayerSlotTargetFromTokenizedCommand(tokens, 1);
	if(e)
	{
		if(ParseCommandPlayerSlotTarget_firsttoken < tokens)
			GetKickVoteVictim_reason = substring(vote, argv_start_index(ParseCommandPlayerSlotTarget_firsttoken), argv_end_index(-1) - argv_start_index(ParseCommandPlayerSlotTarget_firsttoken));
		else
			GetKickVoteVictim_reason = "";

		reason = "";
		if(cmd != "vdo" || GetKickVoteVictim_reason == "")
			reason = "~"; // by convention, ~ prefixes a "unverified" kickban which will not be networked

		if(substring(GetKickVoteVictim_reason, 0, 1) == "~")
		{
			reason = "~";
			GetKickVoteVictim_reason = substring(GetKickVoteVictim_reason, 1, strlen(GetKickVoteVictim_reason) - 1);
		}

		if(caller)
			reason = strcat(reason, "player ", strdecolorize(caller.netname));
		else
			reason = strcat(reason, "console vote");
		if(GetKickVoteVictim_reason != "")
			reason = strcat(reason, ": ", strdecolorize(GetKickVoteVictim_reason));

		if not(cvar_value_issafe(reason))
			reason = uri_escape(reason);

		GetKickVoteVictim_newcommand = strcat(argv(0), " # ", ftos(num_for_edict(e)));
		if(argv(0) == "kickban")
		{
			GetKickVoteVictim_newcommand = strcat(GetKickVoteVictim_newcommand, " ", ftos(autocvar_g_ban_default_bantime), " ", ftos(autocvar_g_ban_default_masksize), " ", reason);
		}
		else if(argv(0) == "kick")
		{
			GetKickVoteVictim_newcommand = strcat(GetKickVoteVictim_newcommand, " ", reason);
		}
		return e;
	}

	print_to(caller, strcat("Usage: ", cmd, " ", argv(0), " #playernumber (as in \"status\")\n"));
	return world;
}

float RemapVote(string vote, string cmd, entity e)
{
	float vote_argc;
	entity victim;
	vote_argc = tokenize_console(vote);

	if(!VoteAllowed(argv(0), cmd))
		return FALSE;

	// VoteAllowed tokenizes!
	vote_argc = tokenize_console(vote);

	// remap chmap to gotomap (forces intermission)
	if(vote_argc < 2)
		if(argv(0) == "chmap" || argv(0) == "gotomap" || argv(0) == "kick" || argv(0) == "kickban") // won't work without arguments
			return FALSE;
	if(argv(0) == "chmap")
	{
		vote = strcat("gotomap ", substring(vote, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
		vote_argc = tokenize_console(vote);
	}
	if(argv(0) == "gotomap")
	{
		if(!(vote = ValidateMap(substring(vote, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), e)))
			return FALSE;
		vote = strcat("gotomap ", vote);
		vote_argc = tokenize_console(vote); // ValidateMap may have done some stuff to it
	}

	// make kick and kickban votes a bit nicer (and reject them if formatted badly)
	if(argv(0) == "kick" || argv(0) == "kickban")
	{
		if(!(victim = GetKickVoteVictim(vote, cmd, e)))
			return FALSE;
		RemapVote_vote = GetKickVoteVictim_newcommand;
		RemapVote_display = strcat("^1", vote, " (^7", victim.netname, "^1): ", GetKickVoteVictim_reason);
	}
	else
	{
		RemapVote_vote = vote;
		RemapVote_display = strzone(strcat("^1", vote));
	}

	return TRUE;
}


// =======================
//  Command Sub-Functions
// =======================

void VoteCommand_abstain(float request, entity caller) // CLIENT ONLY
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if not(votecalled) { print_to(caller, "^1No vote called."); }
			else if not(caller.vote_selection == VOTE_SELECT_NULL || autocvar_sv_vote_change) { print_to(caller, "^1You have already voted."); }
			
			else // everything went okay, continue changing vote
			{
				print_to(caller, "^1You abstained from your vote.");
				caller.vote_selection = VOTE_SELECT_ABSTAIN;
				msg_entity = caller;
				if(!autocvar_sv_vote_singlecount) { VoteCount(); }
			}
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote abstain\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_call(float request, entity caller, float argc, string vote_command) // BOTH
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote call\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_force(float request, float argc, string vote_command) // SERVER ONLY
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote force result\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_master(float request, entity caller, float argc, string vote_command) // CLIENT ONLY
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if(autocvar_sv_vote_master)
			{
				switch(strtolower(argv(2)))
				{
					case "do":
					{
						vote_command = VoteCommand_extractcommand(vote_command, 3, argc);
						
						if not(caller.vote_master) { print_to(caller, "^1You do not have vote master privelages."); }
						else if not(VoteCommand_checknasty(vote_command)) { print_to(caller, "^1Syntax error in command, see 'vhelp' for more info."); }
						else if not(RemapVote(vote_command, "vdo", caller)) { print_to(caller, "^1This command is not acceptable, see 'vhelp' for more info."); }
						
						else // everything went okay, proceed with command
						{
							localcmd(strcat(RemapVote_vote, "\n"));
							print_to(caller, strcat("Executing command '", RemapVote_display, "' on server."));
							bprint("\{1}^2* ^3", VoteCommand_getname(caller), "^2 used their ^3master^2 status to do \"^2", RemapVote_display, "^2\".\n");
							if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vdo:", ftos(caller.playerid), ":", RemapVote_display)); }
						}
						
						return;
					}
					
					case "login":
					{
						if not(autocvar_sv_vote_master_password != "") { print_to(caller, "^1Login to vote master is not allowed."); }
						else if(caller.vote_master) { print_to(caller, "^1You are already logged in as vote master."); }
						else if not(autocvar_sv_vote_master_password == argv(3)) { print_to(caller, strcat("Rejected vote master login from ", VoteCommand_getname(caller))); }

						else // everything went okay, proceed with giving this player master privilages
						{
							caller.vote_master = TRUE;
							print_to(caller, strcat("Accepted vote master login from ", VoteCommand_getname(caller)));
							bprint("\{1}^2* ^3", VoteCommand_getname(caller), "^2 logged in as ^3master^2\n");
							if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vlogin:", ftos(caller.playerid))); }
						}
						
						return;
					}
					
					default: // calling a vote for master
					{
						if not(autocvar_sv_vote_master_callable) { print_to(caller, "^1Vote to become vote master is not allowed."); } // todo update this description in defaultXonotic.cfg
						else if(votecalled) { print_to(caller, "^1There is already a vote called."); }
						
						else // everything went okay, continue with creating vote
						{
							votecalled = TRUE;
							votecalledmaster = TRUE;
							votecalledvote = strzone("XXX");
							votecalledvote_display = strzone("^3master");
							votefinished = time + autocvar_sv_vote_timeout;
							votecaller = caller;
							
							caller.vote_selection = VOTE_SELECT_ACCEPT;
							caller.vote_next = time + autocvar_sv_vote_wait;
							
							bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2 calls a vote to become ^3master^2.\n");
							if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vcall:", ftos(votecaller.playerid), ":", votecalledvote_display)); }
							Nagger_VoteChanged();
							VoteCount(); // needed if you are the only one
						}
						
						return;
					}
				}
			}
			else { print_to(caller, "^1Master control of voting is not allowed."); }
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote master action [arguments]\n");
			print("  TODO.\n");
			return;
		}
	}
}

void VoteCommand_no(float request, entity caller) // CLIENT ONLY
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if not(votecalled) { print_to(caller, "^1No vote called."); }
			else if not(caller.vote_selection == VOTE_SELECT_NULL || autocvar_sv_vote_change) { print_to(caller, "^1You have already voted."); }
			
			else // everything went okay, continue changing vote
			{
				print_to(caller, "^1You rejected the vote.");
				caller.vote_selection = VOTE_SELECT_REJECT;
				msg_entity = caller;
				if(!autocvar_sv_vote_singlecount) { VoteCount(); }
			}
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote no\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_status(float request, entity caller) // BOTH
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote status\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_stop(float request, entity caller) // BOTH
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if not(votecalled) { print_to(caller, "^1No vote called."); }
			else if((caller == votecaller) || !caller || caller.vote_master) { VoteStop(caller); }
			else { print_to(caller, "^1You are not allowed to stop that Vote."); }
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote stop\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void VoteCommand_yes(float request, entity caller) // CLIENT ONLY
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if not(votecalled) { print_to(caller, "^1No vote called."); }
			if not(caller.vote_selection == VOTE_SELECT_NULL || autocvar_sv_vote_change) { print_to(caller, "^1You have already voted."); }
			
			else // everything went okay, continue changing vote
			{
				print_to(caller, "^1You accepted the vote.");
				caller.vote_selection = VOTE_SELECT_ACCEPT;
				msg_entity = caller;
				if(!autocvar_sv_vote_singlecount) { VoteCount(); }
			}
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote yes\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void VoteCommand_(float request)
{
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case VC_REQUEST_USAGE:
		{
			print("\nUsage:^3 vote \n");
			print("  No arguments required.\n");
			return;
		}
	}
}
*/


// ================================
//  Macro system for vote commands
// ================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
#define VOTE_COMMANDS(request,caller,arguments,command) \
	VOTE_COMMAND("abstain", VoteCommand_abstain(request, caller), "Abstain your vote in current vote", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("call", VoteCommand_call(request, caller, arguments, command), "Create a new vote for players to decide on", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("force", VoteCommand_force(request, arguments, command), "Force the result of a vote", VC_ASGNMNT_SERVERONLY) \
	VOTE_COMMAND("help", VoteCommand_macro_help(caller, arguments), "Shows this information", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("master", VoteCommand_master(request, caller, arguments, command), "", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("no", VoteCommand_no(request, caller), "Select no in current vote", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("status", VoteCommand_status(request, caller), "Prints information about current vote", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("stop", VoteCommand_stop(request, caller), "Immediately end a vote", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("yes", VoteCommand_yes(request, caller), "Select yes in current vote", VC_ASGNMNT_CLIENTONLY) \
	/* nothing */

void VoteCommand_macro_help(entity caller, float argc)
{
	string command_origin = VoteCommand_getprefix(caller);
	
	if(argc == 2) // help display listing all commands
	{
		print("\nUsage:^3 ", command_origin, " vote COMMAND...^7, where possible commands are:\n");
		
		#define VOTE_COMMAND(name,function,description,assignment) \
			{ if(Votecommand_check_assignment(caller, assignment)) { print("  ^2", name, "^7: ", description, "\n"); } }
			
		VOTE_COMMANDS(0, caller, 0, "")
		#undef VOTE_COMMAND
		
		print("For help about specific commands, type ", command_origin, " vote help COMMAND\n");
	}
	else // usage for individual command
	{
		#define VOTE_COMMAND(name,function,description,assignment) \
			{ if(Votecommand_check_assignment(caller, assignment)) { if(name == strtolower(argv(2))) { function; return; } } }
			
		VOTE_COMMANDS(VC_REQUEST_USAGE, caller, argc, "")
		#undef VOTE_COMMAND
	}
	
	return;
}

float VoteCommand_macro_command(entity caller, float argc, string vote_command)
{
	#define VOTE_COMMAND(name,function,description,assignment) \
		{ if(Votecommand_check_assignment(caller, assignment)) { if(name == strtolower(argv(1))) { function; return TRUE; } } }
		
	VOTE_COMMANDS(VC_REQUEST_COMMAND, caller, argc, vote_command)
	#undef VOTE_COMMAND
	
	return FALSE;
}


// ======================================
//  Main function handling vote commands
// ======================================

void VoteCommand(float request, entity caller, float argc, string vote_command) 
{
	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3 
	// cmd     vote - master - login - password
	
	switch(request)
	{
		case VC_REQUEST_COMMAND:
		{
			if(VoteCommand_macro_command(caller, argc, vote_command))
				return;
		}
			
		default:
			print_to(caller, strcat("Unknown vote command", ((argv(1) != "") ? strcat(" \"", argv(1), "\"") : ""), ". For a list of supported commands, try ", VoteCommand_getprefix(caller), " help.\n"));
		case VC_REQUEST_USAGE:
		{
			VoteCommand_macro_help(caller, argc);
			return;
		}
	}
}

// =======================
//  Game logic for voting
// =======================

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
	entity tmp_player;
	float t_ready, t_players;

	FOR_EACH_REALPLAYER(tmp_player)
	{
		++t_players;
		if(tmp_player.ready) { ++t_ready; }
	}

	readycount = t_ready;

	Nagger_ReadyCounted();

	// TODO: Add ability to 
	if(t_ready) // at least one is ready
	if(t_ready == t_players) // and, everyone is ready
		ReadyRestart();
}


// Restarts the map after the countdown is over (and cvar sv_ready_restart_after_countdown is set)
void restartTimer_Think() 
{
	restart_mapalreadyrestarted = 1;
	reset_map(TRUE);
	Score_ClearAll();
	remove(self);
	return;
}

void VoteHelp(entity e) {
	string vmasterdis;
	if(!autocvar_sv_vote_master) {
		vmasterdis = " ^1(disabled)";
	}

	string vlogindis;
	if("" == autocvar_sv_vote_master_password) {
		vlogindis = " ^1(disabled)";
	}

	string vcalldis;
	if(!autocvar_sv_vote_call) {
		vcalldis = " ^1(disabled)";
	}

	print_to(e, "^7You can use voting with \"^2cmd vote help^7\" \"^2cmd vote status^7\" \"^2cmd vote call ^3COMMAND ARGUMENTS^7\" \"^2cmd vote stop^7\" \"^2cmd vote master^7\" \"^2cmd vote login^7\" \"^2cmd vote do ^3COMMAND ARGUMENTS^7\" \"^2cmd vote yes^7\" \"^2cmd vote no^7\" \"^2cmd vote abstain^7\" \"^2cmd vote dontcare^7\".");
	print_to(e, "^7Or if your version is up to date you can use these aliases \"^2vhelp^7\" \"^2vstatus^7\" \"^2vcall ^3COMMAND ARGUMENTS^7\" \"^2vstop^7\" \"^2vmaster^7\" \"^2vlogin^7\" \"^2vdo ^3COMMAND ARGUMENTS^7\" \"^2vyes^7\" \"^2vno^7\" \"^2abstain^7\" \"^2vdontcare^7\".");
	print_to(e, "^7\"^2help^7\" shows this info.");
	print_to(e, "^7\"^2status^7\" shows if there is a vote called and who called it.");
	print_to(e, strcat("^7\"^2call^7\" is used to call a vote. See the list of allowed commands.", vcalldis, "^7"));
	print_to(e, "^7\"^2stop^7\" can be used by the vote caller or an admin to stop a vote and maybe correct it.");
	print_to(e, strcat("^7\"^2master^7\" call a vote to become master who can execute commands without a vote", vmasterdis, "^7"));
	print_to(e, strcat("^7\"^2login^7\" login to become master who can execute commands without a vote.", vlogindis, "^7"));
	print_to(e, "^7\"^2do^7\" executes a command if you are a master. See the list of allowed commands.");
	print_to(e, "^7\"^2yes^7\", \"^2no^7\", \"^2abstain^7\" and \"^2dontcare^7\" to make your vote.");
	print_to(e, "^7If enough of the players vote yes the vote is accepted.");
	print_to(e, "^7If enough of the players vote no the vote is rejected.");
	print_to(e, strcat("^7If neither the vote will timeout after ", ftos(autocvar_sv_vote_timeout), "^7 seconds."));
	print_to(e, "^7You can call a vote for or execute these commands:");
	print_to(e, strcat("^3", autocvar_sv_vote_commands, "^7 and maybe further ^3arguments^7"));
}

string ValidateMap(string m, entity e)
{
	m = MapInfo_FixName(m);
	if(!m)
	{
		print_to(e, "This map is not available on this server.");
		return string_null;
	}
	if(!autocvar_sv_vote_override_mostrecent)
		if(Map_IsRecent(m))
		{
			print_to(e, "This server does not allow for recent maps to be played again. Please be patient for some rounds.");
			return string_null;
		}
	if(!MapInfo_CheckMap(m))
	{
		print_to(e, strcat("^1Invalid mapname, \"^3", m, "^1\" does not support the current game mode."));
		return string_null;
	}

	return m;
}


void VoteThink() {
	if(votefinished > 0) // a vote was called
	if(time > votefinished) // time is up
	{
		VoteCount();
	}
}

float VoteCommandInList(string votecommand, string list)
{
	string l;
	l = strcat(" ", list, " ");
	
	if(strstrofs(l, strcat(" ", votecommand, " "), 0) >= 0)
		return TRUE;
	
	// if gotomap is allowed, chmap is too, and vice versa
	if(votecommand == "gotomap")
		if(strstrofs(l, " chmap ", 0) >= 0)
			return TRUE;
	if(votecommand == "chmap")
		if(strstrofs(l, " gotomap ", 0) >= 0)
			return TRUE;
	
	return FALSE;
}

float VoteAllowed(string votecommand, string cmd) {
	if(VoteCommandInList(votecommand, autocvar_sv_vote_commands))
		return TRUE;

	if(cmd == "vdo")
	{
		if(VoteCommandInList(votecommand, autocvar_sv_vote_master_commands))
			return TRUE;
	}
	else
	{
		if(VoteCommandInList(votecommand, autocvar_sv_vote_only_commands))
			return TRUE;
	}

	return FALSE;
}

void VoteReset() {
	entity player;

	FOR_EACH_CLIENT(player)
	{
		player.vote_selection = 0;
	}

	if(votecalled)
	{
		strunzone(votecalledvote);
		strunzone(votecalledvote_display);
	}

	votecalled = FALSE;
	votecalledmaster = FALSE;
	votefinished = 0;
	votecalledvote = string_null;
	votecalledvote_display = string_null;

	Nagger_VoteChanged();
}

void VoteAccept() {
	bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2's vote for ^1", votecalledvote_display, "^2 was accepted\n");
	if(votecalledmaster)
	{
		if(votecaller) {
			votecaller.vote_master = 1;
		}
	} else {
		localcmd(strcat(votecalledvote, "\n"));
	}
	if(votecaller) {
		votecaller.vote_next = 0; // people like your votes,
					  // no wait for next vote
	}
	VoteReset();
	Announce("voteaccept");
}

void VoteReject() {
	bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2's vote for ", votecalledvote_display, "^2 was rejected\n");
	VoteReset();
	Announce("votefail");
}

void VoteTimeout() {
	bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2's vote for ", votecalledvote_display, "^2 timed out\n");
	VoteReset();
	Announce("votefail");
}

void VoteSpam(float notvoters, float mincount, string result)
{
	string s;
	if(mincount >= 0)
	{
		s = strcat("\{1}^2* vote results: ^1", ftos(vote_yescount), "^2:^1");
		s = strcat(s, ftos(vote_nocount), "^2 (^1");
		s = strcat(s, ftos(mincount), "^2 needed), ^1");
		s = strcat(s, ftos(vote_abstaincount), "^2 didn't care, ^1");
		s = strcat(s, ftos(notvoters), "^2 didn't vote\n");
	}
	else
	{
		s = strcat("\{1}^2* vote results: ^1", ftos(vote_yescount), "^2:^1");
		s = strcat(s, ftos(vote_nocount), "^2, ^1");
		s = strcat(s, ftos(vote_abstaincount), "^2 didn't care, ^1");
		s = strcat(s, ftos(notvoters), "^2 didn't have to vote\n");
	}
	bprint(s);
	if(autocvar_sv_eventlog)
	{
		s = strcat(":vote:v", result, ":", ftos(vote_yescount));
		s = strcat(s, ":", ftos(vote_nocount));
		s = strcat(s, ":", ftos(vote_abstaincount));
		s = strcat(s, ":", ftos(notvoters));
		s = strcat(s, ":", ftos(mincount));
		GameLogEcho(s);
	}
}

void VoteCount() {
	float playercount;
	playercount = 0;
	vote_yescount = 0;
	vote_nocount = 0;
	vote_abstaincount = 0;
	entity player;
	//same for real players
	float realplayercount;
	float realplayeryescount;
	float realplayernocount;
	float realplayerabstaincount;
	realplayercount = realplayernocount = realplayerabstaincount = realplayeryescount = 0;

	Nagger_VoteCountChanged();

	FOR_EACH_REALCLIENT(player)
	{
		if(player.vote_selection == -1) {
			++vote_nocount;
		} else if(player.vote_selection == 1) {
			++vote_yescount;
		} else if(player.vote_selection == -2) {
			++vote_abstaincount;
		}
		++playercount;
		//do the same for real players
		if(player.classname == "player") {
			if(player.vote_selection == -1) {
				++realplayernocount;
			} else if(player.vote_selection == 1) {
				++realplayeryescount;
			} else if(player.vote_selection == -2) {
				++realplayerabstaincount;
			}
			++realplayercount;
		}
	}

	//in tournament mode, if we have at least one player then don't make the vote dependent on spectators (so specs don't have to press F1)
	if(autocvar_sv_vote_nospectators)
	if(realplayercount > 0) {
		vote_yescount = realplayeryescount;
		vote_nocount = realplayernocount;
		vote_abstaincount = realplayerabstaincount;
		playercount = realplayercount;
	}

	float votefactor, simplevotefactor;
	votefactor = bound(0.5, autocvar_sv_vote_majority_factor, 0.999);
	simplevotefactor = autocvar_sv_vote_simple_majority_factor;

	// FIXME this number is a guess
	vote_needed_absolute = floor((playercount - vote_abstaincount) * votefactor) + 1;
	if(simplevotefactor)
	{
		simplevotefactor = bound(votefactor, simplevotefactor, 0.999);
		vote_needed_simple = floor((vote_yescount + vote_nocount) * simplevotefactor) + 1;
	}
	else
		vote_needed_simple = 0;

	if(votecalledmaster
	   && playercount == 1) {
		// if only one player is on the server becoming vote
		// master is not allowed.  This could be used for
		// trolling or worse. 'self' is the user who has
		// called the vote because this function is called
		// by SV_ParseClientCommand. Maybe all voting should
		// be disabled for a single player?
		print_to(votecaller, "^1You are the only player on this server so you can not become vote master.");
		if(votecaller) {
			votecaller.vote_next = 0;
		}
		VoteReset();
	} else {
		if(vote_yescount >= vote_needed_absolute)
		{
			VoteSpam(playercount - vote_yescount - vote_nocount - vote_abstaincount, -1, "yes");
			VoteAccept();
		}
		else if(vote_nocount > playercount - vote_abstaincount - vote_needed_absolute) // that means, vote_yescount cannot reach vote_needed_absolute any more
		{
			VoteSpam(playercount - vote_yescount - vote_nocount - vote_abstaincount, -1, "no");
			VoteReject();
		}
		else if(time > votefinished)
		{
			if(simplevotefactor)
			{
				string result;
				if(vote_yescount >= vote_needed_simple)
					result = "yes";
				else if(vote_yescount + vote_nocount > 0)
					result = "no";
				else
					result = "timeout";
				VoteSpam(playercount - vote_yescount - vote_nocount - vote_abstaincount, min(vote_needed_absolute, vote_needed_simple), result);
				if(result == "yes")
					VoteAccept();
				else if(result == "no")
					VoteReject();
				else
					VoteTimeout();
			}
			else
			{
				VoteSpam(playercount - vote_yescount - vote_nocount - vote_abstaincount, vote_needed_absolute, "timeout");
				VoteTimeout();
			}
		}
	}
}
