#include "handicap.qh"

/// \file
/// \brief Source file that contains implementation of the handicap system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include <common/state.qh>
#include <server/client.qh>

.float m_handicap; ///< Holds the handicap value.

void Handicap_Initialize(entity player)
{
	CS(player).m_handicap = 1;
}

float Handicap_GetVoluntaryHandicap(entity player)
{
	return bound(1.0, CS_CVAR(player).cvar_cl_handicap, 10.0);
}

float Handicap_GetForcedHandicap(entity player)
{
	return (CS(player)) ? CS(player).m_handicap : 1;
}

void Handicap_SetForcedHandicap(entity player, float value)
{
	if (value <= 0)
	{
		error("Handicap_SetForcedHandicap: Invalid handicap value.");
	}
	CS(player).m_handicap = value;
}

float Handicap_GetTotalHandicap(entity player)
{
	return Handicap_GetForcedHandicap(player) * Handicap_GetVoluntaryHandicap(
		player);
}
