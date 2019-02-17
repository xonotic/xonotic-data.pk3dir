#include "menu_cmd.qh"

#include "../menu.qh"
#include "../item.qh"

#include <menu/mutators/_mod.qh>

#include <common/command/_mod.qh>

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

	if (argv(0) == "help" || argc == 0)
	{
		LOG_INFO(_("Usage: menu_cmd command..., where possible commands are:"));
		LOG_INFO(_("  sync - reloads all cvars on the current menu page"));
		LOG_INFO(_("  directmenu ITEM - select a menu item as main item"));
		LOG_INFO(_("  dumptree - dump the state of the menu as a tree to the console"));
		LOG_INFO("\n");

		LOG_INFO("Generic commands shared by all programs:");
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

	if (argv(0) == "directmenu" || argv(0) == "directpanelhudmenu")
	{
		string filter = string_null;
		if (argv(0) == "directpanelhudmenu") filter = "HUD";

		if (argc == 1)
		{
			LOG_INFO(_("Available options:"));

			FOREACH_ENTITY_ORDERED(it.name != "", {
				if (it.classname == "vtbl") continue;
				string s = it.name;
				if (filter)
				{
					if (!startsWith(s, filter)) continue;
					s = substring(s, strlen(filter), strlen(s) - strlen(filter));
				}
				LOG_INFO(" ", s);
			});
		}
		else if (argc == 2 && !isdemo())     // don't allow this command in demos
		{
			m_play_click_sound(MENU_SOUND_OPEN);
			m_goto(strcat(filter, argv(1))); // switch to a menu item
		}
		return;
	}

	if (argv(0) == "skinselect")
	{
		m_goto("skinselector");
		return;
	}

	if (argv(0) == "languageselect")
	{
		m_goto("languageselector");
		return;
	}

	if (argv(0) == "videosettings")
	{
		m_goto("videosettings");
		return;
	}

	if (argv(0) == "dumptree")
	{
		_dumptree_space = "";
		depthfirst(main, parent, firstChild, nextSibling, _dumptree_open, _dumptree_close, NULL);
		return;
	}

	if(MUTATOR_CALLHOOK(Menu_ConsoleCommand, ss, argc, theCommand)) // handled by a mutator
		return;

	LOG_INFO(_("Invalid command. For a list of supported commands, try menu_cmd help."));
}
