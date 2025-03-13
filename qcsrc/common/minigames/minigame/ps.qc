#include "ps.qh"
REGISTER_MINIGAME(ps, _("Peg Solitaire"));

const float PS_TURN_MOVE  = 0x0100; // player has to click on a piece on the board
const float PS_TURN_WIN   = 0x0200; // player has won
const float PS_TURN_DRAW  = 0x0400; // player can make no more moves
const float PS_TURN_TYPE  = 0x0f00; // turn type mask

const int PS_SPECTATOR_TEAM = 255; // must be above max teams and equal to or below 255

const int PS_LET_CNT = 7;
const int PS_NUM_CNT = 7;

const int PS_TILE_SIZE = 8;

// find same game piece given its tile name
entity ps_find_piece(entity minig, string tile)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return NULL;
}

bool ps_draw(entity minigame)
{
	entity e = NULL;
	while( ( e = findentity(e,owner,minigame) ) )
		if( e.classname == "minigame_board_piece" )
		{
			return true;
		}

	return false;
}

bool ps_tile_blacklisted(string tile)
{
	int number = minigame_tile_number(tile);
	int letter = minigame_tile_letter(tile);
	if(letter < 2)
	{
		if(number < 2)
			return true;
		else if(number > PS_NUM_CNT - 3)
			return true;
	}
	if(letter > PS_LET_CNT - 3)
	{
		if(number < 2)
			return true;
		else if(number > PS_NUM_CNT - 3)
			return true;
	}

	return false;
}

// check if the tile name is valid (5x5 grid)
bool ps_valid_tile(string tile)
{
	if ( !tile )
		return false;
	if(ps_tile_blacklisted(tile))
		return false;
	float number = minigame_tile_number(tile);
	float letter = minigame_tile_letter(tile);
	return 0 <= number && number < PS_NUM_CNT && 0 <= letter && letter < PS_LET_CNT;
}

// Checks if the given piece completes a row
bool ps_winning_piece(entity minigame)
{
	//int number = minigame_tile_number(piece.netname);
	//int letter = minigame_tile_letter(piece.netname);

	entity e = NULL;
	while ( ( e = findentity(e,owner,minigame) ) )
		if ( e.classname == "minigame_board_piece" )
		{
			int number = minigame_tile_number(e.netname);
			int letter = minigame_tile_letter(e.netname);
			string try = minigame_tile_buildname(letter - 1, number);
			if(ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter - 2, number);
				if(ps_valid_tile(try) && !ps_find_piece(minigame,try))
					return false; // a move is valid, abort!
			}
			try = minigame_tile_buildname(letter + 1, number);
			if(ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter + 2, number);
				if(ps_valid_tile(try) && !ps_find_piece(minigame,try))
					return false; // a move is valid, abort!
			}
			try = minigame_tile_buildname(letter, number - 1);
			if(ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter, number - 2);
				if(ps_valid_tile(try) && !ps_find_piece(minigame,try))
					return false; // a move is valid, abort!
			}
			try = minigame_tile_buildname(letter, number + 1);
			if(ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter, number + 2);
				if(ps_valid_tile(try) && !ps_find_piece(minigame,try))
					return false; // a move is valid, abort!
			}
		}

	return true;
}

void ps_setup_pieces(entity minigame)
{
	int i, t;
	for(i = 0; i < PS_NUM_CNT; ++i)
	for(t = 0; t < PS_LET_CNT; ++t)
	{
		string try = minigame_tile_buildname(i,t);
		if(!ps_valid_tile(try))
			continue;
		if(i == floor(PS_NUM_CNT * 0.5) && t == floor(PS_LET_CNT * 0.5))
			continue; // middle piece is empty
		entity piece = msle_spawn(minigame,new(minigame_board_piece));
		piece.team = 1; // init default team?
		piece.netname = strzone(minigame_tile_buildname(t,i));
		minigame_server_sendflags(piece,MINIG_SF_ALL);
	}

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
}

bool ps_move_piece(entity minigame, entity piece, string pos, int leti, int numb)
{
	if(!piece)
		return false;
	if(ps_find_piece(minigame, pos))
		return false;
	entity middle = ps_find_piece(minigame, minigame_tile_buildname(leti,numb));
	if(!middle)
		return false;

	strfree(middle.netname);
	delete(middle);

	strcpy(piece.netname, pos);

	minigame_server_sendflags(piece,MINIG_SF_ALL);

	return true;
}

// make a move
void ps_move(entity minigame, entity player, string thepiece, string pos )
{
	if ( (minigame.minigame_flags & PS_TURN_MOVE) )
	if ( pos )
	{
		if ( ps_valid_tile(pos) )
		if ( !ps_find_piece(minigame, pos) && ps_find_piece(minigame, thepiece) )
		{
			entity piece = ps_find_piece(minigame, thepiece);
			int number = minigame_tile_number(thepiece);
			int letter = minigame_tile_letter(thepiece);
			bool done = false;
			string try;

			try = minigame_tile_buildname(letter-1,number);
			if(ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter-2,number);
				if(ps_valid_tile(try) && try == pos)
					done = ps_move_piece(minigame, piece, pos, letter - 1, number);
			}
			try = minigame_tile_buildname(letter+1,number);
			if(!done && ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter+2,number);
				if(ps_valid_tile(try) && try == pos)
					done = ps_move_piece(minigame, piece, pos, letter + 1, number);
			}
			try = minigame_tile_buildname(letter,number-1);
			if(!done && ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter,number-2);
				if(ps_valid_tile(try) && try == pos)
					done = ps_move_piece(minigame, piece, pos, letter, number - 1);
			}
			try = minigame_tile_buildname(letter,number+1);
			if(!done && ps_find_piece(minigame,try))
			{
				try = minigame_tile_buildname(letter,number+2);
				if(ps_valid_tile(try) && try == pos)
					done = ps_move_piece(minigame, piece, pos, letter, number + 1);
			}

			if(!done)
				return; // didn't make a move

			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

			if ( ps_winning_piece(minigame) )
			{
				if(ps_draw(minigame))
					minigame.minigame_flags = PS_TURN_DRAW;
				else
					minigame.minigame_flags = PS_TURN_WIN;
			}
			else
				minigame.minigame_flags = PS_TURN_MOVE;
		}
	}
}

#ifdef SVQC


// required function, handle server side events
int ps_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			ps_setup_pieces(minigame);
			minigame.minigame_flags = PS_TURN_MOVE;
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

			// Don't allow more than 1 player
			if(pl_num >= 1) { return PS_SPECTATOR_TEAM; }

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			entity player = ...(0,entity);
			bool event_blocked = (player.team == PS_SPECTATOR_TEAM);
			switch(argv(0))
			{
				case "move":
					if(event_blocked)
						return true;
					ps_move(minigame, ...(0,entity), (...(1,int) == 3 ? argv(1) : string_null), (...(1,int) == 3 ? argv(2) : string_null));
					return true;
			}

			return false;
		}
	}

	return false;
}


#elif defined(CSQC)

entity ps_curr_piece; // identifier for the currently selected piece
string ps_curr_pos; // identifier of the tile under the mouse
vector ps_boardpos; // HUD board position
vector ps_boardsize;// HUD board size

// Required function, draw the game board
void ps_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	ps_boardpos = pos;
	ps_boardsize = mySize;

	minigame_hud_simpleboard(pos,mySize,minigame_texture("ps/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0' / PS_TILE_SIZE,pos,mySize);
	vector tile_pos;

	bool valid = ps_valid_tile(ps_curr_pos);
	bool highlight = false;
	if(valid)
	{
		string try;
		int number = minigame_tile_number(ps_curr_pos);
		int letter = minigame_tile_letter(ps_curr_pos);
		try = minigame_tile_buildname(letter-1,number);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(letter-2,number);
			if(ps_valid_tile(try) && !ps_find_piece(active_minigame,try))
				highlight = true;
		}
		try = minigame_tile_buildname(letter+1,number);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(letter+2,number);
			if(ps_valid_tile(try) && !ps_find_piece(active_minigame,try))
				highlight = true;
		}
		try = minigame_tile_buildname(letter,number-1);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(letter,number-2);
			if(ps_valid_tile(try) && !ps_find_piece(active_minigame,try))
				highlight = true;
		}
		try = minigame_tile_buildname(letter,number+1);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(letter,number+2);
			if(ps_valid_tile(try) && !ps_find_piece(active_minigame,try))
				highlight = true;
		}
	}
	bool draw_pos = false;
	if(ps_curr_piece && valid && !ps_find_piece(active_minigame, ps_curr_pos))
	{
		string try; // sigh
		int numb = minigame_tile_number(ps_curr_piece.netname);
		int leti = minigame_tile_letter(ps_curr_piece.netname);

		try = minigame_tile_buildname(leti-1,numb);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(leti-2,numb);
			if(try == ps_curr_pos)
				draw_pos = true;
		}
		try = minigame_tile_buildname(leti+1,numb);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(leti+2,numb);
			if(try == ps_curr_pos)
				draw_pos = true;
		}
		try = minigame_tile_buildname(leti,numb-1);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(leti,numb-2);
			if(try == ps_curr_pos)
				draw_pos = true;
		}
		try = minigame_tile_buildname(leti,numb+1);
		if(ps_find_piece(active_minigame,try))
		{
			try = minigame_tile_buildname(leti,numb+2);
			if(try == ps_curr_pos)
				draw_pos = true;
		}
	}

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,PS_NUM_CNT,PS_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			vector tile_color = '1 1 1';

			if(highlight)
			if(e.netname == ps_curr_pos)
			if(ps_curr_piece.netname != ps_curr_pos)
			{
				minigame_drawpic_centered( tile_pos,
						minigame_texture("ps/tile_available"),
						tile_size, tile_color, panel_fg_alpha, DRAWFLAG_NORMAL );
			}
			if(e == ps_curr_piece)
			{
				minigame_drawpic_centered( tile_pos,
						minigame_texture("ps/tile_selected"),
						tile_size, tile_color, panel_fg_alpha, DRAWFLAG_ADDITIVE );
			}

			minigame_drawpic_centered( tile_pos,
					minigame_texture("ps/piece"),
					tile_size * 0.8, tile_color, panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	if(draw_pos)
	{
		tile_pos = minigame_tile_pos(ps_curr_pos,PS_NUM_CNT,PS_LET_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

		minigame_drawpic_centered(tile_pos,
				minigame_texture("ps/piece"),
				tile_size * 0.8, '0.5 0.5 0.5', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(active_minigame.minigame_flags & (PS_TURN_WIN | PS_TURN_DRAW))
	{
		int remaining = 0;
		FOREACH_MINIGAME_ENTITY(e)
			if(e.classname == "minigame_board_piece")
				++remaining;

		vector winfs = hud_fontsize*2;
		string remaining_text;
		if(active_minigame.minigame_flags & PS_TURN_WIN)
			remaining_text = _("All pieces cleared!");
		else
			remaining_text = strcat(_("Remaining pieces:"), " ", ftos(remaining));

		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			strcat(_("Game over!"), " ", remaining_text),
			winfs, 0, DRAWFLAG_NORMAL, 0.5);

		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'1 1 1',0.5*panel_fg_alpha,DRAWFLAG_ADDITIVE);

		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			strcat(_("Game over!"), " ", remaining_text),
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}

	minigame_show_allspecs(ps_boardpos, ps_boardsize);
}


// Required function, draw the game status panel
void ps_hud_status(vector pos, vector mySize)
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

	if(minigame_self.team != PS_SPECTATOR_TEAM)
	{
		mypos = pos;
		drawfill(mypos,eX*mySize_x+eY*player_fontsize_y,'1 1 1',0.5*panel_fg_alpha,DRAWFLAG_ADDITIVE);
		mypos_y += player_fontsize_y;
		drawfill(mypos,eX*mySize_x+eY*tile_size_y,'1 1 1',0.25*panel_fg_alpha,DRAWFLAG_ADDITIVE);
	}

	int remaining = 0;
	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if(e.classname == "minigame_board_piece")
		{
			++remaining;
		}
	}

	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" && e.team != PS_SPECTATOR_TEAM )
		{
			mypos = pos;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				entcs_GetName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			//drawpic( mypos,
			//		minigame_texture("ps/piece"),
			//		tile_size, '1 0 0', panel_fg_alpha, DRAWFLAG_NORMAL );

			//mypos_x += tile_size_x;

			drawstring(mypos,sprintf(_("Pieces left: %s"), ftos(remaining)),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string ps_turn_to_string(int turnflags)
{
	if(minigame_self.team == PS_SPECTATOR_TEAM)
		return _("You are spectating");

	if (turnflags & PS_TURN_DRAW )
		return _("No more valid moves");

	if ( turnflags & PS_TURN_WIN )
		return _("Well done, you win!");

	if ( turnflags & PS_TURN_MOVE )
		return _("Jump a piece over another to capture it");

	return "";
}

// Make the correct move
void ps_make_move(entity minigame)
{
	if ( minigame.minigame_flags == PS_TURN_MOVE )
	{
		entity piece = ps_find_piece(minigame,ps_curr_pos);
		if(!ps_curr_piece || piece)
			ps_curr_piece = ps_find_piece(minigame,ps_curr_pos);
		else
		{
			minigame_cmd("move ", ps_curr_piece.netname, " ", ps_curr_pos);
			ps_curr_piece = NULL;
		}
	}
}

void ps_set_curr_pos(string s)
{
	strfree(ps_curr_pos);
	if ( s )
		s = strzone(s);
	ps_curr_pos = s;
}

// Required function, handle client events
int ps_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			ps_set_curr_pos("");
			ps_curr_piece = NULL;
			strcpy(minigame.message, ps_turn_to_string(minigame.minigame_flags));
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
			bool event_blocked = (event == "key_released" || minigame_self.team == PS_SPECTATOR_TEAM);
			if (!(minigame.minigame_flags & (PS_TURN_WIN | PS_TURN_DRAW)))
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if (event_blocked)
							return true;
						if ( ! ps_curr_pos )
							ps_set_curr_pos("a3");
						else
							ps_set_curr_pos( minigame_relative_tile(ps_curr_pos,1,0,PS_NUM_CNT,PS_LET_CNT));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if (event_blocked)
							return true;
						if ( ! ps_curr_pos )
							ps_set_curr_pos("c3");
						else
							ps_set_curr_pos(minigame_relative_tile(ps_curr_pos,-1,0,PS_NUM_CNT,PS_LET_CNT));
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						if (event_blocked)
							return true;
						if ( ! ps_curr_pos )
							ps_set_curr_pos("a1");
						else
							ps_set_curr_pos(minigame_relative_tile(ps_curr_pos,0,1,PS_NUM_CNT,PS_LET_CNT));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if (event_blocked)
							return true;
						if ( ! ps_curr_pos )
							ps_set_curr_pos("a3");
						else
							ps_set_curr_pos(minigame_relative_tile(ps_curr_pos,0,-1,PS_NUM_CNT,PS_LET_CNT));
						return true;
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						if (event_blocked)
							return true;
						ps_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,int) == K_MOUSE1)
			{
				ps_client_event(minigame, "mouse_moved");
				ps_make_move(minigame);
				return true;
			}

			return false;
		}
		case "mouse_moved":
		{
			vector mouse_pos = minigame_hud_normalize(mousepos,ps_boardpos,ps_boardsize);
			if ( minigame.minigame_flags == PS_TURN_MOVE && minigame_self.team != PS_SPECTATOR_TEAM )
			{
				ps_set_curr_pos(minigame_tile_name(mouse_pos,PS_NUM_CNT,PS_LET_CNT));
			}
			if ( ! ps_valid_tile(ps_curr_pos) )
				ps_set_curr_pos("");

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
					strcpy(sent.message, ps_turn_to_string(sent.minigame_flags));
					//if ( sent.minigame_flags & minigame_self.team )
						//minigame_prompt();
				}
			}

			return false;
		}
	}

	return false;
}

#endif
