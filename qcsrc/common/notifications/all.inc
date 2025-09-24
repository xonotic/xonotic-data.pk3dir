// ====================================
//  Notifications List and Information
// ====================================
/*
 List of all notifications (including identifiers and display information)
 Possible Tokens:
    default, name, strnum, flnum,
    channel, sound, volume, position,
    args, hudargs, icon, cpid, durcnt, normal, gentle,
    anncename, infoname, centername,
    challow, chtype, optiona, optionb
 Format Specifications:
    name: VAR: Name of notification
    MSG_ANNCE:
      default: FLOAT: Default setting for whether the notification is enabled or not
         ^-> 0 = disabled, 1 = enabled if gentle is disabled, 2 = always enabled
      sound: STRING: Filename for the announcement sound
      channel: FLOAT: Sound channel to broadcast on to
      volume: FLOAT: Volume setting for the announcement sound
      position: FLOAT: Attenuation/positioning value
    MSG_INFO:
      default: FLOAT: Default setting for whether the notification is enabled or not
         ^-> 0 = disabled, 1 = enabled, 2 = also print to chat box
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: STRING: Arguments for Local_Notification_sprintf()
      hudargs: STRING: Arguments for Local_Notification_HUD_Notify_Push()
      icon: STRING: icon string name for the hud notify panel, "" if no icon is used
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_CENTER:
      default: FLOAT: Default setting for whether the notification is enabled or not
         ^-> 0 = disabled, 1 = enabled
      strnum: FLOAT: Number of STRING arguments (so that networking knows how many to send/receive)
      flnum: FLOAT: Number of FLOAT arguments (so that networking knows how many to send/receive)
      args: STRING: Arguments for Local_Notification_sprintf()
      cpid: FLOAT: centerprint ID number (CPID_*), CPID_Null if no CPID is needed
      durcnt: XPD(FLOAT, FLOAT): Duration/Countdown: extra arguments for centerprint messages
      normal: STRING: Normal message (string for sprintf when gentle messages are NOT enabled)
      gentle: STRING: Gentle message (string for sprintf when gentle messages ARE enabled)
    MSG_MULTI:
      default: FLOAT: Default setting for whether the notification is enabled or not
         ^-> 0 = disabled, 1 = enabled
      anncename: VAR: Name of announcer notification for reference
      infoname: VAR: Name of info notification for reference
      centername: VAR: Name of centerprint notification for reference
    MSG_CHOICE:
      default: FLOAT: Default setting for whether the notification is enabled or not
         ^-> 0 = disabled, 1 = select option A, 2 = selection option B
      challow: FLOAT: Default setting for server allowing choices other than A
         ^-> 0 = no choice, 1 = allowed in warmup, 2 = always allowed
      chtype: VAR: Notification message type for options
      optiona: VAR: Name of choice "A" notification for reference
      optionb: VAR: Name of choice "B" notification for reference

 Messages with ^F1, ^BG, ^TC, etc etc in them will replace those strings
 with colors according to the cvars the user has chosen. This allows for
 users to create unique color profiles for their HUD, giving more customization
 options to HUD designers and end users who want such a feature.

 Check out the definitions in util.qc/util.qh/teams.qh for string CCR(...) and
 string TCR(...) to better understand how these code replacements work.

 Additionally, you can find all the definitions and explanations for
 the argument values and what they return down below in this file.

 Guidlines for notification declaration (please try and follow these):
  Specific rules:
    - ALWAYS start the string with a color, preferably background.
    - ALWAYS reset a color after a name (this way they don't set it for the whole string).
    - NEVER add or remove tokens from the format, it SHOULD already work.
    - MSG_INFO hudargs must always be ATTACKER -> VICTIM
    - MSG_INFO and MSG_CENTER should NOT end with a new line

 General rules:
    - Be clean and simple with your notification naming,
     nothing too long for the name field... Abbreviations are your friend. :D
    - Keep the spacing as clean as possible... if the arguments are abnormally long,
      it's okay to go out of line a bit... but try and keep it clean still.
    - Use ONLY spaces for spacing in the notification list, tabs are too inconsistent
      with keeping alignment on different mediums.
    - Sort the notifications in the most appropriate order for their tasks.

 Final note: DO NOT PROVIDE MORE ARGUMENTS THAN NECESSARY FOR THE NOTIFICATION YOU'RE CALLING!
      The system is designed to save as much networking bandwidth as possible,
      so please dynamically control your argument sending to fit *exactly* what is required.
      If you send a notification with mismatching arguments, Send_Notification() will error.
*/

// NOTE: leaving BOLD_OPERATOR outside of translatable messages has 2 advantages:
// 1. translators don't have to deal with it
// 2. messages can be changed to bold / normal without the need to translate them again
#define BOLD(translatable_msg) strcat(BOLD_OPERATOR, translatable_msg)

// default value for annce notification cvars (notification_ANNCE_*):
// 0: off, 1: announce only if gentle mode is off, 2: announce always
#define N___NEVER 0
#define N_GNTLOFF 1
#define N__ALWAYS 2

// default time for announcer queue (time to wait before the next announcer is played)
// -1 = bypass queue and play the announcer immediately
// 0 = use the announcer sound length
// >0 = use the specified time in seconds
#define ANNCE_INSTANT -1
#define ANNCE_LENGTH 0
#define ANNCE_DEFTIME 2

#define MULTITEAM_ANNCE(prefix, defaultvalue, sound, channel, volume, position) \
    NOTIF_ADD_AUTOCVAR(ANNCE_##prefix, defaultvalue) \
    MSG_ANNCE_NOTIF_TEAM(NUM_TEAM_1, prefix##_RED, prefix, defaultvalue, sprintf(sound, strtolower(STATIC_NAME_TEAM_1)), channel, volume, position) \
    MSG_ANNCE_NOTIF_TEAM(NUM_TEAM_2, prefix##_BLUE, prefix, defaultvalue, sprintf(sound, strtolower(STATIC_NAME_TEAM_2)), channel, volume, position) \
    MSG_ANNCE_NOTIF_TEAM(NUM_TEAM_3, prefix##_YELLOW, prefix, defaultvalue, sprintf(sound, strtolower(STATIC_NAME_TEAM_3)), channel, volume, position) \
    MSG_ANNCE_NOTIF_TEAM(NUM_TEAM_4, prefix##_PINK, prefix, defaultvalue, sprintf(sound, strtolower(STATIC_NAME_TEAM_4)), channel, volume, position)

// MSG_ANNCE_NOTIFICATIONS
    MSG_ANNCE_NOTIF(ACHIEVEMENT_AIRSHOT,        N_GNTLOFF, "airshot",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_AMAZING,        N_GNTLOFF, "amazing",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_AWESOME,        N_GNTLOFF, "awesome",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_BOTLIKE,        N_GNTLOFF, "botlike",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_ELECTROBITCH,   N__ALWAYS, "electrobitch",      CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_IMPRESSIVE,     N_GNTLOFF, "impressive",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(ACHIEVEMENT_YODA,           N_GNTLOFF, "yoda",              CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(BEGIN,                      N__ALWAYS, "begin",             CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(HEADSHOT,                   N__ALWAYS, "headshot",          CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(KILLSTREAK_03,              N_GNTLOFF, "03kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_05,              N_GNTLOFF, "05kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_10,              N_GNTLOFF, "10kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_15,              N_GNTLOFF, "15kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_20,              N_GNTLOFF, "20kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_25,              N_GNTLOFF, "25kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(KILLSTREAK_30,              N_GNTLOFF, "30kills",           CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(INSTAGIB_LASTSECOND,        N_GNTLOFF, "lastsecond",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(INSTAGIB_NARROWLY,          N_GNTLOFF, "narrowly",          CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(INSTAGIB_TERMINATED,        N_GNTLOFF, "terminated",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(MULTIFRAG,                  N___NEVER, "multifrag",         CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(NUM_1,                      N__ALWAYS, "1",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_2,                      N__ALWAYS, "2",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_3,                      N__ALWAYS, "3",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_4,                      N__ALWAYS, "4",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_5,                      N__ALWAYS, "5",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_6,                      N__ALWAYS, "6",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_7,                      N__ALWAYS, "7",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_8,                      N__ALWAYS, "8",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_9,                      N__ALWAYS, "9",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_10,                     N__ALWAYS, "10",                CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(NUM_GAMESTART_1,            N__ALWAYS, "1",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_2,            N__ALWAYS, "2",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_3,            N__ALWAYS, "3",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_4,            N__ALWAYS, "4",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_5,            N__ALWAYS, "5",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_6,            N___NEVER, "6",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_7,            N___NEVER, "7",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_8,            N___NEVER, "8",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_9,            N___NEVER, "9",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_GAMESTART_10,           N___NEVER, "10",                CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(NUM_KILL_1,                 N___NEVER, "1",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_2,                 N___NEVER, "2",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_3,                 N___NEVER, "3",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_4,                 N___NEVER, "4",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_5,                 N___NEVER, "5",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_6,                 N___NEVER, "6",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_7,                 N___NEVER, "7",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_8,                 N___NEVER, "8",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_9,                 N___NEVER, "9",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_KILL_10,                N___NEVER, "10",                CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(NUM_RESPAWN_1,              N___NEVER, "1",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_2,              N___NEVER, "2",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_3,              N___NEVER, "3",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_4,              N___NEVER, "4",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_5,              N___NEVER, "5",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_6,              N___NEVER, "6",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_7,              N___NEVER, "7",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_8,              N___NEVER, "8",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_9,              N___NEVER, "9",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_RESPAWN_10,             N___NEVER, "10",                CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_1,           N__ALWAYS, "1",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_2,           N__ALWAYS, "2",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_3,           N__ALWAYS, "3",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_4,           N___NEVER, "4",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_5,           N___NEVER, "5",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_6,           N___NEVER, "6",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_7,           N___NEVER, "7",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_8,           N___NEVER, "8",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_9,           N___NEVER, "9",                 CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)
    MSG_ANNCE_NOTIF(NUM_ROUNDSTART_10,          N___NEVER, "10",                CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(PREPARE,                    N__ALWAYS, "prepareforbattle",  CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(REMAINING_FRAG_1,           N_GNTLOFF, "1fragleft",         CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(REMAINING_FRAG_2,           N_GNTLOFF, "2fragsleft",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(REMAINING_FRAG_3,           N_GNTLOFF, "3fragsleft",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(REMAINING_MIN_1,            N__ALWAYS, "1minuteremains",    CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(REMAINING_MIN_5,            N__ALWAYS, "5minutesremain",    CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

    MSG_ANNCE_NOTIF(TIMEOUT,                    N__ALWAYS, "timeoutcalled",     CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_INSTANT)

    MSG_ANNCE_NOTIF(VOTE_ACCEPT,                N__ALWAYS, "voteaccept",        CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(VOTE_CALL,                  N__ALWAYS, "votecall",          CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)
    MSG_ANNCE_NOTIF(VOTE_FAIL,                  N__ALWAYS, "votefail",          CH_INFO, VOL_BASEVOICE, ATTEN_NONE, ANNCE_DEFTIME)

#undef N___NEVER
#undef N_GNTLOFF
#undef N__ALWAYS

// default value for info notification cvars (notification_INFO_*):
// 0: off, 1: display in console, 2: display in chatbox and console
#define N_DISABLE 0
#define N_CONSOLE 1
#define N_CHATCON 2

// hack to work around the limitations of sprintf
string multiteam_info_sprintf(string input, string teamname) { return ((input != "") ? sprintf(input, teamname) : ""); }

#define MULTITEAM_INFO(prefix, defaultvalue, strnum, flnum, args, hudargs, icon, normal, gentle, type) \
    NOTIF_ADD_AUTOCVAR(INFO_##prefix, defaultvalue) \
    MSG_INFO_NOTIF_TEAM(NUM_TEAM_1, prefix##_RED, prefix, defaultvalue, strnum, flnum, args, hudargs, multiteam_info_sprintf(icon, strtolower(STATIC_NAME_TEAM_1)), TCR(normal, type, 1), TCR(gentle, type, 1)) \
    MSG_INFO_NOTIF_TEAM(NUM_TEAM_2, prefix##_BLUE, prefix, defaultvalue, strnum, flnum, args, hudargs, multiteam_info_sprintf(icon, strtolower(STATIC_NAME_TEAM_2)), TCR(normal, type, 2), TCR(gentle, type, 2)) \
    MSG_INFO_NOTIF_TEAM(NUM_TEAM_3, prefix##_YELLOW, prefix, defaultvalue, strnum, flnum, args, hudargs, multiteam_info_sprintf(icon, strtolower(STATIC_NAME_TEAM_3)), TCR(normal, type, 3), TCR(gentle, type, 3)) \
    MSG_INFO_NOTIF_TEAM(NUM_TEAM_4, prefix##_PINK, prefix, defaultvalue, strnum, flnum, args, hudargs, multiteam_info_sprintf(icon, strtolower(STATIC_NAME_TEAM_4)), TCR(normal, type, 4), TCR(gentle, type, 4))

// MSG_INFO_NOTIFICATIONS
    MSG_INFO_NOTIF(CHAT_DISABLED,                           N_CHATCON,  0, 0, "", "",       "",     _("^F4NOTE: ^BGChat is currently disabled on this server"), "")
    MSG_INFO_NOTIF(CHAT_NOSPECTATORS,                       N_CHATCON,  0, 0, "", "",       "",     _("^F4NOTE: ^BGSpectator chat is not sent to players during the match"), "")
    MSG_INFO_NOTIF(CHAT_PRIVATE_DISABLED,                   N_CHATCON,  0, 0, "", "",       "",     _("^F4NOTE: ^BGPrivate chat is currently disabled on this server"), "")
    MSG_INFO_NOTIF(CHAT_SPECTATOR_DISABLED,                 N_CHATCON,  0, 0, "", "",       "",     _("^F4NOTE: ^BGSpectator chat is currently disabled on this server"), "")
    MSG_INFO_NOTIF(CHAT_TEAM_DISABLED,                      N_CHATCON,  0, 0, "", "",       "",     _("^F4NOTE: ^BGTeam chat is currently disabled on this server"), "")

    MULTITEAM_INFO(CTF_CAPTURE,                             N_CONSOLE,  1, 0, "s1", "s1",                       "notify_%s_captured",       _("^BG%s^BG captured the ^TC^TT^BG flag"), "", FLAG)
    MULTITEAM_INFO(CTF_CAPTURE_BROKEN,                      N_CONSOLE,  2, 2, "s1 f1dtime s2 f2dtime", "s1",    "notify_%s_captured",       _("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%s^BG seconds, breaking ^BG%s^BG's previous record of ^F2%s^BG seconds"), "", FLAG)
    MSG_INFO_NOTIF(CTF_CAPTURE_NEUTRAL,                     N_CONSOLE,  1, 0, "s1", "s1",                       "notify_neutral_captured",  _("^BG%s^BG captured the flag"), "")
    MULTITEAM_INFO(CTF_CAPTURE_TIME,                        N_CONSOLE,  1, 1, "s1 f1dtime", "s1",               "notify_%s_captured",       _("^BG%s^BG captured the ^TC^TT^BG flag in ^F1%s^BG seconds"), "", FLAG)
    MULTITEAM_INFO(CTF_CAPTURE_UNBROKEN,                    N_CONSOLE,  2, 2, "s1 f1dtime s2 f2dtime", "s1",    "notify_%s_captured",       _("^BG%s^BG captured the ^TC^TT^BG flag in ^F2%s^BG seconds, failing to break ^BG%s^BG's previous record of ^F1%s^BG seconds"), "", FLAG)
    MULTITEAM_INFO(CTF_FLAGRETURN_ABORTRUN,                 N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe ^TC^TT^BG flag was returned to base by its owner"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_ABORTRUN_NEUTRAL,         N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe flag was returned by its owner"), "")
    MULTITEAM_INFO(CTF_FLAGRETURN_DAMAGED,                  N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe ^TC^TT^BG flag was destroyed and returned to base"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_DAMAGED_NEUTRAL,          N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe flag was destroyed and returned to base"), "")
    MULTITEAM_INFO(CTF_FLAGRETURN_DROPPED,                  N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe ^TC^TT^BG flag was dropped in the base and returned itself"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_DROPPED_NEUTRAL,          N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe flag was dropped in the base and returned itself"), "")
    MULTITEAM_INFO(CTF_FLAGRETURN_NEEDKILL,                 N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe ^TC^TT^BG flag fell somewhere it couldn't be reached and returned to base"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_NEEDKILL_NEUTRAL,         N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe flag fell somewhere it couldn't be reached and returned to base"), "")
    MULTITEAM_INFO(CTF_FLAGRETURN_SPEEDRUN,                 N_CONSOLE,  0, 1, "f1dtime", "",                    "",                         _("^BGThe ^TC^TT^BG flag became impatient after ^F1%.2f^BG seconds and returned itself"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_SPEEDRUN_NEUTRAL,         N_CONSOLE,  0, 1, "f1dtime", "",                    "",                         _("^BGThe flag became impatient after ^F1%.2f^BG seconds and returned itself"), "")
    MULTITEAM_INFO(CTF_FLAGRETURN_TIMEOUT,                  N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe ^TC^TT^BG flag has returned to the base"), "", FLAG)
    MSG_INFO_NOTIF(CTF_FLAGRETURN_TIMEOUT_NEUTRAL,          N_CONSOLE,  0, 0, "", "",                           "",                         _("^BGThe flag has returned to the base"), "")
    MULTITEAM_INFO(CTF_LOST,                                N_CONSOLE,  1, 0, "s1", "s1",                       "notify_%s_lost",           _("^BG%s^BG lost the ^TC^TT^BG flag"), "", FLAG)
    MSG_INFO_NOTIF(CTF_LOST_NEUTRAL,                        N_CONSOLE,  1, 0, "s1", "s1",                       "notify_neutral_lost",      _("^BG%s^BG lost the flag"), "")
    MULTITEAM_INFO(CTF_PICKUP,                              N_CONSOLE,  1, 0, "s1", "s1",                       "notify_%s_taken",          _("^BG%s^BG got the ^TC^TT^BG flag"), "", FLAG)
    MSG_INFO_NOTIF(CTF_PICKUP_NEUTRAL,                      N_CONSOLE,  1, 0, "s1", "s1",                       "notify_neutral_taken",     _("^BG%s^BG got the flag"), "")
    MULTITEAM_INFO(CTF_RETURN,                              N_CONSOLE,  1, 0, "s1", "s1",                       "notify_%s_returned",       _("^BG%s^BG returned the ^TC^TT^BG flag"), "", FLAG)
    MULTITEAM_INFO(CTF_RETURN_MONSTER,                      N_CONSOLE,  1, 0, "s1", "s1",                       "notify_%s_returned",       _("^BG%s^BG returned the ^TC^TT^BG flag"), "", FLAG)

    MSG_INFO_NOTIF(COINTOSS,                                N_CHATCON,  1, 0, "s1", "",     "",     _("^F2Throwing coin... Result: %s^F2!"), "")

    MSG_INFO_NOTIF(JETPACK_NOFUEL,                          N_CONSOLE,  0, 0, "", "",       "",     _("^BGYou don't have any fuel for the ^F1Jetpack"), "")

    MSG_INFO_NOTIF(SUPERSPEC_MISSING_UID,                   N_CHATCON,  0, 0, "", "",       "",     _("^F2You lack a UID, superspec options will not be saved/restored"), "")

    MSG_INFO_NOTIF(CA_JOIN_LATE,                            N_CONSOLE,  0, 0, "", "",       "",     _("^F1Round already started, you will join the game in the next round"), "")
    MSG_INFO_NOTIF(CA_LEAVE,                                N_CONSOLE,  0, 0, "", "",       "",     _("^F2You will spectate in the next round"), "")

    MSG_INFO_NOTIF(COUNTDOWN_RESTART,                       N_CHATCON,  0, 0, "", "",       "",     _("^F2Match is restarting..."), "")
    MSG_INFO_NOTIF(COUNTDOWN_STOP_MINPLAYERS,               N_CHATCON,  0, 1, "f1", "",     "",     strcat(_("^F4Countdown stopped!"), "\n^BG", _("%s players are needed for this match.")), "")
    MSG_INFO_NOTIF(COUNTDOWN_STOP_BADTEAMS,                 N_CHATCON,  0, 0, "", "",       "",     strcat(_("^F4Countdown stopped!"), "\n^BG", _("Teams are too unbalanced.")), "")

    MSG_INFO_NOTIF(DEATH_MURDER_BUFF,                       N_CONSOLE,  3, 3, "spree_inf s1 s2 f3buffname s3loc spree_end", "s2 s1",    "notify_death",         _("^BG%s%s^K1 was killed by ^BG%s^K1's ^BG%s^K1 buff ^K1%s%s"), _("^BG%s%s^K1 was scored against by ^BG%s^K1's ^BG%s^K1 buff ^K1%s%s"))
    MSG_INFO_NOTIF(DEATH_MURDER_CHEAT,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was unfairly eliminated by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_DROWN,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_water",         _("^BG%s%s^K1 was drowned by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_FALL,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_fall",          _("^BG%s%s^K1 was grounded by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_FIRE,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was burnt up into a crisp by ^BG%s^K1%s%s"), _("^BG%s%s^K1 felt a little hot from ^BG%s^K1's fire^K1%s%s"))
    MSG_INFO_NOTIF(DEATH_MURDER_LAVA,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_lava",          _("^BG%s%s^K1 was cooked by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_MONSTER,                    N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was pushed in front of a monster by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_NADE,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "nade_normal",          _("^BG%s%s^K1 was blown up by ^BG%s^K1's Nade%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_NADE_NAPALM,                N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "nade_napalm",          _("^BG%s%s^K1 was burned to death by ^BG%s^K1's Napalm Nade%s%s"), _("^BG%s%s^K1 got too close to a napalm explosion%s%s"))
    MSG_INFO_NOTIF(DEATH_MURDER_NADE_ICE,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "nade_ice",             _("^BG%s%s^K1 was blown up by ^BG%s^K1's Ice Nade%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_NADE_HEAL,                  N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "nade_heal",            _("^BG%s%s^K1 has not been healed by ^BG%s^K1's Healing Nade%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_SHOOTING_STAR,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_shootingstar",  _("^BG%s%s^K1 was shot into space by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_SLIME,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_slime",         _("^BG%s%s^K1 was slimed by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_SWAMP,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_slime",         _("^BG%s%s^K1 was preserved by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_TELEFRAG,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_telefrag",      _("^BG%s%s^K1 was telefragged by ^BG%s^K1%s%s"), _("^BG%s%s^K1 tried to occupy ^BG%s^K1's teleport destination space%s%s"))
    MSG_INFO_NOTIF(DEATH_MURDER_TOUCHEXPLODE,               N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 died in an accident with ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_BUMB_DEATH,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 got caught in the blast when ^BG%s^K1's Bumblebee exploded%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_BUMB_GUN,                N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 saw the pretty lights of ^BG%s^K1's Bumblebee gun%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_CRUSH,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was crushed by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_RAPT_BOMB,               N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was cluster bombed by ^BG%s^K1's Raptor%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_RAPT_CANNON,             N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 couldn't resist ^BG%s^K1's purple blobs%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_RAPT_DEATH,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 got caught in the blast when ^BG%s^K1's Raptor exploded%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_SPID_DEATH,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 got caught in the blast when ^BG%s^K1's Spiderbot exploded%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_SPID_MINIGUN,            N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 got shredded by ^BG%s^K1's Spiderbot%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_SPID_ROCKET,             N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was blasted to bits by ^BG%s^K1's Spiderbot%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_WAKI_DEATH,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 got caught in the blast when ^BG%s^K1's Racer exploded%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_WAKI_GUN,                N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 was bolted down by ^BG%s^K1's Racer%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VH_WAKI_ROCKET,             N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_death",         _("^BG%s%s^K1 couldn't find shelter from ^BG%s^K1's Racer%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VOID,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",               "notify_void",          _("^BG%s%s^K1 was thrown into a world of hurt by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(DEATH_MURDER_VOID_ENT,                   N_CONSOLE,  4, 2, "spree_inf s1 s3#s2 #s2 s4loc spree_end", "s2 s1",        "notify_void",            "^BG%s%s^K1 %s%s%s%s", "")

    MSG_INFO_NOTIF(DEATH_SELF_AUTOTEAMCHANGE,               N_CONSOLE,  2, 1, "s1 death_team s2loc", "",        "",                     _("^BG%s^K1 was moved into the %s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_BETRAYAL,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_teamkill_red",  _("^BG%s^K1 became enemies with the Lord of Teamplay%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_CAMP,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_camping",       _("^BG%s^K1 thought they found a nice camping ground%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_CHEAT,                        N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_selfkill",      _("^BG%s^K1 unfairly eliminated themselves%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_CUSTOM,                       N_CONSOLE,  3, 1, "s1 s2 s3loc spree_lost", "s1",   "notify_void",            "^BG%s^K1 %s^K1%s%s", "")
    MSG_INFO_NOTIF(DEATH_SELF_DROWN,                        N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_water",         _("^BG%s^K1 couldn't catch their breath%s%s"), _("^BG%s^K1 was in the water for too long%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_FALL,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_fall",          _("^BG%s^K1 hit the ground with a crunch%s%s"), _("^BG%s^K1 hit the ground with a bit too much force%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_FIRE,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 became a bit too crispy%s%s"), _("^BG%s^K1 felt a little hot%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_GENERIC,                      N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_selfkill",      _("^BG%s^K1 died%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_LAVA,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_lava",          _("^BG%s^K1 turned into hot slag%s%s"), _("^BG%s^K1 found a hot place%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_MON_MAGE,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was exploded by a Mage%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_GOLEM_CLAW,               N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1's innards became outwards by a Golem%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_GOLEM_SMASH,              N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was smashed by a Golem%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_GOLEM_ZAP,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was zapped to death by a Golem%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_SPIDER,                   N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was bitten by a Spider%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_WYVERN,                   N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was fireballed by a Wyvern%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_ZOMBIE_JUMP,              N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 joins the Zombies%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_MON_ZOMBIE_MELEE,             N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was given kung fu lessons by a Zombie%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_NADE,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "nade_normal",          _("^BG%s^K1 mastered the art of self-nading%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_NADE_NAPALM,                  N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "nade_napalm",          _("^BG%s^K1 was burned to death by their own Napalm Nade%s%s"), _("^BG%s^K1 decided to take a look at the results of their napalm explosion%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_NADE_ICE,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "nade_ice",             _("^BG%s^K1 mastered the art of self-nading%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_NADE_HEAL,                    N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "nade_heal",            _("^BG%s^K1's Healing Nade didn't quite heal them%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_NOAMMO,                       N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_outofammo",     _("^BG%s^K1 died%s%s. What's the point of living without ammo?"), _("^BG%s^K1 ran out of ammo%s%s"))
    MSG_INFO_NOTIF(DEATH_SELF_ROT,                          N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 rotted away%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_SHOOTING_STAR,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_shootingstar",  _("^BG%s^K1 became a shooting star%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_SLIME,                        N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_slime",         _("^BG%s^K1 was slimed%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_SUICIDE,                      N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_selfkill",      _("^BG%s^K1 couldn't take it anymore%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_SWAMP,                        N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_slime",         _("^BG%s^K1 is now preserved for centuries to come%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TEAMCHANGE,                   N_CONSOLE,  2, 1, "s1 death_team s2loc", "",        "",                     _("^BG%s^K1 switched to the %s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TOUCHEXPLODE,                 N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 died in an accident%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET,                       N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 ran into a turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_EWHEEL,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was blasted away by an eWheel turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_FLAC,                  N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got caught up in the FLAC turret fire%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_HELLION,               N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was blasted away by a Hellion turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_HK,                    N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 could not hide from the Hunter turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_MACHINEGUN,            N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was riddled full of holes by a Machinegun turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_MLRS,                  N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got turned into smoldering gibs by an MLRS turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_PHASER,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was phased out by a turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_PLASMA,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got served some superheated plasma from a turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_TESLA,                 N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was electrocuted by a Tesla turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_WALK_GUN,              N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got served a lead enrichment by a Walker turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_WALK_MELEE,            N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was impaled by a Walker turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_TURRET_WALK_ROCKET,           N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was blasted away by a Walker turret%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_BUMB_DEATH,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got caught in the blast of a Bumblebee explosion%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_CRUSH,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was crushed by a vehicle%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_RAPT_BOMB,                 N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was caught in a Raptor cluster bomb%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_RAPT_DEATH,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got caught in the blast of a Raptor explosion%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_SPID_DEATH,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got caught in the blast of a Spiderbot explosion%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_SPID_ROCKET,               N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 was blasted to bits by a Spiderbot rocket%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_WAKI_DEATH,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 got caught in the blast of a Racer explosion%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VH_WAKI_ROCKET,               N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_death",         _("^BG%s^K1 couldn't find shelter from a Racer rocket%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VOID,                         N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",      "notify_void",          _("^BG%s^K1 ended up in the wrong place%s%s"), "")
    MSG_INFO_NOTIF(DEATH_SELF_VOID_ENT,                     N_CONSOLE,  3, 1, "s1 s2 s3loc spree_lost", "s1",   "notify_void",            "^BG%s^K1 %s%s%s", "")

    MULTITEAM_INFO(DEATH_TEAMKILL,                          N_CONSOLE,  3, 1, "s1 s2 s3loc spree_end", "s2 s1",     "notify_teamkill_%s",   _("^BG%s^K1 was betrayed by ^BG%s^K1%s%s"), "", NAME)

    MSG_INFO_NOTIF(DOMINATION_CAPTURE_TIME,                 N_CONSOLE,  2, 2, "s1 s2 f1points f2", "",       "",     strcat("^BG%s^BG%s^BG ", _("(%s every %s seconds)")), "") // example for translators: Red Team has captured the Strength control point (2 points every 5 seconds)

    MSG_INFO_NOTIF(FREEZETAG_FREEZE,                        N_CONSOLE,  2, 0, "s1 s2", "",      "",     _("^BG%s^K1 was frozen by ^BG%s"), "")
    MSG_INFO_NOTIF(FREEZETAG_REVIVED,                       N_CONSOLE,  2, 0, "s1 s2", "",      "",     _("^BG%s^K3 was revived by ^BG%s"), "")
    MSG_INFO_NOTIF(FREEZETAG_REVIVED_FALL,                  N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^K3 was revived by falling"), "")
    MSG_INFO_NOTIF(FREEZETAG_REVIVED_NADE,                  N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^K3 was revived by their Nade explosion"), "")
    MSG_INFO_NOTIF(FREEZETAG_AUTO_REVIVED,                  N_CONSOLE,  1, 1, "s1 f1", "",      "",     _("^BG%s^K3 was automatically revived after %s seconds"), "")
    MSG_INFO_NOTIF(FREEZETAG_SELF,                          N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^K1 froze themselves"), "")

    MULTITEAM_INFO(ROUND_TEAM_WIN,                          N_CONSOLE,  0, 0, "", "",           "",     _("^TC^TT^BG team wins the round"), "", NAME)
    MSG_INFO_NOTIF(ROUND_PLAYER_WIN,                        N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG wins the round"), "")
    MSG_INFO_NOTIF(ROUND_TIED,                              N_CONSOLE,  0, 0, "", "",           "",     _("^BGRound tied"), "")
    MSG_INFO_NOTIF(ROUND_OVER,                              N_CONSOLE,  0, 0, "", "",           "",     _("^BGRound over, there's no winner"), "")

    MSG_INFO_NOTIF(GODMODE_OFF,                             N_CONSOLE,  0, 1, "f1", "",         "",     _("^BGGodmode saved you %s units of damage, cheater!"), "")

    MSG_INFO_NOTIF(ITEM_BUFF,                               N_CONSOLE,  1, 1, "s1 item_buffname", "",       "",     _("^BG%s^BG got the %s^BG buff!"), "")
    MSG_INFO_NOTIF(ITEM_BUFF_LOST,                          N_CONSOLE,  1, 1, "s1 item_buffname", "",       "",     _("^BG%s^BG lost the %s^BG buff!"), "")
    MSG_INFO_NOTIF(ITEM_BUFF_DROP,                          N_CONSOLE,  0, 1, "item_buffname", "",          "",     _("^BGYou dropped the %s^BG buff!"), "")
    MSG_INFO_NOTIF(ITEM_BUFF_GOT,                           N_CONSOLE,  0, 1, "item_buffname", "",          "",     _("^BGYou got the %s^BG buff!"), "")

    MSG_INFO_NOTIF(ITEM_WEAPON_DONTHAVE,                    N_DISABLE,  0, 1, "item_wepname", "",                           "",     _("^BGYou do not have the ^F1%s"), "")
    MSG_INFO_NOTIF(ITEM_WEAPON_DROP,                        N_DISABLE,  0, 2, "item_wepname item_wepammo", "",              "",     _("^BGYou dropped the ^F1%s^BG%s"), "")
    MSG_INFO_NOTIF(ITEM_WEAPON_GOT,                         N_DISABLE,  0, 1, "item_wepname", "",                           "",     _("^BGYou got the ^F1%s"), "")
    MSG_INFO_NOTIF(ITEM_WEAPON_NOAMMO,                      N_DISABLE,  0, 1, "item_wepname", "",                           "",     _("^BGYou don't have enough ammo for the ^F1%s"), "")
    MSG_INFO_NOTIF(ITEM_WEAPON_PRIMORSEC,                   N_DISABLE,  0, 3, "item_wepname f2primsec f3primsec", "",       "",     _("^F1%s %s^BG is unable to fire, but its ^F1%s^BG can"), "")
    MSG_INFO_NOTIF(ITEM_WEAPON_UNAVAILABLE,                 N_DISABLE,  0, 1, "item_wepname", "",                           "",     _("^F1%s^BG is ^F4not available^BG on this map"), "")

    MSG_INFO_NOTIF(CONNECTING,                              N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG is connecting..."), "")
    MSG_INFO_NOTIF(JOIN_CONNECT,                            N_CHATCON,  1, 0, "s1", "",         "",     _("^BG%s^F3 connected"), "")
    MSG_INFO_NOTIF(JOIN_PLAY,                               N_CHATCON,  1, 0, "s1", "",         "",     _("^BG%s^F3 is now playing"), "")
    MULTITEAM_INFO(JOIN_PLAY_TEAM,                          N_CHATCON,  1, 0, "s1", "",         "",     _("^BG%s^F3 is now playing on the ^TC^TT team"), "", NAME)
    MULTITEAM_INFO(JOIN_WANTS_TEAM,                         N_CHATCON,  1, 0, "s1", "",         "",     _("^BG%s^F3 wants to play on the ^TC^TT team"), "", NAME)
    MSG_INFO_NOTIF(JOIN_WANTS,                              N_CHATCON,  1, 0, "s1", "",         "",     _("^BG%s^F3 wants to play"), "")

    MSG_INFO_NOTIF(KEEPAWAY_DROPPED,                        N_CONSOLE,  1, 0, "s1", "s1",       "notify_balldropped",       _("^BG%s^BG has dropped the ball!"), "")
    MSG_INFO_NOTIF(KEEPAWAY_PICKUP,                         N_CONSOLE,  1, 0, "s1", "s1",       "notify_ballpickedup",      _("^BG%s^BG has picked up the ball!"), "")

    MULTITEAM_INFO(KEYHUNT_CAPTURE,                         N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG captured the keys for the ^TC^TT team"), "", NAME)
    MULTITEAM_INFO(KEYHUNT_DROP,                            N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG dropped the ^TC^TT Key"), "", KEY)
    MULTITEAM_INFO(KEYHUNT_LOST,                            N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG lost the ^TC^TT Key"), "", KEY)
    MULTITEAM_INFO(KEYHUNT_PUSHED,                          N_CONSOLE,  2, 0, "s1 s2", "",      "",     _("^BG%s^BG pushed %s^BG causing the ^TC^TT Key ^BGdestruction"), "", KEY)
    MULTITEAM_INFO(KEYHUNT_DESTROYED,                       N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG destroyed the ^TC^TT Key"), "", KEY)
    MULTITEAM_INFO(KEYHUNT_PICKUP,                          N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG picked up the ^TC^TT Key"), "", KEY)

    MSG_INFO_NOTIF(LMS_NOLIVES,                             N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^F3 has no more lives left"), "")

    MSG_INFO_NOTIF(MONSTERS_DISABLED,                       N_CONSOLE,  0, 0, "", "",           "",     _("^BGMonsters are currently disabled"), "")

    MULTITEAM_INFO(NEXBALL_RETURN_HELD,                     N_CONSOLE,  0, 0, "", "",           "",     _("^BGThe ^TC^TT^BG team held the ball for too long"), "", NAME)

    MSG_INFO_NOTIF(ONSLAUGHT_CAPTURE,                       N_CONSOLE,  2, 0, "s1 s2", "",      "",     _("^BG%s^BG captured %s^BG control point"), "")
    MSG_INFO_NOTIF(ONSLAUGHT_CAPTURE_NONAME,                N_CONSOLE,  1, 0, "s1", "",         "",     _("^BG%s^BG captured a control point"), "")
    MULTITEAM_INFO(ONSLAUGHT_CPDESTROYED,                   N_CONSOLE,  2, 0, "s1 s2", "",      "",     _("^TC^TT^BG team %s^BG control point has been destroyed by %s"), "", NAME)
    MULTITEAM_INFO(ONSLAUGHT_CPDESTROYED_NONAME,            N_CONSOLE,  1, 0, "s1", "",         "",     _("^TC^TT^BG team control point has been destroyed by %s"), "", NAME)
    MULTITEAM_INFO(ONSLAUGHT_GENDESTROYED,                  N_CONSOLE,  0, 0, "", "",           "",     _("^TC^TT^BG generator has been destroyed"), "", GENERATOR)
    MULTITEAM_INFO(ONSLAUGHT_GENDESTROYED_OVERTIME,         N_CONSOLE,  0, 0, "", "",           "",     _("^TC^TT^BG generator spontaneously combusted due to overtime!"), "", GENERATOR)

    MSG_INFO_NOTIF(POWERUP_INVISIBILITY,                    N_CONSOLE,  1, 0, "s1", "s1",       "buff_invisible", _("^BG%s^K1 picked up Invisibility"), "")
    MSG_INFO_NOTIF(POWERUP_SHIELD,                          N_CONSOLE,  1, 0, "s1", "s1",       "shield",         _("^BG%s^K1 picked up Shield"), "")
    MSG_INFO_NOTIF(POWERUP_SPEED,                           N_CONSOLE,  1, 0, "s1", "s1",       "buff_speed",     _("^BG%s^K1 picked up Speed"), "")
    MSG_INFO_NOTIF(POWERUP_STRENGTH,                        N_CONSOLE,  1, 0, "s1", "s1",       "strength",       _("^BG%s^K1 picked up Strength"), "")

    MSG_INFO_NOTIF(QUIT_DISCONNECT,                         N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 disconnected"), "")
    MSG_INFO_NOTIF(QUIT_KICK_IDLING,                        N_CHATCON,  1, 1, "s1 f1", "",      "",             _("^BG%s^F3 was kicked after idling for %s seconds"), "")
    MSG_INFO_NOTIF(MOVETOSPEC_IDLING,                       N_CHATCON,  1, 1, "s1 f1", "",      "",             _("^BG%s^F3 was moved to^BG spectators^F3 after idling for %s seconds"), "")
    MSG_INFO_NOTIF(MOVETOSPEC_IDLING_QUEUE,                 N_CHATCON,  1, 1, "s1 f1", "",      "",             _("^BG%s^F3 has left the join queue after idling for %s seconds"), "")
    MSG_INFO_NOTIF(MOVETOSPEC_REMOVE,                       N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 was moved to^BG spectators^F3 for balance reasons"), "")
    MSG_INFO_NOTIF(QUIT_KICK_SPECTATING,                    N_CONSOLE,  0, 0, "", "",           "",             _("^F2You were kicked from the server because you are a spectator and spectators aren't allowed at the moment."), "")
    MSG_INFO_NOTIF(QUIT_KICK_TEAMKILL,                      N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 was kicked for excessive teamkilling"), "")
    MSG_INFO_NOTIF(QUIT_PLAYBAN_TEAMKILL,                   N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 was forced to spectate for excessive teamkilling"), "")
    MSG_INFO_NOTIF(QUIT_SPECTATE,                           N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 is now^BG spectating"), "")
    MSG_INFO_NOTIF(QUIT_QUEUE,                              N_CHATCON,  1, 0, "s1", "",         "",             _("^BG%s^F3 has left the join queue"), "")

    MSG_INFO_NOTIF(RACE_ABANDONED,                          N_CONSOLE,  1, 0, "s1", "",                                                                     "",                         _("^BG%s^BG has abandoned the race"), "")
    MSG_INFO_NOTIF(RACE_FAIL_RANKED,                        N_CONSOLE,  1, 3, "s1 race_col f1ord race_col f3race_time race_diff", "s1 f3race_time",         "race_newfail",             _("^BG%s^BG couldn't break their %s%s^BG place record of %s%s %s"), "")
    MSG_INFO_NOTIF(RACE_FAIL_UNRANKED,                      N_CONSOLE,  1, 3, "s1 race_col f1ord race_col f3race_time race_diff", "s1 f3race_time",         "race_newfail",             _("^BG%s^BG couldn't break the %s%s^BG place record of %s%s %s"), "")
    MSG_INFO_NOTIF(RACE_FINISHED,                           N_CONSOLE,  1, 0, "s1", "",                                                                     "",                         _("^BG%s^BG has finished the race"), "")
    MSG_INFO_NOTIF(RACE_NEW_BROKEN,                         N_CONSOLE,  2, 3, "s1 s2 race_col f1ord race_col f2race_time race_diff",  "s1 f2race_time",     "race_newrankyellow",       _("^BG%s^BG broke %s^BG's %s%s^BG place record with %s%s %s"), "")
    MSG_INFO_NOTIF(RACE_NEW_IMPROVED,                       N_CONSOLE,  1, 3, "s1 race_col f1ord race_col f2race_time race_diff", "s1 f2race_time",         "race_newtime",             _("^BG%s^BG improved their %s%s^BG place record with %s%s %s"), "")
    MSG_INFO_NOTIF(RACE_NEW_MISSING_UID,                    N_CONSOLE,  1, 1, "s1 f1race_time", "s1 f1race_time",                                           "race_newfail",             _("^BG%s^BG scored a new record with ^F2%s^BG, but unfortunately lacks a UID and will be lost."), "")
    MSG_INFO_NOTIF(RACE_NEW_MISSING_NAME,                   N_CONSOLE,  1, 1, "s1 f1race_time", "s1 f1race_time",                                           "race_newfail",             _("^BG%s^BG scored a new record with ^F2%s^BG, but is anonymous and will be lost."), "")
    MSG_INFO_NOTIF(RACE_NEW_SET,                            N_CONSOLE,  1, 2, "s1 race_col f1ord race_col f2race_time", "s1 f2race_time",                   "race_newrecordserver",     _("^BG%s^BG set the %s%s^BG place record with %s%s"), "")

    MULTIICON_INFO(MINIGAME_INVITE,                         N_CONSOLE,  2, 0, "s2 minigame1_name s1", "s2", "minigame1_d", "minigames/%s/icon_notif",   _("^F4You have been invited by ^BG%s^F4 to join their game of ^F2%s^F4 (^F1%s^F4)"), "")

    MULTITEAM_INFO(SCORES,                                  N_CONSOLE,  0, 0, "", "",           "",                     _("^TC^TT ^BGteam scores!"), "", NAME)

    MSG_INFO_NOTIF(SPECTATE_WARNING,                        N_CONSOLE,  0, 1, "f1secs", "",     "",                     _("^F2You have to become a player within the next %s, otherwise you will be kicked, because spectating isn't allowed at this time!"), "")
    MSG_INFO_NOTIF(SPECTATE_NOTALLOWED,                     N_CONSOLE,  0, 0, "", "",           "",                     _("^F2Spectating isn't allowed at this time!"), "")
    MSG_INFO_NOTIF(SPECTATE_SPEC_NOTALLOWED,                N_CONSOLE,  0, 0, "", "",           "",                     _("^F2Spectating specific players isn't allowed at this time!"), "")

    MSG_INFO_NOTIF(SUPERWEAPON_PICKUP,                      N_CONSOLE,  1, 0, "s1", "s1",       "superweapons",         _("^BG%s^K1 picked up a Superweapon"), "")

    MSG_INFO_NOTIF(SURVIVAL_HUNTER_WIN,                     N_CONSOLE,  0, 0, "", "",           "",                     _("^K1Hunters^BG win the round"), "")
    MSG_INFO_NOTIF(SURVIVAL_SURVIVOR_WIN,                   N_CONSOLE,  0, 0, "", "",           "",                     _("^F1Survivors^BG win the round"), "")

    MSG_INFO_NOTIF(TEAMCHANGE_LARGERTEAM,                   N_CONSOLE,  0, 0, "", "",           "",                     _("^K2You're not allowed to join a larger team!"), "")
    MSG_INFO_NOTIF(TEAMCHANGE_NOTALLOWED,                   N_CONSOLE,  0, 0, "", "",           "",                     _("^K2You're not allowed to join that team!"), "")
    MSG_INFO_NOTIF(TEAMCHANGE_LOCKED,                       N_CONSOLE,  0, 0, "", "",           "",                     _("^K2Teams are locked, you can't join or change teams until they're unlocked or the map changes."), "")
    MSG_INFO_NOTIF(TEAMCHANGE_SAME,                         N_CONSOLE,  0, 0, "", "",           "",                     _("^K2You're already on that team!"), "")

    MSG_INFO_NOTIF(TEAMS_LOCKED,                            N_CHATCON,  0, 0, "", "",           "",                     _("^F4The teams are now locked."), "")
    MSG_INFO_NOTIF(TEAMS_UNLOCKED,                          N_CHATCON,  0, 0, "", "",           "",                     _("^F1The teams are now unlocked."), "")

    MSG_INFO_NOTIF(VERSION_BETA,                            N_CONSOLE,  2, 0, "s1 s2", "",      "",                     _("^F4NOTE: ^BGThe server is running ^F1Xonotic %s (beta)^BG, you have ^F2Xonotic %s"), "")
    MSG_INFO_NOTIF(VERSION_OLD,                             N_CHATCON,  2, 0, "s1 s2", "",      "",                     _("^F4NOTE: ^BGThe server is running ^F1Xonotic %s^BG, you have ^F2Xonotic %s"), "")
    MSG_INFO_NOTIF(VERSION_OUTDATED,                        N_CHATCON,  2, 0, "s1 s2", "",      "",                     _("^F4NOTE: ^F1Xonotic %s^BG is out, and you still have ^F2Xonotic %s^BG - get the update from ^F3https://xonotic.org^BG!"), "")

    MSG_INFO_NOTIF(WEAPON_ACCORDEON_MURDER,                 N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weapontuba",               _("^BG%s%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Accordeon%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ACCORDEON_SUICIDE,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weapontuba",               _("^BG%s^K1 hurt their own ears with the @!#%%'n Accordeon%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ARC_MURDER,                       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponarc",                _("^BG%s%s^K1 was electrocuted by ^BG%s^K1's Arc%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ARC_MURDER_SPRAY,                 N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponarc",                _("^BG%s%s^K1 was blasted by ^BG%s^K1's Arc bolts%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ARC_SUICIDE_BOLT,                 N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponarc",                _("^BG%s^K1 played with Arc bolts%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_BLASTER_MURDER,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponlaser",              _("^BG%s%s^K1 was shot to death by ^BG%s^K1's Blaster%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_BLASTER_SUICIDE,                  N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponlaser",              _("^BG%s^K1 shot themselves to hell with their Blaster%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_CRYLINK_MURDER,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponcrylink",            _("^BG%s%s^K1 felt the strong pull of ^BG%s^K1's Crylink%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_CRYLINK_SUICIDE,                  N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponcrylink",            _("^BG%s^K1 felt the strong pull of their Crylink%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_DEVASTATOR_MURDER_DIRECT,         N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrocketlauncher",     _("^BG%s%s^K1 ate ^BG%s^K1's rocket%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_DEVASTATOR_MURDER_SPLASH,         N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrocketlauncher",     _("^BG%s%s^K1 got too close to ^BG%s^K1's rocket%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_DEVASTATOR_SUICIDE,               N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponrocketlauncher",     _("^BG%s^K1 blew themselves up with their Devastator%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ELECTRO_MURDER_BOLT,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponelectro",            _("^BG%s%s^K1 was blasted by ^BG%s^K1's Electro bolt%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ELECTRO_MURDER_COMBO,             N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponelectro",            _("^BG%s%s^K1 felt the electrifying air of ^BG%s^K1's Electro combo%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ELECTRO_MURDER_ORBS,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponelectro",            _("^BG%s%s^K1 got too close to ^BG%s^K1's Electro orb%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ELECTRO_SUICIDE_BOLT,             N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponelectro",            _("^BG%s^K1 played with Electro bolts%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_ELECTRO_SUICIDE_ORBS,             N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponelectro",            _("^BG%s^K1 could not remember where they put their Electro orb%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_FIREBALL_MURDER_BLAST,            N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponfireball",           _("^BG%s%s^K1 got too close to ^BG%s^K1's fireball%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_FIREBALL_MURDER_FIREMINE,         N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponfireball",           _("^BG%s%s^K1 got burnt by ^BG%s^K1's firemine%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_FIREBALL_SUICIDE_BLAST,           N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponfireball",           _("^BG%s^K1 should have used a smaller gun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_FIREBALL_SUICIDE_FIREMINE,        N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponfireball",           _("^BG%s^K1 forgot about their firemine%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HAGAR_MURDER_BURST,               N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponhagar",              _("^BG%s%s^K1 was pummeled by a burst of ^BG%s^K1's Hagar rockets%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HAGAR_MURDER_SPRAY,               N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponhagar",              _("^BG%s%s^K1 was pummeled by ^BG%s^K1's Hagar rockets%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HAGAR_SUICIDE,                    N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponhagar",              _("^BG%s^K1 played with tiny Hagar rockets%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HLAC_MURDER,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponhlac",               _("^BG%s%s^K1 was cut down with ^BG%s^K1's HLAC%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HLAC_SUICIDE,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponhlac",               _("^BG%s^K1 got a little jumpy with their HLAC%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_HOOK_MURDER,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponhook",               _("^BG%s%s^K1 was caught in ^BG%s^K1's Hook gravity bomb%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_KLEINBOTTLE_MURDER,               N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weapontuba",               _("^BG%s%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Klein Bottle%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_KLEINBOTTLE_SUICIDE,              N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weapontuba",               _("^BG%s^K1 hurt their own ears with the @!#%%'n Klein Bottle%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MACHINEGUN_MURDER_SNIPE,          N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponuzi",                _("^BG%s%s^K1 was sniped by ^BG%s^K1's Machine Gun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MACHINEGUN_MURDER_SPRAY,          N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponuzi",                _("^BG%s%s^K1 was riddled full of holes by ^BG%s^K1's Machine Gun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MINELAYER_LIMIT,                  N_CONSOLE,  0, 1, "f1", "",                                         "",                         _("^BGYou cannot place more than ^F2%s^BG mines at a time"), "")
    MSG_INFO_NOTIF(WEAPON_MINELAYER_MURDER,                 N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponminelayer",          _("^BG%s%s^K1 got too close to ^BG%s^K1's mine%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MINELAYER_SUICIDE,                N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponminelayer",          _("^BG%s^K1 forgot about their mine%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MORTAR_MURDER_BOUNCE,             N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weapongrenadelauncher",    _("^BG%s%s^K1 got too close to ^BG%s^K1's Mortar grenade%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MORTAR_MURDER_EXPLODE,            N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weapongrenadelauncher",    _("^BG%s%s^K1 ate ^BG%s^K1's Mortar grenade%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MORTAR_SUICIDE_BOUNCE,            N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weapongrenadelauncher",    _("^BG%s^K1 didn't see their own Mortar grenade%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_MORTAR_SUICIDE_EXPLODE,           N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weapongrenadelauncher",    _("^BG%s^K1 blew themselves up with their own Mortar%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_HMG_MURDER_SPRAY,        N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponhmg",                _("^BG%s%s^K1 was torn to bits by ^BG%s^K1's Overkill Heavy MachineGun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_MACHINEGUN_MURDER,       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponuzi",                _("^BG%s%s^K1 was riddled full of holes by ^BG%s^K1's Overkill Machine Gun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_NEX_MURDER,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponnex",                _("^BG%s%s^K1 has been vaporized by ^BG%s^K1's Overkill Nex%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_RPC_MURDER_DIRECT,       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrpc",                _("^BG%s%s^K1 was sawn in half by ^BG%s^K1's Overkill Rocket Propelled Chainsaw%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_RPC_MURDER_SPLASH,       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrpc",                _("^BG%s%s^K1 almost dodged ^BG%s^K1's Overkill Rocket Propelled Chainsaw%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_RPC_SUICIDE_DIRECT,      N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponrpc",                _("^BG%s^K1 was sawn in half by their own Overkill Rocket Propelled Chainsaw%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_OVERKILL_RPC_SUICIDE_SPLASH,      N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponrpc",                _("^BG%s^K1 blew themselves up with their Overkill Rocket Propelled Chainsaw%s%s"), "")

    MSG_INFO_NOTIF(WEAPON_OVERKILL_SHOTGUN_MURDER,          N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponshotgun",            _("^BG%s%s^K1 was gunned down by ^BG%s^K1's Overkill Shotgun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_RIFLE_MURDER,                     N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrifle",              _("^BG%s%s^K1 was sniped with a Rifle by ^BG%s^K1%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_RIFLE_MURDER_HAIL,                N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrifle",              _("^BG%s%s^K1 died in ^BG%s^K1's Rifle bullet hail%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_RIFLE_MURDER_HAIL_PIERCING,       N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrifle",              _("^BG%s%s^K1 failed to hide from ^BG%s^K1's Rifle bullet hail%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_RIFLE_MURDER_PIERCING,            N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponrifle",              _("^BG%s%s^K1 failed to hide from ^BG%s^K1's Rifle%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_SEEKER_MURDER_SPRAY,              N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponseeker",             _("^BG%s%s^K1 was pummeled by ^BG%s^K1's Seeker rockets%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_SEEKER_MURDER_TAG,                N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponseeker",             _("^BG%s%s^K1 was tagged by ^BG%s^K1's Seeker%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_SEEKER_SUICIDE,                   N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weaponseeker",             _("^BG%s^K1 played with tiny Seeker rockets%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_SHOTGUN_MURDER,                   N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponshotgun",            _("^BG%s%s^K1 was gunned down by ^BG%s^K1's Shotgun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_SHOTGUN_MURDER_SLAP,              N_CONSOLE,  3, 2, "spree_inf s2 s1 s3loc spree_end", "s2 s1",       "notify_melee_shotgun",     _("^BG%s%s^K1 slapped ^BG%s^K1 around a bit with a large Shotgun%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_THINKING_WITH_PORTALS,            N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "notify_selfkill",          _("^BG%s^K1 is now thinking with portals%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_TUBA_MURDER,                      N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weapontuba",               _("^BG%s%s^K1 died of ^BG%s^K1's great playing on the @!#%%'n Tuba%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_TUBA_SUICIDE,                     N_CONSOLE,  2, 1, "s1 s2loc spree_lost", "s1",                      "weapontuba",               _("^BG%s^K1 hurt their own ears with the @!#%%'n Tuba%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_VAPORIZER_MURDER,                 N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponminstanex",          _("^BG%s%s^K1 has been sublimated by ^BG%s^K1's Vaporizer%s%s"), "")
    MSG_INFO_NOTIF(WEAPON_VORTEX_MURDER,                    N_CONSOLE,  3, 2, "spree_inf s1 s2 s3loc spree_end", "s2 s1",       "weaponnex",                _("^BG%s%s^K1 has been vaporized by ^BG%s^K1's Vortex%s%s"), "")

#undef N_DISABLE
#undef N_CONSOLE
#undef N_CHATCON

// default value for centerprint notification cvars (notification_CENTER_*):
// 0: off, 1: centerprint
#define N_DISABL 0
#define N_ENABLE 1

#define MULTITEAM_CENTER(prefix, defaultvalue, strnum, flnum, args, cpid, durcnt, normal, gentle, type) \
    NOTIF_ADD_AUTOCVAR(CENTER_##prefix, defaultvalue) \
    MSG_CENTER_NOTIF_TEAM(NUM_TEAM_1, prefix##_RED, prefix, defaultvalue, strnum, flnum, args, cpid, durcnt, TCR(normal, type, 1), TCR(gentle, type, 1)) \
    MSG_CENTER_NOTIF_TEAM(NUM_TEAM_2, prefix##_BLUE, prefix, defaultvalue, strnum, flnum, args, cpid, durcnt, TCR(normal, type, 2), TCR(gentle, type, 2)) \
    MSG_CENTER_NOTIF_TEAM(NUM_TEAM_3, prefix##_YELLOW, prefix, defaultvalue, strnum, flnum, args, cpid, durcnt, TCR(normal, type, 3), TCR(gentle, type, 3)) \
    MSG_CENTER_NOTIF_TEAM(NUM_TEAM_4, prefix##_PINK, prefix, defaultvalue, strnum, flnum, args, cpid, durcnt, TCR(normal, type, 4), TCR(gentle, type, 4))

// MSG_CENTER_NOTIFICATIONS
    MSG_CENTER_NOTIF(ALONE,                             N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^F4You are now alone!"), "")

    MSG_CENTER_NOTIF(ASSAULT_ATTACKING,                 N_ENABLE,    0, 0, "",               CPID_ASSAULT_ROLE,      "0 0",  _("^BGYou are attacking!"), "")
    MSG_CENTER_NOTIF(ASSAULT_DEFENDING,                 N_ENABLE,    0, 0, "",               CPID_ASSAULT_ROLE,      "0 0",  _("^BGYou are defending!"), "")
    MSG_CENTER_NOTIF(ASSAULT_OBJ_DESTROYED,             N_ENABLE,    0, 1, "f1time",         CPID_ASSAULT_ROLE,      "0 0",  _("^BGObjective destroyed in ^F4%s^BG!"), "")

    MSG_CENTER_NOTIF(COUNTDOWN_STOP_MINPLAYERS,         N_ENABLE,    0, 1, "f1",             CPID_MISSING_PLAYERS,   "4 0",  strcat(BOLD(_("^F4Countdown stopped!")), "\n^BG", _("%s players are needed for this match.")), "")
    MSG_CENTER_NOTIF(COUNTDOWN_STOP_BADTEAMS,           N_ENABLE,    0, 0, "",               CPID_MISSING_PLAYERS,   "0 0",  strcat(BOLD(_("^F4Countdown stopped!")), "\n^BG", _("Teams are too unbalanced.")), "")
    MSG_CENTER_NOTIF(COUNTDOWN_BEGIN,                   N_ENABLE,    0, 0, "",               CPID_ROUND,             "2 0",  BOLD(_("^BGBegin!")), "")
    MSG_CENTER_NOTIF(COUNTDOWN_GAMESTART,               N_ENABLE,    0, 1, "",               CPID_ROUND,             "1 f1", strcat(_("^BGGame starts in"), "\n", BOLD("^COUNT")), "")
    MSG_CENTER_NOTIF(COUNTDOWN_ROUNDSTART,              N_ENABLE,    0, 2, "f1",             CPID_ROUND,             "1 f2", strcat(_("^BGRound %s starts in"), "\n", BOLD("^COUNT")), "")
    MSG_CENTER_NOTIF(COUNTDOWN_ROUNDSTOP,               N_ENABLE,    0, 0, "",               CPID_ROUND,             "2 0",  _("^F4Round cannot start"), "")

    MSG_CENTER_NOTIF(ROUND_TIED,                        N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^BGRound tied"), "")
    MSG_CENTER_NOTIF(ROUND_OVER,                        N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^BGRound over, there's no winner"), "")

    MSG_CENTER_NOTIF(CAMPCHECK,                         N_ENABLE,    0, 0, "",               CPID_CAMPCHECK,         "0 0",  _("^F2Don't camp!"), "")

    MSG_CENTER_NOTIF(COINTOSS,                          N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^F2Throwing coin... Result: %s^F2!"), "")

    MSG_CENTER_NOTIF(CTF_CAPTURESHIELD_FREE,            N_ENABLE,    0, 0, "",               CPID_CTF_CAPSHIELD,     "0 0",  _("^BGYou are now free.\n^BGFeel free to ^F2try to capture^BG the flag again\n^BGif you think you will succeed."), "")
    MSG_CENTER_NOTIF(CTF_CAPTURESHIELD_INACTIVE,        N_ENABLE,    0, 0, "",               CPID_CTF_CAPSHIELD,     "0 0",  _("^BGThis flag is currently inactive"), "")
    MSG_CENTER_NOTIF(CTF_CAPTURESHIELD_SHIELDED,        N_ENABLE,    0, 0, "",               CPID_CTF_CAPSHIELD,     "0 0",  _("^BGYou are now ^F1shielded^BG from the flag(s)\n^BGfor ^F2too many unsuccessful attempts^BG to capture.\n^BGMake some defensive scores before trying again."), "")
    MULTITEAM_CENTER(CTF_CAPTURE,                       N_ENABLE,    0, 0, "",               CPID_CTF_LOWPRIO,       "0 0",  _("^BGYou captured the ^TC^TT^BG flag!"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_CAPTURE_NEUTRAL,               N_ENABLE,    0, 0, "",               CPID_CTF_LOWPRIO,       "0 0",  _("^BGYou captured the flag!"), "")
    MSG_CENTER_NOTIF(CTF_FLAG_THROW_PUNISH,             N_ENABLE,    0, 1, "f1secs",         CPID_CTF_LOWPRIO,       "0 0",  _("^BGToo many flag throws! Throwing disabled for %s."), "")
    MULTITEAM_CENTER(CTF_PASS_OTHER,                    N_ENABLE,    2, 0, "s1 s2",          CPID_CTF_PASS,          "0 0",  _("^BG%s^BG passed the ^TC^TT^BG flag to %s"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PASS_OTHER_NEUTRAL,            N_ENABLE,    2, 0, "s1 s2",          CPID_CTF_PASS,          "0 0",  _("^BG%s^BG passed the flag to %s"), "")
    MULTITEAM_CENTER(CTF_PASS_RECEIVED,                 N_ENABLE,    1, 0, "s1",             CPID_CTF_PASS,          "0 0",  _("^BGYou received the ^TC^TT^BG flag from %s"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PASS_RECEIVED_NEUTRAL,         N_ENABLE,    1, 0, "s1",             CPID_CTF_PASS,          "0 0",  _("^BGYou received the flag from %s"), "")
    MSG_CENTER_NOTIF(CTF_PASS_REQUESTED,                N_ENABLE,    1, 0, "pass_key s1",    CPID_CTF_PASS,          "0 0",  _("^BGPress ^F2%s^BG to receive the flag from %s^BG"), "")
    MSG_CENTER_NOTIF(CTF_PASS_REQUESTING,               N_ENABLE,    1, 0, "s1",             CPID_CTF_PASS,          "0 0",  _("^BGRequesting %s^BG to pass you the flag"), "")
    MULTITEAM_CENTER(CTF_PASS_SENT,                     N_ENABLE,    1, 0, "s1",             CPID_CTF_PASS,          "0 0",  _("^BGYou passed the ^TC^TT^BG flag to %s"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PASS_SENT_NEUTRAL,             N_ENABLE,    1, 0, "s1",             CPID_CTF_PASS,          "0 0",  _("^BGYou passed the flag to %s"), "")
    MULTITEAM_CENTER(CTF_PICKUP,                        N_ENABLE,    0, 0, "",               CPID_CTF_LOWPRIO,       "0 0",  BOLD(_("^BGYou got the ^TC^TT^BG flag!")), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PICKUP_NEUTRAL,                N_ENABLE,    0, 0, "",               CPID_CTF_LOWPRIO,       "0 0",  BOLD(_("^BGYou got the flag!")), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_RETURN,                 N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  BOLD(_("^BGYou got your %steam^BG's flag, return it!")), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_RETURN_ENEMY,           N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  BOLD(_("^BGYou got the %senemy^BG's flag, return it!")), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY,                  N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy^BG got your flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_VERBOSE,          N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy (^BG%s%s)^BG got your flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_NEUTRAL,          N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy^BG got the flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_NEUTRAL_VERBOSE,  N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy (^BG%s%s)^BG got the flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_TEAM,             N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy^BG got their flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_TEAM_VERBOSE,     N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy (^BG%s%s)^BG got their flag! Retrieve it!"), "")
    MULTITEAM_CENTER(CTF_PICKUP_ENEMY_OTHER,            N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy^BG got the ^TC^TT^BG flag! Retrieve it!"), "", FLAG)
    MULTITEAM_CENTER(CTF_PICKUP_ENEMY_OTHER_VERBOSE,    N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy (^BG%s%s)^BG got the ^TC^TT^BG flag! Retrieve it!"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_OTHER_NEUTRAL,    N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy^BG got the flag! Retrieve it!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_ENEMY_OTHER_VERBOSE_NEUTRAL, N_ENABLE,    2, 0, "s1 s2 s1",  CPID_CTF_LOWPRIO,       "0 0",  _("^BGThe %senemy (^BG%s%s)^BG got the flag! Retrieve it!"), "")
    MULTITEAM_CENTER(CTF_PICKUP_TEAM,                   N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGYour %steammate^BG got the ^TC^TT^BG flag! Protect them!"), "", FLAG)
    MULTITEAM_CENTER(CTF_PICKUP_TEAM_VERBOSE,           N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGYour %steammate (^BG%s%s)^BG got the ^TC^TT^BG flag! Protect them!"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_PICKUP_TEAM_NEUTRAL,           N_ENABLE,    1, 0, "s1",             CPID_CTF_LOWPRIO,       "0 0",  _("^BGYour %steammate^BG got the flag! Protect them!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_TEAM_VERBOSE_NEUTRAL,   N_ENABLE,    2, 0, "s1 s2 s1",       CPID_CTF_LOWPRIO,       "0 0",  _("^BGYour %steammate (^BG%s%s)^BG got the flag! Protect them!"), "")
    MSG_CENTER_NOTIF(CTF_PICKUP_VISIBLE,                N_ENABLE,    0, 0, "",               CPID_STALEMATE,         "0 0",  _("^BGEnemies can now see you on radar!"), "")
    MULTITEAM_CENTER(CTF_RETURN,                        N_ENABLE,    0, 0, "",               CPID_CTF_LOWPRIO,       "0 0",  _("^BGYou returned the ^TC^TT^BG flag!"), "", FLAG)
    MSG_CENTER_NOTIF(CTF_STALEMATE_CARRIER,             N_ENABLE,    0, 0, "",               CPID_STALEMATE,         "0 0",  _("^BGStalemate! Enemies can now see you on radar!"), "")
    MSG_CENTER_NOTIF(CTF_STALEMATE_OTHER,               N_ENABLE,    0, 0, "",               CPID_STALEMATE,         "0 0",  _("^BGStalemate! Flag carriers can now be seen by enemies on radar!"), "")

    #define VERBOSE_MURDER(type) strcat(MURDER_##type, "^BG%s")

    #define MURDER_FRAG             BOLD(_("^K3%sYou fragged ^BG%s"))
    #define MURDER_FRAG2            BOLD(_("^K3%sYou scored against ^BG%s"))
    #define MURDER_FRAGGED          BOLD(_("^K1%sYou were fragged by ^BG%s"))
    #define MURDER_FRAGGED2         BOLD(_("^K1%sYou were scored against by ^BG%s"))
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG,                   N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAG,                    MURDER_FRAG2                   )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED,                N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAGGED,                 MURDER_FRAGGED2                )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED_VERBOSE,        N_ENABLE,  1, 4, "spree_cen s1 frag_stats",    CPID_Null,  "0 0",  VERBOSE_MURDER(FRAGGED),        VERBOSE_MURDER(FRAGGED2)       )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG_VERBOSE,           N_ENABLE,  1, 2, "spree_cen s1 frag_ping",     CPID_Null,  "0 0",  VERBOSE_MURDER(FRAG),           VERBOSE_MURDER(FRAG2)          )

    #define MURDER_FRAG_FIRE        BOLD(_("^K3%sYou burned ^BG%s"))
    #define MURDER_FRAG_FIRE2       BOLD(_("^K3%sYou scored against ^BG%s"))
    #define MURDER_FRAGGED_FIRE     BOLD(_("^K1%sYou were burned by ^BG%s"))
    #define MURDER_FRAGGED_FIRE2    BOLD(_("^K1%sYou were scored against by ^BG%s"))
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG_FIRE,              N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAG_FIRE,               MURDER_FRAG_FIRE2              )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED_FIRE,           N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAGGED_FIRE,            MURDER_FRAGGED_FIRE2           )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED_FIRE_VERBOSE,   N_ENABLE,  1, 4, "spree_cen s1 frag_stats",    CPID_Null,  "0 0",  VERBOSE_MURDER(FRAGGED_FIRE),   VERBOSE_MURDER(FRAGGED_FIRE2)  )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG_FIRE_VERBOSE,      N_ENABLE,  1, 2, "spree_cen s1 frag_ping",     CPID_Null,  "0 0",  VERBOSE_MURDER(FRAG_FIRE),      VERBOSE_MURDER(FRAG_FIRE2)     )

    #define MURDER_FRAG_FREEZE      BOLD(_("^K3%sYou froze ^BG%s"))
    #define MURDER_FRAG_FREEZE2     BOLD(_("^K3%sYou scored against ^BG%s"))
    #define MURDER_FRAGGED_FREEZE   BOLD(_("^K1%sYou were frozen by ^BG%s"))
    #define MURDER_FRAGGED_FREEZE2  BOLD(_("^K1%sYou were scored against by ^BG%s"))
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG_FREEZE,            N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAG_FREEZE,             MURDER_FRAG_FREEZE2            )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED_FREEZE,         N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_FRAGGED_FREEZE,          MURDER_FRAGGED_FREEZE2         )
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAGGED_FREEZE_VERBOSE, N_ENABLE,  1, 4, "spree_cen s1 frag_stats",    CPID_Null,  "0 0",  VERBOSE_MURDER(FRAGGED_FREEZE), VERBOSE_MURDER(FRAGGED_FREEZE2))
    MSG_CENTER_NOTIF(DEATH_MURDER_FRAG_FREEZE_VERBOSE,    N_ENABLE,  1, 2, "spree_cen s1 frag_ping",     CPID_Null,  "0 0",  VERBOSE_MURDER(FRAG_FREEZE),    VERBOSE_MURDER(FRAG_FREEZE2)   )

    #define MURDER_TYPEFRAG         BOLD(_("^K1%sYou typefragged ^BG%s"))
    #define MURDER_TYPEFRAG2        BOLD(_("^K1%sYou scored against ^BG%s^K1 while they were typing"))
    #define MURDER_TYPEFRAGGED      BOLD(_("^K1%sYou were typefragged by ^BG%s"))
    #define MURDER_TYPEFRAGGED2     BOLD(_("^K1%sYou were scored against by ^BG%s^K1 while typing"))
    MSG_CENTER_NOTIF(DEATH_MURDER_TYPEFRAG,               N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_TYPEFRAG,                MURDER_TYPEFRAG2               )
    MSG_CENTER_NOTIF(DEATH_MURDER_TYPEFRAGGED,            N_ENABLE,  1, 1, "spree_cen s1",               CPID_Null,  "0 0",  MURDER_TYPEFRAGGED,             MURDER_TYPEFRAGGED2            )
    MSG_CENTER_NOTIF(DEATH_MURDER_TYPEFRAGGED_VERBOSE,    N_ENABLE,  1, 4, "spree_cen s1 frag_stats",    CPID_Null,  "0 0",  VERBOSE_MURDER(TYPEFRAGGED),    VERBOSE_MURDER(TYPEFRAGGED2)   )
    MSG_CENTER_NOTIF(DEATH_MURDER_TYPEFRAG_VERBOSE,       N_ENABLE,  1, 2, "spree_cen s1 frag_ping",     CPID_Null,  "0 0",  VERBOSE_MURDER(TYPEFRAG),       VERBOSE_MURDER(TYPEFRAG2)      )

    MSG_CENTER_NOTIF(NADE_THROW,                        N_ENABLE,    0, 0, "nade_key",       CPID_NADES,             "0 0",  _("^BGPress ^F2%s^BG again to toss the nade!"), "")
    MSG_CENTER_NOTIF(NADE_BONUS,                        N_ENABLE,    0, 0, "",               CPID_NADES,             "0 0",  _("^F2You got a ^K1BONUS GRENADE^F2!"), "")

    MSG_CENTER_NOTIF(DEATH_SELF_AUTOTEAMCHANGE,         N_ENABLE,    0, 1, "death_team",     CPID_Null,              "0 0",  BOLD(_("^BGYou have been moved into a different team\nYou are now on: %s")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_BETRAYAL,               N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were punished for attacking your teammates!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_CAMP,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1Die camper!")), BOLD(_("^K1Reconsider your tactics, camper!")))
    MSG_CENTER_NOTIF(DEATH_SELF_CHEAT,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You unfairly eliminated yourself!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_CUSTOM,                 N_ENABLE,    2, 0, "s2",             CPID_Null,              "0 0",  BOLD(_("^K1You were %s")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_DROWN,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You couldn't catch your breath!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_FALL,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You hit the ground with a crunch!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_FIRE,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got a little bit too crispy!")), BOLD(_("^K1You felt a little too hot!")))
    MSG_CENTER_NOTIF(DEATH_SELF_GENERIC,                N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You fragged yourself!")), BOLD(_("^K1You need to be more careful!")))
    MSG_CENTER_NOTIF(DEATH_SELF_LAVA,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You couldn't stand the heat!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_MONSTER,                N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were killed by a monster!")), BOLD(_("^K1You need to watch out for monsters!")))
    MSG_CENTER_NOTIF(DEATH_SELF_NADE,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You forgot to put the pin back in!")), BOLD(_("^K1Tastes like chicken!")))
    MSG_CENTER_NOTIF(DEATH_SELF_NADE_NAPALM,            N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1Hanging around a napalm explosion is bad!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_NADE_HEAL,              N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1Your Healing Nade is a bit defective")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_NOAMMO,                 N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were killed for running out of ammo...")), BOLD(_("^K1You are respawning for running out of ammo...")))
    MSG_CENTER_NOTIF(DEATH_SELF_ROT,                    N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You grew too old without taking your medicine")), BOLD(_("^K1You need to preserve your health")))
    MSG_CENTER_NOTIF(DEATH_SELF_SHOOTING_STAR,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You became a shooting star!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_SLIME,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You melted away in slime!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_SUICIDE,                N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You committed suicide!")), BOLD(_("^K1You ended it all!")))
    MSG_CENTER_NOTIF(DEATH_SELF_SWAMP,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got stuck in a swamp!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_TEAMCHANGE,             N_ENABLE,    0, 1, "death_team",     CPID_Null,              "0 0",  BOLD(_("^BGYou are now on: %s")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_TOUCHEXPLODE,           N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You died in an accident!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_TURRET,                 N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were fragged by a turret!")), BOLD(_("^K1You had an unfortunate run in with a turret!")))
    MSG_CENTER_NOTIF(DEATH_SELF_TURRET_EWHEEL,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were fragged by an eWheel turret!")), BOLD(_("^K1You had an unfortunate run in with an eWheel turret!")))
    MSG_CENTER_NOTIF(DEATH_SELF_TURRET_WALK,            N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were fragged by a Walker turret!")), BOLD(_("^K1You had an unfortunate run in with a Walker turret!")))
    MSG_CENTER_NOTIF(DEATH_SELF_VH_BUMB_DEATH,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got caught in the blast of a Bumblebee explosion!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_CRUSH,               N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were crushed by a vehicle!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_RAPT_BOMB,           N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were caught in a Raptor cluster bomb!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_RAPT_DEATH,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got caught in the blast of a Raptor explosion!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_SPID_DEATH,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got caught in the blast of a Spiderbot explosion!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_SPID_ROCKET,         N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You were blasted to bits by a Spiderbot rocket!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_WAKI_DEATH,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You got caught in the blast of a Racer explosion!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VH_WAKI_ROCKET,         N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You couldn't find shelter from a Racer rocket!")), "")
    MSG_CENTER_NOTIF(DEATH_SELF_VOID,                   N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1Watch your step!")), "")

    MSG_CENTER_NOTIF(DEATH_TEAMKILL_FRAG,               N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  BOLD(_("^K1Traitor! You team killed ^BG%s")), BOLD(_("^K1Traitor! You betrayed teammate ^BG%s")))
    MSG_CENTER_NOTIF(DEATH_TEAMKILL_FRAGGED,            N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  BOLD(_("^K1You were team killed by ^BG%s")), BOLD(_("^K1You were betrayed by teammate ^BG%s")))

    MSG_CENTER_NOTIF(DISCONNECT_IDLING,                 N_ENABLE,    0, 1, "",               CPID_IDLING,            "1 f1", BOLD(_("^K1Stop idling!\n^BGDisconnecting in ^COUNT...")), "")
    MSG_CENTER_NOTIF(MOVETOSPEC_IDLING,                 N_ENABLE,    0, 1, "",               CPID_IDLING,            "1 f1", BOLD(_("^K1Stop idling!\n^BGMoving to spectators in ^COUNT...")), "")
    MSG_CENTER_NOTIF(MOVETOSPEC_REMOVE,                 N_ENABLE,    1, 1, "s1",             CPID_REMOVE,            "1 f1", BOLD(_("^K1Teams unbalanced!\n^BGMoving %s^BG to spectators in ^COUNT...")), "")

    MSG_CENTER_NOTIF(DOOR_LOCKED_NEED,                  N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^BGYou need %s^BG!"), "")
    MSG_CENTER_NOTIF(DOOR_LOCKED_ALSONEED,              N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^BGYou also need %s^BG!"), "")
    MSG_CENTER_NOTIF(DOOR_UNLOCKED,                     N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^BGDoor unlocked!"), "")

    MSG_CENTER_NOTIF(EXTRALIVES,                        N_ENABLE,    0, 1, "f1",             CPID_Null,              "0 0",  _("^F2Extra lives taken: ^K1%s"), "")

    MSG_CENTER_NOTIF(FREEZETAG_REVIVE,                  N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^K3You revived ^BG%s"), "")
    MSG_CENTER_NOTIF(FREEZETAG_REVIVE_SELF,             N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^K3You revived yourself"), "")
    MSG_CENTER_NOTIF(FREEZETAG_REVIVED,                 N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^K3You were revived by ^BG%s"), "")
    MSG_CENTER_NOTIF(FREEZETAG_AUTO_REVIVED,            N_ENABLE,    0, 1, "f1",             CPID_Null,              "0 0",  _("^BGYou were automatically revived after %s seconds"), "")

    MSG_CENTER_NOTIF(GENERATOR_UNDERATTACK,             N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^BGThe generator is under attack!"), "")

    MULTITEAM_CENTER(ROUND_TEAM_LOSS,                   N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^TC^TT^BG team loses the round"), "", NAME)
    MULTITEAM_CENTER(ROUND_TEAM_WIN,                    N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^TC^TT^BG team wins the round"), "", NAME)
    MSG_CENTER_NOTIF(ROUND_PLAYER_WIN,                  N_ENABLE,    1, 0, "s1",             CPID_ROUND,             "0 0",  _("^BG%s^BG wins the round"), "")

    MSG_CENTER_NOTIF(FREEZETAG_SELF,                    N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^K1You froze yourself"), "")
    MSG_CENTER_NOTIF(FREEZETAG_SPAWN_LATE,              N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^K1Round already started, you spawn as frozen"), "")

    MSG_CENTER_NOTIF(INVASION_SUPERMONSTER,             N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  _("^K1A %s has arrived!"), "")

    MSG_CENTER_NOTIF(ITEM_BUFF_DROP,                    N_ENABLE,    0, 1, "item_buffname",                      CPID_ITEM, "item_centime 0", _("^BGYou dropped the %s^BG buff!"), "")
    MSG_CENTER_NOTIF(ITEM_BUFF_GOT,                     N_ENABLE,    0, 1, "item_buffname",                      CPID_ITEM, "item_centime 0", _("^BGYou got the %s^BG buff!"), "")
    MSG_CENTER_NOTIF(ITEM_FUELREGEN_GOT,                N_ENABLE,    0, 0, "",                                   CPID_ITEM, "item_centime 0", _("^BGYou got the ^F1Fuel regenerator"), "")
    MSG_CENTER_NOTIF(ITEM_JETPACK_GOT,                  N_ENABLE,    0, 0, "",                                   CPID_ITEM, "item_centime 0", _("^BGYou got the ^F1Jetpack"), "")
    MSG_CENTER_NOTIF(ITEM_WEAPON_DONTHAVE,              N_ENABLE,    0, 1, "item_wepname",                       CPID_ITEM, "item_centime 0", _("^BGYou do not have the ^F1%s"), "")
    MSG_CENTER_NOTIF(ITEM_WEAPON_DROP,                  N_ENABLE,    0, 2, "item_wepname item_wepammo",          CPID_ITEM, "item_centime 0", _("^BGYou dropped the ^F1%s^BG%s"), "")
    MSG_CENTER_NOTIF(ITEM_WEAPON_GOT,                   N_ENABLE,    0, 1, "item_wepname",                       CPID_ITEM, "item_centime 0", _("^BGYou got the ^F1%s"), "")
    MSG_CENTER_NOTIF(ITEM_WEAPON_NOAMMO,                N_ENABLE,    0, 1, "item_wepname",                       CPID_ITEM, "item_centime 0", _("^BGYou don't have enough ammo for the ^F1%s"), "")
    MSG_CENTER_NOTIF(ITEM_WEAPON_PRIMORSEC,             N_ENABLE,    0, 3, "item_wepname f2primsec f3primsec",   CPID_ITEM, "item_centime 0", _("^F1%s %s^BG is unable to fire, but its ^F1%s^BG can"), "") // example for translators: Electro primary is unable to fire, but its secondary can
    MSG_CENTER_NOTIF(ITEM_WEAPON_UNAVAILABLE,           N_ENABLE,    0, 1, "item_wepname",                       CPID_ITEM, "item_centime 0", _("^F1%s^BG is ^F4not available^BG on this map"), "")

    MSG_CENTER_NOTIF(JOIN_PREVENT_VERSIONMISMATCH,      N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K1Your Xonotic version is incompatible with the server's version!"), "")
    MSG_CENTER_NOTIF(JOIN_NOSPAWNS,                     N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K1No spawnpoints available!\nHope your team can fix it..."), "")
    MSG_CENTER_NOTIF(JOIN_PLAYBAN,                      N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  BOLD(_("^K1You aren't allowed to play because you are banned in this server")), "")
    MSG_CENTER_NOTIF(JOIN_PREVENT,                      N_ENABLE,    0, 1, "f1",             CPID_PREVENT_JOIN,      "0 0",  _("^K1You may not join the game at this time.\nThis match is limited to ^F2%s^BG players."), "")
    MSG_CENTER_NOTIF(JOIN_PREVENT_MINIGAME,             N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^K1Cannot join given minigame session!"), "" )
    MSG_CENTER_NOTIF(JOIN_PREVENT_PING,                 N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2Your ping (connection latency) is currently too high to play here.\nPlease consider joining a server closer to you."), "")
    MSG_CENTER_NOTIF(JOIN_PREVENT_QUEUE,                N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^BGYou're queued to join any available team."), "")
    MULTITEAM_CENTER(JOIN_PREVENT_QUEUE_TEAM,           N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^BGYou're queued to join the ^TC^TT^BG team."), "", NAME)
    MULTITEAM_CENTER(JOIN_PREVENT_QUEUE_TEAM_CONFLICT,  N_ENABLE,    1, 0, "s1",             CPID_PREVENT_JOIN,      "0 0",  strcat(_("^K2You're queued to join any available team."), "\n", _("%s^K2 chose ^TC^TT^K2 first.")), "", NAME)
    MULTITEAM_CENTER(JOIN_PLAY_TEAM_QUEUECONFLICT,      N_ENABLE,    1, 0, "s1",             CPID_Null,              "0 0",  strcat(_("^K2You're now playing on ^TC^TT^K2 team!"), "\n", _("%s^K2 chose your preferred team first.")), "", NAME)
    MULTITEAM_CENTER(JOIN_PLAY_TEAM,                    N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^BGYou're now playing on ^TC^TT^BG team!"), "", NAME)

    MSG_CENTER_NOTIF(KEEPAWAY_DROPPED,                  N_ENABLE,    1, 0, "s1",             CPID_KEEPAWAY,          "0 0",  _("^BG%s^BG has dropped the ball!"), "")
    MSG_CENTER_NOTIF(KEEPAWAY_PICKUP,                   N_ENABLE,    1, 0, "s1",             CPID_KEEPAWAY,          "0 0",  _("^BG%s^BG has picked up the ball!"), "")
    MSG_CENTER_NOTIF(KEEPAWAY_PICKUP_SELF,              N_ENABLE,    0, 0, "",               CPID_KEEPAWAY,          "0 0",  _("^BGYou picked up the ball"), "")
    MSG_CENTER_NOTIF(KEEPAWAY_WARN,                     N_ENABLE,    0, 0, "",               CPID_KEEPAWAY_WARN,     "0 0",  _("^BGGet the ball to score points for frags!"), "")

    MSG_CENTER_NOTIF(KEYHUNT_HELP,                      N_ENABLE,    0, 0, "",               CPID_KEYHUNT,           "0 0",  _("^BGAll keys are in your team's hands!\nHelp the key carriers to meet!"), "")
    MULTITEAM_CENTER(KEYHUNT_INTERFERE,                 N_ENABLE,    0, 0, "",               CPID_KEYHUNT,           "0 0",  _("^BGAll keys are in ^TC^TT team^BG's hands!\nInterfere ^F4NOW^BG!"), "", NAME)
    MSG_CENTER_NOTIF(KEYHUNT_MEET,                      N_ENABLE,    0, 0, "",               CPID_KEYHUNT,           "0 0",  _("^BGAll keys are in your team's hands!\nMeet the other key carriers ^F4NOW^BG!"), "")
    MSG_CENTER_NOTIF(KEYHUNT_ROUNDSTART,                N_ENABLE,    0, 1, "",               CPID_KEYHUNT_OTHER,     "1 f1", _("^F4Round will start in ^COUNT"), "")
    MSG_CENTER_NOTIF(KEYHUNT_SCAN,                      N_ENABLE,    0, 1, "",               CPID_KEYHUNT_OTHER,     "f1 0", _("^BGScanning frequency range..."), "")
    MULTITEAM_CENTER(KEYHUNT_START,                     N_ENABLE,    0, 0, "",               CPID_KEYHUNT,           "0 0",  _("^BGYou are starting with the ^TC^TT Key"), "", KEY)

    MSG_CENTER_NOTIF(LMS_NOLIVES,                       N_ENABLE,    0, 0, "",               CPID_LMS,               "0 0",  _("^BGYou have no lives left, you must wait until the next match"), "")
    MSG_CENTER_NOTIF(LMS_VISIBLE_LEADER,                N_ENABLE,    0, 0, "",               CPID_LMS,               "0 0",  _("^BGEnemies can now see you on radar!"), "")
    MSG_CENTER_NOTIF(LMS_VISIBLE_OTHER,                 N_ENABLE,    0, 0, "",               CPID_LMS,               "0 0",  _("^BGLeaders can now be seen by enemies on radar!"), "")

    MSG_CENTER_NOTIF(MISSING_TEAMS,                     N_ENABLE,    0, 1, "missing_teams",  CPID_MISSING_TEAMS,     "-1 0", _("^BGWaiting for players to join...\nNeed active players for: %s"), "")
    MSG_CENTER_NOTIF(MISSING_PLAYERS,                   N_ENABLE,    0, 1, "f1",             CPID_MISSING_PLAYERS,   "-1 0", _("^BGWaiting for %s player(s) to join..."), "")

    MSG_CENTER_NOTIF(INSTAGIB_DOWNGRADE,                N_ENABLE,    0, 0, "",               CPID_INSTAGIB_FINDAMMO, "5 0",  _("^BGYour weapon has been downgraded until you find some ammo!"), "")
    MSG_CENTER_NOTIF(INSTAGIB_FINDAMMO,                 N_ENABLE,    0, 0, "",               CPID_INSTAGIB_FINDAMMO, "1 9",  _("^F4^COUNT^BG left to find some ammo!"), "")
    MSG_CENTER_NOTIF(INSTAGIB_FINDAMMO_FIRST,           N_ENABLE,    0, 0, "",               CPID_INSTAGIB_FINDAMMO, "1 10", _("^BGGet some ammo or you'll be dead in ^F4^COUNT^BG!"), _("^BGGet some ammo! ^F4^COUNT^BG left!"))
    MSG_CENTER_NOTIF(INSTAGIB_LIVES_REMAINING,          N_ENABLE,    0, 1, "f1",             CPID_Null,              "0 0",  _("^F2Extra lives remaining: ^K1%s"), "")

    MSG_CENTER_NOTIF(NIX_COUNTDOWN,                     N_ENABLE,    0, 2, "item_wepname",   CPID_NIX,               "1 f2", _("^F2^COUNT^BG until weapon change...\nNext weapon: ^F1%s"), "")
    MSG_CENTER_NOTIF(NIX_NEWWEAPON,                     N_ENABLE,    0, 1, "item_wepname",   CPID_NIX,               "0 0",  _("^F2Active weapon: ^F1%s"), "")

    MSG_CENTER_NOTIF(ONS_CAPTURE,                       N_ENABLE,    1, 0, "s1",             CPID_ONSLAUGHT,         "0 0",  _("^BGYou captured %s^BG control point"), "")
    MSG_CENTER_NOTIF(ONS_CAPTURE_NONAME,                N_ENABLE,    0, 0, "",               CPID_ONSLAUGHT,         "0 0",  _("^BGYou captured a control point"), "")
    MULTITEAM_CENTER(ONS_CAPTURE_TEAM,                  N_ENABLE,    1, 0, "s1",             CPID_ONSLAUGHT,         "0 0",  _("^TC^TT^BG team captured %s^BG control point"), "", NAME)
    MULTITEAM_CENTER(ONS_CAPTURE_TEAM_NONAME,           N_ENABLE,    0, 0, "",               CPID_ONSLAUGHT,         "0 0",  _("^TC^TT^BG team captured a control point"), "", NAME)
    MSG_CENTER_NOTIF(ONS_CONTROLPOINT_SHIELDED,         N_ENABLE,    0, 0, "",               CPID_ONS_CAPSHIELD,     "0 0",  _("^BGThis control point currently cannot be captured"), "")
    MSG_CENTER_NOTIF(ONS_GENERATOR_SHIELDED,            N_ENABLE,    0, 0, "",               CPID_ONS_CAPSHIELD,     "0 0",  _("^BGThe enemy generator cannot be destroyed yet\n^F2Capture some control points to unshield it"), "")
    MULTITEAM_CENTER(ONS_NOTSHIELDED,                   N_ENABLE,    0, 0, "",               CPID_ONSLAUGHT,         "0 0",  _("^BGThe ^TCenemy^BG generator is no longer shielded!"), "", NAME)
    MSG_CENTER_NOTIF(ONS_NOTSHIELDED_TEAM,              N_ENABLE,    0, 0, "",               CPID_ONSLAUGHT,         "0 0",  _("^K1Your generator is NOT shielded!\n^BGRe-capture control points to shield it!"), "")
    MSG_CENTER_NOTIF(ONS_TELEPORT,                      N_ENABLE,    0, 0, "pass_key",       CPID_ONSLAUGHT,         "0 0",  _("^BGPress ^F2%s^BG to teleport"), "")
    MSG_CENTER_NOTIF(ONS_TELEPORT_ANTISPAM,             N_ENABLE,    0, 1, "f1secs",         CPID_ONSLAUGHT,         "0 0",  _("^BGTeleporting disabled for %s"), "")

    MSG_CENTER_NOTIF(OVERTIME_FRAG,                     N_ENABLE,    0, 0, "",               CPID_OVERTIME,          "0 0",  _("^F2Now playing ^F4OVERTIME^F2!\nKeep fragging until we have a winner!"), _("^F2Now playing ^F4OVERTIME^F2!\nKeep scoring until we have a winner!"))
    MSG_CENTER_NOTIF(OVERTIME_CONTROLPOINT,             N_ENABLE,    0, 0, "",               CPID_OVERTIME,          "5 0",  _("^F2Now playing ^F4OVERTIME^F2!\n\nGenerators are now decaying.\nThe more control points your team holds,\nthe faster the enemy generator decays"), "")
    MSG_CENTER_NOTIF(OVERTIME_TIME,                     N_ENABLE,    0, 1, "f1time",         CPID_OVERTIME,          "0 0",  _("^F2Now playing ^F4OVERTIME^F2!\n^BGAdded ^F4%s^BG to the game!"), "")

    MSG_CENTER_NOTIF(PORTO_CREATED_IN,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^K1In^BG-portal created"), "")
    MSG_CENTER_NOTIF(PORTO_CREATED_OUT,                 N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^F3Out^BG-portal created"), "")
    MSG_CENTER_NOTIF(PORTO_FAILED,                      N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^F1Portal creation failed"), "")

    MSG_CENTER_NOTIF(POWERUP_STRENGTH,                  N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Strength infuses your weapons with devastating power"), "")
    MSG_CENTER_NOTIF(POWERDOWN_STRENGTH,                N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Strength has worn off"), "")

    MSG_CENTER_NOTIF(POWERUP_SHIELD,                    N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Shield surrounds you"), "")
    MSG_CENTER_NOTIF(POWERDOWN_SHIELD,                  N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Shield has worn off"), "")

    MSG_CENTER_NOTIF(POWERUP_SPEED,                     N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2You are on speed"), "")
    MSG_CENTER_NOTIF(POWERDOWN_SPEED,                   N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Speed has worn off"), "")

    MSG_CENTER_NOTIF(POWERUP_INVISIBILITY,              N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2You are invisible"), "")
    MSG_CENTER_NOTIF(POWERDOWN_INVISIBILITY,            N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Invisibility has worn off"), "")

    MSG_CENTER_NOTIF(QUIT_PLAYBAN_TEAMKILL,             N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You are forced to spectate and you aren't allowed to play because you are banned in this server")), "")

    MSG_CENTER_NOTIF(RACE_FINISHLAP,                    N_ENABLE,    0, 0, "",               CPID_RACE_FINISHLAP,    "0 0",  _("^F2The race is over, finish your lap!"), "")

    MSG_CENTER_NOTIF(SEQUENCE_COMPLETED,                N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^BGSequence completed!"), "")
    MSG_CENTER_NOTIF(SEQUENCE_COUNTER,                  N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^BGThere are more to go..."), "")
    MSG_CENTER_NOTIF(SEQUENCE_COUNTER_FEWMORE,          N_ENABLE,    0, 1, "f1",             CPID_Null,              "0 0",  _("^BGOnly %s^BG more to go..."), "")

    MSG_CENTER_NOTIF(SPECTATE_WARNING,                  N_ENABLE,    0, 1, "f1secs",         CPID_PREVENT_JOIN,      "0 0",  _("^F2You have to become a player within the next %s, otherwise you will be kicked, because spectating isn't allowed at this time!"), "") // same string as INFO_SPECTATE_WARNING
    MSG_CENTER_NOTIF(SPECTATE_NOTALLOWED,               N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^F2Spectating isn't allowed at this time!"), "")
    MSG_CENTER_NOTIF(SPECTATE_SPEC_NOTALLOWED,          N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  _("^F2Spectating specific players isn't allowed at this time!"), "")

    MSG_CENTER_NOTIF(SUPERWEAPON_BROKEN,                N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Superweapons have broken down"), "")
    MSG_CENTER_NOTIF(SUPERWEAPON_LOST,                  N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2Superweapons have been lost"), "")
    MSG_CENTER_NOTIF(SUPERWEAPON_PICKUP,                N_ENABLE,    0, 0, "",               CPID_POWERUP,           "0 0",  _("^F2You now have a superweapon"), "")

    MSG_CENTER_NOTIF(SURVIVAL_HUNTER,                   N_ENABLE,    0, 0, "",               CPID_SURVIVAL,          "5 0",  BOLD(_("^BGYou are a ^K1hunter^BG! Eliminate the survivor(s) without raising suspicion!")), "")
    MSG_CENTER_NOTIF(SURVIVAL_HUNTER_WIN,               N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^K1Hunters^BG win the round"), "")
    MSG_CENTER_NOTIF(SURVIVAL_SURVIVOR,                 N_ENABLE,    0, 0, "",               CPID_SURVIVAL,          "5 0",  BOLD(_("^BGYou are a ^F1survivor^BG! Identify and eliminate the hunter(s)!")), "")
    MSG_CENTER_NOTIF(SURVIVAL_SURVIVOR_WIN,             N_ENABLE,    0, 0, "",               CPID_ROUND,             "0 0",  _("^F1Survivors^BG win the round"), "")

    MULTITEAM_CENTER(TEAMCHANGE,                        N_ENABLE,    0, 1, "",               CPID_TEAMCHANGE,        "1 f1", _("^K1Changing to ^TC^TT^K1 in ^COUNT"), "", NAME)
    MSG_CENTER_NOTIF(TEAMCHANGE_SPECTATE,               N_ENABLE,    0, 1, "",               CPID_TEAMCHANGE,        "1 f1", _("^K1Spectating in ^COUNT"), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_SUICIDE,                N_ENABLE,    0, 1, "",               CPID_TEAMCHANGE,        "1 f1", _("^K1Suicide in ^COUNT"), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_ALREADYBEST,            N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2Your current team choice seems fine."), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_LARGERTEAM,             N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2You're not allowed to join a larger team!"), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_NOTALLOWED,             N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2You're not allowed to join that team!"), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_LOCKED,                 N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2Teams are locked, you can't join or change teams until they're unlocked or the map changes."), "")
    MSG_CENTER_NOTIF(TEAMCHANGE_SAME,                   N_ENABLE,    0, 0, "",               CPID_PREVENT_JOIN,      "0 0",  _("^K2You're already on that team!"), "")

    MSG_CENTER_NOTIF(TIMEOUT_BEGINNING,                 N_ENABLE,    0, 1, "",               CPID_TIMEOUT,           "1 f1", _("^F4Timeout begins in ^COUNT"), "")
    MSG_CENTER_NOTIF(TIMEOUT_ENDING,                    N_ENABLE,    0, 1, "",               CPID_TIMEIN,            "1 f1", _("^F4Timeout ends in ^COUNT"), "")

    MSG_CENTER_NOTIF(VEHICLE_ENTER,                     N_ENABLE,    0, 0, "pass_key",       CPID_VEHICLES,          "0 0",  _("^BGPress ^F2%s^BG to enter/exit the vehicle"), "")
    MSG_CENTER_NOTIF(VEHICLE_ENTER_GUNNER,              N_ENABLE,    0, 0, "pass_key",       CPID_VEHICLES,          "0 0",  _("^BGPress ^F2%s^BG to enter the vehicle gunner"), "")
    MSG_CENTER_NOTIF(VEHICLE_ENTER_STEAL,               N_ENABLE,    0, 0, "pass_key",       CPID_VEHICLES,          "0 0",  _("^BGPress ^F2%s^BG to steal this vehicle"), "")
    MSG_CENTER_NOTIF(VEHICLE_STEAL,                     N_ENABLE,    0, 0, "",               CPID_VEHICLES_OTHER,    "0 0",  _("^F2The enemy is stealing one of your vehicles!\n^F4Stop them!"), "")
    MSG_CENTER_NOTIF(VEHICLE_STEAL_SELF,                N_ENABLE,    0, 0, "",               CPID_VEHICLES_OTHER,    "4 0",  _("^F2Intruder detected, disabling shields!"), "")

    MSG_CENTER_NOTIF(VOTEBAN,                           N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You aren't allowed to call a vote because you are banned in this server")), "")
    MSG_CENTER_NOTIF(VOTEBANYN,                         N_ENABLE,    0, 0, "",               CPID_Null,              "0 0",  BOLD(_("^K1You aren't allowed to vote because you are banned in this server")), "")

    MSG_CENTER_NOTIF(WEAPON_MINELAYER_LIMIT,            N_ENABLE,    0, 1, "f1",             CPID_Null,              "0 0",  _("^BGYou cannot place more than ^F2%s^BG mines at a time"), "")

#undef N_DISABL
#undef N_ENABLE

// default value for multi notification cvars:
// 0: off, 1: enable this multiple notification
#define N_DISABL 0
#define N_ENABLE 1

#define MULTITEAM_MULTI(prefix, defaultvalue, anncepre, infopre, centerpre) \
    MSG_MULTI_NOTIF(prefix##_RED, defaultvalue, anncepre##_RED, infopre##_RED, centerpre##_RED) \
    MSG_MULTI_NOTIF(prefix##_BLUE, defaultvalue, anncepre##_BLUE, infopre##_BLUE, centerpre##_BLUE) \
    MSG_MULTI_NOTIF(prefix##_YELLOW, defaultvalue, anncepre##YELLOW, infopre##YELLOW, centerpre##YELLOW) \
    MSG_MULTI_NOTIF(prefix##_PINK, defaultvalue, anncepre##PINK, infopre##PINK, centerpre##PINK)

// MSG_MULTI_NOTIFICATIONS
    MSG_MULTI_NOTIF(COUNTDOWN_BEGIN,                    N_ENABLE,  ANNCE_BEGIN,    NULL,                                   CENTER_COUNTDOWN_BEGIN)
    MSG_MULTI_NOTIF(COUNTDOWN_STOP_MINPLAYERS,          N_ENABLE,  NULL,           INFO_COUNTDOWN_STOP_MINPLAYERS,         CENTER_COUNTDOWN_STOP_MINPLAYERS)
    MSG_MULTI_NOTIF(COUNTDOWN_STOP_BADTEAMS,            N_ENABLE,  NULL,           INFO_COUNTDOWN_STOP_BADTEAMS,           CENTER_COUNTDOWN_STOP_BADTEAMS)

    MSG_MULTI_NOTIF(DEATH_MURDER_BUFF,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_BUFF,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_CHEAT,                 N_ENABLE,  NULL,           INFO_DEATH_MURDER_CHEAT,                NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_DROWN,                 N_ENABLE,  NULL,           INFO_DEATH_MURDER_DROWN,                NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_FALL,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_FALL,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_FIRE,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_FIRE,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_LAVA,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_LAVA,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_MONSTER,               N_ENABLE,  NULL,           INFO_DEATH_MURDER_MONSTER,              CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_MURDER_NADE,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_NADE,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_NADE_NAPALM,           N_ENABLE,  NULL,           INFO_DEATH_MURDER_NADE_NAPALM,          NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_NADE_ICE,              N_ENABLE,  NULL,           INFO_DEATH_MURDER_NADE_ICE,             NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_NADE_HEAL,             N_ENABLE,  NULL,           INFO_DEATH_MURDER_NADE_HEAL,            NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_SHOOTING_STAR,         N_ENABLE,  NULL,           INFO_DEATH_MURDER_SHOOTING_STAR,        NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_SLIME,                 N_ENABLE,  NULL,           INFO_DEATH_MURDER_SLIME,                NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_SWAMP,                 N_ENABLE,  NULL,           INFO_DEATH_MURDER_SWAMP,                NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_TELEFRAG,              N_ENABLE,  NULL,           INFO_DEATH_MURDER_TELEFRAG,             NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_TOUCHEXPLODE,          N_ENABLE,  NULL,           INFO_DEATH_MURDER_TOUCHEXPLODE,         NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_BUMB_DEATH,         N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_BUMB_DEATH,        NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_BUMB_GUN,           N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_BUMB_GUN,          NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_CRUSH,              N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_CRUSH,             NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_RAPT_BOMB,          N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_RAPT_BOMB,         NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_RAPT_CANNON,        N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_RAPT_CANNON,       NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_RAPT_DEATH,         N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_RAPT_DEATH,        NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_SPID_DEATH,         N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_SPID_DEATH,        NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_SPID_MINIGUN,       N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_SPID_MINIGUN,      NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_SPID_ROCKET,        N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_SPID_ROCKET,       NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_WAKI_DEATH,         N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_WAKI_DEATH,        NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_WAKI_GUN,           N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_WAKI_GUN,          NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VH_WAKI_ROCKET,        N_ENABLE,  NULL,           INFO_DEATH_MURDER_VH_WAKI_ROCKET,       NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VOID,                  N_ENABLE,  NULL,           INFO_DEATH_MURDER_VOID,                 NULL)
    MSG_MULTI_NOTIF(DEATH_MURDER_VOID_ENT,              N_ENABLE,  NULL,           INFO_DEATH_MURDER_VOID_ENT,             NULL)

    MSG_MULTI_NOTIF(DEATH_SELF_AUTOTEAMCHANGE,          N_ENABLE,  NULL,           INFO_DEATH_SELF_AUTOTEAMCHANGE,         CENTER_DEATH_SELF_AUTOTEAMCHANGE)
    MSG_MULTI_NOTIF(DEATH_SELF_BETRAYAL,                N_ENABLE,  NULL,           INFO_DEATH_SELF_BETRAYAL,               CENTER_DEATH_SELF_BETRAYAL)
    MSG_MULTI_NOTIF(DEATH_SELF_CAMP,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_CAMP,                   CENTER_DEATH_SELF_CAMP)
    MSG_MULTI_NOTIF(DEATH_SELF_CHEAT,                   N_ENABLE,  NULL,           INFO_DEATH_SELF_CHEAT,                  CENTER_DEATH_SELF_CHEAT)
    MSG_MULTI_NOTIF(DEATH_SELF_CUSTOM,                  N_ENABLE,  NULL,           INFO_DEATH_SELF_GENERIC,                CENTER_DEATH_SELF_CUSTOM)
    MSG_MULTI_NOTIF(DEATH_SELF_DROWN,                   N_ENABLE,  NULL,           INFO_DEATH_SELF_DROWN,                  CENTER_DEATH_SELF_DROWN)
    MSG_MULTI_NOTIF(DEATH_SELF_FALL,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_FALL,                   CENTER_DEATH_SELF_FALL)
    MSG_MULTI_NOTIF(DEATH_SELF_FIRE,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_FIRE,                   CENTER_DEATH_SELF_FIRE)
    MSG_MULTI_NOTIF(DEATH_SELF_GENERIC,                 N_ENABLE,  NULL,           INFO_DEATH_SELF_GENERIC,                CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(DEATH_SELF_LAVA,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_LAVA,                   CENTER_DEATH_SELF_LAVA)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_MAGE,                N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_MAGE,               CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_GOLEM_CLAW,          N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_GOLEM_CLAW,         CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_GOLEM_SMASH,         N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_GOLEM_SMASH,        CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_GOLEM_ZAP,           N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_GOLEM_ZAP,          CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_SPIDER,              N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_SPIDER,             CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_WYVERN,              N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_WYVERN,             CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_ZOMBIE_JUMP,         N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_ZOMBIE_JUMP,        CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_MON_ZOMBIE_MELEE,        N_ENABLE,  NULL,           INFO_DEATH_SELF_MON_ZOMBIE_MELEE,       CENTER_DEATH_SELF_MONSTER)
    MSG_MULTI_NOTIF(DEATH_SELF_NADE,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_NADE,                   CENTER_DEATH_SELF_NADE)
    MSG_MULTI_NOTIF(DEATH_SELF_NADE_NAPALM,             N_ENABLE,  NULL,           INFO_DEATH_SELF_NADE_NAPALM,            CENTER_DEATH_SELF_NADE_NAPALM)
    MSG_MULTI_NOTIF(DEATH_SELF_NADE_ICE,                N_ENABLE,  NULL,           INFO_DEATH_SELF_NADE_ICE,               CENTER_DEATH_SELF_NADE)
    MSG_MULTI_NOTIF(DEATH_SELF_NADE_HEAL,               N_ENABLE,  NULL,           INFO_DEATH_SELF_NADE_HEAL,              CENTER_DEATH_SELF_NADE_HEAL)
    MSG_MULTI_NOTIF(DEATH_SELF_NOAMMO,                  N_ENABLE,  NULL,           INFO_DEATH_SELF_NOAMMO,                 CENTER_DEATH_SELF_NOAMMO)
    MSG_MULTI_NOTIF(DEATH_SELF_ROT,                     N_ENABLE,  NULL,           INFO_DEATH_SELF_ROT,                    CENTER_DEATH_SELF_ROT)
    MSG_MULTI_NOTIF(DEATH_SELF_SHOOTING_STAR,           N_ENABLE,  NULL,           INFO_DEATH_SELF_SHOOTING_STAR,          CENTER_DEATH_SELF_SHOOTING_STAR)
    MSG_MULTI_NOTIF(DEATH_SELF_SLIME,                   N_ENABLE,  NULL,           INFO_DEATH_SELF_SLIME,                  CENTER_DEATH_SELF_SLIME)
    MSG_MULTI_NOTIF(DEATH_SELF_SUICIDE,                 N_ENABLE,  NULL,           INFO_DEATH_SELF_SUICIDE,                CENTER_DEATH_SELF_SUICIDE)
    MSG_MULTI_NOTIF(DEATH_SELF_SWAMP,                   N_ENABLE,  NULL,           INFO_DEATH_SELF_SWAMP,                  CENTER_DEATH_SELF_SWAMP)
    MSG_MULTI_NOTIF(DEATH_SELF_TEAMCHANGE,              N_ENABLE,  NULL,           INFO_DEATH_SELF_TEAMCHANGE,             CENTER_DEATH_SELF_TEAMCHANGE)
    MSG_MULTI_NOTIF(DEATH_SELF_TOUCHEXPLODE,            N_ENABLE,  NULL,           INFO_DEATH_SELF_TOUCHEXPLODE,           CENTER_DEATH_SELF_TOUCHEXPLODE)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET,                  N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET,                 CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_EWHEEL,           N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_EWHEEL,          CENTER_DEATH_SELF_TURRET_EWHEEL)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_FLAC,             N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_FLAC,            CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_HELLION,          N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_HELLION,         CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_HK,               N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_HK,              CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_MACHINEGUN,       N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_MACHINEGUN,      CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_MLRS,             N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_MLRS,            CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_PHASER,           N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_PHASER,          CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_PLASMA,           N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_PLASMA,          CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_TESLA,            N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_TESLA,           CENTER_DEATH_SELF_TURRET)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_WALK_GUN,         N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_WALK_GUN,        CENTER_DEATH_SELF_TURRET_WALK)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_WALK_MELEE,       N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_WALK_MELEE,      CENTER_DEATH_SELF_TURRET_WALK)
    MSG_MULTI_NOTIF(DEATH_SELF_TURRET_WALK_ROCKET,      N_ENABLE,  NULL,           INFO_DEATH_SELF_TURRET_WALK_ROCKET,     CENTER_DEATH_SELF_TURRET_WALK)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_BUMB_DEATH,           N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_BUMB_DEATH,          CENTER_DEATH_SELF_VH_BUMB_DEATH)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_CRUSH,                N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_CRUSH,               CENTER_DEATH_SELF_VH_CRUSH)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_RAPT_BOMB,            N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_RAPT_BOMB,           CENTER_DEATH_SELF_VH_RAPT_BOMB)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_RAPT_DEATH,           N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_RAPT_DEATH,          CENTER_DEATH_SELF_VH_RAPT_DEATH)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_SPID_DEATH,           N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_SPID_DEATH,          CENTER_DEATH_SELF_VH_SPID_DEATH)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_SPID_ROCKET,          N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_SPID_ROCKET,         CENTER_DEATH_SELF_VH_SPID_ROCKET)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_WAKI_DEATH,           N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_WAKI_DEATH,          CENTER_DEATH_SELF_VH_WAKI_DEATH)
    MSG_MULTI_NOTIF(DEATH_SELF_VH_WAKI_ROCKET,          N_ENABLE,  NULL,           INFO_DEATH_SELF_VH_WAKI_ROCKET,         CENTER_DEATH_SELF_VH_WAKI_ROCKET)
    MSG_MULTI_NOTIF(DEATH_SELF_VOID,                    N_ENABLE,  NULL,           INFO_DEATH_SELF_VOID,                   CENTER_DEATH_SELF_VOID)
    MSG_MULTI_NOTIF(DEATH_SELF_VOID_ENT,                N_ENABLE,  NULL,           INFO_DEATH_SELF_VOID_ENT,               CENTER_DEATH_SELF_VOID)

    MSG_MULTI_NOTIF(ITEM_BUFF_DROP,                     N_ENABLE,  NULL,           INFO_ITEM_BUFF_DROP,                    CENTER_ITEM_BUFF_DROP)
    MSG_MULTI_NOTIF(ITEM_BUFF_GOT,                      N_ENABLE,  NULL,           INFO_ITEM_BUFF_GOT,                     CENTER_ITEM_BUFF_GOT)
    MSG_MULTI_NOTIF(ITEM_WEAPON_DONTHAVE,               N_ENABLE,  NULL,           INFO_ITEM_WEAPON_DONTHAVE,              CENTER_ITEM_WEAPON_DONTHAVE)
    MSG_MULTI_NOTIF(ITEM_WEAPON_DROP,                   N_ENABLE,  NULL,           INFO_ITEM_WEAPON_DROP,                  CENTER_ITEM_WEAPON_DROP)
    MSG_MULTI_NOTIF(ITEM_WEAPON_GOT,                    N_ENABLE,  NULL,           INFO_ITEM_WEAPON_GOT,                   CENTER_ITEM_WEAPON_GOT)
    MSG_MULTI_NOTIF(ITEM_WEAPON_NOAMMO,                 N_ENABLE,  NULL,           INFO_ITEM_WEAPON_NOAMMO,                CENTER_ITEM_WEAPON_NOAMMO)
    MSG_MULTI_NOTIF(ITEM_WEAPON_PRIMORSEC,              N_ENABLE,  NULL,           INFO_ITEM_WEAPON_PRIMORSEC,             CENTER_ITEM_WEAPON_PRIMORSEC)
    MSG_MULTI_NOTIF(ITEM_WEAPON_UNAVAILABLE,            N_ENABLE,  NULL,           INFO_ITEM_WEAPON_UNAVAILABLE,           CENTER_ITEM_WEAPON_UNAVAILABLE)

    MSG_MULTI_NOTIF(MULTI_COINTOSS,                     N_ENABLE,  NULL,           INFO_COINTOSS,                          CENTER_COINTOSS)
    MSG_MULTI_NOTIF(MULTI_INSTAGIB_FINDAMMO,            N_ENABLE,  ANNCE_NUM_10,   NULL,                                   CENTER_INSTAGIB_FINDAMMO_FIRST)

    MSG_MULTI_NOTIF(SPECTATE_WARNING,                   N_ENABLE,  NULL,           INFO_SPECTATE_WARNING,                  CENTER_SPECTATE_WARNING)
    MSG_MULTI_NOTIF(SPECTATE_NOTALLOWED,                N_ENABLE,  NULL,           INFO_SPECTATE_NOTALLOWED,               CENTER_SPECTATE_NOTALLOWED)
    MSG_MULTI_NOTIF(SPECTATE_SPEC_NOTALLOWED,           N_ENABLE,  NULL,           INFO_SPECTATE_SPEC_NOTALLOWED,          CENTER_SPECTATE_SPEC_NOTALLOWED)

    MSG_MULTI_NOTIF(WEAPON_ACCORDEON_MURDER,            N_ENABLE,  NULL,           INFO_WEAPON_ACCORDEON_MURDER,           NULL)
    MSG_MULTI_NOTIF(WEAPON_ACCORDEON_SUICIDE,           N_ENABLE,  NULL,           INFO_WEAPON_ACCORDEON_SUICIDE,          CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_ARC_MURDER,                  N_ENABLE,  NULL,           INFO_WEAPON_ARC_MURDER,                 NULL)
    MSG_MULTI_NOTIF(WEAPON_ARC_MURDER_SPRAY,            N_ENABLE,  NULL,           INFO_WEAPON_ARC_MURDER_SPRAY,           NULL)
    MSG_MULTI_NOTIF(WEAPON_ARC_SUICIDE_BOLT,            N_ENABLE,  NULL,           INFO_WEAPON_ARC_SUICIDE_BOLT,           CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_BLASTER_MURDER,              N_ENABLE,  NULL,           INFO_WEAPON_BLASTER_MURDER,             NULL)
    MSG_MULTI_NOTIF(WEAPON_BLASTER_SUICIDE,             N_ENABLE,  NULL,           INFO_WEAPON_BLASTER_SUICIDE,            CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_CRYLINK_MURDER,              N_ENABLE,  NULL,           INFO_WEAPON_CRYLINK_MURDER,             NULL)
    MSG_MULTI_NOTIF(WEAPON_CRYLINK_SUICIDE,             N_ENABLE,  NULL,           INFO_WEAPON_CRYLINK_SUICIDE,            CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_DEVASTATOR_MURDER_DIRECT,    N_ENABLE,  NULL,           INFO_WEAPON_DEVASTATOR_MURDER_DIRECT,   NULL)
    MSG_MULTI_NOTIF(WEAPON_DEVASTATOR_MURDER_SPLASH,    N_ENABLE,  NULL,           INFO_WEAPON_DEVASTATOR_MURDER_SPLASH,   NULL)
    MSG_MULTI_NOTIF(WEAPON_DEVASTATOR_SUICIDE,          N_ENABLE,  NULL,           INFO_WEAPON_DEVASTATOR_SUICIDE,         CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_ELECTRO_MURDER_BOLT,         N_ENABLE,  NULL,           INFO_WEAPON_ELECTRO_MURDER_BOLT,        NULL)
    MSG_MULTI_NOTIF(WEAPON_ELECTRO_MURDER_COMBO,        N_ENABLE,  NULL,           INFO_WEAPON_ELECTRO_MURDER_COMBO,       NULL)
    MSG_MULTI_NOTIF(WEAPON_ELECTRO_MURDER_ORBS,         N_ENABLE,  NULL,           INFO_WEAPON_ELECTRO_MURDER_ORBS,        NULL)
    MSG_MULTI_NOTIF(WEAPON_ELECTRO_SUICIDE_BOLT,        N_ENABLE,  NULL,           INFO_WEAPON_ELECTRO_SUICIDE_BOLT,       CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_ELECTRO_SUICIDE_ORBS,        N_ENABLE,  NULL,           INFO_WEAPON_ELECTRO_SUICIDE_ORBS,       CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_FIREBALL_MURDER_BLAST,       N_ENABLE,  NULL,           INFO_WEAPON_FIREBALL_MURDER_BLAST,      NULL)
    MSG_MULTI_NOTIF(WEAPON_FIREBALL_MURDER_FIREMINE,    N_ENABLE,  NULL,           INFO_WEAPON_FIREBALL_MURDER_FIREMINE,   NULL)
    MSG_MULTI_NOTIF(WEAPON_FIREBALL_SUICIDE_BLAST,      N_ENABLE,  NULL,           INFO_WEAPON_FIREBALL_SUICIDE_BLAST,     CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_FIREBALL_SUICIDE_FIREMINE,   N_ENABLE,  NULL,           INFO_WEAPON_FIREBALL_SUICIDE_FIREMINE,  CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_HAGAR_MURDER_BURST,          N_ENABLE,  NULL,           INFO_WEAPON_HAGAR_MURDER_BURST,         NULL)
    MSG_MULTI_NOTIF(WEAPON_HAGAR_MURDER_SPRAY,          N_ENABLE,  NULL,           INFO_WEAPON_HAGAR_MURDER_SPRAY,         NULL)
    MSG_MULTI_NOTIF(WEAPON_HAGAR_SUICIDE,               N_ENABLE,  NULL,           INFO_WEAPON_HAGAR_SUICIDE,              CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_HLAC_MURDER,                 N_ENABLE,  NULL,           INFO_WEAPON_HLAC_MURDER,                NULL)
    MSG_MULTI_NOTIF(WEAPON_HLAC_SUICIDE,                N_ENABLE,  NULL,           INFO_WEAPON_HLAC_SUICIDE,               CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_HOOK_MURDER,                 N_ENABLE,  NULL,           INFO_WEAPON_HOOK_MURDER,                NULL)
    MSG_MULTI_NOTIF(WEAPON_KLEINBOTTLE_MURDER,          N_ENABLE,  NULL,           INFO_WEAPON_KLEINBOTTLE_MURDER,         NULL)
    MSG_MULTI_NOTIF(WEAPON_KLEINBOTTLE_SUICIDE,         N_ENABLE,  NULL,           INFO_WEAPON_KLEINBOTTLE_SUICIDE,        CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_MACHINEGUN_MURDER_SNIPE,     N_ENABLE,  NULL,           INFO_WEAPON_MACHINEGUN_MURDER_SNIPE,    NULL)
    MSG_MULTI_NOTIF(WEAPON_MACHINEGUN_MURDER_SPRAY,     N_ENABLE,  NULL,           INFO_WEAPON_MACHINEGUN_MURDER_SPRAY,    NULL)
    MSG_MULTI_NOTIF(WEAPON_MINELAYER_LIMIT,             N_ENABLE,  NULL,           INFO_WEAPON_MINELAYER_LIMIT,            CENTER_WEAPON_MINELAYER_LIMIT)
    MSG_MULTI_NOTIF(WEAPON_MINELAYER_MURDER,            N_ENABLE,  NULL,           INFO_WEAPON_MINELAYER_MURDER,           NULL)
    MSG_MULTI_NOTIF(WEAPON_MINELAYER_SUICIDE,           N_ENABLE,  NULL,           INFO_WEAPON_MINELAYER_SUICIDE,          CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_MORTAR_MURDER_BOUNCE,        N_ENABLE,  NULL,           INFO_WEAPON_MORTAR_MURDER_BOUNCE,       NULL)
    MSG_MULTI_NOTIF(WEAPON_MORTAR_MURDER_EXPLODE,       N_ENABLE,  NULL,           INFO_WEAPON_MORTAR_MURDER_EXPLODE,      NULL)
    MSG_MULTI_NOTIF(WEAPON_MORTAR_SUICIDE_BOUNCE,       N_ENABLE,  NULL,           INFO_WEAPON_MORTAR_SUICIDE_BOUNCE,      CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_MORTAR_SUICIDE_EXPLODE,      N_ENABLE,  NULL,           INFO_WEAPON_MORTAR_SUICIDE_EXPLODE,     CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_HMG_MURDER_SPRAY,   N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_HMG_MURDER_SPRAY,  NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_MACHINEGUN_MURDER,  N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_MACHINEGUN_MURDER, NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_NEX_MURDER,         N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_NEX_MURDER,        NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_RPC_MURDER_DIRECT,  N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_RPC_MURDER_DIRECT, NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_RPC_MURDER_SPLASH,  N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_RPC_MURDER_SPLASH, NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_RPC_SUICIDE_DIRECT, N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_RPC_SUICIDE_DIRECT,NULL)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_RPC_SUICIDE_SPLASH, N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_RPC_SUICIDE_SPLASH,CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_OVERKILL_SHOTGUN_MURDER,     N_ENABLE,  NULL,           INFO_WEAPON_OVERKILL_SHOTGUN_MURDER,    NULL)
    MSG_MULTI_NOTIF(WEAPON_RIFLE_MURDER,                N_ENABLE,  NULL,           INFO_WEAPON_RIFLE_MURDER,               NULL)
    MSG_MULTI_NOTIF(WEAPON_RIFLE_MURDER_HAIL,           N_ENABLE,  NULL,           INFO_WEAPON_RIFLE_MURDER_HAIL,          NULL)
    MSG_MULTI_NOTIF(WEAPON_RIFLE_MURDER_HAIL_PIERCING,  N_ENABLE,  NULL,           INFO_WEAPON_RIFLE_MURDER_HAIL_PIERCING, NULL)
    MSG_MULTI_NOTIF(WEAPON_RIFLE_MURDER_PIERCING,       N_ENABLE,  NULL,           INFO_WEAPON_RIFLE_MURDER_PIERCING,      NULL)
    MSG_MULTI_NOTIF(WEAPON_SEEKER_MURDER_SPRAY,         N_ENABLE,  NULL,           INFO_WEAPON_SEEKER_MURDER_SPRAY,        NULL)
    MSG_MULTI_NOTIF(WEAPON_SEEKER_MURDER_TAG,           N_ENABLE,  NULL,           INFO_WEAPON_SEEKER_MURDER_TAG,          NULL)
    MSG_MULTI_NOTIF(WEAPON_SEEKER_SUICIDE,              N_ENABLE,  NULL,           INFO_WEAPON_SEEKER_SUICIDE,             CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_SHOTGUN_MURDER,              N_ENABLE,  NULL,           INFO_WEAPON_SHOTGUN_MURDER,             NULL)
    MSG_MULTI_NOTIF(WEAPON_SHOTGUN_MURDER_SLAP,         N_ENABLE,  NULL,           INFO_WEAPON_SHOTGUN_MURDER_SLAP,        NULL)
    MSG_MULTI_NOTIF(WEAPON_THINKING_WITH_PORTALS,       N_ENABLE,  NULL,           INFO_WEAPON_THINKING_WITH_PORTALS,      CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_TUBA_MURDER,                 N_ENABLE,  NULL,           INFO_WEAPON_TUBA_MURDER,                NULL)
    MSG_MULTI_NOTIF(WEAPON_TUBA_SUICIDE,                N_ENABLE,  NULL,           INFO_WEAPON_TUBA_SUICIDE,               CENTER_DEATH_SELF_GENERIC)
    MSG_MULTI_NOTIF(WEAPON_VAPORIZER_MURDER,            N_ENABLE,  NULL,           INFO_WEAPON_VAPORIZER_MURDER,           NULL)
    MSG_MULTI_NOTIF(WEAPON_VORTEX_MURDER,               N_ENABLE,  NULL,           INFO_WEAPON_VORTEX_MURDER,              NULL)

#define MULTITEAM_CHOICE(prefix, defaultvalue, challow, chtype, optiona, optionb) \
    NOTIF_ADD_AUTOCVAR(CHOICE_##prefix, defaultvalue) \
    NOTIF_ADD_AUTOCVAR(CHOICE_##prefix##_ALLOWED, challow) \
    MSG_CHOICE_NOTIF_TEAM(NUM_TEAM_1, prefix##_RED, prefix, defaultvalue, challow, chtype, optiona##_RED, optionb##_RED) \
    MSG_CHOICE_NOTIF_TEAM(NUM_TEAM_2, prefix##_BLUE, prefix, defaultvalue, challow, chtype, optiona##_BLUE, optionb##_BLUE) \
    MSG_CHOICE_NOTIF_TEAM(NUM_TEAM_3, prefix##_YELLOW, prefix, defaultvalue, challow, chtype, optiona##_YELLOW, optionb##_YELLOW) \
    MSG_CHOICE_NOTIF_TEAM(NUM_TEAM_4, prefix##_PINK, prefix, defaultvalue, challow, chtype, optiona##_PINK, optionb##_PINK)

#undef N_DISABL
#undef N_ENABLE

// default value for choice notification cvars (notification_CHOICE_*):
// 0: off, 1: display default message, 2: display verbose message
#define N_DISABLE 0
#define N__NORMAL 1
#define N_VERBOSE 2

// default value for allowed choice notification cvars (notification_CHOICE_*_ALLOWED):
// 0: never allowed, 1: allowed in warmup, 2: always allowed
#define A__NEVER 0
#define A_WARMUP 1
#define A_ALWAYS 2

// MSG_CHOICE_NOTIFICATIONS
    MULTITEAM_CHOICE(CTF_CAPTURE_BROKEN,        N_VERBOSE, A_ALWAYS,  MSG_INFO,   INFO_CTF_CAPTURE,                   INFO_CTF_CAPTURE_BROKEN)
    MULTITEAM_CHOICE(CTF_CAPTURE_TIME,          N_VERBOSE, A_ALWAYS,  MSG_INFO,   INFO_CTF_CAPTURE,                   INFO_CTF_CAPTURE_TIME)
    MULTITEAM_CHOICE(CTF_CAPTURE_UNBROKEN,      N_VERBOSE, A_ALWAYS,  MSG_INFO,   INFO_CTF_CAPTURE,                   INFO_CTF_CAPTURE_UNBROKEN)
    MULTITEAM_CHOICE(CTF_PICKUP_TEAM,           N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_TEAM,             CENTER_CTF_PICKUP_TEAM_VERBOSE)
    MULTITEAM_CHOICE(CTF_PICKUP_ENEMY_OTHER,    N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_ENEMY_OTHER,      CENTER_CTF_PICKUP_ENEMY_OTHER_VERBOSE)
    MSG_CHOICE_NOTIF(CTF_PICKUP_TEAM_NEUTRAL,   N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_TEAM_NEUTRAL,     CENTER_CTF_PICKUP_TEAM_VERBOSE_NEUTRAL)
    MSG_CHOICE_NOTIF(CTF_PICKUP_ENEMY,          N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_ENEMY,            CENTER_CTF_PICKUP_ENEMY_VERBOSE)
    MSG_CHOICE_NOTIF(CTF_PICKUP_ENEMY_NEUTRAL,  N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_ENEMY_NEUTRAL,    CENTER_CTF_PICKUP_ENEMY_NEUTRAL_VERBOSE)
    MSG_CHOICE_NOTIF(CTF_PICKUP_ENEMY_TEAM,     N__NORMAL, A_ALWAYS,  MSG_CENTER, CENTER_CTF_PICKUP_ENEMY_TEAM,       CENTER_CTF_PICKUP_ENEMY_TEAM_VERBOSE)
    MSG_CHOICE_NOTIF(CTF_PICKUP_ENEMY_OTHER_NEUTRAL, N__NORMAL, A_ALWAYS, MSG_CENTER, CENTER_CTF_PICKUP_ENEMY_OTHER_NEUTRAL, CENTER_CTF_PICKUP_ENEMY_OTHER_VERBOSE_NEUTRAL)
    MSG_CHOICE_NOTIF(FRAG,                      N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAG,           CENTER_DEATH_MURDER_FRAG_VERBOSE)
    MSG_CHOICE_NOTIF(FRAGGED,                   N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAGGED,        CENTER_DEATH_MURDER_FRAGGED_VERBOSE)
    MSG_CHOICE_NOTIF(FRAG_FIRE,                 N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAG_FIRE,      CENTER_DEATH_MURDER_FRAG_FIRE_VERBOSE)
    MSG_CHOICE_NOTIF(FRAGGED_FIRE,              N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAGGED_FIRE,   CENTER_DEATH_MURDER_FRAGGED_FIRE_VERBOSE)
    MSG_CHOICE_NOTIF(FRAG_FREEZE,               N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAG_FREEZE,    CENTER_DEATH_MURDER_FRAG_FREEZE_VERBOSE)
    MSG_CHOICE_NOTIF(FRAGGED_FREEZE,            N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_FRAGGED_FREEZE, CENTER_DEATH_MURDER_FRAGGED_FREEZE_VERBOSE)
    MSG_CHOICE_NOTIF(TYPEFRAG,                  N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_TYPEFRAG,       CENTER_DEATH_MURDER_TYPEFRAG_VERBOSE)
    MSG_CHOICE_NOTIF(TYPEFRAGGED,               N__NORMAL, A_WARMUP,  MSG_CENTER, CENTER_DEATH_MURDER_TYPEFRAGGED,    CENTER_DEATH_MURDER_TYPEFRAGGED_VERBOSE)

#undef N_DISABLE
#undef N__NORMAL
#undef N_VERBOSE

// default value for allowed choice notification cvars (notification_CHOICE_*_ALLOWED):
// 0: never allowed, 1: allowed in warmup, 2: always allowed
#undef A__NEVER
#undef A_WARMUP
#undef A_ALWAYS
