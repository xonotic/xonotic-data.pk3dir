// ==========================
//  Balance Config Generator
// ==========================

void W_Config_Queue_Swap(float root, float child, entity pass)
{
	string oldroot = wep_config_queue[root];
	wep_config_queue[root] = wep_config_queue[child];
	wep_config_queue[child] = oldroot;
}

float W_Config_Queue_Compare(float root, float child, entity pass)
{
	float i, r, c;

	for(i = 1; i <= 100; ++i)
	{
		r = str2chr(wep_config_queue[root], i);
		c = str2chr(wep_config_queue[child], i);
		if(r == c) { continue; }
		else if(c > r) { return -1; }
		else { return 1; }
	}
	
	return 0;
}

void Dump_Weapon_Settings(void)
{
	float i, x;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		// step 1: clear the queue
		WEP_CONFIG_COUNT = 0;
		for(x = 0; x <= MAX_WEP_CONFIG; ++x)
			{ wep_config_queue[x] = string_null; }

		// step 2: build new queue
		WEP_ACTION(i, WR_CONFIG);

		// step 3: sort queue
		heapsort(WEP_CONFIG_COUNT, W_Config_Queue_Swap, W_Config_Queue_Compare, world);
		
		// step 4: write queue
		WEP_CONFIG_WRITETOFILE(sprintf("// {{{ #%d: %s\n// %d settings\n", i, W_Name(i), WEP_CONFIG_COUNT))
		for(x = 0; x <= WEP_CONFIG_COUNT; ++x)
			{ WEP_CONFIG_WRITETOFILE(wep_config_queue[x]) }
		WEP_CONFIG_WRITETOFILE("// }}}\n")
	}
}
	/*
	 * float WEP_CONFIG_COUNT;
string wep_config_queue[MAX_WEP_CONFIG];
	#define WEP_BAL_WRITE(a) { \
		fputs(fh, a); \
		if(alsoprint) { print(a); } }
	#define WEP_BAL_WRITE_ENTITY(description) { \
		notif_msg = \
			sprintf( \
				"seta notification_%s \"%d\" \"%s\"\n", \
				e.nent_name, e.nent_default, description \
			); \
		WEP_BAL_WRITE(notif_msg) }
	#define WEP_BAL_WRITE_HARDCODED(cvar,default,description) { \
		notif_msg = \
			sprintf( \
				"seta notification_%s \"%s\" \"%s\"\n", \
				cvar, default, description \
			); \
		WEP_BAL_WRITE(notif_msg) }

	string notif_msg;
	float i;
	entity e;

	NOTIF_WRITE(sprintf("\n// MSG_ANNCE notifications (count = %d):\n", NOTIF_ANNCE_COUNT));
	for(i = 1; i <= NOTIF_ANNCE_COUNT; ++i)
	{
		e = Get_Notif_Ent(MSG_ANNCE, i);
		if not(e) { backtrace("Dump_Notifications(): Missing notification entity!\n"); return; }
		
		NOTIF_WRITE_ENTITY(
			"Notification control cvar: 0 = disabled, 1 = enabled if gentle mode is off, 2 = always enabled)"
		);
	}

	NOTIF_WRITE(sprintf("\n// MSG_INFO notifications (count = %d):\n", NOTIF_INFO_COUNT));
	for(i = 1; i <= NOTIF_INFO_COUNT; ++i)
	{
		e = Get_Notif_Ent(MSG_INFO, i);
		if not(e) { backtrace("Dump_Notifications(): Missing notification entity!\n"); return; }
		
		NOTIF_WRITE_ENTITY(
			"Notification control cvar: 0 = off, 1 = print to console, "
			"2 = print to console and chatbox (if notification_allow_chatboxprint is enabled)"
		);
	}

	NOTIF_WRITE(sprintf("\n// MSG_CENTER notifications (count = %d):\n", NOTIF_CENTER_COUNT));
	for(i = 1; i <= NOTIF_CENTER_COUNT; ++i)
	{
		e = Get_Notif_Ent(MSG_CENTER, i);
		if not(e) { backtrace("Dump_Notifications(): Missing notification entity!\n"); return; }
		
		NOTIF_WRITE_ENTITY(
			"Notification control cvar: 0 = off, 1 = centerprint"
		);
	}

	NOTIF_WRITE(sprintf("\n// MSG_MULTI notifications (count = %d):\n", NOTIF_MULTI_COUNT));
	for(i = 1; i <= NOTIF_MULTI_COUNT; ++i)
	{
		e = Get_Notif_Ent(MSG_MULTI, i);
		if not(e) { backtrace("Dump_Notifications(): Missing notification entity!\n"); return; }
		
		NOTIF_WRITE_ENTITY(
			"Notification control cvar: 0 = off, 1 = trigger subcalls"
		);
	}

	// edit these to match whichever cvars are used for specific notification options
	NOTIF_WRITE("\n// HARD CODED notification variables:\n");
	
	NOTIF_WRITE_HARDCODED(
		"allow_chatboxprint", "1",
		"Allow notifications to be printed to chat box by setting notification cvar to 2 "
		"(You can also set this cvar to 2 to force ALL notifications to be printed to the chatbox)"
	);

	NOTIF_WRITE(sprintf(
		strcat(
			"\n// Notification counts (total = %d): ",
			"MSG_ANNCE = %d, MSG_INFO = %d, MSG_CENTER = %d, MSG_MULTI = %d\n"
		),
		(
			NOTIF_ANNCE_COUNT +
			NOTIF_INFO_COUNT +
			NOTIF_CENTER_COUNT +
			NOTIF_MULTI_COUNT
		),
		NOTIF_ANNCE_COUNT,
		NOTIF_INFO_COUNT,
		NOTIF_CENTER_COUNT,
		NOTIF_MULTI_COUNT
	));
	
	return;
	#undef NOTIF_WRITE_HARDCODED
	#undef NOTIF_WRITE_ENTITY
	#undef NOTIF_WRITE
}*/
