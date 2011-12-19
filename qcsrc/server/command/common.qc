// ====================================================
//  Shared code for server commands, written by Samual
//  Last updated: December 19th, 2011
// ====================================================

// select the proper prefix for usage and other messages
string GetCommandPrefix(entity caller)
{
	if(caller)
		return "cmd";
	else
		return "sv_cmd";
}

// if client return player nickname, or if server return admin nickname
string GetCallerName(entity caller)
{
	if(caller)
		return caller.netname;
	else
		return admin_name(); //((autocvar_sv_adminnick != "") ? autocvar_sv_adminnick : autocvar_hostname);
}

// verify that the client provided is acceptable for use
float VerifyClientEntity(entity client, float must_be_real, float must_be_bots)
{
	if not(client.flags & FL_CLIENT)
		return CLIENT_DOESNT_EXIST;
	else if(must_be_real && (clienttype(client) != CLIENTTYPE_REAL))
		return CLIENT_NOT_REAL;
	else if(must_be_bots && (clienttype(client) != CLIENTTYPE_BOT))
		return CLIENT_NOT_BOT;
		
	return CLIENT_ACCEPTABLE;
}

// if the client is not acceptable, return a string to be used for error messages
string GetClientErrorString(float clienterror, string original_input)
{
	switch(clienterror)
	{
		case CLIENT_DOESNT_EXIST: { return strcat("Client '", original_input, "' doesn't exist"); }
		case CLIENT_NOT_REAL: { return strcat("Client '", original_input, "' is not real"); }
		case CLIENT_NOT_BOT: { return strcat("Client '", original_input, "' is not a bot"); }
		default: { return "Incorrect usage of GetClientErrorString"; }
	}
}

// is this entity number even in the possible range of entities?
float VerifyClientNumber(float tmp_number)
{
	if((tmp_number < 1) || (tmp_number > maxclients))
		return FALSE;
	else
		return TRUE;
}

// find a player which matches the input string, and return their entity
entity GetFilteredEntity(string input)
{
	entity tmp_player, selection;
	float tmp_number;
	
	if(substring(input, 0, 1) == "#")
		tmp_number = stof(substring(input, 1, -1));
	else
		tmp_number = stof(input);
	
	if(VerifyClientNumber(tmp_number))
	{
		selection = edict_num(tmp_number);
	}
	else
	{
		FOR_EACH_CLIENT(tmp_player)
			if (strdecolorize(tmp_player.netname) == strdecolorize(input))
				selection = tmp_player;
	}
	
	return selection;
}

// same thing, but instead return their edict number
float GetFilteredNumber(string input)
{
	entity selection = GetFilteredEntity(input);
	float output;
	
	if(selection) { output = num_for_edict(selection); }

	print(strcat("input: ", input, ", output: ", ftos(output), ",\n")); // todo remove after done debugging
	return output;
}

// switch between sprint and print depending on whether the reciever is the server or a player
void print_to(entity to, string input)
{
    if(to)
        sprint(to, strcat(input, "\n"));
    else
        print(input, "\n");
}


// ===================================================
//  Common commands used in both sv_cmd.qc and cmd.qc
// ===================================================

void CommonCommand_cvar_changes(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, cvar_changes);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " cvar_changes"));
			print_to(caller, "  No arguments required.");
			print_to(caller, "See also: ^2cvar_purechanges^7");
			return;
		}
	}
}

void CommonCommand_cvar_purechanges(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, cvar_purechanges);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " cvar_purechanges"));
			print_to(caller, "  No arguments required.");
			print_to(caller, "See also: ^2cvar_changes^7");
			return;
		}
	}
}

void CommonCommand_info(float request, entity caller, float argc) // todo: figure out how this works?
{	
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string command;
			
			command = builtin_cvar_string(strcat("sv_info_", argv(1))); 
			if(command)
				wordwrap_sprint(command, 1111); // why 1111?
			else
				print_to(caller, "ERROR: unsupported info command");
				
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " info request"));
			print_to(caller, "  Where 'request' is the suffixed string appended onto the request for cvar.");
			return;
		}
	}
}

void CommonCommand_ladder(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, ladder_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " ladder"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_lsmaps(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, lsmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " lsmaps"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_lsnewmaps(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, lsnewmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " lsnewmaps"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_maplist(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, maplist_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " maplist"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void GameCommand_rankings(float request) // this is OLD.... jeez.
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			strunzone(rankings_reply);
			rankings_reply = strzone(getrankings());
			print(rankings_reply);
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd rankings");
			print("  No arguments required.");
			return;
		}
	}
}

void CommonCommand_rankings(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, rankings_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " rankings"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_records(float request, entity caller) // TODO: Isn't this flooding with the sprint messages? Old code, but perhaps bad?
{	
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i;
			
			for(i = 0; i < 10; ++i)
				print_to(caller, records_reply[i]);
				
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " records"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_teamstatus(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			Score_NicePrint(caller);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " teamstatus"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_time(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, strcat("time = ", ftos(time), "\n"));
			print_to(caller, strcat("frame start = ", ftos(gettime(GETTIME_FRAMESTART)), "\n"));
			print_to(caller, strcat("realtime = ", ftos(gettime(GETTIME_REALTIME)), "\n"));
			print_to(caller, strcat("hires = ", ftos(gettime(GETTIME_HIRES)), "\n"));
			print_to(caller, strcat("uptime = ", ftos(gettime(GETTIME_UPTIME)), "\n"));
			print_to(caller, strcat("localtime = ", strftime(TRUE, "%a %b %e %H:%M:%S %Z %Y"), "\n")); // todo: Why is strftime broken? is engine problem, I think.
			print_to(caller, strcat("gmtime = ", strftime(FALSE, "%a %b %e %H:%M:%S %Z %Y"), "\n"));
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " time"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_timein(float request, entity caller) // todo entirely re-write this
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(caller.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout)
				{
					if (!timeoutStatus)
						return print_to(caller, "^7Error: There is no active timeout which could be aborted!");
					if (caller != timeoutInitiator)
						return print_to(caller, "^7Error: You may not abort the active timeout. Only the player who called it can do that!");
						
					if (timeoutStatus == 1) 
					{
						remainingTimeoutTime = timeoutStatus = 0;
						timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
						bprint(strcat("^7The timeout was aborted by ", caller.netname, " !\n"));
					}
					else if (timeoutStatus == 2) 
					{
						//only shorten the remainingTimeoutTime if it makes sense
						if( remainingTimeoutTime > (autocvar_sv_timeout_resumetime + 1) ) 
						{
							bprint(strcat("^1Attention: ^7", caller.netname, " resumed the game! Prepare for battle!\n"));
							remainingTimeoutTime = autocvar_sv_timeout_resumetime;
							timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
						}
						else
							print_to(caller, "^7Error: Your resumegame call was discarded!");
					}
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " timein"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_timeout(float request, entity caller) // DEAR GOD THIS COMMAND IS TERRIBLE.
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(caller.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout) 
				{
					if(caller.classname == "player") 
					{
						if(vote_called)
							print_to(caller, "^7Error: you can not call a timeout while a vote is active!");
						else
						{
							if (inWarmupStage && !g_warmup_allow_timeout)
								return print_to(caller, "^7Error: You can not call a timeout in warmup-stage!");
							if (time < game_starttime )
								return print_to(caller, "^7Error: You can not call a timeout while the map is being restarted!");
								
							if (timeoutStatus != 2) {
								//if the map uses a timelimit make sure that timeout cannot be called right before the map ends
								if (autocvar_timelimit) {
									//a timelimit was used
									float myTl;
									myTl = autocvar_timelimit;

									float lastPossibleTimeout;
									lastPossibleTimeout = (myTl*60) - autocvar_sv_timeout_leadtime - 1;

									if (lastPossibleTimeout < time - game_starttime)
										return print_to(caller, "^7Error: It is too late to call a timeout now!");
								}
							}
							
							//player may not call a timeout if he has no calls left
							if (caller.allowedTimeouts < 1)
								return print_to(caller, "^7Error: You already used all your timeout calls for this map!");
								
								
							//now all required checks are passed
							caller.allowedTimeouts -= 1;
							bprint(caller.netname, " ^7called a timeout (", ftos(caller.allowedTimeouts), " timeouts left)!\n"); //write a bprint who started the timeout (and how many he has left)
							remainingTimeoutTime = autocvar_sv_timeout_length;
							remainingLeadTime = autocvar_sv_timeout_leadtime;
							timeoutInitiator = caller;
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
					}
					else
						print_to(caller, "^7Error: only players can call a timeout!");
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " timeout"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_who(float request, entity caller, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float total_listed_players, tmp_hours, tmp_minutes, tmp_seconds, is_bot;
			entity tmp_player;			
			
			string separator = strcat((argv(1) ? argv(1) : " "), "^7");
			float privacy = (caller && autocvar_sv_status_privacy);
			
			print_to(caller, strcat("List of client information", (privacy ? " (some data is hidden for privacy)" : string_null), ":"));
			print_to(caller, sprintf(strreplace(" ", separator, " %-4s %-20s %-5s %-3s %-9s %-16s %s "), 
				"ent", "nickname", "ping", "pl", "time", "ip", "crypto_id"));
			
			FOR_EACH_CLIENT(tmp_player)
			{
				is_bot = (clienttype(tmp_player) == CLIENTTYPE_BOT);
				
				tmp_hours = tmp_minutes = tmp_seconds = 0;
				
				tmp_seconds = floor(time - tmp_player.jointime);
				tmp_minutes = floor(tmp_seconds / 60);
				tmp_hours = floor(tmp_minutes / 60);

				if(tmp_minutes) { tmp_seconds -= (tmp_minutes * 60); }				
				if(tmp_hours) { tmp_minutes -= (tmp_hours * 60); }

				print_to(caller, sprintf(strreplace(" ", separator, " %-4s %-20.20s %-5d %-3d %-9s %-16s %s "), 
					strcat("#", ftos(num_for_edict(tmp_player))), 
					tmp_player.netname,
					tmp_player.ping, 
					tmp_player.ping_packetloss, 
					sprintf("%02d:%02d:%02d", tmp_hours, tmp_minutes, tmp_seconds),
					(is_bot ? "null/botclient" : (privacy ? "hidden" : tmp_player.netaddress)),
					(is_bot ? "null/botclient" : (privacy ? "hidden" : tmp_player.crypto_idfp))));
					
				++total_listed_players;
			}
			
			print_to(caller, strcat("Finished listing ", ftos(total_listed_players), " client(s) out of ", ftos(maxclients), " slots."));
			
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " who [separator]"));
			print_to(caller, "  Where 'separator' is the optional string to separate the values with, default is a space.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void CommonCommand_(float request, entity caller)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " "));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}
*/