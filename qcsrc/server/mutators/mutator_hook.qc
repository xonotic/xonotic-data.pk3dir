AUTOCVAR(g_grappling_hook, bool, false, _("let players spawn with the grappling hook which allows them to pull themselves up"));
#ifdef SVQC
REGISTER_MUTATOR(hook, autocvar_g_grappling_hook) {
    MUTATOR_ONADD {
        g_grappling_hook = true;
        WEP_HOOK.ammo_factor = 0;
    }
    MUTATOR_ONROLLBACK_OR_REMOVE {
        g_grappling_hook = false;
        WEP_HOOK.ammo_factor = 1;
    }
}

MUTATOR_HOOKFUNCTION(hook, BuildMutatorsString)
{
    ret_string = strcat(ret_string, ":grappling_hook");
}

MUTATOR_HOOKFUNCTION(hook, BuildMutatorsPrettyString)
{
    ret_string = strcat(ret_string, ", Hook");
}

MUTATOR_HOOKFUNCTION(hook, BuildGameplayTipsString)
{
    ret_string = strcat(ret_string, "\n\n^3grappling hook^8 is enabled, press 'e' to use it\n");
}

MUTATOR_HOOKFUNCTION(hook, PlayerSpawn)
{
    SELFPARAM();
    self.offhand = OFFHAND_HOOK;
}

MUTATOR_HOOKFUNCTION(hook, FilterItem)
{
    return self.weapon == WEP_HOOK.m_id;
}

#endif
