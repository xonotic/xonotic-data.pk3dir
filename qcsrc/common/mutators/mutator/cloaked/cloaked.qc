#ifdef IMPLEMENTATION

REGISTER_MUTATOR(cloaked, cvar("g_cloaked"));

float autocvar_g_balance_cloaked_alpha;

MUTATOR_HOOKFUNCTION(cloaked, SetDefaultAlpha)
{
    default_player_alpha = autocvar_g_balance_cloaked_alpha;
    default_weapon_alpha = default_player_alpha;
    return true;
}

MUTATOR_HOOKFUNCTION(cloaked, BuildMutatorsPrettyString)
{
	if (!g_cts) ret_string = strcat(ret_string, ", Cloaked");
}

#endif
