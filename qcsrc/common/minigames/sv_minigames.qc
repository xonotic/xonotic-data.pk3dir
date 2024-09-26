#include "sv_minigames.qh"

#include <common/minigames/minigames.qh>
#include <server/gamelog.qh>

void player_clear_minigame(entity player)
{
	CS(player).active_minigame = NULL;
	player.minigame_players = NULL;
	if ( IS_PLAYER(player) )
		set_movetype(player, MOVETYPE_WALK);
	else
		set_movetype(player, MOVETYPE_FLY_WORLDONLY);
	Player_SetForcedTeamIndex(player, TEAM_FORCE_DEFAULT);
}

void minigame_rmplayer(entity minigame_session, entity player)
{
	entity e;
	entity p = minigame_session.minigame_players;

	if ( p.minigame_players == player )
	{
		if ( p.list_next == NULL )
		{
			end_minigame(minigame_session);
			return;
		}
		minigame_session.minigame_event(minigame_session,"part",player);
		GameLogEcho(strcat(":minigame:part:",minigame_session.netname,":",
			ftos(etof(player)),":",player.netname));
		minigame_session.minigame_players = p.list_next;
		delete( p );
		player_clear_minigame(player);
	}
	else
	{
		for ( e = p.list_next; e != NULL; e = e.list_next )
		{
			if ( e.minigame_players == player )
			{
				minigame_session.minigame_event(minigame_session,"part",player);
				GameLogEcho(strcat(":minigame:part:",minigame_session.netname,":",
					ftos(etof(player)),":",player.netname));
				p.list_next = e.list_next;
				delete(e);
				player_clear_minigame(player);
				return;
			}
			p = e;
		}
	}
}


#define FIELD(Flags, Type,Name) if ( sf & (Flags) ) Write##Type(MSG_ENTITY, this.Name);
#define MSLE(Name,Fields) \
	else if ( this.classname == #Name ) { \
		if ( sf & MINIG_SF_CREATE ) WriteString(MSG_ENTITY,this.owner.netname); \
		Fields }

// Send an entity to a client
// only use on minigame entities or entities with a minigame owner
bool minigame_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_MINIGAME);
	WriteByte(MSG_ENTITY, sf);

	if ( sf & MINIG_SF_CREATE )
	{
		WriteShort(MSG_ENTITY,msle_id(this.classname));
		WriteString(MSG_ENTITY,this.netname);
	}

	entity minigame_ent = this.owner;

	if ( this.classname == "minigame" )
	{
		minigame_ent = this;

		if ( sf & MINIG_SF_CREATE )
			WriteString(MSG_ENTITY,this.descriptor.netname);

		if ( sf & MINIG_SF_UPDATE )
			WriteLong(MSG_ENTITY,this.minigame_flags);
	}
	else if ( this.classname == "minigame_player" )
	{
		if ( sf & MINIG_SF_CREATE )
		{
			WriteString(MSG_ENTITY,this.owner.netname);
			WriteLong(MSG_ENTITY,etof(this.minigame_players));
		}
		if ( sf & MINIG_SF_UPDATE )
			WriteByte(MSG_ENTITY,this.team);
	}
	MINIGAME_SIMPLELINKED_ENTITIES

	minigame_ent.minigame_event(minigame_ent,"network_send",this,sf);

	return true;

}
#undef FIELD
#undef MSLE

// Force resend all minigame entities
void minigame_resend(entity minigame)
{
	minigame.SendFlags = MINIG_SF_ALL;
	entity e = NULL;
	while (( e = findentity(e,owner,minigame) ))
	{
		e.SendFlags = MINIG_SF_ALL;
	}
}

bool minigame_CheckSend(entity this, entity client)
{
	entity e;
	for ( e = this.owner.minigame_players; e != NULL; e = e.list_next )
		if ( e.minigame_players == client )
			return true;
	return false;
}

int minigame_addplayer(entity minigame_session, entity player)
{
	if ( CS(player).active_minigame )
	{
		if ( CS(player).active_minigame == minigame_session )
			return 0;
		minigame_rmplayer(CS(player).active_minigame,player);
	}
	entity player_pointer = new(minigame_player);
	int mgteam = minigame_session.minigame_event(minigame_session,"join",player,player_pointer);

	if ( mgteam )
	{
		player_pointer.owner = minigame_session;
		player_pointer.minigame_players = player;
		player_pointer.team = mgteam;
		player_pointer.list_next = minigame_session.minigame_players;
		minigame_session.minigame_players = player_pointer;
		CS(player).active_minigame = minigame_session;
		player.minigame_players = player_pointer;
		setcefc(player_pointer, minigame_CheckSend);
		Net_LinkEntity(player_pointer, false, 0, minigame_SendEntity);

		if ( !IS_OBSERVER(player) && autocvar_sv_minigames_observer )
			PutObserverInServer(player, true, true);
		if ( autocvar_sv_minigames_observer == 2 )
			Player_SetForcedTeamIndex(player, TEAM_FORCE_SPECTATOR);

		minigame_resend(minigame_session);
	}
	else { delete(player_pointer); }
	GameLogEcho(strcat(":minigame:join",(mgteam?"":"fail"),":",minigame_session.netname,":",
		ftos(etof(player)),":",player.netname));

	return mgteam;
}

entity start_minigame(entity player, string minigame )
{
	if ( !autocvar_sv_minigames || !IS_REAL_CLIENT(player) )
		return NULL;

	entity e = minigame_get_descriptor(minigame);
	if ( e )
	{
		entity minig = new(minigame);
		minig.netname = strzone(strcat(e.netname,"_",ftos(etof(minig))));
		minig.descriptor = e;
		minig.minigame_event = e.minigame_event;
		minig.minigame_event(minig,"start");
		GameLogEcho(strcat(":minigame:start:",minig.netname));
		if ( ! minigame_addplayer(minig,player) )
		{
			LOG_TRACE("Minigame ",minig.netname," rejected the first player join!");
			end_minigame(minig);
			return NULL;
		}
		Net_LinkEntity(minig, false, 0, minigame_SendEntity);

		if ( !minigame_sessions )
			minigame_sessions = minig;
		else
		{
			minigame_sessions.owner = minig;
			minig.list_next = minigame_sessions;
			minigame_sessions = minig;
		}
		return minig;
	}

	return NULL;
}

entity join_minigame(entity player, string game_id )
{
	if ( !autocvar_sv_minigames || !IS_REAL_CLIENT(player) )
		return NULL;

	entity minig;
	for ( minig = minigame_sessions; minig != NULL; minig = minig.list_next )
	{
		if ( minig.netname == game_id )
		if ( minigame_addplayer(minig,player) )
			return minig;
	}

	return NULL;
}

void part_minigame(entity player)
{
	entity minig = CS(player).active_minigame;

	if ( minig && minig.classname == "minigame" )
		minigame_rmplayer(minig,player);
}

void end_minigame(entity minigame_session)
{
	if ( minigame_session.owner )
		minigame_session.owner.list_next = minigame_session.list_next;
	else
		minigame_sessions = minigame_session.list_next;

	minigame_session.minigame_event(minigame_session,"end");
	GameLogEcho(strcat(":minigame:end:",minigame_session.netname));


	entity e = NULL;
	while( (e = findentity(e, owner, minigame_session)) )
		if ( e.minigame_autoclean )
		{
			LOG_TRACE("SV Auto-cleaned: ",ftos(etof(e)), " (",e.classname,")");
			delete(e);
		}

	entity p;
	for ( e = minigame_session.minigame_players; e != NULL; e = p )
	{
		p = e.list_next;
		player_clear_minigame(e.minigame_players);
		delete(e);
	}

	strfree(minigame_session.netname);
	delete(minigame_session);
}

void end_minigames()
{
	while ( minigame_sessions )
	{
		end_minigame(minigame_sessions);
	}
}

string invite_minigame(entity inviter, entity player)
{
	if ( !inviter || !CS(inviter).active_minigame )
		return "Invalid minigame";
	if ( VerifyClientEntity(player, true, false) <= 0 )
		return "Invalid player";
	if ( inviter == player )
		return "You can't invite yourself";
	if (autocvar_g_playban_minigames && PlayerInList(player, autocvar_g_playban_list)) // playban
		return "You can't invite a banned player";
	if ( CS(player).active_minigame == CS(inviter).active_minigame )
		return strcat(player.netname," is already playing");

	Send_Notification(NOTIF_ONE, player, MSG_INFO, INFO_MINIGAME_INVITE,
		CS(inviter).active_minigame.netname, inviter.netname );

	GameLogEcho(strcat(":minigame:invite:",CS(inviter).active_minigame.netname,":",
		ftos(etof(player)),":",player.netname));

	return "";
}

entity minigame_find_player(entity client)
{
	if ( ! CS(client).active_minigame )
		return NULL;
	entity e;
	for ( e = CS(client).active_minigame.minigame_players; e; e = e.list_next )
		if ( e.minigame_players == client )
			return e;
	return NULL;
}

bool MinigameImpulse(entity this, int imp)
{
	if (!CS(this).active_minigame) return false;
	entity e = minigame_find_player(this);
	if ( imp && CS(this).active_minigame && e )
	{
		return CS(this).active_minigame.minigame_event(CS(this).active_minigame,"impulse",e,imp);
	}
	return false;
}

// this macro exists only to shorten code lines
#define MINIGAME_CMD(cmd_id) MINIGAME_COMMON_CMD[MINIGAME_COMMON_CMD_ID_##cmd_id]

void ClientCommand_minigame(entity caller, int request, int argc, string command)
{
	if ( !autocvar_sv_minigames )
	{
		sprint(caller,"Minigames are not enabled!\n");
		return;
	}

	if (autocvar_g_playban_minigames && PlayerInList(caller, autocvar_g_playban_list)) // playban
	{
		Send_Notification(NOTIF_ONE_ONLY, caller, MSG_CENTER, CENTER_JOIN_PLAYBAN);
		sprint(caller, "You aren't allowed to play minigames because you are banned from them in this server.\n");
		return;
	}

	if (request == CMD_REQUEST_COMMAND )
	{
		string minig_cmd = argv(1);
		if ( minig_cmd == MINIGAME_CMD(CREATE) && argc > 2 )
		{
			entity minig = start_minigame(caller, argv(2));
			if ( minig )
				sprint(caller,"Created minigame session: ",minig.netname,"\n");
			else
				sprint(caller,"Cannot start minigame session!\n");
			return;
		}
		else if ( minig_cmd == MINIGAME_CMD(JOIN) && argc > 2 )
		{
			entity minig = join_minigame(caller, argv(2));
			if ( minig )
				sprint(caller,"Joined: ",minig.netname,"\n");
			else
			{
				Send_Notification(NOTIF_ONE, caller, MSG_CENTER, CENTER_JOIN_PREVENT_MINIGAME);
				sprint(caller,"Cannot join given minigame session!\n");
			}
			return;
		}
		else if ( minig_cmd == MINIGAME_CMD(LIST) )
		{
			FOREACH(Minigames, true, sprint(caller, it.netname, " (", it.message, ") ", "\n"));
			return;
		}
		else if ( minig_cmd == MINIGAME_CMD(LIST_SESSIONS) )
		{
			entity e;
			for ( e = minigame_sessions; e != NULL; e = e.list_next )
				sprint(caller,e.netname,"\n");
			return;
		}
		else if ( minig_cmd == MINIGAME_CMD(END) || minig_cmd == MINIGAME_CMD(PART) )
		{
			if ( CS(caller).active_minigame )
			{
				part_minigame(caller);
				sprint(caller,"Left minigame session\n");
			}
			else
				sprint(caller,"You aren't playing any minigame...\n");
			return;
		}
		else if ( minig_cmd == MINIGAME_CMD(INVITE) && argc > 2 )
		{
			if ( CS(caller).active_minigame )
			{
				entity client = GetIndexedEntity(argc, 2);
				string error = invite_minigame(caller,client);
				if ( error == "" )
				{
					sprint(caller,"You have invited ",client.netname,
						" to join your game of ", CS(caller).active_minigame.descriptor.message, "\n");
				}
				else
					sprint(caller,"Could not invite: ", error, ".\n");
			}
			else
				sprint(caller,"You aren't playing any minigame...\n");
			return;
		}
		else if ( CS(caller).active_minigame )
		{
			entity e = minigame_find_player(caller);
			string subcommand = substring(command,argv_end_index(0),-1);
			int arg_c = tokenize_console(subcommand);
			if ( CS(caller).active_minigame.minigame_event(CS(caller).active_minigame,"cmd",e,arg_c,subcommand) )
				return;

		}
		else sprint(caller,strcat("Wrong command:^1 ",command,"\n"));
	}

	sprint(caller, "\nUsage:^3 cmd minigame create <minigame>\n");
	sprint(caller, "  Start a new minigame session\n");
	sprint(caller, "Usage:^3 cmd minigame join <session>\n");
	sprint(caller, "  Join an exising minigame session\n");
	sprint(caller, "Usage:^3 cmd minigame list\n");
	sprint(caller, "  List available minigames\n");
	sprint(caller, "Usage:^3 cmd minigame list-sessions\n");
	sprint(caller, "  List available minigames sessions\n");
	sprint(caller, "Usage:^3 cmd minigame part|end\n");
	sprint(caller, "  Leave the current minigame\n");
	sprint(caller, "Usage:^3 cmd minigame invite <player>\n");
	sprint(caller, "  Invite the given player to join you in a minigame\n");
}
