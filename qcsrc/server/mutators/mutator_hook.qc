REGISTER_MUTATOR(hook, cvar("_g_grappling_hook"));

MUTATOR_HOOKFUNCTION(hook, PlayerSpawn)
{
    SELFPARAM();
    self.offhand = OFFHAND_HOOK;
}
