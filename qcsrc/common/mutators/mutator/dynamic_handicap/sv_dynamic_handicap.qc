#include "sv_dynamic_handicap.qh"
/// \file
/// \brief Source file that contains implementation of the Dynamic handicap
/// mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//======================= Global variables ====================================

int autocvar_g_dynamic_handicap; ///< Whether to enable dynamic handicap.
/// \brief The scale of the handicap. Larger values mean more penalties for
/// strong players and more buffs for weak players.
float autocvar_g_dynamic_handicap_scale;
/// \brief The exponent used to calculate handicap. 1 means linear scale. Values
/// more than 1 mean stronger non-linear handicap. Values less than 1 mean
/// weaker non-linear handicap.
float autocvar_g_dynamic_handicap_exponent;
float autocvar_g_dynamic_handicap_min; ///< The minimum value of the handicap.
float autocvar_g_dynamic_handicap_max; ///< The maximum value of the handicap.

//====================== Forward declarations =================================

/// \brief Clamps the value of the handicap.
/// \param[in] handicap Value to clamp.
/// \return Clamped value.
float DynamicHandicap_ClampHandicap(float handicap);

//========================= Free functions ====================================

/// \brief Updates the handicap of all players.
/// \return No return.
void DynamicHandicap_UpdateHandicap()
{
	float total_score = 0;
	float totalplayers = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		total_score += PlayerScore_Get(it, SP_SCORE);
		++totalplayers;
	});
	if (totalplayers == 0)
		return;

	float mean_score = total_score / totalplayers;
	FOREACH_CLIENT(true,
	{
		float score = PlayerScore_Get(it, SP_SCORE);
		float handicap = fabs((score - mean_score) *
			autocvar_g_dynamic_handicap_scale);
		handicap = handicap ** autocvar_g_dynamic_handicap_exponent;
		if (score < mean_score)
		{
			handicap = -handicap;
		}
		if (handicap >= 0)
		{
			handicap += 1;
		}
		else
		{
			handicap = 1 / (fabs(handicap) + 1);
		}
		handicap = DynamicHandicap_ClampHandicap(handicap);
		Handicap_SetForcedHandicap(it, handicap, false);
		Handicap_SetForcedHandicap(it, handicap, true);
	});
}

float DynamicHandicap_ClampHandicap(float handicap)
{
	if ((autocvar_g_dynamic_handicap_min >= 0) && (handicap <
		autocvar_g_dynamic_handicap_min))
	{
		handicap = autocvar_g_dynamic_handicap_min;
	}
	if ((autocvar_g_dynamic_handicap_max > 0) && (handicap >
		autocvar_g_dynamic_handicap_max))
	{
		handicap = autocvar_g_dynamic_handicap_max;
	}
	return handicap;
}

//============================= Hooks ========================================

REGISTER_MUTATOR(dynamic_handicap, autocvar_g_dynamic_handicap && !HANDICAP_DISABLED());

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
	if (M_ARGV(0, entity) != SP_SCORE)
	{
		return;
	}
	DynamicHandicap_UpdateHandicap();
}
