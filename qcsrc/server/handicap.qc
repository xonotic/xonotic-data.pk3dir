#include "handicap.qh"

/// \file
/// \brief Source file that contains implementation of the handicap system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include <common/state.qh>
#include <server/client.qh>

.float m_handicap_give; ///< Holds the handicap value.
.float m_handicap_take; ///< Holds the handicap value.

void Handicap_Initialize(entity player)
{
	CS(player).m_handicap_give = 1;
	CS(player).m_handicap_take = 1;
}

float Handicap_GetVoluntaryHandicap(entity player, bool receiving)
{
	if (receiving)
		return bound(1.0, CS_CVAR(player).cvar_cl_handicap_take, 10.0);
	else
		return bound(1.0, CS_CVAR(player).cvar_cl_handicap_give, 10.0);

}

float Handicap_GetForcedHandicap(entity player, bool receiving)
{
	if (receiving)
		return (CS(player)) ? CS(player).m_handicap_take : 1;
	else
		return (CS(player)) ? CS(player).m_handicap_give : 1;

}

void Handicap_SetForcedHandicap(entity player, float value, bool receiving)
{
	if (value <= 0)
		error("Handicap_SetForcedHandicap: Invalid handicap value.");

	if (receiving)
		CS(player).m_handicap_take = value;
	else
		CS(player).m_handicap_give = value;
}

float Handicap_GetTotalHandicap(entity player, bool receiving)
{
	return Handicap_GetForcedHandicap(player, receiving) *
		Handicap_GetVoluntaryHandicap(player, receiving);
}
