#include "loader.qh"

#include <common/mapinfo.qh>
#include <common/mutators/base.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>

STATIC_INIT_LATE(Gametype)
{
	Gametype g = MapInfo_CurrentGametype();
	if (g)
		for (string s, _s = g.m_mutators; _s != ""; _s = cdr(_s))
		{
			s = car(_s);
			FOREACH(Mutators, it.m_name == s,
			{
				Mutator_Add(it);
				break;
			});
		}
}
