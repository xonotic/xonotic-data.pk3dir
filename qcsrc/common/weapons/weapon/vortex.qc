#include "vortex.qh"

//REGISTER_STAT(WEP_CVAR_vortex_charge, bool, WEP_CVAR(vortex, charge))
//REGISTER_STAT(WEP_CVAR_vortex_charge_animlimit, float, WEP_CVAR(vortex, charge_animlimit))

#if defined(GAMEQC)
METHOD(Vortex, wr_glow, vector(Vortex this, int actor_colors, entity wepent))
{
	if (!WEP_CVAR(vortex, charge)) return '0 0 0';
	float charge = max(0.25, wepent.vortex_charge);
	float animlimit = WEP_CVAR(vortex, charge_animlimit);
	float f = min(1, charge / animlimit);
	vector mycolors = colormapPaletteColor(actor_colors & 0x0F, true);
	vector g = f * (mycolors * 0.3);
	if (charge > animlimit)
	{
		f = (charge - animlimit) / (1 - animlimit);
		g += f * (mycolors * 0.7);
	}
	// transition color can't be '0 0 0' as it defaults to player model glow color
	if (g == '0 0 0')
		g = '0 0 0.000001';
	return g;
}
#endif

REGISTER_NET_TEMP(TE_CSQC_VORTEXBEAMPARTICLE)

#if defined(SVQC)
void SendCSQCVortexBeamParticle(float charge) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteHeader(MSG_BROADCAST, TE_CSQC_VORTEXBEAMPARTICLE);
	WriteVector(MSG_BROADCAST, w_shotorg);
	WriteVector(MSG_BROADCAST, v);
	WriteByte(MSG_BROADCAST, bound(0, 255 * charge, 255));
}
#elif defined(CSQC)
NET_HANDLE(TE_CSQC_VORTEXBEAMPARTICLE, bool isNew)
{
	float charge;
	vector shotorg = ReadVector();
	vector endpos = ReadVector();
	charge = ReadByte() / 255.0;

	//pointparticles(EFFECT_VORTEX_MUZZLEFLASH, shotorg, normalize(endpos - shotorg) * 1000, 1);

	//draw either the old v2.3 beam or the new beam
	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;

	if(!MUTATOR_CALLHOOK(Particles_VortexBeam, shotorg, endpos))
	{
		if(autocvar_cl_particles_oldvortexbeam)
			WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
		else
			WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	}
	return true;
}
#endif

#ifdef SVQC

REGISTER_MUTATOR(vortex_charge, true);

MUTATOR_HOOKFUNCTION(vortex_charge, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	// WEAPONTODO
	if(!WEP_CVAR(vortex, charge) || !WEP_CVAR(vortex, charge_velocity_rate))
		return;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		if (player.(weaponentity).m_weapon == WEP_VORTEX && WEP_CVAR(vortex, charge) && WEP_CVAR(vortex, charge_velocity_rate) && vdist(vec2(player.velocity), >, WEP_CVAR(vortex, charge_minspeed)))
		{
			float xyspeed = vlen(vec2(player.velocity));
			// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
				xyspeed = min(xyspeed, WEP_CVAR(vortex, charge_maxspeed));
			float f = (xyspeed - WEP_CVAR(vortex, charge_minspeed)) / (WEP_CVAR(vortex, charge_maxspeed) - WEP_CVAR(vortex, charge_minspeed));
			// add the extra charge
			player.(weaponentity).vortex_charge = min(1, player.(weaponentity).vortex_charge + WEP_CVAR(vortex, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
		}
	}
}

void W_Vortex_Attack(Weapon thiswep, entity actor, .entity weaponentity, float issecondary)
{
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;

	mydmg = WEP_CVAR_BOTH(vortex, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(vortex, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(vortex, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(vortex, !issecondary, ammo);

	float dtype = thiswep.m_id;
	if(WEP_CVAR_BOTH(vortex, !issecondary, armorpierce))
		dtype |= HITTYPE_ARMORPIERCE;

	float flying;
	flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(WEP_CVAR(vortex, charge))
	{
		charge = WEP_CVAR(vortex, charge_mindmg) / mydmg + (1 - WEP_CVAR(vortex, charge_mindmg) / mydmg) * actor.(weaponentity).vortex_charge;
		actor.(weaponentity).vortex_charge *= WEP_CVAR(vortex, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot(actor, weaponentity, true, 5, SND_NEXFIRE, CH_WEAPON_A, mydmg, dtype);
	if(charge > WEP_CVAR(vortex, charge_animlimit) && WEP_CVAR(vortex, charge_animlimit)) // if the Vortex is overcharged, we play an extra sound
	{
		sound(actor, CH_WEAPON_B, SND_NEXCHARGE, VOL_BASE * (charge - 0.5 * WEP_CVAR(vortex, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(vortex, charge_animlimit)), ATTN_NORM);
	}

	yoda = 0;
	impressive_hits = 0;
	FireRailgunBullet(actor, weaponentity, w_shotorg, w_shotorg + w_shotdir * max_shot_distance, mydmg, false, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, dtype);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(impressive_hits && actor.vortex_lasthit)
	{
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		impressive_hits = 0; // only every second time
	}

	actor.vortex_lasthit = impressive_hits;

	//beam done on client
	vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, normalize(v - w_shotorg));
	SendCSQCVortexBeamParticle(charge);

	W_DecreaseAmmo(thiswep, actor, myammo, weaponentity);

	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_BOTH(vortex, !issecondary, animtime), w_ready);
}

.float vortex_chargepool_pauseregen_finished;

void W_Vortex_Charge(entity actor, .entity weaponentity, float dt)
{
	if(WEP_CVAR(vortex, charge) && actor.(weaponentity).vortex_charge < WEP_CVAR(vortex, charge_limit))
		actor.(weaponentity).vortex_charge = min(1, actor.(weaponentity).vortex_charge + WEP_CVAR(vortex, charge_rate) * dt);
}

.float hagar_loadblock; // are we loading or not
.float hagar_loadstep; // time when to force release
.float hagar_loadbeep, hagar_warning; // prevent sounds from playing on multiple frames
void W_Vortex_Charge_Bow(Weapon thiswep, entity actor, .entity weaponentity)
{
	// loadable vortex attack, must always run each frame
	if(time < game_starttime || time < actor.race_penalty || timeout_status == TIMEOUT_ACTIVE)
		return;
	if (weaponUseForbidden(actor))
		return;

	bool loaded = actor.(weaponentity).vortex_charge == WEP_CVAR(vortex, charge_limit);

	// check if we can attempt to charge more
	if(PHYS_INPUT_BUTTON_ATCK(actor) && (weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire)) || actor.(weaponentity).hagar_loadblock == true))
	{
		actor.(weaponentity).hagar_loadblock = true; // we are charging

		if(!loaded) // not fully loaded
		{
			W_Vortex_Charge(actor, weaponentity, frametime / W_TICSPERFRAME);
			actor.(weaponentity).state = WS_INUSE;
			if(!actor.(weaponentity).hagar_loadbeep){
				// set to true so that charging sound isn't replayed each charging frame
				actor.(weaponentity).hagar_loadbeep = true;
				// TODO find a better charging sound?
				sound(actor, CH_SHOTS_SINGLE, SND_ELECTRO_FLY, 1, ATTEN_NORM);
			}

			if(actor.(weaponentity).vortex_charge >= WEP_CVAR(vortex, charge_limit)){
				loaded = true;
				actor.(weaponentity).hagar_loadstep = time + WEP_CVAR(vortex, charge_bow_hold) * W_WeaponRateFactor(actor);
				actor.(weaponentity).vortex_charge = WEP_CVAR(vortex, charge_limit); //no overcharge

				// we are now fully loaded, play a beep sound to notify the player
				sound(actor, CH_WEAPON_B, SND_ONS_SPARK1, 1, ATTEN_NORM);

				sound(actor, CH_SHOTS_SINGLE, SND_ARC_LOOP_OVERHEAT, 1, ATTEN_NORM);
			}
		}
		else if(!actor.(weaponentity).hagar_warning) // prevents the beep from playing each frame
		{
			if(actor.(weaponentity).hagar_loadstep - 0.5 < time && WEP_CVAR(vortex, charge_bow_hold) >= 0)
			{
				// we're soon about to automatically have a forced release
				// play a sound to notify the player
				sound(actor, CH_WEAPON_B, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);
				actor.(weaponentity).hagar_warning = true;
			}
		}
	}

	// have we charged?
	if(actor.(weaponentity).vortex_charge && actor.(weaponentity).hagar_loadblock)
	{
		// release if player let go of firing button or if they've held it in too long
		if(!PHYS_INPUT_BUTTON_ATCK(actor) || (loaded && actor.(weaponentity).hagar_loadstep < time && WEP_CVAR(vortex, charge_bow_hold) >= 0))
		{
			stopsound(actor, CH_SHOTS_SINGLE);
			actor.(weaponentity).state = WS_READY;
			if(thiswep.wr_checkammo1(thiswep, actor, weaponentity)){
				weapon_prepareattack_do(actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire));
				W_Vortex_Attack(thiswep, actor, weaponentity, 0);
			}
			actor.(weaponentity).hagar_loadblock = false;
		}
	}
	else
	{
		actor.(weaponentity).hagar_loadbeep = false;
		actor.(weaponentity).hagar_warning = false;

		// we aren't checking ammo during an attack, so we must do it here
		if(!(thiswep.wr_checkammo1(thiswep, actor, weaponentity) + thiswep.wr_checkammo2(thiswep, actor, weaponentity)))
		if(!(actor.items & IT_UNLIMITED_AMMO))
		{
			// note: this doesn't force the switch
			W_SwitchToOtherWeapon(actor, weaponentity);
			return;
		}
	}
}

METHOD(Vortex, wr_gonethink, void(entity thiswep, entity actor, .entity weaponentity))
{
	// we lost the weapon and want to prepare switching away
	if(actor.(weaponentity).vortex_charge && actor.(weaponentity).hagar_loadblock)
	{
		actor.(weaponentity).vortex_charge = 0;
		actor.(weaponentity).hagar_loadbeep = false;
		actor.(weaponentity).hagar_warning = false;
		actor.(weaponentity).hagar_loadblock = false;
		actor.(weaponentity).state = WS_READY;
		stopsound(actor, CH_SHOTS_SINGLE);
	}
}
METHOD(Vortex, wr_playerdeath, void(entity thiswep, entity actor, .entity weaponentity))
{
	// if we have charge loaded when we die, release it
	if(actor.(weaponentity).vortex_charge && WEP_CVAR(vortex, charge_bow_hold_releasedeath)){
		actor.(weaponentity).state = WS_READY;
		if(thiswep.wr_checkammo1(thiswep, actor, weaponentity)){
			weapon_prepareattack_do(actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire));
			W_Vortex_Attack(thiswep, actor, weaponentity, 0);
		}
		actor.(weaponentity).hagar_loadblock = false;
	}
}

METHOD(Vortex, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(bot_aim(actor, weaponentity, 1000000, 0, 1, false, true))
		PHYS_INPUT_BUTTON_ATCK(actor) = true;

	// check if we have a bow charging vortex and it's fully loaded
	if(WEP_CVAR(vortex, charge_bow) && actor.(weaponentity).vortex_charge >= WEP_CVAR(vortex, charge_limit))
		PHYS_INPUT_BUTTON_ATCK(actor) = false;
}
METHOD(Vortex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(vortex, ammo), WEP_CVAR_SEC(vortex, ammo)))
	{ // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);

		if(WEP_CVAR(vortex, charge_bow))
			actor.(weaponentity).vortex_charge = 0;

		return; // if we need to reload cancel all charging and firing
	}

	if(WEP_CVAR(vortex, charge_bow))
	{
		W_Vortex_Charge_Bow(thiswep, actor, weaponentity);
		return; // this charging mode overrides normal charging and firing
	}

	if(!WEP_CVAR(vortex, charge_always))
		W_Vortex_Charge(actor, weaponentity, frametime / W_TICSPERFRAME);

	if(WEP_CVAR_SEC(vortex, chargepool))
	{
		if(actor.(weaponentity).vortex_chargepool_ammo < 1)
		{
			if(actor.vortex_chargepool_pauseregen_finished < time)
				actor.(weaponentity).vortex_chargepool_ammo = min(1, actor.(weaponentity).vortex_chargepool_ammo + WEP_CVAR_SEC(vortex, chargepool_regen) * frametime / W_TICSPERFRAME);
			actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(vortex, chargepool_pause_regen));
		}
	}

	if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire)))
		{
			W_Vortex_Attack(thiswep, actor, weaponentity, 0);
		}
	}
	if((WEP_CVAR(vortex, charge) && !WEP_CVAR(vortex, secondary)) ? (PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) : (fire & 2))
	{
		if(WEP_CVAR(vortex, charge))
		{
			actor.(weaponentity).vortex_charge_rottime = time + WEP_CVAR(vortex, charge_rot_pause);
			float dt = frametime / W_TICSPERFRAME;

			if(actor.(weaponentity).vortex_charge < 1)
			{
				if(WEP_CVAR_SEC(vortex, chargepool))
				{
					if(WEP_CVAR_SEC(vortex, ammo))
					{
						// always deplete if secondary is held
						actor.(weaponentity).vortex_chargepool_ammo = max(0, actor.(weaponentity).vortex_chargepool_ammo - WEP_CVAR_SEC(vortex, ammo) * dt);

						dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(vortex, charge_rate));
						actor.vortex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(vortex, chargepool_pause_regen);
						dt = min(dt, actor.(weaponentity).vortex_chargepool_ammo);
						dt = max(0, dt);

						actor.(weaponentity).vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
					}
				}

				else if(WEP_CVAR_SEC(vortex, ammo))
				{
					if(fire & 2) // only eat ammo when the button is pressed
					{
						dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(vortex, charge_rate));
						if(!(actor.items & IT_UNLIMITED_AMMO))
						{
							// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
							if(autocvar_g_balance_vortex_reload_ammo)
							{
								dt = min(dt, (actor.(weaponentity).clip_load - WEP_CVAR_PRI(vortex, ammo)) / WEP_CVAR_SEC(vortex, ammo));
								dt = max(0, dt);
								if(dt > 0)
								{
									actor.(weaponentity).clip_load = max(WEP_CVAR_SEC(vortex, ammo), actor.(weaponentity).clip_load - WEP_CVAR_SEC(vortex, ammo) * dt);
								}
								actor.(weaponentity).(weapon_load[thiswep.m_id]) = actor.(weaponentity).clip_load;
							}
							else
							{
								dt = min(dt, (GetResource(actor, thiswep.ammo_type) - WEP_CVAR_PRI(vortex, ammo)) / WEP_CVAR_SEC(vortex, ammo));
								dt = max(0, dt);
								if(dt > 0)
								{
									SetResource(actor, thiswep.ammo_type, max(WEP_CVAR_SEC(vortex, ammo), GetResource(actor, thiswep.ammo_type) - WEP_CVAR_SEC(vortex, ammo) * dt));
								}
							}
						}
						actor.(weaponentity).vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
					}
				}

				else
				{
					dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(vortex, charge_rate));
					actor.(weaponentity).vortex_charge += dt * WEP_CVAR(vortex, charge_rate);
				}
			}
		}
		else if(WEP_CVAR(vortex, secondary))
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(vortex, refire)))
			{
				W_Vortex_Attack(thiswep, actor, weaponentity, 1);
			}
		}
	}
}
METHOD(Vortex, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
	actor.vortex_lasthit = 0;
}
METHOD(Vortex, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(vortex, ammo);
	ammo_amount += (autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(vortex, ammo));
	return ammo_amount;
}
METHOD(Vortex, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if(WEP_CVAR(vortex, secondary))
	{
		// don't allow charging if we don't have enough ammo
		float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(vortex, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(vortex, ammo);
		return ammo_amount;
	}
	else
	{
		return false; // zoom is not a fire mode
	}
}
METHOD(Vortex, wr_resetplayer, void(entity thiswep, entity actor))
{
	if (WEP_CVAR(vortex, charge)) {
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			actor.(weaponentity).vortex_charge = WEP_CVAR(vortex, charge_start);

			if (WEP_CVAR_SEC(vortex, chargepool))
				actor.(weaponentity).vortex_chargepool_ammo = 1;
		}
	}
	actor.vortex_lasthit = 0;
}
METHOD(Vortex, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(vortex, ammo), WEP_CVAR_SEC(vortex, ammo)), SND_RELOAD);
}
METHOD(Vortex, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Vortex, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_VORTEX_MURDER;
}
METHOD(Vortex, wr_zoom, bool(entity thiswep, entity actor))
{
	return PHYS_INPUT_BUTTON_ATCK2(actor) && !WEP_CVAR(vortex, secondary);
}

#endif
#ifdef CSQC

METHOD(Vortex, wr_impacteffect, void(entity thiswep, entity actor))
{
	entity this = actor;
	vector org2 = w_org + w_backoff * 6;
	pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(this, CH_SHOTS, SND_NEXIMPACT, VOL_BASE, ATTN_NORM);
}
METHOD(Vortex, wr_init, void(entity thiswep))
{
	if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
	{
		precache_pic("gfx/reticle_nex");
	}
}
METHOD(Vortex, wr_zoom, bool(entity thiswep, entity actor))
{
	if(button_zoom || zoomscript_caught || (!WEP_CVAR(vortex, secondary) && button_attack2))
	{
		return true;
	}
	else
	{
		// no weapon specific image for this weapon
		return false;
	}
}
METHOD(Vortex, wr_zoomdir, bool(entity thiswep))
{
	return button_attack2 && !WEP_CVAR(vortex, secondary);
}

#endif
