#include "oknex.qh"

#ifdef SVQC

.float oknex_lasthit;
#endif

#if defined(GAMEQC)

METHOD(OverkillNex, wr_glow, vector(OverkillNex this, int actor_colors, entity wepent))
{
	if (!WEP_CVAR(WEP_OVERKILL_NEX, charge)) return '0 0 0';
	float charge = max(0.25, wepent.oknex_charge);
	float animlimit = WEP_CVAR(WEP_OVERKILL_NEX, charge_animlimit);
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

#ifdef SVQC
REGISTER_MUTATOR(oknex_charge, true);

MUTATOR_HOOKFUNCTION(oknex_charge, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);

	// WEAPONTODO
	if(!WEP_CVAR(WEP_OVERKILL_NEX, charge) || !WEP_CVAR(WEP_OVERKILL_NEX, charge_velocity_rate))
		return;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		if (player.(weaponentity).m_weapon == WEP_OVERKILL_NEX && WEP_CVAR(WEP_OVERKILL_NEX, charge) && WEP_CVAR(WEP_OVERKILL_NEX, charge_velocity_rate) && vdist(vec2(player.velocity), >, WEP_CVAR(WEP_OVERKILL_NEX, charge_minspeed)))
		{
			float xyspeed = vlen(vec2(player.velocity));
			// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
				xyspeed = min(xyspeed, WEP_CVAR(WEP_OVERKILL_NEX, charge_maxspeed));
			float f = (xyspeed - WEP_CVAR(WEP_OVERKILL_NEX, charge_minspeed)) / (WEP_CVAR(WEP_OVERKILL_NEX, charge_maxspeed) - WEP_CVAR(WEP_OVERKILL_NEX, charge_minspeed));
			// add the extra charge
			player.(weaponentity).oknex_charge = min(1, player.(weaponentity).oknex_charge + WEP_CVAR(WEP_OVERKILL_NEX, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
		}
	}
}

void W_OverkillNex_Attack(Weapon thiswep, entity actor, .entity weaponentity, float issecondary)
{
	float mydmg, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, myammo, charge;

	mydmg = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, damage);
	myforce = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, force);
	mymindist = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, damagefalloff_mindist);
	mymaxdist = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, damagefalloff_maxdist);
	myhalflife = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, damagefalloff_halflife);
	myforcehalflife = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, damagefalloff_forcehalflife);
	myammo = WEP_CVAR_BOTH(WEP_OVERKILL_NEX, !issecondary, ammo);

	float flying;
	flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last

	if (WEP_CVAR(WEP_OVERKILL_NEX, charge))
	{
		charge = WEP_CVAR(WEP_OVERKILL_NEX, charge_mindmg) / mydmg + (1 - WEP_CVAR(WEP_OVERKILL_NEX, charge_mindmg) / mydmg) * actor.(weaponentity).oknex_charge;
		actor.(weaponentity).oknex_charge *= WEP_CVAR(WEP_OVERKILL_NEX, charge_shot_multiplier); // do this AFTER setting mydmg/myforce
		// O RLY? -- divVerent
		// YA RLY -- FruitieX
	}
	else
	{
		charge = 1;
	}
	mydmg *= charge;
	myforce *= charge;

	W_SetupShot(actor, weaponentity, true, 5, SND_OK_NEX_FIRE, CH_WEAPON_A, mydmg, thiswep.m_id);
	if(charge > WEP_CVAR(WEP_OVERKILL_NEX, charge_animlimit) && WEP_CVAR(WEP_OVERKILL_NEX, charge_animlimit)) // if the OverkillNex is overcharged, we play an extra sound
	{
		sound(actor, CH_WEAPON_B, SND_OK_NEX_CHARGE, VOL_BASE * (charge - 0.5 * WEP_CVAR(WEP_OVERKILL_NEX, charge_animlimit)) / (1 - 0.5 * WEP_CVAR(WEP_OVERKILL_NEX, charge_animlimit)), ATTN_NORM);
	}

	yoda = 0;
	impressive_hits = 0;
	FireRailgunBullet(actor, weaponentity, w_shotorg, w_shotorg + w_shotdir * max_shot_distance, mydmg, true, myforce, mymindist, mymaxdist, myhalflife, myforcehalflife, thiswep.m_id);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(impressive_hits && actor.oknex_lasthit)
	{
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		impressive_hits = 0; // only every second time
	}

	actor.oknex_lasthit = impressive_hits;

	//beam and muzzle flash done on client
	SendCSQCVortexBeamParticle(actor, charge);

	W_DecreaseAmmo(thiswep, actor, myammo, weaponentity);
}

.float oknex_chargepool_pauseregen_finished;

METHOD(OverkillNex, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(bot_aim(actor, weaponentity, 1000000, 0, 1, false, true))
		PHYS_INPUT_BUTTON_ATCK(actor) = true;
	else
	{
		if(WEP_CVAR(WEP_OVERKILL_NEX, charge))
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
	}
}

METHOD(OverkillNex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if (WEP_CVAR(WEP_OVERKILL_NEX, charge) && actor.(weaponentity).oknex_charge < WEP_CVAR(WEP_OVERKILL_NEX, charge_limit))
	{
		actor.(weaponentity).oknex_charge = min(1, actor.(weaponentity).oknex_charge + WEP_CVAR(WEP_OVERKILL_NEX, charge_rate) * frametime / W_TICSPERFRAME);
	}

	if (WEP_CVAR_SEC(WEP_OVERKILL_NEX, chargepool))
		if (actor.(weaponentity).oknex_chargepool_ammo < 1)
		{
			if (actor.oknex_chargepool_pauseregen_finished < time)
				actor.(weaponentity).oknex_chargepool_ammo = min(1, actor.(weaponentity).oknex_chargepool_ammo + WEP_CVAR_SEC(WEP_OVERKILL_NEX, chargepool_regen) * frametime / W_TICSPERFRAME);
			actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(WEP_OVERKILL_NEX, chargepool_pause_regen));
		}

	if ((WEP_CVAR_SEC(WEP_OVERKILL_NEX, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_PRI(WEP_BLASTER, refire) * W_WeaponRateFactor(actor);
		makevectors(actor.v_angle);
		W_Blaster_Attack(actor, weaponentity);
		if ((actor.(weaponentity).wframe == WFRAME_IDLE) ||
			(actor.(weaponentity).wframe == WFRAME_FIRE2))
		{
			// Set secondary fire animation.
			actor.(weaponentity).wframe = WFRAME_FIRE2;
			FOREACH_CLIENT(true, LAMBDA(
				if (it == actor || (IS_SPEC(it) && it.enemy == actor))
				{
					wframe_send(it, actor.(weaponentity), WFRAME_FIRE2, autocvar_g_weaponratefactor, true);
				}
			));
			animdecide_setaction(actor, ANIMACTION_SHOOT, true);
		}
	}

	if (autocvar_g_balance_oknex_reload_ammo && actor.(weaponentity).clip_load < WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo))
	{
		// Rorced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_OVERKILL_NEX, refire)))
		{
			return;
		}
		W_OverkillNex_Attack(thiswep, actor, weaponentity, 0);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_OVERKILL_NEX, animtime), w_ready);
		return;
	}
	if ((fire & 2) && (WEP_CVAR(WEP_OVERKILL_NEX, secondary) == 2) && (WEP_CVAR_SEC(WEP_OVERKILL_NEX, refire_type) == 0))
	{
		// Secondary attack
		if (!weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_PRI(WEP_BLASTER, refire)))
		{
			return;
		}
		makevectors(actor.v_angle);
		W_Blaster_Attack(actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
		return;
	}

#if 0
	if ((WEP_CVAR(WEP_OVERKILL_NEX, charge) && (WEP_CVAR(WEP_OVERKILL_NEX, secondary) == 1)) ? (PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) : (fire & 2))
	{
		if(WEP_CVAR(WEP_OVERKILL_NEX, charge))
		{
			actor.(weaponentity).oknex_charge_rottime = time + WEP_CVAR(WEP_OVERKILL_NEX, charge_rot_pause);
			float dt = frametime / W_TICSPERFRAME;
	
			if(actor.(weaponentity).oknex_charge < 1)
			{
				if(WEP_CVAR_SEC(WEP_OVERKILL_NEX, chargepool))
				{
					if(WEP_CVAR_PRI(WEP_BLASTER, ammo))
					{
						// always deplete if secondary is held
						actor.(weaponentity).oknex_chargepool_ammo = max(0, actor.(weaponentity).oknex_chargepool_ammo - WEP_CVAR_PRI(WEP_BLASTER, ammo) * dt);

						dt = min(dt, (1 - actor.(weaponentity).oknex_charge) / WEP_CVAR(WEP_OVERKILL_NEX, charge_rate));
						actor.oknex_chargepool_pauseregen_finished = time + WEP_CVAR_SEC(WEP_OVERKILL_NEX, chargepool_pause_regen);
						dt = min(dt, actor.(weaponentity).oknex_chargepool_ammo);
						dt = max(0, dt);

						actor.(weaponentity).oknex_charge += dt * WEP_CVAR(WEP_OVERKILL_NEX, charge_rate);
					}
				}

				else if(WEP_CVAR_PRI(WEP_BLASTER, ammo))
				{
					if(fire & 2) // only eat ammo when the button is pressed
					{
						dt = min(dt, (1 - actor.(weaponentity).oknex_charge) / WEP_CVAR(WEP_OVERKILL_NEX, charge_rate));
						if(!(actor.items & IT_UNLIMITED_AMMO))
						{
							// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
							if(autocvar_g_balance_vortex_reload_ammo)
							{
								dt = min(dt, (actor.(weaponentity).clip_load - WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo)) / WEP_CVAR_PRI(WEP_BLASTER, ammo));
								dt = max(0, dt);
								if(dt > 0)
								{
									actor.(weaponentity).clip_load = max(WEP_CVAR_PRI(WEP_BLASTER, ammo), actor.(weaponentity).clip_load - WEP_CVAR_PRI(WEP_BLASTER, ammo) * dt);
								}
								actor.(weaponentity).(weapon_load[WEP_OVERKILL_NEX.m_id]) = actor.(weaponentity).clip_load;
							}
							else
							{
								dt = min(dt, (actor.(thiswep.ammo_field) - WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo)) / WEP_CVAR_PRI(WEP_BLASTER, ammo));
								dt = max(0, dt);
								if(dt > 0)
								{
									actor.(thiswep.ammo_field) = max(WEP_CVAR_PRI(WEP_BLASTER, ammo), actor.(thiswep.ammo_field) - WEP_CVAR_PRI(WEP_BLASTER, ammo) * dt);
								}
							}
						}
						actor.(weaponentity).oknex_charge += dt * WEP_CVAR(WEP_OVERKILL_NEX, charge_rate);
					}
				}

				else
				{
					dt = min(dt, (1 - actor.(weaponentity).oknex_charge) / WEP_CVAR(WEP_OVERKILL_NEX, charge_rate));
					actor.(weaponentity).oknex_charge += dt * WEP_CVAR(WEP_OVERKILL_NEX, charge_rate);
				}
			}
		}
		else if(WEP_CVAR(WEP_OVERKILL_NEX, secondary))
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_BLASTER, refire)))
			{
				W_OverkillNex_Attack(thiswep, actor, weaponentity, 1);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
			}
		}
	}
#endif
}

METHOD(OverkillNex, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
	actor.oknex_lasthit = 0;
}

METHOD(OverkillNex, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo);
	ammo_amount += (autocvar_g_balance_oknex_reload_ammo && actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo));
	return ammo_amount;
}

METHOD(OverkillNex, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if (WEP_CVAR(WEP_OVERKILL_NEX, secondary))
	{
		// don't allow charging if we don't have enough ammo
		float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_BLASTER, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_BLASTER, ammo);
		return ammo_amount;
	}
	else
	{
		return false; // zoom is not a fire mode
	}
}

METHOD(OverkillNex, wr_resetplayer, void(entity thiswep, entity actor))
{
	if (WEP_CVAR(WEP_OVERKILL_NEX, charge)) {
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			actor.(weaponentity).oknex_charge = WEP_CVAR(WEP_OVERKILL_NEX, charge_start);
		}
	}
	actor.oknex_lasthit = 0;
}

METHOD(OverkillNex, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(WEP_OVERKILL_NEX, ammo), SND_RELOAD);
}

METHOD(OverkillNex, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillNex, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_OVERKILL_NEX_MURDER;
}

METHOD(OverkillNex, wr_zoom, bool(entity thiswep, entity actor))
{
	return PHYS_INPUT_BUTTON_ATCK2(actor) && !WEP_CVAR(WEP_OVERKILL_NEX, secondary);
}

#endif
#ifdef CSQC

METHOD(OverkillNex, wr_impacteffect, void(entity thiswep, entity actor))
{
	entity this = actor;
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(this, CH_SHOTS, SND_OK_NEX_IMPACT, VOL_BASE, ATTN_NORM);
}

METHOD(OverkillNex, wr_init, void(entity thiswep))
{
	if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
	{
		precache_pic("gfx/reticle_nex");
	}
}

METHOD(OverkillNex, wr_zoom, bool(entity thiswep, entity actor))
{
	if(button_zoom || zoomscript_caught || (!WEP_CVAR(WEP_OVERKILL_NEX, secondary) && button_attack2))
	{
		return true;
	}
	else
	{
		// no weapon specific image for this weapon
		return false;
	}
}

METHOD(OverkillNex, wr_zoomdir, bool(entity thiswep))
{
    return button_attack2 && !WEP_CVAR(WEP_OVERKILL_NEX, secondary);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include <common/mutators/mutator/overkill/overkill.qh>

METHOD(OverkillNex, describe, string(OverkillNex this))
{
	TC(OverkillNex, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s fires harmful beams of energy that traverse the map instantaneously and deal a significant chunk of damage on impact."), COLORED_NAME(this));
	PAR(_("Like with all %s weapons, the secondary fire shoots a laser which doesn't damage or push enemies, but can be used to push yourself around."), COLORED_NAME(MUTATOR_ok));
	PAR(_("The primary fire consumes %s ammo, although you spawn with an infinite amount of it in %s. "
	      "It has a limited magazine size, so needs reloading after several shots."), COLORED_NAME(ITEM_Cells), COLORED_NAME(MUTATOR_ok));
	PAR(_("Since it is the only %s weapon with no spread, the %s stands out at long ranges."), COLORED_NAME(MUTATOR_ok), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne(this.netname, "primary"));
	return PAGE_TEXT;
}

#endif
