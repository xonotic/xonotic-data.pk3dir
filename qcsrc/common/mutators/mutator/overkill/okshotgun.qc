#include "okshotgun.qh"

#ifdef SVQC
METHOD(OverkillShotgun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if (vdist(actor.origin - actor.enemy.origin, >, WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, bot_range)))
	{
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, false);
	}
	else
	{
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, false);
	}
}

METHOD(OverkillShotgun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(WEP_OVERKILL_SHOTGUN, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
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
	if (WEP_CVAR(WEP_OVERKILL_SHOTGUN, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, ammo))
	{
		// Forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, refire)))
		{
			return;
		}
		W_Shotgun_Attack(thiswep, actor, weaponentity, true,
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, ammo),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, damage),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, damagefalloff_halflife),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, damagefalloff_mindist),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, damagefalloff_maxdist),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, bullets),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, spread),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, spread_pattern),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, spread_pattern_scale),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, spread_pattern_bias),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, solidpenetration),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, force),
			WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, damagefalloff_forcehalflife),
			EFFECT_RIFLE_WEAK);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, animtime), w_ready);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(WEP_OVERKILL_SHOTGUN, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_BLASTER, refire)))
		{
			return;
		}
		makevectors(actor.v_angle);
		W_Blaster_Attack(actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
	}
}

METHOD(OverkillShotgun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_SHOTGUN.m_id]) >= WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, ammo);
	return ammo_amount;
}

METHOD(OverkillShotgun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // Blaster secondary is unlimited.
}

METHOD(OverkillShotgun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(WEP_OVERKILL_SHOTGUN, ammo), SND_RELOAD); // WEAPONTODO
}

METHOD(OverkillShotgun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillShotgun, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_OVERKILL_SHOTGUN_MURDER;
}

#endif
#ifdef CSQC
.float prevric;

METHOD(OverkillShotgun, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_SHOTGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent && time - actor.prevric > 0.25)
	{
		if(w_random < 0.05)
			sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
		actor.prevric = time;
	}
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include <common/mutators/mutator/overkill/overkill.qh>

METHOD(OverkillShotgun, describe, string(OverkillShotgun this))
{
	TC(OverkillShotgun, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s fires a single shotgun round which spreads into multiple pellets upon exiting the barrel, dealing a deadly blow if up close."), COLORED_NAME(this));
	PAR(_("Like with all %s weapons, the secondary fire shoots a laser which doesn't damage or push enemies, but can be used to push yourself around."), COLORED_NAME(MUTATOR_ok));
	PAR(_("The primary fire consumes %s ammo, although you spawn with an infinite amount of it in %s. "
	      "It has a limited magazine size, so needs reloading after several shots."), COLORED_NAME(ITEM_Shells), COLORED_NAME(MUTATOR_ok));
	PAR(_("The %s damage drops off quickly as the range increases, so it is only useful for close combat or sometimes medium range combat."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOneMultishot(this.netname, "primary", "primary_bullets", ""));
	return PAGE_TEXT;
}

#endif
