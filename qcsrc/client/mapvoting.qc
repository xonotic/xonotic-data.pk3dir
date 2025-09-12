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

// These are mostly the same as server/mapvoting.qc, or otherwise intuitive
string mv_entries[MAPVOTE_COUNT]; // map name or gametype name
string mv_pics[MAPVOTE_COUNT];
string mv_data[MAPVOTE_COUNT];    // map pk3 name or gametype human readable name
string mv_suggester[MAPVOTE_COUNT];
string mv_desc[MAPVOTE_COUNT];
float mv_preview[MAPVOTE_COUNT];
int mv_votes[MAPVOTE_COUNT];
int mv_flags[MAPVOTE_COUNT];
int mv_flags_start[MAPVOTE_COUNT];
float mv_select_lasttime[MAPVOTE_COUNT];
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
string mv_suggester_cache;
float mv_suggester_cachetime;

int mv_selection;
int mv_columns;
int mv_mouse_selection;
bool mv_selection_keyboard;

bool gametypevote;
string mapvote_chosenmap;
vector gtv_text_size;
vector gtv_text_size_small;

const float MV_FADETIME = 0.2;

const int NUM_SSDIRS = 4;
string ssdirs[NUM_SSDIRS];
int n_ssdirs;

bool PreviewExists(string name)
{
	if (autocvar_cl_readpicture_force)
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
	string post;
	string pre = sprintf("%d. ", id + 1);
	if (mv_detail)
	{
		if (_count == 1)
			post = _(" (1 vote)");
		else if (_count >= 0 && (mv_flags[id] & GTV_AVAILABLE))
			post = sprintf(_(" (%d votes)"), _count);
		else
			post = "";
		if (post != "" && (mv_flags[id] & GTV_AVAILABLE))
		if (mv_tie_winner == id || (mv_tie_winner == -2 && _count == most_votes))
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

	vector rgb;
	if (!(mv_flags[id] & GTV_AVAILABLE))
		rgb = '1 1 1';
	else if (id == mv_ownvote)
		rgb = '0 1 0';
	else if (id == mv_selection)
		rgb = '1 1 0';
	else
	{
		const float time_frac = (time - mv_select_lasttime[id]) / MV_FADETIME;
		rgb = '1 1 0' + eZ * (time_frac >= 1 ? 1 : sqrt(time_frac));
	}
	return rgb;
}

void GameTypeVote_DrawGameTypeItem(vector pos, float maxh, float tsize, string gtype, string pic, int _count, int id, int most_votes)
{
	TC(int, id);
	// gtype is unused

	// Find the correct alpha
	float alpha;
	if (!(mv_flags_start[id] & GTV_AVAILABLE))
		alpha = 0.2; // The gametype isn't supported by the map
	else if (!(mv_flags[id] & GTV_AVAILABLE) && mv_top2_alpha)
		alpha = mv_top2_alpha; // Fade away if not one of the top 2 choice
	else
		alpha = 1; // Normal, full alpha
	alpha *= panel_fg_alpha;

	// Bounding box details
	const float rect_margin = hud_fontsize.y * 0.5;

	pos.x += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	pos.y += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	maxh -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);
	tsize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);

	vector rect_pos = pos - '0.5 0.5 0' * rect_margin;
	vector rect_size = '1 1 0';
	rect_size.x = tsize + rect_margin;
	rect_size.y = maxh + rect_margin;

	const vector rgb = MapVote_RGB(id);
	float time_frac;
	if (id == mv_ownvote)
	{
		// Highlight current vote
		time_frac = 0;
		mv_select_lasttime[id] = time; // pretend it's selected, to also enlarge icon
		drawfill(rect_pos, rect_size, rgb, 0.1 * alpha, DRAWFLAG_NORMAL);
		drawborderlines(autocvar_hud_panel_mapvote_highlight_border, rect_pos, rect_size, rgb, alpha, DRAWFLAG_NORMAL);
	}
	else if (mv_flags[id] & GTV_AVAILABLE)
	{
		// Highlight selected item
		if (id == mv_selection)
			time_frac = 0;
		else
			time_frac = (time - mv_select_lasttime[id]) / MV_FADETIME;
		if (time_frac < 1)
			drawfill(rect_pos, rect_size, '1 1 1', 0.1 * (1 - sqrt(time_frac)) * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
		time_frac = 1;

	vector offset = pos;

	const float title_gap = gtv_text_size.y * 1.4; // distance between the title and the description
	pos.y += title_gap;
	maxh -= title_gap;

	// Evaluate the image size
	vector image_size = '3 3 0' * gtv_text_size.x;
	if (maxh < image_size.y)
		image_size = '1 1 0' * maxh;
	image_size *= 0.8;
	const float desc_padding = gtv_text_size.x * 0.6;
	pos.x += image_size.x + desc_padding;

	// Split the description into lines
	entity title = spawn();
	title.message = strcat(rgb_to_hexcolor(rgb), MapVote_FormatMapItem(id, mv_data[id], _count, tsize, gtv_text_size, most_votes));
	tsize -= image_size.x + desc_padding;

	string thelabel = mv_desc[id], ts;
	entity last = title;
	entity next = NULL;
	int nlines = 0;
	if (thelabel != "")
	{
		const int n = tokenizebyseparator(thelabel, "\n");
		for (int i = 0; i < n && maxh > (nlines + 1) * gtv_text_size_small.y; ++i)
		{
			getWrappedLine_remaining = argv(i);
			while (getWrappedLine_remaining && maxh > (nlines + 1) * gtv_text_size_small.y)
			{
				ts = getWrappedLine(tsize, gtv_text_size_small, stringwidth_colors);
				if (ts != "")
				{
					next = spawn();
					next.message = ts;
					next.origin = pos - offset;
					last.chain = next;
					last = next;
					pos.y += gtv_text_size_small.y;
					++nlines;
				}
			}
		}
	}

	// Center the contents in the bounding box
	maxh -= max(nlines * gtv_text_size_small.y, image_size.y);
	if (maxh > 0)
		offset.y += maxh * 0.5;

	// Draw the title
	drawcolorcodedstring(offset, title.message, gtv_text_size, alpha, DRAWFLAG_NORMAL);

	// Draw the icon
	if (pic != "")
	{
		vector offset_padding;
		if (time_frac >= 0 && time_frac < 1)
		{
			const float extra_padding = min(desc_padding, title_gap);
			const float transition_progress = (1 - sqrt(time_frac));
			image_size *= transition_progress * (extra_padding / image_size.x) + 1;
			offset_padding = transition_progress * extra_padding * '-0.5 -0.5 0';
		}
		else
			offset_padding = '0 0 0';
		drawpic(eY * title_gap + eX * 0.5 * desc_padding + offset + offset_padding, pic, image_size, '1 1 1', alpha, DRAWFLAG_NORMAL);
	}

	// Draw the description
	last = title.chain;
	while (last)
	{
		drawstring(last.origin + offset, last.message, gtv_text_size_small, '1 1 1', alpha, DRAWFLAG_NORMAL);
		next = last;
		last = last.chain;
		delete(next);
	}

	// Cleanup
	delete(title);
}

void MapVote_DrawMapPicture(string pic, vector pos, vector img_size, float theAlpha)
{
	if (pic == "")
		drawfill(pos, img_size, '0.5 0.5 0.5', 0.7 * theAlpha, DRAWFLAG_NORMAL);
	else
	{
		if (drawgetimagesize(pic) == '0 0 0')
			drawpic(pos, draw_UseSkinFor("nopreview_map"), img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
		else
			drawpic(pos, pic, img_size, '1 1 1', theAlpha, DRAWFLAG_NORMAL);
	}
}

void MapVote_DrawMapItem(vector pos, float isize, float tsize, string map, string pic, int _count, int id, int most_votes)
{
	TC(int, id);

	const float rect_margin = hud_fontsize.y * 0.5;
	pos.x += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	pos.y += rect_margin + autocvar_hud_panel_mapvote_highlight_border;
	isize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);
	tsize -= 2 * (rect_margin + autocvar_hud_panel_mapvote_highlight_border);

	vector rect_pos = pos - '0.5 0.5 0' * rect_margin;
	vector rect_size = '1 1 0';
	rect_size.x = tsize + rect_margin;
	rect_size.y = isize + rect_margin;

	const float img_ar = 4/3;
	vector img_size = '0 0 0';
	img_size.x = min(tsize, isize * img_ar);
	img_size.y = img_size.x / img_ar;
	img_size.y -= hud_fontsize.y;
	img_size.x = img_size.y * img_ar;

	pos.y += (isize - img_size.y - hud_fontsize.y) * 0.5;

	const vector rgb = MapVote_RGB(id);
	const string label = strcat(rgb_to_hexcolor(rgb), MapVote_FormatMapItem(id, map, _count, tsize, hud_fontsize, most_votes));

	const float text_size = stringwidth(label, true, hud_fontsize);

	const float save_rect_sizex = rect_size.x;
	rect_size.x = max(img_size.x, text_size) + rect_margin;
	rect_pos.x += (save_rect_sizex - rect_size.x) * 0.5;

	vector text_pos;
	text_pos.x = pos.x + (tsize - text_size) * 0.5;
	text_pos.y = pos.y + img_size.y;
	text_pos.z = 0;

	pos.x += (tsize - img_size.x) * 0.5;

	float theAlpha;
	if (!(mv_flags[id] & GTV_AVAILABLE) && mv_top2_alpha)
		theAlpha = mv_top2_alpha;
	else if (mv_winner && mv_winner_alpha)
		theAlpha = mv_winner_alpha;
	else
		theAlpha = 1;
	theAlpha *= panel_fg_alpha;

	if (!mv_winner)
	{
		if (id == mv_ownvote)
		{
			// Highlight current vote
			drawfill(rect_pos, rect_size, rgb, 0.1 * theAlpha, DRAWFLAG_NORMAL);
			drawborderlines(autocvar_hud_panel_mapvote_highlight_border, rect_pos, rect_size, rgb, theAlpha, DRAWFLAG_NORMAL);
		}
		else if (mv_flags[id] & GTV_AVAILABLE)
		{
			// Highlight selected item
			float time_frac;
			if (id == mv_selection)
				time_frac = 0;
			else
				time_frac = (time - mv_select_lasttime[id]) / MV_FADETIME;
			if (time_frac < 1)
				drawfill(rect_pos, rect_size, '1 1 1', 0.1 * (1 - sqrt(time_frac)) * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	drawcolorcodedstring(text_pos, label, hud_fontsize, theAlpha, DRAWFLAG_NORMAL);

	MapVote_DrawMapPicture(pic, pos, img_size, theAlpha);
}

void MapVote_DrawAbstain(vector pos, float tsize, int _count, int id)
{
	const string label = MapVote_FormatMapItem(id, _("Don't care"), _count, tsize, hud_fontsize, -1);

	float theAlpha = (mv_winner && mv_winner_alpha)
		? mv_winner_alpha
		: 1;
	theAlpha *= panel_fg_alpha;
	pos.x -= 0.5 * stringwidth(label, false, hud_fontsize);
	drawstring(pos, label, hud_fontsize, MapVote_RGB(id), theAlpha, DRAWFLAG_NORMAL);
}

void MapVote_DrawSuggester(vector pos)
{
	const int id = mv_winner ? mv_winner - 1 : mv_selection;

	float theAlpha = 0;
	if (id != -1 && (mv_flags[id] & GTV_AVAILABLE)) // if the map is valid, update cache and time
	{
		if (mv_suggester_cache == "" && mv_suggester[id] == "")
			return;
		if (mv_suggester[id] != "") // update cache to current, set time
		{
			mv_suggester_cache = mv_suggester[id];
			mv_suggester_cachetime = time;
			theAlpha = 1;
		}
	}
	if (mv_suggester_cache != "" && theAlpha != 1) // figure out alpha for cache if it's partly-faded
	{
		const float time_frac = (time - mv_suggester_cachetime) / MV_FADETIME;
		if (time_frac >= 1) // finished fading out, delete cache
		{
			mv_suggester_cache = "";
			return;
		}
		theAlpha = (1 - sqrt(time_frac));
	}
	if (!theAlpha)
		return;

	const string label = sprintf(_("Suggested by: %s"), ColorTranslateRGB(mv_suggester_cache));

	theAlpha *= panel_fg_alpha;
	pos.x -= 0.5 * stringwidth(label, true, hud_fontsize);
	drawcolorcodedstring(pos, label, hud_fontsize, theAlpha, DRAWFLAG_NORMAL);
}

vector MapVote_GridVec(vector gridspec, int i, int m)
{
	TC(int, i); TC(int, m);
	const int r = i % m;
	return
		eX * (gridspec.x * r)
		+
		eY * (gridspec.y * (i - r) / m);
}

float MapVote_Selection(vector topleft, vector cellsize, float rows, float columns)
{
	if (mv_winner)
		return -1;

	mv_mouse_selection = -1;

	for (float c, r = 0; r < rows; ++r)
		for (c = 0; c < columns; ++c)
			if (mousepos.x >= topleft.x + cellsize.x *  c
			&&  mousepos.x <= topleft.x + cellsize.x * (c + 1)
			&&  mousepos.y >= topleft.y + cellsize.y *  r
			&&  mousepos.y <= topleft.y + cellsize.y * (r + 1))
			{
				mv_mouse_selection = r * columns + c;
				break;
			}

	if (mv_mouse_selection >= mv_num_maps)
		mv_mouse_selection = -1;
	if (mv_abstain && mv_mouse_selection < 0)
		mv_mouse_selection = mv_num_maps;

	if (mv_selection_keyboard)
		return mv_selection;
	return mv_mouse_selection;
}

// draws map vote or gametype vote
void MapVote_Draw()
{
	//if (intermission != 2) return;
	if (!mv_active)
		return;

	HUD_Panel_LoadCvars();

	const float center = (vid_conwidth - 1) * 0.5;
	xmin = vid_conwidth * (gametypevote ? 0.08 : 0.1);
	xmax = vid_conwidth - xmin;
	ymin = 20;
	ymax = vid_conheight - ymin;

	if (chat_posy + chat_sizey * 0.5 < vid_conheight * 0.5)
		ymin += chat_sizey;
	else
		ymax -= chat_sizey;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");
	if (gametypevote)
	{
		gtv_text_size = hud_fontsize * 1.4;
		gtv_text_size_small = hud_fontsize * 1.1;
	}

	vector pos;
	pos.y = ymin;
	pos.z = 0;

	HUD_Scale_Disable();
	draw_beginBoldFont();

	string map = (gametypevote) ? _("Decide the gametype") : _("Vote for a map");
	if (!mv_winner)
	{
		pos.x = center - stringwidth(map, false, hud_fontsize * 2) * 0.5;
		drawstring(pos, map, hud_fontsize * 2, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	pos.y += hud_fontsize.y * 2;

	if (mapvote_chosenmap != "")
	{
		pos.y += hud_fontsize.y * 0.25;
		pos.x = center - stringwidth(mapvote_chosenmap, false, hud_fontsize * 1.5) * 0.5;
		drawstring(pos, mapvote_chosenmap, hud_fontsize * 1.5, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += hud_fontsize.y * 1.5;
	}
	pos.y += hud_fontsize.y * 0.5;

	draw_endBoldFont();

	int i;
	if (mv_winner)
		map = mv_entries[mv_winner - 1];
	else
	{
		i = ceil(max(1, mv_timeout - time)); // make sure 0 seconds left never shows up, not even for a frame
		map = count_seconds(i);
	}
	pos.x = center - stringwidth(map, false, hud_fontsize * 1.5) * 0.5;
	drawstring(pos, map, hud_fontsize * 1.5, '0 1 0', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += hud_fontsize.y * 1.5;
	pos.y += hud_fontsize.y * 0.5;

	// base for multi-column stuff...
	pos.y += hud_fontsize.y;
	pos.x = xmin;
	ymin = pos.y;
	const float abstain_spacing = panel_bg_border + hud_fontsize.y;
	const float suggester_spacing = hud_fontsize.y * 1.5;
	if (mv_abstain)
	{
		--mv_num_maps;
		ymax -= abstain_spacing;
	}
	const bool were_suggesters = (mv_suggester[0] != ""); // suggestions are placed at the start
	if (were_suggesters)
		ymax -= suggester_spacing;

	// higher than the image itself ratio for mapvote items to reserve space for long map names
	const float item_aspect = (gametypevote) ? 3/1 : 5/3;
	const vector table_size = HUD_GetTableSize_BestItemAR(mv_num_maps, vec2(xmax - xmin, ymax - ymin), item_aspect);
	mv_columns = table_size.x;
	const float rows = table_size.y;

	vector dist;
	dist.x = (xmax - xmin) / mv_columns;
	dist.y = (ymax - pos.y) / rows;
	dist.z = 0;

	// reduce size of too wide items
	float tmp = vid_conwidth / 3; // max width
	if (dist.x > tmp)
	{
		dist.x = tmp;
		dist.y = min(dist.y, dist.x / item_aspect);
	}
	tmp = vid_conheight / 3; // max height
	if (dist.y > tmp)
	{
		dist.y = tmp;
		dist.x = min(dist.x, dist.y * item_aspect);
	}

	// reduce size to fix aspect ratio
	if (dist.x / dist.y > item_aspect)
		dist.x = dist.y * item_aspect;
	else
		dist.y = dist.x / item_aspect;

	// adjust table pos and size according to the new size
	float offset = ((xmax - pos.x) - dist.x * mv_columns) * 0.5;
	xmin = pos.x += offset;
	xmax -= offset;
	offset = ((ymax - pos.y) - dist.y * rows) * 0.5;
	ymax -= 2 * offset;

	// override panel_pos and panel_size
	panel_pos.x = pos.x;
	panel_pos.y = pos.y;
	panel_size.x = xmax - xmin;
	panel_size.y = ymax - ymin;
	HUD_Panel_DrawBg();

	if (panel_bg_padding)
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
	if (mv_selection != -1)
		mv_select_lasttime[mv_selection] = time;

	if (mv_top2_time)
		mv_top2_alpha = max(0.2, 1 - (time - mv_top2_time) ** 2);

	if (mv_winner_time)
		mv_winner_alpha = max(0.2, 1 - sqrt(max(0, time - mv_winner_time)));

	int most_votes = -1;
	if (mv_tie_winner == -2)
		for (i = 0; i < mv_num_maps; ++i)
			if (mv_votes[i] > most_votes)
				most_votes = mv_votes[i];

	void(vector, float, float, string, string, float, int, int) DrawItem;
	if (gametypevote)
		DrawItem = GameTypeVote_DrawGameTypeItem;
	else
		DrawItem = MapVote_DrawMapItem;

	for (i = 0; i < mv_num_maps; ++i)
	{
		tmp = mv_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		map = mv_entries[i];
		const string pic = mv_preview[i] ? mv_pics[i] : "";
		DrawItem(pos + MapVote_GridVec(dist, i, mv_columns), dist.y, dist.x, map, pic, tmp, i, most_votes);
	}

	if (mv_abstain)
		++mv_num_maps;

	pos.y = ymax + abstain_spacing;
	if (mv_abstain && i < mv_num_maps)
	{
		tmp = mv_votes[i];
		pos.x = center;
		MapVote_DrawAbstain(pos, xmax - xmin, tmp, i);
		pos.y += suggester_spacing;
	}

	if (mv_winner)
	{
		// expand winner map image
		vector startsize;
		startsize.z = 0;
		startsize.y = vid_conheight * 0.1;
		startsize.x = startsize.y * 4/3;
		const vector startpos = panel_pos + (panel_size - startsize) * 0.5;

		vector endsize;
		endsize.z = 0;
		endsize.y = vid_conheight * 0.5;
		endsize.x = endsize.y * 4/3;
		vector endpos;
		endpos.z = 0;
		endpos.y = panel_pos.y;
		endpos.x = (vid_conwidth - endsize.x) * 0.5;

		float f = bound(0, sqrt((time - mv_winner_time) * 2), 1);
		const float theAlpha = f;
		f = min(0.1 + f, 1);
		vector img_size = endsize * f + startsize * (1 - f);
		vector img_pos = endpos * f + startpos * (1 - f);

		MapVote_DrawMapPicture(mv_pics[mv_winner - 1], img_pos, img_size, theAlpha);

		if (were_suggesters)
		{
			const float suggester_startposy = pos.y;
			const float suggester_endposy = panel_pos.y + endsize.y + hud_fontsize.y;
			pos.y = suggester_endposy * f + suggester_startposy * (1 - f);
		}
	}

	if (were_suggesters)
	{
		pos.x = center;
		MapVote_DrawSuggester(pos);
	}
}

void Cmd_MapVote_MapDownload(int argc)
{
	TC(int, argc);

	if (argc != 2 || !mv_pk3list)
	{
		LOG_INFO(_("mv_mapdownload: ^3You're not supposed to use this command on your own!"));
		return;
	}

	entity pak;
	const int id = stof(argv(1));
	for (pak = mv_pk3list; pak; pak = pak.chain)
		if (pak.sv_entnum == id)
			break;

	if (!pak || pak.sv_entnum != id)
	{
		LOG_INFO(_("^1Error:^7 Couldn't find pak index."));
		return;
	}

	if (PreviewExists(pak.message))
	{
		mv_preview[id] = true;
		return;
	}
	else
	{
		LOG_INFO(_("Requesting preview..."));
		localcmd("\ncmd mv_getpicture ", ftos(id), "\n");
	}
}

void MapVote_CheckPK3(string pic, string pk3, int id)
{
	TC(int, id);
	entity pak = spawn();
	pak.message = pic;
	pak.netname = pk3;
	pak.sv_entnum = id;

	pak.chain = mv_pk3list;
	mv_pk3list = pak;

	if (pk3 != "")
		localcmd("\ncurl --pak ", pk3, "; wait; cl_cmd mv_download ", itos(id), "\n");
	else
		Cmd_MapVote_MapDownload(tokenize_console(strcat("mv_download ", itos(id))));
}

void MapVote_CheckPic(string pic, string pk3, int id)
{
	TC(int, id);
	// never try to retrieve a pic for the "don't care" 'map'
	if (mv_abstain && id == mv_num_maps - 1)
		return;

	if (PreviewExists(pic))
	{
		mv_preview[id] = true;
		return;
	}
	MapVote_CheckPK3(pic, pk3, id);
}

void MapVote_ReadMask()
{
	int i;
	if (mv_num_maps < 24)
	{
		int mask;
		if (mv_num_maps < 8)
			mask = ReadByte();
		else if (mv_num_maps < 16)
			mask = ReadShort();
		else
			mask = ReadLong();

		for (i = 0; i < mv_num_maps; ++i)
		{
			if (mask & BIT(i))
				mv_flags[i] |= GTV_AVAILABLE;
			else
				mv_flags[i] &= ~GTV_AVAILABLE;
		}
	}
	else
	{
		for (i = 0; i < mv_num_maps; ++i)
			mv_flags[i] = ReadByte();
	}
}

void MapVote_ReadOption(int i)
{
	TC(int, i);

	mv_entries[i] = strzone(ReadString());
	mv_data[i] = strzone(ReadString());
	mv_suggester[i] = strzone(ReadString());
	mv_flags[i] = GTV_AVAILABLE;
	const int j = bound(0, ReadByte(), n_ssdirs - 1);

	mv_pics[i] = strzone(strcat(ssdirs[j], "/", mv_entries[i]));
	mv_preview[i] = false;
	MapVote_CheckPic(mv_pics[i], mv_data[i], i);
}

void GameTypeVote_ReadOption(int i)
{
	TC(int, i);

	mv_entries[i] = strzone(ReadString());
	mv_flags[i] = ReadByte();
	mv_suggester[i] = "";

	string basetype = "";

	if (mv_flags[i] & GTV_CUSTOM)
	{
		string name = ReadString();
		if (strlen(name) < 1)
			name = mv_entries[i];
		mv_data[i] = strzone(name);
		mv_desc[i] = strzone(ReadString());
		basetype = strzone(ReadString());
	}
	else
	{
		const Gametype type = MapInfo_Type_FromString(mv_entries[i], false, false);
		mv_data[i] = strzone(MapInfo_Type_ToText(type));
		mv_desc[i] = MapInfo_Type_Description(type);
	}

	string mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, mv_entries[i]);
	if (precache_pic(mv_picpath) == "")
	{
		mv_picpath = strcat("gfx/menu/wickedx/gametype_", mv_entries[i]);
		if (precache_pic(mv_picpath) == "")
		{
			mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, basetype);
			if (precache_pic(mv_picpath) == "")
				mv_picpath = strcat("gfx/menu/wickedx/gametype_", basetype);
		}
	}
	mv_pics[i] = strzone(mv_picpath);
	mv_preview[i] = PreviewExists(mv_pics[i]);
}

void MapVote_Init()
{
	mv_active = true;
	if (!autocvar_hud_cursormode)
		mousepos = (eX * vid_conwidth + eY * vid_conheight) * 0.5;
	mv_selection = -1;
	mv_selection_keyboard = false;

	string s;
	for (n_ssdirs = 0; ; ++n_ssdirs)
	{
		s = ReadString();
		if (s == "")
			break;
		if (n_ssdirs < NUM_SSDIRS)
			ssdirs[n_ssdirs] = s;
	}
	n_ssdirs = min(n_ssdirs, NUM_SSDIRS);

	mv_num_maps = min(MAPVOTE_COUNT, ReadByte());
	mv_abstain = boolean(ReadByte());
	mv_detail = ReadByte();

	mv_suggester_cache = "";
	mv_suggester_cachetime = 0;

	mv_ownvote = -1;
	mv_timeout = ReadCoord();

	const int gametypevote_flags = ReadByte();
	gametypevote = boolean(gametypevote_flags & BIT(0));
	if (gametypevote_flags)
		mapvote_chosenmap = strzone(ReadString());

	MapVote_ReadMask();
	int i;
	for (i = 0; i < mv_num_maps; ++i)
		mv_flags_start[i] = mv_flags[i];

	// Assume mv_pk3list is NULL, there should only be 1 mapvote per round
	mv_pk3list = NULL; // I'm still paranoid!

	for (i = 0; i < mv_num_maps; ++i)
	{
		mv_votes[i] = 0;
		mv_select_lasttime[i] = 0;

		if (gametypevote)
			GameTypeVote_ReadOption(i);
		else
			MapVote_ReadOption(i);
	}

	for (i = 0; i < n_ssdirs; ++i)
		ssdirs[n_ssdirs] = string_null;
	n_ssdirs = 0;
}

void MapVote_SendChoice(int index)
{
	TC(int, index);
	localcmd("\nimpulse ", ftos(index + 1), "\n");
}

int MapVote_MoveLeft(int pos)
{
	TC(int, pos);
	int imp;
	if (pos < 0)
		imp = mv_num_maps - 1;
	else
		imp = pos < 1 ? mv_num_maps - 1 : pos - 1;
	if (!(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote)
		imp = MapVote_MoveLeft(imp);
	return imp;
}
int MapVote_MoveRight(int pos)
{
	TC(int, pos);
	int imp;
	if (pos < 0)
		imp = 0;
	else
		imp = pos >= mv_num_maps - 1 ? 0 : pos + 1;
	if (!(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote)
		imp = MapVote_MoveRight(imp);
	return imp;
}
int MapVote_MoveUp(int pos)
{
	TC(int, pos);
	int imp;
	if (pos < 0)
		imp = mv_num_maps - 1;
	else
	{
		imp = pos - mv_columns;
		if (imp < 0)
		{
			const int mv_rows = ceil(mv_num_maps / mv_columns);
			if (imp == -mv_columns) // pos == 0
				imp = mv_columns * mv_rows - 1;
			else
				imp = imp + mv_columns * mv_rows - 1;
		}
	}
	if (!(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote)
		imp = MapVote_MoveUp(imp);
	return imp;
}
int MapVote_MoveDown(int pos)
{
	TC(int, pos);
	int imp;
	if (pos < 0)
		imp = 0;
	else
	{
		imp = pos + mv_columns;
		if (imp >= mv_num_maps)
		{
			const int col = imp % mv_columns;
			if (col == mv_columns - 1)
				imp = 0;
			else
				imp = col + 1;
		}
	}
	if (!(mv_flags[imp] & GTV_AVAILABLE) && imp != mv_ownvote)
		imp = MapVote_MoveDown(imp);
	return imp;
}

float MapVote_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	TC(int, bInputType);

	static int first_digit = 0;
	if (!mv_active || isdemo())
		return false;

	if (bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		mv_selection_keyboard = false;
		return true;
	}

	if (bInputType == 2)
	{
		mv_selection_keyboard = false;
		return false;
	}

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	const bool key_pressed = (bInputType == 0);

	if (key_pressed)
	{
		if (nPrimary == K_ALT)   hudShiftState |= S_ALT;
		if (nPrimary == K_CTRL)  hudShiftState |= S_CTRL;
		if (nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
	}
	else
	{
		if (nPrimary == K_ALT)   hudShiftState &= ~S_ALT;
		if (nPrimary == K_CTRL)  hudShiftState &= ~S_CTRL;
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
	switch (nPrimary)
	{
		case K_RIGHTARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = true;
			mv_selection = MapVote_MoveRight(mv_selection);
			return true;
		case K_LEFTARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = true;
			mv_selection = MapVote_MoveLeft(mv_selection);
			return true;
		case K_DOWNARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = true;
			mv_selection = MapVote_MoveDown(mv_selection);
			return true;
		case K_UPARROW:
			if (mv_winner)
				return true;
			mv_selection_keyboard = true;
			mv_selection = MapVote_MoveUp(mv_selection);
			return true;
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			if (mv_winner)
				return true;
			if (mv_selection_keyboard)
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
		mv_selection_keyboard = false;
		mv_selection = mv_mouse_selection;
		if (mv_selection >= 0)
			imp = min(mv_selection + 1, mv_num_maps);
	}

	if (nPrimary == K_MOUSE2)
		return true; // do nothing

	if (imp)
	{
		if (!mv_winner && imp <= mv_num_maps)
			localcmd("\nimpulse ", ftos(imp), "\n");
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
	for (int i = 0; i < mv_num_maps; ++i)
	{
		if (mv_flags[i] & GTV_AVAILABLE)
		{
			if (mv_detail)
				mv_votes[i] = ReadByte();
			else
				mv_votes[i] = 0;
		}
		else
			mv_votes[i] = -1;
	}
	if (mv_detail)
		mv_tie_winner = ReadChar();

	mv_ownvote = ReadByte() - 1;
}

NET_HANDLE(ENT_CLIENT_MAPVOTE, bool isnew)
{
	make_pure(this);
	const int sf = ReadByte();
	return = true;

	if (sf & BIT(0))
		MapVote_Init();

	if (sf & BIT(1))
		MapVote_UpdateMask();

	if (sf & BIT(2))
		MapVote_UpdateVotes();

	if (sf & BIT(3))
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
	const int type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
}
