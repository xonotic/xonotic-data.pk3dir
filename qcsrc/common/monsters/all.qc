#ifndef MONSTERS_ALL_C
#define MONSTERS_ALL_C

#include "all.qh"

entity get_monsterinfo(int id)
{
	if (id >= MON_FIRST && id <= MON_LAST) {
		entity m = monster_info[id];
		if (m) return m;
	}
	return MON_Null;
}

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION

#endif
