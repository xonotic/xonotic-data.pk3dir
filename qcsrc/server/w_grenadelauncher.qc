#ifdef REGISTER_WEAPON
REGISTER_WEAPON(GRENADE_LAUNCHER, w_glauncher, IT_ROCKETS, 4, WEP_FLAG_NORMAL | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "gl", "grenadelauncher", _("Mortar"))
#else
#ifdef SVQC
.float gl_detonate_later;
.float gl_bouncecnt;

.float grenadelauncher_load;

void W_GrenadeLauncher_SetAmmoCounter()
{
	// set clip_load to the weapon we have switched to, if the gun uses reloading
	if(!autocvar_g_balance_grenadelauncher_reload_ammo)
		self.clip_load = 0; // also keeps crosshair ammo from displaying
	else
	{
		self.clip_load = self.grenadelauncher_load;
		self.clip_size = autocvar_g_balance_grenadelauncher_reload_ammo; // for the crosshair ammo display
	}
}

void W_GrenadeLauncher_ReloadedAndReady()
{
	float t;

	// now do the ammo transfer
	self.clip_load = self.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading
	while(self.clip_load < autocvar_g_balance_grenadelauncher_reload_ammo && self.ammo_rockets) // make sure we don't add more ammo than we have
	{
		self.clip_load += 1;
		self.ammo_rockets -= 1;
	}
	self.grenadelauncher_load = self.clip_load;

	t = ATTACK_FINISHED(self) - autocvar_g_balance_grenadelauncher_reload_time - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

void W_GrenadeLauncher_Reload()
{
	// return if reloading is disabled for this weapon
	if(!autocvar_g_balance_grenadelauncher_reload_ammo)
		return;

	if(!W_ReloadCheck(self.ammo_rockets))
		return;

	float t;

	sound (self, CHAN_WEAPON2, "weapons/reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_grenadelauncher_reload_time + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_grenadelauncher_reload_time, W_GrenadeLauncher_ReloadedAndReady);

	self.old_clip_load = self.clip_load;
	self.clip_load = -1;
}

void W_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						AnnounceTo(self.owner, "airshot");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.owner, autocvar_g_balance_grenadelauncher_primary_damage, autocvar_g_balance_grenadelauncher_primary_edgedamage, autocvar_g_balance_grenadelauncher_primary_radius, world, autocvar_g_balance_grenadelauncher_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Explode2 (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(IsFlying(other))
					AnnounceTo(self.owner, "airshot");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.owner, autocvar_g_balance_grenadelauncher_secondary_damage, autocvar_g_balance_grenadelauncher_secondary_edgedamage, autocvar_g_balance_grenadelauncher_secondary_radius, world, autocvar_g_balance_grenadelauncher_secondary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		W_PrepareExplosionByDamage(attacker, self.think);
	}
}

void W_Grenade_Think1 (void)
{
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Grenade_Explode ();
		return;
	}
	if(self.gl_detonate_later && self.gl_bouncecnt >= autocvar_g_balance_grenadelauncher_primary_remote_minbouncecnt)
		W_Grenade_Explode();
}

void W_Grenade_Touch1 (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM || autocvar_g_balance_grenadelauncher_primary_type == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		self.use ();
	}
	else if (autocvar_g_balance_grenadelauncher_primary_type == 1) // bounce
	{
		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		self.gl_bouncecnt += 1;
	}
	else if(autocvar_g_balance_grenadelauncher_primary_type == 2 && (!other || (other.takedamage != DAMAGE_AIM && other.movetype == MOVETYPE_NONE))) // stick
	{
		spamsound (self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		self.oldvelocity = self.velocity;
		self.velocity = '0 0 0';
		self.movetype = MOVETYPE_NONE; // also disables gravity
		self.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(self);

		// do not respond to any more touches
		self.solid = SOLID_NOT;

		self.nextthink = min(self.nextthink, time + autocvar_g_balance_grenadelauncher_primary_lifetime2);
	}
}

void W_Grenade_Touch2 (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM || autocvar_g_balance_grenadelauncher_secondary_type == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		self.use ();
	}
	else if (autocvar_g_balance_grenadelauncher_secondary_type == 1) // bounce
	{
		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		self.gl_bouncecnt += 1;
	}
	else if(autocvar_g_balance_grenadelauncher_secondary_type == 2 && (!other || (other.takedamage != DAMAGE_AIM && other.movetype == MOVETYPE_NONE))) // stick
	{
		spamsound (self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		self.oldvelocity = self.velocity;
		self.velocity = '0 0 0';
		self.movetype = MOVETYPE_NONE; // also disables gravity
		self.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(self);

		// do not respond to any more touches
		self.solid = SOLID_NOT;

		self.nextthink = min(self.nextthink, time + autocvar_g_balance_grenadelauncher_secondary_lifetime2);
	}
}

void W_Grenade_Attack (void)
{
	if(autocvar_g_balance_grenadelauncher_reload_ammo && self.clip_load <= 0)
		return; // reloading, so we are done

	local entity gren;

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 4, "weapons/grenade_fire.wav", CHAN_WEAPON, autocvar_g_balance_grenadelauncher_primary_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = self;
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = autocvar_g_balance_grenadelauncher_primary_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	gren.bouncefactor = autocvar_g_balance_grenadelauncher_bouncefactor;
	gren.bouncestop = autocvar_g_balance_grenadelauncher_bouncestop;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.cnt = time + autocvar_g_balance_grenadelauncher_primary_lifetime;
	gren.nextthink = time;
	gren.think = W_Grenade_Think1;
	gren.use = W_Grenade_Explode;
	gren.touch = W_Grenade_Touch1;

	gren.takedamage = DAMAGE_YES;
	gren.health = autocvar_g_balance_grenadelauncher_primary_health;
	gren.damageforcescale = autocvar_g_balance_grenadelauncher_primary_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	W_SETUPPROJECTILEVELOCITY_UP(gren, g_balance_grenadelauncher_primary);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	if(autocvar_g_balance_grenadelauncher_primary_type == 0 || autocvar_g_balance_grenadelauncher_primary_type == 2)
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
	else
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);

	other = gren; MUTATOR_CALLHOOK(EditProjectile);

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_grenadelauncher_reload_ammo)
		{
			self.clip_load -= autocvar_g_balance_grenadelauncher_primary_ammo;
			self.grenadelauncher_load = self.clip_load;
		}
		else
			self.ammo_rockets -= autocvar_g_balance_grenadelauncher_primary_ammo;
	}
}

void W_Grenade_Attack2 (void)
{
	local entity gren;

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 4, "weapons/grenade_fire.wav", CHAN_WEAPON, autocvar_g_balance_grenadelauncher_secondary_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = self;
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = autocvar_g_balance_grenadelauncher_secondary_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	gren.bouncefactor = autocvar_g_balance_grenadelauncher_bouncefactor;
	gren.bouncestop = autocvar_g_balance_grenadelauncher_bouncestop;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.nextthink = time + autocvar_g_balance_grenadelauncher_secondary_lifetime;
	gren.think = adaptor_think2use_hittype_splash;
	gren.use = W_Grenade_Explode2;
	gren.touch = W_Grenade_Touch2;

	gren.takedamage = DAMAGE_YES;
	gren.health = autocvar_g_balance_grenadelauncher_secondary_health;
	gren.damageforcescale = autocvar_g_balance_grenadelauncher_secondary_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	W_SETUPPROJECTILEVELOCITY_UP(gren, g_balance_grenadelauncher_secondary);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	if(autocvar_g_balance_grenadelauncher_secondary_type == 0 || autocvar_g_balance_grenadelauncher_secondary_type == 2)
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
	else
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);

	other = gren; MUTATOR_CALLHOOK(EditProjectile);

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_grenadelauncher_reload_ammo)
		{
			self.clip_load -= autocvar_g_balance_grenadelauncher_secondary_ammo;
			self.grenadelauncher_load = self.clip_load;
		}
		else
			self.ammo_rockets -= autocvar_g_balance_grenadelauncher_secondary_ammo;
	}
}

void spawnfunc_weapon_grenadelauncher (void)
{
	weapon_defaultspawnfunc(WEP_GRENADE_LAUNCHER);
}

.float bot_secondary_grenademooth;
float w_glauncher(float req)
{
	entity nade;
	float nadefound;

	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if (self.bot_secondary_grenademooth == 0)
		{
			if(bot_aim(autocvar_g_balance_grenadelauncher_primary_speed, autocvar_g_balance_grenadelauncher_primary_speed_up, autocvar_g_balance_grenadelauncher_primary_lifetime, TRUE))
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.01) self.bot_secondary_grenademooth = 1;
			}
		}
		else
		{
			if(bot_aim(autocvar_g_balance_grenadelauncher_secondary_speed, autocvar_g_balance_grenadelauncher_secondary_speed_up, autocvar_g_balance_grenadelauncher_secondary_lifetime, TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < 0.02) self.bot_secondary_grenademooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_grenadelauncher_reload_ammo && self.clip_load < min(autocvar_g_balance_grenadelauncher_primary_ammo, autocvar_g_balance_grenadelauncher_secondary_ammo)) // forced reload
			W_GrenadeLauncher_Reload();
		else if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, autocvar_g_balance_grenadelauncher_primary_refire))
			{
				W_Grenade_Attack();
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_grenadelauncher_primary_animtime, w_ready);
			}
		}
		else if (self.BUTTON_ATCK2)
		{
			if (cvar("g_balance_grenadelauncher_secondary_remote_detonateprimary"))
			{
				nadefound = 0;
				for(nade = world; (nade = find(nade, classname, "grenade")); ) if(nade.owner == self)
				{
					if(!nade.gl_detonate_later)
					{
						nade.gl_detonate_later = TRUE;
						nadefound = 1;
					}
				}
				if(nadefound)
					sound (self, CHAN_WEAPON2, "weapons/rocket_det.wav", VOL_BASE, ATTN_NORM);
			}
			else if (weapon_prepareattack(1, autocvar_g_balance_grenadelauncher_secondary_refire))
			{
				W_Grenade_Attack2();
				weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_grenadelauncher_secondary_animtime, w_ready);
			}
		}
        if(self.wish_reload)
        {
            if(self.switchweapon == self.weapon)
            {
                if(self.weaponentity.state == WS_READY)
                {
                    self.wish_reload = 0;
                    W_GrenadeLauncher_Reload();
                }
            }
        }
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_gl.md3");
		precache_model ("models/weapons/v_gl.md3");
		precache_model ("models/weapons/h_gl.iqm");
		precache_sound ("weapons/grenade_bounce1.wav");
		precache_sound ("weapons/grenade_bounce2.wav");
		precache_sound ("weapons/grenade_bounce3.wav");
		precache_sound ("weapons/grenade_bounce4.wav");
		precache_sound ("weapons/grenade_bounce5.wav");
		precache_sound ("weapons/grenade_bounce6.wav");
		precache_sound ("weapons/grenade_stick.wav");
		precache_sound ("weapons/grenade_fire.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_GRENADE_LAUNCHER);
		W_GrenadeLauncher_SetAmmoCounter();
	}
	else if (req == WR_CHECKAMMO1)
	{
		if(autocvar_g_balance_grenadelauncher_reload_ammo)
			return self.grenadelauncher_load >= autocvar_g_balance_grenadelauncher_primary_ammo;
		else
			return self.ammo_rockets >= autocvar_g_balance_grenadelauncher_primary_ammo;
	}
	else if (req == WR_CHECKAMMO2)
	{
		if(autocvar_g_balance_grenadelauncher_reload_ammo)
			return self.grenadelauncher_load >= autocvar_g_balance_grenadelauncher_secondary_ammo;
		else
			return self.ammo_rockets >= autocvar_g_balance_grenadelauncher_secondary_ammo;
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_glauncher(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 12;
		pointparticles(particleeffectnum("grenade_explode"), org2, '0 0 0', 1);
		if(!w_issilent)
			sound(self, CHAN_PROJECTILE, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/grenade_impact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%s tried out his own grenade";
		else
			w_deathtypestring = "%s detonated";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SPLASH)
			if(w_deathtype & HITTYPE_BOUNCE) // (must be secondary then)
				w_deathtypestring = "%s didn't see %s's grenade";
			else // unchecked: SECONDARY
				w_deathtypestring = "%s almost dodged %s's grenade";
		else // unchecked: SECONDARY, BOUNCE
			w_deathtypestring = "%s ate %s's grenade";
	}
	else if (req == WR_RELOAD)
	{
		W_GrenadeLauncher_Reload();
	}
	return TRUE;
}
#endif
#endif
