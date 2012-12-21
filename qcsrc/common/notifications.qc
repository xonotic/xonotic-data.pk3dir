// ================================================
//  Unified notification system, written by Samual
//  Last updated: December, 2012
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

// Since this code uses macro processors to list notifications,
// the normal compiler sees these checks as "constant" and throws
// a warning. We have to get around this by using another function.
#define NOTIF_MATCH(a,b) if(min(NOTIF_MAX, a) == b)

#ifdef CSQC
// NO_CPID normally has a variable value, so we need to check and see
// whether a notification uses it. If so, cancel out the centerprint ID.
#define HANDLE_CPID(cpid) ((min(NOTIF_MAX, cpid) == NO_CPID) ? FALSE : cpid)

// client-side handling of cvars
#define ADD_CSQC_AUTOCVAR(name) var float autocvar_notification_##name = TRUE;
#define CHECK_AUTOCVAR(name) if(autocvar_notification_##name)

/*
 Acquire special information to generate for display in the
 notification from variables networked to the client.
 Macro descriptions:
    PASS_KEY: find the keybind for "passing" or "dropping" in CTF game mode
    FRAG_PING: show the ping of a player
    FRAG_STATS: show health/armor/ping of a player
    FRAG_POS: show score status and position in the match of a player
    SPREE_CEN: centerprint notif for kill spree/how many kills they have
    SPREE_INF: info notif for kill spree/how many kills they have
    SPREE_END: placed at the end of murder messages to show ending of sprees
    SPREE_LOST: placed at the end of suicide messages to show losing of sprees
    DEATH_TEAM: show the full name of the team a player is switching from
    WEAPON_NAME: return the full name of a weapon from a weaponid
*/
// CSQC replacements
string got_commandkey;
#define PASS_KEY ((((got_commandkey = getcommandkey("pass", "+use")) != "pass") && !(strstrofs(got_commandkey, "not bound", 0) >= 0)) ? sprintf(CCR(_(" ^F1(Press %s)")), got_commandkey) : "")
#define FRAG_PING ((f2 != BOT_PING) ? sprintf(CCR(_("\n(Ping ^2%d^BG)")), f2) : "")
#define FRAG_STATS sprintf(CCR(_("\n(Health ^1%d^BG / Armor ^2%d^BG)%s")), f1, f2, ((f3 != BOT_PING) ? sprintf(CCR(_(" (Ping ^2%d^BG)")), f3) : ""))
#define FRAG_POS ((Should_Print_Score_Pos(f1)) ? sprintf("\n^BG%s", Read_Score_Pos(f1)) : "")
#define SPREE_CEN (((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : "")
#define SPREE_INF (((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : "")
#define SPREE_END ((f1 >= 3) ? sprintf(normal_or_gentle(_(", ending their %d frag spree"), _(", ending their %d score spree")), f1) : "")
#define SPREE_LOST ((f1 >= 3) ? sprintf(normal_or_gentle(_(", losing their %d frag spree"), _(", losing their %d score spree")), f1) : "")
#define DEATH_TEAM Team_ColoredFullName(TEAM_SV_TO_CL(f1))
#define WEAPON_NAME f1 // weaponorder[f1].netname
#else
#ifdef SVQC
// SVQC replacements
#define SPREE_INF (((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : "")
#define SPREE_END ((f1 >= 3) ? sprintf(normal_or_gentle(_(", ending their %d frag spree"), _(", ending their %d score spree")), f1) : "")
#define SPREE_LOST ((f1 >= 3) ? sprintf(normal_or_gentle(_(", losing their %d frag spree"), _(", losing their %d score spree")), f1) : "")
#define DEATH_TEAM Team_ColoredFullName(f1)
#define WEAPON_NAME f1 // weaponorder[f1].netname

// allow sending of notifications to also pass through to spectators (specifically for centerprints)
#define WRITESPECTATABLE_MSG_ONE_VARNAME(varname,statement) entity varname; varname = msg_entity; FOR_EACH_REALCLIENT(msg_entity) if(msg_entity == varname || (msg_entity.classname == STR_SPECTATOR && msg_entity.enemy == varname)) statement msg_entity = varname
#define WRITESPECTATABLE_MSG_ONE(statement) WRITESPECTATABLE_MSG_ONE_VARNAME(oldmsg_entity, statement)
#define WRITESPECTATABLE(msg,statement) if(msg == MSG_ONE) { WRITESPECTATABLE_MSG_ONE(statement); } else statement float WRITESPECTATABLE_workaround = 0
#endif

// do nothing for the other programs, they don't need cvars (those are just for the clients)
#define ADD_CSQC_AUTOCVAR(name)
#endif


// ====================================
//  Notifications List and Information
// ====================================
/*
 List of all notifications (including identifiers and display information)
 Possible Tokens: name, infoname, centername, strnum, flnum, args, hudargs, icon, cpid, durcnt, normal, gentle
 Format Specifications:
    MSG_INFO:
      name: VAR: Name of notification
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: MISC: Arguments for sprintf(string, args), if no args needed then use ""
      hudargs: XPD2(STRING, STRING): arguments for names in notify messages 
      icon: STRING: icon string name for the hud notify panel, "" if no icon is used
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_CENTER:
      name: VAR: Name of notification
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: MISC: Arguments for sprintf(string, args), if no args needed then use ""
      cpid: FLOAT: centerprint ID number (CPID_*), NO_CPID if no CPID is needed
      durcnt: XPD2(FLOAT, FLOAT): Duration/Countdown: extra arguments for centerprint messages
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_WEAPON:
    MSG_DEATH:
      name: VAR: Name of chaining notification
      infoname: VAR: Name of info notification for reference
      centername: VAR: Name of centerprint notification for reference

 Messages with ^F1, ^BG, ^TC, etc etc in them will replace those strings
 with colors according to the cvars the user has chosen. This allows for
 users to create unique color profiles for their HUD, giving more customization
 options to HUD designers and end users who want such a feature.

 Check out the function calls for string CCR(...) and
 string TCR(...) to better understand how these codes work.

 Guidlines for notification declaration (please try and follow these):
    -ALWAYS start the string with a color, preferably background.
    -ALWAYS reset a color after a name (this way they don't set it for the whole string).
    -NEVER re-declare an event twice.
    -NEVER add or remove tokens from the format, it SHOULD already work.
    -MSG_INFO messages must ALWAYS end with a new line: \n
    -MSG_CENTER should NOT end with a new line
    -Be clean and simple with your notification naming,
     nothing too long for the name field... Abbreviations are your friend. :D
    -Keep the spacing as clean as possible... if the arguments are abnormally long,
      it's okay to go out of line a bit... but try and keep it clean still.
    -Sort the notifications in the most appropriate order for their tasks.
      TODO: ? centerprint IDs are given priority based on their order (first being highest priority going downwards)
    -ARIRE unir frk jvgu lbhe bja zbgure. (gvc sbe zvxrrhfn) -- Don't pay attention to this ^_^

 Final note: DO NOT PROVIDE MORE ARGUMENTS THAN NECESSARY FOR THE NOTIFICATION YOU'RE CALLING!
      The system is designed to save as much networking bandwidth as possible,
      so please dynamically control your argument sending to fit *exactly* what is required.
*/

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
	MSG_INFO_NOTIF(INFO_EMPTY,							0, 0, NO_STR_ARG, XPD2("", ""),						"",						"", "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DROPPED_, 2,		0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^BGThe ^TC^TT^BG flag was dropped in the base and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_DAMAGED_, 2,		0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^BGThe ^TC^TT^BG flag was destroyed and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_SPEEDRUN_, 2,	0, 1, f1/100, XPD2("", ""),							"",						_("^BGThe ^TC^TT^BG flag became impatient after ^F1%.2f^BG seconds and returned itself\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_NEEDKILL_, 2,	0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^BGThe ^TC^TT^BG flag fell somewhere it couldn't be reached and returned to base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_ABORTRUN_, 2,	0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^BGThe ^TC^TT^BG flag was returned to base by its owner\n"), "") \
	MULTITEAM_INFO(INFO_CTF_FLAGRETURN_TIMEOUT_, 2,		0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^BGThe ^TC^TT^BG flag has returned to the base\n"), "") \
	MULTITEAM_INFO(INFO_CTF_PICKUP_, 2,					1, 0, s1, XPD2(s1, ""),								"notify_%s_taken",		_("^BG%s^BG got the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_RETURN_, 2,					1, 0, s1, XPD2(s1, ""),								"notify_%s_returned",	_("^BG%s^BG returned the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_LOST_, 2,					1, 0, s1, XPD2(s1, ""),								"notify_%s_lost",		_("^BG%s^BG lost the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_, 2,				1, 0, s1, XPD2(s1, ""),								"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_TIME_, 2,			1, 1, XPD2(s1, f1/100), XPD2(s1, ""),				"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_BROKEN_, 2,			2, 2, XPD4(s1, f1/100, s2, f2/100), XPD2(s1, ""),	"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%.2f^BG seconds, breaking ^BG%s^BG's previous record of ^F2%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_CTF_CAPTURE_UNBROKEN_, 2,		2, 2, XPD4(s1, f1/100, s2, f2/100), XPD2(s1, ""),	"notify_%s_captured",	_("^BG%s^BG captured the ^TC^TT^BG flag in ^F2%.2f^BG seconds, failing to break ^BG%s^BG's previous record of ^F1%.2f^BG seconds\n"), "") \
	MULTITEAM_INFO(INFO_DEATH_TEAMKILL_, 4,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_teamkill_%s",	_("^BG%s^K1 was betrayed by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_FIRSTBLOOD,				2, 0, s2, XPD2("", ""),								"",						_("^BG%s^K1 drew first blood\n"), _("^F1%s^K1 got the first score\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_CUSTOM,				2, 1, XPD3(s1, s2, SPREE_LOST), XPD2(s1, ""),		"notify_void",			_("^BG%s^K1 %s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_GENERIC,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_selfkill",		_("^BG%s^K1 died%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_VOID,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_void",			_("^BG%s^K1 was in the wrong place%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SUICIDE,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_selfkill",		_("^BG%s^K1 couldn't take it anymore%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_NOAMMO,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_outofammo",		_("^BG%s^K1 died%s. What's the point of living without ammo?\n"), _("^F1%s^K1 ran out of ammo%s\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_ROT,					1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_death",			_("^BG%s^K1 rotted away%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_CAMP,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_camping",		_("^BG%s^K1 thought they found a nice camping ground%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_BETRAYAL,			1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_teamkill_red",	_("^BG%s^K1 became enemies with the Lord of Teamplay%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_TEAMCHANGE,			1, 1, XPD2(s1, DEATH_TEAM), XPD2("", ""),			"",						_("^BG%s^K1 switched to the %s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_AUTOTEAMCHANGE,		1, 1, XPD2(s1, DEATH_TEAM), XPD2("", ""),			"",						_("^BG%s^K1 was moved into the %s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_FALL,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_fall",			_("^BG%s^K1 hit the ground with a crunch%s\n"), _("^F1%s^K1 hit the ground with a bit too much force%s\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_DROWN,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_water",			_("^BG%s^K1 couldn't catch their breath%s\n"), _("^F1%s^K1 was in the water for too long%s\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_FIRE,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_death",			_("^BG%s^K1 became a bit too crispy%s\n"), _("^F1%s^K1 felt a little hot%s\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_LAVA,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_lava",			_("^BG%s^K1 turned into hot slag%s\n"), _("^F1%s^K1 found a hot place%s\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SLIME,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_slime",			_("^BG%s^K1 was slimed%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SHOOTING_STAR,		1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_shootingstar",	_("^BG%s^K1 became a shooting star%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_SWAMP,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_slime",			_("^BG%s^K1 is now preserved for centuries to come%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_CHEAT,				1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_selfkill",		_("^BG%s^K1 unfairly eliminated themself%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_SELF_TOUCHEXPLODE,		1, 1, XPD2(s1, SPREE_LOST), XPD2(s1, ""),			"notify_death",			_("^BG%s^K1 died in an accident%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_TELEFRAG,			2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_telefrag",		_("^BG%s^K1 was telefragged by ^BG%s^K1%s\n"), _("^F1%s^K1 tried to occupy ^BG%s^K1's teleport destination space\n")) \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_FALL,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_fall",			_("^BG%s^K1 was grounded by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_DROWN,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_water",			_("^BG%s^K1 was drowned by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_LAVA,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_lava",			_("^BG%s^K1 was cooked by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_SLIME,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_slime",			_("^BG%s^K1 was slimed by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_SHOOTING_STAR,		2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_shootingstar",	_("^BG%s^K1 was shot into space by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_SWAMP,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_slime",			_("^BG%s^K1 was preserved by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_VOID,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2), 		"notify_void",			_("^BG%s^K1 was thrown into a world of hurt by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_TOUCHEXPLODE,		2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2), 		"notify_death", 		_("^BG%s^K1 died in an accident with ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_CHEAT,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2),		"notify_death",			_("^BG%s^K1 was unfairly eliminated by ^BG%s^K1%s\n"), "") \
	MSG_INFO_NOTIF(INFO_DEATH_MURDER_FIRE,				2, 1, XPD3(s1, s2, SPREE_END), XPD2(s1, s2), 		"notify_death",			_("^BG%s^K1 was burnt up into a crisp by ^BG%s^K1%s\n"), _("^F1%s^K1 felt a little hot from ^BG%s^K1's fire^K1%s\n")) \
	MULTITEAM_INFO(INFO_FREEZETAG_ROUND_WIN_, 4,		0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^TC^TT^BG team wins the round, all other teams were frozen\n"), "") \
	MSG_INFO_NOTIF(INFO_FREEZETAG_REVIVE,				2, 0, XPD2(s1, s2), XPD2("", ""),					"",						_("^BG%s^K3 was revived by ^BG%s\n"), "") \
	MSG_INFO_NOTIF(INFO_FREEZETAG_FREEZE,				2, 0, XPD2(s1, s2), XPD2("", ""),					"",						_("^BG%s^K1 was frozen by ^BG%s\n"), "") \
	MSG_INFO_NOTIF(INFO_FREEZETAG_SELF,					1, 0, s1, XPD2("", ""),								"",						_("^BG%s^K1 froze themself\n"), "") \
	MSG_INFO_NOTIF(INFO_KEEPAWAY_DROPPED,				1, 0, s1, XPD2(s1, ""),								"notify_balldropped",	_("^BG%s^BG has dropped the ball!\n"), "") \
	MSG_INFO_NOTIF(INFO_KEEPAWAY_PICKUP,				1, 0, s1, XPD2(s1, ""),								"notify_ballpickedup",	_("^BG%s^BG has picked up the ball!\n"), "") \
	MSG_INFO_NOTIF(INFO_RACE_FAIL,						2, 0, XPD2(s1, s2), XPD2(s1, ""),					"race_newfail",			"", "") \
	MSG_INFO_NOTIF(INFO_RACE_NEW_RECORD,				2, 0, XPD2(s1, s2), XPD2(s1, ""),					"race_newrecordserver",	"", "") \
	MSG_INFO_NOTIF(INFO_RACE_NEW_TIME,					2, 0, XPD2(s1, s2), XPD2(s1, ""),					"race_newtime",			"", "") \
	MSG_INFO_NOTIF(INFO_RACE_NEW_RANK,					2, 0, XPD2(s1, s2), XPD2(s1, ""),					"race_newrankyellow",	"", "") \
	MULTITEAM_INFO(INFO_SCORES_, 4,						0, 0, NO_STR_ARG, XPD2("", ""),						"",						_("^TC^TT ^BGteam scores!\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_THINKING_WITH_PORTALS,			1, 0, s1, XPD2(s1, ""), 					"notify_selfkill", _("^BG%s^K1 is now thinking with portals...\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_CRYLINK_SUICIDE, 				1, 0, s1, XPD2(s1, ""), 					"weaponcrylink", _("^BG%s^K1 felt the strong pull of their Crylink\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_CRYLINK_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponcrylink", _("^BG%s^K1 felt the strong pull of ^BG%s^K1's Crylink\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ELECTRO_SUICIDE_ORBS, 			1, 0, s1, XPD2(s1, ""), 					"weaponelectro", _("^BG%s^K1 could not remember where they put their Electro plasma\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ELECTRO_SUICIDE_BOLT, 			1, 0, s1, XPD2(s1, ""), 					"weaponelectro", _("^BG%s^K1 played with Electro plasma\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ELECTRO_MURDER_BOLT, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponelectro", _("^BG%s^K1 was blasted by ^BG%s^K1's Electro bolt\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ELECTRO_MURDER_ORBS, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponelectro", _("^BG%s^K1 got too close to ^BG%s^K1's Electro plasma\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ELECTRO_MURDER_COMBO, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponelectro", _("^BG%s^K1 felt the electrifying air of ^BG%s^K1's Electro combo\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_FIREBALL_SUICIDE_FIREMINE, 		1, 0, s1, XPD2(s1, ""), 					"weaponfireball", _("^BG%s^K1 forgot about their firemine\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_FIREBALL_SUICIDE_BLAST, 			1, 0, s1, XPD2(s1, ""), 					"weaponfireball", _("^BG%s^K1 should have used a smaller gun\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_FIREBALL_MURDER_FIREMINE, 		2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponfireball", _("^BG%s^K1 got burnt by ^BG%s^K1's firemine\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_FIREBALL_MURDER_BLAST, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponfireball", _("^BG%s^K1 got too close to ^BG%s^K1's fireball\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MORTAR_SUICIDE_EXPLODE, 			1, 0, s1, XPD2(s1, ""), 					"weapongrenadelauncher", _("^BG%s^K1 blew themself up with their own Mortar\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MORTAR_SUICIDE_BOUNCE, 			1, 0, s1, XPD2(s1, ""), 					"weapongrenadelauncher", _("^BG%s^K1 didn't see their own Mortar grenade\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MORTAR_MURDER_EXPLODE,	 		2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weapongrenadelauncher", _("^BG%s^K1 ate ^BG%s^K1's Mortar grenade\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MORTAR_MURDER_BOUNCE, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weapongrenadelauncher", _("^BG%s^K1 got too close to ^BG%s^K1's Mortar grenade\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HAGAR_SUICIDE, 					1, 0, s1, XPD2(s1, ""), 					"weaponhagar", _("^BG%s^K1 played with tiny Hagar rockets\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HAGAR_MURDER_BURST, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponhagar", _("^BG%s^K1 was pummeled by a burst of ^BG%s^K1's Hagar rockets\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HAGAR_MURDER_SPRAY, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponhagar", _("^BG%s^K1 was pummeled by ^BG%s^K1's Hagar rockets\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HLAC_SUICIDE, 					1, 0, s1, XPD2(s1, ""), 					"weaponhlac", _("^BG%s^K1 got a little jumpy with their HLAC\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HLAC_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponhlac", _("^BG%s^K1 was cut down with ^BG%s^K1's HLAC\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_HOOK_MURDER,						2, 0, XPD2(s1, s2), XPD2(s1, s2),			"weaponhook", _("^BG%s^K1 was caught in ^BG%s^K1's Hook gravity bomb\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_LASER_SUICIDE, 					1, 0, s1, XPD2(s1, ""), 					"weaponlaser", _("^BG%s^K1 shot themself to hell with their Laser\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_LASER_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponlaser", _("^BG%s^K1 was shot to death by ^BG%s^K1's Laser\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MINELAYER_SUICIDE, 				1, 0, s1, XPD2(s1, ""), 					"weaponminelayer", _("^BG%s^K1 forgot about their mine\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MINELAYER_MURDER, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponminelayer", _("^BG%s^K1 got too close to ^BG%s^K1's mine\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_MINSTANEX_MURDER, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponminstanex", _("^BG%s^K1 has been vaporized by ^BG%s^K1's Minstanex\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_NEX_MURDER, 						2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponnex", _("^BG%s^K1 has been vaporized by ^BG%s^K1's Nex\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_RIFLE_MURDER_HAIL_PIERCING,		2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrifle", _("^BG%s^K1 failed to hide from ^BG%s^K1's Rifle bullet hail\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_RIFLE_MURDER_HAIL, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrifle", _("^BG%s^K1 died in ^BG%s^K1's Rifle bullet hail\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_RIFLE_MURDER_PIERCING, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrifle", _("^BG%s^K1 failed to hide from ^BG%s^K1's Rifle\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_RIFLE_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrifle", _("^BG%s^K1 was sniped with a Rifle by ^BG%s\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_RIFLE_MURDER_HEADSHOT, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"notify_headshot", _("^BG%s^K1 was shot in the head with a Rifle by ^BG%s\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ROCKETLAUNCHER_SUICIDE, 			1, 0, s1, XPD2(s1, ""), 					"weaponrocketlauncher", _("^BG%s^K1 blew themself up with their Rocketlauncher\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ROCKETLAUNCHER_MURDER_DIRECT, 	2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrocketlauncher", _("^BG%s^K1 ate ^BG%s^K1's rocket\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ROCKETLAUNCHER_MURDER_SPLASH, 	2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponrocketlauncher", _("^BG%s^K1 got too close ^BG%s^K1's rocket\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_SEEKER_SUICIDE, 					1, 0, s1, XPD2(s1, ""), 					"weaponseeker", _("^BG%s^K1 played with tiny Seeker rockets\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_SEEKER_MURDER_TAG, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponseeker", _("^BG%s^K1 was tagged by ^BG%s^K1's Seeker\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_SEEKER_MURDER_SPRAY, 			2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponseeker", _("^BG%s^K1 was pummeled by ^BG%s^K1's Seeker rockets\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_SHOTGUN_MURDER_SLAP, 			2, 0, XPD2(s2, s1), XPD2(s1, s2), 			"notify_melee_shotgun", _("^BG%s^K1 slapped ^BG%s^K1 around a bit with a large Shotgun\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_SHOTGUN_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponshotgun", _("^BG%s^K1 was gunned down by ^BG%s^K1's Shotgun\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_TUBA_SUICIDE, 					1, 0, s1, XPD2(s1, ""), 					"weapontuba", _("^BG%s^K1 hurt their own ears with the @!#%%'n Tuba\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_TUBA_MURDER, 					2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weapontuba", _("^BG%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Tuba\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ACCORDEON_SUICIDE, 				1, 0, s1, XPD2(s1, ""), 					"weapontuba", _("^BG%s^K1 hurt their own ears with the @!#%%'n Accordeon\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_ACCORDEON_MURDER, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weapontuba", _("^BG%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Accordeon\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_KLEINBOTTLE_SUICIDE, 			1, 0, s1, XPD2(s1, ""), 					"weapontuba", _("^BG%s^K1 hurt their own ears with the @!#%%'n Klein Bottle\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_KLEINBOTTLE_MURDER, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weapontuba", _("^BG%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Klein Bottle\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_UZI_MURDER_SNIPE, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponuzi", _("^BG%s^K1 was sniped by ^BG%s^K1's Machine Gun\n"), "") \
	MSG_INFO_NOTIF(INFO_WEAPON_UZI_MURDER_SPRAY, 				2, 0, XPD2(s1, s2), XPD2(s1, s2), 			"weaponuzi", _("^BG%s^K1 was riddled full of holes by ^BG%s^K1's Machine Gun\n"), "") 

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
	MSG_CENTER_NOTIF(CENTER_EMPTY,							0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), "", "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_SHIELDED,		0, 0, NO_STR_ARG, 				CPID_CTF_CAPSHIELD,		XPD2(0, 0), _("^BGYou are now ^F1shielded^BG from the flag\n^BGfor ^F2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_CAPTURESHIELD_FREE, 		0, 0, NO_STR_ARG, 				CPID_CTF_CAPSHIELD,		XPD2(0, 0), _("^BGYou are now free.\n^BGFeel free to ^F2try to capture^BG the flag again\n^BGif you think you will succeed."), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_OTHER_, 2,				2, 0, XPD2(s1, s2),				CPID_CTF_PASS, 			XPD2(0, 0), _("^BG%s^BG passed the ^TC^TT^BG flag to %s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_SENT_, 2,				1, 0, s1, 						CPID_CTF_PASS, 			XPD2(0, 0), _("^BGYou passed the ^TC^TT^BG flag to %s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PASS_RECEIVED_, 2,			1, 0, s1, 						CPID_CTF_PASS, 			XPD2(0, 0), _("^BGYou received the ^TC^TT^BG flag from %s"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PASS_REQUESTING,			1, 0, s1,						CPID_CTF_PASS,			XPD2(0, 0), _("^BGRequesting %s^BG to pass you the flag"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PASS_REQUESTED, 			1, 0, XPD2(s1, PASS_KEY),		CPID_CTF_PASS,			XPD2(0, 0), _("^BG%s^BG requests you to pass the flag%s"), "") \
	MULTITEAM_CENTER(CENTER_CTF_RETURN_, 2,					0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPD2(0, 0), _("^BGYou returned the ^TC^TT^BG flag!"), "") \
	MULTITEAM_CENTER(CENTER_CTF_CAPTURE_, 2,				0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPD2(0, 0), _("^BGYou captured the ^TC^TT^BG flag!"), "") \
	MULTITEAM_CENTER(CENTER_CTF_PICKUP_, 2,					0, 0, NO_STR_ARG,				CPID_CTF_LOWPRIO, 		XPD2(0, 0), _("^BGYou got the ^TC^TT^BG flag!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_TEAM,				1, 0, s1,						CPID_CTF_LOWPRIO,		XPD2(0, 0), _("^BGYour %steam mate^BG got the flag! Protect them!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_TEAM_VERBOSE,		2, 0, XPD3(s1, s2, s1),			CPID_CTF_LOWPRIO,		XPD2(0, 0), _("^BGYour %steam mate (^BG%s%s)^BG got the flag! Protect them!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_ENEMY,				1, 0, s1,						CPID_CTF_LOWPRIO,		XPD2(0, 0), _("^BGThe %senemy^BG got your flag! Retrieve it!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_PICKUP_ENEMY_VERBOSE,		2, 0, XPD3(s1, s2, s1),			CPID_CTF_LOWPRIO,		XPD2(0, 0), _("^BGThe %senemy (^BG%s%s)^BG got your flag! Retrieve it!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_STALEMATE_CARRIER,			0, 0, NO_STR_ARG,				CPID_STALEMATE,			XPD2(0, 0), _("^BGStalemate! Enemies can now see you on radar!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_STALEMATE_OTHER,			0, 0, NO_STR_ARG,				CPID_STALEMATE,			XPD2(0, 0), _("^BGStalemate! Flag carriers can now be seen by enemies on radar!"), "") \
	MSG_CENTER_NOTIF(CENTER_CTF_FLAG_THROW_PUNISH,			0, 1, f1,						CPID_CTF_LOWPRIO,		XPD2(0, 0), _("^BGToo many flag throws! Throwing disabled for %d seconds."), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_CUSTOM,				2, 0, s2,						NO_CPID,				XPD2(0, 0), _("^K1You were %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_GENERIC,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You killed your own dumb self!"), _("^K1You need to be more careful!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_VOID,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1Watch your step!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SUICIDE,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You committed suicide!"), _("^K1You ended it all!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_NOAMMO,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You were killed for running out of ammo..."), _("^K1You are respawning for running out of ammo...")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_ROT,					0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You grew too old without taking your medicine"), _("^K1You need to preserve your health")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_CAMP,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1Die camper!"), _("^K1Reconsider your tactics, camper!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_BETRAYAL,			0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1Don't shoot your team mates!"), _("^K1Don't go against your team mates!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_TEAMCHANGE,			0, 1, DEATH_TEAM,				NO_CPID,				XPD2(0, 0), _("^BGYou are now on: %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_AUTOTEAMCHANGE,		0, 1, DEATH_TEAM,				NO_CPID,				XPD2(0, 0), _("^BGYou have been moved into a different team\nYou are now on: %s"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_FALL,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You hit the ground with a crunch!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_DROWN,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You couldn't catch your breath in time!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_FIRE,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You got a little bit too crispy!"), _("^K1You felt a little too hot!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_LAVA,				0, 0, NO_STR_ARG, 				NO_CPID,				XPD2(0, 0), _("^K1You couldn't stand the heat!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SLIME,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You melted away in slime!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SHOOTING_STAR,		0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You became a shooting star!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_SWAMP,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You got stuck in a swamp!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_CHEAT,				0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You unfairly eliminated yourself!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_SELF_TOUCHEXPLODE,		0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You died in an accident!"), "") \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG,						1, 1, XPD2(SPREE_CEN, s1),								NO_CPID, XPD2(0, 0), _("^K3%sYou fragged ^BG%s"), _("^K3%sYou scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED,					1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1You were fragged by ^BG%s"), _("^K1You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG,					1, 1, XPD2(SPREE_CEN, s1),								NO_CPID, XPD2(0, 0), _("^K1%sYou typefragged ^BG%s"), _("^K1%sYou scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED,				1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1You were typefragged by ^BG%s"), _("^K1You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_FIRST,				1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K3First blood! You fragged ^BG%s"), _("^K3First score! You scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_FIRST,				1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1First victim! You were fragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_FIRST,			1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1First blood! You typefragged ^BG%s"), _("^K1First score! You scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST,			1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1First victim! You were typefragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_VERBOSE,				1, 2, XPD3(SPREE_CEN, s1, FRAG_PING),					NO_CPID, XPD2(0, 0), _("^K3You fragged ^BG%s^BG%s"), _("^K3You scored against ^BG%s^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_VERBOSE,			1, 3, XPD2(s1, FRAG_STATS),								NO_CPID, XPD2(0, 0), _("^K1You were fragged by ^BG%s^BG%s"), _("^K1You were scored against by ^BG%s^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_VERBOSE,			1, 2, XPD3(SPREE_CEN, s1, FRAG_PING),					NO_CPID, XPD2(0, 0), _("^K1You typefragged ^BG%s^BG%s"), _("^K1You scored against ^BG%s^K1 while they were typing^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_VERBOSE,		1, 3, XPD2(s1, FRAG_STATS),								NO_CPID, XPD2(0, 0), _("^K1You were typefragged by ^BG%s^BG%s"), _("^K1You were scored against by ^BG%s^K1 while typing^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAG_FIRST_VERBOSE,		1, 1, s1,												NO_CPID, XPD2(0, 0), _("^K3First blood! You fragged ^BG%s"), _("^K3First score! You scored against ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_FRAGGED_FIRST_VERBOSE,		1, 3, s1,												NO_CPID, XPD2(0, 0), _("^K1First victim! You were fragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE,	1, 1, s1,												NO_CPID, XPD2(0, 0), _("^K1First blood! You typefragged ^BG%s"), _("^K1First score! You scored against ^BG%s^K1 while they were typing")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE,	1, 3, s1,												NO_CPID, XPD2(0, 0), _("^K1First victim! You were typefragged by ^BG%s"), _("^K1First casualty! You were scored against by ^BG%s^K1 while typing!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_TEAMKILL_FRAG,					1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1Moron! You fragged ^BG%s^K1, a team mate!"), _("^K1Moron! You went against ^BG%sK1, a team mate!")) \
	MSG_CENTER_NOTIF(CENTER_DEATH_TEAMKILL_FRAGGED,					1, 0, s1,												NO_CPID, XPD2(0, 0), _("^K1You were fragged by ^BG%s^K1, a team mate"), _("^K1You were scored against by ^BG%s^K1, a team mate")) \
	MULTITEAM_CENTER(CENTER_FREEZETAG_ROUND_WIN_, 4,		0, 0, NO_STR_ARG,				NO_CPID, 				XPD2(0, 0), _("^TC^TT^BG team wins the round, all other teams were frozen"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_SPAWN_LATE,			0, 0, NO_STR_ARG,				NO_CPID, 				XPD2(0, 0), _("^K1You spawned after the round started, you'll spawn as frozen"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_REVIVE,				1, 0, s1,						NO_CPID, 				XPD2(0, 0), _("^K3You revived ^BG%s"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_REVIVED,				1, 0, s1,						NO_CPID, 				XPD2(0, 0), _("^K3You were revived by ^BG%s"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_SELF,					0, 0, NO_STR_ARG,				NO_CPID,				XPD2(0, 0), _("^K1You froze yourself"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_FREEZE,				1, 0, s1,						NO_CPID, 				XPD2(0, 0), _("^K3You froze ^BG%s"), "") \
	MSG_CENTER_NOTIF(CENTER_FREEZETAG_FROZEN,				1, 0, s1,						NO_CPID, 				XPD2(0, 0), _("^K1You were frozen by ^BG%s"), "") \
	MSG_CENTER_NOTIF(CENTER_KEEPAWAY_DROPPED,				1, 0, s1, 						CPID_KEEPAWAY,			XPD2(0, 0), _("^BG%s^BG has dropped the ball!"), "") \
	MSG_CENTER_NOTIF(CENTER_KEEPAWAY_PICKUP,				1, 0, s1, 						CPID_KEEPAWAY,			XPD2(0, 0), _("^BG%s^BG has picked up the ball!"), "") \
	MSG_CENTER_NOTIF(CENTER_KEEPAWAY_WARN,					0, 0, NO_STR_ARG,				CPID_KA_WARN,			XPD2(0, 0), _("^BGKilling people while you don't have the ball gives no points!"), "") \
	MSG_CENTER_NOTIF(CENTER_WEAPON_MARBLES_LOST,			1, 1, XPD2(s1, WEAPON_NAME),	NO_CPID,				XPD2(0, 0), _("^K1You lost your marbles against ^BG%s^K1 using the ^BG%s!"), "")

#define MSG_WEAPON_NOTIFICATIONS \
	MSG_WEAPON_NOTIF(WEAPON_EMPTY,							NO_MSG,										NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_THINKING_WITH_PORTALS,			INFO_WEAPON_THINKING_WITH_PORTALS,			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_CRYLINK_SUICIDE, 				INFO_WEAPON_CRYLINK_SUICIDE, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_CRYLINK_MURDER, 				INFO_WEAPON_CRYLINK_MURDER, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ELECTRO_SUICIDE_ORBS, 			INFO_WEAPON_ELECTRO_SUICIDE_ORBS, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ELECTRO_SUICIDE_BOLT, 			INFO_WEAPON_ELECTRO_SUICIDE_BOLT, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ELECTRO_MURDER_BOLT, 			INFO_WEAPON_ELECTRO_MURDER_BOLT, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ELECTRO_MURDER_ORBS, 			INFO_WEAPON_ELECTRO_MURDER_ORBS, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ELECTRO_MURDER_COMBO, 			INFO_WEAPON_ELECTRO_MURDER_COMBO, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_FIREBALL_SUICIDE_FIREMINE, 		INFO_WEAPON_FIREBALL_SUICIDE_FIREMINE, 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_FIREBALL_SUICIDE_BLAST, 		INFO_WEAPON_FIREBALL_SUICIDE_BLAST, 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_FIREBALL_MURDER_FIREMINE, 		INFO_WEAPON_FIREBALL_MURDER_FIREMINE, 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_FIREBALL_MURDER_BLAST, 			INFO_WEAPON_FIREBALL_MURDER_BLAST, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MORTAR_SUICIDE_EXPLODE, 		INFO_WEAPON_MORTAR_SUICIDE_EXPLODE, 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MORTAR_SUICIDE_BOUNCE, 			INFO_WEAPON_MORTAR_SUICIDE_BOUNCE, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MORTAR_MURDER_EXPLODE,	 		INFO_WEAPON_MORTAR_MURDER_EXPLODE,	 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MORTAR_MURDER_BOUNCE, 			INFO_WEAPON_MORTAR_MURDER_BOUNCE, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HAGAR_SUICIDE, 					INFO_WEAPON_HAGAR_SUICIDE, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HAGAR_MURDER_BURST, 			INFO_WEAPON_HAGAR_MURDER_BURST, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HAGAR_MURDER_SPRAY, 			INFO_WEAPON_HAGAR_MURDER_SPRAY, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HLAC_SUICIDE, 					INFO_WEAPON_HLAC_SUICIDE, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HLAC_MURDER, 					INFO_WEAPON_HLAC_MURDER, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_HOOK_MURDER,					INFO_WEAPON_HOOK_MURDER,					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_LASER_SUICIDE, 					INFO_WEAPON_LASER_SUICIDE, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_LASER_MURDER, 					INFO_WEAPON_LASER_MURDER, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MINELAYER_SUICIDE, 				INFO_WEAPON_MINELAYER_SUICIDE, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MINELAYER_MURDER, 				INFO_WEAPON_MINELAYER_MURDER, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_MINSTANEX_MURDER, 				INFO_WEAPON_MINSTANEX_MURDER, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_NEX_MURDER, 					INFO_WEAPON_NEX_MURDER, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_RIFLE_MURDER_HAIL_PIERCING,		INFO_WEAPON_RIFLE_MURDER_HAIL_PIERCING,		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_RIFLE_MURDER_HAIL, 				INFO_WEAPON_RIFLE_MURDER_HAIL, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_RIFLE_MURDER_PIERCING, 			INFO_WEAPON_RIFLE_MURDER_PIERCING, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_RIFLE_MURDER, 					INFO_WEAPON_RIFLE_MURDER, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_RIFLE_MURDER_HEADSHOT, 			INFO_WEAPON_RIFLE_MURDER_HEADSHOT, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ROCKETLAUNCHER_SUICIDE, 		INFO_WEAPON_ROCKETLAUNCHER_SUICIDE, 		NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ROCKETLAUNCHER_MURDER_DIRECT, 	INFO_WEAPON_ROCKETLAUNCHER_MURDER_DIRECT, 	NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ROCKETLAUNCHER_MURDER_SPLASH, 	INFO_WEAPON_ROCKETLAUNCHER_MURDER_SPLASH, 	NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_SEEKER_SUICIDE, 				INFO_WEAPON_SEEKER_SUICIDE, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_SEEKER_MURDER_TAG, 				INFO_WEAPON_SEEKER_MURDER_TAG, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_SEEKER_MURDER_SPRAY, 			INFO_WEAPON_SEEKER_MURDER_SPRAY, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_SHOTGUN_MURDER_SLAP, 			INFO_WEAPON_SHOTGUN_MURDER_SLAP, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_SHOTGUN_MURDER, 				INFO_WEAPON_SHOTGUN_MURDER, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_TUBA_SUICIDE, 					INFO_WEAPON_TUBA_SUICIDE, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_TUBA_MURDER, 					INFO_WEAPON_TUBA_MURDER, 					NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ACCORDEON_SUICIDE, 				INFO_WEAPON_ACCORDEON_SUICIDE, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_ACCORDEON_MURDER, 				INFO_WEAPON_ACCORDEON_MURDER, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_KLEINBOTTLE_SUICIDE, 			INFO_WEAPON_KLEINBOTTLE_SUICIDE, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_KLEINBOTTLE_MURDER, 			INFO_WEAPON_KLEINBOTTLE_MURDER, 			NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_UZI_MURDER_SNIPE, 				INFO_WEAPON_UZI_MURDER_SNIPE, 				NO_MSG) \
	MSG_WEAPON_NOTIF(WEAPON_UZI_MURDER_SPRAY, 				INFO_WEAPON_UZI_MURDER_SPRAY, 				NO_MSG) 

#define MSG_DEATH_NOTIFICATIONS \
	MSG_DEATH_NOTIF(DEATH_EMPTY,						NO_MSG,									NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_SELF_CUSTOM,					INFO_DEATH_SELF_GENERIC,				CENTER_DEATH_SELF_CUSTOM) \
	MSG_DEATH_NOTIF(DEATH_SELF_GENERIC,					INFO_DEATH_SELF_GENERIC,				CENTER_DEATH_SELF_GENERIC) \
	MSG_DEATH_NOTIF(DEATH_SELF_VOID,					INFO_DEATH_SELF_VOID,					CENTER_DEATH_SELF_VOID) \
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
	MSG_DEATH_NOTIF(DEATH_SELF_CHEAT,					INFO_DEATH_SELF_CHEAT,					CENTER_DEATH_SELF_CHEAT) \
	MSG_DEATH_NOTIF(DEATH_SELF_TOUCHEXPLODE,			INFO_DEATH_SELF_TOUCHEXPLODE,			CENTER_DEATH_SELF_TOUCHEXPLODE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TELEFRAG,					INFO_DEATH_MURDER_TELEFRAG,					NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FALL,						INFO_DEATH_MURDER_FALL,						NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_DROWN,						INFO_DEATH_MURDER_DROWN,					NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_LAVA,						INFO_DEATH_MURDER_LAVA,						NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_SLIME,						INFO_DEATH_MURDER_SLIME,					NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_SHOOTING_STAR,				INFO_DEATH_MURDER_SHOOTING_STAR,			NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_SWAMP,						INFO_DEATH_MURDER_SWAMP,					NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_VOID,						INFO_DEATH_MURDER_VOID,						NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TOUCHEXPLODE,				INFO_DEATH_MURDER_TOUCHEXPLODE,				NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_CHEAT,						INFO_DEATH_MURDER_CHEAT,					NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FIRE,						INFO_DEATH_MURDER_FIRE,						NO_MSG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG,							NO_MSG,						CENTER_DEATH_MURDER_FRAG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED,						NO_MSG,						CENTER_DEATH_MURDER_FRAGGED) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG,						NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAG) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED,					NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAGGED) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_FIRST,					INFO_DEATH_FIRSTBLOOD,		CENTER_DEATH_MURDER_FRAG_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_FIRST,					NO_MSG,						CENTER_DEATH_MURDER_FRAGGED_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_FIRST,				INFO_DEATH_FIRSTBLOOD,		CENTER_DEATH_MURDER_TYPEFRAG_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_FIRST,				NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_VERBOSE,					NO_MSG,						CENTER_DEATH_MURDER_FRAG_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_VERBOSE,				NO_MSG,						CENTER_DEATH_MURDER_FRAGGED_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_VERBOSE,				NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAG_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_VERBOSE,			NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAGGED_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAG_FIRST_VERBOSE,			INFO_DEATH_FIRSTBLOOD,		CENTER_DEATH_MURDER_FRAG_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_FRAGGED_FIRST_VERBOSE,			NO_MSG,						CENTER_DEATH_MURDER_FRAGGED_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE,		INFO_DEATH_FIRSTBLOOD,		CENTER_DEATH_MURDER_TYPEFRAG_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE,		NO_MSG,						CENTER_DEATH_MURDER_TYPEFRAGGED_FIRST_VERBOSE) \
	MSG_DEATH_NOTIF(DEATH_TEAMKILL_FRAG,						NO_MSG,						CENTER_DEATH_TEAMKILL_FRAG) \
	MSG_DEATH_NOTIF(DEATH_TEAMKILL_FRAGGED,						NO_MSG,						CENTER_DEATH_TEAMKILL_FRAGGED)

	
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

float notif_checkstring(string input)
{
	if not(input == "") { return TRUE; }
	else { return FALSE; }
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

#define NOTIF_Write(type,name,text) notif_msg = sprintf("seta %s 1 // %s - %s\n", name, type, strreplace("\n", "\\n", text)); fputs(fh, notif_msg); if(alsoprint) { print(strreplace("^", "^^", notif_msg)); }
void Dump_Notifications(float fh, float alsoprint)
{
	float MSG_INFO_NOTIFS, MSG_CENTER_NOTIFS, MSG_WEAPON_NOTIFS, MSG_DEATH_NOTIFS;
	string notif_msg;
	#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) { ++MSG_INFO_NOTIFS; NOTIF_Write("MSG_INFO", VAR_TO_TEXT(name), normal) }
	#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) { ++MSG_CENTER_NOTIFS; NOTIF_Write("MSG_CENTER", VAR_TO_TEXT(name), normal) }
	#define MSG_WEAPON_NOTIF(name,infoname,centername) { ++MSG_WEAPON_NOTIFS; NOTIF_Write("MSG_WEAPON", VAR_TO_TEXT(name),sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))) }
	#define MSG_DEATH_NOTIF(name,infoname,centername) { ++MSG_DEATH_NOTIFS; NOTIF_Write("MSG_DEATH", VAR_TO_TEXT(name), sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))) }
	MSG_INFO_NOTIFICATIONS
	MSG_CENTER_NOTIFICATIONS
	MSG_WEAPON_NOTIFICATIONS
	MSG_DEATH_NOTIFICATIONS
	#undef MSG_INFO_NOTIF
	#undef MSG_CENTER_NOTIF
	#undef MSG_WEAPON_NOTIF
	#undef MSG_DEATH_NOTIF
	print(sprintf("Notification counts: MSG_INFO = %d, MSG_CENTER = %d, MSG_WEAPON = %d, MSG_DEATH = %d\n", MSG_INFO_NOTIFS, MSG_CENTER_NOTIFS, MSG_WEAPON_NOTIFS, MSG_DEATH_NOTIFS));
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
	//print("Local_Notification(", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", s1, ", ", s2, ", ", ftos(f1), strcat(", ", ftos(f2), ", ", ftos(f3), ");\n")));
	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					if(notif_checkstring(normal)) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } \
					if(notif_checkstring(icon)) { HUD_Notify_Push(icon, hudargs); } \
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
					if(notif_checkstring(normal)) { centerprint_generic(HANDLE_CPID(cpid), sprintf(CCR(normal_or_gentle(normal, gentle)), args), durcnt); } \
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
	if(broadcast && net_type && net_name)
	{
		dprint("Send_Notification(", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", s1, ", ", s2, ", ", ftos(f1), strcat(", ", ftos(f2), ", ", ftos(f3), ");\n")));

		float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
		
		if(notif_stringcount(s1, s2) > stringcount) { backtrace("Too many string arguments for notification!\n"); return; }
		if(notif_floatcount(f1, f2, f3) > floatcount) { backtrace("Too many float arguments for notification!\n"); return; }

		#define WRITE_BROADCAST(msg) \
			WriteByte(msg, SVC_TEMPENTITY); \
			WriteByte(msg, TE_CSQC_NOTIFICATION); \
			WriteByte(msg, net_type); \
			WriteShort(msg, net_name); \
			if(stringcount >= 1) { WriteString(msg, s1); } \
			if(stringcount == 2) { WriteString(msg, s2); } \
			if(floatcount >= 1) { WriteLong(msg, f1); } \
			if(floatcount >= 2) { WriteLong(msg, f2); } \
			if(floatcount == 3) { WriteLong(msg, f3); }
			
		switch(broadcast)
		{
			case MSG_ONE: // personal/direct notification sent to ONE person and their spectators
			{
				if(client && (clienttype(client) == CLIENTTYPE_REAL) && (client.flags & FL_CLIENT))
				{
					msg_entity = client;
					WRITESPECTATABLE_MSG_ONE({WRITE_BROADCAST(MSG_ONE)});
				}
				break;
			}
			
			case MSG_ALL: // global notification sent to EVERYONE
			{
				WRITE_BROADCAST(MSG_ALL)
				break;
			}
			
			default: { backtrace("Unknown MSG_ type to write with!\n"); break; }
		}

		#undef WRITE_BROADCAST

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
