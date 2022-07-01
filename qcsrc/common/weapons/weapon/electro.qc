#include "electro.qh"

#ifdef SVQC
#include <common/effects/qc/_mod.qh>

void W_Electro_TriggerCombo(vector org, float rad, entity own)
{
	entity e = WarpZone_FindRadius(org, rad, !WEP_CVAR(electro, combo_comboradius_thruwall));
	while(e)
	{
		if(e.classname == "electro_orb")
		{
			// check if the ball we are exploding is not owned by an
			// independent player which is not the player who shot the ball
			if(IS_INDEPENDENT_PLAYER(e.realowner) && own != e.realowner)
			{
				e = e.chain;
				continue;
			}
			// do we allow thruwall triggering?
			if(WEP_CVAR(electro, combo_comboradius_thruwall))
			{
				// if distance is greater than thruwall distance, check to make sure it's not through a wall
				if(vdist(e.WarpZone_findradius_dist, >, WEP_CVAR(electro, combo_comboradius_thruwall)))
				{
					WarpZone_TraceLine(org, e.origin, MOVE_NOMONSTERS, e);
					if(trace_fraction != 1)
					{
						// trigger is through a wall and outside of thruwall range, abort
						e = e.chain;
						continue;
					}
				}
			}

			// change owner to whoever caused the combo explosion
			e.realowner = own;
			e.takedamage = DAMAGE_NO;
			e.classname = "electro_orb_chain";

			// now set the next one to trigger as well
			setthink(e, W_Electro_ExplodeCombo);

			// delay combo chains, looks cooler
			float delay = 0;
			if (WEP_CVAR(electro, combo_speed))
				delay = vlen(e.WarpZone_findradius_dist) / WEP_CVAR(electro, combo_speed);
			e.nextthink = time + delay;
		}
		e = e.chain;
	}
}

void W_Electro_ExplodeCombo(entity this)
{
	W_Electro_TriggerCombo(this.origin, WEP_CVAR(electro, combo_comboradius), this.realowner);

	this.event_damage = func_null;
	this.velocity = this.movedir; // particle fx and decals need .velocity

	RadiusDamage(
		this,
		this.realowner,
		WEP_CVAR(electro, combo_damage),
		WEP_CVAR(electro, combo_edgedamage),
		WEP_CVAR(electro, combo_radius),
		NULL,
		NULL,
		WEP_CVAR(electro, combo_force),
		WEP_ELECTRO.m_id | HITTYPE_BOUNCE, // use THIS type for a combo because primary can't bounce
		this.weaponentity_fld,
		NULL
	);

	delete(this);
}

void W_Electro_Explode(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_ELECTROBITCH);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;
	this.velocity = this.movedir; // particle fx and decals need .velocity

	if(this.move_movetype == MOVETYPE_BOUNCE || this.classname == "electro_orb") // TODO: classname is more reliable anyway?
	{
		RadiusDamage(
			this,
			this.realowner,
			WEP_CVAR_SEC(electro, damage),
			WEP_CVAR_SEC(electro, edgedamage),
			WEP_CVAR_SEC(electro, radius),
			NULL,
			NULL,
			WEP_CVAR_SEC(electro, force),
			this.projectiledeathtype,
			this.weaponentity_fld,
			directhitentity
		);
	}
	else
	{
		W_Electro_TriggerCombo(this.origin, WEP_CVAR_PRI(electro, comboradius), this.realowner);
		RadiusDamage(
			this,
			this.realowner,
			WEP_CVAR_PRI(electro, damage),
			WEP_CVAR_PRI(electro, edgedamage),
			WEP_CVAR_PRI(electro, radius),
			NULL,
			NULL,
			WEP_CVAR_PRI(electro, force),
			this.projectiledeathtype,
			this.weaponentity_fld,
			directhitentity
		);
	}

	delete(this);
}

void W_Electro_Explode_use(entity this, entity actor, entity trigger)
{
	W_Electro_Explode(this, trigger);
}

void W_Electro_TouchExplode(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	W_Electro_Explode(this, toucher);
}


//void sys_phys_update_single(entity this);

void W_Electro_Bolt_Think(entity this)
{
	// sys_phys_update_single(this);
	if(time >= this.ltime)
	{
		this.use(this, NULL, NULL);
		return;
	}

	if(WEP_CVAR_PRI(electro, midaircombo_radius))
	{
		float found = 0;
		entity e = WarpZone_FindRadius(this.origin, WEP_CVAR_PRI(electro, midaircombo_radius), true);

		// loop through nearby orbs and trigger them
		while(e)
		{
			if(e.classname == "electro_orb")
			{
				// check if the ball we are exploding is not owned by an
				// independent player which is not the player who shot the ball
				if(IS_INDEPENDENT_PLAYER(e.realowner) && this.realowner != e.realowner)
				{
					e = e.chain;
					continue;
				}
				bool explode;
				if (this.owner == e.owner)
				{
					explode = WEP_CVAR_PRI(electro, midaircombo_own);
				}
				else if (SAME_TEAM(this.owner, e.owner))
				{
					explode = WEP_CVAR_PRI(electro, midaircombo_teammate);
				}
				else
				{
					explode = WEP_CVAR_PRI(electro, midaircombo_enemy);
				}

				if (explode)
				{
					// change owner to whoever caused the combo explosion
					e.realowner = this.realowner;
					e.takedamage = DAMAGE_NO;
					e.classname = "electro_orb_chain";

					// Only first orb explosion uses midaircombo_speed, others use the normal combo_speed.
					// This allows to avoid the delay on the first explosion which looks better
					// (the bolt and orb should explode together because they interacted together)
					// while keeping the chaining delay.
					setthink(e, W_Electro_ExplodeCombo);
					float delay = 0;
					if (WEP_CVAR_PRI(electro, midaircombo_speed))
						delay = vlen(e.WarpZone_findradius_dist) / WEP_CVAR_PRI(electro, midaircombo_speed);
					e.nextthink = time + delay;

					++found;
				}
			}
			e = e.chain;
		}

		// if we triggered an orb, should we explode? if not, lets try again next time
		if(found && WEP_CVAR_PRI(electro, midaircombo_explode))
			{ this.use(this, NULL, NULL); }
		else
			{ this.nextthink = min(time + WEP_CVAR_PRI(electro, midaircombo_interval), this.ltime); }
	}
	else { this.nextthink = this.ltime; }
	// this.nextthink = time;
}

void W_Electro_Attack_Bolt(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity proj;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(electro, ammo), weaponentity);

	W_SetupShot_ProjectileSize(
		actor,
		weaponentity,
		'0 0 -3',
		'0 0 -3',
		false,
		2,
		SND_ELECTRO_FIRE,
		CH_WEAPON_A,
		WEP_CVAR_PRI(electro, damage),
		thiswep.m_id
	);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	proj = new(electro_bolt);
	proj.owner = proj.realowner = actor;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_PRI(electro, damage);
	proj.use = W_Electro_Explode_use;
	setthink(proj, W_Electro_Bolt_Think);
	proj.nextthink = time;
	proj.ltime = time + WEP_CVAR_PRI(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = thiswep.m_id;
	proj.weaponentity_fld = weaponentity;
	setorigin(proj, w_shotorg);

	// if (IS_CSQC)
	set_movetype(proj, MOVETYPE_FLY);
	W_SetupProjVelocity_PRI(proj, electro);
	proj.angles = vectoangles(proj.velocity);
	settouch(proj, W_Electro_TouchExplode);
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.missile_flags = MIF_SPLASH;

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO_BEAM, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, proj);
	// proj.com_phys_pos = proj.origin;
	// proj.com_phys_vel = proj.velocity;
}

void W_Electro_Orb_Follow_Think(entity this)
{
	if (time > this.death_time)
	{
		adaptor_think2use_hittype_splash(this);
		return;
	}
	if (this.move_movetype == MOVETYPE_FOLLOW)
	{
		int lost = LostMovetypeFollow(this);
		if (lost == 2)
		{
			// FIXME if player disconnected, it isn't possible to drop the orb at player's origin
			// see comment in LostMovetypeFollow implementation
			delete(this);
			return;
		}
		if (lost)
		{
			// drop the orb at the corpse's location
			PROJECTILE_MAKETRIGGER(this);
			set_movetype(this, MOVETYPE_TOSS);

			setthink(this, adaptor_think2use_hittype_splash);
			this.nextthink = this.death_time;
			return;
		}
	}
	this.nextthink = time;
}

void W_Electro_Orb_Stick(entity this, entity to)
{
	entity newproj = spawn();
	newproj.classname = this.classname;

	newproj.bot_dodge = this.bot_dodge;
	newproj.bot_dodgerating = this.bot_dodgerating;

	newproj.owner = this.owner;
	newproj.realowner = this.realowner;
	setorigin(newproj, this.origin);
	setmodel(newproj, MDL_PROJECTILE_ELECTRO);
	setsize(newproj, this.mins, this.maxs);
	newproj.angles = vectoangles(-trace_plane_normal); // face against the surface
	newproj.traileffectnum = _particleeffectnum(EFFECT_TR_NEXUIZPLASMA.eent_eff_name);

	newproj.movedir = -trace_plane_normal;

	newproj.takedamage = this.takedamage;
	newproj.damageforcescale = this.damageforcescale;
	SetResourceExplicit(newproj, RES_HEALTH, GetResource(this, RES_HEALTH));
	newproj.event_damage = this.event_damage;
	newproj.spawnshieldtime = this.spawnshieldtime;
	newproj.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, newproj);

	set_movetype(newproj, MOVETYPE_NONE); // lock the orb in place
	newproj.projectiledeathtype = this.projectiledeathtype;
	newproj.weaponentity_fld = this.weaponentity_fld;

	settouch(newproj, func_null);
	if(WEP_CVAR_SEC(electro, stick_lifetime) > 0){
		newproj.death_time = time + WEP_CVAR_SEC(electro, stick_lifetime);
	}else{
		newproj.death_time = this.death_time;
	}
	newproj.use = this.use;
	newproj.flags = this.flags;
	IL_PUSH(g_projectiles, newproj);
	IL_PUSH(g_bot_dodge, newproj);

	// check if limits are enabled (we can tell by checking if the original orb is listed) and push it to the list if so
	if(LimitedElectroBallRubbleList && IL_CONTAINS(LimitedElectroBallRubbleList, this))
	{
		ReplaceOldListedChildRubble(LimitedElectroBallRubbleList, newproj, this);
	}

	delete(this);

	if(to)
	{
		SetMovetypeFollow(newproj, to);

		setthink(newproj, W_Electro_Orb_Follow_Think);
		newproj.nextthink = time;
	}
	else
	{
		setthink(newproj, adaptor_think2use_hittype_splash);
		newproj.nextthink = newproj.death_time;
	}
}

void W_Electro_Orb_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM && WEP_CVAR_SEC(electro, touchexplode))
		{ W_Electro_Explode(this, toucher); }
	else if(toucher.owner != this.owner && toucher.classname != this.classname) // don't stick to player's other projectiles!
	{
		//UpdateCSQCProjectile(this);
		spamsound(this, CH_SHOTS, SND_ELECTRO_BOUNCE, VOL_BASE, ATTEN_NORM);
		this.projectiledeathtype |= HITTYPE_BOUNCE;

		if(WEP_CVAR_SEC(electro, stick)){
			if(WEP_CVAR_SEC(electro, stick_lifetime) == 0){
				W_Electro_Explode(this, toucher);
			} else {
				W_Electro_Orb_Stick(this, toucher);
			}
		}
	}
}

void W_Electro_Orb_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	// note: combos are usually triggered by W_Electro_TriggerCombo, not damage
	float is_combo = (inflictor.classname == "electro_orb_chain" || inflictor.classname == "electro_bolt");

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, (is_combo ? 1 : -1)))
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	if(GetResource(this, RES_HEALTH) <= 0)
	{
		this.takedamage = DAMAGE_NO;
		this.nextthink = time;
		if(is_combo)
		{
			// change owner to whoever caused the combo explosion
			this.realowner = inflictor.realowner;
			this.classname = "electro_orb_chain";
			setthink(this, W_Electro_ExplodeCombo);
			// delay combo chains, looks cooler
			// bound the length, inflictor may be in a galaxy far far away (warpzones)
			float len = min(WEP_CVAR(electro, combo_radius), vlen(this.origin - inflictor.origin));
			float delay = len / WEP_CVAR(electro, combo_speed);
			this.nextthink = time + delay;
		}
		else
		{
			this.use = W_Electro_Explode_use;
			setthink(this, adaptor_think2use); // not _hittype_splash, as this runs "immediately"
		}
	}
}

void W_Electro_Attack_Orb(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(electro, ammo), weaponentity);

	W_SetupShot_ProjectileSize(
		actor,
		weaponentity,
		'-4 -4 -4',
		'4 4 4',
		false,
		2,
		SND_ELECTRO_FIRE2,
		CH_WEAPON_A,
		WEP_CVAR_SEC(electro, damage),
		thiswep.m_id | HITTYPE_SECONDARY
	);

	w_shotdir = v_forward; // no TrueAim for grenades please

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity proj = new(electro_orb);
	proj.owner = proj.realowner = actor;
	proj.use = W_Electro_Explode_use;
	setthink(proj, adaptor_think2use_hittype_splash);
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_SEC(electro, damage);
	proj.nextthink = time + WEP_CVAR_SEC(electro, lifetime);
	proj.death_time = time + WEP_CVAR_SEC(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	proj.weaponentity_fld = weaponentity;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	set_movetype(proj, MOVETYPE_BOUNCE);
	W_SetupProjVelocity_UP_SEC(proj, electro);
	settouch(proj, W_Electro_Orb_Touch);
	setsize(proj, '-4 -4 -4', '4 4 4');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_SEC(electro, damageforcescale);
	SetResourceExplicit(proj, RES_HEALTH, WEP_CVAR_SEC(electro, health));
	proj.event_damage = W_Electro_Orb_Damage;
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.damagedbycontents = (WEP_CVAR_SEC(electro, damagedbycontents));
	if(proj.damagedbycontents)
		IL_PUSH(g_damagedbycontents, proj);

	proj.bouncefactor = WEP_CVAR_SEC(electro, bouncefactor);
	proj.bouncestop = WEP_CVAR_SEC(electro, bouncestop);
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	if(WEP_CVAR_SEC(electro, limit) > 0)
	{
		if (!LimitedElectroBallRubbleList)
			LimitedElectroBallRubbleList = IL_NEW();
		ListNewChildRubble(LimitedElectroBallRubbleList, proj);
		LimitedChildrenRubble(LimitedElectroBallRubbleList, "electro_orb", WEP_CVAR_SEC(electro, limit), adaptor_think2use_hittype_splash, actor);
	}

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO, false); // no culling, it has sound

	MUTATOR_CALLHOOK(EditProjectile, actor, proj);
}

void W_Electro_CheckAttack(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(actor.(weaponentity).electro_count > 1)
	if(PHYS_INPUT_BUTTON_ATCK2(actor))
	if(weapon_prepareattack(thiswep, actor, weaponentity, true, -1))
	{
		W_Electro_Attack_Orb(thiswep, actor, weaponentity);
		actor.(weaponentity).electro_count -= 1;
		actor.(weaponentity).electro_secondarytime = time;
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
		return;
	}
	w_ready(thiswep, actor, weaponentity, fire);
}

.float bot_secondary_electromooth;

METHOD(Electro, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    PHYS_INPUT_BUTTON_ATCK(actor) = PHYS_INPUT_BUTTON_ATCK2(actor) = false;
    if(vdist(actor.origin - actor.enemy.origin, >, 1000)) { actor.bot_secondary_electromooth = 0; }
    if(actor.bot_secondary_electromooth == 0)
    {
        float shoot;

        if(WEP_CVAR_PRI(electro, speed))
            shoot = bot_aim(actor, weaponentity, WEP_CVAR_PRI(electro, speed), 0, WEP_CVAR_PRI(electro, lifetime), false);
        else
            shoot = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);

        if(shoot)
        {
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
            if(random() < 0.01) actor.bot_secondary_electromooth = 1;
        }
    }
    else
    {
        if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(electro, speed), WEP_CVAR_SEC(electro, speed_up), WEP_CVAR_SEC(electro, lifetime), true))
        {
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
            if(random() < 0.03) actor.bot_secondary_electromooth = 0;
        }
    }
}
METHOD(Electro, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(autocvar_g_balance_electro_reload_ammo) // forced reload // WEAPONTODO
    {
        float ammo_amount = 0;
        if(actor.(weaponentity).clip_load >= WEP_CVAR_PRI(electro, ammo))
            ammo_amount = 1;
        if(actor.(weaponentity).clip_load >= WEP_CVAR_SEC(electro, ammo))
            ammo_amount += 1;

        if(!ammo_amount)
        {
            thiswep.wr_reload(thiswep, actor, weaponentity);
            return;
        }
    }

    if(fire & 1)
    {
        if(time >= actor.(weaponentity).electro_secondarytime + WEP_CVAR_SEC(electro, refire2) * W_WeaponRateFactor(actor))
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire)))
        {
            W_Electro_Attack_Bolt(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
    }
    else if(fire & 2)
    {
        if(time >= actor.(weaponentity).electro_secondarytime + WEP_CVAR_SEC(electro, refire) * W_WeaponRateFactor(actor))
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, -1))
        {
            W_Electro_Attack_Orb(thiswep, actor, weaponentity);
            actor.(weaponentity).electro_count = WEP_CVAR_SEC(electro, count);
            actor.(weaponentity).electro_secondarytime = time;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
        }
    }
}
METHOD(Electro, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(electro, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(electro, ammo);
    return ammo_amount;
}
METHOD(Electro, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount;
    if(WEP_CVAR(electro, combo_safeammocheck)) // true if you can fire at least one secondary blob AND one primary shot after it, otherwise false.
    {
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
        ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
    }
    else
    {
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(electro, ammo);
        ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(electro, ammo);
    }
    return ammo_amount;
}
METHOD(Electro, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(electro, ammo), WEP_CVAR_SEC(electro, ammo)), SND_RELOAD);
}
METHOD(Electro, wr_suicidemessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_ELECTRO_SUICIDE_ORBS;
    else
        return WEAPON_ELECTRO_SUICIDE_BOLT;
}
METHOD(Electro, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        return WEAPON_ELECTRO_MURDER_ORBS;
    }
    else
    {
        if(w_deathtype & HITTYPE_BOUNCE)
            return WEAPON_ELECTRO_MURDER_COMBO;
        else
            return WEAPON_ELECTRO_MURDER_BOLT;
    }
}

#endif
#ifdef CSQC

METHOD(Electro, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 6;
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        pointparticles(EFFECT_ELECTRO_BALLEXPLODE, org2, '0 0 0', 1);
        if(!w_issilent)
            sound(actor, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
    }
    else
    {
        if(w_deathtype & HITTYPE_BOUNCE)
        {
            // this is sent as "primary (w_deathtype & HITTYPE_BOUNCE)" to distinguish it from (w_deathtype & HITTYPE_SECONDARY) bounced balls
            pointparticles(EFFECT_ELECTRO_COMBO, org2, '0 0 0', 1);
            if(!w_issilent)
                sound(actor, CH_SHOTS, SND_ELECTRO_IMPACT_COMBO, VOL_BASE, ATTEN_NORM);
        }
        else
        {
            pointparticles(EFFECT_ELECTRO_IMPACT, org2, '0 0 0', 1);
            if(!w_issilent)
                sound(actor, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
        }
    }
}

#endif
