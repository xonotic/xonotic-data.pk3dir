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
// Format: type, name, number, args, special, normal, gentle
// Specifications:
//    Type of notification
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

#define NOTIFICATIONS \
	NOTIFICATION(MSG_NOTIFY, DEATH_MARBLES_LOST, 1, CLPS3(s1, s2, s3), "notify_death", _("^FG1%s^BG lost their marbles against ^FG1%s^BG using the ^FG2%s^BG\n"), "") \
	NOTIFICATION(MSG_CENTER, CENTER_CTF_CAPTURESHIELD_SHIELDED, 1, "", CPID_CTF_CAPTURESHIELD, _("^BGYou are now ^FG1shielded^BG from the flag\n^BGfor ^FG2too many unsuccessful attempts^BG to capture.\n\n^BGMake some defensive scores before trying again."), "") \
	/* nothing */

// declare notifications
#define NOTIFICATION(type,name,num,args,special,normal,gentle) float name = num;
NOTIFICATIONS
#undef NOTIFICATION


void testingthisshit()
{
	print("KILL_FRAG = ", ftos(KILL_FRAG), ".\n");


	return;
}
