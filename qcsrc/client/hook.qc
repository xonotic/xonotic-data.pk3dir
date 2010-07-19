.vector HookStart;
.vector HookEnd;
.float HookKillTime;
.vector LGBeamStart;
.vector LGBeamEnd;
.float LGBeamKillTime;
.float LGBeamSound;
.float LGBeamSilent;

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
	string tex;
	vector rgb;
	float t;
	float s;
	vector vs;

	if(time < self.HookKillTime)
	{
		s = cvar("cl_gunalign");
		if(s != 1 && s != 2 && s != 4)
			s = 3; // default value
		--s;
		vs = hook_shotorigin[s];

		if(self.sv_entnum == player_localentnum - 1)
			a = view_origin + view_forward * vs_x + view_right * vs_y + view_up * vs_z;
		else
			a = self.HookStart;
		b = self.HookEnd;

		t = GetPlayerColorForce(self.sv_entnum);

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

		Draw_GrapplingHook_trace_callback_tex = tex;
		Draw_GrapplingHook_trace_callback_rnd = random();
		WarpZone_TraceBox_ThroughZone(a, '0 0 0', '0 0 0', b, MOVE_NOMONSTERS, world, world, Draw_GrapplingHook_trace_callback);
		Draw_GrapplingHook_trace_callback_tex = string_null;
	}

	if(time < self.LGBeamKillTime)
	{
		s = cvar("cl_gunalign");
		if(s != 1 && s != 2 && s != 4)
			s = 3; // default value
		--s;
		vs = electro_shotorigin[s];

		if(self.sv_entnum == player_localentnum - 1)
			a = view_origin + view_forward * vs_x + view_right * vs_y + view_up * vs_z;
		else
			a = self.LGBeamStart;
		b = self.LGBeamEnd;

		tex = "particles/lgbeam";
		rgb = '1 1 1';

		Draw_GrapplingHook_trace_callback_tex = tex;
		Draw_GrapplingHook_trace_callback_rnd = random();
		WarpZone_TraceBox_ThroughZone(a, '0 0 0', '0 0 0', b, MOVE_NOMONSTERS, world, world, Draw_GrapplingHook_trace_callback);
		Draw_GrapplingHook_trace_callback_tex = string_null;
	}

	if(time < self.LGBeamKillTime && !self.LGBeamSilent)
	{
		if(!self.LGBeamSound)
		{
			sound (self, CHAN_PROJECTILE, "weapons/lgbeam_fly.wav", VOL_BASE, ATTN_NORM);
			self.LGBeamSound = 1;
		}
	}
	else
	{
		if(self.LGBeamSound)
		{
			sound (self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);
			self.LGBeamSound = 0;
		}
	}
}

void Net_GrapplingHook()
{
	float i, t;
	vector start, end;
	entity p;

	i = ReadByte();
	t = ReadByte();
	end_x = ReadCoord();
	end_y = ReadCoord();
	end_z = ReadCoord();
	start_x = ReadCoord();
	start_y = ReadCoord();
	start_z = ReadCoord();

	if(i <= 0 || i >= 256) // not owned by a client
		return;
	--i;

	p = playerslots[i];
	if(!p)
		return;

	switch(t)
	{
		case 0: // hook beam
			p.HookKillTime = time + 0.1;
			p.HookStart = start;
			p.HookEnd = end;
			p.draw = Draw_GrapplingHook;
			break;
		case 1: // electro lgbeam
			p.LGBeamKillTime = time + 0.1;
			p.LGBeamStart = start;
			p.LGBeamEnd = end;
			p.LGBeamSilent = 0;
			p.draw = Draw_GrapplingHook;
			break;
		case 2: // silent electro lgbeam
			p.LGBeamKillTime = time + 0.1;
			p.LGBeamStart = start;
			p.LGBeamEnd = end;
			p.LGBeamSilent = 1;
			p.draw = Draw_GrapplingHook;
			break;
	}
}

void Hook_Precache()
{
	precache_sound("weapons/lgbeam_fly.wav");
}
