#include "spawn.qh"

#ifdef SVQC
void nade_spawn_boom(entity this)
{
	entity player = this.realowner;
	entity spawnloc = new(nade_spawn_loc);
	setorigin(spawnloc, this.origin);
	setsize(spawnloc, player.mins, player.maxs);
	set_movetype(spawnloc, MOVETYPE_NONE);
	spawnloc.solid = SOLID_NOT;
	spawnloc.drawonlytoclient = player;
	spawnloc.effects = EF_STARDUST;
	spawnloc.cnt = autocvar_g_nades_spawn_count;

	if(player.nade_spawnloc)
		delete(player.nade_spawnloc);

	player.nade_spawnloc = spawnloc;
}

void nade_spawn_SetSpawnHealth(entity player)
{
	if(autocvar_g_nades_spawn_health_respawn > 0)
		SetResource(player, RES_HEALTH, autocvar_g_nades_spawn_health_respawn);
}

bool nade_spawn_DestroyDamage(entity this, entity attacker)
{
	if(autocvar_g_nades_spawn_destroy_damage > 0 && STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_SPAWN.m_id)
		Damage(this.realowner, attacker, attacker, autocvar_g_nades_spawn_destroy_damage, DEATH_TOUCHEXPLODE.m_id, DMG_NOWEP, this.realowner.origin, '0 0 0');
	return false;
}
#endif // SVQC
#ifdef MENUQC
METHOD(SpawnNade, describe, string(SpawnNade this))
{
	TC(SpawnNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, temporarily setting your spawnpoint to where it detonated. "
	      "It is useful for cases where you want to go back to some point on the map after you die."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
