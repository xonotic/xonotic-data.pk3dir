#include "crylink.qh"

#ifdef SVQC

void W_Crylink_CheckLinks(entity e)
{
	float i;
	entity p;

	if(e == NULL)
		error("W_Crylink_CheckLinks: entity is NULL");
	if(e.classname != "spike" || wasfreed(e))
		error(sprintf("W_Crylink_CheckLinks: entity is not a spike but a %s (freed: %d)", e.classname, wasfreed(e)));

	p = e;
	for(i = 0; i < 1000; ++i)
	{
		if(p.queuenext.queueprev != p || p.queueprev.queuenext != p)
			error("W_Crylink_CheckLinks: queue is inconsistent");
		p = p.queuenext;
		if(p == e)
			break;
	}
	if(i >= 1000)
		error("W_Crylink_CheckLinks: infinite chain");
}

void W_Crylink_Dequeue_Raw(entity own, entity prev, entity me, entity next)
{
	W_Crylink_CheckLinks(next);
	.entity weaponentity = me.weaponentity_fld;
	if(me == own.(weaponentity).crylink_lastgroup)
		own.(weaponentity).crylink_lastgroup = ((me == next) ? NULL : next);
	prev.queuenext = next;
	next.queueprev = prev;
	me.classname = "spike_oktoremove";
	if(me != next)
		W_Crylink_CheckLinks(next);
}

void W_Crylink_Dequeue(entity e)
{
	W_Crylink_Dequeue_Raw(e.crylink_owner, e.queueprev, e, e.queuenext);
}

void W_Crylink_Reset(entity this)
{
	W_Crylink_Dequeue(this);
	delete(this);
}

// force projectile to explode
void W_Crylink_LinkExplode(entity e, entity e2, entity directhitentity)
{
	float a;

	if(e == e2)
		return;

	a = bound(0, 1 - (time - e.fade_time) * e.fade_rate, 1);

	.entity weaponentity = e.weaponentity_fld;
	if(e == e.crylink_owner.(weaponentity).crylink_lastgroup)
		e.crylink_owner.(weaponentity).crylink_lastgroup = NULL;

	float isprimary = !(e.projectiledeathtype & HITTYPE_SECONDARY);

	RadiusDamage(e, e.realowner, WEP_CVAR_BOTH(crylink, isprimary, damage) * a, WEP_CVAR_BOTH(crylink, isprimary, edgedamage) * a, WEP_CVAR_BOTH(crylink, isprimary, radius),
				NULL, NULL, WEP_CVAR_BOTH(crylink, isprimary, force) * a, e.projectiledeathtype, e.weaponentity_fld, directhitentity);

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
	vector avg_origin, avg_velocity;
	vector targ_origin;
	float avg_dist, n;
	entity p;

	// FIXME remove this debug code
	W_Crylink_CheckLinks(e);

	w_crylink_linkjoin_time = 0;

	avg_origin = e.origin;
	avg_velocity = e.velocity;
	n = 1;
	for(p = e; (p = p.queuenext) != e; )
	{
		avg_origin += WarpZone_RefSys_TransformOrigin(p, e, p.origin);
		avg_velocity += WarpZone_RefSys_TransformVelocity(p, e, p.velocity);
		++n;
	}
	avg_origin *= (1.0 / n);
	avg_velocity *= (1.0 / n);

	if(n < 2)
		return avg_origin; // nothing to do

	// yes, mathematically we can do this in ONE step, but beware of 32bit floats...
	avg_dist = (vlen(e.origin - avg_origin) ** 2);
	for(p = e; (p = p.queuenext) != e; )
		avg_dist += (vlen(WarpZone_RefSys_TransformOrigin(p, e, p.origin) - avg_origin) ** 2);
	avg_dist *= (1.0 / n);
	avg_dist = sqrt(avg_dist);

	if(avg_dist == 0)
		return avg_origin; // no change needed

	if(jspeed == 0)
	{
		e.velocity = avg_velocity;
		UpdateCSQCProjectile(e);
		for(p = e; (p = p.queuenext) != e; )
		{
			p.velocity = WarpZone_RefSys_TransformVelocity(e, p, avg_velocity);
			UpdateCSQCProjectile(p);
		}
		targ_origin = avg_origin + 1000000000 * normalize(avg_velocity); // HUUUUUUGE
	}
	else
	{
		w_crylink_linkjoin_time = avg_dist / jspeed;
		targ_origin = avg_origin + w_crylink_linkjoin_time * avg_velocity;

		e.velocity = (targ_origin - e.origin) * (1.0 / w_crylink_linkjoin_time);
		UpdateCSQCProjectile(e);
		for(p = e; (p = p.queuenext) != e; )
		{
			p.velocity = WarpZone_RefSys_TransformVelocity(e, p, (targ_origin - WarpZone_RefSys_TransformOrigin(p, e, p.origin)) * (1.0 / w_crylink_linkjoin_time));
			UpdateCSQCProjectile(p);
		}

		// analysis:
		//   jspeed -> +infinity:
		//      w_crylink_linkjoin_time -> +0
		//      targ_origin -> avg_origin
		//      p->velocity -> HUEG towards center
		//   jspeed -> 0:
		//      w_crylink_linkjoin_time -> +/- infinity
		//      targ_origin -> avg_velocity * +/- infinity
		//      p->velocity -> avg_velocity
		//   jspeed -> -infinity:
		//      w_crylink_linkjoin_time -> -0
		//      targ_origin -> avg_origin
		//      p->velocity -> HUEG away from center
	}

	W_Crylink_CheckLinks(e);

	return targ_origin;
}

void W_Crylink_LinkJoinEffect_Think(entity this)
{
	// is there at least 2 projectiles very close?
	entity e, p;
	float n;
	.entity weaponentity = this.weaponentity_fld;
	e = this.owner.(weaponentity).crylink_lastgroup;
	n = 0;
	if(e)
	{
		if(vlen2(e.origin - this.origin) < vlen2(e.velocity) * frametime)
			++n;
		for(p = e; (p = p.queuenext) != e; )
		{
			if(vlen2(p.origin - this.origin) < vlen2(p.velocity) * frametime)
				++n;
		}
		if(n >= 2)
		{
			float isprimary = !(e.projectiledeathtype & HITTYPE_SECONDARY);

			if(WEP_CVAR_BOTH(crylink, isprimary, joinexplode))
			{
				n /= WEP_CVAR_BOTH(crylink, isprimary, shots);
				RadiusDamage(
					e,
					e.realowner,
					WEP_CVAR_BOTH(crylink, isprimary, joinexplode_damage) * n,
					WEP_CVAR_BOTH(crylink, isprimary, joinexplode_edgedamage) * n,
					WEP_CVAR_BOTH(crylink, isprimary, joinexplode_radius) * n,
					e.realowner,
					NULL,
					WEP_CVAR_BOTH(crylink, isprimary, joinexplode_force) * n,
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

float W_Crylink_Touch_WouldHitFriendly(entity projectile, float rad)
{
	entity head = WarpZone_FindRadius((projectile.origin + (projectile.mins + projectile.maxs) * 0.5), rad + MAX_DAMAGEEXTRARADIUS, false);
	float hit_friendly = 0;
	float hit_enemy = 0;

	while(head)
	{
		if((head.takedamage != DAMAGE_NO) && (!IS_DEAD(head)))
		{
			if(SAME_TEAM(head, projectile.realowner))
				++hit_friendly;
			else
				++hit_enemy;
		}

		head = head.chain;
	}

	return (hit_enemy ? false : hit_friendly);
}

// NO bounce protection, as bounces are limited!
void W_Crylink_Touch(entity this, entity toucher)
{
	float finalhit;
	float f;
	float isprimary = !(this.projectiledeathtype & HITTYPE_SECONDARY);
	PROJECTILE_TOUCH(this, toucher);

	float a;
	a = bound(0, 1 - (time - this.fade_time) * this.fade_rate, 1);

	finalhit = ((this.cnt <= 0) || (toucher.takedamage != DAMAGE_NO));
	if(finalhit)
		f = 1;
	else
		f = WEP_CVAR_BOTH(crylink, isprimary, bouncedamagefactor);
	if(a)
		f *= a;

	float totaldamage = RadiusDamage(this, this.realowner, WEP_CVAR_BOTH(crylink, isprimary, damage) * f, WEP_CVAR_BOTH(crylink, isprimary, edgedamage) * f, WEP_CVAR_BOTH(crylink, isprimary, radius),
										NULL, NULL, WEP_CVAR_BOTH(crylink, isprimary, force) * f, this.projectiledeathtype, this.weaponentity_fld, toucher);

	if(totaldamage && ((WEP_CVAR_BOTH(crylink, isprimary, linkexplode) == 2) || ((WEP_CVAR_BOTH(crylink, isprimary, linkexplode) == 1) && !W_Crylink_Touch_WouldHitFriendly(this, WEP_CVAR_BOTH(crylink, isprimary, radius)))))
	{
		.entity weaponentity = this.weaponentity_fld;
		if(this == this.crylink_owner.(weaponentity).crylink_lastgroup)
			this.crylink_owner.(weaponentity).crylink_lastgroup = NULL;
		W_Crylink_LinkExplode(this.queuenext, this, toucher);
		this.classname = "spike_oktoremove";
		delete(this);
		return;
	}
	else if(finalhit)
	{
		// just unlink
		W_Crylink_Dequeue(this);
		delete(this);
		return;
	}
	this.cnt = this.cnt - 1;
	this.angles = vectoangles(this.velocity);
	this.owner = NULL;
	this.projectiledeathtype |= HITTYPE_BOUNCE;
	// commented out as it causes a little hitch...
	//if(proj.cnt == 0)
	//	CSQCProjectile(proj, true, PROJECTILE_CRYLINK, true);
}

void W_Crylink_Fadethink(entity this)
{
	W_Crylink_Dequeue(this);
	delete(this);
}

void W_Crylink_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	float counter, shots;
	entity proj, prevproj, firstproj;
	vector s;
	vector forward, right, up;
	float maxdmg;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(crylink, ammo), weaponentity);

	maxdmg = WEP_CVAR_PRI(crylink, damage) * WEP_CVAR_PRI(crylink, shots);
	maxdmg *= 1 + WEP_CVAR_PRI(crylink, bouncedamagefactor) * WEP_CVAR_PRI(crylink, bounces);
	if(WEP_CVAR_PRI(crylink, joinexplode))
		maxdmg += WEP_CVAR_PRI(crylink, joinexplode_damage);

	W_SetupShot(actor, weaponentity, false, 2, SND_CRYLINK_FIRE, CH_WEAPON_A, maxdmg, thiswep.m_id);
	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = WEP_CVAR_PRI(crylink, shots);
	Send_Effect(EFFECT_CRYLINK_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, shots);
	proj = prevproj = firstproj = NULL;
	for(counter = 0; counter < shots; ++counter)
	{
		proj = new(spike);
		proj.reset = W_Crylink_Reset;
		proj.realowner = proj.owner = actor;
		proj.crylink_owner = actor;
		proj.weaponentity_fld = weaponentity;
		proj.bot_dodge = true;
		proj.bot_dodgerating = WEP_CVAR_PRI(crylink, damage);
		if(shots == 1) {
			proj.queuenext = proj;
			proj.queueprev = proj;
		}
		else if(counter == 0) { // first projectile, store in firstproj for now
			firstproj = proj;
		}
		else if(counter == shots - 1) { // last projectile, link up with first projectile
			prevproj.queuenext = proj;
			firstproj.queueprev = proj;
			proj.queuenext = firstproj;
			proj.queueprev = prevproj;
		}
		else { // else link up with previous projectile
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


		s = '0 0 0';
		if(counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s.y = v_forward.x;
			s.z = v_forward.y;
		}
		s = s * WEP_CVAR_PRI(crylink, spread) * g_weaponspreadfactor;
		W_SetupProjVelocity_Explicit(proj, w_shotdir + right * s.y + up * s.z, v_up, WEP_CVAR_PRI(crylink, speed), 0, 0, 0, false);
		settouch(proj, W_Crylink_Touch);

		setthink(proj, W_Crylink_Fadethink);
		if(counter == 0)
		{
			proj.fade_time = time + WEP_CVAR_PRI(crylink, middle_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_PRI(crylink, middle_fadetime);
			proj.nextthink = time + WEP_CVAR_PRI(crylink, middle_lifetime) + WEP_CVAR_PRI(crylink, middle_fadetime);
		}
		else
		{
			proj.fade_time = time + WEP_CVAR_PRI(crylink, other_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_PRI(crylink, other_fadetime);
			proj.nextthink = time + WEP_CVAR_PRI(crylink, other_lifetime) + WEP_CVAR_PRI(crylink, other_fadetime);
		}
		proj.teleport_time = time + WEP_CVAR_PRI(crylink, joindelay);
		proj.cnt = WEP_CVAR_PRI(crylink, bounces);
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
	if(WEP_CVAR_PRI(crylink, joinspread) != 0)
	{
		actor.(weaponentity).crylink_lastgroup = proj;
		W_Crylink_CheckLinks(proj);
		actor.(weaponentity).crylink_waitrelease = 1;
	}
}

void W_Crylink_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	float counter, shots;
	entity proj, prevproj, firstproj;
	vector s;
	vector forward, right, up;
	float maxdmg;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(crylink, ammo), weaponentity);

	maxdmg = WEP_CVAR_SEC(crylink, damage) * WEP_CVAR_SEC(crylink, shots);
	maxdmg *= 1 + WEP_CVAR_SEC(crylink, bouncedamagefactor) * WEP_CVAR_SEC(crylink, bounces);
	if(WEP_CVAR_SEC(crylink, joinexplode))
		maxdmg += WEP_CVAR_SEC(crylink, joinexplode_damage);

	W_SetupShot(actor, weaponentity, false, 2, SND_CRYLINK_FIRE2, CH_WEAPON_A, maxdmg, thiswep.m_id | HITTYPE_SECONDARY);
	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = WEP_CVAR_SEC(crylink, shots);
	Send_Effect(EFFECT_CRYLINK_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, shots);
	proj = prevproj = firstproj = NULL;
	for(counter = 0; counter < shots; ++counter)
	{
		proj = new(spike);
		proj.weaponentity_fld = weaponentity;
		proj.reset = W_Crylink_Reset;
		proj.realowner = proj.owner = actor;
		proj.crylink_owner = actor;
		proj.bot_dodge = true;
		proj.bot_dodgerating = WEP_CVAR_SEC(crylink, damage);
		if(shots == 1) {
			proj.queuenext = proj;
			proj.queueprev = proj;
		}
		else if(counter == 0) { // first projectile, store in firstproj for now
			firstproj = proj;
		}
		else if(counter == shots - 1) { // last projectile, link up with first projectile
			prevproj.queuenext = proj;
			firstproj.queueprev = proj;
			proj.queuenext = firstproj;
			proj.queueprev = prevproj;
		}
		else { // else link up with previous projectile
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

		if(WEP_CVAR_SEC(crylink, spreadtype) == 1)
		{
			s = '0 0 0';
			if(counter == 0)
				s = '0 0 0';
			else
			{
				makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
				s.y = v_forward.x;
				s.z = v_forward.y;
			}
			s = s * WEP_CVAR_SEC(crylink, spread) * g_weaponspreadfactor;
			s = w_shotdir + right * s.y + up * s.z;
		}
		else
		{
			s = (w_shotdir + (((counter + 0.5) / shots) * 2 - 1) * v_right * WEP_CVAR_SEC(crylink, spread) * g_weaponspreadfactor);
		}

		W_SetupProjVelocity_Explicit(proj, s, v_up, WEP_CVAR_SEC(crylink, speed), 0, 0, 0, false);
		settouch(proj, W_Crylink_Touch);
		setthink(proj, W_Crylink_Fadethink);
		if(counter == (shots - 1) / 2)
		{
			proj.fade_time = time + WEP_CVAR_SEC(crylink, middle_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_SEC(crylink, middle_fadetime);
			proj.nextthink = time + WEP_CVAR_SEC(crylink, middle_lifetime) + WEP_CVAR_SEC(crylink, middle_fadetime);
		}
		else
		{
			proj.fade_time = time + WEP_CVAR_SEC(crylink, other_lifetime);
			proj.fade_rate = 1 / WEP_CVAR_SEC(crylink, other_fadetime);
			proj.nextthink = time + WEP_CVAR_SEC(crylink, other_lifetime) + WEP_CVAR_SEC(crylink, other_fadetime);
		}
		proj.teleport_time = time + WEP_CVAR_SEC(crylink, joindelay);
		proj.cnt = WEP_CVAR_SEC(crylink, bounces);
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
	if(WEP_CVAR_SEC(crylink, joinspread) != 0)
	{
		actor.(weaponentity).crylink_lastgroup = proj;
		W_Crylink_CheckLinks(proj);
		actor.(weaponentity).crylink_waitrelease = 2;
	}
}

METHOD(Crylink, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(random() < 0.10)
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(crylink, speed), 0, WEP_CVAR_PRI(crylink, middle_lifetime), false);
    else
        PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_SEC(crylink, speed), 0, WEP_CVAR_SEC(crylink, middle_lifetime), false);
}
METHOD(Crylink, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(autocvar_g_balance_crylink_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(crylink, ammo), WEP_CVAR_SEC(crylink, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    }

    // attack swapping is useful for emulating BFG behavior in XDF
    int primary_fire = autocvar_g_balance_crylink_swap_attacks ? fire & 2 : fire & 1;
    int secondary_fire = autocvar_g_balance_crylink_swap_attacks ? fire & 1 : fire & 2;

    if(primary_fire)
    {
        if(actor.(weaponentity).crylink_waitrelease != 1)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(crylink, refire)))
        {
            W_Crylink_Attack(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(crylink, animtime), w_ready);
        }
    }

    if((secondary_fire) && autocvar_g_balance_crylink_secondary)
    {
        if(actor.(weaponentity).crylink_waitrelease != 2)
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(crylink, refire)))
        {
            W_Crylink_Attack2(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(crylink, animtime), w_ready);
        }
    }

    if((actor.(weaponentity).crylink_waitrelease == 1 && !(primary_fire)) || (actor.(weaponentity).crylink_waitrelease == 2 && !(secondary_fire)))
    {
        if(!actor.(weaponentity).crylink_lastgroup || time > actor.(weaponentity).crylink_lastgroup.teleport_time)
        {
            // fired and released now!
            if(actor.(weaponentity).crylink_lastgroup)
            {
                vector pos;
                entity linkjoineffect;
                float isprimary = (actor.(weaponentity).crylink_waitrelease == 1);

                pos = W_Crylink_LinkJoin(actor.(weaponentity).crylink_lastgroup, WEP_CVAR_BOTH(crylink, isprimary, joinspread) * WEP_CVAR_BOTH(crylink, isprimary, speed));

                linkjoineffect = new(linkjoineffect);
                linkjoineffect.weaponentity_fld = weaponentity;
                setthink(linkjoineffect, W_Crylink_LinkJoinEffect_Think);
                linkjoineffect.nextthink = time + w_crylink_linkjoin_time;
                linkjoineffect.owner = actor;
                setorigin(linkjoineffect, pos);
            }
            actor.(weaponentity).crylink_waitrelease = 0;
            if(!thiswep.wr_checkammo1(thiswep, actor, weaponentity) && !thiswep.wr_checkammo2(thiswep, actor, weaponentity))
            if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
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
    if(actor.(weaponentity).crylink_lastgroup && actor.(weaponentity).crylink_waitrelease)
        return true;

    float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(crylink, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(crylink, ammo);
    return ammo_amount;
}
METHOD(Crylink, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    // don't "run out of ammo" and switch weapons while waiting for release
    if(actor.(weaponentity).crylink_lastgroup && actor.(weaponentity).crylink_waitrelease)
        return true;

    float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(crylink, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(crylink, ammo);
    return ammo_amount;
}
METHOD(Crylink, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(crylink, ammo), WEP_CVAR_SEC(crylink, ammo)), SND_RELOAD);
}
METHOD(Crylink, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_CRYLINK_SUICIDE;
}
METHOD(Crylink, wr_killmessage, Notification(entity thiswep))
{
    return WEAPON_CRYLINK_MURDER;
}
#endif
#ifdef CSQC
METHOD(Crylink, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        pointparticles(EFFECT_CRYLINK_IMPACT2, org2, '0 0 0', 1);
        if(!w_issilent)
            sound(actor, CH_SHOTS, SND_CRYLINK_IMPACT2, VOL_BASE, ATTN_NORM);
    }
    else
    {
        pointparticles(EFFECT_CRYLINK_IMPACT, org2, '0 0 0', 1);
        if(!w_issilent)
            sound(actor, CH_SHOTS, SND_CRYLINK_IMPACT, VOL_BASE, ATTN_NORM);
    }
}
#endif
