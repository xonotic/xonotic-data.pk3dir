#include "monster.qh"

#ifdef SVQC
#include <common/monsters/sv_spawn.qh>
#include <common/monsters/sv_monsters.qh>

void nade_monster_boom(entity this)
{
	if(!autocvar_g_monsters)
		return;
	entity e = spawn();
	e.noalign = true; // don't drop to floor
	e = spawnmonster(e, this.pokenade_type, MON_Null, this.realowner, this.realowner, this.origin, false, false, 1);
	if(!e)
		return; // monster failed to be spawned

	if(autocvar_g_nades_pokenade_monster_lifetime > 0)
		e.monster_lifetime = time + autocvar_g_nades_pokenade_monster_lifetime;
	e.monster_skill = MONSTER_SKILL_INSANE;
}
#endif // SVQC
#ifdef MENUQC
METHOD(MonsterNade, describe, string(MonsterNade this))
{
	TC(MonsterNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, spawning one of the five monster types."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
