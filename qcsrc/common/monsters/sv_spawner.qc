#include "sv_spawner.qh"

#include <common/monsters/sv_monsters.qh>
#include <common/monsters/sv_spawn.qh>

void spawner_use(entity this, entity actor, entity trigger)
{
	int moncount = 0;
	IL_EACH(g_monsters, it.realowner == this,
	{
		++moncount;
	});

	if(moncount >= this.count)
		return;

	entity e = spawn();
	e.noalign = this.noalign;
	e.angles = this.angles;
	e.monster_skill = this.monster_skill;
	e.skin = this.skin;
	e = spawnmonster(e, this.spawnmob, MON_Null, this, this, this.origin, false, true, this.monster_moveflags);
}

spawnfunc(monster_spawner)
{
	if(!autocvar_g_monsters || !this.spawnmob || this.spawnmob == "") { delete(this); return; }

	this.use = spawner_use;
}
