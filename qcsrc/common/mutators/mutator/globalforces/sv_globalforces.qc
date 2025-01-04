#include "sv_globalforces.qh"

AUTOCVAR(g_globalforces, float, false, "enable global forces, so that knockback affects everyone");
AUTOCVAR(g_globalforces_noself, bool, true, "ignore self damage");
AUTOCVAR(g_globalforces_self, float, 1, "global forces knockback self scale");
AUTOCVAR(g_globalforces_range, float, 1000, "global forces max range of effect");
REGISTER_MUTATOR(mutator_globalforces, autocvar_g_globalforces);

MUTATOR_HOOKFUNCTION(mutator_globalforces, BuildMutatorsString) {
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ":GlobalForces");
}

MUTATOR_HOOKFUNCTION(mutator_globalforces, BuildMutatorsPrettyString) {
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Global forces");
}

MUTATOR_HOOKFUNCTION(mutator_globalforces, PlayerDamage_SplitHealthArmor) {
    entity frag_attacker = M_ARGV(1, entity);
    entity frag_target = M_ARGV(2, entity);
    if (autocvar_g_globalforces_noself && frag_target == frag_attacker) return;
    vector damage_force = M_ARGV(3, vector) * autocvar_g_globalforces;
    FOREACH_CLIENT(IS_PLAYER(it) && it != frag_target, {
        if (autocvar_g_globalforces_range) {
            if (vdist(it.origin - frag_target.origin, >, autocvar_g_globalforces_range)) {
                continue;
            }
        }
        float f = (it == frag_attacker) ? autocvar_g_globalforces_self : 1;
        it.velocity += damage_explosion_calcpush(f * it.damageforcescale * damage_force, it.velocity, autocvar_g_balance_damagepush_speedfactor);
    });
}
