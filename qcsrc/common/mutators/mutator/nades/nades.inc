#ifdef GAMEQC
#define NADE_PROJECTILE(i, projectile, trail) MACRO_BEGIN \
    this.m_projectile[i] = projectile; \
    this.m_trail[i] = trail; \
MACRO_END
#else
#define NADE_PROJECTILE(i, projectile, trail)
#endif

REGISTER_NADE(NORMAL) {
    this.m_color = '1 1 1';
    NADE_PROJECTILE(0, PROJECTILE_NADE, EFFECT_Null);
    NADE_PROJECTILE(1, PROJECTILE_NADE_BURN, EFFECT_Null);
}

REGISTER_NADE(NAPALM) {
    this.m_color = '2 0.5 0';
    this.m_name = _("Napalm grenade");
    this.m_icon = "nade_napalm";
    NADE_PROJECTILE(0, PROJECTILE_NADE_NAPALM, EFFECT_TR_ROCKET);
    NADE_PROJECTILE(1, PROJECTILE_NADE_NAPALM_BURN, EFFECT_SPIDERBOT_ROCKET_TRAIL);
}

REGISTER_NADE(ICE) {
    this.m_color = '0 0.5 2';
    this.m_name = _("Ice grenade");
    this.m_icon = "nade_ice";
    NADE_PROJECTILE(0, PROJECTILE_NADE_ICE, EFFECT_TR_NEXUIZPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ICE_BURN, EFFECT_RACER_ROCKET_TRAIL);
}

REGISTER_NADE(TRANSLOCATE) {
    this.m_color = '1 0 1';
    this.m_name = _("Translocate grenade");
    this.m_icon = "nade_translocate";
    NADE_PROJECTILE(0, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
}

REGISTER_NADE(SPAWN) {
    this.m_color = '1 0.9 0';
    this.m_name = _("Spawn grenade");
    this.m_icon = "nade_spawn";
    NADE_PROJECTILE(0, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
}

REGISTER_NADE(HEAL) {
    this.m_color = '1 0 0';
    this.m_name = _("Heal grenade");
    this.m_icon = "nade_heal";
    NADE_PROJECTILE(0, PROJECTILE_NADE_HEAL, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_HEAL_BURN, EFFECT_NADE_TRAIL_BURN_RED);
}

REGISTER_NADE(MONSTER) {
    this.m_color = '0.25 0.75 0';
    this.m_name = _("Monster grenade");
    this.m_icon = "nade_monster";
    NADE_PROJECTILE(0, PROJECTILE_NADE_MONSTER, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_MONSTER_BURN, EFFECT_NADE_TRAIL_BURN_RED);
}

REGISTER_NADE(ENTRAP) {
    this.m_color = '0.15 0.85 0';
    this.m_name = _("Entrap grenade");
    this.m_icon = "nade_entrap";
    NADE_PROJECTILE(0, PROJECTILE_NADE_ENTRAP, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ENTRAP_BURN, EFFECT_NADE_TRAIL_BURN_YELLOW);
}

REGISTER_NADE(VEIL) {
    this.m_color = '0.65 0.85 0.65';
    this.m_name = _("Veil grenade");
    this.m_icon = "nade_veil";
    this.m_alpha = 0.45;
    NADE_PROJECTILE(0, PROJECTILE_NADE_VEIL, EFFECT_NADE_TRAIL_NEUTRAL);
    NADE_PROJECTILE(1, PROJECTILE_NADE_VEIL_BURN, EFFECT_NADE_TRAIL_BURN_NEUTRAL);
}
