.float dphitcontentsmask;

.float cnt; // effect number
.vector velocity; // particle velocity
.float waterlevel; // direction jitter
.float count; // count multiplier
.float impulse; // density
.string noise; // sound
.float atten;
.float volume;
.float absolute; // 1 = count per second is absolute, 2 = only spawn at toggle
.vector movedir; // trace direction

void Draw_PointParticles()
{
	float n, i, fail;
	vector p;
	vector sz;
	vector o;
	o = self.origin;
	sz = self.maxs - self.mins;
	n = BGMScript(self);
	if(self.absolute == 2)
	{
		if(n >= 0)
			n = self.just_toggled ? self.impulse : 0;
		else
			n = self.impulse * drawframetime;
	}
	else
	{
		n *= self.impulse * drawframetime;
		if(self.just_toggled)
			if(n < 1)
				n = 1;
	}
	if(n == 0)
		return;
	fail = 0;
	for(i = random(); i <= n && fail <= 64*n; ++i)
	{
		p = o + self.mins;
		p_x += random() * sz_x;
		p_y += random() * sz_y;
		p_z += random() * sz_z;
		if(WarpZoneLib_BoxTouchesBrush(p, p, self, world))
		{
			if(self.movedir != '0 0 0')
			{
				traceline(p, p + normalize(self.movedir) * 4096, 0, world);
				p = trace_endpos;
				pointparticles(self.cnt, p, trace_plane_normal * vlen(self.movedir) + self.velocity + randomvec() * self.waterlevel, self.count);
			}
			else
			{
				pointparticles(self.cnt, p, self.velocity + randomvec() * self.waterlevel, self.count);
			}
			if(self.noise != "")
			{
				setorigin(self, p);
				sound(self, CH_AMBIENT, self.noise, VOL_BASE * self.volume, self.atten);
			}
			self.just_toggled = 0;
		}
		else if(self.absolute)
		{
			++fail;
			--i;
		}
	}
	setorigin(self, o);
}

void Ent_PointParticles_Remove()
{
	if(self.noise)
		strunzone(self.noise);
	self.noise = string_null;
	if(self.bgmscript)
		strunzone(self.bgmscript);
	self.bgmscript = string_null;
}

void Ent_PointParticles()
{
	float f, i;
	vector v;
	f = ReadByte();
	if(f & 2)
	{
		i = ReadCoord(); // density (<0: point, >0: volume)
		if(i && !self.impulse && self.cnt) // self.cnt check is so it only happens if the ent already existed
			self.just_toggled = 1;
		self.impulse = i;
	}
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	if(f & 1)
	{
		self.modelindex = ReadShort();
		if(f & 0x80)
		{
			if(self.modelindex)
			{
				self.mins_x = ReadCoord();
				self.mins_y = ReadCoord();
				self.mins_z = ReadCoord();
				self.maxs_x = ReadCoord();
				self.maxs_y = ReadCoord();
				self.maxs_z = ReadCoord();
			}
			else
			{
				self.mins    = '0 0 0';
				self.maxs_x = ReadCoord();
				self.maxs_y = ReadCoord();
				self.maxs_z = ReadCoord();
			}
		}
		else
		{
			self.mins = self.maxs = '0 0 0';
		}

		self.cnt = ReadShort(); // effect number

		if(f & 0x20)
		{
			self.velocity = decompressShortVector(ReadShort());
			self.movedir = decompressShortVector(ReadShort());
		}
		else
		{
			self.velocity = self.movedir = '0 0 0';
		}
		if(f & 0x40)
		{
			self.waterlevel = ReadShort() / 16.0;
			self.count = ReadByte() / 16.0;
		}
		else
		{
			self.waterlevel = 0;
			self.count = 1;
		}
		if(self.noise)
			strunzone(self.noise);
		if(self.bgmscript)
			strunzone(self.bgmscript);
		self.noise = strzone(ReadString());
		if(self.noise != "")
		{
			self.atten = ReadByte() / 64.0;
			self.volume = ReadByte() / 255.0;
		}
		self.bgmscript = strzone(ReadString());
		if(self.bgmscript != "")
		{
			self.bgmscriptattack = ReadByte() / 64.0;
			self.bgmscriptdecay = ReadByte() / 64.0;
			self.bgmscriptsustain = ReadByte() / 255.0;
			self.bgmscriptrelease = ReadByte() / 64.0;
		}
		BGMScript_InitEntity(self);
	}

	if(f & 2)
	{
		self.absolute = (self.impulse >= 0);
		if(!self.absolute)
		{
			v = self.maxs - self.mins;
			self.impulse *= -v_x * v_y * v_z / 262144; // relative: particles per 64^3 cube
		}
	}

	if(f & 0x10)
		self.absolute = 2;

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	self.draw = Draw_PointParticles;
	self.entremove = Ent_PointParticles_Remove;
}

.float glow_color; // palette index
void Draw_Rain()
{
    te_particlerain(self.origin + self.mins, self.origin + self.maxs, self.velocity, floor(self.count * drawframetime + random()), self.glow_color);
}

void Draw_Snow()
{
    te_particlesnow(self.origin + self.mins, self.origin + self.maxs, self.velocity, floor(self.count * drawframetime + random()), self.glow_color);
}

void Ent_RainOrSnow()
{
	self.impulse = ReadByte(); // Rain, Snow, or Whatever
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.velocity = decompressShortVector(ReadShort());
	self.count = ReadShort() * 10;
	self.glow_color = ReadByte(); // color

	self.mins    = -0.5 * self.maxs;
	self.maxs    =  0.5 * self.maxs;
	self.origin  = self.origin - self.mins;

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	if(self.impulse)
		self.draw = Draw_Rain;
	else
		self.draw = Draw_Snow;
}

void Net_ReadVortexBeamParticle()
{
	vector shotorg, endpos;
	float charge;
	shotorg_x = ReadCoord(); shotorg_y = ReadCoord(); shotorg_z = ReadCoord();
	endpos_x = ReadCoord(); endpos_y = ReadCoord(); endpos_z = ReadCoord();
	charge = ReadByte() / 255.0;

	pointparticles(particleeffectnum("nex_muzzleflash"), shotorg, normalize(endpos - shotorg) * 1000, 1);

	//draw either the old v2.3 beam or the new beam
	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;

	if (autocvar_cl_particles_oldnexbeam && (getstati(STAT_ALLOW_OLDNEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum("TE_TEI_G3"), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum("nex_beam"), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
}

.vector sw_shotorg;
.vector sw_endpos;
.float sw_spread_max;
.float sw_spread_min;
.float sw_time;

void Draw_Shockwave()
{
	float a = bound(0, (0.5 - ((time - self.sw_time) / 0.4)), 0.5);

	if(!a) { remove(self); }
	
	vector deviation, angle;

	vector sw_color = getcsqcplayercolor(self.sv_entnum); // GetTeamRGB(GetPlayerColor(self.sv_entnum));

	vector first_min_end = '0 0 0', prev_min_end = '0 0 0', new_min_end = '0 0 0';
	vector first_max_end = '0 0 0', prev_max_end = '0 0 0', new_max_end = '0 0 0';

	float new_max_dist, new_min_dist;
	
	vector shotdir = normalize(self.sw_endpos - self.sw_shotorg);
	vectorvectors(shotdir);
	vector right = v_right;
	vector up = v_up;
	
	float counter, dist_before_normal = 200, shots = 20;
	
	vector min_end = ((self.sw_shotorg + (shotdir * dist_before_normal)) + (up * self.sw_spread_min));
	vector max_end = (self.sw_endpos + (up * self.sw_spread_max));
	
	float spread_to_min = vlen(normalize(min_end - self.sw_shotorg) - shotdir);
	float spread_to_max = vlen(normalize(max_end - min_end) - shotdir);
	
	for(counter = 0; counter < shots; ++counter)
	{
		// perfect circle effect lines
		angle = '0 0 0';
		makevectors('0 360 0' * (0.75 + (counter - 0.5) / shots));
		angle_y = v_forward_x;
		angle_z = v_forward_y;

		// first do the spread_to_min effect
		deviation = angle * spread_to_min;
		deviation = ((shotdir + (right * deviation_y) + (up * deviation_z)));
		new_min_dist = dist_before_normal;
		new_min_end = (self.sw_shotorg + (deviation * new_min_dist));
		//te_lightning2(world, new_min_end, self.sw_shotorg);

		// then calculate spread_to_max effect
		deviation = angle * spread_to_max;
		deviation = ((shotdir + (right * deviation_y) + (up * deviation_z)));
		new_max_dist = vlen(new_min_end - self.sw_endpos);
		new_max_end = (new_min_end + (deviation * new_max_dist));
		//te_lightning2(world, new_end, prev_min_end);
		

		if(counter == 0)
		{
			first_min_end = new_min_end;
			first_max_end = new_max_end;
		}

		if(counter >= 1)
		{
			R_BeginPolygon("", DRAWFLAG_NORMAL);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(new_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(self.sw_shotorg, '0 0 0', sw_color, a);
			R_EndPolygon();

			R_BeginPolygon("", DRAWFLAG_NORMAL);
			R_PolygonVertex(new_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_max_end, '0 0 0', sw_color, a);
			R_PolygonVertex(new_max_end, '0 0 0', sw_color, a);
			R_EndPolygon();
		}

		prev_min_end = new_min_end;
		prev_max_end = new_max_end;

		if((counter + 1) == shots)
		{
			R_BeginPolygon("", DRAWFLAG_NORMAL);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(first_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(self.sw_shotorg, '0 0 0', sw_color, a);
			R_EndPolygon();

			R_BeginPolygon("", DRAWFLAG_NORMAL);
			R_PolygonVertex(first_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_max_end, '0 0 0', sw_color, a);
			R_PolygonVertex(first_max_end, '0 0 0', sw_color, a);
			R_EndPolygon();
		}
	}
}

void Net_ReadShockwaveParticle()
{
	entity shockwave;
	shockwave = spawn();
	shockwave.draw = Draw_Shockwave;
	
	shockwave.sw_shotorg_x = ReadCoord(); shockwave.sw_shotorg_y = ReadCoord(); shockwave.sw_shotorg_z = ReadCoord();
	shockwave.sw_endpos_x  = ReadCoord(); shockwave.sw_endpos_y  = ReadCoord(); shockwave.sw_endpos_z  = ReadCoord();
	
	shockwave.sw_spread_max = ReadByte();
	shockwave.sw_spread_min = ReadByte();

	shockwave.sv_entnum = ReadByte();

	shockwave.sw_time = time;
}

.float beam_usevieworigin;
.float beam_initialized;
.vector beam_shotorigin;
.vector beam_dir;
void Draw_ArcBeam()
{
	if(self.teleport_time)
	if(time > self.teleport_time)
	{
		sound(self, CH_SHOTS_SINGLE, "misc/null.wav", VOL_BASE, ATTEN_NORM); // safeguard
		self.teleport_time = 0;
	}

	InterpolateOrigin_Do();

	// origin = beam starting origin
	// v_angle = wanted/aim direction
	// angles = current direction of beam

	vector start_pos;
	vector wantdir; //= view_forward;
	vector beamdir; //= self.beam_dir;

	if(self.beam_usevieworigin)
	{
		// find *exactly* where we are aiming
		makevectors(view_angles);

		// decide upon start position
		if(self.beam_usevieworigin == 2)
			{ start_pos = view_origin; }
		else
			{ start_pos = self.origin; }

		// trace forward with an estimation
		WarpZone_TraceLine(start_pos, start_pos + view_forward * cvar("g_balance_arc_beam_range"), MOVE_NOMONSTERS, self);

		// untransform in case our trace went through a warpzone
		vector vf, vr, vu;
		vf = view_forward;
		vr = view_right;
		vu = view_up;
		vector shothitpos = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
		view_forward = vf;
		view_right = vr;
		view_up = vu;

		// un-adjust trueaim if shotend is too close
		if(vlen(shothitpos - view_origin) < cvar("g_trueaim_minrange"))
			shothitpos = view_origin + (view_forward * cvar("g_trueaim_minrange"));

		// move shot origin to the actual gun muzzle origin
		vector origin_offset = view_forward * self.beam_shotorigin_x + view_right * -self.beam_shotorigin_y + view_up * self.beam_shotorigin_z;
		start_pos = start_pos + origin_offset;

		// calculate the aim direction now
		wantdir = normalize(shothitpos - start_pos);

		if(!self.beam_initialized)
		{
			self.beam_dir = wantdir;
			self.beam_initialized = TRUE;
		}

		if(self.beam_dir != wantdir)
		{
			float angle = ceil(vlen(wantdir - self.beam_dir) * RAD2DEG);
			float anglelimit;
			if(angle && (angle > cvar("g_balance_arc_beam_maxangle")))
			{
				// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
				anglelimit = min(cvar("g_balance_arc_beam_maxangle") / angle, 1);
			}
			else
			{
				// the radius is not too far yet, no worries :D
				anglelimit = 1;
			}

			// calculate how much we're going to move the end of the beam to the want position
			float blendfactor = bound(0, anglelimit * (1 - (cvar("g_balance_arc_beam_returnspeed") * frametime)), 1);
			self.beam_dir = normalize((wantdir * (1 - blendfactor)) + (self.beam_dir * blendfactor));
		}

		// finally, set the beam direction which the rest of the code will refer to
		beamdir = self.beam_dir;
	}
	else
	{
		// set the values from the provided info from the networked entity
		start_pos = self.origin;
		wantdir = self.v_angle;
		beamdir = self.angles;
	}

	setorigin(self, start_pos);

	vector beam_endpos_estimate = (start_pos + (beamdir * cvar("g_balance_arc_beam_range")));

	float i;
	float segments = 20; // todo: calculate this in a similar way to server does
	float maxthickness = 8;


	vector thickdir = normalize(cross(beamdir, view_origin - start_pos));

	vector last_origin = start_pos;

	float lastthickness = 0;

	vector last_top = start_pos + (thickdir * lastthickness);
	vector last_bottom = start_pos - (thickdir * lastthickness);

	for(i = 1; i <= segments; ++i)
	{
		// calculate this on every segment to ensure that we always reach the full length of the attack
		float segmentblend = (i/segments);
		float segmentdist = vlen(beam_endpos_estimate - last_origin) * (i/segments);

		vector new_dir = normalize( (wantdir * (1 - segmentblend)) + (normalize(beam_endpos_estimate - last_origin) * segmentblend) );
		vector new_origin = last_origin + (new_dir * segmentdist);

		WarpZone_TraceLine(
			last_origin,
			new_origin,
			MOVE_NORMAL,
			self
		);

		vector hitorigin;

		// draw segment
		if(trace_fraction != 1)
		{
			// calculate our own hit origin as trace_endpos tends to jump around annoyingly (to player origin?)
			hitorigin = last_origin + (new_dir * segmentdist * trace_fraction);
		}
		else
		{
			hitorigin = new_origin;
		}

		#if 0
		float falloff = ExponentialFalloff(
			WEP_CVAR(arc, beam_falloff_mindist),
			WEP_CVAR(arc, beam_falloff_maxdist),
			WEP_CVAR(arc, beam_falloff_halflifedist),
			vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, hitorigin) - start_pos)
		);
		#else
		//float falloff = 1;
		#endif

		float thickness = 8;

		vector top    = hitorigin + (thickdir * thickness);
		vector bottom = hitorigin - (thickdir * thickness);

		R_BeginPolygon("particles/lgbeam", DRAWFLAG_NORMAL);
		R_PolygonVertex(top,         '0 0.5 0' + ('0 0.5 0' * (thickness / maxthickness)), '0.5 0.5 1', 0.5);
		R_PolygonVertex(last_top,    '0 0.5 0' + ('0 0.5 0' * (lastthickness / maxthickness)), '0.5 0.5 1', 0.5);
		R_PolygonVertex(last_bottom, '0 0.5 0' * (1 - (lastthickness / maxthickness)), '0.5 0.5 1', 0.5);
		R_PolygonVertex(bottom,      '0 0.5 0' * (1 - (thickness / maxthickness)), '0.5 0.5 1', 0.5);
		R_EndPolygon();

		// draw collision effect
		if(trace_fraction != 1)
		{
			#if 0
			switch(self.beam_type)
			{
				//case ARC_BT_MISS: te_customflash(hitorigin, 40, 5, '1 1 0'); break;
				case ARC_BT_WALL: te_customflash(hitorigin, 40, 2, '0 0 1'); break;
				case ARC_BT_HIT:  te_customflash(hitorigin, 80, 5, '1 0 0'); break;
				//case ARC_BT_MISS: te_customflash(hitorigin, 80, 5, '0 1 0'); break;
				default: te_customflash(hitorigin, 40, 2, '0 1 0'); break;
			}
			#endif
			pointparticles(particleeffectnum("electro_lightning"), hitorigin, beamdir * -1, frametime * 2);
			break; // we're done with drawing this frame
		}
		else
		{
			last_origin = new_origin; // continue onto the next segment
			last_top = top;
			last_bottom = bottom;
			lastthickness = thickness;
		}
	}

	if(trace_fraction == 1)
	{
		// do end of beam effect here
	}
}

void Remove_ArcBeam(void)
{
	sound(self, CH_SHOTS_SINGLE, "misc/null.wav", VOL_BASE, ATTEN_NORM);
}

void Ent_ReadArcBeam(float isnew)
{
	float sf = ReadByte();

	// self.iflags = IFLAG_ORIGIN | IFLAG_ANGLES | IFLAG_V_ANGLE; // why doesn't this work?
	self.iflags = IFLAG_ORIGIN;

	InterpolateOrigin_Undo();

	if(sf & 1) // starting location // not sent if beam is for owner
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		self.beam_usevieworigin = 0;
		//WriteCoord(MSG_ENTITY, WEP_CVAR(arc, beam_range));
	}
	else // infer the location from player location
	{
		if(autocvar_chase_active) // use player origin so that third person display still works
		{
			self.beam_usevieworigin = 1;
			self.origin = getplayerorigin(player_localnum) + ('0 0 1' * getstati(STAT_VIEWHEIGHT));
		}
		else // use view origin
		{
			self.beam_usevieworigin = 2;
			self.origin = view_origin; // note that this is only necessary for the sound to be properly located
		}
		setorigin(self, self.origin);
	}
	
	if(sf & 2) // want/aim direction
	{
		self.v_angle_x = ReadCoord();
		self.v_angle_y = ReadCoord();
		self.v_angle_z = ReadCoord();
	}
	if(sf & 4) // beam direction
	{
		self.angles_x = ReadCoord();
		self.angles_y = ReadCoord();
		self.angles_z = ReadCoord();
	}
	if(sf & 8) // beam type
	{
		self.beam_type = ReadByte();
	}

	InterpolateOrigin_Note();

	if(isnew || !self.teleport_time)
	{
		// calculate shot origin offset from gun alignment
		float gunalign = autocvar_cl_gunalign;
		if(gunalign != 1 && gunalign != 2 && gunalign != 4)
			gunalign = 3; // default value
		--gunalign;

		self.beam_shotorigin = arc_shotorigin[gunalign];

		// set other main attributes of the beam
		self.draw = Draw_ArcBeam;
		self.entremove = Remove_ArcBeam;
		sound(self, CH_SHOTS_SINGLE, "weapons/lgbeam_fly.wav", VOL_BASE, ATTEN_NORM);
	}

	self.teleport_time = time + 10;

	#if 0
	printf(
		"Ent_ReadArcBeam(%d): sf = %d, start = %s, want = %s, dir = %s, type = %d\n",
		isnew,
		sf,
		vtos(self.beam_start),
		vtos(self.v_angle),
		vtos(self.angles),
		self.beam_type
	);
	#endif
}

