#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ ELECTRO,
/* function */ w_electro,
/* ammotype */ IT_CELLS,
/* impulse  */ 5,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "electro",
/* netname  */ "electro",
/* fullname */ _("Electro")
);

#ifdef SVQC
var float autocvar_g_balance_electro_combo_comboradius_thruwall = 200;
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_electro() { weapon_defaultspawnfunc(WEP_ELECTRO); }

.float electro_count;
.float electro_secondarytime;

void W_Plasma_Explode_Combo (void);

void W_Plasma_TriggerCombo(vector org, float rad, entity own)
{
	entity e;
	e = WarpZone_FindRadius(org, rad, !autocvar_g_balance_electro_combo_comboradius_thruwall);
	while (e)
	{
		if (e.classname == "plasma")
		{
			// change owner to whoever caused the combo explosion
			WarpZone_TraceLine(org, e.origin, MOVE_NOMONSTERS, e);

			if((trace_fraction == 1) || (autocvar_g_balance_electro_combo_comboradius_thruwall >= vlen(e.WarpZone_findradius_dist)))
			{
				e.realowner = own;
				e.takedamage = DAMAGE_NO;
				e.classname = "plasma_chain";
				e.think = W_Plasma_Explode_Combo;
				e.nextthink = time + vlen(e.WarpZone_findradius_dist) / autocvar_g_balance_electro_combo_speed; // delay combo chains, looks cooler
			}
		}
		e = e.chain;
	}
}

void W_Plasma_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_ELECTROBITCH);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	if (self.movetype == MOVETYPE_BOUNCE)
	{
		RadiusDamage(self, self.realowner, autocvar_g_balance_electro_secondary_damage, autocvar_g_balance_electro_secondary_edgedamage, autocvar_g_balance_electro_secondary_radius, world, world, autocvar_g_balance_electro_secondary_force, self.projectiledeathtype, other);
	}
	else
	{
		W_Plasma_TriggerCombo(self.origin, autocvar_g_balance_electro_primary_comboradius, self.realowner);
		RadiusDamage (self, self.realowner, autocvar_g_balance_electro_primary_damage, autocvar_g_balance_electro_primary_edgedamage, autocvar_g_balance_electro_primary_radius, world, world, autocvar_g_balance_electro_primary_force, self.projectiledeathtype, other);
	}

	remove (self);
}

void W_Plasma_Explode_Combo (void)
{
	W_Plasma_TriggerCombo(self.origin, autocvar_g_balance_electro_combo_comboradius, self.realowner);

	self.event_damage = func_null;
	RadiusDamage (self, self.realowner, autocvar_g_balance_electro_combo_damage, autocvar_g_balance_electro_combo_edgedamage, autocvar_g_balance_electro_combo_radius, world, world, autocvar_g_balance_electro_combo_force, WEP_ELECTRO | HITTYPE_BOUNCE, world); // use THIS type for a combo because primary can't bounce

	remove (self);
}

void W_Plasma_Touch (void)
{
	//self.velocity = self.velocity  * 0.1;

	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM) {
		W_Plasma_Explode ();
	} else {
		//UpdateCSQCProjectile(self);
		spamsound (self, CH_SHOTS, "weapons/electro_bounce.wav", VOL_BASE, ATTEN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Plasma_TouchExplode (void)
{
	PROJECTILE_TOUCH;
	W_Plasma_Explode ();
}

void W_Plasma_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;

	// note: combos are usually triggered by W_Plasma_TriggerCombo, not damage
	float is_combo = (inflictor.classname == "plasma_chain" || inflictor.classname == "plasma_prim");

	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, (is_combo ? 1 : -1)))
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.takedamage = DAMAGE_NO;
		self.nextthink = time;
		if (is_combo)
		{
			// change owner to whoever caused the combo explosion
			self.realowner = inflictor.realowner;
			self.classname = "plasma_chain";
			self.think = W_Plasma_Explode_Combo;
			self.nextthink = time + min(autocvar_g_balance_electro_combo_radius, vlen(self.origin - inflictor.origin)) / autocvar_g_balance_electro_combo_speed; // delay combo chains, looks cooler
				//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ bounding the length, because inflictor may be in a galaxy far far away (warpzones)
		}
		else
		{
			self.use = W_Plasma_Explode;
			self.think = adaptor_think2use; // not _hittype_splash, as this runs "immediately"
		}
	}
}

void W_Electro_Attack()
{
	entity proj;

	W_DecreaseAmmo(ammo_cells, autocvar_g_balance_electro_primary_ammo, autocvar_g_balance_electro_reload_ammo);

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire.wav", CH_WEAPON_A, autocvar_g_balance_electro_primary_damage);

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = proj.realowner = self;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = autocvar_g_balance_electro_primary_damage;
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.nextthink = time + autocvar_g_balance_electro_primary_lifetime;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(proj, g_balance_electro_primary);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Plasma_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;
	proj.missile_flags = MIF_SPLASH;

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO_BEAM, TRUE);

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Electro_Attack2()
{
	entity proj;

	W_DecreaseAmmo(ammo_cells, autocvar_g_balance_electro_secondary_ammo, autocvar_g_balance_electro_reload_ammo);

	W_SetupShot_ProjectileSize (self, '0 0 -4', '0 0 -4', FALSE, 2, "weapons/electro_fire2.wav", CH_WEAPON_A, autocvar_g_balance_electro_secondary_damage);

	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma";
	proj.owner = proj.realowner = self;
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = autocvar_g_balance_electro_secondary_damage;
	proj.nextthink = time + autocvar_g_balance_electro_secondary_lifetime;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SETUPPROJECTILEVELOCITY_UP(proj, g_balance_electro_secondary);
	proj.touch = W_Plasma_Touch;
	setsize(proj, '0 0 -4', '0 0 -4');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = autocvar_g_balance_electro_secondary_damageforcescale;
	proj.health = autocvar_g_balance_electro_secondary_health;
	proj.event_damage = W_Plasma_Damage;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = (autocvar_g_balance_electro_secondary_damagedbycontents);

	proj.bouncefactor = autocvar_g_balance_electro_secondary_bouncefactor;
	proj.bouncestop = autocvar_g_balance_electro_secondary_bouncestop;
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

void w_electro_checkattack()
{
	if(self.electro_count > 1)
	if(self.BUTTON_ATCK2)
	if(weapon_prepareattack(1, -1))
	{
		W_Electro_Attack2();
		self.electro_count -= 1;
		weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_electro_secondary_animtime, w_electro_checkattack);
		return;
	}

	w_ready();
}

.float bot_secondary_electromooth;
float w_electro(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			self.BUTTON_ATCK=FALSE;
			self.BUTTON_ATCK2=FALSE;
			if(vlen(self.origin-self.enemy.origin) > 1000)
				self.bot_secondary_electromooth = 0;
			if(self.bot_secondary_electromooth == 0)
			{
				float shoot;

				if(autocvar_g_balance_electro_primary_speed)
					shoot = bot_aim(autocvar_g_balance_electro_primary_speed, 0, autocvar_g_balance_electro_primary_lifetime, FALSE);
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
				if(bot_aim(autocvar_g_balance_electro_secondary_speed, autocvar_g_balance_mortar_secondary_speed_up, autocvar_g_balance_electro_secondary_lifetime, TRUE)) // WHAT THE ACTUAL FUUUUUUUUUCK?!?!? WEAPONTODO
				{
					self.BUTTON_ATCK2 = TRUE;
					if(random() < 0.03) self.bot_secondary_electromooth = 0;
				}
			}
			
			return TRUE;
		}
		case WR_THINK:
		{
			if(autocvar_g_balance_electro_reload_ammo) // forced reload
			{
				ammo_amount = 0;
				if(self.clip_load >= autocvar_g_balance_electro_primary_ammo)
					ammo_amount = 1;
				if(self.clip_load >= autocvar_g_balance_electro_secondary_ammo)
					ammo_amount += 1;

				if(!ammo_amount)
				{
					WEP_ACTION(self.weapon, WR_RELOAD);
					return FALSE;
				}
				
				return TRUE;
			}
			if (self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, autocvar_g_balance_electro_primary_refire))
				{
						W_Electro_Attack();
						weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_electro_primary_animtime, w_ready);
				}
			}
			else if(self.BUTTON_ATCK2)
			{
				if (time >= self.electro_secondarytime)
				if (weapon_prepareattack(1, autocvar_g_balance_electro_secondary_refire))
				{
					W_Electro_Attack2();
					self.electro_count = autocvar_g_balance_electro_secondary_count;
					weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_electro_secondary_animtime, w_electro_checkattack);
					self.electro_secondarytime = time + autocvar_g_balance_electro_secondary_refire2 * W_WeaponRateFactor();
				}
			}

			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/weapons/g_electro.md3");
			precache_model ("models/weapons/v_electro.md3");
			precache_model ("models/weapons/h_electro.iqm");
			precache_sound ("weapons/electro_bounce.wav");
			precache_sound ("weapons/electro_fire.wav");
			precache_sound ("weapons/electro_fire2.wav");
			precache_sound ("weapons/electro_impact.wav");
			precache_sound ("weapons/electro_impact_combo.wav");
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_cells;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_cells >= autocvar_g_balance_electro_primary_ammo;
			ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= autocvar_g_balance_electro_primary_ammo;
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(autocvar_g_balance_electro_combo_safeammocheck) // true if you can fire at least one secondary blob AND one primary shot after it, otherwise false.
			{
				ammo_amount = self.ammo_cells >= autocvar_g_balance_electro_secondary_ammo + autocvar_g_balance_electro_primary_ammo;
				ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= autocvar_g_balance_electro_secondary_ammo + autocvar_g_balance_electro_primary_ammo;
			}
			else
			{
				ammo_amount = self.ammo_cells >= autocvar_g_balance_electro_secondary_ammo;
				ammo_amount += self.(weapon_load[WEP_ELECTRO]) >= autocvar_g_balance_electro_secondary_ammo;
			}
			return ammo_amount;
		}
		case WR_RESETPLAYER:
		{
			self.electro_secondarytime = time;
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(autocvar_g_balance_electro_primary_ammo, autocvar_g_balance_electro_secondary_ammo), "weapons/reload.wav");
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
float w_electro(float req)
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
