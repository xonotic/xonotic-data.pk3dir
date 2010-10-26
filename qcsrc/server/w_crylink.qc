#ifdef REGISTER_WEAPON
REGISTER_WEAPON(CRYLINK, w_crylink, IT_CELLS, 6, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "crylink", "crylink", "Crylink");
#else
#ifdef SVQC
.float gravity;

.entity queuenext;
.entity queueprev;

// force projectile to explode
void W_Crylink_LinkExplode (entity e, entity e2)
{
	float a;
	a = bound(0, 1 - (time - e.fade_time) * e.fade_rate, 1);

	RadiusDamage (e, e.realowner, cvar("g_balance_crylink_primary_damage") * a, cvar("g_balance_crylink_primary_edgedamage") * a, cvar("g_balance_crylink_primary_radius"), world, cvar("g_balance_crylink_primary_force") * a, e.projectiledeathtype, other);

	if(e.queuenext != e2)
		W_Crylink_LinkExplode(e.queuenext, e2);
	remove (e);
}

// NO bounce protection, as bounces are limited!
void W_Crylink_Touch (void)
{
	float finalhit;
	float f;
	//PROJECTILE_TOUCH;
	local entity savenext, saveprev;
	savenext = self.queuenext;
	saveprev = self.queueprev;
	if(WarpZone_Projectile_Touch())
	{
		if(wasfreed(self))
		{
			savenext.queueprev = saveprev;
			saveprev.queuenext = savenext;
		}
		return;
	}

	float a;
	a = bound(0, 1 - (time - self.fade_time) * self.fade_rate, 1);

	finalhit = ((self.cnt <= 0) || (other.takedamage != DAMAGE_NO));
	if(finalhit)
		f = 1;
	else
		f = cvar("g_balance_crylink_primary_bouncedamagefactor");
	if(a)
		f *= a;
	if (RadiusDamage (self, self.realowner, cvar("g_balance_crylink_primary_damage") * f, cvar("g_balance_crylink_primary_edgedamage") * f, cvar("g_balance_crylink_primary_radius"), world, cvar("g_balance_crylink_primary_force") * f, self.projectiledeathtype, other) || finalhit)
	{
		W_Crylink_LinkExplode(self.queuenext, self);
		remove (self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.angles = vectoangles(self.velocity);
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
	// commented out as it causes a little hitch...
	//if(proj.cnt == 0)
	//	CSQCProjectile(proj, TRUE, PROJECTILE_CRYLINK, TRUE);
}

void W_Crylink_Touch2 (void)
{
	float finalhit;
	float f;
	//PROJECTILE_TOUCH;
	local entity savenext, saveprev;
	savenext = self.queuenext;
	saveprev = self.queueprev;
	if(WarpZone_Projectile_Touch())
	{
		if(wasfreed(self))
		{
			savenext.queueprev = saveprev;
			saveprev.queuenext = savenext;
		}
		return;
	}

	float a;
	a = 1 - (time - self.fade_time) * self.fade_rate;

	finalhit = ((self.cnt <= 0) || (other.takedamage != DAMAGE_NO));
	if(finalhit)
		f = 1;
	else
		f = cvar("g_balance_crylink_secondary_bouncedamagefactor");
	if(a)
		f *= a;
	if (RadiusDamage (self, self.realowner, cvar("g_balance_crylink_secondary_damage") * f, cvar("g_balance_crylink_secondary_edgedamage") * f, cvar("g_balance_crylink_secondary_radius"), world, cvar("g_balance_crylink_secondary_force") * f, self.projectiledeathtype, other) || finalhit)
	{
		W_Crylink_LinkExplode(self.queuenext, self);
		remove (self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.angles = vectoangles(self.velocity);
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
	// commented out as it causes a little hitch...
	//if(proj.cnt == 0)
	//	CSQCProjectile(proj, TRUE, PROJECTILE_CRYLINK, TRUE);
}

void W_Crylink_Fadethink (void)
{
	self.queuenext.queueprev = self.queueprev;
	self.queueprev.queuenext = self.queuenext;
	remove(self);
}

void W_Crylink_Attack (void)
{
	local float counter, shots;
	local entity proj, prevproj, firstproj;
	local vector s;
	vector forward, right, up;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - cvar("g_balance_crylink_primary_ammo");

	W_SetupShot (self, FALSE, 2, "weapons/crylink_fire.wav", (cvar("g_balance_crylink_primary_damage")*cvar("g_balance_crylink_primary_shots")));
	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = cvar("g_balance_crylink_primary_shots");
	pointparticles(particleeffectnum("crylink_muzzleflash"), w_shotorg, w_shotdir * 1000, shots);
	while (counter < shots)
	{
		proj = spawn ();
		proj.realowner = proj.owner = self;
		proj.classname = "spike";
		proj.bot_dodge = TRUE;
		proj.bot_dodgerating = cvar("g_balance_crylink_primary_damage");
		if(counter == 0) { // first projectile, store in firstproj for now
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

		proj.movetype = MOVETYPE_BOUNCEMISSILE;
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = WEP_CRYLINK;
		//proj.gravity = 0.001;

		setorigin (proj, w_shotorg);
		setsize(proj, '0 0 0', '0 0 0');


		s = '0 0 0';
		if (counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s_y = v_forward_x;
			s_z = v_forward_y;
		}
		s = s * cvar("g_balance_crylink_primary_spread") * g_weaponspreadfactor;
		W_SetupProjectileVelocityEx(proj, w_shotdir + right * s_y + up * s_z, v_up, cvar("g_balance_crylink_primary_speed"), 0, 0, 0);
		proj.touch = W_Crylink_Touch;

		proj.think = W_Crylink_Fadethink;
		if(counter == 0)
		{
			proj.fade_time = time + cvar("g_balance_crylink_primary_middle_lifetime");
			self.fade_rate = 1 / cvar("g_balance_crylink_primary_middle_fadetime");
			proj.nextthink = time + cvar("g_balance_crylink_primary_middle_lifetime") + cvar("g_balance_crylink_primary_middle_fadetime");
		}
		else if(counter <= 3)
		{
			proj.fade_time = time + cvar("g_balance_crylink_primary_star_lifetime");
			self.fade_rate = 1 / cvar("g_balance_crylink_primary_star_fadetime");
			proj.nextthink = time + cvar("g_balance_crylink_primary_star_lifetime") + cvar("g_balance_crylink_primary_star_fadetime");
		}
		else
		{
			proj.fade_time = time + cvar("g_balance_crylink_primary_other_lifetime");
			self.fade_rate = 1 / cvar("g_balance_crylink_primary_other_fadetime");
			proj.nextthink = time + cvar("g_balance_crylink_primary_other_lifetime") + cvar("g_balance_crylink_primary_other_fadetime");
		}
		proj.cnt = cvar("g_balance_crylink_primary_bounces");
		//proj.scale = 1 + 1 * proj.cnt;

		proj.angles = vectoangles (proj.velocity);

		//proj.glow_size = 20;

		proj.flags = FL_PROJECTILE;

		CSQCProjectile(proj, TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE);

		other = proj; MUTATOR_CALLHOOK(EditProjectile);

		counter = counter + 1;
	}
}

void W_Crylink_Attack2 (void)
{
	local float counter, shots;
	local entity proj, prevproj, firstproj;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - cvar("g_balance_crylink_secondary_ammo");

	W_SetupShot (self, FALSE, 2, "weapons/crylink_fire2.wav", (cvar("g_balance_crylink_secondary_damage")*cvar("g_balance_crylink_secondary_shots")));

	shots = cvar("g_balance_crylink_secondary_shots");
	pointparticles(particleeffectnum("crylink_muzzleflash"), w_shotorg, w_shotdir * 1000, shots);
	while (counter < shots)
	{
		proj = spawn ();
		proj.realowner = proj.owner = self;
		proj.classname = "spike";
		proj.bot_dodge = TRUE;
		proj.bot_dodgerating = cvar("g_balance_crylink_secondary_damage");
		if(counter == 0) { // first projectile, store in firstproj for now
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

		proj.movetype = MOVETYPE_BOUNCEMISSILE;
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = WEP_CRYLINK | HITTYPE_SECONDARY;
		//proj.gravity = 0.001;

		setorigin (proj, w_shotorg);
		setsize(proj, '0 0 0', '0 0 0');

		W_SetupProjectileVelocityEx(proj, (w_shotdir + (((counter + 0.5) / shots) * 2 - 1) * v_right * cvar("g_balance_crylink_secondary_spread") * g_weaponspreadfactor), v_up, cvar("g_balance_crylink_secondary_speed"), 0, 0, 0);
		proj.touch = W_Crylink_Touch2;
		proj.think = W_Crylink_Fadethink;
		if(counter == (shots - 1) / 2)
		{
			proj.fade_time = time + cvar("g_balance_crylink_secondary_middle_lifetime");
			self.fade_rate = 1 / cvar("g_balance_crylink_secondary_middle_fadetime");
			proj.nextthink = time + cvar("g_balance_crylink_secondary_middle_lifetime") + cvar("g_balance_crylink_secondary_middle_fadetime");
		}
		else
		{
			proj.fade_time = time + cvar("g_balance_crylink_secondary_line_lifetime");
			self.fade_rate = 1 / cvar("g_balance_crylink_secondary_line_fadetime");
			proj.nextthink = time + cvar("g_balance_crylink_secondary_line_lifetime") + cvar("g_balance_crylink_secondary_line_fadetime");
		}
		proj.cnt = cvar("g_balance_crylink_secondary_bounces");
		//proj.scale = 1 + 1 * proj.cnt;

		proj.angles = vectoangles (proj.velocity);

		//proj.glow_size = 20;

		proj.flags = FL_PROJECTILE;

		CSQCProjectile(proj, TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE);

		other = proj; MUTATOR_CALLHOOK(EditProjectile);

		counter = counter + 1;
	}
}

void spawnfunc_weapon_crylink (void)
{
	weapon_defaultspawnfunc(WEP_CRYLINK);
}

float w_crylink(float req)
{
	if (req == WR_AIM)
	{
		if (random() > 0.15)
			self.BUTTON_ATCK = bot_aim(cvar("g_balance_crylink_primary_speed"), 0, cvar("g_balance_crylink_primary_middle_lifetime"), FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_crylink_secondary_speed"), 0, cvar("g_balance_crylink_secondary_middle_lifetime"), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, cvar("g_balance_crylink_primary_refire")))
		{
			W_Crylink_Attack();
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_crylink_primary_animtime"), w_ready);
		}
		if (self.BUTTON_ATCK2 && cvar("g_balance_crylink_secondary"))
		if (weapon_prepareattack(1, cvar("g_balance_crylink_secondary_refire")))
		{
			W_Crylink_Attack2();
			weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_crylink_secondary_animtime"), w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_crylink.md3");
		precache_model ("models/weapons/v_crylink.md3");
		precache_model ("models/weapons/h_crylink.iqm");
		precache_sound ("weapons/crylink_fire.wav");
		precache_sound ("weapons/crylink_fire2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_CRYLINK);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= cvar("g_balance_crylink_primary_ammo");
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= cvar("g_balance_crylink_secondary_ammo");
	return TRUE;
};
#endif
#ifdef CSQC
float w_crylink(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 2;
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			pointparticles(particleeffectnum("crylink_impact"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CHAN_PROJECTILE, "weapons/crylink_impact2.wav", VOL_BASE, ATTN_NORM);
		}
		else
		{
			pointparticles(particleeffectnum("crylink_impactbig"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CHAN_PROJECTILE, "weapons/crylink_impact.wav", VOL_BASE, ATTN_NORM);
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/crylink_impact2.wav");
		precache_sound("weapons/crylink_impact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		w_deathtypestring = "%s succeeded at self-destructing themself with the Crylink";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_BOUNCE)
			w_deathtypestring = "%s could not hide from %s's Crylink"; // unchecked: SPLASH (SECONDARY can't be)
		else if(w_deathtype & HITTYPE_SPLASH)
			w_deathtypestring = "%s was too close to %s's Crylink"; // unchecked: SECONDARY
		else
			w_deathtypestring = "%s took a close look at %s's Crylink"; // unchecked: SECONDARY
	}
	return TRUE;
}
#endif
#endif
