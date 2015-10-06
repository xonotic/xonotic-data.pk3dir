#ifndef IMPLEMENTATION
CLASS(Electro, Weapon)
/* ammotype  */ ATTRIB(Electro, ammo_field, .int, ammo_cells)
/* impulse   */ ATTRIB(Electro, impulse, int, 5)
/* flags     */ ATTRIB(Electro, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Electro, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(Electro, wpcolor, vector, '0 0.5 1');
/* modelname */ ATTRIB(Electro, mdl, string, "electro");
#ifndef MENUQC
/* model     */ ATTRIB(Electro, m_model, Model, MDL_ELECTRO_ITEM);
#endif
/* crosshair */ ATTRIB(Electro, w_crosshair, string, "gfx/crosshairelectro");
/* crosshair */ ATTRIB(Electro, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(Electro, model2, string, "weaponelectro");
/* refname   */ ATTRIB(Electro, netname, string, "electro");
/* wepname   */ ATTRIB(Electro, message, string, _("Electro"));
ENDCLASS(Electro)
REGISTER_WEAPON(ELECTRO, NEW(Electro));

#define ELECTRO_SETTINGS(w_cvar,w_prop) ELECTRO_SETTINGS_LIST(w_cvar, w_prop, ELECTRO, electro)
#define ELECTRO_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, edgedamage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, radius) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, speed) \
	w_cvar(id, sn, BOTH, spread) \
	w_cvar(id, sn, BOTH, lifetime) \
	w_cvar(id, sn, PRI,  comboradius) \
	w_cvar(id, sn, PRI,  midaircombo_explode) \
	w_cvar(id, sn, PRI,  midaircombo_interval) \
	w_cvar(id, sn, PRI,  midaircombo_radius) \
	w_cvar(id, sn, SEC,  bouncefactor) \
	w_cvar(id, sn, SEC,  bouncestop) \
	w_cvar(id, sn, SEC,  count) \
	w_cvar(id, sn, SEC,  damageforcescale) \
	w_cvar(id, sn, SEC,  damagedbycontents) \
	w_cvar(id, sn, SEC,  health) \
	w_cvar(id, sn, SEC,  refire2) \
	w_cvar(id, sn, SEC,  speed_up) \
	w_cvar(id, sn, SEC,  speed_z) \
	w_cvar(id, sn, SEC,  touchexplode) \
	w_cvar(id, sn, NONE, combo_comboradius) \
	w_cvar(id, sn, NONE, combo_comboradius_thruwall) \
	w_cvar(id, sn, NONE, combo_damage) \
	w_cvar(id, sn, NONE, combo_edgedamage) \
	w_cvar(id, sn, NONE, combo_force) \
	w_cvar(id, sn, NONE, combo_radius) \
	w_cvar(id, sn, NONE, combo_speed) \
	w_cvar(id, sn, NONE, combo_safeammocheck) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
ELECTRO_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float electro_count;
.float electro_secondarytime;
void W_Electro_ExplodeCombo(void);
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_electro) { weapon_defaultspawnfunc(WEP_ELECTRO.m_id); }

void W_Electro_TriggerCombo(vector org, float rad, entity own)
{
	entity e = WarpZone_FindRadius(org, rad, !WEP_CVAR(electro, combo_comboradius_thruwall));
	while(e)
	{
		if(e.classname == "electro_orb")
		{
			// do we allow thruwall triggering?
			if(WEP_CVAR(electro, combo_comboradius_thruwall))
			{
				// if distance is greater than thruwall distance, check to make sure it's not through a wall
				if(vlen(e.WarpZone_findradius_dist) > WEP_CVAR(electro, combo_comboradius_thruwall))
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
			e.think = W_Electro_ExplodeCombo;

			// delay combo chains, looks cooler
			e.nextthink =
				(
					time
					+
					(WEP_CVAR(electro, combo_speed) ?
						(vlen(e.WarpZone_findradius_dist) / WEP_CVAR(electro, combo_speed))
						:
						0
					)
				);
		}
		e = e.chain;
	}
}

void W_Electro_ExplodeCombo(void)
{SELFPARAM();
	W_Electro_TriggerCombo(self.origin, WEP_CVAR(electro, combo_comboradius), self.realowner);

	self.event_damage = func_null;

	RadiusDamage(
		self,
		self.realowner,
		WEP_CVAR(electro, combo_damage),
		WEP_CVAR(electro, combo_edgedamage),
		WEP_CVAR(electro, combo_radius),
		world,
		world,
		WEP_CVAR(electro, combo_force),
		WEP_ELECTRO.m_id | HITTYPE_BOUNCE, // use THIS type for a combo because primary can't bounce
		world
	);

	remove(self);
}

void W_Electro_Explode(void)
{SELFPARAM();
	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_ELECTROBITCH);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_BOUNCE)
	{
		RadiusDamage(
			self,
			self.realowner,
			WEP_CVAR_SEC(electro, damage),
			WEP_CVAR_SEC(electro, edgedamage),
			WEP_CVAR_SEC(electro, radius),
			world,
			world,
			WEP_CVAR_SEC(electro, force),
			self.projectiledeathtype,
			other
		);
	}
	else
	{
		W_Electro_TriggerCombo(self.origin, WEP_CVAR_PRI(electro, comboradius), self.realowner);
		RadiusDamage(
			self,
			self.realowner,
			WEP_CVAR_PRI(electro, damage),
			WEP_CVAR_PRI(electro, edgedamage),
			WEP_CVAR_PRI(electro, radius),
			world,
			world,
			WEP_CVAR_PRI(electro, force),
			self.projectiledeathtype,
			other
		);
	}

	remove(self);
}

void W_Electro_TouchExplode(void)
{
	PROJECTILE_TOUCH;
	W_Electro_Explode();
}

void W_Electro_Bolt_Think(void)
{SELFPARAM();
	if(time >= self.ltime)
	{
		self.use();
		return;
	}

	if(WEP_CVAR_PRI(electro, midaircombo_radius))
	{
		float found = 0;
		entity e = WarpZone_FindRadius(self.origin, WEP_CVAR_PRI(electro, midaircombo_radius), true);

		// loop through nearby orbs and trigger them
		while(e)
		{
			if(e.classname == "electro_orb")
			{
				// change owner to whoever caused the combo explosion
				e.realowner = self.realowner;
				e.takedamage = DAMAGE_NO;
				e.classname = "electro_orb_chain";

				// now set the next one to trigger as well
				e.think = W_Electro_ExplodeCombo;

				// delay combo chains, looks cooler
				e.nextthink =
					(
						time
						+
						(WEP_CVAR(electro, combo_speed) ?
							(vlen(e.WarpZone_findradius_dist) / WEP_CVAR(electro, combo_speed))
							:
							0
						)
					);

				++found;
			}
			e = e.chain;
		}

		// if we triggered an orb, should we explode? if not, lets try again next time
		if(found && WEP_CVAR_PRI(electro, midaircombo_explode))
			{ self.use(); }
		else
			{ self.nextthink = min(time + WEP_CVAR_PRI(electro, midaircombo_interval), self.ltime); }
	}
	else { self.nextthink = self.ltime; }
}

void W_Electro_Attack_Bolt(Weapon thiswep)
{SELFPARAM();
	entity proj;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_PRI(electro, ammo));

	W_SetupShot_ProjectileSize(
		self,
		'0 0 -3',
		'0 0 -3',
		false,
		2,
		SND(ELECTRO_FIRE),
		CH_WEAPON_A,
		WEP_CVAR_PRI(electro, damage)
	);

	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	proj = spawn();
	proj.classname = "electro_bolt";
	proj.owner = proj.realowner = self;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_PRI(electro, damage);
	proj.use = W_Electro_Explode;
	proj.think = W_Electro_Bolt_Think;
	proj.nextthink = time;
	proj.ltime = time + WEP_CVAR_PRI(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO.m_id;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	W_SetupProjVelocity_PRI(proj, electro);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Electro_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;
	proj.missile_flags = MIF_SPLASH;

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO_BEAM, true);

	MUTATOR_CALLHOOK(EditProjectile, self, proj);
}

void W_Electro_Orb_Touch(void)
{SELFPARAM();
	PROJECTILE_TOUCH;
	if(other.takedamage == DAMAGE_AIM)
		{ if(WEP_CVAR_SEC(electro, touchexplode)) { W_Electro_Explode(); } }
	else
	{
		//UpdateCSQCProjectile(self);
		spamsound(self, CH_SHOTS, SND(ELECTRO_BOUNCE), VOL_BASE, ATTEN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Electro_Orb_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	// note: combos are usually triggered by W_Electro_TriggerCombo, not damage
	float is_combo = (inflictor.classname == "electro_orb_chain" || inflictor.classname == "electro_bolt");

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, (is_combo ? 1 : -1)))
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	if(self.health <= 0)
	{
		self.takedamage = DAMAGE_NO;
		self.nextthink = time;
		if(is_combo)
		{
			// change owner to whoever caused the combo explosion
			self.realowner = inflictor.realowner;
			self.classname = "electro_orb_chain";
			self.think = W_Electro_ExplodeCombo;
			self.nextthink = time +
				(
					// bound the length, inflictor may be in a galaxy far far away (warpzones)
					min(
						WEP_CVAR(electro, combo_radius),
						vlen(self.origin - inflictor.origin)
					)
					/
					// delay combo chains, looks cooler
					WEP_CVAR(electro, combo_speed)
				);
		}
		else
		{
			self.use = W_Electro_Explode;
			self.think = adaptor_think2use; // not _hittype_splash, as this runs "immediately"
		}
	}
}

void W_Electro_Attack_Orb(Weapon thiswep)
{SELFPARAM();
	W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(electro, ammo));

	W_SetupShot_ProjectileSize(
		self,
		'0 0 -4',
		'0 0 -4',
		false,
		2,
		SND(ELECTRO_FIRE2),
		CH_WEAPON_A,
		WEP_CVAR_SEC(electro, damage)
	);

	w_shotdir = v_forward; // no TrueAim for grenades please

	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	entity proj = spawn();
	proj.classname = "electro_orb";
	proj.owner = proj.realowner = self;
	proj.use = W_Electro_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_SEC(electro, damage);
	proj.nextthink = time + WEP_CVAR_SEC(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO.m_id | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SetupProjVelocity_UP_SEC(proj, electro);
	proj.touch = W_Electro_Orb_Touch;
	setsize(proj, '0 0 -4', '0 0 -4');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_SEC(electro, damageforcescale);
	proj.health = WEP_CVAR_SEC(electro, health);
	proj.event_damage = W_Electro_Orb_Damage;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = (WEP_CVAR_SEC(electro, damagedbycontents));

	proj.bouncefactor = WEP_CVAR_SEC(electro, bouncefactor);
	proj.bouncestop = WEP_CVAR_SEC(electro, bouncestop);
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

#if 0
	entity p2;
	p2 = spawn();
	copyentity(proj, p2);
	setmodel(p2, MDL_PROJECTILE_ELECTRO);
	setsize(p2, proj.mins, proj.maxs);
#endif

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO, false); // no culling, it has sound

	MUTATOR_CALLHOOK(EditProjectile, self, proj);
}

void W_Electro_CheckAttack(Weapon thiswep, entity actor, bool fire1, bool fire2)
{SELFPARAM();
	if(self.electro_count > 1)
	if(self.BUTTON_ATCK2)
	if(weapon_prepareattack(thiswep, actor, true, -1))
	{
		W_Electro_Attack_Orb(WEP_ELECTRO);
		self.electro_count -= 1;
		weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
		return;
	}
	// WEAPONTODO: when the player releases the button, cut down the length of refire2?
	w_ready(thiswep, actor, fire1, fire2);
}

.float bot_secondary_electromooth;

		METHOD(Electro, wr_aim, void(entity thiswep))
		{
			self.BUTTON_ATCK = self.BUTTON_ATCK2 = false;
			if(vlen(self.origin-self.enemy.origin) > 1000) { self.bot_secondary_electromooth = 0; }
			if(self.bot_secondary_electromooth == 0)
			{
				float shoot;

				if(WEP_CVAR_PRI(electro, speed))
					shoot = bot_aim(WEP_CVAR_PRI(electro, speed), 0, WEP_CVAR_PRI(electro, lifetime), false);
				else
					shoot = bot_aim(1000000, 0, 0.001, false);

				if(shoot)
				{
					self.BUTTON_ATCK = true;
					if(random() < 0.01) self.bot_secondary_electromooth = 1;
				}
			}
			else
			{
				if(bot_aim(WEP_CVAR_SEC(electro, speed), WEP_CVAR_SEC(electro, speed_up), WEP_CVAR_SEC(electro, lifetime), true))
				{
					self.BUTTON_ATCK2 = true;
					if(random() < 0.03) self.bot_secondary_electromooth = 0;
				}
			}
		}
		METHOD(Electro, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if(autocvar_g_balance_electro_reload_ammo) // forced reload // WEAPONTODO
			{
				float ammo_amount = 0;
				if(actor.clip_load >= WEP_CVAR_PRI(electro, ammo))
					ammo_amount = 1;
				if(actor.clip_load >= WEP_CVAR_SEC(electro, ammo))
					ammo_amount += 1;

				if(!ammo_amount)
				{
					Weapon w = get_weaponinfo(actor.weapon);
					w.wr_reload(w);
					return;
				}
			}

			if(fire1)
			{
				if(weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(electro, refire)))
				{
						W_Electro_Attack_Bolt(thiswep);
						weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
				}
			}
			else if(fire2)
			{
				if(time >= actor.electro_secondarytime)
				if(weapon_prepareattack(thiswep, actor, true, WEP_CVAR_SEC(electro, refire)))
				{
					W_Electro_Attack_Orb(thiswep);
					actor.electro_count = WEP_CVAR_SEC(electro, count);
					weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
					actor.electro_secondarytime = time + WEP_CVAR_SEC(electro, refire2) * W_WeaponRateFactor();
				}
			}
		}
		METHOD(Electro, wr_init, void(entity thiswep))
		{
			ELECTRO_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(Electro, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(ELECTRO) >= WEP_CVAR_PRI(electro, ammo);
			ammo_amount += self.(weapon_load[WEP_ELECTRO.m_id]) >= WEP_CVAR_PRI(electro, ammo);
			return ammo_amount;
		}
		METHOD(Electro, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(electro, combo_safeammocheck)) // true if you can fire at least one secondary blob AND one primary shot after it, otherwise false.
			{
				ammo_amount = self.WEP_AMMO(ELECTRO) >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
				ammo_amount += self.(weapon_load[WEP_ELECTRO.m_id]) >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
			}
			else
			{
				ammo_amount = self.WEP_AMMO(ELECTRO) >= WEP_CVAR_SEC(electro, ammo);
				ammo_amount += self.(weapon_load[WEP_ELECTRO.m_id]) >= WEP_CVAR_SEC(electro, ammo);
			}
			return ammo_amount;
		}
		METHOD(Electro, wr_config, void(entity thiswep))
		{
			ELECTRO_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(Electro, wr_resetplayer, void(entity thiswep))
		{
			self.electro_secondarytime = time;
		}
		METHOD(Electro, wr_reload, void(entity thiswep))
		{
			W_Reload(self, min(WEP_CVAR_PRI(electro, ammo), WEP_CVAR_SEC(electro, ammo)), SND(RELOAD));
		}
		METHOD(Electro, wr_suicidemessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_ELECTRO_SUICIDE_ORBS;
			else
				return WEAPON_ELECTRO_SUICIDE_BOLT;
		}
		METHOD(Electro, wr_killmessage, int(entity thiswep))
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

		METHOD(Electro, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				pointparticles(particleeffectnum(EFFECT_ELECTRO_BALLEXPLODE), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
			}
			else
			{
				if(w_deathtype & HITTYPE_BOUNCE)
				{
					// this is sent as "primary (w_deathtype & HITTYPE_BOUNCE)" to distinguish it from (w_deathtype & HITTYPE_SECONDARY) bounced balls
					pointparticles(particleeffectnum(EFFECT_ELECTRO_COMBO), org2, '0 0 0', 1);
					if(!w_issilent)
						sound(self, CH_SHOTS, SND_ELECTRO_IMPACT_COMBO, VOL_BASE, ATTEN_NORM);
				}
				else
				{
					pointparticles(particleeffectnum(EFFECT_ELECTRO_IMPACT), org2, '0 0 0', 1);
					if(!w_issilent)
						sound(self, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
				}
			}
		}

#endif
#endif
