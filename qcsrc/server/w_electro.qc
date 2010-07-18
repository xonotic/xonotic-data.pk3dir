#ifdef REGISTER_WEAPON
REGISTER_WEAPON(ELECTRO, w_electro, IT_CELLS, 5, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "electro", "electro", "Electro");
#else
#ifdef SVQC
.float electro_count;
.float electro_secondarytime;

void W_Plasma_Explode_Combo (void);

void W_Plasma_TriggerCombo(vector org, float rad, entity own)
{
	local entity e;
	e = WarpZone_FindRadius(org, rad, TRUE);
	while (e)
	{
		if (e.classname == "plasma")
		{
			// change owner to whoever caused the combo explosion
			e.owner = own;
			e.takedamage = DAMAGE_NO;
			e.classname = "plasma_chain";
			e.think = W_Plasma_Explode_Combo;
			e.nextthink = time + vlen(e.WarpZone_findradius_dist) / cvar("g_balance_electro_combo_speed"); // delay combo chains, looks cooler
		}
		e = e.chain;
	}
}

void W_Plasma_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						AnnounceTo(self.owner, "electrobitch");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	if (self.movetype == MOVETYPE_BOUNCE)
	{
		RadiusDamage (self, self.owner, cvar("g_balance_electro_secondary_damage"), cvar("g_balance_electro_secondary_edgedamage"), cvar("g_balance_electro_secondary_radius"), world, cvar("g_balance_electro_secondary_force"), self.projectiledeathtype, other);
	}
	else
	{
		W_Plasma_TriggerCombo(self.origin, cvar("g_balance_electro_primary_comboradius"), self.owner);
		RadiusDamage (self, self.owner, cvar("g_balance_electro_primary_damage"), cvar("g_balance_electro_primary_edgedamage"), cvar("g_balance_electro_primary_radius"), world, cvar("g_balance_electro_primary_force"), self.projectiledeathtype, other);
	}

	remove (self);
}

void W_Plasma_Explode_Combo (void)
{
	W_Plasma_TriggerCombo(self.origin, cvar("g_balance_electro_combo_comboradius"), self.owner);

	self.event_damage = SUB_Null;
	RadiusDamage (self, self.owner, cvar("g_balance_electro_combo_damage"), cvar("g_balance_electro_combo_edgedamage"), cvar("g_balance_electro_combo_radius"), world, cvar("g_balance_electro_combo_force"), WEP_ELECTRO | HITTYPE_BOUNCE, world); // use THIS type for a combo because primary can't bounce
	remove (self);
}

void W_Plasma_Touch (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM) {
		W_Plasma_Explode ();
	} else {
		spamsound (self, CHAN_PROJECTILE, "weapons/electro_bounce.wav", VOL_BASE, ATTN_NORM);
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
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.takedamage = DAMAGE_NO;
		self.nextthink = time;
		if (inflictor.classname == "plasma_chain" || inflictor.classname == "plasma_prim")
		{
			// change owner to whoever caused the combo explosion
			self.owner = inflictor.owner;
			self.classname = "plasma_chain";
			self.think = W_Plasma_Explode_Combo;
			self.nextthink = time + min(cvar("g_balance_electro_combo_radius"), vlen(self.origin - inflictor.origin)) / cvar("g_balance_electro_combo_speed"); // delay combo chains, looks cooler
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
	local entity proj;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire.wav", cvar("g_balance_electro_primary_damage"));

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = self;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = cvar("g_balance_electro_primary_damage");
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.nextthink = time + cvar("g_balance_electro_primary_lifetime");
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO;
	setorigin(proj, w_shotorg);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - cvar("g_balance_electro_primary_ammo");
	proj.movetype = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(proj, g_balance_electro_primary);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Plasma_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;

	//sound (proj, CHAN_PAIN, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
	//sounds bad

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO_BEAM, TRUE);
}

void W_Electro_Attack2()
{
	local entity proj;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire2.wav", cvar("g_balance_electro_secondary_damage"));
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma";
	proj.owner = self;
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = cvar("g_balance_electro_secondary_damage");
	proj.nextthink = time + cvar("g_balance_electro_secondary_lifetime");
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - cvar("g_balance_electro_secondary_ammo");
	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SETUPPROJECTILEVELOCITY_UP(proj, g_balance_electro_secondary);
	proj.touch = W_Plasma_Touch;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = cvar("g_balance_electro_secondary_damageforcescale");
	proj.health = cvar("g_balance_electro_secondary_health");
	proj.event_damage = W_Plasma_Damage;
	proj.flags = FL_PROJECTILE;

#if 0
	entity p2;
	p2 = spawn();
	copyentity(proj, p2);
	setmodel(p2, "models/ebomb.mdl");
	setsize(p2, proj.mins, proj.maxs);
#endif

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO, FALSE); // no culling, it has sound
}

.entity lgbeam, exteriorlgbeam;
void lgbeam_think()
{
	if (self.owner.weaponentity.state != WS_INUSE || (self.owner.ammo_cells <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self != self.owner.lgbeam)
	{
		remove(self);
		return;
	}

	self.nextthink = time;

	makevectors(self.owner.v_angle);
	vector angle;
	angle = v_forward;

	vector force;
	force = angle * cvar("g_balance_electro_primary_force");

	traceline_antilag(self.owner, self.owner.origin + self.owner.view_ofs, self.owner.origin + self.owner.view_ofs + angle * cvar("g_balance_electro_primary_range"), FALSE, self.owner, ANTILAG_LATENCY(self.owner));

	self.scale = vlen(self.owner.origin - trace_endpos) / 256 * (0.75 + 0.75 * random());
}

void exteriorlgbeam_think()
{
	if (self.owner.weaponentity.state != WS_INUSE || (self.owner.ammo_cells <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self != self.owner.exteriorlgbeam)
	{
		sound (self, CHAN_PROJECTILE, "sound/misc/null.wav", VOL_BASE, ATTN_NORM);
		remove(self);
		return;
	}

	if (time - self.shot_spread + random() * 0.2 > 0)
	{
		self.shot_spread = time + 2;
		sound (self, CHAN_PROJECTILE, "turrets/phaser.wav", VOL_BASE, ATTN_NORM);
	}

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - cvar("g_balance_electro_primary_ammo") * frametime;

	self.nextthink = time;

	makevectors(self.owner.v_angle);
	vector angle;
	angle = v_forward;

	traceline_antilag(self.owner, self.owner.origin + self.owner.view_ofs, self.owner.origin + self.owner.view_ofs + angle * cvar("g_balance_electro_primary_range"), FALSE, self.owner, ANTILAG_LATENCY(self.owner));

	// apply the damage
	if(trace_fraction < 1)
	{
		vector force;
		force = angle * cvar("g_balance_electro_primary_force") + trace_ent.velocity * cvar("g_balance_electro_primary_velocityfactor") + '0 0 1' * cvar("g_balance_electro_primary_force_up");
		Damage (trace_ent, self.owner, self.owner, cvar("g_balance_electro_primary_damage") * frametime, WEP_ELECTRO, trace_endpos, force * frametime);
	}

	self.angles = '0 0 0';
	self.scale = vlen(gettaginfo(self, 0) - trace_endpos) / 256 * (0.75 + 0.75 * random());

	// v_forward, v_right, v_up now are the ACTUAL directions
	// express self.angles in terms of them to aim at target!
	self.angles = vectoangles('1 0 0' * (angle * v_forward) + '0 -1 0' * (angle * v_right) + '0 0 1' * (angle * v_up));
}

// experimental lightning gun
void W_Electro_Attack3 (void)
{
	entity beam, oldself;

	self.lgbeam = beam = spawn();
	setmodel(beam,"models/turrets/phaser_beam.md3");
	beam.effects = EF_LOWPRECISION;
	beam.solid = SOLID_NOT;
	beam.think = lgbeam_think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	if(gettagindex(self.weaponentity, "shot"))
		setattachment(beam, self.weaponentity, "shot");
	else
		setattachment(beam, self.weaponentity, "tag_shot");

	oldself = self;
	self = beam;
	self.think();
	self = oldself;

	self.exteriorlgbeam = beam = spawn();
	setmodel(beam,"models/turrets/phaser_beam.md3");
	beam.effects = EF_LOWPRECISION;
	beam.solid = SOLID_NOT;
	beam.think = exteriorlgbeam_think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	//beam.viewmodelforclient = self;
	if(self.weaponentity.oldorigin_x > 0)
	{
		setattachment(beam, self.exteriorweaponentity, "");
		setorigin(beam, self.weaponentity.oldorigin);
	}
	else
	{
		if(gettagindex(self.exteriorweaponentity, "shot"))
			setattachment(beam, self.exteriorweaponentity, "shot");
		else
			setattachment(beam, self.exteriorweaponentity, "tag_shot");
	}

	beam.shot_spread = 0;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = cvar("g_balance_electro_primary_damage");

	oldself = self;
	self = beam;
	self.think();
	self = oldself;
}

void spawnfunc_weapon_electro (void)
{
	weapon_defaultspawnfunc(WEP_ELECTRO);
}

void w_electro_checkattack()
{
	if(self.electro_count > 1)
	if(self.BUTTON_ATCK2)
	if(weapon_prepareattack(1, -1))
	{
		W_Electro_Attack2();
		self.electro_count -= 1;
		weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_electro_secondary_animtime"), w_electro_checkattack);
		return;
	}

	w_ready();
}

.float bot_secondary_electromooth;
.float BUTTON_ATCK_prev;
float w_electro(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK=FALSE;
		self.BUTTON_ATCK2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_secondary_electromooth = 0;
		if(self.bot_secondary_electromooth == 0)
		{
			if(bot_aim(cvar("g_balance_electro_primary_speed"), 0, cvar("g_balance_electro_primary_lifetime"), FALSE))
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.01) self.bot_secondary_electromooth = 1;
			}
		}
		else
		{
			if(bot_aim(cvar("g_balance_electro_secondary_speed"), cvar("g_balance_grenadelauncher_secondary_speed_up"), cvar("g_balance_electro_secondary_lifetime"), TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < 0.03) self.bot_secondary_electromooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, cvar("g_balance_electro_primary_refire")))
		{
			if(cvar("g_balance_electro_lightning"))
			{
				if (self.BUTTON_ATCK_prev == 0)
				{
					W_Electro_Attack3();
				}
			}
			else
			{
				W_Electro_Attack();
			}
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_electro_primary_animtime"), w_ready);
		}
		if (self.BUTTON_ATCK2)
		if (time >= self.electro_secondarytime)
		if (weapon_prepareattack(1, cvar("g_balance_electro_secondary_refire")))
		{
			W_Electro_Attack2();
			self.electro_count = cvar("g_balance_electro_secondary_count");
			weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_electro_secondary_animtime"), w_electro_checkattack);
			self.electro_secondarytime = time + cvar("g_balance_electro_secondary_refire2");
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_electro.md3");
		precache_model ("models/weapons/v_electro.md3");
		precache_model ("models/weapons/h_electro.iqm");
		precache_sound ("weapons/electro_bounce.wav");
		precache_sound ("weapons/electro_fire.wav");
		precache_sound ("weapons/electro_fire2.wav");
		precache_sound ("weapons/electro_impact.wav");
		precache_sound ("weapons/electro_impact_combo.wav");
		if(cvar("g_balance_electro_lightning"))
			precache_sound ("weapons/crylink_fire2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_ELECTRO);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= cvar("g_balance_electro_primary_ammo");
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= cvar("g_balance_electro_secondary_ammo");
	else if (req == WR_RESETPLAYER)
	{
		self.electro_secondarytime = time;
	}
	self.BUTTON_ATCK_prev = self.BUTTON_ATCK;
	return TRUE;
};
#endif
#ifdef CSQC
float w_electro(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			pointparticles(particleeffectnum("electro_ballexplode"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				// this is sent as "primary (w_deathtype & HITTYPE_BOUNCE)" to distinguish it from (w_deathtype & HITTYPE_SECONDARY) bounced balls
				pointparticles(particleeffectnum("electro_combo"), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CHAN_PROJECTILE, "weapons/electro_impact_combo.wav", VOL_BASE, ATTN_NORM);
			}
			else
			{
				pointparticles(particleeffectnum("electro_impact"), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
			}
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/electro_impact.wav");
		precache_sound("weapons/electro_impact_combo.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "could not remember where they put plasma";
		else
			w_deathtypestring = "played with plasma";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_SPLASH) // unchecked: BOUNCE
				w_deathtypestring = "just noticed #'s blue ball";
			else // unchecked: BOUNCE
				w_deathtypestring = "got in touch with #'s blue ball";
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE) // combo
				w_deathtypestring = "felt the electrifying air of #'s combo";
			else if(w_deathtype & HITTYPE_SPLASH)
				w_deathtypestring = "got too close to #'s blue beam";
			else
				w_deathtypestring = "was blasted by #'s blue beam";
		}
	}
	return TRUE;
}
#endif
#endif
