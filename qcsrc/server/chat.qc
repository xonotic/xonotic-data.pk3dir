#include "chat.qh"

#include <common/gametypes/_mod.qh>
#include <common/mapobjects/target/location.qh>
#include <common/mapobjects/triggers.qh>
#include <common/notifications/all.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/weapons/weapon.qh>
#include <common/wepent.qh>
#include <server/command/cmd.qh>
#include <server/command/common.qh>
#include <server/gamelog.qh>
#include <server/main.qh>
#include <server/mapvoting.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/tracing.qh>
#include <server/world.qh>

/**
 * message "": do not say, just test flood control
 * return value:
 *   1 = accept
 *   0 = reject
 *  -1 = fake accept
 */
int Say(entity source, int teamsay, entity privatesay, string msgin, bool floodcontrol)
{
	if(!autocvar_g_chat_allowed && IS_REAL_CLIENT(source))
	{
		Send_Notification(NOTIF_ONE_ONLY, source, MSG_INFO, INFO_CHAT_DISABLED);
		return 0;
	}

	if(!autocvar_g_chat_private_allowed && privatesay)
	{
		Send_Notification(NOTIF_ONE_ONLY, source, MSG_INFO, INFO_CHAT_PRIVATE_DISABLED);
		return 0;
	}

	if(!autocvar_g_chat_spectator_allowed && IS_OBSERVER(source))
	{
		Send_Notification(NOTIF_ONE_ONLY, source, MSG_INFO, INFO_CHAT_SPECTATOR_DISABLED);
		return 0;
	}

	if(!autocvar_g_chat_team_allowed && teamsay)
	{
		Send_Notification(NOTIF_ONE_ONLY, source, MSG_INFO, INFO_CHAT_TEAM_DISABLED);
		return 0;
	}

	if (!teamsay && !privatesay && substring(msgin, 0, 1) == " ")
		msgin = substring(msgin, 1, -1); // work around DP say bug (say_team does not have this!)

	if (source)
		msgin = formatmessage(source, msgin);

	string colorstr;
	if (!(IS_PLAYER(source) || INGAME(source)))
		colorstr = "^0"; // black for spectators
	else if(teamplay)
		colorstr = Team_ColorCode(source.team);
	else
	{
		colorstr = "";
		teamsay = false;
	}

	if (!source) {
		colorstr = "";
		teamsay = false;
	}

	if(msgin != "")
		msgin = trigger_magicear_processmessage_forallears(source, teamsay, privatesay, msgin);

	/*
	 * using bprint solves this... me stupid
	// how can we prevent the message from appearing in a listen server?
	// for now, just give "say" back and only handle say_team
	if(!teamsay)
	{
		clientcommand(source, strcat("say ", msgin));
		return;
	}
	*/

	string namestr = "";
	if (source)
		namestr = playername(source.netname, source.team, (autocvar_g_chat_teamcolors && IS_PLAYER(source)));

	if (autocvar_g_chat_show_playerid)
		namestr = strcat(namestr, " ^9#", itos(etof(source)), "^7");

	string colorprefix = (strdecolorize(namestr) == namestr) ? "^3" : "^7";

	string msgstr = "", cmsgstr = "";
	string privatemsgprefix = string_null;
	int privatemsgprefixlen = 0;
	if (msgin != "")
	{
		bool found_me = (substring(msgin, 0, 4) == "/me "); // only accept /me at the start of the string, to prevent imitating others
		if(found_me)
		{
			string newnamestr = ((teamsay) ? strcat(colorstr, "(", colorprefix, namestr, colorstr, ")", "^7") : strcat(colorprefix, namestr, "^7"));
			msgin = strcat(newnamestr, substring(msgin, 3, strlen(msgin) - 3));
		}

		if(privatesay)
		{
			msgstr = strcat("\{1}\{13}* ", colorprefix, namestr, "^3 tells you: ^7");
			privatemsgprefixlen = strlen(msgstr);
			msgstr = strcat(msgstr, msgin);
			cmsgstr = strcat(colorstr, colorprefix, namestr, "^3 tells you:\n^7", msgin);
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", playername(privatesay.netname, privatesay.team, (autocvar_g_chat_teamcolors && IS_PLAYER(privatesay))), ": ^7");
		}
		else if(teamsay)
		{
			if(found_me)
			{
				//msgin = strreplace("/me", "", msgin);
				//msgin = substring(msgin, 3, strlen(msgin));
				//msgin = strreplace("/me", strcat(colorstr, "(", colorprefix, namestr, colorstr, ")^7"), msgin);
				msgstr = strcat("\{1}\{13}^4* ", "^7", msgin);
			}
			else
				msgstr = strcat("\{1}\{13}", colorstr, "(", colorprefix, namestr, colorstr, ") ^7", msgin);
			cmsgstr = strcat(colorstr, "(", colorprefix, namestr, colorstr, ")\n^7", msgin);
		}
		else
		{
			if(found_me)
			{
				//msgin = strreplace("/me", "", msgin);
				//msgin = substring(msgin, 3, strlen(msgin));
				//msgin = strreplace("/me", strcat(colorprefix, namestr), msgin);
				msgstr = strcat("\{1}^4* ^7", msgin);
			}
			else {
				msgstr = "\{1}";
				msgstr = strcat(msgstr, (namestr != "") ? strcat(colorprefix, namestr, "^7: ") : "^7");
				msgstr = strcat(msgstr, msgin);
			}
			cmsgstr = "";
		}
		msgstr = strcat(strreplace("\n", " ", msgstr), "\n"); // newlines only are good for centerprint
	}

	string fullmsgstr = msgstr;
	string fullcmsgstr = cmsgstr;
	float mod_time = 0;

	// FLOOD CONTROL
	int flood = 0;
	var .float flood_field = floodcontrol_chat;
	if(floodcontrol && source)
	{
		float flood_spl, flood_burst, flood_lmax;
		if(privatesay)
		{
			flood_spl = autocvar_g_chat_flood_spl_tell;
			flood_burst = autocvar_g_chat_flood_burst_tell;
			flood_lmax = autocvar_g_chat_flood_lmax_tell;
			flood_field = floodcontrol_chattell;
		}
		else if(teamsay)
		{
			flood_spl = autocvar_g_chat_flood_spl_team;
			flood_burst = autocvar_g_chat_flood_burst_team;
			flood_lmax = autocvar_g_chat_flood_lmax_team;
			flood_field = floodcontrol_chatteam;
		}
		else
		{
			flood_spl = autocvar_g_chat_flood_spl;
			flood_burst = autocvar_g_chat_flood_burst;
			flood_lmax = autocvar_g_chat_flood_lmax;
			flood_field = floodcontrol_chat;
		}
		// to match cvar descriptions, a value of 3 must allow three-line bursts and not four!
		flood_burst = max(0, flood_burst - 1);

		int lines = -1;
		mod_time = gettime(GETTIME_FRAMESTART) + flood_burst * flood_spl;
		// do flood control for the default line size
		if(msgstr != "")
		{
			getWrappedLine_remaining = msgstr;
			msgstr = "";
			lines = 0;
			while(getWrappedLine_remaining && (!flood_lmax || lines <= flood_lmax))
			{
				msgstr = strcat(msgstr, " ", getWrappedLineLen(82.4289758859709, strlennocol)); // perl averagewidth.pl < gfx/vera-sans.width
				++lines;
			}
			msgstr = substring(msgstr, 1, strlen(msgstr) - 1);

			if(getWrappedLine_remaining != "")
			{
				msgstr = strcat(msgstr, "\n");
				flood = 2;
			}
		}

		if (mod_time >= source.(flood_field))
		{
			if (lines > 1)
				flood_spl *= lines;
			source.(flood_field) = max(gettime(GETTIME_FRAMESTART), source.(flood_field)) + flood_spl;
		}
		else
		{
			if (lines >= 0) // if true msgstr was modified
				msgstr = fullmsgstr;
			flood = 1;
		}
	}

	string sourcemsgstr, sourcecmsgstr;
	if(flood == 2) // cannot happen for empty msgstr
	{
		if(autocvar_g_chat_flood_notify_flooder)
		{
			sourcemsgstr = strcat(msgstr, "\n^3CHAT FLOOD CONTROL: ^7message too long, trimmed\n");
			sourcecmsgstr = "";
		}
		else
		{
			sourcemsgstr = fullmsgstr;
			sourcecmsgstr = fullcmsgstr;
		}
		cmsgstr = "";
	}
	else
	{
		sourcemsgstr = msgstr;
		sourcecmsgstr = cmsgstr;
	}

	if (!privatesay && source && !(IS_PLAYER(source) || INGAME(source)) && !game_stopped
		&& (teamsay || CHAT_NOSPECTATORS()))
	{
		teamsay = -1; // spectators
	}

	if(flood)
		LOG_INFO("NOTE: ", playername(source.netname, source.team, IS_PLAYER(source)), "^7 is flooding.");

	// build sourcemsgstr by cutting off a prefix and replacing it by the other one
	if(privatesay)
		sourcemsgstr = strcat(privatemsgprefix, substring(sourcemsgstr, privatemsgprefixlen, -1));

	int ret;
	if(source && CS(source).muted)
	{
		// always fake the message
		ret = -1;
	}
	else if(flood == 1)
	{
		if (autocvar_g_chat_flood_notify_flooder)
		{
			sprint(source, strcat("^3CHAT FLOOD CONTROL: ^7wait ^1",
				ftos(source.(flood_field) - mod_time), "^3 seconds\n"));
			ret = 0;
		}
		else
			ret = -1;
	}
	else
	{
		ret = 1;
	}

	if (privatesay && source && !(IS_PLAYER(source) || INGAME(source)) && !game_stopped
		&& (IS_PLAYER(privatesay) || INGAME(privatesay)) && CHAT_NOSPECTATORS())
	{
		ret = -1; // just hide the message completely
	}

	MUTATOR_CALLHOOK(ChatMessage, source, ret, sourcemsgstr);
	ret = M_ARGV(1, int);

	string event_log_msg = "";

	if(sourcemsgstr != "" && ret != 0)
	{
		if(ret < 0) // faked message, because the player is muted
		{
			sprint(source, sourcemsgstr);
			if(sourcecmsgstr != "" && !privatesay)
				centerprint(source, sourcecmsgstr);
		}
		else if(privatesay) // private message, between 2 people only
		{
			sprint(source, sourcemsgstr);
			if (!autocvar_g_chat_tellprivacy) { dedicated_print(msgstr); } // send to server console too if "tellprivacy" is disabled
			if(!MUTATOR_CALLHOOK(ChatMessageTo, privatesay, source))
			{
				if(IS_REAL_CLIENT(source) && ignore_playerinlist(source, privatesay)) // check ignored players from personal chat log (from "ignore" command)
					return -1; // no sending to this player, thank you very much

				sprint(privatesay, msgstr);
				if(cmsgstr != "")
					centerprint(privatesay, cmsgstr);
			}
		}
		else if ( teamsay && CS(source).active_minigame )
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != source && CS(it).active_minigame == CS(source).active_minigame && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				if(IS_REAL_CLIENT(source) && ignore_playerinlist(source, it)) // check ignored players from personal chat log (from "ignore" command)
					continue; // no sending to this player, thank you very much

				sprint(it, msgstr);
			});
			event_log_msg = sprintf(":chat_minigame:%d:%s:%s", source.playerid, CS(source).active_minigame.netname, msgin);

		}
		else if(teamsay > 0) // team message, only sent to teammates
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			if(sourcecmsgstr != "")
				centerprint(source, sourcecmsgstr);
			FOREACH_CLIENT((IS_PLAYER(it) || INGAME(it)) && IS_REAL_CLIENT(it) && it != source && it.team == source.team && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				if(IS_REAL_CLIENT(source) && ignore_playerinlist(source, it)) // check ignored players from personal chat log (from "ignore" command)
					continue; // no sending to this player, thank you very much

				sprint(it, msgstr);
				if(cmsgstr != "")
					centerprint(it, cmsgstr);
			});
			event_log_msg = sprintf(":chat_team:%d:%d:%s", source.playerid, source.team, strreplace("\n", " ", msgin));
		}
		else if(teamsay < 0) // spectator message, only sent to spectators
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOREACH_CLIENT(!(IS_PLAYER(it) || INGAME(it)) && IS_REAL_CLIENT(it) && it != source && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				if(IS_REAL_CLIENT(source) && ignore_playerinlist(source, it)) // check ignored players from personal chat log (from "ignore" command)
					continue; // no sending to this player, thank you very much

				sprint(it, msgstr);
			});
			event_log_msg = sprintf(":chat_spec:%d:%s", source.playerid, strreplace("\n", " ", msgin));
		}
		else
		{
			if (source) {
				sprint(source, sourcemsgstr);
				dedicated_print(msgstr); // send to server console too
				MX_Say(strcat(playername(source.netname, source.team, IS_PLAYER(source)), "^7: ", msgin));
			}
			FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != source && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				if(IS_REAL_CLIENT(source) && ignore_playerinlist(source, it)) // check ignored players from personal chat log (from "ignore" command)
					continue; // no sending to this player, thank you very much

				sprint(it, msgstr);
			});
			event_log_msg = sprintf(":chat:%d:%s", source.playerid, strreplace("\n", " ", msgin));
		}
	}

	if (autocvar_sv_eventlog && (event_log_msg != "")) {
		GameLogEcho(event_log_msg);
	}

	return ret;
}

entity findnearest(vector point, bool checkitems, vector axismod)
{
	vector dist;
	int num_nearest = 0;

	IntrusiveList list = ((checkitems) ? g_items : g_locations);
	IL_EACH(list, (checkitems ? (it.target == "###item###") : (it.classname == "target_location")),
	{
		if ((it.items == IT_KEY1 || it.items == IT_KEY2) && it.target == "###item###")
			dist = it.oldorigin;
		else
			dist = it.origin;
		dist = dist - point;
		dist = vec3(dist.x * axismod.x, dist.y * axismod.y, dist.z * axismod.z);
		float len = vlen2(dist);

		int l;
		for (l = 0; l < num_nearest; ++l)
		{
			if (len < nearest_length[l])
				break;
		}

		// now i tells us where to insert at
		//	 INSERTION SORT! YOU'VE SEEN IT! RUN!
		if (l < NUM_NEAREST_ENTITIES)
		{
			for (int j = NUM_NEAREST_ENTITIES - 2; j >= l; --j)
			{
				nearest_length[j + 1] = nearest_length[j];
				nearest_entity[j + 1] = nearest_entity[j];
			}
			nearest_length[l] = len;
			nearest_entity[l] = it;
			if (num_nearest < NUM_NEAREST_ENTITIES)
				num_nearest = num_nearest + 1;
		}
	});

	// now use the first one from our list that we can see
	for (int j = 0; j < num_nearest; ++j)
	{
		traceline(point, nearest_entity[j].origin, true, NULL);
		if (trace_fraction == 1)
		{
			if (j != 0)
			{
				LOG_TRACEF("Nearest point (%s) is not visible, using a visible one.",
					nearest_entity[0].netname);
			}
			return nearest_entity[j];
		}
	}

	if (num_nearest == 0)
		return NULL;

	LOG_TRACE("Not seeing any location point, using nearest as fallback.");
	/* DEBUGGING CODE:
	dprint("Candidates were: ");
	for(j = 0; j < num_nearest; ++j)
	{
		if(j != 0)
			dprint(", ");
		dprint(nearest_entity[j].netname);
	}
	dprint("\n");
	*/

	return nearest_entity[0];
}

string NearestLocation(vector p)
{
	string ret = "somewhere";
	entity loc = findnearest(p, false, '1 1 1');
	if (loc)
		ret = loc.message;
	else
	{
		loc = findnearest(p, true, '1 1 4');
		if (loc)
			ret = loc.netname;
	}
	return ret;
}

string PlayerHealth(entity this)
{
	float myhealth = floor(GetResource(this, RES_HEALTH));
	if(myhealth == -666)
		return "spectating";
	else if(myhealth == -2342 || (myhealth == 2342 && mapvote_initialized))
		return "observing";
	else if(myhealth <= 0 || IS_DEAD(this))
		return "dead";
	return ftos(myhealth);
}

string WeaponNameFromWeaponentity(entity this, .entity weaponentity)
{
	entity wepent = this.(weaponentity);
	if(!wepent || !IS_PLAYER(this))
		return "N/A";
	else if(wepent.m_weapon != WEP_Null)
		return wepent.m_weapon.m_name;
	else if(wepent.m_switchweapon != WEP_Null)
		return wepent.m_switchweapon.m_name;
	return "none"; //REGISTRY_GET(Weapons, wepent.cnt).m_name;
}

string AmmoNameFromWeaponentity(entity this, .entity weaponentity)
{
	entity wepent = this.(weaponentity);
	string fallback = "N/A";
	if(!wepent || !IS_PLAYER(this))
		return fallback;
	else if(wepent.m_weapon.ammo_type != RES_NONE)
		return wepent.m_weapon.ammo_type.m_name;
	else if(wepent.m_switchweapon.ammo_type != RES_NONE)
		return wepent.m_switchweapon.ammo_type.m_name;
	return fallback; // REGISTRY_GET(Weapons, wepent.cnt).ammo_type.m_name;
}

string formatmessage(entity this, string msg)
{
	float p, p1, p2;
	float n;
	vector cursor = '0 0 0';
	entity cursor_ent = NULL;
	string escape,escape_token;
	bool warn_slash = false;
	string replacement;
	p = 0;
	n = 7;
	bool traced = false;

	MUTATOR_CALLHOOK(PreFormatMessage, this, msg);
	msg = M_ARGV(1, string);

	while (1) {
		if (n < 1)
			break; // too many replacements

		n = n - 1;
		p1 = strstrofs(msg, "%", p); // NOTE: this destroys msg as it's a tempstring!
		p2 = strstrofs(msg, "\\", p); // NOTE: this destroys msg as it's a tempstring!

		if (p1 < 0)
			p1 = p2;

		if (p2 < 0)
			p2 = p1;

		p = min(p1, p2);

		if (p < 0)
			break;

		if(!traced)
		{
			WarpZone_crosshair_trace_plusvisibletriggers(this);
			cursor = trace_endpos;
			cursor_ent = trace_ent;
			traced = true;
		}

		replacement = substring(msg, p, 2);
		escape_token = substring(msg, p, 1);
		escape = substring(msg, p + 1, 1);

		.entity weaponentity = weaponentities[0]; // TODO: unhardcode

#define ON_SLASH() MACRO_BEGIN warn_slash = false; if(escape_token != "\\") break; MACRO_END
#define NO_SLASH() MACRO_BEGIN if(escape_token == "\\") break; MACRO_END
// TODO: remove warn_slash before next release (xonotic-v0.9.0)
// this is only to warn users of backslash expansions for anything other than '\%', '\\' and '\n'
		if(escape_token == "\\")
			warn_slash = true;
		else
			warn_slash = false;
		switch(escape)
		{
			case "%":             replacement = "%"; warn_slash = false; break;
			case "\\":ON_SLASH(); replacement = "\\"; break;
			case "n": ON_SLASH(); replacement = "\n"; break;
			case "a": NO_SLASH(); replacement = ftos(floor(GetResource(this, RES_ARMOR))); break;
			case "h": NO_SLASH(); replacement = PlayerHealth(this); break;
			case "l": NO_SLASH(); replacement = NearestLocation(this.origin); break;
			case "y": NO_SLASH(); replacement = NearestLocation(cursor); break;
			case "d": NO_SLASH(); replacement = NearestLocation(this.death_origin); break;
			case "o": NO_SLASH(); replacement = vtos(this.origin); break;
			case "O": NO_SLASH(); replacement = sprintf("'%f %f %f'", this.origin.x, this.origin.y, this.origin.z); break;
			case "w": NO_SLASH(); replacement = WeaponNameFromWeaponentity(this, weaponentity); break;
			case "W": NO_SLASH(); replacement = AmmoNameFromWeaponentity(this, weaponentity); break;
			case "x": NO_SLASH(); replacement = ((cursor_ent.netname == "" || !cursor_ent) ? "nothing" : cursor_ent.netname); break;
			case "s": NO_SLASH(); replacement = ftos(vlen(this.velocity - this.velocity_z * '0 0 1')); break;
			case "S": NO_SLASH(); replacement = ftos(vlen(this.velocity)); break;
			case "t": NO_SLASH(); replacement = seconds_tostring(ceil(max(0, autocvar_timelimit * 60 + game_starttime - time))); break;
			case "T": NO_SLASH(); replacement = seconds_tostring(floor(time - game_starttime)); break;
			default:
			{
				warn_slash = false; // too noisy
				NO_SLASH();
				MUTATOR_CALLHOOK(FormatMessage, this, escape, replacement, msg);
				replacement = M_ARGV(2, string);
				break;
			}
		}
#undef ON_SLASH
#undef NO_SLASH
		if(warn_slash)
			PrintToChat(this, sprintf("^3WARNING: unsupported \"\\%s\" expansion, use \"%%%s\"", escape, escape));
		msg = strcat(substring(msg, 0, p), replacement, substring(msg, p+2, strlen(msg) - (p+2)));
		p = p + strlen(replacement);
	}
	return msg;
}

ERASEABLE
void PrintToChat(entity client, string text)
{
	text = strcat("\{1}^7", text, "\n");
	sprint(client, text);
}

ERASEABLE
void DebugPrintToChat(entity client, string text)
{
	if (autocvar_developer > 0)
	{
		PrintToChat(client, text);
	}
}

ERASEABLE
void PrintToChatAll(string text)
{
	text = strcat("\{1}^7", text, "\n");
	bprint(text);
}

ERASEABLE
void DebugPrintToChatAll(string text)
{
	if (autocvar_developer > 0)
	{
		PrintToChatAll(text);
	}
}

ERASEABLE
void PrintToChatTeam(int team_num, string text)
{
	text = strcat("\{1}^7", text, "\n");
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		if (it.team == team_num)
		{
			sprint(it, text);
		}
	});
}

ERASEABLE
void DebugPrintToChatTeam(int team_num, string text)
{
	if (autocvar_developer > 0)
	{
		PrintToChatTeam(team_num, text);
	}
}
