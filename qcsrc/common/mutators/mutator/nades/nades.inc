#include <common/colors.qh>

#ifdef GAMEQC
#define NADE_PROJECTILE(i, projectile, trail) MACRO_BEGIN \
    this.m_projectile[i] = projectile; \
    this.m_trail[i] = trail; \
MACRO_END
#endif

CLASS(NormalNade, Nade)
#ifdef MENUQC
    METHOD(NormalNade, describe, string(NormalNade this))
    {
        TC(NormalNade, this);
        return _("The (normal) Grenade explodes after a short delay, dealing damage to nearby players\n\n"
                 "Make sure you remember to throw it, or else it will blow up in your hands!");
    }
#endif
ENDCLASS(NormalNade)
REGISTER_NADE(NORMAL, NEW(NormalNade)) {
    this.m_color = COLOR_NADE_NORMAL;
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE, EFFECT_Null);
    NADE_PROJECTILE(1, PROJECTILE_NADE_BURN, EFFECT_Null);
#endif
}

CLASS(NapalmNade, Nade)
#ifdef MENUQC
    METHOD(NapalmNade, describe, string(NapalmNade this))
    {
        TC(NapalmNade, this);
        return _("The Napalm grenade explodes after a short delay, spreading fiery napalm globs around in the fountain. "
                 "The napalm fire balls burn for a while, and damage players who get too close");
    }
#endif
ENDCLASS(NapalmNade)
REGISTER_NADE(NAPALM, NEW(NapalmNade)) {
    this.m_color = COLOR_NADE_NAPALM;
    this.m_name = _("Napalm grenade");
    this.m_icon = "nade_napalm";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_NAPALM, EFFECT_TR_ROCKET);
    NADE_PROJECTILE(1, PROJECTILE_NADE_NAPALM_BURN, EFFECT_SPIDERBOT_ROCKET_TRAIL);
#endif
}

CLASS(IceNade, Nade)
#ifdef MENUQC
    METHOD(IceNade, describe, string(IceNade this))
    {
        TC(IceNade, this);
        return _("The Ice grenade detonates after a short delay, freezing any enemies who walk within the explosion radius for a few seconds after the explosion. "
                 "While frozen, enemies are progressively dealt damage");
    }
#endif
ENDCLASS(IceNade)
REGISTER_NADE(ICE, NEW(IceNade)) {
    this.m_color = COLOR_NADE_ICE;
    this.m_name = _("Ice grenade");
    this.m_icon = "nade_ice";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ICE, EFFECT_TR_NEXUIZPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ICE_BURN, EFFECT_RACER_ROCKET_TRAIL);
#endif
}

CLASS(TranslocateNade, Nade)
#ifdef MENUQC
    METHOD(TranslocateNade, describe, string(TranslocateNade this))
    {
        TC(TranslocateNade, this);
        return _("The Translocate grenade detonates after a short delay, teleporting you to where it detonated");
    }
#endif
ENDCLASS(TranslocateNade)
REGISTER_NADE(TRANSLOCATE, NEW(TranslocateNade)) {
    this.m_color = COLOR_NADE_TRANSLOCATE;
    this.m_name = _("Translocate grenade");
    this.m_icon = "nade_translocate";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
#endif
}

CLASS(SpawnNade, Nade)
#ifdef MENUQC
    METHOD(SpawnNade, describe, string(SpawnNade this))
    {
        TC(SpawnNade, this);
        return _("The Spawn grenade detonates after a short delay, temporarily setting your spawn point to where it detonated. "
                 "It is useful for cases where you want to go back to some point on the map after you die");
    }
#endif
ENDCLASS(SpawnNade)
REGISTER_NADE(SPAWN, NEW(SpawnNade)) {
    this.m_color = COLOR_NADE_SPAWN;
    this.m_name = _("Spawn grenade");
    this.m_icon = "nade_spawn";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
#endif
}

CLASS(HealNade, Nade)
#ifdef MENUQC
    METHOD(HealNade, describe, string(HealNade this))
    {
        TC(HealNade, this);
        return _("The Heal grenade detonates after a short delay, temporarily creating a healing orb around the point where it detonated for several seconds. "
                 "If your team members enter the orb they will recover health, and if enemies enter the sphere they will be harmed");
    }
#endif
ENDCLASS(HealNade)
REGISTER_NADE(HEAL, NEW(HealNade)) {
    this.m_color = COLOR_NADE_HEAL;
    this.m_name = _("Heal grenade");
    this.m_icon = "nade_heal";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_HEAL, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_HEAL_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(MonsterNade, Nade)
#ifdef MENUQC
    METHOD(MonsterNade, describe, string(MonsterNade this))
    {
        TC(MonsterNade, this);
        return _("The Monster grenade explodes after a short delay, spawning one of four monster types");
    }
#endif
ENDCLASS(MonsterNade)
REGISTER_NADE(MONSTER, NEW(MonsterNade)) {
    this.m_color = COLOR_NADE_MONSTER;
    this.m_name = _("Monster grenade");
    this.m_icon = "nade_monster";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_MONSTER, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_MONSTER_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(EntrapNade, Nade)
#ifdef MENUQC
    METHOD(EntrapNade, describe, string(EntrapNade this))
    {
        TC(EntrapNade, this);
        return _("The Entrap grenade detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
                 "Players and projectiles that enter the sphere will be slowed down, including yourself");
    }
#endif
ENDCLASS(EntrapNade)
REGISTER_NADE(ENTRAP, NEW(EntrapNade)) {
    this.m_color = COLOR_NADE_ENTRAP;
    this.m_name = _("Entrap grenade");
    this.m_icon = "nade_entrap";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ENTRAP, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ENTRAP_BURN, EFFECT_NADE_TRAIL_BURN_YELLOW);
#endif
}

CLASS(VeilNade, Nade)
#ifdef MENUQC
    METHOD(VeilNade, describe, string(VeilNade this))
    {
        TC(VeilNade, this);
        return _("The Veil grenade detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
                 "Players inside the orb will be invisible to those outside it");
    }
#endif
ENDCLASS(VeilNade)
REGISTER_NADE(VEIL, NEW(VeilNade)) {
    this.m_color = COLOR_NADE_VEIL;
    this.m_name = _("Veil grenade");
    this.m_icon = "nade_veil";
    this.m_alpha = 0.45;
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_VEIL, EFFECT_NADE_TRAIL_NEUTRAL);
    NADE_PROJECTILE(1, PROJECTILE_NADE_VEIL_BURN, EFFECT_NADE_TRAIL_BURN_NEUTRAL);
#endif
}

CLASS(AmmoNade, Nade)
#ifdef MENUQC
    METHOD(AmmoNade, describe, string(AmmoNade this))
    {
        TC(AmmoNade, this);
        return _("The Ammo grenade detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
                 "If your team members enter the orb they will recover ammo, and if enemies enter the sphere they will lose ammo\n\n"
                 "This does not impact weapon magazines, so it won't reload your weapons for you");
    }
#endif
ENDCLASS(AmmoNade)
REGISTER_NADE(AMMO, NEW(AmmoNade)) {
    this.m_color = COLOR_NADE_AMMO;
    this.m_name = _("Ammo grenade");
    this.m_icon = "nade_ammo";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_AMMO, EFFECT_NADE_TRAIL_BROWN);
    NADE_PROJECTILE(1, PROJECTILE_NADE_AMMO_BURN, EFFECT_NADE_TRAIL_BURN_BROWN);
#endif
}

CLASS(DarknessNade, Nade)
#ifdef MENUQC
    METHOD(DarknessNade, describe, string(DarknessNade this))
    {
        TC(DarknessNade, this);
        return _("The Darkness grenade detonates after a short delay, creating a dark field which temporarily blinds enemies who enter it");
    }
#endif
ENDCLASS(DarknessNade)
REGISTER_NADE(DARKNESS, NEW(DarknessNade)) {
    this.m_color = COLOR_NADE_DARKNESS;
    this.m_name = _("Darkness grenade");
    this.m_icon = "nade_darkness";
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_DARKNESS, EFFECT_NADE_TRAIL_PURPLE);
    NADE_PROJECTILE(1, PROJECTILE_NADE_DARKNESS_BURN, EFFECT_NADE_TRAIL_BURN_PURPLE);
#endif
}
