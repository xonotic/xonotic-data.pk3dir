// ==========================
//  Balance Config Generator
// ==========================

void Dump_Weapon_Settings(float fh, float alsoprint)
{
	float i;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		WEP_ACTION(i, WR_CONFIG)
	}

			
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
}
