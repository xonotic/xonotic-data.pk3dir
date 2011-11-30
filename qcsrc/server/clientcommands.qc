// =========================================================
//  Server side networked commands code, reworked by Samual
//  Last updated: November 30th, 2011
// =========================================================

#define CC_REQUEST_COMMAND 1
#define CC_REQUEST_USAGE 2

.float cmd_floodtime;
.float cmd_floodcount;
.float checkfail;
.float lms_spectate_warning;

string MapVote_Suggest(string m);
//void MapVote_SendPicture(float id)


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


// =======================
//  Command Sub-Functions
// =======================

void ClientCommand_autoswitch(float request, float argc)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			self.autoswitch = ("0" != argv(1));
			sprint(self, strcat("^1autoswitch is currently turned ", (self.autoswitch ? "on" : "off"), ".\n"));
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd autoswitch selection\n");
			sprint(self, "  Where 'selection' is 1 or 0 for on or off.\n"); 
			return;
		}
	}
}

void ClientCommand_checkfail(float request, string command) // used only by client side code
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			print(sprintf("CHECKFAIL: %s (%s) epically failed check %s\n", self.netname, self.netaddress, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1))));
			self.checkfail = 1;
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd checkfail message\n");
			sprint(self, "  Where 'message' is the message reported by client about the fail.\n");
			return;
		}
	}
}

void ClientCommand_clientversion(float request, float argc) // used only by client side code
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
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
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd clientversion version\n");
			sprint(self, "  Where 'version' is the game version reported by self.\n");
			return;
		}
	}
}

void ClientCommand_cvar_changes(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, cvar_changes);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 sv_cmd cvar_changes\n");
			sprint(self, "  No arguments required.\n");
			//sprint(self, "See also: ^2cvar_purechanges^7\n");
			return;
		}
	}
}

void ClientCommand_cvar_purechanges(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, cvar_purechanges);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 sv_cmd cvar_purechanges\n");
			sprint(self, "  No arguments required.\n");
			//sprint(self, "See also: ^2cvar_changes^7\n");
			return;
		}
	}
}

void ClientCommand_getmapvotepic(float request, float argc)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(intermission_running)				
				MapVote_SendPicture(stof(argv(1)));

			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd getmapvotepic mapid\n");
			sprint(self, "  Where 'mapid' is the id number of the map to request an image of on the map vote selection menu.\n");
			return;
		}
	}
}

void ClientCommand_info(float request, float argc)
{	
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			string command;
			
			command = builtin_cvar_string(strcat("sv_info_", argv(1))); 
			if(command)
				wordwrap_sprint(command, 1111); // why 1111?
			else
				sprint(self, "ERROR: unsupported info command\n");
				
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd info request\n");
			sprint(self, "  Where 'request' is the suffixed string appended onto the request for cvar.\n");
			return;
		}
	}
}

void ClientCommand_join(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
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
						centerprint(self, PREVENT_JOIN_TEXT);
					}
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd join\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_ladder(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, ladder_reply);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd ladder\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_lsmaps(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, lsmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd lsmaps\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_lsnewmaps(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, lsnewmaps_reply);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd lsnewmaps\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_maplist(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, maplist_reply);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd maplist\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_rankings(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, rankings_reply);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd rankings\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_ready(float request) 
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
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
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd ready\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_records(float request) // TODO: Isn't this flooding with the sprint messages? Old code, but perhaps bad?
{	
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			float i;
			
			for(i = 0; i < 10; ++i)
				sprint(self, records_reply[i]);
				
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd records\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_reportcvar(float request, float argc, string command) // TODO: confirm this works
{	
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			float tokens;
			string s;
			
			if(substring(argv(2), 0, 1) == "$") // undefined cvar: use the default value on the server then
			{
				s = strcat(substring(command, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
				tokens = tokenize_console(s);
			}
			GetCvars(1);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd reportcvar <cvar>\n");
			sprint(self, "  Where 'cvar' is the cvar plus arguments to send to the server.\n");
			return;
		}
	}
}

void ClientCommand_say(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(argc >= 2) { Say(self, FALSE, world, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1); }
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd say <message>\n");
			sprint(self, "  Where 'message' is the string of text to say.\n");
			return;
		}
	}
}

void ClientCommand_say_team(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(argc >= 2) { Say(self, TRUE, world, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1); }
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd say_team <message>\n");
			sprint(self, "  Where 'message' is the string of text to say.\n");
			return;
		}
	}
}

void ClientCommand_selectteam(float request, float argc) // TODO: Update the messages for this command
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			float selection;
			
			if (self.flags & FL_CLIENT)
			{
				if(teamplay)
					if not(self.team_forced > 0) 
						if not(lockteams) 
						{
							switch(argv(1))
							{
								case "red": selection = COLOR_TEAM1; break;
								case "blue": selection = COLOR_TEAM2; break;
								case "yellow": selection = COLOR_TEAM3; break;
								case "pink": selection = COLOR_TEAM4; break;
								case "auto": selection = (-1); break;
								
								default: break;
							}
							
							if(selection)
							{
								if(self.team != selection || self.deadflag != DEAD_NO)
									ClientKill_TeamChange(selection);
								else
									sprint(self, "^7You already are on that team.\n");
							}
						}
						else
							sprint(self, "^7The game has already begun, you must wait until the next map to be able to join a team.\n");
					else
						sprint(self, "^7selectteam can not be used as your team is forced\n");
				else
					sprint(self, "^7selectteam can only be used in teamgames\n");
			}
			return; // never fall through to usage
		}

		default:
		case CC_REQUEST_USAGE:
		{
			//sprint(self, strcat( "selectteam none/red/blue/yellow/pink/auto - \"", argv(1), "\" not recognised\n" ) );
			sprint(self, "\nUsage:^3 cmd selectteam team\n");
			sprint(self, "  Where 'team' is the prefered team to try and join.\n");
			sprint(self, "  Full list of options here: \"red, blue, yellow, pink, auto\"\n");
			return;
		}
	}
}

void ClientCommand_sentcvar(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			float tokens;
			string s;
			
			if(argc == 2) // undefined cvar: use the default value on the server then
			{
				s = strcat(substring(command, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
				tokens = tokenize_console(s);
			}
			GetCvars(1);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd sentcvar <cvar>\n");
			sprint(self, "  Where 'cvar' is the cvar plus arguments to send to the server.\n");
			return;
		}
	}
}

void ClientCommand_spectate(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(self.flags & FL_CLIENT)
			{
				if(g_arena) { return; } 
				if(g_lms)
				{
					if(self.lms_spectate_warning)
					{
						// mark player as spectator
						PlayerScore_Add(self, SP_LMS_RANK, 666 - PlayerScore_Add(self, SP_LMS_RANK, 0));
					}
					else
					{
						self.lms_spectate_warning = 1;
						sprint(self, "WARNING: you won't be able to enter the game again after spectating in LMS. Use the same command again to spectate anyway.\n");
						return;
					}
				}
				
				if(self.classname == "player" && autocvar_sv_spectate == 1) 
					ClientKill_TeamChange(-2); // observe
				
				// in CA, allow a dead player to move to spectatators (without that, caplayer!=0 will be moved back to the player list)
				// note: if arena game mode is ever done properly, this needs to be removed.
				if(g_ca && self.caplayer && (self.classname == "spectator" || self.classname == "observer"))
				{
					sprint(self, "WARNING: you will spectate in the next round.\n");
					self.caplayer = 0;
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd spectate\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_suggestmap(float request, float argc)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			sprint(self, strcat(MapVote_Suggest(argv(1)), "\n"));
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd suggestmap map\n");
			sprint(self, "  Where 'map' is the name of the map to suggest.\n");
			return;
		}
	}
}

void ClientCommand_teamstatus(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			Score_NicePrint(self);
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd teamstatus\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_tell(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			entity e = GetCommandPlayerSlotTargetFromTokenizedCommand(argc, 1);
			
			if(e && argc > ParseCommandPlayerSlotTarget_firsttoken)
			{
				Say(self, FALSE, e, substring(command, argv_start_index(ParseCommandPlayerSlotTarget_firsttoken), argv_end_index(-1) - argv_start_index(ParseCommandPlayerSlotTarget_firsttoken)), TRUE);
			}
			else
			{
				if(argc > ParseCommandPlayerSlotTarget_firsttoken)
					trigger_magicear_processmessage_forallears(self, -1, world, substring(command, argv_start_index(ParseCommandPlayerSlotTarget_firsttoken), argv_end_index(-1) - argv_start_index(ParseCommandPlayerSlotTarget_firsttoken)));
			}
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd tell playerid <message>\n");
			sprint(self, "  Where 'playerid' is the entity number of the player to send the 'message' to.\n");
			return;
		}
	}
}

void ClientCommand_timein(float request)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(self.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout)
				{
					if (!timeoutStatus)
						return sprint(self, "^7Error: There is no active timeout which could be aborted!\n");
					if (self != timeoutInitiator)
						return sprint(self, "^7Error: You may not abort the active timeout. Only the player who called it can do that!\n");
						
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
							sprint(self, "^7Error: Your resumegame call was discarded!\n");
					}
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd timein\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_timeout(float request) // DEAR GOD THIS COMMAND IS TERRIBLE.
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(self.flags & FL_CLIENT)
			{
				if(autocvar_sv_timeout) 
				{
					if(self.classname == "player") 
					{
						if(votecalled)
							sprint(self, "^7Error: you can not call a timeout while a vote is active!\n");
						else
						{
							if (inWarmupStage && !g_warmup_allow_timeout)
								return sprint(self, "^7Error: You can not call a timeout in warmup-stage!\n");
							if (time < game_starttime )
								return sprint(self, "^7Error: You can not call a timeout while the map is being restarted!\n");
								
							if (timeoutStatus != 2) {
								//if the map uses a timelimit make sure that timeout cannot be called right before the map ends
								if (autocvar_timelimit) {
									//a timelimit was used
									float myTl;
									myTl = autocvar_timelimit;

									float lastPossibleTimeout;
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
					}
					else
						sprint(self, "^7Error: only players can call a timeout!\n");
				}
			}
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd timeout\n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_voice(float request, float argc, string command)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			if(argc >= 3)
				VoiceMessage(argv(1), substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));
			else
				VoiceMessage(argv(1), "");
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd voice\n");
			sprint(self, "  FIXME ARGUMENTS UNKNOWN.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void ClientCommand_(float request)ClientCommand_getmapvotepic(request, arguments)
{
	switch(request)
	{
		case CC_REQUEST_COMMAND:
		{
			
			return; // never fall through to usage
		}
			
		default:
		case CC_REQUEST_USAGE:
		{
			sprint(self, "\nUsage:^3 cmd \n");
			sprint(self, "  No arguments required.\n");
			return;
		}
	}
}
*/


// =====================================
//  Macro system for networked commands
// =====================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
#define CLIENT_COMMANDS(request,arguments,command) \
	CLIENT_COMMAND("autoswitch", ClientCommand_autoswitch(request, arguments), "Whether or not to switch automatically when getting a better weapon") \
	CLIENT_COMMAND("checkfail", ClientCommand_checkfail(request, command), "Report if a client-side check failed") \
	CLIENT_COMMAND("clientversion", ClientCommand_clientversion(request, arguments), "Release version of the game") \
	CLIENT_COMMAND("cvar_changes", ClientCommand_cvar_changes(request), "Prints a list of all changed server cvars") \
	CLIENT_COMMAND("cvar_purechanges", ClientCommand_cvar_purechanges(request), "Prints a list of all changed gameplay cvars") \
	CLIENT_COMMAND("getmapvotepic", ClientCommand_getmapvotepic(request, arguments), "Retrieve mapshot picture from the server") \
	CLIENT_COMMAND("info", ClientCommand_info(request, arguments), "Request for unique server information set up by admin") \
	CLIENT_COMMAND("join", ClientCommand_join(request), "Become a player in the game") \
	CLIENT_COMMAND("ladder", ClientCommand_ladder(request), "Get information about top players if supported") \
	CLIENT_COMMAND("lsmaps", ClientCommand_lsmaps(request), "List maps which can be used with the current game mode") \
	CLIENT_COMMAND("lsnewmaps", ClientCommand_lsnewmaps(request), "List maps which TODO") \
	CLIENT_COMMAND("maplist", ClientCommand_maplist(request), "Full server maplist reply") \
	CLIENT_COMMAND("rankings", ClientCommand_rankings(request), "Print information about rankings") \
	CLIENT_COMMAND("ready", ClientCommand_ready(request), "Qualify as ready to end warmup stage (or restart server if allowed)") \
	CLIENT_COMMAND("records", ClientCommand_records(request), "List top 10 records for the current map") \
	CLIENT_COMMAND("reportcvar", ClientCommand_reportcvar(request, arguments, command), "Old system for sending a client cvar to the server") \
	CLIENT_COMMAND("say", ClientCommand_say(request, arguments, command), "Print a message to chat to all players") \
	CLIENT_COMMAND("say_team", ClientCommand_say_team(request, arguments, command), "Print a message to chat to all team mates") \
	CLIENT_COMMAND("selectteam", ClientCommand_selectteam(request, arguments), "Attempt to choose a team to join into") \
	CLIENT_COMMAND("sentcvar", ClientCommand_sentcvar(request, arguments, command), "New system for sending a client cvar to the server") \
	CLIENT_COMMAND("spectate", ClientCommand_spectate(request), "Become an observer") \
	CLIENT_COMMAND("suggestmap", ClientCommand_suggestmap(request, arguments), "Suggest a map to the mapvote at match end") \
	CLIENT_COMMAND("teamstatus", ClientCommand_teamstatus(request), "Print detailed score information for all players") \
	CLIENT_COMMAND("tell", ClientCommand_tell(request, arguments, command), "Send a message directly to a player") \
	CLIENT_COMMAND("timein", ClientCommand_timein(request), "Resume the game from being paused with a timeout") \
	CLIENT_COMMAND("timeout", ClientCommand_timeout(request), "Call a timeout which pauses the game for certain amount of time unless unpaused") \
	CLIENT_COMMAND("voice", ClientCommand_voice(request, arguments, command), "Send voice message via sound") \
	CLIENT_COMMAND("vote", VoteCommand(self, arguments), "Request an action to be voted upon by players") \
	/* nothing */
	
void ClientCommand_macro_help()
{
	#define CLIENT_COMMAND(name,function,description) \
		{ print("  ^2", name, "^7: ", description, "\n"); }
		
	CLIENT_COMMANDS(0, 0, "")
	#undef CLIENT_COMMAND
	
	return;
}

float ClientCommand_macro_command(float argc, string command)
{
	#define CLIENT_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(0))) { function; return TRUE; } }
		
	CLIENT_COMMANDS(CC_REQUEST_COMMAND, argc, command)
	#undef CLIENT_COMMAND
	
	return FALSE;
}

float ClientCommand_macro_usage(float argc, string command)
{
	#define CLIENT_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(1))) { function; return TRUE; } }
		
	CLIENT_COMMANDS(CC_REQUEST_USAGE, argc, command)
	#undef CLIENT_COMMAND
	
	return FALSE;
}


// ======================================
//  Main Function Called By Engine (cmd)
// ======================================
// If this function exists, server game code parses clientcommand before the engine code gets it.

void SV_ParseClientCommand(string command)
{
	float argc = tokenize_console(command);
	
	// for floodcheck
	switch(strtolower(argv(0)))
	{
		// exempt commands which are not subject to floodcheck
		case "begin": break; // handled by engine in host_cmd.c
		case "getmapvotepic": break; // handled by server in this file
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
			ClientCommand_macro_help;
			sprint(self, "For help about specific commands, type cmd help COMMAND\n");
			return;
		} 
		else if(ClientCommand_macro_usage(argc, command)) // Instead of trying to call a command, we're going to see detailed information about it
		{
			return;
		}
	} 
	else*/ if(MUTATOR_CALLHOOK(SV_ParseClientCommand))
	{
		return; // handled by a mutator
	}
	else if(CheatCommand(argc)) 
	{
		return; // handled by server/cheats.qc
	}
	else if(ClientCommand_macro_command(argc, command)) // continue as usual and scan for normal commands
	{
		return; // handled by one of the above GameCommand_* functions
	}
	else
		clientcommand(self, command);
}