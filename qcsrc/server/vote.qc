// =============================================
//  Server side voting code, reworked by Samual
//  Last updated: December 6th, 2011
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

string vote_parsed_command;
string vote_parsed_display;


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

void VoteReset() 
{
	entity tmp_player;

	FOR_EACH_CLIENT(tmp_player) { tmp_player.vote_selection = 0; }

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
	
	vote_parsed_command = string_null;
	vote_parsed_display = string_null;

	Nagger_VoteChanged();
}

void VoteStop(entity stopper) 
{
	bprint("\{1}^2* ^3", VoteCommand_getname(stopper), "^2 stopped ^3", VoteCommand_getname(votecaller), "^2's vote\n");
	if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vstop:", ftos(stopper.playerid))); }
	
	// Don't force them to wait for next vote, this way they can e.g. correct their vote.
	if((votecaller) && (stopper == votecaller)) { votecaller.vote_next = time + autocvar_sv_vote_stop; }

	VoteReset();
}

void VoteThink() 
{
	if(votefinished > 0) // a vote was called
	if(time > votefinished) // time is up
	{
		VoteCount();
	}
	
	return;
}

void VoteAccept() 
{
	bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2's vote for ^1", votecalledvote_display, "^2 was accepted\n");
	
	if(votecalledmaster && votecaller)
		votecaller.vote_master = 1;
	else
		localcmd(strcat(votecalledvote, "\n"));
	
	if(votecaller) { votecaller.vote_next = 0; } // people like your votes, you don't need to wait to vote again // todo separate anti-spam even for succeeded votes

	VoteReset();
	Announce("voteaccept");
}

void VoteReject() 
{
	bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2's vote for ", votecalledvote_display, "^2 was rejected\n");
	VoteReset();
	Announce("votefail");
}

void VoteTimeout() 
{
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

void VoteCount() 
{
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


// =======================
//  Game logic for warmup
// =======================

// Restarts the map after the countdown is over (and cvar sv_ready_restart_after_countdown is set)
void ReadyRestart_think() 
{
	restart_mapalreadyrestarted = 1;
	reset_map(TRUE);
	Score_ClearAll();
	remove(self);
	
	return;
}

// Forces a restart of the game without actually reloading the map // this is a mess...
void ReadyRestart_force()
{
	entity tmp_player, restart_timer;

	bprint("^1Server is restarting...\n");

	VoteReset();

	// clear overtime, we have to decrease timelimit to its original value again.
	if (checkrules_overtimesadded > 0 && g_race_qualifying != 2) { cvar_set("timelimit", ftos(autocvar_timelimit - (checkrules_overtimesadded * autocvar_timelimit_overtime))); }

	checkrules_suddendeathend = checkrules_overtimesadded = checkrules_suddendeathwarning = 0;

	readyrestart_happened = 1;
	game_starttime = time;
	if(!g_ca && !g_arena) { game_starttime += RESTART_COUNTDOWN; }
		
	restart_mapalreadyrestarted = 0; // reset this var, needed when cvar sv_ready_restart_repeatable is in use

	// disable the warmup global for the server
	inWarmupStage = 0; // once the game is restarted the game is in match stage

	// reset the .ready status of all players (also spectators)
	FOR_EACH_CLIENTSLOT(tmp_player) { tmp_player.ready = 0; }
	readycount = 0;
	Nagger_ReadyCounted(); // NOTE: this causes a resend of that entity, and will also turn off warmup state on the client

	// lock teams with lockonrestart
	if(autocvar_teamplay_lockonrestart && teamplay) 
	{
		lockteams = 1;
		bprint("^1The teams are now locked.\n");
	}

	//initiate the restart-countdown-announcer entity
	if(autocvar_sv_ready_restart_after_countdown && !g_ca && !g_arena)
	{
		restart_timer = spawn();
		restart_timer.think = ReadyRestart_think;
		restart_timer.nextthink = game_starttime;
	}

	// after a restart every players number of allowed timeouts gets reset, too
	if(autocvar_sv_timeout) { FOR_EACH_REALPLAYER(tmp_player) { tmp_player.allowedTimeouts = autocvar_sv_timeout_number; } }

	//reset map immediately if this cvar is not set
	if not(autocvar_sv_ready_restart_after_countdown) { reset_map(TRUE); }

	if(autocvar_sv_eventlog) { GameLogEcho(":restart"); }
}

void ReadyRestart()
{
	// no arena, assault support yet...
	if(g_arena | g_assault | gameover | intermission_running | race_completing)
		localcmd("restart\n");
	else
		localcmd("\nsv_hook_gamerestart\n");

	// Reset ALL scores, but only do that at the beginning of the countdown if sv_ready_restart_after_countdown is off!
	// Otherwise scores could be manipulated during the countdown.
	if not(autocvar_sv_ready_restart_after_countdown) { Score_ClearAll(); }

	ReadyRestart_force();
	
	return;
}

// Count the players who are ready and determine whether or not to restart the match
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

	// TODO: check percentage of ready players
	if(t_ready) // at least one is ready
	if(t_ready == t_players) // and, everyone is ready
		ReadyRestart();
		
	return;
}


// ======================================
//  Supporting functions for VoteCommand
// ======================================

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

float VoteCommand_checkinlist(string vote_command, string list)
{
	string l = strcat(" ", list, " ");
	
	if(strstrofs(l, strcat(" ", vote_command, " "), 0) >= 0)
		return TRUE;
	
	// if gotomap is allowed, chmap is too, and vice versa
	if(vote_command == "gotomap")
		if(strstrofs(l, " chmap ", 0) >= 0)
			return TRUE;
			
	if(vote_command == "chmap")
		if(strstrofs(l, " gotomap ", 0) >= 0)
			return TRUE;
	
	return FALSE;
}

string ValidateMap(string validated_map, entity caller)
{
	validated_map = MapInfo_FixName(validated_map);
	
	if(!validated_map)
	{
		print_to(caller, "This map is not available on this server.");
		return string_null;
	}
	
	if(!autocvar_sv_vote_override_mostrecent && caller)
	{
		if(Map_IsRecent(validated_map))
		{
			print_to(caller, "This server does not allow for recent maps to be played again. Please be patient for some rounds.");
			return string_null;
		}
	}
	
	if(!MapInfo_CheckMap(validated_map))
	{
		print_to(caller, strcat("^1Invalid mapname, \"^3", validated_map, "^1\" does not support the current game mode."));
		return string_null;
	}

	return validated_map;
}

float VoteCommand_parse(entity caller, string vote_command, string vote_list, float startpos, float argc)
{
	string first_command;
	entity victim;
	
	first_command = argv(startpos);

	if not(VoteCommand_checkinlist(vote_command, vote_list))
		return FALSE;

	if((argc - 1) < startpos) // These commands won't work without arguments
	{
		switch(first_command)
		{
			case "map":
			case "chmap":
			case "gotomap":
			case "kick":
			case "kickban":
				return FALSE;
				
			default: { break; }
		}
	}
	
	switch(first_command) // now go through and parse the proper commands to adjust as needed.
	{
		case "kick":
		case "kickban": // catch all kick/kickban commands
		{
			victim = edict_num(GetFilteredNumber(substring(vote_command, argv_start_index(startpos + 1), argv_end_index(-1) - argv_start_index(startpos + 1))));
			if not(victim) { return FALSE; }
			// TODO: figure out how kick/kickban/ban commands work and re-write this to fit around them
			vote_parsed_command = vote_command;
			vote_parsed_display = strcat("^1", vote_command, " (^7", victim.netname, "^1): ", "todo");
			
			break;
		}
		
		case "map":
		case "chmap":
		case "gotomap": // re-direct all map selection commands to gotomap
		{
			vote_command = ValidateMap(substring(vote_command, argv_start_index(startpos + 1), argv_end_index(-1) - argv_start_index(startpos + 1)), caller);
			if not(vote_command) { return FALSE; }
			vote_parsed_command = strcat("gotomap ", vote_command);
			vote_parsed_display = strzone(strcat("^1", vote_parsed_command));
			
			break;
		}
		
		default: 
		{ 
			vote_parsed_command = vote_command;
			vote_parsed_display = strzone(strcat("^1", vote_command));
			
			break; 
		}
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
			float spectators_allowed = ((autocvar_sv_vote_nospectators != 2) || ((autocvar_sv_vote_nospectators == 1) && inWarmupStage));
			float tmp_playercount;
			entity tmp_player;
			
			vote_command = VoteCommand_extractcommand(vote_command, 2, argc);
			
			if not(autocvar_sv_vote_call || !caller) { print_to(caller, "^1Vote calling is not allowed."); }
			else if(votecalled) { print_to(caller, "^1There is already a vote called."); }
			else if(spectators_allowed && (caller && (caller.classname != "player"))) { print_to(caller, "^1Only players can call a vote."); }
			else if(timeoutStatus) { print_to(caller, "^1You can not call a vote while a timeout is active."); }
			else if(caller && (time < caller.vote_next)) { print_to(caller, strcat("^1You have to wait ^2", ftos(ceil(caller.vote_next - time)), "^1 seconds before you can again call a vote.")); }
			else if not(VoteCommand_checknasty(vote_command)) { print_to(caller, "^1Syntax error in command, see 'vhelp' for more info."); }
			else if not(VoteCommand_parse(caller, vote_command, autocvar_sv_vote_commands, 2, argc)) { print_to(caller, "^1This command is not acceptable, see 'vhelp' for more info."); }

			else // everything went okay, continue with calling the vote // TODO: fixes to make this more compatible with sv_cmd
			{
				votecalled = TRUE;
				votecalledmaster = FALSE;
				votecalledvote = strzone(vote_parsed_command);
				votecalledvote_display = strzone(vote_parsed_display);
				votefinished = time + autocvar_sv_vote_timeout;
				votecaller = caller; // remember who called the vote
				
				if(caller)
				{
					caller.vote_selection = VOTE_SELECT_ACCEPT;
					caller.vote_next = time + autocvar_sv_vote_wait;
					msg_entity = caller; // todo: what is this for?
				}
				
				FOR_EACH_REALCLIENT(tmp_player) { ++tmp_playercount; }
				if(tmp_playercount > 1) { Announce("votecall"); } // don't announce a "vote now" sound if player is alone
				
				bprint("\{1}^2* ^3", VoteCommand_getname(votecaller), "^2 calls a vote for ", votecalledvote_display, "\n");
				if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vcall:", ftos(votecaller.playerid), ":", votecalledvote_display)); }
				Nagger_VoteChanged();
				VoteCount(); // needed if you are the only one
			}
			
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
						else if not(VoteCommand_parse(caller, vote_command, autocvar_sv_vote_master_commands, 3, argc)) { print_to(caller, "^1This command is not acceptable, see 'vhelp' for more info."); }
						
						else // everything went okay, proceed with command
						{
							localcmd(strcat(vote_parsed_command, "\n"));
							print_to(caller, strcat("Executing command '", vote_parsed_display, "' on server."));
							bprint("\{1}^2* ^3", VoteCommand_getname(caller), "^2 used their ^3master^2 status to do \"^2", vote_parsed_display, "^2\".\n");
							if(autocvar_sv_eventlog) { GameLogEcho(strcat(":vote:vdo:", ftos(caller.playerid), ":", vote_parsed_display)); }
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
			if(votecalled)
				print_to(caller, strcat("^7Vote for ", votecalledvote_display, "^7 called by ^7", VoteCommand_getname(votecaller), "^7."));
			else
				print_to(caller, "^1No vote called.");
				
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
			else { print_to(caller, "^1You are not allowed to stop that vote."); }
			
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