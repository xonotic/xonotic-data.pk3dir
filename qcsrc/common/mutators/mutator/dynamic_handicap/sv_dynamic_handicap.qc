#include "sv_dynamic_handicap.qh"

bool autocvar_g_dynamic_handicap; ///< Enable dynamic handicap
float autocvar_g_dynamic_handicap_scale; ///< Dynamic handicap scale, larger values mean more penalties for strong players & more buffs for weak players
float autocvar_g_dynamic_handicap_exponent; ///< Exponent used to calculate dynamic handicap, 1 is linear, >1 minimizes small differences, vice versa
float autocvar_g_dynamic_handicap_min; ///< Min dynamic handicap, can be < 1
float autocvar_g_dynamic_handicap_max; ///< Max dynamic handicap

REGISTER_MUTATOR(dynamic_handicap, autocvar_g_dynamic_handicap && !HANDICAP_DISABLED());

/// Clamps the value of the handicap
float DynamicHandicap_ClampHandicap(float handicap)
{
	if (handicap < 0)
		return 0;

	if (autocvar_g_dynamic_handicap_min <= autocvar_g_dynamic_handicap_max
	&&  autocvar_g_dynamic_handicap_min > 0)
		return bound(autocvar_g_dynamic_handicap_min, handicap, autocvar_g_dynamic_handicap_max);

	return handicap;
}

/// Updates the handicap of all players
void DynamicHandicap_UpdateHandicap()
{
	int total_players = 0;
	int scoring_players = 0;
	float score, total_score = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		++total_players;
		score = PlayerScore_Get(it, SP_SCORE);
		if (score <= 0) // negative scores can make the mean be negative or small,
			continue;   // which amplifies handicap for scores close to the mean
		total_score += score;
		++scoring_players;
	});
	if (!total_players)
		return;

	float handicap, mean_score = (scoring_players)
		? total_score / scoring_players
		: 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		score = PlayerScore_Get(it, SP_SCORE);
		if (score <= 0 || mean_score <= 0)
			handicap = 1;
		else
		{
			handicap = fabs((score - mean_score) / mean_score * autocvar_g_dynamic_handicap_scale);
			handicap = 1 + (handicap ** autocvar_g_dynamic_handicap_exponent);
			if (score < mean_score)
				handicap = 1 / handicap;
			// Handicap of a score x points below the mean will be equal to the reciprocal of a score x points above
		}
		handicap = DynamicHandicap_ClampHandicap(handicap);
		Handicap_SetForcedHandicap(it, handicap, false);
		Handicap_SetForcedHandicap(it, handicap, true);
	});
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":handicap");
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Dynamic handicap");
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, ClientDisconnect)
{
	DynamicHandicap_UpdateHandicap();
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, PutClientInServer)
{
	DynamicHandicap_UpdateHandicap();
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, MakePlayerObserver)
{
	DynamicHandicap_UpdateHandicap();
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, AddedPlayerScore)
{
	if (M_ARGV(0, entity) == SP_SCORE)
		DynamicHandicap_UpdateHandicap();
}
