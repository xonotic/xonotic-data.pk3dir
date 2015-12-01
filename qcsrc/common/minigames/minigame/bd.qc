REGISTER_MINIGAME(bd, "Bulldozer");

const int BD_TURN_MOVE  = 0x0100; // player must move the bulldozer
const int BD_TURN_WIN   = 0x0200; // victory
const int BD_TURN_LOSS  = 0x0400; // they did it?!
const int BD_TURN_EDIT  = 0x0800; // editing mode
const int BD_TURN_TYPE  = 0x0f00; // turn type mask

const int BD_SF_PLAYERMOVES = MINIG_SF_CUSTOM;

// 240 tiles...
const int BD_LET_CNT = 20;
const int BD_NUM_CNT = 20;

const int BD_TILE_SIZE = 20;

const int BD_TEAMS = 1;

.vector bd_dir;

.int bd_moves;

.string bd_levelname;
.string bd_nextlevel;

#ifdef SVQC
.bool bd_canedit;
#endif

.int bd_tiletype;
const int BD_TILE_DOZER = 1;
const int BD_TILE_TARGET = 2;
const int BD_TILE_BOULDER = 3;
const int BD_TILE_BRICK1 = 4;
const int BD_TILE_BRICK2 = 5;
const int BD_TILE_BRICK3 = 6;
const int BD_TILE_BRICK4 = 7;
const int BD_TILE_BRICK5 = 8;
const int BD_TILE_BRICK6 = 9;
const int BD_TILE_BRICK7 = 10;
const int BD_TILE_BRICK8 = 11;
const int BD_TILE_LAST = 11;

string autocvar_sv_minigames_bulldozer_startlevel = "level1";

// find same game piece given its tile name
entity bd_find_piece(entity minig, string tile, bool check_target)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.netname == tile && ((check_target) ? e.bd_tiletype == BD_TILE_TARGET : e.bd_tiletype != BD_TILE_TARGET) )
			return e;
	return world;
}

// check if the tile name is valid (15x15 grid)
bool bd_valid_tile(string tile)
{
	if ( !tile )
		return false;
	int number = minigame_tile_number(tile);
	int letter = minigame_tile_letter(tile);
	return 0 <= number && number < BD_NUM_CNT && 0 <= letter && letter < BD_LET_CNT;
}

entity bd_find_dozer(entity minig)
{
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.bd_tiletype == BD_TILE_DOZER )
			return e;
	return world;
}

void bd_check_winner(entity minig)
{
	int total = 0, valid = 0;
	entity e = world;
	while ( ( e = findentity(e,owner,minig) ) )
		if ( e.classname == "minigame_board_piece" && e.bd_tiletype == BD_TILE_TARGET )
		{
			++total;
			if(bd_find_piece(minig, e.netname, false).bd_tiletype == BD_TILE_BOULDER)
				++valid;
		}

	if(valid >= total)
	{
		minig.minigame_flags = BD_TURN_WIN;
		minigame_server_sendflags(minig,MINIG_SF_UPDATE);
	}
}

bool bd_canfill(int ttype)
{
	switch(ttype)
	{
		case BD_TILE_BRICK8:
		case BD_TILE_BRICK7:
		case BD_TILE_BRICK6:
		case BD_TILE_BRICK5:
		case BD_TILE_BRICK4:
		case BD_TILE_BRICK3:
		case BD_TILE_BRICK2:
		case BD_TILE_BRICK1: return true;
	}

	return false;
}

bool bd_move_dozer(entity minigame, entity dozer)
{
	if(!dozer.bd_dir_x && !dozer.bd_dir_y)
		return false; // nope!

	int myx = minigame_tile_letter(dozer.netname);
	int myy = minigame_tile_number(dozer.netname);

	myx += dozer.bd_dir_x;
	myy += dozer.bd_dir_y;

	string newpos = minigame_tile_buildname(myx, myy);
	entity hit = bd_find_piece(minigame, newpos, false);

	if(!bd_valid_tile(newpos))
		return false;

	if(hit)
	switch(hit.bd_tiletype)
	{
		case BD_TILE_DOZER: // wtf, but let's do this incase
		case BD_TILE_BRICK8:
		case BD_TILE_BRICK7:
		case BD_TILE_BRICK6:
		case BD_TILE_BRICK5:
		case BD_TILE_BRICK4:
		case BD_TILE_BRICK3:
		case BD_TILE_BRICK2:
		case BD_TILE_BRICK1: return false;
		case BD_TILE_BOULDER:
		{
			string testpos;
			int tx = minigame_tile_letter(hit.netname);
			int ty = minigame_tile_number(hit.netname);

			tx += dozer.bd_dir_x;
			ty += dozer.bd_dir_y;

			testpos = minigame_tile_buildname(tx, ty);
			entity testhit = bd_find_piece(minigame, testpos, false);

			if(!bd_valid_tile(testpos) || testhit)
				return false;

			if(hit.netname) { strunzone(hit.netname); }
			hit.netname = strzone(testpos);
			minigame_server_sendflags(hit,MINIG_SF_UPDATE);
			break;
		}
	}

	if(dozer.netname) { strunzone(dozer.netname); }
	dozer.netname = strzone(newpos);

	return true;
}

// make a move
void bd_move(entity minigame, entity player, string dir)
{
	if ( minigame.minigame_flags & BD_TURN_MOVE )
	if ( dir )
	{
		//if ( bd_valid_tile(pos) )
		//if ( bd_find_piece(minigame, pos, false) )
		{
			entity dozer = bd_find_dozer(minigame);
			if(!dozer)
			{
				LOG_INFO("Dozer wasn't found!\n");
				return; // should not happen... TODO: end match?
			}

			int dxs = 0, dys = 0;
			string thedir = strtolower(dir);
			if(thedir == "up" || thedir == "u") { dxs = 0; dys = 1; }
			if(thedir == "down" || thedir == "dn" || thedir == "d") { dxs = 0; dys = -1; }
			if(thedir == "left" || thedir == "lt" || thedir == "l") { dxs = -1; dys = 0; }
			if(thedir == "right" || thedir == "rt" || thedir == "r") { dxs = 1; dys = 0; }

			int dx = bound(-1, dxs, 1);
			int dy = bound(-1, dys, 1);

			dozer.bd_dir_x = dx;
			dozer.bd_dir_y = dy;
			dozer.bd_dir_z = 0;

			if(bd_move_dozer(minigame, dozer))
				player.bd_moves++;

			bd_check_winner(minigame);

			minigame_server_sendflags(dozer,MINIG_SF_UPDATE); // update anyway
			minigame_server_sendflags(player,BD_SF_PLAYERMOVES);
			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		}
	}
}

// editor
void bd_editor_place(entity minigame, entity player, string pos, int thetile, string thedir)
{
	if ( minigame.minigame_flags & BD_TURN_EDIT )
	if ( pos && thetile )
	{
		if ( bd_valid_tile(pos) )
		{
			entity found_piece = bd_find_piece(minigame, pos, false);
			entity targ = bd_find_piece(minigame, pos, true);

			if(found_piece.bd_tiletype == BD_TILE_DOZER && thedir != "")
			{
				int dxs = 0, dys = 0;
				string newdir = strtolower(thedir);
				if(newdir == "up" || newdir == "u") { dxs = 0; dys = 1; }
				if(newdir == "down" || newdir == "dn" || newdir == "d") { dxs = 0; dys = -1; }
				if(newdir == "left" || newdir == "lt" || newdir == "l") { dxs = -1; dys = 0; }
				if(newdir == "right" || newdir == "rt" || newdir == "r") { dxs = 1; dys = 0; }

				int dx = bound(-1, dxs, 1);
				int dy = bound(-1, dys, 1);

				found_piece.bd_dir_x = dx;
				found_piece.bd_dir_y = dy;
				found_piece.bd_dir_z = 0;
				minigame_server_sendflags(found_piece,MINIG_SF_UPDATE); // update anyway
				return;
			}

			entity dozer = bd_find_dozer(minigame);
			if(dozer && thetile == BD_TILE_DOZER && pos != dozer.netname)
				return; // nice try

			if(found_piece || (targ && thetile != BD_TILE_BOULDER))
			{
				entity piece = bd_find_piece(minigame, pos, false);
				if(!piece) piece = bd_find_piece(minigame, pos, true);
				if(!piece)
					return; // how?!

				if(piece.netname) { strunzone(piece.netname); }
				remove(piece);
				minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
				return;
			}

			entity piece = msle_spawn(minigame,"minigame_board_piece");
			piece.team = 1;
			piece.netname = strzone(pos);
			piece.bd_tiletype = thetile;
			piece.bd_dir = '0 -1 0';
			minigame_server_sendflags(piece,MINIG_SF_UPDATE);

			minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
		}
	}
}

void bd_do_move(entity minigame, entity player, string dir, string thetile, string thedir)
{
	if(minigame.minigame_flags & BD_TURN_MOVE)
		bd_move(minigame, player, dir);

	if(minigame.minigame_flags & BD_TURN_EDIT)
		bd_editor_place(minigame, player, dir, stof(thetile), thedir);
}

void bd_fill_recurse(entity minigame, entity player, int thetype, int letter, int number)
{
	string pos = minigame_tile_buildname(letter,number);
	if(!bd_valid_tile(pos))
		return;
	if(bd_find_piece(minigame, pos, false) || bd_find_piece(minigame, pos, true))
		return;

	bd_editor_place(minigame, player, pos, thetype, "");

	bd_fill_recurse(minigame, player, thetype, letter - 1, number);
	bd_fill_recurse(minigame, player, thetype, letter + 1, number);
	bd_fill_recurse(minigame, player, thetype, letter, number - 1);
	bd_fill_recurse(minigame, player, thetype, letter, number + 1);
}

void bd_unfill_recurse(entity minigame, entity player, int thetype, int letter, int number)
{
	string pos = minigame_tile_buildname(letter,number);
	if(!bd_valid_tile(pos))
		return;

	entity targ = bd_find_piece(minigame, pos, true);
	entity piece = bd_find_piece(minigame, pos, false);

	if(targ && thetype == targ.bd_tiletype)
	{
		if(targ.netname) { strunzone(targ.netname); }
		remove(targ);
	}
	else if(piece && thetype == piece.bd_tiletype)
	{
		if(piece.netname) { strunzone(piece.netname); }
		remove(piece);
	}
	else return;

	bd_unfill_recurse(minigame, player, thetype, letter - 1, number);
	bd_unfill_recurse(minigame, player, thetype, letter + 1, number);
	bd_unfill_recurse(minigame, player, thetype, letter, number - 1);
	bd_unfill_recurse(minigame, player, thetype, letter, number + 1);
}

void bd_do_fill(entity minigame, entity player, string dir, string thetile)
{
	if(minigame.minigame_flags & BD_TURN_EDIT)
	{
		int thetype = stof(thetile);

		entity targ = bd_find_piece(minigame, dir, true);
		entity piece = bd_find_piece(minigame, dir, false);

		if(!bd_canfill(thetype) || (piece || targ))
		{
			int killtype = 0;

			if(targ) { killtype = targ.bd_tiletype; }
			if(piece) { killtype = piece.bd_tiletype; }

			if(killtype)
			{
				int letter = minigame_tile_letter(dir);
				int number = minigame_tile_number(dir);
				bd_unfill_recurse(minigame, player, killtype, letter, number);
			}

			return;
		}

		int letter = minigame_tile_letter(dir);
		int number = minigame_tile_number(dir);

		bd_fill_recurse(minigame, player, thetype, letter, number);
	}
}

void bd_reset_moves(entity minigame)
{
	entity e;
#ifdef SVQC
	for(e = minigame.minigame_players; e; e = e.list_next)
#elif defined(CSQC)
	e = world;
	while( (e = findentity(e,owner,minigame)) )
		if ( e.classname == "minigame_player" )
#endif
		{
			e.bd_moves = 0;
			minigame_server_sendflags(e,BD_SF_PLAYERMOVES);
		}
}

void bd_load_level(entity minigame);
void bd_setup_pieces(entity minigame)
{
	entity e = world;
	while( (e = findentity(e, owner, minigame)) )
		if(e.classname == "minigame_board_piece")
		{
			if(e.netname) { strunzone(e.netname); }
			remove(e);
		}

	bd_load_level(minigame);
}

void bd_do_next_match(entity minigame, entity player)
{
	minigame.minigame_flags = BD_TURN_MOVE;
	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

	if(minigame.bd_nextlevel && minigame.bd_nextlevel != "")
	{
		if(minigame.bd_levelname) { strunzone(minigame.bd_levelname); }
		minigame.bd_levelname = strzone(minigame.bd_nextlevel);
	}

	bd_setup_pieces(minigame);

	bd_reset_moves(minigame);
}

void bd_set_next_match(entity minigame, string next)
{
	if(minigame.bd_nextlevel) { strunzone(minigame.bd_nextlevel); }
	minigame.bd_nextlevel = strzone(next);
}

void bd_next_match(entity minigame, entity player, string next)
{
	if(minigame.minigame_flags & BD_TURN_WIN)
		bd_do_next_match(minigame, player);
	if(minigame.minigame_flags & BD_TURN_EDIT)
		bd_set_next_match(minigame, next);
}

// request a new match
void bd_restart_match(entity minigame, entity player)
{
	minigame.minigame_flags = BD_TURN_MOVE;
	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

	bd_setup_pieces(minigame);

	bd_reset_moves(minigame);
}

void bd_activate_editor(entity minigame, entity player)
{
#ifdef SVQC
	if(!player.minigame_players.bd_canedit)
	{
		sprint(player.minigame_players, "You're not allowed to edit levels, sorry!\n");
		return;
	}
#endif

	minigame.minigame_flags = BD_TURN_EDIT;
	minigame_server_sendflags(minigame,MINIG_SF_UPDATE);

	bd_reset_moves(minigame);

	bd_setup_pieces(minigame);
}

string bd_save_piece(entity minigame, entity e)
{
	string bd_string = "";

	bd_string = strcat(bd_string, "\"", e.netname, "\" ");
	bd_string = strcat(bd_string, ftos(e.bd_tiletype), " ");
	bd_string = strcat(bd_string, sprintf("\"%.9v\"", e.bd_dir));

	return bd_string;
}

void bd_set_nextlevel(entity minigame, string s)
{
	tokenize_console(s);

	if(minigame.bd_nextlevel) { strunzone(minigame.bd_nextlevel); }
	minigame.bd_nextlevel = strzone(argv(2));
}

entity bd_load_piece(entity minigame, string s)
{
	// separate pieces between the ; symbols
	string bd_string = s;

	tokenize_console(bd_string);

	entity e = msle_spawn(minigame,"minigame_board_piece");
	e.team = 1;
	e.bd_dir = '0 -1 0';

	int argv_num = 0;
	e.netname = strzone(argv(argv_num)); ++argv_num;
	e.bd_tiletype = stof(argv(argv_num)); ++argv_num;
	e.bd_dir = stov(argv(argv_num)); ++argv_num;

	minigame_server_sendflags(e,MINIG_SF_ALL);

	return e;
}

bool bd_save_level(entity minigame)
{
	if(minigame.bd_levelname && minigame.bd_levelname != "")
	{
		int target_count = 0, boulder_count = 0;
		entity piece = world;
		while((piece = findentity(piece,owner,minigame)))
		if(piece.classname == "minigame_board_piece")
			if(piece.bd_tiletype == BD_TILE_BOULDER)
				++boulder_count;
			else if(piece.bd_tiletype == BD_TILE_TARGET)
				++target_count;

		if(boulder_count != target_count)
		{
			LOG_INFO("Not enough targets or boulders, fix your level!\n");
			return false;
		}

		// saves all objects to the database file
		string file_name;
		float file_get;

		file_name = strcat("minigames/bulldozer/storage_", minigame.bd_levelname, ".txt");
		file_get = fopen(file_name, FILE_WRITE);
		fputs(file_get, strcat("// bulldozer storage \"", minigame.bd_levelname, "\" last updated ", strftime(true, "%d-%m-%Y %H:%M:%S"), "\n"));

		if(minigame.bd_nextlevel && minigame.bd_nextlevel != "" && fexists(strcat("minigames/bulldozer/storage_", minigame.bd_nextlevel, ".txt")))
			fputs(file_get, strcat("nextlevel = \"", minigame.bd_nextlevel, "\"\n"));

		entity e = world;
		while ( ( e = findentity(e,owner,minigame) ) )
		if ( e.classname == "minigame_board_piece" )
		{
			// use a line of text for each object, listing all properties
			fputs(file_get, strcat(bd_save_piece(minigame, e), "\n"));
		}
		fclose(file_get);

		return true;
	}

	return false;
}

void bd_load_level(entity minigame)
{
	// loads all items from the database file
	string file_read, file_name;
	float file_get;

	file_name = strcat("minigames/bulldozer/storage_", minigame.bd_levelname, ".txt");
	file_get = fopen(file_name, FILE_READ);
	if(file_get < 0)
	{
		LOG_INFO("^3BULLDOZER: ^7could not find storage file ^3", file_name, "^7, no items were loaded\n");
	}
	else
	{
		for(;;)
		{
			file_read = fgets(file_get);
			if(file_read == "")
				break;
			if(substring(file_read, 0, 2) == "//")
				continue;
			if(substring(file_read, 0, 1) == "#")
				continue;
			if(substring(file_read, 0, 9) == "nextlevel")
			{
				bd_set_nextlevel(minigame, file_read);
				continue;
			}

			entity e;
			e = bd_load_piece(minigame, file_read);
		}
	}
	fclose(file_get);
}

void bd_close_editor(entity minigame)
{
	entity dozer = bd_find_dozer(minigame);
	if(!dozer)
	{
		LOG_INFO("You need to place a bulldozer on the level to save it!\n");
		return;
	}

	if(bd_save_level(minigame))
	{
		minigame.minigame_flags = BD_TURN_MOVE;
		minigame_server_sendflags(minigame,MINIG_SF_UPDATE);
	}
	else
	{
		LOG_INFO("You need to set the level name!\n");
		return;
	}
}

#ifdef SVQC

// required function, handle server side events
int bd_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			if(minigame.bd_levelname) { strunzone(minigame.bd_levelname); }
			minigame.bd_levelname = strzone(autocvar_sv_minigames_bulldozer_startlevel);
			bd_setup_pieces(minigame);
			minigame.minigame_flags = BD_TURN_MOVE;
			
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

			if(minigame.bd_nextlevel) { strunzone(minigame.bd_nextlevel); }
			if(minigame.bd_levelname) { strunzone(minigame.bd_levelname); }
			return false;
		}
		case "join":
		{
			int pl_num = minigame_count_players(minigame);

			if(pl_num >= BD_TEAMS) { return false; }

			return 1;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "move":
					bd_do_move(minigame, ...(0,entity), ((...(1,int)) >= 2 ? argv(1) : string_null), ((...(1,int)) >= 3 ? argv(2) : string_null), ((...(1,int)) >= 4 ? argv(3) : string_null)); 
					return true;
				case "next":
					bd_next_match(minigame,...(0,entity), ((...(1,int) >= 2 ? argv(1) : string_null)));
					return true;
				case "restart":
					bd_restart_match(minigame,...(0,entity));
					return true;
				case "edit":
					bd_activate_editor(minigame,...(0,entity));
					return true;
				case "save":
					bd_close_editor(minigame);
					return true;
				case "fill":
					bd_do_fill(minigame, ...(0,entity), ((...(1,int)) >= 2 ? argv(1) : string_null), ((...(1,int)) >= 3 ? argv(2) : string_null)); 
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

				WriteByte(MSG_ENTITY,sent.bd_tiletype);

				int dx = sent.bd_dir_x;
				int dy = sent.bd_dir_y;
				if(dx == -1) dx = 2;
				if(dy == -1) dy = 2;
				WriteByte(MSG_ENTITY,dx);
				WriteByte(MSG_ENTITY,dy);
			}
			else if(sent.classname == "minigame_player" && (sf & BD_SF_PLAYERMOVES))
				WriteShort(MSG_ENTITY,sent.bd_moves);
			return false;
		}
	}
	
	return false;
}


#elif defined(CSQC)

int bd_curr_tile;
string bd_curr_pos;

.entity bd_enemy;
.bool bd_hide;

vector bd_boardpos; // HUD board position
vector bd_boardsize;// HUD board size

string bd_get_tile_pic(int tileid)
{
	switch(tileid)
	{
		case BD_TILE_BOULDER: return "bd/boulder";
		case BD_TILE_BRICK1: return "bd/brick1";
		case BD_TILE_BRICK2: return "bd/brick2";
		case BD_TILE_BRICK3: return "bd/brick3";
		case BD_TILE_BRICK4: return "bd/brick4";
		case BD_TILE_BRICK5: return "bd/brick5";
		case BD_TILE_BRICK6: return "bd/brick6";
		case BD_TILE_BRICK7: return "bd/brick7";
		case BD_TILE_BRICK8: return "bd/brick8";
		case BD_TILE_TARGET: return "bd/target";
		case BD_TILE_DOZER: return "bd/dozer";
	}

	return string_null;
}

// Required function, draw the game board
void bd_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	bd_boardpos = pos;
	bd_boardsize = mySize;
	
	minigame_hud_simpleboard(pos,mySize,minigame_texture("bd/board"));

	vector tile_size = minigame_hud_denormalize_size('1 1 0' / BD_TILE_SIZE,pos,mySize);
	vector tile_pos;

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if(e.classname == "minigame_board_piece")
		{
			if(e.bd_tiletype == BD_TILE_TARGET)
			{
				e.bd_enemy = world;
				e.bd_enemy = bd_find_piece(active_minigame, e.netname, false);
			}
			else if(e.bd_tiletype == BD_TILE_BOULDER)
			{
				e.bd_hide = false; // reset either way
				e.bd_hide = ((bd_find_piece(active_minigame, e.netname, true)) != world);
			}
		}
	}
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" )
		{
			if(e.bd_tiletype != BD_TILE_DOZER && !e.bd_hide) // hide boulders
			{
				tile_pos = minigame_tile_pos(e.netname,BD_NUM_CNT,BD_LET_CNT);
				tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

				string thepiece = bd_get_tile_pic(e.bd_tiletype);

				if(e.bd_enemy)
					thepiece = "bd/boulder_target";

				minigame_drawpic_centered( tile_pos,  
						minigame_texture(thepiece),
						tile_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			}	
		}
	}

	// draw dozers on top, always
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_board_piece" && e.bd_tiletype == BD_TILE_DOZER )
		{
			tile_pos = minigame_tile_pos(e.netname,BD_NUM_CNT,BD_LET_CNT);
			tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);

			vector thedir = e.bd_dir;
			float theang = 0;

			if(thedir_y == -1) { theang = M_PI; }
			if(thedir_x == 1) { theang = M_PI/2; }
			if(thedir_x == -1) { theang = M_PI*3/2; }

			drawrotpic(tile_pos, theang, minigame_texture("bd/dozer"),
						tile_size, tile_size/2, '1 1 1',
						panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	if(active_minigame.minigame_flags & BD_TURN_EDIT)
	if(bd_valid_tile(bd_curr_pos))
	{
		entity piece = bd_find_piece(active_minigame, bd_curr_pos, false);
		entity targ = bd_find_piece(active_minigame, bd_curr_pos, true);
		string thepiece = ((piece || (targ && bd_curr_tile != BD_TILE_BOULDER)) ? "bd/delete" : bd_get_tile_pic(bd_curr_tile));

		tile_pos = minigame_tile_pos(bd_curr_pos,BD_LET_CNT,BD_NUM_CNT);
		tile_pos = minigame_hud_denormalize(tile_pos,pos,mySize);
		if(bd_curr_tile == BD_TILE_DOZER)
		{
			drawrotpic(tile_pos, M_PI, minigame_texture("bd/dozer"),
						tile_size, tile_size/2, '1 1 1',
						panel_fg_alpha/2, DRAWFLAG_NORMAL );
		}
		else
		{
			minigame_drawpic_centered( tile_pos,
					minigame_texture(thepiece),
					tile_size, '1 1 1', panel_fg_alpha/2, DRAWFLAG_NORMAL );
		}
	}

	if ( (active_minigame.minigame_flags & BD_TURN_LOSS) || (active_minigame.minigame_flags & BD_TURN_WIN) )
	{
		vector winfs = hud_fontsize*2;
		string victory_text = "Game over!";

		if(active_minigame.minigame_flags & BD_TURN_WIN)
			victory_text = "Well done! Click 'Next Level' to continue";
		
		vector win_pos = pos+eY*(mySize_y-winfs_y)/2;
		vector win_sz;
		win_sz = minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s", victory_text), 
			winfs, 0, DRAWFLAG_NORMAL, 0.5);
		
		drawfill(win_pos-eY*hud_fontsize_y,win_sz+2*eY*hud_fontsize_y,'0.3 0.3 1',0.8,DRAWFLAG_ADDITIVE);
		
		minigame_drawcolorcodedstring_wrapped(mySize_x,win_pos,
			sprintf("%s", victory_text), 
			winfs, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5);
	}
}


// Required function, draw the game status panel
void bd_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg(1);
	vector ts;
	ts = minigame_drawstring_wrapped(mySize_x,pos,active_minigame.descriptor.message,
		hud_fontsize * 2, '0.25 0.47 0.72', panel_fg_alpha, DRAWFLAG_NORMAL,0.5);

	pos_y += ts_y;
	mySize_y -= ts_y;

	vector player_fontsize = hud_fontsize * 1.75;
	ts_y = ( mySize_y - 2*player_fontsize_y ) / BD_TEAMS;
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
				entcs_GetName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;
			string thepiece = "bd/dozer";
			if(active_minigame.minigame_flags & BD_TURN_EDIT)
				thepiece = bd_get_tile_pic(bd_curr_tile);
			drawpic( mypos,
					minigame_texture(thepiece),
					tile_size * 0.7, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );

			mypos_x += tile_size_x;

			drawstring(mypos,ftos(e.bd_moves),tile_size,
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// Turn a set of flags into a help message
string bd_turn_to_string(int turnflags)
{
	if ( turnflags & BD_TURN_LOSS )
		return _("Better luck next time!");

	if ( turnflags & BD_TURN_WIN )
		if(random() > 0.5)
			return _("Tubular! Press \"Next Level\" to continue!");
		else
			return _("Wicked! Press \"Next Level\" to continue!");

	if( turnflags & BD_TURN_EDIT )
		return _("Press the space bar to change your currently selected tile");

	if ( turnflags & BD_TURN_MOVE )
		return _("Push the boulders onto the targets");
	
	return "";
}

// Make the correct move
void bd_make_move(entity minigame, string dir)
{
	if ( minigame.minigame_flags == BD_TURN_MOVE )
	{
		minigame_cmd("move ", dir);
	}
}

void bd_editor_make_move(entity minigame, string dir)
{
	if ( minigame.minigame_flags == BD_TURN_EDIT )
	{
		minigame_cmd("move ", bd_curr_pos, " ", ftos(bd_curr_tile), " ", dir);
	}
}

void bd_editor_fill(entity minigame)
{
	if ( minigame.minigame_flags == BD_TURN_EDIT )
	{
		minigame_cmd("fill ", bd_curr_pos, " ", ftos(bd_curr_tile));
	}
}

void bd_set_curr_pos(string s)
{
	if ( bd_curr_pos )
		strunzone(bd_curr_pos);
	if ( s )
		s = strzone(s);
	bd_curr_pos = s;
}

bool bd_normal_move(entity minigame, int themove)
{
	switch ( themove )
	{
		case K_RIGHTARROW:
		case K_KP_RIGHTARROW:
			bd_make_move(minigame, "r");
			return true;
		case K_LEFTARROW:
		case K_KP_LEFTARROW:
			bd_make_move(minigame, "l");
			return true;
		case K_UPARROW:
		case K_KP_UPARROW:
			bd_make_move(minigame, "u");
			return true;
		case K_DOWNARROW:
		case K_KP_DOWNARROW:
			bd_make_move(minigame, "d");
			return true;
	}

	return false;
}

bool bd_change_dozer_angle(entity minigame)
{
	entity dozer = bd_find_piece(minigame, bd_curr_pos, false);
	if(!dozer || dozer.bd_tiletype != BD_TILE_DOZER)
		return false;

	string thedir = "";
	vector dir = dozer.bd_dir;
	if(dir.x == 0 && dir.y == 0) { thedir = "r"; }

	if(dir.x == 0 && dir.y == 1) { thedir = "r"; }
	if(dir.x == 0 && dir.y ==-1) { thedir = "l"; }
	if(dir.x ==-1 && dir.y == 0) { thedir = "u"; }
	if(dir.x == 1 && dir.y == 0) { thedir = "d"; }

	bd_editor_make_move(minigame, thedir);
	return true;
}

bool bd_editor_move(entity minigame, int themove)
{
	switch ( themove )
	{
		case K_RIGHTARROW:
		case K_KP_RIGHTARROW:
			if ( ! bd_curr_pos )
				bd_set_curr_pos("a3");
			else
				bd_set_curr_pos(minigame_relative_tile(bd_curr_pos,1,0,BD_NUM_CNT,BD_LET_CNT));
			return true;
		case K_LEFTARROW:
		case K_KP_LEFTARROW:
			if ( ! bd_curr_pos )
				bd_set_curr_pos("c3");
			else
				bd_set_curr_pos(minigame_relative_tile(bd_curr_pos,-1,0,BD_NUM_CNT,BD_LET_CNT));
			return true;
		case K_UPARROW:
		case K_KP_UPARROW:
			if ( ! bd_curr_pos )
				bd_set_curr_pos("a1");
			else
				bd_set_curr_pos(minigame_relative_tile(bd_curr_pos,0,1,BD_NUM_CNT,BD_LET_CNT));
			return true;
		case K_DOWNARROW:
		case K_KP_DOWNARROW:
			if ( ! bd_curr_pos )
				bd_set_curr_pos("a3");
			else
				bd_set_curr_pos(minigame_relative_tile(bd_curr_pos,0,-1,BD_NUM_CNT,BD_LET_CNT));
			return true;
		case K_ENTER:
		case K_KP_ENTER:
			bd_editor_make_move(minigame, "");
			return true;
		case K_SPACE:
			if(bd_change_dozer_angle(minigame))
				return true;
			bd_curr_tile += 1;
			if(bd_curr_tile > BD_TILE_LAST)
				bd_curr_tile = 1;
			return true;
	}

	return false;
}

// Required function, handle client events
int bd_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
		{
			minigame.message = bd_turn_to_string(minigame.minigame_flags);
			bd_set_curr_pos("");
			bd_curr_tile = BD_TILE_BRICK1;
			return false;
		}
		case "key_pressed":
		{
			if(minigame.minigame_flags & BD_TURN_MOVE)
			{
				if(bd_normal_move(minigame, ...(0,int)))
					return true;
			}

			if(minigame.minigame_flags & BD_TURN_EDIT)
			{
				if(bd_editor_move(minigame, ...(0,int)))
					return true;
			}

			return false;
		}
		case "mouse_pressed":
		{
			if(minigame.minigame_flags & BD_TURN_EDIT)
			{
				if(...(0,int) == K_MOUSE1)
				{
					bd_editor_make_move(minigame, "");
					return true;
				}

				if(...(0,int) == K_MOUSE2)
				{
					bd_editor_fill(minigame);
					return true;
				}
			}

			return false;
		}
		case "mouse_moved":
		{
			if(minigame.minigame_flags & BD_TURN_EDIT)
			{
				vector mouse_pos = minigame_hud_normalize(mousepos,bd_boardpos,bd_boardsize);
				bd_set_curr_pos(minigame_tile_name(mouse_pos,BD_LET_CNT,BD_NUM_CNT));
				if ( ! bd_valid_tile(bd_curr_pos) )
					bd_set_curr_pos("");
			}
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
					sent.message = bd_turn_to_string(sent.minigame_flags);
					//if ( sent.minigame_flags & minigame_self.team )
						minigame_prompt();
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

					sent.bd_tiletype = ReadByte();

					int dx = ReadByte();
					int dy = ReadByte();

					if(dx == 2) dx = -1;
					if(dy == 2) dy = -1;

					sent.bd_dir_x = dx;
					sent.bd_dir_y = dy;
					sent.bd_dir_z = 0;
				}
			}
			else if(sent.classname == "minigame_player" && (sf & BD_SF_PLAYERMOVES))
				sent.bd_moves = ReadShort(); // make this a byte when possible

			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Next Level"),"next");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Restart"),"restart");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Editor"),"edit");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Save"),"save");
			return false;
		}
		case "menu_click":
		{
			if(...(0,string) == "next")
				minigame_cmd("next");
			if(...(0,string) == "restart")
				minigame_cmd("restart");
			if(...(0,string) == "edit")
				minigame_cmd("edit");
			if(...(0,string) == "save")
				minigame_cmd("save");
			return false;
		}
	}

	return false;
}

#endif
