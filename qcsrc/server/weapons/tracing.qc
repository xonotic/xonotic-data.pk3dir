// this function calculates w_shotorg and w_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put w_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
void W_SetupShot_Dir_ProjectileSize_Range(entity ent, vector s_forward, vector mi, vector ma, float antilag, float recoil, string snd, float chan, float maxdamage, float range)
{
	float nudge = 1; // added to traceline target and subtracted from result
	float oldsolid;
	vector vecs, dv;
	oldsolid = ent.dphitcontentsmask;
	if(ent.weapon == WEP_RIFLE)
		ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	else
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	if(antilag)
		WarpZone_traceline_antilag(world, ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
		// passing world, because we do NOT want it to touch dphitcontentsmask
	else
		WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NOMONSTERS, ent);
	ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	w_shotend = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
	v_forward = vf;
	v_right = vr;
	v_up = vu;

	// un-adjust trueaim if shotend is too close
	if(vlen(w_shotend - (ent.origin + ent.view_ofs)) < autocvar_g_trueaim_minrange)
		w_shotend = ent.origin + ent.view_ofs + s_forward * autocvar_g_trueaim_minrange;

	// track max damage
	if(accuracy_canbegooddamage(ent))
		accuracy_add(ent, ent.weapon, maxdamage, 0);

	W_HitPlotAnalysis(ent, v_forward, v_right, v_up);

	if(ent.weaponentity.movedir_x > 0)
		vecs = ent.weaponentity.movedir;
	else
		vecs = '0 0 0';

	dv = v_right * -vecs_y + v_up * vecs_z;
	w_shotorg = ent.origin + ent.view_ofs + dv;

	// now move the shotorg forward as much as requested if possible
	if(antilag)
	{
		if(ent.antilag_debug)
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent, ent.antilag_debug);
		else
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
	}
	else
		tracebox(w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent);
	w_shotorg = trace_endpos - v_forward * nudge;
	// calculate the shotdir from the chosen shotorg
	w_shotdir = normalize(w_shotend - w_shotorg);

	if (antilag)
	if (!ent.cvar_cl_noantilag)
	{
		if (autocvar_g_antilag == 1) // switch to "ghost" if not hitting original
		{
			traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
			if (!trace_ent.takedamage)
			{
				traceline_antilag_force (ent, w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
				if (trace_ent.takedamage && IS_PLAYER(trace_ent))
				{
					entity e;
					e = trace_ent;
					traceline(w_shotorg, e.origin, MOVE_NORMAL, ent);
					if(trace_ent == e)
						w_shotdir = normalize(trace_ent.origin - w_shotorg);
				}
			}
		}
		else if(autocvar_g_antilag == 3) // client side hitscan
		{
			// this part MUST use prydon cursor
			if (ent.cursor_trace_ent)                 // client was aiming at someone
			if (ent.cursor_trace_ent != ent)         // just to make sure
			if (ent.cursor_trace_ent.takedamage)      // and that person is killable
			if (IS_PLAYER(ent.cursor_trace_ent)) // and actually a player
			{
				// verify that the shot would miss without antilag
				// (avoids an issue where guns would always shoot at their origin)
				traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
				if (!trace_ent.takedamage)
				{
					// verify that the shot would hit if altered
					traceline(w_shotorg, ent.cursor_trace_ent.origin, MOVE_NORMAL, ent);
					if (trace_ent == ent.cursor_trace_ent)
						w_shotdir = normalize(ent.cursor_trace_ent.origin - w_shotorg);
					else
						print("antilag fail\n");
				}
			}
		}
	}

	ent.dphitcontentsmask = oldsolid; // restore solid type (generally SOLID_SLIDEBOX)

	if (!autocvar_g_norecoil)
		ent.punchangle_x = recoil * -1;

	if (snd != "")
	{
		sound (ent, chan, snd, VOL_BASE, ATTN_NORM);
		W_PlayStrengthSound(ent);
	}

	// nudge w_shotend so a trace to w_shotend hits
	w_shotend = w_shotend + normalize(w_shotend - w_shotorg) * nudge;
}

vector W_CalculateProjectileVelocity(vector pvelocity, vector mvelocity, float forceAbsolute)
{
	vector mdirection;
	float mspeed;
	vector outvelocity;

	mvelocity = mvelocity * g_weaponspeedfactor;

	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);

	outvelocity = get_shotvelocity(pvelocity, mdirection, mspeed, (forceAbsolute ? 0 : autocvar_g_projectiles_newton_style), autocvar_g_projectiles_newton_style_2_minfactor, autocvar_g_projectiles_newton_style_2_maxfactor);

	return outvelocity;
}

#if 0
float mspercallsum;
float mspercallsstyle;
float mspercallcount;
#endif
void W_SetupProjectileVelocityEx(entity missile, vector dir, vector upDir, float pSpeed, float pUpSpeed, float pZSpeed, float spread, float forceAbsolute)
{
	if(missile.owner == world)
		error("Unowned missile");

	dir = dir + upDir * (pUpSpeed / pSpeed);
	dir_z += pZSpeed / pSpeed;
	pSpeed *= vlen(dir);
	dir = normalize(dir);

#if 0
	if(autocvar_g_projectiles_spread_style != mspercallsstyle)
	{
		mspercallsum = mspercallcount = 0;
		mspercallsstyle = autocvar_g_projectiles_spread_style;
	}
	mspercallsum -= gettime(GETTIME_HIRES);
#endif
	dir = W_CalculateSpread(dir, spread, g_weaponspreadfactor, autocvar_g_projectiles_spread_style);
#if 0
	mspercallsum += gettime(GETTIME_HIRES);
	mspercallcount += 1;
	print("avg: ", ftos(mspercallcount / mspercallsum), " per sec\n");
#endif

	missile.velocity = W_CalculateProjectileVelocity(missile.owner.velocity, pSpeed * dir, forceAbsolute);
}

void W_SetupProjectileVelocity(entity missile, float pSpeed, float spread) // WEAPONTODO
{
	W_SetupProjectileVelocityEx(missile, w_shotdir, v_up, pSpeed, 0, 0, spread, FALSE);
}


// ====================
//  Ballistics Tracing
// ====================

void FireRailgunBullet (vector start, vector end, float bdamage, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, float deathtype)
{
	vector hitloc, force, endpoint, dir;
	entity ent, endent;
	float endq3surfaceflags;
	float totaldmg;
	entity o;

	float length;
	vector beampos;
	string snd;
	entity pseudoprojectile;
	float f, ffs;

	pseudoprojectile = world;

	railgun_start = start;
	railgun_end = end;

	dir = normalize(end - start);
	length = vlen(end - start);
	force = dir * bforce;

	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;

	totaldmg = 0;

	// trace multiple times until we hit a wall, each obstacle will be made
	// non-solid so we can hit the next, while doing this we spawn effects and
	// note down which entities were hit so we can damage them later
	o = self;
	while (1)
	{
		if(self.antilag_debug)
			WarpZone_traceline_antilag (self, start, end, FALSE, o, self.antilag_debug);
		else
			WarpZone_traceline_antilag (self, start, end, FALSE, o, ANTILAG_LATENCY(self));
		if(o && WarpZone_trace_firstzone)
		{
			o = world;
			continue;
		}

		if(trace_ent.solid == SOLID_BSP || trace_ent.solid == SOLID_SLIDEBOX)
			Damage_DamageInfo(trace_endpos, bdamage, 0, 0, force, deathtype, trace_ent.species, self);

		// if it is world we can't hurt it so stop now
		if (trace_ent == world || trace_fraction == 1)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = TRUE;
		trace_ent.railgunhitloc = end;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;
		trace_ent.railgundistance = vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - start);
		trace_ent.railgunforce = WarpZone_TransformVelocity(WarpZone_trace_transform, force);

		// stop if this is a wall
		if (trace_ent.solid == SOLID_BSP)
			break;

		// make the entity non-solid
		trace_ent.solid = SOLID_NOT;
	}

	endpoint = trace_endpos;
	endent = trace_ent;
	endq3surfaceflags = trace_dphitq3surfaceflags;

	// find all the entities the railgun hit and restore their solid state
	ent = findfloat(world, railgunhit, TRUE);
	while (ent)
	{
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
		ent = findfloat(ent, railgunhit, TRUE);
	}

	// spawn a temporary explosion entity for RadiusDamage calls
	//explosion = spawn();

	// Find all non-hit players the beam passed close by
	if(deathtype == WEP_MINSTANEX || deathtype == WEP_NEX)
	{
		FOR_EACH_REALCLIENT(msg_entity) if(msg_entity != self) if(!msg_entity.railgunhit) if not(IS_SPEC(msg_entity) && msg_entity.enemy == self) // we use realclient, so spectators can hear the whoosh too
		{
			// nearest point on the beam
			beampos = start + dir * bound(0, (msg_entity.origin - start) * dir, length);

			f = bound(0, 1 - vlen(beampos - msg_entity.origin) / 512, 1);
			if(f <= 0)
				continue;

			snd = strcat("weapons/nexwhoosh", ftos(floor(random() * 3) + 1), ".wav");

			if(!pseudoprojectile)
				pseudoprojectile = spawn(); // we need this so the sound uses the "entchannel4" volume
			soundtoat(MSG_ONE, pseudoprojectile, beampos, CH_SHOTS, snd, VOL_BASE * f, ATTEN_NONE);
		}

		if(pseudoprojectile)
			remove(pseudoprojectile);
	}

	// find all the entities the railgun hit and hurt them
	ent = findfloat(world, railgunhit, TRUE);
	while (ent)
	{
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;

		f = ExponentialFalloff(mindist, maxdist, halflifedist, ent.railgundistance);
		ffs = ExponentialFalloff(mindist, maxdist, forcehalflifedist, ent.railgundistance);

		if(accuracy_isgooddamage(self.realowner, ent))
			totaldmg += bdamage * f;

		// apply the damage
		if (ent.takedamage)
			Damage (ent, self, self, bdamage * f, deathtype, hitloc, ent.railgunforce * ffs);

		// create a small explosion to throw gibs around (if applicable)
		//setorigin (explosion, hitloc);
		//RadiusDamage (explosion, self, 10, 0, 50, world, world, 300, deathtype);

		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = FALSE;
		ent.railgundistance = 0;

		// advance to the next entity
		ent = findfloat(ent, railgunhit, TRUE);
	}

	// calculate hits and fired shots for hitscan
	accuracy_add(self, self.weapon, 0, min(bdamage, totaldmg));

	trace_endpos = endpoint;
	trace_ent = endent;
	trace_dphitq3surfaceflags = endq3surfaceflags;
}

void W_BallisticBullet_Hit (void)
{
	float f, q, g;

	f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
	q = 1 + self.dmg_edge / self.dmg;

	if(other.solid == SOLID_BSP || other.solid == SOLID_SLIDEBOX)
		Damage_DamageInfo(self.origin, self.dmg * f, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * f, self.projectiledeathtype, other.species, self);

	if(other && other != self.enemy)
	{
		endzcurveparticles();

		yoda = 0;
		railgun_start = self.origin - 2 * frametime * self.velocity;
		railgun_end = self.origin + 2 * frametime * self.velocity;
		g = accuracy_isgooddamage(self.realowner, other);
		Damage(other, self, self.realowner, self.dmg * f, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity) * f);

		/*if(yoda && (time > (self.last_yoda + 5)))
		{
			Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
			self.last_yoda = time; 
		}*/

		// calculate hits for ballistic weapons
		if(g)
		{
			// do not exceed 100%
			q = min(self.dmg * q, self.dmg_total + f * self.dmg) - self.dmg_total;
			self.dmg_total += f * self.dmg;
			accuracy_add(self.realowner, self.realowner.weapon, 0, q);
		}
	}

	self.enemy = other; // don't hit the same player twice with the same bullet
}

void W_BallisticBullet_LeaveSolid_think()
{
	setorigin(self, self.W_BallisticBullet_LeaveSolid_origin);
	self.velocity = self.W_BallisticBullet_LeaveSolid_velocity;

	self.think = self.W_BallisticBullet_LeaveSolid_think_save;
	self.nextthink = max(time, self.W_BallisticBullet_LeaveSolid_nextthink_save);
	self.W_BallisticBullet_LeaveSolid_think_save = func_null;

	self.flags &= ~FL_ONGROUND;

	if(self.enemy.solid == SOLID_BSP)
	{
		float f;
		f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
		Damage_DamageInfo(self.origin, 0, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * -f, self.projectiledeathtype, 0, self);
	}

	UpdateCSQCProjectile(self);
}

float W_BallisticBullet_LeaveSolid(float eff)
{
	// move the entity along its velocity until it's out of solid, then let it resume
	vector vel = self.velocity;
	float dt, dst, velfactor, v0, vs;
	float maxdist;
	float E0_m, Es_m;
	float constant = self.dmg_radius * (other.ballistics_density ? other.ballistics_density : 1);

	// outside the world? forget it
	if(self.origin_x > world.maxs_x || self.origin_y > world.maxs_y || self.origin_z > world.maxs_z || self.origin_x < world.mins_x || self.origin_y < world.mins_y || self.origin_z < world.mins_z)
		return 0;

	// special case for zero density and zero bullet constant: 

	if(self.dmg_radius == 0)
	{
		if(other.ballistics_density < 0)
			constant = 0; // infinite travel distance
		else
			return 0; // no penetration
	}
	else
	{
		if(other.ballistics_density < 0)
			constant = 0; // infinite travel distance
		else if(other.ballistics_density == 0)
			constant = self.dmg_radius;
		else
			constant = self.dmg_radius * other.ballistics_density;
	}

	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	v0 = vlen(vel);

	E0_m = 0.5 * v0 * v0;

	if(constant)
	{
		maxdist = E0_m / constant;
		// maxdist = 0.5 * v0 * v0 / constant
		// dprint("max dist = ", ftos(maxdist), "\n");

		if(maxdist <= autocvar_g_ballistics_mindistance)
			return 0;
	}
	else
	{
		maxdist = vlen(other.maxs - other.mins) + 1; // any distance, as long as we leave the entity
	}

	traceline_inverted (self.origin, self.origin + normalize(vel) * maxdist, MOVE_NORMAL, self, TRUE);
	if(trace_fraction == 1) // 1: we never got out of solid
		return 0;

	self.W_BallisticBullet_LeaveSolid_origin = trace_endpos;

	dst = max(autocvar_g_ballistics_mindistance, vlen(trace_endpos - self.origin));
	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	Es_m = E0_m - constant * dst;
	if(Es_m <= 0)
	{
		// roundoff errors got us
		return 0;
	}
	vs = sqrt(2 * Es_m);
	velfactor = vs / v0;

	dt = dst / (0.5 * (v0 + vs));
	// this is not correct, but the differential equations have no analytic
	// solution - and these times are very small anyway
	//print("dt = ", ftos(dt), "\n");

	self.W_BallisticBullet_LeaveSolid_think_save = self.think;
	self.W_BallisticBullet_LeaveSolid_nextthink_save = self.nextthink;
	self.think = W_BallisticBullet_LeaveSolid_think;
	self.nextthink = time + dt;

	vel = vel * velfactor;

	self.velocity = '0 0 0';
	self.flags |= FL_ONGROUND; // prevent moving
	self.W_BallisticBullet_LeaveSolid_velocity = vel;

	if(eff >= 0)
		if(vlen(trace_endpos - self.origin) > 4)
		{
			endzcurveparticles();
			trailparticles(self, eff, self.origin, trace_endpos);
		}

	return 1;
}

void W_BallisticBullet_Touch (void)
{
	//float density;

	if(self.think == W_BallisticBullet_LeaveSolid_think) // skip this!
		return;

	PROJECTILE_TOUCH;
	W_BallisticBullet_Hit ();

	if(self.dmg_radius < 0) // these NEVER penetrate solid
	{
		remove(self);
		return;
	}

	// if we hit "weapclip", bail out
	//
	// rationale of this check:
	//
	// any shader that is solid, nodraw AND trans is meant to clip weapon
	// shots and players, but has no other effect!
	//
	// if it is not trans, it is caulk and should not have this side effect
	//
	// matching shaders:
	//   common/weapclip (intended)
	//   common/noimpact (is supposed to eat projectiles, but is erased farther above)
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
	if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID)
	if not(trace_dphitcontents & DPCONTENTS_OPAQUE)
	{
		remove(self);
		return;
	}

	// go through solid!
	if(!W_BallisticBullet_LeaveSolid(-1))
	{
		remove(self);
		return;
	}

	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void endFireBallisticBullet() // WEAPONTODO
{
	endzcurveparticles();
}

void fireBallisticBullet_trace_callback(vector start, vector hit, vector end)
{
	if(vlen(trace_endpos - fireBallisticBullet_trace_callback_ent.origin) > 16)
		zcurveparticles_from_tracetoss(fireBallisticBullet_trace_callback_eff, fireBallisticBullet_trace_callback_ent.origin, trace_endpos, fireBallisticBullet_trace_callback_ent.velocity);
	WarpZone_trace_forent = world;
	self.owner = world;
}

void fireBallisticBullet(vector start, vector dir, float spread, float pSpeed, float lifetime, float damage, float force, float dtype, float tracereffects, float gravityfactor, float bulletconstant)
{
	float lag, dt, savetime; //, density;
	entity pl, oldself;
	float antilagging;

	antilagging = (autocvar_g_antilag_bullets && (pSpeed >= autocvar_g_antilag_bullets));

	entity proj;
	proj = spawn();
	proj.classname = "bullet";
	proj.owner = proj.realowner = self;
	PROJECTILE_MAKETRIGGER(proj);
	if(gravityfactor > 0)
	{
		proj.movetype = MOVETYPE_TOSS;
		proj.gravity = gravityfactor;
	}
	else
		proj.movetype = MOVETYPE_FLY;
	proj.think = SUB_Remove;
	proj.nextthink = time + lifetime; // min(pLifetime, vlen(world.maxs - world.mins) / pSpeed);
	W_SetupProjectileVelocityEx(proj, dir, v_up, pSpeed, 0, 0, spread, antilagging);
	proj.angles = vectoangles(proj.velocity);
	if(bulletconstant > 0)
		proj.dmg_radius = autocvar_g_ballistics_materialconstant / bulletconstant;
	else if(bulletconstant == 0)
		proj.dmg_radius = 0;
	else
		proj.dmg_radius = -1;
	// so: bulletconstant = bullet mass / area of bullet circle
	setorigin(proj, start);
	proj.flags = FL_PROJECTILE;

	proj.touch = W_BallisticBullet_Touch;
	proj.dmg = damage;
	proj.dmg_force = force;
	proj.projectiledeathtype = dtype;

	proj.oldvelocity = proj.velocity;

	other = proj; MUTATOR_CALLHOOK(EditProjectile);

	if(antilagging)
	{
		float eff;

		if(tracereffects & EF_RED)
			eff = particleeffectnum("tr_rifle");
		else if(tracereffects & EF_BLUE)
			eff = particleeffectnum("tr_rifle_weak");
		else
			eff = particleeffectnum("tr_bullet");

		// NOTE: this may severely throw off weapon balance
		lag = ANTILAG_LATENCY(self);
		if(lag < 0.001)
			lag = 0;
		if not(IS_REAL_CLIENT(self))
			lag = 0;
		if(autocvar_g_antilag == 0 || self.cvar_cl_noantilag)
			lag = 0; // only do hitscan, but no antilag

		if(lag)
			FOR_EACH_PLAYER(pl)
				if(pl != self)
					antilag_takeback(pl, time - lag);

		oldself = self;
		self = proj;

		savetime = frametime;
		frametime = 0.05;

		for(;;)
		{
			// DP tracetoss is stupid and always traces in 0.05s
			// ticks. This makes it trace in 0.05*0.125s ticks
			// instead.
			vector v0;
			float g0;
			v0 = self.velocity;
			g0 = self.gravity;
			self.velocity = self.velocity * 0.125;
			self.gravity *= 0.125 * 0.125;
			trace_fraction = 0;
			fireBallisticBullet_trace_callback_ent = self;
			fireBallisticBullet_trace_callback_eff = eff;
			WarpZone_TraceToss_ThroughZone(self, self.owner, world, fireBallisticBullet_trace_callback);
			self.velocity = v0;
			self.gravity = g0;

			if(trace_fraction == 1)
				break;
				// won't hit anything anytime soon (DP's
				// tracetoss does 200 tics of, here,
				// 0.05*0.125s, that is, 1.25 seconds

			other = trace_ent;
			dt = WarpZone_tracetoss_time * 0.125; // this is only approximate!
			setorigin(self, trace_endpos);
			self.velocity = WarpZone_tracetoss_velocity * (1 / 0.125);

			if(!SUB_OwnerCheck())
			{
				if(SUB_NoImpactCheck())
					break;

				// hit the player
				W_BallisticBullet_Hit();
			}

			if(proj.dmg_radius < 0) // these NEVER penetrate solid
				break;

			// if we hit "weapclip", bail out
			//
			// rationale of this check:
			//
			// any shader that is solid, nodraw AND trans is meant to clip weapon
			// shots and players, but has no other effect!
			//
			// if it is not trans, it is caulk and should not have this side effect
			//
			// matching shaders:
			//   common/weapclip (intended)
			//   common/noimpact (is supposed to eat projectiles, but is erased farther above)
			if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
			if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID)
			if not(trace_dphitcontents & DPCONTENTS_OPAQUE)
				break;

			// go through solid!
			if(!W_BallisticBullet_LeaveSolid((other && (other.solid != SOLID_BSP)) ? eff : -1))
				break;

			W_BallisticBullet_LeaveSolid_think();

			self.projectiledeathtype |= HITTYPE_BOUNCE;
		}
		frametime = savetime;
		self = oldself;

		if(lag)
			FOR_EACH_PLAYER(pl)
				if(pl != self)
					antilag_restore(pl);

		remove(proj);

		return;
	}

	if(tracereffects & EF_RED)
		CSQCProjectile(proj, TRUE, PROJECTILE_BULLET_GLOWING_TRACER, TRUE);
	else if(tracereffects & EF_BLUE)
		CSQCProjectile(proj, TRUE, PROJECTILE_BULLET_GLOWING, TRUE);
	else
		CSQCProjectile(proj, TRUE, PROJECTILE_BULLET, TRUE);
}

void fireBullet (vector start, vector dir, float spread, float damage, float force, float dtype, float tracer)
{
	vector  end;

	dir = normalize(dir + randomvec() * spread);
	end = start + dir * MAX_SHOT_DISTANCE;
	if(self.antilag_debug)
		traceline_antilag (self, start, end, FALSE, self, self.antilag_debug);
	else
		traceline_antilag (self, start, end, FALSE, self, ANTILAG_LATENCY(self));

	end = trace_endpos;

	if (pointcontents (trace_endpos) != CONTENT_SKY)
	{
		if not (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			Damage_DamageInfo(trace_endpos, damage, 0, 0, dir * max(1, force), dtype, trace_ent.species, self);                    

		Damage (trace_ent, self, self, damage, dtype, trace_endpos, dir * force);
	}
	trace_endpos = end;
}
