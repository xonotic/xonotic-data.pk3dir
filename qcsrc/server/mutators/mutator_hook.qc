AUTOCVAR(g_grappling_hook, bool, _("let players spawn with the grappling hook which allows them to pull themselves up"));
REGISTER_MUTATOR(hook, autocvar_g_grappling_hook) {
    MUTATOR_ONADD {
        g_grappling_hook = true;
    }
    MUTATOR_ONROLLBACK_OR_REMOVE {
        g_grappling_hook = false;
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

MUTATOR_HOOKFUNCTION(hook, SetStartItems)
{
    start_items |= ITEM_JetpackRegen.m_itemid;
    start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
    warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
}
