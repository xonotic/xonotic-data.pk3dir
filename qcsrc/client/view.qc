
#include "announcer.qh"
#include "hook.qh"
#include "hud/all.qh"
#include "mapvoting.qh"
#include "scoreboard.qh"
#include "shownames.qh"
#include "quickmenu.qh"

#include "mutators/events.qh"

#include "../common/anim.qh"
#include "../common/constants.qh"
#include "../common/debug.qh"
#include "../common/mapinfo.qh"
#include "../common/gamemodes/all.qh"
#include "../common/physics.qh"
#include "../common/stats.qh"
#include "../common/triggers/target/music.qh"
#include "../common/teams.qh"

#include "../common/vehicles/all.qh"
#include "../common/weapons/all.qh"
#include "../common/viewloc.qh"
#include "../common/minigames/cl_minigames.qh"
#include "../common/minigames/cl_minigames_hud.qh"

#include "../lib/csqcmodel/cl_player.qh"

#include "../lib/warpzone/client.qh"
#include "../lib/warpzone/common.qh"

#define EFMASK_CHEAP (EF_ADDITIVE | EF_DOUBLESIDED | EF_FULLBRIGHT | EF_NODEPTHTEST | EF_NODRAW | EF_NOSHADOW | EF_SELECTABLE | EF_TELEPORT_BIT)

float autocvar_cl_viewmodel_scale;

bool autocvar_cl_bobmodel;
float autocvar_cl_bobmodel_speed;
float autocvar_cl_bobmodel_side;
float autocvar_cl_bobmodel_up;

float autocvar_cl_followmodel;
float autocvar_cl_followmodel_side_speed;
float autocvar_cl_followmodel_side_highpass;
float autocvar_cl_followmodel_side_highpass1;
float autocvar_cl_followmodel_side_limit;
float autocvar_cl_followmodel_side_lowpass;
float autocvar_cl_followmodel_up_speed;
float autocvar_cl_followmodel_up_highpass;
float autocvar_cl_followmodel_up_highpass1;
float autocvar_cl_followmodel_up_limit;
float autocvar_cl_followmodel_up_lowpass;

float autocvar_cl_leanmodel;
float autocvar_cl_leanmodel_side_speed;
float autocvar_cl_leanmodel_side_highpass;
float autocvar_cl_leanmodel_side_highpass1;
float autocvar_cl_leanmodel_side_lowpass;
float autocvar_cl_leanmodel_side_limit;
float autocvar_cl_leanmodel_up_speed;
float autocvar_cl_leanmodel_up_highpass;
float autocvar_cl_leanmodel_up_highpass1;
float autocvar_cl_leanmodel_up_lowpass;
float autocvar_cl_leanmodel_up_limit;

#define lowpass(value, frac, ref_store, ret) MACRO_BEGIN \
{ \
	float __frac = bound(0, frac, 1); \
	ret = ref_store = ref_store * (1 - __frac) + (value) * __frac; \
} MACRO_END

#define lowpass_limited(value, frac, limit, ref_store, ret) MACRO_BEGIN \
{ \
	float __ignore; lowpass(value, frac, ref_store, __ignore); \
	ret = ref_store = bound((value) - (limit), ref_store, (value) + (limit)); \
} MACRO_END

#define highpass(value, frac, ref_store, ret) MACRO_BEGIN \
{ \
	float __f = 0; lowpass(value, frac, ref_store, __f); \
	ret = (value) - __f; \
} MACRO_END

#define highpass_limited(value, frac, limit, ref_store, ret) MACRO_BEGIN \
{ \
	float __f = 0; lowpass_limited(value, frac, limit, ref_store, __f); \
	ret = (value) - __f; \
} MACRO_END

#define lowpass3(value, fracx, fracy, fracz, ref_store, ref_out) MACRO_BEGIN \
{ \
	lowpass(value.x, fracx, ref_store.x, ref_out.x); \
	lowpass(value.y, fracy, ref_store.y, ref_out.y); \
	lowpass(value.z, fracz, ref_store.z, ref_out.z); \
} MACRO_END

#define highpass3(value, fracx, fracy, fracz, ref_store, ref_out) MACRO_BEGIN \
{ \
	highpass(value.x, fracx, ref_store.x, ref_out.x); \
	highpass(value.y, fracy, ref_store.y, ref_out.y); \
	highpass(value.z, fracz, ref_store.z, ref_out.z); \
} MACRO_END

#define highpass3_limited(value, fracx, limitx, fracy, limity, fracz, limitz, ref_store, ref_out) MACRO_BEGIN \
{ \
	highpass_limited(value.x, fracx, limitx, ref_store.x, ref_out.x); \
	highpass_limited(value.y, fracy, limity, ref_store.y, ref_out.y); \
	highpass_limited(value.z, fracz, limitz, ref_store.z, ref_out.z); \
} MACRO_END

void viewmodel_animate(entity this)
{
	static float prevtime;
	float frametime = (time - prevtime) * STAT(MOVEVARS_TIMESCALE);
	prevtime = time;

	if (autocvar_chase_active) return;
	if (STAT(HEALTH) <= 0) return;

	entity view = CSQCModel_server2csqc(player_localentnum - 1);

	bool clonground = !(view.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
	static bool oldonground;
	static float hitgroundtime;
	static float lastongroundtime;
	if (clonground)
	{
		float f = time; // cl.movecmd[0].time
		if (!oldonground)
			hitgroundtime = f;
		lastongroundtime = f;
	}
	oldonground = clonground;

	vector gunorg = '0 0 0', gunangles = '0 0 0';
	static vector gunorg_prev = '0 0 0', gunangles_prev = '0 0 0';

	bool teleported = view.csqcmodel_teleported;

	// 1. if we teleported, clear the frametime... the lowpass will recover the previous value then
	if (teleported)
	{
		// try to fix the first highpass; result is NOT
		// perfect! TODO find a better fix
		gunangles_prev = view_angles;
		gunorg_prev = view_origin;
	}

	static vector gunorg_highpass = '0 0 0';

	// 2. for the gun origin, only keep the high frequency (non-DC) parts, which is "somewhat like velocity"
	gunorg_highpass += gunorg_prev;
	highpass3_limited(view_origin,
		frametime * autocvar_cl_followmodel_side_highpass1, autocvar_cl_followmodel_side_limit,
		frametime * autocvar_cl_followmodel_side_highpass1, autocvar_cl_followmodel_side_limit,
		frametime * autocvar_cl_followmodel_up_highpass1, autocvar_cl_followmodel_up_limit,
		gunorg_highpass, gunorg);
	gunorg_prev = view_origin;
	gunorg_highpass -= gunorg_prev;

	static vector gunangles_highpass = '0 0 0';

	// in the highpass, we _store_ the DIFFERENCE to the actual view angles...
	gunangles_highpass += gunangles_prev;
	PITCH(gunangles_highpass) += 360 * floor((PITCH(view_angles) - PITCH(gunangles_highpass)) / 360 + 0.5);
	YAW(gunangles_highpass) += 360 * floor((YAW(view_angles) - YAW(gunangles_highpass)) / 360 + 0.5);
	ROLL(gunangles_highpass) += 360 * floor((ROLL(view_angles) - ROLL(gunangles_highpass)) / 360 + 0.5);
	highpass3_limited(view_angles,
		frametime * autocvar_cl_leanmodel_up_highpass1, autocvar_cl_leanmodel_up_limit,
		frametime * autocvar_cl_leanmodel_side_highpass1, autocvar_cl_leanmodel_side_limit,
		0, 0,
		gunangles_highpass, gunangles);
	gunangles_prev = view_angles;
	gunangles_highpass -= gunangles_prev;

	// 3. calculate the RAW adjustment vectors
	gunorg.x *= (autocvar_cl_followmodel ? -autocvar_cl_followmodel_side_speed : 0);
	gunorg.y *= (autocvar_cl_followmodel ? -autocvar_cl_followmodel_side_speed : 0);
	gunorg.z *= (autocvar_cl_followmodel ? -autocvar_cl_followmodel_up_speed : 0);

	PITCH(gunangles) *= (autocvar_cl_leanmodel ? -autocvar_cl_leanmodel_up_speed : 0);
	YAW(gunangles) *= (autocvar_cl_leanmodel ? -autocvar_cl_leanmodel_side_speed : 0);
	ROLL(gunangles) = 0;

	static vector gunorg_adjustment_highpass;
	static vector gunorg_adjustment_lowpass;
	static vector gunangles_adjustment_highpass;
	static vector gunangles_adjustment_lowpass;

	// 4. perform highpass/lowpass on the adjustment vectors (turning velocity into acceleration!)
	//    trick: we must do the lowpass LAST, so the lowpass vector IS the final vector!
	highpass3(gunorg,
		frametime * autocvar_cl_followmodel_side_highpass,
		frametime * autocvar_cl_followmodel_side_highpass,
		frametime * autocvar_cl_followmodel_up_highpass,
		gunorg_adjustment_highpass, gunorg);
	lowpass3(gunorg,
		frametime * autocvar_cl_followmodel_side_lowpass,
		frametime * autocvar_cl_followmodel_side_lowpass,
		frametime * autocvar_cl_followmodel_up_lowpass,
		gunorg_adjustment_lowpass, gunorg);
	// we assume here: PITCH = 0, YAW = 1, ROLL = 2
	highpass3(gunangles,
		frametime * autocvar_cl_leanmodel_up_highpass,
		frametime * autocvar_cl_leanmodel_side_highpass,
		0,
		gunangles_adjustment_highpass, gunangles);
	lowpass3(gunangles,
		frametime * autocvar_cl_leanmodel_up_lowpass,
		frametime * autocvar_cl_leanmodel_side_lowpass,
		0,
		gunangles_adjustment_lowpass, gunangles);
	float xyspeed = bound(0, vlen(vec2(view.velocity)), 400);

	// vertical view bobbing code
	// TODO: cl_bob

	// horizontal view bobbing code
	// TODO: cl_bob2

	// fall bobbing code
	// causes the view to swing down and back up when touching the ground
	// TODO: cl_bobfall

	// gun model bobbing code
	if (autocvar_cl_bobmodel)
	{
		// calculate for swinging gun model
		// the gun bobs when running on the ground, but doesn't bob when you're in the air.
		// Sajt: I tried to smooth out the transitions between bob and no bob, which works
		// for the most part, but for some reason when you go through a message trigger or
		// pick up an item or anything like that it will momentarily jolt the gun.
		vector forward, right = '0 0 0', up = '0 0 0';
		float bspeed;
		float t = 1;
		float s = time * autocvar_cl_bobmodel_speed;
		if (clonground)
		{
			if (time - hitgroundtime < 0.2)
			{
				// just hit the ground, speed the bob back up over the next 0.2 seconds
				t = time - hitgroundtime;
				t = bound(0, t, 0.2);
				t *= 5;
			}
		}
		else
		{
			// recently left the ground, slow the bob down over the next 0.2 seconds
			t = time - lastongroundtime;
			t = 0.2 - bound(0, t, 0.2);
			t *= 5;
		}
		bspeed = xyspeed * 0.01;
		MAKEVECTORS(makevectors, view_angles, forward, right, up);
		float bobr = bspeed * autocvar_cl_bobmodel_side * autocvar_cl_viewmodel_scale * sin(s) * t;
		gunorg += bobr * right;
		float bobu = bspeed * autocvar_cl_bobmodel_up * autocvar_cl_viewmodel_scale * cos(s * 2) * t;
		gunorg += bobu * up;
	}
	vector v = rotate(gunorg, YAW(view_angles) * DEG2RAD); // rotate world coordinates to relative ones
	v.z = gunorg.z;
	this.origin += v;
	gunangles.x = -gunangles.x; // pitch was inverted, now that actually matters
	this.angles += gunangles;
}

.vector viewmodel_origin, viewmodel_angles;
.float weapon_nextthink;
.float weapon_eta_last;
.float weapon_switchdelay;

void viewmodel_draw(entity this)
{
	int mask = (intermission || (STAT(HEALTH) <= 0) || autocvar_chase_active) ? 0 : MASK_NORMAL;
	float a = this.alpha;
	static bool wasinvehicle;
	bool invehicle = player_localentnum > maxclients;
	if (invehicle) a = -1;
	else if (wasinvehicle) a = 1;
	wasinvehicle = invehicle;
	int c = stof(getplayerkeyvalue(current_player, "colors"));
	vector g;
	Weapon wep = activeweapon;
	if (!(g = wep.wr_glow(wep))) g = colormapPaletteColor(c & 0x0F, true) * 2;
	entity me = CSQCModel_server2csqc(player_localentnum - 1);
	int fx = ((me.csqcmodel_effects & EFMASK_CHEAP)
		| EF_NODEPTHTEST)
		&~ (EF_FULLBRIGHT); // can mask team color, so get rid of it
	for (entity e = this; e; e = e.weaponchild)
	{
		e.drawmask = mask;
		e.alpha = a;
		e.colormap = 256 + c;  // colormap == 0 is black, c == 0 is white
		e.glowmod = g;
		e.csqcmodel_effects = fx;
		WITH(entity, self, e, CSQCModel_Effects_Apply());
	}
	{
		static string name_last;
		string name = wep.mdl;
		if (name != name_last)
		{
			name_last = name;
			CL_WeaponEntity_SetModel(this, name);
			this.viewmodel_origin = this.origin;
			this.viewmodel_angles = this.angles;
		}
		anim_update(this);
		if (!this.animstate_override)
			anim_set(this, this.anim_idle, true, false, false);
	}
	float f = 0; // 0..1; 0: fully active
	float eta = (this.weapon_nextthink - time) / STAT(WEAPONRATEFACTOR);
	if (eta <= 0) f = this.weapon_eta_last;
	else switch (this.state)
	{
		case WS_RAISE:
		{
			f = eta / max(eta, this.weapon_switchdelay);
			break;
		}
		case WS_DROP:
		{
			f = 1 - eta / max(eta, this.weapon_switchdelay);
			break;
		}
		case WS_CLEAR:
		{
			f = 1;
			break;
		}
	}
	this.weapon_eta_last = f;
	this.origin = this.viewmodel_origin;
	this.angles = this.viewmodel_angles;
	this.angles_x = (-90 * f * f);
	viewmodel_animate(this);
	setorigin(this, this.origin);
}

entity viewmodel;
STATIC_INIT(viewmodel) {
    viewmodel = new(viewmodel);
    make_pure(viewmodel);
	viewmodel.draw = viewmodel_draw;
}

entity porto;
vector polyline[16];
void Porto_Draw(entity this)
{
	vector p, dir, ang, q, nextdir;
	float portal_number, portal1_idx;

	if(activeweapon != WEP_PORTO || spectatee_status || gametype == MAPINFO_TYPE_NEXBALL)
		return;
	if(WEP_CVAR(porto, secondary))
		return;
	if(intermission == 1)
		return;
	if(intermission == 2)
		return;
	if (STAT(HEALTH) <= 0)
		return;

	dir = view_forward;

	if(angles_held_status)
	{
		makevectors(angles_held);
		dir = v_forward;
	}

	p = view_origin;

	polyline[0] = p;
	int idx = 1;
	portal_number = 0;
	nextdir = dir;

	for (;;)
	{
		dir = nextdir;
		traceline(p, p + 65536 * dir, true, porto);
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
		ang.x = -ang.x;
		makevectors(ang);
		if(!CheckWireframeBox(porto, p - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
			return;
		if(portal_number == 1)
		{
			portal1_idx = idx;
			if(portal_number >= 2)
				break;
		}
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

void Porto_Init()
{
	porto = new(porto);
	make_pure(porto);
	porto.draw = Porto_Draw;
	porto.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

float drawtime;
float avgspeed;
vector GetCurrentFov(float fov)
{
	float zoomsensitivity, zoomspeed, zoomfactor, zoomdir;
	float velocityzoom, curspeed;
	vector v;

	zoomsensitivity = autocvar_cl_zoomsensitivity;
	zoomfactor = autocvar_cl_zoomfactor;
	if(zoomfactor < 1 || zoomfactor > 30)
		zoomfactor = 2.5;
	zoomspeed = autocvar_cl_zoomspeed;
	if(zoomspeed >= 0)
	if(zoomspeed < 0.5 || zoomspeed > 16)
			zoomspeed = 3.5;

	zoomdir = button_zoom;
	if(hud == HUD_NORMAL)
	if(switchweapon == activeweapon)
	if((activeweapon == WEP_VORTEX && !WEP_CVAR(vortex, secondary)) || (activeweapon == WEP_RIFLE && !WEP_CVAR(rifle, secondary))) // do NOT use switchweapon here
		zoomdir += button_attack2;
	if(spectatee_status > 0 || isdemo())
	{
		if(spectatorbutton_zoom)
		{
			if(zoomdir)
				zoomdir = 0;
			else
				zoomdir = 1;
		}
		// fteqcc failed twice here already, don't optimize this
	}

	if(zoomdir) { zoomin_effect = 0; }

	if(camera_active)
	{
		current_viewzoom = min(1, current_viewzoom + drawframetime);
	}
	else if(autocvar_cl_spawnzoom && zoomin_effect)
	{
		float spawnzoomfactor = bound(1, autocvar_cl_spawnzoom_factor, 30);

		current_viewzoom += (autocvar_cl_spawnzoom_speed * (spawnzoomfactor - current_viewzoom) * drawframetime);
		current_viewzoom = bound(1 / spawnzoomfactor, current_viewzoom, 1);
		if(current_viewzoom == 1) { zoomin_effect = 0; }
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

	if(autocvar_cl_velocityzoom_enabled && autocvar_cl_velocityzoom_type) // _type = 0 disables velocity zoom too
	{
		if(intermission) { curspeed = 0; }
		else
		{

			makevectors(view_angles);
			v = pmove_vel;
			if(csqcplayer)
				v = csqcplayer.velocity;

			switch(autocvar_cl_velocityzoom_type)
			{
				case 3: curspeed = max(0, v_forward * v); break;
				case 2: curspeed = (v_forward * v); break;
				case 1: default: curspeed = vlen(v); break;
			}
		}

		velocityzoom = bound(0, drawframetime / max(0.000000001, autocvar_cl_velocityzoom_time), 1); // speed at which the zoom adapts to player velocity
		avgspeed = avgspeed * (1 - velocityzoom) + (curspeed / autocvar_cl_velocityzoom_speed) * velocityzoom;
		velocityzoom = exp(float2range11(avgspeed * -autocvar_cl_velocityzoom_factor / 1) * 1);

		//print(ftos(avgspeed), " avgspeed, ", ftos(curspeed), " curspeed, ", ftos(velocityzoom), " return\n"); // for debugging
	}
	else
		velocityzoom = 1;

	float frustumx, frustumy, fovx, fovy;
	frustumy = tan(fov * M_PI / 360.0) * 0.75 * current_viewzoom * velocityzoom;
	frustumx = frustumy * vid_width / vid_height / vid_pixelheight;
	fovx = atan2(frustumx, 1) / M_PI * 360.0;
	fovy = atan2(frustumy, 1) / M_PI * 360.0;

	return '1 0 0' * fovx + '0 1 0' * fovy;
}

vector GetViewLocationFOV(float fov)
{
	float frustumy = tan(fov * M_PI / 360.0) * 0.75;
	float frustumx = frustumy * vid_width / vid_height / vid_pixelheight;
	float fovx = atan2(frustumx, 1) / M_PI * 360.0;
	float fovy = atan2(frustumy, 1) / M_PI * 360.0;
	return '1 0 0' * fovx + '0 1 0' * fovy;
}

vector GetOrthoviewFOV(vector ov_worldmin, vector ov_worldmax, vector ov_mid, vector ov_org)
{
	float fovx, fovy;
	float width = (ov_worldmax.x - ov_worldmin.x);
	float height = (ov_worldmax.y - ov_worldmin.y);
	float distance_to_middle_of_world = vlen(ov_mid - ov_org);
	fovx = atan2(width/2, distance_to_middle_of_world) / M_PI * 360.0;
	fovy = atan2(height/2, distance_to_middle_of_world) / M_PI * 360.0;
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

float wcross_ring_prev;

entity trueaim;
entity trueaim_rifle;

const float SHOTTYPE_HITTEAM = 1;
const float SHOTTYPE_HITOBSTRUCTION = 2;
const float SHOTTYPE_HITWORLD = 3;
const float SHOTTYPE_HITENEMY = 4;

void TrueAim_Init()
{
	trueaim = new(trueaim);
	make_pure(trueaim);
	trueaim.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	trueaim_rifle = new(trueaim_rifle);
	make_pure(trueaim_rifle);
	trueaim_rifle.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
}

float EnemyHitCheck()
{
	float t, n;
	wcross_origin = project_3d_to_2d(trace_endpos);
	wcross_origin.z = 0;
	if(trace_ent)
		n = trace_ent.entnum;
	else
		n = trace_networkentity;
	if(n < 1)
		return SHOTTYPE_HITWORLD;
	if(n > maxclients)
		return SHOTTYPE_HITWORLD;
	t = entcs_GetTeam(n - 1);
	if(teamplay)
		if(t == myteam)
			return SHOTTYPE_HITTEAM;
	if(t == NUM_SPECTATOR)
		return SHOTTYPE_HITWORLD;
	return SHOTTYPE_HITENEMY;
}

float TrueAimCheck()
{
	float nudge = 1; // added to traceline target and subtracted from result TOOD(divVerent): do we still need this? Doesn't the engine do this now for us?
	vector vecs, trueaimpoint, w_shotorg;
	vector mi, ma, dv;
	float shottype;
	entity ta;
	float mv;

	mi = ma = '0 0 0';
	ta = trueaim;
	mv = MOVE_NOMONSTERS;

	switch(activeweapon) // WEAPONTODO
	{
		case WEP_TUBA: // no aim
		case WEP_PORTO: // shoots from eye
		case WEP_NEXBALL: // shoots from eye
		case WEP_HOOK: // no trueaim
		case WEP_MORTAR: // toss curve
			return SHOTTYPE_HITWORLD;
		case WEP_VORTEX:
		case WEP_VAPORIZER:
			mv = MOVE_NORMAL;
			break;
		case WEP_RIFLE:
			ta = trueaim_rifle;
			mv = MOVE_NORMAL;
			if(zoomscript_caught)
			{
				tracebox(view_origin, '0 0 0', '0 0 0', view_origin + view_forward * MAX_SHOT_DISTANCE, mv, ta);
				return EnemyHitCheck();
			}
			break;
		case WEP_DEVASTATOR: // projectile has a size!
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

	vector traceorigin = entcs_receiver(player_localentnum - 1).origin + (eZ * STAT(VIEWHEIGHT));

	vecs = decompressShotOrigin(STAT(SHOTORG));

	traceline(traceorigin, traceorigin + view_forward * MAX_SHOT_DISTANCE, mv, ta);
	trueaimpoint = trace_endpos;

	if(vlen(trueaimpoint - traceorigin) < g_trueaim_minrange)
		trueaimpoint = traceorigin + view_forward * g_trueaim_minrange;

	if(vecs.x > 0)
		vecs.y = -vecs.y;
	else
		vecs = '0 0 0';

	dv = view_right * vecs.y + view_up * vecs.z;
	w_shotorg = traceorigin + dv;

	// now move the vecs forward as much as requested if possible
	tracebox(w_shotorg, mi, ma, w_shotorg + view_forward * (vecs.x + nudge), MOVE_NORMAL, ta); // FIXME this MOVE_NORMAL part will misbehave a little in csqc
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

void PostInit();
void CSQC_Demo_Camera();
float HUD_WouldDrawScoreboard();
float camera_mode;
const float CAMERA_FREE = 1;
const float CAMERA_CHASE = 2;
float reticle_type;
string reticle_image;
string NextFrameCommand;

vector freeze_org, freeze_ang;
entity nightvision_noise, nightvision_noise2;

const float MAX_TIME_DIFF = 5;
float pickup_crosshair_time, pickup_crosshair_size;
float hitindication_crosshair_size;
float use_vortex_chargepool;

float myhealth, myhealth_prev;
float myhealth_flash;

float old_blurradius, old_bluralpha;
float old_sharpen_intensity;

vector myhealth_gentlergb;

float contentavgalpha, liquidalpha_prev;
vector liquidcolor_prev;

float eventchase_current_distance;
float eventchase_running;
bool WantEventchase()
{SELFPARAM();
	if(autocvar_cl_orthoview)
		return false;
	if(intermission)
		return true;
	if(self.viewloc)
		return true;
	if(spectatee_status >= 0)
	{
		if(hud != HUD_NORMAL && (autocvar_cl_eventchase_vehicle || spectatee_status > 0))
			return true;
		if(MUTATOR_CALLHOOK(WantEventchase, self))
			return true;
		if(autocvar_cl_eventchase_nexball && gametype == MAPINFO_TYPE_NEXBALL && !(WepSet_GetFromStat() & WEPSET(NEXBALL)))
			return true;
		if(autocvar_cl_eventchase_death && (STAT(HEALTH) <= 0))
		{
			if(autocvar_cl_eventchase_death == 2)
			{
				// don't stop eventchase once it's started (even if velocity changes afterwards)
				if(self.velocity == '0 0 0' || eventchase_running)
					return true;
			}
			else return true;
		}
	}
	return false;
}

void HUD_Crosshair_Vehicle()
{
	if(hud != HUD_BUMBLEBEE_GUN)
	{
		Vehicle info = get_vehicleinfo(hud);
		info.vr_crosshair(info);
	}
}

vector damage_blurpostprocess, content_blurpostprocess;

float unaccounted_damage = 0;
void UpdateDamage()
{
	// accumulate damage with each stat update
	static float damage_total_prev = 0;
	float damage_total = STAT(DAMAGE_DEALT_TOTAL);
	float unaccounted_damage_new = COMPARE_INCREASING(damage_total, damage_total_prev);
	damage_total_prev = damage_total;

	static float damage_dealt_time_prev = 0;
	float damage_dealt_time = STAT(HIT_TIME);
	if (damage_dealt_time != damage_dealt_time_prev)
	{
		unaccounted_damage += unaccounted_damage_new;
		LOG_TRACE("dmg total: ", ftos(unaccounted_damage), " (+", ftos(unaccounted_damage_new), ")", "\n");
	}
	damage_dealt_time_prev = damage_dealt_time;

	// prevent hitsound when switching spectatee
	static float spectatee_status_prev = 0;
	if (spectatee_status != spectatee_status_prev)
		unaccounted_damage = 0;
	spectatee_status_prev = spectatee_status;
}

void HitSound()
{
	// varying sound pitch

	static float hitsound_time_prev = 0;
	// HACK: the only way to get the arc to sound consistent with pitch shift is to ignore cl_hitsound_antispam_time
	float arc_hack = activeweapon == WEP_ARC && autocvar_cl_hitsound >= 2;
	if (arc_hack || COMPARE_INCREASING(time, hitsound_time_prev) > autocvar_cl_hitsound_antispam_time)
	{
		if (autocvar_cl_hitsound && unaccounted_damage)
		{
			// customizable gradient function that crosses (0,a), (c,1) and asymptotically approaches b
			float a = autocvar_cl_hitsound_max_pitch;
			float b = autocvar_cl_hitsound_min_pitch;
			float c = autocvar_cl_hitsound_nom_damage;
			float x = unaccounted_damage;
			float pitch_shift = (b*x*(a-1) + a*c*(1-b)) / (x*(a-1) + c*(1-b));

			// if sound variation is disabled, set pitch_shift to 1
			if (autocvar_cl_hitsound == 1)
				pitch_shift = 1;

			// if pitch shift is reversed, mirror in (max-min)/2 + min
			if (autocvar_cl_hitsound == 3)
			{
				float mirror_value = (a-b)/2 + b;
				pitch_shift = mirror_value + (mirror_value - pitch_shift);
			}

			LOG_TRACE("dmg total (dmg): ", ftos(unaccounted_damage), " , pitch shift: ", ftos(pitch_shift), "\n");

			// todo: avoid very long and very short sounds from wave stretching using different sound files? seems unnecessary
			// todo: normalize sound pressure levels? seems unnecessary

			sound7(world, CH_INFO, SND(HIT), VOL_BASE, ATTN_NONE, pitch_shift * 100, 0);
		}
		unaccounted_damage = 0;
		hitsound_time_prev = time;
	}

	static float typehit_time_prev = 0;
	float typehit_time = STAT(TYPEHIT_TIME);
	if (COMPARE_INCREASING(typehit_time, typehit_time_prev) > autocvar_cl_hitsound_antispam_time)
	{
		sound(world, CH_INFO, SND_TYPEHIT, VOL_BASE, ATTN_NONE);
		typehit_time_prev = typehit_time;
	}
}

void HUD_Crosshair()
{SELFPARAM();
	static float rainbow_last_flicker;
	static vector rainbow_prev_color;
	entity e = self;
	float f, i, j;
	vector v;
	if(!scoreboard_active && !camera_active && intermission != 2 &&
		spectatee_status != -1 && !csqcplayer.viewloc &&
		!HUD_MinigameMenu_IsOpened() )
	{
		if (!autocvar_crosshair_enabled) // main toggle for crosshair rendering
			return;

		if (hud != HUD_NORMAL)
		{
			HUD_Crosshair_Vehicle();
			return;
		}

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

		// wcross_origin = '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight;
		wcross_origin = project_3d_to_2d(view_origin + MAX_SHOT_DISTANCE * view_forward);
		wcross_origin.z = 0;
		if(autocvar_crosshair_hittest)
		{
			vector wcross_oldorigin;
			wcross_oldorigin = wcross_origin;
			shottype = TrueAimCheck();
			if(shottype == SHOTTYPE_HITWORLD)
			{
				v = wcross_origin - wcross_oldorigin;
				v.x /= vid_conwidth;
				v.y /= vid_conheight;
				if(vlen(v) > 0.01)
					shottype = SHOTTYPE_HITOBSTRUCTION;
			}
			if(!autocvar_crosshair_hittest_showimpact)
				wcross_origin = wcross_oldorigin;
		}
		else
			shottype = SHOTTYPE_HITWORLD;

		vector wcross_color = '0 0 0', wcross_size = '0 0 0';
		string wcross_name = "";
		float wcross_scale, wcross_blur;

		if(autocvar_crosshair_per_weapon || (autocvar_crosshair_color_special == 1))
		{
			e = switchingweapon;
			if(e)
			{
				if(autocvar_crosshair_per_weapon)
				{
					// WEAPONTODO: access these through some general settings (with non-balance config settings)
					//wcross_resolution *= cvar(strcat("crosshair_", wcross_wep, "_size"));
					//if (wcross_resolution == 0)
						//return;

					//wcross_style = cvar_string(strcat("crosshair_", wcross_wep));
					wcross_resolution *= e.w_crosshair_size;
					wcross_name = e.w_crosshair;
				}
			}
		}

		if(wcross_name == "")
			wcross_name = strcat("gfx/crosshair", wcross_style);

		// MAIN CROSSHAIR COLOR DECISION
		switch(autocvar_crosshair_color_special)
		{
			case 1: // crosshair_color_per_weapon
			{
				if(e)
				{
					wcross_color = e.wpcolor;
					break;
				}
				else { goto normalcolor; }
			}

			case 2: // crosshair_color_by_health
			{
				float x = STAT(HEALTH);

				//x = red
				//y = green
				//z = blue

				wcross_color.z = 0;

				if(x > 200)
				{
					wcross_color.x = 0;
					wcross_color.y = 1;
				}
				else if(x > 150)
				{
					wcross_color.x = 0.4 - (x-150)*0.02 * 0.4;
					wcross_color.y = 0.9 + (x-150)*0.02 * 0.1;
				}
				else if(x > 100)
				{
					wcross_color.x = 1 - (x-100)*0.02 * 0.6;
					wcross_color.y = 1 - (x-100)*0.02 * 0.1;
					wcross_color.z = 1 - (x-100)*0.02;
				}
				else if(x > 50)
				{
					wcross_color.x = 1;
					wcross_color.y = 1;
					wcross_color.z = 0.2 + (x-50)*0.02 * 0.8;
				}
				else if(x > 20)
				{
					wcross_color.x = 1;
					wcross_color.y = (x-20)*90/27/100;
					wcross_color.z = (x-20)*90/27/100 * 0.2;
				}
				else
				{
					wcross_color.x = 1;
					wcross_color.y = 0;
				}
				break;
			}

			case 3: // crosshair_color_rainbow
			{
				if(time >= rainbow_last_flicker)
				{
					rainbow_prev_color = randomvec() * autocvar_crosshair_color_special_rainbow_brightness;
					rainbow_last_flicker = time + autocvar_crosshair_color_special_rainbow_delay;
				}
				wcross_color = rainbow_prev_color;
				break;
			}
			:normalcolor
			default: { wcross_color = stov(autocvar_crosshair_color); break; }
		}

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
			float stat_pickup_time = STAT(LAST_PICKUP);

			if(pickup_crosshair_time < stat_pickup_time)
			{
				if(time - stat_pickup_time < MAX_TIME_DIFF) // don't trigger the animation if it's too old
					pickup_crosshair_size = 1;

				pickup_crosshair_time = stat_pickup_time;
			}

			if(pickup_crosshair_size > 0)
				pickup_crosshair_size -= autocvar_crosshair_pickup_speed * frametime;
			else
				pickup_crosshair_size = 0;

			wcross_scale += sin(pickup_crosshair_size) * autocvar_crosshair_pickup;
		}

		// todo: make crosshair hit indication dependent on damage dealt
		if(autocvar_crosshair_hitindication)
		{
			vector hitindication_color = ((autocvar_crosshair_color_special == 1) ? stov(autocvar_crosshair_hitindication_per_weapon_color) : stov(autocvar_crosshair_hitindication_color));

			if(unaccounted_damage)
			{
				hitindication_crosshair_size = 1;
			}

			if(hitindication_crosshair_size > 0)
				hitindication_crosshair_size -= autocvar_crosshair_hitindication_speed * frametime;
			else
				hitindication_crosshair_size = 0;

			wcross_scale += sin(hitindication_crosshair_size) * autocvar_crosshair_hitindication;
			wcross_color.x += sin(hitindication_crosshair_size) * hitindication_color.x;
			wcross_color.y += sin(hitindication_crosshair_size) * hitindication_color.y;
			wcross_color.z += sin(hitindication_crosshair_size) * hitindication_color.z;
		}

		if(shottype == SHOTTYPE_HITENEMY)
			wcross_scale *= autocvar_crosshair_hittest; // is not queried if hittest is 0
		if(shottype == SHOTTYPE_HITTEAM)
			wcross_scale /= autocvar_crosshair_hittest; // is not queried if hittest is 0

		f = fabs(autocvar_crosshair_effect_time);
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

		if(spectatee_status == -1 && shottype == SHOTTYPE_HITTEAM || (shottype == SHOTTYPE_HITOBSTRUCTION && autocvar_crosshair_hittest_blur && !autocvar_chase_active))
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

		MUTATOR_CALLHOOK(UpdateCrosshair);

		wcross_scale *= 1 - autocvar__menu_alpha;
		wcross_alpha *= 1 - autocvar__menu_alpha;
		wcross_size = draw_getimagesize(wcross_name) * wcross_scale;

		if(wcross_scale >= 0.001 && wcross_alpha >= 0.001)
		{
			// crosshair rings for weapon stats
			if (autocvar_crosshair_ring || autocvar_crosshair_ring_reload)
			{
				// declarations and stats
				float ring_value = 0, ring_scale = 0, ring_alpha = 0, ring_inner_value = 0, ring_inner_alpha = 0;
				string ring_image = string_null, ring_inner_image = string_null;
				vector ring_rgb = '0 0 0', ring_inner_rgb = '0 0 0';

				ring_scale = autocvar_crosshair_ring_size;

				float weapon_clipload, weapon_clipsize;
				weapon_clipload = STAT(WEAPON_CLIPLOAD);
				weapon_clipsize = STAT(WEAPON_CLIPSIZE);

				float ok_ammo_charge, ok_ammo_chargepool;
				ok_ammo_charge = STAT(OK_AMMO_CHARGE);
				ok_ammo_chargepool = STAT(OK_AMMO_CHARGEPOOL);

				float vortex_charge, vortex_chargepool;
				vortex_charge = STAT(VORTEX_CHARGE);
				vortex_chargepool = STAT(VORTEX_CHARGEPOOL);

				float arc_heat = STAT(ARC_HEAT);

				if(vortex_charge_movingavg == 0) // this should only happen if we have just loaded up the game
					vortex_charge_movingavg = vortex_charge;


				// handle the values
				if (autocvar_crosshair_ring && activeweapon == WEP_VORTEX && vortex_charge && autocvar_crosshair_ring_vortex) // ring around crosshair representing velocity-dependent damage for the vortex
				{
					if (vortex_chargepool || use_vortex_chargepool) {
						use_vortex_chargepool = 1;
						ring_inner_value = vortex_chargepool;
					} else {
						vortex_charge_movingavg = (1 - autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate) * vortex_charge_movingavg + autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate * vortex_charge;
						ring_inner_value = bound(0, autocvar_crosshair_ring_vortex_currentcharge_scale * (vortex_charge - vortex_charge_movingavg), 1);
					}

					ring_inner_alpha = autocvar_crosshair_ring_vortex_inner_alpha;
					ring_inner_rgb = eX * autocvar_crosshair_ring_vortex_inner_color_red + eY * autocvar_crosshair_ring_vortex_inner_color_green + eZ * autocvar_crosshair_ring_vortex_inner_color_blue;
					ring_inner_image = "gfx/crosshair_ring_inner.tga";

					// draw the outer ring to show the current charge of the weapon
					ring_value = vortex_charge;
					ring_alpha = autocvar_crosshair_ring_vortex_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring_nexgun.tga";
				}
				else if (autocvar_crosshair_ring && activeweapon == WEP_MINE_LAYER && WEP_CVAR(minelayer, limit) && autocvar_crosshair_ring_minelayer)
				{
					ring_value = bound(0, STAT(LAYED_MINES) / WEP_CVAR(minelayer, limit), 1); // if you later need to use the count of bullets in another place, then add a float for it. For now, no need to.
					ring_alpha = autocvar_crosshair_ring_minelayer_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring.tga";
				}
				else if (activeweapon == WEP_HAGAR && STAT(HAGAR_LOAD) && autocvar_crosshair_ring_hagar)
				{
					ring_value = bound(0, STAT(HAGAR_LOAD) / WEP_CVAR_SEC(hagar, load_max), 1);
					ring_alpha = autocvar_crosshair_ring_hagar_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring.tga";
				}
				else if (ok_ammo_charge)
				{
					ring_value = ok_ammo_chargepool;
					ring_alpha = autocvar_crosshair_ring_reload_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring.tga";
				}
				else if(autocvar_crosshair_ring_reload && weapon_clipsize) // forces there to be only an ammo ring
				{
					ring_value = bound(0, weapon_clipload / weapon_clipsize, 1);
					ring_scale = autocvar_crosshair_ring_reload_size;
					ring_alpha = autocvar_crosshair_ring_reload_alpha;
					ring_rgb = wcross_color;

					// Note: This is to stop Taoki from complaining that the image doesn't match all potential balances.
					// if a new image for another weapon is added, add the code (and its respective file/value) here
					if ((activeweapon == WEP_RIFLE) && (weapon_clipsize == 80))
						ring_image = "gfx/crosshair_ring_rifle.tga";
					else
						ring_image = "gfx/crosshair_ring.tga";
				}
				else if ( autocvar_crosshair_ring && autocvar_crosshair_ring_arc && arc_heat && activeweapon == WEP_ARC )
				{
					ring_value = arc_heat;
					ring_alpha = (1-arc_heat)*autocvar_crosshair_ring_arc_cold_alpha +
						arc_heat*autocvar_crosshair_ring_arc_hot_alpha;
					ring_rgb = (1-arc_heat)*wcross_color + arc_heat*autocvar_crosshair_ring_arc_hot_color;
					ring_image = "gfx/crosshair_ring.tga";
				}

				// if in weapon switch animation, fade ring out/in
				if(autocvar_crosshair_effect_time > 0)
				{
					f = (time - wcross_name_changestarttime) / autocvar_crosshair_effect_time;
					if (f >= 1)
					{
						wcross_ring_prev = ((ring_image) ? true : false);
					}

					if(wcross_ring_prev)
					{
						if(f < 1)
							ring_alpha *= fabs(1 - bound(0, f, 1));
					}
					else
					{
						if(f < 1)
							ring_alpha *= bound(0, f, 1);
					}
				}

				if (autocvar_crosshair_ring_inner && ring_inner_value) // lets draw a ring inside a ring so you can ring while you ring
					DrawCircleClippedPic(wcross_origin, wcross_size.x * ring_scale, ring_inner_image, ring_inner_value, ring_inner_rgb, wcross_alpha * ring_inner_alpha, DRAWFLAG_ADDITIVE);

				if (ring_value)
					DrawCircleClippedPic(wcross_origin, wcross_size.x * ring_scale, ring_image, ring_value, ring_rgb, wcross_alpha * ring_alpha, DRAWFLAG_ADDITIVE);
			}

#define CROSSHAIR_DO_BLUR(M,sz,wcross_name,wcross_alpha) \
			MACRO_BEGIN { \
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
			} MACRO_END

#define CROSSHAIR_DRAW_SINGLE(i,j,sz,wcross_name,wcross_alpha) \
			drawpic(wcross_origin - ('0.5 0 0' * (sz * wcross_size.x + i * wcross_blur) + '0 0.5 0' * (sz * wcross_size.y + j * wcross_blur)), wcross_name, sz * wcross_size, wcross_color, wcross_alpha, DRAWFLAG_NORMAL)

#define CROSSHAIR_DRAW(sz,wcross_name,wcross_alpha) \
			CROSSHAIR_DO_BLUR(CROSSHAIR_DRAW_SINGLE,sz,wcross_name,wcross_alpha)

			if(time < wcross_name_changedonetime && wcross_name != wcross_name_goal_prev_prev && wcross_name_goal_prev_prev)
			{
				f = (wcross_name_changedonetime - time) / (wcross_name_changedonetime - wcross_name_changestarttime);
				wcross_size = draw_getimagesize(wcross_name_goal_prev_prev) * wcross_scale;
				CROSSHAIR_DRAW(wcross_resolution_goal_prev_prev, wcross_name_goal_prev_prev, wcross_alpha * f * wcross_name_alpha_goal_prev_prev);
				f = 1 - f;
			}
			else
			{
				f = 1;
			}
			wcross_name_alpha_goal_prev = f;

			wcross_size = draw_getimagesize(wcross_name) * wcross_scale;
			CROSSHAIR_DRAW(wcross_resolution, wcross_name, wcross_alpha * f);

			if(autocvar_crosshair_dot)
			{
				vector wcross_color_old;
				wcross_color_old = wcross_color;

				if((autocvar_crosshair_dot_color_custom) && (autocvar_crosshair_dot_color != "0"))
					wcross_color = stov(autocvar_crosshair_dot_color);

				CROSSHAIR_DRAW(wcross_resolution * autocvar_crosshair_dot_size, "gfx/crosshairdot.tga", f * autocvar_crosshair_dot_alpha);
				// FIXME why don't we use wcross_alpha here?
				wcross_color = wcross_color_old;
			}
		}
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

void HUD_Draw()
{
	vector rgb = '0 0 0';
	float a = 1;
	if (MUTATOR_CALLHOOK(HUD_Draw_overlay))
	{
		rgb = MUTATOR_ARGV(0, vector);
		a = MUTATOR_ARGV(0, float);
	}
	else if(STAT(FROZEN))
	{
		rgb = ((STAT(REVIVE_PROGRESS)) ? ('0.25 0.90 1' + ('1 0 0' * STAT(REVIVE_PROGRESS)) + ('0 1 1' * STAT(REVIVE_PROGRESS) * -1)) : '0.25 0.90 1');
	}
	drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, rgb, autocvar_hud_colorflash_alpha * a, DRAWFLAG_ADDITIVE);
	if(!intermission)
	if(STAT(NADE_TIMER) && autocvar_cl_nade_timer) // give nade top priority, as it's a matter of life and death
	{
		DrawCircleClippedPic(eX * 0.5 * vid_conwidth + eY * 0.6 * vid_conheight, 0.1 * vid_conheight, "gfx/crosshair_ring.tga", STAT(NADE_TIMER), '0.25 0.90 1' + ('1 0 0' * STAT(NADE_TIMER)) - ('0 1 1' * STAT(NADE_TIMER)), autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
		drawstring_aspect(eY * 0.64 * vid_conheight, ((autocvar_cl_nade_timer == 2) ? _("Nade timer") : ""), eX * vid_conwidth + eY * 0.025 * vid_conheight, '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	else if(STAT(REVIVE_PROGRESS))
	{
		DrawCircleClippedPic(eX * 0.5 * vid_conwidth + eY * 0.6 * vid_conheight, 0.1 * vid_conheight, "gfx/crosshair_ring.tga", STAT(REVIVE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
		drawstring_aspect(eY * 0.64 * vid_conheight, _("Revival progress"), eX * vid_conwidth + eY * 0.025 * vid_conheight, '1 1 1', 1, DRAWFLAG_NORMAL);
	}

	if(autocvar_r_letterbox == 0)
		if(autocvar_viewsize < 120)
		{
			if(!(gametype == MAPINFO_TYPE_RACE || gametype == MAPINFO_TYPE_CTS))
				Accuracy_LoadLevels();

			HUD_Main();
			HUD_DrawScoreboard();
		}

	// crosshair goes VERY LAST
	UpdateDamage();
	HUD_Crosshair();
	HitSound();
}

bool ov_enabled;
float oldr_nearclip;
float oldr_farclip_base;
float oldr_farclip_world;
float oldr_novis;
float oldr_useportalculling;
float oldr_useinfinitefarclip;

void cl_notice_run();
float prev_myteam;
int lasthud;
float vh_notice_time;
void WaypointSprite_Load();
void CSQC_UpdateView(float w, float h)
{SELFPARAM();
	entity e;
	float fov;
	float f;
	vector vf_size, vf_min;
	float a;

	execute_next_frame();

	++framecount;

	stats_get();
	hud = STAT(HUD);

	if(hud != HUD_NORMAL && lasthud == HUD_NORMAL)
		vh_notice_time = time + autocvar_cl_vehicles_notify_time;

	lasthud = hud;

	if(autocvar__hud_showbinds_reload) // menu can set this one
	{
		db_close(binddb);
		binddb = db_create();
		cvar_set("_hud_showbinds_reload", "0");
	}

	if(checkextension("DP_CSQC_MINFPS_QUALITY"))
		view_quality = getproperty(VF_MINFPS_QUALITY);
	else
		view_quality = 1;

	button_attack2 = PHYS_INPUT_BUTTON_ATCK2(self);
	button_zoom = PHYS_INPUT_BUTTON_ZOOM(self);

	vf_size = getpropertyvec(VF_SIZE);
	vf_min = getpropertyvec(VF_MIN);
	vid_width = vf_size.x;
	vid_height = vf_size.y;

	vector reticle_pos = '0 0 0', reticle_size = '0 0 0';
	vector splash_pos = '0 0 0', splash_size = '0 0 0';

	WaypointSprite_Load();

	CSQCPlayer_SetCamera();

	if(player_localentnum <= maxclients) // is it a client?
		current_player = player_localentnum - 1;
	else // then player_localentnum is the vehicle I'm driving
		current_player = player_localnum;
	myteam = entcs_GetTeam(current_player);

	if(myteam != prev_myteam)
	{
		myteamcolors = colormapPaletteColor(myteam, 1);
		FOREACH(hud_panels, true, LAMBDA(it.update_time = time));
		prev_myteam = myteam;
	}

	ticrate = STAT(MOVEVARS_TICRATE) * STAT(MOVEVARS_TIMESCALE);

	float is_dead = (STAT(HEALTH) <= 0);

	// FIXME do we need this hack?
	if(isdemo())
	{
		// in demos, input_buttons do not work
		button_zoom = (autocvar__togglezoom == "-");
	}
	else if(button_zoom
		&& autocvar_cl_unpress_zoom_on_death
		&& (spectatee_status >= 0)
		&& (is_dead || intermission))
	{
		// no zoom while dead or in intermission please
		localcmd("-zoom\n");
		button_zoom = false;
	}

	// event chase camera
	if(autocvar_chase_active <= 0) // greater than 0 means it's enabled manually, and this code is skipped
	{
		float vehicle_chase = (hud != HUD_NORMAL && (autocvar_cl_eventchase_vehicle || spectatee_status > 0));
		float ons_roundlost = (gametype == MAPINFO_TYPE_ONSLAUGHT && STAT(ROUNDLOST));
		entity gen = world;

		if(ons_roundlost)
		{
			entity e;
			for(e = world; (e = find(e, classname, "onslaught_generator")); )
			{
				if(e.health <= 0)
				{
					gen = e;
					break;
				}
			}
			if(!gen)
				ons_roundlost = FALSE; // don't enforce the 3rd person camera if there is no dead generator to show
		}
		if(WantEventchase() || (!autocvar_cl_orthoview && ons_roundlost))
		{
			eventchase_running = true;

			// make special vector since we can't use view_origin (It is one frame old as of this code, it gets set later with the results this code makes.)
			vector current_view_origin = (csqcplayer ? csqcplayer.origin : pmove_org);
			if(ons_roundlost) { current_view_origin = gen.origin; }

			// detect maximum viewoffset and use it
			vector view_offset = autocvar_cl_eventchase_viewoffset;
			if(vehicle_chase && autocvar_cl_eventchase_vehicle_viewoffset) { view_offset = autocvar_cl_eventchase_vehicle_viewoffset; }
			if(ons_roundlost) { view_offset = autocvar_cl_eventchase_generator_viewoffset; }

			if(view_offset)
			{
				WarpZone_TraceLine(current_view_origin, current_view_origin + view_offset + ('0 0 1' * autocvar_cl_eventchase_maxs.z), MOVE_WORLDONLY, self);
				if(trace_fraction == 1) { current_view_origin += view_offset; }
				else { current_view_origin.z += max(0, (trace_endpos.z - current_view_origin.z) - autocvar_cl_eventchase_maxs.z); }
			}

			// We must enable chase_active to get a third person view (weapon viewmodel hidden and own player model showing).
			// Ideally, there should be another way to enable third person cameras, such as through setproperty()
			// -1 enables chase_active while marking it as set by this code, and not by the user (which would be 1)
			if(!autocvar_chase_active) { cvar_set("chase_active", "-1"); }

			// make the camera smooth back
			float chase_distance = autocvar_cl_eventchase_distance;
			if(vehicle_chase && autocvar_cl_eventchase_vehicle_distance) { chase_distance = autocvar_cl_eventchase_vehicle_distance; }
			if(ons_roundlost) { chase_distance = autocvar_cl_eventchase_generator_distance; }

			if(autocvar_cl_eventchase_speed && eventchase_current_distance < chase_distance)
				eventchase_current_distance += autocvar_cl_eventchase_speed * (chase_distance - eventchase_current_distance) * frametime; // slow down the further we get
			else if(eventchase_current_distance != chase_distance)
				eventchase_current_distance = chase_distance;

			makevectors(view_angles);

			vector eventchase_target_origin = (current_view_origin - (v_forward * eventchase_current_distance));
			WarpZone_TraceBox(current_view_origin, autocvar_cl_eventchase_mins, autocvar_cl_eventchase_maxs, eventchase_target_origin, MOVE_WORLDONLY, self);

			// If the boxtrace fails, revert back to line tracing.
			if(!self.viewloc)
			if(trace_startsolid)
			{
				eventchase_target_origin = (current_view_origin - (v_forward * eventchase_current_distance));
				WarpZone_TraceLine(current_view_origin, eventchase_target_origin, MOVE_WORLDONLY, self);
				setproperty(VF_ORIGIN, (trace_endpos - (v_forward * autocvar_cl_eventchase_mins.z)));
			}
			else { setproperty(VF_ORIGIN, trace_endpos); }

			if(!self.viewloc)
				setproperty(VF_ANGLES, WarpZone_TransformVAngles(WarpZone_trace_transform, view_angles));
		}
		else if(autocvar_chase_active < 0) // time to disable chase_active if it was set by this code
		{
			eventchase_running = false;
			cvar_set("chase_active", "0");
			eventchase_current_distance = 0; // start from 0 next time
		}
	}
	// workaround for camera stuck between player's legs when using chase_active 1
	// because the engine stops updating the chase_active camera when the game ends
	else if(intermission)
	{
		cvar_settemp("chase_active", "-1");
		eventchase_current_distance = 0;
	}

	// do lockview after event chase camera so that it still applies whenever necessary.
	if(autocvar_cl_lockview || (!autocvar_hud_cursormode && (autocvar__hud_configure && spectatee_status <= 0 || intermission > 1 || QuickMenu_IsOpened())))
	{
		setproperty(VF_ORIGIN, freeze_org);
		setproperty(VF_ANGLES, freeze_ang);
	}
	else
	{
		freeze_org = getpropertyvec(VF_ORIGIN);
		freeze_ang = getpropertyvec(VF_ANGLES);
	}

	WarpZone_FixView();
	//WarpZone_FixPMove();

	vector ov_org = '0 0 0';
	vector ov_mid = '0 0 0';
	vector ov_worldmin = '0 0 0';
	vector ov_worldmax = '0 0 0';
	if(autocvar_cl_orthoview)
	{
		ov_worldmin = mi_picmin;
		ov_worldmax = mi_picmax;

		float ov_width = (ov_worldmax.x - ov_worldmin.x);
		float ov_height = (ov_worldmax.y - ov_worldmin.y);
		float ov_distance = (max(vid_width, vid_height) * max(ov_width, ov_height));

		ov_mid = ((ov_worldmax + ov_worldmin) * 0.5);
		ov_org = vec3(ov_mid.x, ov_mid.y, (ov_mid.z + ov_distance));

		float ov_nearest = vlen(ov_org - vec3(
			bound(ov_worldmin.x, ov_org.x, ov_worldmax.x),
			bound(ov_worldmin.y, ov_org.y, ov_worldmax.y),
			bound(ov_worldmin.z, ov_org.z, ov_worldmax.z)
		));

		float ov_furthest = 0;
		float dist = 0;

		if((dist = vlen(vec3(ov_worldmin.x, ov_worldmin.y, ov_worldmin.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmax.x, ov_worldmin.y, ov_worldmin.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmin.x, ov_worldmax.y, ov_worldmin.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmin.x, ov_worldmin.y, ov_worldmax.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmax.x, ov_worldmax.y, ov_worldmin.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmin.x, ov_worldmax.y, ov_worldmax.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmax.x, ov_worldmin.y, ov_worldmax.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }
		if((dist = vlen(vec3(ov_worldmax.x, ov_worldmax.y, ov_worldmax.z) - ov_org)) > ov_furthest) { ov_furthest = dist; }

		if(!ov_enabled)
		{
			oldr_nearclip = cvar("r_nearclip");
			oldr_farclip_base = cvar("r_farclip_base");
			oldr_farclip_world = cvar("r_farclip_world");
			oldr_novis = cvar("r_novis");
			oldr_useportalculling = cvar("r_useportalculling");
			oldr_useinfinitefarclip = cvar("r_useinfinitefarclip");
		}

		cvar_settemp("r_nearclip", ftos(ov_nearest));
		cvar_settemp("r_farclip_base", ftos(ov_furthest));
		cvar_settemp("r_farclip_world", "0");
		cvar_settemp("r_novis", "1");
		cvar_settemp("r_useportalculling", "0");
		cvar_settemp("r_useinfinitefarclip", "0");

		setproperty(VF_ORIGIN, ov_org);
		setproperty(VF_ANGLES, '90 0 0');

		ov_enabled = true;

		#if 0
		LOG_INFOF("OrthoView: org = %s, angles = %s, distance = %f, nearest = %f, furthest = %f\n",
			vtos(ov_org),
			vtos(getpropertyvec(VF_ANGLES)),
			ov_distance,
			ov_nearest,
			ov_furthest);
		#endif
	}
	else
	{
		if(ov_enabled)
		{
			cvar_set("r_nearclip", ftos(oldr_nearclip));
			cvar_set("r_farclip_base", ftos(oldr_farclip_base));
			cvar_set("r_farclip_world", ftos(oldr_farclip_world));
			cvar_set("r_novis", ftos(oldr_novis));
			cvar_set("r_useportalculling", ftos(oldr_useportalculling));
			cvar_set("r_useinfinitefarclip", ftos(oldr_useinfinitefarclip));
		}
		ov_enabled = false;
	}

	// Render the Scene
	view_origin = getpropertyvec(VF_ORIGIN);
	view_angles = getpropertyvec(VF_ANGLES);
	makevectors(view_angles);
	view_forward = v_forward;
	view_right = v_right;
	view_up = v_up;

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

	if(drawtime == 0)
		drawframetime = 0.01666667; // when we don't know fps yet, we assume 60fps
	else
		drawframetime = bound(0.000001, time - drawtime, 1);
	drawtime = time;

	// watch for gametype changes here...
	// in ParseStuffCMD the cmd isn't executed yet :/
	// might even be better to add the gametype to TE_CSQC_INIT...?
	if(!postinit)
		PostInit();

	if(intermission && !isdemo() && !(calledhooks & HOOK_END))
	{
		if(calledhooks & HOOK_START)
		{
			localcmd("\ncl_hook_gameend\n");
			calledhooks |= HOOK_END;
		}
	}

	Announcer();

	fov = autocvar_fov;
	if(fov <= 59.5)
	{
		if(!zoomscript_caught)
		{
			localcmd("+button9\n");
			zoomscript_caught = 1;
		}
	}
	else
	{
		if(zoomscript_caught)
		{
			localcmd("-button9\n");
			zoomscript_caught = 0;
		}
	}

	ColorTranslateMode = autocvar_cl_stripcolorcodes;

	// currently switching-to weapon (for crosshair)
	switchingweapon = Weapons_from(STAT(SWITCHINGWEAPON));

	// actually active weapon (for zoom)
	activeweapon = Weapons_from(STAT(ACTIVEWEAPON));

	switchweapon = Weapons_from(STAT(SWITCHWEAPON));

	f = (serverflags & SERVERFLAG_TEAMPLAY);
	if(f != teamplay)
	{
		teamplay = f;
		HUD_InitScores();
	}

	if(last_switchweapon != switchweapon)
	{
		weapontime = time;
		last_switchweapon = switchweapon;
		if(button_zoom && autocvar_cl_unpress_zoom_on_weapon_switch)
		{
			localcmd("-zoom\n");
			button_zoom = false;
		}
		if(autocvar_cl_unpress_attack_on_weapon_switch)
		{
			localcmd("-fire\n");
			localcmd("-fire2\n");
			button_attack2 = false;
		}
	}
	if(last_activeweapon != activeweapon)
	{
		last_activeweapon = activeweapon;

		e = activeweapon;
		if(e.netname != "")
			localcmd(strcat("\ncl_hook_activeweapon ", e.netname), "\n");
		else
			localcmd("\ncl_hook_activeweapon none\n");
	}

	// ALWAYS Clear Current Scene First
	clearscene();

	setproperty(VF_ORIGIN, view_origin);
	setproperty(VF_ANGLES, view_angles);

	// FIXME engine bug? VF_SIZE and VF_MIN are not restored to sensible values by this
	setproperty(VF_SIZE, vf_size);
	setproperty(VF_MIN, vf_min);

	// Assign Standard Viewflags
	// Draw the World (and sky)
	setproperty(VF_DRAWWORLD, 1);

	// Set the console size vars
	vid_conwidth = autocvar_vid_conwidth;
	vid_conheight = autocvar_vid_conheight;
	vid_pixelheight = autocvar_vid_pixelheight;

	if(autocvar_cl_orthoview) { setproperty(VF_FOV, GetOrthoviewFOV(ov_worldmin, ov_worldmax, ov_mid, ov_org)); }
	else if(csqcplayer.viewloc) { setproperty(VF_FOV, GetViewLocationFOV(110)); } // enforce 110 fov, so things dont look odd
	else { setproperty(VF_FOV, GetCurrentFov(fov)); }

	// Camera for demo playback
	if(camera_active)
	{
		if(autocvar_camera_enable)
			CSQC_Demo_Camera();
		else
		{
			cvar_set("chase_active", ftos(chase_active_backup));
			cvar_set("cl_demo_mousegrab", "0");
			camera_active = false;
		}
	}
	else
	{
#ifdef CAMERATEST
		if(autocvar_camera_enable)
#else
		if(autocvar_camera_enable && isdemo())
#endif
		{
			// Enable required Darkplaces cvars
			chase_active_backup = autocvar_chase_active;
			cvar_set("chase_active", "2");
			cvar_set("cl_demo_mousegrab", "1");
			camera_active = true;
			camera_mode = false;
		}
	}

	// Draw the Crosshair
	setproperty(VF_DRAWCROSSHAIR, 0); //Make sure engine crosshairs are always hidden

	// Draw the Engine Status Bar (the default Quake HUD)
	setproperty(VF_DRAWENGINESBAR, 0);

	// Update the mouse position
	/*
	   mousepos_x = vid_conwidth;
	   mousepos_y = vid_conheight;
	   mousepos = mousepos*0.5 + getmousepos();
	 */

	FOREACH_ENTITY(it.draw, LAMBDA(WITH(entity, self, it, it.draw(it))));

	addentities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	renderscene();

	// now switch to 2D drawing mode by calling a 2D drawing function
	// then polygon drawing will draw as 2D stuff, and NOT get queued until the
	// next R_RenderScene call
	drawstring('0 0 0', "", '1 1 0', '1 1 1', 0, 0);

	if(autocvar_r_fakelight >= 2 || autocvar_r_fullbright)
	if (!(serverflags & SERVERFLAG_ALLOW_FULLBRIGHT))
	{
		// apply night vision effect
		vector tc_00, tc_01, tc_10, tc_11;
		vector rgb = '0 0 0';

		if(!nightvision_noise)
		{
			nightvision_noise = new(nightvision_noise);
		}
		if(!nightvision_noise2)
		{
			nightvision_noise2 = new(nightvision_noise2);
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

	if(autocvar_cl_reticle)
	{
		Weapon wep = activeweapon;
		// Draw the aiming reticle for weapons that use it
		// reticle_type is changed to the item we are zooming / aiming with, to decide which reticle to use
		// It must be a persisted float for fading out to work properly (you let go of the zoom button for
		// the view to go back to normal, so reticle_type would become 0 as we fade out)
		if(spectatee_status || is_dead || hud != HUD_NORMAL)
		{
			// no zoom reticle while dead
			reticle_type = 0;
		}
		else if(wep.wr_zoomreticle(wep) && autocvar_cl_reticle_weapon)
		{
			if(reticle_image != "") { reticle_type = 2; }
			else { reticle_type = 0; }
		}
		else if(button_zoom || zoomscript_caught)
		{
			// normal zoom
			reticle_type = 1;
		}

		if(reticle_type)
		{
			if(autocvar_cl_reticle_stretch)
			{
				reticle_size.x = vid_conwidth;
				reticle_size.y = vid_conheight;
				reticle_pos.x = 0;
				reticle_pos.y = 0;
			}
			else
			{
				reticle_size.x = max(vid_conwidth, vid_conheight);
				reticle_size.y = max(vid_conwidth, vid_conheight);
				reticle_pos.x = (vid_conwidth - reticle_size.x) / 2;
				reticle_pos.y = (vid_conheight - reticle_size.y) / 2;
			}

			if(zoomscript_caught)
				f = 1;
			else
				f = current_zoomfraction;

			if(f)
			{
				switch(reticle_type)
				{
					case 1: drawpic(reticle_pos, "gfx/reticle_normal", reticle_size, '1 1 1', f * autocvar_cl_reticle_normal_alpha, DRAWFLAG_NORMAL); break;
					case 2: drawpic(reticle_pos, reticle_image, reticle_size, '1 1 1', f * autocvar_cl_reticle_weapon_alpha, DRAWFLAG_NORMAL); break;
				}
			}
		}
	}
	else
	{
		if(reticle_type != 0) { reticle_type = 0; }
	}


	// improved polyblend
	if(autocvar_hud_contents)
	{
		float contentalpha_temp, incontent, liquidalpha, contentfadetime;
		vector liquidcolor;

		switch(pointcontents(view_origin))
		{
			case CONTENT_WATER:
				liquidalpha = autocvar_hud_contents_water_alpha;
				liquidcolor = stov(autocvar_hud_contents_water_color);
				incontent = 1;
				break;

			case CONTENT_LAVA:
				liquidalpha = autocvar_hud_contents_lava_alpha;
				liquidcolor = stov(autocvar_hud_contents_lava_color);
				incontent = 1;
				break;

			case CONTENT_SLIME:
				liquidalpha = autocvar_hud_contents_slime_alpha;
				liquidcolor = stov(autocvar_hud_contents_slime_color);
				incontent = 1;
				break;

			default:
				liquidalpha = 0;
				liquidcolor = '0 0 0';
				incontent = 0;
				break;
		}

		if(incontent) // fade in/out at different speeds so you can do e.g. instant fade when entering water and slow when leaving it.
		{ // also lets delcare previous values for blending properties, this way it isn't reset until after you have entered a different content
			contentfadetime = autocvar_hud_contents_fadeintime;
			liquidalpha_prev = liquidalpha;
			liquidcolor_prev = liquidcolor;
		}
		else
			contentfadetime = autocvar_hud_contents_fadeouttime;

		contentalpha_temp = bound(0, drawframetime / max(0.0001, contentfadetime), 1);
		contentavgalpha = contentavgalpha * (1 - contentalpha_temp) + incontent * contentalpha_temp;

		if(contentavgalpha)
			drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, liquidcolor_prev, contentavgalpha * liquidalpha_prev, DRAWFLAG_NORMAL);

		if(autocvar_hud_postprocessing)
		{
			if(autocvar_hud_contents_blur && contentavgalpha)
			{
				content_blurpostprocess.x = 1;
				content_blurpostprocess.y = contentavgalpha * autocvar_hud_contents_blur;
				content_blurpostprocess.z = contentavgalpha * autocvar_hud_contents_blur_alpha;
			}
			else
			{
				content_blurpostprocess.x = 0;
				content_blurpostprocess.y = 0;
				content_blurpostprocess.z = 0;
			}
		}
	}

	if(autocvar_hud_damage && !STAT(FROZEN))
	{
		splash_size.x = max(vid_conwidth, vid_conheight);
		splash_size.y = max(vid_conwidth, vid_conheight);
		splash_pos.x = (vid_conwidth - splash_size.x) / 2;
		splash_pos.y = (vid_conheight - splash_size.y) / 2;

		float myhealth_flash_temp;
		myhealth = STAT(HEALTH);

		// fade out
		myhealth_flash = max(0, myhealth_flash - autocvar_hud_damage_fade_rate * frametime);
		// add new damage
		myhealth_flash = bound(0, myhealth_flash + dmg_take * autocvar_hud_damage_factor, autocvar_hud_damage_maxalpha);

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

		// IDEA: change damage color/picture based on player model for robot/alien species?
		// pro: matches model better
		// contra: it's not red because blood is red, but because red is an alarming color, so red should stay
		// maybe different reddish pics?
		if(autocvar_cl_gentle_damage || autocvar_cl_gentle)
		{
			if(autocvar_cl_gentle_damage == 2)
			{
				if(myhealth_flash < pain_threshold) // only randomize when the flash is gone
					myhealth_gentlergb = eX * random() + eY * random() + eZ * random();
			}
			else
				myhealth_gentlergb = stov(autocvar_hud_damage_gentle_color);

			if(myhealth_flash_temp > 0)
				drawfill('0 0 0', eX * vid_conwidth + eY * vid_conheight, myhealth_gentlergb, autocvar_hud_damage_gentle_alpha_multiplier * bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage, DRAWFLAG_NORMAL);
		}
		else if(myhealth_flash_temp > 0)
			drawpic(splash_pos, "gfx/blood", splash_size, stov(autocvar_hud_damage_color), bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage, DRAWFLAG_NORMAL);

		if(autocvar_hud_postprocessing) // we still need to set this anyway even when chase_active is set, this way it doesn't get stuck on.
		{
			if(autocvar_hud_damage_blur && myhealth_flash_temp)
			{
				damage_blurpostprocess.x = 1;
				damage_blurpostprocess.y = bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage_blur;
				damage_blurpostprocess.z = bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage_blur_alpha;
			}
			else
			{
				damage_blurpostprocess.x = 0;
				damage_blurpostprocess.y = 0;
				damage_blurpostprocess.z = 0;
			}
		}
	}

	float e1 = (autocvar_hud_postprocessing_maxbluralpha != 0);
	float e2 = (autocvar_hud_powerup != 0);
	if(autocvar_hud_postprocessing && (e1 || e2)) // TODO: Remove this code and re-do the postprocess handling in the engine, where it properly belongs.
	{
		// enable or disable rendering types if they are used or not
		if(cvar("r_glsl_postprocess_uservec1_enable") != e1) { cvar_set("r_glsl_postprocess_uservec1_enable", ftos(e1)); }
		if(cvar("r_glsl_postprocess_uservec2_enable") != e2) { cvar_set("r_glsl_postprocess_uservec2_enable", ftos(e2)); }

		// blur postprocess handling done first (used by hud_damage and hud_contents)
		if((damage_blurpostprocess.x || content_blurpostprocess.x))
		{
			float blurradius = bound(0, damage_blurpostprocess.y + content_blurpostprocess.y, autocvar_hud_postprocessing_maxblurradius);
			float bluralpha = bound(0, damage_blurpostprocess.z + content_blurpostprocess.z, autocvar_hud_postprocessing_maxbluralpha);
			if(blurradius != old_blurradius || bluralpha != old_bluralpha) // reduce cvar_set spam as much as possible
			{
				cvar_set("r_glsl_postprocess_uservec1", strcat(ftos(blurradius), " ", ftos(bluralpha), " 0 0"));
				old_blurradius = blurradius;
				old_bluralpha = bluralpha;
			}
		}
		else if(cvar_string("r_glsl_postprocess_uservec1") != "0 0 0 0") // reduce cvar_set spam as much as possible
		{
			cvar_set("r_glsl_postprocess_uservec1", "0 0 0 0");
			old_blurradius = 0;
			old_bluralpha = 0;
		}

		// edge detection postprocess handling done second (used by hud_powerup)
		float sharpen_intensity = 0, strength_finished = STAT(STRENGTH_FINISHED), invincible_finished = STAT(INVINCIBLE_FINISHED);
		if (strength_finished - time > 0) { sharpen_intensity += (strength_finished - time); }
		if (invincible_finished - time > 0) { sharpen_intensity += (invincible_finished - time); }

		sharpen_intensity = bound(0, ((STAT(HEALTH) > 0) ? sharpen_intensity : 0), 5); // Check to see if player is alive (if not, set 0) - also bound to fade out starting at 5 seconds.

		if(autocvar_hud_powerup && sharpen_intensity > 0)
		{
			if(sharpen_intensity != old_sharpen_intensity) // reduce cvar_set spam as much as possible
			{
				cvar_set("r_glsl_postprocess_uservec2", strcat(ftos((sharpen_intensity / 5) * autocvar_hud_powerup), " ", ftos(-sharpen_intensity * autocvar_hud_powerup), " 0 0"));
				old_sharpen_intensity = sharpen_intensity;
			}
		}
		else if(cvar_string("r_glsl_postprocess_uservec2") != "0 0 0 0") // reduce cvar_set spam as much as possible
		{
			cvar_set("r_glsl_postprocess_uservec2", "0 0 0 0");
			old_sharpen_intensity = 0;
		}

		if(cvar("r_glsl_postprocess") == 0)
			cvar_set("r_glsl_postprocess", "2");
	}
	else if(cvar("r_glsl_postprocess") == 2)
		cvar_set("r_glsl_postprocess", "0");

	/*if(gametype == MAPINFO_TYPE_CTF)
	  {
	  ctf_view();
	  } else */

	// draw 2D entities
	FOREACH_ENTITY(it.draw2d, LAMBDA(WITH(entity, self, it, it.draw2d(it))));
	Draw_ShowNames_All();
	Debug_Draw();

	scoreboard_active = HUD_WouldDrawScoreboard();

	HUD_Draw();

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
		//setproperty(VF_VIEWPORT, '0 0 0', '640 480 0');
		//setproperty(VF_FOV, '90 90 0');
		setproperty(VF_ORIGIN, '0 0 0');
		setproperty(VF_ANGLES, '0 0 0');
		setproperty(VF_PERSPECTIVE, 1);
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
	else if ( HUD_MinigameMenu_IsOpened() || minigame_isactive() )
		HUD_Minigame_Mouse();
	else if(QuickMenu_IsOpened())
		QuickMenu_Mouse();
	else
		HUD_Radar_Mouse();

	cl_notice_run();
	unpause_update();
	Net_Flush();

	// let's reset the view back to normal for the end
	setproperty(VF_MIN, '0 0 0');
	setproperty(VF_SIZE, '1 0 0' * w + '0 1 0' * h);
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
		camera_offset.z += 30;
		camera_offset.x += 30 * -cos(current_angles.y * DEG2RAD);
		camera_offset.y += 30 * -sin(current_angles.y * DEG2RAD);
		current_origin = view_origin;
		current_camera_offset  = camera_offset;
		cvar_set("camera_reset", "0");
		camera_mode = CAMERA_CHASE;
	}

	// Camera angles
	if( camera_roll )
		mouse_angles.z += camera_roll * autocvar_camera_speed_roll;

	if(autocvar_camera_look_player)
	{
		vector dir;
		float n;

		dir = normalize(view_origin - current_position);
		n = mouse_angles.z;
		mouse_angles = vectoangles(dir);
		mouse_angles.x = mouse_angles.x * -1;
		mouse_angles.z = n;
	}
	else
	{
		tmp = getmousepos() * 0.1;
		if(vlen(tmp)>autocvar_camera_mouse_threshold)
		{
			mouse_angles.x += tmp.y * cos(mouse_angles.z * DEG2RAD) + (tmp.x * sin(mouse_angles.z * DEG2RAD));
			mouse_angles.y -= tmp.x * cos(mouse_angles.z * DEG2RAD) + (tmp.y * -sin(mouse_angles.z * DEG2RAD));
		}
	}

	while (mouse_angles.x < -180) mouse_angles.x = mouse_angles.x + 360;
	while (mouse_angles.x > 180) mouse_angles.x = mouse_angles.x - 360;
	while (mouse_angles.y < -180) mouse_angles.y = mouse_angles.y + 360;
	while (mouse_angles.y > 180) mouse_angles.y = mouse_angles.y - 360;

	// Fix difference when angles don't have the same sign
	delta = '0 0 0';
	if(mouse_angles.y < -60 && current_angles.y > 60)
		delta = '0 360 0';
	if(mouse_angles.y > 60 && current_angles.y < -60)
		delta = '0 -360 0';

	if(autocvar_camera_look_player)
		attenuation = autocvar_camera_look_attenuation;
	else
		attenuation = autocvar_camera_speed_attenuation;

	attenuation = 1 / max(1, attenuation);
	current_angles += (mouse_angles - current_angles + delta) * attenuation;

	while (current_angles.x < -180) current_angles.x = current_angles.x + 360;
	while (current_angles.x > 180) current_angles.x = current_angles.x - 360;
	while (current_angles.y < -180) current_angles.y = current_angles.y + 360;
	while (current_angles.y > 180) current_angles.y = current_angles.y - 360;

	// Camera position
	tmp = '0 0 0';
	dimensions = 0;

	if( camera_direction.x )
	{
		tmp.x = camera_direction.x * cos(current_angles.y * DEG2RAD);
		tmp.y = camera_direction.x * sin(current_angles.y * DEG2RAD);
		if( autocvar_camera_forward_follows && !autocvar_camera_look_player )
			tmp.z = camera_direction.x * -sin(current_angles.x * DEG2RAD);
		++dimensions;
	}

	if( camera_direction.y )
	{
		tmp.x += camera_direction.y * -sin(current_angles.y * DEG2RAD);
		tmp.y += camera_direction.y * cos(current_angles.y * DEG2RAD) * cos(current_angles.z * DEG2RAD);
		tmp.z += camera_direction.y * sin(current_angles.z * DEG2RAD);
		++dimensions;
	}

	if( camera_direction.z )
	{
		tmp.z += camera_direction.z * cos(current_angles.z * DEG2RAD);
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

	setproperty(VF_ANGLES, current_angles);
	setproperty(VF_ORIGIN, current_position);
}
