void WarpZone_Fade_PreDraw()
{
	if(self.warpzone_fadestart)
		self.alpha = bound(0, (self.warpzone_fadeend - vlen(view_origin - self.origin - 0.5 * (self.mins + self.maxs))) / (self.warpzone_fadeend - self.warpzone_fadestart), 1);
	else
		self.alpha = 1;
	//print(sprintf("%v <-> %v\n", view_origin, self.origin + 0.5 * (self.mins + self.maxs)));
	if(self.alpha <= 0)
		self.drawmask = 0;
	else
		self.drawmask = MASK_NORMAL;
}

void WarpZone_Read(float isnew)
{
	float f;

	warpzone_warpzones_exist = 1;
	if not(self.enemy)
	{
		self.enemy = spawn();
		self.enemy.classname = "warpzone_from";
	}
	self.classname = "trigger_warpzone";

	f = ReadByte();
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
	if(self.warpzone_fadestart)
		self.predraw = WarpZone_Fade_PreDraw;
	else
		self.drawmask = MASK_NORMAL;
}

void WarpZone_Camera_Read(float isnew)
{
	float f;
	warpzone_cameras_exist = 1;
	self.classname = "func_warpzone_camera";

	f = ReadByte();
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
	if(self.warpzone_fadestart)
		self.predraw = WarpZone_Fade_PreDraw;
	else
		self.drawmask = MASK_NORMAL;
}

float warpzone_fixingview;
float warpzone_fixingview_drawexteriormodel;
//float warpzone_fixingview_sidespeed;
//float warpzone_fixingview_forwardspeed;
void WarpZone_Inside()
{
	if(warpzone_fixingview)
		return;
	warpzone_fixingview = 1;
	warpzone_fixingview_drawexteriormodel = cvar("r_drawexteriormodel");
	//warpzone_fixingview_sidespeed = cvar("cl_sidespeed");
	//warpzone_fixingview_forwardspeed = cvar("cl_forwardspeed");
	cvar_set("r_drawexteriormodel", "0");
	//cvar_set("cl_sidespeed", ftos(warpzone_fixingview_sidespeed / 100)); // just keep a bit of it in case player gets stuck
	//cvar_set("cl_forwardspeed", ftos(warpzone_fixingview_forwardspeed / 100)); // just keep a bit of it in case player gets stuck
}

void WarpZone_Outside()
{
	if(!warpzone_fixingview)
		return;
	warpzone_fixingview = 0;
	cvar_set("r_drawexteriormodel", ftos(warpzone_fixingview_drawexteriormodel));
	//cvar_set("cl_sidespeed", ftos(warpzone_fixingview_sidespeed));
	//cvar_set("cl_forwardspeed", ftos(warpzone_fixingview_forwardspeed));
}

vector WarpZone_FixNearClip(vector o, vector c0, vector c1, vector c2, vector c3)
{
	vector mi, ma;
	entity e;
	float pd;

	mi_x = min5(o_x, c0_x, c1_x, c2_x, c3_x);
	ma_x = max5(o_x, c0_x, c1_x, c2_x, c3_x);
	mi_y = min5(o_y, c0_y, c1_y, c2_y, c3_y);
	ma_y = max5(o_y, c0_y, c1_y, c2_y, c3_y);
	mi_z = min5(o_z, c0_z, c1_z, c2_z, c3_z);
	ma_z = max5(o_z, c0_z, c1_z, c2_z, c3_z);

	e = WarpZone_Find(mi, ma);
	if(e)
	{
		if(WarpZone_PlaneDist(e, o) < 0)
			return '0 0 0';
			// can't really be, though, but if it is, this is not my warpzone, but a random different one in the same mins/maxs
		pd = min4(
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

float warpzone_saved;
vector warpzone_saved_origin;
vector warpzone_saved_angles;
vector warpzone_saved_cl_viewangles;
#ifndef KEEP_ROLL
var float autocvar_cl_rollkillspeed = 10;
#endif
void WarpZone_FixView()
{
	float f;
	vector o;
	entity e;
	vector corner0, corner1, corner2, corner3, nearclip;

	warpzone_saved = 0;
	warpzone_saved_origin = warpzone_fixview_origin;
	warpzone_saved_angles = warpzone_fixview_angles;
	warpzone_saved_cl_viewangles = warpzone_fixview_cl_viewangles;

	nearclip = '0 0 1' * (cvar("r_nearclip") * 1.125);
	corner0 = cs_unproject('0 0 0' + nearclip);
	corner1 = cs_unproject('1 0 0' * cvar("vid_conwidth") + nearclip);
	corner2 = cs_unproject('0 1 0' * cvar("vid_conheight") + nearclip);
	corner3 = cs_unproject('1 0 0' * cvar("vid_conwidth") + '0 1 0' * cvar("vid_conheight") + nearclip);

#ifndef KEEP_ROLL
	if(warpzone_fixview_angles_z != 0 || warpzone_fixview_cl_viewangles_z != 0)
	{
		if(autocvar_cl_rollkillspeed)
			f = max(0, (1 - frametime * autocvar_cl_rollkillspeed));
		else
			f = 0;
		warpzone_fixview_angles_z *= f;
		warpzone_fixview_cl_viewangles_z *= f;
		warpzone_saved_angles_z *= f; // PERMANENTLY apply that change!
		warpzone_saved_cl_viewangles_z *= f; // PERMANENTLY apply that change!
		warpzone_saved = 2;
		R_SetView(VF_CL_VIEWANGLES_Z, warpzone_fixview_angles_z);
	}
#endif

	e = WarpZone_Find(warpzone_fixview_origin, warpzone_fixview_origin);
	if(e)
	{
		warpzone_saved = 1;
		warpzone_fixview_origin = WarpZone_TransformOrigin(e, warpzone_fixview_origin);
		corner0 = WarpZone_TransformOrigin(e, corner0);
		corner1 = WarpZone_TransformOrigin(e, corner1);
		corner2 = WarpZone_TransformOrigin(e, corner2);
		corner3 = WarpZone_TransformOrigin(e, corner3);
		warpzone_fixview_angles = WarpZone_TransformVAngles(e, warpzone_fixview_angles);
		warpzone_fixview_cl_viewangles = WarpZone_TransformVAngles(e, warpzone_fixview_cl_viewangles);
		WarpZone_Inside();
	}
	else
		WarpZone_Outside();

	// if we are near any warpzone planes - MOVE AWAY (work around nearclip)
	o = WarpZone_FixNearClip(warpzone_fixview_origin, corner0, corner1, corner2, corner3);
	if(o != '0 0 0')
	{
		warpzone_saved = 1;
		warpzone_fixview_origin += o;
	}

	if(warpzone_saved == 1)
	{
		R_SetView(VF_ORIGIN, warpzone_fixview_origin);
		R_SetView(VF_ANGLES, warpzone_fixview_cl_viewangles);
	}
}
void WarpZone_UnFixView()
{
	if(warpzone_saved)
	{
		warpzone_fixview_origin = warpzone_saved_origin;
		warpzone_fixview_angles = warpzone_saved_angles;
		warpzone_fixview_cl_viewangles = warpzone_saved_cl_viewangles;
		R_SetView(VF_ORIGIN, warpzone_fixview_origin);
		R_SetView(VF_ANGLES, warpzone_fixview_angles);
		R_SetView(VF_CL_VIEWANGLES, warpzone_fixview_cl_viewangles);
	}
}

void WarpZone_Init()
{
}

void WarpZone_Shutdown()
{
	WarpZone_Outside();
}
