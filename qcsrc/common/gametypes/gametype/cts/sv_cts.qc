#include "sv_cts.qh"

#include <common/gametypes/gametype/race/sv_util.qh>

#include <common/mapobjects/triggers.qh>
#include <common/monsters/sv_monsters.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/items/spawning.qh>
#include <server/race.qh>
#include <server/weapons/common.qh>
#include <server/world.qh>

float autocvar_g_cts_finish_kill_delay;
bool autocvar_g_cts_selfdamage;
bool autocvar_g_cts_removeprojectiles;
bool autocvar_g_cts_drop_monster_items;

void cts_ScoreRules()
{
	GameRules_score_enabled(false);
	GameRules_scoring(0, 0, 0,
	{
		if (g_race_qualifying)
			field(SP_RACE_FASTEST, "fastest", SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		else
		{
			field(SP_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
			field(SP_RACE_TIME, "time", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
			field(SP_RACE_FASTEST, "fastest", SFL_LOWER_IS_BETTER | SFL_TIME);
		}
	});
}

void cts_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":cts:", mode, ":", (actor != NULL ? strcat(":", itos(actor.playerid)) : "")));
}

MUTATOR_HOOKFUNCTION(cts, PlayerPhysics)
{
	race_util_PlayerPhysics();
}

MUTATOR_HOOKFUNCTION(cts, reset_map_global)
{
	race_util_reset_map_global(cts_EventLog);
}

MUTATOR_HOOKFUNCTION(cts, ClientConnect)
{
	race_util_ClientConnect();
}

MUTATOR_HOOKFUNCTION(cts, AbortSpeedrun)
{
	race_util_AbortSpeedrun();
}

MUTATOR_HOOKFUNCTION(cts, MakePlayerObserver)
{
	race_util_MakePlayerObserver();
}

MUTATOR_HOOKFUNCTION(cts, PlayerSpawn)
{
	race_util_PlayerSpawn();
}

MUTATOR_HOOKFUNCTION(cts, PutClientInServer)
{
	race_util_PutClientInServer();
}

MUTATOR_HOOKFUNCTION(cts, PlayerDamaged)
{
	return true; // forbid logging damage
}

MUTATOR_HOOKFUNCTION(cts, PlayerDies)
{
	race_util_PlayerDies();

	entity frag_target = M_ARGV(2, entity);
	if (autocvar_g_cts_removeprojectiles)
		IL_EACH(g_projectiles, it.owner == frag_target && (it.flags & FL_PROJECTILE), delete(it));
}

MUTATOR_HOOKFUNCTION(cts, HavocBot_ChooseRole)
{
	return race_util_HavocBot_ChooseRole();
}

MUTATOR_HOOKFUNCTION(cts, GetPressedKeys)
{
	race_util_GetPressedKeys();
}

MUTATOR_HOOKFUNCTION(cts, ForbidThrowCurrentWeapon)
{
	// no weapon dropping in CTS
	return true;
}

MUTATOR_HOOKFUNCTION(cts, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (ITEM_IS_LOOT(item))
		return !(item.monster_item && autocvar_g_cts_drop_monster_items);
}

MUTATOR_HOOKFUNCTION(cts, MonsterDropItem)
{
	if (!autocvar_g_cts_drop_monster_items)
		M_ARGV(1, string) = "";
}

MUTATOR_HOOKFUNCTION(cts, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if ((frag_target == frag_attacker || frag_deathtype == DEATH_FALL.m_id)
	&& !autocvar_g_cts_selfdamage)
	{
		frag_damage = 0;
		M_ARGV(4, float) = frag_damage;
	}
}

MUTATOR_HOOKFUNCTION(cts, GetRecords)
{
	race_util_GetRecords();
}

MUTATOR_HOOKFUNCTION(cts, ClientKill)
{
	M_ARGV(1, float) = 0; // kill delay
}

MUTATOR_HOOKFUNCTION(cts, Race_FinalCheckpoint)
{
	entity player = M_ARGV(0, entity);

	// useful to prevent cheating by running back to the start line and starting out with more speed
	if (autocvar_g_cts_finish_kill_delay)
		ClientKill_Silent(player, autocvar_g_cts_finish_kill_delay);
}

MUTATOR_HOOKFUNCTION(cts, ReadLevelCvars)
{
	warmup_stage = 0;
}

MUTATOR_HOOKFUNCTION(cts, FixClientCvars)
{
	race_util_FixClientCvars();
}

MUTATOR_HOOKFUNCTION(cts, WantWeapon)
{
	M_ARGV(1, float) = (M_ARGV(0, entity) == WEP_SHOTGUN); // want weapon = weapon info
	M_ARGV(3, bool) = true; // want mutator blocked
	return true;
}

MUTATOR_HOOKFUNCTION(cts, ForbidDropCurrentWeapon)
{
	return true;
}

void cts_Initialize()
{
	record_type = CTS_RECORD;
	cts_ScoreRules();
}
