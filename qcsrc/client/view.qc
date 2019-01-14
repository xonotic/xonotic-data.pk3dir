#include "view.qh"

#include "autocvars.qh"
#include "miscfunctions.qh"
#include "announcer.qh"
#include "hud/_mod.qh"
#include "mapvoting.qh"
#include "shownames.qh"
#include "hud/panel/scoreboard.qh"
#include "hud/panel/quickmenu.qh"

#include <client/mutators/_mod.qh>

#include <common/animdecide.qh>
#include <common/deathtypes/all.qh>
#include <common/ent_cs.qh>
#include <common/anim.qh>
#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/net_notice.qh>
#include <common/debug.qh>
#include <common/mapinfo.qh>
#include <common/gamemodes/_mod.qh>
#include <common/physics/player.qh>
#include <common/stats.qh>
#include <common/mapobjects/target/music.qh>
#include <common/teams.qh>
#include <common/wepent.qh>

#include <common/weapons/weapon/tuba.qh>

#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <common/mutators/mutator/overkill/oknex.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/viewloc.qh>
#include <common/mapobjects/trigger/viewloc.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/minigames/cl_minigames_hud.qh>

#include <lib/csqcmodel/cl_player.qh>
#include <lib/csqcmodel/cl_model.qh>
#include "csqcmodel_hooks.qh"

#include <lib/warpzone/client.qh>
#include <lib/warpzone/common.qh>

#define EFMASK_CHEAP (EF_ADDITIVE | EF_DOUBLESIDED | EF_FULLBRIGHT | EF_NODEPTHTEST | EF_NODRAW | EF_NOSHADOW | EF_SELECTABLE | EF_TELEPORT_BIT)

float autocvar_cl_viewmodel_scale;
float autocvar_cl_viewmodel_alpha;

bool autocvar_cl_bobmodel;
float autocvar_cl_bobmodel_speed;
float autocvar_cl_bobmodel_side;
float autocvar_cl_bobmodel_up;

float autocvar_cl_followmodel;
float autocvar_cl_followmodel_speed = 0.3;
float autocvar_cl_followmodel_limit = 135;
float autocvar_cl_followmodel_velocity_lowpass = 0.05;
float autocvar_cl_followmodel_highpass = 0.05;
float autocvar_cl_followmodel_lowpass = 0.03;
bool autocvar_cl_followmodel_velocity_absolute;

float autocvar_cl_leanmodel;
float autocvar_cl_leanmodel_speed = 0.3;
float autocvar_cl_leanmodel_limit = 30;
float autocvar_cl_leanmodel_highpass1 = 0.2;
float autocvar_cl_leanmodel_highpass = 0.2;
float autocvar_cl_leanmodel_lowpass = 0.05;

#define avg_factor(avg_time) (1 - exp(-frametime / max(0.001, avg_time)))

#define lowpass(value, frac, ref_store, ret) \
	ret = ref_store = ref_store * (1 - frac) + (value) * frac;

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

#define lowpass2(value, frac, ref_store, ref_out) MACRO_BEGIN \
{ \
	lowpass(value.x, frac, ref_store.x, ref_out.x); \
	lowpass(value.y, frac, ref_store.y, ref_out.y); \
} MACRO_END

#define highpass2(value, frac, ref_store, ref_out) MACRO_BEGIN \
{ \
	highpass(value.x, frac, ref_store.x, ref_out.x); \
	highpass(value.y, frac, ref_store.y, ref_out.y); \
} MACRO_END

#define highpass2_limited(value, frac, limit, ref_store, ref_out) MACRO_BEGIN \
{ \
	highpass_limited(value.x, frac, limit, ref_store.x, ref_out.x); \
	highpass_limited(value.y, frac, limit, ref_store.y, ref_out.y); \
} MACRO_END

#define lowpass3(value, frac, ref_store, ref_out) MACRO_BEGIN \
{ \
	lowpass(value.x, frac, ref_store.x, ref_out.x); \
	lowpass(value.y, frac, ref_store.y, ref_out.y); \
	lowpass(value.z, frac, ref_store.z, ref_out.z); \
} MACRO_END

#define highpass3(value, frac, ref_store, ref_out) MACRO_BEGIN \
{ \
	highpass(value.x, frac, ref_store.x, ref_out.x); \
	highpass(value.y, frac, ref_store.y, ref_out.y); \
	highpass(value.z, frac, ref_store.z, ref_out.z); \
} MACRO_END

void calc_followmodel_ofs(entity view)
{
	if(cl_followmodel_time == time)
		return; // cl_followmodel_ofs already calculated for this frame

	float frac;
	vector gunorg = '0 0 0';
	static vector vel_average;
	static vector gunorg_adjustment_highpass;
	static vector gunorg_adjustment_lowpass;

	vector vel;
	if (autocvar_cl_followmodel_velocity_absolute)
		vel = view.velocity;
	else
	{
		vector forward = '0 0 0', right = '0 0 0', up = '0 0 0';
		MAKEVECTORS(makevectors, view_angles, forward, right, up);
		vel.x = view.velocity * forward;
		vel.y = view.velocity * right * -1;
		vel.z = view.velocity * up;
	}

	vel.x = bound(vel_average.x - autocvar_cl_followmodel_limit, vel.x, vel_average.x + autocvar_cl_followmodel_limit);
	vel.y = bound(vel_average.y - autocvar_cl_followmodel_limit, vel.y, vel_average.y + autocvar_cl_followmodel_limit);
	vel.z = bound(vel_average.z - autocvar_cl_followmodel_limit, vel.z, vel_average.z + autocvar_cl_followmodel_limit);

	frac = avg_factor(autocvar_cl_followmodel_velocity_lowpass);
	lowpass3(vel, frac, vel_average, gunorg);

	gunorg *= -autocvar_cl_followmodel_speed * 0.042;

	// perform highpass/lowpass on the adjustment vectors (turning velocity into acceleration!)
	// trick: we must do the lowpass LAST, so the lowpass vector IS the final vector!
	frac = avg_factor(autocvar_cl_followmodel_highpass);
	highpass3(gunorg, frac, gunorg_adjustment_highpass, gunorg);
	frac = avg_factor(autocvar_cl_followmodel_lowpass);
	lowpass3(gunorg, frac, gunorg_adjustment_lowpass, gunorg);

	if (autocvar_cl_followmodel_velocity_absolute)
	{
		vector fixed_gunorg;
		vector forward = '0 0 0', right = '0 0 0', up = '0 0 0';
		MAKEVECTORS(makevectors, view_angles, forward, right, up);
		fixed_gunorg.x = gunorg * forward;
		fixed_gunorg.y = gunorg * right * -1;
		fixed_gunorg.z = gunorg * up;
		gunorg = fixed_gunorg;
	}

	cl_followmodel_ofs = gunorg;
	cl_followmodel_time = time;
}

vector leanmodel_ofs(entity view)
{
	float frac;
	vector gunangles = '0 0 0';
	static vector gunangles_prev = '0 0 0';
	static vector gunangles_highpass = '0 0 0';
	static vector gunangles_adjustment_highpass;
	static vector gunangles_adjustment_lowpass;

	if (view.csqcmodel_teleported)
		gunangles_prev = view_angles;

	// in the highpass, we _store_ the DIFFERENCE to the actual view angles...
	gunangles_highpass += gunangles_prev;
	PITCH(gunangles_highpass) += 360 * floor((PITCH(view_angles) - PITCH(gunangles_highpass)) / 360 + 0.5);
	YAW(gunangles_highpass) += 360 * floor((YAW(view_angles) - YAW(gunangles_highpass)) / 360 + 0.5);
	ROLL(gunangles_highpass) += 360 * floor((ROLL(view_angles) - ROLL(gunangles_highpass)) / 360 + 0.5);
	frac = avg_factor(autocvar_cl_leanmodel_highpass1);
	highpass2_limited(view_angles, frac, autocvar_cl_leanmodel_limit, gunangles_highpass, gunangles);
	gunangles_prev = view_angles;
	gunangles_highpass -= gunangles_prev;

	PITCH(gunangles) *= -autocvar_cl_leanmodel_speed;
	YAW(gunangles) *= -autocvar_cl_leanmodel_speed;

	// we assume here: PITCH = 0, YAW = 1, ROLL = 2
	frac = avg_factor(autocvar_cl_leanmodel_highpass);
	highpass2(gunangles, frac, gunangles_adjustment_highpass, gunangles);
	frac = avg_factor(autocvar_cl_leanmodel_lowpass);
	lowpass2(gunangles, frac, gunangles_adjustment_lowpass, gunangles);

	gunangles.x = -gunangles.x; // pitch was inverted, now that actually matters

	return gunangles;
}

vector bobmodel_ofs(entity view)
{
	bool clonground = !(view.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
	static bool oldonground;
	static float hitgroundtime;
	if (clonground)
	{
		float f = time; // cl.movecmd[0].time
		if (!oldonground)
			hitgroundtime = f;
	}
	oldonground = clonground;

	// calculate for swinging gun model
	// the gun bobs when running on the ground, but doesn't bob when you're in the air.
	vector gunorg = '0 0 0';
	static float bobmodel_scale = 0;
	static float time_ofs = 0; // makes the effect always restart in the same way
	if (clonground)
	{
		if (time - hitgroundtime > 0.05)
			bobmodel_scale = min(1, bobmodel_scale + frametime * 5);
	}
	else
		bobmodel_scale = max(0, bobmodel_scale - frametime * 5);

	float xyspeed = bound(0, vlen(vec2(view.velocity)), 400);
	if (bobmodel_scale && xyspeed)
	{
		float bspeed = xyspeed * 0.01 * autocvar_cl_viewmodel_scale * bobmodel_scale;
		float s = (time - time_ofs) * autocvar_cl_bobmodel_speed;
		gunorg.y = bspeed * autocvar_cl_bobmodel_side * sin(s);
		gunorg.z = bspeed * autocvar_cl_bobmodel_up * cos(s * 2);
	}
	else
		time_ofs = time;

	return gunorg;
}

void viewmodel_animate(entity this)
{
	if (autocvar_chase_active) return;
	if (STAT(HEALTH) <= 0) return;

	entity view = CSQCModel_server2csqc(player_localentnum - 1);

	if (autocvar_cl_followmodel)
	{
		calc_followmodel_ofs(view);
		this.origin += cl_followmodel_ofs;
	}

	if (autocvar_cl_leanmodel)
		this.angles += leanmodel_ofs(view);

	// vertical view bobbing code
	// TODO: cl_bob

	// horizontal view bobbing code
	// TODO: cl_bob2

	// fall bobbing code
	// causes the view to swing down and back up when touching the ground
	// TODO: cl_bobfall

	// gun model bobbing code
	if (autocvar_cl_bobmodel)
		this.origin += bobmodel_ofs(view);
}

.vector viewmodel_origin, viewmodel_angles;
.float weapon_nextthink;
.float weapon_eta_last;
.float weapon_switchdelay;

.string name_last;

void viewmodel_draw(entity this)
{
	if(!this.activeweapon || !autocvar_r_drawviewmodel)
		return;
	int mask = (intermission || (STAT(HEALTH) <= 0) || autocvar_chase_active) ? 0 : MASK_NORMAL;
	float a = ((autocvar_cl_viewmodel_alpha) ? bound(-1, autocvar_cl_viewmodel_alpha, this.m_alpha) : this.m_alpha);
	bool invehicle = player_localentnum > maxclients;
	if (invehicle) a = -1;
	Weapon wep = this.activeweapon;
	int c = entcs_GetClientColors(current_player);
	vector g = weaponentity_glowmod(wep, NULL, c, this);
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
		CSQCModel_Effects_Apply(e);
	}
	if(a >= 0)
	{
		string name = wep.mdl;
		string newname = wep.wr_viewmodel(wep, this);
		if(newname)
			name = newname;
		bool swap = name != this.name_last;
		// if (swap)
		{
			this.name_last = name;
			CL_WeaponEntity_SetModel(this, name, swap);
			this.viewmodel_origin = this.origin;
			this.viewmodel_angles = this.angles;
		}
		anim_update(this);
		if ((!this.animstate_override && !this.animstate_looping) || time > this.animstate_endtime)
			anim_set(this, this.anim_idle, true, false, false);
	}
	float f = 0; // 0..1; 0: fully active
	float rate = STAT(WEAPONRATEFACTOR);
	float eta = rate ? ((this.weapon_nextthink - time) / rate) : 0;
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
	MUTATOR_CALLHOOK(DrawViewModel, this);
	setorigin(this, this.origin);
}

STATIC_INIT(viewmodel) {
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    	viewmodels[slot] = new(viewmodel);
}

float showfps_prevfps;
float showfps_prevfps_time;
int showfps_framecounter;

void fpscounter_update()
{
	if(!STAT(SHOWFPS))
		return;

	float currentTime = gettime(GETTIME_REALTIME);
	showfps_framecounter += 1;
	if(currentTime - showfps_prevfps_time > STAT(SHOWFPS))
	{
		showfps_prevfps = showfps_framecounter/(currentTime - showfps_prevfps_time);
		showfps_framecounter = 0;
		showfps_prevfps_time = currentTime;

		int channel = MSG_C2S;
		WriteHeader(channel, fpsreport);
		WriteShort(channel, bound(0, rint(showfps_prevfps), 65535)); // prevent insane fps values
	}
}

STATIC_INIT(fpscounter_init)
{
	float currentTime = gettime(GETTIME_REALTIME);
	showfps_prevfps_time = currentTime; // we must initialize it to avoid an instant low frame sending
}

STATIC_INIT(Porto)
{
	entity e = new_pure(porto);
	e.draw = Porto_Draw;
	IL_PUSH(g_drawables, e);
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

const int polyline_length = 16;
.vector polyline[polyline_length];
void Porto_Draw(entity this)
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wepent = viewmodels[slot];

		if (wepent.activeweapon != WEP_PORTO) continue;
		if (spectatee_status) continue;
		if (WEP_CVAR(porto, secondary)) continue;
		if (intermission == 1) continue;
		if (intermission == 2) continue;
		if (STAT(HEALTH) <= 0) continue;

		vector pos = view_origin;
		vector dir = view_forward;
		makevectors(((autocvar_chase_active) ? warpzone_save_view_angles : view_angles));
		pos += v_right * -wepent.movedir.y
			+  v_up * wepent.movedir.z;

		if (wepent.angles_held_status)
		{
			makevectors(wepent.angles_held);
			dir = v_forward;
		}

		wepent.polyline[0] = pos;

		int portal_number = 0, portal1_idx = 1, portal_max = 2;
		int n = 1 + 2;  // 2 lines == 3 points
		for (int idx = 0; idx < n && idx < polyline_length - 1; )
		{
			traceline(pos, pos + 65536 * dir, true, this);
			dir = reflect(dir, trace_plane_normal);
			pos = trace_endpos;
			wepent.polyline[++idx] = pos;
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			{
				n += 1;
				continue;
			}
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			{
				n = max(2, idx);
				break;
			}
			// check size
			{
				vector ang = vectoangles2(trace_plane_normal, dir);
				ang.x = -ang.x;
				makevectors(ang);
				if (!CheckWireframeBox(this, pos - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
				{
					n = max(2, idx);
					break;
				}
			}
			portal_number += 1;
			if (portal_number >= portal_max) break;
			if (portal_number == 1) portal1_idx = idx;
		}
		for (int idx = 0; idx < n - 1; ++idx)
		{
			vector p = wepent.polyline[idx], q = wepent.polyline[idx + 1];
			if (idx == 0) p -= view_up * 16;  // line from player
			vector rgb = (idx < portal1_idx) ? '1 0 0' : '0 0 1';
			Draw_CylindricLine(p, q, 4, "", 1, 0, rgb, 0.5, DRAWFLAG_NORMAL, view_origin);
		}
	}
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
	if (zoomspeed >= 0 && (zoomspeed < 0.5 || zoomspeed > 16))
		zoomspeed = 3.5;

	zoomdir = button_zoom;

	if(hud == HUD_NORMAL && !spectatee_status)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			entity wepent = viewmodels[slot];
			if(wepent.switchweapon != wepent.activeweapon)
				continue;
			Weapon wep = wepent.activeweapon;
			if(wep != WEP_Null && wep.wr_zoomdir)
			{
				bool do_zoom = wep.wr_zoomdir(wep); // TODO: merge this with wr_zoom?
				zoomdir += do_zoom;
			}
		}
	}
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

	if (spectatee_status > 0 && STAT(CAMERA_SPECTATOR) == 2)
	{
		current_viewzoom = 1;
	}
	else if (camera_active)
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
		setsensitivityscale(current_viewzoom ** (1 - zoomsensitivity));
	else
		setsensitivityscale(1);

	if(autocvar_cl_velocityzoom_enabled && autocvar_cl_velocityzoom_type) // _type = 0 disables velocity zoom too
	{
		if (intermission || (spectatee_status > 0 && STAT(CAMERA_SPECTATOR) == 2))
			curspeed = 0;
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

bool minigame_wasactive;

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
	(trueaim = new_pure(trueaim)).dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	(trueaim_rifle = new_pure(trueaim_rifle)).dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
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

float TrueAimCheck(entity wepent)
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

	switch(wepent.activeweapon) // WEAPONTODO
	{
		case WEP_TUBA: // no aim
		case WEP_PORTO: // shoots from eye
		case WEP_NEXBALL: // shoots from eye
		case WEP_HOOK: // no trueaim
		case WEP_MORTAR: // toss curve
			return SHOTTYPE_HITWORLD;
		case WEP_VORTEX:
		case WEP_OVERKILL_NEX:
		case WEP_VAPORIZER:
			mv = MOVE_NORMAL;
			break;
		case WEP_RIFLE:
			ta = trueaim_rifle;
			mv = MOVE_NORMAL;
			if(zoomscript_caught)
			{
				tracebox(view_origin, '0 0 0', '0 0 0', view_origin + view_forward * max_shot_distance, mv, ta);
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

	traceline(traceorigin, traceorigin + view_forward * max_shot_distance, mv, ta);
	trueaimpoint = trace_endpos;

	if(vdist((trueaimpoint - traceorigin), <, g_trueaim_minrange))
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

float camera_mode;
const float CAMERA_FREE = 1;
const float CAMERA_CHASE = 2;
float reticle_type;
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
int WantEventchase(entity this)
{
	if(autocvar_cl_orthoview)
		return 0;
	if(STAT(GAME_STOPPED) || intermission)
		return 1;
	if(this.viewloc)
		return 1;
	if(spectatee_status >= 0)
	{
		if(hud != HUD_NORMAL && (autocvar_cl_eventchase_vehicle || spectatee_status > 0))
			return 1;
		if(MUTATOR_CALLHOOK(WantEventchase, this))
			return 1;
		if(autocvar_cl_eventchase_frozen && STAT(FROZEN))
			return 1;
		if(autocvar_cl_eventchase_death && (STAT(HEALTH) <= 0))
		{
			if(autocvar_cl_eventchase_death == 2)
			{
				// don't stop eventchase once it's started (even if velocity changes afterwards)
				if(this.velocity == '0 0 0' || eventchase_running)
					return 1;
			}
			else return 1;
		}
		if (spectatee_status > 0 && autocvar_cl_eventchase_spectated_change)
		{
			if (time <= spectatee_status_changed_time + min(3, autocvar_cl_eventchase_spectated_change_time))
				return 1;
			else if (eventchase_running)
				return -1; // disable chase_active while eventchase is still enabled so to avoid a glicth
		}
	}
	return 0;
}

void HUD_Crosshair_Vehicle(entity this)
{
	if(hud != HUD_BUMBLEBEE_GUN)
	{
		Vehicle info = Vehicles_from(hud);
		info.vr_crosshair(info, this);
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
		LOG_TRACE("dmg total: ", ftos(unaccounted_damage), " (+", ftos(unaccounted_damage_new), ")");
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

	bool have_arc = false;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wepent = viewmodels[slot];

		if(wepent.activeweapon == WEP_ARC)
			have_arc = true;
	}

	static float hitsound_time_prev = 0;
	// HACK: the only way to get the arc to sound consistent with pitch shift is to ignore cl_hitsound_antispam_time
	bool arc_hack = have_arc && autocvar_cl_hitsound >= 2;
	if (arc_hack || COMPARE_INCREASING(time, hitsound_time_prev) > autocvar_cl_hitsound_antispam_time)
	{
		if (autocvar_cl_hitsound && unaccounted_damage)
		{
			// customizable gradient function that crosses (0,a), (c,1) and asymptotically approaches b
			float a = autocvar_cl_hitsound_max_pitch;
			float b = autocvar_cl_hitsound_min_pitch;
			float c = autocvar_cl_hitsound_nom_damage;
			float d = unaccounted_damage;
			float pitch_shift = (b*d*(a-1) + a*c*(1-b)) / (d*(a-1) + c*(1-b));

			// if sound variation is disabled, set pitch_shift to 1
			if (autocvar_cl_hitsound == 1)
				pitch_shift = 1;

			// if pitch shift is reversed, mirror in (max-min)/2 + min
			if (autocvar_cl_hitsound == 3)
			{
				float mirror_value = (a-b)/2 + b;
				pitch_shift = mirror_value + (mirror_value - pitch_shift);
			}

			LOG_TRACE("dmg total (dmg): ", ftos(unaccounted_damage), " , pitch shift: ", ftos(pitch_shift));

			// todo: avoid very long and very short sounds from wave stretching using different sound files? seems unnecessary
			// todo: normalize sound pressure levels? seems unnecessary

			sound7(NULL, CH_INFO, SND(HIT), VOL_BASE, ATTN_NONE, pitch_shift * 100, 0);
		}
		unaccounted_damage = 0;
		hitsound_time_prev = time;
	}

	static float typehit_time_prev = 0;
	float typehit_time = STAT(TYPEHIT_TIME);
	if (COMPARE_INCREASING(typehit_time, typehit_time_prev) > autocvar_cl_hitsound_antispam_time)
	{
		sound(NULL, CH_INFO, SND_TYPEHIT, VOL_BASE, ATTN_NONE);
		typehit_time_prev = typehit_time;
	}

	static float kill_time_prev = 0;
	float kill_time = STAT(KILL_TIME);
	if (COMPARE_INCREASING(kill_time, kill_time_prev) > autocvar_cl_hitsound_antispam_time)
	{
		sound(NULL, CH_INFO, SND_KILL, VOL_BASE, ATTN_NONE);
		kill_time_prev = kill_time;
	}
}

vector crosshair_getcolor(entity this, float health_stat)
{
	static float rainbow_last_flicker;
	static vector rainbow_prev_color;
	vector wcross_color = '0 0 0';
	switch(autocvar_crosshair_color_special)
	{
		case 1: // crosshair_color_per_weapon
		{
			if(this != WEP_Null && hud == HUD_NORMAL)
			{
				wcross_color = this.wpcolor;
				break;
			}
			else { goto normalcolor; }
		}

		case 2: // crosshair_color_by_health
		{
			vector v = healtharmor_maxdamage(health_stat, STAT(ARMOR), armorblockpercent, DEATH_WEAPON.m_id);
			float hp = floor(v.x + 1);

			//x = red
			//y = green
			//z = blue

			wcross_color.z = 0;

			if(hp > 200)
			{
				wcross_color.x = 0;
				wcross_color.y = 1;
			}
			else if(hp > 150)
			{
				wcross_color.x = 0.4 - (hp-150)*0.02 * 0.4;
				wcross_color.y = 0.9 + (hp-150)*0.02 * 0.1;
			}
			else if(hp > 100)
			{
				wcross_color.x = 1 - (hp-100)*0.02 * 0.6;
				wcross_color.y = 1 - (hp-100)*0.02 * 0.1;
				wcross_color.z = 1 - (hp-100)*0.02;
			}
			else if(hp > 50)
			{
				wcross_color.x = 1;
				wcross_color.y = 1;
				wcross_color.z = 0.2 + (hp-50)*0.02 * 0.8;
			}
			else if(hp > 20)
			{
				wcross_color.x = 1;
				wcross_color.y = (hp-20)*90/27/100;
				wcross_color.z = (hp-20)*90/27/100 * 0.2;
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
LABEL(normalcolor)
		default: { wcross_color = stov(autocvar_crosshair_color); break; }
	}

	return wcross_color;
}

void HUD_Crosshair(entity this)
{
	float f, i, j;
	vector v;
	if(!scoreboard_active && !camera_active && intermission != 2 && !STAT(GAME_STOPPED) &&
		spectatee_status != -1 && (!csqcplayer.viewloc || (!spectatee_status && (csqcplayer.viewloc.spawnflags & VIEWLOC_FREEAIM))) && !MUTATOR_CALLHOOK(DrawCrosshair) &&
		!HUD_MinigameMenu_IsOpened() )
	{
		if (!autocvar_crosshair_enabled) // main toggle for crosshair rendering
			return;

		if (spectatee_status > 0 && STAT(CAMERA_SPECTATOR) == 2)
			return;

		if (hud != HUD_NORMAL)
		{
			HUD_Crosshair_Vehicle(this);
			return;
		}

		string wcross_style;
		float wcross_alpha, wcross_resolution;
		wcross_style = autocvar_crosshair;
		if (csqcplayer.viewloc && (csqcplayer.viewloc.spawnflags & VIEWLOC_FREEAIM) && autocvar_crosshair_2d != "")
			wcross_style = autocvar_crosshair_2d;
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
		if(csqcplayer.viewloc && (csqcplayer.viewloc.spawnflags & VIEWLOC_FREEAIM))
			wcross_origin = viewloc_mousepos;
		else
			wcross_origin = project_3d_to_2d(view_origin + max_shot_distance * view_forward);
		wcross_origin.z = 0;
		if(autocvar_crosshair_hittest)
		{
			vector wcross_oldorigin;
			entity thiswep = viewmodels[0]; // TODO: unhardcode
			wcross_oldorigin = wcross_origin;
			shottype = TrueAimCheck(thiswep);
			if(shottype == SHOTTYPE_HITWORLD)
			{
				v = wcross_origin - wcross_oldorigin;
				v.x /= vid_conwidth;
				v.y /= vid_conheight;
				if(vdist(v, >, 0.01))
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

        entity e = WEP_Null;
		if(autocvar_crosshair_per_weapon || (autocvar_crosshair_color_special == 1))
		{
			entity wepent = viewmodels[0]; // TODO: unhardcode
			e = wepent.switchingweapon;
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
		wcross_color = crosshair_getcolor(e, STAT(HEALTH));

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

				entity wepent = viewmodels[0]; // TODO: unhardcode

				int weapon_clipload = wepent.clip_load;
				int weapon_clipsize = wepent.clip_size;

				float arc_heat = wepent.arc_heat_percent;
				float vcharge = wepent.vortex_charge;
				float vchargepool = wepent.vortex_chargepool_ammo;
				float oknex_charge_ = wepent.oknex_charge;
				float oknex_chargepool_ = wepent.oknex_chargepool_ammo;

				if(vortex_charge_movingavg == 0) // this should only happen if we have just loaded up the game
					vortex_charge_movingavg = vcharge;

				// handle the values
				if (autocvar_crosshair_ring && wepent.activeweapon == WEP_VORTEX && vcharge && autocvar_crosshair_ring_vortex) // ring around crosshair representing velocity-dependent damage for the vortex
				{
					if (vchargepool || use_vortex_chargepool) {
						use_vortex_chargepool = 1;
						ring_inner_value = vchargepool;
					} else {
						vortex_charge_movingavg = (1 - autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate) * vortex_charge_movingavg + autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate * vcharge;
						ring_inner_value = bound(0, autocvar_crosshair_ring_vortex_currentcharge_scale * (vcharge - vortex_charge_movingavg), 1);
					}

					ring_inner_alpha = autocvar_crosshair_ring_vortex_inner_alpha;
					ring_inner_rgb = vec3(autocvar_crosshair_ring_vortex_inner_color_red, autocvar_crosshair_ring_vortex_inner_color_green, autocvar_crosshair_ring_vortex_inner_color_blue);
					ring_inner_image = "gfx/crosshair_ring_inner.tga";

					// draw the outer ring to show the current charge of the weapon
					ring_value = vcharge;
					ring_alpha = autocvar_crosshair_ring_vortex_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring_nexgun.tga";
				}
				else if (autocvar_crosshair_ring && (wepent.activeweapon == WEP_OVERKILL_NEX) && oknex_charge_ && autocvar_crosshair_ring_vortex)
				{
					if (oknex_chargepool_ || use_vortex_chargepool) {
						use_vortex_chargepool = 1;
						ring_inner_value = oknex_chargepool_;
					} else {
						vortex_charge_movingavg = (1 - autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate) * vortex_charge_movingavg + autocvar_crosshair_ring_vortex_currentcharge_movingavg_rate * oknex_charge_;
						ring_inner_value = bound(0, autocvar_crosshair_ring_vortex_currentcharge_scale * (oknex_charge_ - vortex_charge_movingavg), 1);
					}

					ring_inner_alpha = autocvar_crosshair_ring_vortex_inner_alpha;
					ring_inner_rgb = eX * autocvar_crosshair_ring_vortex_inner_color_red + eY * autocvar_crosshair_ring_vortex_inner_color_green + eZ * autocvar_crosshair_ring_vortex_inner_color_blue;
					ring_inner_image = "gfx/crosshair_ring_inner.tga";

					// draw the outer ring to show the current charge of the weapon
					ring_value = oknex_charge_;
					ring_alpha = autocvar_crosshair_ring_vortex_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring_nexgun.tga";
				}
				else if (autocvar_crosshair_ring && wepent.activeweapon == WEP_MINE_LAYER && WEP_CVAR(minelayer, limit) && autocvar_crosshair_ring_minelayer)
				{
					ring_value = bound(0, wepent.minelayer_mines / WEP_CVAR(minelayer, limit), 1); // if you later need to use the count of bullets in another place, then add a float for it. For now, no need to.
					ring_alpha = autocvar_crosshair_ring_minelayer_alpha;
					ring_rgb = wcross_color;
					ring_image = "gfx/crosshair_ring.tga";
				}
				else if (wepent.activeweapon == WEP_HAGAR && wepent.hagar_load && autocvar_crosshair_ring_hagar)
				{
					ring_value = bound(0, wepent.hagar_load / WEP_CVAR_SEC(hagar, load_max), 1);
					ring_alpha = autocvar_crosshair_ring_hagar_alpha;
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
					if ((wepent.activeweapon == WEP_RIFLE) && (weapon_clipsize == 80))
						ring_image = "gfx/crosshair_ring_rifle.tga";
					else
						ring_image = "gfx/crosshair_ring.tga";
				}
				else if ( autocvar_crosshair_ring && autocvar_crosshair_ring_arc && arc_heat && wepent.activeweapon == WEP_ARC )
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
				vector scaled_sz = sz * wcross_size; \
				if(wcross_blur > 0) \
				{ \
					for(i = -2; i <= 2; ++i) \
					for(j = -2; j <= 2; ++j) \
					M(i,j,sz,scaled_sz,wcross_name,wcross_alpha*0.04); \
				} \
				else \
				{ \
					M(0,0,sz,scaled_sz,wcross_name,wcross_alpha); \
				} \
			} MACRO_END

#define CROSSHAIR_DRAW_SINGLE(i,j,sz,scaled_sz,wcross_name,wcross_alpha) \
			drawpic(wcross_origin - ('0.5 0 0' * (scaled_sz.x + i * wcross_blur) + '0 0.5 0' * (scaled_sz.y + j * wcross_blur)), wcross_name, scaled_sz, wcross_color, wcross_alpha, DRAWFLAG_NORMAL)

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
		strfree(wcross_name_goal_prev);
		strfree(wcross_name_goal_prev_prev);
		wcross_name_changestarttime = 0;
		wcross_name_changedonetime = 0;
		wcross_name_alpha_goal_prev = 0;
		wcross_name_alpha_goal_prev_prev = 0;
		wcross_resolution_goal_prev = 0;
		wcross_resolution_goal_prev_prev = 0;
	}
}

const int MAX_SPECIALCOMMAND = 15;
vector specialcommand_slots[MAX_SPECIALCOMMAND];
vector specialcommand_colors[MAX_SPECIALCOMMAND];
const float SPECIALCOMMAND_SPEED = 150;
const float SPECIALCOMMAND_TURNSPEED = 2;
const float SPECIALCOMMAND_SIZE = 0.025;
const float SPECIALCOMMAND_CHANCE = 0.35;
float sc_spawntime, sc_changetime;
vector sc_color = '1 1 1';
void SpecialCommand()
{
	if(!STAT(MOVEVARS_SPECIALCOMMAND))
		return;

	if(time >= sc_changetime)
	{
		sc_changetime = time + 1;
		sc_color = randomvec() * 1.5;
		sc_color.x = bound(0.2, sc_color.x, 0.75);
		sc_color.y = bound(0.2, sc_color.y, 0.75);
		sc_color.z = bound(0.2, sc_color.z, 0.75);
	}
	drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), sc_color, autocvar_hud_colorflash_alpha * bound(0.1, sc_changetime - time, 0.3), DRAWFLAG_ADDITIVE);

	if(!precache_pic("gfx/smile"))
		return; // damn party poopers

	for(int j = MAX_SPECIALCOMMAND - 1; j >= 0; --j)
	{
		vector slot = specialcommand_slots[j];
		if(slot.y)
			slot.y += SPECIALCOMMAND_SPEED * frametime;
		//if(slot.z)
			//slot.z = sin(SPECIALCOMMAND_TURNSPEED * M_PI * time);
		if(slot.y >= vid_conheight)
			slot = '0 0 0';

		if(slot == '0 0 0')
		{
			if(random() <= SPECIALCOMMAND_CHANCE && time > sc_spawntime) // low chance to spawn!
			{
				slot.x = bound(0, (random() * vid_conwidth + 1), vid_conwidth);
				slot.y = 1; // start it off 0 so we can use it
				slot.z = floor(random() * Weapons_MAX);
				sc_spawntime = time + bound(0.4, random(), 0.75); // prevent spawning another one for this amount of time!
				vector newcolor = randomvec() * 2;
				newcolor.x = bound(0.4, newcolor.x, 1);
				newcolor.y = bound(0.4, newcolor.y, 1);
				newcolor.z = bound(0.4, newcolor.z, 1);
				specialcommand_colors[j] = newcolor;
			}
		}
		else
		{
			vector splash_size = '0 0 0';
			splash_size.x = max(vid_conwidth, vid_conheight) * SPECIALCOMMAND_SIZE;
			splash_size.y = max(vid_conwidth, vid_conheight) * SPECIALCOMMAND_SIZE;
			entity wep = Weapons_from(slot.z);
			if(wep == WEP_Null)
				drawpic(vec2(slot), "gfx/smile", vec2(splash_size), specialcommand_colors[j], 0.95, DRAWFLAG_NORMAL);
			else
				drawpic_skin(vec2(slot), wep.model2, vec2(splash_size), specialcommand_colors[j], 0.95, DRAWFLAG_NORMAL);
			//drawrotpic(vec2(slot), slot.z, "gfx/smile", vec2(splash_size), vec2(splash_size) / 2, specialcommand_colors[j], 0.95, DRAWFLAG_NORMAL);
		}

		specialcommand_slots[j] = slot;
	}
}

void HUD_Draw(entity this)
{
	// if we don't know gametype and scores yet avoid drawing the scoreboard
	// also in the very first frames, player state may be inconsistent so avoid drawing the hud at all
	// e.g. since initial player's health is 0 hud would display the hud_damage effect,
	// cl_deathscoreboard would show the scoreboard and so on
	if(!gametype)
		return;

	Hud_Dynamic_Frame();

	if(!intermission)
	if (MUTATOR_CALLHOOK(HUD_Draw_overlay))
	{
		drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), M_ARGV(0, vector), autocvar_hud_colorflash_alpha * M_ARGV(1, float), DRAWFLAG_ADDITIVE);
	}
	else if(STAT(FROZEN))
	{
		vector col = '0.25 0.90 1';
		if(STAT(REVIVE_PROGRESS))
			col += vec3(STAT(REVIVE_PROGRESS), -STAT(REVIVE_PROGRESS), -STAT(REVIVE_PROGRESS));
		drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), col, autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
	}

	HUD_Scale_Enable();
	if(!intermission)
	if(STAT(NADE_TIMER) && autocvar_cl_nade_timer) // give nade top priority, as it's a matter of life and death
	{
		vector col = '0.25 0.90 1' + vec3(STAT(NADE_TIMER), -STAT(NADE_TIMER), -STAT(NADE_TIMER));
		DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring.tga", STAT(NADE_TIMER), col, autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
		drawstring_aspect(eY * 0.64 * vid_conheight, ((autocvar_cl_nade_timer == 2) ? _("Nade timer") : ""), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	else if(STAT(CAPTURE_PROGRESS))
	{
		DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring.tga", STAT(CAPTURE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
		drawstring_aspect(eY * 0.64 * vid_conheight, _("Capture progress"), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	else if(STAT(REVIVE_PROGRESS))
	{
		DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring.tga", STAT(REVIVE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
		drawstring_aspect(eY * 0.64 * vid_conheight, _("Revival progress"), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	HUD_Scale_Disable();

	if(autocvar_r_letterbox == 0)
		if(autocvar_viewsize < 120)
		{
			if(!(ISGAMETYPE(RACE) || ISGAMETYPE(CTS)))
				Accuracy_LoadLevels();

			HUD_Main();
			HUD_Scale_Disable();
		}

	// crosshair goes VERY LAST
	SpecialCommand();
	UpdateDamage();
	HUD_Crosshair(this);
	HitSound();
}

void ViewLocation_Mouse()
{
	if(spectatee_status)
		return; // don't draw it as spectator!

	viewloc_mousepos += getmousepos() * autocvar_menu_mouse_speed;
	viewloc_mousepos.x = bound(0, viewloc_mousepos.x, vid_conwidth);
	viewloc_mousepos.y = bound(0, viewloc_mousepos.y, vid_conheight);

	//float cursor_alpha = 1 - autocvar__menu_alpha;
	//draw_cursor(viewloc_mousepos, '0.5 0.5 0', "/cursor_move", '1 1 1', cursor_alpha);
}

void HUD_Cursor_Show()
{
	float cursor_alpha = 1 - autocvar__menu_alpha;
	if(cursor_type == CURSOR_NORMAL)
		draw_cursor_normal(mousepos, '1 1 1', cursor_alpha);
	else if(cursor_type == CURSOR_MOVE)
		draw_cursor(mousepos, '0.5 0.5 0', "/cursor_move", '1 1 1', cursor_alpha);
	else if(cursor_type == CURSOR_RESIZE)
		draw_cursor(mousepos, '0.5 0.5 0', "/cursor_resize", '1 1 1', cursor_alpha);
	else if(cursor_type == CURSOR_RESIZE2)
		draw_cursor(mousepos, '0.5 0.5 0', "/cursor_resize2", '1 1 1', cursor_alpha);
}

void HUD_Mouse(entity player)
{
	if(autocvar__menu_alpha == 1)
		return;

	if(!cursor_active)
	{
		if(player.viewloc && (player.viewloc.spawnflags & VIEWLOC_FREEAIM))
			ViewLocation_Mouse(); // NOTE: doesn't use cursormode
		return;
	}

	if (cursor_active == -1) // starting to display the cursor
	{
		// since HUD_Mouse is called by CSQC_UpdateView before CSQC_InputEvent,
		// in the first frame mousepos is the mouse position of the last time
		// the cursor was displayed, thus we ignore it to avoid a glictch
		cursor_active = 1;
		return;
	}

	if(!autocvar_hud_cursormode)
		update_mousepos();

	if(autocvar__hud_configure)
		HUD_Panel_Mouse();
	else
	{
		if (HUD_MinigameMenu_IsOpened())
			HUD_Minigame_Mouse();
		if (QuickMenu_IsOpened())
			QuickMenu_Mouse();
		if (HUD_Radar_Clickable())
			HUD_Radar_Mouse();
	}

	prevMouseClicked = mouseClicked;

	HUD_Cursor_Show();
}

bool ov_enabled;
float oldr_nearclip;
float oldr_farclip_base;
float oldr_farclip_world;
float oldr_novis;
float oldr_useportalculling;
float oldr_useinfinitefarclip;

float prev_myteam;
int lasthud;
float vh_notice_time;
void CSQC_UpdateView(entity this, float w, float h)
{
	TC(int, w); TC(int, h);
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

	HUD_Scale_Disable();

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

	button_attack2 = PHYS_INPUT_BUTTON_ATCK2(this);
	button_zoom = PHYS_INPUT_BUTTON_ZOOM(this);

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
		FOREACH(hud_panels, true, it.update_time = time);
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

	// abused multiple places below
	entity local_player = ((csqcplayer) ? csqcplayer : CSQCModel_server2csqc(player_localentnum - 1));
	if(!local_player)
		local_player = this; // fall back!

	// event chase camera
	if(autocvar_chase_active <= 0) // greater than 0 means it's enabled manually, and this code is skipped
	{
		if(STAT(CAMERA_SPECTATOR))
		{
			if(spectatee_status > 0)
			{
				if(!autocvar_chase_active)
				{
					cvar_set("chase_active", "-2");
					goto skip_eventchase_death;
				}
			}
			else if(autocvar_chase_active == -2)
				cvar_set("chase_active", "0");

			if(autocvar_chase_active == -2)
				goto skip_eventchase_death;
		}
		else if(autocvar_chase_active == -2)
			cvar_set("chase_active", "0");

		float vehicle_chase = (hud != HUD_NORMAL && (autocvar_cl_eventchase_vehicle || spectatee_status > 0));

		float vehicle_viewdist = 0;
		vector vehicle_viewofs = '0 0 0';

		if(vehicle_chase)
		{
			if(hud != HUD_BUMBLEBEE_GUN)
			{
				Vehicle info = Vehicles_from(hud);
				vehicle_viewdist = info.height;
				vehicle_viewofs = info.view_ofs;
			}
		}

		int eventchase = WantEventchase(this);
		if (eventchase)
		{
			vector current_view_origin_override = '0 0 0';
			vector view_offset_override = '0 0 0';
			float chase_distance_override = 0;
			bool custom_eventchase = MUTATOR_CALLHOOK(CustomizeEventchase, this);
			if(custom_eventchase)
			{
				current_view_origin_override = M_ARGV(0, vector);
				view_offset_override = M_ARGV(1, vector);
				chase_distance_override = M_ARGV(0, float);
			}
			eventchase_running = true;

			// make special vector since we can't use view_origin (It is one frame old as of this code, it gets set later with the results this code makes.)
			vector current_view_origin = (csqcplayer ? csqcplayer.origin : pmove_org);
			if (custom_eventchase)
				current_view_origin = current_view_origin_override;

			// detect maximum viewoffset and use it
			vector view_offset = autocvar_cl_eventchase_viewoffset;
			if(vehicle_chase)
			{
				if(vehicle_viewofs)
					view_offset = vehicle_viewofs;
				else
					view_offset = autocvar_cl_eventchase_vehicle_viewoffset;
			}
			if (custom_eventchase)
				view_offset = view_offset_override;

			if(view_offset)
			{
				WarpZone_TraceLine(current_view_origin, current_view_origin + view_offset + ('0 0 1' * autocvar_cl_eventchase_maxs.z), MOVE_WORLDONLY, this);
				if(trace_fraction == 1) { current_view_origin += view_offset; }
				else { current_view_origin.z += max(0, (trace_endpos.z - current_view_origin.z) - autocvar_cl_eventchase_maxs.z); }
			}

			// We must enable chase_active to get a third person view (weapon viewmodel hidden and own player model showing).
			// Ideally, there should be another way to enable third person cameras, such as through setproperty()
			// -1 enables chase_active while marking it as set by this code, and not by the user (which would be 1)
			if(!autocvar_chase_active) { cvar_set("chase_active", "-1"); }

			// make the camera smooth back
			float chase_distance = autocvar_cl_eventchase_distance;
			if(vehicle_chase)
			{
				if(vehicle_viewofs)
					chase_distance = vehicle_viewdist;
				else
					chase_distance = autocvar_cl_eventchase_vehicle_distance;
			}
			if (custom_eventchase)
				chase_distance = chase_distance_override;

			if(autocvar_cl_eventchase_speed && eventchase_current_distance < chase_distance)
				eventchase_current_distance += autocvar_cl_eventchase_speed * (chase_distance - eventchase_current_distance) * frametime; // slow down the further we get
			else if(eventchase_current_distance != chase_distance)
				eventchase_current_distance = chase_distance;

			makevectors(view_angles);

			vector eventchase_target_origin = (current_view_origin - (v_forward * eventchase_current_distance));
			WarpZone_TraceBox(current_view_origin, autocvar_cl_eventchase_mins, autocvar_cl_eventchase_maxs, eventchase_target_origin, MOVE_WORLDONLY, this);

			// If the boxtrace fails, revert back to line tracing.
			if(!local_player.viewloc)
			if(trace_startsolid)
			{
				eventchase_target_origin = (current_view_origin - (v_forward * eventchase_current_distance));
				WarpZone_TraceLine(current_view_origin, eventchase_target_origin, MOVE_WORLDONLY, this);
				setproperty(VF_ORIGIN, (trace_endpos - (v_forward * autocvar_cl_eventchase_mins.z)));
			}
			else { setproperty(VF_ORIGIN, trace_endpos); }

			if(!local_player.viewloc)
				setproperty(VF_ANGLES, WarpZone_TransformVAngles(WarpZone_trace_transform, view_angles));
		}

		if (eventchase <= 0 && autocvar_chase_active < 0) // time to disable chase_active if it was set by this code
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

	LABEL(skip_eventchase_death);

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

		if((dist = vdist((vec3(ov_worldmin.x, ov_worldmin.y, ov_worldmin.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmax.x, ov_worldmin.y, ov_worldmin.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmin.x, ov_worldmax.y, ov_worldmin.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmin.x, ov_worldmin.y, ov_worldmax.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmax.x, ov_worldmax.y, ov_worldmin.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmin.x, ov_worldmax.y, ov_worldmax.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmax.x, ov_worldmin.y, ov_worldmax.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }
		if((dist = vdist((vec3(ov_worldmax.x, ov_worldmax.y, ov_worldmax.z) - ov_org), >, ov_furthest))) { ov_furthest = dist; }

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
		LOG_INFOF("OrthoView: org = %s, angles = %s, distance = %f, nearest = %f, furthest = %f",
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

	// run viewmodel_draw before updating view_angles to the angles calculated by WarpZone_FixView
	// viewmodel_draw needs to use the view_angles set by the engine on every CSQC_UpdateView call
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		viewmodel_draw(viewmodels[slot]);

	// Render the Scene
	view_origin = getpropertyvec(VF_ORIGIN);
	view_angles = getpropertyvec(VF_ANGLES);
	MAKEVECTORS(makevectors, view_angles, view_forward, view_right, view_up);

#ifdef BLURTEST
	if(time > blurtest_time0 && time < blurtest_time1)
	{
		float r, t;

		t = (time - blurtest_time0) / (blurtest_time1 - blurtest_time0);
		r = t * blurtest_radius;
		f = 1 / (t ** blurtest_power) - 1;

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
	fpscounter_update();

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

	if(intermission && !intermission_time)
		intermission_time = time;

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

	if(active_minigame && HUD_MinigameMenu_IsOpened())
	{
		if(!minigame_wasactive)
		{
			localcmd("+button14\n");
			minigame_wasactive = true;
		}
	}
	else if(minigame_wasactive)
	{
		localcmd("-button14\n");
		minigame_wasactive = false;
	}

	ColorTranslateMode = autocvar_cl_stripcolorcodes;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wepent = viewmodels[slot];

		if(wepent.last_switchweapon != wepent.switchweapon)
		{
			weapontime = time;
			wepent.last_switchweapon = wepent.switchweapon;
			if(slot == 0 && button_zoom && autocvar_cl_unpress_zoom_on_weapon_switch)
			{
				localcmd("-zoom\n");
				button_zoom = false;
			}
			if(slot == 0 && autocvar_cl_unpress_attack_on_weapon_switch)
			{
				localcmd("-fire\n");
				localcmd("-fire2\n");
				button_attack2 = false;
			}
		}
		if(wepent.last_activeweapon != wepent.activeweapon)
		{
			wepent.last_activeweapon = wepent.activeweapon;

			e = wepent.activeweapon;
			if(e.netname != "")
				localcmd(strcat("\ncl_hook_activeweapon ", e.netname), "\n");
			else if(slot == 0)
				localcmd("\ncl_hook_activeweapon none\n");
		}
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

	if(camera_active) // Camera for demo playback
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

	IL_EACH(g_drawables, it.draw, it.draw(it));

	addentities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS); // TODO: .health is used in cl_deathfade (a feature we have turned off currently)
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
		string reticle_image = string_null;
		bool wep_zoomed = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			entity wepe = viewmodels[slot];
			Weapon wep = wepe.activeweapon;
			if(wep != WEP_Null && wep.wr_zoom)
			{
				bool do_zoom = wep.wr_zoom(wep, NULL);
				if(!reticle_image && wep.w_reticle && wep.w_reticle != "")
					reticle_image = wep.w_reticle;
				wep_zoomed += do_zoom;
			}
		}
		// Draw the aiming reticle for weapons that use it
		// reticle_type is changed to the item we are zooming / aiming with, to decide which reticle to use
		// It must be a persisted float for fading out to work properly (you let go of the zoom button for
		// the view to go back to normal, so reticle_type would become 0 as we fade out)
		if(spectatee_status || is_dead || hud != HUD_NORMAL || local_player.viewloc)
		{
			// no zoom reticle while dead
			reticle_type = 0;
		}
		else if(wep_zoomed && autocvar_cl_reticle_weapon)
		{
			if(reticle_image) { reticle_type = 2; }
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
					case 2: if(reticle_image) drawpic(reticle_pos, reticle_image, reticle_size, '1 1 1', f * autocvar_cl_reticle_weapon_alpha, DRAWFLAG_NORMAL); break;
				}
			}
		}
	}
	else
	{
		if(reticle_type != 0) { reticle_type = 0; }
	}


	// improved polyblend
	if(autocvar_hud_contents && !MUTATOR_CALLHOOK(HUD_Contents))
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
			drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), liquidcolor_prev, contentavgalpha * liquidalpha_prev, DRAWFLAG_NORMAL);

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
					myhealth_gentlergb = randomvec();
			}
			else
				myhealth_gentlergb = stov(autocvar_hud_damage_gentle_color);

			if(myhealth_flash_temp > 0)
				drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), myhealth_gentlergb, autocvar_hud_damage_gentle_alpha_multiplier * bound(0, myhealth_flash_temp, 1) * autocvar_hud_damage, DRAWFLAG_NORMAL);
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

	/*if(ISGAMETYPE(CTF))
	  {
	  ctf_view();
	  } else */

	// draw 2D entities
	IL_EACH(g_drawables_2d, it.draw2d, it.draw2d(it));
	Draw_ShowNames_All();
#if ENABLE_DEBUGDRAW
	Debug_Draw();
#endif

	scoreboard_active = Scoreboard_WouldDraw();

	HUD_Draw(this); // this parameter for deep vehicle function

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

	HUD_Mouse(local_player);

	cl_notice_run();
	unpause_update();
	Net_Flush();

	// let's reset the view back to normal for the end
	setproperty(VF_MIN, '0 0 0');
	setproperty(VF_SIZE, '1 0 0' * w + '0 1 0' * h);

	IL_ENDFRAME();
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
		if(vdist(tmp, >, autocvar_camera_mouse_threshold))
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
