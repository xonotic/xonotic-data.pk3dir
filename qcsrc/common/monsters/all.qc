#ifndef MONSTERS_ALL_C
#define MONSTERS_ALL_C
#include "all.qh"

REGISTER_MONSTER(Null, Monster) {
	this.netname = "";
	this.monster_name = "Monster";
	this.monster_func = m_null;
	this.mdl = "";
	this.mins = '-0 -0 -0';
	this.maxs = '0 0 0';
	this.model = "";
}

#include "all.inc"

entity get_monsterinfo(int id)
{
	if (id >= MON_FIRST && id <= MON_LAST)
	{
		entity m = monster_info[id];
		if (m) return m;
	}
	return MON_Null;
}

#endif
