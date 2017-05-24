#include "all.qh"

string M_Model(string m_mdl)
{
	string output = strcat("models/monsters/", m_mdl);
#ifdef SVQC
	MUTATOR_CALLHOOK(MonsterModel, m_mdl, output);
	return M_ARGV(1, string);
#else
	return output;
#endif
}
