#include "sv_respawntime.qh"

AUTOCVAR(g_killers_spawn_faster, bool, false, "Killers spawn faster: a mutator that penalizes dying, and rewards killing, by adjusting time to respawn");
AUTOCVAR(g_killers_spawn_faster_frag_modifier, float, -0.25, "Killers spawn faster: respawntime factor change when fragging someone");
AUTOCVAR(g_killers_spawn_faster_death_modifier, float, 0.5, "Killers spawn faster: respawntime factor change when dying");
AUTOCVAR(g_killers_spawn_faster_min, float, 0.2, "Minimum factor the respawn time can be multiplied with");
AUTOCVAR(g_killers_spawn_faster_max, float, 5.0, "Maximum factor the respawn time can be multiplied with");
REGISTER_MUTATOR(mutator_killers_spawn_faster, autocvar_g_killers_spawn_faster);

float killers_spawn_faster_adjust(float base, float adj) {
	if (adj < 0) {
		adj *= base;
	}
	return bound(autocvar_g_killers_spawn_faster_min, base + adj, autocvar_g_killers_spawn_faster_max);
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, BuildMutatorsString) {
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":KillersSpawnFaster");
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, BuildMutatorsPrettyString) {
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Killers spawn faster");
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, ClientConnect) {
	entity player = M_ARGV(0, entity);
	player.killers_spawn_faster_factor = 1;
	LOG_DEBUGF("Newly spawned player %i with respawntime factor %f", player, player.killers_spawn_faster_factor);
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, GiveFragsForKill, CBC_ORDER_FIRST) {
	// Note: this runs BEFORE CalculateRespawnTime.
	entity attacker = M_ARGV(0, entity);
	float frags = M_ARGV(2, float);
	if (frags < 0) {
		// Suicide, teamkill or similar.
		// As the frags amount is an inout parameter, this must be CBC_ORDER_FIRST.
		return false;
	}
	attacker.killers_spawn_faster_factor = killers_spawn_faster_adjust(
		attacker.killers_spawn_faster_factor,
		autocvar_g_killers_spawn_faster_frag_modifier);
	LOG_DEBUGF("Killer player %i now has respawntime factor %f", attacker, attacker.killers_spawn_faster_factor);
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, CalculateRespawnTime) {
	entity player = M_ARGV(0, entity);
	float sdelay = M_ARGV(1, float);
	sdelay *= player.killers_spawn_faster_factor;
	LOG_DEBUGF("Adjusted player %i respawntime to %f", player, sdelay);
	M_ARGV(1, float) = sdelay;
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, PlayerDied) {
	// Note: this runs AFTER CalculateRespawnTime.
	entity player = M_ARGV(0, entity);
	player.killers_spawn_faster_factor = killers_spawn_faster_adjust(
		player.killers_spawn_faster_factor,
		autocvar_g_killers_spawn_faster_death_modifier);
	LOG_DEBUGF("Dying player %i now has respawntime factor %f", player, player.killers_spawn_faster_factor);
}

MUTATOR_HOOKFUNCTION(mutator_killers_spawn_faster, PlayerScore_Clear) {
	entity player = M_ARGV(0, entity);
	player.killers_spawn_faster_factor = 1;
	LOG_DEBUGF("Restarted player %i now has respawntime factor %f", player, player.killers_spawn_faster_factor);
}
