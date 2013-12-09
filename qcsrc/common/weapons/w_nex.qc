#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ NEX,
/* function */ w_nex,
/* ammotype */ IT_CELLS,
/* impulse  */ 7,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN,
/* rating   */ BOT_PICKUP_RATING_HIGH,
/* model    */ "nex",
/* netname  */ "nex",
/* fullname */ _("Nex")
);

#define NEX_SETTINGS(w_cvar,w_prop) \
	w_cvar(WEP_NEX, nex, MO_BOTH, ammo) \
	w_cvar(WEP_NEX, nex, MO_BOTH, animtime) \
	w_cvar(WEP_NEX, nex, MO_BOTH, damage) \
	w_cvar(WEP_NEX, nex, MO_BOTH, force) \
	w_cvar(WEP_NEX, nex, MO_BOTH, damagefalloff_mindist) \
	w_cvar(WEP_NEX, nex, MO_BOTH, damagefalloff_maxdist) \
	w_cvar(WEP_NEX, nex, MO_BOTH, damagefalloff_halflife) \
	w_cvar(WEP_NEX, nex, MO_BOTH, damagefalloff_forcehalflife) \
	w_cvar(WEP_NEX, nex, MO_BOTH, refire) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_mindmg) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_shot_multiplier) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_animlimit) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_limit) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_rate) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_rot_rate) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_rot_pause) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_start) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_minspeed) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_maxspeed) \
	w_cvar(WEP_NEX, nex, MO_NONE, charge_velocity_rate) \
	w_cvar(WEP_NEX, nex, MO_NONE, secondary) \
	w_cvar(WEP_NEX, nex, MO_SEC,  chargepool) \
	w_cvar(WEP_NEX, nex, MO_SEC,  chargepool_regen) \
	w_cvar(WEP_NEX, nex, MO_SEC,  chargepool_pause_regen) \
	w_prop(WEP_NEX, nex, float,  reloading_ammo, reload_ammo) \
	w_prop(WEP_NEX, nex, float,  reloading_time, reload_time) \
	w_prop(WEP_NEX, nex, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(WEP_NEX, nex, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(WEP_NEX, nex, string, weaponreplace, weaponreplace) \
	w_prop(WEP_NEX, nex, float,  weaponstart, weaponstart) \
	w_prop(WEP_NEX, nex, float,  weaponstartoverride, weaponstartoverride)

#ifdef SVQC
NEX_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_nex (void) { weapon_defaultspawnfunc(WEP_NEX); }

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
	
	mydmg = WEP_CVAR_BOTH(nex, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(nex, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(nex, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(nex, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(nex, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(nex, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(nex, !issecondary, ammo);

	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(WEP_CVAR(nex, charge))
	{
		charge = WEP_CVAR(nex, charge_mindmg) / mydmg + (1 - WEP_CVAR(nex, charge_mindmg) / mydmg) * self.nex_charge;
		self.nex_charge *= WEP_CVAR(nex, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot (self, TRUE, 5, "weapons/nexfire.wav", CH_WEAPON_A, mydmg);
	if(charge > WEP_CVAR(nex, charge_animlimit) && WEP_CVAR(nex, charge_animlimit)) // if the Nex is overcharged, we play an extra sound
	{
		sound (self, CH_WEAPON_B, "weapons/nexcharge.wav", VOL_BASE * (charge - 0.5 * WEP_CVAR(nex, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(nex, charge_animlimit)), ATTN_NORM);
	}

	yoda = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, WEP_NEX);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA); 

	//beam and muzzle flash done on client
	SendCSQCNexBeamParticle(charge);

	W_DecreaseAmmo(ammo_cells, myammo, autocvar_g_balance_nex_reload_ammo);
}

void spawnfunc_weapon_nex (void); // defined in t_items.qc

.float nex_chargepool_pauseregen_finished;
float w_nex(float req)
{
	float dt;
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if(bot_aim(1000000, 0, 1, FALSE))
				self.BUTTON_ATCK = TRUE;
			else
			{
				if(WEP_CVAR(nex, charge))
					self.BUTTON_ATCK2 = TRUE;
			}
			return TRUE;
		}
		case WR_THINK:
		{
			if(WEP_CVAR(nex, charge) && self.nex_charge < WEP_CVAR(nex, charge_limit))
				self.nex_charge = min(1, self.nex_charge + WEP_CVAR(nex, charge_rate) * frametime / W_TICSPERFRAME);
				
			if(WEP_CVAR_SEC(nex, chargepool))
				if(self.nex_chargepool_ammo < 1)
				{
					if(self.nex_chargepool_pauseregen_finished < time)
						self.nex_chargepool_ammo = min(1, self.nex_chargepool_ammo + WEP_CVAR_SEC(nex, chargepool_regen) * frametime / W_TICSPERFRAME);
					self.pauseregen_finished = max(self.pauseregen_finished, time + WEP_CVAR_SEC(nex, chargepool_pause_regen));
				}

			if(autocvar_g_balance_nex_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(nex, ammo), WEP_CVAR_SEC(nex, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else
			{
				if (self.BUTTON_ATCK)
				{
					if (weapon_prepareattack(0, WEP_CVAR_PRI(nex, refire)))
					{
						W_Nex_Attack(0);
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(nex, animtime), w_ready);
					}
				}
				if ((WEP_CVAR(nex, charge) && !WEP_CVAR(nex, secondary)) ? (self.BUTTON_ZOOM | self.BUTTON_ZOOMSCRIPT) : self.BUTTON_ATCK2)
				{
					if(WEP_CVAR(nex, charge))
					{
						self.nex_charge_rottime = time + WEP_CVAR(nex, charge_rot_pause);
						dt = frametime / W_TICSPERFRAME;

						if(self.nex_charge < 1)
						{
							if(WEP_CVAR_SEC(nex, chargepool))
							{
								if(WEP_CVAR_SEC(nex, ammo))
								{
									// always deplete if secondary is held
									self.nex_chargepool_ammo = max(0, self.nex_chargepool_ammo - WEP_CVAR_SEC(nex, ammo) * dt);

									dt = min(dt, (1 - self.nex_charge) / WEP_CVAR(nex, charge_rate));
									self.nex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(nex, chargepool_pause_regen);
									dt = min(dt, self.nex_chargepool_ammo);
									dt = max(0, dt);

									self.nex_charge += dt * WEP_CVAR(nex, charge_rate);
								}
							}

							else if(WEP_CVAR_SEC(nex, ammo))
							{
								if(self.BUTTON_ATCK2) // only eat ammo when the button is pressed
								{
									dt = min(dt, (1 - self.nex_charge) / WEP_CVAR(nex, charge_rate));
									if(!(self.items & IT_UNLIMITED_WEAPON_AMMO))
									{
										// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
										if(autocvar_g_balance_nex_reload_ammo)
										{
											dt = min(dt, (self.clip_load - WEP_CVAR_PRI(nex, ammo)) / WEP_CVAR_SEC(nex, ammo));
											dt = max(0, dt);
											if(dt > 0)
											{
												self.clip_load = max(WEP_CVAR_SEC(nex, ammo), self.clip_load - WEP_CVAR_SEC(nex, ammo) * dt);
											}
											self.(weapon_load[WEP_NEX]) = self.clip_load;
										}
										else
										{
											dt = min(dt, (self.ammo_cells - WEP_CVAR_PRI(nex, ammo)) / WEP_CVAR_SEC(nex, ammo));
											dt = max(0, dt);
											if(dt > 0)
											{
												self.ammo_cells = max(WEP_CVAR_SEC(nex, ammo), self.ammo_cells - WEP_CVAR_SEC(nex, ammo) * dt);
											}
										}
									}
									self.nex_charge += dt * WEP_CVAR(nex, charge_rate);
								}
							}

							else
							{
								dt = min(dt, (1 - self.nex_charge) / WEP_CVAR(nex, charge_rate));
								self.nex_charge += dt * WEP_CVAR(nex, charge_rate);
							}
						}
					}
					else if(WEP_CVAR(nex, secondary))
					{
						if (weapon_prepareattack(0, WEP_CVAR_SEC(nex, refire)))
						{
							W_Nex_Attack(1);
							weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_SEC(nex, animtime), w_ready);
						}
					}
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/nexflash.md3");
			precache_model ("models/weapons/g_nex.md3");
			precache_model ("models/weapons/v_nex.md3");
			precache_model ("models/weapons/h_nex.iqm");
			precache_sound ("weapons/nexfire.wav");
			precache_sound ("weapons/nexcharge.wav");
			precache_sound ("weapons/nexwhoosh1.wav");
			precache_sound ("weapons/nexwhoosh2.wav");
			precache_sound ("weapons/nexwhoosh3.wav");
			NEX_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_cells;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_cells >= WEP_CVAR_PRI(nex, ammo);
			ammo_amount += (autocvar_g_balance_nex_reload_ammo && self.(weapon_load[WEP_NEX]) >= WEP_CVAR_PRI(nex, ammo));
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(WEP_CVAR(nex, secondary))
			{
				// don't allow charging if we don't have enough ammo
				ammo_amount = self.ammo_cells >= WEP_CVAR_SEC(nex, ammo);
				ammo_amount += self.(weapon_load[WEP_NEX]) >= WEP_CVAR_SEC(nex, ammo);	
				return ammo_amount;
			}
			else
			{
				return FALSE; // zoom is not a fire mode
			}
		}
		case WR_CONFIG:
		{
			NEX_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(nex, ammo), WEP_CVAR_SEC(nex, ammo)), "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_NEX_MURDER;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_nex(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
				
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/neximpact.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
