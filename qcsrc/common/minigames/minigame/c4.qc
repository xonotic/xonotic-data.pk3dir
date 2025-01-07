#include "c4.qh"
REGISTER_MINIGAME(c4, _("Connect Four"));

const float C4_TURN_PLACE = 0x0100; // player has to place a piece on the board
const float C4_TURN_WIN   = 0x0200; // player has won
const float C4_TURN_DRAW  = 0x0400; // no moves are possible

const float C4_TURN_TEAM1 = 0x0001;
const float C4_TURN_TEAM2 = 0x0002;
const float C4_TURN_TEAM  = 0x000f; // turn team mask

const int C4_LET_CNT = 7;
const int C4_NUM_CNT = 6;
const int C4_WIN_CNT = 4;

const int C4_MAX_TILES = 42;

const int C4_TILE_SIZE = 8;

const int C4_TEAMS = 2;
const int C4_SPECTATOR_TEAM = 255; // must be above max teams and equal to or below 255

.int c4_npieces; // (minigame) number of pieces on the board (simplifies checking a draw)
.int c4_nexteam; // (minigame) next team (used to change the starting team on following matches)

// find connect 4 piece given its tile name
entity c4_find_piece(entity minig, string tile)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return NULL;
}

// Checks if the given piece completes a row
bool c4_winning_piece(entity piece)
{
	int number = minigame_tile_number(piece.netname);
	int letter = minigame_tile_letter(piece.netname);

	int i;
	entity top = piece;
	entity left = piece;
	entity topleft = piece;
	entity botleft = piece;
	for(i = number; i < C4_NUM_CNT; ++i)
	{
		entity p = c4_find_piece(piece.owner,minigame_tile_buildname(letter, i));
		if(p.team == piece.team)
			top = p;
		else break;
	}

	for(i = letter; i >= 0; --i)
	{
		entity p = c4_find_piece(piece.owner,minigame_tile_buildname(i, number));
		if(p.team == piece.team)
			left = p;
		else break;
	}

	int j;
	for(i = letter, j = number; i >= 0, j >= 0; --i, --j)
	{
		entity p = c4_find_piece(piece.owner,minigame_tile_buildname(i, j));
		if(p.team == piece.team)
			botleft = p;
		else break;
	}
	for(i = letter, j = number; i >= 0, j < C4_NUM_CNT; --i, ++j)
	{
		entity p = c4_find_piece(piece.owner,minigame_tile_buildname(i, j));
		if(p.team == piece.team)
			topleft = p;
		else break;
	}

	// down
	int found = 0;
	for(i = minigame_tile_number(top.netname); i >= 0; --i)
	{
		if(c4_find_piece(piece.owner,minigame_tile_buildname(letter, i)).team == piece.team)
			++found;
		else break;
	}

	if(found >= C4_WIN_CNT)
		return true;

	// right
	found = 0;
	for(i = minigame_tile_letter(left.netname); i < C4_LET_CNT; ++i)
	{
		if(c4_find_piece(piece.owner,minigame_tile_buildname(i, number)).team == piece.team)
			++found;
		else break;
	}

	if(found >= C4_WIN_CNT)
		return true;

	// diagright down
	found = 0;
	for(i = minigame_tile_letter(topleft.netname), j = minigame_tile_number(topleft.netname); i < C4_LET_CNT, j >= 0; ++i, --j)
	{
		if(c4_find_piece(piece.owner,minigame_tile_buildname(i, j)).team == piece.team)
			++found;
		else break;
	}

	if(found >= C4_WIN_CNT)
		return true;

	// diagright up
	found = 0;
	for(i = minigame_tile_letter(botleft.netname), j = minigame_tile_number(botleft.netname); i < C4_LET_CNT, j < C4_NUM_CNT; ++i, ++j)
	{
		if(c4_find_piece(piece.owner,minigame_tile_buildname(i, j)).team == piece.team)
			++found;
		else break;
	}

	if(found >= C4_WIN_CNT)
		return true;

	return false;
}

// check if the tile name is valid (6x7 grid)
bool c4_valid_tile(string tile)
{
	if ( !tile )
		return false;
	float number = minigame_tile_number(tile);
	float letter = minigame_tile_letter(tile);
	return 0 <= number && number < C4_NUM_CNT && 0 <= letter && letter < C4_LET_CNT;
}

string c4_get_lowest_tile(entity minigame, string s)
{
	int i;
	int end = 0;
	for(i = C4_NUM_CNT; i >= 0; --i)
	{
		if(!c4_find_piece(minigame,minigame_tile_buildname(minigame_tile_letter(s), i)))
		if(c4_find_piece(minigame,minigame_tile_buildname(minigame_tile_letter(s), i - 1)))
		{
			end = i;
			break;
		}
	}
	return minigame_tile_buildname(minigame_tile_letter(s), end);
}

// make a move
void c4_move(entity minigame, entity player, string pos )
{
	pos = c4_get_lowest_tile(minigame, pos);

	if ( minigame.minigame_flags & C4_TURN_PLACE )
	if ( pos && player.team == (minigame.minigame_flags & C4_TURN_TEAM) )
	{
		if ( c4_valid_tile(pos) )
		if ( !c4_find_piece(minigame,pos) )
		{
			entity piece = msle_spawn(minigame,new(minigame_board_piece));
			piece.team = player.team;
			piece.netname = strzone(pos);
			minigame_server_sendflags(piece,MINIG_SF_ALL);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
			minigame.c4_npieces++;
			minigame.c4_nexteam = minigame_next_team(player.team,C4_TEAMS);
			if ( c4_winning_piece(piece) )
			{
				minigame.minigame_flags = C4_TURN_WIN | player.team;
			}
			else if ( minigame.c4_npieces >= C4_MAX_TILES )
				minigame.minigame_flags = C4_TURN_DRAW;
			else
				minigame.minigame_flags = C4_TURN_PLACE | minigame.c4_nexteam;
		}
	}
}

#ifdef SVQC


// required function, handle server side events
int c4_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			minigame.minigame_flags = (C4_TURN_PLACE | C4_TURN_TEAM1);
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

			// Don't allow more than 2 players
			if(pl_num >= C4_TEAMS) { return C4_SPECTATOR_TEAM; }

			// Get the right team
			if(minigame.minigame_players)
				return minigame_next_team(minigame.minigame_players.team, C4_TEAMS);

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			entity player = ...(0,entity);
			bool event_blocked = (player.team == C4_SPECTATOR_TEAM);
			switch(argv(0))
			{
				case "move":
					if(event_blocked)
						return true;
					c4_move(minigame, ...(0,entity), ...(1,int) == 2 ? argv(1) : string_null );
					return true;
			}

			return false;
		}
	}

	return false;
}


#elif defined(CSQC)

string c4_curr_pos; // identifier of the tile under the mouse
vector c4_boardpos; // HUD board position
vector c4_boardsize;// HUD board size
.int c4_checkwin; // Used to optimize checks to display a win

// Required function, draw the game board
void c4_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	c4_boardpos = pos;
	c4_boardsize = mySize;

	minigame_hud_simpleboard(pos,mySize,minigame_texture("c4/board_under"));

	drawpic(pos, minigame_texture("c4/board_over"), mySize, '1 1 1', 1, 0);

	vector tile_size = minigame_hud_denormalize_size('1 1 0' / C4_TILE_SIZE,pos,mySize);
	vector tile_pos;

	if ( (active_minigame.minigame_flags & C4_TURN_TEAM) == minigame_self.team )
	if ( c4_valid_tile(c4_curr_pos) )
	{
		tile_pos = minigame_tile_pos(c4_curr_pos,C4_NUM_CNT,C4_LET_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
		minigame_drawpic_centered( tile_pos,
				minigame_texture(strcat("c4/piece",ftos(minigame_self.team))),
				tile_size, '1 1 1', panel_fg_alpha/2, DRAWFLAG_NORMAL );
	}

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,C4_NUM_CNT,C4_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			if ( active_minigame.minigame_flags & C4_TURN_WIN )
			if ( !e.c4_checkwin )
				e.c4_checkwin = c4_winning_piece(e) ? 1 : -1;

			float icon_color = 1;
			if ( e.c4_checkwin == -1 )
				icon_color = 0.4;
			else if ( e.c4_checkwin == 1 )
			{
				icon_color = 2;
				minigame_drawpic_centered( tile_pos, minigame_texture("c4/winglow"),
						tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_ADDITIVE );
			}

			minigame_drawpic_centered( tile_pos,
					minigame_texture(strcat("c4/piece",ftos(e.team))),
					tile_size, '1 1 1'*icon_color, panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	if ( active_minigame.minigame_flags & C4_TURN_WIN )
	{
		vector winfs = hud_fontsize*2;
		string pname = "";
		FOREACH_MINIGAME_ENTITY(e)
			if ( e.classname == "minigame_player" &&
					e.team == (active_minigame.minigame_flags & C4_TURN_TEAM) )
				pname = entcs_GetName(e.minigame_playerslot-1);

		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf(_("%s^7 won the game!"), pname),
			winfs, 0, DRAWFLAG_NORMAL, 0.5);

		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'1 1 1',0.5*panel_fg_alpha,DRAWFLAG_ADDITIVE);

		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf(_("%s^7 won the game!"), pname),
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}

	minigame_show_allspecs(c4_boardpos, c4_boardsize);
}


// Required function, draw the game status panel
void c4_hud_status(vector pos, vector mySize)
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

	if(minigame_self.team != C4_SPECTATOR_TEAM)
	{
		mypos = pos;
		if ( (active_minigame.minigame_flags&C4_TURN_TEAM) == 2 )
			mypos_y  += player_fontsize_y + ts_y;
		drawfill(mypos,eX*mySize_x+eY*player_fontsize_y,'1 1 1',0.5*panel_fg_alpha,DRAWFLAG_ADDITIVE);
		mypos_y += player_fontsize_y;
		drawfill(mypos,eX*mySize_x+eY*tile_size_y,'1 1 1',0.25*panel_fg_alpha,DRAWFLAG_ADDITIVE);
	}

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" && e.team != C4_SPECTATOR_TEAM )
		{
			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				entcs_GetName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			drawpic( mypos,
					minigame_texture(strcat("c4/piece",ftos(e.team))),
					tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );

			mypos_x += tile_size_x;
		}
	}
}

// Turn a set of flags into a help message
string c4_turn_to_string(int turnflags)
{
	if(minigame_self.team == C4_SPECTATOR_TEAM)
		return _("You are spectating");

	if ( turnflags & C4_TURN_DRAW )
		return _("Draw");

	if ( turnflags & C4_TURN_WIN )
	{
		if ( (turnflags&C4_TURN_TEAM) != minigame_self.team )
			return _("You lost the game!");
		return _("You win!");
	}

	if ( (turnflags & C4_TURN_TEAM) != minigame_self.team )
		return _("Wait for your opponent to make their move");

	if ( turnflags & C4_TURN_PLACE )
		return _("Click on the game board to place your piece");

	return "";
}

// Make the correct move
void c4_make_move(entity minigame)
{
	if ( minigame.minigame_flags == (C4_TURN_PLACE|minigame_self.team) )
	{
		minigame_cmd("move ",c4_curr_pos);
	}
}

void c4_set_curr_pos(string s)
{
	strfree(c4_curr_pos);
	if ( s )
		s = strzone(s);
	c4_curr_pos = s;
}

// Required function, handle client events
int c4_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			c4_set_curr_pos("");
			strcpy(minigame.message, c4_turn_to_string(minigame.minigame_flags));
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
				|| ((minigame.minigame_flags & C4_TURN_TEAM) != minigame_self.team));
			if (!(minigame.minigame_flags & (C4_TURN_WIN | C4_TURN_DRAW)))
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if (event_blocked)
							return true;
						if ( ! c4_curr_pos )
							c4_set_curr_pos(c4_get_lowest_tile(minigame, "a3"));
						else
							c4_set_curr_pos(c4_get_lowest_tile(minigame, minigame_relative_tile(c4_curr_pos,1,0,C4_NUM_CNT,C4_LET_CNT)));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if (event_blocked)
							return true;
						if ( ! c4_curr_pos )
							c4_set_curr_pos(c4_get_lowest_tile(minigame, "c3"));
						else
							c4_set_curr_pos(c4_get_lowest_tile(minigame, minigame_relative_tile(c4_curr_pos,-1,0,C4_NUM_CNT,C4_LET_CNT)));
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						return true;
					/*case K_UPARROW:
					case K_KP_UPARROW:
						if (event_blocked)
							return true;
						if ( ! c4_curr_pos )
							c4_set_curr_pos("a1");
						else
							c4_set_curr_pos(minigame_relative_tile(c4_curr_pos,0,1,6,7));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if (event_blocked)
							return true;
						if ( ! c4_curr_pos )
							c4_set_curr_pos("a3");
						else
							c4_set_curr_pos(minigame_relative_tile(c4_curr_pos,0,-1,6,7));
						return true;*/
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						if (event_blocked)
							return true;
						c4_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,int) == K_MOUSE1)
			{
				c4_client_event(minigame, "mouse_moved");
				c4_make_move(minigame);
				return true;
			}

			return false;
		}
		case "mouse_moved":
		{
			vector mouse_pos = minigame_hud_normalize(mousepos,c4_boardpos,c4_boardsize);
			if ( minigame.minigame_flags == (C4_TURN_PLACE|minigame_self.team) )
			{
				c4_set_curr_pos(c4_get_lowest_tile(minigame, minigame_tile_name(mouse_pos,C4_NUM_CNT,C4_LET_CNT)));
			}
			if ( ! c4_valid_tile(c4_curr_pos) )
				c4_set_curr_pos("");

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
					strcpy(sent.message, c4_turn_to_string(sent.minigame_flags));
					if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
				}
			}

			return false;
		}
	}

	return false;
}

#endif
