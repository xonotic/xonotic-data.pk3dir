var float(string text, float handleColors, vector fontSize) stringwidth;

entity players;
entity teams;

void serverAnnouncer()
{
	// check for pending announcement, play it and remove it
	if(announce_snd != "")
	{
		sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/", announce_snd, ".wav"), VOL_BASEVOICE, ATTN_NONE);
		strunzone(announce_snd);
		announce_snd = "";
	}
}

void restartAnnouncer_Think() {
	float countdown_rounded, countdown;
	countdown = getstatf(STAT_GAMESTARTTIME) - time;
	countdown_rounded = floor(0.5 + countdown);
	if(countdown <= 0) {
		if (!spectatee_status) //do cprint only for players
			centerprint(_("^1Begin!"));

		sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/begin.wav"), VOL_BASEVOICE, ATTN_NONE);
		//reset maptime announcers now as well
		announcer_5min = announcer_1min = FALSE;

		remove(self);
		return;
	}
	else {
		if (!spectatee_status) //do cprint only for players
			centerprint(sprintf(_("^1Game starts in %d seconds"), countdown_rounded));

		if(countdown_rounded <= 3 && countdown_rounded >= 1) {
			sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/", ftos(countdown_rounded), ".wav"), VOL_BASEVOICE, ATTN_NONE);
		}

		self.nextthink = getstatf(STAT_GAMESTARTTIME) - (countdown - 1);
	}
}

/**
 * Plays the 1minute or 5 minutes (of maptime) remaining sound, if client wants it
 */
void maptimeAnnouncer() {
	float timelimit;
	timelimit = getstatf(STAT_TIMELIMIT);
	float timeleft;
	timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);

	float warmuplimit;
	float warmuptimeleft;
	if(warmup_stage) {
		warmuplimit = autocvar_g_warmup_limit;
		if(warmuplimit > 0) {
			warmuptimeleft = max(0, warmuplimit + getstatf(STAT_GAMESTARTTIME) - time); 
		}
	}

	//5 minute check
	if (autocvar_cl_sound_maptime_warning >= 2) {
		//make sure that after connect (and e.g. 4 minutes left) we will not get a wrong sound
		if(announcer_5min)
		{
			if(((!warmup_stage || warmuplimit == 0) && timeleft > 300) || (warmup_stage && warmuplimit > 0 && warmuptimeleft > 300))
				announcer_5min = FALSE;
		}
		else if (((!warmup_stage || warmuplimit == 0) && timelimit > 0 && timeleft < 300 && timeleft > 299) || (warmup_stage && warmuplimit > 0 && warmuptimeleft < 300 && warmuptimeleft > 299))
			//if we're in warmup mode, check whether there's a warmup timelimit
			if not (warmuplimit == -1 && warmup_stage) {
				announcer_5min = TRUE;
				sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/5minutesremain.wav"), VOL_BASEVOICE, ATTN_NONE);
			}
	}

	//1 minute check
	if (autocvar_cl_sound_maptime_warning == 1 || autocvar_cl_sound_maptime_warning == 3) {
		if (announcer_1min)
		{
			if(((!warmup_stage || warmuplimit == 0) && timeleft > 60) || (warmup_stage && warmuplimit > 0 && warmuptimeleft > 60))
				announcer_1min = FALSE;
		}
		else if (((!warmup_stage || warmuplimit == 0) && timelimit > 0 && timeleft < 60) || (warmup_stage && warmuplimit > 0 && warmuptimeleft < 60))
			//if we're in warmup mode, check whether there's a warmup timelimit
			if not (warmuplimit == -1 && warmup_stage) {
				announcer_1min = TRUE;
				sound(world, CH_INFO, strcat("announcer/", autocvar_cl_announcer, "/1minuteremains.wav"), VOL_BASEVOICE, ATTN_NONE);
			}
	}
}

/**
 * Announce carried items (e.g. flags in CTF).
 */
float redflag_prev;
float blueflag_prev;
void carrierAnnouncer() {
	float stat_items, redflag, blueflag;
	float pickup;
	string item;

	if not(autocvar_cl_notify_carried_items)
		return;

	stat_items = getstati(STAT_ITEMS);

	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;

	if (redflag == 3 && redflag != redflag_prev) {
		item = _("^1RED^7 flag");
		pickup = (redflag_prev == 2);
	}

	if (blueflag == 3 && blueflag != blueflag_prev) {
		item = _("^4BLUE^7 flag");
		pickup = (blueflag_prev == 2);
	}

	if (item)
	{
		if (pickup) {
			if (autocvar_cl_notify_carried_items & 2)
				centerprint(sprintf(_("You picked up the %s!"), item));
		}
		else {
			if (autocvar_cl_notify_carried_items & 1)
				centerprint(sprintf(_("You got the %s!"), item));
		}
	}

	blueflag_prev = blueflag;
	redflag_prev = redflag;
}

/**
 * Add all future announcer sounds precaches here.
 * TODO: announcer queues
 */
void Announcer_Precache () {
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1minuteremains.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/5minutesremain.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/electrobitch.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/airshot.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/03kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/05kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/10kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/15kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/20kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/25kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/30kills.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/botlike.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/yoda.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/amazing.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/awesome.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/headshot.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/impressive.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/prepareforbattle.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/begin.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/timeoutcalled.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1fragleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/2fragsleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/3fragsleft.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/terminated.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/1.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/2.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/3.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/4.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/5.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/6.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/7.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/8.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/9.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/10.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/lastsecond.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/narrowly.wav"));

	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/voteaccept.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/votecall.wav"));
	precache_sound (strcat("announcer/", autocvar_cl_announcer, "/votefail.wav"));
}

void AuditLists()
{
	entity e;
	entity prev;

	prev = players;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}

	prev = teams;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}
}


float RegisterPlayer(entity player)
{
	entity pl;
	AuditLists();
	for(pl = players.sort_next; pl; pl = pl.sort_next)
		if(pl == player)
			error("Player already registered!");
	player.sort_next = players.sort_next;
	player.sort_prev = players;
	if(players.sort_next)
		players.sort_next.sort_prev = player;
	players.sort_next = player;
	AuditLists();
	return true;
}

void RemovePlayer(entity player)
{
	entity pl, parent;
	AuditLists();
	parent = players;
	for(pl = players.sort_next; pl && pl != player; pl = pl.sort_next)
		parent = pl;

	if(!pl)
	{
		error("Trying to remove a player which is not in the playerlist!");
		return;
	}
	parent.sort_next = player.sort_next;
	if(player.sort_next)
		player.sort_next.sort_prev = parent;
	AuditLists();
}

void MoveToLast(entity e)
{
	AuditLists();
	other = e.sort_next;
	while(other)
	{
		SORT_SWAP(other, e);
		other = e.sort_next;
	}
	AuditLists();
}

float RegisterTeam(entity Team)
{
	entity tm;
	AuditLists();
	for(tm = teams.sort_next; tm; tm = tm.sort_next)
		if(tm == Team)
			error("Team already registered!");
	Team.sort_next = teams.sort_next;
	Team.sort_prev = teams;
	if(teams.sort_next)
		teams.sort_next.sort_prev = Team;
	teams.sort_next = Team;
	AuditLists();
	return true;
}

void RemoveTeam(entity Team)
{
	entity tm, parent;
	AuditLists();
	parent = teams;
	for(tm = teams.sort_next; tm && tm != Team; tm = tm.sort_next)
		parent = tm;

	if(!tm)
	{
		print(_("Trying to remove a team which is not in the teamlist!"));
		return;
	}
	parent.sort_next = Team.sort_next;
	if(Team.sort_next)
		Team.sort_next.sort_prev = parent;
	AuditLists();
}

entity GetTeam(float Team, float add)
{
	float num;
	entity tm;
	num = (Team == COLOR_SPECTATOR) ? 16 : Team;
	if(teamslots[num])
		return teamslots[num];
	if not(add)
		return NULL;
	tm = spawn();
	tm.team = Team;
	teamslots[num] = tm;
	RegisterTeam(tm);
	return tm;
}

vector HUD_GetFontsize(string cvarname)
{
	vector v;
	v = stov(cvar_string(cvarname));
	if(v_x == 0)
		v = '8 8 0';
	if(v_y == 0)
		v_y = v_x;
	v_z = 0;
	return v;
}

float PreviewExists(string name)
{
	if(autocvar_cl_readpicture_force)
		return false;

	if (fexists(strcat(name, ".tga"))) return true;
	if (fexists(strcat(name, ".png"))) return true;
	if (fexists(strcat(name, ".jpg"))) return true;
	if (fexists(strcat(name, ".pcx"))) return true;

	return false;
}

vector rotate(vector v, float a)
{
	vector w;
	// FTEQCC SUCKS AGAIN
	w_x =      v_x * cos(a) + v_y * sin(a);
	w_y = -1 * v_x * sin(a) + v_y * cos(a);
	return w;
}

float ColorTranslateMode;

string ColorTranslateRGB(string s)
{
	if(ColorTranslateMode & 1)
		return strdecolorize(s);
	else
		return s;
}

string Team_ColorCode(float teamid)
{
    if (teamid == COLOR_TEAM1)
        return "^1";
    else if (teamid == COLOR_TEAM2)
        return "^4";
    else if (teamid == COLOR_TEAM3)
        return "^3";
    else if (teamid == COLOR_TEAM4)
        return "^6";
    else
        return "^7";
}

// decolorizes and team colors the player name when needed
string playername(string thename, float teamid)
{
    string t;
    if (teamplay)
    {
        t = Team_ColorCode(teamid);
        return strcat(t, strdecolorize(thename));
    }
    else
        return strdecolorize(thename);
}

float cvar_or(string cv, float v)
{
	string s;
	s = cvar_string(cv);
	if(s == "")
		return v;
	else
		return stof(s);
}

vector project_3d_to_2d(vector vec)
{
	vec = cs_project(vec);
	if(cs_project_is_b0rked > 0)
	{
		vec_x *= vid_conwidth / vid_width;
		vec_y *= vid_conheight / vid_height;
	}
	return vec;
}

void dummyfunction(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8)
{
}

float expandingbox_sizefactor_from_fadelerp(float fadelerp)
{
	return 1.2 / (1.2 - fadelerp);
}

vector expandingbox_resize_centered_box_offset(float sz, vector boxsize, float boxxsizefactor)
{
	boxsize_x *= boxxsizefactor; // easier interface for text
	return boxsize * (0.5 * (1 - sz));
}

void drawborderlines(float thickness, vector pos, vector dim, vector color, float alpha, float drawflag)
{
	vector line_dim;

	// left and right lines
	pos_x -= thickness;
	line_dim_x = thickness;
	line_dim_y = dim_y;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_x + thickness) * '1 0 0', line_dim, color, alpha, drawflag);

	// upper and lower lines
	pos_y -= thickness;
	line_dim_x = dim_x + thickness * 2; // make upper and lower lines longer
	line_dim_y = thickness;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_y + thickness) * '0 1 0', line_dim, color, alpha, drawflag);
}

void drawpic_tiled(vector pos, string pic, vector sz, vector area, vector color, float alpha, float drawflag)
{
	vector current_pos, end_pos, new_size, ratio;
	end_pos = pos + area;

	current_pos_y = pos_y;
	while (current_pos_y < end_pos_y)
	{
		current_pos_x = pos_x;
		while (current_pos_x < end_pos_x)
		{
			new_size_x = min(sz_x, end_pos_x - current_pos_x);
			new_size_y = min(sz_y, end_pos_y - current_pos_y);
			ratio_x = new_size_x / sz_x;
			ratio_y = new_size_y / sz_y;
			drawsubpic(current_pos, new_size, pic, '0 0 0', ratio, color, alpha, drawflag);
			current_pos_x += sz_x;
		}
		current_pos_y += sz_y;
	}
}

// drawpic wrapper to draw an image as large as possible with preserved aspect ratio into a box
var float _drawpic_imgaspect;
var vector _drawpic_imgsize;
var vector _drawpic_sz;
var float _drawpic_oldsz;
var string _drawpic_picpath;
#define drawpic_aspect(pos,pic,mySize,color,alpha,drawflag)\
	do {\
		_drawpic_imgsize = drawgetimagesize(pic);\
		_drawpic_imgaspect = _drawpic_imgsize_x/_drawpic_imgsize_y;\
		_drawpic_sz = mySize;\
		if(_drawpic_sz_x/_drawpic_sz_y > _drawpic_imgaspect) {\
			_drawpic_oldsz = _drawpic_sz_x;\
			_drawpic_sz_x = _drawpic_sz_y * _drawpic_imgaspect;\
			drawpic(pos + eX * (_drawpic_oldsz - _drawpic_sz_x) * 0.5, pic, _drawpic_sz, color, alpha, drawflag);\
		} else {\
			_drawpic_oldsz = _drawpic_sz_y;\
			_drawpic_sz_y = _drawpic_sz_x / _drawpic_imgaspect;\
			drawpic(pos + eY * (_drawpic_oldsz - _drawpic_sz_y) * 0.5, pic, _drawpic_sz, color, alpha, drawflag);\
		}\
	} while(0)

// draw HUD element with image from gfx/hud/hud_skin/foo.tga if it exists, otherwise gfx/hud/default/foo.tga
#define drawpic_aspect_skin(pos,pic,sz,color,alpha,drawflag)\
	do{\
		_drawpic_picpath = strcat(hud_skin_path, "/", pic);\
		if(precache_pic(_drawpic_picpath) == "") {\
			_drawpic_picpath = strcat("gfx/hud/default/", pic);\
		}\
		drawpic_aspect(pos, _drawpic_picpath, sz, color, alpha, drawflag);\
		_drawpic_picpath = string_null;\
	} while(0)

// draw HUD element with image from gfx/hud/hud_skin/foo.tga if it exists, otherwise gfx/hud/default/foo.tga
#define drawpic_skin(pos,pic,sz,color,alpha,drawflag)\
	do{\
		_drawpic_picpath = strcat(hud_skin_path, "/", pic);\
		if(precache_pic(_drawpic_picpath) == "") {\
			_drawpic_picpath = strcat("gfx/hud/default/", pic);\
		}\
		drawpic(pos, _drawpic_picpath, sz, color, alpha, drawflag);\
		_drawpic_picpath = string_null;\
	} while(0)

void drawpic_aspect_skin_expanding(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	drawpic_aspect_skin(position + expandingbox_resize_centered_box_offset(sz, scale, 1), pic, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void drawpic_aspect_skin_expanding_two(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	drawpic_aspect_skin_expanding(position, pic, scale, rgb, alpha, flag, fadelerp);
	drawpic_skin(position, pic, scale, rgb, alpha * fadelerp, flag);
}
#define SET_POS_AND_SZ_Y_ASPECT(allow_colors)\
	float textaspect, oldsz;\
	textaspect = stringwidth(text, allow_colors, '1 1 1' * sz_y) / sz_y;\
	if(sz_x/sz_y > textaspect) {\
		oldsz = sz_x;\
		sz_x = sz_y * textaspect;\
		pos_x += (oldsz - sz_x) * 0.5;\
	} else {\
		oldsz = sz_y;\
		sz_y = sz_x / textaspect; \
		pos_y += (oldsz - sz_y) * 0.5;\
	}

// drawstring wrapper to draw a string as large as possible with preserved aspect ratio into a box
void drawstring_aspect(vector pos, string text, vector sz, vector color, float alpha, float drawflag) {
	SET_POS_AND_SZ_Y_ASPECT(FALSE)
	drawstring(pos, text, '1 1 0' * sz_y, color, alpha, drawflag);
}

// drawstring wrapper to draw a colorcodedstring as large as possible with preserved aspect ratio into a box
void drawcolorcodedstring_aspect(vector pos, string text, vector sz, float alpha, float drawflag) {
	SET_POS_AND_SZ_Y_ASPECT(TRUE)
	drawcolorcodedstring(pos, text, '1 1 0' * sz_y, alpha, drawflag);
}

vector drawfontscale;
void drawstring_expanding(vector position, string text, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	drawfontscale = sz * '1 1 0';
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, FALSE, scale * (sz / drawfontscale_x)) / (scale_x * sz)), text, scale * (sz / drawfontscale_x), rgb, alpha * (1 - fadelerp), flag);
	// width parameter:
	//    (scale_x * sz / drawfontscale_x) * drawfontscale_x * SIZE1 / (scale_x * sz)
	//    SIZE1
	drawfontscale = '1 1 0';
}

// drawstring wrapper to draw a string as large as possible with preserved aspect ratio into a box
void drawstring_aspect_expanding(vector pos, string text, vector sz, vector color, float alpha, float drawflag, float fadelerp) {
	SET_POS_AND_SZ_Y_ASPECT(FALSE)
	drawstring_expanding(pos, text, '1 1 0' * sz_y, color, alpha, drawflag, fadelerp);
}

void drawcolorcodedstring_expanding(vector position, string text, vector scale, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	drawfontscale = sz * '1 1 0';
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawcolorcodedstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, TRUE, scale * (sz / drawfontscale_x)) / (scale_x * sz)), text, scale * (sz / drawfontscale_x), alpha * (1 - fadelerp), flag);
	drawfontscale = '1 1 0';
}

void drawcolorcodedstring_aspect_expanding(vector pos, string text, vector sz, float alpha, float drawflag, float fadelerp) {
	SET_POS_AND_SZ_Y_ASPECT(TRUE)
	drawcolorcodedstring_expanding(pos, text, '1 1 0' * sz_y, alpha, drawflag, fadelerp);
}

// this draws the triangles of a model DIRECTLY. Don't expect high performance, really...
float PolyDrawModelSurface(entity e, float i_s)
{
	float i_t;
	float n_t;
	vector tri;
	string tex;
	tex = getsurfacetexture(e, i_s);
	if not(tex)
		return 0; // this is beyond the last one
	n_t = getsurfacenumtriangles(e, i_s);
	for(i_t = 0; i_t < n_t; ++i_t)
	{
		tri = getsurfacetriangle(e, i_s, i_t);
		R_BeginPolygon(tex, 0);
		R_PolygonVertex(getsurfacepoint(e, i_s, tri_x), getsurfacepointattribute(e, i_s, tri_x, SPA_TEXCOORDS0), '1 1 1', 1);
		R_PolygonVertex(getsurfacepoint(e, i_s, tri_y), getsurfacepointattribute(e, i_s, tri_y, SPA_TEXCOORDS0), '1 1 1', 1);
		R_PolygonVertex(getsurfacepoint(e, i_s, tri_z), getsurfacepointattribute(e, i_s, tri_z, SPA_TEXCOORDS0), '1 1 1', 1);
		R_EndPolygon();
	}
	return 1;
}
void PolyDrawModel(entity e)
{
	float i_s;
	for(i_s = 0; ; ++i_s)
		if(!PolyDrawModelSurface(e, i_s))
			break;
}

void DrawCircleClippedPic(vector centre, float radius, string pic, float f, vector rgb, float a, float drawflag)
{
	float x, y, q, d;
	vector ringsize, v, t;
	ringsize = radius * '1 1 0';

	x = cos(f * 2 * M_PI);
	y = sin(f * 2 * M_PI);
	q = fabs(x) + fabs(y);
	x /= q;
	y /= q;

	if(f >= 1)
	{
		// draw full rectangle
		R_BeginPolygon(pic, drawflag);
			v = centre;			t = '0.5 0.5 0';
			v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y += 0.5 * ringsize_y;	t += '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_x -= 0.5 * ringsize_x;	t -= '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y -= 0.5 * ringsize_y;	t -= '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);
		R_EndPolygon();

		d = q - 1;
		if(d > 0)
		{
			R_BeginPolygon(pic, drawflag);
				v = centre;			t = '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);

				v = centre;			t = '0.5 0.5 0';
				v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);
		}
	}
	else if(f > 0.75)
	{
		// draw upper and first triangle
		R_BeginPolygon(pic, drawflag);
			v = centre;			t = '0.5 0.5 0';
			v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y += 0.5 * ringsize_y;	t += '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_x -= 0.5 * ringsize_x;	t -= '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);
		R_EndPolygon();
		R_BeginPolygon(pic, drawflag);
			v = centre;			t = '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_x -= 0.5 * ringsize_x;	t -= '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y -= 0.5 * ringsize_y;	t -= '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);

		d = q - 0.75;
		if(d <= 0)
			R_EndPolygon();
	}
	else if(f > 0.5)
	{
		// draw upper triangle
		R_BeginPolygon(pic, drawflag);
			v = centre;			t = '0.5 0.5 0';
			v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y += 0.5 * ringsize_y;	t += '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_x -= 0.5 * ringsize_x;	t -= '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);
		R_EndPolygon();

		d = q - 0.5;
		if(d > 0)
		{
			R_BeginPolygon(pic, drawflag);
				v = centre;			t = '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);

				v = centre;			t = '0.5 0.5 0';
				v_x -= 0.5 * ringsize_x;	t -= '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);
		}
	}
	else if(f > 0.25)
	{
		// draw first triangle
		R_BeginPolygon(pic, drawflag);
			v = centre;			t = '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
			R_PolygonVertex(v, t, rgb, a);

			v = centre;			t = '0.5 0.5 0';
			v_y += 0.5 * ringsize_y;	t += '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);

		d = q - 0.25;
		if(d <= 0)
			R_EndPolygon();
	}
	else
	{
		d = q;
		if(d > 0)
		{
			R_BeginPolygon(pic, drawflag);
				v = centre;			t = '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);

				v = centre;			t = '0.5 0.5 0';
				v_x += 0.5 * ringsize_x;	t += '0.5 0.5 0';
				R_PolygonVertex(v, t, rgb, a);
		}
	}

	if(d > 0)
	{
			v = centre;			t = '0.5 0.5 0';
			v_x += x * 0.5 * ringsize_x;	t += x * '0.5 0.5 0';
			v_y += y * 0.5 * ringsize_y;	t += y * '0.5 -0.5 0';
			R_PolygonVertex(v, t, rgb, a);
		R_EndPolygon();
	}
}

const vector GETPLAYERORIGIN_ERROR = '1123581321 2357111317 3141592653'; // way out of bounds for anything on the map
vector getplayerorigin(float pl)
{
	string s;
	entity e;

	s = getplayerkey(pl, "TEMPHACK_origin");
	if(s != "")
		return stov(s);

	e = entcs_receiver[pl];
	if(e)
		return e.origin;

	return GETPLAYERORIGIN_ERROR;
}
