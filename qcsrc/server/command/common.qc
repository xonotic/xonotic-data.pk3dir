// ====================================================
//  Shared code for server commands, written by Samual
//  Last updated: December 13th, 2011
// ====================================================

string GetCommandPrefix(entity caller)
{
	if(caller)
		return "cmd";
	else
		return "sv_cmd";
}

string GetCallerName(entity caller)
{
	if(caller)
		return caller.netname;
	else
		return ((autocvar_sv_adminnick != "") ? autocvar_sv_adminnick : autocvar_hostname);
}

// find a player which matches the input string, and return their entity number
float GetFilteredNumber(string input)
{
	entity tmp_player, selection;
	float output, matches;
	
	// check and see if we can get a number from input like "#3" or "3" 
	if(substring(input, 0, 1) == "#")
		output = stof(substring(input, 1, -1));
	else
		output = stof(input);
		
	// if we can't, check and see if we can match the input to the netname of any player in the game
	if not(output) 
	{
		FOR_EACH_CLIENT(tmp_player)
			if (strdecolorize(tmp_player.netname) == strdecolorize(input))
				selection = tmp_player;

		if (selection) { output = num_for_edict(selection); }
	}
		
	print(strcat("input: ", input, ", output: ", ftos(output), ",\n"));
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

void CommonCommand_cvar_changes(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, cvar_changes);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 sv_cmd cvar_changes");
			print_to(self, "  No arguments required.");
			//print_to(self, "See also: ^2cvar_purechanges^7");
			return;
		}
	}
}

void CommonCommand_cvar_purechanges(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, cvar_purechanges);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 sv_cmd cvar_purechanges");
			print_to(self, "  No arguments required.");
			//print_to(self, "See also: ^2cvar_changes^7");
			return;
		}
	}
}

void CommonCommand_info(float request, float argc)
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
				print_to(self, "ERROR: unsupported info command");
				
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd info request");
			print_to(self, "  Where 'request' is the suffixed string appended onto the request for cvar.");
			return;
		}
	}
}

void CommonCommand_ladder(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, ladder_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd ladder");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_lsmaps(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, lsmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd lsmaps");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_lsnewmaps(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, lsnewmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd lsnewmaps");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_maplist(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, maplist_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd maplist");
			print_to(self, "  No arguments required.");
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

void CommonCommand_rankings(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(self, rankings_reply);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd rankings");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_records(float request) // TODO: Isn't this flooding with the sprint messages? Old code, but perhaps bad?
{	
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i;
			
			for(i = 0; i < 10; ++i)
				print_to(self, records_reply[i]);
				
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd records");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_teamstatus(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			Score_NicePrint(self);
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd teamstatus");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}


void CommonCommand_timein(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(self.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout)
				{
					if (!timeoutStatus)
						return print_to(self, "^7Error: There is no active timeout which could be aborted!");
					if (self != timeoutInitiator)
						return print_to(self, "^7Error: You may not abort the active timeout. Only the player who called it can do that!");
						
					if (timeoutStatus == 1) 
					{
						remainingTimeoutTime = timeoutStatus = 0;
						timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
						bprint(strcat("^7The timeout was aborted by ", self.netname, " !\n"));
					}
					else if (timeoutStatus == 2) 
					{
						//only shorten the remainingTimeoutTime if it makes sense
						if( remainingTimeoutTime > (autocvar_sv_timeout_resumetime + 1) ) 
						{
							bprint(strcat("^1Attention: ^7", self.netname, " resumed the game! Prepare for battle!\n"));
							remainingTimeoutTime = autocvar_sv_timeout_resumetime;
							timeoutHandler.nextthink = time; //timeoutHandler has to take care of it immediately
						}
						else
							print_to(self, "^7Error: Your resumegame call was discarded!");
					}
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd timein");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_timeout(float request) // DEAR GOD THIS COMMAND IS TERRIBLE.
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(self.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout) 
				{
					if(self.classname == "player") 
					{
						if(vote_called)
							print_to(self, "^7Error: you can not call a timeout while a vote is active!");
						else
						{
							if (inWarmupStage && !g_warmup_allow_timeout)
								return print_to(self, "^7Error: You can not call a timeout in warmup-stage!");
							if (time < game_starttime )
								return print_to(self, "^7Error: You can not call a timeout while the map is being restarted!");
								
							if (timeoutStatus != 2) {
								//if the map uses a timelimit make sure that timeout cannot be called right before the map ends
								if (autocvar_timelimit) {
									//a timelimit was used
									float myTl;
									myTl = autocvar_timelimit;

									float lastPossibleTimeout;
									lastPossibleTimeout = (myTl*60) - autocvar_sv_timeout_leadtime - 1;

									if (lastPossibleTimeout < time - game_starttime)
										return print_to(self, "^7Error: It is too late to call a timeout now!");
								}
							}
							
							//player may not call a timeout if he has no calls left
							if (self.allowedTimeouts < 1)
								return print_to(self, "^7Error: You already used all your timeout calls for this map!");
								
								
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
					}
					else
						print_to(self, "^7Error: only players can call a timeout!");
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd timeout");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_who(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float total_listed_players, tmp_hours, tmp_minutes, tmp_seconds;
			entity tmp_player;
			//string tmp_player_name;
			
			print_to(self, strcat("List of client information", (autocvar_sv_status_privacy ? " (some data is hidden for privacy)" : string_null), ":\n"));
			print_to(self, sprintf(" %-4s %-20s %-5s %-3s %-9s %-16s %s\n", "ent", "nickname", "ping", "pl", "time", "ip", "crypto_id"));
			
			FOR_EACH_CLIENT(tmp_player)
			{
				//tmp_player_name = strlimitedlen(tmp_player.netname, "...", TRUE, 20);
				
				tmp_hours = tmp_minutes = tmp_seconds = 0;
				
				tmp_seconds = (time - tmp_player.jointime);
				tmp_minutes = (tmp_seconds / 60);
				
				if(tmp_minutes)
				{
					tmp_seconds -= (tmp_minutes * 60);
					tmp_hours = (tmp_minutes / 60);
					
					if(tmp_hours) { tmp_minutes -= (tmp_hours * 60); }
				}
				
				print_to(self, sprintf(" %-4s %-20s %-5d %-3d %-9s %-16s %s\n", 
					strcat("#", ftos(num_for_edict(tmp_player))), 
					tmp_player.netname, //strcat(tmp_player_name, sprintf("%*s", (20 - strlen(strdecolorize(tmp_player_name))), "")),
					tmp_player.ping, tmp_player.ping_packetloss, 
					sprintf("%02d:%02d:%02d", tmp_hours, tmp_minutes, tmp_seconds),
					(autocvar_sv_status_privacy ? "hidden" : tmp_player.netaddress),
					(autocvar_sv_status_privacy ? "hidden" : tmp_player.crypto_idfp)));
					
				++total_listed_players;
			}
			
			print_to(self, strcat("Finished listing ", ftos(total_listed_players), " client(s). \n"));
			
			return; // never fall through to usage
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(self, "\nUsage:^3 cmd who");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void CommonCommand_(float request)
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
			print_to(self, "\nUsage:^3 cmd ");
			print_to(self, "  No arguments required.");
			return;
		}
	}
}
*/