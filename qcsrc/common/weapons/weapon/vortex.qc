#include "vortex.qh"

//REGISTER_STAT(WEP_CVAR_vortex_charge, bool, WEP_CVAR(WEP_VORTEX, charge))
//REGISTER_STAT(WEP_CVAR_vortex_charge_animlimit, float, WEP_CVAR(WEP_VORTEX, charge_animlimit))

#if defined(GAMEQC)
vector vortex_glowcolor(int actor_colors, float charge)
{
	if (!WEP_CVAR(WEP_VORTEX, charge)) return '0 0 0';

	float animlimit = WEP_CVAR(WEP_VORTEX, charge_animlimit);
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

METHOD(Vortex, wr_glow, vector(Vortex this, int actor_colors, entity wepent))
{
	return vortex_glowcolor(actor_colors, max(0.25, wepent.vortex_charge));
}
#endif

#ifdef GAMEQC
REGISTER_NET_TEMP(TE_CSQC_VORTEXBEAMPARTICLE)
#endif

#if defined(SVQC)
void SendCSQCVortexBeamParticle(entity player, float charge) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteHeader(MSG_BROADCAST, TE_CSQC_VORTEXBEAMPARTICLE);
	WriteVector(MSG_BROADCAST, w_shotorg);
	WriteVector(MSG_BROADCAST, v);
	WriteByte(MSG_BROADCAST, bound(0, 255 * charge, 255));
	WriteByte(MSG_BROADCAST, etof(player));
}
#elif defined(CSQC)
NET_HANDLE(TE_CSQC_VORTEXBEAMPARTICLE, bool isNew)
{
	float charge;
	vector shotorg = ReadVector();
	vector endpos = ReadVector();
	charge = ReadByte() / 255.0;
	int myowner = ReadByte();

	int eff_flags = PARTICLES_USEALPHA | PARTICLES_USEFADE;

	//pointparticles(EFFECT_VORTEX_MUZZLEFLASH, shotorg, normalize(endpos - shotorg) * 1000, 1);

	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;
	if((teamplay && autocvar_cl_tracers_teamcolor == 1) || autocvar_cl_tracers_teamcolor == 2)
	{
		float mycolors = entcs_GetClientColors(myowner - 1);
		vector rgb = vortex_glowcolor(mycolors, max(0.25, charge));
		// in the event of charging being turned off, fall back to player colours
		if(rgb == '0 0 0')
			rgb = colormapPaletteColor(mycolors & 0x0F, true);
		particles_colormin = particles_colormax = rgb;
		eff_flags |= PARTICLES_USECOLOR;
	}

	if(!MUTATOR_CALLHOOK(Particles_VortexBeam, shotorg, endpos))
	{
		if(autocvar_cl_particles_oldvortexbeam)
			WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), shotorg, endpos, 1, eff_flags);
		else
			WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM), shotorg, endpos, 1, eff_flags);
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
	if(!WEP_CVAR(WEP_VORTEX, charge) || !WEP_CVAR(WEP_VORTEX, charge_velocity_rate))
		return;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		if (player.(weaponentity).m_weapon == WEP_VORTEX && WEP_CVAR(WEP_VORTEX, charge) && WEP_CVAR(WEP_VORTEX, charge_velocity_rate) && vdist(vec2(player.velocity), >, WEP_CVAR(WEP_VORTEX, charge_minspeed)))
		{
			float xyspeed = vlen(vec2(player.velocity));
			// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
				xyspeed = min(xyspeed, WEP_CVAR(WEP_VORTEX, charge_maxspeed));
			float f = (xyspeed - WEP_CVAR(WEP_VORTEX, charge_minspeed)) / (WEP_CVAR(WEP_VORTEX, charge_maxspeed) - WEP_CVAR(WEP_VORTEX, charge_minspeed));
			// add the extra charge
			player.(weaponentity).vortex_charge = min(1, player.(weaponentity).vortex_charge + WEP_CVAR(WEP_VORTEX, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
		}
	}
}

void W_Vortex_Attack(Weapon thiswep, entity actor, .entity weaponentity, float issecondary)
{
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;

	mydmg = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, ammo);

	float dtype = thiswep.m_id;
	if(WEP_CVAR_BOTH(WEP_VORTEX, !issecondary, armorpierce))
		dtype |= HITTYPE_ARMORPIERCE;

	float flying;
	flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(WEP_CVAR(WEP_VORTEX, charge))
	{
		charge = WEP_CVAR(WEP_VORTEX, charge_mindmg) / mydmg + (1 - WEP_CVAR(WEP_VORTEX, charge_mindmg) / mydmg) * actor.(weaponentity).vortex_charge;
		actor.(weaponentity).vortex_charge *= WEP_CVAR(WEP_VORTEX, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot(actor, weaponentity, true, 5, SND_VORTEX_FIRE, CH_WEAPON_A, mydmg, dtype);
	if(charge > WEP_CVAR(WEP_VORTEX, charge_animlimit) && WEP_CVAR(WEP_VORTEX, charge_animlimit)) // if the Vortex is overcharged, we play an extra sound
	{
		sound(actor, CH_WEAPON_B, SND_VORTEX_CHARGE, VOL_BASE * (charge - 0.5 * WEP_CVAR(WEP_VORTEX, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(WEP_VORTEX, charge_animlimit)), ATTN_NORM);
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
	SendCSQCVortexBeamParticle(actor, charge);

	W_DecreaseAmmo(thiswep, actor, myammo, weaponentity);
}

.float vortex_chargepool_pauseregen_finished;

void W_Vortex_Charge(entity actor, .entity weaponentity, float dt)
{
	if(WEP_CVAR(WEP_VORTEX, charge) && actor.(weaponentity).vortex_charge < WEP_CVAR(WEP_VORTEX, charge_limit))
		actor.(weaponentity).vortex_charge = min(1, actor.(weaponentity).vortex_charge + WEP_CVAR(WEP_VORTEX, charge_rate) * dt);
}

METHOD(Vortex, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(bot_aim(actor, weaponentity, 1000000, 0, 1, false, true))
		PHYS_INPUT_BUTTON_ATCK(actor) = true;
}
METHOD(Vortex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(!WEP_CVAR(WEP_VORTEX, charge_always))
		W_Vortex_Charge(actor, weaponentity, frametime / W_TICSPERFRAME);

	if(WEP_CVAR_SEC(WEP_VORTEX, chargepool))
		if(actor.(weaponentity).vortex_chargepool_ammo < 1)
		{
			if(actor.vortex_chargepool_pauseregen_finished < time)
				actor.(weaponentity).vortex_chargepool_ammo = min(1, actor.(weaponentity).vortex_chargepool_ammo + WEP_CVAR_SEC(WEP_VORTEX, chargepool_regen) * frametime / W_TICSPERFRAME);
			actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(WEP_VORTEX, chargepool_pause_regen));
		}

	if(autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(WEP_VORTEX, ammo), WEP_CVAR_SEC(WEP_VORTEX, ammo))) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else
	{
		if(fire & 1)
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_VORTEX, refire)))
			{
				W_Vortex_Attack(thiswep, actor, weaponentity, 0);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_VORTEX, animtime), w_ready);
			}
		}
		if((WEP_CVAR(WEP_VORTEX, charge) && !WEP_CVAR(WEP_VORTEX, secondary)) ? (PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) : (fire & 2))
		{
			if(WEP_CVAR(WEP_VORTEX, charge))
			{
				actor.(weaponentity).vortex_charge_rottime = time + WEP_CVAR(WEP_VORTEX, charge_rot_pause);
				float dt = frametime / W_TICSPERFRAME;

				if(actor.(weaponentity).vortex_charge < 1)
				{
					if(WEP_CVAR_SEC(WEP_VORTEX, chargepool))
					{
						if(WEP_CVAR_SEC(WEP_VORTEX, ammo))
						{
							// always deplete if secondary is held
							actor.(weaponentity).vortex_chargepool_ammo = max(0, actor.(weaponentity).vortex_chargepool_ammo - WEP_CVAR_SEC(WEP_VORTEX, ammo) * dt);

							dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(WEP_VORTEX, charge_rate));
							actor.vortex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(WEP_VORTEX, chargepool_pause_regen);
							dt = min(dt, actor.(weaponentity).vortex_chargepool_ammo);
							dt = max(0, dt);

							actor.(weaponentity).vortex_charge += dt * WEP_CVAR(WEP_VORTEX, charge_rate);
						}
					}

					else if(WEP_CVAR_SEC(WEP_VORTEX, ammo))
					{
						if(fire & 2) // only eat ammo when the button is pressed
						{
							dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(WEP_VORTEX, charge_rate));
							if(!(actor.items & IT_UNLIMITED_AMMO))
							{
								// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
								if(autocvar_g_balance_vortex_reload_ammo)
								{
									dt = min(dt, (actor.(weaponentity).clip_load - WEP_CVAR_PRI(WEP_VORTEX, ammo)) / WEP_CVAR_SEC(WEP_VORTEX, ammo));
									dt = max(0, dt);
									if(dt > 0)
									{
										actor.(weaponentity).clip_load = max(WEP_CVAR_SEC(WEP_VORTEX, ammo), actor.(weaponentity).clip_load - WEP_CVAR_SEC(WEP_VORTEX, ammo) * dt);
									}
									actor.(weaponentity).(weapon_load[thiswep.m_id]) = actor.(weaponentity).clip_load;
								}
								else
								{
									dt = min(dt, (GetResource(actor, thiswep.ammo_type) - WEP_CVAR_PRI(WEP_VORTEX, ammo)) / WEP_CVAR_SEC(WEP_VORTEX, ammo));
									dt = max(0, dt);
									if(dt > 0)
									{
										SetResource(actor, thiswep.ammo_type, max(WEP_CVAR_SEC(WEP_VORTEX, ammo), GetResource(actor, thiswep.ammo_type) - WEP_CVAR_SEC(WEP_VORTEX, ammo) * dt));
									}
								}
							}
							actor.(weaponentity).vortex_charge += dt * WEP_CVAR(WEP_VORTEX, charge_rate);
						}
					}

					else
					{
						dt = min(dt, (1 - actor.(weaponentity).vortex_charge) / WEP_CVAR(WEP_VORTEX, charge_rate));
						actor.(weaponentity).vortex_charge += dt * WEP_CVAR(WEP_VORTEX, charge_rate);
					}
				}
			}
			else if(WEP_CVAR(WEP_VORTEX, secondary))
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(WEP_VORTEX, refire)))
				{
					W_Vortex_Attack(thiswep, actor, weaponentity, 1);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(WEP_VORTEX, animtime), w_ready);
				}
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
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_VORTEX, ammo);
	ammo_amount += (autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_VORTEX, ammo));
	return ammo_amount;
}
METHOD(Vortex, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if(WEP_CVAR(WEP_VORTEX, secondary))
	{
		// don't allow charging if we don't have enough ammo
		float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(WEP_VORTEX, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(WEP_VORTEX, ammo);
		return ammo_amount;
	}
	else
	{
		return false; // zoom is not a fire mode
	}
}
METHOD(Vortex, wr_resetplayer, void(entity thiswep, entity actor))
{
	if (WEP_CVAR(WEP_VORTEX, charge)) {
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			actor.(weaponentity).vortex_charge = WEP_CVAR(WEP_VORTEX, charge_start);

			if (WEP_CVAR_SEC(WEP_VORTEX, chargepool))
				actor.(weaponentity).vortex_chargepool_ammo = 1;
		}
	}
	actor.vortex_lasthit = 0;
}
METHOD(Vortex, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(WEP_VORTEX, ammo), WEP_CVAR_SEC(WEP_VORTEX, ammo)), SND_RELOAD);
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
	return PHYS_INPUT_BUTTON_ATCK2(actor) && !WEP_CVAR(WEP_VORTEX, secondary);
}

#endif
#ifdef CSQC

METHOD(Vortex, wr_impacteffect, void(entity thiswep, entity actor))
{
	entity this = actor;
	vector org2 = w_org + w_backoff * 2;
	bool usecolor = ((teamplay && autocvar_cl_tracers_teamcolor == 1) || autocvar_cl_tracers_teamcolor == 2);
	boxparticles(particleeffectnum(EFFECT_VORTEX_IMPACT), NULL, org2, org2, '0 0 0', '0 0 0', 1, ((usecolor) ? PARTICLES_USECOLOR : 0));
	if(!w_issilent)
		sound(this, CH_SHOTS, SND_VORTEX_IMPACT, VOL_BASE, ATTN_NORM);
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
	if(button_zoom || zoomscript_caught || (!WEP_CVAR(WEP_VORTEX, secondary) && button_attack2))
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
	return button_attack2 && !WEP_CVAR(WEP_VORTEX, secondary);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include "rifle.qh"

METHOD(Vortex, describe, string(Vortex this))
{
	TC(Vortex, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s fires harmful beams of energy that traverse the map instantaneously and deal a significant chunk of damage on impact."), COLORED_NAME(this));
	PAR(_("The secondary fire zooms in when held, allowing for ease of aiming."));
	PAR(_("It consumes %s ammo for each bullet shot."), COLORED_NAME(ITEM_Cells)); // shared string
	PAR(_("Unlike the %s, the %s doesn't need to be reloaded manually, although you have to wait a couple seconds between shots. "
	      "Uniquely, it can be fired slightly before it finishes completely reloading, albeit with the tradeoff of dealing slightly less damage."), COLORED_NAME(WEP_RIFLE), COLORED_NAME(this));
	PAR(_("Similar to the %s, the %s can be used at any range, but it stands out at long ranges."), COLORED_NAME(WEP_RIFLE), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne(this.netname, "primary"));
	return PAGE_TEXT;
}

#endif
