#ifdef REGISTER_WEAPON
REGISTER_WEAPON(NEX, w_nex, IT_CELLS, 7, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_HIGH, "nex", "nex", "Nex");
#else
#ifdef SVQC
void SendCSQCNexBeamParticle(float charge) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_NEXGUNBEAMPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg_x);
	WriteCoord(MSG_BROADCAST, w_shotorg_y);
	WriteCoord(MSG_BROADCAST, w_shotorg_z);
	WriteCoord(MSG_BROADCAST, v_x);
	WriteCoord(MSG_BROADCAST, v_y);
	WriteCoord(MSG_BROADCAST, v_z);
	WriteByte(MSG_BROADCAST, bound(0, 255 * charge, 255));
}

void W_Nex_Attack (float issecondary)
{
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;
	if(issecondary)
	{
		mydmg = cvar("g_balance_nex_secondary_damage");
		myforce = cvar("g_balance_nex_secondary_force");
		mymindist = cvar("g_balance_nex_secondary_damagefalloff_mindist");
		mymaxdist = cvar("g_balance_nex_secondary_damagefalloff_maxdist");
		myhalflife = cvar("g_balance_nex_secondary_damagefalloff_halflife");
		myforcehalflife = cvar("g_balance_nex_secondary_damagefalloff_forcehalflife");
		myammo = cvar("g_balance_nex_secondary_ammo");
	}
	else
	{
		mydmg = cvar("g_balance_nex_primary_damage");
		myforce = cvar("g_balance_nex_primary_force");
		mymindist = cvar("g_balance_nex_primary_damagefalloff_mindist");
		mymaxdist = cvar("g_balance_nex_primary_damagefalloff_maxdist");
		myhalflife = cvar("g_balance_nex_primary_damagefalloff_halflife");
		myforcehalflife = cvar("g_balance_nex_primary_damagefalloff_forcehalflife");
		myammo = cvar("g_balance_nex_primary_ammo");
	}

	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(cvar("g_balance_nex_charge"))
	{
		charge = cvar("g_balance_nex_charge_mindmg") / mydmg + (1 - cvar("g_balance_nex_charge_mindmg") / mydmg) * self.nex_charge;
		self.nex_charge *= cvar("g_balance_nex_charge_shot_multiplier"); // do this AFTER setting mydmg/myforce
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot (self, TRUE, 5, "weapons/nexfire.wav", mydmg);

	yoda = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, WEP_NEX);

	if(yoda && flying)
		AnnounceTo(self, "yoda");

	//beam and muzzle flash done on client
	SendCSQCNexBeamParticle(charge);
	
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, mydmg, 0, 0, myforce * w_shotdir, WEP_NEX, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - myammo;
}

void spawnfunc_weapon_nex (void); // defined in t_items.qc

float w_nex(float req)
{
	float dt;
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		self.BUTTON_ATCK2 = bot_aim(1000000, 0, 1, FALSE);
	}
	else if (req == WR_THINK)
	{
		if(cvar("g_balance_nex_charge") && self.nex_charge < cvar("g_balance_nex_charge_limit"))
			self.nex_charge = min(1, self.nex_charge + cvar("g_balance_nex_charge_rate") * frametime / W_TICSPERFRAME);
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, cvar("g_balance_nex_primary_refire")))
			{
				W_Nex_Attack(0);
				weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_nex_primary_animtime"), w_ready);
			}
		}
		if (self.BUTTON_ATCK2)
		{
			if(cvar("g_balance_nex_secondary_charge"))
			{
				dt = frametime / W_TICSPERFRAME;
				if(self.nex_charge < 1)
				{
					dt = min(dt, (1 - self.nex_charge) / cvar("g_balance_nex_secondary_charge_rate"));
					if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
					{
						if(cvar("g_balance_nex_secondary_ammo"))
						{
							dt = min(dt, (self.ammo_cells - cvar("g_balance_nex_primary_ammo")) / cvar("g_balance_nex_secondary_ammo"));
							dt = max(0, dt);
							if(dt > 0)
							{
								self.ammo_cells = max(cvar("g_balance_nex_secondary_ammo"), self.ammo_cells - cvar("g_balance_nex_secondary_ammo") * dt);
							}
						}
					}
					self.nex_charge += dt * cvar("g_balance_nex_secondary_charge_rate");
				}
			}
			else if(cvar("g_balance_nex_secondary"))
			{
				if (weapon_prepareattack(0, cvar("g_balance_nex_secondary_refire")))
				{
					W_Nex_Attack(1);
					weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_nex_secondary_animtime"), w_ready);
				}
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_model ("models/weapons/g_nex.md3");
		precache_model ("models/weapons/v_nex.md3");
		precache_model ("models/weapons/h_nex.iqm");
		precache_sound ("weapons/nexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_NEX);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= cvar("g_balance_nex_primary_ammo");
	else if (req == WR_CHECKAMMO2)
	{
		if(cvar("g_balance_nex_secondary_charge"))
			return self.ammo_cells >= cvar("g_balance_nex_primary_ammo");
		return self.ammo_cells >= cvar("g_balance_nex_secondary_ammo");
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_nex(float req)
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
		w_deathtypestring = "%s did the impossible";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "%s has been vaporized by %s";
	return TRUE;
}
#endif
#endif
