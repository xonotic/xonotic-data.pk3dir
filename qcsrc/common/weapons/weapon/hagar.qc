#include "hagar.qh"

#ifdef SVQC

// NO bounce protection, as bounces are limited!

void W_Hagar_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;
	RadiusDamage(this, this.realowner, WEP_CVAR_PRI(hagar, damage), WEP_CVAR_PRI(hagar, edgedamage), WEP_CVAR_PRI(hagar, radius), NULL, NULL, WEP_CVAR_PRI(hagar, force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Hagar_Explode_use(entity this, entity actor, entity trigger)
{
	W_Hagar_Explode(this, trigger);
}

void W_Hagar_Explode2(entity this, entity directhitentity)
{
	this.event_damage = func_null;
	RadiusDamage(this, this.realowner, WEP_CVAR_SEC(hagar, damage), WEP_CVAR_SEC(hagar, edgedamage), WEP_CVAR_SEC(hagar, radius), NULL, NULL, WEP_CVAR_SEC(hagar, force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Hagar_Explode2_use(entity this, entity actor, entity trigger)
{
	W_Hagar_Explode2(this, trigger);
}

void W_Hagar_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	float is_linkexplode = ( ((inflictor.owner != NULL) ? (inflictor.owner == this.owner) : true)
		&& (inflictor.projectiledeathtype & HITTYPE_SECONDARY)
		&& (this.projectiledeathtype & HITTYPE_SECONDARY));

	if(is_linkexplode)
		is_linkexplode = (is_linkexplode && WEP_CVAR_SEC(hagar, load_linkexplode));
	else
		is_linkexplode = -1; // not secondary load, so continue as normal without exception.

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, is_linkexplode))
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	this.angles = vectoangles(this.velocity);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, getthink(this));
}

void W_Hagar_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	this.use(this, NULL, toucher);
}

void W_Hagar_Touch2(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	if(this.cnt > 0 || toucher.takedamage == DAMAGE_AIM) {
		this.use(this, NULL, toucher);
	} else {
		this.cnt++;
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.angles = vectoangles(this.velocity);
		this.owner = NULL;
		this.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Hagar_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(hagar, ammo), weaponentity);

	W_SetupShot(actor, weaponentity, false, 2, SND_HAGAR_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(hagar, damage), thiswep.m_id);

	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = new(missile);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR_PRI(hagar, damage);

	missile.takedamage = DAMAGE_YES;
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR_PRI(hagar, health));
	missile.damageforcescale = WEP_CVAR_PRI(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);

	settouch(missile, W_Hagar_Touch);
	missile.use = W_Hagar_Explode_use;
	setthink(missile, adaptor_think2use_hittype_splash);
	missile.nextthink = time + WEP_CVAR_PRI(hagar, lifetime);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = thiswep.m_id;
	missile.weaponentity_fld = weaponentity;
	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	set_movetype(missile, MOVETYPE_FLY);
	W_SetupProjVelocity_PRI(missile, hagar);

	missile.angles = vectoangles(missile.velocity);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, true, PROJECTILE_HAGAR, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

void W_Hagar_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(hagar, ammo), weaponentity);

	W_SetupShot(actor, weaponentity, false, 2, SND_HAGAR_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage), thiswep.m_id | HITTYPE_SECONDARY);

	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = new(missile);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);

	missile.takedamage = DAMAGE_YES;
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR_SEC(hagar, health));
	missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);

	settouch(missile, W_Hagar_Touch2);
	missile.cnt = 0;
	missile.use = W_Hagar_Explode2_use;
	setthink(missile, adaptor_think2use_hittype_splash);
	missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	missile.weaponentity_fld = weaponentity;
	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	set_movetype(missile, MOVETYPE_BOUNCEMISSILE);
	W_SetupProjVelocity_SEC(missile, hagar);

	missile.angles = vectoangles(missile.velocity);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, true, PROJECTILE_HAGAR_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

.float hagar_loadstep, hagar_loadblock, hagar_loadbeep, hagar_warning;
void W_Hagar_Attack2_Load_Release(Weapon thiswep, entity actor, .entity weaponentity)
{
	// time to release the rockets we've loaded

	entity missile;
	float counter, shots, spread_pershot;
	vector s;
	vector forward, right, up;

	if(!actor.(weaponentity).hagar_load)
		return;

	weapon_prepareattack_do(actor, weaponentity, true, WEP_CVAR_SEC(hagar, refire));

	shots = actor.(weaponentity).hagar_load;
	W_SetupShot(actor, weaponentity, false, 2, SND_HAGAR_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage) * shots, thiswep.m_id | HITTYPE_SECONDARY);
	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	forward = v_forward;
	right = v_right;
	up = v_up;

	missile = NULL;
	for(counter = 0; counter < shots; ++counter)
	{
		missile = new(missile);
		missile.owner = missile.realowner = actor;
		missile.bot_dodge = true;
		missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);

		missile.takedamage = DAMAGE_YES;
		SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR_SEC(hagar, health));
		missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
		missile.event_damage = W_Hagar_Damage;
		missile.damagedbycontents = true;
		IL_PUSH(g_damagedbycontents, missile);

		settouch(missile, W_Hagar_Touch); // not bouncy
		missile.use = W_Hagar_Explode2_use;
		setthink(missile, adaptor_think2use_hittype_splash);
		missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
		PROJECTILE_MAKETRIGGER(missile);
		missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
		missile.weaponentity_fld = weaponentity;
		setorigin(missile, w_shotorg);
		setsize(missile, '0 0 0', '0 0 0');
		set_movetype(missile, MOVETYPE_FLY);
		missile.missile_flags = MIF_SPLASH;

		// per-shot spread calculation: the more shots there are, the less spread is applied (based on the bias cvar)
		spread_pershot = ((shots - 1) / (WEP_CVAR_SEC(hagar, load_max) - 1));
		spread_pershot = (1 - (spread_pershot * WEP_CVAR_SEC(hagar, load_spread_bias)));
		spread_pershot = (WEP_CVAR_SEC(hagar, spread) * spread_pershot * g_weaponspreadfactor);

		// pattern spread calculation
		s = '0 0 0';
		if(counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s.y = v_forward.x;
			s.z = v_forward.y;
		}
		s = s * WEP_CVAR_SEC(hagar, load_spread) * g_weaponspreadfactor;

		W_SetupProjVelocity_Explicit(missile, w_shotdir + right * s.y + up * s.z, v_up, WEP_CVAR_SEC(hagar, speed), 0, 0, spread_pershot, false);

		missile.angles = vectoangles(missile.velocity);
		missile.flags = FL_PROJECTILE;
		IL_PUSH(g_projectiles, missile);
		IL_PUSH(g_bot_dodge, missile);

		CSQCProjectile(missile, true, PROJECTILE_HAGAR, true);

		MUTATOR_CALLHOOK(EditProjectile, actor, missile);
	}

	weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hagar, load_animtime), w_ready);
	actor.(weaponentity).hagar_loadstep = time + WEP_CVAR_SEC(hagar, refire) * W_WeaponRateFactor(actor);
	actor.(weaponentity).hagar_load = 0;
}

void W_Hagar_Attack2_Load(Weapon thiswep, entity actor, .entity weaponentity)
{
	// loadable hagar secondary attack, must always run each frame
	if(time < game_starttime || time < actor.race_penalty || timeout_status == TIMEOUT_ACTIVE)
		return;
	if (round_handler_IsActive() && !round_handler_IsRoundStarted())
		return;

	bool loaded = actor.(weaponentity).hagar_load >= WEP_CVAR_SEC(hagar, load_max);

	// this is different than WR_CHECKAMMO when it comes to reloading
	bool enough_ammo;
	if(actor.items & IT_UNLIMITED_WEAPON_AMMO)
		enough_ammo = true;
	else if(autocvar_g_balance_hagar_reload_ammo)
		enough_ammo = actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(hagar, ammo);
	else
		enough_ammo = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(hagar, ammo);

	bool stopped = loaded || !enough_ammo;

	if(PHYS_INPUT_BUTTON_ATCK2(actor))
	{
		if(PHYS_INPUT_BUTTON_ATCK(actor) && WEP_CVAR_SEC(hagar, load_abort))
		{
			if(actor.(weaponentity).hagar_load)
			{
				// if we pressed primary fire while loading, unload all rockets and abort
				actor.(weaponentity).state = WS_READY;
				W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(hagar, ammo) * actor.(weaponentity).hagar_load * -1, weaponentity); // give back ammo
				actor.(weaponentity).hagar_load = 0;
				sound(actor, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);

				// pause until we can load rockets again, once we re-press the alt fire button
				actor.(weaponentity).hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor(actor);

				// require letting go of the alt fire button before we can load again
				actor.(weaponentity).hagar_loadblock = true;
			}
		}
		else
		{
			// check if we can attempt to load another rocket
			if(!stopped)
			{
				if(!actor.(weaponentity).hagar_loadblock && actor.(weaponentity).hagar_loadstep < time)
				{
					W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(hagar, ammo), weaponentity);
					actor.(weaponentity).state = WS_INUSE;
					actor.(weaponentity).hagar_load += 1;
					sound(actor, CH_WEAPON_B, SND_HAGAR_LOAD, VOL_BASE * 0.8, ATTN_NORM); // sound is too loud according to most

					if(actor.(weaponentity).hagar_load >= WEP_CVAR_SEC(hagar, load_max))
						stopped = true;
					else
						actor.(weaponentity).hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor(actor);
				}
			}
			if(stopped && !actor.(weaponentity).hagar_loadbeep && actor.(weaponentity).hagar_load) // prevents the beep from playing each frame
			{
				// if this is the last rocket we can load, play a beep sound to notify the player
				sound(actor, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);
				actor.(weaponentity).hagar_loadbeep = true;
				actor.(weaponentity).hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_hold) * W_WeaponRateFactor(actor);
			}
		}
	}
	else if(actor.(weaponentity).hagar_loadblock)
	{
		// the alt fire button has been released, so re-enable loading if blocked
		actor.(weaponentity).hagar_loadblock = false;
	}

	if(actor.(weaponentity).hagar_load)
	{
		// play warning sound if we're about to release
		if(stopped && actor.(weaponentity).hagar_loadstep - 0.5 < time && WEP_CVAR_SEC(hagar, load_hold) >= 0)
		{
			if(!actor.(weaponentity).hagar_warning) // prevents the beep from playing each frame
			{
				// we're about to automatically release after holding time, play a beep sound to notify the player
				sound(actor, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);
				actor.(weaponentity).hagar_warning = true;
			}
		}

		// release if player let go of button or if they've held it in too long
		if(!PHYS_INPUT_BUTTON_ATCK2(actor) || (stopped && actor.(weaponentity).hagar_loadstep < time && WEP_CVAR_SEC(hagar, load_hold) >= 0))
		{
			actor.(weaponentity).state = WS_READY;
			W_Hagar_Attack2_Load_Release(thiswep, actor, weaponentity);
		}
	}
	else
	{
		actor.(weaponentity).hagar_loadbeep = false;
		actor.(weaponentity).hagar_warning = false;

		// we aren't checking ammo during an attack, so we must do it here
		if(!(thiswep.wr_checkammo1(thiswep, actor, weaponentity) + thiswep.wr_checkammo2(thiswep, actor, weaponentity)))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			// note: this doesn't force the switch
			W_SwitchToOtherWeapon(actor, weaponentity);
			return;
		}
	}
}

void W_Hagar_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(!(fire & 1) || actor.(weaponentity).hagar_load || actor.(weaponentity).hagar_loadblock || actor.(weaponentity).m_switchweapon != thiswep || !weapon_prepareattack_check(thiswep, actor, weaponentity, false, -1))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(!thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_Hagar_Attack(thiswep, actor, weaponentity);

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(hagar, refire) * W_WeaponRateFactor(actor);
	actor.(weaponentity).wframe = WFRAME_FIRE1;
	weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, WEP_CVAR_PRI(hagar, refire), W_Hagar_Attack_Auto);
}

METHOD(Hagar, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(random()>0.15)
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), false);
    else // not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
        PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), false);
}
METHOD(Hagar, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    float loadable_secondary;
    loadable_secondary = (WEP_CVAR_SEC(hagar, load) && WEP_CVAR(hagar, secondary));

    if(loadable_secondary)
        W_Hagar_Attack2_Load(thiswep, actor, weaponentity); // must always run each frame
    if(autocvar_g_balance_hagar_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    }
    else if((fire & 1) && !actor.(weaponentity).hagar_load && !actor.(weaponentity).hagar_loadblock) // not while secondary is loaded or awaiting reset
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
			W_Hagar_Attack_Auto(thiswep, actor, weaponentity, fire);
	}
    else if((fire & 2) && !loadable_secondary && WEP_CVAR(hagar, secondary))
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(hagar, refire)))
        {
            W_Hagar_Attack2(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hagar, refire), w_ready);
        }
    }
}
METHOD(Hagar, wr_gonethink, void(entity thiswep, entity actor, .entity weaponentity))
{
    // we lost the weapon and want to prepare switching away
    if(actor.(weaponentity).hagar_load)
    {
    	actor.(weaponentity).state = WS_READY;
    	W_Hagar_Attack2_Load_Release(thiswep, actor, weaponentity);
    }
}
METHOD(Hagar, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
    actor.(weaponentity).hagar_loadblock = false;
    if(actor.(weaponentity).hagar_load)
    {
    	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(hagar, ammo) * actor.(weaponentity).hagar_load * -1, weaponentity); // give back ammo if necessary
    	actor.(weaponentity).hagar_load = 0;
    }
}
METHOD(Hagar, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(hagar, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(hagar, ammo);
    return ammo_amount;
}
METHOD(Hagar, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(hagar, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(hagar, ammo);
    return ammo_amount;
}
METHOD(Hagar, wr_resetplayer, void(entity thiswep, entity actor))
{
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
    	.entity weaponentity = weaponentities[slot];
    	actor.(weaponentity).hagar_load = 0;
    }
}
METHOD(Hagar, wr_playerdeath, void(entity thiswep, entity actor, .entity weaponentity))
{
    // if we have any rockets loaded when we die, release them
    if(actor.(weaponentity).hagar_load && WEP_CVAR_SEC(hagar, load_releasedeath))
    	W_Hagar_Attack2_Load_Release(thiswep, actor, weaponentity);
}
METHOD(Hagar, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(!actor.(weaponentity).hagar_load) // require releasing loaded rockets first
        W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo)), SND_RELOAD);
}
METHOD(Hagar, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_HAGAR_SUICIDE;
}
METHOD(Hagar, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_HAGAR_MURDER_BURST;
    else
        return WEAPON_HAGAR_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(Hagar, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 6;
    pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
    if(!w_issilent)
    {
        if(w_random<0.15)
            sound(actor, CH_SHOTS, SND_HAGEXP1, VOL_BASE, ATTN_NORM);
        else if(w_random<0.7)
            sound(actor, CH_SHOTS, SND_HAGEXP2, VOL_BASE, ATTN_NORM);
        else
            sound(actor, CH_SHOTS, SND_HAGEXP3, VOL_BASE, ATTN_NORM);
    }
}

#endif
