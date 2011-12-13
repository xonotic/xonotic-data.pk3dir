float GameCommand_Ban(string command)
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