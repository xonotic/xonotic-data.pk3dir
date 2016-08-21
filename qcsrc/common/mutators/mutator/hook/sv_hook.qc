#include "sv_hook.qh"

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

    return false;
}

MUTATOR_HOOKFUNCTION(hook, BuildMutatorsString)
{
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ":grappling_hook");
}

MUTATOR_HOOKFUNCTION(hook, BuildMutatorsPrettyString)
{
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Hook");
}

MUTATOR_HOOKFUNCTION(hook, BuildGameplayTipsString)
{
    M_ARGV(0, string) = strcat(M_ARGV(0, string), "\n\n^3grappling hook^8 is enabled, press 'e' to use it\n");
}

MUTATOR_HOOKFUNCTION(hook, PlayerSpawn)
{
    entity player = M_ARGV(0, entity);

    player.offhand = OFFHAND_HOOK;
}

MUTATOR_HOOKFUNCTION(hook, FilterItem)
{
    entity item = M_ARGV(0, entity);

    return item.weapon == WEP_HOOK.m_id;
}

#endif
