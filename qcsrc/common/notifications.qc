// ================================================
//  Unified notification system, written by Samual
//  Last updated: February, 2013
// ================================================

#ifndef MENUQC
entity Get_Notif_Ent(float net_type, float net_name)
{
	switch(net_type)
	{
		case MSG_INFO: return msg_info_notifs[net_name - 1];
		case MSG_CENTER: return msg_center_notifs[net_name - 1];
		case MSG_WEAPON: return msg_weapon_notifs[net_name - 1];
		case MSG_DEATH: return msg_death_notifs[net_name - 1];
	}
	backtrace(sprintf("Get_Notif_Ent(%d, %d): Improper net type!\n", net_type, net_name));
	return world;
}

string Get_Notif_Name(float net_type, float net_name)
{
	entity e = Get_Notif_Ent(net_type, net_name);
	if(e) { return e.nent_name; }
	backtrace(sprintf("Get_Notif_Name(%d, %d): Could not find entity!\n", net_type, net_name));
	return "";
}

float Get_Notif_Infval(float net_type, float net_name)
{
	entity e = Get_Notif_Ent(net_type, net_name);
	if(e) { return e.nent_infoname; }
	backtrace(sprintf("Get_Notif_Infval(%d, %d): Could not find entity!\n", net_type, net_name));
	return NO_MSG;
}

float Get_Notif_Cenval(float net_type, float net_name)
{
	entity e = Get_Notif_Ent(net_type, net_name);
	if(e) { return e.nent_centername; }
	backtrace(sprintf("Get_Notif_Cenval(%d, %d): Could not find entity!\n", net_type, net_name));
	return NO_MSG;
}

float Get_Notif_Strnum(float net_type, float net_name)
{
	entity e = Get_Notif_Ent(net_type, net_name);
	if(e) { return e.nent_stringcount; }
	backtrace(sprintf("Get_Notif_Strnum(%d, %d): Could not find entity!\n", net_type, net_name));
	return NO_MSG;
}

float Get_Notif_Flnum(float net_type, float net_name)
{
	entity e = Get_Notif_Ent(net_type, net_name);
	if(e) { return e.nent_floatcount; }
	backtrace(sprintf("Get_Notif_Flnum(%d, %d): Could not find entity!\n", net_type, net_name));
	return NO_MSG;
}
#endif // ifndef MENUQC


// ===============================
//  Frontend Notification Pushing
// ===============================

void Dump_Notifications(float fh, float alsoprint)
{
	float MSG_INFO_NOTIFS = 0, MSG_CENTER_NOTIFS = 0, MSG_WEAPON_NOTIFS = 0, MSG_DEATH_NOTIFS = 0;

	#define NOTIF_WRITE(type,name,text) { \
		++##type##_NOTIFS; \
		notif_msg = sprintf("seta %s 1 // %s - %s\n", name, #type, strreplace("\n", "\\n", text)); \
		fputs(fh, notif_msg); \
		if(alsoprint) { print(strreplace("^", "^^", notif_msg)); } }

	#ifndef MENUQC
	string notif_msg;
	float i;
	entity e;

	for(i = 0; i < NOTIF_INFO_COUNT; ++i) {
		e = Get_Notif_Ent(MSG_INFO, i);
		NOTIF_WRITE(MSG_INFO, e.nent_name, e.nent_string); }
		
	for(i = 0; i < NOTIF_CENTER_COUNT; ++i) {
		e = Get_Notif_Ent(MSG_CENTER, i);
		NOTIF_WRITE(MSG_CENTER, e.nent_name, e.nent_string); }
	
	for(i = 0; i < NOTIF_WEAPON_COUNT; ++i) {
		e = Get_Notif_Ent(MSG_WEAPON, i);
		NOTIF_WRITE(MSG_WEAPON, e.nent_name, sprintf("infoname: %s, centername: %s",
			Get_Notif_Name(MSG_INFO, Get_Notif_Infval(MSG_WEAPON, i)),
			Get_Notif_Name(MSG_CENTER, Get_Notif_Cenval(MSG_WEAPON, i)) ) ); }
		
	for(i = 0; i < NOTIF_DEATH_COUNT; ++i) {
		e = Get_Notif_Ent(MSG_DEATH, i);
		NOTIF_WRITE(MSG_DEATH, e.nent_name, sprintf("infoname: %s, centername: %s",
			Get_Notif_Name(MSG_INFO, Get_Notif_Infval(MSG_DEATH, i)),
			Get_Notif_Name(MSG_CENTER, Get_Notif_Cenval(MSG_DEATH, i)) ) ); }
		
	#endif

	print(sprintf("Notification counts: MSG_INFO = %d, MSG_CENTER = %d, MSG_WEAPON = %d, MSG_DEATH = %d\n",
		MSG_INFO_NOTIFS, MSG_CENTER_NOTIFS, MSG_WEAPON_NOTIFS, MSG_DEATH_NOTIFS));
	
	return;
	#undef NOTIF_WRITE
}

#ifndef MENUQC
string Local_Notification_sprintf(string input, string args, 
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	#ifdef NOTIFICATIONS_DEBUG
	dprint(sprintf("Local_Notification_sprintf('%s^7', '%s', %s, %s);\n",
		strreplace("\n", "\\n", input), args,
		sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)));
	#endif
	
	string selected, remaining = args;
	float sel_num = 0;

	#ifdef CSQC
	string tmp_s;
	#endif

	arg_slot[0] = ""; arg_slot[1] = ""; arg_slot[2] = ""; arg_slot[3] = ""; arg_slot[4] = ""; arg_slot[5] = ""; arg_slot[6] = "";
	
	if((remaining != "") && (input != ""))
	{
		for(;remaining;)
		{
			selected = car(remaining); remaining = cdr(remaining);

			switch(strtolower(selected))
			{
				#define ARG_CASE(prog,selected,result) \
					#ifdef CSQC \
					#if (prog == ARG_BOTH) || (prog == ARG_CSQC) \
						case selected: { arg_slot[sel_num] = result; ++sel_num; break; } \
					#endif \
					#else \
					#if (prog == ARG_BOTH) || (prog == ARG_SVQC) \
						case selected: { arg_slot[sel_num] = result; ++sel_num; break; } \
					#endif \
					#endif

				NOTIF_ARGUMENT_LIST
				#undef ARG_CASE
				default: { backtrace(sprintf("Hit unknown token in selected string! '%s'\n", selected)); break; }
			}
			if((sel_num+1) > 7) { backtrace("Hit maximum arguments!\n"); break; }
		}

		return sprintf(input, arg_slot[0], arg_slot[1], arg_slot[2], arg_slot[3], arg_slot[4], arg_slot[5], arg_slot[6]);
	}

	return "";
}

#ifdef CSQC
void Local_Notification_HUD_Notify_Push(string icon, string hudargs, string s1, string s2)
{
	string selected, remaining = hudargs;
	float sel_num = 0;

	arg_slot[0] = ""; arg_slot[1] = "";
	
	if(remaining != "")
	{
		for(;remaining;)
		{
			selected = car(remaining); remaining = cdr(remaining);

			switch(strtolower(selected))
			{
				#define ARG_CASE(selected,result) case selected: { arg_slot[sel_num] = result; ++sel_num; break; }
				ARG_CASE("s1", s1)
				ARG_CASE("s2", s2)
				#undef ARG_CASE
				default: { backtrace(sprintf("Hit unknown token in selected string! '%s'\n", selected)); break; }
			}
			if((sel_num+1) > 2) { backtrace("Hit maximum arguments!\n"); break; }
		}
	}

	HUD_Notify_Push(icon, arg_slot[0], arg_slot[1]);
}
#endif

void Local_Notification(float net_type, float net_name, ...count)
{
	// check supplied type and name for errors
	#define CHECKARG_TYPENAME(type) case MSG_##type##: \
		{ if(!net_name || (net_name > NOTIF_##type##_COUNT)) \
		{ checkargs = sprintf("Improper name: %d!", net_name); } break; }
	string checkargs = "";
	switch(net_type)
	{
		CHECKARG_TYPENAME(INFO)
		CHECKARG_TYPENAME(CENTER)
		CHECKARG_TYPENAME(WEAPON)
		CHECKARG_TYPENAME(DEATH)
		default: { checkargs = sprintf("Improper type: %d!", checkargs, net_type); break; }
	}
	#undef CHECKARG_TYPENAME
	if(checkargs != "") { backtrace(sprintf("Incorrect usage of Local_Notification: %s\n", checkargs)); return; }

	entity notif = Get_Notif_Ent(net_type, net_name);
	if not(notif) { backtrace("Local_Notification: Could not find notification entity! (This wasn't caught by usage check?...)\n"); return; }
	if not(notif.nent_enabled) { print("entity notification was disabled...\n"); return; }

	if((notif.nent_stringcount + notif.nent_floatcount) > count)
		{ backtrace(sprintf(strcat("Not enough arguments for Local_Notification! stringcount(%d) + floatcount(%d) > count(%d)\n", 
		"Check the notification definition and function call for accuracy...?\n"), notif.nent_stringcount, notif.nent_floatcount, count)); return; }
	else if((notif.nent_stringcount + notif.nent_floatcount) < count)
		{ backtrace(sprintf(strcat("Too many arguments for Local_Notification! stringcount(%d) + floatcount(%d) < count(%d)\n",
		"Check the notification definition and function call for accuracy...?\n"), notif.nent_stringcount, notif.nent_floatcount, count)); return; }

	string s1 = ((0 < notif.nent_stringcount) ? ...(0, string) : "");
	string s2 = ((1 < notif.nent_stringcount) ? ...(1, string) : "");
	string s3 = ((2 < notif.nent_stringcount) ? ...(2, string) : "");
	string s4 = ((3 < notif.nent_stringcount) ? ...(3, string) : "");
	float f1 = ((notif.nent_stringcount < count) ? ...(notif.nent_stringcount, float) : NO_FL_ARG);
	float f2 = (((notif.nent_stringcount + 1) < count) ? ...((notif.nent_stringcount + 1), float) : NO_FL_ARG);
	float f3 = (((notif.nent_stringcount + 2) < count) ? ...((notif.nent_stringcount + 2), float) : NO_FL_ARG);
	float f4 = (((notif.nent_stringcount + 3) < count) ? ...((notif.nent_stringcount + 3), float) : NO_FL_ARG);

	#ifdef NOTIFICATIONS_DEBUG
	dprint(sprintf("Local_Notification(%d, %s, %s, %s);\n",
		net_type, notif.nent_name,
		sprintf("'%s^7', '%s^7', '%s^7', '%s^7'", s1, s2, s3, s4),
		sprintf("%d, %d, %d, %d", f1, f2, f3, f4)));
	#endif
	
	switch(net_type)
	{
		case MSG_INFO:
		{
			print(Local_Notification_sprintf(notif.nent_string, notif.nent_args, 
				s1, s2, s3, s4, f1, f2, f3, f4));
			#ifdef CSQC 
			if(notif.nent_icon != "") { Local_Notification_HUD_Notify_Push(notif.nent_icon, notif.nent_hudargs, s1, s2); } 
			#endif 
			break;
		}
		
		#ifdef CSQC
		case MSG_CENTER:
		{
			centerprint_generic(notif.nent_cpid,
				Local_Notification_sprintf(notif.nent_string, notif.nent_args, 
				s1, s2, s3, s4, f1, f2, f3, f4), 0, 0);
			break;
		}
		#endif
		
		case MSG_WEAPON:
		case MSG_DEATH:
		{
			if(notif.nent_infoname)
			if(msg_info_notifs[notif.nent_infoname - 1].nent_enabled)
			{
				Local_Notification_Without_VarArgs(MSG_INFO, notif.nent_infoname, 
					Get_Notif_Strnum(MSG_INFO, notif.nent_infoname), 
					Get_Notif_Flnum(MSG_INFO, notif.nent_infoname), 
					s1, s2, s3, s4, f1, f2, f3, f4);
			}
			#ifdef CSQC
			if(notif.nent_centername)
			if(msg_center_notifs[notif.nent_centername - 1].nent_enabled)
			{
				Local_Notification_Without_VarArgs(MSG_CENTER, notif.nent_centername, 
					Get_Notif_Strnum(MSG_CENTER, notif.nent_centername), 
					Get_Notif_Flnum(MSG_CENTER, notif.nent_centername), 
					s1, s2, s3, s4, f1, f2, f3, f4); 
			}
			#endif
			break;
		}
	}
}

void Local_Notification_Without_VarArgs(float net_type, float net_name,
	float stringcount, float floatcount,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
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

	entity notif = Get_Notif_Ent(net_type, net_name);
	if not(notif) { print("Read_Notification: Could not find notification entity!\n"); return; }
	if not(notif.nent_enabled) { print("Read_Notification: Entity was disabled but networked anyway?!?...\n"); return; }

	string s1 = ((0 < notif.nent_stringcount) ? ReadString() : "");
	string s2 = ((1 < notif.nent_stringcount) ? ReadString() : "");
	string s3 = ((2 < notif.nent_stringcount) ? ReadString() : "");
	string s4 = ((3 < notif.nent_stringcount) ? ReadString() : "");
	float f1 = ((0 < notif.nent_floatcount) ? ReadLong() : NO_FL_ARG);
	float f2 = ((1 < notif.nent_floatcount) ? ReadLong() : NO_FL_ARG);
	float f3 = ((2 < notif.nent_floatcount) ? ReadLong() : NO_FL_ARG);
	float f4 = ((3 < notif.nent_floatcount) ? ReadLong() : NO_FL_ARG);

	#ifdef NOTIFICATIONS_DEBUG
	dprint(sprintf("Read_Notification(%d) at %f: net_name = %s.\n", is_new, time, notif.nent_name));
	#endif
	
	if(is_new) { Local_Notification_Without_VarArgs(net_type, net_name, notif.nent_stringcount, notif.nent_floatcount, s1, s2, s3, s4, f1, f2, f3, f4); }
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

void Send_Notification(float broadcast, entity client,
	float net_type, float net_name, ...count)
{
	// check supplied broadcast, target, type, and name for errors
	#define CHECKARG_TYPENAME(type) case MSG_##type##: \
		{ if(!net_name || (net_name > NOTIF_##type##_COUNT)) \
		{ checkargs = sprintf("Improper name: %d!", net_name); } break; }
	string checkargs = "";
	switch(net_type)
	{
		CHECKARG_TYPENAME(INFO)
		CHECKARG_TYPENAME(CENTER)
		CHECKARG_TYPENAME(WEAPON)
		CHECKARG_TYPENAME(DEATH)
		default: { checkargs = sprintf("Improper type: %d!", checkargs, net_type); break; }
	}
	#undef CHECKARG_TYPENAME
	if(checkargs != "") { checkargs = strcat(checkargs, " "); }
	switch(broadcast)
	{
		case NOTIF_ONE:
		case NOTIF_ONE_ONLY: { if(clienttype(client) == CLIENTTYPE_NOTACLIENT) { checkargs = sprintf("%sNo client provided!", checkargs); } break; }
		case NOTIF_ANY_EXCEPT: { if(clienttype(client) == CLIENTTYPE_NOTACLIENT) { checkargs = sprintf("%sException can't be a non-client!", checkargs); } break; }
		case NOTIF_ANY: { if(client) { checkargs = sprintf("%sEntity provided when world was required!", checkargs); } break; }
		case NOTIF_TEAM:
		case NOTIF_TEAM_EXCEPT:
		{
			if not(teamplay) { checkargs = sprintf("%sTeamplay not active!", checkargs); }
			else if(clienttype(client) == CLIENTTYPE_NOTACLIENT)
			{
				if(broadcast == NOTIF_TEAM) { checkargs = sprintf("%sNo client provided!", checkargs); }
				else { checkargs = sprintf("%sException can't be a non-client!", checkargs); }
			}
			break;
		}
		default: { checkargs = sprintf("%sImproper broadcast: %d!", checkargs, broadcast); break; }
	}
	if(checkargs != "") { backtrace(sprintf("Incorrect usage of Send_Notification: %s\n", checkargs)); return; }

	// retreive counts for the arguments of this notification
	entity notif = Get_Notif_Ent(net_type, net_name);
	if not(notif) { backtrace("Send_Notification: Could not find notification entity! (This wasn't caught by usage check?...)\n"); return; }
	if not(notif.nent_enabled) { print("Send_Notification: Entity was disabled...\n"); return; }

	if((notif.nent_stringcount + notif.nent_floatcount) > count)
		{ backtrace(sprintf(strcat("Not enough arguments for Send_Notification! stringcount(%d) + floatcount(%d) > count(%d)\n", 
		"Check the notification definition and function call for accuracy...?\n"), notif.nent_stringcount, notif.nent_floatcount, count)); return; }
	else if((notif.nent_stringcount + notif.nent_floatcount) < count)
		{ backtrace(sprintf(strcat("Too many arguments for Send_Notification! stringcount(%d) + floatcount(%d) < count(%d)\n",
		"Check the notification definition and function call for accuracy...?\n"), notif.nent_stringcount, notif.nent_floatcount, count)); return; }

	#ifdef NOTIFICATIONS_DEBUG
	dprint(sprintf("Send_Notification(%d, %d, %s, stringcount: %d, floatcount: %d, varargs: %d);\n",
		broadcast, net_type, notif.nent_name, notif.nent_stringcount, notif.nent_floatcount, count));
	#endif

	entity net_notif = spawn();
	net_notif.nent_broadcast = broadcast;
	net_notif.nent_client = client;
	net_notif.nent_net_type = net_type;
	net_notif.nent_net_name = net_name;
	net_notif.nent_stringcount = notif.nent_stringcount;
	net_notif.nent_floatcount = notif.nent_floatcount;
	
	float i;
	
	for(i = 0; i < net_notif.nent_stringcount; ++i) { net_notif.nent_strings[i] = strzone(...(i, string)); }
	for(i = 0; i < net_notif.nent_floatcount; ++i) { net_notif.nent_floats[i] = ...((net_notif.nent_stringcount + i), float); }
	
	net_notif.think = Notification_Remove;
	net_notif.nextthink = (time + 0.5); 

	Net_LinkEntity(net_notif, FALSE, 0, Write_Notification);

	if((!server_is_local) && (broadcast == NOTIF_ANY || broadcast == NOTIF_ANY_EXCEPT) && (net_type != MSG_CENTER))
		{ Local_Notification_Without_VarArgs(net_type, net_name, notif.nent_stringcount, notif.nent_floatcount,
			IFSTR(0), IFSTR(1), IFSTR(2), IFSTR(3), IFFL(0), IFFL(1), IFFL(2), IFFL(3)); }
}

void Send_Notification_Without_VarArgs(float broadcast, entity client,
	float net_type, float net_name,
	float stringcount, float floatcount,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{		
	#define VARITEM(stringc,floatc,args) if((stringcount == stringc) && (floatcount == floatc)) { Send_Notification(broadcast, client, net_type, net_name, args); return; }
	EIGHT_VARS_TO_VARARGS_VARLIST
	#undef VARITEM

	Send_Notification(broadcast, client, net_type, net_name); // some notifications don't have any arguments at all
}

void Send_Notification_Legacy_Wrapper(float broadcast, entity client,
	float net_type, float net_name,
	string s1, string s2,
	float f1, float f2, float f3)
{
	float stringcount = Get_Notif_Strnum(net_type, net_name);
	float floatcount = Get_Notif_Flnum(net_type, net_name);
	Send_Notification_Without_VarArgs(broadcast, client, net_type, net_name, stringcount, floatcount, s1, s2, "", "", f1, f2, f3, NO_FL_ARG);
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
