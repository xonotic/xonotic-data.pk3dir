.float HookType; // ENT_CLIENT_*
.vector origin;
.vector velocity;
.float HookSound;
.float HookSilent;

void Draw_CylindricLine(vector from, vector to, float thickness, string texture, float aspect, float shift, vector rgb, float alpha, float drawflag)
{
	// I want to draw a quad...
	// from and to are MIDPOINTS.
	
	vector axis, thickdir, A, B, C, D;
	float length_tex;

	axis = normalize(to - from);
	length_tex = aspect * vlen(to - from) / thickness;

	// direction is perpendicular to the view normal, and perpendicular to the axis
	thickdir = normalize(cross(axis, view_origin - from));

/*
	print("from ", vtos(from), "\n");
	print("to ", vtos(to), "\n");
	print("org ", vtos(view_origin), "\n");
	print("dir ", vtos(thickdir), "\n");
*/

	A = from - thickdir * (thickness / 2);
	B = from + thickdir * (thickness / 2);
	C = to + thickdir * (thickness / 2);
	D = to - thickdir * (thickness / 2);

	R_BeginPolygon(texture, drawflag);
	R_PolygonVertex(A, '0 0 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(B, '0 1 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(C, '0 1 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_PolygonVertex(D, '0 0 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_EndPolygon();
}

string Draw_GrapplingHook_trace_callback_tex;
float Draw_GrapplingHook_trace_callback_rnd;
void Draw_GrapplingHook_trace_callback(vector start, vector hit, vector end)
{
	Draw_CylindricLine(hit, start, 8, Draw_GrapplingHook_trace_callback_tex, 0.25, Draw_GrapplingHook_trace_callback_rnd, '1 1 1', 1, DRAWFLAG_NORMAL);
	Draw_GrapplingHook_trace_callback_rnd += 0.25 * vlen(hit - start) / 8;
}

void Draw_GrapplingHook()
{
	vector a, b;
	string tex, snd;
	vector rgb;
	float t;
	float s;
	vector vs;

	InterpolateOrigin_Do();

	s = cvar("cl_gunalign");
	if(s != 1 && s != 2 && s != 4)
		s = 3; // default value
	--s;
	switch(self.HookType)
	{
		default:
		case ENT_CLIENT_HOOK:
			vs = hook_shotorigin[s];
			break;
		case ENT_CLIENT_LGBEAM:
			vs = electro_shotorigin[s];
			break;
		case ENT_CLIENT_GAUNTLET:
			vs = gauntlet_shotorigin[s];
			break;
	}

	if((self.owner.sv_entnum == player_localentnum - 1))
	{
		switch(self.HookType)
		{
			default:
			case ENT_CLIENT_HOOK:
				a = view_origin + view_forward * vs_x + view_right * -vs_y + view_up * vs_z;
				b = self.origin;
				break;
			case ENT_CLIENT_LGBEAM:
			case ENT_CLIENT_GAUNTLET:
				b = view_origin + view_forward * MAX_SHOT_DISTANCE;
				WarpZone_TraceLine(view_origin, b, MOVE_NORMAL, world);
				b = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
				a = view_origin + view_forward * vs_x + view_right * -vs_y + view_up * vs_z;
				break;
		}
	}
	else
	{
		switch(self.HookType)
		{
			default:
			case ENT_CLIENT_HOOK:
				a = self.velocity;
				b = self.origin;
				break;
			case ENT_CLIENT_LGBEAM:
			case ENT_CLIENT_GAUNTLET:
				a = self.origin;
				b = self.velocity;
				break;
		}
	}

	t = GetPlayerColorForce(self.owner.sv_entnum);

	switch(self.HookType)
	{
		default:
		case ENT_CLIENT_HOOK:
			if(t == COLOR_TEAM1)
			{
				tex = "particles/hook_red";
				rgb = '1 .3 .3';
			}
			else if(t == COLOR_TEAM2)
			{
				tex = "particles/hook_blue";
				rgb = '.3 .3 1';
			}
			else if(t == COLOR_TEAM3)
			{
				tex = "particles/hook_yellow";
				rgb = '1 1 .3';
			}
			else if(t == COLOR_TEAM4)
			{
				tex = "particles/hook_pink";
				rgb = '1 .3 1';
			}
			else
			{
				tex = "particles/hook_green";
				rgb = '.3 1 .3';
			}
			break;
		case ENT_CLIENT_LGBEAM:
			tex = "particles/lgbeam";
			rgb = '1 1 1';
			break;
		case ENT_CLIENT_GAUNTLET:
			tex = "particles/gauntletbeam";
			rgb = '1 1 1';
			break;
	}

	Draw_GrapplingHook_trace_callback_tex = tex;
	Draw_GrapplingHook_trace_callback_rnd = random();
	WarpZone_TraceBox_ThroughZone(a, '0 0 0', '0 0 0', b, MOVE_NOMONSTERS, world, world, Draw_GrapplingHook_trace_callback);
	Draw_GrapplingHook_trace_callback_tex = string_null;

	switch(self.HookType)
	{
		default:
		case ENT_CLIENT_HOOK:
			self.angles = vectoangles(b - a);
			break;
		case ENT_CLIENT_LGBEAM:
		case ENT_CLIENT_GAUNTLET:
			break;
	}
}

void Remove_GrapplingHook()
{
	sound (self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);
}

void Ent_ReadHook(float bIsNew, float type)
{
	self.HookType = type;

	float sf;
	sf = ReadByte();

	self.HookSilent = (sf & 0x80);
	self.iflags = IFLAG_VELOCITY;

	InterpolateOrigin_Undo();

	if(sf & 1)
	{
		self.owner = playerslots[ReadByte() - 1];
	}
	if(sf & 2)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
	}
	if(sf & 4)
	{
		self.velocity_x = ReadCoord();
		self.velocity_y = ReadCoord();
		self.velocity_z = ReadCoord();
	}

	InterpolateOrigin_Note();

	if(bIsNew)
	{
		self.draw = Draw_GrapplingHook;
		self.entremove = Remove_GrapplingHook;

		switch(self.HookType)
		{
			default:
			case ENT_CLIENT_HOOK:
				// for the model
				setmodel(self, "models/hook.md3");
				self.drawmask = MASK_NORMAL;
				break;
			case ENT_CLIENT_LGBEAM:
				sound (self, CHAN_PROJECTILE, "weapons/lgbeam_fly.wav", VOL_BASE, ATTN_NORM);
				break;
			case ENT_CLIENT_GAUNTLET:
				sound (self, CHAN_PROJECTILE, "weapons/gauntletbeam_fly.wav", VOL_BASE, ATTN_NORM);
				break;
		}
	}
}

void Hook_Precache()
{
	precache_sound("weapons/lgbeam_fly.wav");
	precache_sound("weapons/gauntletbeam_fly.wav");
	precache_model("models/hook.md3");
}

// TODO: hook: temporarily transform self.origin for drawing the model along warpzones!
