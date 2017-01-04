#include "sv_random_gravity.qh"

// Random Gravity

// Mutator by Mario
// Inspired by Player 2

float autocvar_g_random_gravity_negative_chance;
float autocvar_g_random_gravity_min;
float autocvar_g_random_gravity_max;
float autocvar_g_random_gravity_positive;
float autocvar_g_random_gravity_negative;
float autocvar_g_random_gravity_delay;

REGISTER_MUTATOR(random_gravity, cvar("g_random_gravity"))
{
	MUTATOR_ONADD
	{
		cvar_settemp("sv_gravity", cvar_string("sv_gravity")); // settemp current gravity so it's restored on match end
	}
}

float gravity_delay;

MUTATOR_HOOKFUNCTION(random_gravity, SV_StartFrame)
{
	if(game_stopped || !cvar("g_random_gravity")) return false;
	if(time < gravity_delay) return false;
	if(time < game_starttime) return false;
	if(round_handler_IsActive() && !round_handler_IsRoundStarted()) return false;

    if(random() >= autocvar_g_random_gravity_negative_chance)
        cvar_set("sv_gravity", ftos(bound(autocvar_g_random_gravity_min, random() - random() * -autocvar_g_random_gravity_negative, autocvar_g_random_gravity_max)));
    else
        cvar_set("sv_gravity", ftos(bound(autocvar_g_random_gravity_min, random() * autocvar_g_random_gravity_positive, autocvar_g_random_gravity_max)));

	gravity_delay = time + autocvar_g_random_gravity_delay;

	LOG_TRACE("Gravity is now: ", ftos(autocvar_sv_gravity));
}

MUTATOR_HOOKFUNCTION(random_gravity, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":RandomGravity");
}

MUTATOR_HOOKFUNCTION(random_gravity, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Random gravity");
}
