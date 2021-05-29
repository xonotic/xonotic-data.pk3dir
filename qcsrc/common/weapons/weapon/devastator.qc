#include "devastator.qh"

#ifdef SVQC

.entity lastrocket;

void W_Devastator_Unregister(entity this)
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.realowner.(weaponentity).lastrocket == this)
			this.realowner.(weaponentity).lastrocket = NULL;
	}
}

void W_Devastator_Explode(entity this, entity directhitentity)
{
	W_Devastator_Unregister(this);

	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	RadiusDamage(
		this,
		this.realowner,
		WEP_CVAR(devastator, damage),
		WEP_CVAR(devastator, edgedamage),
		WEP_CVAR(devastator, radius),
		NULL,
		NULL,
		WEP_CVAR(devastator, force),
		this.projectiledeathtype,
		this.weaponentity_fld,
		directhitentity
	);

	Weapon thiswep = WEP_DEVASTATOR;
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		if(GetResource(this.realowner, thiswep.ammo_type) < WEP_CVAR(devastator, ammo))
		if(!(this.realowner.items & IT_UNLIMITED_AMMO))
		{
			this.realowner.cnt = thiswep.m_id;
			ATTACK_FINISHED(this.realowner, weaponentity) = time;
			this.realowner.(weaponentity).m_switchweapon = w_getbestweapon(this.realowner, weaponentity);
		}
	}
	delete(this);
}

void W_Devastator_Explode_think(entity this)
{
	W_Devastator_Explode(this, NULL);
}

void W_Devastator_DoRemoteExplode(entity this, .entity weaponentity)
{
	W_Devastator_Unregister(this);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	bool handled_as_rocketjump = false;
	entity head = NULL;
	bool allow_rocketjump = WEP_CVAR(devastator, remote_jump);
	MUTATOR_CALLHOOK(AllowRocketJumping, allow_rocketjump);
	allow_rocketjump = M_ARGV(0, bool);

	if(allow_rocketjump && WEP_CVAR(devastator, remote_jump_radius))
	{
		head = WarpZone_FindRadius(
			this.origin,
			WEP_CVAR(devastator, remote_jump_radius),
			false
		);

		while(head)
		{
			if(head.takedamage && (head == this.realowner))
			{
				if(vdist(this.origin - head.WarpZone_findradius_nearest, <=, WEP_CVAR(devastator, remote_jump_radius)))
				{
					// we handled this as a rocketjump :)
					handled_as_rocketjump = true;

					// modify velocity
					if(WEP_CVAR(devastator, remote_jump_velocity_z_add))
					{
						head.velocity_x *= 0.9;
						head.velocity_y *= 0.9;
						head.velocity_z = bound(
							WEP_CVAR(devastator, remote_jump_velocity_z_min),
							head.velocity.z + WEP_CVAR(devastator, remote_jump_velocity_z_add),
							WEP_CVAR(devastator, remote_jump_velocity_z_max)
						);
					}

					// now do the damage
					RadiusDamage(
						this,
						head,
						WEP_CVAR(devastator, remote_jump_damage),
						WEP_CVAR(devastator, remote_jump_damage),
						WEP_CVAR(devastator, remote_jump_radius),
						NULL,
						head,
						(WEP_CVAR(devastator, remote_jump_force) ? WEP_CVAR(devastator, remote_jump_force) : 0),
						this.projectiledeathtype | HITTYPE_BOUNCE,
						this.weaponentity_fld,
						NULL
					);
					break;
				}
			}
			head = head.chain;
		}
	}

	RadiusDamage(
		this,
		this.realowner,
		WEP_CVAR(devastator, remote_damage),
		WEP_CVAR(devastator, remote_edgedamage),
		WEP_CVAR(devastator, remote_radius),
		(handled_as_rocketjump ? head : NULL),
		NULL,
		WEP_CVAR(devastator, remote_force),
		this.projectiledeathtype | HITTYPE_BOUNCE,
		this.weaponentity_fld,
		NULL
	);

	Weapon thiswep = WEP_DEVASTATOR;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		if(GetResource(this.realowner, thiswep.ammo_type) < WEP_CVAR(devastator, ammo))
		if(!(this.realowner.items & IT_UNLIMITED_AMMO))
		{
			this.realowner.cnt = thiswep.m_id;
			ATTACK_FINISHED(this.realowner, weaponentity) = time;
			this.realowner.(weaponentity).m_switchweapon = w_getbestweapon(this.realowner, weaponentity);
		}
	}
	delete(this);
}

void W_Devastator_RemoteExplode(entity this, .entity weaponentity)
{
	if(!IS_DEAD(this.realowner))
	if(this.realowner.(weaponentity).lastrocket)
	{
		if((this.spawnshieldtime >= 0)
			? (time >= this.spawnshieldtime) // timer
			: (vdist(NearestPointOnBox(this.realowner, this.origin) - this.origin, >, WEP_CVAR(devastator, remote_radius))) // safety device
		)
		{
			W_Devastator_DoRemoteExplode(this, weaponentity);
		}
	}
}

vector W_Devastator_SteerTo(vector thisdir, vector goaldir, float maxturn_cos)
{
	if(thisdir * goaldir > maxturn_cos)
		return goaldir;
	if(thisdir * goaldir < -0.9998) // less than 1 degree and opposite
		return thisdir; // refuse to guide (better than letting a numerical error happen)
	float f, m2;
	vector v;
	// solve:
	//   g = normalize(thisdir + goaldir * X)
	//   thisdir * g = maxturn
	//
	//   gg = thisdir + goaldir * X
	//   (thisdir * gg)^2 = maxturn^2 * (gg * gg)
	//
	//   (1 + (thisdir * goaldir) * X)^2 = maxturn^2 * (1 + X*X + 2 * X * thisdir * goaldir)
	f = thisdir * goaldir;
	//   (1 + f * X)^2 = maxturn^2 * (1 + X*X + 2 * X * f)
	//   0 = (m^2 - f^2) * x^2 + (2 * f * (m^2 - 1)) * x + (m^2 - 1)
	m2 = maxturn_cos * maxturn_cos;
	v = solve_quadratic(m2 - f * f, 2 * f * (m2 - 1), m2 - 1);
	return normalize(thisdir + goaldir * v.y); // the larger solution!
}
// assume thisdir == -goaldir:
//   f == -1
//   v = solve_qadratic(m2 - 1, -2 * (m2 - 1), m2 - 1)
//   (m2 - 1) x^2 - 2 * (m2 - 1) * x + (m2 - 1) = 0
//   x^2 - 2 * x + 1 = 0
//   (x - 1)^2 = 0
//   x = 1
//   normalize(thisdir + goaldir)
//   normalize(0)

void W_Devastator_Think(entity this)
{
	vector desireddir, olddir, newdir, desiredorigin, goal;
	float velspeed, f;
	this.nextthink = time;
	if(time > this.cnt)
	{
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Devastator_Explode(this, NULL);
		return;
	}

	// accelerate
	makevectors(this.angles.x * '-1 0 0' + this.angles.y * '0 1 0');
	velspeed = WEP_CVAR(devastator, speed) * W_WeaponSpeedFactor(this.realowner) - (this.velocity * v_forward);
	if(velspeed > 0)
		this.velocity = this.velocity + v_forward * min(WEP_CVAR(devastator, speedaccel) * W_WeaponSpeedFactor(this.realowner) * frametime, velspeed);

	// laser guided, or remote detonation
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_DEVASTATOR)
	{
		if(this == this.realowner.(weaponentity).lastrocket)
		if(!this.realowner.(weaponentity).rl_release)
		if(!PHYS_INPUT_BUTTON_ATCK2(this))
		if(WEP_CVAR(devastator, guiderate))
		if(time > this.pushltime)
		if(!IS_DEAD(this.realowner))
		{
			f = WEP_CVAR(devastator, guideratedelay);
			if(f)
				f = bound(0, (time - this.pushltime) / f, 1);
			else
				f = 1;

			vector md = this.realowner.(weaponentity).movedir;
			vector vecs = ((md.x > 0) ? md : '0 0 0');

			vector dv = v_right * -vecs.y + v_up * vecs.z;

			if(!W_DualWielding(this.realowner))
				dv = '0 0 0'; // don't override!

			velspeed = vlen(this.velocity);

			makevectors(this.realowner.v_angle);
			desireddir = WarpZone_RefSys_TransformVelocity(this.realowner, this, v_forward);
			desiredorigin = WarpZone_RefSys_TransformOrigin(this.realowner, this, this.realowner.origin + this.realowner.view_ofs + dv);
			olddir = normalize(this.velocity);

			// now it gets tricky... we want to move like some curve to approximate the target direction
			// but we are limiting the rate at which we can turn!
			goal = desiredorigin + ((this.origin - desiredorigin) * desireddir + WEP_CVAR(devastator, guidegoal)) * desireddir;
			newdir = W_Devastator_SteerTo(olddir, normalize(goal - this.origin), cos(WEP_CVAR(devastator, guiderate) * f * frametime * DEG2RAD));

			this.velocity = newdir * velspeed;
			this.angles = vectoangles(this.velocity);

			if(!this.count)
			{
				Send_Effect(EFFECT_ROCKET_GUIDE, this.origin, this.velocity, 1);
				// TODO add a better sound here
				sound(this.realowner, CH_WEAPON_B, SND_ROCKET_MODE, VOL_BASE, ATTN_NORM);
				this.count = 1;
			}
		}

		if(this.rl_detonate_later)
			W_Devastator_RemoteExplode(this, weaponentity);
	}

	if(this.csqcprojectile_clientanimate == 0)
		UpdateCSQCProjectile(this);
}

void W_Devastator_Touch(entity this, entity toucher)
{
	if(WarpZone_Projectile_Touch(this, toucher))
	{
		if(wasfreed(this))
			W_Devastator_Unregister(this);
		return;
	}
	W_Devastator_Unregister(this);
	W_Devastator_Explode(this, toucher);
}

void W_Devastator_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	this.angles = vectoangles(this.velocity);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, W_Devastator_Explode_think);
}

void W_Devastator_Attack(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(devastator, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 5, SND_ROCKET_FIRE, CH_WEAPON_A, WEP_CVAR(devastator, damage), thiswep.m_id);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity missile = WarpZone_RefSys_SpawnSameRefSys(actor);
	missile.weaponentity_fld = weaponentity;
	missile.owner = missile.realowner = actor;
	actor.(weaponentity).lastrocket = missile;
	if(WEP_CVAR(devastator, detonatedelay) >= 0)
		missile.spawnshieldtime = time + WEP_CVAR(devastator, detonatedelay);
	else
		missile.spawnshieldtime = -1; // NOTE: proximity based when rocket jumping
	missile.pushltime = time + WEP_CVAR(devastator, guidedelay);
	missile.classname = "rocket";
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(devastator, damage) * 2; // * 2 because it can be detonated inflight which makes it even more dangerous

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = WEP_CVAR(devastator, damageforcescale);
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR(devastator, health));
	missile.event_damage = W_Devastator_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);

	set_movetype(missile, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = thiswep.m_id;
	setsize(missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin(missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(missile, WEP_CVAR(devastator, speedstart), 0);
	missile.angles = vectoangles(missile.velocity);

	settouch(missile, W_Devastator_Touch);
	setthink(missile, W_Devastator_Think);
	missile.nextthink = time;
	missile.cnt = time + WEP_CVAR(devastator, lifetime);
	missile.rl_detonate_later = (fire & 2); // allow instant detonation
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, WEP_CVAR(devastator, guiderate) == 0 && WEP_CVAR(devastator, speedaccel) == 0, PROJECTILE_ROCKET, false); // because of fly sound

	// common properties
	MUTATOR_CALLHOOK(EditProjectile, actor, missile);

	if (time >= missile.nextthink)
	{
		getthink(missile)(missile);
	}
}

METHOD(Devastator, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    // aim and decide to fire if appropriate
    PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR(devastator, speed), 0, WEP_CVAR(devastator, lifetime), false);
    if(skill >= 2) // skill 0 and 1 bots won't detonate rockets!
    {
        // decide whether to detonate rockets
        float edgedamage, coredamage, edgeradius, recipricoledgeradius;
        float selfdamage, teamdamage, enemydamage;
        edgedamage = WEP_CVAR(devastator, edgedamage);
        coredamage = WEP_CVAR(devastator, damage);
        edgeradius = WEP_CVAR(devastator, radius);
        recipricoledgeradius = 1 / edgeradius;
        selfdamage = 0;
        teamdamage = 0;
        enemydamage = 0;
        IL_EACH(g_projectiles, it.realowner == actor && it.classname == "rocket",
        {
            entity rocket = it;
            IL_EACH(g_bot_targets, it.bot_attack,
            {
            	float d = vlen(it.origin + (it.mins + it.maxs) * 0.5 - rocket.origin);
            	d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
            	// count potential damage according to type of target
            	if(it == actor)
            		selfdamage = selfdamage + d;
            	else if(SAME_TEAM(it, actor))
            		teamdamage = teamdamage + d;
            	else if(bot_shouldattack(actor, it))
            		enemydamage = enemydamage + d;
            });
        });
        float desirabledamage;
        desirabledamage = enemydamage;
        if(StatusEffects_active(STATUSEFFECT_Shield, actor) && !StatusEffects_active(STATUSEFFECT_SpawnShield, actor))
            desirabledamage = desirabledamage - selfdamage * autocvar_g_balance_selfdamagepercent;
        if(teamplay && actor.team)
            desirabledamage = desirabledamage - teamdamage;

        makevectors(actor.v_angle);
        IL_EACH(g_projectiles, it.realowner == actor && it.classname == "rocket",
        {
            if(skill > 9) // normal players only do this for the target they are tracking
            {
	            entity rocket = it;
	            IL_EACH(g_bot_targets, it.bot_attack,
	            {
	            	if((v_forward * normalize(rocket.origin - it.origin) < 0.1)
	                    && desirabledamage > 0.1 * coredamage
	                    ) PHYS_INPUT_BUTTON_ATCK2(actor) = true;
	            });
	        }
	        else
	        {
                //As the distance gets larger, a correct detonation gets near imposible
                //Bots are assumed to use the rocket spawnfunc_light to see if the rocket gets near a player
                if((v_forward * normalize(it.origin - actor.enemy.origin) < 0.1)
                	&& IS_PLAYER(actor.enemy)
                	&& (desirabledamage >= 0.1 * coredamage)
                	)
                {
                	float distance = bound(300, vlen(actor.origin - actor.enemy.origin), 30000);
                	if(random() / distance * 300 > frametime * bound(0, (10 - skill) * 0.2, 1))
                		PHYS_INPUT_BUTTON_ATCK2(actor) = true;
                }
	        }
        });
        // if we would be doing at X percent of the core damage, detonate it
        // but don't fire a new shot at the same time!
        if(desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
        if((skill > 6.5) && (selfdamage > GetResource(actor, RES_HEALTH)))
            PHYS_INPUT_BUTTON_ATCK2(actor) = false;
        //if(PHYS_INPUT_BUTTON_ATCK2(actor) == true)
        //	dprint(ftos(desirabledamage),"\n");
        if(PHYS_INPUT_BUTTON_ATCK2(actor)) PHYS_INPUT_BUTTON_ATCK(actor) = false;
    }
}

METHOD(Devastator, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(WEP_CVAR(devastator, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR(devastator, ammo)) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else {
        if(fire & 1)
        {
            if(actor.(weaponentity).rl_release || WEP_CVAR(devastator, guidestop))
            if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(devastator, refire)))
            {
                W_Devastator_Attack(thiswep, actor, weaponentity, fire);
                weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(devastator, animtime), w_ready);
                actor.(weaponentity).rl_release = 0;
            }
        }
        else
            actor.(weaponentity).rl_release = 1;

        if(fire & 2)
        if(actor.(weaponentity).m_switchweapon == thiswep)
        {
            bool rockfound = false;
            IL_EACH(g_projectiles, it.realowner == actor && it.classname == "rocket",
            {
                if(!it.rl_detonate_later)
                {
                    it.rl_detonate_later = true;
                    rockfound = true;
                }
            });
            if(rockfound)
                sound(actor, CH_WEAPON_B, SND_ROCKET_DET, VOL_BASE, ATTN_NORM);
        }
    }
}
METHOD(Devastator, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
    actor.(weaponentity).rl_release = 1;
}
METHOD(Devastator, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    #if 0
    // don't switch while guiding a missile
    if(ATTACK_FINISHED(actor, weaponentity) <= time || PS(actor).m_weapon != WEP_DEVASTATOR)
    {
        ammo_amount = false;
        if(WEP_CVAR(devastator, reload_ammo))
        {
            if(GetResource(actor, thiswep.ammo_type) < WEP_CVAR(devastator, ammo) && actor.(weaponentity).(weapon_load[WEP_DEVASTATOR.m_id]) < WEP_CVAR(devastator, ammo))
                ammo_amount = true;
        }
        else if(GetResource(actor, thiswep.ammo_type) < WEP_CVAR(devastator, ammo))
            ammo_amount = true;
        return !ammo_amount;
    }
    #endif
    #if 0
    if(actor.rl_release == 0)
    {
        LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: TRUE", actor.rl_release, GetResource(actor, thiswep.ammo_type), WEP_CVAR(devastator, ammo));
        return true;
    }
    else
    {
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(devastator, ammo);
        ammo_amount += actor.(weaponentity).(weapon_load[WEP_DEVASTATOR.m_id]) >= WEP_CVAR(devastator, ammo);
        LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: %s", actor.rl_release, GetResource(actor, thiswep.ammo_type), WEP_CVAR(devastator, ammo), (ammo_amount ? "TRUE" : "FALSE"));
        return ammo_amount;
    }
    #else
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(devastator, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(devastator, ammo);
    return ammo_amount;
    #endif
}
METHOD(Devastator, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    return false;
}
METHOD(Devastator, wr_resetplayer, void(entity thiswep, entity actor))
{
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
    	.entity weaponentity = weaponentities[slot];
    	actor.(weaponentity).lastrocket = NULL; // stop rocket guiding, no revenge from the grave!
    	actor.(weaponentity).rl_release = 0;
    }
}
METHOD(Devastator, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, WEP_CVAR(devastator, ammo), SND_RELOAD);
}
METHOD(Devastator, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_DEVASTATOR_SUICIDE;
}
METHOD(Devastator, wr_killmessage, Notification(entity thiswep))
{
    if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
        return WEAPON_DEVASTATOR_MURDER_SPLASH;
    else
        return WEAPON_DEVASTATOR_MURDER_DIRECT;
}

#endif
#ifdef CSQC

METHOD(Devastator, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 12;
    pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif
