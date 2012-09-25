// ================================================
//  Unified notification system, written by Samual
//  Last updated: September, 2012
// ================================================

// main types/groups of notifications
#define MSG_INFO 1 // information messages (sent to console)
#define MSG_NOTIFY 2 // events to be sent to the notification panel
#define MSG_CENTER 3 // centerprint messages
#define MSG_WEAPON 4 // weapon messages (like "You got the Nex", sent to weapon notify panel)

// collapse multiple arguments into one argument
#define CLPS4(arg1,arg2,arg3,arg4) arg1, arg2, arg3, arg4
#define CLPS3(arg1,arg2,arg3) arg1, arg2, arg3
#define CLPS2(s1,s2) s1, s2

// accumulate functions for declarations
#define NOTIF_FIRST 1
float NOTIF_INFO_COUNT;
float NOTIF_NOTIFY_COUNT;
float NOTIF_CENTER_COUNT;
float NOTIF_WEAPON_COUNT;
float NOTIF_CPID_COUNT;

#define MSG_INFO_NOTIF(name,args,normal,gentle) \
	float name; \
	void DecNotif_##name() { \
		if(!name) { \
			name = (NOTIF_FIRST + NOTIF_INFO_COUNT); \
			++NOTIF_INFO_COUNT; } } \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_NOTIFY_NOTIF(name,args,icon,normal,gentle) \
	float name; \
	void DecNotif_##name() { \
		if(!name) { \
			name = (NOTIF_FIRST + NOTIF_NOTIFY_COUNT); \
			++NOTIF_NOTIFY_COUNT; } } \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_CENTER_NOTIF(name,args,cpid,normal,gentle) \
	float name; \
	float cpid; \
	void DecNotif_##name() { \
		if(!name) { \
			name = (NOTIF_FIRST + NOTIF_CENTER_COUNT); \
			++NOTIF_CENTER_COUNT; } \
		if(!cpid) { \
			cpid = (NOTIF_FIRST + NOTIF_CPID_COUNT); \
			++NOTIF_CPID_COUNT; } } \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)

#define MSG_WEAPON_NOTIF(name,args,normal,gentle) \
	float name; \
	void DecNotif_##name() { \
		if(!name) { \
			name = (NOTIF_FIRST + NOTIF_WEAPON_COUNT); \
			++NOTIF_WEAPON_COUNT; } } \
	ACCUMULATE_FUNCTION(DecNotifs, DecNotif_##name)


// ====================================
//  Notifications List and Information
// ====================================
/*
 List of all notifications (including identifiers and display information)
 Format: name, number, args, icon/CPID, normal, gentle
 Specifications:
    Name of notification
    ID number of notification
    Arguments for sprintf(string, args), if no args needed then use ""
    Icon/CPID:
      MSG_NOTIFY: STRING: icon string name for the hud notify panel, "" if no icon is used
      MSG_CENTER: FLOAT: centerprint ID number (CPID_*), NO_CPID if no CPID is needed
    Normal message (string for sprintf when gentle messages are NOT enabled)
    Gentle message (string for sprintf when gentle messages ARE enabled)

 Messages have ^F1, ^F2, and ^BG in them-- these are replaced
 with colors according to the cvars the user has chosen.
    ^F1 = highest priority, "primary"
    ^F2 = next highest priority, "secondary"
    ^BG = normal/less important priority, "tertiary"

 Guidlines:
    ALWAYS start the string with a color, preferably background
    ALWAYS end messages with a new line
    ARIRE unir frk jvgu lbhe bja zbgure (gvc sbe zvxrrhfn)
*/
#define MSG_INFO_NOTIFICATIONS \
	MSG_INFO_NOTIF(DEATH_MARBLES_LOST, CLPS3(s1, s2, s3), _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_INFO_NOTIF

#define MSG_NOTIFY_NOTIFICATIONS \
	MSG_NOTIFY_NOTIF(DEATH_MARBLES_LOST2, CLPS3(s1, s2, s3), "notify_death", _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_NOTIFY_NOTIF

#define MSG_CENTER_NOTIFICATIONS \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_SHIELDED, "", CPID_CTF_CAPTURESHIELD, _("^BGYou are now ^F1shielded^BG from the flag\n^BGfor ^F2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_FREE, "", CPID_CTF_CAPTURESHIELD, _("^BGYou are now free.\n^BGFeel free to ^F2try to capture^BG the flag again\n^BGif you think you will succeed."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS, CLPS2(s1, s2, s3), CPID_CTF_PASS, _("^BG%s passed the ^F1%s^BG to %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS_SENT, CLPS2(s1, s2), CPID_CTF_PASS, _("^BGYou passed the ^F1%s^BG to %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_PASS_RECEIVED, CLPS2(s1, s2), CPID_CTF_PASS, _("^BGYou received the ^F1%s^BG from %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_RETURN, s1, CPID_CTF_LOWPRIO, _("^BGYou returned the ^F1%s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_EVENT_CAPTURE, s1, NO_CPID, _("^BGYou captured the ^F1%s"), "") \
	#undef MSG_CENTER_NOTIF

#define MSG_WEAPON_NOTIFICATIONS \
	MSG_WEAPON_NOTIF(DEATH_MARBLES_LOST3, CLPS3(s1, s2, s3), _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_WEAPON_NOTIF

// NOW we actually activate the declarations
MSG_INFO_NOTIFICATIONS
MSG_NOTIFY_NOTIFICATIONS
MSG_CENTER_NOTIFICATIONS
MSG_WEAPON_NOTIFICATIONS


// ======================
//  Supporting Functions
// ======================

#ifdef SVQC
#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0
#endif

string CCR(string input) // color code replace, place inside of sprintf and parse the string
{
	input = strreplace("^F1", "^3", input);
	input = strreplace("^F2", "^2", input);
	input = strreplace("^BG", "^7", input);

	input = strreplace("^N", "^7", input); // "none"-- reset to white

	return input;
}


// ===============================
//  Frontend Notification Pushing
// ===============================


// =========================
//  Notification Networking
// =========================

#ifdef CSQC
#define NORMAL_OR_GENTLE(normal,gentle) ((autocvar_cl_gentle || autocvar_cl_gentle_messages) ? gentle : normal)
#define HANDLE_CPID(cpid) ((min(256, cpid) == NO_CPID) ? FALSE : cpid)

void Read_Notification()
{
	float net_type = ReadByte();
	float net_name = ReadByte();
	string s1 = ReadString();
	string s2 = ReadString();
	string s3 = ReadString();

	switch(net_type)
	{
		case MSG_INFO:
		{
			break;
		}

		case MSG_NOTIFY:
		{
			break;
		}

		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,args,cpid,normal,gentle) \
				{ if(min(256, name) == net_name) { centerprint_generic(HANDLE_CPID(cpid), sprintf(CCR(NORMAL_OR_GENTLE(normal, gentle)), args), 0, 0); } }

			MSG_CENTER_NOTIFICATIONS
			break;
		}

		case MSG_WEAPON:
		{
			break;
		}
	}
}
#endif
#ifdef SVQC
void Send_Notification(float type, entity client, float id, string s, float duration, float countdown_num)
{
	//WriteByte(
	if((clienttype(client) == CLIENTTYPE_REAL) && (client.flags & FL_CLIENT))
	{
		msg_entity = client;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_NOTIFICATION);
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

// LEGACY NOTIFICATION SYSTEMS
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
