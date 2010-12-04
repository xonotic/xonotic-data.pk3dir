#define spider_rocket_icon "gfx/vehicles/rocket_ico.tga"
#define spider_rocket_targ "gfx/vehicles/target.tga"
#define SPIDER_CROSS "textures/spiderbot/cross.tga"
#define rkt_size 32
#define rld_size_x 256
#define rld_size_y 16

void CSQC_WAKIZASHI_HUD();

entity porto;
vector polyline[16];
float trace_dphitcontents;
float trace_networkentity;
float Q3SURFACEFLAG_SLICK = 2; // low friction surface
float DPCONTENTS_SOLID = 1; // blocks player movement
float DPCONTENTS_BODY = 32; // blocks player movement
float DPCONTENTS_CORPSE = 64; // blocks player movement
float DPCONTENTS_PLAYERCLIP = 256; // blocks player movement
void Porto_Draw()
{
	vector p, dir, ang, q, nextdir;
	float idx, portal_number, portal1_idx;

	if(activeweapon != WEP_PORTO || spectatee_status || gametype == GAME_NEXBALL)
		return;
	if(intermission == 1)
		return;
	if(intermission == 2)
		return;
	if (getstati(STAT_HEALTH) <= 0)
		return;

	dir = view_forward;

	if(angles_held_status)
	{
		makevectors(angles_held);
		dir = v_forward;
	}

	p = view_origin;

	polyline[0] = p;
	idx = 1;
	portal_number = 0;
	nextdir = dir;

	for(;;)
	{
		dir = nextdir;
		traceline(p, p + 65536 * dir, TRUE, porto);
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
		nextdir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal; // mirror dir at trace_plane_normal
		p = trace_endpos;
		polyline[idx] = p;
		++idx;
		if(idx >= 16)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			continue;
		++portal_number;
		ang = vectoangles2(trace_plane_normal, dir);
		ang_x = -ang_x;
		makevectors(ang);
		if(!CheckWireframeBox(porto, p - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
			return;
		if(portal_number == 1)
			portal1_idx = idx;
		if(portal_number >= 2)
			break;
	}

	while(idx >= 2)
	{
		p = polyline[idx-2];
		q = polyline[idx-1];
		if(idx == 2)
			p = p - view_up * 16;
		if(idx-1 >= portal1_idx)
		{
			Draw_CylindricLine(p, q, 4, "", 1, 0, '0 0 1', 0.5, DRAWFLAG_NORMAL, view_origin);
		}
		else
		{
			Draw_CylindricLine(p, q, 4, "", 1, 0, '1 0 0', 0.5, DRAWFLAG_NORMAL, view_origin);
		}
		--idx;
	}
}

/**
 * Checks whether the server initiated a map restart (stat_game_starttime changed)
 *
 * TODO: Use a better solution where a common shared entitiy is used that contains
 * timelimit, fraglimit and game_starttime! Requires engine changes (remove STAT_TIMELIMIT
 * and STAT_FRAGLIMIT to be auto-sent)
 */
void CheckForGamestartChange() {
	float startTime;
	startTime = getstatf(STAT_GAMESTARTTIME);
	if (previous_game_starttime != startTime) {
		if ((time + 5.0) < startTime) {
			//if connecting to server while restart was active don't always play prepareforbattle
			sound(world, CHAN_AUTO, strcat("announcer/", autocvar_cl_announcer, "/prepareforbattle.wav"), VOL_BASEVOICE, ATTN_NONE);
		}
		if (time < startTime) {
			restartAnnouncer = spawn();
			restartAnnouncer.think = restartAnnouncer_Think;
			restartAnnouncer.nextthink = startTime - floor(startTime - time); //synchronize nextthink to startTime
		}
	}
	previous_game_starttime = startTime;
}

void Porto_Init()
{
	porto = spawn();
	porto.classname = "porto";
	porto.draw = Porto_Draw;
	porto.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

float drawtime;
float avgspeed;
vector GetCurrentFov(float fov)
{
	float zoomsensitivity, zoomspeed, zoomfactor, zoomdir, velocityzoom;

	zoomsensitivity = autocvar_cl_zoomsensitivity;
	zoomfactor = autocvar_cl_zoomfactor;
	if(zoomfactor < 1 || zoomfactor > 16)
		zoomfactor = 2.5;
	zoomspeed = autocvar_cl_zoomspeed;
	if(zoomspeed >= 0)
		if(zoomspeed < 0.5 || zoomspeed > 16)
			zoomspeed = 3.5;

	zoomdir = button_zoom;
	if((getstati(STAT_ACTIVEWEAPON) == WEP_NEX && nex_scope) || (getstati(STAT_ACTIVEWEAPON) == WEP_CAMPINGRIFLE && campingrifle_scope)) // do NOT use switchweapon here
		zoomdir += button_attack2;
	if(spectatee_status > 0 || isdemo())
	{
		if(spectatorbutton_zoom)
			zoomdir = 0 + !zoomdir;
		// do not even THINK about removing this 0
		// _I_ know what I am doing
		// fteqcc does not
	}

	if(zoomdir)
		zoomin_effect = 0;

	if(zoomin_effect || camera_active)
	{
		current_viewzoom = min(1, current_viewzoom + drawframetime);
	}
	else
	{
		if(zoomspeed < 0) // instant zoom
		{
			if(zoomdir)
				current_viewzoom = 1 / zoomfactor;
			else
				current_viewzoom = 1;
		}
		else
		{
			if(zoomdir)
				current_viewzoom = 1 / bound(1, 1 / current_viewzoom + drawframetime * zoomspeed * (zoomfactor - 1), zoomfactor);
			else
				current_viewzoom = bound(1 / zoomfactor, current_viewzoom + drawframetime * zoomspeed * (1 - 1 / zoomfactor), 1);
		}
	}

	if(almost_equals(current_viewzoom, 1))
		current_zoomfraction = 0;
	else if(almost_equals(current_viewzoom, 1/zoomfactor))
		current_zoomfraction = 1;
	else
		current_zoomfraction = (current_viewzoom - 1) / (1/zoomfactor - 1);

	if(zoomsensitivity < 1)
		setsensitivityscale(pow(current_viewzoom, 1 - zoomsensitivity));
	else
		setsensitivityscale(1);

	velocityzoom = bound(0, drawframetime / max(0.000000001, autocvar_cl_velocityzoomtime), 1);
	avgspeed = avgspeed * (1 - velocityzoom) + (vlen(pmove_vel) / 1000) * velocityzoom;
	velocityzoom = exp(float2range11(avgspeed * -autocvar_cl_velocityzoom / 1) * 1);

	//print(ftos(avgspeed), " avgspeed, ", ftos(autocvar_cl_velocityzoom), " cvar, ", ftos(velocityzoom), " return\n"); // for debugging

	float frustumx, frustumy, fovx, fovy;
	frustumy = tan(fov * M_PI / 360.0) * 0.75 * current_viewzoom * velocityzoom;
	frustumx = frustumy * vid_width / vid_height / vid_pixelheight;
	fovx = atan2(frustumx, 1) / M_PI * 360.0;
	fovy = atan2(frustumy, 1) / M_PI * 360.0;

	return '1 0 0' * fovx + '0 1 0' * fovy;
}

// this function must match W_SetupShot!
float zoomscript_caught;

vector wcross_origin;
float wcross_scale_prev, wcross_alpha_prev;
vector wcross_color_prev;
float wcross_scale_goal_prev, wcross_alpha_goal_prev;
vector wcross_color_goal_prev;
float wcross_changedonetime;

string wcross_name_goal_prev, wcross_name_goal_prev_prev;
float wcross_resolution_goal_prev, wcross_resolution_goal_prev_prev;
float wcross_name_changestarttime, wcross_name_changedonetime;
float wcross_name_alpha_goal_prev, wcross_name_alpha_goal_prev_prev;
entity trueaim;
entity trueaim_rifle;

#define SHOTTYPE_HITTEAM 1
#define SHOTTYPE_HITOBSTRUCTION 2
#define SHOTTYPE_HITWORLD 3
#define SHOTTYPE_HITENEMY 4

void TrueAim_Init()
{
	trueaim = spawn();
	trueaim.classname = "trueaim";
	trueaim.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	trueaim_rifle = spawn();
	trueaim_rifle.classname = "trueaim_rifle";
	trueaim_rifle.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
}

float EnemyHitCheck()
{
	float t;
	wcross_origin = project_3d_to_2d(trace_endpos);
	wcross_origin_z = 0;
	if(trace_networkentity < 1)
		return SHOTTYPE_HITWORLD;
	if(trace_networkentity > maxclients)
		return SHOTTYPE_HITWORLD;
	t = GetPlayerColor(trace_networkentity - 1);
	if(teamplay)
		if(t == myteam)
			return SHOTTYPE_HITTEAM;
	if(t == COLOR_SPECTATOR)
		return SHOTTYPE_HITWORLD;
	return SHOTTYPE_HITENEMY;
}

float TrueAimCheck()
{
	float nudge = 1; // added to traceline target and subtracted from result
	vector vecs, trueaimpoint, w_shotorg;
	vector mi, ma, dv;
	float shottype;
	entity ta;
	float mv;

	mi = ma = '0 0 0';
	ta = trueaim;
	mv = MOVE_NOMONSTERS;

	switch(activeweapon)
	{
		case WEP_TUBA: // no aim
		case WEP_PORTO: // shoots from eye
		case WEP_HOOK: // no trueaim
		case WEP_GRENADE_LAUNCHER: // toss curve
			return SHOTTYPE_HITWORLD;
		case WEP_NEX:
		case WEP_MINSTANEX:
			mv = MOVE_NORMAL;
			break;
		case WEP_CAMPINGRIFLE:
			ta = trueaim_rifle;
			mv = MOVE_NORMAL;
			if(zoomscript_caught)
			{
				tracebox(view_origin, '0 0 0', '0 0 0', view_origin + view_forward * MAX_SHOT_DISTANCE, mv, ta);
				return EnemyHitCheck();
			}
			break;
		case WEP_ROCKET_LAUNCHER: // projectile has a size!
			mi = '-3 -3 -3';
			ma = '3 3 3';
			break;
		case WEP_FIREBALL: // projectile has a size!
			mi = '-16 -16 -16';
			ma = '16 16 16';
			break;
		case WEP_SEEKER: // projectile has a size!
			mi = '-2 -2 -2';
			ma = '2 2 2';
			break;
		case WEP_ELECTRO: // projectile has a size!
			mi = '0 0 -3';
			ma = '0 0 -3';
			break;
	}

	vecs = decompressShotOrigin(getstati(STAT_SHOTORG));

	traceline(view_origin, view_origin + view_forward * MAX_SHOT_DISTANCE, mv, ta);
	trueaimpoint = trace_endpos;

	if(vecs_x > 0)
		vecs_y = -vecs_y;
	else
		vecs = '0 0 0';

	dv = view_right * vecs_y + view_up * vecs_z;
	w_shotorg = view_origin + dv;

	// now move the vecs forward as much as requested if possible
	tracebox(w_shotorg, mi, ma, w_shotorg + view_forward * (vecs_x + nudge), MOVE_NORMAL, ta); // FIXME this MOVE_NORMAL part will misbehave a little in csqc
	w_shotorg = trace_endpos - view_forward * nudge;

	tracebox(w_shotorg, mi, ma, trueaimpoint, MOVE_NORMAL, ta);
	shottype = EnemyHitCheck();
	if(shottype != SHOTTYPE_HITWORLD)
		return shottype;

#if 0
	// FIXME WHY DOES THIS NOT WORK FOR THE ROCKET LAUNCHER?
	// or rather, I know why, but see no fix
	if(vlen(trace_endpos - trueaimpoint) > vlen(ma) + vlen(mi) + 1)
		// yes, this is an ugly hack... but it seems good enough to find out whether the test hits the same place as the initial trace
		return SHOTTYPE_HITOBSTRUCTION;
#endif

	return SHOTTYPE_HITWORLD;
}

void CSQC_common_hud(void);

void PostInit(void);
void CSQC_Demo_Camera();
float HUD_WouldDrawScoreboard();
float view_set;
float camera_mode;
float reticle_type;
string NextFrameCommand;
void CSQC_SPIDER_HUD();
void CSQC_RAPTOR_HUD();

vector freeze_pmove_org, freeze_input_angles;
entity nightvision_noise, nightvision_noise2;

float pickup_crosshair_time, pickup_crosshair_size;
float use_nex_chargepool;

float myhealth, myhealth_prev;
float myhealth_flash;

vector myhealth_gentlergb;

void CSQC_UpdateView(float w, float h)
{
	entity e;
	float fov;
	float f, i, j;
	vector v, vo;
	vector vf_size, vf_min;
	float a;

	vf_size = R_SetView3fv(VF_SIZE);
	vf_min = R_SetView3fv(VF_MIN);
	vid_width = vf_size_x;
	vid_height = vf_size_y;

	vector reticle_pos, reticle_size;

	WaypointSprite_Load();

	if(spectatee_status)
		myteam = GetPlayerColor(spectatee_status - 1);
	else
		myteam = GetPlayerColor(player_localentnum - 1);

	ticrate = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
	vo = '0 0 1' * getstati(STAT_VIEWHEIGHT);

	warpzone_fixview_origin = pmove_org + vo;
	warpzone_fixview_cl_viewangles = input_angles;
	warpzone_fixview_angles = view_angles;
	WarpZone_FixView();
	pmove_org = warpzone_fixview_origin - vo;
	input_angles = warpzone_fixview_cl_viewangles;
	view_angles = warpzone_fixview_angles;

	if(autocvar_cl_lockview || (autocvar__hud_configure && spectatee_status <= 0))
	{
		pmove_org = freeze_pmove_org;
		input_angles = view_angles = freeze_input_angles;
		R_SetView(VF_ORIGIN, pmove_org + vo);
		R_SetView(VF_ANGLES, view_angles);
		//R_SetView(VF_CL_VIEWANGLES, input_angles);
	}
	freeze_pmove_org = pmove_org;
	freeze_input_angles = input_angles;

	// Render the Scene
	if(!intermission || !view_set)
	{
		view_origin = pmove_org + vo;
		view_angles = input_angles;
		makevectors(view_angles);
		view_forward = v_forward;
		view_right = v_right;
		view_up = v_up;
		view_set = 1;
	}

#ifdef BLURTEST
	if(time > blurtest_time0 && time < blurtest_time1)
	{
		float r, t;

		t = (time - blurtest_time0) / (blurtest_time1 - blurtest_time0);
		r = t * blurtest_radius;
		f = 1 / pow(t, blurtest_power) - 1;

		cvar_set("r_glsl_postprocess", "1");
		cvar_set("r_glsl_postprocess_uservec1", strcat(ftos(r), " ", ftos(f), " 0 0"));
	}
	else
	{
		cvar_set("r_glsl_postprocess", "0");
		cvar_set("r_glsl_postprocess_uservec1", "0 0 0 0");
	}
#endif

	TargetMusic_Advance();
	Fog_Force();

	drawframetime = max(0.000001, time - drawtime);
	drawtime = time;

	// watch for gametype changes here...
	// in ParseStuffCMD the cmd isn't executed yet :/
	// might even be better to add the gametype to TE_CSQC_INIT...?
	if(!postinit)
		PostInit();

	if(intermission && !isdemo() && !(calledhooks & HOOK_END))
		if(calledhooks & HOOK_START)
		{
			localcmd("\ncl_hook_gameend\n");
			calledhooks |= HOOK_END;
		}

	CheckForGamestartChange();
	serverAnnouncer();
	maptimeAnnouncer();
	carrierAnnouncer();

	fov = autocvar_fov;
	if(button_zoom || fov <= 59.5)
	{
		if(!zoomscript_caught)
		{
			localcmd("+button4\n");
			zoomscript_caught = 1;
			ignore_plus_zoom += 1;
		}
	}
	else
	{
		if(zoomscript_caught)
		{
			localcmd("-button4\n");
			zoomscript_caught = 0;
			ignore_minus_zoom += 1;
		}
	}

	ColorTranslateMode = autocvar_cl_stripcolorcodes;
	activeweapon = getstati(STAT_SWITCHWEAPON);
	f = (serverflags & SERVERFLAG_TEAMPLAY);
	if(f != teamplay)
	{
		teamplay = f;
		HUD_InitScores();
	}

	if(last_weapon != activeweapon) {
		weapontime = time;
		last_weapon = activeweapon;

		e = get_weaponinfo(activeweapon);
		if(e.netname != "")
			localcmd(strcat("\ncl_hook_activeweapon ", e.netname), "\n");
		else
			localcmd("\ncl_hook_activeweapon none\n");
	}

	// ALWAYS Clear Current Scene First
	R_ClearScene();

	// FIXME engine bug? VF_SIZE and VF_MIN are not restored to sensible values by this
	R_SetView(VF_SIZE, vf_size);
	R_SetView(VF_MIN, vf_min);

	// Assign Standard Viewflags
	// Draw the World (and sky)
	R_SetView(VF_DRAWWORLD, 1);

	// Set the console size vars
	vid_conwidth = autocvar_vid_conwidth;
	vid_conheight = autocvar_vid_conheight;
	vid_pixelheight = autocvar_vid_pixelheight;

	R_SetView(VF_FOV, GetCurrentFov(fov));

	// Camera for demo playback
	if(camera_active)
	{
		if(autocvar_camera_enable)
			CSQC_Demo_Camera();
		else
		{
			cvar_set("chase_active", ftos(chase_active_backup));
			cvar_set("cl_demo_mousegrab", "0");
			camera_active = FALSE;
		}
	}
#ifdef CAMERATEST
	else if(autocvar_camera_enable)
#else
	else if(autocvar_camera_enable && isdemo())
#endif
	{
		// Enable required Darkplaces cvars
		chase_active_backup = autocvar_chase_active;
		cvar_set("chase_active", "2");
		cvar_set("cl_demo_mousegrab", "1");
		camera_active = TRUE;
		camera_mode = FALSE;
	}

	// Draw the Crosshair
	R_SetView(VF_DRAWCROSSHAIR, 0); //Make sure engine crosshairs are always hidden

	// Draw the Engine Status Bar (the default Quake HUD)
	R_SetView(VF_DRAWENGINEHUD, 0);

	// fetch this one only once per frame
	hud_showbinds = autocvar_hud_showbinds;
	hud_showbinds_limit = autocvar_hud_showbinds_limit;

	// Update the mouse position
	/*
	   mousepos_x = vid_conwidth;
	   mousepos_y = vid_conheight;
	   mousepos = mousepos*0.5 + getmousepos();
	 */

	e = self;
	for(self = world; (self = nextent(self)); )
		if(self.draw)
			self.draw();
	self = e;

	R_AddEntities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	R_RenderScene();

	// now switch to 2D drawing mode by calling a 2D drawing function
	// then polygon drawing will draw as 2D stuff, and NOT get queued until the
	// next R_RenderScene call
	drawstring('0 0 0', "", '1 1 0', '1 1 1', 0, 0);

	if(autocvar_r_fakelight >= 2 || autocvar_r_fullbright >= 1)
	if not(serverflags & SERVERFLAG_ALLOW_FULLBRIGHT)
	{
		// apply night vision effect
		vector rgb, tc_00, tc_01, tc_10, tc_11;

		if(!nightvision_noise)
		{
			nightvision_noise = spawn();
			nightvision_noise.classname = "nightvision_noise";
		}
		if(!nightvision_noise2)
		{
			nightvision_noise2 = spawn();
			nightvision_noise2.classname = "nightvision_noise2";
		}

		// color tint in yellow
		drawfill('0 0 0', autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', '0.5 1 0.3', 1, DRAWFLAG_MODULATE);

		// draw BG
		a = Noise_Pink(nightvision_noise, frametime * 1.5) * 0.05 + 0.15;
		rgb = '1 1 1';
		tc_00 = '0 0 0' + '0.2 0 0' * sin(time * 0.3) + '0 0.3 0' * cos(time * 0.7);
		tc_01 = '0 2.25 0' + '0.6 0 0' * cos(time * 1.2) - '0 0.3 0' * sin(time * 2.2);
		tc_10 = '1.5 0 0' - '0.2 0 0' * sin(time * 0.5) + '0 0.5 0' * cos(time * 1.7);
		//tc_11 = '1 1 0' + '0.6 0 0' * sin(time * 0.6) + '0 0.3 0' * cos(time * 0.1);
		tc_11 = tc_01 + tc_10 - tc_00;
		R_BeginPolygon("gfx/nightvision-bg.tga", DRAWFLAG_ADDITIVE);
		R_PolygonVertex('0 0 0', tc_00, rgb, a);
		R_PolygonVertex(autocvar_vid_conwidth * '1 0 0', tc_10, rgb, a);
		R_PolygonVertex(autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', tc_11, rgb, a);
		R_PolygonVertex(autocvar_vid_conheight * '0 1 0', tc_01, rgb, a);
		R_EndPolygon();

		// draw FG
		a = Noise_Pink(nightvision_noise2, frametime * 0.1) * 0.05 + 0.12;
		rgb = '0.3 0.6 0.4' + '0.1 0.4 0.2' * Noise_White(nightvision_noise2, frametime);
		tc_00 = '0 0 0' + '1 0 0' * Noise_White(nightvision_noise2, frametime) + '0 1 0' * Noise_White(nightvision_noise2, frametime);
		tc_01 = tc_00 + '0 3 0' * (1 + Noise_White(nightvision_noise2, frametime) * 0.2);
		tc_10 = tc_00 + '2 0 0' * (1 + Noise_White(nightvision_noise2, frametime) * 0.3);
		tc_11 = tc_01 + tc_10 - tc_00;
		R_BeginPolygon("gfx/nightvision-fg.tga", DRAWFLAG_ADDITIVE);
		R_PolygonVertex('0 0 0', tc_00, rgb, a);
		R_PolygonVertex(autocvar_vid_conwidth * '1 0 0', tc_10, rgb, a);
		R_PolygonVertex(autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', tc_11, rgb, a);
		R_PolygonVertex(autocvar_vid_conheight * '0 1 0', tc_01, rgb, a);
		R_EndPolygon();
	}

	// Draw the aiming reticle for weapons that use it
	// reticle_type is changed to the item we are zooming / aiming with, to decide which reticle to use
	// It must be a persisted float for fading out to work properly (you let go of the zoom button for
	// the view to go back to normal, so reticle_type would become 0 as we fade out)
	if(spectatee_status || getstati(STAT_HEALTH) <= 0)
		reticle_type = 0; // prevent reticle from showing during the respawn zoom effect or for spectators
	else if(activeweapon == WEP_NEX && (button_zoom || zoomscript_caught) || activeweapon == WEP_CAMPINGRIFLE && (button_zoom || zoomscript_caught) || activeweapon == WEP_MINSTANEX && (button_zoom || zoomscript_caught))
		reticle_type = 2; // nex zoom
	else if(button_zoom || zoomscript_caught)
		reticle_type = 1; // normal zoom
	else if(activeweapon == WEP_NEX && button_attack2 || activeweapon == WEP_CAMPINGRIFLE && button_attack2)
		reticle_type = 2; // nex zoom

	if(autocvar_cl_reticle_stretch)
	{
		reticle_size_x = vid_conwidth;
		reticle_size_y = vid_conheight;
		reticle_pos_x = 0;
		reticle_pos_y = 0;
	}
	else
	{
		reticle_size_x = max(vid_conwidth, vid_conheight);
		reticle_size_y = max(vid_conwidth, vid_conheight);
		reticle_pos_x = (vid_conwidth - reticle_size_x) / 2;
		reticle_pos_y = (vid_conheight - reticle_size_y) / 2;
	}

	f = current_zoomfraction;
	if(zoomscript_caught)
		f = 1;
	if(autocvar_cl_reticle_item_normal)
	{
		precache_pic("gfx/reticle_normal");
		if(reticle_type == 1 && f)
			drawpic(reticle_pos, "gfx/reticle_normal", reticle_size, '1 1 1', f * autocvar_cl_reticle_item_normal, DRAWFLAG_NORMAL);
	}
	if(autocvar_cl_reticle_item_nex)
	{
		precache_pic("gfx/reticle_nex");
		if(reticle_type == 2 && f)
			drawpic(reticle_pos, "gfx/reticle_nex", reticle_size, '1 1 1', f * autocvar_cl_reticle_item_nex, DRAWFLAG_NORMAL);
	}

	// improved polyblend
	vector rgb;
	if(autocvar_hud_damage)
	{
		float myhealth_flash_temp;
		myhealth = getstati(STAT_HEALTH);

		// fade out
		myhealth_flash = max(0, myhealth_flash - autocvar_hud_damage_fade_rate * frametime);
		// add new damage
		myhealth_flash = bound(0, myhealth_flash + max(0, myhealth_prev - myhealth) * autocvar_hud_damage_factor, autocvar_hud_damage_maxalpha);

		float pain_threshold, pain_threshold_lower, pain_threshold_lower_health;
		pain_threshold = autocvar_hud_damage_pain_threshold;
		pain_threshold_lower = autocvar_hud_damage_pain_threshold_lower;
		pain_threshold_lower_health = autocvar_hud_damage_pain_threshold_lower_health;

		if(pain_threshold_lower && myhealth < pain_threshold_lower_health)
		{
			pain_threshold = pain_threshold - max(autocvar_hud_damage_pain_threshold_pulsating_min, fabs(sin(M_PI * time / autocvar_hud_damage_pain_threshold_pulsating_period))) * pain_threshold_lower * (1 - max(0, myhealth)/pain_threshold_lower_health);
		}

		myhealth_flash_temp = bound(0, myhealth_flash - pain_threshold, 1);

		if(myhealth_prev < 1)
		{
			if(myhealth >= 1)
			{
				myhealth_flash = 0; // just spawned, clear the flash immediately
				myhealth_flash_temp = 0;
			}
			else
			{
				myhealth_flash += autocvar_hud_damage_fade_rate * frametime; // dead
			}
		}

		if(spectatee_status == -1 || intermission)
		{
			myhealth_flash = 0; // observing, or match ended
			myhealth_flash_temp = 0;
		}

		myhealth_prev = myhealth;

		if(autocvar_cl_gentle_damage || autocvar_cl_gentle)
		{
			if(autocvar_cl_gentle_damage == 2)
			{
				if(myhealth_flash < pain_threshold) // only randomize when the flash is gone
				{
					myhealth_gentlergb = eX * random() + eY * random() + eZ * random();
				}
			}
			else
				myhealth_gentlergb = stov(autocvar_hud_damage_gentle_color);

			drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, myhealth_gentlergb, autocvar_hud_damage_gentle_alpha_multiplier * bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage, DRAWFLAG_NORMAL);
		}
		else
			drawpic(reticle_pos, "gfx/blood", reticle_size, stov(autocvar_hud_damage_color), bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage, DRAWFLAG_NORMAL);
	}

	// Draw the mouse cursor
	// NOTE: drawpic must happen after R_RenderScene for some reason
	//drawpic(getmousepos(), "gfx/cursor.tga", '11 14 0', '1 1 1', 1, 0);
	//drawstring('50 50', ftos(game), '10 10 0', '1 1 1', 1, 0);
	//self = edict_num(player_localnum);
	//drawstring('0 0', vtos(pmove_org), '8 8 0', '1 1 1', 1, 0);
	//drawstring('0 8', strcat("ORG: ", vtos(self.origin), " state: ", ftos(self.ctf_state), " HP: ", ftos(self.health)), '8 8 0', '1 1 1', 1, 0);
	// as long as the ctf part isn't in, this is useless
	if(menu_visible)
		menu_show();

	/*if(gametype == GAME_CTF)
	  {
	  ctf_view();
	  } else */

	// draw 2D entities
	e = self;
	for(self = world; (self = nextent(self)); )
		if(self.draw2d)
			self.draw2d();
	self = e;

	scoreboard_active = HUD_WouldDrawScoreboard();

	float hud;
	hud = getstati(STAT_HUD);
	if(hud == HUD_SPIDERBOT)
		CSQC_SPIDER_HUD();
	else if(hud == HUD_WAKIZASHI)
        CSQC_WAKIZASHI_HUD();
    else if(hud == HUD_RAPTOR)
        CSQC_RAPTOR_HUD();
	else
	{
		if(gametype == GAME_FREEZETAG)
		{
			if(getstati(STAT_FROZEN))
				drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
			if(getstatf(STAT_REVIVE_PROGRESS))
			{
				DrawCircleClippedPic(eX * 0.5 * vid_conwidth + eY * 0.6 * vid_conheight, 0.1 * vid_conheight, "gfx/crosshair_ring.tga", getstatf(STAT_REVIVE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
				drawstring_aspect(eY * 0.64 * vid_conheight, "Revival progress", eX * vid_conwidth + eY * 0.025 * vid_conheight, '1 1 1', 1, DRAWFLAG_NORMAL);
			}
		}

		if(autocvar_r_letterbox == 0)
			if(autocvar_viewsize < 120)
				CSQC_common_hud();

		// crosshair goes VERY LAST
		if(!scoreboard_active && !camera_active && intermission != 2) {
			string wcross_style;
			float wcross_alpha, wcross_resolution;
			wcross_style = autocvar_crosshair;
			if (wcross_style == "0")
				return;
			wcross_resolution = autocvar_crosshair_size;
			if (wcross_resolution == 0)
				return;
			wcross_alpha = autocvar_crosshair_alpha;
			if (wcross_alpha == 0)
				return;

			// TrueAim check
			float shottype;
			float bullets, ring_scale;
			// wcross_origin = '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight;
			wcross_origin = project_3d_to_2d(view_origin + MAX_SHOT_DISTANCE * view_forward);
			wcross_origin_z = 0;
			if(autocvar_crosshair_hittest)
			{
				vector wcross_oldorigin;
				wcross_oldorigin = wcross_origin;
				shottype = TrueAimCheck();
				if(shottype == SHOTTYPE_HITWORLD)
				{
					v = wcross_origin - wcross_oldorigin;
					v_x /= vid_conwidth;
					v_y /= vid_conheight;
					if(vlen(v) > 0.01)
						shottype = SHOTTYPE_HITOBSTRUCTION;
				}
				if(!autocvar_crosshair_hittest_showimpact)
					wcross_origin = wcross_oldorigin;
			}
			else
				shottype = SHOTTYPE_HITWORLD;

			vector wcross_color, wcross_size;
			string wcross_wep, wcross_name;
			float wcross_scale, wcross_blur;

			if (autocvar_crosshair_per_weapon || autocvar_crosshair_color_per_weapon) {
				e = get_weaponinfo(activeweapon);
				if (e && e.netname != "")
				{
					wcross_wep = e.netname;
					if(autocvar_crosshair_per_weapon)
					{
						wcross_resolution *= cvar(strcat("crosshair_", wcross_wep, "_size"));
						if (wcross_resolution == 0)
							return;
						wcross_alpha *= cvar(strcat("crosshair_", wcross_wep, "_alpha"));
						if (wcross_alpha == 0)
							return;

						wcross_style = cvar_string(strcat("crosshair_", wcross_wep));
						if(wcross_style == "" || wcross_style == "0")
							wcross_style = wcross_wep;
					}
				}
			}
			if(wcross_wep != "" && autocvar_crosshair_color_per_weapon)
				wcross_color = stov(cvar_string(strcat("crosshair_", wcross_wep, "_color")));
			else
				wcross_color = stov(autocvar_crosshair_color);

			wcross_name = strcat("gfx/crosshair", wcross_style);

			if(autocvar_crosshair_effect_scalefade)
			{
				wcross_scale = wcross_resolution;
				wcross_resolution = 1;
			}
			else
			{
				wcross_scale = 1;
			}

			if(autocvar_crosshair_pickup)
			{
				if(pickup_crosshair_time < getstatf(STAT_LAST_PICKUP))
				{
					pickup_crosshair_size = 1;
					pickup_crosshair_time = getstatf(STAT_LAST_PICKUP);
				}

				if(pickup_crosshair_size > 0)
					pickup_crosshair_size -= autocvar_crosshair_pickup_speed * frametime;
				else
					pickup_crosshair_size = 0;

				wcross_scale += sin(pickup_crosshair_size) * autocvar_crosshair_pickup;
			}

			if(shottype == SHOTTYPE_HITENEMY)
				wcross_scale *= autocvar_crosshair_hittest; // is not queried if hittest is 0
			if(shottype == SHOTTYPE_HITTEAM)
				wcross_scale /= autocvar_crosshair_hittest; // is not queried if hittest is 0

			f = autocvar_crosshair_effect_speed;
			if(f < 0)
				f *= -2 * g_weaponswitchdelay;
			if(wcross_scale != wcross_scale_goal_prev || wcross_alpha != wcross_alpha_goal_prev || wcross_color != wcross_color_goal_prev)
			{
				wcross_changedonetime = time + f;
			}
			if(wcross_name != wcross_name_goal_prev || wcross_resolution != wcross_resolution_goal_prev)
			{
				wcross_name_changestarttime = time;
				wcross_name_changedonetime = time + f;
				if(wcross_name_goal_prev_prev)
					strunzone(wcross_name_goal_prev_prev);
				wcross_name_goal_prev_prev = wcross_name_goal_prev;
				wcross_name_goal_prev = strzone(wcross_name);
				wcross_name_alpha_goal_prev_prev = wcross_name_alpha_goal_prev;
				wcross_resolution_goal_prev_prev = wcross_resolution_goal_prev;
				wcross_resolution_goal_prev = wcross_resolution;
			}

			wcross_scale_goal_prev = wcross_scale;
			wcross_alpha_goal_prev = wcross_alpha;
			wcross_color_goal_prev = wcross_color;

			if(shottype == SHOTTYPE_HITTEAM || (shottype == SHOTTYPE_HITOBSTRUCTION && autocvar_crosshair_hittest_blur && !autocvar_chase_active))
			{
				wcross_blur = 1;
				wcross_alpha *= 0.75;
			}
			else
				wcross_blur = 0;
			// *_prev is at time-frametime
			// * is at wcross_changedonetime+f
			// what do we have at time?
			if(time < wcross_changedonetime)
			{
				f = frametime / (wcross_changedonetime - time + frametime);
				wcross_scale = f * wcross_scale + (1 - f) * wcross_scale_prev;
				wcross_alpha = f * wcross_alpha + (1 - f) * wcross_alpha_prev;
				wcross_color = f * wcross_color + (1 - f) * wcross_color_prev;
			}

			wcross_scale_prev = wcross_scale;
			wcross_alpha_prev = wcross_alpha;
			wcross_color_prev = wcross_color;

			wcross_scale *= 1 - autocvar__menu_alpha;
			wcross_alpha *= 1 - autocvar__menu_alpha;

			ring_scale = autocvar_crosshair_ring_size;

			wcross_size = drawgetimagesize(wcross_name) * wcross_scale;

			float nex_charge, nex_chargepool;
			nex_charge = getstatf(STAT_NEX_CHARGE);
			nex_chargepool = getstatf(STAT_NEX_CHARGEPOOL);

			if(nex_charge_movingavg == 0) // this should only happen if we have just loaded up the game
				nex_charge_movingavg = nex_charge;

			// ring around crosshair representing bullets left in camping rifle clip
			if (activeweapon == WEP_CAMPINGRIFLE && cr_maxbullets)
			{
				bullets = getstati(STAT_BULLETS_LOADED);
				f = bound(0, bullets / cr_maxbullets, 1);

				a = autocvar_crosshair_ring_campingrifle_alpha;
				DrawCircleClippedPic(wcross_origin, wcross_size_x * ring_scale, "gfx/crosshair_ring.tga", f, wcross_color, wcross_alpha * a, DRAWFLAG_ADDITIVE);
			}
			else if (activeweapon == WEP_NEX && nex_charge) // ring around crosshair representing velocity-dependent damage for the nex
			{
				if(nex_chargepool || use_nex_chargepool)
				{
					use_nex_chargepool = 1;

					a = autocvar_crosshair_ring_nex_inner_alpha;
					rgb = eX * autocvar_crosshair_ring_nex_inner_color_red + eY * autocvar_crosshair_ring_nex_inner_color_green + eZ * autocvar_crosshair_ring_nex_inner_color_blue;
					DrawCircleClippedPic(wcross_origin, wcross_size_x * ring_scale, "gfx/crosshair_ring_inner.tga", nex_chargepool, rgb, wcross_alpha * a, DRAWFLAG_ADDITIVE);
				}
				else
				{
					// indicate how much we're charging right now with an inner circle
					a = autocvar_crosshair_ring_nex_inner_alpha;
					nex_charge_movingavg = (1 - autocvar_crosshair_ring_nex_currentcharge_movingavg_rate) * nex_charge_movingavg + autocvar_crosshair_ring_nex_currentcharge_movingavg_rate * nex_charge;

					rgb = eX * autocvar_crosshair_ring_nex_inner_color_red + eY * autocvar_crosshair_ring_nex_inner_color_green + eZ * autocvar_crosshair_ring_nex_inner_color_blue;
					DrawCircleClippedPic(wcross_origin, wcross_size_x * ring_scale, "gfx/crosshair_ring_inner.tga", bound(0, autocvar_crosshair_ring_nex_currentcharge_scale * (nex_charge - nex_charge_movingavg), 1), rgb, wcross_alpha * a, DRAWFLAG_ADDITIVE);
				}

				// draw the charge
				a = autocvar_crosshair_ring_nex_outer_alpha;
				DrawCircleClippedPic(wcross_origin, wcross_size_x * ring_scale, "gfx/crosshair_ring.tga", nex_charge, wcross_color, wcross_alpha * a, DRAWFLAG_ADDITIVE);
			}

#define CROSSHAIR_DO_BLUR(M,sz,wcross_name,wcross_alpha) \
			do \
			{ \
				if(wcross_blur > 0) \
				{ \
					for(i = -2; i <= 2; ++i) \
						for(j = -2; j <= 2; ++j) \
							M(i,j,sz,wcross_name,wcross_alpha*0.04); \
				} \
				else \
				{ \
					M(0,0,sz,wcross_name,wcross_alpha); \
				} \
			} \
			while(0)

#define CROSSHAIR_DRAW_SINGLE(i,j,sz,wcross_name,wcross_alpha) \
			drawpic(wcross_origin - ('0.5 0 0' * (sz * wcross_size_x + i * wcross_blur) + '0 0.5 0' * (sz * wcross_size_y + j * wcross_blur)), wcross_name, sz * wcross_size, wcross_color, wcross_alpha, DRAWFLAG_NORMAL)

#define CROSSHAIR_DRAW(sz,wcross_name,wcross_alpha) \
			CROSSHAIR_DO_BLUR(CROSSHAIR_DRAW_SINGLE,sz,wcross_name,wcross_alpha)

			if(time < wcross_name_changedonetime && wcross_name != wcross_name_goal_prev_prev && wcross_name_goal_prev_prev)
			{
				f = (wcross_name_changedonetime - time) / (wcross_name_changedonetime - wcross_name_changestarttime);
				wcross_size = drawgetimagesize(wcross_name_goal_prev_prev) * wcross_scale;
				CROSSHAIR_DRAW(wcross_resolution_goal_prev_prev, wcross_name_goal_prev_prev, wcross_alpha * f * wcross_name_alpha_goal_prev_prev);
				f = 1 - f;
			}
			else
			{
				f = 1;
			}

			wcross_size = drawgetimagesize(wcross_name) * wcross_scale;
			CROSSHAIR_DRAW(wcross_resolution, wcross_name, wcross_alpha * f);

			if(autocvar_crosshair_dot)
            {
                vector wcross_color_old;
                wcross_color_old = wcross_color;
                if(autocvar_crosshair_dot_color != "0")
                    wcross_color = stov(autocvar_crosshair_dot_color);
				CROSSHAIR_DRAW(wcross_resolution * autocvar_crosshair_dot_size, "gfx/crosshairdot.tga", f * autocvar_crosshair_dot_alpha);
                wcross_color = wcross_color_old;
            }

			wcross_name_alpha_goal_prev = f;
		}
		else
		{
			wcross_scale_prev = 0;
			wcross_alpha_prev = 0;
			wcross_scale_goal_prev = 0;
			wcross_alpha_goal_prev = 0;
			wcross_changedonetime = 0;
			if(wcross_name_goal_prev)
				strunzone(wcross_name_goal_prev);
			wcross_name_goal_prev = string_null;
			if(wcross_name_goal_prev_prev)
				strunzone(wcross_name_goal_prev_prev);
			wcross_name_goal_prev_prev = string_null;
			wcross_name_changestarttime = 0;
			wcross_name_changedonetime = 0;
			wcross_name_alpha_goal_prev = 0;
			wcross_name_alpha_goal_prev_prev = 0;
			wcross_resolution_goal_prev = 0;
			wcross_resolution_goal_prev_prev = 0;
		}
	}

	if(NextFrameCommand)
	{
		localcmd("\n", NextFrameCommand, "\n");
		NextFrameCommand = string_null;
	}

	// we must do this check AFTER a frame was rendered, or it won't work
	if(cs_project_is_b0rked == 0)
	{
		string w0, h0;
		w0 = ftos(autocvar_vid_conwidth);
		h0 = ftos(autocvar_vid_conheight);
		//R_SetView(VF_VIEWPORT, '0 0 0', '640 480 0');
		//R_SetView(VF_FOV, '90 90 0');
		R_SetView(VF_ORIGIN, '0 0 0');
		R_SetView(VF_ANGLES, '0 0 0');
		R_SetView(VF_PERSPECTIVE, 1);
		makevectors('0 0 0');
		vector v1, v2;
		cvar_set("vid_conwidth", "800");
		cvar_set("vid_conheight", "600");
		v1 = cs_project(v_forward);
		cvar_set("vid_conwidth", "640");
		cvar_set("vid_conheight", "480");
		v2 = cs_project(v_forward);
		if(v1 == v2)
			cs_project_is_b0rked = 1;
		else
			cs_project_is_b0rked = -1;
		cvar_set("vid_conwidth", w0);
		cvar_set("vid_conheight", h0);
	}

	if(autocvar__hud_configure)
		HUD_Panel_Mouse();

	// let's reset the view back to normal for the end
	R_SetView(VF_MIN, '0 0 0');
	R_SetView(VF_SIZE, '1 0 0' * w + '0 1 0' * h);
}

#define spider_h "gfx/vehicles/hud_bg.tga"
#define spider_b "gfx/vehicles/sbot.tga"
#define spider_r "gfx/vehicles/sbot_rpods.tga"
#define spider_g "gfx/vehicles/sbot_mguns.tga"
#define spider_s "gfx/vehicles/shiled.tga"
#define spider_a1 "gfx/hud/sb_rocket.tga"
#define spider_a2 "gfx/sb_bullets.tga"

void CSQC_SPIDER_HUD()
{
	float rockets, reload, heat, hp, shield;
	vector picsize, hudloc;

    // Fetch health & ammo stats
    hp      = bound(0,getstatf(STAT_VEHICLESTAT_HEALTH), 1);
	shield  = bound(0,getstatf(STAT_VEHICLESTAT_SHIELD), 1);
	heat    = min(getstatf(STAT_VEHICLESTAT_RELOAD1), 2);
	rockets =     getstati(STAT_VEHICLESTAT_AMMO2);
	reload  = min(getstatf(STAT_VEHICLESTAT_RELOAD2), 1);

    // Draw the crosshairs
    picsize = drawgetimagesize(SPIDER_CROSS);
    picsize_x *= autocvar_cl_vehicle_spiderbot_cross_size;
    picsize_y *= autocvar_cl_vehicle_spiderbot_cross_size;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), SPIDER_CROSS, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_NORMAL);

    hudloc_y =  4;
    hudloc_x = 4;

    picsize = drawgetimagesize(spider_h) * 0.5;
    drawpic(hudloc, spider_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a2) * 0.5;
    drawpic(hudloc + '120 96  0', spider_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '145 19  0', strcat(ftos(rint(hp * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '136 102  0', strcat(ftos(100 - rint(heat * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a1) * 0.85;
    if(rockets == 9)
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69 0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(9 - rockets), "/8"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(spider_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, spider_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_b, picsize, '0 1 0' * hp + '1 0 0' * (1 - hp), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_r, picsize, '1 1 1' * reload + '1 0 0' * (1 - reload), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_g, picsize, '1 1 1' * (1 - heat) + '1 0 0' *  heat, 1, DRAWFLAG_NORMAL);


	/*
	// Draw health bar
	p = '0.5 0 0' * (vid_conwidth - (rkt_size * 8));
	p = p + '0 1 0' * vid_conheight - '0 32 0';
	//pp = ('0 1 0' * hp) + ('1 0 0' * (1-hp));
	drawfill(p, '256 0 0' * shield + '0 8 0' , '0.5 0.5 1', 0.75, DRAWFLAG_NORMAL);
	p_y += 8;
	drawfill(p, '256 0 0' * hp + '0 8 0' , '0 1 0', 0.75, DRAWFLAG_NORMAL);
	p_x += 256 * hp;
	drawfill(p, '256 0 0' * (1-hp) + '0 8 0' , '0 0 0', 0.75, DRAWFLAG_NORMAL);

	// Draw minigun heat indicator
	p = '0.5 0 0' * (vid_conwidth - 256);
	p = p + '0 1 0' * vid_conheight - '0 34  0';
	drawfill(p, '256 0 0' * (1-heat) + '0 2 0' ,'0 0 1', 0.5, DRAWFLAG_NORMAL);
	p_x += 256 * (1-heat);
	drawfill(p, '256 0 0' * heat  + '0 2 0' , '1 0 0', 0.5, DRAWFLAG_NORMAL);


	// Draw rocket icons for loaded/empty tubes.
	pp = '0.5 0 0' * (vid_conwidth - (rkt_size * 8));
	pp += '0 1 0' * vid_conheight - '0 64 0';
	for(i = 0; i < 8; ++i)
	{
		p = pp + '1 0 0' * (rkt_size * i);
		if(rockets == 8)
		{
			if(floor(reload * 8) == i)
			{
				drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 0 0' + '0 1 0' * ((reload*8)-i), 0.75 , DRAWFLAG_NORMAL);
			}
			else if(i < reload * 8)
				drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '1 1 0', 0.75 , DRAWFLAG_NORMAL);
			else
				drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0.5 0.5 0.5', 0.75, DRAWFLAG_NORMAL);
		}
		else
		{
			if(i < rockets)
				drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 0 0', 0.25, DRAWFLAG_NORMAL);
			else
				drawpic(p, spider_rocket_icon, '1 1 0' * rkt_size, '0 1 0' * reload, 0.75, DRAWFLAG_NORMAL);
		}
	}
	*/

	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}

#define raptor_h "gfx/vehicles/hud_bg.tga"
#define raptor_b "gfx/vehicles/raptor.tga"
#define raptor_g1 "gfx/vehicles/raptor_guns.tga"
#define raptor_g2 "gfx/vehicles/raptor_bombs.tga"
#define raptor_s "gfx/vehicles/shiled.tga"

void CSQC_RAPTOR_HUD()
{
	float reload, hp, shield, energy;
	vector picsize, hudloc;

    // Fetch health & ammo stats
    hp      = bound(0,getstatf(STAT_VEHICLESTAT_HEALTH), 1);
	shield  = bound(0,getstatf(STAT_VEHICLESTAT_SHIELD), 1);
	reload  = min(getstatf(STAT_VEHICLESTAT_RELOAD1), 1);
	energy  = min(getstatf(STAT_VEHICLESTAT_ENERGY),  1);

    // Draw the crosshairs
    picsize = drawgetimagesize(SPIDER_CROSS);
    picsize_x *= autocvar_cl_vehicle_spiderbot_cross_size;
    picsize_y *= autocvar_cl_vehicle_spiderbot_cross_size;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), SPIDER_CROSS, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_NORMAL);

    hudloc_y =  4;
    hudloc_x = 4;

    picsize = drawgetimagesize(raptor_h) * 0.5;
    drawpic(hudloc, raptor_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a2) * 0.5;
    drawpic(hudloc + '120 96  0', spider_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '145 19  0', strcat(ftos(rint(hp * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '136 102 0', strcat(ftos(rint(energy * 100)), "%"),'15 15 0','0.5 0.5 1', 1, DRAWFLAG_NORMAL);


    picsize = drawgetimagesize(spider_a1) * 0.85;
    if(reload == 1)
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','0 1 0', 0.5, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','0 0 1', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(raptor_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, raptor_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_b, picsize, '0 1 0' * hp + '1 0 0' * (1 - hp), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_g1, picsize, '1 1 1' * energy + '1 0 0' * (1 - energy), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_g2, picsize, '1 1 1' * reload + '1 0 0' *  (1 - reload), 1, DRAWFLAG_NORMAL);


	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}

#define waki_h "gfx/vehicles/hud_bg.tga"
#define waki_b "gfx/vehicles/waki.tga"
#define waki_e "gfx/vehicles/waki_e.tga"
#define waki_g "gfx/vehicles/waki_guns.tga"
#define waki_r "gfx/vehicles/waki_rockets.tga"
#define waki_s "gfx/vehicles/shiled.tga"

#define waki_a1 "gfx/hud/sb_rocket.tga"
#define waki_a2 "gfx/sb_cells.tga"

void CSQC_WAKIZASHI_HUD()
{
	// 0--1 floats. 1 = 100%, 0.6 = 50%.
	float health, shield, energy, rockets;
	vector picsize, hudloc;

    picsize = drawgetimagesize(SPIDER_CROSS);
    picsize_x *= autocvar_cl_vehicle_spiderbot_cross_size;
    picsize_y *= autocvar_cl_vehicle_spiderbot_cross_size;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), SPIDER_CROSS, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_NORMAL);

/*
const float STAT_VEHICLESTAT_HEALTH  = 60;
const float STAT_VEHICLESTAT_SHIELD  = 61;
const float STAT_VEHICLESTAT_ENERGY  = 62;
const float STAT_VEHICLESTAT_AMMO1   = 63;
const float STAT_VEHICLESTAT_RELAOD1 = 64;
const float STAT_VEHICLESTAT_AMMO2   = 65;
const float STAT_VEHICLESTAT_RELOAD2 = 66;
*/
    health  = min(getstatf(STAT_VEHICLESTAT_HEALTH),  1);
	shield  = min(getstatf(STAT_VEHICLESTAT_SHIELD),  1);
	energy  = min(getstatf(STAT_VEHICLESTAT_ENERGY),  1);
	rockets = bound(0,getstatf(STAT_VEHICLESTAT_RELOAD1), 1);

    hudloc_y =  4;
    hudloc_x = 4;

    picsize = drawgetimagesize(waki_h) * 0.5;
    drawpic(hudloc, waki_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(waki_a2) * 0.7;
    drawpic(hudloc + '116 92  0', waki_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);


    drawstring(hudloc + '145 19  0', strcat(ftos(rint(health * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '136 102  0', strcat(ftos(rint(energy * 100)), "%"),'14 14 0','1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(waki_a1) * 0.75;
    if(rockets == 1)
    {
        drawpic(hudloc + '140 55  0', waki_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawpic(hudloc + '144 59  0', waki_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '140 55  0', waki_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawpic(hudloc + '144 59  0', waki_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '165 69 0', strcat(ftos(rint(rockets * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(waki_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, waki_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_b, picsize, '0 1 0' * health + '1 0 0' * (1 - health), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_r, picsize, '1 1 1' * rockets + '1 0 0' * (1 - rockets), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_e, picsize, '1 1 1' * energy + '1 0 0' *  (1 - energy), 1, DRAWFLAG_NORMAL);



	/*
	p = '0.5 0 0' * (vid_conwidth - (rkt_size * 8));
	p = p + '0 1 0' * vid_conheight - '0 32 0';

	// Draw health bar
	p_y += 8;
	drawfill(p, '256 0 0' * health + '0 8 0' , '0 0.7 0', 0.75, DRAWFLAG_NORMAL);
	p_x += 256 * health;
	drawfill(p, '256 0 0' * (1 - health) + '0 8 0' , '0 0 0', 0.75, DRAWFLAG_NORMAL);

	// Draw shiled bar
	p_x -= 256 * health;
	p_y += 4;
	drawfill(p, '256 0 0' * shield + '0 4 0' , '0.25 0.25 1', 0.5, DRAWFLAG_NORMAL);

	// Draw energy
	//p_x -= 256 * health;
	p_y -= 8;
	drawfill(p, '256 0 0' * energy + '0 4 0' , '1 1 1', 0.75, DRAWFLAG_NORMAL);

	// Draw rockets bar
	p_y += 12;
	drawfill(p, '256 0 0' * rockets + '0 4 0' , '1 0 0', 0.75, DRAWFLAG_NORMAL);
	*/




	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}


void CSQC_common_hud(void)
{
	// HUD_SortFrags(); done in HUD_Draw
	float hud;
	hud = getstati(STAT_HUD);

	//hud = 10;
	switch(hud)
	{
		case HUD_NORMAL:
			// do some accuracy var caching
			float i;
			if(!(gametype == GAME_RACE || gametype == GAME_CTS))
			{
				if(autocvar_accuracy_color_levels != acc_color_levels)
				{
					if(acc_color_levels)
						strunzone(acc_color_levels);
					acc_color_levels = strzone(autocvar_accuracy_color_levels);
					acc_levels = tokenize(acc_color_levels);
					if (acc_levels > MAX_ACCURACY_LEVELS)
						acc_levels = MAX_ACCURACY_LEVELS;

					for (i = 0; i < acc_levels; ++i)
						acc_lev[i] = stof(argv(i)) / 100.0;
				}
				// let know that acc_col[] needs to be loaded
				acc_col_x[0] = -1;
			}

			HUD_Main(); // always run these functions for alpha checks
			HUD_DrawScoreboard();

			if (scoreboard_active) // scoreboard/accuracy
			{	
				HUD_Reset();
				// HUD_DrawScoreboard takes care of centerprint_start
			}
			else if (intermission == 2) // map voting screen
			{
				HUD_FinaleOverlay();
				HUD_Reset();

				centerprint_start_x = 0;
				centerprint_start_y = autocvar_scr_centerpos * vid_conheight;
			}
			else // hud
			{
				centerprint_start_x = 0;
				centerprint_start_y = autocvar_scr_centerpos * vid_conheight;
			}

			HUD_DrawCenterPrint();
			break;

		case HUD_SPIDERBOT:
			CSQC_SPIDER_HUD();
			break;

		case HUD_WAKIZASHI:
			CSQC_WAKIZASHI_HUD();
			break;
	}
}


// following vectors must be global to allow seamless switching between camera modes
vector camera_offset, current_camera_offset, mouse_angles, current_angles, current_origin, current_position;
void CSQC_Demo_Camera()
{
	float speed, attenuation, dimensions;
	vector tmp, delta;

	if( autocvar_camera_reset || !camera_mode )
	{
		camera_offset = '0 0 0';
		current_angles = '0 0 0';
		camera_direction = '0 0 0';
		camera_offset_z += 30;
		camera_offset_x += 30 * -cos(current_angles_y * DEG2RAD);
		camera_offset_y += 30 * -sin(current_angles_y * DEG2RAD);
		current_origin = view_origin;
		current_camera_offset  = camera_offset;
		cvar_set("camera_reset", "0");
		camera_mode = CAMERA_CHASE;
	}

	// Camera angles
	if( camera_roll )
		mouse_angles_z += camera_roll * autocvar_camera_speed_roll;

	if(autocvar_camera_look_player)
	{
		local vector dir;
		local float n;

		dir = normalize(view_origin - current_position);
		n = mouse_angles_z;
		mouse_angles = vectoangles(dir);
		mouse_angles_x = mouse_angles_x * -1;
		mouse_angles_z = n;
	}
	else
	{
		tmp = getmousepos() * 0.1;
		if(vlen(tmp)>autocvar_camera_mouse_treshold)
		{
			mouse_angles_x += tmp_y * cos(mouse_angles_z * DEG2RAD) + (tmp_x * sin(mouse_angles_z * DEG2RAD));
			mouse_angles_y -= tmp_x * cos(mouse_angles_z * DEG2RAD) + (tmp_y * -sin(mouse_angles_z * DEG2RAD));
		}
	}

	while (mouse_angles_x < -180) mouse_angles_x = mouse_angles_x + 360;
	while (mouse_angles_x > 180) mouse_angles_x = mouse_angles_x - 360;
	while (mouse_angles_y < -180) mouse_angles_y = mouse_angles_y + 360;
	while (mouse_angles_y > 180) mouse_angles_y = mouse_angles_y - 360;

	// Fix difference when angles don't have the same sign
	delta = '0 0 0';
	if(mouse_angles_y < -60 && current_angles_y > 60)
		delta = '0 360 0';
	if(mouse_angles_y > 60 && current_angles_y < -60)
		delta = '0 -360 0';

	if(autocvar_camera_look_player)
		attenuation = autocvar_camera_look_attenuation;
	else
		attenuation = autocvar_camera_speed_attenuation;

	attenuation = 1 / max(1, attenuation);
	current_angles += (mouse_angles - current_angles + delta) * attenuation;

	while (current_angles_x < -180) current_angles_x = current_angles_x + 360;
	while (current_angles_x > 180) current_angles_x = current_angles_x - 360;
	while (current_angles_y < -180) current_angles_y = current_angles_y + 360;
	while (current_angles_y > 180) current_angles_y = current_angles_y - 360;

	// Camera position
	tmp = '0 0 0';
	dimensions = 0;

	if( camera_direction_x )
	{
		tmp_x = camera_direction_x * cos(current_angles_y * DEG2RAD);
		tmp_y = camera_direction_x * sin(current_angles_y * DEG2RAD);
		if( autocvar_camera_forward_follows && !autocvar_camera_look_player )
			tmp_z = camera_direction_x * -sin(current_angles_x * DEG2RAD);
		++dimensions;
	}

	if( camera_direction_y )
	{
		tmp_x += camera_direction_y * -sin(current_angles_y * DEG2RAD);
		tmp_y += camera_direction_y * cos(current_angles_y * DEG2RAD) * cos(current_angles_z * DEG2RAD);
		tmp_z += camera_direction_y * sin(current_angles_z * DEG2RAD);
		++dimensions;
	}

	if( camera_direction_z )
	{
		tmp_z += camera_direction_z * cos(current_angles_z * DEG2RAD);
		++dimensions;
	}

	if(autocvar_camera_free)
		speed = autocvar_camera_speed_free;
	else
		speed = autocvar_camera_speed_chase;

	if(dimensions)
	{
		speed = speed * sqrt(1 / dimensions);
		camera_offset += tmp * speed;
	}

	current_camera_offset += (camera_offset - current_camera_offset) * attenuation;

	// Camera modes
	if( autocvar_camera_free )
	{
		if ( camera_mode == CAMERA_CHASE )
		{
			current_camera_offset = current_origin + current_camera_offset;
			camera_offset = current_origin + camera_offset;
		}

		camera_mode = CAMERA_FREE;
		current_position = current_camera_offset;
	}
	else
	{
		if ( camera_mode == CAMERA_FREE )
		{
			current_origin = view_origin;
			camera_offset = camera_offset - current_origin;
			current_camera_offset = current_camera_offset - current_origin;
		}

		camera_mode = CAMERA_CHASE;

		if(autocvar_camera_chase_smoothly)
			current_origin += (view_origin - current_origin) * attenuation;
		else
			current_origin = view_origin;

		current_position = current_origin + current_camera_offset;
	}

	R_SetView(VF_ANGLES, current_angles);
	R_SetView(VF_ORIGIN, current_position);
}
