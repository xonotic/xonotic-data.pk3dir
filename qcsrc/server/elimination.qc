#include "elimination.qh"

#include <common/net_linked.qh>
#include <server/utils.qh>

.float(entity) isEliminated;
bool EliminatedPlayers_SendEntity(entity this, entity to, float sendflags)
{
	Stream out = MSG_ENTITY;
	WriteHeader(out, ENT_CLIENT_ELIMINATEDPLAYERS);
	serialize(byte, out, sendflags);
	if (sendflags & 1) {
		for (int i = 1; i <= maxclients; i += 8) {
			int f = 0;
			entity e = edict_num(i);
			for (int b = 0; b < 8; ++b, e = nextent(e)) {
				if (eliminatedPlayers.isEliminated(e)) {
					f |= BIT(b);
				}
			}
			serialize(byte, out, f);
		}
	}
	return true;
}

void EliminatedPlayers_Init(float(entity) isEliminated_func)
{
	if(eliminatedPlayers)
	{
		backtrace("Can't spawn eliminatedPlayers again!");
		return;
	}
	Net_LinkEntity(eliminatedPlayers = new_pure(eliminatedPlayers), false, 0, EliminatedPlayers_SendEntity);
	eliminatedPlayers.isEliminated = isEliminated_func;
}
