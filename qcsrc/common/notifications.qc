// ================================================
//  Unified notification system, written by Samual
//  Last updated: February, 2013
// ================================================

#ifndef MENUQC
string arg_slot[8];
string Fill_Notif_Args(string args, string input,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3, float f4)
{
	dprint(sprintf("Fill_Notif_Args('%s', '%s', %s, %s, %s, %s, %d, %d, %d, %d);\n",
		args, input, s1, s2, s3, s4, f1, f2, f3, f4));

	string selected, remaining = args;
	float sel_num = 0;

	#ifdef CSQC
	string tmp_s;
	#endif
	
	if((remaining != "") && (input != ""))
	{
		for(;remaining;)
		{
			selected = car(remaining); remaining = cdr(remaining);

			switch(strtolower(selected))
			{
				#define ADD_ARG_CASE(selected,result) case selected: { arg_slot[sel_num] = result; ++sel_num; break; }
				
				ADD_ARG_CASE("s1", s1)
				ADD_ARG_CASE("s2", s2)
				ADD_ARG_CASE("s3", s3)
				ADD_ARG_CASE("s4", s4)
				ADD_ARG_CASE("f1", ftos(f1))
				ADD_ARG_CASE("f2", ftos(f2))
				ADD_ARG_CASE("f3", ftos(f3))
				ADD_ARG_CASE("f4", ftos(f4))

				#ifdef CSQC // CSQC replacements
				ADD_ARG_CASE("pass_key", 		((((tmp_s = getcommandkey("pass", "+use")) != "pass") && !(strstrofs(tmp_s, "not bound", 0) >= 0)) ? sprintf(CCR(_(" ^F1(Press %s)")), tmp_s) : ""))
				ADD_ARG_CASE("frag_ping", 		((f2 != BOT_PING) ? sprintf(CCR(_("\n(Ping ^2%d^BG)")), f2) : ""))
				ADD_ARG_CASE("frag_stats", 		sprintf(CCR(_("\n(Health ^1%d^BG / Armor ^2%d^BG)%s")), f1, f2, ((f3 != BOT_PING) ? sprintf(CCR(_(" (Ping ^2%d^BG)")), f3) : "")))
				//ADD_ARG_CASE("frag_pos", 		((Should_Print_Score_Pos(f1)) ? sprintf("\n^BG%s", Read_Score_Pos(f1)) : ""))
				ADD_ARG_CASE("spree_cen", 		(((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : ""))
				ADD_ARG_CASE("spree_inf", 		(((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : ""))
				ADD_ARG_CASE("spree_end", 		((f1 >= 3) ? sprintf(normal_or_gentle(_(", ending their %d frag spree"), _(", ending their %d score spree")), f1) : ""))
				ADD_ARG_CASE("spree_lost", 		((f1 >= 3) ? sprintf(normal_or_gentle(_(", losing their %d frag spree"), _(", losing their %d score spree")), f1) : ""))
				ADD_ARG_CASE("death_team", 		Team_ColoredFullName(f1 - 1))
				ADD_ARG_CASE("weapon_name", 	ftos(f1)) // weaponorder[f1].netname

				#else // SVQC replacements
				ADD_ARG_CASE("spree_inf", 		(((f1 == 3) || (f1 == 5) || (f1 == 10) || (f1 == 15) || (f1 == 20) || (f1 == 25) || (f1 == 30)) ? sprintf(normal_or_gentle(_("%d frag spree! "), _("%d score spree! ")), f1) : ""))
				ADD_ARG_CASE("spree_end", 		((f1 >= 3) ? sprintf(normal_or_gentle(_(", ending their %d frag spree"), _(", ending their %d score spree")), f1) : ""))
				ADD_ARG_CASE("spree_lost", 		((f1 >= 3) ? sprintf(normal_or_gentle(_(", losing their %d frag spree"), _(", losing their %d score spree")), f1) : ""))
				ADD_ARG_CASE("death_team", 		Team_ColoredFullName(f1))
				ADD_ARG_CASE("weapon_name",		ftos(f1)) // weaponorder[f1].netname
				#endif

				#undef ADD_ARG_CASE
				default: { print("Hit unknown token in selected string! '", selected, "'\n"); break; }
			}
			if(sel_num == 7) { print("Hit maximum arguments!\n"); break; }
		}

		return sprintf(input, arg_slot[0], arg_slot[1], arg_slot[2], arg_slot[3], arg_slot[4], arg_slot[5], arg_slot[6], arg_slot[7]);
	}

	return "";
}

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

	for(i = 0; i < NOTIF_INFO_COUNT; ++i) { e = Get_Notif_Ent(MSG_INFO, i); NOTIF_WRITE(MSG_INFO, e.nent_name, e.nent_normal); }
	for(i = 0; i < NOTIF_CENTER_COUNT; ++i) { e = Get_Notif_Ent(MSG_CENTER, i); NOTIF_WRITE(MSG_CENTER, e.nent_name, e.nent_normal); }
	
	for(i = 0; i < NOTIF_WEAPON_COUNT; ++i) { e = Get_Notif_Ent(MSG_WEAPON, i); NOTIF_WRITE(MSG_WEAPON, e.nent_name, sprintf("infoname: %s, centername: %s",
		Get_Notif_Name(MSG_INFO, Get_Notif_Infval(MSG_WEAPON, i)),
		Get_Notif_Name(MSG_CENTER, Get_Notif_Cenval(MSG_WEAPON, i)))); }
		
	for(i = 0; i < NOTIF_DEATH_COUNT; ++i) { e = Get_Notif_Ent(MSG_DEATH, i); NOTIF_WRITE(MSG_DEATH, e.nent_name, sprintf("infoname: %s, centername: %s",
		Get_Notif_Name(MSG_INFO, Get_Notif_Infval(MSG_DEATH, i)),
		Get_Notif_Name(MSG_CENTER, Get_Notif_Cenval(MSG_DEATH, i)))); }
		
	#endif

	print(sprintf("Notification counts: MSG_INFO = %d, MSG_CENTER = %d, MSG_WEAPON = %d, MSG_DEATH = %d\n",
		MSG_INFO_NOTIFS, MSG_CENTER_NOTIFS, MSG_WEAPON_NOTIFS, MSG_DEATH_NOTIFS));
	
	return;
	#undef NOTIF_WRITE
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
	// check supplied type and name for errors
	#ifdef NOTIFICATIONS_DEBUG
	{
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
	}
	#endif
	
	float stringcount = Get_Notif_Strnum(net_type, net_name);
	float floatcount = Get_Notif_Flnum(net_type, net_name);

	string s1 = ((0 < stringcount) ? ...(0, string) : NO_STR_ARG);
	string s2 = ((1 < stringcount) ? ...(1, string) : NO_STR_ARG);
	string s3 = ((2 < stringcount) ? ...(2, string) : NO_STR_ARG);
	string s4 = ((3 < stringcount) ? ...(3, string) : NO_STR_ARG);
	float f1 = ((stringcount < count) ? ...(stringcount, float) : NO_FL_ARG);
	float f2 = (((stringcount + 1) < count) ? ...((stringcount + 1), float) : NO_FL_ARG);
	float f3 = (((stringcount + 2) < count) ? ...((stringcount + 2), float) : NO_FL_ARG);
	float f4 = (((stringcount + 3) < count) ? ...((stringcount + 3), float) : NO_FL_ARG);

	#ifdef NOTIFICATIONS_DEBUG
	{
		dprint(sprintf("Local_Notification(%d, %s, %s, %s, %s, %s, %d, %d, %d, %d);\n",
			net_type, Get_Notif_Name(net_type, net_name),
			s1, s2, s3, s4, f1, f2, f3, f4));

		if((stringcount + floatcount) > count)
			{ backtrace(sprintf(strcat("Not enough arguments for Send_Notification! stringcount(%d) + floatcount(%d) > count(%d)\n", 
			"Check the notification definition and function call for accuracy...?\n"), stringcount, floatcount, count)); return; }
		else if((stringcount + floatcount) < count)
			{ backtrace(sprintf(strcat("Too many arguments for Send_Notification! stringcount(%d) + floatcount(%d) < count(%d)\n",
			"Check the notification definition and function call for accuracy...?\n"), stringcount, floatcount, count)); return; }
	}
	#endif
	

	switch(net_type)
	{
		case MSG_INFO:
		{
			#define MSG_INFO_NOTIF(name,strnum,flnum,args,hudargs,icon,normal,gentle) \
				case name: { CHECK_AUTOCVAR(name) \
				{ \
					print(sprintf(CCR(normal_or_gentle(normal, gentle)), args)); \
					#ifdef CSQC \
						if(icon != "") { HUD_Notify_Push(icon, hudargs); } \
					#endif \
				} return; }
				
			NOTIF_SWITCH_LIST(MSG_INFO, net_name, return)
			
			#undef MSG_INFO_NOTIF
			break;
		}
		#ifdef CSQC
		case MSG_CENTER:
		{
			#define MSG_CENTER_NOTIF(name,strnum,flnum,args,cpid,durcnt,normal,gentle) \
				case name: { CHECK_AUTOCVAR(name) \
				{ \
					centerprint_generic(HANDLE_CPID(cpid), sprintf(CCR(normal_or_gentle(normal, gentle)), args), durcnt); \
				} return; }

			NOTIF_SWITCH_LIST(MSG_CENTER, net_name, return)
			
			#undef MSG_CENTER_NOTIF
			break;
		}
		#endif
		case MSG_WEAPON:
		{
			#define MSG_WEAPON_NOTIF(name,infoname,centername) \
				case name: { CHECK_AUTOCVAR(name) \
				{ \
					#if infoname != NO_MSG \
						Local_Notification_Without_VarArgs(MSG_INFO, infoname, \
							Get_Notif_Strnum(MSG_INFO, infoname), \
							Get_Notif_Flnum(MSG_INFO, infoname), \
							s1, s2, s3, s4, f1, f2, f3, f4); \
					#endif \
					#ifdef CSQC \
						#if centername != NO_MSG \
							Local_Notification_Without_VarArgs(MSG_CENTER, centername, \
								Get_Notif_Strnum(MSG_CENTER, centername), \
								Get_Notif_Flnum(MSG_CENTER, centername), \
								s1, s2, s3, s4, f1, f2, f3, f4); \
						#endif \
					#endif \
				} return; }

			NOTIF_SWITCH_LIST(MSG_WEAPON, net_name, return)
			
			#undef MSG_WEAPON_NOTIF
			break;
		}
		case MSG_DEATH:
		{
			#define MSG_DEATH_NOTIF(name,infoname,centername) \
				case name: { CHECK_AUTOCVAR(name) \
				{ \
					#if infoname != NO_MSG \
						Local_Notification_Without_VarArgs(MSG_INFO, infoname, \
							Get_Notif_Strnum(MSG_INFO, infoname), \
							Get_Notif_Flnum(MSG_INFO, infoname), \
							s1, s2, s3, s4, f1, f2, f3, f4); \
					#endif \
					#ifdef CSQC \
						#if centername != NO_MSG \
							Local_Notification_Without_VarArgs(MSG_CENTER, centername, \
								Get_Notif_Strnum(MSG_CENTER, centername), \
								Get_Notif_Flnum(MSG_CENTER, centername), \
								s1, s2, s3, s4, f1, f2, f3, f4); \
						#endif \
					#endif \
				} return; } 

			NOTIF_SWITCH_LIST(MSG_DEATH, net_name, return)
			
			#undef MSG_DEATH_NOTIF
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

	float stringcount = Get_Notif_Strnum(net_type, net_name);
	float floatcount = Get_Notif_Flnum(net_type, net_name);

	string s1 = ((stringcount >= 1) ? ReadString() : NO_STR_ARG);
	string s2 = ((stringcount >= 2) ? ReadString() : NO_STR_ARG);
	string s3 = ((stringcount >= 3) ? ReadString() : NO_STR_ARG);
	string s4 = ((stringcount == 4) ? ReadString() : NO_STR_ARG);
	float f1 = ((floatcount >= 1) ? ReadLong() : NO_FL_ARG);
	float f2 = ((floatcount >= 2) ? ReadLong() : NO_FL_ARG);
	float f3 = ((floatcount >= 3) ? ReadLong() : NO_FL_ARG);
	float f4 = ((floatcount == 4) ? ReadLong() : NO_FL_ARG);

	#ifdef NOTIFICATIONS_DEBUG
		dprint(sprintf("Read_Notification(%d) at %f: net_name = %s.\n", is_new, time, Get_Notif_Name(net_type, net_name)));
	#endif
	
	if(is_new) { Local_Notification_Without_VarArgs(net_type, net_name, stringcount, floatcount, s1, s2, s3, s4, f1, f2, f3, f4); }
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
	#ifdef NOTIFICATIONS_DEBUG
	{
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
	}
	#endif

	// retreive counts for the arguments of this notification
	float stringcount = Get_Notif_Strnum(net_type, net_name);
	float floatcount = Get_Notif_Flnum(net_type, net_name);

	#ifdef NOTIFICATIONS_DEBUG
	{
		dprint(sprintf("Send_Notification(%d, %d, %s, stringcount: %d, floatcount: %d, varargs: %d);\n",
			broadcast, net_type, Get_Notif_Name(net_type, net_name), stringcount, floatcount, count));

		if((stringcount + floatcount) > count)
			{ backtrace(sprintf(strcat("Not enough arguments for Send_Notification! stringcount(%d) + floatcount(%d) > count(%d)\n", 
			"Check the notification definition and function call for accuracy...?\n"), stringcount, floatcount, count)); return; }
		else if((stringcount + floatcount) < count)
			{ backtrace(sprintf(strcat("Too many arguments for Send_Notification! stringcount(%d) + floatcount(%d) < count(%d)\n",
			"Check the notification definition and function call for accuracy...?\n"), stringcount, floatcount, count)); return; }
	}
	#endif

	entity notif = spawn();
	notif.nent_broadcast = broadcast;
	notif.nent_client = client;
	notif.nent_net_type = net_type;
	notif.nent_net_name = net_name;
	notif.nent_stringcount = stringcount;
	notif.nent_floatcount = floatcount;
	
	float i;
	
	for(i = 0; i < stringcount; ++i) { notif.nent_strings[i] = strzone(...(i, string)); }
	for(i = 0; i < floatcount; ++i) { notif.nent_floats[i] = ...((stringcount + i), float); }
	
	notif.think = Notification_Remove;
	notif.nextthink = (time + 0.5); 

	Net_LinkEntity(notif, FALSE, 0, Write_Notification);

	if((!server_is_local) && (broadcast == NOTIF_ANY || broadcast == NOTIF_ANY_EXCEPT) && (net_type != MSG_CENTER))
		{ Local_Notification_Without_VarArgs(net_type, net_name, stringcount, floatcount,
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
