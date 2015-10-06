#ifndef IMPLEMENTATION
CLASS(Vortex, Weapon)
/* ammotype  */ ATTRIB(Vortex, ammo_field, .int, ammo_cells)
/* impulse   */ ATTRIB(Vortex, impulse, int, 7)
/* flags     */ ATTRIB(Vortex, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Vortex, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(Vortex, wpcolor, vector, '0.5 1 1');
/* modelname */ ATTRIB(Vortex, mdl, string, "nex");
#ifndef MENUQC
/* model     */ ATTRIB(Vortex, m_model, Model, MDL_VORTEX_ITEM);
#endif
/* crosshair */ ATTRIB(Vortex, w_crosshair, string, "gfx/crosshairnex");
/* crosshair */ ATTRIB(Vortex, w_crosshair_size, float, 0.65);
/* wepimg    */ ATTRIB(Vortex, model2, string, "weaponnex");
/* refname   */ ATTRIB(Vortex, netname, string, "vortex");
/* wepname   */ ATTRIB(Vortex, message, string, _("Vortex"));
ENDCLASS(Vortex)
REGISTER_WEAPON(VORTEX, NEW(Vortex));

#define VORTEX_SETTINGS(w_cvar,w_prop) VORTEX_SETTINGS_LIST(w_cvar, w_prop, VORTEX, vortex)
#define VORTEX_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, damagefalloff_mindist) \
	w_cvar(id, sn, BOTH, damagefalloff_maxdist) \
	w_cvar(id, sn, BOTH, damagefalloff_halflife) \
	w_cvar(id, sn, BOTH, damagefalloff_forcehalflife) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, NONE, charge) \
	w_cvar(id, sn, NONE, charge_mindmg) \
	w_cvar(id, sn, NONE, charge_shot_multiplier) \
	w_cvar(id, sn, NONE, charge_animlimit) \
	w_cvar(id, sn, NONE, charge_limit) \
	w_cvar(id, sn, NONE, charge_rate) \
	w_cvar(id, sn, NONE, charge_rot_rate) \
	w_cvar(id, sn, NONE, charge_rot_pause) \
	w_cvar(id, sn, NONE, charge_start) \
	w_cvar(id, sn, NONE, charge_minspeed) \
	w_cvar(id, sn, NONE, charge_maxspeed) \
	w_cvar(id, sn, NONE, charge_velocity_rate) \
	w_cvar(id, sn, NONE, secondary) \
	w_cvar(id, sn, SEC,  chargepool) \
	w_cvar(id, sn, SEC,  chargepool_regen) \
	w_cvar(id, sn, SEC,  chargepool_pause_regen) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
VORTEX_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)

.float vortex_lasthit;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_vortex) { weapon_defaultspawnfunc(WEP_VORTEX.m_id); }
spawnfunc(weapon_nex) { spawnfunc_weapon_vortex(this); }

void SendCSQCVortexBeamParticle(float charge) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_VORTEXBEAMPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg.x);
	WriteCoord(MSG_BROADCAST, w_shotorg.y);
	WriteCoord(MSG_BROADCAST, w_shotorg.z);
	WriteCoord(MSG_BROADCAST, v.x);
	WriteCoord(MSG_BROADCAST, v.y);
	WriteCoord(MSG_BROADCAST, v.z);
	WriteByte(MSG_BROADCAST, bound(0, 255 * charge, 255));
}

void W_Vortex_Attack(Weapon thiswep, float issecondary)
{SELFPARAM();
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;

	mydmg = WEP_CVAR_BOTH(vortex, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(vortex, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(vortex, !issecondary, ammo);

	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(WEP_CVAR(vortex, charge))
	{
		charge = WEP_CVAR(vortex, charge_mindmg) / mydmg + (1 - WEP_CVAR(vortex, charge_mindmg) / mydmg) * self.vortex_charge;
		self.vortex_charge *= WEP_CVAR(vortex, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot(self, true, 5, SND(NEXFIRE), CH_WEAPON_A, mydmg);
	if(charge > WEP_CVAR(vortex, charge_animlimit) && WEP_CVAR(vortex, charge_animlimit)) // if the Vortex is overcharged, we play an extra sound
	{
		sound(self, CH_WEAPON_B, SND_NEXCHARGE, VOL_BASE * (charge - 0.5 * WEP_CVAR(vortex, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(vortex, charge_animlimit)), ATTN_NORM);
	}

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet(w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, WEP_VORTEX.m_id);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && self.vortex_lasthit)
	{
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	self.vortex_lasthit = damage_goodhits;

	//beam and muzzle flash done on client
	SendCSQCVortexBeamParticle(charge);

	W_DecreaseAmmo(thiswep, self, myammo);
}

.float vortex_chargepool_pauseregen_finished;

		METHOD(Vortex, wr_aim, void(entity thiswep))
		{
			if(bot_aim(1000000, 0, 1, false))
				self.BUTTON_ATCK = true;
			else
			{
				if(WEP_CVAR(vortex, charge))
					self.BUTTON_ATCK2 = true;
			}
		}
		METHOD(Vortex, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if(WEP_CVAR(vortex, charge) && actor.vortex_charge < WEP_CVAR(vortex, charge_limit))
				actor.vortex_charge = min(1, actor.vortex_charge + WEP_CVAR(vortex, charge_rate) * frametime / W_TICSPERFRAME);

			if(WEP_CVAR_SEC(vortex, chargepool))
				if(actor.vortex_chargepool_ammo < 1)
				{
					if(actor.vortex_chargepool_pauseregen_finished < time)
						actor.vortex_chargepool_ammo = min(1, actor.vortex_chargepool_ammo + WEP_CVAR_SEC(vortex, chargepool_regen) * frametime / W_TICSPERFRAME);
					actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(vortex, chargepool_pause_regen));
				}

			if(autocvar_g_balance_vortex_reload_ammo && actor.clip_load < min(WEP_CVAR_PRI(vortex, ammo), WEP_CVAR_SEC(vortex, ammo))) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			} else
			{
				if(fire1)
				{
					if(weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(vortex, refire)))
					{
						W_Vortex_Attack(thiswep, 0);
						weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(vortex, animtime), w_ready);
					}
				}
				if((WEP_CVAR(vortex, charge) && !WEP_CVAR(vortex, secondary)) ? (actor.BUTTON_ZOOM | actor.BUTTON_ZOOMSCRIPT) : fire2)
				{
					if(WEP_CVAR(vortex, charge))
					{
						actor.vortex_charge_rottime = time + WEP_CVAR(vortex, charge_rot_pause);
						float dt = frametime / W_TICSPERFRAME;

						if(actor.vortex_charge < 1)
						{
							if(WEP_CVAR_SEC(vortex, chargepool))
							{
								if(WEP_CVAR_SEC(vortex, ammo))
								{
									// always deplete if secondary is held
									actor.vortex_chargepool_ammo = max(0, actor.vortex_chargepool_ammo - WEP_CVAR_SEC(vortex, ammo) * dt);

									dt = min(dt, (1 - actor.vortex_charge) / WEP_CVAR(vortex, charge_rate));
									actor.vortex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(vortex, chargepool_pause_regen);
									dt = min(dt, actor.vortex_chargepool_ammo);
									dt = max(0, dt);

									actor.vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
								}
							}

							else if(WEP_CVAR_SEC(vortex, ammo))
							{
								if(fire2) // only eat ammo when the button is pressed
								{
									dt = min(dt, (1 - actor.vortex_charge) / WEP_CVAR(vortex, charge_rate));
									if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
									{
										// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
										if(autocvar_g_balance_vortex_reload_ammo)
										{
											dt = min(dt, (actor.clip_load - WEP_CVAR_PRI(vortex, ammo)) / WEP_CVAR_SEC(vortex, ammo));
											dt = max(0, dt);
											if(dt > 0)
											{
												actor.clip_load = max(WEP_CVAR_SEC(vortex, ammo), actor.clip_load - WEP_CVAR_SEC(vortex, ammo) * dt);
											}
											actor.(weapon_load[WEP_VORTEX.m_id]) = actor.clip_load;
										}
										else
										{
											dt = min(dt, (actor.WEP_AMMO(VORTEX) - WEP_CVAR_PRI(vortex, ammo)) / WEP_CVAR_SEC(vortex, ammo));
											dt = max(0, dt);
											if(dt > 0)
											{
												actor.WEP_AMMO(VORTEX) = max(WEP_CVAR_SEC(vortex, ammo), actor.WEP_AMMO(VORTEX) - WEP_CVAR_SEC(vortex, ammo) * dt);
											}
										}
									}
									actor.vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
								}
							}

							else
							{
								dt = min(dt, (1 - actor.vortex_charge) / WEP_CVAR(vortex, charge_rate));
								actor.vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
							}
						}
					}
					else if(WEP_CVAR(vortex, secondary))
					{
						if(weapon_prepareattack(thiswep, actor, false, WEP_CVAR_SEC(vortex, refire)))
						{
							W_Vortex_Attack(thiswep, 1);
							weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_SEC(vortex, animtime), w_ready);
						}
					}
				}
			}
		}
		METHOD(Vortex, wr_init, void(entity thiswep))
		{
			VORTEX_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(Vortex, wr_setup, void(entity thiswep))
		{
			self.vortex_lasthit = 0;
		}
		METHOD(Vortex, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(VORTEX) >= WEP_CVAR_PRI(vortex, ammo);
			ammo_amount += (autocvar_g_balance_vortex_reload_ammo && self.(weapon_load[WEP_VORTEX.m_id]) >= WEP_CVAR_PRI(vortex, ammo));
			return ammo_amount;
		}
		METHOD(Vortex, wr_checkammo2, bool(entity thiswep))
		{
			if(WEP_CVAR(vortex, secondary))
			{
				// don't allow charging if we don't have enough ammo
				float ammo_amount = self.WEP_AMMO(VORTEX) >= WEP_CVAR_SEC(vortex, ammo);
				ammo_amount += self.(weapon_load[WEP_VORTEX.m_id]) >= WEP_CVAR_SEC(vortex, ammo);
				return ammo_amount;
			}
			else
			{
				return false; // zoom is not a fire mode
			}
		}
		METHOD(Vortex, wr_config, void(entity thiswep))
		{
			VORTEX_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(Vortex, wr_resetplayer, void(entity thiswep))
		{
			self.vortex_lasthit = 0;
		}
		METHOD(Vortex, wr_reload, void(entity thiswep))
		{
			W_Reload(self, min(WEP_CVAR_PRI(vortex, ammo), WEP_CVAR_SEC(vortex, ammo)), SND(RELOAD));
		}
		METHOD(Vortex, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(Vortex, wr_killmessage, int(entity thiswep))
		{
			return WEAPON_VORTEX_MURDER;
		}

#endif
#ifdef CSQC
float autocvar_g_balance_vortex_secondary = 0; // WEAPONTODO

		METHOD(Vortex, wr_impacteffect, void(entity thiswep))
		{
			vector org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum(EFFECT_VORTEX_IMPACT), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_NEXIMPACT, VOL_BASE, ATTN_NORM);
		}
		METHOD(Vortex, wr_init, void(entity thiswep))
		{
			if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
			{
				precache_pic("gfx/reticle_nex");
			}
		}
		METHOD(Vortex, wr_zoomreticle, bool(entity thiswep))
		{
			if(button_zoom || zoomscript_caught || (!WEP_CVAR(vortex, secondary) && button_attack2))
			{
				reticle_image = "gfx/reticle_nex";
				return true;
			}
			else
			{
				// no weapon specific image for this weapon
				return false;
			}
		}

#endif
#endif
