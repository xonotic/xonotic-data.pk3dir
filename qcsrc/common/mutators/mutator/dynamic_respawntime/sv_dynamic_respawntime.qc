#include "sv_dynamic_respawntime.qh"

bool autocvar_g_dynamic_respawntime;
float autocvar_g_dynamic_respawntime_maxfactor;
float autocvar_g_dynamic_respawntime_modifier_death;
float autocvar_g_dynamic_respawntime_modifier_frag;
float autocvar_g_dynamic_respawntime_modifier_suicide;
float autocvar_g_dynamic_respawntime_modifier_teamkill;

.float respawntime_factor;

REGISTER_MUTATOR(dynamic_respawntime, autocvar_g_dynamic_respawntime);

void dynamic_respawntime_adjust(entity player, float modifier)
{
	if (!modifier) // disabled
		return;
	float multiplier = autocvar_g_dynamic_respawntime_maxfactor ** (1 / modifier);
	// multiplier ** modifier = autocvar_g_dynamic_respawntime_maxfactor

	// Exponential approach: n frags will exactly counteract n deaths, if the modifier values are equal,
	// exponential to minimize the effect of small differences
	if (modifier < 0) // respawning faster
		player.respawntime_factor = max(1 / autocvar_g_dynamic_respawntime_maxfactor, player.respawntime_factor / multiplier);
	else
		player.respawntime_factor = min(player.respawntime_factor * multiplier, autocvar_g_dynamic_respawntime_maxfactor);
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, PlayerDied)
{
	entity player = M_ARGV(0, entity);
	entity attacker = M_ARGV(1, entity);

	if (player != attacker && IS_PLAYER(attacker))
	{
		if (SAME_TEAM(attacker, player)) // teamkill: only adjust the attacker
			dynamic_respawntime_adjust(attacker, autocvar_g_dynamic_respawntime_modifier_teamkill);
		else
		{
			dynamic_respawntime_adjust(attacker, autocvar_g_dynamic_respawntime_modifier_frag);
			dynamic_respawntime_adjust(player,   autocvar_g_dynamic_respawntime_modifier_death);
		}
	}
	else
		dynamic_respawntime_adjust(player, autocvar_g_dynamic_respawntime_modifier_suicide);
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, CalculateRespawnTime)
{
	// NOTE: this runs before PlayerDied, so changes to respawntime apply on the next respawn
	entity player = M_ARGV(0, entity);
	float sdelay = M_ARGV(1, float);

	M_ARGV(1, float) = sdelay * player.respawntime_factor;
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, PlayerScore_Clear)
{
	entity player = M_ARGV(0, entity);
	player.respawntime_factor = 1;
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	player.respawntime_factor = 1;
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":DynamicRespawnTime");
}

MUTATOR_HOOKFUNCTION(dynamic_respawntime, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Dynamic respawn time");
}
