// ================================================
//  Unified notification system, written by Samual
//  Last updated: November, 2012
// ================================================

// main types/groups of notifications
#define MSG_INFO 1 // "Global" information messages (sent to console, and notify panel if it has an icon)
#define MSG_CENTER 2 // "Personal" centerprint messages
#define MSG_WEAPON 3 // "Personal" weapon messages (like "You got the Nex", sent to weapon notify panel)
#define MSG_DEATH 4 // "Personal" AND "Global" death messages 

#define NO_STR_ARG ""
#define NO_FL_ARG -12345
#define NO_MSG -12345

#define F_NAME 1
#define F_STRNUM 2
#define F_FLNUM 3

#define BOT_PING -1

// Since this is code uses macro processors to list notifications,
// the normal compiler sees these checks as "constant" and throws
// a warning. We have to get around this by using another function.
#define NOTIF_MATCH(a,b) if(min(NOTIF_MAX, a) == b)

#ifdef CSQC
/*
 Acquire special information to generate for display in the
 notification from variables networked to the client.
 Macro descriptions:
    PASS_KEY: find the keybind for "passing" or "dropping" in CTF game mode
    FRAG_SPREE: find out if the player is on a kill spree/how many kills they have
    FRAG_PING: show the ping of a player
    FRAG_STATS: show health/armor/ping of a player
    FRAG_POS: show score status and position in the match of a player
    DEATH_TEAM: show the full name of the team a player is switching from
*/
string got_commandkey;
#define PASS_KEY ((((got_commandkey = getcommandkey("pass", "+use")) != "pass") && !(strstrofs(got_commandkey, "not bound", 0) >= 0)) ? sprintf(CCR(_(" ^F1(Press %s)")), got_commandkey) : "")
#define FRAG_SPREE (((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d kill spree! "), _("%d score spree! ")), f1) : "")
#define FRAG_PING ((f2 != BOT_PING) ? sprintf(CCR(_("\n(Ping ^2%d^BG)")), f2) : "")
#define FRAG_STATS sprintf(CCR(_("\n(Health ^1%d^BG / Armor ^2%d^BG)%s")), f1, f2, ((f3 != BOT_PING) ? sprintf(CCR(_(" (Ping ^2%d^BG)")), f3) : ""))
//#define FRAG_POS ((Should_Print_Score_Pos(f1)) ? sprintf("\n^BG%s", Read_Score_Pos(f1)) : "")
#define DEATH_TEAM Team_ColoredFullName(TEAM_SV_TO_CL(f1))
#define WEAPON_NAME f1

// NO_CPID normally has a variable value, so we need to check and see
// whether a notification uses it. If so, cancel out the centerprint ID.
#define HANDLE_CPID(cpid) ((min(NOTIF_MAX, cpid) == NO_CPID) ? FALSE : cpid)

// client-side handling of cvars
#define ADD_CSQC_AUTOCVAR(name) var float autocvar_notification_##name = TRUE;
#define CHECK_AUTOCVAR(name) if(autocvar_notification_##name)
#else

// allow sending of notifications to also pass through to spectators (specifically for centerprints)
#ifdef SVQC
#define DEATH_TEAM Team_ColoredFullName(f1)
#define WEAPON_NAME f1

#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0
#endif

// do nothing for the other programs, they don't need cvars (those are just for the clients)
#define ADD_CSQC_AUTOCVAR(name)
#endif


/*
	If BELOW negative maxplayers, you dropped a place lower
	If below 0, you are tied for that place
	If above 0, you are holding that place alone
	If above positive maxplayers, you moved up a place
* 
float Should_Print_Score_Pos

string Read_Score_Pos(float num)
{
	
}

float Form_Score_Pos(entity player)
{
	return 
}*/

// ====================================
//  Notifications List and Information
// ====================================
/*(name,strnum,flnum,args,cpid,cennor,cengen,infargs,hudargs,icon,infnor,infgen)
 List of all notifications (including identifiers and display information)
 Possible Tokens: name, infoname, centername, strnum, flnum, args, hudargs, icon, cpid, durcnt, normal, gentle
 Format Specifications:
    MSG_INFO:
      name: VAR: Name of notification
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: MISC: Arguments for sprintf(string, args), if no args needed then use ""
      hudargs: XPND2(STRING, STRING): arguments for names in notify messages 
      icon: STRING: icon string name for the hud notify panel, "" if no icon is used
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_CENTER:
      name: VAR: Name of notification
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: MISC: Arguments for sprintf(string, args), if no args needed then use ""
      cpid: FLOAT: centerprint ID number (CPID_*), NO_CPID if no CPID is needed
      durcnt: XPND2(FLOAT, FLOAT): Duration/Countdown: extra arguments for centerprint messages
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_WEAPON:
    MSG_DEATH:
      name: VAR: Name of chaining notification
      infoname: VAR: Name of centerprint notification for reference
      centername: VAR: Name of info notification for reference

 Messages with ^F1, ^BG, ^TC, etc etc in them will replace those strings
 with colors according to the cvars the user has chosen. This allows for
 users to create unique color profiles for their HUD, giving more customization
 options to HUD designers and end users who want such a feature.

 Check out the function calls for string CCR(...) and
 string TCR(...) to better understand how these codes work.

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
    -Sort the notifications in the most appropriate order for their tasks.
      TODO: ? centerprint IDs are given priority based on their order (first being highest priority going downwards)
    -ARIRE unir frk jvgu lbhe bja zbgure. (gvc sbe zvxrrhfn) -- Don't pay attention to this ^_^
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
	MSG_INFO_NOTIF(INFO_EMPTY,							0, 0, NO_STR_ARG, XPND2("", ""),					"",						"", "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DROPPED_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^BGThe ^TC^TT^BG flag was dropped in the base and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DAMAGED_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^BGThe ^TC^TT^BG flag was destroyed and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_SPEEDRUN_, 2,	0, 1, f1/100, XPND2("", ""),						"",						_("^BGThe ^TC^TT^BG flag became impatient after ^F1%.2f^BG seconds and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_NEEDKILL_, 2,	0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^BGThe ^TC^TT^BG flag fell somewhere it couldn't be reached and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_ABORTRUN_, 2,	0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^BGThe ^TC^TT^BG flag was returned to base by its owner\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_TIMEOUT_, 2,		0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^BGThe ^TC^TT^BG flag has returned to the base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_PICKUP_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_taken",		_("^BG%s^BG got the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_RETURN_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_returned",	_("^BG%s^BG returned the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_LOST_, 2,					1, 0, s1, XPND2(s1, ""),							"notify_%s_lost",		_("^BG%s^BG lost the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_, 2,				1, 0, s1, XPND2(s1, ""),							"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_TIME_, 2,			1, 1, XPND2(s1, f1/100), XPND2(s1, ""),				"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_BROKEN_, 2,			2, 2, XPND4(s1, f1/100, s2, f2/100), XPND2(s1, ""),	"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds, breaking ^BG%s^BG's previous record of ^F2%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_UNBROKEN_, 2,		2, 2, XPND4(s1, f1/100, s2, f2/100), XPND2(s1, ""),	"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F2%.2f^BG seconds, failing to break ^BG%s^BG's previous record of ^F1%.2f^BG seconds\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_CUSTOM,				2, 0, XPND2(s1, s2), XPND2(s1, ""),					"notify_void",			_("^F1%s^K1 %s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_GENERIC,				1, 0, s1, XPND2(s1, ""),							"notify_void",			_("^F1%s^K1 was in the wrong place\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SELFKILL,			1, 0, s1, XPND2(s1, ""),							"notify_selfkill",		_("^F1%s^K1 died\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SUICIDE,				1, 0, s1, XPND2(s1, ""),							"notify_selfkill",		_("^F1%s^K1 couldn't take it anymore\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_NOAMMO,				1, 0, s1, XPND2(s1, ""),							"notify_outofammo",		_("^F1%s^K1 died. What's the point of living without ammo?\n"), _("^F1%s^K1 ran out of ammo\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_ROT,					1, 0, s1, XPND2(s1, ""),							"notify_death",			_("^F1%s^K1 rotted away\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_CAMP,				1, 0, s1, XPND2(s1, ""),							"notify_camping",		_("^F1%s^K1 thought they found a nice camping ground\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_BETRAYAL,			1, 1, s1, XPND2(s1, ""),							"notify_teamkill_red",	_("^F1%s^K1 became enemies with the Lord of Teamplay\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_TEAMCHANGE,			1, 1, XPND2(s1, DEATH_TEAM), XPND2("", ""),			"",						_("^F1%s^K1 switched to the %s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_AUTOTEAMCHANGE,		1, 1, XPND2(s1, DEATH_TEAM), XPND2("", ""),			"",						_("^F1%s^K1 was moved into the %s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_FALL,				1, 0, s1, XPND2(s1, ""),							"notify_fall",			_("^F1%s^K1 hit the ground with a crunch\n"), _("^F1%s^K1 hit the ground with a bit too much force\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_DROWN,				1, 0, s1, XPND2(s1, ""),							"notify_water",			_("^F1%s^K1 couldn't catch their breath\n"), _("^F1%s^K1 was in the water for too long\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_FIRE,				1, 0, s1, XPND2(s1, ""),							"notify_death",			_("^F1%s^K1 became a bit too crispy\n"), _("^F1%s^K1 felt a little hot\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_LAVA,				1, 0, s1, XPND2(s1, ""),							"notify_lava",			_("^F1%s^K1 turned into hot slag\n"), _("^F1%s^K1 found a hot place\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SLIME,				1, 0, s1, XPND2(s1, ""),							"notify_slime",			_("^F1%s^K1 was slimed\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SHOOTING_STAR,		1, 0, s1, XPND2(s1, ""),							"notify_shootingstar",	_("^F1%s^K1 became a shooting star\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SWAMP,				1, 0, s1, XPND2(s1, ""),							"notify_slime",			_("^F1%s^K1 is now conserved for centuries to come\n"), _("^F1%s^K1 discovered a swamp\n")) \
	MULTITEAM_INFO(INFO_SCORES_, 4,						0, 0, NO_STR_ARG, XPND2("", ""),					"",						_("^TC^TT ^BGteam scores!\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MARBLES_LOST, 			2, 1, XPND3(s1, s2, WEAPON_NAME), XPND2("", ""),	"",						_("^F1%s^BG lost their marbles against ^F1%s^BG using the ^F2%s^BG\n"), "")

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
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_CUSTOM,				2, 0, s2,						NO_CPID,				XPND2(0, 0), _("^K1You were %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_GENERIC,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1Watch your step!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SELFKILL,			0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You killed your own dumb self!"), _("^K1You need to be more careful!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SUICIDE,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You committed suicide!"), _("^K1You ended it all!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_NOAMMO,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You were killed for running out of ammo..."), _("^K1You are respawning for running out of ammo...")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_ROT,					0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You grew too old without taking your medicine"), _("^K1You need to preserve your health")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_CAMP,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1Die camper!"), _("^K1Reconsider your tactics, camper!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_BETRAYAL,			0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1Don't shoot your team mates!"), _("^K1Don't go against your team mates!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_TEAMCHANGE,			0, 1, DEATH_TEAM,				NO_CPID,				XPND2(0, 0), _("^BGYou are now on: %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_AUTOTEAMCHANGE,		0, 1, DEATH_TEAM,				NO_CPID,				XPND2(0, 0), _("^BGYou have been moved into a different team\nYou are now on: %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_FALL,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You hit the ground with a crunch!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_DROWN,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You couldn't catch your breath in time!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_FIRE,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You got a little bit too crispy!"), _("^K1You felt a little too hot!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_LAVA,				0, 0, NO_STR_ARG, 				NO_CPID,				XPND2(0, 0), _("^K1You couldn't stand the heat!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SLIME,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You melted away in slime!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SHOOTING_STAR,		0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You became a shooting star!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SWAMP,				0, 0, NO_STR_ARG,				NO_CPID,				XPND2(0, 0), _("^K1You got stuck in a swamp!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG,						1, 1, XPND2(FRAG_SPREE, s1),							NO_CPID, XPND2(0, 0), _("^K3%sYou fragged ^BG%s"), _("^K3%sYou scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED,					1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K1You were fragged by ^BG%s"), _("^K1You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG,					1, 1, XPND2(FRAG_SPREE, s1),							NO_CPID, XPND2(0, 0), _("^K1%sYou typefragged ^BG%s"), _("^K1%sYou scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED,				1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K1You were typefragged by ^BG%s"), _("^K1You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_FIRST,				1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K3First blood! You fragged ^BG%s"), _("^K3First score! You scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_FIRST,				1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K1First victim! You were fragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_FIRST,			1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K1First blood! You typefragged ^BG%s"), _("^K1First score! You scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST,			1, 0, s1,												NO_CPID, XPND2(0, 0), _("^K1First victim! You were typefragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_VERBOSE,				1, 2, XPND3(FRAG_SPREE, s1, FRAG_PING),					NO_CPID, XPND2(0, 0), _("^K3You fragged ^BG%s^BG%s"), _("^K3You scored against ^BG%s^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_VERBOSE,			1, 3, XPND2(s1, FRAG_STATS),							NO_CPID, XPND2(0, 0), _("^K1You were fragged by ^BG%s^BG%s"), _("^K1You were scored against by ^BG%s^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_VERBOSE,			1, 2, XPND3(FRAG_SPREE, s1, FRAG_PING),					NO_CPID, XPND2(0, 0), _("^K1You typefragged ^BG%s^BG%s"), _("^K1You scored against ^BG%s^K1 while they were typing^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_VERBOSE,		1, 3, XPND2(s1, FRAG_STATS),							NO_CPID, XPND2(0, 0), _("^K1You were typefragged by ^BG%s^BG%s"), _("^K1You were scored against by ^BG%s^K1 while typing^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_FIRST_VERBOSE,		1, 1, s1,												NO_CPID, XPND2(0, 0), _("^K3First blood! You fragged ^BG%s"), _("^K3First score! You scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_FIRST_VERBOSE,		1, 3, s1,												NO_CPID, XPND2(0, 0), _("^K1First victim! You were fragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE,	1, 1, s1,												NO_CPID, XPND2(0, 0), _("^K1First blood! You typefragged ^BG%s"), _("^K1First score! You scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE,	1, 3, s1,												NO_CPID, XPND2(0, 0), _("^K1First victim! You were typefragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_WEAPON_MARBLES_LOST,			1, 1, XPND2(s1, WEAPON_NAME),	NO_CPID,				XPND2(0, 0), _("^K1You lost your marbles against ^BG%s^K1 using the ^BG%s!"), "")

#define MSG_WEAPON_NOTIFICATIONS \
	MSG_WEAPON_NOTIF(WEAPON_EMPTY,						NO_MSG,									NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MARBLES_LOST,				INFO_WEAPON_MARBLES_LOST,				CENTER_WEAPON_MARBLES_LOST)

#define MSG_DEATH_NOTIFICATIONS \
	MSG_DEATH_NOTIF(DEATH_EMPTY,						NO_MSG,									NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_SELF_CUSTOM,					INFO_DEATH_SELF_GENERIC,				CENTER_DEATH_SELF_CUSTOM) \
	MSG_DEATH_NOTIF(DEATH_SELF_GENERIC,					INFO_DEATH_SELF_GENERIC,				CENTER_DEATH_SELF_GENERIC) \
	MSG_DEATH_NOTIF(DEATH_SELF_SELFKILL,				INFO_DEATH_SELF_SELFKILL,				CENTER_DEATH_SELF_SELFKILL) \
	MSG_DEATH_NOTIF(DEATH_SELF_SUICIDE,					INFO_DEATH_SELF_SUICIDE,				CENTER_DEATH_SELF_SUICIDE) \
	MSG_DEATH_NOTIF(DEATH_SELF_NOAMMO,					INFO_DEATH_SELF_NOAMMO,					CENTER_DEATH_SELF_NOAMMO) \
	MSG_DEATH_NOTIF(DEATH_SELF_ROT,						INFO_DEATH_SELF_ROT,					CENTER_DEATH_SELF_ROT) \
	MSG_DEATH_NOTIF(DEATH_SELF_CAMP,					INFO_DEATH_SELF_CAMP,					CENTER_DEATH_SELF_CAMP) \
	MSG_DEATH_NOTIF(DEATH_SELF_BETRAYAL,				INFO_DEATH_SELF_BETRAYAL,				CENTER_DEATH_SELF_BETRAYAL) \
	MSG_DEATH_NOTIF(DEATH_SELF_TEAMCHANGE,				INFO_DEATH_SELF_TEAMCHANGE,				CENTER_DEATH_SELF_TEAMCHANGE) \
	MSG_DEATH_NOTIF(DEATH_SELF_AUTOTEAMCHANGE,			INFO_DEATH_SELF_AUTOTEAMCHANGE,			CENTER_DEATH_SELF_AUTOTEAMCHANGE) \
	MSG_DEATH_NOTIF(DEATH_SELF_FALL,					INFO_DEATH_SELF_FALL,					CENTER_DEATH_SELF_FALL) \
	MSG_DEATH_NOTIF(DEATH_SELF_DROWN,					INFO_DEATH_SELF_DROWN,					CENTER_DEATH_SELF_DROWN) \
	MSG_DEATH_NOTIF(DEATH_SELF_FIRE,					INFO_DEATH_SELF_FIRE,					CENTER_DEATH_SELF_FIRE) \
	MSG_DEATH_NOTIF(DEATH_SELF_LAVA,					INFO_DEATH_SELF_LAVA,					CENTER_DEATH_SELF_LAVA) \
	MSG_DEATH_NOTIF(DEATH_SELF_SLIME,					INFO_DEATH_SELF_SLIME,					CENTER_DEATH_SELF_SLIME) \
	MSG_DEATH_NOTIF(DEATH_SELF_SHOOTING_STAR,			INFO_DEATH_SELF_SHOOTING_STAR,			CENTER_DEATH_SELF_SHOOTING_STAR) \
	MSG_DEATH_NOTIF(DEATH_SELF_SWAMP,					INFO_DEATH_SELF_SWAMP,					CENTER_DEATH_SELF_SWAMP) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG,							NO_MSG,			CENTER_DEATH_MURDER_FRAG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED,						NO_MSG,			CENTER_DEATH_MURDER_FRAGGED) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG,						NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED,					NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAGGED) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_FIRST,					NO_MSG,			CENTER_DEATH_MURDER_FRAG_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_FIRST,					NO_MSG,			CENTER_DEATH_MURDER_FRAGGED_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_FIRST,				NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAG_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_FIRST,				NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_VERBOSE,					NO_MSG,			CENTER_DEATH_MURDER_FRAG_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_VERBOSE,				NO_MSG,			CENTER_DEATH_MURDER_FRAGGED_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_VERBOSE,				NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAG_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_VERBOSE,			NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAGGED_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_FIRST_VERBOSE,			NO_MSG,			CENTER_DEATH_MURDER_FRAG_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_FIRST_VERBOSE,			NO_MSG,			CENTER_DEATH_MURDER_FRAGGED_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE,		NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE,		NO_MSG,			CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE)

	
// ====================================
//  Initialization/Create Declarations
// ====================================

#define NOTIF_FIRST 1
#define NOTIF_MAX 1024 // limit of recursive functions with ACCUMULATE_FUNCTION
float NOTIF_INFO_COUNT;
float NOTIF_CENTER_COUNT;
float NOTIF_WEAPON_COUNT;
float NOTIF_DEATH_COUNT;
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

#define MSG_WEAPON_NOTIF(name,infoname,centername) \
	ADD_CSQC_AUTOCVAR(name) \
	float name; \
	void RegisterNotification_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_WEAPON_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_WEAPON_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(RegisterNotifications, RegisterNotification_##name)

#define MSG_DEATH_NOTIF(name,infoname,centername) \
	ADD_CSQC_AUTOCVAR(name) \
	float name; \
	void RegisterNotification_##name() \
	{ \
		SET_FIELD_COUNT(name, NOTIF_FIRST, NOTIF_DEATH_COUNT) \
		CHECK_MAX_COUNT(name, NOTIF_MAX, NOTIF_DEATH_COUNT, "notifications") \
	} \
	ACCUMULATE_FUNCTION(RegisterNotifications, RegisterNotification_##name)

// NOW we actually activate the declarations
MSG_INFO_NOTIFICATIONS
MSG_CENTER_NOTIFICATIONS
MSG_WEAPON_NOTIFICATIONS
MSG_DEATH_NOTIFICATIONS
#undef MSG_INFO_NOTIF
#undef MSG_CENTER_NOTIF
#undef MSG_WEAPON_NOTIF
#undef MSG_DEATH_NOTIF

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
			#undef MSG_INFO_NOTIF
			break;
		}
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) } }
			MSG_CENTER_NOTIFICATIONS
			#undef MSG_CENTER_NOTIF
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,infoname,centername) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name, \
				max(stof(Get_Field_Value(F_STRNUM, MSG_INFO, infoname)), stof(Get_Field_Value(F_STRNUM, MSG_CENTER, centername))), \
				max(stof(Get_Field_Value(F_FLNUM, MSG_INFO, infoname)), stof(Get_Field_Value(F_FLNUM, MSG_CENTER, centername)))) } }
			MSG_WEAPON_NOTIFICATIONS
			#undef MSG_WEAPON_NOTIF
			break;
		}
		case MSG_DEATH:
		{
			#define MSG_DEATH_NOTIF(name,infoname,centername) \
				{ NOTIF_MATCH(name, net_name) { GET_FIELD_VALUE_OUTPUT(field,name, \
				max(stof(Get_Field_Value(F_STRNUM, MSG_INFO, infoname)), stof(Get_Field_Value(F_STRNUM, MSG_CENTER, centername))), \
				max(stof(Get_Field_Value(F_FLNUM, MSG_INFO, infoname)), stof(Get_Field_Value(F_FLNUM, MSG_CENTER, centername)))) } }
			MSG_DEATH_NOTIFICATIONS
			#undef MSG_DEATH_NOTIF
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
	// foreground/normal colors
	input = strreplace("^F1", "^2", input); // primary priority (important names, etc)
	input = strreplace("^F2", "^3", input); // secondary priority (items, locations, numbers, etc)

	// "kill" colors
	input = strreplace("^K1", "^1", input); // "bad" or "dangerous" text (death messages against you, kill notifications, etc)
	input = strreplace("^K2", "^3", input); // similar to above, but less important... OR, a highlight out of above message type
	input = strreplace("^K3", "^4", input); // "good" or "beneficial" text (you fragging someone, etc)

	// background colors
	input = strreplace("^BG", "^7", input); // neutral/unimportant text
	input = strreplace("^N", "^7", input); // "none"-- reset to white...
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
	#define MSG_WEAPON_NOTIF(name,infoname,centername) { NOTIF_Write("MSG_WEAPON", VAR_TO_TEXT(name),sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))); }
	#define MSG_DEATH_NOTIF(name,infoname,centername) { NOTIF_Write("MSG_DEATH", VAR_TO_TEXT(name), sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))); }
	MSG_INFO_NOTIFICATIONS
	MSG_CENTER_NOTIFICATIONS
	MSG_WEAPON_NOTIFICATIONS
	MSG_DEATH_NOTIFICATIONS
	#undef MSG_INFO_NOTIF
	#undef MSG_CENTER_NOTIF
	#undef MSG_WEAPON_NOTIF
	#undef MSG_DEATH_NOTIF
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
	print("Local_Notification(", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", s1, ", ", s2, ", ", ftos(f1), strcat(", ", ftos(f2), ", ", ftos(f3), ");\n")));
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
			#undef MSG_INFO_NOTIF
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
			#undef MSG_CENTER_NOTIF
			break;
		}
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,infoname,centername) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					#if infoname != NO_MSG \
						Local_Notification(MSG_INFO, infoname, s1, s2, f1, f2, f3); \
					#endif \
					#if centername != NO_MSG \
						Local_Notification(MSG_CENTER, centername, s1, s2, f1, f2, f3); \
					#endif \
				} }
			MSG_WEAPON_NOTIFICATIONS
			#undef MSG_WEAPON_NOTIF
			break;
		}
		case MSG_DEATH:
		{
			#define MSG_DEATH_NOTIF(name,infoname,centername) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					#if infoname != NO_MSG \
						Local_Notification(MSG_INFO, infoname, s1, s2, f1, f2, f3); \
					#endif \
					#if centername != NO_MSG \
						Local_Notification(MSG_CENTER, centername, s1, s2, f1, f2, f3); \
					#endif \
				} }
			MSG_DEATH_NOTIFICATIONS
			#undef MSG_DEATH_NOTIF
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

	//print("stringcount = ", ftos(stringcount), ", floatcount = ", ftos(floatcount), ".\n");
	
	Local_Notification(net_type, net_name,
		((stringcount >= 1) ? ReadString() : ""),
		((stringcount == 2) ? ReadString() : ""),
		((floatcount >= 1) ? ReadLong() : 0),
		((floatcount >= 2) ? ReadLong() : 0),
		((floatcount == 3) ? ReadLong() : 0));
}
#endif

#ifdef SVQC
void Send_Notification(entity client, float broadcast, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	if(net_type && net_name)
	{
		//print("notification: ", Get_Field_Value(F_NAME, net_type, net_name), ": ", ftos(net_name), ".\n");
		print("Send_Notification(", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", s1, ", ", s2, ", ", ftos(f1), strcat(", ", ftos(f2), ", ", ftos(f3), ");\n")));

		float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
		
		if(notif_stringcount(s1, s2) > stringcount) { backtrace("Too many string arguments for notification!\n"); return; }
		if(notif_floatcount(f1, f2, f3) > floatcount) { backtrace("Too many float arguments for notification!\n"); return; }

		if(broadcast == MSG_ONE)
		{
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
		}
		else if(broadcast == MSG_ALL)
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
		else { backtrace("Unknown MSG_ type to write with!\n"); }

		if(!server_is_local && (net_type == MSG_INFO))
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } }
			MSG_INFO_NOTIFICATIONS
			#undef MSG_INFO_NOTIF
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
			Send_Notification(tmp_entity, MSG_ONE, net_type, net_name, s1, s2, f1, f2, f3);
		}
	}
}

// WARNING: use this ONLY if you need exceptions or want to exclude spectators, otherwise use Send_Notification(world, MSG_ALL, ...)
void Send_Notification_ToAll(entity except, float spectators, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if((tmp_entity.classname == STR_PLAYER) || spectators)
		if(tmp_entity != except)
		{
			Send_Notification(tmp_entity, MSG_ONE, net_type, net_name, s1, s2, f1, f2, f3);
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
