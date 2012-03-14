string _dumptree_space;
void _dumptree_open(entity pass, entity me)
{
	string s;
	s = me.toString(me);
	if(s == "")
		s = me.classname;
	else
		s = strcat(me.classname, ": ", s);
	print(_dumptree_space, etos(me), " (", s, ")");
	if(me.firstChild)
	{
		print(" {\n");
		_dumptree_space = strcat(_dumptree_space, "  ");
	}
	else
		print("\n");
}
void _dumptree_close(entity pass, entity me)
{
	if(me.firstChild)
	{
		_dumptree_space = substring(_dumptree_space, 0, strlen(_dumptree_space) - 2);
		print(_dumptree_space, "}\n");
	}
}

void GameCommand(string theCommand)
{
	float argc;
	argc = tokenize_console(theCommand);

	if(argv(0) == "help" || argc == 0)
	{
		print(_("Usage: menu_cmd command..., where possible commands are:\n"));
		print(_("  sync - reloads all cvars on the current menu page\n"));
		print(_("  directmenu ITEM - select a menu item as main item\n"));
		GenericCommand("help");
		return;
	}

	if(GenericCommand(theCommand))
		return;

	if(argv(0) == "sync")
	{
		m_sync();
		return;
	}

	if(argv(0) == "directmenu") if(argc == 2)
	{
		// switch to a menu item
		if(!isdemo()) // don't allow this command in demos
			m_goto(argv(1));
		return;
	}

	if(argv(0) == "directpanelhudmenu")
	{
		// switch to a menu item
		m_goto(strcat("HUD", argv(1)));
		return;
	}

	if(argv(0) == "skinselect")
	{
		m_goto("skinselector");
		return;
	}

	if(argv(0) == "languageselect")
	{
		m_goto("languageselector");
		return;
	}

	if(argv(0) == "videosettings")
	{
		m_goto("videosettings");
		return;
	}

	if(argv(0) == "dumptree")
	{
		_dumptree_space = "";
		depthfirst(main, parent, firstChild, nextSibling, _dumptree_open, _dumptree_close, NULL);
		return;
	}

	if(argv(0) == "curl")
	{
	}

	print(_("Invalid command. For a list of supported commands, try menu_cmd help.\n"));
}
