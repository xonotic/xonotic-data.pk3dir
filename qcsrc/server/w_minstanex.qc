#ifdef REGISTER_WEAPON
REGISTER_WEAPON(MINSTANEX, w_minstanex, IT_CELLS, 7, WEP_FLAG_HIDDEN | WEP_FLAG_CANCLIMB | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", _("MinstaNex"))
#else
#ifdef SVQC
.float minstanex_lasthit;

// weapon load persistence, for weapons that support reloading
.float minstanex_load;

void W_Minstanex_SetAmmoCounter()
{
	// set clip_load to the weapon we have switched to, if the gun uses reloading
	if(!autocvar_g_balance_minstanex_reload_ammo)
		self.clip_load = 0; // also keeps crosshair ammo from displaying
	else
	{
		self.clip_load = self.minstanex_load;
		self.clip_size = autocvar_g_balance_minstanex_reload_ammo; // for the crosshair ammo display
	}
}

void W_Minstanex_ReloadedAndReady()
{
	float t;

	// now do the ammo transfer
	self.clip_load = self.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading
	while(self.clip_load < autocvar_g_balance_minstanex_reload_ammo && self.ammo_cells) // make sure we don't add more ammo than we have
	{
		self.clip_load += 1;
		self.ammo_cells -= 1;
	}
	self.minstanex_load = self.clip_load;

	t = ATTACK_FINISHED(self) - autocvar_g_balance_minstanex_reload_time - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

void W_Minstanex_Reload()
{
	// return if reloading is disabled for this weapon
	if(!autocvar_g_balance_minstanex_reload_ammo)
		return;

	if(autocvar_g_balance_minstanex_laser_ammo)
	{
		if(!W_ReloadCheck(self.ammo_cells, min(autocvar_g_balance_minstanex_ammo, autocvar_g_balance_minstanex_laser_ammo)))
			return;
	}
	else if(!W_ReloadCheck(self.ammo_cells, autocvar_g_balance_minstanex_ammo))
		return;

	float t;

	sound (self, CHAN_WEAPON2, "weapons/reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_minstanex_reload_time + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_minstanex_reload_time, W_Minstanex_ReloadedAndReady);

	self.old_clip_load = self.clip_load;
	self.clip_load = -1;
}

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 0, "weapons/minstanexfire.wav", CHAN_WEAPON, 10000);

	yoda = 0;
	damage_goodhits = 0;
	headshot = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_MINSTANEX);

	if(g_minstagib)
	{
		if(yoda)
			AnnounceTo(self, "yoda");
	}
	else
	{
		if(yoda && flying)
			AnnounceTo(self, "yoda");
		if(headshot)
		{
			AnnounceTo(self, "headshot");
		}
		if(damage_goodhits && self.minstanex_lasthit)
		{
			if(AnnounceTo(self, "impressive"))
				damage_goodhits = 0; // only every second time
		}
	}

	self.minstanex_lasthit = damage_goodhits;

	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	if(teams_matter)
	{
	    switch(self.team)
	    {
            case COLOR_TEAM1:   // Red
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, v);
                break;
            case COLOR_TEAM2:   // Blue
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, v);
                break;
            case COLOR_TEAM3:   // Yellow
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, v);
                break;
            case COLOR_TEAM4:   // Pink
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, v);
                break;
	    }
	}
	else
        WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, v);

	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, 10000, 0, 0, 800 * w_shotdir, WEP_MINSTANEX, self);

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_minstanex_reload_ammo)
		{
			if (g_minstagib)
				self.clip_load -= - 1;
			else
				self.clip_load -= autocvar_g_balance_minstanex_ammo;
			self.minstanex_load = self.clip_load;
		}
		else
		{
			if (g_minstagib)
				self.ammo_cells -= - 1;
			else
				self.ammo_cells -= autocvar_g_balance_minstanex_ammo;
		}
	}
}


.float minstagib_nextthink;
void minstagib_ammocheck (void)
{
	if (time < self.minstagib_nextthink || self.deadflag || gameover)
		return;

	if (self.ammo_cells <= 0)
	{
		if (self.health == 5)
		{
			centerprint(self, "you're dead now...\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "terminated");
		}
		else if (self.health == 10)
		{
			centerprint(self, "^11^7 second left to find some ammo\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "1");
		}
		else if (self.health == 20)
		{
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "2");
		}
		else if (self.health == 30)
		{
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "3");
		}
		else if (self.health == 40)
		{
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "4");
		}
		else if (self.health == 50)
		{
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "5");
		}
		else if (self.health == 60)
		{
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "6");
		}
		else if (self.health == 70)
		{
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "7");
		}
		else if (self.health == 80)
		{
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "8");
		}
		else if (self.health == 90)
		{
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "9");
		}
		else if (self.health == 100)
		{
			centerprint(self, "get some ammo or\nyou'll be dead in ^310^7 seconds...");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			if not(self.flags & FL_GODMODE)
				AnnounceTo(self, "10");
		}
	}
	self.minstagib_nextthink = time + 1;
}

void spawnfunc_weapon_minstanex (void); // defined in t_items.qc

float minstanex_ammo;
float w_minstanex(float req)
{
	float ammo_amount;
	if (req == WR_AIM)
	{
		if(self.ammo_cells > 0)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		if(g_minstagib)
			minstanex_ammo = 1;
		else
			minstanex_ammo = autocvar_g_balance_minstanex_ammo;

		// if the laser uses load, we also consider its ammo for reloading
		if(autocvar_g_balance_minstanex_reload_ammo && autocvar_g_balance_minstanex_laser_ammo && self.clip_load < min(minstanex_ammo, autocvar_g_balance_minstanex_laser_ammo)) // forced reload
			W_Minstanex_Reload();
		else if(autocvar_g_balance_minstanex_reload_ammo && self.clip_load < minstanex_ammo) // forced reload
			W_Minstanex_Reload();
		else if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, autocvar_g_balance_minstanex_refire))
			{
				W_MinstaNex_Attack();
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_minstanex_animtime, w_ready);
			}
		}
		else if (self.BUTTON_ATCK2)
		{
			if (self.jump_interval <= time)
			{
				self.jump_interval = time + autocvar_g_balance_laser_primary_refire * W_WeaponRateFactor();

				// decrease ammo for the laser?
				if(autocvar_g_balance_minstanex_laser_ammo)
				{
					if(autocvar_g_balance_minstanex_reload_ammo)
						self.clip_load -= autocvar_g_balance_minstanex_laser_ammo;
					else
						self.ammo_cells -= autocvar_g_balance_minstanex_laser_ammo;
				}

				// ugly minstagib hack to reuse the fire mode of the laser
				float w;
				w = self.weapon;
				self.weapon = WEP_LASER;
				W_Laser_Attack(2);
				self.weapon = w;
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_model ("models/weapons/g_minstanex.md3");
		precache_model ("models/weapons/v_minstanex.md3");
		precache_model ("models/weapons/h_minstanex.iqm");
		precache_sound ("weapons/minstanexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
		precache_sound ("weapons/reload.wav");
		w_laser(WR_PRECACHE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		W_Minstanex_SetAmmoCounter();
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		ammo_amount = self.ammo_cells >= autocvar_g_balance_minstanex_ammo;
		ammo_amount += self.minstanex_load >= autocvar_g_balance_minstanex_ammo;
		return ammo_amount;
	}
	else if (req == WR_CHECKAMMO2)
	{
		if(!autocvar_g_balance_minstanex_laser_ammo)
			return TRUE;
		ammo_amount = self.ammo_cells >= autocvar_g_balance_minstanex_laser_ammo;
		ammo_amount += self.minstanex_load >= autocvar_g_balance_minstanex_laser_ammo;
		return ammo_amount;
	}
	else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;

		// all weapons must be fully loaded when we spawn
		self.minstanex_load = autocvar_g_balance_minstanex_reload_ammo;
	}
	else if (req == WR_RELOAD)
	{
		W_Minstanex_Reload();
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_minstanex(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
		if(!w_issilent)
			sound(self, CHAN_PROJECTILE, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/neximpact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = _("%s did the impossible");
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = _("%s has been vaporized by %s");
	return TRUE;
}
#endif
#endif
