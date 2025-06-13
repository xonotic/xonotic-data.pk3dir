#include "handicap.qh"

/// \file
/// \brief Source file that contains implementation of the handicap system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include <common/state.qh>
#include <common/ent_cs.qh> // for .handicap_level
#include <lib/replicate.qh> // for REPLICATE_APPLYCHANGE
#include <server/client.qh>

.float m_handicap_give; ///< Holds the forced handicap value.
.float m_handicap_take; ///< Holds the forced handicap value.

void Handicap_Initialize(entity player)
{
	// forced handicap defaults
	CS(player).m_handicap_give = 1;
	CS(player).m_handicap_take = 1;

	Handicap_UpdateHandicapLevel(player);
}

float Handicap_GetVoluntaryHandicap(entity player, bool receiving)
{
	if (HANDICAP_DISABLED())
		return 1;
#if 0
	if (receiving)
		return bound(1.0, CS_CVAR(player).cvar_cl_handicap_damage_taken, 10.0);
	else
		return bound(1.0, CS_CVAR(player).cvar_cl_handicap_damage_given, 10.0);
#else
	// TODO: remove the else vector branch after 0.9 release
	// Forwards compatibility for old clients on new servers. `cl_handicap 2`
	// ( '2 0 0' ) is treated the same as `cl_handicap_damage_{given,taken} 2`.
	// The x is give and y is take.
	// '2 0 0' gives and takes x2
	// '2 2 0' gives and takes x2
	// '2 1 0' only gives x2
	// '1 2 0' only takes x2
	// z is wasted

	int handicap_value;

	// First read if the new cvars have a valid value,
	// if they don't then read old cvar, checking if the old cvar has
	// separate give and take values or we should use the first value for both
	if (receiving)
	{
		if (CS_CVAR(player).cvar_cl_handicap_damage_taken > 1)
			handicap_value = CS_CVAR(player).cvar_cl_handicap_damage_taken;
		else if (CS_CVAR(player).cvar_cl_handicap.y > 0)
			handicap_value = CS_CVAR(player).cvar_cl_handicap.y;
		else
			handicap_value = CS_CVAR(player).cvar_cl_handicap.x;
	}
	else
	{
		if (CS_CVAR(player).cvar_cl_handicap_damage_given > 1)
			handicap_value = CS_CVAR(player).cvar_cl_handicap_damage_given;
		else
			handicap_value = CS_CVAR(player).cvar_cl_handicap.x;
	}

	return bound(1.0, handicap_value, 10.0);
#endif
}

float Handicap_GetForcedHandicap(entity player, bool receiving)
{
	if (HANDICAP_DISABLED())
		return 1;
	if (receiving)
		return (CS(player)) ? CS(player).m_handicap_take : 1;
	else
		return (CS(player)) ? CS(player).m_handicap_give : 1;
}

void Handicap_SetForcedHandicap(entity player, float value, bool receiving)
{
	if (HANDICAP_DISABLED())
		return;
	if (value <= 0)
		error("Handicap_SetForcedHandicap: Invalid handicap value.");

	if (receiving)
		CS(player).m_handicap_take = value;
	else
		CS(player).m_handicap_give = value;

	Handicap_UpdateHandicapLevel(player);
}

float Handicap_GetTotalHandicap(entity player, bool receiving)
{
	if (HANDICAP_DISABLED())
		return 1;
	return Handicap_GetForcedHandicap(player, receiving) *
		Handicap_GetVoluntaryHandicap(player, receiving);
}

void Handicap_UpdateHandicapLevel(entity player)
{
	if (HANDICAP_DISABLED())
	{
		player.handicap_level = 0;
		return;
	}

	float handicap_total = (Handicap_GetTotalHandicap(player, true) +
		Handicap_GetTotalHandicap(player, false)) / 2;
	player.handicap_level = floor(map_bound_ranges(handicap_total, 1, HANDICAP_MAX_LEVEL_EQUIVALENT, 0, 16));
}

REPLICATE_APPLYCHANGE("cl_handicap_damage_given", { Handicap_UpdateHandicapLevel(this); });
REPLICATE_APPLYCHANGE("cl_handicap_damage_taken", { Handicap_UpdateHandicapLevel(this); });

