#ifdef IMPLEMENTATION
#ifdef SVQC
	#include "../../../../server/antilag.qh"
#endif
#include "../../../physics.qh"

#ifdef SVQC
REGISTER_MUTATOR(doublejump, autocvar_sv_doublejump);
#elif defined(CSQC)
REGISTER_MUTATOR(doublejump, true);
#endif

#define PHYS_DOUBLEJUMP(s)                     STAT(DOUBLEJUMP, s)


MUTATOR_HOOKFUNCTION(doublejump, PlayerJump)
{
	if (PHYS_DOUBLEJUMP(self))
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

#endif
