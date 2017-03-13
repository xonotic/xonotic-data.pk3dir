#include "okvortex.qh"

#ifdef SVQC

.float okvortex_lasthit;
#endif

#if defined(GAMEQC)

METHOD(OverkillVortex, wr_glow, vector(OverkillVortex this, entity actor, entity wepent))
{
	if (!WEP_CVAR(okvortex, charge)) return '0 0 0';
	float charge = wepent.okvortex_charge;
	float animlimit = WEP_CVAR(okvortex, charge_animlimit);
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

#ifdef SVQC
spawnfunc(weapon_okvortex) { weapon_defaultspawnfunc(this, WEP_OVERKILL_VORTEX); }

REGISTER_MUTATOR(okvortex_charge, true);

MUTATOR_HOOKFUNCTION(okvortex_charge, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	// WEAPONTODO
	if(!WEP_CVAR(okvortex, charge) || !WEP_CVAR(okvortex, charge_velocity_rate))
		return;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		if (player.(weaponentity).m_weapon == WEP_OVERKILL_VORTEX && WEP_CVAR(okvortex, charge) && WEP_CVAR(okvortex, charge_velocity_rate) && vdist(vec2(player.velocity), >, WEP_CVAR(okvortex, charge_minspeed)))
		{
			float xyspeed = vlen(vec2(player.velocity));
			// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
				xyspeed = min(xyspeed, WEP_CVAR(okvortex, charge_maxspeed));
			float f = (xyspeed - WEP_CVAR(okvortex, charge_minspeed)) / (WEP_CVAR(okvortex, charge_maxspeed) - WEP_CVAR(okvortex, charge_minspeed));
			// add the extra charge
			player.(weaponentity).okvortex_charge = min(1, player.(weaponentity).okvortex_charge + WEP_CVAR(okvortex, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
		}
	}
}

void W_OverkillVortex_Attack(Weapon thiswep, entity actor, .entity weaponentity, float issecondary)
{
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;

	mydmg = WEP_CVAR_BOTH(okvortex, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(okvortex, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(okvortex, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(okvortex, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(okvortex, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(okvortex, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(okvortex, !issecondary, ammo);

	float flying;
	flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last

	if(WEP_CVAR(okvortex, charge))
	{
		charge = WEP_CVAR(okvortex, charge_mindmg) / mydmg + (1 - WEP_CVAR(okvortex, charge_mindmg) / mydmg) * actor.(weaponentity).okvortex_charge;
		actor.(weaponentity).okvortex_charge *= WEP_CVAR(okvortex, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
		charge = 1;
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot(actor, weaponentity, true, 5, SND_NEXFIRE, CH_WEAPON_A, mydmg);
	if(charge > WEP_CVAR(okvortex, charge_animlimit) && WEP_CVAR(okvortex, charge_animlimit)) // if the OverkillVortex is overcharged, we play an extra sound
	{
		sound(actor, CH_WEAPON_B, SND_NEXCHARGE, VOL_BASE * (charge - 0.5 * WEP_CVAR(okvortex, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(okvortex, charge_animlimit)), ATTN_NORM);
	}

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet(actor, weaponentity, w_shotorg, w_shotorg + w_shotdir * max_shot_distance, mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, WEP_OVERKILL_VORTEX.m_id);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && actor.okvortex_lasthit)
	{
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	actor.okvortex_lasthit = damage_goodhits;

	//beam and muzzle flash done on client
	SendCSQCVortexBeamParticle(charge);

	W_DecreaseAmmo(thiswep, actor, myammo, weaponentity);
}

.float okvortex_chargepool_pauseregen_finished;

METHOD(OverkillVortex, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(bot_aim(actor, weaponentity, 1000000, 0, 1, false))
		PHYS_INPUT_BUTTON_ATCK(actor) = true;
	else
	{
		if(WEP_CVAR(okvortex, charge))
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
	}
}

METHOD(OverkillVortex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(WEP_CVAR(okvortex, charge) && actor.(weaponentity).okvortex_charge < WEP_CVAR(okvortex, charge_limit))
		actor.(weaponentity).okvortex_charge = min(1, actor.(weaponentity).okvortex_charge + WEP_CVAR(okvortex, charge_rate) * frametime / W_TICSPERFRAME);

	if(weaponslot(weaponentity) == 0)
		actor.okvortex_charge = actor.(weaponentity).okvortex_charge;

	if(WEP_CVAR_SEC(okvortex, chargepool))
		if(actor.(weaponentity).okvortex_chargepool_ammo < 1)
		{
			if(actor.okvortex_chargepool_pauseregen_finished < time)
				actor.(weaponentity).okvortex_chargepool_ammo = min(1, actor.(weaponentity).okvortex_chargepool_ammo + WEP_CVAR_SEC(okvortex, chargepool_regen) * frametime / W_TICSPERFRAME);
			actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(okvortex, chargepool_pause_regen));
		}

	if(weaponslot(weaponentity) == 0)
		actor.okvortex_chargepool_ammo = actor.(weaponentity).okvortex_chargepool_ammo;

	if(autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(okvortex, ammo), WEP_CVAR_SEC(okvortex, ammo))) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else
	{
		if (fire & 1)
		{
			if (weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(okvortex, refire)))
			{
				W_OverkillVortex_Attack(thiswep, actor, weaponentity, 0);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(okvortex, animtime), w_ready);
			}
		}
		else if ((fire & 2) && (WEP_CVAR(okvortex, secondary) == 2))
		{
			if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(okshotgun, refire)))
			{
				return;
			}
			// ugly instagib hack to reuse the fire mode of the laser
			makevectors(actor.v_angle);
			Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
			actor.(weaponentity).m_weapon = WEP_BLASTER;
			W_Blaster_Attack(
				actor,
				weaponentity,
				WEP_BLASTER.m_id | HITTYPE_SECONDARY,
				WEP_CVAR_SEC(okshotgun, shotangle),
				WEP_CVAR_SEC(okshotgun, damage),
				WEP_CVAR_SEC(okshotgun, edgedamage),
				WEP_CVAR_SEC(okshotgun, radius),
				WEP_CVAR_SEC(okshotgun, force),
				WEP_CVAR_SEC(okshotgun, speed),
				WEP_CVAR_SEC(okshotgun, spread),
				WEP_CVAR_SEC(okshotgun, delay),
				WEP_CVAR_SEC(okshotgun, lifetime)
			);
			actor.(weaponentity).m_weapon = oldwep;
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okshotgun, animtime), w_ready);
			return;
		}
		if((WEP_CVAR(okvortex, charge) && !WEP_CVAR(okvortex, secondary)) ? (PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) : (fire & 2))
		{
			if(WEP_CVAR(okvortex, charge))
			{
				actor.(weaponentity).okvortex_charge_rottime = time + WEP_CVAR(okvortex, charge_rot_pause);
				float dt = frametime / W_TICSPERFRAME;

				if(actor.(weaponentity).okvortex_charge < 1)
				{
					if(WEP_CVAR_SEC(okvortex, chargepool))
					{
						if(WEP_CVAR_SEC(okvortex, ammo))
						{
							// always deplete if secondary is held
							actor.okvortex_chargepool_ammo = max(0, actor.okvortex_chargepool_ammo - WEP_CVAR_SEC(okvortex, ammo) * dt);

							dt = min(dt, (1 - actor.(weaponentity).okvortex_charge) / WEP_CVAR(okvortex, charge_rate));
							actor.okvortex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(okvortex, chargepool_pause_regen);
							dt = min(dt, actor.okvortex_chargepool_ammo);
							dt = max(0, dt);

							actor.(weaponentity).okvortex_charge += dt * WEP_CVAR(okvortex, charge_rate);
						}
					}

					else if(WEP_CVAR_SEC(okvortex, ammo))
					{
						if(fire & 2) // only eat ammo when the button is pressed
						{
							dt = min(dt, (1 - actor.(weaponentity).okvortex_charge) / WEP_CVAR(okvortex, charge_rate));
							if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
							{
								// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
								if(autocvar_g_balance_vortex_reload_ammo)
								{
									dt = min(dt, (actor.(weaponentity).clip_load - WEP_CVAR_PRI(okvortex, ammo)) / WEP_CVAR_SEC(okvortex, ammo));
									dt = max(0, dt);
									if(dt > 0)
									{
										actor.(weaponentity).clip_load = max(WEP_CVAR_SEC(okvortex, ammo), actor.(weaponentity).clip_load - WEP_CVAR_SEC(okvortex, ammo) * dt);
									}
									actor.(weaponentity).(weapon_load[WEP_OVERKILL_VORTEX.m_id]) = actor.(weaponentity).clip_load;
								}
								else
								{
									dt = min(dt, (actor.(thiswep.ammo_field) - WEP_CVAR_PRI(okvortex, ammo)) / WEP_CVAR_SEC(okvortex, ammo));
									dt = max(0, dt);
									if(dt > 0)
									{
										actor.(thiswep.ammo_field) = max(WEP_CVAR_SEC(okvortex, ammo), actor.(thiswep.ammo_field) - WEP_CVAR_SEC(okvortex, ammo) * dt);
									}
								}
							}
							actor.(weaponentity).okvortex_charge += dt * WEP_CVAR(okvortex, charge_rate);
						}
					}

					else
					{
						dt = min(dt, (1 - actor.(weaponentity).okvortex_charge) / WEP_CVAR(okvortex, charge_rate));
						actor.(weaponentity).okvortex_charge += dt * WEP_CVAR(okvortex, charge_rate);
					}
				}
			}
			else if(WEP_CVAR(okvortex, secondary))
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(okvortex, refire)))
				{
					W_OverkillVortex_Attack(thiswep, actor, weaponentity, 1);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(okvortex, animtime), w_ready);
				}
			}
		}
	}
}
METHOD(OverkillVortex, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
	actor.okvortex_lasthit = 0;
}
METHOD(OverkillVortex, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_PRI(okvortex, ammo);
	ammo_amount += (autocvar_g_balance_okvortex_reload_ammo && actor.(weaponentity).(weapon_load[WEP_OVERKILL_VORTEX.m_id]) >= WEP_CVAR_PRI(okvortex, ammo));
	return ammo_amount;
}
METHOD(OverkillVortex, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if(WEP_CVAR(okvortex, secondary))
	{
		// don't allow charging if we don't have enough ammo
		float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_SEC(okvortex, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_VORTEX.m_id]) >= WEP_CVAR_SEC(okvortex, ammo);
		return ammo_amount;
	}
	else
	{
		return false; // zoom is not a fire mode
	}
}
METHOD(OverkillVortex, wr_resetplayer, void(entity thiswep, entity actor))
{
	if (WEP_CVAR(okvortex, charge)) {
		if (WEP_CVAR_SEC(okvortex, chargepool)) {
			actor.okvortex_chargepool_ammo = 1;
		}
		actor.okvortex_charge = WEP_CVAR(okvortex, charge_start);
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			actor.(weaponentity).okvortex_charge = WEP_CVAR(okvortex, charge_start);

			if (WEP_CVAR_SEC(okvortex, chargepool))
				actor.(weaponentity).okvortex_chargepool_ammo = 1;
		}
	}
	actor.okvortex_lasthit = 0;
}
METHOD(OverkillVortex, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(okvortex, ammo), WEP_CVAR_SEC(okvortex, ammo)), SND_RELOAD);
}
METHOD(OverkillVortex, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(OverkillVortex, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_VORTEX_MURDER;
}
METHOD(OverkillVortex, wr_zoom, bool(entity thiswep, entity actor))
{
	return PHYS_INPUT_BUTTON_ATCK2(actor) && !WEP_CVAR(okvortex, secondary);
}

#endif
#ifdef CSQC

METHOD(OverkillVortex, wr_impacteffect, void(entity thiswep, entity actor))
{
	entity this = actor;
	vector org2 = w_org + w_backoff * 6;
	pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(this, CH_SHOTS, SND_NEXIMPACT, VOL_BASE, ATTN_NORM);
}
METHOD(OverkillVortex, wr_init, void(entity thiswep))
{
	if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
	{
		precache_pic("gfx/reticle_nex");
	}
}
METHOD(OverkillVortex, wr_zoom, bool(entity thiswep, entity actor))
{
	if(button_zoom || zoomscript_caught || (!WEP_CVAR(okvortex, secondary) && button_attack2))
	{
		return true;
	}
	else
	{
		// no weapon specific image for this weapon
		return false;
	}
}

#endif
