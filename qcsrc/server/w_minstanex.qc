#ifdef REGISTER_WEAPON
REGISTER_WEAPON(MINSTANEX, w_minstanex, IT_CELLS, 7, WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_FLAG_SUPERWEAPON | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", _("MinstaNex"))
#else
#ifdef SVQC
.float minstanex_lasthit;
.float jump_interval;

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 0, "weapons/minstanexfire.wav", CH_WEAPON_A, 10000);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_MINSTANEX);

	if(g_minstagib)
	{
		if(yoda)
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	}
	else
	{
		if(yoda && flying)
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
		if(damage_goodhits && self.minstanex_lasthit)
		{
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
			damage_goodhits = 0; // only every second time
		}
	}

	self.minstanex_lasthit = damage_goodhits;

	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	if(teamplay)
	{
	    switch(self.team)
	    {
            case NUM_TEAM_1:   // Red
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, v);
                break;
            case NUM_TEAM_2:   // Blue
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, v);
                break;
            case NUM_TEAM_3:   // Yellow
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, v);
                break;
            case NUM_TEAM_4:   // Pink
                if(damage_goodhits)
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, v);
                else
                    WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, v);
                break;
	    }
	}
	else
        WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, v);

	if (g_minstagib)
		W_DecreaseAmmo(ammo_cells, 1, autocvar_g_balance_minstanex_reload_ammo);
	else
		W_DecreaseAmmo(ammo_cells, autocvar_g_balance_minstanex_ammo, autocvar_g_balance_minstanex_reload_ammo);
}


.float minstagib_nextthink;
.float minstagib_needammo;
void minstagib_stop_countdown(entity e)
{
	if (!e.minstagib_needammo)
		return;
	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER_CPID, CPID_MINSTA_FINDAMMO);
	e.minstagib_needammo = FALSE;
}
void minstagib_ammocheck(void)
{
	if (time < self.minstagib_nextthink)
		return;

	if (self.deadflag || gameover || (self.flags & FL_GODMODE))
		minstagib_stop_countdown(self);
	else if (self.ammo_cells > 0 || (self.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		if (self.minstagib_needammo)
			self.health = 100;
		minstagib_stop_countdown(self);
	}
	else
	{
		self.minstagib_needammo = TRUE;
		if (self.health == 5)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_MINSTAGIB_TERMINATED);
		}
		else if (self.health == 10)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_1);
		}
		else if (self.health == 20)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_2);
		}
		else if (self.health == 30)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_3);
		}
		else if (self.health == 40)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_4);
		}
		else if (self.health == 50)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_5);
		}
		else if (self.health == 60)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_6);
		}
		else if (self.health == 70)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_7);
		}
		else if (self.health == 80)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_8);
		}
		else if (self.health == 90)
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_MINSTA_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_9);
		}
		else if (self.health == 100)
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_MULTI, MULTI_MINSTA_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
		}
	}
	self.minstagib_nextthink = time + 1;
}

void spawnfunc_weapon_minstanex (void); // defined in t_items.qc

float w_minstanex(float req)
{
	float ammo_amount;
	float minstanex_ammo;

	// now multiple WR_s use this
	if(g_minstagib)
		minstanex_ammo = 1;
	else
		minstanex_ammo = autocvar_g_balance_minstanex_ammo;

	if (req == WR_AIM)
	{
		if(self.ammo_cells > 0)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		// if the laser uses load, we also consider its ammo for reloading
		if(autocvar_g_balance_minstanex_reload_ammo && autocvar_g_balance_minstanex_laser_ammo && self.clip_load < min(minstanex_ammo, autocvar_g_balance_minstanex_laser_ammo)) // forced reload
			weapon_action(self.weapon, WR_RELOAD);
		else if(autocvar_g_balance_minstanex_reload_ammo && self.clip_load < minstanex_ammo) // forced reload
			weapon_action(self.weapon, WR_RELOAD);
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
			if (weapon_prepareattack(1, -1))
			{
				// handle refire manually, so that primary and secondary can be fired without conflictions (important for minstagib)
				self.jump_interval = time + autocvar_g_balance_minstanex_laser_refire * W_WeaponRateFactor();
				
				// decrease ammo for the laser?
				if(autocvar_g_balance_minstanex_laser_ammo)
					W_DecreaseAmmo(ammo_cells, autocvar_g_balance_minstanex_laser_ammo, autocvar_g_balance_minstanex_reload_ammo);

				// ugly minstagib hack to reuse the fire mode of the laser
				float w;
				w = self.weapon;
				self.weapon = WEP_LASER;
				W_Laser_Attack(2);
				self.weapon = w;
				
				// now do normal refire
				weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_minstanex_laser_animtime, w_ready);
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
		//precache_sound ("weapons/reload.wav"); // until weapons have individual reload sounds, precache the reload sound somewhere else
		w_laser(WR_PRECACHE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		self.current_ammo = ammo_cells;
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		ammo_amount = self.ammo_cells >= minstanex_ammo;
		ammo_amount += self.(weapon_load[WEP_MINSTANEX]) >= minstanex_ammo;
		return ammo_amount;
	}
	else if (req == WR_CHECKAMMO2)
	{
		if(!autocvar_g_balance_minstanex_laser_ammo)
			return TRUE;
		ammo_amount = self.ammo_cells >= autocvar_g_balance_minstanex_laser_ammo;
		ammo_amount += self.(weapon_load[WEP_MINSTANEX]) >= autocvar_g_balance_minstanex_laser_ammo;
		return ammo_amount;
	}
	else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_RELOAD)
	{
		float used_ammo;
		if(autocvar_g_balance_minstanex_laser_ammo)
			used_ammo = min(minstanex_ammo, autocvar_g_balance_minstanex_laser_ammo);
		else
			used_ammo = minstanex_ammo;

		W_Reload(used_ammo, autocvar_g_balance_minstanex_reload_ammo, autocvar_g_balance_minstanex_reload_time, "weapons/reload.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		return WEAPON_THINKING_WITH_PORTALS;
	}
	else if (req == WR_KILLMESSAGE)
	{
		return WEAPON_MINSTANEX_MURDER;
	}
	return TRUE;
}
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
			sound(self, CH_SHOTS, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/neximpact.wav");
	}
	return TRUE;
}
#endif
#endif
