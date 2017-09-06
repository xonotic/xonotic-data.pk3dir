/// \file
/// \brief Source file that contains implementation of the Dynamic handicap
/// mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//======================= Global variables ====================================

int autocvar_g_dynamic_handicap; ///< Whether to enable dynamic handicap.
/// \brief The scale of the handicap. Larget values mean more penalties for
/// strong players and more buffs for weak players.
float autocvar_g_dynamic_handicap_scale;
float autocvar_g_dynamic_handicap_min; ///< The minimum value of the handicap.
float autocvar_g_dynamic_handicap_max; ///< The maximum value of the handicap.

//====================== Forward declarations =================================

/// \brief Returns the base value of the handicap.
/// \param[in] player Player to evaluate.
/// \return Base handicap value.
float DynamicHandicap_GetBaseValue(entity player);

/// \brief Scales the base value of the handicap.
/// \param[in] handicap Value to scale.
/// \return Scaled value.
float DynamicHandicap_ScaleHandicap(float handicap);

/// \brief Clamps the value of the handicap.
/// \param[in] handicap Value to clamp.
/// \return Clamped value.
float DynamicHandicap_ClampHandicap(float handicap);

//========================= Free functions ====================================

/// \brief Updates the handicap of a given player.
/// \param[in,out] player Player to update.
/// \return No return.
void DynamicHandicap_UpdateHandicap(entity player)
{
	float handicap = DynamicHandicap_GetBaseValue(player);
	//PrintToChat(player, strcat("Base handicap = ", ftos(handicap)));
	handicap = DynamicHandicap_ScaleHandicap(handicap);
	//PrintToChat(player, strcat("Scaled handicap = ", ftos(handicap)));
	handicap = DynamicHandicap_ClampHandicap(handicap);
	//PrintToChat(player, strcat("Clamped handicap = ", ftos(handicap)));
	Handicap_SetForcedHandicap(player, handicap);
}

float DynamicHandicap_GetBaseValue(entity player)
{
	int kills = PlayerScore_Get(player, SP_KILLS);
	int deaths = PlayerScore_Get(player, SP_DEATHS);
	if (kills == deaths)
	{
		return 1;
	}
	if (deaths == 0)
	{
		return kills;
	}
	if (kills == 0)
	{
		return 1 / deaths;
	}
	return kills / deaths;
}

float DynamicHandicap_ScaleHandicap(float handicap)
{
	if (handicap == 1)
	{
		return 1;
	}
	if (autocvar_g_dynamic_handicap_scale == 1)
	{
		return handicap;
	}
	if (handicap > 1)
	{
		handicap -= 1;
		handicap *= autocvar_g_dynamic_handicap_scale;
		return handicap + 1;
	}
	if (handicap < 1)
	{
		handicap = 1 / handicap;
		handicap -= 1;
		handicap *= autocvar_g_dynamic_handicap_scale;
		handicap += 1;
		return 1 / handicap;
	}
	return 1;
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

REGISTER_MUTATOR(dynamic_handicap, autocvar_g_dynamic_handicap);

MUTATOR_HOOKFUNCTION(dynamic_handicap, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":handicap");
}

MUTATOR_HOOKFUNCTION(dynamic_handicap, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Dynamic handicap");
}

/// \brief Hook that is called when player connects to the server.
MUTATOR_HOOKFUNCTION(dynamic_handicap, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	DynamicHandicap_UpdateHandicap(player);
}

/// \brief Hook that is called when player dies.
MUTATOR_HOOKFUNCTION(dynamic_handicap, PlayerDies)
{
	entity attacker = M_ARGV(1, entity);
	entity victim = M_ARGV(2, entity);
	DynamicHandicap_UpdateHandicap(victim);
	if (!IS_CLIENT(attacker))
	{
		return;
	}
	DynamicHandicap_UpdateHandicap(attacker);
}
