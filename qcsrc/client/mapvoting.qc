#include "mapvoting.qh"

#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/panel/scoreboard.qh>
#include <common/mapinfo.qh>
#include <common/util.qh>

// MapVote (#21)

void MapVote_Draw_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_mapvote_highlight_border");
}

int mv_num_maps;

string mv_maps[MAPVOTE_COUNT];
string mv_pics[MAPVOTE_COUNT];
string mv_pk3[MAPVOTE_COUNT]; // map pk3 name or gametype human readable name
string mv_desc[MAPVOTE_COUNT];
float mv_preview[MAPVOTE_COUNT];
int mv_votes[MAPVOTE_COUNT];
int mv_flags[MAPVOTE_COUNT];
int mv_flags_start[MAPVOTE_COUNT];
entity mv_pk3list;
bool mv_abstain;
int mv_detail;
int mv_ownvote;
int mv_tie_winner;
float mv_timeout;
float mv_top2_time;
float mv_top2_alpha;
float mv_winner_time;
float mv_winner_alpha;

int mv_selection;
int mv_columns;
int mv_mouse_selection;
int mv_selection_keyboard;

bool gametypevote;
string mapvote_chosenmap;
vector gtv_text_size;
vector gtv_text_size_small;

const int NUM_SSDIRS = 4;
string ssdirs[NUM_SSDIRS];
int n_ssdirs;

bool PreviewExists(string name)
{
	if(autocvar_cl_readpicture_force)
		return false;

	if (fexists(strcat(name, ".tga"))) return true;
	if (fexists(strcat(name, ".png"))) return true;
	if (fexists(strcat(name, ".jpg"))) return true;
	if (fexists(strcat(name, ".pcx"))) return true;

	return false;
}

string MapVote_FormatMapItem(int id, string map, int _count, float maxwidth, vector fontsize, int most_votes)
{
	TC(int, id);
	string pre, post;
	pre = sprintf("%d. ", id+1);
	if(mv_detail)
	{
		if(_count == 1)
			post = _(" (1 vote)");
		else if(_count >= 0 && (mv_flags[id] & GTV_AVAILABLE))
			post = sprintf(_(" (%d votes)"), _count);
		else
			post = "";
		if(post != "" && (mv_flags[id] & GTV_AVAILABLE))
		if(mv_tie_winner == id || (mv_tie_winner == -2 && _count == most_votes))
			post = strcat("^5", post);
	}
	else
		post = "";
	maxwidth -= stringwidth(pre, false, fontsize) + stringwidth(post, true, fontsize);
	map = textShortenToWidth(map, maxwidth, fontsize, stringwidth_nocolors);
	return strcat(pre, map, post);
}

vector MapVote_RGB(int id)
{
	TC(int, id);
	if(!(mv_flags[id] & GTV_AVAILABLE))
		return '1 1 1';
	if(id == mv_ownvote)
		return '0 1 0';
	else if (id == mv_selection)
		return '1 1 0';
	else
		return '1 1 1';
}

void GameTypeVote_DrawGameTypeItem(vector pos, float maxh, float tsize, string gtype, string pic, int _count, int id, int most_votes)
{
	TC(int, id);
	// Find the correct alpha
	float alpha;
	if(!(mv_flags_start[id] & GTV_AVAILABLE))
		alpha = 0.2; // The gametype isn't supported by the map
	else if ( !(mv_flags[id] & GTV_AVAILABLE) && mv_top2_alpha)
		alpha = mv_top2_alpha; // Fade away if not one of the top 2 choice
	else
		alpha = 1; // Normal, full alpha
	alpha *= panel_fg_alpha;

	// Bounding box details
	float rect_margin = hud_fontsize.y / 2;

	pos.x += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	pos.y += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	maxh -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);
	tsize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);

	vector rect_pos = pos - '0.5 0.5 0' * rect_margin;
	vector rect_size = '1 1 0';
	rect_size.x = tsize + rect_margin;
	rect_size.y = maxh + rect_margin;

	// Highlight selected item
	if(id == mv_selection && (mv_flags[id] & GTV_AVAILABLE))
	{
		drawfill(rect_pos, rect_size, '1 1 1', 0.1 * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	// Highlight current vote
	vector rgb = MapVote_RGB(id);
	if(id == mv_ownvote)
	{
		drawfill(rect_pos, rect_size, rgb, 0.1 * alpha, DRAWFLAG_NORMAL);
		drawborderlines(autocvar_hud_panel_mapvote_highlight_border, rect_pos, rect_size, rgb, alpha, DRAWFLAG_NORMAL);
	}

	vector offset = pos;

	float title_gap = gtv_text_size.y * 1.4; // distance between the title and the description
	pos.y += title_gap;
	maxh -= title_gap;

	// Evaluate the image size
	vector image_size = '1 1 0' * gtv_text_size.x * 3;
	if ( maxh < image_size.y )
		image_size = '1 1 0' * maxh;
	image_size *= 0.8;
	float desc_padding = gtv_text_size.x * 0.6;
	pos.x += image_size.x + desc_padding;
	tsize -= image_size.x + desc_padding;

	// Split the description into lines
	entity title;
	title = spawn();
	title.message = strcat(rgb_to_hexcolor(rgb), MapVote_FormatMapItem(id, mv_pk3[id], _count, tsize, gtv_text_size, most_votes));

	string thelabel = mv_desc[id], ts;
	entity last = title;
	entity next = NULL;
	float nlines = 0;
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

	// Center the contents in the bounding box
	maxh -= max(nlines*gtv_text_size_small.y,image_size.y);
	if ( maxh > 0 )
		offset.y += maxh/2;

	// Draw the title
	drawcolorcodedstring(offset, title.message, gtv_text_size, alpha, DRAWFLAG_NORMAL);

	// Draw the icon
	if(pic != "")
		drawpic('0 1 0'*title_gap+'0.5 0 0'*desc_padding+offset, pic, image_size, '1 1 1', alpha, DRAWFLAG_NORMAL);

	// Draw the description
	for ( last = title.chain; last ; )
	{
		drawstring(last.origin+offset, last.message, gtv_text_size_small, '1 1 1', alpha, DRAWFLAG_NORMAL);
		next = last;
		last = last.chain;
		delete(next);
	}

	// Cleanup
	delete(title);
}

void MapVote_DrawMapPicture(string pic, vector pos, vector img_size, float theAlpha)
{
	if(pic == "")
		drawfill(pos, img_size, '.5 .5 .5', .7 * theAlpha, DRAWFLAG_NORMAL);
	else
	{
		if(drawgetimagesize(pic) == '0 0 0')
			drawpic(pos, draw_UseSkinFor("nopreview_map"), img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
		else
			drawpic(pos, pic, img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
	}
}

void MapVote_DrawMapItem(vector pos, float isize, float tsize, string map, string pic, int _count, int id, int most_votes)
{
	TC(int, id);
	vector img_size = '0 0 0';
	string label;
	float text_size;

	float rect_margin = hud_fontsize.y / 2;

	pos.x += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	pos.y += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	isize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);
	tsize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);

	vector rect_pos = pos - '0.5 0.5 0' * rect_margin;
	vector rect_size = '1 1 0';
	rect_size.x = tsize + rect_margin;
	rect_size.y = isize + rect_margin;

	float img_ar = 4/3;
	img_size.x = min(tsize, isize * img_ar);
	img_size.y = img_size.x / img_ar;
	img_size.y -= hud_fontsize.y;
	img_size.x = img_size.y * img_ar;

	pos.y += (isize - img_size.y - hud_fontsize.y) / 2;

	vector rgb = MapVote_RGB(id);
	label = strcat(rgb_to_hexcolor(rgb), MapVote_FormatMapItem(id, map, _count, tsize, hud_fontsize, most_votes));

	text_size = stringwidth(label, true, hud_fontsize);

	float save_rect_sizex = rect_size.x;
	rect_size.x = max(img_size.x, text_size) + rect_margin;
	rect_pos.x += (save_rect_sizex - rect_size.x) / 2;

	vector text_pos = '0 0 0';
	text_pos.x = pos.x + (tsize - text_size) / 2;
	text_pos.y = pos.y + img_size.y;

	pos.x += (tsize - img_size.x) / 2;

	float theAlpha;
	if (!(mv_flags[id] & GTV_AVAILABLE) && mv_top2_alpha)
		theAlpha = mv_top2_alpha;
	else if (mv_winner && mv_winner_alpha)
		theAlpha = mv_winner_alpha;
	else
		theAlpha = 1;
	theAlpha *= panel_fg_alpha;

	// Highlight selected item
	if (!mv_winner)
	{
		if(id == mv_selection && (mv_flags[id] & GTV_AVAILABLE))
			drawfill(rect_pos, rect_size, '1 1 1', 0.1 * panel_fg_alpha, DRAWFLAG_NORMAL);

		// Highlight current vote
		if(id == mv_ownvote)
		{
			drawfill(rect_pos, rect_size, rgb, 0.1 * theAlpha, DRAWFLAG_NORMAL);
			drawborderlines(autocvar_hud_panel_mapvote_highlight_border, rect_pos, rect_size, rgb, theAlpha, DRAWFLAG_NORMAL);
		}
	}

	drawcolorcodedstring(text_pos, label, hud_fontsize, theAlpha, DRAWFLAG_NORMAL);

	MapVote_DrawMapPicture(pic, pos, img_size, theAlpha);
}

void MapVote_DrawAbstain(vector pos, float isize, float tsize, int _count, int id)
{
	TC(int, id);
	vector rgb;
	float text_size;
	string label;

	rgb = MapVote_RGB(id);

	label = MapVote_FormatMapItem(id, _("Don't care"), _count, tsize, hud_fontsize, -1);

	text_size = stringwidth(label, false, hud_fontsize);

	pos.x -= text_size*0.5;
	drawstring(pos, label, hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
}

vector MapVote_GridVec(vector gridspec, int i, int m)
{
	TC(int, i); TC(int, m);
	int r = i % m;
	return
		'1 0 0' * (gridspec.x * r)
		+
		'0 1 0' * (gridspec.y * (i - r) / m);
}

float MapVote_Selection(vector topleft, vector cellsize, float rows, float columns)
{
	float c, r;
	if (mv_winner)
		return -1;

	mv_mouse_selection = -1;

	for (r = 0; r < rows; ++r)
		for (c = 0; c < columns; ++c)
		{
			if (mousepos.x >= topleft.x + cellsize.x *  c &&
				mousepos.x <= topleft.x + cellsize.x * (c + 1) &&
				mousepos.y >= topleft.y + cellsize.y *  r &&
				mousepos.y <= topleft.y + cellsize.y * (r + 1))
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

// draws map vote or gametype vote
void MapVote_Draw()
{
	string map;
	int i;
	float tmp;
	vector pos;
	float center;
	float rows;
	vector dist = '0 0 0';

	//if(intermission != 2) return;
	if(!mv_active)
		return;

	HUD_Panel_LoadCvars();

	center = (vid_conwidth - 1)/2;
	xmin = vid_conwidth * 0.08;
	xmax = vid_conwidth - xmin;
	ymin = 20;
	ymax = vid_conheight - ymin;

	if(chat_posy + chat_sizey / 2 < vid_conheight / 2)
		ymin += chat_sizey;
	else
		ymax -= chat_sizey;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");
	if (gametypevote)
	{
		gtv_text_size = hud_fontsize * 1.4;
		gtv_text_size_small = hud_fontsize * 1.1;
	}

	pos.y = ymin;
	pos.z = 0;

	HUD_Scale_Disable();
	draw_beginBoldFont();

	map = ((gametypevote) ? _("Decide the gametype") : _("Vote for a map"));
	if (!mv_winner)
	{
		pos.x = center - stringwidth(map, false, hud_fontsize * 2) * 0.5;
		drawstring(pos, map, hud_fontsize * 2, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	pos.y += hud_fontsize.y * 2;

	if( mapvote_chosenmap != "" )
	{
		pos.y += hud_fontsize.y * 0.25;
		pos.x = center - stringwidth(mapvote_chosenmap, false, hud_fontsize * 1.5) * 0.5;
		drawstring(pos, mapvote_chosenmap, hud_fontsize * 1.5, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += hud_fontsize.y * 1.5;
	}
	pos.y += hud_fontsize.y * 0.5;

	draw_endBoldFont();

	i = ceil(max(1, mv_timeout - time)); // make sure 0 seconds left never shows up, not even for a frame
	if (mv_winner)
		map = mv_maps[mv_winner - 1];
	else
		map = sprintf(_("%d seconds left"), i);
	pos.x = center - stringwidth(map, false, hud_fontsize * 1.5) * 0.5;
	drawstring(pos, map, hud_fontsize * 1.5, '0 1 0', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += hud_fontsize.y * 1.5;
	pos.y += hud_fontsize.y * 0.5;

	// base for multi-column stuff...
	pos.y += hud_fontsize.y;
	pos.x = xmin;
	ymin = pos.y;
	float abstain_spacing = panel_bg_border + hud_fontsize.y;
	if(mv_abstain)
	{
		mv_num_maps -= 1;
		ymax -= abstain_spacing;
	}

	// higher than the image itself ratio for mapvote items to reserve space for long map names
	int item_aspect = (gametypevote) ? 3/1 : 5/3;
	vector table_size = HUD_GetTableSize_BestItemAR(mv_num_maps, vec2(xmax - xmin, ymax - ymin), item_aspect);
	mv_columns = table_size.x;
	rows = table_size.y;

	dist.x = (xmax - xmin) / mv_columns;
	dist.y = (ymax - pos.y) / rows;

	// reduce size of too wide items
	tmp = vid_conwidth / 3; // max width
	if(dist.x > tmp)
	{
		dist.x = tmp;
		dist.y = min(dist.y, dist.x / item_aspect);
	}
	tmp = vid_conheight / 3; // max height
	if(dist.y > tmp)
	{
		dist.y = tmp;
		dist.x = min(dist.x, dist.y * item_aspect);
	}

	// reduce size to fix aspect ratio
	if(dist.x / dist.y > item_aspect)
		dist.x = dist.y * item_aspect;
	else
		dist.y = dist.x / item_aspect;

	// adjust table pos and size according to the new size
	float offset;
	offset = ((xmax - pos.x) - dist.x * mv_columns) / 2;
	xmin = pos.x += offset;
	xmax -= offset;
	offset = ((ymax - pos.y) - dist.y * rows) / 2;
	ymax -= 2 * offset;

	// override panel_pos and panel_size
	panel_pos.x = pos.x;
	panel_pos.y = pos.y;
	panel_size.x = xmax - xmin;
	panel_size.y = ymax - ymin;
	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		// FIXME item AR gets slightly changed here...
		// it's rather hard to avoid it at this point
		dist.x -= 2 * panel_bg_padding / mv_columns;
		dist.y -= 2 * panel_bg_padding / rows;
		xmin = pos.x += panel_bg_padding;
		ymin = pos.y += panel_bg_padding;
		xmax -= 2 * panel_bg_padding;
		ymax -= 2 * panel_bg_padding;
	}

	mv_selection = MapVote_Selection(pos, dist, rows, mv_columns);

	if (mv_top2_time)
		mv_top2_alpha = max(0.2, 1 - (time - mv_top2_time) ** 2);

	if (mv_winner_time)
		mv_winner_alpha = max(0.2, 1 - sqrt(max(0, time - mv_winner_time)));

	int most_votes = -1;
	if (mv_tie_winner == -2)
		for (i = 0; i < mv_num_maps; ++i)
			if (mv_votes[i] > most_votes)
				most_votes = mv_votes[i];

	void (vector, float, float, string, string, float, int, int) DrawItem;
	if(gametypevote)
		DrawItem = GameTypeVote_DrawGameTypeItem;
	else
		DrawItem = MapVote_DrawMapItem;

	for(i = 0; i < mv_num_maps; ++i)
	{
		tmp = mv_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		map = mv_maps[i];
		if(mv_preview[i])
			DrawItem(pos + MapVote_GridVec(dist, i, mv_columns), dist.y, dist.x, map, mv_pics[i], tmp, i, most_votes);
		else
			DrawItem(pos + MapVote_GridVec(dist, i, mv_columns), dist.y, dist.x, map, "", tmp, i, most_votes);
	}

	if(mv_abstain)
		++mv_num_maps;

	if(mv_abstain && i < mv_num_maps) {
		tmp = mv_votes[i];
		pos.y = ymax + abstain_spacing;
		pos.x = (xmax + xmin) * 0.5;
		MapVote_DrawAbstain(pos, dist.x, xmax - xmin, tmp, i);
	}

	if (mv_winner)
	{
		// expand winner map image
		vector startsize = '0 0 0';
		startsize.y = vid_conheight * 0.1;
		startsize.x = startsize.y * 4/3;
		vector startpos = panel_pos + (panel_size - startsize) / 2;

		vector endsize = '0 0 0';
		endsize.y = vid_conheight * 0.5;
		endsize.x = endsize.y * 4/3;
		vector endpos = '0 0 0';
		endpos.y = panel_pos.y;
		endpos.x = (vid_conwidth - endsize.x) * 0.5;

		float f = bound(0, (time - mv_winner_time) * 2, 1);
		f = sqrt(f);
		float theAlpha = f;
		f = min(0.1 + f, 1);
		vector img_pos = endpos * f + startpos * (1 - f);
		vector img_size = endsize * f + startsize * (1 - f);

		MapVote_DrawMapPicture(mv_pics[mv_winner - 1], img_pos, img_size, theAlpha);
	}
}

void Cmd_MapVote_MapDownload(int argc)
{
	TC(int, argc);
	entity pak;

	if(argc != 2 || !mv_pk3list)
	{
		LOG_INFO(_("mv_mapdownload: ^3You're not supposed to use this command on your own!"));
		return;
	}

	int id = stof(argv(1));
	for(pak = mv_pk3list; pak; pak = pak.chain)
		if(pak.sv_entnum == id)
			break;

	if(!pak || pak.sv_entnum != id) {
		LOG_INFO(_("^1Error:^7 Couldn't find pak index."));
		return;
	}

	if(PreviewExists(pak.message))
	{
		mv_preview[id] = true;
		return;
	} else {
		LOG_INFO(_("Requesting preview..."));
		localcmd(strcat("\ncmd mv_getpicture ", ftos(id), "\n"));
	}
}

void MapVote_CheckPK3(string pic, string pk3, int id)
{
	TC(int, id);
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
	TC(int, id);
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
		int mask;
		if(mv_num_maps < 8)
			mask = ReadByte();
		else if(mv_num_maps < 16)
			mask = ReadShort();
		else
			mask = ReadLong();

		for(i = 0; i < mv_num_maps; ++i)
		{
			if (mask & BIT(i))
				mv_flags[i] |= GTV_AVAILABLE;
			else
				mv_flags[i] &= ~GTV_AVAILABLE;
		}
	}
	else
	{
		for(i = 0; i < mv_num_maps; ++i )
			mv_flags[i] = ReadByte();
	}
}

void MapVote_ReadOption(int i)
{
	TC(int, i);
	string map = strzone(ReadString());
	string pk3 = strzone(ReadString());
	int j = bound(0, ReadByte(), n_ssdirs - 1);

	mv_maps[i] = map;
	mv_pk3[i] = pk3;
	mv_flags[i] = GTV_AVAILABLE;

	string pic = strzone(strcat(ssdirs[j], "/", map));
	mv_pics[i] = pic;
	mv_preview[i] = false;
	MapVote_CheckPic(pic, pk3, i);
}

void GameTypeVote_ReadOption(int i)
{
	TC(int, i);
	string gt = strzone(ReadString());

	mv_maps[i] = gt;
	mv_flags[i] = ReadByte();

	string basetype = "";

	if ( mv_flags[i] & GTV_CUSTOM )
	{
		string name = ReadString();
		if ( strlen(name) < 1 )
			name = gt;
		mv_pk3[i] = strzone(name);
		mv_desc[i] = strzone(ReadString());
		basetype = strzone(ReadString());
	}
	else
	{
		Gametype type = MapInfo_Type_FromString(gt, false, false);
		mv_pk3[i] = strzone(MapInfo_Type_ToText(type));
		mv_desc[i] = MapInfo_Type_Description(type);
	}

	string mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, gt);
	if(precache_pic(mv_picpath) == "")
	{
		mv_picpath = strcat("gfx/menu/default/gametype_", gt);
		if(precache_pic(mv_picpath) == "")
		{
			mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, basetype);
			if(precache_pic(mv_picpath) == "")
			{
				mv_picpath = strcat("gfx/menu/default/gametype_", basetype);
			}
		}
	}
	string pic = strzone(mv_picpath);
	mv_pics[i] = pic;
	mv_preview[i] = PreviewExists(pic);
}

void MapVote_Init()
{
	mv_active = 1;
	if(!autocvar_hud_cursormode) mousepos = '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight;
	mv_selection = -1;
	mv_selection_keyboard = 0;

	string s;
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
	mv_abstain = boolean(ReadByte());
	mv_detail = ReadByte();

	mv_ownvote = -1;
	mv_timeout = ReadCoord();

	int gametypevote_flags = ReadByte();
	gametypevote = boolean(gametypevote_flags & BIT(0));
	if(gametypevote_flags)
		mapvote_chosenmap = strzone(ReadString());

	MapVote_ReadMask();
	int i;
	for(i = 0; i < mv_num_maps; ++i )
		mv_flags_start[i] = mv_flags[i];

	// Assume mv_pk3list is NULL, there should only be 1 mapvote per round
	mv_pk3list = NULL; // I'm still paranoid!

	for(i = 0; i < mv_num_maps; ++i)
	{
		mv_votes[i] = 0;

		if ( gametypevote )
			GameTypeVote_ReadOption(i);
		else
			MapVote_ReadOption(i);
	}

	for(i = 0; i < n_ssdirs; ++i)
		ssdirs[n_ssdirs] = string_null;
	n_ssdirs = 0;
}

void MapVote_SendChoice(int index)
{
	TC(int, index);
	localcmd(strcat("\nimpulse ", ftos(index+1), "\n"));
}

int MapVote_MoveLeft(int pos)
{
	TC(int, pos);
	int imp;
	if ( pos < 0 )
		imp = mv_num_maps - 1;
	else
		imp = pos < 1 ? mv_num_maps - 1 : pos - 1;
	if ( !(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote )
		imp = MapVote_MoveLeft(imp);
	return imp;
}
int MapVote_MoveRight(int pos)
{
	TC(int, pos);
	int imp;
	if ( pos < 0 )
		imp = 0;
	else
		imp = pos >= mv_num_maps - 1 ? 0 : pos + 1;
	if ( !(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote )
		imp = MapVote_MoveRight(imp);
	return imp;
}
int MapVote_MoveUp(int pos)
{
	TC(int, pos);
	int imp;
	if ( pos < 0 )
		imp = mv_num_maps - 1;
	else
	{
		imp = pos - mv_columns;
		if ( imp < 0 )
		{
			int mv_rows = ceil(mv_num_maps / mv_columns);
			if (imp == -mv_columns) // pos == 0
				imp = mv_columns * mv_rows - 1;
			else
				imp = imp + mv_columns * mv_rows - 1;
		}
	}
	if ( !(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote )
		imp = MapVote_MoveUp(imp);
	return imp;
}
int MapVote_MoveDown(int pos)
{
	TC(int, pos);
	int imp;
	if ( pos < 0 )
		imp = 0;
	else
	{
		imp = pos + mv_columns;
		if ( imp >= mv_num_maps )
		{
			if ((imp % mv_columns) == mv_columns - 1)
				imp = 0;
			else
				imp = imp % mv_columns + 1;
		}
	}
	if ( !(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote )
		imp = MapVote_MoveDown(imp);
	return imp;
}

float MapVote_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	TC(int, bInputType);

	static int first_digit = 0;
	if (!mv_active || isdemo())
		return false;

	if(bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		mv_selection_keyboard = 0;
		return true;
	}

	if (bInputType == 2)
	{
		mv_selection_keyboard = 0;
		return false;
	}

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	if (key_pressed)
	{
		if (nPrimary == K_ALT) hudShiftState |= S_ALT;
		if (nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if (nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
	}
	else
	{
		if (nPrimary == K_ALT) hudShiftState &= ~S_ALT;
		if (nPrimary == K_CTRL) hudShiftState &= ~S_CTRL;
		if (nPrimary == K_SHIFT) hudShiftState &= ~S_SHIFT;

		if (nPrimary == K_CTRL)
			first_digit = 0;
	}

	// Key release events must be handled by the engine otherwise the on-press command such as +jump
	// executed by pressing SPACE before entering the map voting screen won't be followed by the
	// on-release command (-jump) on key release once entered the map voting screen, causing +jump
	// to stay active even on the next map and automatically forcing the player to join
	if (!key_pressed) return false;

	int imp = 0;
	switch(nPrimary)
	{
		case K_RIGHTARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveRight(mv_selection);
			return true;
		case K_LEFTARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveLeft(mv_selection);
			return true;
		case K_DOWNARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveDown(mv_selection);
			return true;
		case K_UPARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = 1;
			mv_selection = MapVote_MoveUp(mv_selection);
			return true;
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			if (mv_winner)
				return true;
			if ( mv_selection_keyboard )
				MapVote_SendChoice(mv_selection);
			return true;
		case '1': case K_KP_1: imp = 1; break;
		case '2': case K_KP_2: imp = 2; break;
		case '3': case K_KP_3: imp = 3; break;
		case '4': case K_KP_4: imp = 4; break;
		case '5': case K_KP_5: imp = 5; break;
		case '6': case K_KP_6: imp = 6; break;
		case '7': case K_KP_7: imp = 7; break;
		case '8': case K_KP_8: imp = 8; break;
		case '9': case K_KP_9: imp = 9; break;
		case '0': case K_KP_0: imp = 10; break;
	}

	if (imp && hudShiftState & S_CTRL)
	{
		if (!first_digit)
		{
			first_digit = imp % 10;
			return true;
		}
		else
			imp = first_digit * 10 + (imp % 10);
	}

	if (nPrimary == K_MOUSE1)
	{
		mv_selection_keyboard = 0;
		mv_selection = mv_mouse_selection;
		if (mv_selection >= 0)
			imp = min(mv_selection + 1, mv_num_maps);
	}

	if (nPrimary == K_MOUSE2)
		return true; // do nothing

	if (imp)
	{
		if (!mv_winner && imp <= mv_num_maps)
			localcmd(strcat("\nimpulse ", ftos(imp), "\n"));
		return true;
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
		if(mv_flags[i] & GTV_AVAILABLE)
		{
			if(mv_detail)
				mv_votes[i] = ReadByte();
			else
				mv_votes[i] = 0;
		}
		else
			mv_votes[i] = -1;
	}
	if(mv_detail)
		mv_tie_winner = ReadChar();

	mv_ownvote = ReadByte()-1;
}

NET_HANDLE(ENT_CLIENT_MAPVOTE, bool isnew)
{
	make_pure(this);
	int sf = ReadByte();
	return = true;

	if(sf & 1)
		MapVote_Init();

	if(sf & 2)
		MapVote_UpdateMask();

	if(sf & 4)
		MapVote_UpdateVotes();

	if(sf & 8)
	{
		mv_winner = ReadByte();
		mv_winner_time = time;
	}
}

NET_HANDLE(TE_CSQC_PICTURE, bool isNew)
{
	Net_MapVote_Picture();
	return true;
}

void Net_MapVote_Picture()
{
	int type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
}
