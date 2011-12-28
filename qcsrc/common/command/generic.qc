// =========================================================
//  Generic program common command code, reworked by Samual
//  Last updated: December 28th, 2011
// =========================================================

// used by generic commands for better help/usage information
string GetProgramCommandPrefix(void)
{
	#ifdef SVQC
	return "sv_cmd";
	#endif
	#ifdef CSQC
	return "cl_cmd";
	#endif
	#ifdef MENUQC
	return "menu_cmd";
	#endif
}

#define NUM_MARKUPS	41
float markup_init;
string markup_from[NUM_MARKUPS];
string markup_to[NUM_MARKUPS];
void GameCommand_MarkupInit()
{
	float i;
	if (markup_init)
		return;
	markup_init = 1;
	i = 0;
	markup_from[i] = "&alien"; markup_to[i] = "\x12"; ++i;
	markup_from[i] = "&:-)"; markup_to[i] = "\x13"; ++i;
	markup_from[i] = "&:-("; markup_to[i] = "\x14"; ++i;
	markup_from[i] = "&x-P"; markup_to[i] = "\x15"; ++i;
	markup_from[i] = "&:-/"; markup_to[i] = "\x16"; ++i;
	markup_from[i] = "&:-D"; markup_to[i] = "\x17"; ++i;
	markup_from[i] = "&<<"; markup_to[i] = "\x18"; ++i;
	markup_from[i] = "&>>"; markup_to[i] = "\x19"; ++i;
	markup_from[i] = "&dot"; markup_to[i] = "\x1a"; ++i;
	markup_from[i] = "&^_"; markup_to[i] = "\x1b"; ++i;
	markup_from[i] = "&ysplat"; markup_to[i] = "\x1c"; ++i;
	markup_from[i] = "&-]"; markup_to[i] = "\x1d"; ++i;
	markup_from[i] = "&--"; markup_to[i] = "\x1e"; ++i;
	markup_from[i] = "&[-"; markup_to[i] = "\x1f"; ++i;
	markup_from[i] = "&s<"; markup_to[i] = "\x2c"; ++i;
	markup_from[i] = "&s>"; markup_to[i] = "\x2e"; ++i;
	markup_from[i] = "&<-"; markup_to[i] = "\x7f"; ++i;
	markup_from[i] = "&[="; markup_to[i] = "\x80"; ++i;
	markup_from[i] = "&=="; markup_to[i] = "\x81"; ++i;
	markup_from[i] = "&=]"; markup_to[i] = "\x82"; ++i;
	markup_from[i] = "&r!"; markup_to[i] = "\x84"; ++i;
	markup_from[i] = "&|o|"; markup_to[i] = "\x85"; ++i;
	markup_from[i] = "&|u|"; markup_to[i] = "\x86"; ++i;
	markup_from[i] = "&|i|"; markup_to[i] = "\x87"; ++i;
	markup_from[i] = "&|c|"; markup_to[i] = "\x88"; ++i;
	markup_from[i] = "&[c]"; markup_to[i] = "\x89"; ++i;
	markup_from[i] = "&[n]"; markup_to[i] = "\x8a"; ++i;
	markup_from[i] = "&[]"; markup_to[i] = "\x8b"; ++i;
	markup_from[i] = "&r?"; markup_to[i] = "\x8c"; ++i;
	markup_from[i] = "&|>"; markup_to[i] = "\x8d"; ++i;
	markup_from[i] = "&splat0"; markup_to[i] = "\x8e"; ++i;
	markup_from[i] = "&splat1"; markup_to[i] = "\x8f"; ++i;
	markup_from[i] = "&[["; markup_to[i] = "\x90"; ++i;
	markup_from[i] = "&]]"; markup_to[i] = "\x91"; ++i;
	markup_from[i] = "&splat2"; markup_to[i] = "\x9a"; ++i;
	markup_from[i] = "&)("; markup_to[i] = "\x9b"; ++i;
	markup_from[i] = "&splat3"; markup_to[i] = "\x9c"; ++i;
	markup_from[i] = "&(."; markup_to[i] = "\x9d"; ++i;
	markup_from[i] = "&.."; markup_to[i] = "\x9e"; ++i;
	markup_from[i] = "&.)"; markup_to[i] = "\x9f"; ++i;
	markup_from[i] = "&<|"; markup_to[i] = "\xff"; ++i;
}

string GameCommand_Markup(string s2)
{
	float red, ccase, i, j;
	string s, s3;

	GameCommand_MarkupInit();

	s = "";

	red = 0;
	ccase = 0;
	for(i = 0; i < strlen(s2); ++i)
	{
		for(j = 0; j < NUM_MARKUPS; ++j)
		{
			s3 = substring(s2, i, strlen(markup_from[j]));
			if (s3 == markup_from[j])
			{
				s = strcat(s, markup_to[j]);
				i += strlen(markup_from[j]) - 1;
				break;
			}
		}

		if(j == NUM_MARKUPS)
		{
			if(substring(s2, i, 2) == "&&")
			{
				s = strcat(s, strconv(ccase, red, red, "&"));
				++i;
			}
			else if(substring(s2, i, 2) == "&d")
			{
				red = 2;
				ccase = 0;
				++i;
			}
			else if(substring(s2, i, 2) == "&a")
			{
				red = 2;
				ccase = 2;
				++i;
			}
			else if(substring(s2, i, 2) == "&n")
			{
				red = 0;
				ccase = 0;
				++i;
			}
			else
				s = strcat(s, strconv(ccase, red, red, substring(s2, i, 1)));
		}
	}

	return s;
}

void GenericCommand_addtolist(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i;
			
			if(argc >= 2)
			{
				if(cvar_string(argv(1)) == "") // cvar was empty
				{
					cvar_set(argv(1), argv(2));
				}
				else // add it to the end of the list if the list doesn't already have it
				{
					argc = tokenizebyseparator(cvar_string(argv(1)), " ");
					for(i = 0; i < argc; ++i)
						if(argv(i) == argv(2))
							return; // already in list
							
					cvar_set(argv(1), strcat(argv(2), " ", cvar_string(argv(1))));
				}
				return;
			}
		}
			
		default:
			// todo
		case CMD_REQUEST_USAGE:
		{
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " addtolist variable [value]"));
			print("  Where 'variable' is what to add to the list,\n");
			print("  and 'value' is any extra optional paramaters to add with quotes.");
			return;
		}
	}
}

void GenericCommand_maplist(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string tmp_string;
			float i;
			
			switch(argv(1))
			{
				case "add": // appends new maps to the maplist
				{
					if(argc == 3)
					{
						if (!fexists(strcat("maps/", argv(2), ".bsp")))
						{
							print("maplist: ERROR: ", argv(2), " does not exist!\n");
							break;
						}
						
						if(cvar_string("g_maplist") == "")
							cvar_set("g_maplist", argv(2));
						else
							cvar_set("g_maplist", strcat(argv(2), " ", cvar_string("g_maplist")));
							
						return;
					}
					break; // go to usage
				}
				
				case "remove": // scans maplist and only adds back whatever maps were not provided in argv(2)
				{
					if(argc == 3)
					{
						argc = tokenizebyseparator(cvar_string("g_maplist"), " ");
						
						for(i = 0; i < argc; ++i)
							if(argv(i) != argv(2))
								tmp_string = strcat(tmp_string, " ", argv(i));
								
						tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
						cvar_set("g_maplist", tmp_string);
						
						return;
					}
					break; // go to usage
				}
				
				case "shuffle": // randomly shuffle the maplist
				{
					cvar_set("g_maplist", shufflewords(cvar_string("g_maplist")));
					return;
				}
				
				case "cleanup": // scans maplist and only adds back the ones which are really usable
				{
					MapInfo_Enumerate();
					MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
					argc = tokenizebyseparator(cvar_string("g_maplist"), " ");
					
					for(i = 0; i < argc; ++i)
						if(MapInfo_CheckMap(argv(i)))
							tmp_string = strcat(tmp_string, " ", argv(i));
							
					tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
					cvar_set("g_maplist", tmp_string);
					
					return;
				}
					
				default: break;
			}
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " maplist command [map]")); // todo
			print("  No arguments required.\n");
			return;
		}
	}
}

void GenericCommand_settemp(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 3)
			{
				if(cvar_settemp(argv(1), argv(2)))
					dprint("Creating new settemp tracker for ", argv(1), " and setting it to \"", argv(2), "\" temporarily.\n"); 
				else
					dprint("Already had a tracker for ", argv(1), ", updating it to \"", argv(2), "\".\n");
			
				return;
			}
		}
			
		default:
			print("Incorrect parameters for ^2settemp^7\n");
		case CMD_REQUEST_USAGE:
		{
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " settemp \"cvar\" \"arguments\"\n"));
			print("  Where 'cvar' is the cvar you want to temporarily set with 'arguments'.\n");
			return;
		}
	}
}

void GenericCommand_settemp_restore(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i = cvar_settemp_restore();
			
			if(i)
				dprint("Restored ", ftos(i), " temporary cvar settings to their original values.\n");
			else
				dprint("Nothing to restore.\n");
			
			return;
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " settemp_restore\n"));
			print("  No arguments required.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void GenericCommand_(float request)
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
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " ")));
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
#define GENERIC_COMMANDS(request,arguments,command) \
	GENERIC_COMMAND("addtolist", GenericCommand_addtolist(request, arguments), "Add a string to a cvar at the end of a list") \
	GENERIC_COMMAND("maplist", GenericCommand_maplist(request, arguments), "Automatic control of maplist") \
	GENERIC_COMMAND("rpn", GenericCommand_rpn(request, arguments, command), "RPN calculator") \
	GENERIC_COMMAND("settemp", GenericCommand_settemp(request, arguments), "Temporarily set a value to a cvar which is restored later") \
	GENERIC_COMMAND("settemp_restore", GenericCommand_settemp_restore(request, arguments), "Restore all cvars set by settemp command") \
	/* nothing */

void GenericCommand_macro_help()
{
	#define GENERIC_COMMAND(name,function,description) \
		{ print("  ^2", name, "^7: ", description, "\n"); }
		
	GENERIC_COMMANDS(0, 0, "")
	#undef GENERIC_COMMAND
	
	return;
}

float GenericCommand_macro_command(float argc, string command)
{
	#define GENERIC_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(0))) { function; return TRUE; } }
		
	GENERIC_COMMANDS(CMD_REQUEST_COMMAND, argc, command)
	#undef GENERIC_COMMAND
	
	return FALSE;
}

float GenericCommand_macro_usage(float argc)
{
	#define GENERIC_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(1))) { function; return TRUE; } }
		
	GENERIC_COMMANDS(CMD_REQUEST_USAGE, argc, "")
	#undef GENERIC_COMMAND
	
	return FALSE;
}
	

// ===========================================
//  Main Common Function For Generic Commands
// ===========================================
// Commands spread out among all programs (menu, client, and server) 

float GenericCommand(string command)
{
	float argc = tokenize_console(command);
	float n, j, f, i;
	string s, s2, c;
	vector rgb;

	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3 
	// cmd     vote - master - login - password
	
	if(strtolower(argv(0)) == "help") 
	{
		if(argc == 1) 
		{
			GenericCommand_macro_help();
			return TRUE;
		} 
		else if(GenericCommand_macro_usage(argc)) // Instead of trying to call a command, we're going to see detailed information about it
		{
			return TRUE;
		}
	} 
	else if(GenericCommand_macro_command(argc, command)) // continue as usual and scan for normal commands
	{
		return TRUE; // handled by one of the above GenericCommand_* functions
	}
	else if(argc >= 3 && argv(0) == "red")
	{
		s = substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2));
		localcmd(strcat(argv(1), " ", GameCommand_Markup(s)));
		return TRUE;
	}
	else if(argc >= 3 && crc16(0, argv(0)) == 38566 && crc16(0, strcat(argv(0), argv(0), argv(0))) == 59830)
	{
		// other test case
		s = strconv(2, 0, 0, substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));

		n = floor(random() * 6 + 2);

		s2 = "";
		for(i = 0; i < n; ++i)
		{
			s2 = strcat(s2, "AH");
		}

		if(random() < 0.1)
			s2 = strcat(substring(s2, 1, strlen(s2) - 1), "A");

		if(s == "")
			s = s2;
		else
			if(random() < 0.8)
				s = strcat(s, " ", s2);
			else
				s = strcat(s2, " ", s);

		s2 = substring(s, strlen(s) - 2, 2);
		if(s2 == "AH" || s2 == "AY")
			s = strcat(s, "))");
		else
			s = strcat(s, " ))");

		if(random() < 0.1)
			s = substring(s, 0, strlen(s) - 1);

		if(random() < 0.1)
			s = strconv(1, 0, 0, s);

		localcmd(strcat(argv(1), " ", s));

		return TRUE;
	}
	else if(argc >= 3 && crc16(0, argv(0)) == 3826 && crc16(0, strcat(argv(0), argv(0), argv(0))) == 55790)
	{
		// test case for terencehill's color codes
		s = strdecolorize(substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));
		s2 = "";
		
		n = strlen(s);
		j = ((6 * max(1, floor(strlen(s)/32 + random() * 2 - 1))) / n) * (1 - 2 * (random() > 0.5));
		f = random() * 6;

		for(i = 0; i < n; ++i)
		{
			c = substring(s, i, 1);

			if(c == ";")
				c = ":";
			else if(c == "^")
			{
				c = "^^";
				if(substring(s, i+1, 1) == "^")
					++i;
			}

			if(c != " ")
			{
				rgb = hsl_to_rgb('1 0 0' * (j * i + f) + '0 1 .5');
				c = strcat(rgb_to_hexcolor(rgb), c);
			}
			s2 = strcat(s2, c);
		}

		localcmd(strcat(argv(1), " ", s2));

		return TRUE;
	}

	return FALSE;
}
