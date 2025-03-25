#include "menu_cmd.qh"

#include "../menu.qh"
#include "../item.qh"

#include <menu/item/dialog.qh>
#include <menu/mutators/_mod.qh>

#include <common/command/_mod.qh>

.void(entity me, int argsbuf) readInputArgs;
.entity firstChild, nextSibling;

string _dumptree_space;
void _dumptree_open(entity pass, entity me)
{
	string s;
	s = me.toString(me);
	if (s == "") s = me.classname;
	else s = strcat(me.classname, ": ", s);
	print(_dumptree_space, etos(me), " (", s, ")");
	if (me.firstChild)
	{
		print(" {\n");
		_dumptree_space = strcat(_dumptree_space, "  ");
	}
	else
	{
		print("\n");
	}
}
void _dumptree_close(entity pass, entity me)
{
	if (me.firstChild)
	{
		_dumptree_space = substring(_dumptree_space, 0, strlen(_dumptree_space) - 2);
		print(_dumptree_space, "}\n");
	}
}

float updateConwidths(float width, float height, float pixelheight);

void GameCommand(string theCommand)
{
	int argc = tokenize_console(theCommand);
	string ss = strtolower(argv(0));

	// TODO port these commands to the command system
	if (argv(0) == "help" || argc == 0)
	{
		LOG_HELP("Usage:^3 menu_cmd <command> [<item>], where possible commands are:");
		LOG_HELP("  'sync' reloads all cvars on the current menu page");
		LOG_HELP("  'directmenu' shows the menu window named <item> (or the menu window containing an item named <item>)");
		LOG_HELP("  'closemenu' closes the menu window named <item> (or the menu window containing an item named <item>)");
		LOG_HELP("   if <item> is not specified it shows the list of available items in the console");
		LOG_HELP("  'dumptree' dumps the state of the menu as a tree to the console");
		LOG_HELP("  'isdemo' checks if engine is currently running a demo. If given an <item> then 1 / 0 is placed");
		LOG_HELP("   in the cvar with that name. Otherwise without an argument the result is printed to console.");

		LOG_HELP("\nGeneric commands shared by all programs:");
		GenericCommand_macro_help();

		return;
	}

	if (GenericCommand(theCommand)) return;

	if (argv(0) == "sync")
	{
		m_sync();
		return;
	}

	if (argv(0) == "update_conwidths_before_vid_restart")
	{
		updateConwidths(cvar("vid_width"), cvar("vid_height"), cvar("vid_pixelheight"));
		return;
	}

	string argcmd = argv(0);
	string filter = string_null;
	bool close_mode = false;
	if (argcmd == "closemenu")
	{
		close_mode = true;
		argcmd = "directmenu";
	}
	else if (argcmd == "directpanelhudmenu")
	{
		filter = "HUD";
		argcmd = "directmenu";
	}

	if (argcmd == "directmenu")
	{
		if (argc == 1)
		{
			LOG_HELP("Available items (* = closable):");

			FOREACH_ENTITY_ORDERED(it.name != "", {
				if (it.classname == "vtbl") continue;
				string s = it.name;
				if (filter)
				{
					if (!startsWith(s, filter)) continue;
					s = substring(s, strlen(filter), strlen(s) - strlen(filter));
				}
				if (it.instanceOfContainer && it.closable)
					LOG_HELP(" * ", s);
				else
					LOG_HELP("   ", s);
			});
		}
		else if (argc == 2 && !close_mode && (!isdemo() || argv(1) == "Welcome")) // don't allow this command in demos
		{
			m_play_click_sound(MENU_SOUND_OPEN);
			m_goto(strcat(filter, argv(1)), true); // switch to a menu item
		}
		else if(argc > 2 && (!isdemo() || argv(1) == "Welcome"))
		{
			entity e = NULL;
			float argsbuf = 0;
			string s = strzone(argv(1)); // dialog name
			for(int i = 0; (e = nextent(e)); )
				if(e.classname != "vtbl" && e.name == strcat(filter, s))
				{
					argsbuf = buf_create();
					if(argsbuf >= 0)
					if(e.readInputArgs)
					{
						for(i = 2; i < argc; ++i)
							bufstr_add(argsbuf, argv(i), 1);
						e.readInputArgs(e, argsbuf);
						if (!close_mode)
							m_goto(strcat(filter, s), true);
					}
					if(argsbuf >= 0)
						buf_del(argsbuf);

					// NOTE input args are read even in close mode
					if (close_mode)
					{
						if (e.instanceOfContainer && e.closable && e.focused)
							Dialog_Close(e, e);
					}
				}
		}
		return;
	}

	switch (argv(0))
	{
		// unlike menu_cmd directmenu, the menu won't be closed when these menu items will be closed
		case "nexposee":         m_goto("nexposee", false); return;
		case "servers":          m_goto("servers", false); return;
		case "profile":          m_goto("profile", false); return;
		case "skinselect":       m_goto("skinselector", false); return;
		case "languageselect":   m_goto("languageselector", false); return;
		case "settings":         m_goto("settings", false); return;
		case "inputsettings":    m_goto("inputsettings", false); return;
		case "videosettings":    m_goto("videosettings", false); return;
	}

	if (argv(0) == "dumptree")
	{
		_dumptree_space = "";
		depthfirst(main, parent, firstChild, nextSibling, _dumptree_open, _dumptree_close, NULL);
		return;
	}

	if (argv(0) == "isdemo")
	{
		int value = isdemo();

		if (argv(1) != "")
		{
			cvar_set(argv(1), ftos(value));
		}
		else
		{
			print(sprintf("%d\n", value));
		}

		return;
	}

	if(MUTATOR_CALLHOOK(Menu_ConsoleCommand, ss, argc, theCommand)) // handled by a mutator
		return;

	LOG_INFO("Invalid command. For a list of supported commands, try menu_cmd help.");
}
