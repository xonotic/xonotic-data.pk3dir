// ================================================
//  Unified notification system, written by Samual
//  Last updated: December, 2012
// ================================================

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
void Notification_Remove()
{
	float i;
	for(i = 0; i < 4; ++i) { if(self.nent_strings[i]) { strunzone(self.nent_strings[i]); } }
	remove(self);
}

float Write_Notification(entity client, float sf)
{
	float i, send = FALSE;
	
	switch(self.nent_broadcast)
	{
		case NOTIF_ONE: { if((client == self.nent_client) || (client.classname == STR_SPECTATOR && client.enemy == self.nent_client)) { send = TRUE; } break; }
		case NOTIF_ONE_ONLY: { if(client == self.nent_client) { send = TRUE; } break; }
		case NOTIF_TEAM: { if((client.team == self.nent_client.team) || (client.classname == STR_SPECTATOR && client.enemy.team == self.nent_client.team)) { send = TRUE; } break; }
		case NOTIF_TEAM_EXCEPT: { if(((client != self.nent_client) && (client.team == self.nent_client.team) && !(client.classname == STR_SPECTATOR && client.enemy == self.nent_client))) { send = TRUE; } break; }
		case NOTIF_ANY: { send = TRUE; break; }
		case NOTIF_ANY_EXCEPT: { if((client != self.nent_client) && !(client.classname == STR_SPECTATOR && client.enemy == self.nent_client)) { send = TRUE; } break; }
		default: { send = FALSE; break; }
	}

	if(send)
	{		
		WriteByte(MSG_ENTITY, ENT_CLIENT_NOTIFICATION);
		WriteByte(MSG_ENTITY, self.nent_net_type);
		WriteShort(MSG_ENTITY, self.nent_net_name);
		for(i = 0; i < self.nent_stringcount; ++i) { WriteString(MSG_ENTITY, self.nent_strings[i]); } 
		for(i = 0; i < self.nent_floatcount; ++i) { WriteLong(MSG_ENTITY, self.nent_floats[i]); }
	}

	return send; 
}

void Send_Notification(float broadcast, entity client, float net_type, float net_name, ...count)
{
	if(broadcast && net_type && net_name)
	{
		float stringcount = stof(Get_Field_Value(F_STRNUM, net_type, net_name));
		float floatcount = stof(Get_Field_Value(F_FLNUM, net_type, net_name));
		float i;

		dprint("Send_Notification(", ftos(broadcast), ", ", ftos(net_type), ", ", Get_Field_Value(F_NAME, net_type, net_name), strcat(", ", ftos(count), ");\n"));
		dprint("  ^--: stringcount: ", ftos(stringcount), ", floatcount: ", ftos(floatcount), ".\n");

		if((stringcount + floatcount) > count) { backtrace(strcat("Not enough arguments for Send_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), "),"), " > count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }
		else if((stringcount + floatcount) < count) { backtrace(strcat("Too many arguments for Send_Notification! ", strcat("stringcount(", ftos(stringcount), ") + floatcount(", ftos(floatcount), "),"), " < count(", ftos(count), ").\nCheck the notification definition and the function call for accuracy...?\n")); return; }

		entity notif = spawn();
		notif.nent_broadcast = broadcast;
		notif.nent_client = client;
		notif.nent_net_type = net_type;
		notif.nent_net_name = net_name;
		notif.nent_stringcount = stringcount;
		notif.nent_floatcount = floatcount; 
		for(i = 0; i < stringcount; ++i) { notif.nent_strings[i] = strzone(...(i, string)); }
		for(i = 0; i < floatcount; ++i) { notif.nent_floats[i] = ...((stringcount + i), float); }
		
		notif.think = Notification_Remove;
		notif.nextthink = (time + 0.5); 

		Net_LinkEntity(notif, FALSE, 0, Write_Notification);

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
