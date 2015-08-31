const float QTO_TURN_MOVE  = 0x0100; // player has to click on a piece on the board
const float QTO_TURN_WIN   = 0x0200; // player has won
const float QTO_TURN_TYPE  = 0x0f00; // turn type mask

const int QTO_SF_PLAYERSCORE = MINIG_SF_CUSTOM;

const int QTO_LET_CNT = 5;
const int QTO_NUM_CNT = 5;

const int QTO_TILE_SIZE = 8;

.int qto_moves;

// find same game piece given its tile name
entity qto_find_piece(entity minig, string tile)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return world;
}

// Checks if the given piece completes a row
bool qto_winning_piece(entity minigame)
{
	//int number = minigame_tile_number(piece.netname);
	//int letter = minigame_tile_letter(piece.netname);

	entity e = world;
	while ( ( e = findentity(e,owner,minigame) ) )
		if ( e.classname == "minigame_board_piece" )
		{
			if(!e.cnt)
				return false;
		}
	
	return true;
}

// check if the tile name is valid (5x5 grid)
bool qto_valid_tile(string tile)
{
	if ( !tile )
		return false;
	float number = minigame_tile_number(tile);
	float letter = minigame_tile_letter(tile);
	return 0 <= number && number < QTO_NUM_CNT && 0 <= letter && letter < QTO_LET_CNT;
}

void qto_setup_pieces(entity minigame)
{
	int i, t;
	for(i = 0; i < QTO_NUM_CNT; ++i)
	for(t = 0; t < QTO_LET_CNT; ++t)
	{
		entity piece = msle_spawn(minigame,"minigame_board_piece");
		piece.team = 1; // init default team?
		piece.cnt = 0; // initialize cnt
		piece.netname = strzone(minigame_tile_buildname(t,i));
		minigame_server_sendflags(piece,MINIG_SF_ALL);
	}

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
}

void qto_add_score(entity minigame, int thescore)
{
#ifdef SVQC
	if(!minigame)
		return;
	if(minigame.minigame_players)
	{
		minigame.minigame_players.qto_moves += thescore;
		minigame.minigame_players.SendFlags |= QTO_SF_PLAYERSCORE;
	}
#endif
}

// make a move
void qto_move(entity minigame, entity player, string pos )
{
	if ( minigame.minigame_flags & QTO_TURN_MOVE )
	if ( pos )
	{
		if ( qto_valid_tile(pos) )
		if ( qto_find_piece(minigame, pos) )
		{
			entity piece;
		#define DO_JUNK \
			if(piece) \
			{ \
				piece.cnt = (piece.cnt) ? 0 : 1; \
				minigame_server_sendflags(piece,MINIG_SF_UPDATE); \
			}

			int number = minigame_tile_number(pos);
			int letter = minigame_tile_letter(pos);
			piece = qto_find_piece(minigame, pos);
			DO_JUNK
			piece = qto_find_piece(minigame, minigame_tile_buildname(letter-1,number));
			DO_JUNK
			piece = qto_find_piece(minigame, minigame_tile_buildname(letter+1,number));
			DO_JUNK
			piece = qto_find_piece(minigame, minigame_tile_buildname(letter,number-1));
			DO_JUNK
			piece = qto_find_piece(minigame, minigame_tile_buildname(letter,number+1));
			DO_JUNK

			qto_add_score(minigame,1); // add 1 move score

			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

			if ( qto_winning_piece(minigame) )
			{
				minigame.minigame_flags = QTO_TURN_WIN;
			}
			else
				minigame.minigame_flags = QTO_TURN_MOVE;
		}
	}
}

// restart match
void qto_restart_match(entity minigame, entity player)
{
	minigame.minigame_flags = QTO_TURN_MOVE;
	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
	entity e = world;
	while ( ( e = findentity(e,owner,minigame) ) )
		if ( e.classname == "minigame_board_piece" )
			remove(e);

	qto_setup_pieces(minigame);
#ifdef SVQC
	if(minigame.minigame_players)
	{
		minigame.minigame_players.qto_moves = 0;
		minigame.minigame_players.SendFlags |= QTO_SF_PLAYERSCORE;
	}
#endif
}

#ifdef SVQC


// required function, handle server side events
int qto_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			qto_setup_pieces(minigame);
			minigame.minigame_flags = QTO_TURN_MOVE;
			return true;
		}
		case "end":
		{
			entity e = world;
			while( (e = findentity(e, owner, minigame)) )
			if(e.classname == "minigame_board_piece")
			{
				if(e.netname) { strunzone(e.netname); }
				remove(e);
			}
			return false;
		}
		case "join":
		{
			int pl_num = minigame_count_players(minigame);

			// Don't allow more than 1 player
			if(pl_num >= 1) { return false; }

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "move": 
					qto_move(minigame, ...(0,entity), ...(1,int) == 2 ? argv(1) : string_null ); 
					return true;
				case "restart":
					qto_restart_match(minigame,...(0,entity));
					return true;
			}

			return false;
		}
		case "network_send":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_board_piece" && (sf & MINIG_SF_UPDATE) )
			{
				WriteByte(MSG_ENTITY,sent.cnt);
			}
			else if ( sent.classname == "minigame_player" && (sf & QTO_SF_PLAYERSCORE ) )
			{
				WriteLong(MSG_ENTITY,sent.qto_moves);
			}
			return false;
		}
	}
	
	return false;
}


#elif defined(CSQC)

string qto_curr_pos; // identifier of the tile under the mouse
vector qto_boardpos; // HUD board position
vector qto_boardsize;// HUD board size

// Required function, draw the game board
void qto_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	qto_boardpos = pos;
	qto_boardsize = mySize;
	
	minigame_hud_simpleboard(pos,mySize,minigame_texture("qto/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0' / QTO_TILE_SIZE,pos,mySize);
	vector tile_pos;

	bool valid = qto_valid_tile(qto_curr_pos);
	int number = minigame_tile_number(qto_curr_pos);
	int letter = minigame_tile_letter(qto_curr_pos);
	string pos1 = minigame_tile_buildname(letter-1,number);
	string pos2 = minigame_tile_buildname(letter+1,number);
	string pos3 = minigame_tile_buildname(letter,number-1);
	string pos4 = minigame_tile_buildname(letter,number+1);
	
	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,QTO_NUM_CNT,QTO_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			vector tile_color = '0.4 0.4 0.4';

			if(valid)
			switch(e.netname)
			{
				case qto_curr_pos:
				case pos1: case pos2: case pos3: case pos4:
					tile_color = '0.8 0.8 0.8';
					break;
			}
				
			minigame_drawpic_centered( tile_pos,  
					minigame_texture(strcat("qto/piece", ftos(e.cnt))),
					tile_size, tile_color, panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}
}


// Required function, draw the game status panel
void qto_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg(1);
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

	mypos = pos;
	drawfill(mypos,eX*mySize_x+eY*player_fontsize_y,'1 1 1',0.5,DRAWFLAG_ADDITIVE);
	mypos_y += player_fontsize_y;
	drawfill(mypos,eX*mySize_x+eY*tile_size_y,'1 1 1',0.25,DRAWFLAG_ADDITIVE);

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			mypos = pos;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				GetPlayerName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			
			mypos_y += player_fontsize_y;
			//drawpic( mypos,  
			//		minigame_texture("qto/piece"),
			//		tile_size, '1 0 0', panel_fg_alpha, DRAWFLAG_NORMAL );
			
			//mypos_x += tile_size_x;

			drawstring(mypos,sprintf(_("Moves: %s"), ftos(e.qto_moves)),'32 32 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string qto_turn_to_string(int turnflags)
{
	if ( turnflags & QTO_TURN_WIN )
		return _("Well done, you win!");
	
	if ( turnflags & QTO_TURN_MOVE )
		return _("Turn all the angry faces into happy faces");
	
	return "";
}

// Make the correct move
void qto_make_move(entity minigame)
{
	if ( minigame.minigame_flags == QTO_TURN_MOVE )
	{
		minigame_cmd("move ",qto_curr_pos);
	}
}

void qto_set_curr_pos(string s)
{
	if ( qto_curr_pos )
		strunzone(qto_curr_pos);
	if ( s )
		s = strzone(s);
	qto_curr_pos = s;
}

// Required function, handle client events
int qto_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			qto_set_curr_pos("");
			minigame.message = qto_turn_to_string(minigame.minigame_flags);
			return false;
		}
		case "key_pressed":
		{
			//if((minigame.minigame_flags & QTO_TURN_TEAM) == minigame_self.team)
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if ( ! qto_curr_pos )
							qto_set_curr_pos("a3");
						else
							qto_set_curr_pos( minigame_relative_tile(qto_curr_pos,1,0,QTO_NUM_CNT,QTO_LET_CNT));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if ( ! qto_curr_pos )
							qto_set_curr_pos("c3");
						else
							qto_set_curr_pos(minigame_relative_tile(qto_curr_pos,-1,0,QTO_NUM_CNT,QTO_LET_CNT));
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						if ( ! qto_curr_pos )
							qto_set_curr_pos("a1");
						else
							qto_set_curr_pos(minigame_relative_tile(qto_curr_pos,0,1,QTO_NUM_CNT,QTO_LET_CNT));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if ( ! qto_curr_pos )
							qto_set_curr_pos("a3");
						else
							qto_set_curr_pos(minigame_relative_tile(qto_curr_pos,0,-1,QTO_NUM_CNT,QTO_LET_CNT));
						return true;
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						qto_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,int) == K_MOUSE1)
			{
				qto_make_move(minigame);
				return true;
			}

			return false;
		}
		case "mouse_moved":
		{
			vector mouse_pos = minigame_hud_normalize(mousepos,qto_boardpos,qto_boardsize);
			if ( minigame.minigame_flags == QTO_TURN_MOVE )
			{
				qto_set_curr_pos(minigame_tile_name(mouse_pos,QTO_NUM_CNT,QTO_LET_CNT));
			}
			if ( ! qto_valid_tile(qto_curr_pos) )
				qto_set_curr_pos("");

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
					sent.message = qto_turn_to_string(sent.minigame_flags);
					if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
				}
			}
			else if(sent.classname == "minigame_board_piece")
			{
				if(sf & MINIG_SF_UPDATE)
				{
					sent.cnt = ReadByte();
				}
			}
			else if ( sent.classname == "minigame_player" && (sf & QTO_SF_PLAYERSCORE ) )
			{
				sent.qto_moves = ReadLong();
			}

			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Restart"),"restart");
			return false;
		}
		case "menu_click":
		{
			if(...(0,string) == "restart")
				minigame_cmd("restart");
			return false;
		}
	}

	return false;
}

#endif