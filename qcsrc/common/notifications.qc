// ================================================
//  Unified notification system, written by Samual
//  Last updated: December, 2012
// ================================================

// ======================
//  Supporting Functions
// ======================

// team code replace
string TCR(string input, string teamcolor, string teamtext) // TODO: MOVE TO UTIL.QC
{
	input = strreplace("^TC", teamcolor, input);
	input = strreplace("^TT", teamtext, input);
	return input;
}

// color code replace, place inside of sprintf and parse the string
string CCR(string input) // TODO: MOVE TO UTIL.QC
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

#ifndef MENUQC
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

float notif_checkstring(string input)
{
	if not(input == "") { return TRUE; }
	else { return FALSE; }
}

// get the actual name of a notification and return it as a string
string Get_Field_Value(float field, float net_type, float net_name)
{
	string output = "";
	
	#define GET_FIELD_VALUE_OUTPUT(field,name,strnum,flnum) \
		switch(field) { \
			case F_NAME: { output = VAR_TO_TEXT(name); break; } \
			case F_STRNUM: { output = ftos(strnum); break; } \
			case F_FLNUM: { output = ftos(flnum); break; } }
	
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
#endif // ifndef MENUQC


// ===============================
//  Frontend Notification Pushing
// ===============================

void Dump_Notifications(float fh, float alsoprint)
{
	float MSG_INFO_NOTIFS = 0, MSG_CENTER_NOTIFS = 0, MSG_WEAPON_NOTIFS = 0, MSG_DEATH_NOTIFS = 0;
	string notif_msg;

	#define NOTIF_WRITE(type,name,text) notif_msg = sprintf("seta %s 1 // %s - %s\n", name, type, strreplace("\n", "\\n", text)); fputs(fh, notif_msg); if(alsoprint) { print(strreplace("^", "^^", notif_msg)); }
	#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) { ++MSG_INFO_NOTIFS; NOTIF_WRITE("MSG_INFO", VAR_TO_TEXT(name), normal) }
	#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) { ++MSG_CENTER_NOTIFS; NOTIF_WRITE("MSG_CENTER", VAR_TO_TEXT(name), normal) }
	#define MSG_WEAPON_NOTIF(name,infoname,centername) { ++MSG_WEAPON_NOTIFS; NOTIF_WRITE("MSG_WEAPON", VAR_TO_TEXT(name),sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))) }
	#define MSG_DEATH_NOTIF(name,infoname,centername) { ++MSG_DEATH_NOTIFS; NOTIF_WRITE("MSG_DEATH", VAR_TO_TEXT(name), sprintf("infoname: %s, centername: %s", VAR_TO_TEXT(infoname), VAR_TO_TEXT(centername))) }
	MSG_INFO_NOTIFICATIONS
	MSG_CENTER_NOTIFICATIONS
	MSG_WEAPON_NOTIFICATIONS
	MSG_DEATH_NOTIFICATIONS
	#undef NOTIF_WRITE
	#undef MSG_INFO_NOTIF
	#undef MSG_CENTER_NOTIF
	#undef MSG_WEAPON_NOTIF
	#undef MSG_DEATH_NOTIF
	
	print(sprintf("Notification counts: MSG_INFO = %d, MSG_CENTER = %d, MSG_WEAPON = %d, MSG_DEATH = %d\n", MSG_INFO_NOTIFS, MSG_CENTER_NOTIFS, MSG_WEAPON_NOTIFS, MSG_DEATH_NOTIFS));
	return;
}

#ifndef MENUQC
#ifdef CSQC
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

void backtrace(string msg) // TODO: MOVE TO UTIL.QC
{
    float dev, war;
    dev = cvar("developer");
    war = cvar("prvm_backtraceforwarnings");
    cvar_set("developer", "1");
    cvar_set("prvm_backtraceforwarnings", "1");
    print("\n");
    print("--- CUT HERE ---\nWARNING: ");
    print(msg);
    print("\n");
    remove(world); // isn't there any better way to cause a backtrace?
    print("\n--- CUT UNTIL HERE ---\n");
    cvar_set("developer", ftos(dev));
    cvar_set("prvm_backtraceforwarnings", ftos(war));
}
#endif // ifdef CSQC

void Local_Notification(float net_type, float net_name, ...count)
{
	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));

	string s1 = ((0 < stringcount) ? ...(0, string) : NO_STR_ARG);
	string s2 = ((1 < stringcount) ? ...(1, string) : NO_STR_ARG);
	string s3 = ((2 < stringcount) ? ...(2, string) : NO_STR_ARG);
	string s4 = ((3 < stringcount) ? ...(3, string) : NO_STR_ARG);
	float f1 = ((stringcount < count) ? ...(stringcount, float) : NO_FL_ARG);
	float f2 = (((stringcount + 1) < count) ? ...((stringcount + 1), float) : NO_FL_ARG);
	float f3 = (((stringcount + 2) < count) ? ...((stringcount + 2), float) : NO_FL_ARG);
	float f4 = (((stringcount + 3) < count) ? ...((stringcount + 3), float) : NO_FL_ARG);
	
	dprint("Local_Notification(", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", s1, ", ", s2, ", ", s3, ", ", s4, ", "), strcat(ftos(f1), strcat(", ", ftos(f2), ", ", ftos(f3), ", ", ftos(f4), ");\n")));
	dprint("  ^--: stringcount: ", ftos(stringcount), ", floatcount: ", ftos(floatcount), ".\n");

	if((stringcount + floatcount) > count) { backtrace(strcat("Not enough arguments for Local_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), ")"), " > count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }
	else if((stringcount + floatcount) < count) { backtrace(strcat("Too many arguments for Local_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), ")"), " < count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }

	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					if(notif_checkstring(normal)) { print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); } \
					#ifdef CSQC \
						if(notif_checkstring(icon)) { HUD_Notify_Push(icon, hudargs); } \
					#endif \
				} }
			MSG_INFO_NOTIFICATIONS
			#undef MSG_INFO_NOTIF
			break;
		}
		#ifdef CSQC
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
		#endif
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,infoname,centername) \
				{ NOTIF_MATCH(name, net_name) CHECK_AUTOCVAR(name) \
				{ \
					#if infoname != NO_MSG \
						Local_Notification_Without_VarArgs(MSG_INFO, infoname, \
							stof(Get_Field_Value(F_STRNUM, MSG_INFO, infoname)), \
							stof(Get_Field_Value(F_FLNUM, MSG_INFO, infoname)), \
							s1, s2, s3, s4, f1, f2, f3, f4); \
					#endif \
					#ifdef CSQC \
						#if centername != NO_MSG \
							Local_Notification_Without_VarArgs(MSG_CENTER, centername, \
								stof(Get_Field_Value(F_STRNUM, MSG_CENTER, centername)), \
								stof(Get_Field_Value(F_FLNUM, MSG_CENTER, centername)), \
								s1, s2, s3, s4, f1, f2, f3, f4); \
						#endif \
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
						Local_Notification_Without_VarArgs(MSG_INFO, infoname, \
							stof(Get_Field_Value(F_STRNUM, MSG_INFO, infoname)), \
							stof(Get_Field_Value(F_FLNUM, MSG_INFO, infoname)), \
							s1, s2, s3, s4, f1, f2, f3, f4); \
					#endif \
					#ifdef CSQC \
						#if centername != NO_MSG \
							Local_Notification_Without_VarArgs(MSG_CENTER, centername, \
								stof(Get_Field_Value(F_STRNUM, MSG_CENTER, centername)), \
								stof(Get_Field_Value(F_FLNUM, MSG_CENTER, centername)), \
								s1, s2, s3, s4, f1, f2, f3, f4); \
						#endif \
					#endif \
				} }
			MSG_DEATH_NOTIFICATIONS
			#undef MSG_DEATH_NOTIF
			break;
		}
	}
}

void Local_Notification_Without_VarArgs(float net_type, float net_name, float stringcount, float floatcount, string s1, string s2, string s3, string s4, float f1, float f2, float f3, float f4)
{
	#define VARITEM(stringc,floatc,args) if((stringcount == stringc) && (floatcount == floatc)) { Local_Notification(net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM

	Local_Notification(net_type, net_name); // some notifications don't have any arguments at all
}


// =========================
//  Notification Networking
// =========================

#define NOTIF_ONE 1
#define NOTIF_ONE_SPECTATABLE 2
#define NOTIF_TEAM 3
#define NOTIF_TEAM_EXCEPT 4
#define NOTIF_ANY 5
#define NOTIF_ANY_EXCEPT 6

.float nent_broadcast;
.entity nent_client;
.float nent_net_type;
.float nent_net_name;
.string nent_strings[4];
.float nent_floats[4];

#ifdef CSQC
void Read_Notification(float is_new)
{
	float net_type = ReadByte();
	float net_name = ReadShort();

	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));

	string s1 = ((stringcount >= 1) ? ReadString() : NO_STR_ARG);
	string s2 = ((stringcount >= 2) ? ReadString() : NO_STR_ARG);
	string s3 = ((stringcount >= 3) ? ReadString() : NO_STR_ARG);
	string s4 = ((stringcount == 4) ? ReadString() : NO_STR_ARG);
	float f1 = ((floatcount >= 1) ? ReadLong() : NO_FL_ARG);
	float f2 = ((floatcount >= 2) ? ReadLong() : NO_FL_ARG);
	float f3 = ((floatcount >= 3) ? ReadLong() : NO_FL_ARG);
	float f4 = ((floatcount == 4) ? ReadLong() : NO_FL_ARG);

	if(is_new) { Local_Notification_Without_VarArgs(net_type, net_name, stringcount, floatcount, s1, s2, s3, s4, f1, f2, f3, f4); }
	else { print("received old notification? net_name = ", ftos(net_name), ".\n"); }
}
#endif

#ifdef SVQC
float Write_Notification(entity client, float sf)
{
	float i, send;
	
	switch(self.nent_broadcast)
	{
		case NOTIF_ONE: { if(client == self.nent_client) { send = TRUE; } break; }
		case NOTIF_ONE_SPECTATABLE: { if((client == self.nent_client) || (client.classname == STR_SPECTATOR && client.enemy == self.nent_client)) { send = TRUE; } break; }
		case NOTIF_TEAM: { if(client.team == self.nent_client.team) { send = TRUE; } break; }
		case NOTIF_TEAM_EXCEPT: { if((client != self.nent_client) && (client.team == self.nent_client.team)) { send = TRUE; } break; }
		case NOTIF_ANY: { send = TRUE; break; }
		case NOTIF_ANY_EXCEPT: { if(client != self.nent_client) { send = TRUE; } break; }
		default: { send = FALSE; break; }
	}

	if(send)
	{
		float stringcount = stof(Get_Field_Value(F_STRNUM, self.nent_net_type, self.nent_net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, self.nent_net_type, self.nent_net_name));
		
		WriteByte(MSG_ENTITY, ENT_CLIENT_NOTIFICATION);
		WriteByte(MSG_ENTITY, self.nent_net_type);
		WriteShort(MSG_ENTITY, self.nent_net_name);
		for(i = 0; i < stringcount; ++i) { WriteString(MSG_ENTITY, self.nent_strings[i]); } 
		for(i = 0; i < floatcount; ++i) { WriteLong(MSG_ENTITY, self.nent_floats[stringcount + i]); }
	}

	return send; 
}

void Send_Notification(float broadcast, entity client, float net_type, float net_name, ...count)
{
	if((broadcast == MSG_BROADCAST || broadcast == MSG_ONE) && net_type && net_name)
	{
		float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
		float i, tmp_f;
		string tmp_s;

		dprint("Send_Notification(", ftos(broadcast), ", ", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", ftos(count), ");\n"));
		dprint("  ^--: stringcount: ", ftos(stringcount), ", floatcount: ", ftos(floatcount), ".\n");

		if((stringcount + floatcount) > count) { backtrace(strcat("Not enough arguments for Send_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), "),"), " > count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }
		else if((stringcount + floatcount) < count) { backtrace(strcat("Too many arguments for Send_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), "),"), " < count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }

		entity notif = spawn();
		notif.nent_broadcast = broadcast;
		notif.nent_client = client;
		notif.nent_net_type = net_type;
		notif.nent_net_name = net_name;
		for(i = 0; i < stringcount; ++i) { tmp_s = ...(i, string); notif.nent_strings[i] = tmp_s; dprint("WriteString(...(", ftos(i), ", string)); - ", tmp_s, "\n"); } 
		for(i = 0; i < floatcount; ++i) { tmp_f = ...((stringcount + i), float); notif.nent_floats[i] = tmp_f; dprint("WriteLong(...(", ftos((stringcount + i)), ", float)); - ", ftos(tmp_f), "\n"); }

		Net_LinkEntity(notif, FALSE, 0.5, Write_Notification);

		if(!server_is_local)
		{
			Local_Notification_Without_VarArgs(net_type, net_name, stringcount, floatcount, IFSTR(0), IFSTR(1), IFSTR(2), IFSTR(3), IFFL(0), IFFL(1), IFFL(2), IFFL(3));
		}
	}
	else { backtrace("Incorrect usage of Send_Notification!\n"); }
}

void Send_Notification_Without_VarArgs(float broadcast, entity client, float net_type, float net_name, float stringcount, float floatcount, string s1, string s2, string s3, string s4, float f1, float f2, float f3, float f4)
{		
	#define VARITEM(stringc,floatc,args) if((stringcount == stringc) && (floatcount == floatc)) { Send_Notification(broadcast, client, net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM

	Send_Notification(broadcast, client, net_type, net_name); // some notifications don't have any arguments at all
}

void Send_Notification_Legacy_Wrapper(float broadcast, entity client, float net_type, float net_name, string s1, string s2, float f1, float f2, float f3)
{
	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
	Send_Notification_Without_VarArgs(broadcast, client, net_type, net_name, stringcount, floatcount, s1, s2, NO_STR_ARG, NO_STR_ARG, f1, f2, f3, NO_FL_ARG);
}

/*void Send_Notification_ToTeam(float targetteam, entity except, float net_type, float net_name, ...count)
{
	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
	Send_Notification_Without_VarArgs(NOTIF_TEAM, tmp_entity, net_type, net_name, stringcount, floatcount, IFSTR(0), IFSTR(1), IFSTR(2), IFSTR(3), IFFL(0), IFFL(1), IFFL(2), IFFL(3));
}

// WARNING: use this ONLY if you need exceptions or want to exclude spectators, otherwise use Send_Notification(world, MSG_BROADCAST, ...)
void Send_Notification_ToAll(entity except, float spectators, float net_type, float net_name, ...count)
{
	float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
	float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
	
	entity tmp_entity;
	FOR_EACH_REALCLIENT(tmp_entity)
	{
		if((tmp_entity.classname == STR_PLAYER) || spectators)
		if(tmp_entity != except)
		{
			Send_Notification_Without_VarArgs(tmp_entity, MSG_ONE, net_type, net_name, stringcount, floatcount, IFSTR(0), IFSTR(1), IFSTR(2), IFSTR(3), IFFL(0), IFFL(1), IFFL(2), IFFL(3));
		}
	}
}*/


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
#endif // ifdef SVQC
#endif // ifndef MENUQC
