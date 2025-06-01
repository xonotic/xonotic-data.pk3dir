#include "sv_hook.qh"

// can't use the autocvar as it doesn't work in the campaign
//AUTOCVAR(g_grappling_hook, bool, false, "let players spawn with the Grappling Hook which allows them to pull themselves up");
#ifdef SVQC
AUTOCVAR(g_grappling_hook_useammo, bool, false, "use ammunition with the offhand Grappling Hook");

REGISTER_MUTATOR(hook, expr_evaluate(cvar_string("g_grappling_hook"))) {
    MUTATOR_ONADD {
        g_grappling_hook = true;
        if(!autocvar_g_grappling_hook_useammo)
            WEP_HOOK.ammo_factor = 0;
    }
    MUTATOR_ONROLLBACK_OR_REMOVE {
        g_grappling_hook = false;
        if(!autocvar_g_grappling_hook_useammo)
            WEP_HOOK.ammo_factor = 1; // we don't need to change it
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

MUTATOR_HOOKFUNCTION(hook, SetStartItems)
{
    if(autocvar_g_grappling_hook_useammo)
    {
        start_items |= ITEM_FuelRegen.m_itemid;
        start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
        warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
    }
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
