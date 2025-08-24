#include "tracing.qh"

#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/net_linked.qh>
#include <common/state.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <lib/warpzone/common.qh>
#include <server/antilag.qh>
#include <server/damage.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/common.qh>
#include <server/weapons/hitplot.qh>
#include <server/weapons/weaponsystem.qh>

// this function calculates w_shotorg and w_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put w_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
void W_SetupShot_Dir_ProjectileSize_Range(entity ent, .entity weaponentity, vector s_forward, vector mi, vector ma, float antilag, float recoil, Sound snd, float chan, float maxdamage, float range, int deathtype)
{
	TC(Sound, snd);
	float nudge = 1; // added to traceline target and subtracted from result  TOOD(divVerent): do we still need this? Doesn't the engine do this now for us?
	float oldsolid = ent.dphitcontentsmask;
	Weapon wep = DEATH_WEAPONOF(deathtype);
	if(!IS_CLIENT(ent))
		antilag = false; // no antilag for non-clients!
	if (IS_PLAYER(ent) && (wep.spawnflags & WEP_FLAG_PENETRATEWALLS))
	{
		// This is the reason rifle, MG, OKMG and other fireBullet weapons don't hit the crosshair when shooting at walls.
		// This is intentional, otherwise if you stand too close to a (glass) wall and attempt to shoot an enemy through it,
		// trueaim will cause the shot to hit the wall exactly but then miss the enemy (unless shooting from eye/center).
		// TODO for fireBullet, find how far the shot will penetrate and aim at that
		//      for fireRailgunbullet, find the farthest target and aim at that
		//      this will avoid issues when another player is passing in front of you when you shoot
		//      (currently such a shot will hit them but then miss the original target)
		ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}
	else
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	if(antilag)
		WarpZone_traceline_antilag(NULL, ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
		// passing NULL, because we do NOT want it to touch dphitcontentsmask
	else
		WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NOMONSTERS, ent);
	ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	vector forward, right, up;
	forward = v_forward;
	right = v_right;
	up = v_up;
	w_shotend = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
	v_forward = forward;
	v_right = right;
	v_up = up;

	// un-adjust trueaim if shotend is too close
	if(vdist(w_shotend - (ent.origin + ent.view_ofs), <, autocvar_g_trueaim_minrange))
		w_shotend = ent.origin + ent.view_ofs + s_forward * autocvar_g_trueaim_minrange;

	// track max damage
	if (IS_PLAYER(ent) && accuracy_canbegooddamage(ent))
		accuracy_add(ent, wep, maxdamage, 0, 0); // add to fired

	if(IS_PLAYER(ent))
		W_HitPlotAnalysis(ent, wep, forward, right, up);

	// read shot origin offset, like g_shootfromcenter
	// set in CL_WeaponEntity_SetModel (not a CSQC exclusive function...)
	vector md = ent.(weaponentity).movedir;
	//print(sprintf("offset of %s: %v\n", ent.(weaponentity).m_weapon.netname, md));
	vector dv = right * -md.y + up * md.z;

	w_shotorg = ent.origin + ent.view_ofs;

	// move the shotorg sideways and vertically as much as requested if possible
	if(antilag)
	{
		if(CS(ent).antilag_debug)
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + dv, MOVE_NORMAL, ent, CS(ent).antilag_debug);
		else
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + dv, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
	}
	else
		tracebox(w_shotorg, mi, ma, w_shotorg + dv, MOVE_NORMAL, ent);
	w_shotorg = trace_endpos;

	// now move the shotorg forward as much as requested if possible
	if(antilag)
	{
		if(CS(ent).antilag_debug)
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + forward * (md.x + nudge), MOVE_NORMAL, ent, CS(ent).antilag_debug);
		else
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + forward * (md.x + nudge), MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
	}
	else
		tracebox(w_shotorg, mi, ma, w_shotorg + forward * (md.x + nudge), MOVE_NORMAL, ent);
	w_shotorg = trace_endpos - forward * nudge;

	//print(sprintf("w_shotorg %v\n\n", w_shotorg - (ent.origin + ent.view_ofs)));

	// calculate the shotdir from the chosen shotorg
	if(W_DualWielding(ent))
		w_shotdir = s_forward;
	else
		w_shotdir = normalize(w_shotend - w_shotorg);

	//vector prevdir = w_shotdir;
	//vector prevorg = w_shotorg;
	//vector prevend = w_shotend;

	if (antilag)
	if (!CS_CVAR(ent).cvar_cl_noantilag)
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
			if (CS(ent).cursor_trace_ent)                 // client was aiming at someone
			if (CS(ent).cursor_trace_ent != ent)         // just to make sure
			if (CS(ent).cursor_trace_ent.takedamage)      // and that person is killable
			if (IS_PLAYER(CS(ent).cursor_trace_ent)) // and actually a player
			{
				// verify that the shot would miss without antilag
				// (avoids an issue where guns would always shoot at their origin)
				traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
				if (!trace_ent.takedamage)
				{
					// verify that the shot would hit if altered
					traceline(w_shotorg, CS(ent).cursor_trace_ent.origin, MOVE_NORMAL, ent);
					if (trace_ent == CS(ent).cursor_trace_ent)
						w_shotdir = normalize(CS(ent).cursor_trace_ent.origin - w_shotorg);
					else
						LOG_INFO("antilag fail");
				}
			}
		}
	}

	ent.dphitcontentsmask = oldsolid; // restore solid type (generally SOLID_SLIDEBOX)

	if (!autocvar_g_norecoil)
		ent.punchangle_x = recoil * -1;

	if (snd != SND_Null) {
		sound(ent, chan, snd, (W_DualWielding(ent) ? VOL_BASE * 0.7 : VOL_BASE), ATTN_NORM);
		W_PlayStrengthSound(ent);
	}

	// nudge w_shotend so a trace to w_shotend hits
	w_shotend = w_shotend + normalize(w_shotend - w_shotorg) * nudge;
	//if(w_shotend != prevend) { printf("SERVER: shotEND differs: %s - %s\n", vtos(w_shotend), vtos(prevend)); }
	//if(w_shotorg != prevorg) { printf("SERVER: shotORG differs: %s - %s\n", vtos(w_shotorg), vtos(prevorg)); }
	//if(w_shotdir != prevdir) { printf("SERVER: shotDIR differs: %s - %s\n", vtos(w_shotdir), vtos(prevdir)); }
}

vector W_CalculateProjectileVelocity(entity actor, vector pvelocity, vector mvelocity, float forceAbsolute)
{
	vector mdirection;
	float mspeed;
	vector outvelocity;

	mvelocity = mvelocity * W_WeaponSpeedFactor(actor);

	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);

	outvelocity = get_shotvelocity(pvelocity, mdirection, mspeed, (forceAbsolute ? 0 : autocvar_g_projectiles_newton_style), autocvar_g_projectiles_newton_style_2_minfactor, autocvar_g_projectiles_newton_style_2_maxfactor);

	return outvelocity;
}

void W_SetupProjVelocity_Explicit(entity proj, vector dir, vector upDir, float pSpeed, float pUpSpeed, float pZSpeed, float spread, float forceAbsolute)
{
	if(proj.owner == NULL)
		error("Unowned missile");

	dir = dir + upDir * (pUpSpeed / pSpeed);
	dir.z += pZSpeed / pSpeed;
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

	dir = W_CalculateSpread(dir, spread, autocvar_g_projectiles_spread_style, false);

	#if 0
	mspercallsum += gettime(GETTIME_HIRES);
	mspercallcount += 1;
	LOG_INFO("avg: ", ftos(mspercallcount / mspercallsum), " per sec");
	#endif

	proj.velocity = W_CalculateProjectileVelocity(proj.owner, proj.owner.velocity, pSpeed * dir, forceAbsolute);
}


// ====================
//  Ballistics Tracing
// ====================

bool Headshot(entity targ, entity ent, vector start, vector end)
{
	if(!IS_PLAYER(targ) || IS_DEAD(targ) || STAT(FROZEN, targ) || !targ.takedamage)
		return false;
	vector org = targ.origin; // antilag is already taken into consideration //antilag_takebackorigin(targ, CS(targ), time - ANTILAG_LATENCY(ent));
	vector headmins = org + '0.6 0 0' * targ.mins_x + '0 0.6 0' * targ.mins_y + '0 0 1' * (1.3 * targ.view_ofs_z - 0.3 * targ.maxs_z);
	vector headmaxs = org + '0.6 0 0' * targ.maxs_x + '0 0.6 0' * targ.maxs_y + '0 0 1' * targ.maxs_z;

	return trace_hits_box(start, end, headmins, headmaxs);
}

void FireRailgunBullet (entity this, .entity weaponentity, vector start, vector end, float bdamage, bool headshot_notify, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, int deathtype)
{
	vector dir = normalize(end - start);
	vector force = dir * bforce;

	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;

	float totaldmg = 0;
	bool headshot = false; // indicates that one of the targets hit was a headshot

	// trace multiple times until we hit a wall, each obstacle will be made
	// non-solid so we can hit the next, while doing this we spawn effects and
	// note down which entities were hit so we can damage them later
	entity o = this;
	while (1)
	{
		if(CS(this).antilag_debug)
			WarpZone_traceline_antilag (this, start, end, false, o, CS(this).antilag_debug);
		else
			WarpZone_traceline_antilag (this, start, end, false, o, ANTILAG_LATENCY(this));
		if(o && WarpZone_trace_firstzone)
		{
			o = NULL;
			continue;
		}

		if(trace_ent.solid == SOLID_BSP || trace_ent.solid == SOLID_SLIDEBOX)
			Damage_DamageInfo(trace_endpos, bdamage, 0, 0, force, deathtype, trace_ent.species, this);

		// if it is NULL we can't hurt it so stop now
		if (trace_ent == NULL || trace_fraction == 1)
			break;

		if(headshot_notify && !headshot && Headshot(trace_ent, this, start, end))
			headshot = true;

		// make the entity non-solid so we can hit the next one
		IL_PUSH(g_railgunhit, trace_ent);
		trace_ent.railgunhit = true;
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

	vector endpoint = trace_endpos;
	entity endent = trace_ent;
	float endq3surfaceflags = trace_dphitq3surfaceflags;

	// find all the entities the railgun hit and restore their solid state
	IL_EACH(g_railgunhit, it.railgunhit,
	{
		it.solid = it.railgunhitsolidbackup;
	});

	// Find all players the beam passed close by (even those hit)
	float length = vlen(endpoint - start);
	entity pseudoprojectile = NULL;
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != this, {
		// not when spectating the shooter
		if (IS_SPEC(it) && it.enemy == this) continue;

		// nearest point on the beam
		vector beampos = start + dir * bound(0, (it.origin - start) * dir, length);

		if(!pseudoprojectile)
			pseudoprojectile = new(pseudoprojectile); // we need this so the sound uses the "entchannel4" volume

		msg_entity = it;
		// we want this to be very loud when close but fall off quickly -> using max base volume and high attenuation
		soundtoat(MSG_ONE, pseudoprojectile, beampos, CH_SHOTS, SND(NEXWHOOSH_RANDOM()), VOL_BASEVOICE, ATTEN_IDLE, 0);
	});
	if(pseudoprojectile)
		delete(pseudoprojectile);

	// find all the entities the railgun hit and hurt them
	IL_EACH(g_railgunhit, it.railgunhit,
	{
		// removal from the list is handled below

		float foff = ExponentialFalloff(mindist, maxdist, halflifedist, it.railgundistance);
		float ffs = ExponentialFalloff(mindist, maxdist, forcehalflifedist, it.railgundistance);

		if(accuracy_isgooddamage(this, it))
			totaldmg += bdamage * foff;

		// apply the damage
		if (it.takedamage)
			Damage(it, this, this, bdamage * foff, deathtype, weaponentity, it.railgunhitloc, it.railgunforce * ffs);

		it.railgunhitloc = '0 0 0';
		it.railgunhitsolidbackup = SOLID_NOT;
		it.railgunhit = false;
		it.railgundistance = 0;
	});

	IL_CLEAR(g_railgunhit);

	if(headshot)
		Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_HEADSHOT);

	// calculate hits and fired shots for hitscan
	if(this.(weaponentity))
		accuracy_add(this, this.(weaponentity).m_weapon, 0, min(bdamage, totaldmg), 0); // add to hit

	trace_endpos = endpoint;
	trace_ent = endent;
	trace_dphitq3surfaceflags = endq3surfaceflags;
}

void fireBullet_trace_callback(vector start, vector hit, vector end)
{
	if(vdist(hit - start, >, 16))
		trailparticles(NULL, fireBullet_trace_callback_eff, start, hit);
	WarpZone_trace_forent = NULL;
	fireBullet_last_hit = NULL;
}

void fireBullet_falloff(entity this, .entity weaponentity, vector start, vector dir,
                        float spread, float max_solid_penetration, float damage,
                        float falloff_halflife, float falloff_mindist,
                        float falloff_maxdist, float headshot_multiplier,
                        float force, float falloff_forcehalflife,
                        float dtype, entity tracer_effect, bool do_antilag)
{
	dir = W_CalculateSpread(dir, spread, autocvar_g_hitscan_spread_style, true);
	vector end = start + dir * max_shot_distance;

	fireBullet_last_hit = NULL;
	fireBullet_trace_callback_eff = tracer_effect;

	float solid_penetration_fraction = 1;
	float damage_fraction = 1;
	float total_damage = 0;

	float lag = ((do_antilag) ? antilag_getlag(this) : 0);
	if(lag)
		antilag_takeback_all(this, lag);

	// change shooter to SOLID_BBOX so the shot can hit corpses
	int oldsolid = this.dphitcontentsmask;
	if(this)
		this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	WarpZone_trace_forent = this;

	bool headshot = false; // indicates that one of the hit targets was a headshot
	for (;;)
	{
		WarpZone_TraceBox_ThroughZone(start, '0 0 0', '0 0 0', end, false, WarpZone_trace_forent, NULL, fireBullet_trace_callback);
		dir = WarpZone_TransformVelocity(WarpZone_trace_transform, dir);
		end = WarpZone_TransformOrigin(WarpZone_trace_transform, end);
		start = trace_endpos;
		entity hit = trace_ent;

		// traced up to max_shot_distance and didn't hit anything at all
		if (trace_fraction == 1.0)
			break;

		// When hitting sky, stop.
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
			break;

		// can't use noimpact, as we need to pass through walls
		//if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			//break;

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
		//   common/noimpact (is supposed to eat projectiles, but is erased anyway)
		bool is_weapclip = false;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
		if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
		if (!(trace_dphitcontents & DPCONTENTS_OPAQUE))
			is_weapclip = true;

		if(!hit || hit.solid == SOLID_BSP || hit.solid == SOLID_SLIDEBOX)
			Damage_DamageInfo(start, damage * damage_fraction, 0, 0, max(1, force) * dir * damage_fraction, dtype, hit.species, this);

		// Avoid self-damage (except after going through a warp)
		// avoid hitting the same entity twice (engine bug)
		if (hit && hit != WarpZone_trace_forent && hit != fireBullet_last_hit)
		{
			fireBullet_last_hit = hit;
			yoda = 0;
			MUTATOR_CALLHOOK(FireBullet_Hit, this, hit, start, end, damage, this.(weaponentity));
			damage = M_ARGV(4, float);
			if(headshot_multiplier && Headshot(hit, this, start, end))
			{
				damage *= headshot_multiplier;
				headshot = true;
			}
			bool gooddamage = accuracy_isgooddamage(this, hit);

			float dealt_damage = damage * damage_fraction;
			vector dealt_force = force * dir * damage_fraction;

			if (falloff_halflife || falloff_forcehalflife)
			{
				// start, end and trace_endpos seem unreliable for
				// falloff calculations, using `entity.origin`s instead.
				// dist is only used to measure distance between shooter
				// and target entities and do math based on the distance
				// target's location = hit.origin
				// shooter's location = this.origin
				float dist = vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, hit.origin) - this.origin);

				if (falloff_halflife)
					dealt_damage *= ExponentialFalloff(falloff_mindist, falloff_maxdist, falloff_halflife,      dist);

				if (falloff_forcehalflife)
					dealt_force  *= ExponentialFalloff(falloff_mindist, falloff_maxdist, falloff_forcehalflife, dist);
			}

			Damage(hit, this, this, dealt_damage, dtype, weaponentity, start, dealt_force);

			// calculate hits for ballistic weapons
			if(gooddamage)
			{
				// do not exceed 100%
				float added_damage = min(damage - total_damage, damage * damage_fraction);
				total_damage += damage * damage_fraction;
				accuracy_add(this, this.(weaponentity).m_weapon, 0, added_damage, 0); // add to hit
			}
		}

		if (is_weapclip && !autocvar_g_ballistics_penetrate_clips)
			break;

		// go through solid!
		// outside the world? forget it
		if(start.x > world.maxs.x || start.y > world.maxs.y || start.z > world.maxs.z || start.x < world.mins.x || start.y < world.mins.y || start.z < world.mins.z)
			break;

		float maxdist;
		entity hitstore = IS_PLAYER(hit) ? PS(hit) : hit;
		if(max_solid_penetration < 0)
			break;
		else if(hitstore.ballistics_density < -1)
			break; // -2: no solid penetration, ever
		else if(hitstore.ballistics_density < 0)
			maxdist = vlen(hit.maxs - hit.mins) + 1; // -1: infinite travel distance
		else if(hitstore.ballistics_density == 0)
			maxdist = max_solid_penetration * solid_penetration_fraction;
		else
			maxdist = max_solid_penetration * solid_penetration_fraction / hitstore.ballistics_density;

		if(maxdist <= autocvar_g_ballistics_mindistance)
			break;

		// move the entity along its velocity until it's out of solid, then let it resume
		// The previously hit entity is ignored here!
		traceline_inverted (start, start + dir * maxdist, MOVE_NORMAL, WarpZone_trace_forent, true, hit);
		if(trace_fraction == 1) // 1: we never got out of solid
			break;

		float dist_taken = max(autocvar_g_ballistics_mindistance, vlen(trace_endpos - start));
		float fraction_used_of_what_is_left = dist_taken / maxdist;
		solid_penetration_fraction -= solid_penetration_fraction * fraction_used_of_what_is_left;
		solid_penetration_fraction = max(solid_penetration_fraction, 0);
		damage_fraction = pow(solid_penetration_fraction, autocvar_g_ballistics_solidpenetration_exponent);

		// Only show effect when going through a player (invisible otherwise)
		if (hit && (hit.solid != SOLID_BSP))
			if(vdist(trace_endpos - start, >, 4))
				trailparticles(this, fireBullet_trace_callback_eff, start, trace_endpos);

		start = trace_endpos;

		if(hit.solid == SOLID_BSP)
			Damage_DamageInfo(start, 0, 0, 0, max(1, force) * normalize(dir) * -damage_fraction, dtype, 0, this);
	}

	if(headshot)
		Send_Notification(NOTIF_ONE, this, MSG_ANNCE, ANNCE_HEADSHOT);

	if(lag)
		antilag_restore_all(this);

	// restore shooter solid type
	if(this)
		this.dphitcontentsmask = oldsolid;
}

void fireBullet_antilag(entity this, .entity weaponentity, vector start, vector dir, float spread, float max_solid_penetration, float damage, float headshot_multiplier, float force, float dtype, entity tracer_effect, bool do_antilag)
{
	fireBullet_falloff(this, weaponentity, start, dir, spread, max_solid_penetration, damage, 0, 0, 0, headshot_multiplier, force, 0, dtype, tracer_effect, do_antilag);
}

void fireBullet(entity this, .entity weaponentity, vector start, vector dir, float spread, float max_solid_penetration, float damage, float headshot_multiplier, float force, float dtype, entity tracer_effect)
{
	fireBullet_antilag(this, weaponentity, start, dir, spread, max_solid_penetration, damage, headshot_multiplier, force, dtype, tracer_effect, true);
}

void crosshair_trace(entity pl)
{
	traceline_antilag(pl, CS(pl).cursor_trace_start, CS(pl).cursor_trace_start + normalize(CS(pl).cursor_trace_endpos - CS(pl).cursor_trace_start) * max_shot_distance, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}

void crosshair_trace_plusvisibletriggers(entity pl)
{
	crosshair_trace_plusvisibletriggers__is_wz(pl, false);
}

void WarpZone_crosshair_trace_plusvisibletriggers(entity pl)
{
	crosshair_trace_plusvisibletriggers__is_wz(pl, true);
}

void crosshair_trace_plusvisibletriggers__is_wz(entity pl, bool is_wz)
{
	FOREACH_ENTITY_FLOAT(solid, SOLID_TRIGGER,
	{
		if(it.model != "")
		{
			it.solid = SOLID_BSP;
			IL_PUSH(g_ctrace_changed, it);
		}
	});

	if (is_wz)
		WarpZone_crosshair_trace(pl);
	else
		crosshair_trace(pl);

	IL_EACH(g_ctrace_changed, true, { it.solid = SOLID_TRIGGER; });

	IL_CLEAR(g_ctrace_changed);
}

void WarpZone_crosshair_trace(entity pl)
{
	WarpZone_traceline_antilag(pl, CS(pl).cursor_trace_start, CS(pl).cursor_trace_start + normalize(CS(pl).cursor_trace_endpos - CS(pl).cursor_trace_start) * max_shot_distance, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}
