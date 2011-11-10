void GameCommand_Init()
{
	// make gg call menu QC theCommands
	localcmd("alias qc_cmd \"menu_cmd $*\"\n");
}

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

float curl_uri_get_pos;
float curl_uri_get_exec[URI_GET_CURL_END - URI_GET_CURL + 1];
string curl_uri_get_cvar[URI_GET_CURL_END - URI_GET_CURL + 1];
void Curl_URI_Get_Callback(float id, float status, string data)
{
	float i;
	float do_exec;
	string do_cvar;
	i = id - URI_GET_CURL;
	do_exec = curl_uri_get_exec[i];
	do_cvar = curl_uri_get_cvar[i];
	if(status != 0)
	{
		print(sprintf(_("error: status is %d\n"), status));
		if(do_cvar)
			strunzone(do_cvar);
		return;
	}
	if(do_exec)
		localcmd(data);
	if(do_cvar)
	{
		cvar_set(do_cvar, data);
		strunzone(do_cvar);
	}
	if(!do_exec && !do_cvar)
		print(data);
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
		GameCommand_Generic("help");
		return;
	}

	if(GameCommand_Generic(theCommand))
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
		m_goto_skin_selector();
		return;
	}

	if(argv(0) == "languageselect")
	{
		m_goto_language_selector();
		return;
	}

	if(argv(0) == "videosettings")
	{
		m_goto_video_settings();
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
		float do_exec;
		string do_cvar;
		float key;
		float i, j;
		string url;
		float buf;
		float r;

		do_exec = FALSE;
		do_cvar = string_null;
		key = -1;

		for(i = 1; i+1 < argc; ++i)
		{
			if(argv(i) == "--cvar" && i+2 < argc)
			{
				++i;
				do_cvar = strzone(argv(i));
				continue;
			}
			if(argv(i) == "--exec")
			{
				do_exec = TRUE;
				continue;
			}
			if(argv(i) == "--key" && i+2 < argc)
			{
				++i;
				key = stof(argv(i));
				continue;
			}
			break;
		}

		// now, argv(i) is the URL
		// following args may be POST parameters
		url = argv(i);
		++i;
		buf = buf_create();
		j = 0;
		for(; i+1 < argc; i += 2)
			bufstr_set(buf, ++j, sprintf("%s=%s", uri_escape(argv(i)), uri_escape(argv(i+1))));
		if(i < argc)
			bufstr_set(buf, ++j, sprintf("submit=%s", uri_escape(argv(i))));

		if(j == 0) // no args: GET
			r = crypto_uri_postbuf(url, URI_GET_CURL + curl_uri_get_pos, string_null, string_null, -1, key);
		else // with args: POST
			r = crypto_uri_postbuf(url, URI_GET_CURL + curl_uri_get_pos, "application/x-www-form-urlencoded", "&", buf, key);

		if(r)
		{
			curl_uri_get_exec[curl_uri_get_pos] = do_exec;
			curl_uri_get_cvar[curl_uri_get_pos] = do_cvar;
			curl_uri_get_pos = mod(curl_uri_get_pos + 1, URI_GET_CURL_END - URI_GET_CURL + 1);
		}
		else
			print(_("error creating curl handle\n"));

		buf_del(buf);

		return;
	}

	print(_("Invalid command. For a list of supported commands, try menu_cmd help.\n"));
}
