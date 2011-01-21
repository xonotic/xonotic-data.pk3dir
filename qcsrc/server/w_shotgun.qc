#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SHOTGUN, w_shotgun, IT_SHELLS, 2, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", _("Shotgun"))
#else
#ifdef SVQC

.float shotgun_load;

void W_Shotgun_SetAmmoCounter()
{
	// set ammo_counter to the weapon we have switched to, if the gun uses reloading
	if(!autocvar_g_balance_shotgun_reload_ammo)
		self.ammo_counter = 0; // also keeps crosshair ammo from displaying
	else
		self.ammo_counter = self.shotgun_load;
}

void W_Shotgun_ReloadedAndReady()
{
	float t;

	// now do the ammo transfer
	self.ammo_counter = self.old_ammo_counter; // restore the ammo counter, in case we still had ammo in the weapon before reloading
	while(self.ammo_counter < autocvar_g_balance_shotgun_reload_ammo && self.ammo_shells) // make sure we don't add more ammo than we have
	{
		self.ammo_counter += 1;
		self.ammo_shells -= 1;
	}
	self.shotgun_load = self.ammo_counter;

	t = ATTACK_FINISHED(self) - autocvar_g_balance_shotgun_reload_time - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

void W_Shotgun_Reload()
{
	// return if reloading is disabled for this weapon
	if(!autocvar_g_balance_shotgun_reload_ammo)
		return;

	if(!W_ReloadCheck(self.ammo_shells))
		return;

	float t;

	sound (self, CHAN_WEAPON2, "weapons/reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_shotgun_reload_time + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_shotgun_reload_time, W_Shotgun_ReloadedAndReady);

	self.old_ammo_counter = self.ammo_counter;
	self.ammo_counter = -1;
}

void W_Shotgun_Attack (void)
{
	float	sc;
	float	ammoamount;
	float	bullets;
	float	d;
	float	f;
	float	spread;
	float	bulletspeed;
	float	bulletconstant;
	local entity flash;

	if(autocvar_g_balance_shotgun_reload_ammo && self.ammo_counter <= 0)
		return; // reloading, so we are done

	ammoamount = autocvar_g_balance_shotgun_primary_ammo;
	bullets = autocvar_g_balance_shotgun_primary_bullets;
	d = autocvar_g_balance_shotgun_primary_damage;
	f = autocvar_g_balance_shotgun_primary_force;
	spread = autocvar_g_balance_shotgun_primary_spread;
	bulletspeed = autocvar_g_balance_shotgun_primary_speed;
	bulletconstant = autocvar_g_balance_shotgun_primary_bulletconstant;

	W_SetupShot (self, autocvar_g_antilag_bullets && bulletspeed >= autocvar_g_antilag_bullets, 5, "weapons/shotgun_fire.wav", CHAN_WEAPON, d * bullets);
	for (sc = 0;sc < bullets;sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, spread, bulletspeed, 5, d, 0, f, WEP_SHOTGUN, 0, 1, bulletconstant);
	endFireBallisticBullet();

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg, w_shotdir * 1000, autocvar_g_balance_shotgun_primary_ammo);

	// casing code
	if (autocvar_g_casings >= 1)
		for (sc = 0;sc < ammoamount;sc = sc + 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(!autocvar_g_balance_shotgun_reload_ammo)
			self.ammo_shells -= ammoamount;
		else
		{
			self.ammo_counter -= ammoamount;
			self.shotgun_load = self.ammo_counter;
		}
	}
}

void shotgun_meleethink (void)
{
	// store time when we started swinging down inside self.cnt
	if(!self.cnt)
		self.cnt = time;

	makevectors(self.owner.v_angle);
	vector angle;
	angle = v_forward;

	float meleetime;
	meleetime = autocvar_g_balance_shotgun_secondary_melee_time * W_WeaponRateFactor();

	// perform trace
	float f;
	f = (self.cnt + meleetime - time) / meleetime * 2 - 1;
	vector targpos;
	targpos = self.owner.origin + self.owner.view_ofs + angle * autocvar_g_balance_shotgun_secondary_melee_range + v_right * f * autocvar_g_balance_shotgun_secondary_melee_swing + v_up * f * autocvar_g_balance_shotgun_secondary_melee_swing;

	WarpZone_traceline_antilag(self.owner, self.owner.origin + self.owner.view_ofs, targpos, FALSE, self.owner, ANTILAG_LATENCY(self.owner));

	// apply the damage, also remove self
	if(trace_fraction < 1 && trace_ent.takedamage == DAMAGE_AIM && (trace_ent.classname == "player" || trace_ent.classname == "body"))
	{
		vector force;
		force = angle * autocvar_g_balance_shotgun_secondary_force;
		if(accuracy_isgooddamage(self.owner, trace_ent))
			accuracy_add(self.owner, WEP_SHOTGUN, 0, autocvar_g_balance_shotgun_secondary_damage * min(1, f + 1));
		Damage (trace_ent, self.owner, self.owner, autocvar_g_balance_shotgun_secondary_damage * min(1, f + 1), WEP_SHOTGUN | HITTYPE_SECONDARY , self.owner.origin + self.owner.view_ofs, force);
		remove(self);
	}
	else if(time >= self.cnt + meleetime) // missed, remove ent
		remove(self);
	else // continue swinging the weapon in hope of hitting someone :)
		self.nextthink = time;
}

void W_Shotgun_Attack2 (void)
{
	sound (self, CHAN_PROJECTILE, "weapons/shotgun_melee.wav", VOL_BASE, ATTN_NORM);
	weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_shotgun_secondary_animtime, w_ready);

	entity meleetemp;
	meleetemp = spawn();
	meleetemp.owner = self;
	meleetemp.think = shotgun_meleethink;
	meleetemp.nextthink = time + autocvar_g_balance_shotgun_secondary_melee_delay;
	W_SetupShot_Range(self, TRUE, 0, "", 0, autocvar_g_balance_shotgun_secondary_damage, autocvar_g_balance_shotgun_secondary_melee_range);
}

void spawnfunc_weapon_shotgun(); // defined in t_items.qc

.float shotgun_primarytime;

float w_shotgun(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin) <= autocvar_g_balance_shotgun_secondary_melee_range)
			self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_shotgun_reload_ammo && self.ammo_counter <= 0) // forced reload
			W_Shotgun_Reload();
		else
		{
			if (self.BUTTON_ATCK)
			{
				if (time >= self.shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
				{
					if(weapon_prepareattack(0, autocvar_g_balance_shotgun_primary_animtime))
					{
						W_Shotgun_Attack();
						self.shotgun_primarytime = time + autocvar_g_balance_shotgun_primary_refire;
						weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_shotgun_primary_animtime, w_ready);
					}
				}
			}
			if (self.BUTTON_ATCK2 && autocvar_g_balance_shotgun_secondary)
			if (weapon_prepareattack(1, autocvar_g_balance_shotgun_secondary_refire))
			{
				// attempt forcing playback of the anim by switching to another anim (that we never play) here...
				weapon_thinkf(WFRAME_FIRE1, 0, W_Shotgun_Attack2);
			}
		}
        if(self.wish_reload)
        {
            if(self.switchweapon == self.weapon)
            {
                if(self.weaponentity.state == WS_READY)
                {
                    self.wish_reload = 0;
                    W_Shotgun_Reload();
                }
            }
        }
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_model ("models/weapons/g_shotgun.md3");
		precache_model ("models/weapons/v_shotgun.md3");
		precache_model ("models/weapons/h_shotgun.iqm");
		precache_sound ("misc/itempickup.wav");
		precache_sound ("weapons/shotgun_fire.wav");
		precache_sound ("weapons/shotgun_melee.wav");
		precache_sound ("weapons/reload.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_SHOTGUN);
		W_Shotgun_SetAmmoCounter();
	}
	else if (req == WR_CHECKAMMO1)
	{
		if(autocvar_g_balance_shotgun_reload_ammo)
			return self.shotgun_load >= autocvar_g_balance_shotgun_primary_ammo;
		else
			return self.ammo_shells >= autocvar_g_balance_shotgun_primary_ammo;
	}
	else if (req == WR_CHECKAMMO2)
	{
		return TRUE;
	}
	else if (req == WR_RELOAD)
	{
		W_Shotgun_Reload();
	}
	return TRUE;
};
#endif
#ifdef CSQC
.float prevric;
float w_shotgun(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 2;
		pointparticles(particleeffectnum("shotgun_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent && time - self.prevric > 0.25)
		{
			if(w_random < 0.0165)
				sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.033)
				sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.05)
				sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
			self.prevric = time;
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/ric1.wav");
		precache_sound("weapons/ric2.wav");
		precache_sound("weapons/ric3.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s did the impossible";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%2$s ^7slapped %1$s ^7around a bit with a large ^2shotgun";
		else
			w_deathtypestring = "%s was gunned by %s";
	}
	return TRUE;
}
#endif
#endif
