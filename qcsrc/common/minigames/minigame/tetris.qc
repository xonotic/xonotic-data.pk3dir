#include "tetris.qh"
REGISTER_MINIGAME(tetris, "Tetris");

const float TETRIS_TURN_MOVE  = 0x0100; // player has to place a piece on the board
const float TETRIS_TURN_WIN   = 0x0200; // player has won
const float TETRIS_TURN_LOSS  = 0x0400; // no moves are possible

const int TETRIS_LET_CNT = 10;
const int TETRIS_NUM_CNT = 16;

const int TETRIS_TILE_SIZE = 16;

const int TETRIS_SHAPE_CNT = 7;

const int TET_DIR_UP = 0;
const int TET_DIR_DN = 1;
const int TET_DIR_LF = 2;
const int TET_DIR_RT = 3;

.bool tetris_inair; // flag to indicate whether the piece has landed and is no longer part of the moving pieces
.int tetris_shape; // flag to indicate which shape the piece is part of
.vector tetris_pos; // position in the shape the piece is
.int tetris_rotation; // player-chosen rotation of the controller

// bit diagram
// 0 1 2 3
// 0 1 2 3
vector tetris_shapes[TETRIS_SHAPE_CNT];

STATIC_INIT(tetris_set_shapes)
{
	tetris_shapes[0] = vec2(BIT(0) | BIT(1) | BIT(2) | BIT(3), 0); // I block
	tetris_shapes[1] = vec2(BIT(0), BIT(0) | BIT(1) | BIT(2)); // J block
	tetris_shapes[2] = vec2(BIT(2), BIT(0) | BIT(1) | BIT(2)); // L block
	tetris_shapes[3] = vec2(BIT(0) | BIT(1), BIT(0) | BIT(1)); // O block
	tetris_shapes[4] = vec2(BIT(1) | BIT(2), BIT(0) | BIT(1)); // S block
	tetris_shapes[5] = vec2(BIT(1), BIT(0) | BIT(1) | BIT(2)); // T block
	tetris_shapes[6] = vec2(BIT(0) | BIT(1), BIT(1) | BIT(2)); // Z block
}

// find connect 4 piece given its tile name
entity tetris_find_piece(entity minig, string tile)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile )
			return e;
	return NULL;
}

entity tetris_find_static_piece(entity minig, string tile)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile && !e.tetris_inair )
			return e;
	return NULL;
}

entity tetris_find_controller(entity minig)
{
	entity e = NULL;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "tetris_controller" )
			return e;
	return NULL;
}

// Checks if the given piece completes a row
bool tetris_winning_piece(entity piece)
{
	return false;
}

// check if the tile name is valid (6x7 grid)
bool tetris_valid_tile(string tile)
{
	if ( !tile )
		return false;
	float number = minigame_tile_number(tile);
	float letter = minigame_tile_letter(tile);
	return 0 <= number && number < TETRIS_NUM_CNT && 0 <= letter && letter < TETRIS_LET_CNT;
}

int tetris_dir_fromname(string bdir)
{
	if(bdir == "up" || bdir == "u")
		return TET_DIR_UP; // up
	if(bdir == "down" || bdir == "dn" || bdir == "d")
		return TET_DIR_DN; /// down
	if(bdir == "left" || bdir == "lt" || bdir == "l")
		return TET_DIR_LF; // left
	if(bdir == "right" || bdir == "rt" || bdir == "r")
		return TET_DIR_RT; // right

	return TET_DIR_RT; // invalid, just go right?
}

int tetris_pick_shape(int oldshape)
{
	RandomSelection_Init();

	for(int j = 0; j < TETRIS_SHAPE_CNT; ++j)
	{
		RandomSelection_AddFloat(j, ((oldshape == j) ? 0.5 : 1), 1);
	}

	return RandomSelection_chosen_float;
}

// same as spawn function, but checks spaces instead of spawning at them
bool tetris_checkspace(entity minigame, int shape, int rotation, int letter, int number)
{
	vector chosen = tetris_shapes[shape];

	for(int j = 0; j < 4; ++j)
	{
		if(chosen.x & BIT(j))
		{
			int newlet = letter;
			int newnum = number;
			if(rotation == 1)
				newnum += j;
			else if(rotation == 2)
				newlet -= j;
			else if(rotation == 3)
				newnum -= j;
			else
				newlet += j;
			string tile = minigame_tile_buildname(newlet, newnum);
			if(!tetris_valid_tile(tile) || tetris_find_static_piece(minigame, tile))
				return false;
		}
	}

	for(int j = 0; j < 4; ++j)
	{
		if(chosen.y & BIT(j))
		{
			int newlet = letter;
			int newnum = number;
			if(rotation == 1)
			{
				newnum += j;
				newlet -= 1;
			}
			else if(rotation == 2)
			{
				newlet -= j;
				newnum += 1;
			}
			else if(rotation == 3)
			{
				newnum -= j;
				newlet += 1;
			}
			else
			{
				newlet += j;
				newnum -= 1;
			}
			string tile = minigame_tile_buildname(newlet, newnum);
			if(!tetris_valid_tile(tile) || tetris_find_static_piece(minigame, tile))
				return false;
		}
	}

	return true;
}

entity tetris_spawn_piece(entity minigame, vector pos, int shape, int letter, int number)
{
	entity piece = msle_spawn(minigame,"minigame_board_piece");
	piece.tetris_inair = true;
	piece.tetris_shape = shape;
	piece.tetris_pos = pos;
	piece.team = 1; // TODO?
	piece.netname = strzone(minigame_tile_buildname(letter, number));
	minigame_server_sendflags(piece,MINIG_SF_ALL);

	return piece;
}

void tetris_spawn_shape(entity minigame, entity controller, int letter, int number, int shape, int rotation)
{
	vector chosen = tetris_shapes[shape];
	controller.tetris_shape = shape; // so we know which one is currently in play
	if(controller.netname) { strunzone(controller.netname); }
	controller.netname = strzone(minigame_tile_buildname(letter, number)); // keep tabs on the position of the clump

	if(!tetris_checkspace(minigame, shape, rotation, letter, number))
	{
		minigame.minigame_flags = TETRIS_TURN_LOSS;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		return;
	}

	for(int j = 0; j < 4; ++j)
	{
		if(chosen.x & BIT(j))
		{
			int newlet = letter;
			int newnum = number;
			if(rotation == 1)
				newnum += j;
			else if(rotation == 2)
				newlet -= j;
			else if(rotation == 3)
				newnum -= j;
			else
				newlet += j;
			tetris_spawn_piece(minigame, vec2(j, 0), shape, newlet, newnum);
		}
	}

	for(int j = 0; j < 4; ++j)
	{
		if(chosen.y & BIT(j))
		{
			int newlet = letter;
			int newnum = number;
			if(rotation == 1)
			{
				newnum += j;
				newlet -= 1;
			}
			else if(rotation == 2)
			{
				newlet -= j;
				newnum += 1;
			}
			else if(rotation == 3)
			{
				newnum -= j;
				newlet += 1;
			}
			else
			{
				newlet += j;
				newnum -= 1;
			}
			tetris_spawn_piece(minigame, vec2(0, j), shape, newlet, newnum);
		}
	}

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
}

void tetris_move_above(entity minigame, int startpos)
{
	for(int k = startpos; k < TETRIS_NUM_CNT; ++k)
	{
		for(int j = 0; j < TETRIS_LET_CNT; ++j)
		{
			string pos = minigame_tile_buildname(j, k - 1); // let's just assume this is a valid new position
			entity piece = tetris_find_static_piece(minigame, minigame_tile_buildname(j, k));
			if(piece && !wasfreed(piece))
			{
				if(piece.netname) { strunzone(piece.netname); }
				piece.netname = strzone(pos);
				minigame_server_sendflags(piece,MINIG_SF_UPDATE);
			}
		}
	}
}

void tetris_checkrows(entity minigame)
{
	for(int k = 0; k < TETRIS_NUM_CNT; ++k)
	{
		int found = 0;
		for(int j = 0; j < TETRIS_LET_CNT; ++j)
		{
			string pos = minigame_tile_buildname(j, k);
			entity piece = tetris_find_static_piece(minigame, pos);
			if(piece && !wasfreed(piece)) // due to the nature of this function, we'd better make sure it isn't already removed
				++found;
		}

		if(found >= TETRIS_LET_CNT)
		{
			// this is where things get messy: we need to remove the row, then loop through every row again!
			for(int j = 0; j < TETRIS_LET_CNT; ++j)
			{
				string pos = minigame_tile_buildname(j, k);
				entity piece = tetris_find_static_piece(minigame, pos);
				if(piece && !wasfreed(piece)) // just to make extra sure
				{
					if(piece.netname) { strunzone(piece.netname); }
					delete(piece);
				}
			}
			if(k < TETRIS_NUM_CNT - 1) // if it wasn't the top row, move everything above it down one
				tetris_move_above(minigame, k + 1);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
			tetris_checkrows(minigame);
			return; // no need to continue, the new loop will find new ones
		}
	}
}

void tetris_controller_think(entity this)
{
	entity minigame = this.owner;

	if(!(minigame.minigame_flags & TETRIS_TURN_MOVE))
		return;

	int letter = minigame_tile_letter(this.netname);
	int number = minigame_tile_number(this.netname) - 1;

	if(!tetris_checkspace(minigame, this.tetris_shape, this.tetris_rotation, letter, number))
	{
		entity e2 = NULL;
		while( (e2 = findentity(e2, owner, minigame)) )
			if(e2.classname == "minigame_board_piece" && e2.tetris_inair)
				e2.tetris_inair = false;

		int newshape = tetris_pick_shape(this.tetris_shape);
		this.tetris_rotation = 0; // reset rotation for the new shape
		tetris_spawn_shape(minigame, this, 4, TETRIS_NUM_CNT - 1, newshape, 0);

		tetris_checkrows(minigame);

		this.nextthink = time + 1;
		return;
	}

	string cpos = minigame_tile_buildname(letter, number);
	if(this.netname) { strunzone(this.netname); }
		this.netname = strzone(cpos);

	entity e = NULL;
	while ( ( e = findentity(e,owner,minigame) ) )
		if ( e.classname == "minigame_board_piece" && e.tetris_inair )
		{
			int pletter = minigame_tile_letter(e.netname);
			int pnumber = minigame_tile_number(e.netname);
			string newpos = minigame_tile_buildname(pletter, pnumber - 1);
			if(e.netname) { strunzone(e.netname); }
			e.netname = strzone(newpos);
			minigame_server_sendflags(e,MINIG_SF_UPDATE);
		}

	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

	this.nextthink = time + 0.75;
}

void tetris_begin(entity minigame)
{
	entity e = NULL;
	while( (e = findentity(e, owner, minigame)) )
		if(e.classname == "tetris_controller")
		{
			delete(e);
		}

	entity controller = new_pure(tetris_controller);
	controller.owner = minigame;
	setthink(controller, tetris_controller_think);
	controller.nextthink = time + 1; // begin moving down in a second

	int theshape = tetris_pick_shape(-1);
	tetris_spawn_shape(minigame, controller, 4, TETRIS_NUM_CNT - 1, theshape, 0);
}

// make a move
void tetris_move(entity minigame, entity player, string dir )
{
	if ( minigame.minigame_flags & TETRIS_TURN_MOVE )
	if ( dir )
	{
		string thedir = strtolower(dir);
		int bdir = tetris_dir_fromname(thedir);
		entity controller = tetris_find_controller(minigame);

		if(bdir == TET_DIR_RT || bdir == TET_DIR_LF)
		{
			int realdir = ((bdir == TET_DIR_LF) ? -1 : 1);
			int cletter = minigame_tile_letter(controller.netname) + realdir;
			int cnumber = minigame_tile_number(controller.netname);
			string cpos = minigame_tile_buildname(cletter, cnumber);
			if(!tetris_checkspace(minigame, controller.tetris_shape, controller.tetris_rotation, cletter, cnumber))
				return;

			if(controller.netname) { strunzone(controller.netname); }
			controller.netname = strzone(cpos);

			entity e = NULL;
			while ( ( e = findentity(e,owner,minigame) ) )
				if ( e.classname == "minigame_board_piece" && e.tetris_inair )
				{
					int pletter = minigame_tile_letter(e.netname);
					int pnumber = minigame_tile_number(e.netname);
					string newpos = minigame_tile_buildname(pletter + realdir, pnumber);
					if(e.netname) { strunzone(e.netname); }
					e.netname = strzone(newpos);
					minigame_server_sendflags(e,MINIG_SF_UPDATE);
				}

			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		}
		else if(bdir == TET_DIR_DN)
		{
			controller.nextthink = time + 0.1; // quicker fall
		}
		else if(bdir == TET_DIR_UP)
		{
			// this is where things get complicated
			// we need to somehow rotate the pieces...
			int oldrotation = controller.tetris_rotation;
			controller.tetris_rotation += 1;
			if(controller.tetris_rotation >= 4)
				controller.tetris_rotation = 0;

			int myletter = minigame_tile_letter(controller.netname);
			int mynumber = minigame_tile_number(controller.netname);
			if(!tetris_checkspace(minigame, controller.tetris_shape, controller.tetris_rotation, myletter, mynumber))
			{
				controller.tetris_rotation = oldrotation; // restore it so we aren't performing weird tests above
				return;
			}

			entity e3 = NULL;
			while ( ( e3 = findentity(e3,owner,minigame) ) )
				if ( e3.classname == "minigame_board_piece" && e3.tetris_inair )
				{
					if(e3.netname) { strunzone(e3.netname); }
					delete(e3);
				}

			tetris_spawn_shape(minigame, controller, myletter, mynumber, controller.tetris_shape, controller.tetris_rotation);
		}
	}
}

#ifdef SVQC


// required function, handle server side events
int tetris_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			tetris_begin(minigame);
			minigame.minigame_flags = TETRIS_TURN_MOVE;
			return true;
		}
		case "end":
		{
			entity e = NULL;
			while( (e = findentity(e, owner, minigame)) )
			if(e.classname == "minigame_board_piece")
			{
				if(e.netname) { strunzone(e.netname); }
				delete(e);
			}
			e = NULL;
			while( (e = findentity(e, owner, minigame)) )
			if(e.classname == "tetris_controller")
			{
				delete(e);
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
					tetris_move(minigame, ...(0,entity), ...(1,int) == 2 ? argv(1) : string_null );
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
				int letter = minigame_tile_letter(sent.netname);
				int number = minigame_tile_number(sent.netname);

				WriteByte(MSG_ENTITY,letter);
				WriteByte(MSG_ENTITY,number);

				WriteByte(MSG_ENTITY,sent.tetris_shape);
			}
			return false;
		}
	}

	return false;
}


#elif defined(CSQC)

vector tetris_boardpos; // HUD board position
vector tetris_boardsize;// HUD board size

vector tetris_shape_color(int shape)
{
	switch(shape)
	{
		case 0: return '0 1 1';
		case 1: return '0 0 1';
		case 2: return '1 0.5 0';
		case 3: return '1 1 0';
		case 4: return '0 0.5 0';
		case 5: return '0.5 0 0.5';
		case 6: return '1 0 0';
	}

	return '1 1 1';
}

#define tetris_hud_fitsquare(pos, mySize, xx) \
	if ( mySize##_x > mySize##_y ) \
	{ \
		pos##_x += (mySize##_x-(mySize##_y / xx))/2; \
		mySize##_x = mySize##_y / xx; \
	} \
	if(panel_bg_padding) \
	{ \
		pos += '1 1 0' * panel_bg_padding; \
		mySize -= '2 2 0' * panel_bg_padding; \
	}

// Required function, draw the game board
void tetris_hud_board(vector pos, vector mySize)
{
	float xsize = (TETRIS_NUM_CNT / TETRIS_LET_CNT);

	tetris_hud_fitsquare(pos, mySize, xsize);
	tetris_boardpos = pos;
	tetris_boardsize = mySize;

	minigame_hud_simpleboard(pos,mySize,minigame_texture("tetris/board"));

	vector tile_size = minigame_hud_denormalize_size(vec2(1 / TETRIS_LET_CNT, 1 / TETRIS_NUM_CNT),pos,mySize);
	vector tile_pos;

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			tile_pos = minigame_tile_pos(e.netname,TETRIS_NUM_CNT,TETRIS_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			minigame_drawpic_centered( tile_pos,
					minigame_texture("tetris/piece"),
					tile_size, tetris_shape_color(e.tetris_shape), panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	if ( active_minigame.minigame_flags & TETRIS_TURN_WIN )
	{
		vector winfs = hud_fontsize*2;
		string pname = "";
		FOREACH_MINIGAME_ENTITY(e)
			if ( e.classname == "minigame_player" )
			{
				pname = entcs_GetName(e.minigame_playerslot-1);
				break;
			}

		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s^7 won the game!",pname),
			winfs, 0, DRAWFLAG_NORMAL, 0.5);

		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'1 1 1',0.5,DRAWFLAG_ADDITIVE);

		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s^7 won the game!",pname),
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}
}


// Required function, draw the game status panel
void tetris_hud_status(vector pos, vector mySize)
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

	mypos = pos;
	//if ( (active_minigame.minigame_flags&TETRIS_TURN_TEAM) == 2 )
		//mypos_y  += player_fontsize_y + ts_y;
	drawfill(mypos,eX*mySize_x+eY*player_fontsize_y,'1 1 1',0.5,DRAWFLAG_ADDITIVE);
	mypos_y += player_fontsize_y;
	drawfill(mypos,eX*mySize_x+eY*tile_size_y,'1 1 1',0.25,DRAWFLAG_ADDITIVE);

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				entcs_GetName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			drawpic( mypos,
					minigame_texture("tetris/piece"),
					tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );

			mypos_x += tile_size_x;
		}
	}
}

// Turn a set of flags into a help message
string tetris_turn_to_string(int turnflags)
{
	if ( turnflags & TETRIS_TURN_LOSS )
		return _("Game over!");

	if ( turnflags & TETRIS_TURN_WIN )
		return _("You win!");

	if ( turnflags & TETRIS_TURN_MOVE )
		return _("Use the left and right arrows to move, up arrow to change orientation and down arrow to place the piece");

	return "";
}

// Make the correct move
void tetris_make_move(entity minigame, string dir)
{
	if ( minigame.minigame_flags & TETRIS_TURN_MOVE )
	{
		minigame_cmd("move ", dir);
	}
}

// Required function, handle client events
int tetris_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			minigame.message = tetris_turn_to_string(minigame.minigame_flags);
			return false;
		}
		case "key_pressed":
		{
			if(minigame.minigame_flags & TETRIS_TURN_MOVE)
			{
				switch(...(0,int))
				{
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						tetris_make_move(minigame, "r");
						return true;
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						tetris_make_move(minigame, "l");
						return true;
					case K_UPARROW:
					case K_KP_UPARROW:
						tetris_make_move(minigame, "u");
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
						tetris_make_move(minigame, "d");
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
					sent.message = tetris_turn_to_string(sent.minigame_flags);
				}
			}
			else if(sent.classname == "minigame_board_piece")
			{
				if(sf & MINIG_SF_UPDATE)
				{
					int letter = ReadByte();
					int number = ReadByte();
					if(sent.netname) { strunzone(sent.netname); }
					sent.netname = strzone(minigame_tile_buildname(letter, number));

					sent.tetris_shape = ReadByte();
				}
			}

			return false;
		}
	}

	return false;
}

#endif
