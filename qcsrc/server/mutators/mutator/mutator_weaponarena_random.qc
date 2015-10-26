#ifdef IMPLEMENTATION
// WEAPONTODO: rename the cvars
REGISTER_MUTATOR(weaponarena_random, true);

MUTATOR_HOOKFUNCTION(weaponarena_random, PlayerSpawn) {
    SELFPARAM();
    if (!g_weaponarena_random) return;
    if (g_weaponarena_random_with_blaster) this.weapons &= ~WEPSET(BLASTER);
    W_RandomWeapons(this, g_weaponarena_random);
    if (g_weaponarena_random_with_blaster) this.weapons |= WEPSET(BLASTER);
}

#endif
