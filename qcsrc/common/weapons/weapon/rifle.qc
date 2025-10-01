#include "rifle.qh"

#ifdef SVQC

void W_Rifle_FireBullet(Weapon thiswep, .entity weaponentity, int deathtype, Sound pSound, entity actor, bool isprimary)
{
	float pAmmo = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, ammo);
	float pDamage = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, damage);
	float pDF_HalfLife = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, damagefalloff_halflife);
	float pDF_ForceHalfLife = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, damagefalloff_forcehalflife);
	float pDF_MaxDist = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, damagefalloff_maxdist);
	float pDF_MinDist = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, damagefalloff_mindist);
	float pForce = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, force);
	float pHeadshotDamage = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, headshot_multiplier);
	float pShots = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, shots);
	float pSolidPenetration = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, solidpenetration);
	float pSpread = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, spread);
	float pTracer = WEP_CVAR_BOTH(WEP_RIFLE, isprimary, tracer);

	W_DecreaseAmmo(thiswep, actor, pAmmo, weaponentity);

	W_SetupShot(actor, weaponentity, true, 2, pSound, CH_WEAPON_A, pDamage * pShots, deathtype);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir * 2);

	if(PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = actor.origin + actor.view_ofs + ((w_shotorg - actor.origin - actor.view_ofs) * v_forward) * v_forward;
	}

	for(int i = 0; i < pShots; ++i)
		fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir, pSpread,
			pSolidPenetration, pDamage, pDF_HalfLife, pDF_MinDist,
			pDF_MaxDist, pHeadshotDamage, pForce, pDF_ForceHalfLife,
			deathtype, (pTracer ? EFFECT_RIFLE : EFFECT_RIFLE_WEAK), true);

	if(autocvar_g_casings >= 2)
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), vectoangles(v_forward), 3, actor, weaponentity);
	}
}

void W_Rifle_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(thiswep, weaponentity, thiswep.m_id, SND_RIFLE_FIRE, actor, true);
}

void W_Rifle_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(thiswep, weaponentity, thiswep.m_id | HITTYPE_SECONDARY, SND_RIFLE_FIRE2, actor, false);
}

.void(Weapon thiswep, entity actor, .entity weaponentity) rifle_bullethail_attackfunc;
.WFRAME rifle_bullethail_frame;
.float rifle_bullethail_animtime;
.float rifle_bullethail_refire;
void W_Rifle_BulletHail_Continue(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float r, af;

	Weapon sw = actor.(weaponentity).m_switchweapon; // make it not detect weapon changes as reason to abort firing
	af = ATTACK_FINISHED(actor, weaponentity);
	actor.(weaponentity).m_switchweapon = actor.(weaponentity).m_weapon;
	ATTACK_FINISHED(actor, weaponentity) = time;
	r = weapon_prepareattack(thiswep, actor, weaponentity, actor.rifle_bullethail_frame == WFRAME_FIRE2, actor.rifle_bullethail_refire);
	if(actor.(weaponentity).m_switchweapon == actor.(weaponentity).m_weapon)
		actor.(weaponentity).m_switchweapon = sw;
	if(r)
	{
		actor.rifle_bullethail_attackfunc(thiswep, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, actor.rifle_bullethail_frame, actor.rifle_bullethail_animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		ATTACK_FINISHED(actor, weaponentity) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
	}
}

void W_Rifle_BulletHail(Weapon thiswep, entity actor, .entity weaponentity, float mode, void(Weapon thiswep, entity actor, .entity weaponentity) AttackFunc, WFRAME fr, float animtime, float refire)
{
	// if we get here, we have at least one bullet to fire
	AttackFunc(thiswep, actor, weaponentity);
	if(mode)
	{
		// continue hail
		actor.rifle_bullethail_attackfunc = AttackFunc;
		actor.rifle_bullethail_frame = fr;
		actor.rifle_bullethail_animtime = animtime;
		actor.rifle_bullethail_refire = refire;
		weapon_thinkf(actor, weaponentity, fr, animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(actor, weaponentity, fr, animtime, w_ready);
	}
}

.float bot_secondary_riflemooth;

METHOD(Rifle, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = false;
	PHYS_INPUT_BUTTON_ATCK2(actor) = false;
	if(vdist(actor.origin - actor.enemy.origin, >, 1000))
		actor.bot_secondary_riflemooth = 0;
	if(actor.bot_secondary_riflemooth == 0)
	{
		if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, true))
		{
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
			if(random() < 0.01) actor.bot_secondary_riflemooth = 1;
		}
	}
	else
	{
		if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, true))
		{
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
			if(random() < 0.03) actor.bot_secondary_riflemooth = 0;
		}
	}
}

METHOD(Rifle, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_rifle_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(WEP_RIFLE, ammo), WEP_CVAR_SEC(WEP_RIFLE, ammo)))
	{ // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	}
	else
	{
		actor.(weaponentity).rifle_accumulator = bound(time - WEP_CVAR(WEP_RIFLE, bursttime), actor.(weaponentity).rifle_accumulator, time);
		if(fire & 1)
		if(weapon_prepareattack_check(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_RIFLE, refire)))
		if(time >= actor.(weaponentity).rifle_accumulator + WEP_CVAR_PRI(WEP_RIFLE, burstcost))
		{
			weapon_prepareattack_do(actor, weaponentity, false, WEP_CVAR_PRI(WEP_RIFLE, refire));
			W_Rifle_BulletHail(thiswep, actor, weaponentity, WEP_CVAR_PRI(WEP_RIFLE, bullethail), W_Rifle_Attack, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_RIFLE, animtime), WEP_CVAR_PRI(WEP_RIFLE, refire));
			actor.(weaponentity).rifle_accumulator += WEP_CVAR_PRI(WEP_RIFLE, burstcost);
		}
		if(fire & 2)
		{
			if(WEP_CVAR(WEP_RIFLE, secondary))
			{
				if(WEP_CVAR_SEC(WEP_RIFLE, reload)) {
					thiswep.wr_reload(thiswep, actor, weaponentity);
				}
				else
				{
					if(weapon_prepareattack_check(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_RIFLE, refire)))
					if(time >= actor.(weaponentity).rifle_accumulator + WEP_CVAR_SEC(WEP_RIFLE, burstcost))
					{
						weapon_prepareattack_do(actor, weaponentity, true, WEP_CVAR_SEC(WEP_RIFLE, refire));
						W_Rifle_BulletHail(thiswep, actor, weaponentity, WEP_CVAR_SEC(WEP_RIFLE, bullethail), W_Rifle_Attack2, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_RIFLE, animtime), WEP_CVAR_PRI(WEP_RIFLE, refire));
						actor.(weaponentity).rifle_accumulator += WEP_CVAR_SEC(WEP_RIFLE, burstcost);
					}
				}
			}
		}
	}
}

METHOD(Rifle, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_RIFLE, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_RIFLE, ammo);
	return ammo_amount;
}

METHOD(Rifle, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(WEP_RIFLE, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(WEP_RIFLE, ammo);
	return ammo_amount;
}

METHOD(Rifle, wr_resetplayer, void(entity thiswep, entity actor))
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		actor.(weaponentity).rifle_accumulator = time - WEP_CVAR(WEP_RIFLE, bursttime);
	}
}

METHOD(Rifle, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(WEP_RIFLE, ammo), WEP_CVAR_SEC(WEP_RIFLE, ammo)), SND_RELOAD);
}

METHOD(Rifle, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(Rifle, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
	{
		if(w_deathtype & HITTYPE_BOUNCE)
			return WEAPON_RIFLE_MURDER_HAIL_PIERCING;
		else
			return WEAPON_RIFLE_MURDER_HAIL;
	}
	else
	{
		if(w_deathtype & HITTYPE_BOUNCE)
			return WEAPON_RIFLE_MURDER_PIERCING;
		else
			return WEAPON_RIFLE_MURDER;
	}
}

METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
	return PHYS_INPUT_BUTTON_ATCK2(actor) && WEP_CVAR(WEP_RIFLE, secondary) == 0;
}

#endif
#ifdef CSQC

METHOD(Rifle, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_RIFLE_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent)
	{
		sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
	}
}

METHOD(Rifle, wr_init, void(entity thiswep))
{
	if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
	{
		precache_pic("gfx/reticle_nex");
	}
}

METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
	if(button_zoom || zoomscript_caught)
	{
		return true;
	}
	else
	{
		// no weapon specific image for this weapon
		return false;
	}
}

METHOD(Rifle, wr_zoomdir, bool(entity thiswep))
{
	return button_attack2 && !WEP_CVAR(WEP_RIFLE, secondary);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include "vortex.qh"

METHOD(Rifle, describe, string(Rifle this))
{
	TC(Rifle, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s fires bullets that traverse the map instantaneously and deal a significant chunk of damage on impact."), COLORED_NAME(this));
	PAR(_("The secondary fire shoots a few less powerful bullets at once with a bit of scatter."));
	PAR(_("It consumes %s ammo for each bullet shot."), COLORED_NAME(ITEM_Bullets)); // shared string
	PAR(_("Unlike the %s, the secondary fire doesn't zoom, so %s needs to be used manually with the %s. "
	      "Also, it needs to be reloaded after its magazine is emptied."), COLORED_NAME(WEP_VORTEX), strcat("^3", _("zoom"), "^7"), COLORED_NAME(this));
	PAR(_("Similar to the %s, the %s can be used at any range, but it stands out at long ranges."), COLORED_NAME(WEP_VORTEX), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_secondaryMultishot(this.netname, "primary", "secondary", "secondary_shots", "", false));
	return PAGE_TEXT;
}

#endif
