#include "sv_spawn.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/monsters/all.qh>
	#include <common/monsters/sv_monsters.qh>
	#include <common/stats.qh>
	#include <common/util.qh>
	#include <common/weapons/_all.qh>
	#include <server/weapons/common.qh>
#endif

entity spawnmonster (entity e, string monster, Monster monster_id, entity spawnedby, entity own, vector orig, bool respwn, bool removeifinvalid, int moveflag)
{
	e.spawnflags = MONSTERFLAG_SPAWNED;

	if(!respwn) { e.spawnflags |= MONSTERFLAG_NORESPAWN; }
	//if(invincible) { e.spawnflags |= MONSTERFLAG_INVINCIBLE; }

	setorigin(e, orig);
	bool allow_any = boolean(monster == "anyrandom");

	if(monster == "random" || allow_any)
	{
		RandomSelection_Init();
		FOREACH(Monsters, it != MON_Null && (allow_any || !(it.spawnflags & MON_FLAG_HIDDEN)) && !(it.spawnflags & MONSTER_TYPE_PASSIVE),
		{
			RandomSelection_AddEnt(it, 1, 1);
		});

		monster_id = RandomSelection_chosen_ent;
	}
	else if(monster != "")
	{
		bool found = false;
		FOREACH(Monsters, it != MON_Null,
		{
			if(it.netname == monster)
			{
				found = true;
				monster_id = it; // we have the monster, old monster id is no longer required
				break;
			}
		});

		if(!found && monster_id == MON_Null)
		{
			if(removeifinvalid)
			{
				delete(e);
				return NULL; // no good
			}
			else
			{
				// select a random valid monster type if no valid monster was provided
				return spawnmonster(e, "random", MON_Null, spawnedby, own, orig, respwn, removeifinvalid, moveflag);
			}
		}
	}

	e.realowner = spawnedby;

	if(moveflag)
		e.monster_moveflags = moveflag;

	if(IS_PLAYER(spawnedby))
	{
		if(teamplay && autocvar_g_monsters_teams)
			e.team = spawnedby.team; // colors handled in spawn code

		if(autocvar_g_monsters_owners)
			e.monster_follow = own; // using .owner makes the monster non-solid for its master

		e.angles_y = spawnedby.angles_y;
	}

	// Monster_Spawn checks if monster is valid
	if(!Monster_Spawn(e, false, monster_id))
	{
		delete(e);
		return NULL; // remove even if told not to, as we didn't spawn any kind of monster
	}

	return e;
}
