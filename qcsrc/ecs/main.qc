#include "main.qh"

#include "components/_mod.qh"
#include "events/_mod.qh"
#include "systems/_mod.qh"

void systems_update()
{
	float realtime = time;
	SYSTEM_UPDATE(phys);
	time = realtime;
}
