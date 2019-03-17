#include "machinegun.qh"

#ifdef SVQC

METHOD(MachineGun, m_spawnfunc_hookreplace, Weapon(MachineGun this, entity e))
{
	if (autocvar_sv_q3acompat_machineshotgunswap && !Item_IsLoot(e))
	{
		return WEP_SHOCKWAVE;
	}
	return this;
}

void W_MachineGun_MuzzleFlash_Think(entity this)
{
	this.frame += 2;
	this.scale *= 0.5;
	this.alpha -= 0.25;
	this.nextthink = time + 0.05;

	if(this.alpha <= 0)
	{
		setthink(this, SUB_Remove);
		this.nextthink = time;
		this.realowner.muzzle_flash = NULL;
		return;
	}

}

void W_MachineGun_MuzzleFlash(entity actor, .entity weaponentity)
{
	entity wepent = actor.(weaponentity);

	if(wepent.muzzle_flash == NULL)
		wepent.muzzle_flash = spawn();

	// muzzle flash for 1st person view
	setmodel(wepent.muzzle_flash, MDL_MACHINEGUN_MUZZLEFLASH); // precision set below

	wepent.muzzle_flash.scale = 0.75;
	setthink(wepent.muzzle_flash, W_MachineGun_MuzzleFlash_Think);
	wepent.muzzle_flash.nextthink = time + 0.02;
	wepent.muzzle_flash.frame = 2;
	wepent.muzzle_flash.alpha = 0.75;
	wepent.muzzle_flash.angles_z = random() * 180;
	wepent.muzzle_flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	wepent.muzzle_flash.owner = wepent.muzzle_flash.realowner = wepent;
}

void W_MachineGun_Attack(Weapon thiswep, int deathtype, entity actor, .entity weaponentity)
{
	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, ((actor.(weaponentity).misc_bulletcounter == 1) ? WEP_CVAR(machinegun, first_damage) : WEP_CVAR(machinegun, sustained_damage)), deathtype);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}
	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor(actor);

	if(actor.(weaponentity).misc_bulletcounter == 1)
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, WEP_CVAR(machinegun, first_spread), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, first_damage), WEP_CVAR(machinegun, first_force), deathtype, EFFECT_BULLET);
	else
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, WEP_CVAR(machinegun, sustained_spread), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), deathtype, EFFECT_BULLET);

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	// casing code
	if(autocvar_g_casings >= 2)
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	if(actor.(weaponentity).misc_bulletcounter == 1)
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, first_ammo), weaponentity);
	else
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, sustained_ammo), weaponentity);
}

// weapon frames
void W_MachineGun_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(actor.(weaponentity).m_weapon != actor.(weaponentity).m_switchweapon || !weapon_prepareattack_check(thiswep, actor, weaponentity, (fire & 2), -1)) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}
	if(PHYS_INPUT_BUTTON_ATCK(actor))
	{
		if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}
		actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;
		W_MachineGun_Attack(thiswep, thiswep.m_id, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
	}
	else
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), w_ready);
}


void W_MachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float machinegun_spread;

	if(!(fire & 1) || !weapon_prepareattack_check(thiswep, actor, weaponentity, false, -1))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(!thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, sustained_ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR(machinegun, sustained_damage), thiswep.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	machinegun_spread = bound(WEP_CVAR(machinegun, spread_min), WEP_CVAR(machinegun, spread_min) + (WEP_CVAR(machinegun, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR(machinegun, spread_max));
	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, machinegun_spread, WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), thiswep.m_id, EFFECT_BULLET);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Auto);
}

void W_MachineGun_Attack_Burst(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR(machinegun, sustained_damage), thiswep.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, WEP_CVAR(machinegun, burst_speed), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), thiswep.m_id, EFFECT_BULLET);

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;
	if(actor.(weaponentity).misc_bulletcounter == 0)
	{
		ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(machinegun, burst_refire2) * W_WeaponRateFactor(actor);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_animtime), w_ready);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_refire), W_MachineGun_Attack_Burst);
	}

}

METHOD(MachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
    else
        PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
}
METHOD(MachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(WEP_CVAR(machinegun, reload_ammo) && actor.(weaponentity).clip_load < min(max(WEP_CVAR(machinegun, sustained_ammo), WEP_CVAR(machinegun, first_ammo)), WEP_CVAR(machinegun, burst_ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else
    if(WEP_CVAR(machinegun, mode) == 1)
    {
        if(fire & 1)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
        {
            actor.(weaponentity).misc_bulletcounter = 0;
            W_MachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
        }

        if(fire & 2)
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
        {
            if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
            if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
            {
                W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
                w_ready(thiswep, actor, weaponentity, fire);
                return;
            }

            W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, burst_ammo), weaponentity);

            actor.(weaponentity).misc_bulletcounter = WEP_CVAR(machinegun, burst) * -1;
            W_MachineGun_Attack_Burst(thiswep, actor, weaponentity, fire);
        }
    }
    else
    {

        if(fire & 1)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
        {
            actor.(weaponentity).misc_bulletcounter = 1;
            W_MachineGun_Attack(thiswep, thiswep.m_id, actor, weaponentity); // sets attack_finished
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
        }

        if((fire & 2) && WEP_CVAR(machinegun, first))
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
        {
            actor.(weaponentity).misc_bulletcounter = 1;
            W_MachineGun_Attack(thiswep, thiswep.m_id | HITTYPE_SECONDARY, actor, weaponentity); // sets attack_finished
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, first_refire), w_ready);
        }
    }
}
METHOD(MachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount;
    if(WEP_CVAR(machinegun, mode) == 1)
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(machinegun, sustained_ammo);
    else
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(machinegun, first_ammo);

    if(WEP_CVAR(machinegun, reload_ammo))
    {
        if(WEP_CVAR(machinegun, mode) == 1)
            ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(machinegun, sustained_ammo);
        else
            ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(machinegun, first_ammo);
    }
    return ammo_amount;
}
METHOD(MachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount;
    if(WEP_CVAR(machinegun, mode) == 1)
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(machinegun, burst_ammo);
    else
        ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(machinegun, first_ammo);

    if(WEP_CVAR(machinegun, reload_ammo))
    {
        if(WEP_CVAR(machinegun, mode) == 1)
            ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(machinegun, burst_ammo);
        else
            ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(machinegun, first_ammo);
    }
    return ammo_amount;
}
METHOD(MachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(max(WEP_CVAR(machinegun, sustained_ammo), WEP_CVAR(machinegun, first_ammo)), WEP_CVAR(machinegun, burst_ammo)), SND_RELOAD);
}
METHOD(MachineGun, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(MachineGun, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_MACHINEGUN_MURDER_SNIPE;
    else
        return WEAPON_MACHINEGUN_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(MachineGun, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
}

#endif
