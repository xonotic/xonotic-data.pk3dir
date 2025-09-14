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
	// if there is no armor it means the timer of the powerup is running
	if(this.waypointsprite_attached && !GetResource(this, RES_ARMOR))
	{
		float timeleft = floor(this.wait - time);
		if (timeleft)
			WaypointSprite_UpdateHealth(this.waypointsprite_attached, timeleft);
		else
			WaypointSprite_Kill(this.waypointsprite_attached);
	}
}

void powerups_DropItem(entity this, StatusEffect effect, bool freezeTimer)
{
	float t = StatusEffects_gettime(effect, this);
	float timeleft = t - time;
	float maxtime = 0;

	if(timeleft <= 1)
		return;
	entity e = spawn();

	// If we want the timer to keep running, we enable expiring then use the exact time the powerup will finish at.
	// If we want the timer to freeze, we disable expiring and we just use the time left of the powerup.
	// See ITEM_SET_EXPIRING() below.
	float finished = (freezeTimer ? timeleft : t);

	// If the timer is frozen, the item will stay on the floor for 20 secs (same as weapons),
	// otherwise it'll disappear after the timer runs out.
	e.lifetime = (freezeTimer ? autocvar_g_items_dropped_lifetime : timeleft);

	// TODO: items cannot hold their "item field" yet, so we need to list all the powerups here!
	switch (effect)
	{
		case STATUSEFFECT_Strength:     e.itemdef = ITEM_Strength;     e.strength_finished = finished;     maxtime = autocvar_g_balance_powerup_strength_time;   break;
		case STATUSEFFECT_Shield:       e.itemdef = ITEM_Shield;       e.invincible_finished = finished;   maxtime = autocvar_g_balance_powerup_invincible_time; break;
		case STATUSEFFECT_Invisibility: e.itemdef = ITEM_Invisibility; e.invisibility_finished = finished; maxtime = autocvar_g_balance_powerup_invisibility_time; break;
		case STATUSEFFECT_Speed:        e.itemdef = ITEM_Speed;        e.speed_finished = finished;        maxtime = autocvar_g_balance_powerup_speed_time;      break;
		default: delete(e); return;
	}

	e.origin = this.origin;
	e.velocity = W_CalculateProjectileVelocity(this, this.velocity, v_forward * 750, false);
	if (!Item_Initialise(e))
		return;

	if(!freezeTimer)
		ITEM_SET_EXPIRING(e, true);

	// Use armor as timer freezer
	if(freezeTimer)
		SetResourceExplicit(e, RES_ARMOR, 1);

	// Create waypoint displaying time left of the powerup
	entity wp = WaypointSprite_Spawn(WP_Item, 0, 0, e, '0 0 1' * e.maxs.z, NULL, 0, e, waypointsprite_attached, true, RADARICON_Item);
	wp.wp_extra = e.itemdef.m_id;
	WaypointSprite_UpdateMaxHealth(e.waypointsprite_attached, maxtime);
	WaypointSprite_UpdateHealth(e.waypointsprite_attached, timeleft);
	// Item_Think() will call powerups_DropItem_Think() to update the waypoint
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

	FOREACH(StatusEffects, it.instanceOfPowerupStatusEffect,
	{
		if(StatusEffects_active(it, frag_target))
			powerups_DropItem(frag_target, it, autocvar_g_powerups_drop_ondeath == 2);
	});
}

MUTATOR_HOOKFUNCTION(powerups, PlayerUseKey)
{
	if(MUTATOR_RETURNVALUE || game_stopped || !autocvar_g_powerups_drop) return;

	entity player = M_ARGV(0, entity);

	FOREACH(StatusEffects, it.instanceOfPowerupStatusEffect,
	{
		if(StatusEffects_active(it, player)) {
			powerups_DropItem(player, it, autocvar_g_powerups_drop == 2);
			StatusEffects_remove(it, player, STATUSEFFECT_REMOVE_NORMAL);
			return true;
		}
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
		M_ARGV(0, float) *= autocvar_g_balance_powerup_speed_attack_time_multiplier;
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
