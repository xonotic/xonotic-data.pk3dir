#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ ELECTRO,
/* function */ W_Electro,
/* ammotype */ IT_CELLS,
/* impulse  */ 5,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "electro",
/* netname  */ "electro",
/* fullname */ _("Electro")
);

#define ELECTRO_SETTINGS(w_cvar,w_prop) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, ammo) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, animtime) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, damage) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, edgedamage) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, force) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, radius) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, refire) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, speed) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, spread) \
	w_cvar(WEP_ELECTRO, electro, MO_BOTH, lifetime) \
	w_cvar(WEP_ELECTRO, electro, MO_PRI,  comboradius) \
	w_cvar(WEP_ELECTRO, electro, MO_PRI,  midaircombo_interval) \
	w_cvar(WEP_ELECTRO, electro, MO_PRI,  midaircombo_radius) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  bouncefactor) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  bouncestop) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  count) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  damageforcescale) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  damagedbycontents) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  takedamageexplode) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  health) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  refire2) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  speed_up) \
	w_cvar(WEP_ELECTRO, electro, MO_SEC,  speed_z) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_comboradius) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_comboradius_thruwall) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_damage) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_edgedamage) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_force) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_radius) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_speed) \
	w_cvar(WEP_ELECTRO, electro, MO_NONE, combo_safeammocheck) \
	w_prop(WEP_ELECTRO, electro, reloading_ammo, reload_ammo) \
	w_prop(WEP_ELECTRO, electro, reloading_time, reload_time) \
	w_prop(WEP_ELECTRO, electro, switchdelay_raise, switchdelay_raise) \
	w_prop(WEP_ELECTRO, electro, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
ELECTRO_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float electro_count;
.float electro_secondarytime;
void W_Plasma_Explode_Combo(void);
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_electro() { weapon_defaultspawnfunc(WEP_ELECTRO); }

void W_Plasma_TriggerCombo(vector org, float rad, entity own)
{
	entity e = WarpZone_FindRadius(org, rad, !WEP_CVAR(electro, combo_comboradius_thruwall));
	while(e)
	{
		if(e.classname == "plasma")
		{
			// change owner to whoever caused the combo explosion
			WarpZone_TraceLine(org, e.origin, MOVE_NOMONSTERS, e);

			if(
				(trace_fraction == 1)
				||
				(WEP_CVAR(electro, combo_comboradius_thruwall) >= vlen(e.WarpZone_findradius_dist))
			)
			{
				e.realowner = own;
				e.takedamage = DAMAGE_NO;
				e.classname = "plasma_chain";
				e.think = W_Plasma_Explode_Combo;
				e.nextthink = time + vlen(e.WarpZone_findradius_dist) / WEP_CVAR(electro, combo_speed); // delay combo chains, looks cooler
			}
		}
		e = e.chain;
	}
}

void W_Plasma_Explode(void)
{
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
		W_Plasma_TriggerCombo(self.origin, WEP_CVAR_PRI(electro, comboradius), self.realowner);
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

void W_Plasma_Explode_Combo(void)
{
	W_Plasma_TriggerCombo(self.origin, WEP_CVAR(electro, combo_comboradius), self.realowner);

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
		WEP_ELECTRO | HITTYPE_BOUNCE, // use THIS type for a combo because primary can't bounce
		world
	);

	remove (self);
}

void W_Plasma_Touch(void)
{
	PROJECTILE_TOUCH;
	if(other.takedamage == DAMAGE_AIM)
		{ if(WEP_CVAR_SEC(electro, takedamageexplode)) { W_Plasma_Explode(); } }
	else
	{
		//UpdateCSQCProjectile(self);
		spamsound(self, CH_SHOTS, "weapons/electro_bounce.wav", VOL_BASE, ATTEN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Plasma_TouchExplode(void)
{
	PROJECTILE_TOUCH;
	W_Plasma_Explode();
}

void W_Plasma_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;

	// note: combos are usually triggered by W_Plasma_TriggerCombo, not damage
	float is_combo = (inflictor.classname == "plasma_chain" || inflictor.classname == "plasma_prim");

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
			self.classname = "plasma_chain";
			self.think = W_Plasma_Explode_Combo;
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
			self.use = W_Plasma_Explode;
			self.think = adaptor_think2use; // not _hittype_splash, as this runs "immediately"
		}
	}
}

void W_Plasma_Think()
{
	self.nextthink = min(time + WEP_CVAR_PRI(electro, midaircombo_interval), self.ltime);
	
	if(time >= self.ltime)
	{
		self.use();
		return;
	}
	
	W_Plasma_TriggerCombo(self.origin, WEP_CVAR_PRI(electro, midaircombo_radius), self.realowner);
}

void W_Electro_Attack_Bolt(void)
{
	entity proj;

	W_DecreaseAmmo(ammo_cells, WEP_CVAR_PRI(electro, ammo), autocvar_g_balance_electro_reload_ammo);//weapontodo

	W_SetupShot_ProjectileSize(self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire.wav", CH_WEAPON_A, WEP_CVAR_PRI(electro, damage));

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = proj.realowner = self;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = WEP_CVAR_PRI(electro, damage);
	proj.use = W_Plasma_Explode;
	proj.think = W_Plasma_Think;
	proj.nextthink = time;
	proj.ltime = time + WEP_CVAR_PRI(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	WEP_SETUPPROJVELOCITY_PRI(proj, electro);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Plasma_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;
	proj.missile_flags = MIF_SPLASH;

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO_BEAM, TRUE);

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Electro_Attack_Orbs(void)
{
	W_DecreaseAmmo(ammo_cells, WEP_CVAR_SEC(electro, ammo), autocvar_g_balance_electro_reload_ammo);//weapontodo

	W_SetupShot_ProjectileSize(self, '0 0 -4', '0 0 -4', FALSE, 2, "weapons/electro_fire2.wav", CH_WEAPON_A, WEP_CVAR_SEC(electro, damage));

	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	entity proj = spawn();
	proj.classname = "plasma";
	proj.owner = proj.realowner = self;
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = WEP_CVAR_SEC(electro, damage);
	proj.nextthink = time + WEP_CVAR_SEC(electro, lifetime);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	WEP_SETUPPROJVELOCITY_UP_SEC(proj, electro);
	proj.touch = W_Plasma_Touch;
	setsize(proj, '0 0 -4', '0 0 -4');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_SEC(electro, damageforcescale);
	proj.health = WEP_CVAR_SEC(electro, health);
	proj.event_damage = W_Plasma_Damage;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = (WEP_CVAR_SEC(electro, damagedbycontents));

	proj.bouncefactor = WEP_CVAR_SEC(electro, bouncefactor);
	proj.bouncestop = WEP_CVAR_SEC(electro, bouncestop);
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

#if 0
	entity p2;
	p2 = spawn();
	copyentity(proj, p2);
	setmodel(p2, "models/ebomb.mdl");
	setsize(p2, proj.mins, proj.maxs);
#endif

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO, FALSE); // no culling, it has sound

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Electro_CheckAttack()
{
	if(self.electro_count > 1)
	if(self.BUTTON_ATCK2)
	if(weapon_prepareattack(1, -1))
	{
		W_Electro_Attack_Orbs();
		self.electro_count -= 1;
		weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
		return;
	}
	w_ready();
}

.float bot_secondary_electromooth;
float W_Electro(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			self.BUTTON_ATCK = self.BUTTON_ATCK2 = FALSE;
			if(vlen(self.origin-self.enemy.origin) > 1000) { self.bot_secondary_electromooth = 0; }
			if(self.bot_secondary_electromooth == 0)
			{
				float shoot;

				if(WEP_CVAR_PRI(electro, speed))
					shoot = bot_aim(WEP_CVAR_PRI(electro, speed), 0, WEP_CVAR_PRI(electro, lifetime), FALSE);
				else
					shoot = bot_aim(1000000, 0, 0.001, FALSE);

				if(shoot)
				{
					self.BUTTON_ATCK = TRUE;
					if(random() < 0.01) self.bot_secondary_electromooth = 1;
				}
			}
			else
			{
				if(bot_aim(WEP_CVAR_SEC(electro, speed), WEP_CVAR_SEC(electro, speed_up), WEP_CVAR_SEC(electro, lifetime), TRUE))
				{
					self.BUTTON_ATCK2 = TRUE;
					if(random() < 0.03) self.bot_secondary_electromooth = 0;
				}
			}
			
			return TRUE;
		}
		case WR_THINK:
		{
			if(autocvar_g_balance_electro_reload_ammo) // forced reload // WEAPONTODO
			{
				ammo_amount = 0;
				if(self.clip_load >= WEP_CVAR_PRI(electro, ammo))
					ammo_amount = 1;
				if(self.clip_load >= WEP_CVAR_SEC(electro, ammo))
					ammo_amount += 1;

				if(!ammo_amount)
				{
					WEP_ACTION(self.weapon, WR_RELOAD);
					return FALSE;
				}
				
				return TRUE;
			}
			
			if(self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, WEP_CVAR_PRI(electro, refire)))
				{
						W_Electro_Attack_Bolt();
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
				}
			}
			else if(self.BUTTON_ATCK2)
			{
				if(time >= self.electro_secondarytime)
				if(weapon_prepareattack(1, WEP_CVAR_SEC(electro, refire)))
				{
					W_Electro_Attack_Orbs();
					self.electro_count = WEP_CVAR_SEC(electro, count);
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(electro, animtime), W_Electro_CheckAttack);
					self.electro_secondarytime = time + WEP_CVAR_SEC(electro, refire2) * W_WeaponRateFactor();
				}
			}

			return TRUE;
		}
		case WR_INIT:
		{
			precache_model("models/weapons/g_electro.md3");
			precache_model("models/weapons/v_electro.md3");
			precache_model("models/weapons/h_electro.iqm");
			precache_sound("weapons/electro_bounce.wav");
			precache_sound("weapons/electro_fire.wav");
			precache_sound("weapons/electro_fire2.wav");
			precache_sound("weapons/electro_impact.wav");
			precache_sound("weapons/electro_impact_combo.wav");
			ELECTRO_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_cells;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_cells >= WEP_CVAR_PRI(electro, ammo);
			ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= WEP_CVAR_PRI(electro, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(WEP_CVAR(electro, combo_safeammocheck)) // true if you can fire at least one secondary blob AND one primary shot after it, otherwise false.
			{
				ammo_amount = self.ammo_cells >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
				ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= WEP_CVAR_SEC(electro, ammo) + WEP_CVAR_PRI(electro, ammo);
			}
			else
			{
				ammo_amount = self.ammo_cells >= WEP_CVAR_SEC(electro, ammo);
				ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= WEP_CVAR_SEC(electro, ammo);
			}
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			ELECTRO_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RESETPLAYER:
		{
			self.electro_secondarytime = time;
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(electro, ammo), WEP_CVAR_SEC(electro, ammo)), "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_ELECTRO_SUICIDE_ORBS;
			else
				return WEAPON_ELECTRO_SUICIDE_BOLT;
		}
		case WR_KILLMESSAGE:
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
	}
	return TRUE;
}
#endif
#ifdef CSQC
float W_Electro(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				pointparticles(particleeffectnum("electro_ballexplode"), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CH_SHOTS, "weapons/electro_impact.wav", VOL_BASE, ATTEN_NORM);
			}
			else
			{
				if(w_deathtype & HITTYPE_BOUNCE)
				{
					// this is sent as "primary (w_deathtype & HITTYPE_BOUNCE)" to distinguish it from (w_deathtype & HITTYPE_SECONDARY) bounced balls
					pointparticles(particleeffectnum("electro_combo"), org2, '0 0 0', 1);
					if(!w_issilent)
						sound(self, CH_SHOTS, "weapons/electro_impact_combo.wav", VOL_BASE, ATTEN_NORM);
				}
				else
				{
					pointparticles(particleeffectnum("electro_impact"), org2, '0 0 0', 1);
					if(!w_issilent)
						sound(self, CH_SHOTS, "weapons/electro_impact.wav", VOL_BASE, ATTEN_NORM);
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/electro_impact.wav");
			precache_sound("weapons/electro_impact_combo.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
