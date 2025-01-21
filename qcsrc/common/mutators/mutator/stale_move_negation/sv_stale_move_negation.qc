#include "sv_stale_move_negation.qh"

AUTOCVAR(g_smneg, bool, false, "enable stale-move negation, penalizing repeated use of the same weapon");
AUTOCVAR(g_smneg_bonus, bool, true, "allow weapons to become stronger than their baseline");
AUTOCVAR(g_smneg_bonus_asymptote, float, 4, "stale-move negation damage is infinity at this bonus level");
AUTOCVAR(g_smneg_cooldown_factor, float, 1 / 4, "stale-move negation penalty cooldown factor");
REGISTER_MUTATOR(mutator_smneg, autocvar_g_smneg);

MUTATOR_HOOKFUNCTION(mutator_smneg, BuildMutatorsString) {
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ":StaleMoveNegation");
}

MUTATOR_HOOKFUNCTION(mutator_smneg, BuildMutatorsPrettyString) {
    M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Stale-move negation");
}

.float x_smneg_weight[REGISTRY_MAX(Weapons)];

float smneg_multiplier(float weight) {
    float a = autocvar_g_smneg_bonus_asymptote;
    float x = max(
        (!autocvar_g_smneg_bonus ? 0 : (-a + .1)),
        weight / start_health
    );
    float z = (M_PI / 5) * a;
    float f = (x > 0)
        ? (atan(z / x) / (M_PI / 2))
        : (tan(-(x / z)) + 1);
    return f;
}

MUTATOR_HOOKFUNCTION(mutator_smneg, Damage_Calculate) {
    float deathtype = M_ARGV(3, float);
    Weapon w = DEATH_WEAPONOF(deathtype);
    if (w == WEP_Null) return;

    entity frag_attacker = M_ARGV(1, entity);
    entity c = CS(frag_attacker);
    float weight = c.x_smneg_weight[w.m_id];
    float f = smneg_multiplier(weight);
    float frag_damage = M_ARGV(4, float) = f * M_ARGV(4, float);
    M_ARGV(6, vector) = f * M_ARGV(6, vector); // force

    c.x_smneg_weight[w.m_id] = weight + frag_damage;
    float restore = frag_damage * autocvar_g_smneg_cooldown_factor;
    FOREACH(Weapons, it != WEP_Null && it != w, {
        c.x_smneg_weight[it.m_id] -= restore;
    });
}
