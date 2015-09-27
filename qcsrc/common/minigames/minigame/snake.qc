const float SNAKE_TURN_MOVE  = 0x0100; // the snake is moving, player must control it
const float SNAKE_TURN_LOSS  = 0x0200; // they did it?!
const float SNAKE_TURN_WAIT  = 0x0400; // the snake is waiting for the player to make their first move and begin the game
const float SNAKE_TURN_TYPE  = 0x0f00; // turn type mask

const int SNAKE_SF_PLAYERSCORE = MINIG_SF_CUSTOM;

const int SNAKE_LET_CNT = 15;
const int SNAKE_NUM_CNT = 15;

const int SNAKE_TILE_SIZE = 15;

bool autocvar_sv_minigames_snake_wrap = false;
float autocvar_sv_minigames_snake_delay_initial = 0.7;
float autocvar_sv_minigames_snake_delay_multiplier = 50;
float autocvar_sv_minigames_snake_delay_min = 0.1;

.int snake_score;
.entity snake_head;

.float snake_delay;
.float snake_nextmove;
.vector snake_dir;

// find same game piece given its tile name
entity snake_find_piece(entity minig, string tile)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return world;
}

// find same game piece given its cnt
entity snake_find_cnt(entity minig, int tile)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.cnt == tile )
			return e;
	return world;
}

// check if the tile name is valid (15x15 grid)
bool snake_valid_tile(string tile)
{
	if ( !tile )
		return false;
	int number = minigame_tile_number(tile);
	int letter = minigame_tile_letter(tile);
	return 0 <= number && number < SNAKE_NUM_CNT && 0 <= letter && letter < SNAKE_LET_CNT;
}

void snake_new_mouse(entity minigame)
{
	RandomSelection_Init();
	int i, j;
	for(i = 0; i < SNAKE_LET_CNT; ++i)
	for(j = 0; j < SNAKE_NUM_CNT; ++j)
	{
		string pos = minigame_tile_buildname(i, j);
		if(!snake_find_piece(minigame, pos))
			RandomSelection_Add(world, 0, pos, 1, 1);
	}

	entity piece = msle_spawn(minigame,"minigame_board_piece");
	piece.team = 1;
	piece.netname = strzone(RandomSelection_chosen_string);
	minigame_server_sendflags(piece,MINIG_SF_ALL);

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
}

void snake_setup_pieces(entity minigame)
{
	int targnum = bound(1, floor(random() * SNAKE_NUM_CNT), SNAKE_NUM_CNT - 1);
	int targlet = bound(1, floor(random() * SNAKE_LET_CNT), SNAKE_LET_CNT - 1);

	entity piece = msle_spawn(minigame,"minigame_board_piece");
	piece.team = 1; // init default team?
	piece.netname = strzone(minigame_tile_buildname(targlet,targnum));
	piece.cnt = 1;
	minigame_server_sendflags(piece,MINIG_SF_ALL);

	minigame.snake_head = piece;

	snake_new_mouse(minigame);

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
}

void snake_add_score(entity minigame, int thescore)
{
#ifdef SVQC
	if(!minigame)
		return;
	if(minigame.minigame_players)
	{
		minigame.minigame_players.snake_score += thescore;
		minigame.minigame_players.SendFlags |= SNAKE_SF_PLAYERSCORE;
	}
#endif
}

void snake_move_body(entity minigame, bool ate_mouse)
{
	entity tail = world;
	string tailpos = string_null;
	vector taildir = '0 0 0';

	int i, pieces = 0;
	for(i = (SNAKE_NUM_CNT * SNAKE_LET_CNT); i >= 2; --i)
	{
		entity piece = snake_find_cnt(minigame, i);
		entity nextpiece = snake_find_cnt(minigame, i - 1);
		if(!piece)
			continue;

		pieces++;

		if(!tail)
		{
			tail = piece;
			tailpos = piece.netname;
			taildir = piece.snake_dir;
		}

		if(piece.netname) { strunzone(piece.netname); }
		piece.netname = strzone(nextpiece.netname);
		piece.snake_dir = nextpiece.snake_dir;
		minigame_server_sendflags(piece, MINIG_SF_ALL);
	}

	// just a head
	if(!pieces)
	{
		tail = minigame.snake_head;
		tailpos = minigame.snake_head.netname;
		taildir = minigame.snake_head.snake_dir;
	}

	if(tail && ate_mouse)
	{
		int newcnt = tail.cnt + 1;
		minigame.snake_delay = max(autocvar_sv_minigames_snake_delay_min, autocvar_sv_minigames_snake_delay_initial - (newcnt / autocvar_sv_minigames_snake_delay_multiplier));
		snake_add_score(minigame, 1);

		entity piece = msle_spawn(minigame,"minigame_board_piece");
		piece.cnt = newcnt;
		piece.team = 1;
		piece.snake_dir = taildir;
		piece.netname = strzone(tailpos);
		minigame_server_sendflags(piece,MINIG_SF_ALL);

		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
	}
}

void snake_move_head(entity minigame)
{
	entity head = minigame.snake_head;
	string newpos;

	if(autocvar_sv_minigames_snake_wrap)
		newpos = minigame_relative_tile(head.netname, minigame.snake_dir_x, minigame.snake_dir_y, SNAKE_NUM_CNT, SNAKE_LET_CNT);
	else
	{
		int myx = minigame_tile_letter(head.netname);
		int myy = minigame_tile_number(head.netname);

		myx += minigame.snake_dir_x;
		myy += minigame.snake_dir_y;

		newpos = minigame_tile_buildname(myx, myy);
	}

	if(!snake_valid_tile(newpos) || (snake_find_piece(minigame, newpos)).cnt)
	{
		minigame.minigame_flags = SNAKE_TURN_LOSS;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		return;
	}

	bool ate_mouse = false;
	entity piece = snake_find_piece(minigame, newpos);
	if(piece && !piece.cnt)
		ate_mouse = true;

	// move the body first, then set the new head position?
	snake_move_body(minigame, ate_mouse);

	if(ate_mouse)
	{
		if(piece.netname) { strunzone(piece.netname); }
		remove(piece);

		snake_new_mouse(minigame);
	}

	if(head.netname) { strunzone(head.netname); }
	head.netname = strzone(newpos);
	minigame_server_sendflags(head,MINIG_SF_ALL);
}

// make a move
void snake_move(entity minigame, entity player, string dxs, string dys )
{
	if ( (minigame.minigame_flags & SNAKE_TURN_MOVE) || (minigame.minigame_flags & SNAKE_TURN_WAIT) )
	if ( dxs || dys )
	{
		//if ( snake_valid_tile(pos) )
		//if ( snake_find_piece(minigame, pos) )
		{
			int dx = ((dxs) ? bound(-1, stof(dxs), 1) : 0);
			int dy = ((dys) ? bound(-1, stof(dys), 1) : 0);

			int myl = minigame_tile_letter(minigame.snake_head.netname);
			int myn = minigame_tile_number(minigame.snake_head.netname);

			entity head = snake_find_piece(minigame, minigame_tile_buildname(myl + dx, myn + dy));
			if(head && head.cnt == 2)
				return; // nope!

			if(minigame.minigame_flags & SNAKE_TURN_WAIT)
				minigame.snake_nextmove = time;
			minigame.minigame_flags = SNAKE_TURN_MOVE;
			minigame.snake_dir_x = dx;
			minigame.snake_dir_y = dy;
			minigame.snake_dir_z = 0;
			minigame.snake_head.snake_dir = minigame.snake_dir;
			minigame_server_sendflags(minigame.snake_head,MINIG_SF_UPDATE);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		}
	}
}

#ifdef SVQC


// required function, handle server side events
int snake_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			snake_setup_pieces(minigame);
			minigame.snake_delay = autocvar_sv_minigames_snake_delay_initial;
			minigame.minigame_flags = SNAKE_TURN_WAIT;
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
			minigame.snake_head = world;
			return false;
		}
		case "join":
		{
			int pl_num = minigame_count_players(minigame);

			// Don't allow more than 1 player
			// not sure if this should be a multiplayer game (might get crazy)
			if(pl_num >= 1) { return false; }

			// Team 1 by default
			return 1;
		}
		case "frame":
		{
			if(minigame.minigame_flags & SNAKE_TURN_MOVE)
			if(time >= minigame.snake_nextmove)
			{
				snake_move_head(minigame);
				minigame.snake_nextmove = time + minigame.snake_delay;
			}
			return false;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "move": 
					snake_move(minigame, ...(0,entity), ((...(1,int)) >= 2 ? argv(1) : string_null), ((...(1,int)) == 3 ? argv(2) : string_null)); 
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
				WriteCoord(MSG_ENTITY,sent.snake_dir_x);
				WriteCoord(MSG_ENTITY,sent.snake_dir_y);
			}
			else if ( sent.classname == "minigame_player" && (sf & SNAKE_SF_PLAYERSCORE ) )
			{
				WriteLong(MSG_ENTITY,sent.snake_score);
			}
			else if ( sent.classname == "minigame" && (sf & MINIG_SF_UPDATE ) )
			{
				WriteByte(MSG_ENTITY,autocvar_sv_minigames_snake_wrap);
			}
			return false;
		}
	}
	
	return false;
}


#elif defined(CSQC)

vector snake_boardpos; // HUD board position
vector snake_boardsize;// HUD board size

bool snake_wrap;

// Required function, draw the game board
void snake_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	snake_boardpos = pos;
	snake_boardsize = mySize;
	
	minigame_hud_simpleboard(pos,mySize,minigame_texture("snake/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0' / SNAKE_TILE_SIZE,pos,mySize);
	vector tile_pos;

	entity tail = world;
	int i;
	for(i = (SNAKE_NUM_CNT * SNAKE_LET_CNT); i >= 2; --i)
	{
		entity piece = snake_find_cnt(active_minigame, i);
		if(piece)
		{
			tail = piece;
			break;
		}
	}

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,SNAKE_NUM_CNT,SNAKE_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
			string thepiece = "snake/mouse";
			if(e.cnt)
				thepiece = "snake/body";
			if(tail && e.cnt == tail.cnt)
				thepiece = "snake/tail";
			if(e.cnt == 1)
			{
				int dx = minigame_tile_letter(e.netname) + e.snake_dir_x * 2;
				int dy = minigame_tile_number(e.netname) + e.snake_dir_y * 2;
				entity mouse = snake_find_piece(active_minigame, minigame_tile_buildname(dx, dy));
				thepiece = "snake/head";
				if(mouse && !mouse.cnt)
				{
					float myang = 0;
					int myx = minigame_tile_letter(e.netname);
					int myy = minigame_tile_number(e.netname);
					if(myx - 2 == dx)
						myang = M_PI*3/2;
					if(myx + 2 == dx)
						myang = M_PI/2;
					if(myy - 2 == dy)
						myang = M_PI;

					int newx = minigame_tile_letter(e.netname) + e.snake_dir_x;
					int newy = minigame_tile_number(e.netname) + e.snake_dir_y;
					string newpos = minigame_tile_buildname(newx, newy);

					vector my_pos = minigame_tile_pos(newpos,SNAKE_NUM_CNT,SNAKE_LET_CNT);
					my_pos = minigame_hud_denormalize(my_pos,pos,mySize);

					drawrotpic(my_pos, myang, minigame_texture("snake/tongue"),
							tile_size, tile_size/2, '1 1 1',
							panel_fg_alpha, DRAWFLAG_NORMAL );
				}
			}

			if(e.cnt == 1 || e.cnt == tail.cnt)
			{
				vector thedir = e.snake_dir;
				float theang = 0;
				if(e.cnt == tail.cnt)
				{
					int thex = minigame_tile_letter(e.netname);
					int they = minigame_tile_number(e.netname);
					entity t = snake_find_cnt(active_minigame, e.cnt - 1);
					int tx = minigame_tile_letter(t.netname);
					int ty = minigame_tile_number(t.netname);

					if(thex - 1 == tx)
					{
						thedir_y = 0;
						thedir_x = -1;
					}
					if(they + 1 == ty)
					{
						thedir_x = 0;
						thedir_y = 1;
					}
					if(they - 1 == ty)
					{
						thedir_x = 0;
						thedir_y = -1;
					}
				}

				if(thedir_y == -1)
					theang = M_PI;
				if(thedir_x == 1)
					theang = M_PI/2;
				if(thedir_x == -1)
					theang = M_PI*3/2;

				drawrotpic(tile_pos, theang, minigame_texture(thepiece),
							tile_size, tile_size/2, '1 1 1',
							panel_fg_alpha, DRAWFLAG_NORMAL );
			}
			else
			{
				minigame_drawpic_centered( tile_pos,  
						minigame_texture(thepiece),
						tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			}
		}
	}

	if ( active_minigame.minigame_flags & SNAKE_TURN_LOSS )
	{
		int scores = 0;
		FOREACH_MINIGAME_ENTITY(e)
			if(e.classname == "minigame_player")
				scores = e.snake_score;

		vector winfs = hud_fontsize*2;
		string scores_text;
		scores_text = strcat("Score: ", ftos(scores));
		
		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("Game over! %s", scores_text), 
			winfs, 0, DRAWFLAG_NORMAL, 0.5);
		
		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'0.3 0.3 1',0.8,DRAWFLAG_ADDITIVE);
		
		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("Game over! %s", scores_text), 
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}
}


// Required function, draw the game status panel
void snake_hud_status(vector pos, vector mySize)
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
			//		minigame_texture("snake/piece"),
			//		tile_size, '1 0 0', panel_fg_alpha, DRAWFLAG_NORMAL );
			
			//mypos_x += tile_size_x;

			drawstring(mypos,ftos(e.snake_score),tile_size,
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string snake_turn_to_string(int turnflags)
{
	if ( turnflags & SNAKE_TURN_LOSS )
		return _("Game over!");
	
	if ( turnflags & SNAKE_TURN_WAIT )
		return _("Press an arrow key to begin the game");

	if ( turnflags & SNAKE_TURN_MOVE )
		if(snake_wrap)
			return _("Avoid the snake's body, collect the mice!");
		else
			return _("Avoid the screen edges and the snake's body, collect the mice!");
	
	return "";
}

// Make the correct move
void snake_set_direction(entity minigame, int dx, int dy)
{
	//if ( minigame.minigame_flags == SNAKE_TURN_MOVE )
	//{
		minigame_cmd("move ",ftos(dx), " ", ftos(dy));
	//}
}

// Required function, handle client events
int snake_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			minigame.message = snake_turn_to_string(minigame.minigame_flags);
			return false;
		}
		case "key_pressed":
		{
			//if((minigame.minigame_flags & SNAKE_TURN_TEAM) == minigame_self.team)
			{
				switch ( ...(0,int) )
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						snake_set_direction(minigame, 1, 0);
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						snake_set_direction(minigame, -1, 0);
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						snake_set_direction(minigame, 0, 1);
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						snake_set_direction(minigame, 0, -1);
						return true;
				}
			}

			return false;
		}
		case "network_receive":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame" )
			{
				if ( sf & MINIG_SF_UPDATE )
				{
					snake_wrap = ReadByte();
					sent.message = snake_turn_to_string(sent.minigame_flags);
					//if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
				}
			}
			else if(sent.classname == "minigame_board_piece")
			{
				if(sf & MINIG_SF_UPDATE)
				{
					sent.cnt = ReadByte();
					sent.snake_dir_x = ReadCoord();
					sent.snake_dir_y = ReadCoord();
					sent.snake_dir_z = 0;
					if(sent.cnt == 1)
						minigame.snake_head = sent; // hax
				}
			}
			else if ( sent.classname == "minigame_player" && (sf & SNAKE_SF_PLAYERSCORE ) )
			{
				sent.snake_score = ReadLong();
			}

			return false;
		}
	}

	return false;
}

#endif