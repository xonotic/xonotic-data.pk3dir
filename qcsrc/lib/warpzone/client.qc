#include "client.qh"
#include "common.qh"

#if defined(CSQC)
	#include <lib/csqcmodel/cl_model.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

void WarpZone_Fade_PreDraw(entity this)
{
	vector org;
	org = getpropertyvec(VF_ORIGIN);
	if(!checkpvs(org, this)) // this makes sense as long as we don't support recursive warpzones
		this.alpha = 0;
	else if(this.warpzone_fadestart)
		this.alpha = bound(0, (this.warpzone_fadeend - vlen(org - this.origin - 0.5 * (this.mins + this.maxs))) / (this.warpzone_fadeend - this.warpzone_fadestart), 1);
	else
		this.alpha = 1;
	//printf("%v <-> %v\n", view_origin, this.origin + 0.5 * (this.mins + this.maxs));
	if(this.alpha <= 0)
		this.drawmask = 0;
	else
		this.drawmask = MASK_NORMAL;
}

void WarpZone_Touch(entity this, entity toucher);
NET_HANDLE(ENT_CLIENT_WARPZONE, bool isnew)
{
	if(!warpzone_warpzones_exist)
	{
		cvar_settemp("r_water", "1"); // HACK for DarkPlaces: always enable reflections when a map has warpzones
		cvar_settemp("r_water_resolutionmultiplier", "1"); // HACK for DarkPlaces: enforce full quality so entities can be seen clearly through warpzones
	}
	warpzone_warpzones_exist = 1;
	if (!this.enemy)
	{
		this.enemy = new(warpzone_from);
	}
	this.classname = "trigger_warpzone";

	if(isnew)
		IL_PUSH(g_warpzones, this);

	int f = ReadByte();
	this.warpzone_isboxy = (f & 1);
	if(f & 4)
	{
		this.origin = ReadVector();
	}
	else
		this.origin = '0 0 0';
	this.modelindex = ReadShort();
	this.mins = ReadVector();
	this.maxs = ReadVector();
	this.scale = ReadByte() / 16;
	this.enemy.oldorigin = ReadVector();
	this.enemy.avelocity = ReadVector();
	this.oldorigin = ReadVector();
	this.avelocity = ReadVector();

	if(f & 2)
	{
		this.warpzone_fadestart = ReadShort();
		this.warpzone_fadeend = max(this.warpzone_fadestart + 1, ReadShort());
	}
	else
	{
		this.warpzone_fadestart = 0;
		this.warpzone_fadeend = 0;
	}

	// common stuff
	WarpZone_SetUp(this, this.enemy.oldorigin, this.enemy.avelocity, this.oldorigin, this.avelocity);

	// link me
	//setmodel(this, this.model);
	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);

	// how to draw
	// engine currently wants this
	setpredraw(this, WarpZone_Fade_PreDraw);

	//settouch(this, WarpZone_Touch);
	return true;
}

NET_HANDLE(ENT_CLIENT_WARPZONE_CAMERA, bool isnew)
{
	if(!warpzone_cameras_exist)
	{
		cvar_settemp("r_water", "1"); // HACK for DarkPlaces: always enable reflections when a map has cameras
		cvar_settemp("r_water_resolutionmultiplier", "1"); // HACK for DarkPlaces: enforce full quality so entities can be seen clearly through warpzones
	}
	warpzone_cameras_exist = 1;
	this.classname = "func_warpzone_camera";

	int f = ReadByte();
	if(f & 4)
	{
		this.origin = ReadVector();
	}
	else
		this.origin = '0 0 0';
	this.modelindex = ReadShort();
	this.mins = ReadVector();
	this.maxs = ReadVector();
	this.scale = ReadByte() / 16;
	this.oldorigin = ReadVector();
	this.avelocity = ReadVector();

	if(f & 2)
	{
		this.warpzone_fadestart = ReadShort();
		this.warpzone_fadeend = max(this.warpzone_fadestart + 1, ReadShort());
	}
	else
	{
		this.warpzone_fadestart = 0;
		this.warpzone_fadeend = 0;
	}

	// common stuff
	WarpZone_Camera_SetUp(this, this.oldorigin, this.avelocity);

	// engine currently wants this
	this.drawmask = MASK_NORMAL;

	// link me
	//setmodel(this, this.model);
	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);

	// how to draw
	// engine currently wants this
	setpredraw(this, WarpZone_Fade_PreDraw);
	return true;
}

void CL_RotateMoves(vector ang) = #638;
NET_HANDLE(ENT_CLIENT_WARPZONE_TELEPORTED, bool isnew)
{
	this.classname = "warpzone_teleported";
	vector v = ReadVector();
	return = true;
	if (!isnew) return;
	this.warpzone_transform = v;
	setproperty(VF_CL_VIEWANGLES, WarpZone_TransformVAngles(this, getpropertyvec(VF_CL_VIEWANGLES)));
	if(checkextension("DP_CSQC_ROTATEMOVES"))
		CL_RotateMoves(v);
		//CL_RotateMoves('0 90 0');
}

float warpzone_fixingview;
float warpzone_fixingview_drawexteriormodel;

void WarpZone_View_Outside()
{
	if(!warpzone_fixingview)
		return;
	warpzone_fixingview = 0;
	cvar_set("r_drawexteriormodel", ftos(warpzone_fixingview_drawexteriormodel));
}

void WarpZone_View_Inside()
{
	if(autocvar_chase_active)
	{
		WarpZone_View_Outside();
		return;
	}
	if(warpzone_fixingview)
		return;
	warpzone_fixingview = 1;
	warpzone_fixingview_drawexteriormodel = cvar("r_drawexteriormodel");
	cvar_set("r_drawexteriormodel", "0");
}

vector WarpZone_FixNearClip(vector o, vector c0, vector c1, vector c2, vector c3)
{
	vector mi, ma;
	entity e;
	float pd;

	mi.x = min(o.x, c0_x, c1_x, c2_x, c3_x);
	ma.x = max(o.x, c0_x, c1_x, c2_x, c3_x);
	mi.y = min(o.y, c0_y, c1_y, c2_y, c3_y);
	ma.y = max(o.y, c0_y, c1_y, c2_y, c3_y);
	mi.z = min(o.z, c0_z, c1_z, c2_z, c3_z);
	ma.z = max(o.z, c0_z, c1_z, c2_z, c3_z);

	e = WarpZone_Find(mi, ma);
	if(e)
	{
		if(WarpZone_PlaneDist(e, o) < 0)
			return '0 0 0';
			// can't really be, though, but if it is, this is not my warpzone, but a random different one in the same mins/maxs
		pd = min(
				WarpZone_PlaneDist(e, c0),
				WarpZone_PlaneDist(e, c1),
				WarpZone_PlaneDist(e, c2),
				WarpZone_PlaneDist(e, c3)
			);
		if(pd < 0)
			return e.warpzone_forward * -pd;
	}

	return '0 0 0';
}

void WarpZone_FixPMove()
{
	entity e = WarpZone_Find(pmove_org, pmove_org);
	if(e)
	{
		pmove_org = WarpZone_TransformOrigin(e, pmove_org);
		input_angles = WarpZone_TransformVAngles(e, input_angles);
	}
}

#ifndef KEEP_ROLL
float autocvar_cl_rollkillspeed = 10;
#endif
void WarpZone_FixView()
{
	entity e;
	vector org, ang, nearclip, corner0, corner1, corner2, corner3, o;

	warpzone_save_view_origin = org = getpropertyvec(VF_ORIGIN);
	warpzone_save_view_angles = ang = getpropertyvec(VF_ANGLES);

	e = WarpZone_Find(org, org);
	if(e)
	{
		org = WarpZone_TransformOrigin(e, org);
		ang = WarpZone_TransformVAngles(e, ang);
		WarpZone_View_Inside();
	}
	else
		WarpZone_View_Outside();

#ifndef KEEP_ROLL
	float rick;
	float f;
	static float rollkill;
	if (STAT(HEALTH) > 0 || STAT(HEALTH) == -666 || STAT(HEALTH) == -2342)
	{
		f = 0;
		// reset roll when passing through a warpzone that change player's roll angle
		if(autocvar_cl_rollkillspeed)
			f = max(0, (1 - frametime * autocvar_cl_rollkillspeed));
		if(rollkill)
			rollkill = 0;
	}
	else
	{
		f = 1;
		// roll the view when killed (v_deathtilt)
		if(autocvar_cl_rollkillspeed)
		{
			rollkill += frametime * autocvar_cl_rollkillspeed;
			f = min(1, rollkill);
		}
		else if(rollkill)
			rollkill = 0;
	}

	rick = getproperty(VF_CL_VIEWANGLES_Z);
	rick *= f;
	setproperty(VF_CL_VIEWANGLES_Z, rick);
	ang.z *= f;
#endif

	setproperty(VF_ORIGIN, org);
	setproperty(VF_ANGLES, ang);

	vector width = '1 0 0' * cvar("vid_conwidth");
	vector height = '0 1 0' * cvar("vid_conheight");
	nearclip = '0 0 1' * (cvar("r_nearclip") * 1.125);
	corner0 = cs_unproject('0 0 0' + nearclip);
	corner1 = cs_unproject(width + nearclip);
	corner2 = cs_unproject(height + nearclip);
	corner3 = cs_unproject(width + height + nearclip);
	o = WarpZone_FixNearClip(org, corner0, corner1, corner2, corner3);
	if(o != '0 0 0')
		setproperty(VF_ORIGIN, org + o);
}

void WarpZone_Shutdown()
{
	WarpZone_View_Outside();
}
