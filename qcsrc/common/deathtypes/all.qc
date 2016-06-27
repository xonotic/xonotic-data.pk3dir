#include "all.qh"

string Deathtype_Name(int deathtype)
{
	if (DEATH_ISSPECIAL(deathtype)) {
		entity deathent = Deathtypes_from(deathtype - DT_FIRST);
		if (!deathent) { backtrace("Deathtype_Name: Could not find deathtype entity!\n"); return ""; }
		return deathent.nent_name;
	}
	return ftos(deathtype);
}
