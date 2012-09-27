// ================================================
//  Unified notification system, written by Samual
//  Last updated: September, 2012
// ================================================

// main types/groups of notifications
#define MSG_INFO 1 // "Global" information messages (sent to console)
#define MSG_NOTIFY 2 // "Global" events to be sent to the notification panel
#define MSG_CENTER 3 // "Personal" centerprint messages
#define MSG_WEAPON 4 // "Personal" weapon messages (like "You got the Nex", sent to weapon notify panel)

// expand multiple arguments into one argument
#define XPND4(a,b,c,d) a, b, c, d
#define XPND3(a,b,c) a, b, c
#define XPND2(a,b) a, b

// allow sending of notifications to also pass through to spectators (specifically for centerprints)
#ifdef SVQC
#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0
#endif

#define HANDLE_CPID(cpid) ((min(NOTIF_MAX, cpid) == NO_CPID) ? FALSE : cpid)
#define NOTIF_MATCH(a,b) if(min(NOTIF_MAX, a) == b)


// ====================================
//  Notifications List and Information
// ====================================
/*
 List of all notifications (including identifiers and display information)
 Format: name, args, *icon/CPID, *durcnt, normal, gentle
 Asterisked fields are not present in all notification types.
 Specifications:
    Name of notification
    Arguments for sprintf(string, args), if no args needed then use ""
    *Icon/CPID:
      MSG_NOTIFY: STRING: icon string name for the hud notify panel, "" if no icon is used
      MSG_CENTER: FLOAT: centerprint ID number (CPID_*), NO_CPID if no CPID is needed
    *Duration/Countdown:
      MSG_CENTER: XPND2(FLOAT, FLOAT): extra arguments for centerprint messages
    Normal message (string for sprintf when gentle messages are NOT enabled)
    Gentle message (string for sprintf when gentle messages ARE enabled)

 Messages have ^F1, ^F2, and ^BG in them-- these are replaced
 with colors according to the cvars the user has chosen.
    ^F1 = highest priority, "primary"
    ^F2 = next highest priority, "secondary"
    ^BG = normal/less important priority, "tertiary"

 Guidlines (please try and follow these):
    ALWAYS start the string with a color, preferably background.
    ALWAYS end messages with a new line.
    ALWAYS properly use tab spacing to even out the notifications.
    NEVER re-declare an event twice.
    NEVER add or remove fields from the format, it SHOULD already work.
    ARIRE unir frk jvgu lbhe bja zbgure. (gvc sbe zvxrrhfn) -- Don't pay attention to this ^_^
    Be clean and simple with your notification naming, nothing too long.
    Keep the notifications in alphabetical order.
*/
#define MSG_INFO_NOTIFICATIONS \
	MSG_INFO_NOTIF(DEATH_MARBLES_LOST, XPND3(s1, s2, s3), _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_INFO_NOTIF

#define MSG_NOTIFY_NOTIFICATIONS \
	MSG_NOTIFY_NOTIF(DEATH_MARBLES_LOST2, XPND3(s1, s2, s3), "notify_death", _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_NOTIFY_NOTIF

#define MSG_CENTER_NOTIFICATIONS \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_SHIELDED,		"", 				CPID_CTF_CAPTURESHIELD,	XPND2(0, 0), _("^BGYou are now ^F1shielded^BG from the flag\n^BGfor ^F2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_FREE, 		"", 				CPID_CTF_CAPTURESHIELD,	XPND2(0, 0), _("^BGYou are now free.\n^BGFeel free to ^F2try to capture^BG the flag again\n^BGif you think you will succeed."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS, 				XPND2(s1, s2, s3),	CPID_CTF_PASS, 			XPND2(0, 0), _("^BG%s passed the ^F1%s^BG to %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS_SENT, 			XPND2(s1, s2), 		CPID_CTF_PASS, 			XPND2(0, 0), _("^BGYou passed the ^F1%s^BG to %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS_RECEIVED, 		XPND2(s1, s2), 		CPID_CTF_PASS, 			XPND2(0, 0), _("^BGYou received the ^F1%s^BG from %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_RETURN, 				s1,					CPID_CTF_LOWPRIO, 		XPND2(0, 0), _("^BGYou returned the ^F1%s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_CAPTURE, 				s1,					NO_CPID, 				XPND2(0, 0), _("^BGYou captured the ^F1%s"), "") \
	#undef MSG_CENTER_NOTIF

#define MSG_WEAPON_NOTIFICATIONS \
	MSG_WEAPON_NOTIF(DEATH_MARBLES_LOST3, XPND3(s1, s2, s3), _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_WEAPON_NOTIF


// ====================================
//  Initialization/Create Declarations
// ====================================

#define NOTIF_FIRST 1
#define NOTIF_MAX 1024 // limit of recursive functions with ACCUMULATE_FUNCTION
float NOTIF_INFO_COUNT;
float NOTIF_NOTIFY_COUNT;
float NOTIF_CENTER_COUNT;
float NOTIF_WEAPON_COUNT;
float NOTIF_CPID_COUNT;

#define MSG_INFO_NOTIF(name,args,normal,gentle) \
	float name; \
	void DecNotif_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_INFO_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_INFO_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_NOTIFY_NOTIF(name,args,icon,normal,gentle) \
	float name; \
	void DecNotif_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_NOTIFY_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_NOTIFY_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_CENTER_NOTIF(name,args,cpid,durcnt,normal,gentle) \
	float name; \
	float cpid; \
	void DecNotif_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_CENTER_COUNT) \
		SET_FIELD_COUNT(cpid, NOTIF_FIRST, NOTIF_CPID_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_CENTER_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_WEAPON_NOTIF(name,args,normal,gentle) \
	float name; \
	void DecNotif_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_WEAPON_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_WEAPON_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

// NOW we actually activate the declarations
MSG_INFO_NOTIFICATIONS
MSG_NOTIFY_NOTIFICATIONS
MSG_CENTER_NOTIFICATIONS
MSG_WEAPON_NOTIFICATIONS


// ======================
//  Supporting Functions
// ======================

// select between the normal or the gentle message string based on client (or server) settings
string normal_or_gentle(string normal, string gentle)
{
	#ifdef CSQC
	if(autocvar_cl_gentle || autocvar_cl_gentle_messages)
	#else
	if(autocvar_sv_gentle)
	#endif
		return ((gentle != "") ? gentle : normal);
	else
		return normal;
}

// get the actual name of a notification and return it as a string
string Get_Notif_Name(float net_type, float net_name)
{
	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,args,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { return VAR_TO_TEXT(name); } }
			MSG_INFO_NOTIFICATIONS
			break;
		}
		case MSG_NOTIFY:
		{
			#define MSG_NOTIFY_NOTIF(name,args,icon,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { return VAR_TO_TEXT(name); } }
			MSG_NOTIFY_NOTIFICATIONS
			break;
		}
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,args,cpid,durcnt,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { return VAR_TO_TEXT(name); } }
			MSG_CENTER_NOTIFICATIONS
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,args,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { return VAR_TO_TEXT(name); } }
			MSG_WEAPON_NOTIFICATIONS
			break;
		}
	}
	return "";
}

// color code replace, place inside of sprintf and parse the string
string CCR(string input)
{
	input = strreplace("^F1", "^3", input);
	input = strreplace("^F2", "^2", input);
	input = strreplace("^K1", "^1", input);
	input = strreplace("^K2", "^5", input);
	input = strreplace("^BG", "^7", input);

	input = strreplace("^N", "^7", input); // "none"-- reset to white

	return input;
}


// ===============================
//  Frontend Notification Pushing
// ===============================

#ifdef CSQC
void Local_Notification(float net_type, float net_name, string s1, string s2, string s3)
{
	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,args,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } }

			MSG_INFO_NOTIFICATIONS
			break;
		}
		case MSG_NOTIFY:
		{
			#define MSG_NOTIFY_NOTIF(name,args,icon,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { print("unhandled\n"); } }
				
			MSG_NOTIFY_NOTIFICATIONS
			break;
		}
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,args,cpid,durcnt,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { centerprint_generic(HANDLE_CPID(cpid), sprintf(CCR(normal_or_gentle(normal, gentle)), args), durcnt); } }

			MSG_CENTER_NOTIFICATIONS
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,args,normal,gentle) \
				{ NOTIF_MATCH(name,net_name) { print("unhandled\n"); } }
				
			MSG_WEAPON_NOTIFICATIONS
			break;
		}
	}
}
#endif


// =========================
//  Notification Networking
// =========================

#ifdef SVQC
void Send_Notification(float net_type, entity client, float net_name, string s1, string s2, string s3)
{
	if(net_type && net_name)
	{
		print("notification: ", Get_Notif_Name(net_type, net_name), ": ", ftos(net_name), ".\n");
		
		if(client && (clienttype(client) == CLIENTTYPE_REAL) && (client.flags & FL_CLIENT))
		{
			// personal/direct notification sent to ONE person and their spectators
			msg_entity = client;
			WRITESPECTATABLE_MSG_ONE({
				WriteByte(MSG_ONE, SVC_TEMPENTITY);
				WriteByte(MSG_ONE, TE_CSQC_NOTIFICATION);
				WriteShort(MSG_ONE, net_type);
				WriteCoord(MSG_ONE, net_name);
				WriteString(MSG_ONE, s1);
				WriteString(MSG_ONE, s2);
				WriteString(MSG_ALL, s3);
			});
		}
		else
		{
			// global notification sent to EVERYONE
			WriteByte(MSG_ALL, SVC_TEMPENTITY);
			WriteByte(MSG_ALL, TE_CSQC_NOTIFICATION);
			WriteShort(MSG_ALL, net_type);
			WriteCoord(MSG_ALL, net_name);
			WriteString(MSG_ALL, s1);
			WriteString(MSG_ALL, s2);
			WriteString(MSG_ALL, s3);
		}

		if(!server_is_local && ((net_type == MSG_INFO || net_type == MSG_NOTIFY) || client == world))
		{
			switch(net_type)
			{
				case MSG_INFO:
				{
					#define MSG_INFO_NOTIF(name,args,normal,gentle) \
						{ NOTIF_MATCH(name, net_name) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } }

					MSG_INFO_NOTIFICATIONS
					break;
				}

				case MSG_NOTIFY:
				{
					#define MSG_NOTIFY_NOTIF(name,args,icon,normal,gentle) \
						{ NOTIF_MATCH(name,net_name) { print("unhandled\n"); } }
				
					MSG_NOTIFY_NOTIFICATIONS
					break;
				}
			}
		}
	}
	else { backtrace("Incorrect usage of Send_Notification!\n"); }
}

void Send_Notification_ToTeam(float targetteam, entity except, float net_type, float net_name, string s1, string s2, string s3)
{
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if(tmp_entity.classname == STR_PLAYER)
		if(tmp_entity.team == targetteam)
		if(tmp_entity != except)
		{
			Send_Notification(net_type, tmp_entity, net_name, s1, s2, s3);
		}
	}
}

// use this ONLY if you need exceptions or want to exclude spectators, otherwise use Send_Notification(..., world, ...)
void Send_Notification_ToAll(entity except, float spectators, float net_type, float net_name, string s1, string s2, string s3)
{
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if((tmp_entity.classname == STR_PLAYER) || spectators)
		if(tmp_entity != except)
		{
			Send_Notification(net_type, tmp_entity, net_name, s1, s2, s3);
		}
	}
}

// LEGACY NOTIFICATION SYSTEMS
void Send_KillNotification(string s1, string s2, string s3, float msg, float type)
{
	WriteByte(MSG_ALL, SVC_TEMPENTITY);
	WriteByte(MSG_ALL, TE_CSQC_KILLNOTIFY);
	WriteString(MSG_ALL, s1);
	WriteString(MSG_ALL, s2);
	WriteString(MSG_ALL, s3);
	WriteShort(MSG_ALL, msg);
	WriteByte(MSG_ALL, type);
}

// Function is used to send a generic centerprint whose content CSQC gets to decide (gentle version or not in the below cases)
void Send_CSQC_KillCenterprint(entity e, string s1, string s2, float msg, float type)
{
	if (clienttype(e) == CLIENTTYPE_REAL)
	{
		msg_entity = e;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_KILLCENTERPRINT);
			WriteString(MSG_ONE, s1);
			WriteString(MSG_ONE, s2);
			WriteShort(MSG_ONE, msg);
			WriteByte(MSG_ONE, type);
		});
	}
}

void Send_CSQC_Centerprint_Generic(entity e, float id, string s, float duration, float countdown_num)
{
	if ((clienttype(e) == CLIENTTYPE_REAL) && (e.flags & FL_CLIENT))
	{
		msg_entity = e;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_CENTERPRINT_GENERIC);
			WriteByte(MSG_ONE, id);
			WriteString(MSG_ONE, s);
			if (id != 0 && s != "")
			{
				WriteByte(MSG_ONE, duration);
				WriteByte(MSG_ONE, countdown_num);
			}
		});
	}
}
void Send_CSQC_Centerprint_Generic_Expire(entity e, float id)
{
	Send_CSQC_Centerprint_Generic(e, id, "", 1, 0);
}
#endif
