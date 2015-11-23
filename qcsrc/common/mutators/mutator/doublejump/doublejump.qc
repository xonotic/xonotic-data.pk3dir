#ifdef IMPLEMENTATION
#ifdef SVQC
	#include "../../../../server/antilag.qh"
#endif
#include "../../../physics.qh"


#if defined(SVQC)
void doublejump_AddStats();

REGISTER_MUTATOR(doublejump, true)
{
	MUTATOR_ONADD
	{
		doublejump_AddStats();
	}
	return false;
}
#elif defined(CSQC)
REGISTER_MUTATOR(doublejump, true);
#endif


#ifdef CSQC

#define PHYS_DOUBLEJUMP						getstati(STAT_DOUBLEJUMP)

#elif defined(SVQC)

bool autocvar_sv_doublejump;

#define PHYS_DOUBLEJUMP						autocvar_sv_doublejump

.int stat_doublejump;

void doublejump_UpdateStats(entity this)
{
	this.stat_doublejump = PHYS_DOUBLEJUMP;
}

void doublejump_AddStats()
{
	addstat(STAT_DOUBLEJUMP, AS_INT, stat_doublejump);
}

#endif


MUTATOR_HOOKFUNCTION(doublejump, PlayerJump)
{
	if (PHYS_DOUBLEJUMP)
	{
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);
		if (trace_fraction < 1 && trace_plane_normal_z > 0.7)
		{
			player_multijump = true;

			// we MUST clip velocity here!
			float f = self.velocity * trace_plane_normal;
			if (f < 0)
				self.velocity -= f * trace_plane_normal;
		}
	}
	return false;
}

MUTATOR_HOOKFUNCTION(doublejump, PlayerPhysics)
{
#ifdef SVQC
	doublejump_UpdateStats(self);
#endif
	return false;
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(doublejump, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":doublejump");
	return false;
}

MUTATOR_HOOKFUNCTION(doublejump, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Double jump");
	return false;
}

#endif
#endif
