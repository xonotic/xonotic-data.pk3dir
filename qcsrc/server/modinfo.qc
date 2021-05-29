REGISTER_MUTATOR(mutator_mod, true);

MUTATOR_HOOKFUNCTION(mutator_mod, BuildMutatorsString) {
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ":mod");
}

// we now show a proper message in the about page
//MUTATOR_HOOKFUNCTION(mutator_mod, BuildMutatorsPrettyString) {
//    M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Mod");
//}

MUTATOR_HOOKFUNCTION(mutator_mod, BuildGameplayTipsString, CBC_ORDER_LAST)
{
    M_ARGV(0, string) = strcat(M_ARGV(0, string), "\n\n ^7Running ^5Cyber^7 mod \n^3https://gitlab.com/xonotic/xonotic-data.pk3dir/-/tree/LegendaryGuard/cyber/");
}