#ifndef MONSTERS_ALL_C
#define MONSTERS_ALL_C

string M_Model(string m_mdl)
{
	string output = strcat("models/monsters/", m_mdl);
#ifdef SVQC
	MUTATOR_CALLHOOK(MonsterModel, m_mdl, output);
	return monster_model_output;
#else
	return output;
#endif
}

#include "all.qh"

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION

#endif
