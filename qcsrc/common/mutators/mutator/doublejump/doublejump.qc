#include "doublejump.qh"

#ifdef SVQC
REGISTER_MUTATOR(doublejump, autocvar_sv_doublejump);
#elif defined(CSQC)
REGISTER_MUTATOR(doublejump, true);
#endif
