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
/* wepname   */ ATTRIB(Vortex, m_name, string, _("Vortex"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, BOTH) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, chargepool, float, SEC) \
		P(class, prefix, chargepool_pause_regen, float, SEC) \
		P(class, prefix, chargepool_regen, float, SEC) \
		P(class, prefix, charge, float, NONE) \
		P(class, prefix, charge_animlimit, float, NONE) \
		P(class, prefix, charge_limit, float, NONE) \
		P(class, prefix, charge_maxspeed, float, NONE) \
		P(class, prefix, charge_mindmg, float, NONE) \
		P(class, prefix, charge_minspeed, float, NONE) \
		P(class, prefix, charge_rate, float, NONE) \
		P(class, prefix, charge_rot_pause, float, NONE) \
		P(class, prefix, charge_rot_rate, float, NONE) \
		P(class, prefix, charge_shot_multiplier, float, NONE) \
		P(class, prefix, charge_start, float, NONE) \
		P(class, prefix, charge_velocity_rate, float, NONE) \
		P(class, prefix, damagefalloff_forcehalflife, float, BOTH) \
		P(class, prefix, damagefalloff_halflife, float, BOTH) \
		P(class, prefix, damagefalloff_maxdist, float, BOTH) \
		P(class, prefix, damagefalloff_mindist, float, BOTH) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, weaponreplace, string, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Vortex, vortex)
#undef X

ENDCLASS(Vortex)
REGISTER_WEAPON(VORTEX, vortex, NEW(Vortex));


#ifdef SVQC

.float vortex_lasthit;
#endif
#endif
#ifdef IMPLEMENTATION

REGISTER_STAT(WEP_CVAR_vortex_charge, bool, WEP_CVAR(vortex, charge))
REGISTER_STAT(WEP_CVAR_vortex_charge_animlimit, float, WEP_CVAR(vortex, charge_animlimit))

#if defined(CSQC)
float autocvar_g_weapon_charge_colormod_red_full;
float autocvar_g_weapon_charge_colormod_red_half;
float autocvar_g_weapon_charge_colormod_green_full;
float autocvar_g_weapon_charge_colormod_blue_full;
float autocvar_g_weapon_charge_colormod_blue_half;
float autocvar_g_weapon_charge_colormod_green_half;
float autocvar_g_weapon_charge_colormod_hdrmultiplier;

METHOD(Vortex, wr_glow, vector(Vortex this))
{
	if (!STAT(WEP_CVAR_vortex_charge)) return '0 0 0';
	float charge = STAT(VORTEX_CHARGE);
	float animlimit = STAT(WEP_CVAR_vortex_charge_animlimit);
	vector g;
	g.x = autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_red_half * min(1, charge / animlimit);
	g.y = autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_green_half * min(1, charge / animlimit);
	g.z = autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_blue_half * min(1, charge / animlimit);
	if (charge > animlimit)
	{
		g.x += autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_red_full * (charge - animlimit) / (1 - animlimit);
		g.y += autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_green_full * (charge - animlimit) / (1 - animlimit);
		g.z += autocvar_g_weapon_charge_colormod_hdrmultiplier * autocvar_g_weapon_charge_colormod_blue_full * (charge - animlimit) / (1 - animlimit);
	}
	return g;
}
#endif

REGISTER_NET_TEMP(TE_CSQC_VORTEXBEAMPARTICLE)

#if defined(SVQC)
void SendCSQCVortexBeamParticle(float charge) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteHeader(MSG_BROADCAST, TE_CSQC_VORTEXBEAMPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg.x);
	WriteCoord(MSG_BROADCAST, w_shotorg.y);
	WriteCoord(MSG_BROADCAST, w_shotorg.z);
	WriteCoord(MSG_BROADCAST, v.x);
	WriteCoord(MSG_BROADCAST, v.y);
	WriteCoord(MSG_BROADCAST, v.z);
	WriteByte(MSG_BROADCAST, bound(0, 255 * charge, 255));
}
#elif defined(CSQC)
NET_HANDLE(TE_CSQC_VORTEXBEAMPARTICLE, bool isNew)
{
	vector shotorg, endpos;
	float charge;
	shotorg.x = ReadCoord(); shotorg.y = ReadCoord(); shotorg.z = ReadCoord();
	endpos.x = ReadCoord(); endpos.y = ReadCoord(); endpos.z = ReadCoord();
	charge = ReadByte() / 255.0;

	pointparticles(EFFECT_VORTEX_MUZZLEFLASH, shotorg, normalize(endpos - shotorg) * 1000, 1);

	//draw either the old v2.3 beam or the new beam
	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;

	if(!MUTATOR_CALLHOOK(Particles_VortexBeam, shotorg, endpos))
	if(autocvar_cl_particles_oldvortexbeam && (STAT(ALLOW_OLDVORTEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum(EFFECT_VORTEX_BEAM), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	return true;
}
#endif

#ifdef SVQC
spawnfunc(weapon_vortex) { weapon_defaultspawnfunc(this, WEP_VORTEX); }
spawnfunc(weapon_nex) { spawnfunc_weapon_vortex(this); }

REGISTER_MUTATOR(vortex_charge, true);

MUTATOR_HOOKFUNCTION(vortex_charge, GetPressedKeys)
{SELFPARAM();
	// WEAPONTODO
	float xyspeed = vlen(vec2(self.velocity));
	if (PS(self).m_weapon == WEP_VORTEX && WEP_CVAR(vortex, charge) && WEP_CVAR(vortex, charge_velocity_rate) && xyspeed > WEP_CVAR(vortex, charge_minspeed))
	{
		// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
	        xyspeed = min(xyspeed, WEP_CVAR(vortex, charge_maxspeed));
		float f = (xyspeed - WEP_CVAR(vortex, charge_minspeed)) / (WEP_CVAR(vortex, charge_maxspeed) - WEP_CVAR(vortex, charge_minspeed));
		// add the extra charge
		self.vortex_charge = min(1, self.vortex_charge + WEP_CVAR(vortex, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
	}
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
		METHOD(Vortex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
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
				thiswep.wr_reload(thiswep);
			} else
			{
				if(fire & 1)
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire)))
					{
						W_Vortex_Attack(thiswep, 0);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(vortex, animtime), w_ready);
					}
				}
				if((WEP_CVAR(vortex, charge) && !WEP_CVAR(vortex, secondary)) ? (actor.BUTTON_ZOOM | actor.BUTTON_ZOOMSCRIPT) : (fire & 2))
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
								if(fire & 2) // only eat ammo when the button is pressed
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
											dt = min(dt, (actor.(thiswep.ammo_field) - WEP_CVAR_PRI(vortex, ammo)) / WEP_CVAR_SEC(vortex, ammo));
											dt = max(0, dt);
											if(dt > 0)
											{
												actor.(thiswep.ammo_field) = max(WEP_CVAR_SEC(vortex, ammo), actor.(thiswep.ammo_field) - WEP_CVAR_SEC(vortex, ammo) * dt);
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
						if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(vortex, refire)))
						{
							W_Vortex_Attack(thiswep, 1);
							weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(vortex, animtime), w_ready);
						}
					}
				}
			}
		}
		METHOD(Vortex, wr_setup, void(entity thiswep))
		{
			self.vortex_lasthit = 0;
		}
		METHOD(Vortex, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_PRI(vortex, ammo);
			ammo_amount += (autocvar_g_balance_vortex_reload_ammo && self.(weapon_load[WEP_VORTEX.m_id]) >= WEP_CVAR_PRI(vortex, ammo));
			return ammo_amount;
		}
		METHOD(Vortex, wr_checkammo2, bool(entity thiswep))
		{
			if(WEP_CVAR(vortex, secondary))
			{
				// don't allow charging if we don't have enough ammo
				float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_SEC(vortex, ammo);
				ammo_amount += self.(weapon_load[WEP_VORTEX.m_id]) >= WEP_CVAR_SEC(vortex, ammo);
				return ammo_amount;
			}
			else
			{
				return false; // zoom is not a fire mode
			}
		}
		METHOD(Vortex, wr_resetplayer, void(entity thiswep))
		{
			if (WEP_CVAR(vortex, charge)) {
				if (WEP_CVAR_SEC(vortex, chargepool)) {
					self.vortex_chargepool_ammo = 1;
				}
				self.vortex_charge = WEP_CVAR(vortex, charge_start);
			}
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

		METHOD(Vortex, wr_impacteffect, void(entity thiswep))
		{
			vector org2 = w_org + w_backoff * 6;
			pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
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
