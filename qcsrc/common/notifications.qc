// =====================
//  Notification System
// =====================
// main types/groups of notifications
#define MSG_INFO 1 // information messages (sent to console)
#define MSG_NOTIFY 2 // events to be sent to the notification panel
#define MSG_CENTER 3 // centerprint messages
#define MSG_WEAPON 4 // weapon messages (like "You got the Nex", sent to weapon notify panel)

// collapse multiple arguments into one argument
#define CLPS3(arg1,arg2,arg3) arg1, arg2, arg3
#define CLPS2(arg1,arg2) arg1, arg2


// ===================
//  Notification List
// ===================
// List of all notifications (including identifiers and display information)
// Format: name, number, args, special, normal, gentle
// Specifications:
//    Name of notification
//    ID number of notification
//    Arguments for sprintf(string, args), if no args needed then use ""
//    Special:
//      MSG_INFO: NULL/FLOAT: leave as FALSE
//      MSG_NOTIFY: STRING: icon string name for the hud notify panel, "" if no icon is used
//      MSG_CENTER: FLOAT: centerprint ID number (CPID_*), FALSE if no CPID is needed
//      MSG_WEAPON: NULL/FLOAT: leave as FALSE
//    Normal message (string for sprintf when gentle messages are NOT enabled)
//    Gentle message (string for sprintf when gentle messages ARE enabled)
//
// Messages have ^FG1, ^FG2, and ^BG in them-- these are replaced
// with colors according to the cvars the user has chosen.
//    ^FG1 = highest priority, "primary"
//    ^FG2 = next highest priority, "secondary"
//    ^BG = less important information, "tertiary"

#define MSG_INFO_NOTIFICATIONS \
	NOTIFICATION(DEATH_MARBLES_LOST, 1, CLPS3(s1, s2, s3), "notify_death", _("^FG1%s^BG lost their marbles against ^FG1%s^BG using the ^FG2%s^BG\n"), "") \
	/* nothing */

#define MSG_NOTIFY_NOTIFICATIONS \
	NOTIFICATION(DEATH_MARBLES_LOST2, 1, CLPS3(s1, s2, s3), "notify_death", _("^FG1%s^BG lost their marbles against ^FG1%s^BG using the ^FG2%s^BG\n"), "") \
	/* nothing */

#define MSG_CENTER_NOTIFICATIONS \
	NOTIFICATION(CENTER_CTF_CAPTURESHIELD_SHIELDED, 1, "", xCPID_CTF_CAPTURESHIELD, _("^BGYou are now ^FG1shielded^BG from the flag\n^BGfor ^FG2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "") \
	NOTIFICATION(CENTER_CTF_CAPTURESHIELD_FREE, 2, "", xCPID_CTF_CAPTURESHIELD, _("^BGYou are now free.\n^BGFeel free to ^FG2try to capture^BG the flag again\n^BGif you think you will succeed."), "") \
	NOTIFICATION(CENTER_CTF_EVENT_RETURN, 11, s1, CPID_CTF_LOWPRIO, _("^BGYou returned the ^FG1%s"), "") \
	NOTIFICATION(CENTER_CTF_EVENT_CAPTURE, 11, s1, FALSE, _("^BGYou captured the ^FG1%s"), "") \
	NOTIFICATION(CENTER_CTF_EVENT_PASS, 10, CLPS2(s1, s2, s3), CPID_CTF_PASS, _("^BG%s passed the ^FG1%s^BG to %s"), "") \
	NOTIFICATION(CENTER_CTF_EVENT_PASS_SENT, 11, CLPS2(s1, s2), CPID_CTF_PASS, _("^BGYou passed the ^FG1%s^BG to %s"), "") \
	NOTIFICATION(CENTER_CTF_EVENT_PASS_RECEIVED, 12, CLPS2(s1, s2), CPID_CTF_PASS, _("^BGYou received the ^FG1%s^BG from %s"), "") \
	/* nothing */

#define MSG_WEAPON_NOTIFICATIONS \
	NOTIFICATION(DEATH_MARBLES_LOST3, 1, CLPS3(s1, s2, s3), "notify_death", _("^FG1%s^BG lost their marbles against ^FG1%s^BG using the ^FG2%s^BG\n"), "") \
	/* nothing */

// declare notifications
#define NOTIFICATION(name,num,args,special,normal,gentle) float name = num;
MSG_INFO_NOTIFICATIONS
MSG_NOTIFY_NOTIFICATIONS
MSG_CENTER_NOTIFICATIONS
MSG_WEAPON_NOTIFICATIONS
#undef NOTIFICATION


#ifdef CSQC
// declare centerprint priorities
#define NOTIFICATION(name,num,args,special,normal,gentle) float special = num;
MSG_CENTER_NOTIFICATIONS
#undef

void readnotificationorwhatever()
{
	//stuff and things
}
#endif


// ================
//  
#ifdef SVQC
//#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
//#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
//#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0

void Send_Notification(float type, entity client, float id, string s, float duration, float countdown_num)
{
	if ((clienttype(client) == CLIENTTYPE_REAL) && (client.flags & FL_CLIENT))
	{
		msg_entity = client;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			//WriteByte(MSG_ONE, TE_CSQC_NOTIFICATION);
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
#endif
