REGISTER_MINIGAME(pp, "Push-Pull");

const int PP_TURN_PLACE = 0x0100; // player has to place a piece on the board
const int PP_TURN_WIN   = 0x0200; // player has won
const int PP_TURN_DRAW  = 0x0400; // players have equal scores
const int PP_TURN_NEXT  = 0x0800; // a player wants to start a new match
const int PP_TURN_TYPE  = 0x0f00; // turn type mask

const int PP_TURN_TEAM1 = 0x0001;
const int PP_TURN_TEAM2 = 0x0002;
const int PP_TURN_TEAM  = 0x000f; // turn team mask

const int PP_BLOCKED_TEAM = 5; // there won't ever be a 5th team, so we can abuse this

const int PP_LET_CNT = 7;
const int PP_NUM_CNT = 7;

const int PP_TILE_SIZE = 7;

.int pp_team1_score;
.int pp_team2_score;

.int pp_nexteam;

.entity pp_curr_piece; // identifier for the current target piece

// find tic tac toe piece given its tile name
entity pp_find_piece(entity minig, string tile)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return world;
}

// check if the tile name is valid (3x3 grid)
bool pp_valid_tile(string tile)
{
	if ( !tile )
		return 0;
	int number = minigame_tile_number(tile);
	int letter = minigame_tile_letter(tile);
	return 0 <= number && number < PP_NUM_CNT && 0 <= letter && letter < PP_LET_CNT;
}

// Checks if the given piece completes a row
bool pp_winning_piece(entity piece)
{
	int number = minigame_tile_number(piece.netname);
	int letter = minigame_tile_letter(piece.netname);

	// here goes
	if(!pp_valid_tile(minigame_tile_buildname(letter-1,number)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter-1,number)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter+1,number)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter+1,number)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter,number-1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter,number-1)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter,number+1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter,number+1)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter+1,number+1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter+1,number+1)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter-1,number-1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter-1,number-1)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter+1,number-1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter+1,number-1)).team == 5)
	if(!pp_valid_tile(minigame_tile_buildname(letter-1,number+1)) || pp_find_piece(piece.owner,minigame_tile_buildname(letter-1,number+1)).team == 5)
		return true;

	return false;
}

bool pp_valid_move(entity minigame, string pos)
{
	if(!pp_valid_tile(pos))
		return false;
	if(pp_find_piece(minigame,pos).team == 5)
		return false;

	entity current = minigame.pp_curr_piece;
	if(!current)
		return true; // no current piece? allow the move anywhere

	int number = minigame_tile_number(pos);
	int letter = minigame_tile_letter(pos);

	if( (pp_find_piece(minigame,minigame_tile_buildname(letter-1,number)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter+1,number)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter,number-1)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter,number+1)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter+1,number+1)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter-1,number-1)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter+1,number-1)) == current)
	||	(pp_find_piece(minigame,minigame_tile_buildname(letter-1,number+1)) == current)
	) { return true; }

	return false;
}

// make a move
void pp_move(entity minigame, entity player, string pos )
{
	if ( minigame.minigame_flags & PP_TURN_PLACE )
	if ( pos && player.team == (minigame.minigame_flags & PP_TURN_TEAM) )
	{
		if ( pp_valid_move(minigame,pos))
		{
			entity existing = pp_find_piece(minigame,pos);

			if(existing && existing.team != 5)
			{
				if(existing.team == 1)
					minigame.pp_team1_score++;
				if(existing.team == 2)
					minigame.pp_team2_score++;
			}

			if(minigame.pp_curr_piece)
			{
				minigame.pp_curr_piece.cnt = 0;
				minigame.pp_curr_piece.team = 5;
				minigame_server_sendflags(minigame.pp_curr_piece,MINIG_SF_ALL);
			}

			if(existing)
			{
				if(existing.netname) { strunzone(existing.netname); }
				remove(existing);
			}

			entity piece = msle_spawn(minigame,"minigame_board_piece");
			piece.cnt = 1;
			piece.team = player.team; // temporary
			piece.netname = strzone(pos);
			minigame_server_sendflags(piece,MINIG_SF_ALL);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
			minigame.pp_nexteam = minigame_next_team(player.team,2);
			minigame.pp_curr_piece = piece;
			if ( pp_winning_piece(piece) )
			{
				if(minigame.pp_team1_score == minigame.pp_team2_score)
					minigame.minigame_flags = PP_TURN_DRAW;
				else
					minigame.minigame_flags = PP_TURN_WIN | ((minigame.pp_team1_score > minigame.pp_team2_score) ? 1 : 2);
			}
			else
				minigame.minigame_flags = PP_TURN_PLACE | minigame.pp_nexteam;
		}
	}
}

void pp_setup_pieces(entity minigame)
{
	int i, t; // letter, number
	for(i = 0; i < PP_LET_CNT; ++i)
	for(t = 0; t < PP_NUM_CNT; ++t)
	{
		bool t2_true = ((i == 0 || i == 6) && t > 0 && t < 6);
		bool t1_true = (i > 0 && i < 6 && (t == 0 || t == 6));

		if(t1_true || t2_true)
		{
			entity piece = msle_spawn(minigame,"minigame_board_piece");
			piece.team = ((t1_true) ? 1 : 2);
			piece.netname = strzone(minigame_tile_buildname(i,t));
			minigame_server_sendflags(piece,MINIG_SF_ALL);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		}
	}

	minigame.pp_curr_piece = world;
}

// request a new match
void pp_next_match(entity minigame, entity player)
{
#ifdef SVQC
	// on multiplayer matches, wait for both players to agree
	if ( minigame.minigame_flags & (PP_TURN_WIN|PP_TURN_DRAW) )
	{
		minigame.minigame_flags = PP_TURN_NEXT | player.team;
		minigame.SendFlags |= MINIG_SF_UPDATE;
	}
	else if ( (minigame.minigame_flags & PP_TURN_NEXT) &&
			!( minigame.minigame_flags & player.team ) )
#endif
	{
		minigame.minigame_flags = PP_TURN_PLACE | minigame.pp_nexteam;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		entity e = world;
		while ( ( e = findentity(e,owner,minigame) ) )
			if ( e.classname == "minigame_board_piece" )
				remove(e);
		minigame.pp_team1_score = 0;
		minigame.pp_team2_score = 0;

		pp_setup_pieces(minigame);
	}
}

#ifdef SVQC


// required function, handle server side events
int pp_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			minigame.minigame_flags = (PP_TURN_PLACE | PP_TURN_TEAM1);
			pp_setup_pieces(minigame);
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

			// Don't allow more than 2 players
			if(pl_num >= 2) { return false; }

			// Get the right team
			if(minigame.minigame_players)
				return minigame_next_team(minigame.minigame_players.team, 2);

			// Team 1 by default
			return 1;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "move":
					pp_move(minigame, ...(0,entity), ...(1,int) == 2 ? argv(1) : string_null );
					return true;
				case "next":
					pp_next_match(minigame,...(0,entity));
					return true;
			}

			return false;
		}
		case "network_send":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame" && (sf & MINIG_SF_UPDATE ) )
			{
				WriteByte(MSG_ENTITY,sent.pp_team1_score);
				WriteByte(MSG_ENTITY,sent.pp_team2_score);
			}
			else if(sent.classname == "minigame_board_piece")
				WriteByte(MSG_ENTITY,sent.cnt);
			return false;
		}
	}

	return false;
}


#elif defined(CSQC)

string pp_curr_pos; // identifier of the tile under the mouse
vector pp_boardpos; // HUD board position
vector pp_boardsize;// HUD board size
.int pp_checkwin; // Used to optimize checks to display a win

// Required function, draw the game board
void pp_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	pp_boardpos = pos;
	pp_boardsize = mySize;

	minigame_hud_simpleboard(pos,mySize,minigame_texture("pp/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0'/PP_TILE_SIZE,pos,mySize);
	vector tile_pos;

	active_minigame.pp_curr_piece = world;
	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	if(e.classname == "minigame_board_piece")
	if(e.cnt)
	{
		active_minigame.pp_curr_piece = e;
		break;
	}

	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,PP_LET_CNT,PP_NUM_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			vector tile_color = '1 1 1';
			switch(e.team)
			{
				case 1: tile_color = '1 0.3 0.3'; break;
				case 2: tile_color = '0.3 0.3 1'; break;
				// 3, 4 coming later?
			}

			string tile_name = strcat("pp/piece",ftos(e.team));
			if(e.team == 5) { tile_name = "pp/piece_taken"; }

			if(e == active_minigame.pp_curr_piece)
			{
				tile_name = "pp/piece_current";

				// draw the splat too
				minigame_drawpic_centered( tile_pos,
						minigame_texture("pp/piece_taken"),
						tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			}

			minigame_drawpic_centered( tile_pos,
					minigame_texture(tile_name),
					tile_size, tile_color, panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	if ( (active_minigame.minigame_flags & PP_TURN_TEAM) == minigame_self.team )
	if ( pp_valid_move(active_minigame, pp_curr_pos) )
	{
		tile_pos = minigame_tile_pos(pp_curr_pos,PP_LET_CNT,PP_NUM_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
		minigame_drawpic_centered( tile_pos,
				minigame_texture("pp/piece_current"),
				tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
	}
	else if(pp_valid_tile(pp_curr_pos))
	{
		tile_pos = minigame_tile_pos(pp_curr_pos,PP_LET_CNT,PP_NUM_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
		minigame_drawpic_centered( tile_pos,
				minigame_texture("pp/piece_selected"),
				tile_size, '1 1 1', panel_fg_alpha / 2, DRAWFLAG_NORMAL );
	}

	if ( active_minigame.minigame_flags & PP_TURN_WIN )
	{
		vector winfs = hud_fontsize*2;
		string playername = "";
		FOREACH_MINIGAME_ENTITY(e)
			if ( e.classname == "minigame_player" &&
					e.team == (active_minigame.minigame_flags & PP_TURN_TEAM) )
				playername = GetPlayerName(e.minigame_playerslot-1);

		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s^7 won the game!",playername),
			winfs, 0, DRAWFLAG_NORMAL, 0.5);

		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'1 1 1',0.5,DRAWFLAG_ADDITIVE);

		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s^7 won the game!",playername),
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}
}


// Required function, draw the game status panel
void pp_hud_status(vector pos, vector mySize)
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
	if ( (active_minigame.minigame_flags&PP_TURN_TEAM) == 2 )
		mypos_y  += player_fontsize_y + ts_y;
	drawfill(mypos,eX*mySize_x+eY*player_fontsize_y,'1 1 1',0.5,DRAWFLAG_ADDITIVE);
	mypos_y += player_fontsize_y;
	drawfill(mypos,eX*mySize_x+eY*tile_size_y,'1 1 1',0.25,DRAWFLAG_ADDITIVE);

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			vector tile_color = '1 1 1';
			switch(e.team)
			{
				case 1: tile_color = '1 0.3 0.3'; break;
				case 2: tile_color = '0.3 0.3 1'; break;
				// 3, 4 coming later?
			}

			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				GetPlayerName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			drawpic( mypos,
					minigame_texture(strcat("pp/piece",ftos(e.team))),
					tile_size, tile_color, panel_fg_alpha, DRAWFLAG_NORMAL );

			mypos_x += tile_size_x;
			int myscore = 0;
			if(e.team == 1) { myscore = active_minigame.pp_team1_score; }
			if(e.team == 2) { myscore = active_minigame.pp_team2_score; }

			drawstring(mypos,ftos(myscore),tile_size,
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string pp_turn_to_string(int turnflags)
{
	if ( turnflags & PP_TURN_DRAW )
		return _("Draw");

	if ( turnflags & PP_TURN_WIN )
	{
		if ( (turnflags&PP_TURN_TEAM) != minigame_self.team )
			return _("You lost the game!\nSelect \"^1Next Match^7\" on the menu for a rematch!");
		return _("You win!\nSelect \"^1Next Match^7\" on the menu to start a new match!");
	}

	if ( turnflags & PP_TURN_NEXT )
	{
		if ( (turnflags&PP_TURN_TEAM) != minigame_self.team )
			return _("Select \"^1Next Match^7\" on the menu to start a new match!");
		return _("Wait for your opponent to confirm the rematch");
	}

	if ( (turnflags & PP_TURN_TEAM) != minigame_self.team )
		return _("Wait for your opponent to make their move");

	if ( turnflags & PP_TURN_PLACE )
		return _("Click on the game board to place your piece");

	return "";
}

// Make the correct move
void pp_make_move(entity minigame)
{
	if ( minigame.minigame_flags == (PP_TURN_PLACE|minigame_self.team) )
	{
		minigame_cmd("move ",pp_curr_pos);
	}
}

void pp_set_curr_pos(string s)
{
	if ( pp_curr_pos )
		strunzone(pp_curr_pos);
	if ( s )
		s = strzone(s);
	pp_curr_pos = s;
}

// Required function, handle client events
int pp_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			pp_set_curr_pos("");
			minigame.message = pp_turn_to_string(minigame.minigame_flags);
			return false;
		}
		case "key_pressed":
		{
			if((minigame.minigame_flags & PP_TURN_TEAM) == minigame_self.team)
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if ( ! pp_curr_pos )
							pp_set_curr_pos("a3");
						else
							pp_set_curr_pos(minigame_relative_tile(pp_curr_pos,1,0,PP_LET_CNT,PP_NUM_CNT));
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if ( ! pp_curr_pos )
							pp_set_curr_pos("c3");
						else
							pp_set_curr_pos(minigame_relative_tile(pp_curr_pos,-1,0,PP_LET_CNT,PP_NUM_CNT));
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						if ( ! pp_curr_pos )
							pp_set_curr_pos("a1");
						else
							pp_set_curr_pos(minigame_relative_tile(pp_curr_pos,0,1,PP_LET_CNT,PP_NUM_CNT));
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						if ( ! pp_curr_pos )
							pp_set_curr_pos("a3");
						else
							pp_set_curr_pos(minigame_relative_tile(pp_curr_pos,0,-1,PP_LET_CNT,PP_NUM_CNT));
						return true;
					case K_ENTER:
					case K_KP_ENTER:
					case K_SPACE:
						pp_make_move(minigame);
						return true;
				}
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(...(0,int) == K_MOUSE1)
			{
				pp_make_move(minigame);
				return true;
			}

			return false;
		}
		case "mouse_moved":
		{
			vector mouse_pos = minigame_hud_normalize(mousepos,pp_boardpos,pp_boardsize);
			if ( minigame.minigame_flags == (PP_TURN_PLACE|minigame_self.team) )
				pp_set_curr_pos(minigame_tile_name(mouse_pos,PP_LET_CNT,PP_NUM_CNT));
			if ( ! pp_valid_tile(pp_curr_pos) )
				pp_set_curr_pos("");

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
					sent.message = pp_turn_to_string(sent.minigame_flags);
					if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
					sent.pp_team1_score = ReadByte();
					sent.pp_team2_score = ReadByte();
				}
			}
			else if(sent.classname == "minigame_board_piece")
			{
				sent.cnt = ReadByte();
				if(sent.cnt)
					minigame.pp_curr_piece = sent;
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
				minigame_cmd("next");
			return false;
		}
	}

	return false;
}

#endif
