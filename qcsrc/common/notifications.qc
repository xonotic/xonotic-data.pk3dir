// ================================================
//  Unified notification system, written by Samual
//  Last updated: September, 2012
// ================================================

// main types/groups of notifications
#define MSG_INFO 1 // "Global" information messages (sent to console, and notify panel if it has an icon)
#define MSG_CENTER 2 // "Personal" centerprint messages
#define MSG_WEAPON 3 // "Personal" weapon messages (like "You got the Nex", sent to weapon notify panel)

#define NO_STR_ARG ""
#define NO_FL_ARG -12345

#define F_NAME 1
#define F_STRNUM 2
#define F_FLNUM 3

// allow sending of notifications to also pass through to spectators (specifically for centerprints)
#ifdef SVQC
#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0
#endif

#define NOTIF_MATCH(a,b) if(min(NOTIF_MAX, a) == b)
#ifdef CSQC
string got_commandkey;
#define ADD_CSQC_AUTOCVAR(name) var float autocvar_notification_##name = TRUE;
var float autocvar_notification_ctf_capture_verbose = TRUE;
var float autocvar_notification_ctf_pickup_team_verbose = TRUE;
var float autocvar_notification_ctf_pickup_enemy_verbose = TRUE;
#define CHECK_AUTOCVAR(name) if(autocvar_notification_##name)
#define HANDLE_CPID(cpid) ((min(NOTIF_MAX, cpid) == NO_CPID) ? FALSE : cpid)
#define PASS_KEY ((((got_commandkey = getcommandkey("pass", "+use")) != "pass") && !(strstrofs(got_commandkey, "not bound", 0) >= 0)) ? sprintf(CCR(_(" ^F1(Press %s)")), got_commandkey) : "")
#else
#define ADD_CSQC_AUTOCVAR(name)
#endif


// ====================================
//  Notifications List and Information
// ====================================
/*
 List of all notifications (including identifiers and display information)
 Format: name, strnum, flnum, args, *icon/CPID, *durcnt, normal, gentle
 Asterisked fields are not present in all notification types.
 Specifications:
    Name of notification
    Number of STRING arguments (so that networking knows how many to send/receive)
    Number of FLOAT arguments (so that networking knows how many to send/receive)
    Arguments for sprintf(string, args), if no args needed then use ""
    *Icon/CPID:
      MSG_INFO: STRING: icon string name for the hud notify panel, "" if no icon is used
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
    -ALWAYS start the string with a color, preferably background.
    -ALWAYS reset a color after a name (this way they don't set it for the whole string).
    -NEVER re-declare an event twice.
    -NEVER add or remove fields from the format, it SHOULD already work.
    -MSG_INFO messages must ALWAYS end with a new line: \n
    -Be clean and simple with your notification naming,
     nothing too long for the name field... Abbreviations are your friend. :D
    -Keep the spacing as clean as possible... if the arguments are abnormally long,
      it's okay to go out of line a bit... but try and keep it clean still.
    -Keep the notifications in alphabetical order.
    ARIRE unir frk jvgu lbhe bja zbgure. (gvc sbe zvxrrhfn) -- Don't pay attention to this ^_^
*/

// weaponorder[f1].netname

#define MULTITEAM_INFO(prefix,teams,strnum,flnum,args,hudargs,icon,normal,gentle) \
	MSG_INFO_NOTIF(prefix##RED, strnum, flnum, args, hudargs, sprintf(icon, strtolower(STR_TEAM_1)), TCR(normal, COL_TEAM_1, strtoupper(STR_TEAM_1)), TCR(gentle, COL_TEAM_1, strtoupper(STR_TEAM_1))) \
	MSG_INFO_NOTIF(prefix##BLUE, strnum, flnum, args, hudargs, sprintf(icon, strtolower(STR_TEAM_2)), TCR(normal, COL_TEAM_2, strtoupper(STR_TEAM_2)), TCR(gentle, COL_TEAM_2, strtoupper(STR_TEAM_2))) \
	#if teams >= 3 \
		MSG_INFO_NOTIF(prefix##YELLOW, strnum, flnum, args, hudargs, sprintf(icon, strtolower(STR_TEAM_3)), TCR(normal, COL_TEAM_3, strtoupper(STR_TEAM_3)), TCR(gentle, COL_TEAM_3, strtoupper(STR_TEAM_3))) \
	#endif \
	#if teams >= 4 \
		MSG_INFO_NOTIF(prefix##PINK, strnum, flnum, args, hudargs, sprintf(icon, strtolower(STR_TEAM_4)), TCR(normal, COL_TEAM_4, strtoupper(STR_TEAM_4)), TCR(gentle, COL_TEAM_4, strtoupper(STR_TEAM_4))) \
	#endif
#define MSG_INFO_NOTIFICATIONS \
	MSG_INFO_NOTIF(INFO_EMPTY,							0, 0, NO_STR_ARG, XPND2("", ""),					"", "", "") \
	MULTITEAM_INFO(INFO_SCORES_, 4,						0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^TC^TT ^BGteam scores!\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DROPPED_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^BGThe ^TC^TT^BG flag was dropped in the base and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DAMAGED_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^BGThe ^TC^TT^BG flag was destroyed and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_SPEEDRUN_, 2,	0, 1, f1/100, XPND2("", ""),						"", _("^BGThe ^TC^TT^BG flag became impatient after ^F1%.2f^BG seconds and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_NEEDKILL_, 2,	0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^BGThe ^TC^TT^BG flag fell somewhere it couldn't be reached and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_ABORTRUN_, 2,	0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^BGThe ^TC^TT^BG flag was returned to base by its owner\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_TIMEOUT_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"", _("^BGThe ^TC^TT^BG flag has returned to the base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_PICKUP_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_taken", _("^BG%s^BG got the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_RETURN_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_returned", _("^BG%s^BG returned the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_LOST_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_lost", _("^BG%s^BG lost the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_, 2,				1, 0, s1, XPND2(s1, ""),							"notify_%s_captured", _("^BG%s^BG captured the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_TIME_, 2,			1, 1, XPND2(s1, f1/100), XPND2(s1, ""),				"notify_%s_captured", _("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_BROKEN_, 2,			2, 2, XPND4(s1, f1/100, s2, f2/100), XPND2(s1, ""),	"notify_%s_captured", _("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds, breaking ^BG%s^BG's previous record of ^F2%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_UNBROKEN_, 2,		2, 2, XPND4(s1, f1/100, s2, f2/100), XPND2(s1, ""),	"notify_%s_captured", _("^BG%s^BG captured the ^TC^TT^BG flag in ^F2%.2f^BG seconds, failing to break ^BG%s^BG's previous record of ^F1%.2f^BG seconds\n"), "") \
	#undef MSG_INFO_NOTIF

#define MULTITEAM_CENTER(prefix,teams,strnum,flnum,args,cpid,durcnt,normal,gentle) \
	MSG_CENTER_NOTIF(prefix##RED, strnum, flnum, args, cpid, durcnt, TCR(normal, COL_TEAM_1, strtoupper(STR_TEAM_1)), TCR(gentle, COL_TEAM_1, strtoupper(STR_TEAM_1))) \
	MSG_CENTER_NOTIF(prefix##BLUE, strnum, flnum, args, cpid, durcnt, TCR(normal, COL_TEAM_2, strtoupper(STR_TEAM_2)), TCR(gentle, COL_TEAM_2, strtoupper(STR_TEAM_2))) \
	#if teams >= 3 \
		MSG_CENTER_NOTIF(prefix##YELLOW, strnum, flnum, args, cpid, durcnt, TCR(normal, COL_TEAM_3, strtoupper(STR_TEAM_3)), TCR(gentle, COL_TEAM_3, strtoupper(STR_TEAM_3))) \
	#endif \
	#if teams >= 4 \
		MSG_CENTER_NOTIF(prefix##PINK, strnum, flnum, args, cpid, durcnt, TCR(normal, COL_TEAM_4, strtoupper(STR_TEAM_4)), TCR(gentle, COL_TEAM_4, strtoupper(STR_TEAM_4))) \
	#endif
#define MSG_CENTER_NOTIFICATIONS \
	MSG_CENTER_NOTIF(CENTER_EMPTY,							0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), "", "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_SHIELDED,		0, 0, NO_STR_ARG, 				CPID_CTF_CAPSHIELD,		XPND2(0, 0), _("^BGYou are now ^F1shielded^BG from the flag\n^BGfor ^F2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_FREE, 		0, 0, NO_STR_ARG, 				CPID_CTF_CAPSHIELD,		XPND2(0, 0), _("^BGYou are now free.\n^BGFeel free to ^F2try to capture^BG the flag again\n^BGif you think you will succeed."), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_OTHER_, 2,				2, 0, XPND2(s1, s2),			CPID_CTF_PASS, 			XPND2(0, 0), _("^BG%s^BG passed the ^TC^TT^BG flag to %s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_SENT_, 2,				1, 0, s1, 						CPID_CTF_PASS, 			XPND2(0, 0), _("^BGYou passed the ^TC^TT^BG flag to %s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_RECEIVED_, 2,			1, 0, s1, 						CPID_CTF_PASS, 			XPND2(0, 0), _("^BGYou received the ^TC^TT^BG flag from %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PASS_REQUESTING,			1, 0, s1,						CPID_CTF_PASS,			XPND2(0, 0), _("^BGRequesting %s^BG to pass you the flag"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PASS_REQUESTED, 			1, 0, XPND2(s1, PASS_KEY),		CPID_CTF_PASS,			XPND2(0, 0), _("^BG%s^BG requests you to pass the flag%s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_RETURN_, 2,					0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPND2(0, 0), _("^BGYou returned the ^TC^TT^BG flag!"), "") \
	MULTITEAM_CENTER(CENTER_CTF_CAPTURE_, 2,				0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPND2(0, 0), _("^BGYou captured the ^TC^TT^BG flag!"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PICKUP_, 2,					0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPND2(0, 0), _("^BGYou got the ^TC^TT^BG flag!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_TEAM,				1, 0, s1,						CPID_CTF_LOWPRIO,		XPND2(0, 0), _("^BGYour %steam mate^BG got the flag! Protect them!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_TEAM_VERBOSE,		2, 0, XPND3(s1, s2, s1),		CPID_CTF_LOWPRIO,		XPND2(0, 0), _("^BGYour %steam mate (^BG%s%s)^BG got the flag! Protect them!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_ENEMY,				1, 0, s1,						CPID_CTF_LOWPRIO,		XPND2(0, 0), _("^BGThe %senemy^BG got your flag! Retrieve it!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_ENEMY_VERBOSE,		2, 0, XPND3(s1, s2, s1),		CPID_CTF_LOWPRIO,		XPND2(0, 0), _("^BGThe %senemy (^BG%s%s)^BG got your flag! Retrieve it!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_STALEMATE_CARRIER,			0, 0, NO_STR_ARG,				CPID_STALEMATE,			XPND2(0, 0), _("^BGStalemate! Enemies can now see you on radar!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_STALEMATE_OTHER,			0, 0, NO_STR_ARG,				CPID_STALEMATE,			XPND2(0, 0), _("^BGStalemate! Flag carriers can now be seen by enemies on radar!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_FLAG_THROW_PUNISH,			0, 1, f1,						CPID_CTF_LOWPRIO,		XPND2(0, 0), _("^BGToo many flag throws! Throwing disabled for %d seconds."), "") \
	MSG_CENTER_NOTIF(CENTER_EMPTY,							0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), "", "") \
	#undef MSG_CENTER_NOTIF

#define MSG_WEAPON_NOTIFICATIONS \
	MSG_WEAPON_NOTIF(DEATH_MARBLES_LOST3, 2, 1, XPND3(s1, s2, f1), _("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "") \
	#undef MSG_WEAPON_NOTIF


// ====================================
//  Initialization/Create Declarations
// ====================================

#define NOTIF_FIRST 1
#define NOTIF_MAX 1024 // limit of recursive functions with ACCUMULATE_FUNCTION
float NOTIF_INFO_COUNT;
float NOTIF_CENTER_COUNT;
float NOTIF_WEAPON_COUNT;
float NOTIF_CPID_COUNT;

#define MSG_INFO_NOTIF(name,strnum,flnum,args,icon,normal,gentle) \
	ADD_CSQC_AUTOCVAR(name) \
	float name; \
	void RegisterNotification_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_INFO_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_INFO_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(RegisterNotifications, RegisterNotification_##name)

#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) \
	ADD_CSQC_AUTOCVAR(name) \
	float name; \
	float cpid; \
	void RegisterNotification_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_CENTER_COUNT) \
		SET_FIELD_COUNT(cpid, NOTIF_FIRST, NOTIF_CPID_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_CENTER_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(RegisterNotifications, RegisterNotification_##name)

#define MSG_WEAPON_NOTIF(name,strnum,flnum,args,normal,gentle) \
	ADD_CSQC_AUTOCVAR(name) \
	float name; \
	void RegisterNotification_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_WEAPON_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_WEAPON_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(RegisterNotifications, RegisterNotification_##name)

// NOW we actually activate the declarations
MSG_INFO_NOTIFICATIONS
MSG_CENTER_NOTIFICATIONS
MSG_WEAPON_NOTIFICATIONS


// ======================
//  Supporting Functions
// ======================

// select between the normal or the gentle message string based on client (or server) settings
string normal_or_gentle(string normal, string gentle)
{
	#ifndef MENUQC
		#ifdef CSQC
		if(autocvar_cl_gentle || autocvar_cl_gentle_messages)
		#else
		if(autocvar_sv_gentle)
		#endif
			return ((gentle != "") ? gentle : normal);
		else
			return normal;
	#else
		return normal;
	#endif
}

float notif_stringcount(string s1, string s2)
{
	float stringcount;
	if(s1 != NO_STR_ARG) ++stringcount;
	if(s2 != NO_STR_ARG) ++stringcount;
	return stringcount;
}

float notif_floatcount(float f1, float f2, float f3)
{
	float floatcount;
	if(f1 != NO_FL_ARG) ++floatcount;
	if(f2 != NO_FL_ARG) ++floatcount;
	if(f3 != NO_FL_ARG) ++floatcount;
	return floatcount;
}

// get the actual name of a notification and return it as a string
string Get_Field_Value(float field, float net_type, float net_name)
{
	string output;
	
	#define GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) \
		if(field == F_NAME) { output = VAR_TO_TEXT(name); } \
		else if(field == F_STRNUM) { output = ftos(strnum); } \
		else if(field == F_FLNUM) { output = ftos(flnum); }
	
	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) } }
			MSG_INFO_NOTIFICATIONS
			break;
		}
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) } }
			MSG_CENTER_NOTIFICATIONS
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,strnum,flnum,args,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) } }
			MSG_WEAPON_NOTIFICATIONS
			break;
		}
	}

	#undef GET_FIELD_VALUE_OUTPUT
	return output;
}

// team code replace
string TCR(string input, string teamcolor, string teamtext)
{
	input = strreplace("^TC", teamcolor, input);
	input = strreplace("^TT", teamtext, input);
	return input;
}

// color code replace, place inside of sprintf and parse the string
string CCR(string input)
{
	input = strreplace("^F1", "^2", input); // autocvar_notification_colors_F1 
	input = strreplace("^F2", "^3", input); // autocvar_notification_colors_F2
	input = strreplace("^K1", "^1", input); // autocvar_notification_colors_K1
	input = strreplace("^K2", "^3", input); // autocvar_notification_colors_K2
	input = strreplace("^BG", "^7", input); // autocvar_notification_colors_BG
	input = strreplace("^N", "^7", input); // "none"-- reset to white
	return input;
}


// =============================
//  Debug/Maintenance Functions
// =============================

#define NOTIF_Write(type,name,text) fputs(fh, (sprintf("seta %s 1 // %s - %s\n", name, type, strreplace("\n", "\\n", text))))
void Dump_Notifications(float fh)
{
	#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) { NOTIF_Write("MSG_INFO", VAR_TO_TEXT(name), normal); }
	#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) { NOTIF_Write("MSG_CENTER", VAR_TO_TEXT(name), normal); }
	#define MSG_WEAPON_NOTIF(name,strnum,flnum,args,normal,gentle) { NOTIF_Write("MSG_WEAPON", VAR_TO_TEXT(name), normal); }
	MSG_INFO_NOTIFICATIONS
	MSG_CENTER_NOTIFICATIONS
	MSG_WEAPON_NOTIFICATIONS
	return;
}


// ===============================
//  Frontend Notification Pushing
// ===============================

#ifdef CSQC
#define KN_MAX_ENTRIES 10
float kn_index;
float killnotify_times[KN_MAX_ENTRIES];
string killnotify_icon[KN_MAX_ENTRIES];
string killnotify_attackers[KN_MAX_ENTRIES];
string killnotify_victims[KN_MAX_ENTRIES];
// 0 = "Y [used by] X", 1 = "X [did action to] Y"
void HUD_Notify_Push(string icon, string attacker, string victim)
{
	if(icon != "")
	{
		--kn_index;
		if (kn_index == -1) { kn_index = KN_MAX_ENTRIES-1; }
		killnotify_times[kn_index] = time;

		// icon
		if(killnotify_icon[kn_index]) { strunzone(killnotify_icon[kn_index]); }
		killnotify_icon[kn_index] = strzone(icon);

		// attacker
		if(killnotify_attackers[kn_index]) { strunzone(killnotify_attackers[kn_index]); }
		killnotify_attackers[kn_index] = strzone(attacker);

		// victim
		if(killnotify_victims[kn_index]) { strunzone(killnotify_victims[kn_index]); }
		killnotify_victims[kn_index] = strzone(victim);
	}
}

void Local_Notification(float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); \
					if(strtolower(icon) != "") { HUD_Notify_Push(icon, hudargs); } \
				} }
			MSG_INFO_NOTIFICATIONS
			break;
		}
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					centerprint_generic(HANDLE_CPID(cpid), sprintf(CCR(normal_or_gentle(normal, gentle)), args), durcnt); \
				} }
			MSG_CENTER_NOTIFICATIONS
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,strnum,flnum,args,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					print("unhandled\n"); \
				} }
			MSG_WEAPON_NOTIFICATIONS
			break;
		}
	}
}
#endif


// =========================
//  Notification Networking
// =========================

#ifdef CSQC
void Read_Notification(void)
{
	float net_type = ReadByte();
	float net_name = ReadShort();

	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
	
	Local_Notification(net_type, net_name,
		((stringcount >= 1) ? ReadString() : ""),
		((stringcount == 2) ? ReadString() : ""),
		((floatcount >= 1) ? ReadLong() : 0),
		((floatcount >= 2) ? ReadLong() : 0),
		((floatcount == 3) ? ReadLong() : 0));
}
#endif

#ifdef SVQC
void Send_Notification(entity client, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	if(net_type && net_name)
	{
		//print("notification: ", Get_Field_Value(F_NAME, net_type, net_name), ": ", ftos(net_name), ".\n");

		float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
		
		if(notif_stringcount(s1, s2) > stringcount) { backtrace("Too many string arguments for notification!\n"); return; }
		if(notif_floatcount(f1, f2, f3) > floatcount) { backtrace("Too many float arguments for notification!\n"); return; }
		
		if(client && (clienttype(client) == CLIENTTYPE_REAL) && (client.flags & FL_CLIENT))
		{
			// personal/direct notification sent to ONE person and their spectators
			msg_entity = client;
			WRITESPECTATABLE_MSG_ONE({
				WriteByte(MSG_ONE, SVC_TEMPENTITY);
				WriteByte(MSG_ONE, TE_CSQC_NOTIFICATION);
				WriteByte(MSG_ONE, net_type);
				WriteShort(MSG_ONE, net_name);
				if(stringcount >= 1) { WriteString(MSG_ONE, s1); }
				if(stringcount == 2) { WriteString(MSG_ONE, s2); }
				if(floatcount >= 1) { WriteLong(MSG_ONE, f1); }
				if(floatcount >= 2) { WriteLong(MSG_ONE, f2); }
				if(floatcount == 3) { WriteLong(MSG_ONE, f3); }
			});
		}
		else
		{
			// global notification sent to EVERYONE
			WriteByte(MSG_ALL, SVC_TEMPENTITY);
			WriteByte(MSG_ALL, TE_CSQC_NOTIFICATION);
			WriteByte(MSG_ALL, net_type);
			WriteShort(MSG_ALL, net_name);
			if(stringcount >= 1) { WriteString(MSG_ALL, s1); }
			if(stringcount == 2) { WriteString(MSG_ALL, s2); }
			if(floatcount >= 1) { WriteLong(MSG_ALL, f1); }
			if(floatcount >= 2) { WriteLong(MSG_ALL, f2); }
			if(floatcount == 3) { WriteLong(MSG_ALL, f3); }
		}

		if(!server_is_local && (net_type == MSG_INFO))
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } }
			MSG_INFO_NOTIFICATIONS
		}
	}
	else { backtrace("Incorrect usage of Send_Notification!\n"); }
}

void Send_Notification_ToTeam(float targetteam, entity except, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if(tmp_entity.classname == STR_PLAYER)
		if(tmp_entity.team == targetteam)
		if(tmp_entity != except)
		{
			Send_Notification(tmp_entity, net_type, net_name, s1, s2, f1, f2, f3);
		}
	}
}

// WARNING: use this ONLY if you need exceptions or want to exclude spectators, otherwise use Send_Notification(..., world, ...)
void Send_Notification_ToAll(entity except, float spectators, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if((tmp_entity.classname == STR_PLAYER) || spectators)
		if(tmp_entity != except)
		{
			Send_Notification(tmp_entity, net_type, net_name, s1, s2, f1, f2, f3);
		}
	}
}


// =============================
//  LEGACY NOTIFICATION SYSTEMS
// =============================

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
