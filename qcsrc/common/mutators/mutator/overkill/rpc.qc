#include "rpc.qh"

#ifdef SVQC
spawnfunc(weapon_rpc) { weapon_defaultspawnfunc(this, WEP_RPC); }

void W_RocketPropelledChainsaw_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	RadiusDamage (this, this.realowner, WEP_CVAR_PRI(rpc, damage), WEP_CVAR_PRI(rpc, edgedamage), WEP_CVAR_PRI(rpc, radius), NULL, NULL, WEP_CVAR_PRI(rpc, force), this.projectiledeathtype, directhitentity);

	delete(this);
}

void W_RocketPropelledChainsaw_Explode_think(entity this)
{
	W_RocketPropelledChainsaw_Explode(this, NULL);
}

void W_RocketPropelledChainsaw_Touch (entity this, entity toucher)
{
	if(WarpZone_Projectile_Touch(this, toucher))
		if(wasfreed(this))
			return;

	W_RocketPropelledChainsaw_Explode(this, toucher);
}

void W_RocketPropelledChainsaw_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if (this.health <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	this.health = this.health - damage;

	if (this.health <= 0)
		W_PrepareExplosionByDamage(this, attacker, W_RocketPropelledChainsaw_Explode_think);
}

void W_RocketPropelledChainsaw_Think(entity this)
{
	if(this.cnt <= time)
	{
		delete(this);
		return;
	}

	this.cnt = vlen(this.velocity);
	this.wait = this.cnt * sys_frametime;
	this.pos1 = normalize(this.velocity);

	tracebox(this.origin, this.mins, this.maxs, this.origin + this.pos1 * (2 * this.wait), MOVE_NORMAL, this);
	if(IS_PLAYER(trace_ent))
		Damage (trace_ent, this, this.realowner, WEP_CVAR_PRI(rpc, damage2), this.projectiledeathtype, this.origin, normalize(this.origin - other.origin) * WEP_CVAR_PRI(rpc, force));

	this.velocity = this.pos1 * (this.cnt + (WEP_CVAR_PRI(rpc, speedaccel) * sys_frametime));

	UpdateCSQCProjectile(this);
	this.nextthink = time;
}

void W_RocketPropelledChainsaw_Attack (Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile = spawn(); //WarpZone_RefSys_SpawnSameRefSys(actor);
	entity flash = spawn ();

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(rpc, ammo), weaponentity);
	W_SetupShot_ProjectileSize (actor, weaponentity, '-3 -3 -3', '3 3 3', false, 5, SND_ROCKET_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(rpc, damage));
	Send_Effect(EFFECT_ROCKET_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
	PROJECTILE_MAKETRIGGER(missile);

	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR_PRI(rpc, damage) * 2;

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = WEP_CVAR_PRI(rpc, damageforcescale);
	missile.health = WEP_CVAR_PRI(rpc, health);
	missile.event_damage = W_RocketPropelledChainsaw_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);
	set_movetype(missile, MOVETYPE_FLY);

	missile.projectiledeathtype = WEP_RPC.m_id;
	setsize (missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin(missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(rpc, speed), 0);

	settouch(missile, W_RocketPropelledChainsaw_Touch);

	setthink(missile, W_RocketPropelledChainsaw_Think);
	missile.cnt = time + WEP_CVAR_PRI(rpc, lifetime);
	missile.nextthink = time;
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);

	CSQCProjectile(missile, true, PROJECTILE_RPC, false);

	setmodel(flash, MDL_RPC_MUZZLEFLASH); // precision set below
	SUB_SetFade (flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(actor, weaponentity, flash, '5 0 0');
	missile.pos1 = missile.velocity;

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

METHOD(RocketPropelledChainsaw, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(rpc, speed), 0, WEP_CVAR_PRI(rpc, lifetime), false);
}

METHOD(RocketPropelledChainsaw, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(rpc, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_SEC(rpc, refire) * W_WeaponRateFactor(actor);
		// Ugly hack to reuse the fire mode of the blaster.
		makevectors(actor.v_angle);
		Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
		actor.(weaponentity).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			actor,
			weaponentity,
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(rpc, shotangle),
			WEP_CVAR_SEC(rpc, damage),
			WEP_CVAR_SEC(rpc, edgedamage),
			WEP_CVAR_SEC(rpc, radius),
			WEP_CVAR_SEC(rpc, force),
			WEP_CVAR_SEC(rpc, speed),
			WEP_CVAR_SEC(rpc, spread),
			WEP_CVAR_SEC(rpc, delay),
			WEP_CVAR_SEC(rpc, lifetime)
		);
		actor.(weaponentity).m_weapon = oldwep;
		if ((actor.(weaponentity).wframe == WFRAME_IDLE) ||
			(actor.(weaponentity).wframe == WFRAME_FIRE2))
		{
			// Set secondary fire animation.
			vector a = '0 0 0';
			actor.(weaponentity).wframe = WFRAME_FIRE2;
			a = actor.(weaponentity).anim_fire2;
			a.z *= g_weaponratefactor;
			FOREACH_CLIENT(true, LAMBDA(
				if (it == actor || (IS_SPEC(it) && it.enemy == actor))
				{
					wframe_send(it, actor.(weaponentity), a, true);
				}
			));
			animdecide_setaction(actor, ANIMACTION_SHOOT, true);
		}
	}
	if (WEP_CVAR(rpc, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(rpc, ammo))
	{
		// Forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(rpc, refire)))
		{
			return;
		}
		W_RocketPropelledChainsaw_Attack(thiswep, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(rpc, animtime), w_ready);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(rpc, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(rpc, refire)))
		{
			return;
		}
		// ugly instagib hack to reuse the fire mode of the laser
		makevectors(actor.v_angle);
		Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
		actor.(weaponentity).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			actor,
			weaponentity,
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(rpc, shotangle),
			WEP_CVAR_SEC(rpc, damage),
			WEP_CVAR_SEC(rpc, edgedamage),
			WEP_CVAR_SEC(rpc, radius),
			WEP_CVAR_SEC(rpc, force),
			WEP_CVAR_SEC(rpc, speed),
			WEP_CVAR_SEC(rpc, spread),
			WEP_CVAR_SEC(rpc, delay),
			WEP_CVAR_SEC(rpc, lifetime)
		);
		actor.(weaponentity).m_weapon = oldwep;
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(rpc, animtime), w_ready);
	}
}

METHOD(RocketPropelledChainsaw, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(rpc, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_RPC.m_id]) >= WEP_CVAR_PRI(rpc, ammo);
	return ammo_amount;
}

METHOD(RocketPropelledChainsaw, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(rpc, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_RPC.m_id]) >= WEP_CVAR_SEC(rpc, ammo);
	return ammo_amount;
}

METHOD(RocketPropelledChainsaw, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, WEP_CVAR_PRI(rpc, ammo), SND_RELOAD);
}

METHOD(RocketPropelledChainsaw, wr_suicidemessage, Notification(entity thiswep))
{
    if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
        return WEAPON_RPC_SUICIDE_SPLASH;
    else
        return WEAPON_RPC_SUICIDE_DIRECT;
}

METHOD(RocketPropelledChainsaw, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_BLASTER_MURDER;
    else if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
        return WEAPON_RPC_MURDER_SPLASH;
    else
        return WEAPON_RPC_MURDER_DIRECT;
}

#endif

#ifdef CSQC

METHOD(RocketPropelledChainsaw, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 12;
    pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
}

#endif
