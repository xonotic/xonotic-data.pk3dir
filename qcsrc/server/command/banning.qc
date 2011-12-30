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
			print("\nUsage:^3 sv_cmd ban address [time] [reason]\n");
			print("  No arguments required. todo\n");
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
			print("  No arguments required. todo\n");
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
			if(argc >= 2)
			{
				float who;
				who = stof(argv(1));
				Ban_Delete(who);
				return;
			}
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd unban banid\n");
			print("  Where 'banid' is the ID of the ban of which to remove.\n");
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
#define BAN_COMMANDS(request,arguments,command) \
	BAN_COMMAND("ban", BanCommand_ban(request, arguments, command), "Ban an IP address or a range of addresses (like 1.2.3)") \
	BAN_COMMAND("banlist", BanCommand_banlist(request), "List all existing bans") \
	BAN_COMMAND("kickban", BanCommand_kickban(request, arguments, command), "Disconnect a client and ban it at the same time") \
	BAN_COMMAND("unban", BanCommand_unban(request, arguments), "Remove an existing ban") \
	/* nothing */

void BanCommand_macro_help()
{
	#define BAN_COMMAND(name,function,description) \
		{ print("  ^2", name, "^7: ", description, "\n"); }
		
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
		{ CMD_Write_Alias("qc_cmd_sv", name, description); }
	
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