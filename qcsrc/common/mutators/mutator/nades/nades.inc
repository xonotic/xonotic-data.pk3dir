#ifdef GAMEQC
#define NADE_PROJECTILE(i, projectile, trail) MACRO_BEGIN \
    this.m_projectile[i] = projectile; \
    this.m_trail[i] = trail; \
MACRO_END
#endif

CLASS(NormalNade, Nade)
    ATTRIB(NormalNade, m_color, vector, '1 1 1');
    ATTRIB(NormalNade, m_name, string, _("Grenade"));
    ATTRIB(NormalNade, m_icon, string, "nade_normal");
ENDCLASS(NormalNade)
REGISTER_NADE(NORMAL, NEW(NormalNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE, EFFECT_Null);
    NADE_PROJECTILE(1, PROJECTILE_NADE_BURN, EFFECT_Null);
#endif
}

CLASS(NapalmNade, Nade)
    ATTRIB(NapalmNade, m_color, vector, '2 0.5 0');
    ATTRIB(NapalmNade, m_name, string, _("Napalm grenade"));
    ATTRIB(NapalmNade, m_icon, string, "nade_napalm");
ENDCLASS(NapalmNade)
REGISTER_NADE(NAPALM, NEW(NapalmNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_NAPALM, EFFECT_TR_ROCKET);
    NADE_PROJECTILE(1, PROJECTILE_NADE_NAPALM_BURN, EFFECT_SPIDERBOT_ROCKET_TRAIL);
#endif
}

CLASS(IceNade, Nade)
    ATTRIB(IceNade, m_color, vector, '0 0.5 2');
    ATTRIB(IceNade, m_name, string, _("Ice grenade"));
    ATTRIB(IceNade, m_icon, string, "nade_ice");
ENDCLASS(IceNade)
REGISTER_NADE(ICE, NEW(IceNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ICE, EFFECT_TR_NEXUIZPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ICE_BURN, EFFECT_RACER_ROCKET_TRAIL);
#endif
}

CLASS(TranslocateNade, Nade)
    ATTRIB(TranslocateNade, m_color, vector, '1 0 1');
    ATTRIB(TranslocateNade, m_name, string, _("Translocate grenade"));
    ATTRIB(TranslocateNade, m_icon, string, "nade_translocate");
ENDCLASS(TranslocateNade)
REGISTER_NADE(TRANSLOCATE, NEW(TranslocateNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
#endif
}

CLASS(SpawnNade, Nade)
    ATTRIB(SpawnNade, m_color, vector, '1 0.9 0');
    ATTRIB(SpawnNade, m_name, string, _("Spawn grenade"));
    ATTRIB(SpawnNade, m_icon, string, "nade_spawn");
ENDCLASS(SpawnNade)
REGISTER_NADE(SPAWN, NEW(SpawnNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
#endif
}

CLASS(HealNade, Nade)
    ATTRIB(HealNade, m_color, vector, '1 0 0');
    ATTRIB(HealNade, m_name, string, _("Heal grenade"));
    ATTRIB(HealNade, m_icon, string, "nade_heal");
ENDCLASS(HealNade)
REGISTER_NADE(HEAL, NEW(HealNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_HEAL, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_HEAL_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(MonsterNade, Nade)
    ATTRIB(MonsterNade, m_color, vector, '0.25 0.75 0');
    ATTRIB(MonsterNade, m_name, string, _("Monster grenade"));
    ATTRIB(MonsterNade, m_icon, string, "nade_monster");
ENDCLASS(MonsterNade)
REGISTER_NADE(MONSTER, NEW(MonsterNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_MONSTER, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_MONSTER_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(EntrapNade, Nade)
    ATTRIB(EntrapNade, m_color, vector, '0.15 0.85 0');
    ATTRIB(EntrapNade, m_name, string, _("Entrap grenade"));
    ATTRIB(EntrapNade, m_icon, string, "nade_entrap");
ENDCLASS(EntrapNade)
REGISTER_NADE(ENTRAP, NEW(EntrapNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ENTRAP, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ENTRAP_BURN, EFFECT_NADE_TRAIL_BURN_YELLOW);
#endif
}

CLASS(VeilNade, Nade)
    ATTRIB(VeilNade, m_color, vector, '0.65 0.85 0.65');
    ATTRIB(VeilNade, m_name, string, _("Veil grenade"));
    ATTRIB(VeilNade, m_icon, string, "nade_veil");
    ATTRIB(VeilNade, m_alpha, float, 0.45);
ENDCLASS(VeilNade)
REGISTER_NADE(VEIL, NEW(VeilNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_VEIL, EFFECT_NADE_TRAIL_NEUTRAL);
    NADE_PROJECTILE(1, PROJECTILE_NADE_VEIL_BURN, EFFECT_NADE_TRAIL_BURN_NEUTRAL);
#endif
}

CLASS(AmmoNade, Nade)
    ATTRIB(AmmoNade, m_color, vector, '0.66 0.33 0');
    ATTRIB(AmmoNade, m_name, string, _("Ammo grenade"));
    ATTRIB(AmmoNade, m_icon, string, "nade_ammo");
ENDCLASS(AmmoNade)
REGISTER_NADE(AMMO, NEW(AmmoNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_AMMO, EFFECT_NADE_TRAIL_BROWN);
    NADE_PROJECTILE(1, PROJECTILE_NADE_AMMO_BURN, EFFECT_NADE_TRAIL_BURN_BROWN);
#endif
}

CLASS(DarknessNade, Nade)
    ATTRIB(DarknessNade, m_color, vector, '0.23 0 0.23');
    ATTRIB(DarknessNade, m_name, string, _("Darkness grenade"));
    ATTRIB(DarknessNade, m_icon, string, "nade_darkness");
ENDCLASS(DarknessNade)
REGISTER_NADE(DARKNESS, NEW(DarknessNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_DARKNESS, EFFECT_NADE_TRAIL_PURPLE);
    NADE_PROJECTILE(1, PROJECTILE_NADE_DARKNESS_BURN, EFFECT_NADE_TRAIL_BURN_PURPLE);
#endif
}
