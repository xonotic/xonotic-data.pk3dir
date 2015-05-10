#include "mapvoting.qh"
#include "_all.qh"

#include "hud.qh"
#include "scoreboard.qh"

#include "../common/mapinfo.qh"
#include "../common/util.qh"

#include "../dpdefs/keycodes.qh"

string MapVote_FormatMapItem(int id, string map, float _count, float maxwidth, vector fontsize)
{
	string pre, post;
	pre = sprintf("%d. ", id+1);
	if(mv_detail)
	{
		if(_count == 1)
			post = _(" (1 vote)");
		else if(_count >= 0 && mv_avail[id] == GTV_AVAILABLE)
			post = sprintf(_(" (%d votes)"), _count);
		else
			post = "";
	}
	else
		post = "";
	maxwidth -= stringwidth(pre, false, fontsize) + stringwidth(post, false, fontsize);
	map = textShortenToWidth(map, maxwidth, fontsize, stringwidth_nocolors);
	return strcat(pre, map, post);
}

string GameTypeVote_DescriptionByID(int id)
{
	return MapInfo_Type_Description(MapInfo_Type_FromString(mv_maps[id]));
}

vector MapVote_RGB(int id)
{
	if(mv_avail[id] != GTV_AVAILABLE)
		return '1 1 1';
	if(id == mv_ownvote)
		return '0 1 0';
	else if (id == mv_selection)
		return '1 1 0';
	else
		return '1 1 1';
}

void GameTypeVote_DrawGameTypeItem(vector pos, float maxh, float tsize, string gtype, string pic, float _count, int id)
{
	float alpha;
	float desc_padding = gtv_text_size.x * 3;
	float rect_margin = hud_fontsize.y / 2;
	vector rect_pos = pos - '0.5 0.5 0' * rect_margin;
	vector rect_size = '1 1 0';
	rect_size.x = tsize + rect_margin;
	rect_size.y = maxh + rect_margin;
	vector rgb = MapVote_RGB(id);
	vector offset = pos;
	float nlines = 0;

	if(mv_avail_start[id] != GTV_AVAILABLE)
		alpha = 0.2;
	else if ( mv_avail[id] != GTV_AVAILABLE && mv_top2_alpha)
		alpha = mv_top2_alpha;
	else
		alpha = 1;

	if(id == mv_selection && mv_avail[id] == GTV_AVAILABLE)
	{
		drawfill(rect_pos, rect_size, '1 1 1', 0.1, DRAWFLAG_NORMAL);
	}
	if(id == mv_ownvote)
	{
		drawfill(rect_pos, rect_size, rgb, 0.1*alpha, DRAWFLAG_NORMAL);
		drawborderlines(autocvar_scoreboard_border_thickness, rect_pos, rect_size, rgb, alpha, DRAWFLAG_NORMAL);
	}

	entity title;
	title = spawn();
	title.message = MapVote_FormatMapItem(id, MapInfo_Type_ToText(MapInfo_Type_FromString(gtype)),
										  _count, tsize, gtv_text_size);
	title.origin = pos-offset;

	pos.y += gtv_text_size_small.y;
	pos.y += gtv_text_size.y/2;

	maxh -= gtv_text_size.y;

	entity picent = spawn();
	picent.origin = pos-offset;
	picent.maxs = '1 1 0 ' * min(maxh, desc_padding) * 0.8;

	pos.x += desc_padding;
	tsize -= desc_padding;

	string thelabel = GameTypeVote_DescriptionByID(id), ts;
	entity last = title;
	entity next = world;
	if( thelabel != "")
	{
		float i,n = tokenizebyseparator(thelabel, "\n");
		for(i = 0; i < n && maxh > (nlines+1)*gtv_text_size_small.y; ++i)
		{
			getWrappedLine_remaining = argv(i);
			while(getWrappedLine_remaining && maxh > (nlines+1)*gtv_text_size_small.y)
			{
				ts = getWrappedLine(tsize, gtv_text_size_small, stringwidth_colors);
				if (ts != "")
				{
					next = spawn();
					next.message = ts;
					next.origin = pos-offset;
					last.chain = next;
					last = next;
					pos.y += gtv_text_size_small.y;
					nlines++;
				}
			}
		}
	}

	maxh -= max(nlines*gtv_text_size_small.y,picent.maxs.y);
	if ( maxh > 0 )
		offset.y += maxh/2;
	drawstring(title.origin+offset, title.message, gtv_text_size, rgb, alpha, DRAWFLAG_NORMAL);

	if(pic != "")
		drawpic(picent.origin+offset, pic, picent.maxs, '1 1 1', alpha, DRAWFLAG_NORMAL);

	for ( last = title.chain; last ; )
	{
		drawstring(last.origin+offset, last.message, gtv_text_size_small, '1 1 1', alpha, DRAWFLAG_NORMAL);
		next = last;
		last = last.chain;
		remove(next);
	}

	remove(picent);
	remove(title);
}

void MapVote_DrawMapItem(vector pos, float isize, float tsize, string map, string pic, float _count, int id)
{
	vector img_size = '0 0 0';
	vector rgb;
	string label;
	float text_size;

	isize -= hud_fontsize.y; // respect the text when calculating the image size

	rgb = MapVote_RGB(id);

	img_size.y = isize;
	img_size.x = isize / 0.75; // 4:3 x can be stretched easily, height is defined in isize

	pos.y = pos.y + img_size.y;

	label = MapVote_FormatMapItem(id, map, _count, tsize, hud_fontsize);

	text_size = stringwidth(label, false, hud_fontsize);

	float theAlpha;
	if (mv_avail[id] != GTV_AVAILABLE && mv_top2_alpha)
		theAlpha = mv_top2_alpha;
	else
		theAlpha = 1;

	pos.x -= text_size*0.5;
	drawstring(pos, label, hud_fontsize, rgb, theAlpha, DRAWFLAG_NORMAL);

	pos.x = pos.x + text_size*0.5 - img_size.x*0.5;
	pos.y = pos.y - img_size.y;

	pos += autocvar_scoreboard_border_thickness * '1 1 0';
	img_size -= (autocvar_scoreboard_border_thickness * 2) * '1 1 0';
	if(pic == "")
	{
		drawfill(pos, img_size, '.5 .5 .5', .7 * theAlpha, DRAWFLAG_NORMAL);
	}
	else
	{
		if(drawgetimagesize(pic) == '0 0 0')
			drawpic(pos, draw_UseSkinFor("nopreview_map"), img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
		else
			drawpic(pos, pic, img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
	}

	if(id == mv_ownvote)
		drawborderlines(autocvar_scoreboard_border_thickness, pos, img_size, rgb, theAlpha, DRAWFLAG_NORMAL);
	else
		drawborderlines(autocvar_scoreboard_border_thickness, pos, img_size, '0 0 0', theAlpha, DRAWFLAG_NORMAL);

	if(id == mv_selection && mv_avail[id] == GTV_AVAILABLE)
		drawfill(pos, img_size, '1 1 1', 0.1, DRAWFLAG_NORMAL);
}

void MapVote_DrawAbstain(vector pos, float isize, float tsize, float _count, int id)
{
	vector rgb;
	float text_size;
	string label;

	rgb = MapVote_RGB(id);

	pos.y = pos.y + hud_fontsize.y;

	label = MapVote_FormatMapItem(id, _("Don't care"), _count, tsize, hud_fontsize);

	text_size = stringwidth(label, false, hud_fontsize);

	pos.x -= text_size*0.5;
	drawstring(pos, label, hud_fontsize, rgb, 1, DRAWFLAG_NORMAL);
}

vector MapVote_GridVec(vector gridspec, int i, int m)
{
	int r = i % m;
	return
		'1 0 0' * (gridspec.x * r)
		+
		'0 1 0' * (gridspec.y * (i - r) / m);
}

float MapVote_Selection(vector topleft, vector cellsize, float rows, float columns)
{

	float c, r;

	mv_mouse_selection = -1;

	for (r = 0; r < rows; ++r)
		for (c = 0; c < columns; ++c)
		{
			if (mv_mousepos.x >= topleft.x + cellsize.x *  c &&
				mv_mousepos.x <= topleft.x + cellsize.x * (c + 1) &&
				mv_mousepos.y >= topleft.y + cellsize.y *  r &&
				mv_mousepos.y <= topleft.y + cellsize.y * (r + 1))
			{
				mv_mouse_selection = r * columns + c;
				break;
			}
		}

	if (mv_mouse_selection >= mv_num_maps)
		mv_mouse_selection = -1;

	if (mv_abstain && mv_mouse_selection < 0)
		mv_mouse_selection = mv_num_maps;

	if ( mv_selection_keyboard )
		return mv_selection;

	return mv_mouse_selection;
}

void MapVote_Draw()
{
	string map;
	int i;
	float tmp;
	vector pos;
	float isize;
	float center;
	float rows;
	float tsize;
	vector dist = '0 0 0';

	if(!mv_active)
		return;

	if (!autocvar_hud_cursormode)
	{
		vector mpos = mv_mousepos + getmousepos();
		mpos.x = bound(0, mpos.x, vid_conwidth);
		mpos.y = bound(0, mpos.y, vid_conheight);

		if ( mpos.x != mv_mousepos.x || mpos.y != mv_mousepos.y )
			mv_selection_keyboard = 0;
		mv_mousepos = mpos;

	}

	center = (vid_conwidth - 1)/2;
	xmin = vid_conwidth*0.05; // 5% border must suffice
	xmax = vid_conwidth - xmin;
	ymin = 20;
	i = autocvar_con_chatpos; //*autocvar_con_chatsize;
	if(i < 0)
		ymax = vid_conheight + (i - autocvar_con_chat) * autocvar_con_chatsize;
	if(i >= 0 || ymax < (vid_conheight*0.5))
		ymax = vid_conheight - ymin;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	pos.y = ymin;
	pos.z = 0;

	draw_beginBoldFont();
	map = ((gametypevote) ? _("Decide the gametype") : _("Vote for a map"));
	pos.x = center - stringwidth(map, false, '12 0 0');
	drawstring(pos, map, '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	pos.y += 26;

	if( mapvote_chosenmap != "" )
	{
		pos.x = center - stringwidth(mapvote_chosenmap, false, hud_fontsize*1.5/2);
		drawstring(pos, mapvote_chosenmap, hud_fontsize*1.5, '1 1 1', 1, DRAWFLAG_NORMAL);
		pos.y += hud_fontsize.y*2;
	}

	i = ceil(max(0, mv_timeout - time));
	map = sprintf(_("%d seconds left"), i);
	pos.x = center - stringwidth(map, false, '8 0 0');
	drawstring(pos, map, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	pos.y += 22;
	pos.x = xmin;
	draw_endBoldFont();

	// base for multi-column stuff...
	ymin = pos.y;
	if(mv_abstain)
		mv_num_maps -= 1;

	rows = ceil(mv_num_maps / mv_columns);

	dist.x = (xmax - xmin) / mv_columns;
	dist.y = (ymax - pos.y) / rows;

	if ( gametypevote )
	{
		tsize = dist.x - hud_fontsize.y;
		isize = dist.y;
		float maxheight = (ymax - pos.y) / 3;
		if ( isize > maxheight )
		{
			pos.x += (isize - maxheight)/2;
			isize = maxheight;
		}
		else
			dist.y += hud_fontsize.y;
		pos.x = ( vid_conwidth - dist.x * mv_columns ) / 2;
	}
	else
	{
		tsize = dist.x - 10;
		isize = min(dist.y - 10, 0.75 * tsize);
	}

	mv_selection = MapVote_Selection(pos, dist, rows, mv_columns);

	if ( !gametypevote )
		pos.x += dist.x / 2;
	pos.y += (dist.y - isize) / 2;
	ymax -= isize;

	if (mv_top2_time)
		mv_top2_alpha = max(0.2, 1 - (time - mv_top2_time)*(time - mv_top2_time));

	void (vector, float, float, string, string, float, float) DrawItem;

	if(gametypevote)
		DrawItem = GameTypeVote_DrawGameTypeItem;
	else
		DrawItem = MapVote_DrawMapItem;

	for(i = 0; i < mv_num_maps; ++i)
	{
		tmp = mv_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		map = mv_maps[i];
		if(mv_preview[i])
			DrawItem(pos + MapVote_GridVec(dist, i, mv_columns), isize, tsize, map, mv_pics[i], tmp, i);
		else
			DrawItem(pos + MapVote_GridVec(dist, i, mv_columns), isize, tsize, map, "", tmp, i);
	}

	if(mv_abstain)
		++mv_num_maps;

	if(mv_abstain && i < mv_num_maps) {
		tmp = mv_votes[i];
		pos.y = ymax + isize - hud_fontsize.y;
		pos.x = (xmax+xmin)*0.5;
		MapVote_DrawAbstain(pos, isize, xmax - xmin, tmp, i);
	}

	drawpic(mv_mousepos, strcat("gfx/menu/", autocvar_menu_skin, "/cursor.tga"), '32 32 0', '1 1 1', 1 - autocvar__menu_alpha, DRAWFLAG_NORMAL);
}

void Cmd_MapVote_MapDownload(float argc)
{
	entity pak;

	if(argc != 2 || !mv_pk3list)
	{
		print(_("mv_mapdownload: ^3You're not supposed to use this command on your own!\n"));
		return;
	}

	int id = stof(argv(1));
	for(pak = mv_pk3list; pak; pak = pak.chain)
		if(pak.sv_entnum == id)
			break;

	if(!pak || pak.sv_entnum != id) {
		print(_("^1Error:^7 Couldn't find pak index.\n"));
		return;
	}

	if(PreviewExists(pak.message))
	{
		mv_preview[id] = true;
		return;
	} else {
		print(_("Requesting preview...\n"));
		localcmd(strcat("\ncmd mv_getpicture ", ftos(id), "\n"));
	}
}

void MapVote_CheckPK3(string pic, string pk3, int id)
{
	entity pak;
	pak = spawn();
	pak.netname = pk3;
	pak.message = pic;
	pak.sv_entnum = id;

	pak.chain = mv_pk3list;
	mv_pk3list = pak;

	if(pk3 != "")
	{
		localcmd(strcat("\ncurl --pak ", pk3, "; wait; cl_cmd mv_download ", ftos(id), "\n"));
	}
	else
	{
		Cmd_MapVote_MapDownload(tokenize_console(strcat("mv_download ", ftos(id))));
	}
}

void MapVote_CheckPic(string pic, string pk3, int id)
{
	// never try to retrieve a pic for the "don't care" 'map'
	if(mv_abstain && id == mv_num_maps - 1)
		return;

	if(PreviewExists(pic))
	{
		mv_preview[id] = true;
		return;
	}
	MapVote_CheckPK3(pic, pk3, id);
}

void MapVote_ReadMask()
{
	int i;
	if ( mv_num_maps < 24 )
	{
		int mask, power;
		if(mv_num_maps < 8)
			mask = ReadByte();
		else if(mv_num_maps < 16)
			mask = ReadShort();
		else
			mask = ReadLong();

		for(i = 0, power = 1; i < mv_num_maps; ++i, power *= 2)
			mv_avail[i] = (mask & power) ? GTV_AVAILABLE : GTV_FORBIDDEN;
	}
	else
	{
		for(i = 0; i < mv_num_maps; ++i )
			mv_avail[i] = ReadByte();
	}
}

void MapVote_Init()
{
	int i, j;
	string map, pk3, s;

	precache_sound ("misc/invshot.wav");

	mv_active = 1;
	if(autocvar_hud_cursormode) { setcursormode(1); }
	else { mv_mousepos = '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight; }
	mv_selection = -1;
	mv_selection_keyboard = 0;

	for(n_ssdirs = 0; ; ++n_ssdirs)
	{
		s = ReadString();
		if(s == "")
			break;
		if(n_ssdirs < NUM_SSDIRS)
			ssdirs[n_ssdirs] = s;
	}
	n_ssdirs = min(n_ssdirs, NUM_SSDIRS);

	mv_num_maps = min(MAPVOTE_COUNT, ReadByte());
	mv_abstain = ReadByte();
	if(mv_abstain)
		mv_abstain = 1; // must be 1 for bool-true, makes stuff easier
	mv_detail = ReadByte();

	mv_ownvote = -1;
	mv_timeout = ReadCoord();

	gametypevote = ReadByte();

	float mv_real_num_maps = mv_num_maps - mv_abstain;

	if(gametypevote)
	{
		mapvote_chosenmap = strzone(ReadString());
		if ( gametypevote == 2 )
			gametypevote = 0;

		gtv_text_size = hud_fontsize*1.4;
		gtv_text_size_small = hud_fontsize*1.1;

		if (mv_real_num_maps > 8 )
			mv_columns = 3;
		else
			mv_columns = min(2, mv_real_num_maps);
    }
    else
	{
		if (mv_real_num_maps > 16)
			mv_columns = 5;
		else if (mv_real_num_maps > 9)
			mv_columns = 4;
		else if(mv_real_num_maps > 3)
			mv_columns = 3;
		else
			mv_columns = mv_real_num_maps;
	}

	MapVote_ReadMask();
	for(i = 0; i < mv_num_maps; ++i )
		mv_avail_start[i] = mv_avail[i];

	// Assume mv_pk3list is world, there should only be 1 mapvote per round
	mv_pk3list = world; // I'm still paranoid!

	for(i = 0; i < mv_num_maps; ++i)
	{
		mv_votes[i] = 0;

		map = strzone(ReadString());
		pk3 = strzone(ReadString());
		j = bound(0, ReadByte(), n_ssdirs - 1);

		mv_maps[i] = map;
		mv_pk3[i] = pk3;
		mv_avail[i] = ReadByte();

		if(gametypevote)
		{
			//map = strzone(strcat("gfx/menu/default/gametype_", map));
			//map = strzone(sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, map));
			string mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, map);
			if(precache_pic(mv_picpath) == "")
				mv_picpath = strcat("gfx/menu/default/gametype_", map);
			map = strzone(mv_picpath);
			mv_pics[i] = map;
			mv_preview[i] = PreviewExists(map);
		}
		else
		{
			map = strzone(strcat(ssdirs[j], "/", map));
			mv_pics[i] = map;
			mv_preview[i] = false;
			MapVote_CheckPic(map, pk3, i);
		}
	}

	for(i = 0; i < n_ssdirs; ++i)
		ssdirs[n_ssdirs] = string_null;
	n_ssdirs = 0;
}

void MapVote_SendChoice(float index)
{
	localcmd(strcat("\nimpulse ", ftos(index+1), "\n"));
}

int MapVote_MoveLeft(int pos)
{
	int imp;
	if ( pos < 0 )
		imp = mv_num_maps - 1;
	else
		imp = pos < 1 ? mv_num_maps - 1 : pos - 1;
	if ( mv_avail[imp] != GTV_AVAILABLE && imp != mv_ownvote )
		imp = MapVote_MoveLeft(imp);
	return imp;
}
int MapVote_MoveRight(int pos)
{
	int imp;
	if ( pos < 0 )
		imp = 0;
	else
		imp = pos >= mv_num_maps - 1 ? 0 : pos + 1;
	if ( mv_avail[imp] != GTV_AVAILABLE && imp != mv_ownvote )
		imp = MapVote_MoveRight(imp);
	return imp;
}
int MapVote_MoveUp(int pos)
{
	int imp;
	if ( pos < 0 )
		imp = mv_num_maps - 1;
	else
	{
		imp = pos - mv_columns;
		if ( imp < 0 )
		{
			imp = floor(mv_num_maps/mv_columns)*mv_columns + pos % mv_columns;
			if ( imp >= mv_num_maps )
				imp -= mv_columns;
		}
	}
	if ( mv_avail[imp] != GTV_AVAILABLE && imp != mv_ownvote )
		imp = MapVote_MoveUp(imp);
	return imp;
}
int MapVote_MoveDown(int pos)
{
	int imp;
	if ( pos < 0 )
		imp = 0;
	else
	{
		imp = pos + mv_columns;
		if ( imp >= mv_num_maps )
			imp = imp % mv_columns;
	}
	if ( mv_avail[imp] != GTV_AVAILABLE && imp != mv_ownvote )
		imp = MapVote_MoveDown(imp);
	return imp;
}

float MapVote_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	float imp;

	if (!mv_active)
		return false;

	if(bInputType == 3)
	{
		mv_mousepos.x = nPrimary;
		mv_mousepos.y = nSecondary;
		mv_selection_keyboard = 0;
		return true;
	}

	if (bInputType != 0)
		return false;

	if ('0' <= nPrimary && nPrimary <= '9')
	{
		imp = nPrimary - '0';
		if (imp == 0) imp = 10;
		localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
		return true;
	}
	switch(nPrimary)
	{
		case K_KP_1: localcmd("\nimpulse 1\n"); return true;
		case K_KP_2: localcmd("\nimpulse 2\n"); return true;
		case K_KP_3: localcmd("\nimpulse 3\n"); return true;
		case K_KP_4: localcmd("\nimpulse 4\n"); return true;
		case K_KP_5: localcmd("\nimpulse 5\n"); return true;
		case K_KP_6: localcmd("\nimpulse 6\n"); return true;
		case K_KP_7: localcmd("\nimpulse 7\n"); return true;
		case K_KP_8: localcmd("\nimpulse 8\n"); return true;
		case K_KP_9: localcmd("\nimpulse 9\n"); return true;
		case K_KP_0: localcmd("\nimpulse 10\n"); return true;

		case K_RIGHTARROW:
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveRight(mv_selection);
			return true;
		case K_LEFTARROW:
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveLeft(mv_selection);
			return true;
		case K_DOWNARROW:
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveDown(mv_selection);
			return true;
		case K_UPARROW:
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveUp(mv_selection);
			return true;
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			if ( mv_selection_keyboard )
				MapVote_SendChoice(mv_selection);
			return true;
	}

	if (nPrimary == K_MOUSE1)
	{
		mv_selection_keyboard = 0;
		mv_selection = mv_mouse_selection;
		if (mv_selection >= 0)
		{
			imp = min(mv_selection + 1, mv_num_maps);
			localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
			return true;
		}
	}

	return false;
}

void MapVote_UpdateMask()
{
	MapVote_ReadMask();
	mv_top2_time = time;
}

void MapVote_UpdateVotes()
{
	int i;
	for(i = 0; i < mv_num_maps; ++i)
	{
		if(mv_avail[i] == GTV_AVAILABLE)
		{
			if(mv_detail)
				mv_votes[i] = ReadByte();
			else
				mv_votes[i] = 0;
		}
		else
			mv_votes[i] = -1;
	}

	mv_ownvote = ReadByte()-1;
}

void Ent_MapVote()
{
	int sf = ReadByte();

	if(sf & 1)
		MapVote_Init();

	if(sf & 2)
		MapVote_UpdateMask();

	if(sf & 4)
		MapVote_UpdateVotes();
}

void Net_MapVote_Picture()
{
	int type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
}
