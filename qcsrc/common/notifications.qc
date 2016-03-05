#if defined(CSQC)
	#include "../client/announcer.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "constants.qh"
	#include "teams.qh"
	#include "../server/autocvars.qh"
	#include "../server/constants.qh"
	#include "../server/defs.qh"
	#include "notifications.qh"
	#include <server/mutators/all.qh>
#endif

// ================================================
//  Unified notification system, written by Samual
//  Last updated: August, 2013
// ================================================

#ifdef SVQC
string Notification_CheckArgs(
	NOTIF broadcast, entity client,
	Notification net_name)
{
	// check supplied broadcast, target, type, and name for errors
	string checkargs = "";
	if (!net_name) { checkargs = "No notification provided! "; }
	switch (broadcast)
	{
		case NOTIF_ONE:
		case NOTIF_ONE_ONLY:
		{
			if (IS_NOT_A_CLIENT(client)) {
				checkargs = sprintf("%sNo client provided!", checkargs);
			}
			break;
		}

		case NOTIF_ALL_EXCEPT:
		{
			if (IS_NOT_A_CLIENT(client)) {
				checkargs = sprintf("%sException can't be a non-client!", checkargs);
			}
			break;
		}

		case NOTIF_ALL:
		{
			if (client) {
				checkargs = sprintf("%sEntity provided when world was required!", checkargs);
			}
			break;
		}

		case NOTIF_TEAM:
		{
			if (!teamplay) {
				checkargs = sprintf("%sTeamplay not active!", checkargs);
			} else if (!client.team) {
				// checkargs = sprintf("%sNo team provided!", checkargs);
			}
			break;
		}

		case NOTIF_TEAM_EXCEPT:
		{
			if (!teamplay) {
				checkargs = sprintf("%sTeamplay not active!", checkargs);
			} else if (IS_NOT_A_CLIENT(client)) {
				checkargs = sprintf("%sException can't be a non-client!", checkargs);
			}
			break;
		}

		default:
		{
			checkargs = sprintf("%sImproper broadcast: %d!", checkargs, broadcast);
			break;
		}
	}
	return checkargs;
}

bool Notification_ShouldSend(NOTIF broadcast, entity to_client, entity other_client)
{
	switch (broadcast)
	{
		case NOTIF_ONE:
			return (
				(to_client == other_client)
				||
				(
					IS_SPEC(to_client)
					&&
					(to_client.enemy == other_client)
				)
			);
		case NOTIF_ONE_ONLY:
			return (to_client == other_client);
		case NOTIF_TEAM:
			return (
				(to_client.team == other_client.team)
				||
				(
					IS_SPEC(to_client)
					&&
					(to_client.enemy.team == other_client.team)
				)
			);
		case NOTIF_TEAM_EXCEPT:
			return (
				(to_client != other_client)
				&&
				(
					(to_client.team == other_client.team)
					||
					(
						IS_SPEC(to_client)
						&&
						(
							(to_client.enemy != other_client)
							&&
							(to_client.enemy.team == other_client.team)
						)
					)
				)
			);
		case NOTIF_ALL:
			return true;
		case NOTIF_ALL_EXCEPT:
			return (
				(to_client != other_client)
				&&
				!(
					IS_SPEC(to_client)
					&&
					(to_client.enemy == other_client)
				)
			);
		default:
			return false;
	}
}

#endif

// ===============================
//  Initialization Core Functions
// ===============================

// used by restartnotifs command to initialize notifications
void Destroy_Notification_Entity(entity notif)
{
	if (notif.nent_name != "") strunzone(notif.nent_name);
	if (notif.nent_snd != "") strunzone(notif.nent_snd);
	if (notif.nent_args != "") strunzone(notif.nent_args);
	if (notif.nent_hudargs != "") strunzone(notif.nent_hudargs);
	if (notif.nent_icon != "") strunzone(notif.nent_icon);
	if (notif.nent_durcnt != "") strunzone(notif.nent_durcnt);
	if (notif.nent_string != "") strunzone(notif.nent_string);
	remove(notif);
}

void Destroy_All_Notifications()
{
	// kill all networked notifications and centerprints
	#ifdef SVQC
	Kill_Notification(NOTIF_ALL, NULL, MSG_Null, 0);
	#else
	reset_centerprint_messages();
	#endif

	// kill all real notification entities
	FOREACH(Notifications, true, { Destroy_Notification_Entity(it); });
}

string Process_Notif_Line(
	MSG typeId,
	bool chat,
	string input,
	string notiftype,
	string notifname,
	string stringtype)
{
	#ifdef CSQC
	if(typeId == MSG_INFO)
	{
		if((chat && autocvar_notification_allow_chatboxprint)
			|| (autocvar_notification_allow_chatboxprint == 2))
		{
			// pass 1: add ETX char at beginning of line
			input = strcat("\{3}", input);

			// pass 2: add ETX char at end of each new line (so that
			// messages with multiple lines are put through chatbox too)
			input = strreplace("\n", "\n\{3}", input);

			// pass 3: strip trailing ETX char
			if(substring(input, (strlen(input) - 1), 1) == "\{3}")
				{ input = substring(input, 0, (strlen(input) - 1)); }
		}
	}
	#endif

	// done to both MSG_INFO and MSG_CENTER
	if(substring(input, (strlen(input) - 1), 1) == "\n")
	{
		LOG_INFOF(
			(
				"^1TRAILING NEW LINE AT END OF NOTIFICATION: "
				"^7net_type = %s, net_name = %s, string = %s.\n"
			),
			notiftype,
			notifname,
			stringtype
		);
		notif_error = true;
		input = substring(input, 1, (strlen(input) - 1));
	}

	return input;
}

string Process_Notif_Args(
	float arg_type,
	string args,
	string notiftype,
	string notifname)
{
	string selected, remaining = args;
	float sel_num = 0;

	for (;(remaining != "");)
	{
		selected = car(remaining); remaining = cdr(remaining);

		switch(arg_type)
		{
			case 1: // normal args
			{
				if(sel_num == NOTIF_MAX_ARGS)
				{
					LOG_INFOF(
						(
							"^1NOTIFICATION HAS TOO MANY ARGUMENTS: "
							"^7net_type = %s, net_name = %s, max args = %d.\n"
						),
						notiftype,
						notifname,
						NOTIF_MAX_ARGS
					);
					notif_error = true;
					break;
				}

				switch(strtolower(selected))
				{
					#define ARG_CASE_ARG_CS_SV_HA(selected,result) case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_CS_SV_DC(selected,result) case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_CS_SV(selected,result)    case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_CS(selected,result)       case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_SV(selected,result)       case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_DC(selected,result)
					#define ARG_CASE(prog,selected,result)         ARG_CASE_##prog(selected,result)
					NOTIF_ARGUMENT_LIST
					#undef ARG_CASE
					#undef ARG_CASE_ARG_DC
					#undef ARG_CASE_ARG_SV
					#undef ARG_CASE_ARG_CS
					#undef ARG_CASE_ARG_CS_SV
					#undef ARG_CASE_ARG_CS_SV_DC
					#undef ARG_CASE_ARG_CS_SV_HA
					default:
					{
						LOG_INFOF(
							(
								"^1NOTIFICATION WITH UNKNOWN TOKEN IN ARGUMENT STRING: "
								"^7net_type = %s, net_name = %s, args arg = '%s'.\n"
							),
							notiftype,
							notifname,
							selected
						);
						notif_error = true;
						break;
					}
				}
				break;
			}
			case 2: // hudargs
			{
				if(sel_num == NOTIF_MAX_HUDARGS)
				{
					LOG_INFOF(
						(
							"^1NOTIFICATION HAS TOO MANY ARGUMENTS: "
							"^7net_type = %s, net_name = %s, max hudargs = %d.\n"
						),
						notiftype,
						notifname,
						NOTIF_MAX_HUDARGS
					);
					notif_error = true;
					break;
				}

				switch(strtolower(selected))
				{
					#define ARG_CASE_ARG_CS_SV_HA(selected,result) case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_CS_SV_DC(selected,result)
					#define ARG_CASE_ARG_CS_SV(selected,result)
					#define ARG_CASE_ARG_CS(selected,result)
					#define ARG_CASE_ARG_SV(selected,result)
					#define ARG_CASE_ARG_DC(selected,result)
					#define ARG_CASE(prog,selected,result)         ARG_CASE_##prog(selected,result)
					NOTIF_ARGUMENT_LIST
					#undef ARG_CASE
					#undef ARG_CASE_ARG_DC
					#undef ARG_CASE_ARG_SV
					#undef ARG_CASE_ARG_CS
					#undef ARG_CASE_ARG_CS_SV
					#undef ARG_CASE_ARG_CS_SV_DC
					#undef ARG_CASE_ARG_CS_SV_HA
					default:
					{
						LOG_INFOF(
							(
								"^1NOTIFICATION WITH UNKNOWN TOKEN IN ARGUMENT STRING: "
								"^7net_type = %s, net_name = %s, hudargs arg = '%s'.\n"
							),
							notiftype,
							notifname,
							selected
						);
						notif_error = true;
						break;
					}
				}
				break;
			}
			case 3: // durcnt
			{
				if(sel_num == NOTIF_MAX_DURCNT)
				{
					LOG_INFOF(
						(
							"^1NOTIFICATION HAS TOO MANY ARGUMENTS: "
							"^7net_type = %s, net_name = %s, max durcnt = %d.\n"
						),
						notiftype,
						notifname,
						NOTIF_MAX_DURCNT
					);
					notif_error = true;
					break;
				}

				switch(strtolower(selected))
				{
					#define ARG_CASE_ARG_CS_SV_HA(selected,result)
					#define ARG_CASE_ARG_CS_SV_DC(selected,result) case selected: { ++sel_num; break; }
					#define ARG_CASE_ARG_CS_SV(selected,result)
					#define ARG_CASE_ARG_CS(selected,result)
					#define ARG_CASE_ARG_SV(selected,result)
					#define ARG_CASE_ARG_DC(selected,result)       case selected: { ++sel_num; break; }
					#define ARG_CASE(prog,selected,result)         ARG_CASE_##prog(selected,result)
					NOTIF_ARGUMENT_LIST
					#undef ARG_CASE
					#undef ARG_CASE_ARG_DC
					#undef ARG_CASE_ARG_SV
					#undef ARG_CASE_ARG_CS
					#undef ARG_CASE_ARG_CS_SV
					#undef ARG_CASE_ARG_CS_SV_DC
					#undef ARG_CASE_ARG_CS_SV_HA
					default:
					{
						if(ftos(stof(selected)) != "") { ++sel_num; }
						else
						{
							LOG_INFOF(
								(
									"^1NOTIFICATION WITH UNKNOWN TOKEN IN ARGUMENT STRING: "
									"^7net_type = %s, net_name = %s, durcnt arg = '%s'.\n"
								),
								notiftype,
								notifname,
								selected
							);
							notif_error = true;
						}
						break;
					}
				}
				break;
			}
		}
	}
	return args;
}

void Create_Notification_Entity(entity notif,
	float var_default,
	float var_cvar,
	MSG typeId,
	string namestring)
{
	// =====================
	//  Global Entity Setup
	// =====================
	notif.nent_default = var_default;
	notif.nent_enabled = (var_cvar >= 1);
	notif.nent_type = typeId;
	notif.nent_name = strzone(namestring);

	// Other pre-notif-setup requisites
	notif_error = false;

	switch (typeId)
	{
		case MSG_ANNCE:
		case MSG_INFO:
		case MSG_CENTER:
		case MSG_MULTI:
		case MSG_CHOICE:
			break;
		default:
			LOG_INFOF(
				(
					"^1NOTIFICATION WITH IMPROPER TYPE: "
					"^7net_type = %d, net_name = %s.\n"
				),
				typeId,
				namestring
			);
			notif_error = true;
			break;
	}

	// now check to see if any errors happened
	if (notif_error)
	{
		notif.nent_enabled = false; // disable the notification so it can't cause trouble
		notif_global_error = true; // throw the red flag that an error happened on init
	}
}

void Create_Notification_Entity_Annce(entity notif,
										float var_cvar,
										string namestring,
										/* MSG_ANNCE */
										float channel,
										string snd,
										float vol,
										float position)
		{
			// Set MSG_ANNCE information and handle precaching
			#ifdef CSQC
			MSG typeId = MSG_ANNCE;
			if (!(GENTLE && (var_cvar == 1)))
			{
				if(snd != "")
				{
					if(notif.nent_enabled)
					{
						precache_sound(sprintf("announcer/%s/%s.wav", AnnouncerOption(), snd));
						notif.nent_channel = channel;
						notif.nent_snd = strzone(snd);
						notif.nent_vol = vol;
						notif.nent_position = position;
					}
				}
				else
				{
					string typestring = Get_Notif_TypeName(typeId);
					LOG_INFOF(
						(
							"^1NOTIFICATION WITH NO SOUND: "
							"^7net_type = %s, net_name = %s.\n"
						),
						typestring,
						namestring
					);
					notif_error = true;
				}
			}
			else { notif.nent_enabled = false; }
			#else
			notif.nent_enabled = false;
			#endif

		}

void Create_Notification_Entity_InfoCenter(entity notif,
											float var_cvar,
											string namestring,
											int strnum,
											int flnum,
											/* MSG_INFO & MSG_CENTER */
											string args,
											string hudargs,
											string icon,
											float cpid,
											string durcnt,
											string normal,
											string gentle)
		{
			MSG typeId = notif.nent_type;
			// Set MSG_INFO and MSG_CENTER string/float counts
			notif.nent_stringcount = strnum;
			notif.nent_floatcount = flnum;

			// Only initialize arguments if we're either a client or on a dedicated server
			#ifdef SVQC
			float should_process_args = server_is_dedicated;
			#else
			float should_process_args = true;
			#endif
			string typestring = Get_Notif_TypeName(typeId);
			if(should_process_args)
			{
				// ========================
				//  Process Main Arguments
				// ========================
				if(strnum + flnum)
				{
					if(args != "")
					{
						notif.nent_args = strzone(
							Process_Notif_Args(1, args, typestring, namestring));
					}
					else if((hudargs == "") && (durcnt ==""))
					{
						LOG_INFOF(
							(
								"^1NOTIFICATION HAS ARG COUNTS BUT NO ARGS OR HUDARGS OR DURCNT: "
								"^7net_type = %s, net_name = %s, strnum = %d, flnum = %d\n"
							),
							typestring,
							namestring,
							strnum,
							flnum
						);
						notif_error = true;
					}
				}
				else if(args != "")
				{
					notif.nent_args = strzone(
						Process_Notif_Args(1, args, typestring, namestring));
				}


				// =======================================
				//  Process HUD and Centerprint Arguments
				//    Only processed on CSQC, as these
				//    args are only for HUD features.
				// =======================================
				#ifdef CSQC
				if(hudargs != "")
				{
					notif.nent_hudargs = strzone(
						Process_Notif_Args(2, hudargs, typestring, namestring));

					if(icon != "") { notif.nent_icon = strzone(icon); }
					else
					{
						LOG_INFOF(
							(
								"^1NOTIFICATION HAS HUDARGS BUT NO ICON: "
								"^7net_type = %s, net_name = %s.\n"
							),
							typestring,
							namestring
						);
						notif_error = true;
					}
				}
				else if(icon != "")
				{
					LOG_INFOF(
						(
							"^1NOTIFICATION HAS ICON BUT NO HUDARGS: "
							"^7net_type = %s, net_name = %s.\n"
						),
						typestring,
						namestring
					);
					notif_error = true;
				}

				if(durcnt != "")
				{
					notif.nent_durcnt = strzone(
						Process_Notif_Args(3, durcnt, typestring, namestring));

					if(cpid != NO_MSG_) { notif.nent_cpid = cpid; }
					else
					{
						LOG_INFOF(
							(
								"^1NOTIFICATION HAS DURCNT BUT NO CPID: "
								"^7net_type = %s, net_name = %s.\n"
							),
							typestring,
							namestring
						);
						notif_error = true;
					}
				}
				else if(cpid != NO_MSG_) { notif.nent_cpid = cpid; }
				#endif


				// ======================
				//  Process Notif String
				// ======================
				#define SET_NOTIF_STRING(string,stringname) MACRO_BEGIN { \
					notif.nent_string = strzone(CCR( \
						Process_Notif_Line( \
							typeId, \
							(var_cvar > 1), \
							string, \
							typestring, \
							namestring, \
							stringname \
						)) \
					); \
				} MACRO_END

				if(GENTLE)
				{
					if(gentle != "") { SET_NOTIF_STRING(gentle, "GENTLE"); }
					else if(normal != "") { SET_NOTIF_STRING(normal, "NORMAL"); }
				}
				else if(normal != "") { SET_NOTIF_STRING(normal, "NORMAL"); }
				#undef SET_NOTIF_STRING

				// Check to make sure a string was chosen
				if(notif.nent_string == "")
				{
					LOG_INFOF(
						(
							"^1EMPTY NOTIFICATION: "
							"^7net_type = %s, net_name = %s.\n"
						),
						typestring,
						namestring
					);
					notif_error = true;
				}
			}
		}

void Create_Notification_Entity_Multi(entity notif,
										float var_cvar,
										string namestring,
										/* MSG_MULTI */
										Notification anncename,
										Notification infoname,
										Notification centername)
		{
			MSG typeId = MSG_MULTI;
			// Set MSG_MULTI string/float counts
			if((anncename == NO_MSG) && (infoname == NO_MSG) && (centername == NO_MSG))
			{
				string typestring = Get_Notif_TypeName(typeId);
				LOG_INFOF(
					(
						"^1NOTIFICATION WITH NO SUBCALLS: "
						"^7net_type = %s, net_name = %s.\n"
					),
					typestring,
					namestring
				);
				notif_error = true;
			}
			else
			{
				// announcements don't actually need any arguments, so lets not even count them.
				if(anncename != NO_MSG) { notif.nent_msgannce = anncename; }

				float infoname_stringcount = 0, infoname_floatcount = 0;
				float centername_stringcount = 0, centername_floatcount = 0;

				if(infoname != NO_MSG)
				{
					notif.nent_msginfo = infoname;
					infoname_stringcount = notif.nent_msginfo.nent_stringcount;
					infoname_floatcount = notif.nent_msginfo.nent_floatcount;
				}

				if(centername != NO_MSG)
				{
					notif.nent_msgcenter = centername;
					centername_stringcount = notif.nent_msgcenter.nent_stringcount;
					centername_floatcount = notif.nent_msgcenter.nent_floatcount;
				}

				// set the requirements of THIS notification to the totals of its subcalls
				notif.nent_stringcount = max(infoname_stringcount, centername_stringcount);
				notif.nent_floatcount = max(infoname_floatcount, centername_floatcount);
			}
		}

void Create_Notification_Entity_Choice(entity notif,
										float var_cvar,
										string namestring,
										/* MSG_CHOICE */
										float challow_def,
										float challow_var,
										MSG chtype,
										Notification optiona,
										Notification optionb)
		{
			MSG typeId = MSG_CHOICE;
			if((chtype == MSG_Null) || (optiona == NO_MSG) || (optionb == NO_MSG))
			{
				string typestring = Get_Notif_TypeName(typeId);
				LOG_INFOF(
					(
						"^1NOTIFICATION IS MISSING CHOICE PARAMS: "
						"^7net_type = %s, net_name = %s.\n"
					),
					typestring,
					namestring
				);
				notif_error = true;
			}
			else
			{
				notif.nent_optiona = optiona;
				notif.nent_optionb = optionb;
				notif.nent_challow_def = challow_def; // 0: never allowed, 1: allowed in warmup, 2: always allowed
				notif.nent_challow_var = challow_var; // 0: never allowed, 1: allowed in warmup, 2: always allowed
				notif.nent_stringcount = max(notif.nent_optiona.nent_stringcount, notif.nent_optionb.nent_stringcount);
				notif.nent_floatcount = max(notif.nent_optiona.nent_floatcount, notif.nent_optionb.nent_floatcount);

				/*#ifdef NOTIFICATIONS_DEBUG
				Debug_Notification(sprintf(
					"Create_Notification_Entity(...): MSG_CHOICE: %s\n%s\n%s\n",
					notif.nent_name,
					sprintf(
						"^ optiona: %s %s : %d %d",
						Get_Notif_TypeName(notif.nent_optiona.nent_type),
						notif.nent_optiona.nent_name,
						notif.nent_optiona.nent_stringcount,
						notif.nent_optiona.nent_floatcount
					),
					sprintf(
						"^ optionb: %s %s : %d %d",
						Get_Notif_TypeName(notif.nent_optionb.nent_type),
						notif.nent_optionb.nent_name,
						notif.nent_optionb.nent_stringcount,
						notif.nent_optionb.nent_floatcount
					)
				));
				#endif*/
			}
		}


// ===============
//  Cvar Handling
// ===============

// used by MSG_CHOICE to build list of choices
#ifdef SVQC
void Notification_GetCvars()
{
	int idx = 0;
	FOREACH(Notifications, it.nent_type == MSG_CHOICE, {
		GetCvars_handleFloat(
			get_cvars_s,
			get_cvars_f,
			msg_choice_choices[idx++],
			sprintf("notification_%s", it.nent_name)
		);
	});
}
#endif

/** used to output notifications.cfg file */
void Dump_Notifications(int fh, bool alsoprint)
{
	#define NOTIF_WRITE(a) MACRO_BEGIN { \
		fputs(fh, a); \
		if (alsoprint) LOG_INFO(a); \
	} MACRO_END

	#define NOTIF_WRITE_ENTITY(e, description) MACRO_BEGIN { \
		string notif_msg = sprintf( \
			"seta notification_%s \"%d\" \"%s\"\n", \
			e.nent_name, e.nent_default, description \
		); \
		NOTIF_WRITE(notif_msg); \
	} MACRO_END

	#define NOTIF_WRITE_ENTITY_CHOICE(e, descriptiona, descriptionb) MACRO_BEGIN { \
		string notif_msg = sprintf( \
			"seta notification_%s \"%d\" \"%s\"\n" \
			"seta notification_%s_ALLOWED \"%d\" \"%s\"\n", \
			e.nent_name, e.nent_default, descriptiona, \
			e.nent_name, e.nent_challow_def, descriptionb \
		); \
		NOTIF_WRITE(notif_msg); \
	} MACRO_END

	#define NOTIF_WRITE_HARDCODED(cvar, default, description) MACRO_BEGIN { \
		string notif_msg = sprintf( \
			"seta notification_%s \"%s\" \"%s\"\n", \
			cvar, default, description \
		); \
		NOTIF_WRITE(notif_msg); \
	} MACRO_END

	// Note: This warning only applies to the notifications.cfg file that is output...
	// You ARE supposed to manually edit this function to add i.e. hard coded
	// notification variables for mutators or game modes or such and then
	// regenerate the notifications.cfg file from the new code.

	NOTIF_WRITE("// ********************************************** //\n");
	NOTIF_WRITE("// ** WARNING - DO NOT MANUALLY EDIT THIS FILE ** //\n");
	NOTIF_WRITE("// **                                          ** //\n");
	NOTIF_WRITE("// **  This file is automatically generated    ** //\n");
	NOTIF_WRITE("// **  by code with the command 'dumpnotifs'.  ** //\n");
	NOTIF_WRITE("// **                                          ** //\n");
	NOTIF_WRITE("// **  If you add a new notification, please   ** //\n");
	NOTIF_WRITE("// **  regenerate this file with that command  ** //\n");
	NOTIF_WRITE("// **  making sure that the output matches     ** //\n");
	NOTIF_WRITE("// **  with the lists and defaults in code.    ** //\n");
	NOTIF_WRITE("// **                                          ** //\n");
	NOTIF_WRITE("// ********************************************** //\n");

	// These notifications will also append their string as a comment...
	// This is not necessary, and does not matter if they vary between config versions,
	// it is just a semi-helpful tool for those who want to manually change their user settings.

	int NOTIF_ANNCE_COUNT = 0; FOREACH(Notifications, it.nent_type == MSG_ANNCE, { ++NOTIF_ANNCE_COUNT; });
	NOTIF_WRITE(sprintf("\n// MSG_ANNCE notifications (count = %d):\n", NOTIF_ANNCE_COUNT));
	FOREACH(Notifications, it.nent_type == MSG_ANNCE, {
		NOTIF_WRITE_ENTITY(it,
			"0 = disabled, 1 = enabled if gentle mode is off, 2 = always enabled"
		);
	});

	int NOTIF_INFO_COUNT = 0; FOREACH(Notifications, it.nent_type == MSG_INFO, { ++NOTIF_INFO_COUNT; });
	NOTIF_WRITE(sprintf("\n// MSG_INFO notifications (count = %d):\n", NOTIF_INFO_COUNT));
	FOREACH(Notifications, it.nent_type == MSG_INFO, {
		NOTIF_WRITE_ENTITY(it,
			"0 = off, 1 = print to console, "
			"2 = print to console and chatbox (if notification_allow_chatboxprint is enabled)"
		);
	});

	int NOTIF_CENTER_COUNT = 0; FOREACH(Notifications, it.nent_type == MSG_CENTER, { ++NOTIF_CENTER_COUNT; });
	NOTIF_WRITE(sprintf("\n// MSG_CENTER notifications (count = %d):\n", NOTIF_CENTER_COUNT));
	FOREACH(Notifications, it.nent_type == MSG_CENTER, {
		NOTIF_WRITE_ENTITY(it,
			"0 = off, 1 = centerprint"
		);
	});

	int NOTIF_MULTI_COUNT = 0; FOREACH(Notifications, it.nent_type == MSG_MULTI, { ++NOTIF_MULTI_COUNT; });
	NOTIF_WRITE(sprintf("\n// MSG_MULTI notifications (count = %d):\n", NOTIF_MULTI_COUNT));
	FOREACH(Notifications, it.nent_type == MSG_MULTI, {
		NOTIF_WRITE_ENTITY(it,
			"Enable this multiple notification"
		);
	});

	int NOTIF_CHOICE_COUNT = 0; FOREACH(Notifications, it.nent_type == MSG_CHOICE, { ++NOTIF_CHOICE_COUNT; });
	NOTIF_WRITE(sprintf("\n// MSG_CHOICE notifications (count = %d):\n", NOTIF_CHOICE_COUNT));
	FOREACH(Notifications, it.nent_type == MSG_CHOICE, {
		NOTIF_WRITE_ENTITY_CHOICE(it,
			"Choice for this notification 0 = off, 1 = default message, 2 = verbose message",
			"Allow choice for this notification 0 = off, 1 = only in warmup mode, 2 = always"
		);
	});

	// edit these to match whichever cvars are used for specific notification options
	NOTIF_WRITE("\n// HARD CODED notification variables:\n");

	NOTIF_WRITE_HARDCODED(
		"allow_chatboxprint", "1",
		"Allow INFO notifications to be printed to chat box"
		"0 = do not allow, "
		"1 = allow only if allowed by individual notification_INFO* cvars, "
		"2 = force all INFO notifications to be printed to the chatbox"
	);

	NOTIF_WRITE_HARDCODED(
		"debug", "0",
		"Print extra debug information on all notification function calls "
		"(Requires -DNOTIFICATIONS_DEBUG flag to be enabled on QCSRC compilation)... "
		"0 = disabled, 1 = dprint, 2 = print"
	);

	NOTIF_WRITE_HARDCODED(
		"errors_are_fatal", "1",
		"If a notification fails upon initialization, cause a Host_Error to stop the program"
	);

	NOTIF_WRITE_HARDCODED(
		"item_centerprinttime", "1.5",
		"How long to show item information centerprint messages (like 'You got the Electro' or such)"
	);

	NOTIF_WRITE_HARDCODED(
		"lifetime_mapload", "10",
		"Amount of time that notification entities last immediately at mapload (in seconds) "
		"to help prevent notifications from being lost on early init (like gamestart countdown)"
	);

	NOTIF_WRITE_HARDCODED(
		"lifetime_runtime", "0.5",
		"Amount of time that notification entities last on the server during runtime (In seconds)"
	);

	NOTIF_WRITE_HARDCODED(
		"server_allows_location", "1",
		"Server side cvar for allowing death messages to show location information too"
	);

	NOTIF_WRITE_HARDCODED(
		"show_location", "0",
		"Append location information to MSG_INFO death/kill messages"
	);

	NOTIF_WRITE_HARDCODED(
		"show_location_string", "",
		"Replacement string piped into sprintf, "
		"so you can do different messages like this: ' at the %s' or ' (near %s)'"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees", "1",
		"Print information about sprees in death/kill messages"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees_center", "1",
		"Show spree information in MSG_CENTER messages... "
		"0 = off, 1 = target (but only for first victim) and attacker"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees_center_specialonly", "1",
		"Don't show spree information in MSG_CENTER messages if it isn't an achievement"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees_info", "3",
		"Show spree information in MSG_INFO messages... "
		"0 = off, 1 = target only, 2 = attacker only, 3 = target and attacker"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees_info_newline", "1",
		"Show attacker spree information for MSG_INFO messages on a separate line than the death notification itself"
	);

	NOTIF_WRITE_HARDCODED(
		"show_sprees_info_specialonly", "1",
		"Don't show attacker spree information in MSG_INFO messages if it isn't an achievement"
	);

	NOTIF_WRITE(sprintf(
		(
			"\n// Notification counts (total = %d): "
			"MSG_ANNCE = %d, MSG_INFO = %d, MSG_CENTER = %d, MSG_MULTI = %d, MSG_CHOICE = %d\n"
		),
		(
			NOTIF_ANNCE_COUNT +
			NOTIF_INFO_COUNT +
			NOTIF_CENTER_COUNT +
			NOTIF_MULTI_COUNT +
			NOTIF_CHOICE_COUNT
		),
		NOTIF_ANNCE_COUNT,
		NOTIF_INFO_COUNT,
		NOTIF_CENTER_COUNT,
		NOTIF_MULTI_COUNT,
		NOTIF_CHOICE_COUNT
	));
	#undef NOTIF_WRITE_HARDCODED
	#undef NOTIF_WRITE_ENTITY
	#undef NOTIF_WRITE
}


// ===============================
//  Frontend Notification Pushing
// ===============================

string Local_Notification_sprintf(
	string input, string args,
	string s1, string s2, string s3, string s4,
	int f1, float f2, float f3, float f4)
{
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Local_Notification_sprintf('%s^7', '%s', %s, %s);\n",
		MakeConsoleSafe(input),
		args,
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)
	));
	#endif

	for (int sel_num = 0; sel_num < NOTIF_MAX_ARGS; ++sel_num) { arg_slot[sel_num] = ""; }

	for (int sel_num = 0; (args != ""); )
	{
		string selected = car(args); args = cdr(args);
		NOTIF_HIT_MAX(NOTIF_MAX_ARGS, "Local_Notification_sprintf");
		string tmp_s; // used by NOTIF_ARGUMENT_LIST
		switch (strtolower(selected))
		{
			#define ARG_CASE_ARG_CS_SV_HA(selected, result) case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE_ARG_CS_SV_DC(selected, result) case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE_ARG_CS_SV(selected, result)    case selected: { arg_slot[sel_num++] = result; break; }
#ifdef CSQC
			#define ARG_CASE_ARG_CS(selected, result)       case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE_ARG_SV(selected, result)
#else
			#define ARG_CASE_ARG_CS(selected, result)
			#define ARG_CASE_ARG_SV(selected, result)       case selected: { arg_slot[sel_num++] = result; break; }
#endif
			#define ARG_CASE_ARG_DC(selected, result)
			#define ARG_CASE(prog, selected, result)        ARG_CASE_##prog(selected, result)
			NOTIF_ARGUMENT_LIST
			#undef ARG_CASE
			#undef ARG_CASE_ARG_DC
			#undef ARG_CASE_ARG_SV
			#undef ARG_CASE_ARG_CS
			#undef ARG_CASE_ARG_CS_SV
			#undef ARG_CASE_ARG_CS_SV_DC
			#undef ARG_CASE_ARG_CS_SV_HA
			default: NOTIF_HIT_UNKNOWN(NOTIF_MAX_ARGS, "Local_Notification_sprintf")
		}
	}
	return sprintf(
		strcat(input, "\n"),
		arg_slot[0],
		arg_slot[1],
		arg_slot[2],
		arg_slot[3],
		arg_slot[4],
		arg_slot[5],
		arg_slot[6]
	);
}

#ifdef CSQC
void Local_Notification_sound(
	int soundchannel, string soundfile,
	float soundvolume, float soundposition)
{
	if ((soundfile != prev_soundfile) || (time >= (prev_soundtime + autocvar_cl_announcer_antispam)))
	{
		#ifdef NOTIFICATIONS_DEBUG
		Debug_Notification(sprintf(
			"Local_Notification_sound(%f, '%s', %f, %f);\n",
			soundchannel,
			sprintf(
				"announcer/%s/%s.wav",
				AnnouncerOption(),
				soundfile
			),
			soundvolume,
			soundposition
		));
		#endif

		_sound(
			NULL,
			soundchannel,
			sprintf(
				"announcer/%s/%s.wav",
				AnnouncerOption(),
				soundfile
			),
			soundvolume,
			soundposition
		);

		if (prev_soundfile) strunzone(prev_soundfile);
		prev_soundfile = strzone(soundfile);
		prev_soundtime = time;
	}
	else
	{
		#ifdef NOTIFICATIONS_DEBUG
		Debug_Notification(sprintf(
			(
				"Local_Notification_sound(world, %f, '%s', %f, %f) "
				"^1BLOCKED BY ANTISPAM:^7 prevsnd: '%s', timediff: %f, limit: %f\n"
			 ),
			soundchannel,
			sprintf(
				"announcer/%s/%s.wav",
				AnnouncerOption(),
				soundfile
			),
			soundvolume,
			soundposition,
			prev_soundfile,
			(time - prev_soundtime),
			autocvar_cl_announcer_antispam
		));
		#endif
	}
}

void Local_Notification_HUD_Notify_Push(
	string icon, string hudargs,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	arg_slot[0] = ""; arg_slot[1] = "";

	for (int sel_num = 0; (hudargs != ""); )
	{
		string selected = car(hudargs); hudargs = cdr(hudargs);
		NOTIF_HIT_MAX(NOTIF_MAX_HUDARGS, "Local_Notification_HUD_Notify_Push");
		switch (strtolower(selected))
		{
			#define ARG_CASE_ARG_CS_SV_HA(selected, result) case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE_ARG_CS_SV_DC(selected, result)
			#define ARG_CASE_ARG_CS_SV(selected, result)
			#define ARG_CASE_ARG_CS(selected, result)
			#define ARG_CASE_ARG_SV(selected, result)
			#define ARG_CASE_ARG_DC(selected, result)
			#define ARG_CASE(prog, selected, result)        ARG_CASE_##prog(selected, result)
			NOTIF_ARGUMENT_LIST
			#undef ARG_CASE
			#undef ARG_CASE_ARG_DC
			#undef ARG_CASE_ARG_SV
			#undef ARG_CASE_ARG_CS
			#undef ARG_CASE_ARG_CS_SV
			#undef ARG_CASE_ARG_CS_SV_DC
			#undef ARG_CASE_ARG_CS_SV_HA
			default: NOTIF_HIT_UNKNOWN(NOTIF_MAX_HUDARGS, "Local_Notification_HUD_Notify_Push")
		}
	}
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Local_Notification_HUD_Notify_Push('%s^7', '%s', %s, %s, %s);\n",
		icon,
		hudargs,
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4),
		MakeConsoleSafe(sprintf("'%s^7', '%s^7'", stof(arg_slot[0]), stof(arg_slot[1])))
	));
	#endif
	HUD_Notify_Push(icon, arg_slot[0], arg_slot[1]);
}

void Local_Notification_centerprint_generic(
	string input, string durcnt,
	int cpid, float f1, float f2)
{
	arg_slot[0] = ""; arg_slot[1] = "";

	for (int sel_num = 0; (durcnt != ""); )
	{
		string selected = car(durcnt); durcnt = cdr(durcnt);
		NOTIF_HIT_MAX(NOTIF_MAX_DURCNT, "Local_Notification_centerprint_generic");
		switch (strtolower(selected))
		{
			#define ARG_CASE_ARG_CS_SV_HA(selected, result)
			#define ARG_CASE_ARG_CS_SV_DC(selected, result) case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE_ARG_CS_SV(selected, result)
			#define ARG_CASE_ARG_CS(selected, result)
			#define ARG_CASE_ARG_SV(selected, result)
			#define ARG_CASE_ARG_DC(selected, result)       case selected: { arg_slot[sel_num++] = result; break; }
			#define ARG_CASE(prog, selected, result)        ARG_CASE_##prog(selected,result)
			NOTIF_ARGUMENT_LIST
			#undef ARG_CASE
			#undef ARG_CASE_ARG_DC
			#undef ARG_CASE_ARG_SV
			#undef ARG_CASE_ARG_CS
			#undef ARG_CASE_ARG_CS_SV
			#undef ARG_CASE_ARG_CS_SV_DC
			#undef ARG_CASE_ARG_CS_SV_HA
			default:
			{
				if (/* wtf */ ftos(stof(selected)) != "") { arg_slot[sel_num++] = selected; }
				else { NOTIF_HIT_UNKNOWN(NOTIF_MAX_DURCNT, "Local_Notification_centerprint_generic") }
				break;
			}
		}
	}
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Local_Notification_centerprint_generic('%s^7', '%s', %d, %d, %d, %d);\n",
		MakeConsoleSafe(input),
		durcnt,
		f1, f2,
		stof(arg_slot[0]),
		stof(arg_slot[1])
	));
	#endif
	centerprint_generic(cpid, input, stof(arg_slot[0]), stof(arg_slot[1]));
}
#endif

void Local_Notification(MSG net_type, Notification net_name, ...count)
{
	// check if this should be aborted
	if (net_name == NOTIF_ABORT)
	{
		#ifdef NOTIFICATIONS_DEBUG
		Debug_Notification(sprintf(
			"Local_Notification(%s, %s, ...);\n",
			Get_Notif_TypeName(net_type),
			"NOTIF_ABORT"
		));
		#endif
		return;
	}

	// retreive entity of this notification
	entity notif = net_name;
	if (!notif)
	{
		#ifdef NOTIFICATIONS_DEBUG
		Debug_Notification(sprintf(
			"Local_Notification(%s, %d, ...);\n",
			Get_Notif_TypeName(net_type),
			net_name
		));
		#endif
		backtrace(sprintf("Incorrect usage of Local_Notification: %s\n", "Null notification"));
		return;
	}

	// check if the notification is enabled
	if (!notif.nent_enabled)
	{
		#ifdef NOTIFICATIONS_DEBUG
		Debug_Notification(sprintf(
			"Local_Notification(%s, %s, ...): Entity was disabled...\n",
			Get_Notif_TypeName(net_type),
			notif.nent_name
		));
		#endif
		return;
	}

	string s1 = ((notif.nent_stringcount > 0) ? ...(0, string) : "");
	string s2 = ((notif.nent_stringcount > 1) ? ...(1, string) : "");
	string s3 = ((notif.nent_stringcount > 2) ? ...(2, string) : "");
	string s4 = ((notif.nent_stringcount > 3) ? ...(3, string) : "");
	float f1 =  ((notif.nent_floatcount  > 0) ? ...((notif.nent_stringcount + 0), float) : 0);
	float f2 =  ((notif.nent_floatcount  > 1) ? ...((notif.nent_stringcount + 1), float) : 0);
	float f3 =  ((notif.nent_floatcount  > 2) ? ...((notif.nent_stringcount + 2), float) : 0);
	float f4 =  ((notif.nent_floatcount  > 3) ? ...((notif.nent_stringcount + 3), float) : 0);

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Local_Notification(%s, %s, %s, %s);\n",
		Get_Notif_TypeName(net_type),
		notif.nent_name,
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)
	));
	#endif

	if ((notif.nent_stringcount + notif.nent_floatcount) != count)
	{
		backtrace(sprintf(
			(
				"Arguments mismatch for Local_Notification(%s, %s, ...)! "
				"stringcount(%d) + floatcount(%d) != count(%d)\n"
				"Check the definition and function call for accuracy...?\n"
			),
			Get_Notif_TypeName(net_type),
			notif.nent_name,
			notif.nent_stringcount,
			notif.nent_floatcount,
			count
		));
		return;
	}

	switch (net_type)
	{
		case MSG_ANNCE:
		{
			#ifdef CSQC
			Local_Notification_sound(
				notif.nent_channel,
				notif.nent_snd,
				notif.nent_vol,
				notif.nent_position
			);
			#else
			backtrace("MSG_ANNCE on server?... Please notify Samual immediately!\n");
			#endif
			break;
		}

		case MSG_INFO:
		{
			print(
				Local_Notification_sprintf(
					notif.nent_string,
					notif.nent_args,
					s1, s2, s3, s4,
					f1, f2, f3, f4)
			);
			#ifdef CSQC
			if (notif.nent_icon != "")
			{
				if (notif.nent_iconargs != "")
				{
					string s = Local_Notification_sprintf(
						notif.nent_icon,notif.nent_iconargs,
						s1, s2, s3, s4, f1, f2, f3, f4);
					// remove the trailing newline
					notif.nent_icon = strzone(substring(s, 0, -1));
				}
				Local_Notification_HUD_Notify_Push(
					notif.nent_icon,
					notif.nent_hudargs,
					s1, s2, s3, s4,
					f1, f2, f3, f4);
			}
			#endif
			break;
		}

		#ifdef CSQC
		case MSG_CENTER:
		{
			Local_Notification_centerprint_generic(
				Local_Notification_sprintf(
					notif.nent_string,
					notif.nent_args,
					s1, s2, s3, s4,
					f1, f2, f3, f4),
				notif.nent_durcnt,
				notif.nent_cpid,
				f1, f2);
			break;
		}
		#endif

		case MSG_MULTI:
		{
			if (notif.nent_msginfo && notif.nent_msginfo.nent_enabled)
			{
				Local_Notification_WOVA(
					MSG_INFO,
					notif.nent_msginfo,
					notif.nent_msginfo.nent_stringcount,
					notif.nent_msginfo.nent_floatcount,
					s1, s2, s3, s4,
					f1, f2, f3, f4);
			}
			#ifdef CSQC
			if (notif.nent_msgannce && notif.nent_msgannce.nent_enabled)
			{
				Local_Notification_WOVA(
					MSG_ANNCE,
					notif.nent_msgannce,
					0, 0,
					"", "", "", "",
					0, 0, 0, 0);
			}
			if (notif.nent_msgcenter && notif.nent_msgcenter.nent_enabled)
			{
				Local_Notification_WOVA(
					MSG_CENTER,
					notif.nent_msgcenter,
					notif.nent_msgcenter.nent_stringcount,
					notif.nent_msgcenter.nent_floatcount,
					s1, s2, s3, s4,
					f1, f2, f3, f4);
			}
			#endif
			break;
		}

		case MSG_CHOICE:
		{
			entity found_choice = notif.nent_optiona;
			if (notif.nent_challow_var && (warmup_stage || (notif.nent_challow_var == 2))) {
				switch (cvar(sprintf("notification_%s", notif.nent_name)))
				{
					case 1: break;
					case 2: found_choice = notif.nent_optionb; break;
					default: return; // not enabled anyway
				}
			}

			Local_Notification_WOVA(
				found_choice.nent_type,
				found_choice,
				found_choice.nent_stringcount,
				found_choice.nent_floatcount,
				s1, s2, s3, s4,
				f1, f2, f3, f4);
		}
	}
}

// WOVA = Without Variable Arguments
void Local_Notification_WOVA(
	MSG net_type, Notification net_name,
	float stringcount, float floatcount,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	#define VARITEM(stringc, floatc, args) \
		if ((stringcount == stringc) && (floatcount == floatc)) \
		{ Local_Notification(net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM
	Local_Notification(net_type, net_name); // some notifications don't have any arguments at all
}


// =========================
//  Notification Networking
// =========================

/** networked as a linked entity to give newly connecting clients some notification context */
REGISTER_NET_LINKED(ENT_CLIENT_NOTIFICATION)

#ifdef CSQC
NET_HANDLE(ENT_CLIENT_NOTIFICATION, bool is_new)
{
	make_pure(this);
	MSG net_type = ENUMCAST(MSG, ReadByte());
	int net_name = ReadShort();
	Notification notif = Get_Notif_Ent(net_type, net_name);

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Read_Notification(%d) at %f: net_type = %s, net_name = %s (%d)\n",
		is_new,
		time,
		Get_Notif_TypeName(net_type),
		notif.registered_id,
		net_name
	));
	#endif

	if (net_type == MSG_CENTER_CPID)
	{
		// killing
		return = true;
		if (!is_new) return;
		if (net_name == NO_CPID) {
			backtrace(sprintf(
				"Read_Notification(%d) at %f: ^1TRIED TO KILL NO_CPID CENTERPRINT!\n",
				is_new,
				time
			));
			return;
		}
		if (net_name == 0) {
			// kill all
			reset_centerprint_messages();
			return;
		}
		// kill one
		centerprint_generic(net_name, "", 0, 0);
		return;
	}
	else
	{
		// creating
		if (!notif) {
			backtrace("Read_Notification: Could not find notification entity!\n");
			return false;
		}

		string s1 = ((notif.nent_stringcount > 0) ? ReadString() : "");
		string s2 = ((notif.nent_stringcount > 1) ? ReadString() : "");
		string s3 = ((notif.nent_stringcount > 2) ? ReadString() : "");
		string s4 = ((notif.nent_stringcount > 3) ? ReadString() : "");
		float f1 = ((notif.nent_floatcount > 0) ? ReadLong() : 0);
		float f2 = ((notif.nent_floatcount > 1) ? ReadLong() : 0);
		float f3 = ((notif.nent_floatcount > 2) ? ReadLong() : 0);
		float f4 = ((notif.nent_floatcount > 3) ? ReadLong() : 0);

		return = true;

		if (!is_new) return;
		Local_Notification_WOVA(
			net_type, notif,
			notif.nent_stringcount,
			notif.nent_floatcount,
			s1, s2, s3, s4,
			f1, f2, f3, f4);
		return;
	}
}
#endif

#ifdef SVQC
void Net_Notification_Remove()
{
	SELFPARAM();
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Net_Notification_Remove() at %f: %s '%s - %s' notification\n",
		time,
		((this.nent_net_name == -1) ? "Killed" : "Removed"),
		Get_Notif_TypeName(this.nent_net_type),
		this.owner.nent_name
	));
	#endif
	for (int i = 0; i < this.nent_stringcount; ++i) { if (this.nent_strings[i]) strunzone(this.nent_strings[i]); }
	remove(this);
}

bool Net_Write_Notification(entity this, entity client, int sf)
{
	if (!Notification_ShouldSend(this.nent_broadcast, client, this.nent_client)) return false;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_NOTIFICATION);
	WriteByte(MSG_ENTITY, ORDINAL(this.nent_net_type));
	WriteShort(MSG_ENTITY, this.nent_net_name);
	for (int i = 0; i < this.nent_stringcount; ++i) { WriteString(MSG_ENTITY, this.nent_strings[i]); }
	for (int i = 0; i < this.nent_floatcount; ++i) { WriteLong(MSG_ENTITY, this.nent_floats[i]); }
	return true;
}

void Kill_Notification(
	NOTIF broadcast, entity client,
	/** primary group */
	MSG net_type,
	/** secondary group */
	float net_name)
{
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Kill_Notification(%s, '%s', %s, %d);\n",
		Get_Notif_BroadcastName(broadcast),
		client.netname,
		(net_type ? Get_Notif_TypeName(net_type) : "0"),
		net_name
	));
	#endif

	string checkargs = Notification_CheckArgs(broadcast, client, NO_MSG);
	if (checkargs != "") { backtrace(sprintf("Incorrect usage of Kill_Notification: %s\n", checkargs)); return; }

	entity net_notif;
	float killed_cpid = NO_CPID;

	switch (net_type)
	{
		case MSG_Null:
		{
			killed_cpid = 0; // kill ALL centerprints
			break;
		}

		case MSG_CENTER:
		{
			if(net_name)
			{
				entity notif = Get_Notif_Ent(net_type, net_name);
				if (!notif) { backtrace("Kill_Notification: Could not find notification entity!\n"); return; }

				if(notif.nent_cpid)
					killed_cpid = notif.nent_cpid;
				else
					killed_cpid = NO_CPID;
			}
			else
			{
				killed_cpid = 0; // kill ALL centerprints
			}
			break;
		}

		case MSG_CENTER_CPID:
		{
			killed_cpid = net_name;
			break;
		}
	}

	if (killed_cpid != NO_CPID)
	{
		net_notif = new(net_kill_notification);
		make_pure(net_notif);
		net_notif.nent_broadcast = broadcast;
		net_notif.nent_client = client;
		net_notif.nent_net_type = MSG_CENTER_CPID;
		net_notif.nent_net_name = killed_cpid;
		Net_LinkEntity(net_notif, false, autocvar_notification_lifetime_runtime, Net_Write_Notification);
	}

	FOREACH_ENTITY_CLASS("net_notification", true,
	{
		if (net_type)
		{
			if ((killed_cpid != NO_CPID) && (it.nent_net_type == MSG_CENTER))
			{
				if(it.owner.nent_cpid == killed_cpid)
				{
					it.nent_net_name = -1;
					it.nextthink = time;
				}
				else { continue; } // we ARE looking for a specific CPID, don't kill everything else too
			}
			else if (it.nent_net_type == net_type)
			{
				if (net_name)
				{
					if (it.nent_net_name == net_name) { it.nent_net_name = -1; it.nextthink = time; }
					else { continue; } // we ARE looking for a certain net_name, don't kill everything else too
				}
				else { it.nent_net_name = -1; it.nextthink = time; }
			}
			else { continue; } // we ARE looking for a certain net_type, don't kill everything else too
		}
		else { it.nent_net_name = -1; it.nextthink = time; }
	});
}

void Send_Notification(
	NOTIF broadcast, entity client,
	MSG net_type, Notification net_name,
	...count)
{
	entity notif = net_name;
	string parms = sprintf("%s, '%s', %s, %s",
		Get_Notif_BroadcastName(broadcast),
		client.classname,
		Get_Notif_TypeName(net_type),
		net_name.registered_id
	);
	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf("Send_Notification(%s, ...%d);\n", parms, count));
	#endif
	// check if this should be aborted
	if (net_name == NOTIF_ABORT) return;

	if (!notif)
	{
		LOG_WARNING("Send_Notification: Could not find notification entity!");
		return;
	}

	// check supplied broadcast, target, type, and name for errors
	string checkargs = Notification_CheckArgs(broadcast, client, net_name);
	if (checkargs != "")
	{
		LOG_WARNINGF("Incorrect usage of Send_Notification: %s", checkargs);
		return;
	}

	string s1 = ((0 < notif.nent_stringcount) ? ...(0, string) : "");
	string s2 = ((1 < notif.nent_stringcount) ? ...(1, string) : "");
	string s3 = ((2 < notif.nent_stringcount) ? ...(2, string) : "");
	string s4 = ((3 < notif.nent_stringcount) ? ...(3, string) : "");
	float f1 = ((0 < notif.nent_floatcount) ? ...((notif.nent_stringcount + 0), float) : 0);
	float f2 = ((1 < notif.nent_floatcount) ? ...((notif.nent_stringcount + 1), float) : 0);
	float f3 = ((2 < notif.nent_floatcount) ? ...((notif.nent_stringcount + 2), float) : 0);
	float f4 = ((3 < notif.nent_floatcount) ? ...((notif.nent_stringcount + 3), float) : 0);

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Send_Notification(%s, %s, %s);\n",
		parms,
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)
	));
	#endif

	if ((notif.nent_stringcount + notif.nent_floatcount) != count)
	{
		LOG_WARNINGF(
			"Argument mismatch for Send_Notification(%s, ...)! "
			"stringcount(%d) + floatcount(%d) != count(%d)\n"
			"Check the definition and function call for accuracy...?\n",
			parms,
			notif.nent_stringcount,
			notif.nent_floatcount,
			count
		);
		return;
	}

	if (
		server_is_dedicated
		&&
		(
			broadcast == NOTIF_ALL
			||
			broadcast == NOTIF_ALL_EXCEPT
		)
		&&
		!(
			net_type == MSG_ANNCE
			||
			net_type == MSG_CENTER
		)
	)
	{
		Local_Notification_WOVA(
			net_type, net_name,
			notif.nent_stringcount,
			notif.nent_floatcount,
			s1, s2, s3, s4,
			f1, f2, f3, f4);
	}

	if (net_type == MSG_CHOICE)
	{
		// THIS GETS TRICKY... now we have to cycle through each possible player (checking broadcast)
		// and then do an individual NOTIF_ONE_ONLY recursive call for each one depending on their option...
		// It's slow, but it's better than the alternatives:
		//   1. Constantly networking all info and letting client decide
		//   2. Manually handling each separate call on per-usage basis (See old CTF usage of verbose)
		entity found_choice;

		#define RECURSE_FROM_CHOICE(ent,action) MACRO_BEGIN { \
			if (notif.nent_challow_var && (warmup_stage || (notif.nent_challow_var == 2))) { \
				switch (ent.msg_choice_choices[net_name.nent_choice_idx]) \
				{ \
					case 1: found_choice = notif.nent_optiona; break; \
					case 2: found_choice = notif.nent_optionb; break; \
					default: action; \
				} \
			} else { \
				found_choice = notif.nent_optiona; \
			} \
			Send_Notification_WOVA( \
				NOTIF_ONE_ONLY, \
				ent, \
				found_choice.nent_type, \
				found_choice, \
				found_choice.nent_stringcount, \
				found_choice.nent_floatcount, \
				s1, s2, s3, s4, \
				f1, f2, f3, f4); \
		} MACRO_END

		switch (broadcast)
		{
			case NOTIF_ONE_ONLY: // we can potentially save processing power with this broadcast method
			{
				if (IS_REAL_CLIENT(client)) {
					RECURSE_FROM_CHOICE(client, return);
				}
				break;
			}
			default:
			{
				FOREACH_CLIENT(IS_REAL_CLIENT(it) && Notification_ShouldSend(broadcast, it, client), {
					RECURSE_FROM_CHOICE(it, continue);
				});
				break;
			}
		}
	}
	else
	{
		entity net_notif = new(net_notification);
		make_pure(net_notif);
		net_notif.owner = notif;
		net_notif.nent_broadcast = broadcast;
		net_notif.nent_client = client;
		net_notif.nent_net_type = net_type;
		net_notif.nent_net_name = notif.m_id;
		net_notif.nent_stringcount = notif.nent_stringcount;
		net_notif.nent_floatcount = notif.nent_floatcount;

		for (int i = 0; i < net_notif.nent_stringcount; ++i) {
			net_notif.nent_strings[i] = strzone(...(i, string));
		}
		for (int i = 0; i < net_notif.nent_floatcount; ++i) {
			net_notif.nent_floats[i] = ...((net_notif.nent_stringcount + i), float);
		}

		net_notif.think = Net_Notification_Remove;
		net_notif.nextthink = (time > autocvar_notification_lifetime_mapload)
			? (time + autocvar_notification_lifetime_runtime)
			: autocvar_notification_lifetime_mapload;

		Net_LinkEntity(net_notif, false, 0, Net_Write_Notification);
	}
}

// WOVA = Without Variable Arguments
void Send_Notification_WOVA(
	NOTIF broadcast, entity client,
	MSG net_type, Notification net_name,
	float stringcount, float floatcount,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	#ifdef NOTIFICATIONS_DEBUG
	entity notif = net_name;
	Debug_Notification(sprintf(
		"Send_Notification_WOVA(%s, %d, %d, %s, %s);\n",
		sprintf(
			"%s, '%s', %s, %s",
			Get_Notif_BroadcastName(broadcast),
			client.classname,
			Get_Notif_TypeName(net_type),
			notif.nent_name
		),
		stringcount,
		floatcount,
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)
	));
	#endif

	#define VARITEM(stringc, floatc, args) \
		if ((stringcount == stringc) && (floatcount == floatc)) \
		{ Send_Notification(broadcast, client, net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM
	Send_Notification(broadcast, client, net_type, net_name); // some notifications don't have any arguments at all
}

// WOCOVA = Without Counts Or Variable Arguments
void Send_Notification_WOCOVA(
	NOTIF broadcast, entity client,
	MSG net_type, Notification net_name,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	entity notif = net_name;

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(sprintf(
		"Send_Notification_WOCOVA(%s, %s, %s);\n",
		sprintf(
			"%s, '%s', %s, %s",
			Get_Notif_BroadcastName(broadcast),
			client.classname,
			Get_Notif_TypeName(net_type),
			notif.nent_name
		),
		MakeConsoleSafe(sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4)),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)
	));
	#endif

	#define VARITEM(stringc, floatc, args) \
		if ((notif.nent_stringcount == stringc) && (notif.nent_floatcount == floatc)) \
		{ Send_Notification(broadcast, client, net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM
	Send_Notification(broadcast, client, net_type, net_name); // some notifications don't have any arguments at all
}
#endif // ifdef SVQC
