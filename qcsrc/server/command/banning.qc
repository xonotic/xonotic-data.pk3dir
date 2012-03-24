// =====================================================
//  Banning and kicking command code, written by Samual
//  Last updated: December 29th, 2011
// =====================================================

void BanCommand_ban(float request, float argc, string command)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 2)
			{
				string ip = argv(1);
				float reason_arg, bantime;
				string reason;
				
				reason_arg = 2; 
				
				GET_BAN_ARG(bantime, autocvar_g_ban_default_bantime);
				GET_BAN_REASON(reason, "No reason provided");

				Ban_Insert(ip, bantime, reason, 1);
				return;
			}
		}
			
		default:
			print("Incorrect parameters for ^2ban^7\n");
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd ban address [bantime] [reason]\n");
			print("  'address' is the IP address or range of the player to ban,\n");
			print("  'bantime' is the amount of time that the ban is active (default if not provided),\n");
			print("  and 'reason' is the string to label the ban with as reason for banning.\n");
			print("See also: ^2banlist, kickban, unban^7\n");
			return;
		}
	}
}

void BanCommand_banlist(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			Ban_View();
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd banlist\n");
			print("  No arguments required.\n");
			print("See also: ^2ban, kickban, unban^7\n");
			return;
		}
	}
}

void BanCommand_kickban(float request, float argc, string command)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 2)
			{
				entity client = GetIndexedEntity(argc, 1);
				float accepted = VerifyClientEntity(client, TRUE, FALSE);
				float reason_arg, bantime, masksize;
				string reason;
				
				if(accepted > 0) 
				{
					reason_arg = next_token; 

					GET_BAN_ARG(bantime, autocvar_g_ban_default_bantime);
					GET_BAN_ARG(masksize, autocvar_g_ban_default_masksize);
					GET_BAN_REASON(reason, "No reason provided");

					Ban_KickBanClient(client, bantime, masksize, reason);
					
					return;
				}
				else
				{
					print("kickban: ", GetClientErrorString(accepted, argv(1)), ".\n"); 
				}
			}
		}
			
		default:
			print("Incorrect parameters for ^2kickban^7\n");
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd kickban client [bantime] [masksize] [reason]\n");
			print("  'client' is the entity number or name of the player to ban,\n");
			print("  'bantime' is the amount of time that the ban is active (default if not provided),\n");
			print("  'masksize' is the range of the IP address (1-thru-4, default if not provided),\n");
			print("  and 'reason' is the string to label the ban with as reason for banning.\n");
			print("See also: ^2ban, banlist, unban^7\n");
			return;
		}
	}
}

void BanCommand_mute(float request, float argc, string command)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd mute\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

void BanCommand_unban(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argv(1))
			{
				Ban_Delete(stof(argv(1)));
				return;
			}
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd unban banid\n");
			print("  Where 'banid' is the ID of the ban of which to remove.\n");
			print("See also: ^2ban, banlist, kickban^7\n");
			return;
		}
	}
}

void BanCommand_unmute(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd unmute\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void BanCommand_(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd \n");
			print("  No arguments required.\n");
			return;
		}
	}
}
*/


// ==================================
//  Macro system for server commands
// ==================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
// but for 0.5 compat, we need "bans" here as it was replaced... REMOVE IT AFTER 0.6 RELEASE!!!!
#define BAN_COMMANDS(request,arguments,command) \
	BAN_COMMAND("ban", BanCommand_ban(request, arguments, command), "Ban an IP address or a range of addresses (like 1.2.3)") \
	BAN_COMMAND("banlist", BanCommand_banlist(request), "List all existing bans") \
	BAN_COMMAND("bans", BanCommand_banlist(request), "") \
	BAN_COMMAND("kickban", BanCommand_kickban(request, arguments, command), "Disconnect a client and ban it at the same time") \
	BAN_COMMAND("mute", BanCommand_mute(request, arguments, command), "Disallow a client from talking by muting them") \
	BAN_COMMAND("unban", BanCommand_unban(request, arguments), "Remove an existing ban") \
	BAN_COMMAND("unmute", BanCommand_unmute(request, arguments), "Unmute a client") \
	/* nothing */

void BanCommand_macro_help()
{
	#define BAN_COMMAND(name,function,description) \
		{ if(strtolower(description) != "") { print("  ^2", name, "^7: ", description, "\n"); } }
		
	BAN_COMMANDS(0, 0, "")
	#undef BAN_COMMAND
	
	return;
}

float BanCommand_macro_command(float argc, string command)
{
	#define BAN_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(0))) { function; return TRUE; } }
		
	BAN_COMMANDS(CMD_REQUEST_COMMAND, argc, command)
	#undef BAN_COMMAND
	
	return FALSE;
}

float BanCommand_macro_usage(float argc)
{
	#define BAN_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(1))) { function; return TRUE; } }
		
	BAN_COMMANDS(CMD_REQUEST_USAGE, argc, "")
	#undef BAN_COMMAND
	
	return FALSE;
}

void BanCommand_macro_write_aliases(float fh)
{
	#define BAN_COMMAND(name,function,description) \
		{ if(strtolower(description) != "") { CMD_Write_Alias("qc_cmd_sv", name, description); } }
	
	BAN_COMMANDS(0, 0, "")
	#undef BAN_COMMAND
	
	return;
}

float BanCommand(string command)
{
	float argc = tokenize_console(command);
	
	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3 
	// cmd     vote - master - login - password

	if(BanCommand_macro_command(argc, command)) // continue as usual and scan for normal commands
	{
		return TRUE; // handled by one of the above GenericCommand_* functions
	}
	
	return FALSE;
}