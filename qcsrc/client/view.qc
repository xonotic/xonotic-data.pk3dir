#include "view.qh"

#include <client/announcer.qh>
#include <client/csqcmodel_hooks.qh>
#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/panel/quickmenu.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/mapvoting.qh>
#include <client/mutators/_mod.qh>
#include <client/shownames.qh>
#include <common/anim.qh>
#include <common/animdecide.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/debug.qh>
#include <common/ent_cs.qh>
#include <common/gametypes/_mod.qh>
#include <common/impulses/all.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/target/music.qh>
#include <common/mapobjects/trigger/viewloc.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/minigames/cl_minigames_hud.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/net_linked.qh>
#include <common/net_notice.qh>
#include <common/physics/player.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/vehicles/all.qh>
#include <common/viewloc.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/weapon/tuba.qh>
#include <common/wepent.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <lib/warpzone/client.qh>
#include <lib/warpzone/common.qh>

float autocvar_cl_viewmodel_alpha = 1;
float autocvar_cl_viewmodel_alpha_min;

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
	float __ignore; lowpass(value, frac, ref_store, __ignore); \
	ret = ref_store = bound((value) - (limit), ref_store, (value) + (limit)); \
MACRO_END

#define highpass(value, frac, ref_store, ret) MACRO_BEGIN \
	float __f = 0; lowpass(value, frac, ref_store, __f); \
	ret = (value) - __f; \
MACRO_END

#define highpass_limited(value, frac, limit, ref_store, ret) MACRO_BEGIN \
	float __f = 0; lowpass_limited(value, frac, limit, ref_store, __f); \
	ret = (value) - __f; \
MACRO_END

#define lowpass2(value, frac, ref_store, ref_out) MACRO_BEGIN \
	lowpass(value.x, frac, ref_store.x, ref_out.x); \
	lowpass(value.y, frac, ref_store.y, ref_out.y); \
MACRO_END

#define highpass2(value, frac, ref_store, ref_out) MACRO_BEGIN \
	highpass(value.x, frac, ref_store.x, ref_out.x); \
	highpass(value.y, frac, ref_store.y, ref_out.y); \
MACRO_END

#define highpass2_limited(value, frac, limit, ref_store, ref_out) MACRO_BEGIN \
	highpass_limited(value.x, frac, limit, ref_store.x, ref_out.x); \
	highpass_limited(value.y, frac, limit, ref_store.y, ref_out.y); \
MACRO_END

#define lowpass3(value, frac, ref_store, ref_out) MACRO_BEGIN \
	lowpass(value.x, frac, ref_store.x, ref_out.x); \
	lowpass(value.y, frac, ref_store.y, ref_out.y); \
	lowpass(value.z, frac, ref_store.z, ref_out.z); \
MACRO_END

#define highpass3(value, frac, ref_store, ref_out) MACRO_BEGIN \
	highpass(value.x, frac, ref_store.x, ref_out.x); \
	highpass(value.y, frac, ref_store.y, ref_out.y); \
	highpass(value.z, frac, ref_store.z, ref_out.z); \
MACRO_END

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
		vector forward, right, up;
		MAKE_VECTORS(view_angles, forward, right, up);
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
		vector forward, right, up;
		MAKE_VECTORS(view_angles, forward, right, up);
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
	static float avg_xyspeed = 0; // makes the effect always restart in the same way
	if (clonground)
	{
		if (time - hitgroundtime > 0.05)
			bobmodel_scale = min(1, bobmodel_scale + frametime * 5);
	}
	else
		bobmodel_scale = max(0, bobmodel_scale - frametime * 5);

	if (bobmodel_scale)
	{
		float xyspeed = bound(0, vlen(vec2(view.velocity)), 400);
		// smooth speed changes to get rid of weapon stuttering on direction changes
		const float avg_time = 0.1;
		float frac = 1 - exp(-frametime / max(0.001, avg_time));
		avg_xyspeed = frac * xyspeed + (1 - frac) * avg_xyspeed;
		// stop bobbing at a very low value of avg_xyspeed instead of 0
		// since the averaging formula takes a very long time to reach exactly 0
		if (avg_xyspeed < 1)
			time_ofs = time;
		else
		{
			if (avg_xyspeed < 400) // reduce bob frequency too when player walks crouching
				time_ofs += frametime * map_bound_ranges(avg_xyspeed, 150, 400, 0.08, 0);

			float bspeed = avg_xyspeed * 0.01 * bobmodel_scale;
			float s = (time - time_ofs) * autocvar_cl_bobmodel_speed;
			gunorg.y = bspeed * autocvar_cl_bobmodel_side * sin(s);
			gunorg.z = bspeed * autocvar_cl_bobmodel_up * cos(s * 2);
		}
	}
	else
		time_ofs = time;

	return gunorg;
}

void viewmodel_animate(entity this)
{
	if (autocvar_chase_active || STAT(HEALTH) <= 0) return;

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

.float weapon_nextthink;
.float weapon_eta_last;
.float weapon_switchdelay;

.string name_last;

void viewmodel_draw(entity this)
{
	// alpha calculations
	float amax = (autocvar_cl_viewmodel_alpha != 0) ? autocvar_cl_viewmodel_alpha : 1;
	float amin = (autocvar_cl_viewmodel_alpha_min != 0) ? autocvar_cl_viewmodel_alpha_min : -1;
	float a = (amin >= amax) ? amax : bound(amin, this.m_alpha, amax);

	int mask = (intermission || (STAT(HEALTH) <= 0) || autocvar_chase_active) ? 0 : MASK_NORMAL;
	int wepskin = this.m_skin;
	bool invehicle = player_localentnum > maxclients;
	if (invehicle) a = -1;
	Weapon wep = this.activeweapon;
	int c = entcs_GetClientColors(current_player);
	vector g = weaponentity_glowmod(wep, c, this);
	entity me = CSQCModel_server2csqc(player_localentnum - 1);
	int fx = ((me.csqcmodel_effects & EFMASK_CHEAP)
		| EF_NODEPTHTEST)
		&~ (EF_FULLBRIGHT); // can mask team color, so get rid of it
	for (entity e = this; e; e = e.weaponchild)
	{
		e.drawmask = mask;
		e.alpha = a;
		e.skin = wepskin;
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
			this.origin += autocvar_cl_gunoffset;
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
	this.angles_x = (-90 * f * f);
	viewmodel_animate(this);
	MUTATOR_CALLHOOK(DrawViewModel, this);
	setorigin(this, this.origin);
}

STATIC_INIT(viewmodel) {
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    	viewmodels[slot] = new(viewmodel);
}

vector project_3d_to_2d(vector vec)
{
	vec = cs_project(vec);
	return vec;
}

bool projected_on_screen(vector screen_pos)
{
	return screen_pos.z >= 0
		&& screen_pos.x >= 0
		&& screen_pos.y >= 0
		&& screen_pos.x < vid_conwidth
		&& screen_pos.y < vid_conheight;
}

void update_mousepos()
{
	mousepos += getmousepos() * autocvar_menu_mouse_speed;
	mousepos.x = bound(0, mousepos.x, vid_conwidth);
	mousepos.y = bound(0, mousepos.y, vid_conheight);
}

float showfps_prevfps_time;
int showfps_framecounter;

void fpscounter_update()
{
	if(!STAT(SHOWFPS))
		return;

	float currentTime = gettime(GETTIME_FRAMESTART);

	showfps_framecounter += 1;
	if(currentTime - showfps_prevfps_time > STAT(SHOWFPS))
	{
		float fps = showfps_framecounter / (currentTime - showfps_prevfps_time);
		showfps_framecounter = 0;
		showfps_prevfps_time = currentTime;

		int channel = MSG_C2S;
		WriteHeader(channel, fpsreport);
		WriteShort(channel, bound(0, rint(fps), 32767)); // prevent insane fps values
	}
}

STATIC_INIT(fpscounter_init)
{
	float currentTime = gettime(GETTIME_FRAMESTART);
	showfps_prevfps_time = currentTime; // we must initialize it to avoid an instant low frame sending
}

bool IsZooming(bool ignore_spectatorbutton_zoom)
{
	bool zoomdir = button_zoom;

	if (hud == HUD_NORMAL && !spectatee_status)
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			entity wepent = viewmodels[slot];
			if (wepent.switchweapon != wepent.activeweapon)
				continue;
			Weapon wep = wepent.activeweapon;
			if (wep != WEP_Null && wep.wr_zoomdir)
			if (wep.wr_zoomdir(wep)) // TODO: merge this with wr_zoom?
				zoomdir = true;
		}

	if (!ignore_spectatorbutton_zoom)
	if (spectatorbutton_zoom && (spectatee_status > 0 || isdemo()))
		zoomdir = !zoomdir;

	return zoomdir;
}

const float MAX_ZOOMFACTOR = 30;
float zoomscroll_factor;
float zoomscroll_factor_target;
void ZoomScroll(float nPrimary)
{
	bool zoomin = (nPrimary == K_MWHEELUP);
	if (autocvar_cl_zoomscroll_scale < 0)
		zoomin = !zoomin;

	// allow negatives so that players can scroll the other way, biggest change allowed is +100%
	float zoomscroll_scale = 1 + min(fabs(autocvar_cl_zoomscroll_scale), 1);

	if (zoomin)
		zoomscroll_factor_target = min(MAX_ZOOMFACTOR, zoomscroll_factor_target * zoomscroll_scale);
	else
		zoomscroll_factor_target = max(1, zoomscroll_factor_target / zoomscroll_scale);
}

bool View_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	if (bInputType == 2 || bInputType == 3)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	if (nPrimary == K_MWHEELUP || nPrimary == K_MWHEELDOWN)
	{
		if (!autocvar_cl_zoomscroll || autocvar_cl_zoomscroll_scale == 0)
			return false; // zoom scroll disabled
		if (!IsZooming(true))
			return false;
		if (key_pressed)
			ZoomScroll(nPrimary);
		return true;
	}

	return false;
}

float avgspeed;
vector GetCurrentFov(float fov)
{
	float zoomsensitivity, zoomspeed, zoomfactor, zoomdir;
	float velocityzoom, curspeed;
	vector v;

	zoomdir = IsZooming(false);

	zoomspeed = autocvar_cl_zoomspeed;
	if(zoomspeed >= 0 && (zoomspeed < 0.5 || zoomspeed > 16))
		zoomspeed = 3.5;
	zoomsensitivity = autocvar_cl_zoomsensitivity;

	zoomfactor = autocvar_cl_zoomfactor;
	if(zoomfactor < 1 || zoomfactor > MAX_ZOOMFACTOR)
		zoomfactor = 2.5;

	if(zoomdir)
		zoomin_effect = 0;

	if (spectatee_status > 0 && STAT(CAMERA_SPECTATOR) == 2)
		current_viewzoom = 1;
	else if (camera_active)
		current_viewzoom = min(1, current_viewzoom + drawframetime);
	else if(autocvar_cl_spawnzoom && zoomin_effect)
	{
		float spawnzoomfactor = bound(1, autocvar_cl_spawnzoom_factor, MAX_ZOOMFACTOR);

		current_viewzoom += (autocvar_cl_spawnzoom_speed * (spawnzoomfactor - current_viewzoom) * drawframetime);
		current_viewzoom = bound(1 / spawnzoomfactor, current_viewzoom, 1);
		if(current_viewzoom == 1)
			zoomin_effect = 0;
	}
	else
	{
		if (autocvar_cl_zoomscroll && autocvar_cl_zoomscroll_scale)
		{
			// initialize zoom scroll in the first frame / reset zoom scroll when fully zoomed out
			if (!zoomscroll_factor || (current_viewzoom == 1 && !zoomdir))
			{
				zoomscroll_factor_target = zoomfactor;
				zoomscroll_factor = zoomfactor;
			}
			if (zoomscroll_factor != zoomscroll_factor_target)
			{
				if (fabs(zoomscroll_factor - zoomscroll_factor_target) < 0.001 || autocvar_cl_zoomscroll_speed < 0) // snap
					zoomscroll_factor = zoomscroll_factor_target;
				else if (autocvar_cl_zoomscroll_speed != 0)
				{
					// NOTE: this averaging formula is frametime independent
					float avg_time = 1 / autocvar_cl_zoomscroll_speed;
					float frac = 1 - exp(-drawframetime / max(0.001, avg_time));
					zoomscroll_factor = frac * zoomscroll_factor_target + (1 - frac) * zoomscroll_factor;
				}
			}
			zoomfactor = zoomscroll_factor;
		}

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

	if(zoomfactor == 1 || current_viewzoom > 0.999) // zoomfactor check prevents a division by 0
		current_zoomfraction = 0;
	else if(almost_equals(current_viewzoom, 1/zoomfactor))
		current_zoomfraction = 1;
	else
		current_zoomfraction = (current_viewzoom - 1) / (1/zoomfactor - 1);

	if(zoomsensitivity < 1)
		setsensitivityscale(current_viewzoom ** (1 - zoomsensitivity));
	else
		setsensitivityscale(1);

	if(autocvar_cl_velocityzoom_enabled && autocvar_cl_velocityzoom_type && !autocvar_cl_lockview) // _type = 0 disables velocity zoom too
	{
		if (intermission || (spectatee_status > 0 && STAT(CAMERA_SPECTATOR) == 2))
			curspeed = 0;
		else
		{
			vector forward, right, up;
			MAKE_VECTORS(view_angles, forward, right, up);
			v = pmove_vel;
			if(csqcplayer)
				v = csqcplayer.velocity;

			switch(autocvar_cl_velocityzoom_type)
			{
				case 3: curspeed = max(0, forward * v); break;
				case 2: curspeed = (forward * v); break;
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
	frustumy = tan(fov * (M_PI / 360)) * 0.75 * current_viewzoom * velocityzoom;
	frustumx = frustumy * vid_width / vid_height / vid_pixelheight;
	fovx = atan2(frustumx, 1) * (360 / M_PI);
	fovy = atan2(frustumy, 1) * (360 / M_PI);

	return '1 0 0' * fovx + '0 1 0' * fovy;
}

vector GetViewLocationFOV(float fov)
{
	float frustumy = tan(fov * (M_PI / 360)) * 0.75;
	float frustumx = frustumy * vid_width / vid_height / vid_pixelheight;
	float fovx = atan2(frustumx, 1) * (360 / M_PI);
	float fovy = atan2(frustumy, 1) * (360 / M_PI);
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

bool minigame_wasactive;

float camera_mode;
const float CAMERA_FREE = 1;
const float CAMERA_CHASE = 2;
string NextFrameCommand;

vector freeze_org, freeze_ang;
entity nightvision_noise, nightvision_noise2;

float myhealth, myhealth_prev;
float myhealth_flash;

float old_blurradius, old_bluralpha;
float old_sharpen_intensity;

vector myhealth_gentlergb;

float contentavgalpha, liquidalpha_prev;
vector liquidcolor_prev;

bool View_SpectatorCamera()
{
	static int waiting_CAMERA_SPECTATOR_update;
	static bool camera_spectator_3rd_person;
	if(spectatee_status > 0)
	{
		if(autocvar_chase_active > 0)
		{
			// if chase_active is enabled by the user, spectator camera never switches to 1st person
			// that means CAMERA_SPECTATOR 1 behaves as 0 and is redundant, so we forcedly skip it
			if (STAT(CAMERA_SPECTATOR) == 1)
			{
				if (!waiting_CAMERA_SPECTATOR_update)
				{
					Impulse_Send(IMP_weapon_drop); // switch to CAMERA_SPECTATOR 2
					waiting_CAMERA_SPECTATOR_update = 1;
				}
			}
			else waiting_CAMERA_SPECTATOR_update = 0;
			camera_spectator_3rd_person = true;
		}

		// chase_active disabled by the user?
		if(camera_spectator_3rd_person && autocvar_chase_active == 0)
		{
			if (STAT(CAMERA_SPECTATOR) >= 1)
			{
				if (waiting_CAMERA_SPECTATOR_update != STAT(CAMERA_SPECTATOR))
				{
					Impulse_Send(IMP_weapon_drop); // switch to CAMERA_SPECTATOR (2 and) 0
					waiting_CAMERA_SPECTATOR_update = STAT(CAMERA_SPECTATOR);
				}
			}
			else
			{
				waiting_CAMERA_SPECTATOR_update = 0;
				camera_spectator_3rd_person = false;
			}
			return true;
		}
	}

	if(autocvar_chase_active <= 0) // greater than 0 means it's enabled manually, and this code is skipped
	{
		if(STAT(CAMERA_SPECTATOR))
		{
			if(spectatee_status > 0)
			{
				if(!camera_spectator_3rd_person)
				{
					cvar_set("chase_active", "-2");
					camera_spectator_3rd_person = true;
					return true;
				}
			}
			else if(camera_spectator_3rd_person)
			{
				cvar_set("chase_active", "0");
				camera_spectator_3rd_person = false;
			}

			if(autocvar_chase_active == -2)
				return true;
		}
		else if(camera_spectator_3rd_person)
		{
			cvar_set("chase_active", "0");
			camera_spectator_3rd_person = false;
		}
	}
	return false;
}

float eventchase_current_distance;
float eventchase_running;
int WantEventchase(entity this, bool want_vehiclechase)
{
	if(autocvar_cl_orthoview)
		return 0;
	if(STAT(GAME_STOPPED) || intermission)
		return 1;
	if(this.viewloc)
		return 1;
	if(spectatee_status >= 0)
	{
		if(want_vehiclechase)
			return 1;
		if(MUTATOR_CALLHOOK(WantEventchase, this))
			return 1;
		if(autocvar_cl_eventchase_frozen && StatusEffects_active(STATUSEFFECT_Frozen, this))
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

void View_EventChase(entity this)
{
	// event chase camera
	if(autocvar_chase_active <= 0) // greater than 0 means it's enabled manually, and this code is skipped
	{
		bool vehicle_chase = (hud != HUD_NORMAL && (autocvar_cl_eventchase_vehicle || spectatee_status > 0));

		float vehicle_viewdist = 0;
		vector vehicle_viewofs = '0 0 0';

		if(vehicle_chase)
		{
			if(hud != HUD_BUMBLEBEE_GUN)
			{
				Vehicle info = REGISTRY_GET(Vehicles, hud);
				vehicle_viewdist = info.height;
				vehicle_viewofs = info.view_ofs;
				if(vehicle_viewdist < 0) // when set below 0, this vehicle doesn't use third person view (gunner slots)
					vehicle_chase = false;
			}
			else
				vehicle_chase = false;
		}

		int eventchase = WantEventchase(this, vehicle_chase);
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

			vector forward, right, up;
			MAKE_VECTORS(view_angles, forward, right, up);

			vector eventchase_target_origin = (current_view_origin - (forward * eventchase_current_distance));
			WarpZone_TraceBox(current_view_origin, autocvar_cl_eventchase_mins, autocvar_cl_eventchase_maxs, eventchase_target_origin, MOVE_WORLDONLY, this);

			// If the boxtrace fails, revert back to line tracing.
			if(!this.viewloc)
			if(trace_startsolid)
			{
				eventchase_target_origin = (current_view_origin - (forward * eventchase_current_distance));
				WarpZone_TraceLine(current_view_origin, eventchase_target_origin, MOVE_WORLDONLY, this);
				setproperty(VF_ORIGIN, (trace_endpos - (forward * autocvar_cl_eventchase_mins.z)));
			}
			else { setproperty(VF_ORIGIN, trace_endpos); }

			if(!this.viewloc)
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
}

vector damage_blurpostprocess, content_blurpostprocess;

void UpdateDamage()
{
	// accumulate damage with each stat update
	static float damage_total_prev = 0;
	float damage_total = STAT(HITSOUND_DAMAGE_DEALT_TOTAL);
	float unaccounted_damage_new = COMPARE_INCREASING(damage_total, damage_total_prev);
	damage_total_prev = damage_total;

	static float damage_dealt_time_prev = 0;
	float damage_dealt_time = STAT(HIT_TIME);
	if (damage_dealt_time != damage_dealt_time_prev)
	{
		unaccounted_damage += unaccounted_damage_new;
		//LOG_TRACE("dmg total: ", ftos(unaccounted_damage), " (+", ftos(unaccounted_damage_new), ")");
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
			float pitch_shift = 1;
			if (autocvar_cl_hitsound == 2 || autocvar_cl_hitsound == 3)
			{
				// customizable gradient function that crosses (0,a), (c,1) and asymptotically approaches b
				float a = autocvar_cl_hitsound_max_pitch;
				float b = autocvar_cl_hitsound_min_pitch;
				float c = autocvar_cl_hitsound_nom_damage;
				float d = unaccounted_damage;
				pitch_shift = (b*d*(a-1) + a*c*(1-b)) / (d*(a-1) + c*(1-b));

				// if pitch shift is reversed, mirror in (max-min)/2 + min
				if (autocvar_cl_hitsound == 3)
				{
					float mirror_value = (a-b)/2 + b;
					pitch_shift = mirror_value + (mirror_value - pitch_shift);
				}
			}

			//LOG_TRACE("dmg total (dmg): ", ftos(unaccounted_damage), " , pitch shift: ", ftos(pitch_shift));

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
	{
		if (MUTATOR_CALLHOOK(HUD_Draw_overlay))
		{
			vector col = M_ARGV(0, vector);
			float alpha_multipl = M_ARGV(1, float);
			if (alpha_multipl > 0)
				drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), col, autocvar_hud_colorflash_alpha * alpha_multipl, DRAWFLAG_ADDITIVE);
		}
	}

	HUD_Scale_Enable();
	if(!intermission)
	{
		// TODO: mutator hook for these? maybe something more generic!
		if(STAT(NADE_TIMER) && autocvar_cl_nade_timer) // give nade top priority, as it's a matter of life and death
		{
			vector col = '0.25 0.90 1' + vec3(STAT(NADE_TIMER), -STAT(NADE_TIMER), -STAT(NADE_TIMER));
			DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring", STAT(NADE_TIMER), col, autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
			drawstring_aspect(eY * 0.64 * vid_conheight, ((autocvar_cl_nade_timer == 2) ? _("Nade timer") : ""), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
		}
		else if(STAT(CAPTURE_PROGRESS))
		{
			DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring", STAT(CAPTURE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
			drawstring_aspect(eY * 0.64 * vid_conheight, _("Capture progress"), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
		}
		else if(STAT(REVIVE_PROGRESS))
		{
			DrawCircleClippedPic(vec2(0.5 * vid_conwidth, 0.6 * vid_conheight), 0.1 * vid_conheight, "gfx/crosshair_ring", STAT(REVIVE_PROGRESS), '0.25 0.90 1', autocvar_hud_colorflash_alpha, DRAWFLAG_ADDITIVE);
			drawstring_aspect(eY * 0.64 * vid_conheight, _("Revival progress"), vec2(vid_conwidth, 0.025 * vid_conheight), '1 1 1', 1, DRAWFLAG_NORMAL);
		}
	}
	HUD_Scale_Disable();

	if(autocvar_r_letterbox == 0)
	{
		if(autocvar_viewsize < 120)
		{
			if(!MUTATOR_CALLHOOK(DrawScoreboardAccuracy))
				Accuracy_LoadLevels();

			HUD_Main();
			HUD_Scale_Disable();
		}
	}

	// crosshair goes VERY LAST
	UpdateDamage();
	HUD_Crosshair(this);
	HitSound();
	Local_Notification_Queue_Process();
}

void ViewLocation_Mouse()
{
	if(spectatee_status)
		return; // don't draw it as spectator!

	viewloc_mousepos += getmousepos() * autocvar_menu_mouse_speed;
	viewloc_mousepos.x = bound(0, viewloc_mousepos.x, vid_conwidth);
	viewloc_mousepos.y = bound(0, viewloc_mousepos.y, vid_conheight);

	//float cursor_alpha = 1 - autocvar__menu_alpha;
	//cursor_type = CURSOR_NORMAL;
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

	cursor_type = CURSOR_NORMAL;
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

void View_NightVision()
{
	if(!(autocvar_r_fakelight >= 2 || autocvar_r_fullbright) || (serverflags & SERVERFLAG_ALLOW_FULLBRIGHT))
		return;

	// apply night vision effect
	vector tc_00, tc_01, tc_10, tc_11;
	vector rgb = '0 0 0';
	float a;

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
	R_BeginPolygon("gfx/nightvision-bg", DRAWFLAG_ADDITIVE, true);
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
	R_BeginPolygon("gfx/nightvision-fg", DRAWFLAG_ADDITIVE, true);
	R_PolygonVertex('0 0 0', tc_00, rgb, a);
	R_PolygonVertex(autocvar_vid_conwidth * '1 0 0', tc_10, rgb, a);
	R_PolygonVertex(autocvar_vid_conwidth * '1 0 0' + autocvar_vid_conheight * '0 1 0', tc_11, rgb, a);
	R_PolygonVertex(autocvar_vid_conheight * '0 1 0', tc_01, rgb, a);
	R_EndPolygon();
}

// visual overlay while in liquids
// provides some effects to the postprocessing function
void HUD_Contents()
{
	if(!autocvar_hud_contents || MUTATOR_CALLHOOK(HUD_Contents))
		return;

	// improved polyblend
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

// visual pain effects on the screen
// provides some effects to the postprocessing function
void HUD_Damage()
{
	if(!autocvar_hud_damage || MUTATOR_CALLHOOK(HUD_Damage_show))
		return;

	vector splash_pos = '0 0 0', splash_size = '0 0 0';
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

void View_PostProcessing()
{
	float e1 = (autocvar_hud_postprocessing_maxbluralpha != 0);
	float e2 = (autocvar_hud_powerup != 0);
	bool want_postprocessing = false;
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
			want_postprocessing = true;
		}
		else if(cvar_string("r_glsl_postprocess_uservec1") != "0 0 0 0") // reduce cvar_set spam as much as possible
		{
			cvar_set("r_glsl_postprocess_uservec1", "0 0 0 0");
			old_blurradius = 0;
			old_bluralpha = 0;
		}

		// edge detection postprocess handling done second (used by hud_powerup)
		float sharpen_intensity = 0;
		FOREACH(StatusEffects, it.instanceOfPowerupStatusEffect,
		{
			float powerup_finished = StatusEffects_gettime(it, g_statuseffects) - time;
			if(powerup_finished > 0)
				sharpen_intensity += powerup_finished;
		});

		sharpen_intensity = bound(0, ((STAT(HEALTH) > 0) ? sharpen_intensity : 0), 5); // Check to see if player is alive (if not, set 0) - also bound to fade out starting at 5 seconds.

		if(autocvar_hud_powerup && sharpen_intensity > 0)
		{
			if(sharpen_intensity != old_sharpen_intensity) // reduce cvar_set spam as much as possible
			{
				cvar_set("r_glsl_postprocess_uservec2", strcat(ftos((sharpen_intensity / 5) * autocvar_hud_powerup), " ", ftos(-sharpen_intensity * autocvar_hud_powerup), " 0 0"));
				old_sharpen_intensity = sharpen_intensity;
			}
			want_postprocessing = true;
		}
		else if(cvar_string("r_glsl_postprocess_uservec2") != "0 0 0 0") // reduce cvar_set spam as much as possible
		{
			cvar_set("r_glsl_postprocess_uservec2", "0 0 0 0");
			old_sharpen_intensity = 0;
		}
	}
	if (want_postprocessing)
	{
		if(cvar("r_glsl_postprocess") == 0)
			cvar_set("r_glsl_postprocess", "2");
	}
	else
	{
		if(cvar("r_glsl_postprocess") == 2)
			cvar_set("r_glsl_postprocess", "0");
	}
}

void View_Lock()
{
	int lock_type = autocvar_cl_lockview;

	if (!autocvar_hud_cursormode
		&& ((autocvar__hud_configure && spectatee_status <= 0)
			|| intermission > 1
			|| HUD_Radar_Clickable()
			|| HUD_MinigameMenu_IsOpened()
			|| QuickMenu_IsOpened()
		)
	)
		lock_type = 1;

	// lock_type 1: lock origin and angles
	// lock_type 2: lock only origin
	if(lock_type >= 1)
		setproperty(VF_ORIGIN, freeze_org);
	else
		freeze_org = getpropertyvec(VF_ORIGIN);
	if(lock_type == 1)
		setproperty(VF_ANGLES, freeze_ang);
	else
		freeze_ang = getpropertyvec(VF_ANGLES);
}

void View_DemoCamera()
{
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
}

#ifdef BLURTEST
void View_BlurTest()
{
	if(time > blurtest_time0 && time < blurtest_time1)
	{
		float t = (time - blurtest_time0) / (blurtest_time1 - blurtest_time0);
		float r = t * blurtest_radius;
		float f = 1 / (t ** blurtest_power) - 1;

		cvar_set("r_glsl_postprocess", "1");
		cvar_set("r_glsl_postprocess_uservec1", strcat(ftos(r), " ", ftos(f), " 0 0"));
	}
	else
	{
		cvar_set("r_glsl_postprocess", "0");
		cvar_set("r_glsl_postprocess_uservec1", "0 0 0 0");
	}
}
#endif

void View_CheckButtonStatus()
{
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

	if(autocvar_fov <= 59.5)
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
			localcmd("+button12\n");
			minigame_wasactive = true;
		}
	}
	else if(minigame_wasactive)
	{
		localcmd("-button12\n");
		minigame_wasactive = false;
	}

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

			entity e = wepent.activeweapon;
			if(e.netname != "")
				localcmd(strcat("\ncl_hook_activeweapon ", e.netname), "\n");
			else if(slot == 0)
				localcmd("\ncl_hook_activeweapon none\n");
		}
	}
}

bool ov_enabled;
float oldr_nearclip;
float oldr_farclip_base;
float oldr_farclip_world;
float oldr_novis;
float oldr_useportalculling;
float oldr_useinfinitefarclip;
vector ov_org = '0 0 0';
vector ov_mid = '0 0 0';
vector ov_worldmin = '0 0 0';
vector ov_worldmax = '0 0 0';

void View_Ortho()
{
	ov_org = '0 0 0';
	ov_mid = '0 0 0';
	ov_worldmin = '0 0 0';
	ov_worldmax = '0 0 0';
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
}

void View_UpdateFov()
{
	vector fov;
	if(autocvar_cl_orthoview)
		fov = GetOrthoviewFOV(ov_worldmin, ov_worldmax, ov_mid, ov_org);
	else if(csqcplayer.viewloc)
		fov = GetViewLocationFOV(110); // enforce 110 fov, so things don't look odd
	else
		fov = GetCurrentFov(autocvar_fov);

	setproperty(VF_FOV, fov);
}

void CSQC_UpdateView(entity this, float w, float h, bool notmenu)
{
	TC(int, w); TC(int, h);

	execute_next_frame();

	++framecount;

	stats_get();
	hud = STAT(HUD);

	ReplicateVars(REPLICATEVARS_CHECK);

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

	vector vf_size = getpropertyvec(VF_SIZE);
	vector vf_min = getpropertyvec(VF_MIN);
	vid_width = vf_size.x;
	vid_height = vf_size.y;

	ticrate = STAT(MOVEVARS_TICRATE) * STAT(MOVEVARS_TIMESCALE);

	if (autocvar_chase_active)
	{
		// in first person view if r_drawviewmodel is off weapon isn't visible
		// and server doesn't throw any casing
		// switching to 3rd person view r_drawviewmodel is set to -1 to let know the server casings
		// can be thrown for self since own weapon model is visible
		if (autocvar_r_drawviewmodel == 0 && STAT(HEALTH) > 0)
			cvar_set("r_drawviewmodel", "-1");
	}
	else
	{
		if (autocvar_r_drawviewmodel < 0)
			cvar_set("r_drawviewmodel", "0");
	}

	WaypointSprite_Load();

	CSQCPlayer_SetCamera();

	if(player_localentnum <= maxclients) // is it a client?
		current_player = player_localentnum - 1;
	else // then player_localentnum is the vehicle I'm driving
		current_player = player_localnum;
	myteam = entcs_GetTeam(current_player);

	entity local_player = ((csqcplayer) ? csqcplayer : CSQCModel_server2csqc(player_localentnum - 1));
	if(!local_player)
		local_player = this; // fall back!

	if (!View_SpectatorCamera())
		View_EventChase(local_player);

	// do lockview after event chase camera so that it still applies whenever necessary.
	View_Lock();

	WarpZone_FixView();
	//WarpZone_FixPMove();

	View_Ortho();

	// run viewmodel_draw before updating view_angles to the angles calculated by WarpZone_FixView
	// viewmodel_draw needs to use the view_angles set by the engine on every CSQC_UpdateView call
	if(autocvar_r_drawviewmodel)
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			if(viewmodels[slot].activeweapon)
				viewmodel_draw(viewmodels[slot]);

	// Render the Scene
	view_origin = getpropertyvec(VF_ORIGIN);
	view_angles = getpropertyvec(VF_ANGLES);
	MAKE_VECTORS(view_angles, view_forward, view_right, view_up);

#ifdef BLURTEST
	View_BlurTest();
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

	if(STAT(GAME_STOPPED) && !game_stopped_time)
		game_stopped_time = time;
	else if(game_stopped_time && !STAT(GAME_STOPPED))
		game_stopped_time = 0;

	// fire intermission hooks and gameend hook here
	// gameend hook is executed on CSQC VM shutdown if
	// the shutdown happens before intermission start
	if (intermission
	&& (calledhooks & HOOK_START) // ensure that we have initiated a gametype
	&& !(calledhooks & HOOK_END) // fire only once
	&& !(calledhooks & HOOK_INTERMISSION))
	{
		if(!isdemo())
		{
			int gamecount = cvar("cl_matchcount");
			localcmd("\ncl_hook_gameend\n");
			// NOTE: using localcmd here to ensure it's executed AFTER cl_hook_gameend
			// earlier versions of the game abuse the hook to set this cvar
			localcmd(strcat("cl_matchcount ", itos(gamecount + 1), "\n"));
			//cvar_set("cl_matchcount", itos(gamecount + 1));
			calledhooks |= HOOK_END;

			localcmd("\ncl_hook_gameintermission\n");
			calledhooks |= HOOK_INTERMISSION;
		}
		else
		{
			localcmd("\ncl_hook_demointermission\n");
			calledhooks |= HOOK_INTERMISSION;
		}
	}

	Welcome_Message_Show_Try();

	Announcer();

	View_CheckButtonStatus();

	ColorTranslateMode = autocvar_cl_stripcolorcodes;

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

	vid_conwidth = autocvar_vid_conwidth;
	vid_conheight = autocvar_vid_conheight;
	vid_pixelheight = autocvar_vid_pixelheight;

	View_UpdateFov();

	View_DemoCamera();

	setproperty(VF_DRAWCROSSHAIR, 0); // hide engine crosshair
	setproperty(VF_DRAWENGINESBAR, 0); // hide engine status bar

	IL_EACH(g_drawables, it.draw, it.draw(it));

	addentities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS); // TODO: .health is used in cl_deathfade (a feature we have turned off currently)
	renderscene();

	// Now the the scene has been rendered, begin with the 2D drawing functions

	View_NightVision();
	DrawReticle(local_player);
	HUD_Contents();
	HUD_Damage();
	View_PostProcessing();

	// draw 2D entities
	IL_EACH(g_drawables_2d, it.draw2d, it.draw2d(it));
	IL_EACH(g_damagetext, it.draw2d, it.draw2d(it));
	Draw_ShowNames_All();
#if ENABLE_DEBUGDRAW
	Debug_Draw();
#endif

	if (autocvar__scoreboard_team_selection)
	{
		Scoreboard_UI_Enable(1);
		cvar_set("_scoreboard_team_selection", "0");
	}
	scoreboard_active = Scoreboard_WouldDraw();

	HUD_Draw(this); // this parameter for deep vehicle function

	if(NextFrameCommand)
	{
		localcmd("\n", NextFrameCommand, "\n");
		NextFrameCommand = string_null;
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
	vector tmp;

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

	if(autocvar_camera_look_player)
		attenuation = autocvar_camera_look_attenuation;
	else
		attenuation = autocvar_camera_speed_attenuation;

	attenuation = 1 / max(1, attenuation);
	current_angles += (mouse_angles - current_angles) * attenuation;

	// limit current pitch angle to sane values
	if (current_angles.x < -90) current_angles.x = -90;
	if (current_angles.x > 90 ) current_angles.x = 90;

	// limit mouse and current yaw angles to standard values simultaneously so that the difference
	// between these angles is not altered
	while (current_angles.y < -180 && mouse_angles.y < -180) {current_angles.y += 360; mouse_angles.y += 360;}
	while (current_angles.y > 180  && mouse_angles.y > 180 ) {current_angles.y -= 360; mouse_angles.y -= 360;}

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
