const float C4_TURN_PLACE = 0x0100; // player has to place a piece on the board
const float C4_TURN_WIN   = 0x0200; // player has won
const float C4_TURN_DRAW  = 0x0400; // no moves are possible
const float C4_TURN_NEXT  = 0x0800; // a player wants to start a new match
const float C4_TURN_TYPE  = 0x0f00; // turn type mask

const float C4_TURN_TEAM1 = 0x0001;
const float C4_TURN_TEAM2 = 0x0002;
const float C4_TURN_TEAM  = 0x000f; // turn team mask

const int C4_LET_CNT = 7;
const int C4_NUM_CNT = 6;
const int C4_WIN_CNT = 4;

const int C4_MAX_TILES = 42;

const int C4_TILE_SIZE = 8;

const int C4_TEAMS = 2;

// send flags
const float C4_SF_PLAYERSCORE  = MINIG_SF_CUSTOM;   // send minigame_player scores (won matches)

.float c4_npieces; // (minigame) number of pieces on the board (simplifies checking a draw)
.float c4_nexteam; // (minigame) next team (used to change the starting team on following matches)

// find connect 4 piece given its tile name
entity c4_find_piece(entity minig, string tile)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return world;
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

// check if the tile name is valid (3x3 grid)
float c4_valid_tile(string tile)
{
	if ( !tile )
		return 0;
	float number = minigame_tile_number(tile);
	float letter = minigame_tile_letter(tile);
	return 0 <= number && number < C4_NUM_CNT && 0 <= letter && letter < C4_LET_CNT;
}

// make a move
void c4_move(entity minigame, entity player, string pos )
{
	if ( minigame.minigame_flags & C4_TURN_PLACE )
	if ( pos && player.team == (minigame.minigame_flags & C4_TURN_TEAM) )
	{
		if ( c4_valid_tile(pos) )
		if ( !c4_find_piece(minigame,pos) )
		{
			entity piece = msle_spawn(minigame,"minigame_board_piece");
			piece.team = player.team;
			piece.netname = strzone(pos);
			minigame_server_sendflags(piece,MINIG_SF_ALL);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
			minigame.c4_npieces++;
			minigame.c4_nexteam = minigame_next_team(player.team,C4_TEAMS);
			if ( c4_winning_piece(piece) )
			{
				player.minigame_flags++;
				minigame_server_sendflags(player, C4_SF_PLAYERSCORE);
				minigame.minigame_flags = C4_TURN_WIN | player.team;
			}
			else if ( minigame.c4_npieces >= C4_MAX_TILES )
				minigame.minigame_flags = C4_TURN_DRAW;
			else
				minigame.minigame_flags = C4_TURN_PLACE | minigame.c4_nexteam;
		}
	}
}

// request a new match
void c4_next_match(entity minigame, entity player)
{
#ifdef SVQC
	// on multiplayer matches, wait for both players to agree
	if ( minigame.minigame_flags & (C4_TURN_WIN|C4_TURN_DRAW) )
	{
		minigame.minigame_flags = C4_TURN_NEXT | player.team;
		minigame.SendFlags |= MINIG_SF_UPDATE;
	}
	else if ( (minigame.minigame_flags & C4_TURN_NEXT) &&
			!( minigame.minigame_flags & player.team ) )
#endif
	{
		minigame.minigame_flags = C4_TURN_PLACE | minigame.c4_nexteam;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		minigame.c4_npieces = 0;
		entity e = world;
		while ( ( e = findentity(e,owner,minigame) ) )
			if ( e.classname == "minigame_board_piece" )
				remove(e);
	}
}

#ifdef SVQC


// required function, handle server side events
float c4_server_event(entity minigame, string event, ...)
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
			float pl_num = minigame_count_players(minigame);

			// Don't allow more than 2 players
			if(pl_num >= C4_TEAMS) { return false; }

			// Get the right team
			if(minigame.minigame_players)
				return minigame_next_team(minigame.minigame_players.team, C4_TEAMS);

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "move": 
					c4_move(minigame, ...(0,entity), ...(1,float) == 2 ? argv(1) : string_null ); 
					return true;
				case "next":
					c4_next_match(minigame,...(0,entity));
					return true;
			}

			return false;
		}
		case "network_send":
		{
			entity sent = ...(0,entity);
			float sf = ...(1,float);
			if ( sent.classname == "minigame_player" && (sf & C4_SF_PLAYERSCORE ) )
			{
				WriteByte(MSG_ENTITY,sent.minigame_flags);
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
.float c4_checkwin; // Used to optimize checks to display a win

// Required function, draw the game board
void c4_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	c4_boardpos = pos;
	c4_boardsize = mySize;
	
	minigame_hud_simpleboard(pos,mySize,minigame_texture("c4/board"));

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
}


// Required function, draw the game status panel
void c4_hud_status(vector pos, vector mySize)
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
	vector tile_size = '24 24 0';

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				GetPlayerName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			
			mypos_y += player_fontsize_y;
			drawpic( mypos,  
					minigame_texture(strcat("c4/piece",ftos(e.team))),
					tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			
			mypos_x += tile_size_x;
			
			drawstring(mypos,ftos(e.minigame_flags),tile_size,
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string c4_turn_to_string(float turnflags)
{
	if ( turnflags & C4_TURN_DRAW )
		return _("Draw");
	
	if ( turnflags & C4_TURN_WIN )
	{
		if ( (turnflags&C4_TURN_TEAM) != minigame_self.team )
			return _("You lost the game!\nSelect \"^1Next Match^7\" on the menu for a rematch!");
		return _("You win!\nSelect \"^1Next Match^7\" on the menu to start a new match!");
	}
	
	if ( turnflags & C4_TURN_NEXT )
	{
		if ( (turnflags&C4_TURN_TEAM) != minigame_self.team )
			return _("Select \"^1Next Match^7\" on the menu to start a new match!");
		return _("Wait for your opponent to confirm the rematch");
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
	if ( c4_curr_pos )
		strunzone(c4_curr_pos);
	if ( s )
		s = strzone(s);
	c4_curr_pos = s;
}

string c4_get_lowest_tile(entity minigame, string s)
{
	int i;
	int end = 0;
	for(i = C4_NUM_CNT; i >= 0; --i)
	{
		if(c4_find_piece(minigame,minigame_tile_buildname(minigame_tile_letter(s), i - 1)).team)
		{
			end = i;
			break;
		}
	}
	return minigame_tile_buildname(minigame_tile_letter(s), end);
}

// Required function, handle client events
float c4_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			c4_set_curr_pos("");
			minigame.message = c4_turn_to_string(minigame.minigame_flags);
			return false;
		}
		case "key_pressed":
		{
			if((minigame.minigame_flags & C4_TURN_TEAM) == minigame_self.team)
			{
				switch ( ...(0,float) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if ( ! c4_curr_pos )
							c4_set_curr_pos(c4_get_lowest_tile(minigame, "a3"));
						else
							c4_set_curr_pos(c4_get_lowest_tile(minigame, minigame_relative_tile(c4_curr_pos,1,0,C4_NUM_CNT,C4_LET_CNT)));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if ( ! c4_curr_pos )
							c4_set_curr_pos(c4_get_lowest_tile(minigame, "c3"));
						else
							c4_set_curr_pos(c4_get_lowest_tile(minigame, minigame_relative_tile(c4_curr_pos,-1,0,C4_NUM_CNT,C4_LET_CNT)));
						return true;
					/*case K_UPARROW:
					case K_KP_UPARROW:
						if ( ! c4_curr_pos )
							c4_set_curr_pos("a1");
						else
							c4_set_curr_pos(minigame_relative_tile(c4_curr_pos,0,1,6,7));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if ( ! c4_curr_pos )
							c4_set_curr_pos("a3");
						else
							c4_set_curr_pos(minigame_relative_tile(c4_curr_pos,0,-1,6,7));
						return true;*/
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						c4_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,float) == K_MOUSE1)
			{
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
			float sf = ...(1,float);
			if ( sent.classname == "minigame" )
			{
				if ( sf & MINIG_SF_UPDATE )
				{
					sent.message = c4_turn_to_string(sent.minigame_flags);
					if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
				}
			}
			else if ( sent.classname == "minigame_player" && (sf & C4_SF_PLAYERSCORE ) )
			{
				sent.minigame_flags = ReadByte();
			}

			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Next Match"),"next");
			return false;
		}
		case "menu_click":
		{
			if(...(0,string) == "next")
			{
				minigame_cmd("next");
			}
			return false;
		}
	}

	return false;
}

#endif