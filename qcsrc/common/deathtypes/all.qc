#include "all.qh"

string Deathtype_Name(int deathtype)
{
	if (!DEATH_ISSPECIAL(deathtype))
		return itos(deathtype);

	entity deathent = REGISTRY_GET(Deathtypes, deathtype - DT_FIRST);
	if (deathent)
		return deathent.m_name;

	backtrace("Deathtype_Name: Could not find deathtype entity!\n");
	return "";
}
