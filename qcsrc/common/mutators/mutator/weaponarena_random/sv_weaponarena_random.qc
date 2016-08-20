#include "sv_weaponarena_random.qh"

// WEAPONTODO: rename the cvars
REGISTER_MUTATOR(weaponarena_random, true);

MUTATOR_HOOKFUNCTION(weaponarena_random, PlayerSpawn)
{
    if (!g_weaponarena_random) return;
    entity player = M_ARGV(0, entity);

    if (g_weaponarena_random_with_blaster) player.weapons &= ~WEPSET(BLASTER);
    W_RandomWeapons(player, g_weaponarena_random);
    if (g_weaponarena_random_with_blaster) player.weapons |= WEPSET(BLASTER);
}
