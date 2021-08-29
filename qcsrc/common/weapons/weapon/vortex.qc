#include "vortex.qh"

//REGISTER_STAT(WEP_CVAR_vortex_charge, bool, WEP_CVAR(vortex, charge))
//REGISTER_STAT(WEP_CVAR_vortex_charge_animlimit, float, WEP_CVAR(vortex, charge_animlimit))

#if defined(GAMEQC)
float autocvar_g_weapon_charge_colormod_red_full;
float autocvar_g_weapon_charge_colormod_red_half;
float autocvar_g_weapon_charge_colormod_green_full;
float autocvar_g_weapon_charge_colormod_blue_full;
float autocvar_g_weapon_charge_colormod_blue_half;
float autocvar_g_weapon_charge_colormod_green_half;
float autocvar_g_weapon_charge_colormod_hdrmultiplier;

METHOD(Vortex, wr_glow, vector(Vortex this, entity actor, entity wepent))
{
	if (!WEP_CVAR(vortex, charge)) return '0 0 0';
	float charge = wepent.vortex_charge;
	float animlimit = WEP_CVAR(vortex, charge_animlimit);
	float f = autocvar_g_weapon_charge_colormod_hdrmultiplier * min(1, charge / animlimit);
	vector g;
	g.x = f * autocvar_g_weapon_charge_colormod_red_half;
	g.y = f * autocvar_g_weapon_charge_colormod_green_half;
	g.z = f * autocvar_g_weapon_charge_colormod_blue_half;
	if (charge > animlimit)
	{
		f = autocvar_g_weapon_charge_colormod_hdrmultiplier * (charge - animlimit) / (1 - animlimit);
		g.x += f * autocvar_g_weapon_charge_colormod_red_full;
		g.y += f * autocvar_g_weapon_charge_colormod_green_full;
		g.z += f * autocvar_g_weapon_charge_colormod_blue_full;
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
}

.float vortex_chargepool_pauseregen_finished;

void W_Vortex_Charge(entity actor, .entity weaponentity, float dt)
{
    if(WEP_CVAR(vortex, charge) && actor.(weaponentity).vortex_charge < WEP_CVAR(vortex, charge_limit))
        actor.(weaponentity).vortex_charge = min(1, actor.(weaponentity).vortex_charge + WEP_CVAR(vortex, charge_rate) * dt);
}

METHOD(Vortex, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(bot_aim(actor, weaponentity, 1000000, 0, 1, false))
        PHYS_INPUT_BUTTON_ATCK(actor) = true;
    else
    {
        if(WEP_CVAR(vortex, charge))
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
    }
}
METHOD(Vortex, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(!WEP_CVAR(vortex, charge_always))
        W_Vortex_Charge(actor, weaponentity, frametime / W_TICSPERFRAME);

    if(WEP_CVAR_SEC(vortex, chargepool))
        if(actor.(weaponentity).vortex_chargepool_ammo < 1)
        {
            if(actor.vortex_chargepool_pauseregen_finished < time)
                actor.(weaponentity).vortex_chargepool_ammo = min(1, actor.(weaponentity).vortex_chargepool_ammo + WEP_CVAR_SEC(vortex, chargepool_regen) * frametime / W_TICSPERFRAME);
            actor.pauseregen_finished = max(actor.pauseregen_finished, time + WEP_CVAR_SEC(vortex, chargepool_pause_regen));
        }

    if(autocvar_g_balance_vortex_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(vortex, ammo), WEP_CVAR_SEC(vortex, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else
    {
        if(fire & 1)
        {
            if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(vortex, refire)))
            {
                W_Vortex_Attack(thiswep, actor, weaponentity, 0);
                weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(vortex, animtime), w_ready);
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
                    weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(vortex, animtime), w_ready);
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
