#include "elimination.qh"

#include <common/net_linked.qh>
#include <server/teamplay.qh>
#include <server/utils.qh>

/// Recounts .m_num_players_alive for each team
void EliminatedPlayers_RecountAlivePlayers()
{
	entity e, tm;
	int i;
	for (i = 0; i < NUM_TEAMS; ++i)
		g_team_entities[i].m_num_players_alive = 0;
	total_alive_players = 0;
	for (i = 1; i <= maxclients; ++i)
	{
		e = edict_num(i);
		if (!eliminatedPlayers.isEliminated(e))
		{
			tm = Entity_GetTeam(e);
			if (tm)
			{
				++tm.m_num_players_alive;
				++total_alive_players;
			}
		}
	}
}

bool EliminatedPlayers_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_ELIMINATEDPLAYERS);
	WriteByte(MSG_ENTITY, sf);
	int i;
	if (sf & SF_ELIMPLAYERS_ELIMS) // send elimination statuses, in a bitset
	{
		int b, B;
		for (i = 1; i <= maxclients; )
		{
			B = 0;
			for (b = BIT(0); b < BIT(8) && i <= maxclients; b <<= 1, ++i)
				if (eliminatedPlayers.isEliminated(edict_num(i)))
					B |= b;
			WriteByte(MSG_ENTITY, B);
		}
	}
	// assume EliminatedPlayers_RecountAlivePlayers has already been run
	if (sf & SF_ELIMPLAYERS_ALIVE) // send number of alive players on each team
		for (i = 1; i <= NUM_TEAMS; ++i)
			WriteByte(MSG_ENTITY, Team_GetTeamFromIndex(i).m_num_players_alive);
	return true;
}

void EliminatedPlayers_Init(bool(entity) isEliminated_func)
{
	if (eliminatedPlayers)
	{
		backtrace("Can't spawn eliminatedPlayers again!");
		return;
	}
	Net_LinkEntity(eliminatedPlayers = new_pure(eliminatedPlayers), false, 0, EliminatedPlayers_SendEntity);
	eliminatedPlayers.isEliminated = isEliminated_func;
}
