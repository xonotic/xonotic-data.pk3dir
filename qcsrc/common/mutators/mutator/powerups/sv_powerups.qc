#include "sv_powerups.qh"

MUTATOR_HOOKFUNCTION(powerups, W_PlayStrengthSound)
{
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Strength, player)
		&& ((time > player.prevstrengthsound + autocvar_sv_strengthsound_antispam_time) // prevent insane sound spam
		|| (time > player.prevstrengthsoundattempt + autocvar_sv_strengthsound_antispam_refire_threshold)))
		{
			sound(player, CH_TRIGGER, SND_STRENGTH_FIRE, VOL_BASE, ATTEN_NORM);
			player.prevstrengthsound = time;
		}
	player.prevstrengthsoundattempt = time;
}

MUTATOR_HOOKFUNCTION(powerups, LogDeath_AppendItemCodes)
{
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Strength, player))
		M_ARGV(1, string) = strcat(M_ARGV(1, string), "S");

	if(StatusEffects_active(STATUSEFFECT_Shield, player))
		M_ARGV(1, string) = strcat(M_ARGV(1, string), "I");

	// TODO: item codes for other powerups?
}

MUTATOR_HOOKFUNCTION(powerups, Damage_Calculate)
{
	entity attacker = M_ARGV(1, entity);
	entity targ = M_ARGV(2, entity);

	// apply strength multiplier
	if(StatusEffects_active(STATUSEFFECT_Strength, attacker))
	{
		if(targ == attacker)
		{
			M_ARGV(4, float) = M_ARGV(4, float) * autocvar_g_balance_powerup_strength_selfdamage;
			M_ARGV(6, vector) = M_ARGV(6, vector) * autocvar_g_balance_powerup_strength_selfforce;
		}
		else
		{
			M_ARGV(4, float) = M_ARGV(4, float) * autocvar_g_balance_powerup_strength_damage;
			M_ARGV(6, vector) = M_ARGV(6, vector) * autocvar_g_balance_powerup_strength_force;
		}
	}

	// apply shield multiplier
	if(StatusEffects_active(STATUSEFFECT_Shield, targ))
	{
		M_ARGV(4, float) = M_ARGV(4, float) * autocvar_g_balance_powerup_invincible_takedamage;
		if (targ != attacker)
		{
			M_ARGV(6, vector) = M_ARGV(6, vector) * autocvar_g_balance_powerup_invincible_takeforce;
		}
	}
}

MUTATOR_HOOKFUNCTION(powerups, CustomizeWaypoint)
{
	entity wp = M_ARGV(0, entity);
	entity player = M_ARGV(1, entity);

	entity e = WaypointSprite_getviewentity(player);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if(IS_CLIENT(wp.owner) && (e == player) && DIFF_TEAM(wp.owner, e) && StatusEffects_active(STATUSEFFECT_Invisibility, wp.owner))
		return true;
}

MUTATOR_HOOKFUNCTION(powerups, MonsterValidTarget)
{
	entity targ = M_ARGV(1, entity);
	return StatusEffects_active(STATUSEFFECT_Invisibility, targ);
}

void powerups_DropItem_Think(entity this)
{
	TakeResource(this, RES_HEALTH, 1);
	
	if(GetResource(this, RES_HEALTH) < 1) {
		WaypointSprite_Kill(this.waypointsprite_attached);
		delete(this);
		return;
	}
	
	// Only needed to update if the timer of the powerup is running
	if(autocvar_g_powerups_drop_ondeath == 1)
		WaypointSprite_UpdateHealth(this.waypointsprite_attached, GetResource(this, RES_HEALTH));
	
	this.nextthink = time + 1;
}

void powerups_DropItem(entity this, StatusEffects effect)
{
	entity item = Item_DefinitionFromInternalName(effect.netname);
	float t = StatusEffects_gettime(effect, this);
	float timeleft = t - time;
	float maxtime = 0;

	if(timeleft <= 1 || !item)
		return;
	entity e = spawn();

	// If we want the timer to keep running, we enable expiring then use the exact time the powerup will finish at.
	// If we want the timer to freeze, we disable expiring and we just use the time left of the powerup.
	// See Item_SetExpiring() below.
	float finished = (autocvar_g_powerups_drop_ondeath == 2 ? timeleft : t);

	// If the timer is frozen, the item will stay on the floor for 20 secs (same as weapons),
	// otherwise it'll disappear after the timer runs out.
	float time_to_live = (autocvar_g_powerups_drop_ondeath == 2 ? autocvar_g_items_dropped_lifetime : timeleft);

	// TODO: items cannot hold their "item field" yet, so we need to list all the powerups here!
	switch(item)
	{
		case ITEM_Strength: e.strength_finished = finished; maxtime = autocvar_g_balance_powerup_strength_time; break;
		case ITEM_Shield: e.invincible_finished = finished; maxtime = autocvar_g_balance_powerup_invincible_time; break;
		case ITEM_Invisibility: e.invisibility_finished = finished; maxtime = autocvar_g_balance_powerup_invincible_time; break;
		case ITEM_Speed: e.speed_finished = finished; maxtime = autocvar_g_balance_powerup_speed_time; break;
	}
	Item_InitializeLoot(e, item.m_canonical_spawnfunc, this.origin + '0 0 32', randomvec() * 175 + '0 0 175', time_to_live);

	if(autocvar_g_powerups_drop_ondeath != 2)
		Item_SetExpiring(e, true);
	
	// Use health as time left to live
	SetResourceExplicit(e, RES_HEALTH, time_to_live);
	
	// Create waypoint displaying time left of the powerup
	entity wp = WaypointSprite_Spawn(WP_Item, 0, 0, e, '0 0 1' * e.maxs.z, NULL, 0, e, waypointsprite_attached, true, RADARICON_Item);
	wp.wp_extra = item.m_id;
	WaypointSprite_UpdateMaxHealth(e.waypointsprite_attached, maxtime);
	WaypointSprite_UpdateHealth(e.waypointsprite_attached, timeleft);
	
	// Start dropping its time to live
	setthink(e, powerups_DropItem_Think);
	e.nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(powerups, ItemTouched)
{
	entity e = M_ARGV(0, entity);
	if(e.waypointsprite_attached)
		WaypointSprite_Kill(e.waypointsprite_attached);
}

MUTATOR_HOOKFUNCTION(powerups, PlayerDies)
{
	if(!autocvar_g_powerups_drop_ondeath)
		return;

	entity frag_target = M_ARGV(2, entity);

	FOREACH(StatusEffect, it.instanceOfPowerups,
	{
		if(StatusEffects_active(it, frag_target))
			powerups_DropItem(frag_target, it);
	});
}

MUTATOR_HOOKFUNCTION(powerups, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(StatusEffects_active(STATUSEFFECT_Speed, player))
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_balance_powerup_speed_highspeed;
}

MUTATOR_HOOKFUNCTION(powerups, WeaponRateFactor)
{
	entity player = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Speed, player))
		M_ARGV(0, float) *= autocvar_g_balance_powerup_speed_attackrate;
}

MUTATOR_HOOKFUNCTION(powerups, BuildMutatorsPrettyString)
{
	if(autocvar_g_powerups == 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ", No powerups");
	if(autocvar_g_powerups > 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Powerups");
}

MUTATOR_HOOKFUNCTION(powerups, BotShouldAttack)
{
	entity targ = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Invisibility, targ))
		return true;
}

MUTATOR_HOOKFUNCTION(powerups, BuildMutatorsString)
{
	if(autocvar_g_powerups == 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ":no_powerups");
	if(autocvar_g_powerups > 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ":powerups");
}
