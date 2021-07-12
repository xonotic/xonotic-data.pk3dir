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
