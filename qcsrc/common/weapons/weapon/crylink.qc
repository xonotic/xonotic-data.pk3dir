#include "crylink.qh"

#ifdef SVQC

void W_Crylink_CheckLinks(entity e)
{
	if (e == NULL)
		error("W_Crylink_CheckLinks: entity is NULL");
	if (e.classname != "spike" || wasfreed(e))
		error(sprintf("W_Crylink_CheckLinks: entity is not a spike but a %s (freed: %d)", e.classname, wasfreed(e)));

	entity p = e;
	int i;
	for (i = 0; i < 1000; ++i)
	{
		if (p.queuenext.queueprev != p || p.queueprev.queuenext != p)
			error("W_Crylink_CheckLinks: queue is inconsistent");
		p = p.queuenext;
		if (p == e)
			break;
	}
	if (i >= 1000)
		error("W_Crylink_CheckLinks: infinite chain");
}

void W_Crylink_Dequeue_Raw(entity own, entity prev, entity me, entity next)
{
	W_Crylink_CheckLinks(next);
	.entity weaponentity = me.weaponentity_fld;
	if (me == own.(weaponentity).crylink_lastgroup)
		own.(weaponentity).crylink_lastgroup = (me == next) ? NULL : next;
	prev.queuenext = next;
	next.queueprev = prev;
	me.classname = "spike_oktoremove";
	if (me != next)
		W_Crylink_CheckLinks(next);
}

void W_Crylink_Dequeue(entity e)
{
	W_Crylink_Dequeue_Raw(e.crylink_owner, e.queueprev, e, e.queuenext);
}

void W_Crylink_DeleteLink(entity this)
{
	if (this.classname != "spike_oktoremove")
		W_Crylink_Dequeue(this);
	delete_fn(this);
}

void W_Crylink_Reset(entity this)
{
	delete(this);
}

// force projectile to explode
void W_Crylink_LinkExplode(entity e, entity e2, entity directhitentity)
{
	if (e == e2)
		return;

	float a = bound(0, 1 - (time - e.fade_time) * e.fade_rate, 1);

	.entity weaponentity = e.weaponentity_fld;
	if (e == e.crylink_owner.(weaponentity).crylink_lastgroup)
		e.crylink_owner.(weaponentity).crylink_lastgroup = NULL;

	bool is_primary = !(e.projectiledeathtype & HITTYPE_SECONDARY);
	RadiusDamage(e, e.realowner,
		a * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, damage),
		a * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, edgedamage),
		WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, radius),
		NULL,
		NULL,
		a * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, force),
		e.projectiledeathtype,
		e.weaponentity_fld,
		directhitentity
	);

	W_Crylink_LinkExplode(e.queuenext, e2, directhitentity);

	e.classname = "spike_oktoremove";
	delete(e);
}

// adjust towards center
// returns the origin where they will meet... and the time till the meeting is
// stored in w_crylink_linkjoin_time.
// could possibly network this origin and time, and display a special particle
// effect when projectiles meet there :P
// jspeed: joining speed (calculate this as join spread * initial speed)
float w_crylink_linkjoin_time;
vector W_Crylink_LinkJoin(entity e, float jspeed)
{
	// FIXME remove this debug code
	W_Crylink_CheckLinks(e);

	w_crylink_linkjoin_time = 0;

	entity p;
	vector avg_org = e.origin;
	vector avg_vel = e.velocity;
	float n = 1;
	for (p = e; (p = p.queuenext) != e; )
	{
		avg_org += WarpZone_RefSys_TransformOrigin(p, e, p.origin);
		avg_vel += WarpZone_RefSys_TransformVelocity(p, e, p.velocity);
		++n;
	}
	avg_org *= 1.0 / n;
	avg_vel *= 1.0 / n;

	if (n < 2)
		return avg_org; // nothing to do

	// yes, mathematically we can do this in ONE step, but beware of 32bit floats...
	float avg_dist = vlen2(e.origin - avg_org);
	for (p = e; (p = p.queuenext) != e; )
		avg_dist += vlen2(WarpZone_RefSys_TransformOrigin(p, e, p.origin) - avg_org);
	avg_dist = sqrt(avg_dist * (1.0 / n));

	if (avg_dist == 0)
		return avg_org; // no change needed

	vector targ_origin;
	if (jspeed == 0)
	{
		e.velocity = avg_vel;
		UpdateCSQCProjectile(e);
		for (p = e; (p = p.queuenext) != e; )
		{
			p.velocity = WarpZone_RefSys_TransformVelocity(e, p, avg_vel);
			UpdateCSQCProjectile(p);
		}
		targ_origin = avg_org + 1000000000 * normalize(avg_vel); // HUUUUUUGE
	}
	else
	{
		w_crylink_linkjoin_time = avg_dist / jspeed;
		targ_origin = avg_org + w_crylink_linkjoin_time * avg_vel;

		e.velocity = (targ_origin - e.origin) * (1.0 / w_crylink_linkjoin_time);
		UpdateCSQCProjectile(e);
		for (p = e; (p = p.queuenext) != e; )
		{
			p.velocity = WarpZone_RefSys_TransformVelocity(e, p, (targ_origin - WarpZone_RefSys_TransformOrigin(p, e, p.origin)) * (1.0 / w_crylink_linkjoin_time));
			UpdateCSQCProjectile(p);
		}

		// analysis:
		//   jspeed -> +infinity:
		//      w_crylink_linkjoin_time -> +0
		//      targ_origin -> avg_org
		//      p->velocity -> HUEG towards center
		//   jspeed -> 0:
		//      w_crylink_linkjoin_time -> +/- infinity
		//      targ_origin -> avg_vel * +/- infinity
		//      p->velocity -> avg_vel
		//   jspeed -> -infinity:
		//      w_crylink_linkjoin_time -> -0
		//      targ_origin -> avg_org
		//      p->velocity -> HUEG away from center
	}

	W_Crylink_CheckLinks(e);

	return targ_origin;
}

void W_Crylink_LinkJoinEffect_Think(entity this)
{
	// is there at least 2 projectiles very close?
	.entity weaponentity = this.weaponentity_fld;
	entity e = this.owner.(weaponentity).crylink_lastgroup;
	if (e)
	{
		float n = 0;
		if (vlen2(e.origin - this.origin) < vlen2(e.velocity) * frametime)
			++n;
		for (entity p = e; (p = p.queuenext) != e; )
			if (vlen2(p.origin - this.origin) < vlen2(p.velocity) * frametime)
				++n;
		if (n >= 2)
		{
			bool is_primary = !(e.projectiledeathtype & HITTYPE_SECONDARY);

			if (WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinexplode))
			{
				n /= WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, shots);
				RadiusDamage(e, e.realowner,
					n * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinexplode_damage),
					n * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinexplode_edgedamage),
					n * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinexplode_radius),
					e.realowner,
					NULL,
					n * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinexplode_force),
					e.projectiledeathtype,
					e.weaponentity_fld,
					NULL
				);
				Send_Effect(EFFECT_CRYLINK_JOINEXPLODE, this.origin, '0 0 0', n);
			}
		}
	}
	delete(this);
}

bool W_Crylink_Touch_WouldHitFriendly(entity projectile, float rad)
{
	entity head = WarpZone_FindRadius(projectile.origin + (projectile.mins + projectile.maxs) * 0.5, rad + MAX_DAMAGEEXTRARADIUS, false);
	bool hit_friendly = false;
	for (; head; head = head.chain)
		if (head.takedamage != DAMAGE_NO && !IS_DEAD(head))
		{
			if (SAME_TEAM(head, projectile.realowner))
				hit_friendly = true;
			else
				return false;
		}

	return hit_friendly;
}

// NO bounce protection, as bounces are limited!
void W_Crylink_Touch(entity this, entity toucher)
{
	bool is_primary = !(this.projectiledeathtype & HITTYPE_SECONDARY);
	PROJECTILE_TOUCH(this, toucher);

	float a = bound(0, 1 - (time - this.fade_time) * this.fade_rate, 1);
	float finalhit = (this.cnt <= 0 || toucher.takedamage != DAMAGE_NO);
	float f = (finalhit ? 1 : WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, bouncedamagefactor));
	if (a)
		f *= a;

	float totaldamage = RadiusDamage(this, this.realowner,
		f * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, damage),
		f * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, edgedamage),
		WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, radius),
		NULL,
		NULL,
		f * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, force),
		this.projectiledeathtype,
		this.weaponentity_fld,
		toucher
	);

	if (totaldamage
	&& ((WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, linkexplode) == 1 && !W_Crylink_Touch_WouldHitFriendly(this, WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, radius)))
		|| WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, linkexplode) == 2))
	{
		.entity weaponentity = this.weaponentity_fld;
		if (this == this.crylink_owner.(weaponentity).crylink_lastgroup)
			this.crylink_owner.(weaponentity).crylink_lastgroup = NULL;
		W_Crylink_LinkExplode(this.queuenext, this, toucher);
		this.classname = "spike_oktoremove";
		delete(this);
		return;
	}
	else if (finalhit)
	{
		// just unlink
		delete(this);
		return;
	}
	--this.cnt;
	this.angles = vectoangles(this.velocity);
	this.owner = NULL;
	this.projectiledeathtype |= HITTYPE_BOUNCE;
	// commented out as it causes a little hitch...
	//if (proj.cnt == 0)
	//	CSQCProjectile(proj, true, PROJECTILE_CRYLINK, true);
}

void W_Crylink_Fadethink(entity this)
{
	delete(this);
}

void W_Crylink_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(WEP_CRYLINK, ammo), weaponentity);

	float maxdmg = WEP_CVAR_PRI(WEP_CRYLINK, damage) * WEP_CVAR_PRI(WEP_CRYLINK, shots);
	maxdmg *= 1 + WEP_CVAR_PRI(WEP_CRYLINK, bouncedamagefactor) * WEP_CVAR_PRI(WEP_CRYLINK, bounces);
	if (WEP_CVAR_PRI(WEP_CRYLINK, joinexplode))
		maxdmg += WEP_CVAR_PRI(WEP_CRYLINK, joinexplode_damage);

	W_SetupShot(actor, weaponentity, false, 2, SND_CRYLINK_FIRE, CH_WEAPON_A, maxdmg, thiswep.m_id);
	vector right = v_right;
	vector up = v_up;

	int shots = WEP_CVAR_PRI(WEP_CRYLINK, shots);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);
	entity proj = NULL, prevproj = NULL, firstproj = NULL;
	vector s;
	for (int counter = 0; counter < shots; ++counter)
	{
		proj = new(spike);
		proj.dtor = W_Crylink_DeleteLink;
		proj.reset = W_Crylink_Reset;
		proj.realowner = proj.owner = actor;
		proj.crylink_owner = actor;
		proj.weaponentity_fld = weaponentity;
		proj.bot_dodge = true;
		proj.bot_dodgerating = WEP_CVAR_PRI(WEP_CRYLINK, damage);
		if (shots == 1)
		{
			proj.queuenext = proj;
			proj.queueprev = proj;
		}
		else if (counter == 0) // first projectile, store in firstproj for now
			firstproj = proj;
		else if (counter == shots - 1) // last projectile, link up with first projectile
		{
			prevproj.queuenext = proj;
			firstproj.queueprev = proj;
			proj.queuenext = firstproj;
			proj.queueprev = prevproj;
		}
		else // else link up with previous projectile
		{
			prevproj.queuenext = proj;
			proj.queueprev = prevproj;
		}

		prevproj = proj;

		set_movetype(proj, MOVETYPE_BOUNCEMISSILE);
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = thiswep.m_id;
		//proj.gravity = 0.001;

		setorigin(proj, w_shotorg);
		setsize(proj, '0 0 0', '0 0 0');

		s = W_CalculateSpreadPattern(1, 0, counter, shots) * WEP_CVAR_PRI(WEP_CRYLINK, spread) * autocvar_g_weaponspreadfactor;
		W_SetupProjVelocity_Explicit(proj, w_shotdir + right * s.y + up * s.z, v_up, WEP_CVAR_PRI(WEP_CRYLINK, speed), 0, 0, 0, false);
		settouch(proj, W_Crylink_Touch);

		setthink(proj, W_Crylink_Fadethink);
		if (counter == 0)
		{
			proj.fade_time = time + WEP_CVAR_PRI(WEP_CRYLINK, middle_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_PRI(WEP_CRYLINK, middle_fadetime);
			proj.nextthink = time + WEP_CVAR_PRI(WEP_CRYLINK, middle_lifetime) + WEP_CVAR_PRI(WEP_CRYLINK, middle_fadetime);
		}
		else
		{
			proj.fade_time = time + WEP_CVAR_PRI(WEP_CRYLINK, other_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_PRI(WEP_CRYLINK, other_fadetime);
			proj.nextthink = time + WEP_CVAR_PRI(WEP_CRYLINK, other_lifetime) + WEP_CVAR_PRI(WEP_CRYLINK, other_fadetime);
		}
		proj.teleport_time = time + WEP_CVAR_PRI(WEP_CRYLINK, joindelay);
		proj.cnt = WEP_CVAR_PRI(WEP_CRYLINK, bounces);
		//proj.scale = 1 + 1 * proj.cnt;

		proj.angles = vectoangles(proj.velocity);

		//proj.glow_size = 20;

		proj.flags = FL_PROJECTILE;
		IL_PUSH(g_projectiles, proj);
		IL_PUSH(g_bot_dodge, proj);
		proj.missile_flags = MIF_SPLASH;

		CSQCProjectile(proj, true, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), true);

		MUTATOR_CALLHOOK(EditProjectile, actor, proj);
	}
	if (WEP_CVAR_PRI(WEP_CRYLINK, joinspread) != 0 && WEP_CVAR_PRI(WEP_CRYLINK, shots) > 1)
	{
		actor.(weaponentity).crylink_lastgroup = proj;
		W_Crylink_CheckLinks(proj);
		actor.(weaponentity).crylink_waitrelease = 1;
	}
}

void W_Crylink_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(WEP_CRYLINK, ammo), weaponentity);

	float maxdmg = WEP_CVAR_SEC(WEP_CRYLINK, damage) * WEP_CVAR_SEC(WEP_CRYLINK, shots);
	maxdmg *= 1 + WEP_CVAR_SEC(WEP_CRYLINK, bouncedamagefactor) * WEP_CVAR_SEC(WEP_CRYLINK, bounces);
	if (WEP_CVAR_SEC(WEP_CRYLINK, joinexplode))
		maxdmg += WEP_CVAR_SEC(WEP_CRYLINK, joinexplode_damage);

	W_SetupShot(actor, weaponentity, false, 2, SND_CRYLINK_FIRE2, CH_WEAPON_A, maxdmg, thiswep.m_id | HITTYPE_SECONDARY);
	vector right = v_right;
	vector up = v_up;

	int shots = WEP_CVAR_SEC(WEP_CRYLINK, shots);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);
	entity proj = NULL, prevproj = NULL, firstproj = NULL;
	vector s;
	for (int counter = 0; counter < shots; ++counter)
	{
		proj = new(spike);
		proj.dtor = W_Crylink_DeleteLink;
		proj.weaponentity_fld = weaponentity;
		proj.reset = W_Crylink_Reset;
		proj.realowner = proj.owner = actor;
		proj.crylink_owner = actor;
		proj.bot_dodge = true;
		proj.bot_dodgerating = WEP_CVAR_SEC(WEP_CRYLINK, damage);
		if (shots == 1)
		{
			proj.queuenext = proj;
			proj.queueprev = proj;
		}
		else if (counter == 0) // first projectile, store in firstproj for now
			firstproj = proj;
		else if (counter == shots - 1) // last projectile, link up with first projectile
		{
			prevproj.queuenext = proj;
			firstproj.queueprev = proj;
			proj.queuenext = firstproj;
			proj.queueprev = prevproj;
		}
		else // else link up with previous projectile
		{
			prevproj.queuenext = proj;
			proj.queueprev = prevproj;
		}

		prevproj = proj;

		set_movetype(proj, MOVETYPE_BOUNCEMISSILE);
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
		//proj.gravity = 0.001;

		setorigin(proj, w_shotorg);
		setsize(proj, '0 0 0', '0 0 0');

		if (WEP_CVAR_SEC(WEP_CRYLINK, spreadtype) == 1)
		{
			s = W_CalculateSpreadPattern(1, 0, counter, shots) * WEP_CVAR_SEC(WEP_CRYLINK, spread) * autocvar_g_weaponspreadfactor;
			s = w_shotdir + right * s.y + up * s.z;
		}
		else
			s = w_shotdir + (((counter + 0.5) / shots) * 2 - 1) * v_right * WEP_CVAR_SEC(WEP_CRYLINK, spread) * autocvar_g_weaponspreadfactor;

		W_SetupProjVelocity_Explicit(proj, s, v_up, WEP_CVAR_SEC(WEP_CRYLINK, speed), 0, 0, 0, false);
		settouch(proj, W_Crylink_Touch);
		setthink(proj, W_Crylink_Fadethink);
		if (counter == (shots - 1) * 0.5)
		{
			proj.fade_time = time + WEP_CVAR_SEC(WEP_CRYLINK, middle_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_SEC(WEP_CRYLINK, middle_fadetime);
			proj.nextthink = time + WEP_CVAR_SEC(WEP_CRYLINK, middle_lifetime) + WEP_CVAR_SEC(WEP_CRYLINK, middle_fadetime);
		}
		else
		{
			proj.fade_time = time + WEP_CVAR_SEC(WEP_CRYLINK, other_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_SEC(WEP_CRYLINK, other_fadetime);
			proj.nextthink = time + WEP_CVAR_SEC(WEP_CRYLINK, other_lifetime) + WEP_CVAR_SEC(WEP_CRYLINK, other_fadetime);
		}
		proj.teleport_time = time + WEP_CVAR_SEC(WEP_CRYLINK, joindelay);
		proj.cnt = WEP_CVAR_SEC(WEP_CRYLINK, bounces);
		//proj.scale = 1 + 1 * proj.cnt;

		proj.angles = vectoangles(proj.velocity);

		//proj.glow_size = 20;

		proj.flags = FL_PROJECTILE;
		IL_PUSH(g_projectiles, proj);
		IL_PUSH(g_bot_dodge, proj);
		proj.missile_flags = MIF_SPLASH;

		CSQCProjectile(proj, true, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), true);

		MUTATOR_CALLHOOK(EditProjectile, actor, proj);
	}
	if (WEP_CVAR_SEC(WEP_CRYLINK, joinspread) != 0 && WEP_CVAR_SEC(WEP_CRYLINK, shots) > 1)
	{
		actor.(weaponentity).crylink_lastgroup = proj;
		W_Crylink_CheckLinks(proj);
		actor.(weaponentity).crylink_waitrelease = 2;
	}
}

METHOD(Crylink, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if (random() < 0.10)
		PHYS_INPUT_BUTTON_ATCK(actor)  = bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_CRYLINK, speed), 0, WEP_CVAR_PRI(WEP_CRYLINK, middle_lifetime), false, true);
	else
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_SEC(WEP_CRYLINK, speed), 0, WEP_CVAR_SEC(WEP_CRYLINK, middle_lifetime), false, true);
}

METHOD(Crylink, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if (autocvar_g_balance_crylink_reload_ammo
	&& actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(WEP_CRYLINK, ammo), WEP_CVAR_SEC(WEP_CRYLINK, ammo)))
		// forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	else if (fire & 1)
	{
		if (actor.(weaponentity).crylink_waitrelease != 1
		&& weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_CRYLINK, refire)))
		{
			W_Crylink_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_CRYLINK, animtime), w_ready);
		}
	}
	else if ((fire & 2) && autocvar_g_balance_crylink_secondary)
	{
		if (actor.(weaponentity).crylink_waitrelease != 2
		&& weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_CRYLINK, refire)))
		{
			W_Crylink_Attack2(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_CRYLINK, animtime), w_ready);
		}
	}

	if ((actor.(weaponentity).crylink_waitrelease == 1 && !(fire & 1))
	||  (actor.(weaponentity).crylink_waitrelease == 2 && !(fire & 2)))
	{
		if (!actor.(weaponentity).crylink_lastgroup || time > actor.(weaponentity).crylink_lastgroup.teleport_time)
		{
			// fired and released now!
			if (actor.(weaponentity).crylink_lastgroup)
			{
				bool is_primary = (actor.(weaponentity).crylink_waitrelease == 1);
				vector pos = W_Crylink_LinkJoin(actor.(weaponentity).crylink_lastgroup, WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, joinspread) * WEP_CVAR_BOTH(WEP_CRYLINK, is_primary, speed));

				entity linkjoineffect = new(linkjoineffect);
				linkjoineffect.weaponentity_fld = weaponentity;
				setthink(linkjoineffect, W_Crylink_LinkJoinEffect_Think);
				linkjoineffect.nextthink = time + w_crylink_linkjoin_time;
				linkjoineffect.owner = actor;
				setorigin(linkjoineffect, pos);
			}
			actor.(weaponentity).crylink_waitrelease = 0;
			if (!thiswep.wr_checkammo1(thiswep, actor, weaponentity) && !thiswep.wr_checkammo2(thiswep, actor, weaponentity)
			&& !(actor.items & IT_UNLIMITED_AMMO))
			{
				// ran out of ammo!
				actor.cnt = thiswep.m_id;
				actor.(weaponentity).m_switchweapon = w_getbestweapon(actor, weaponentity);
			}
		}
	}
}

METHOD(Crylink, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// don't "run out of ammo" and switch weapons while waiting for release
	if (actor.(weaponentity).crylink_lastgroup && actor.(weaponentity).crylink_waitrelease)
		return true;

	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_CRYLINK, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_CRYLINK, ammo);
	return ammo_amount;
}

METHOD(Crylink, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// don't "run out of ammo" and switch weapons while waiting for release
	if (actor.(weaponentity).crylink_lastgroup && actor.(weaponentity).crylink_waitrelease)
		return true;

	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(WEP_CRYLINK, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(WEP_CRYLINK, ammo);
	return ammo_amount;
}

METHOD(Crylink, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(WEP_CRYLINK, ammo), WEP_CVAR_SEC(WEP_CRYLINK, ammo)), SND_RELOAD);
}

METHOD(Crylink, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_CRYLINK_SUICIDE;
}

METHOD(Crylink, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_CRYLINK_MURDER;
}

#endif // SVQC
#ifdef CSQC

METHOD(Crylink, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	if (w_deathtype & HITTYPE_SECONDARY)
	{
		pointparticles(EFFECT_CRYLINK_IMPACT2, org2, '0 0 0', 1);
		if (!w_issilent)
			sound(actor, CH_SHOTS, SND_CRYLINK_IMPACT2, VOL_BASE, ATTN_NORM);
	}
	else
	{
		pointparticles(EFFECT_CRYLINK_IMPACT, org2, '0 0 0', 1);
		if (!w_issilent)
			sound(actor, CH_SHOTS, SND_CRYLINK_IMPACT, VOL_BASE, ATTN_NORM);
	}
}

#endif // CSQC
#ifdef MENUQC
#include <common/items/item/ammo.qh>

METHOD(Crylink, describe, string(Crylink this))
{
	TC(Crylink, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s fires bursts of laser-like projectiles, spreading out as they travel away and deflecting off walls. "
	      "If the primary fire is held, when it's released the projectiles will converge before spreading out again, "
	      "which can be utilized to deal more damage to an enemy by making the projectiles converge on them."), COLORED_NAME(this));
	PAR(_("Projectiles deal damage on collision but also when they bounce, so with good positioning they can sometimes deal double damage."));
	PAR(_("The secondary fire shoots the projectiles together in a tight group, so it is often the better option in situations where the enemy is an easy target to hit."));
	PAR(_("It consumes %s ammo for each projectile, which is shared by several weapons."), COLORED_NAME(ITEM_Cells));
	PAR(_("Close to medium range is the ideal time to use the %s, although the secondary fire can be useful for long range combat sometimes."), COLORED_NAME(this));
	PAR(_("The %s deals knockback in a unique way, pulling the player from their center to the point of impact. "
	      "This makes it one of the best weapons to slow someone down if you are chasing them, particularly with the secondary fire. "
	      "Another common use of the %s is \"crylink running,\" where you partially angle down and use the secondary fire to pull yourself forwards, in order to gain speed."), COLORED_NAME(this), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_bothMultishot(this.netname, "primary", "secondary"));
	return PAGE_TEXT;
}

#endif // MENUQC
