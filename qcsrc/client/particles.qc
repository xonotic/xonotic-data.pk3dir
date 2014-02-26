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

.vector beam_color;
.float beam_alpha;
.float beam_thickness;
.float beam_traileffect;
.float beam_hiteffect;
.float beam_hitlight[4]; // 0: radius, 123: rgb
.float beam_muzzleeffect;
.float beam_muzzlelight[4]; // 0: radius, 123: rgb
.string beam_image;

.entity beam_muzzleentity;

.float beam_usevieworigin;
.float beam_initialized;
.float beam_maxangle;
.float beam_range;
.float beam_returnspeed;
.float beam_tightness;
.vector beam_shotorigin;
.vector beam_dir;

entity Draw_ArcBeam_callback_entity;
vector Draw_ArcBeam_callback_new_dir;
float Draw_ArcBeam_callback_segmentdist;
float Draw_ArcBeam_callback_last_thickness;
vector Draw_ArcBeam_callback_last_top;
vector Draw_ArcBeam_callback_last_bottom;

void Draw_ArcBeam_callback(vector start, vector hit, vector end)
{
	entity beam = Draw_ArcBeam_callback_entity;
	vector transformed_view_org;
	transformed_view_org = WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin);

	vector thickdir = normalize(cross(normalize(start - hit), transformed_view_org - start));

	vector hitorigin;

	// draw segment
	#if 0
	if(trace_fraction != 1)
	{
		// calculate our own hit origin as trace_endpos tends to jump around annoyingly (to player origin?)
		hitorigin = start + (Draw_ArcBeam_callback_new_dir * Draw_ArcBeam_callback_segmentdist * trace_fraction);
		hitorigin = WarpZone_TransformOrigin(WarpZone_trace_transform, hitorigin);
	}
	else
	{
		hitorigin = hit;
	}
	#else
	hitorigin = hit;
	#endif

	// decide upon thickness
	float thickness = beam.beam_thickness;

	// draw primary beam render
	vector top    = hitorigin + (thickdir * thickness);
	vector bottom = hitorigin - (thickdir * thickness);
	//vector last_top    = start + (thickdir * Draw_ArcBeam_callback_last_thickness);
	//vector last_bottom = start - (thickdir * Draw_ArcBeam_callback_last_thickness);

	R_BeginPolygon(beam.beam_image, DRAWFLAG_NORMAL); // DRAWFLAG_ADDITIVE
	R_PolygonVertex(
		top,
		'0 0.5 0' + ('0 0.5 0' * (thickness / beam.beam_thickness)),
		beam.beam_color,
		beam.beam_alpha
	);
	R_PolygonVertex(
		Draw_ArcBeam_callback_last_top,
		'0 0.5 0' + ('0 0.5 0' * (Draw_ArcBeam_callback_last_thickness / beam.beam_thickness)),
		beam.beam_color,
		beam.beam_alpha
	);
	R_PolygonVertex(
		Draw_ArcBeam_callback_last_bottom,
		'0 0.5 0' * (1 - (Draw_ArcBeam_callback_last_thickness / beam.beam_thickness)),
		beam.beam_color,
		beam.beam_alpha
	);
	R_PolygonVertex(
		bottom,
		'0 0.5 0' * (1 - (thickness / beam.beam_thickness)),
		beam.beam_color,
		beam.beam_alpha
	);
	R_EndPolygon();

	// draw trailing particles
	// NOTES:
	//  - Don't use spammy particle counts here, use a FEW small particles around the beam
	//  - We're not using WarpZone_TrailParticles here because we will handle warpzones ourselves.
	if(beam.beam_traileffect)
	{
		trailparticles(beam, beam.beam_traileffect, start, hitorigin);
	}

	// set up for the next 
	Draw_ArcBeam_callback_last_thickness = thickness;
	Draw_ArcBeam_callback_last_top = top;
	Draw_ArcBeam_callback_last_bottom = bottom;
}

void Draw_ArcBeam()
{
	if(!self.beam_usevieworigin)
	{
		InterpolateOrigin_Do();
	}

	// origin = beam starting origin
	// v_angle = wanted/aim direction
	// angles = current direction of beam

	vector start_pos;
	vector wantdir; //= view_forward;
	vector beamdir; //= self.beam_dir;

	float segments;
	if(self.beam_usevieworigin)
	{
		// WEAPONTODO:
		// Currently we have to replicate nearly the same method of figuring
		// out the shotdir that the server does... Ideally in the future we
		// should be able to acquire this from a generalized function built
		// into a weapon system for client code. 

		// find where we are aiming
		makevectors(view_angles);

		// decide upon start position
		if(self.beam_usevieworigin == 2)
			{ start_pos = view_origin; }
		else
			{ start_pos = self.origin; }

		// trace forward with an estimation
		WarpZone_TraceLine(
			start_pos,
			start_pos + view_forward * self.beam_range,
			MOVE_NOMONSTERS,
			self
		);

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
		if(vlen(shothitpos - view_origin) < g_trueaim_minrange)
			shothitpos = view_origin + (view_forward * g_trueaim_minrange);

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

		// WEAPONTODO: Calculate segments dyanmically similarly to the server code
		segments = 20;
		if(self.beam_dir != wantdir)
		{
			float angle = ceil(vlen(wantdir - self.beam_dir) * RAD2DEG);
			float anglelimit;
			if(angle && (angle > self.beam_maxangle))
			{
				// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
				anglelimit = min(self.beam_maxangle / angle, 1);
			}
			else
			{
				// the radius is not too far yet, no worries :D
				anglelimit = 1;
			}

			// calculate how much we're going to move the end of the beam to the want position
			float blendfactor = bound(0, anglelimit * (1 - (self.beam_returnspeed * frametime)), 1);
			self.beam_dir = normalize((wantdir * (1 - blendfactor)) + (self.beam_dir * blendfactor));

			// WEAPONTODO (server and client):
			// blendfactor never actually becomes 0 in this situation, which is a problem
			// regarding precision... this means that self.beam_dir and w_shotdir approach
			// eachother, however they never actually become the same value with this method.

			// Perhaps we should do some form of rounding/snapping?

			// printf("blendfactor = %f\n", blendfactor);

			#if 0
			// calculate how many segments are needed
			float max_allowed_segments;

			if(WEP_CVAR(arc, beam_distancepersegment))
				max_allowed_segments = min(ARC_MAX_SEGMENTS, 1 + (vlen(w_shotdir / WEP_CVAR(arc, beam_distancepersegment))));
			else
				max_allowed_segments = ARC_MAX_SEGMENTS;

			if(WEP_CVAR(arc, beam_degreespersegment))
			{
				segments = min( max(1, ( min(angle, WEP_CVAR(arc, beam_maxangle)) / WEP_CVAR(arc, beam_degreespersegment) ) ), max_allowed_segments );
			}
			else
			{
				segments = 1;
			}
			#endif
		}
		#if 0
		else
		{
			segments = 1;
		}
		#endif

		// set the beam direction which the rest of the code will refer to
		beamdir = self.beam_dir;

		// finally, set self.angles to the proper direction so that muzzle attachment points in proper direction
		self.angles = fixedvectoangles2(view_forward, view_up);
	}
	else
	{
		// set the values from the provided info from the networked entity
		start_pos = self.origin;
		wantdir = self.v_angle;
		beamdir = self.angles;

		// WEAPONTODO: Calculate segments dyanmically similarly to the server code
		segments = 20;
		#if 0
		if(beamdir != wantdir)
		{
			// calculate how many segments are needed
			float max_allowed_segments;

			if(WEP_CVAR(arc, beam_distancepersegment))
				max_allowed_segments = min(ARC_MAX_SEGMENTS, 1 + (vlen(w_shotdir / WEP_CVAR(arc, beam_distancepersegment))));
			else
				max_allowed_segments = ARC_MAX_SEGMENTS;

			if(WEP_CVAR(arc, beam_degreespersegment))
			{
				segments = min( max(1, ( min(angle, WEP_CVAR(arc, beam_maxangle)) / WEP_CVAR(arc, beam_degreespersegment) ) ), max_allowed_segments );
			}
			else
			{
				segments = 1;
			}
		}
		else
		{
			segments = 1;
		}
		#endif
	}

	setorigin(self, start_pos);
	self.beam_muzzleentity.angles_z = random() * 360; // WEAPONTODO: use avelocity instead?

	vector beam_endpos_estimate = (start_pos + (beamdir * self.beam_range));

	Draw_ArcBeam_callback_entity = self;
	Draw_ArcBeam_callback_last_thickness = 0;
	Draw_ArcBeam_callback_last_top = start_pos;
	Draw_ArcBeam_callback_last_bottom = start_pos;

	vector last_origin = start_pos;

	float i;
	for(i = 1; i <= segments; ++i)
	{
		// WEAPONTODO (server and client):
		// Segment blend and distance should probably really be calculated in a better way,
		// however I am not sure how to do it properly. There are a few things I have tried,
		// but most of them do not work properly due to my lack of understanding regarding
		// the mathematics behind them.

		// Ideally, we should calculate the positions along a perfect curve
		// between wantdir and self.beam_dir with an option for depth of arc

		// Another issue is that (on the client code) we must separate the
		// curve into multiple rendered curves when handling warpzones.

		// I can handle this by detecting it for each segment, however that
		// is a fairly inefficient method in comparison to having a curved line
		// drawing function similar to Draw_CylindricLine that accepts
		// top and bottom origins as input, this way there would be no
		// overlapping edges when connecting the curved pieces.

		// WEAPONTODO (client):
		// In order to do nice fading and pointing on the starting segment, we must always
		// have that drawn as a separate triangle... However, that is difficult to do when
		// keeping in mind the above problems and also optimizing the amount of segments
		// drawn on screen at any given time. (Automatic beam quality scaling, essentially)

		// calculate this on every segment to ensure that we always reach the full length of the attack
		float segmentblend = bound(0, (i/segments) + self.beam_tightness, 1);
		float segmentdist = vlen(beam_endpos_estimate - last_origin) * (i/segments);

		vector new_dir = normalize( (wantdir * (1 - segmentblend)) + (normalize(beam_endpos_estimate - last_origin) * segmentblend) );
		vector new_origin = last_origin + (new_dir * segmentdist);

		Draw_ArcBeam_callback_segmentdist = segmentdist;
		Draw_ArcBeam_callback_new_dir = new_dir;

		WarpZone_TraceBox_ThroughZone(
			last_origin,
			'0 0 0',
			'0 0 0',
			new_origin,
			MOVE_NORMAL,
			world,
			world,
			Draw_ArcBeam_callback
		);

		//printf("segment: %d, warpzone transform: %d\n", i, (WarpZone_trace_transform != world));

		// WEAPONTODO:
		// Figure out some way to detect a collision with geometry with callback...
		// That way we can know when we are done drawing the beam and skip
		// the rest of the segments without breaking warpzone support.

		last_origin = WarpZone_TransformOrigin(WarpZone_trace_transform, new_origin);
		beam_endpos_estimate = WarpZone_TransformOrigin(WarpZone_trace_transform, beam_endpos_estimate);
	}

	// startpoint and endpoint drawn visual effects
	if(self.beam_hiteffect)
	{
		pointparticles(
			self.beam_hiteffect,
			last_origin,
			beamdir * -1,
			frametime * 2
		);
	}
	if(self.beam_hitlight[0])
	{
		adddynamiclight(
			last_origin,
			self.beam_hitlight[0],
			vec3(
				self.beam_hitlight[1],
				self.beam_hitlight[2],
				self.beam_hitlight[3]
			)
		);
	}
	if(self.beam_muzzleeffect)
	{
		pointparticles(
			self.beam_muzzleeffect,
			start_pos + wantdir * 20,
			wantdir * 1000,
			frametime * 0.1
		);
	}
	if(self.beam_muzzlelight[0])
	{
		adddynamiclight(
			start_pos + wantdir * 20,
			self.beam_muzzlelight[0],
			vec3(
				self.beam_muzzlelight[1],
				self.beam_muzzlelight[2],
				self.beam_muzzlelight[3]
			)
		);
	}

	// cleanup
	Draw_ArcBeam_callback_entity = world;
	Draw_ArcBeam_callback_new_dir = '0 0 0';
	Draw_ArcBeam_callback_segmentdist = 0;
	Draw_ArcBeam_callback_last_thickness = 0;
	Draw_ArcBeam_callback_last_top = '0 0 0';
	Draw_ArcBeam_callback_last_bottom = '0 0 0';
}

void Remove_ArcBeam(void)
{
	remove(self.beam_muzzleentity);
	sound(self, CH_SHOTS_SINGLE, "misc/null.wav", VOL_BASE, ATTEN_NORM);
}

void Ent_ReadArcBeam(float isnew)
{
	float sf = ReadByte();
	entity flash;

	if(isnew)
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

		flash = spawn();
		flash.owner = self;
		flash.effects = EF_ADDITIVE | EF_FULLBRIGHT;
		flash.drawmask = MASK_NORMAL;
		flash.solid = SOLID_NOT;
		setattachment(flash, self, "");
		setorigin(flash, '0 0 0');

		self.beam_muzzleentity = flash;
	}
	else
	{
		flash = self.beam_muzzleentity;
	}

	if(sf & 1) // settings information
	{
		self.beam_maxangle = ReadShort();
		self.beam_range = ReadCoord();
		self.beam_returnspeed = ReadShort();
		self.beam_tightness = (ReadByte() / 10);

		if(ReadByte())
		{
			if(autocvar_chase_active)
				{ self.beam_usevieworigin = 1; }
			else // use view origin
				{ self.beam_usevieworigin = 2; }
		}
		else
		{
			self.beam_usevieworigin = 0;
		}
	}

	if(!self.beam_usevieworigin)
	{
		// self.iflags = IFLAG_ORIGIN | IFLAG_ANGLES | IFLAG_V_ANGLE; // why doesn't this work?
		self.iflags = IFLAG_ORIGIN;

		InterpolateOrigin_Undo();
	}

	if(sf & 2) // starting location
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	else if(self.beam_usevieworigin) // infer the location from player location
	{
		if(self.beam_usevieworigin == 2)
		{
			// use view origin
			self.origin = view_origin;
		}
		else
		{
			// use player origin so that third person display still works
			self.origin = getplayerorigin(player_localnum) + ('0 0 1' * getstati(STAT_VIEWHEIGHT));
		}
	}

	setorigin(self, self.origin);

	if(sf & 4) // want/aim direction
	{
		self.v_angle_x = ReadCoord();
		self.v_angle_y = ReadCoord();
		self.v_angle_z = ReadCoord();
	}

	if(sf & 8) // beam direction
	{
		self.angles_x = ReadCoord();
		self.angles_y = ReadCoord();
		self.angles_z = ReadCoord();
	}

	if(sf & 16) // beam type
	{
		self.beam_type = ReadByte();
		switch(self.beam_type)
		{
			case ARC_BT_MISS:
			{
				self.beam_color = '-1 -1 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 8;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning");
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_WALL: // grenadelauncher_muzzleflash healray_muzzleflash
			{
				self.beam_color = '0.5 0.5 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 8;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning");
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; // particleeffectnum("grenadelauncher_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_HEAL:
			{
				self.beam_color = '0 1 0';
				self.beam_alpha = 0.5;
				self.beam_thickness = 8;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("healray_impact"); 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_HIT:
			{
				self.beam_color = '1 0 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 8;
				self.beam_traileffect = particleeffectnum("nex_beam");
				self.beam_hiteffect = particleeffectnum("electro_lightning"); 
				self.beam_hitlight[0] = 20;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 0;
				self.beam_hitlight[3] = 0;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 50;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 0;
				self.beam_muzzlelight[3] = 0;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_BURST_MISS:
			{
				self.beam_color = '-1 -1 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 14;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning"); 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_BURST_WALL:
			{
				self.beam_color = '0.5 0.5 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 14;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning"); 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_BURST_HEAL:
			{
				self.beam_color = '0 1 0';
				self.beam_alpha = 0.5;
				self.beam_thickness = 14;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning"); 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
			case ARC_BT_BURST_HIT:
			{
				self.beam_color = '1 0 1';
				self.beam_alpha = 0.5;
				self.beam_thickness = 14;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = particleeffectnum("electro_lightning"); 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}

			// shouldn't be possible, but lets make it colorful if it does :D
			default:
			{
				self.beam_color = randomvec();
				self.beam_alpha = 1;
				self.beam_thickness = 8;
				self.beam_traileffect = FALSE;
				self.beam_hiteffect = FALSE; 
				self.beam_hitlight[0] = 0;
				self.beam_hitlight[1] = 1;
				self.beam_hitlight[2] = 1;
				self.beam_hitlight[3] = 1;
				self.beam_muzzleeffect = FALSE; //particleeffectnum("nex_muzzleflash");
				self.beam_muzzlelight[0] = 0;
				self.beam_muzzlelight[1] = 1;
				self.beam_muzzlelight[2] = 1;
				self.beam_muzzlelight[3] = 1;
				self.beam_image = "particles/lgbeam";
				setmodel(flash, "models/flash.md3");
				flash.alpha = self.beam_alpha;
				flash.colormod = self.beam_color;
				flash.scale = 0.5;
				break;
			}
		}
	}

	if(!self.beam_usevieworigin)
	{
		InterpolateOrigin_Note();
	}
}

