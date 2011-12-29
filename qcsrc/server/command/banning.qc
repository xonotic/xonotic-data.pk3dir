// =====================================================
//  Banning and kicking command code, written by Samual
//  Last updated: December 29th, 2011
// =====================================================

void BanCommand_ban(float request, float argc)
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
			print("\nUsage:^3 sv_cmd ");
			print("  No arguments required.\n");
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
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd ");
			print("  No arguments required.\n");
			return;
		}
	}
}

void BanCommand_kickban(float request, float argc)
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
			print("\nUsage:^3 sv_cmd ");
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
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 sv_cmd ");
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
			print("\nUsage:^3 sv_cmd ");
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
	BAN_COMMAND("ban", BanCommand_ban(request, arguments), "Ban an IP address or a range of addresses (like 1.2.3)") \
	BAN_COMMAND("banlist", BanCommand_banlist(request), "List all existing bans") \
	BAN_COMMAND("kickban", BanCommand_kickban(request, arguments), "Disconnect a client and ban it at the same time") \
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
	float argc;
	float bantime;
	entity client;
	float entno;
	float masksize;
	string reason;
	float reasonarg;

	argc = tokenize_console(command);
	if(argv(0) == "help")
	{
		print("  kickban # n m p reason - kickban player n for m seconds, using mask size p (1 to 4)\n");
		print("  ban ip m reason - ban an IP or range (incomplete IP, like 1.2.3) for m seconds\n");
		print("  bans - list all existing bans\n");
		print("  unban n - delete the entry #n from the bans list\n");
		return TRUE;
	}
	if(argv(0) == "kickban")
	{
#define INITARG(c) reasonarg = c
#define GETARG(v,d) if((argc > reasonarg) && ((v = stof(argv(reasonarg))) != 0)) ++reasonarg; else v = d
#define RESTARG(v) if(argc > reasonarg) v = substring(command, argv_start_index(reasonarg), strlen(command) - argv_start_index(reasonarg)); else v = ""
		if(argc >= 3)
		{
			entno = stof(argv(2));
			if(entno > maxclients || entno < 1)
				return TRUE;
			client = edict_num(entno);

			INITARG(3);
			GETARG(bantime, autocvar_g_ban_default_bantime);
			GETARG(masksize, autocvar_g_ban_default_masksize);
			RESTARG(reason);

			Ban_KickBanClient(client, bantime, masksize, reason);
			return TRUE;
		}
	}
	else if(argv(0) == "ban")
	{
		if(argc >= 2)
		{
			string ip;
			ip = argv(1);

			INITARG(2);
			GETARG(bantime, autocvar_g_ban_default_bantime);
			RESTARG(reason);

			Ban_Insert(ip, bantime, reason, 1);
			return TRUE;
		}
#undef INITARG
#undef GETARG
#undef RESTARG
	}
	else if(argv(0) == "bans")
	{
		Ban_View();
		return TRUE;
	}
	else if(argv(0) == "unban")
	{
		if(argc >= 2)
		{
			float who;
			who = stof(argv(1));
			Ban_Delete(who);
			return TRUE;
		}
	}
	return FALSE;
}