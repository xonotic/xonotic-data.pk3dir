#include "client.qh"
#include "common.qh"

#if defined(CSQC)
	#include "../../client/autocvars.qh"
	#include "../csqcmodel/cl_model.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

void WarpZone_Fade_PreDraw()
{SELFPARAM();
	vector org;
	org = getpropertyvec(VF_ORIGIN);
	if(!checkpvs(org, self)) // this makes sense as long as we don't support recursive warpzones
		self.alpha = 0;
	else if(self.warpzone_fadestart)
		self.alpha = bound(0, (self.warpzone_fadeend - vlen(org - self.origin - 0.5 * (self.mins + self.maxs))) / (self.warpzone_fadeend - self.warpzone_fadestart), 1);
	else
		self.alpha = 1;
	//printf("%v <-> %v\n", view_origin, self.origin + 0.5 * (self.mins + self.maxs));
	if(self.alpha <= 0)
		self.drawmask = 0;
	else
		self.drawmask = MASK_NORMAL;
}

void WarpZone_Read(float isnew)
{SELFPARAM();
	warpzone_warpzones_exist = 1;
	if (!self.enemy)
	{
		self.enemy = spawn();
		self.enemy.classname = "warpzone_from";
	}
	self.classname = "trigger_warpzone";

	int f = ReadByte();
	self.warpzone_isboxy = (f & 1);
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	else
		self.origin = '0 0 0';
	self.modelindex = ReadShort();
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.scale = ReadByte() / 16;
	self.enemy.oldorigin_x = ReadCoord();
	self.enemy.oldorigin_y = ReadCoord();
	self.enemy.oldorigin_z = ReadCoord();
	self.enemy.avelocity_x = ReadCoord();
	self.enemy.avelocity_y = ReadCoord();
	self.enemy.avelocity_z = ReadCoord();
	self.oldorigin_x = ReadCoord();
	self.oldorigin_y = ReadCoord();
	self.oldorigin_z = ReadCoord();
	self.avelocity_x = ReadCoord();
	self.avelocity_y = ReadCoord();
	self.avelocity_z = ReadCoord();

	if(f & 2)
	{
		self.warpzone_fadestart = ReadShort();
		self.warpzone_fadeend = max(self.warpzone_fadestart + 1, ReadShort());
	}
	else
	{
		self.warpzone_fadestart = 0;
		self.warpzone_fadeend = 0;
	}

	// common stuff
	WarpZone_SetUp(self, self.enemy.oldorigin, self.enemy.avelocity, self.oldorigin, self.avelocity);

	// link me
	//setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);

	// how to draw
	// engine currently wants this
	self.predraw = WarpZone_Fade_PreDraw;
}

void WarpZone_Camera_Read(float isnew)
{SELFPARAM();
	warpzone_cameras_exist = 1;
	self.classname = "func_warpzone_camera";

	int f = ReadByte();
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	else
		self.origin = '0 0 0';
	self.modelindex = ReadShort();
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.scale = ReadByte() / 16;
	self.oldorigin_x = ReadCoord();
	self.oldorigin_y = ReadCoord();
	self.oldorigin_z = ReadCoord();
	self.avelocity_x = ReadCoord();
	self.avelocity_y = ReadCoord();
	self.avelocity_z = ReadCoord();

	if(f & 2)
	{
		self.warpzone_fadestart = ReadShort();
		self.warpzone_fadeend = max(self.warpzone_fadestart + 1, ReadShort());
	}
	else
	{
		self.warpzone_fadestart = 0;
		self.warpzone_fadeend = 0;
	}

	// common stuff
	WarpZone_Camera_SetUp(self, self.oldorigin, self.avelocity);

	// engine currently wants this
	self.drawmask = MASK_NORMAL;

	// link me
	//setmodel(self, self.model);
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);

	// how to draw
	// engine currently wants this
	self.predraw = WarpZone_Fade_PreDraw;
}

void CL_RotateMoves(vector ang) = #638;
void WarpZone_Teleported_Read(float isnew)
{SELFPARAM();
	vector v;
	self.classname = "warpzone_teleported";
	v.x = ReadCoord();
	v.y = ReadCoord();
	v.z = ReadCoord();
	if(!isnew)
		return;
	self.warpzone_transform = v;
	setproperty(VF_CL_VIEWANGLES, WarpZone_TransformVAngles(self, getpropertyvec(VF_CL_VIEWANGLES)));
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
	entity e;
	e = WarpZone_Find(pmove_org, pmove_org);
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
	float f;

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
	if(autocvar_cl_rollkillspeed)
		f = max(0, (1 - frametime * autocvar_cl_rollkillspeed));
	else
		f = 0;

	rick = getproperty(VF_CL_VIEWANGLES_Z);
	rick *= f;
	setproperty(VF_CL_VIEWANGLES_Z, rick);
	ang.z *= f;
#endif

	setproperty(VF_ORIGIN, org);
	setproperty(VF_ANGLES, ang);

	nearclip = '0 0 1' * (cvar("r_nearclip") * 1.125);
	corner0 = cs_unproject('0 0 0' + nearclip);
	corner1 = cs_unproject('1 0 0' * cvar("vid_conwidth") + nearclip);
	corner2 = cs_unproject('0 1 0' * cvar("vid_conheight") + nearclip);
	corner3 = cs_unproject('1 0 0' * cvar("vid_conwidth") + '0 1 0' * cvar("vid_conheight") + nearclip);
	o = WarpZone_FixNearClip(org, corner0, corner1, corner2, corner3);
	if(o != '0 0 0')
		setproperty(VF_ORIGIN, org + o);
}

void WarpZone_Init()
{
}

void WarpZone_Shutdown()
{
	WarpZone_View_Outside();
}
