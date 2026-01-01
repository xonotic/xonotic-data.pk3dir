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

	vector force_xyzscale = '1 1 1';
	force_xyzscale.x = WEP_CVAR(WEP_DEVASTATOR, force_xyscale);
	force_xyzscale.y = WEP_CVAR(WEP_DEVASTATOR, force_xyscale);

	RadiusDamageForSource(
		this,
		this.origin,
		this.velocity,
		this.realowner,
		WEP_CVAR(WEP_DEVASTATOR, damage),
		WEP_CVAR(WEP_DEVASTATOR, edgedamage),
		WEP_CVAR(WEP_DEVASTATOR, radius),
		NULL,
		NULL,
		false,
		WEP_CVAR(WEP_DEVASTATOR, force),
		force_xyzscale,
		this.projectiledeathtype,
		this.weaponentity_fld,
		directhitentity
	);

	Weapon thiswep = WEP_DEVASTATOR;
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		if(GetResource(this.realowner, thiswep.ammo_type) < WEP_CVAR(WEP_DEVASTATOR, ammo))
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
	bool allow_rocketjump = WEP_CVAR(WEP_DEVASTATOR, remote_jump);
	MUTATOR_CALLHOOK(AllowRocketJumping, allow_rocketjump);
	allow_rocketjump = M_ARGV(0, bool);

	if(allow_rocketjump && WEP_CVAR(WEP_DEVASTATOR, remote_jump_radius))
	{
		head = WarpZone_FindRadius(
			this.origin,
			WEP_CVAR(WEP_DEVASTATOR, remote_jump_radius),
			false
		);

		while(head)
		{
			if(head.takedamage && (head == this.realowner))
			{
				if(vdist(this.origin - head.WarpZone_findradius_nearest, <=, WEP_CVAR(WEP_DEVASTATOR, remote_jump_radius)))
				{
					// we handled this as a rocketjump :)
					handled_as_rocketjump = true;

					// modify velocity
					if(WEP_CVAR(WEP_DEVASTATOR, remote_jump_velocity_z_add))
					{
						head.velocity_x *= 0.9;
						head.velocity_y *= 0.9;
						head.velocity_z = bound(
							WEP_CVAR(WEP_DEVASTATOR, remote_jump_velocity_z_min),
							head.velocity.z + WEP_CVAR(WEP_DEVASTATOR, remote_jump_velocity_z_add),
							WEP_CVAR(WEP_DEVASTATOR, remote_jump_velocity_z_max)
						);
					}

					// now do the damage
					RadiusDamage(
						this,
						head,
						WEP_CVAR(WEP_DEVASTATOR, remote_jump_damage),
						WEP_CVAR(WEP_DEVASTATOR, remote_jump_damage),
						WEP_CVAR(WEP_DEVASTATOR, remote_jump_radius),
						NULL,
						head,
						(WEP_CVAR(WEP_DEVASTATOR, remote_jump_force) ? WEP_CVAR(WEP_DEVASTATOR, remote_jump_force) : 0),
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
		WEP_CVAR(WEP_DEVASTATOR, remote_damage),
		WEP_CVAR(WEP_DEVASTATOR, remote_edgedamage),
		WEP_CVAR(WEP_DEVASTATOR, remote_radius),
		(handled_as_rocketjump ? head : NULL),
		NULL,
		WEP_CVAR(WEP_DEVASTATOR, remote_force),
		this.projectiledeathtype | HITTYPE_BOUNCE,
		this.weaponentity_fld,
		NULL
	);

	Weapon thiswep = WEP_DEVASTATOR;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		if(GetResource(this.realowner, thiswep.ammo_type) < WEP_CVAR(WEP_DEVASTATOR, ammo))
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
			: (vdist(NearestPointOnBox(this.realowner, this.origin) - this.origin, >, WEP_CVAR(WEP_DEVASTATOR, remote_radius))) // safety device
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
	velspeed = WEP_CVAR(WEP_DEVASTATOR, speed) * W_WeaponSpeedFactor(this.realowner) - (this.velocity * v_forward);
	if(velspeed > 0)
		this.velocity = this.velocity + v_forward * min(WEP_CVAR(WEP_DEVASTATOR, speedaccel) * W_WeaponSpeedFactor(this.realowner) * frametime, velspeed);

	// laser guided, or remote detonation
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_DEVASTATOR)
	{
		if(this == this.realowner.(weaponentity).lastrocket)
		if(!this.realowner.(weaponentity).rl_release)
		if(!PHYS_INPUT_BUTTON_ATCK2(this))
		if(WEP_CVAR(WEP_DEVASTATOR, guiderate))
		if(time > this.pushltime)
		if(!IS_DEAD(this.realowner))
		{
			f = WEP_CVAR(WEP_DEVASTATOR, guideratedelay);
			if(f)
				f = bound(0, (time - this.pushltime) / f, 1);
			else
				f = 1;

			vector md = this.realowner.(weaponentity).movedir;
			vector dv = v_right * -md.y + v_up * md.z;

			if(!W_DualWielding(this.realowner))
				dv = '0 0 0'; // don't override!

			velspeed = vlen(this.velocity);

			makevectors(this.realowner.v_angle);
			desireddir = WarpZone_RefSys_TransformVelocity(this.realowner, this, v_forward);
			desiredorigin = WarpZone_RefSys_TransformOrigin(this.realowner, this, this.realowner.origin + this.realowner.view_ofs + dv);
			olddir = normalize(this.velocity);

			// now it gets tricky... we want to move like some curve to approximate the target direction
			// but we are limiting the rate at which we can turn!
			goal = desiredorigin + ((this.origin - desiredorigin) * desireddir + WEP_CVAR(WEP_DEVASTATOR, guidegoal)) * desireddir;
			newdir = W_Devastator_SteerTo(olddir, normalize(goal - this.origin), cos(WEP_CVAR(WEP_DEVASTATOR, guiderate) * f * frametime * DEG2RAD));

			this.velocity = newdir * velspeed;
			this.angles = vectoangles(this.velocity);

			if(!this.count)
			{
				Send_Effect(EFFECT_ROCKET_GUIDE, this.origin, this.velocity, 1);
				// TODO add a better sound here
				sound(this.realowner, CH_WEAPON_B, SND_DEVASTATOR_MODE, VOL_BASE, ATTN_NORM);
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
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_DEVASTATOR, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 5, SND_DEVASTATOR_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_DEVASTATOR, damage), thiswep.m_id);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity missile = WarpZone_RefSys_SpawnSameRefSys(actor);
	missile.weaponentity_fld = weaponentity;
	missile.owner = missile.realowner = actor;
	actor.(weaponentity).lastrocket = missile;
	if(WEP_CVAR(WEP_DEVASTATOR, detonatedelay) >= 0)
		missile.spawnshieldtime = time + WEP_CVAR(WEP_DEVASTATOR, detonatedelay);
	else
		missile.spawnshieldtime = -1; // NOTE: proximity based when rocket jumping
	missile.pushltime = time + WEP_CVAR(WEP_DEVASTATOR, guidedelay);
	missile.classname = "rocket";
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(WEP_DEVASTATOR, damage) * 2; // * 2 because it can be detonated inflight which makes it even more dangerous

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = WEP_CVAR(WEP_DEVASTATOR, damageforcescale);
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR(WEP_DEVASTATOR, health));
	missile.event_damage = W_Devastator_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);

	set_movetype(missile, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = thiswep.m_id;
	setsize(missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin(missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(missile, WEP_CVAR(WEP_DEVASTATOR, speedstart), 0);
	missile.angles = vectoangles(missile.velocity);

	settouch(missile, W_Devastator_Touch);
	setthink(missile, W_Devastator_Think);
	missile.nextthink = time;
	missile.cnt = time + WEP_CVAR(WEP_DEVASTATOR, lifetime);
	missile.rl_detonate_later = (fire & 2); // allow instant detonation
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, WEP_CVAR(WEP_DEVASTATOR, guiderate) == 0 && WEP_CVAR(WEP_DEVASTATOR, speedaccel) == 0, PROJECTILE_ROCKET, false); // because of fly sound

	// common properties
	MUTATOR_CALLHOOK(EditProjectile, actor, missile);

	if (time >= missile.nextthink)
	{
		getthink(missile)(missile);
	}
}

METHOD(Devastator, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if (!WEP_CVAR(WEP_DEVASTATOR, guidestop) && !actor.(weaponentity).rl_release)
	{
		int fired_rockets = 0;
		IL_EACH(g_projectiles, it.realowner == actor && it.classname == "rocket",
		{
			fired_rockets++;
		});
		// release PHYS_INPUT_BUTTON_ATCK after all fired rocket exploded otherwise bot can't fire again
		if (!fired_rockets)
			return;
	}

	// aim and decide to fire if appropriate
	float spd = WEP_CVAR(WEP_DEVASTATOR, speed);
	// simulate rocket guide by calculating rocket trajectory with higher speed
	// 20 times faster at 90 degrees guide rate
	if (WEP_CVAR(WEP_DEVASTATOR, guiderate) > 0)
		spd *= sqrt(WEP_CVAR(WEP_DEVASTATOR, guiderate)) * (20 / 9.489); // 9.489 ~= sqrt(90)
	// no need to fire with high accuracy on large distances if rockets can be guided
	bool shot_accurate = (WEP_CVAR(WEP_DEVASTATOR, guiderate) < 50);
	PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, spd, 0, WEP_CVAR(WEP_DEVASTATOR, lifetime), false, shot_accurate);
	float pred_time = bound(0.02, 0.02 + (8 - skill) * 0.01, 0.1);
	if(skill >= 2) // skill 0 and 1 bots won't detonate rockets!
	{
		// decide whether to detonate rockets
		float selfdamage = 0, teamdamage = 0, enemydamage = 0;
		float pred_selfdamage = 0, pred_teamdamage = 0, pred_enemydamage = 0;
		float edgedamage = WEP_CVAR(WEP_DEVASTATOR, edgedamage);
		float coredamage = WEP_CVAR(WEP_DEVASTATOR, damage);
		float edgeradius = WEP_CVAR(WEP_DEVASTATOR, radius);
		IL_EACH(g_projectiles, it.realowner == actor && it.classname == "rocket",
		{
			entity rocket = it;
			IL_EACH(g_bot_targets, it.bot_attack,
			{
				// code to calculate damage is similar to the one used in RadiusDamageForSource with some simplifications
				vector target_pos = it.origin + (it.maxs - it.mins) * 0.5;

				float dist = vlen(target_pos - rocket.origin);
				float dmg = 0;
				if (dist <= edgeradius)
				{
					float f = (edgeradius > 0) ? max(0, 1 - (dist / edgeradius)) : 1;
					dmg = coredamage * f + edgedamage * (1 - f);
				}

				float pred_dist = vlen(target_pos + it.velocity * pred_time - (rocket.origin + rocket.velocity * pred_time));
				float pred_dmg = 0;
				if (pred_dist <= edgeradius)
				{
					float f = (edgeradius > 0) ? max(0, 1 - (pred_dist / edgeradius)) : 1;
					pred_dmg = coredamage * f + edgedamage * (1 - f);
				}

				// count potential damage according to type of target
				if(it == actor)
				{
					if(StatusEffects_active(STATUSEFFECT_Strength, it))
						dmg *= autocvar_g_balance_powerup_strength_damage;
					if(StatusEffects_active(STATUSEFFECT_Shield, it))
						dmg *= autocvar_g_balance_powerup_invincible_takedamage;
					// self damage reduction factor will be applied later to the total damage
					selfdamage += dmg;
					pred_selfdamage += pred_dmg;
				}
				else if(SAME_TEAM(it, actor))
				{
					if(StatusEffects_active(STATUSEFFECT_Shield, it))
						dmg *= autocvar_g_balance_powerup_invincible_takedamage;
					// bot strength factor will be applied later to the total damage
					teamdamage += dmg;
					pred_teamdamage += pred_dmg;
				}
				else if(bot_shouldattack(actor, it))
				{
					if(StatusEffects_active(STATUSEFFECT_Shield, it))
						dmg *= autocvar_g_balance_powerup_invincible_takedamage;
					// bot strength factor will be applied later to the total damage
					enemydamage += dmg;
					pred_enemydamage += pred_dmg;
				}
			});
		});

		selfdamage *= autocvar_g_balance_selfdamagepercent;
		pred_selfdamage *= autocvar_g_balance_selfdamagepercent;
		if(StatusEffects_active(STATUSEFFECT_Strength, actor))
		{
			// FIXME bots don't know whether team damage is enabled or not
			teamdamage *= autocvar_g_balance_powerup_strength_damage;
			pred_teamdamage *= autocvar_g_balance_powerup_strength_damage;
			enemydamage *= autocvar_g_balance_powerup_strength_damage;
			pred_enemydamage *= autocvar_g_balance_powerup_strength_damage;
		}

		float good_damage = enemydamage;
		float pred_good_damage = pred_enemydamage;
		float bad_damage = selfdamage + teamdamage;
		float pred_bad_damage = pred_selfdamage + pred_teamdamage;

		// detonate if predicted good damage is lower (current good damage is maximum)
		// or if predicted bad damage is too much
		if(good_damage > coredamage * 0.1 && good_damage > bad_damage * 1.5
			&& (pred_good_damage < good_damage + 2 || pred_good_damage < pred_bad_damage * 1.5))
		{
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
		}
		if(skill >= 7 && selfdamage > GetResource(actor, RES_HEALTH))
			PHYS_INPUT_BUTTON_ATCK2(actor) = false;

		// don't fire a new shot at the same time!
		if(PHYS_INPUT_BUTTON_ATCK2(actor)) PHYS_INPUT_BUTTON_ATCK(actor) = false;
	}
}

METHOD(Devastator, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(WEP_CVAR(WEP_DEVASTATOR, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR(WEP_DEVASTATOR, ammo)) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else {
		if(fire & 1)
		{
			if(actor.(weaponentity).rl_release || WEP_CVAR(WEP_DEVASTATOR, guidestop))
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_DEVASTATOR, refire)))
			{
				W_Devastator_Attack(thiswep, actor, weaponentity, fire);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_DEVASTATOR, animtime), w_ready);
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
				sound(actor, CH_WEAPON_B, SND_DEVASTATOR_DET, VOL_BASE, ATTN_NORM);
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
		if(WEP_CVAR(WEP_DEVASTATOR, reload_ammo))
		{
			if(GetResource(actor, thiswep.ammo_type) < WEP_CVAR(WEP_DEVASTATOR, ammo) && actor.(weaponentity).(weapon_load[WEP_DEVASTATOR.m_id]) < WEP_CVAR(WEP_DEVASTATOR, ammo))
				ammo_amount = true;
		}
		else if(GetResource(actor, thiswep.ammo_type) < WEP_CVAR(WEP_DEVASTATOR, ammo))
			ammo_amount = true;
		return !ammo_amount;
	}
	#endif
	#if 0
	if(actor.rl_release == 0)
	{
		LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: TRUE", actor.rl_release, GetResource(actor, thiswep.ammo_type), WEP_CVAR(WEP_DEVASTATOR, ammo));
		return true;
	}
	else
	{
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_DEVASTATOR, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_DEVASTATOR.m_id]) >= WEP_CVAR(WEP_DEVASTATOR, ammo);
		LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: %s", actor.rl_release, GetResource(actor, thiswep.ammo_type), WEP_CVAR(WEP_DEVASTATOR, ammo), (ammo_amount ? "TRUE" : "FALSE"));
		return ammo_amount;
	}
	#else
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_DEVASTATOR, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_DEVASTATOR, ammo);
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
	W_Reload(actor, weaponentity, WEP_CVAR(WEP_DEVASTATOR, ammo), SND_RELOAD);
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
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include <common/mutators/mutator/rocketflying/rocketflying.qh>
#include "vortex.qh"

METHOD(Devastator, describe, string(Devastator this))
{
	TC(Devastator, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s launches a remote controlled rocket, dealing significant damage when it explodes on impact. "
	      "If the primary fire is held, the rocket can be guided by the user's aim, allowing steering it towards enemies."), COLORED_NAME(this));
	PAR(_("The secondary fire can be used to immediately detonate rockets, allowing dealing damage to enemies even if the rocket barely missed colliding with them."));
	PAR(_("It consumes a bunch of %s ammo for each rocket, which can end up being depleted quickly, so often players alternate with another weapon like %s."), COLORED_NAME(ITEM_Rockets), COLORED_NAME(WEP_VORTEX));
	PAR(_("Due to its high damage output, the %s is one of the most commonly used weapons. "
	      "It can be used in almost any scenario, working best in medium range combat. "
	      "In close range combat, the large splash radius often results in rockets damaging both you and your enemy."), COLORED_NAME(this));
	PAR(_("Due to the ability to remotely detonate rockets, a common usage is \"rocket flying,\" where you fire a rocket and immediately detonate it to boost yourself while mid-air, "
	      "much more effective with the %s mutator enabled."), COLORED_NAME(MUTATOR_rocketflying));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne_unnamed(this.netname));
	return PAGE_TEXT;
}

#endif
