#include "swamp.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/warpzone/util_server.qh>
    #include <common/weapons/_all.qh>
    #include <common/weapons/_all.qh>
    #include <common/stats.qh>
    #include <common/deathtypes/all.qh>
#endif

/*
*		t_swamp.c
*		Adds spawnfunc_trigger_swamp and support routines for nexuiz 1.2.1+ and xonotic
*		Author tZork (Jakob MG)
*		jakob@games43.se
*		2005 11 29
*/

#ifdef SVQC
void swamp_think(entity this)
{
	// set myself as current swampslug where possible
	IL_EACH(g_swamped, it.swampslug == this,
	{
		it.swampslug = NULL;
		IL_REMOVE(g_swamped, it);
	});

	if(this.active == ACTIVE_ACTIVE)
	{
		FOREACH_ENTITY_RADIUS((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1, it.swampslug.active == ACTIVE_NOT && IS_PLAYER(it) && !IS_DEAD(it),
		{
			if (WarpZoneLib_ExactTrigger_Touch(this, it, false))
			{
				if(!it.swampslug)
					IL_PUSH(g_swamped, it);
				it.swampslug = this;
			}
		});

		IL_EACH(g_swamped, it.swampslug == this,
		{
			if(time > it.swamp_interval)
			{
				Damage (it, this, this, this.dmg, DEATH_SWAMP.m_id, DMG_NOWEP, it.origin, '0 0 0');
				it.swamp_interval = time + this.swamp_interval;
			}
		});
	}

	this.nextthink = time;
}

/*QUAKED spawnfunc_trigger_swamp (.5 .5 .5) ?
Players in the swamp will be
slowed down and damaged over time
*/
spawnfunc(trigger_swamp)
{
	// Init stuff
	EXACTTRIGGER_INIT;
	this.active = ACTIVE_ACTIVE;
	setthink(this, swamp_think);
	this.nextthink = time;

	// Setup default keys, if missing
	if(!this.dmg)
		this.dmg = 5;
	if(!this.swamp_interval)
		this.swamp_interval = 1;
	if(!this.swamp_slowdown)
		this.swamp_slowdown = 0.5;
}
#endif
