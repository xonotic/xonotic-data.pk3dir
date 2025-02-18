#include "ttt.qh"
REGISTER_MINIGAME(ttt, _("Tic Tac Toe"));

const int TTT_TURN_PLACE = 0x0100; // player has to place a piece on the board
const int TTT_TURN_WIN   = 0x0200; // player has won
const int TTT_TURN_DRAW  = 0x0400; // no moves are possible
const int TTT_TURN_NEXT  = 0x0800; // a player wants to start a new match
const int TTT_TURN_TYPE  = 0x0f00; // turn type mask

const int TTT_TURN_TEAM1 = 0x0001;
const int TTT_TURN_TEAM2 = 0x0002;
const int TTT_TURN_TEAM  = 0x000f; // turn team mask

// send flags
const int TTT_SF_PLAYERSCORE  = MINIG_SF_CUSTOM;   // send minigame_player scores (won matches)
const int TTT_SF_SINGLEPLAYER = MINIG_SF_CUSTOM<<1;// send minigame.ttt_ai

const int TTT_SPECTATOR_TEAM = 255; // must be above max teams and equal to or below 255

const int TTT_LET_CNT = 3;
const int TTT_NUM_CNT = 3;
const int TTT_TILE_SIZE = 3;

.int ttt_npieces; // (minigame) number of pieces on the board (simplifies checking a draw)
.int ttt_nexteam; // (minigame) next team (used to change the starting team on following matches)
.int ttt_ai;      // (minigame) when non-zero, singleplayer vs AI

// find tic tac toe piece given its tile name
entity ttt_find_piece(entity minig, string tile)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return NULL;
}

// Checks if the given piece completes a row
bool ttt_winning_piece(entity piece)
{
	int number = minigame_tile_number(piece.netname);
	int letter = minigame_tile_letter(piece.netname);

	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(0,number)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(1,number)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(2,number)).team == piece.team )
		return true;

	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(letter,0)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(letter,1)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(letter,2)).team == piece.team )
		return true;

	if ( number == letter )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(0,0)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(1,1)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(2,2)).team == piece.team )
		return true;

	if ( number == 2-letter )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(0,2)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(1,1)).team == piece.team )
	if ( ttt_find_piece(piece.owner,minigame_tile_buildname(2,0)).team == piece.team )
		return true;

	return false;
}

// check if the tile name is valid (3x3 grid)
bool ttt_valid_tile(string tile)
{
	if ( !tile )
		return 0;
	int number = minigame_tile_number(tile);
	int letter = minigame_tile_letter(tile);
	return 0 <= number && number < TTT_NUM_CNT && 0 <= letter && letter < TTT_LET_CNT;
}

// make a move
void ttt_move(entity minigame, entity player, string pos )
{
	if ( minigame.minigame_flags & TTT_TURN_PLACE )
	if ( pos && player.team == (minigame.minigame_flags & TTT_TURN_TEAM) )
	{
		if ( ttt_valid_tile(pos) )
		if ( !ttt_find_piece(minigame,pos) )
		{
			entity piece = msle_spawn(minigame,new(minigame_board_piece));
			piece.team = player.team;
			piece.netname = strzone(pos);
			minigame_server_sendflags(piece,MINIG_SF_ALL);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
			minigame.ttt_npieces++;
			minigame.ttt_nexteam = minigame_next_team(player.team,2);
			if ( ttt_winning_piece(piece) )
			{
				player.minigame_flags++;
				minigame_server_sendflags(player, TTT_SF_PLAYERSCORE);
				minigame.minigame_flags = TTT_TURN_WIN | player.team;
			}
			else if ( minigame.ttt_npieces >= (TTT_LET_CNT * TTT_NUM_CNT) )
				minigame.minigame_flags = TTT_TURN_DRAW;
			else
				minigame.minigame_flags = TTT_TURN_PLACE | minigame.ttt_nexteam;
		}
	}
}

// request a new match
void ttt_next_match(entity minigame, entity player)
{
#ifdef SVQC
	// on multiplayer matches, wait for both players to agree
	if ( minigame.minigame_flags & (TTT_TURN_WIN|TTT_TURN_DRAW) )
	{
		minigame.minigame_flags = TTT_TURN_NEXT | player.team;
		minigame.SendFlags |= MINIG_SF_UPDATE;
	}
	else if ( (minigame.minigame_flags & TTT_TURN_NEXT) &&
			!( minigame.minigame_flags & player.team ) )
#endif
	{
		minigame.minigame_flags = TTT_TURN_PLACE | minigame.ttt_nexteam;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		minigame.ttt_npieces = 0;
		entity e = NULL;
		while ( ( e = findentity(e,owner,minigame) ) )
			if ( e.classname == "minigame_board_piece" )
				delete(e);
	}
}

#ifdef SVQC


// required function, handle server side events
int ttt_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			minigame.minigame_flags = (TTT_TURN_PLACE | TTT_TURN_TEAM1);
			return true;
		}
		case "end":
		{
			entity e = NULL;
			while( (e = findentity(e, owner, minigame)) )
			if(e.classname == "minigame_board_piece")
			{
				strfree(e.netname);
				delete(e);
			}
			return false;
		}
		case "join":
		{
			int pl_num = minigame_count_players(minigame);

			// Don't allow joining a single player match
			if ( (minigame.ttt_ai) && pl_num > 0 )
				return false;

			// Don't allow more than 2 players
			if(pl_num >= 2) { return TTT_SPECTATOR_TEAM; }

			// Get the right team
			if(minigame.minigame_players)
				return minigame_next_team(minigame.minigame_players.team, 2);

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			entity player = ...(0,entity);
			bool event_blocked = (player.team == TTT_SPECTATOR_TEAM);
			switch(argv(0))
			{
				case "move":
					if(event_blocked)
						return true;
					ttt_move(minigame, ...(0,entity), ...(1,int) == 2 ? argv(1) : string_null );
					return true;
				case "next":
					if(event_blocked)
						return true;
					ttt_next_match(minigame,...(0,entity));
					return true;
				case "singleplayer":
					if(event_blocked)
						return true;
					if ( minigame_count_players(minigame) == 1 )
					{
						minigame.ttt_ai = minigame_next_team(minigame.minigame_players.team, 2);
						minigame.SendFlags = TTT_SF_SINGLEPLAYER;
					}
					return true;
			}

			return false;
		}
		case "network_send":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_player" && (sf & TTT_SF_PLAYERSCORE ) )
			{
				WriteByte(MSG_ENTITY,sent.minigame_flags);
			}
			else if ( sent.classname == "minigame" && (sf & TTT_SF_SINGLEPLAYER) )
			{
				WriteByte(MSG_ENTITY,sent.ttt_ai);
			}
			return false;
		}
	}

	return false;
}


#elif defined(CSQC)

string ttt_curr_pos; // identifier of the tile under the mouse
vector ttt_boardpos; // HUD board position
vector ttt_boardsize;// HUD board size
.int ttt_checkwin; // Used to optimize checks to display a win

// Required function, draw the game board
void ttt_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	ttt_boardpos = pos;
	ttt_boardsize = mySize;

	minigame_hud_simpleboard(pos,mySize,minigame_texture("ttt/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0'/TTT_TILE_SIZE,pos,mySize);
	vector tile_pos;

	if ( (active_minigame.minigame_flags & TTT_TURN_TEAM) == minigame_self.team )
	if ( ttt_valid_tile(ttt_curr_pos) )
	{
		tile_pos = minigame_tile_pos(ttt_curr_pos,TTT_LET_CNT,TTT_NUM_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
		minigame_drawpic_centered( tile_pos,
				minigame_texture(strcat("ttt/piece",ftos(minigame_self.team))),
				tile_size, '1 1 1', panel_fg_alpha/2, DRAWFLAG_NORMAL );
	}

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,TTT_LET_CNT,TTT_NUM_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			if ( active_minigame.minigame_flags & TTT_TURN_WIN )
			if ( !e.ttt_checkwin )
				e.ttt_checkwin = ttt_winning_piece(e) ? 1 : -1;

			float icon_color = 1;
			if ( e.ttt_checkwin == -1 )
				icon_color = 0.4;
			else if ( e.ttt_checkwin == 1 )
			{
				icon_color = 2;
				minigame_drawpic_centered( tile_pos, minigame_texture("ttt/winglow"),
						tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_ADDITIVE );
			}

			minigame_drawpic_centered( tile_pos,
					minigame_texture(strcat("ttt/piece",ftos(e.team))),
					tile_size, '1 1 1'*icon_color, panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	minigame_show_allspecs(ttt_boardpos, ttt_boardsize);
}


// Required function, draw the game status panel
void ttt_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg();
	vector ts;
	ts = minigame_drawstring_wrapped(mySize_x,pos,active_minigame.descriptor.message,
		hud_fontsize * 2, '0.25 0.47 0.72', panel_fg_alpha, DRAWFLAG_NORMAL,0.5);

	pos_y += ts_y;
	mySize_y -= ts_y;

	vector player_fontsize = hud_fontsize * 1.75;
	ts_y = ( mySize_y - 2*player_fontsize_y ) / 2;
	ts_x = mySize_x;
	vector mypos;
	vector tile_size = '48 48 0';

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" && e.team != TTT_SPECTATOR_TEAM )
		{
			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				(e.minigame_playerslot ? entcs_GetName(e.minigame_playerslot-1) : _("AI")),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			drawpic( mypos,
					minigame_texture(strcat("ttt/piece",ftos(e.team))),
					tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );

			mypos_x += tile_size_x;

			drawstring(mypos,ftos(e.minigame_flags),tile_size,
					'0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string ttt_turn_to_string(int turnflags)
{
	if(minigame_self.team == TTT_SPECTATOR_TEAM)
		return _("You are spectating");

	if ( turnflags & TTT_TURN_DRAW )
		return _("Draw");

	if ( turnflags & TTT_TURN_WIN )
	{
		// translator-friendly messages composed of 2 existing messages
		// TODO: proper "you win" banner instead of hijacking the help message
		if ( (turnflags & TTT_TURN_TEAM) != minigame_self.team )
			return strcat(_("You lost the game!"), "\n", _("Select \"^1Next Match^7\" on the menu for a rematch!"));
		return strcat(_("You win!"), "\n", _("Select \"^1Next Match^7\" on the menu to start a new match!"));
	}

	if ( turnflags & TTT_TURN_NEXT )
	{
		if ( (turnflags & TTT_TURN_TEAM) != minigame_self.team )
			return _("Select \"^1Next Match^7\" on the menu to start a new match!");
		return _("Wait for your opponent to confirm the rematch");
	}

	if ( (turnflags & TTT_TURN_TEAM) != minigame_self.team )
		return _("Wait for your opponent to make their move");

	if ( turnflags & TTT_TURN_PLACE )
		return _("Click on the game board to place your piece");

	return "";
}

const int TTT_AI_POSFLAG_A1 = 0x0001;
const int TTT_AI_POSFLAG_A2 = 0x0002;
const int TTT_AI_POSFLAG_A3 = 0x0004;
const int TTT_AI_POSFLAG_B1 = 0x0008;
const int TTT_AI_POSFLAG_B2 = 0x0010;
const int TTT_AI_POSFLAG_B3 = 0x0020;
const int TTT_AI_POSFLAG_C1 = 0x0040;
const int TTT_AI_POSFLAG_C2 = 0x0080;
const int TTT_AI_POSFLAG_C3 = 0x0100;

// convert a flag to a position
string ttt_ai_piece_flag2pos(int pieceflag)
{
	switch(pieceflag)
	{
		case TTT_AI_POSFLAG_A1:
			return "a1";
		case TTT_AI_POSFLAG_A2:
			return "a2";
		case TTT_AI_POSFLAG_A3:
			return "a3";

		case TTT_AI_POSFLAG_B1:
			return "b1";
		case TTT_AI_POSFLAG_B2:
			return "b2";
		case TTT_AI_POSFLAG_B3:
			return "b3";

		case TTT_AI_POSFLAG_C1:
			return "c1";
		case TTT_AI_POSFLAG_C2:
			return "c2";
		case TTT_AI_POSFLAG_C3:
			return "c3";

		default:
			return string_null;
	}
}

bool ttt_ai_checkmask(int piecemask, int checkflags)
{
	return checkflags && (piecemask & checkflags) == checkflags;
}

// get the third flag if the mask matches two of them
int ttt_ai_1of3(int piecemask, int flag1, int flag2, int flag3)
{
	if ( ttt_ai_checkmask(piecemask,flag1|flag2|flag3) )
		return 0;

	if ( ttt_ai_checkmask(piecemask,flag1|flag2) )
		return flag3;

	if ( ttt_ai_checkmask(piecemask,flag3|flag2) )
		return flag1;

	if ( ttt_ai_checkmask(piecemask,flag3|flag1) )
		return flag2;

	return 0;
}

// Select a random flag in the mask
int ttt_ai_random(int piecemask)
{
	if ( !piecemask )
		return 0;

	int f = 1;

	RandomSelection_Init();

	for ( int i = 0; i < 9; ++i )
	{
		if ( piecemask & f )
			RandomSelection_AddFloat(f, 1, 1);
		f <<= 1;
	}

	LOG_TRACE(sprintf("TTT AI: selected %x from %x",
			RandomSelection_chosen_float, piecemask) );
	return RandomSelection_chosen_float;
}

// Block/complete a 3 i na row
int ttt_ai_block3 ( int piecemask, int piecemask_free )
{
	int r = 0;

	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A1,TTT_AI_POSFLAG_A2,TTT_AI_POSFLAG_A3);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_B1,TTT_AI_POSFLAG_B2,TTT_AI_POSFLAG_B3);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_C1,TTT_AI_POSFLAG_C2,TTT_AI_POSFLAG_C3);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A1,TTT_AI_POSFLAG_B1,TTT_AI_POSFLAG_C1);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A2,TTT_AI_POSFLAG_B2,TTT_AI_POSFLAG_C2);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A3,TTT_AI_POSFLAG_B3,TTT_AI_POSFLAG_C3);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A1,TTT_AI_POSFLAG_B2,TTT_AI_POSFLAG_C3);
	r |= ttt_ai_1of3(piecemask,TTT_AI_POSFLAG_A3,TTT_AI_POSFLAG_B2,TTT_AI_POSFLAG_C1);
	LOG_TRACE(sprintf("TTT AI: possible 3 in a rows in %x: %x (%x)",piecemask,r, r&piecemask_free));
	r &= piecemask_free;
	return ttt_ai_random(r);
}

// Simple AI
// 1) tries to win the game if possible
// 2) tries to block the opponent if they have 2 in a row
// 3) places a piece randomly
string ttt_ai_choose_simple(int piecemask_self, int piecemask_opponent, int piecemask_free )
{
	int move = 0;

	LOG_TRACE("TTT AI: checking winning move");
	if (( move = ttt_ai_block3(piecemask_self,piecemask_free) ))
		return ttt_ai_piece_flag2pos(move); // place winning move

	LOG_TRACE("TTT AI: checking opponent's winning move");
	if (( move = ttt_ai_block3(piecemask_opponent,piecemask_free) ))
		return ttt_ai_piece_flag2pos(move); // block opponent

	LOG_TRACE("TTT AI: random move");
	return ttt_ai_piece_flag2pos(ttt_ai_random(piecemask_free));
}

// AI move (if it's AI's turn)
void ttt_aimove(entity minigame)
{
	if ( minigame.minigame_flags == (TTT_TURN_PLACE|minigame.ttt_ai) )
	{
		entity aiplayer = NULL;
		while ( ( aiplayer = findentity(aiplayer,owner,minigame) ) )
			if ( aiplayer.classname == "minigame_player" && !aiplayer.minigame_playerslot )
				break;

		/*
		 * Build bit masks for the board pieces
		 * .---.---.---.
		 * | 4 | 32|256| 3
		 * |---+---+---|
		 * | 2 | 16|128| 2
		 * |---+---+---|
		 * | 1 | 8 | 64| 1
		 * '---'---'---'
		 *   A   B   C
		 */
		int piecemask_self = 0;
		int piecemask_opponent = 0;
		int piecemask_free = 0;
		int pieceflag = 1;
		string pos;
		for ( int i = 0; i < 3; ++i )
		{
			for ( int j = 0; j < 3; ++j )
			{
				pos = minigame_tile_buildname(i,j);
				entity piece = ttt_find_piece(minigame,pos);
				if ( piece )
				{
					if ( piece.team == aiplayer.team )
						piecemask_self |= pieceflag;
					else
						piecemask_opponent |= pieceflag;
				}
				else
					piecemask_free |= pieceflag;
				pieceflag <<= 1;
			}
		}

		// TODO multiple AI difficulties
		LOG_TRACE(sprintf("TTT AI: self: %x opponent: %x free: %x",
				piecemask_self, piecemask_opponent, piecemask_free));
		pos = ttt_ai_choose_simple(piecemask_self, piecemask_opponent, piecemask_free);
		LOG_TRACE("TTT AI: chosen move: ", pos);
		if ( !pos )
			LOG_TRACE("Tic Tac Toe AI has derped!");
		else
			ttt_move(minigame,aiplayer,pos);
	}
	strcpy(minigame.message, ttt_turn_to_string(minigame.minigame_flags));
}

// Make the correct move
void ttt_make_move(entity minigame)
{
	if ( minigame.minigame_flags == (TTT_TURN_PLACE|minigame_self.team) )
	{
		if ( minigame.ttt_ai  )
		{
			ttt_move(minigame, minigame_self, ttt_curr_pos );
			ttt_aimove(minigame);
		}
		else
			minigame_cmd("move ",ttt_curr_pos);
	}
}

void ttt_set_curr_pos(string s)
{
	strfree(ttt_curr_pos);
	if ( s )
		s = strzone(s);
	ttt_curr_pos = s;
}

// Required function, handle client events
int ttt_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			ttt_set_curr_pos("");
			strcpy(minigame.message, ttt_turn_to_string(minigame.minigame_flags));
			return false;
		}
		case "deactivate":
		{
			strfree(minigame.message);
			return false;
		}
		case "key_pressed":
		case "key_released":
		{
			bool event_blocked = ((event == "key_released")
				|| ((minigame.minigame_flags & TTT_TURN_TEAM) != minigame_self.team));
			if (!(minigame.minigame_flags & (TTT_TURN_WIN | TTT_TURN_DRAW)))
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if (event_blocked)
							return true;
						if ( ! ttt_curr_pos )
							ttt_set_curr_pos("a3");
						else
							ttt_set_curr_pos(minigame_relative_tile(ttt_curr_pos,1,0,TTT_LET_CNT,TTT_NUM_CNT));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if (event_blocked)
							return true;
						if ( ! ttt_curr_pos )
							ttt_set_curr_pos("c3");
						else
							ttt_set_curr_pos(minigame_relative_tile(ttt_curr_pos,-1,0,TTT_LET_CNT,TTT_NUM_CNT));
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						if (event_blocked)
							return true;
						if ( ! ttt_curr_pos )
							ttt_set_curr_pos("a1");
						else
							ttt_set_curr_pos(minigame_relative_tile(ttt_curr_pos,0,1,TTT_LET_CNT,TTT_NUM_CNT));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if (event_blocked)
							return true;
						if ( ! ttt_curr_pos )
							ttt_set_curr_pos("a3");
						else
							ttt_set_curr_pos(minigame_relative_tile(ttt_curr_pos,0,-1,TTT_LET_CNT,TTT_NUM_CNT));
						return true;
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						if (event_blocked)
							return true;
						ttt_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,int) == K_MOUSE1)
			{
				ttt_client_event(minigame, "mouse_moved");
				ttt_make_move(minigame);
				return true;
			}

			return false;
		}
		case "mouse_moved":
		{
			vector mouse_pos = minigame_hud_normalize(mousepos,ttt_boardpos,ttt_boardsize);
			if ( minigame.minigame_flags == (TTT_TURN_PLACE|minigame_self.team) )
				ttt_set_curr_pos(minigame_tile_name(mouse_pos,TTT_LET_CNT,TTT_NUM_CNT));
			if ( ! ttt_valid_tile(ttt_curr_pos) )
				ttt_set_curr_pos("");

			return true;
		}
		case "network_receive":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame" )
			{
				if ( sf & MINIG_SF_UPDATE )
				{
					strcpy(sent.message, ttt_turn_to_string(sent.minigame_flags));
					if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
				}

				if ( (sf & TTT_SF_SINGLEPLAYER) )
				{
					int ai = ReadByte();
					bool spawnai = ai && !sent.ttt_ai;
					sent.ttt_ai = ai;

					if ( spawnai )
					{
						entity aiplayer = new(minigame_player);
						aiplayer.owner = minigame;
						aiplayer.team = ai;
						aiplayer.minigame_playerslot = 0;
						aiplayer.minigame_autoclean = 1;
						ttt_aimove(minigame);
					}

				}
			}
			else if ( sent.classname == "minigame_player" && (sf & TTT_SF_PLAYERSCORE ) )
			{
				sent.minigame_flags = ReadByte();
			}

			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Next Match"),"next");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Single Player"),"singleplayer");
			return false;
		}
		case "menu_click":
		{
			if(...(0,string) == "next")
			{
				if ( minigame.ttt_ai )
				{
					ttt_next_match(minigame,minigame_self);
					ttt_aimove(minigame);
				}
				else
					minigame_cmd("next");
			}
			else if ( ...(0,string) == "singleplayer" && !minigame.ttt_ai )
			{
				if ( minigame_count_players(minigame) == 1 )
					minigame_cmd("singleplayer");
			}
			return false;
		}
	}

	return false;
}

#endif
